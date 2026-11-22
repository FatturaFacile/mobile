import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../domain/inventory_count_models.dart';

/// Local store entities (rows of `entity_records`, tenant scoped).
const String countSessionEntity = 'inv_count_session';
const String countLineEntity = 'inv_count_line';
const String countEntryEntity = 'inv_count_entry';

const String _base = '/inventory/counts';

/// Entries sent per request (the server validates the batch in one transaction).
const int countBatchSize = 50;

/// Offline-first access to the blind physical-inventory counting.
///
/// * Sessions and sheet lines are cached in SQLite (`entity_records`) and read from there.
/// * Every quantity typed by the operator becomes a [CountEntry] with a client generated UUID. It is stored locally
///   first (sync status `pendingCreate`) and sent in batches to `POST counts/{id}/record-counts`; resending a known
///   `client_entry_id` is idempotent on the server.
/// * Blind by design: the cached line payload is a whitelist ([CountLine.toJson]); no system quantity, cost or
///   variance is ever parsed, stored or returned.
class InventoryCountRepository {
  InventoryCountRepository(
    this._db,
    this._dio, {
    Uuid? uuid,
    DateTime Function()? clock,
    this.deviceId,
  }) : _uuid = uuid ?? const Uuid(),
       _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final Dio _dio;
  final Uuid _uuid;
  final DateTime Function() _clock;

  /// Optional identifier of this device, sent with every batch.
  final String? deviceId;

  // --- Sessions -------------------------------------------------------------------------------------------------

  /// Assigned sessions from the local copy, with the local progress.
  Future<List<CountSession>> cachedSessions(String tenantId) async {
    final List<CountSession> sessions = <CountSession>[
      for (final EntityRecord r in await _rows(tenantId, countSessionEntity))
        CountSession.fromJson(jsonDecode(r.payload) as Map<String, dynamic>),
    ];
    final List<CountLine> lines = await _allLines(tenantId);
    final List<CountEntry> entries = await _entries(tenantId);
    final List<CountSession> out = <CountSession>[
      for (final CountSession s in sessions) _withProgress(s, lines, entries),
    ];
    out.sort(
      (CountSession a, CountSession b) =>
          a.sessionNumber.compareTo(b.sessionNumber),
    );
    return out;
  }

  /// Downloads `counts/assigned?assigned_to=me` and replaces the local list. A session that is no longer assigned is
  /// dropped together with its sheet, unless entries of it still wait to be sent.
  Future<List<CountSession>> refreshSessions(String tenantId) async {
    final Response<dynamic> res = await _guard(
      () => _dio.get<dynamic>(
        '$_base/assigned',
        queryParameters: <String, dynamic>{'assigned_to': 'me'},
      ),
    );
    final List<CountSession> fresh = <CountSession>[
      for (final dynamic raw in _list(_map(res.data)['data']))
        if (raw is Map) CountSession.fromJson(Map<String, dynamic>.from(raw)),
    ];
    final Set<String> keep = <String>{for (final CountSession s in fresh) s.id};
    final List<CountEntry> entries = await _entries(tenantId);
    final Set<String> withPending = <String>{
      for (final CountEntry e in entries)
        if (e.isPending) e.sessionId,
    };
    final DateTime now = _clock().toUtc();
    await _db.transaction(() async {
      for (final EntityRecord r in await _rows(tenantId, countSessionEntity)) {
        if (!keep.contains(r.id) && !withPending.contains(r.id)) {
          await _dropSession(tenantId, r.id);
        }
      }
      for (final CountSession s in fresh) {
        await _put(
          tenantId,
          countSessionEntity,
          s.id,
          s.toJson(),
          SyncStatus.synced,
          now,
        );
      }
    });
    return cachedSessions(tenantId);
  }

  // --- Sheet ----------------------------------------------------------------------------------------------------

  /// Sheet lines from the local copy with the entries typed on this device laid over them, by bin then SKU.
  Future<List<CountLine>> cachedSheet(String tenantId, String sessionId) async {
    final List<CountLine> lines = await _sessionLines(tenantId, sessionId);
    final Map<String, CountEntry> latest = _latestByLine(
      await _entries(tenantId, sessionId: sessionId),
    );
    final List<CountLine> out = <CountLine>[
      for (final CountLine l in lines) l.withEntry(latest[l.id]),
    ];
    out.sort((CountLine a, CountLine b) {
      final int bin = (a.binBarcode ?? '').compareTo(b.binBarcode ?? '');
      return bin != 0 ? bin : (a.sku ?? '').compareTo(b.sku ?? '');
    });
    return out;
  }

  /// Downloads `counts/{id}/sheet` and replaces the cached lines of the session. Entries the server has answered are
  /// now reflected by the lines and are dropped; pending and rejected ones stay.
  Future<List<CountLine>> refreshSheet(
    String tenantId,
    String sessionId, {
    bool pendingOnly = false,
  }) async {
    final Response<dynamic> res = await _guard(
      () => _dio.get<dynamic>(
        '$_base/$sessionId/sheet',
        queryParameters: pendingOnly
            ? <String, dynamic>{'pending': 1}
            : const <String, dynamic>{},
      ),
    );
    final Map<String, dynamic> body = _map(res.data);
    final List<CountLine> fresh = <CountLine>[
      for (final dynamic raw in _list(body['data']))
        if (raw is Map)
          CountLine.fromJson(
            Map<String, dynamic>.from(raw),
            sessionId: sessionId,
          ),
    ];
    final DateTime now = _clock().toUtc();
    await _db.transaction(() async {
      if (!pendingOnly) {
        await _deleteWhere(
          tenantId,
          countLineEntity,
          (EntityRecord r) => _lineSession(r) == sessionId,
        );
      }
      for (final CountLine l in fresh) {
        await _put(
          tenantId,
          countLineEntity,
          l.id,
          <String, dynamic>{...l.toJson(), 'session_id': sessionId},
          SyncStatus.synced,
          now,
        );
      }
      final Object? session = body['session'];
      if (session is Map) {
        final CountSession s = CountSession.fromJson(
          Map<String, dynamic>.from(session),
        );
        await _put(
          tenantId,
          countSessionEntity,
          s.id,
          s.toJson(),
          SyncStatus.synced,
          now,
        );
      }
      for (final CountEntry e in await _entries(
        tenantId,
        sessionId: sessionId,
      )) {
        if (e.status == EntryStatus.recorded ||
            e.status == EntryStatus.recountRequired) {
          await _forget(tenantId, countEntryEntity, e.clientEntryId);
        }
      }
    });
    return cachedSheet(tenantId, sessionId);
  }

  // --- Entries (offline outbox) ---------------------------------------------------------------------------------

  /// Stores one count locally, ready to be sent. Never touches the network.
  Future<CountEntry> recordCount(
    String tenantId, {
    required String sessionId,
    required String lineId,
    required double quantity,
    String? notes,
  }) async {
    if (!quantity.isFinite || quantity < 0) {
      throw const CountException(CountErrorKind.invalid);
    }
    final String? trimmed = notes?.trim();
    final CountEntry entry = CountEntry(
      clientEntryId: _uuid.v4(),
      sessionId: sessionId,
      sessionLineId: lineId,
      countedQuantity: quantity,
      createdAt: _clock().toUtc(),
      notes: trimmed == null || trimmed.isEmpty ? null : trimmed,
    );
    await _db.transaction(() async {
      for (final CountEntry old in await _entries(
        tenantId,
        sessionId: sessionId,
      )) {
        final bool sameLine = old.sessionLineId == lineId;
        // A refused entry is superseded by the new attempt; an entry never sent is simply replaced.
        if (sameLine &&
            (old.status == EntryStatus.rejected ||
                (old.isPending && old.attempts == 0))) {
          await _forget(tenantId, countEntryEntity, old.clientEntryId);
        }
      }
      await _put(
        tenantId,
        countEntryEntity,
        entry.clientEntryId,
        <String, dynamic>{...entry.toJson(), 'session_id': sessionId},
        SyncStatus.pendingCreate,
        entry.createdAt,
      );
    });
    return entry;
  }

  /// Hides a refused entry (the operator has seen the server decision).
  Future<void> dismissEntry(String tenantId, String clientEntryId) =>
      _forget(tenantId, countEntryEntity, clientEntryId);

  /// Number of entries waiting to be sent, live.
  Stream<int> watchPendingCount(String tenantId) {
    return (_db.select(_db.entityRecords)..where(
          (EntityRecords t) =>
              t.tenantId.equals(tenantId) &
              t.entity.equals(countEntryEntity) &
              t.syncStatus.equalsValue(SyncStatus.pendingCreate),
        ))
        .watch()
        .map((List<EntityRecord> rows) => rows.length);
  }

  Future<int> pendingCount(String tenantId) async =>
      (await _entries(tenantId)).where((CountEntry e) => e.isPending).length;

  /// Sends every pending entry in batches of [countBatchSize], oldest first, one session at a time. Outcomes are
  /// written per entry. A network failure or a 5xx leaves the entries pending for the next attempt; 403/404/422 refuse
  /// the batch for good (it would never succeed). Never throws.
  Future<CountSyncReport> flush(String tenantId) async {
    final List<CountEntry> pending = <CountEntry>[
      for (final CountEntry e in await _entries(tenantId))
        if (e.isPending) e,
    ]..sort((CountEntry a, CountEntry b) => a.createdAt.compareTo(b.createdAt));
    if (pending.isEmpty) {
      return const CountSyncReport();
    }
    final Map<String, List<CountEntry>> bySession =
        <String, List<CountEntry>>{};
    for (final CountEntry e in pending) {
      bySession.putIfAbsent(e.sessionId, () => <CountEntry>[]).add(e);
    }
    int recorded = 0;
    int recount = 0;
    int rejected = 0;
    int left = 0;
    bool offline = false;
    bool stop = false;
    final Set<String> affected = <String>{};
    for (final MapEntry<String, List<CountEntry>> group in bySession.entries) {
      for (int i = 0; i < group.value.length; i += countBatchSize) {
        final List<CountEntry> chunk = group.value.sublist(
          i,
          i + countBatchSize > group.value.length
              ? group.value.length
              : i + countBatchSize,
        );
        if (stop) {
          left += chunk.length;
          continue;
        }
        try {
          final Response<dynamic> res = await _dio.post<dynamic>(
            '$_base/${group.key}/record-counts',
            data: <String, dynamic>{
              'device_id': ?deviceId,
              'entries': <Map<String, dynamic>>[
                for (final CountEntry e in chunk) e.toWire(),
              ],
            },
          );
          final Map<String, Map<String, dynamic>> results =
              <String, Map<String, dynamic>>{
                for (final dynamic r in _list(_map(res.data)['data']))
                  if (r is Map && r['client_entry_id'] != null)
                    '${r['client_entry_id']}': Map<String, dynamic>.from(r),
              };
          for (final CountEntry e in chunk) {
            final Map<String, dynamic>? r = results[e.clientEntryId];
            if (r == null) {
              left++;
              await _save(tenantId, e.copyWith(attempts: e.attempts + 1));
              continue;
            }
            final EntryStatus status = EntryStatus.parse('${r['status']}');
            if (status == EntryStatus.pending) {
              left++;
              continue;
            }
            switch (status) {
              case EntryStatus.recorded:
                recorded++;
              case EntryStatus.recountRequired:
                recount++;
              case EntryStatus.rejected:
                rejected++;
              case EntryStatus.pending:
                break;
            }
            await _save(
              tenantId,
              e.copyWith(
                status: status,
                recountRound: r['recount_round'] is num
                    ? (r['recount_round'] as num).toInt()
                    : null,
                message: r['message'] is String ? r['message'] as String : null,
              ),
              syncStatus: status == EntryStatus.rejected
                  ? SyncStatus.conflict
                  : SyncStatus.synced,
            );
            affected.add(group.key);
          }
        } on DioException catch (e) {
          final int? code = e.response?.statusCode;
          if (code == 403 || code == 404 || code == 422) {
            final String message = _problemMessage(e.response?.data);
            for (final CountEntry entry in chunk) {
              await _save(
                tenantId,
                entry.copyWith(
                  status: EntryStatus.rejected,
                  message: message.isEmpty ? null : message,
                ),
                syncStatus: SyncStatus.conflict,
              );
            }
            rejected += chunk.length;
            affected.add(group.key);
            continue;
          }
          offline = offline || e.response == null;
          stop = true;
          left += chunk.length;
          for (final CountEntry entry in chunk) {
            await _save(tenantId, entry.copyWith(attempts: entry.attempts + 1));
          }
        }
      }
    }
    return CountSyncReport(
      recorded: recorded,
      recountRequired: recount,
      rejected: rejected,
      stillPending: left,
      offline: offline,
      affectedSessionIds: affected,
    );
  }

  /// Flushes the entries, then refreshes the sheet of every session the server answered for, so new recount flags
  /// and the server value of refused lines show up. Never throws.
  Future<CountSyncReport> sync(String tenantId) async {
    final CountSyncReport report = await flush(tenantId);
    for (final String id in report.affectedSessionIds) {
      try {
        await refreshSheet(tenantId, id);
      } on CountException {
        // Offline or server trouble: the answered entries stay on screen until the next refresh.
      }
    }
    return report;
  }

  // --- Local store ----------------------------------------------------------------------------------------------

  CountSession _withProgress(
    CountSession s,
    List<CountLine> lines,
    List<CountEntry> entries,
  ) {
    final Map<String, CountEntry> latest = _latestByLine(
      entries.where((CountEntry e) => e.sessionId == s.id),
    );
    int total = 0;
    int counted = 0;
    for (final CountLine l in lines) {
      if (l.sessionId != s.id) {
        continue;
      }
      total++;
      if (!l.withEntry(latest[l.id]).toCount) {
        counted++;
      }
    }
    final int pending = entries
        .where((CountEntry e) => e.sessionId == s.id && e.isPending)
        .length;
    return s.withProgress(counted: counted, total: total, pending: pending);
  }

  Map<String, CountEntry> _latestByLine(Iterable<CountEntry> entries) {
    final Map<String, CountEntry> latest = <String, CountEntry>{};
    for (final CountEntry e in entries) {
      final CountEntry? current = latest[e.sessionLineId];
      if (current == null || !e.createdAt.isBefore(current.createdAt)) {
        latest[e.sessionLineId] = e;
      }
    }
    return latest;
  }

  Future<List<EntityRecord>> _rows(String tenantId, String entity) {
    return (_db.select(_db.entityRecords)..where(
          (EntityRecords t) =>
              t.tenantId.equals(tenantId) & t.entity.equals(entity),
        ))
        .get();
  }

  static String? _lineSession(EntityRecord r) {
    final Object? v =
        (jsonDecode(r.payload) as Map<String, dynamic>)['session_id'];
    return v == null ? null : '$v';
  }

  Future<List<CountLine>> _allLines(String tenantId) async => <CountLine>[
    for (final EntityRecord r in await _rows(tenantId, countLineEntity))
      _decodeLine(r),
  ];

  Future<List<CountLine>> _sessionLines(
    String tenantId,
    String sessionId,
  ) async => <CountLine>[
    for (final EntityRecord r in await _rows(tenantId, countLineEntity))
      if (_lineSession(r) == sessionId) _decodeLine(r),
  ];

  CountLine _decodeLine(EntityRecord r) {
    final Map<String, dynamic> json =
        jsonDecode(r.payload) as Map<String, dynamic>;
    return CountLine.fromJson(json, sessionId: '${json['session_id']}');
  }

  Future<List<CountEntry>> _entries(
    String tenantId, {
    String? sessionId,
  }) async {
    final List<CountEntry> all = <CountEntry>[
      for (final EntityRecord r in await _rows(tenantId, countEntryEntity))
        CountEntry.fromJson(jsonDecode(r.payload) as Map<String, dynamic>),
    ];
    return sessionId == null
        ? all
        : all.where((CountEntry e) => e.sessionId == sessionId).toList();
  }

  Future<void> _save(
    String tenantId,
    CountEntry entry, {
    SyncStatus syncStatus = SyncStatus.pendingCreate,
  }) {
    return _put(
      tenantId,
      countEntryEntity,
      entry.clientEntryId,
      entry.toJson(),
      syncStatus,
      _clock().toUtc(),
    );
  }

  Future<void> _put(
    String tenantId,
    String entity,
    String id,
    Map<String, dynamic> payload,
    SyncStatus status,
    DateTime now,
  ) {
    return _db
        .into(_db.entityRecords)
        .insertOnConflictUpdate(
          EntityRecordsCompanion.insert(
            entity: entity,
            id: id,
            tenantId: tenantId,
            payload: jsonEncode(payload),
            syncStatus: status,
            localUpdatedAt: now,
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<void> _forget(String tenantId, String entity, String id) async {
    await (_db.delete(_db.entityRecords)..where(
          (EntityRecords t) =>
              t.tenantId.equals(tenantId) &
              t.entity.equals(entity) &
              t.id.equals(id),
        ))
        .go();
  }

  Future<void> _deleteWhere(
    String tenantId,
    String entity,
    bool Function(EntityRecord) test,
  ) async {
    for (final EntityRecord r in await _rows(tenantId, entity)) {
      if (test(r)) {
        await _forget(tenantId, entity, r.id);
      }
    }
  }

  Future<void> _dropSession(String tenantId, String sessionId) async {
    await _forget(tenantId, countSessionEntity, sessionId);
    await _deleteWhere(
      tenantId,
      countLineEntity,
      (EntityRecord r) => _lineSession(r) == sessionId,
    );
    for (final CountEntry e in await _entries(tenantId, sessionId: sessionId)) {
      await _forget(tenantId, countEntryEntity, e.clientEntryId);
    }
  }

  // --- Transport helpers ----------------------------------------------------------------------------------------

  Future<Response<dynamic>> _guard(
    Future<Response<dynamic>> Function() call,
  ) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw mapCountError(e);
    }
  }

  static Map<String, dynamic> _map(Object? v) =>
      v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

  static List<dynamic> _list(Object? v) => v is List ? v : const <dynamic>[];
}

/// First readable message of a problem+json / Laravel validation answer.
String _problemMessage(Object? body) {
  if (body is! Map) {
    return '';
  }
  final Object? errors = body['errors'];
  if (errors is Map) {
    for (final Object? v in errors.values) {
      if (v is List && v.isNotEmpty) {
        return '${v.first}';
      }
    }
  }
  final Object? d = body['detail'] ?? body['message'] ?? body['title'];
  return d is String ? d : '';
}

/// Maps a transport error to a [CountException].
CountException mapCountError(DioException e) {
  final Response<dynamic>? r = e.response;
  if (r == null) {
    return const CountException(CountErrorKind.offline);
  }
  final String detail = _problemMessage(r.data);
  return switch (r.statusCode) {
    403 => CountException(CountErrorKind.forbidden, detail: detail),
    404 => CountException(CountErrorKind.notFound, detail: detail),
    422 => CountException(CountErrorKind.invalid, detail: detail),
    _ => CountException(CountErrorKind.unknown, detail: detail),
  };
}
