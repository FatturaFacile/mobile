import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_engine.dart';
import '../domain/helpdesk_models.dart';
import '../domain/helpdesk_repository.dart';

/// Offline-queue entities. Both are listed in [SyncEngine.defaultTerminalEntities]: a 422/403 (closed or merged ticket)
/// parks the row as rejected instead of resending it forever.
const String helpdeskTimeEntity = 'helpdesk_time_entries';
const String helpdeskEscalationEntity = 'helpdesk_escalations';

/// Local store entities of the cached reads.
const String helpdeskQueueEntity = 'helpdesk_queue';
const String helpdeskContextEntity = 'helpdesk_context';
const String helpdeskTimeCacheEntity = 'helpdesk_time_cache';

const String _base = '/esm';

/// Maps a transport error to a [HelpdeskException]; the RFC 7807 `detail` is kept.
HelpdeskException mapHelpdeskError(DioException e) {
  final Response<dynamic>? r = e.response;
  if (r == null) {
    return const HelpdeskException(HelpdeskErrorKind.offline);
  }
  final dynamic body = r.data;
  String detail = '';
  if (body is Map) {
    final dynamic d = body['detail'] ?? body['message'] ?? body['title'];
    detail = d is String ? d : '';
  }
  return switch (r.statusCode) {
    403 => HelpdeskException(HelpdeskErrorKind.forbidden, detail: detail),
    404 => HelpdeskException(HelpdeskErrorKind.notFound, detail: detail),
    422 => HelpdeskException(HelpdeskErrorKind.invalid, detail: detail),
    _ => HelpdeskException(HelpdeskErrorKind.unknown, detail: detail),
  };
}

class HelpdeskRepositoryImpl implements HelpdeskRepository {
  HelpdeskRepositoryImpl(this._db, this._dio, this._engine);

  final AppDatabase _db;
  final Dio _dio;
  final SyncEngine _engine;

  // --- Queue -----------------------------------------------------------------------------------------------------

  @override
  Future<List<QueueTicket>> cachedQueue(String tenantId) async =>
      sortQueue(<QueueTicket>[
        for (final EntityRecord r in await _rows(tenantId, helpdeskQueueEntity))
          QueueTicket.fromJson(jsonDecode(r.payload) as Map<String, dynamic>),
      ]);

  @override
  Future<List<QueueTicket>> refreshQueue(
    String tenantId, {
    int riskPercent = 75,
    int limit = 100,
  }) async {
    final Response<dynamic> list = await _guard(
      () => _dio.get<dynamic>(
        '$_base/tickets',
        queryParameters: <String, dynamic>{'per_page': limit},
      ),
    );
    final Response<dynamic> risk = await _guard(
      () => _dio.get<dynamic>(
        '$_base/helpdesk/breach-risk',
        queryParameters: <String, dynamic>{
          'risk_percent': riskPercent,
          'limit': limit,
        },
      ),
    );
    final List<QueueTicket> merged = mergeQueue(
      _tickets(list.data),
      _tickets(risk.data),
    );
    await _replace(
      tenantId,
      helpdeskQueueEntity,
      <String, Map<String, dynamic>>{
        for (final QueueTicket t in merged) t.id: t.toJson(),
      },
    );
    return merged;
  }

  @override
  Future<QueueTicket?> cachedTicket(String tenantId, String ticketId) async {
    final EntityRecord? r = await _row(tenantId, helpdeskQueueEntity, ticketId);
    return r == null
        ? null
        : QueueTicket.fromJson(jsonDecode(r.payload) as Map<String, dynamic>);
  }

  // --- Ticket detail ---------------------------------------------------------------------------------------------

  @override
  Future<CustomerContext?> cachedContext(
    String tenantId,
    String ticketId,
  ) async {
    final EntityRecord? r = await _row(
      tenantId,
      helpdeskContextEntity,
      ticketId,
    );
    return r == null
        ? null
        : CustomerContext.fromJson(
            jsonDecode(r.payload) as Map<String, dynamic>,
          );
  }

  @override
  Future<CustomerContext> refreshContext(
    String tenantId,
    String ticketId,
  ) async {
    final Response<dynamic> res = await _guard(
      () => _dio.get<dynamic>('$_base/tickets/$ticketId/customer-context'),
    );
    final Map<String, dynamic> data = _map(_map(res.data)['data']);
    await _put(tenantId, helpdeskContextEntity, ticketId, data);
    return CustomerContext.fromJson(data);
  }

  @override
  Future<List<TimeEntry>> cachedTimeEntries(
    String tenantId,
    String ticketId,
  ) async {
    final EntityRecord? r = await _row(
      tenantId,
      helpdeskTimeCacheEntity,
      ticketId,
    );
    if (r == null) {
      return const <TimeEntry>[];
    }
    return _entries((jsonDecode(r.payload) as Map<String, dynamic>)['items']);
  }

  @override
  Future<List<TimeEntry>> refreshTimeEntries(
    String tenantId,
    String ticketId,
  ) async {
    final Response<dynamic> res = await _guard(
      () => _dio.get<dynamic>('$_base/tickets/$ticketId/time-entries'),
    );
    final List<TimeEntry> items = _entries(_map(res.data)['data']);
    await _put(tenantId, helpdeskTimeCacheEntity, ticketId, <String, dynamic>{
      'items': <Map<String, dynamic>>[
        for (final TimeEntry e in items) e.toJson(),
      ],
    });
    return items;
  }

  // --- Outbox ----------------------------------------------------------------------------------------------------

  @override
  Future<ActionOutcome> logTime(
    String tenantId,
    String ticketId, {
    required int minutes,
    String? technicianId,
    String? description,
    bool isBillable = true,
  }) {
    return _submit(
      tenantId,
      helpdeskTimeEntity,
      '$_base/tickets/$ticketId/time-entries',
      <String, dynamic>{
        'minutes': minutes,
        'technician_id': ?technicianId,
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
        'is_billable': isBillable,
      },
    );
  }

  @override
  Future<ActionOutcome> escalate(
    String tenantId,
    String ticketId,
    EscalationTarget target,
  ) async {
    final String path =
        '$_base/tickets/$ticketId/escalate/${target.pathSegment}';
    for (final QueueItem r in await _engine.queued(
      tenantId,
      helpdeskEscalationEntity,
    )) {
      if (r.path == path && !_refused(r)) {
        // Already waiting: a second tap must not queue a second request.
        return const ActionOutcome(ActionStatus.queued);
      }
    }
    return _submit(tenantId, helpdeskEscalationEntity, path, null);
  }

  Future<ActionOutcome> _submit(
    String tenantId,
    String entity,
    String path,
    Map<String, dynamic>? data,
  ) async {
    final String entityId = await _engine.enqueueCommand(
      tenantId: tenantId,
      entity: entity,
      path: path,
      data: data,
    );
    try {
      await _engine.flush(tenantId);
    } catch (_) {
      // Whatever went wrong, the action is safely queued and the next sync cycle resends it.
    }
    for (final QueueItem r in await _engine.queued(tenantId, entity)) {
      if (r.entityId == entityId) {
        return _refused(r)
            ? ActionOutcome(ActionStatus.rejected, detail: r.lastError ?? '')
            : const ActionOutcome(ActionStatus.queued);
      }
    }
    return const ActionOutcome(ActionStatus.sent);
  }

  @override
  Future<List<PendingAction>> pendingActions(
    String tenantId, {
    String? ticketId,
  }) async {
    final List<PendingAction> out = <PendingAction>[];
    for (final String entity in <String>[
      helpdeskTimeEntity,
      helpdeskEscalationEntity,
    ]) {
      for (final QueueItem r in await _engine.queued(tenantId, entity)) {
        final PendingAction? a = _toPending(r);
        if (a != null && (ticketId == null || a.ticketId == ticketId)) {
          out.add(a);
        }
      }
    }
    return out;
  }

  @override
  Future<void> retryAction(String tenantId, String queueUuid) async {
    await _engine.retry(queueUuid);
    await _engine.flush(tenantId);
  }

  @override
  Future<void> dismissAction(String queueUuid) => _engine.discard(queueUuid);

  @override
  Future<int> flush(String tenantId) async =>
      (await _engine.flush(tenantId)).sent;

  bool _refused(QueueItem item) =>
      item.state == QueueState.rejected || item.state == QueueState.conflict;

  /// `/esm/tickets/{id}/time-entries` | `/esm/tickets/{id}/escalate/field-service` | `.../escalate/rma`.
  PendingAction? _toPending(QueueItem r) {
    final List<String> parts = r.path.split('/');
    final int at = parts.indexOf('tickets');
    if (at < 0 || at + 2 >= parts.length) {
      return null;
    }
    final PendingActionKind kind = switch (parts.last) {
      'time-entries' => PendingActionKind.timeEntry,
      'field-service' => PendingActionKind.fieldService,
      'rma' => PendingActionKind.rma,
      _ => PendingActionKind.timeEntry,
    };
    int? minutes;
    if (r.payload != null) {
      final dynamic body = jsonDecode(r.payload!);
      if (body is Map && body['minutes'] is num) {
        minutes = (body['minutes'] as num).round();
      }
    }
    return PendingAction(
      queueUuid: r.uuid,
      ticketId: parts[at + 1],
      kind: kind,
      rejected: _refused(r),
      minutes: minutes,
      detail: r.lastError ?? '',
    );
  }

  // --- Parsing ---------------------------------------------------------------------------------------------------

  /// `data` is either the list itself or a paginator `{data: [...]}`.
  static List<QueueTicket> _tickets(Object? body) {
    Object? data = _map(body)['data'];
    if (data is Map) {
      data = data['data'];
    }
    return <QueueTicket>[
      if (data is List)
        for (final dynamic raw in data)
          if (raw is Map) QueueTicket.fromJson(Map<String, dynamic>.from(raw)),
    ];
  }

  static List<TimeEntry> _entries(Object? data) {
    Object? list = data;
    if (list is Map) {
      list = list['data'];
    }
    return <TimeEntry>[
      if (list is List)
        for (final dynamic raw in list)
          if (raw is Map) TimeEntry.fromJson(Map<String, dynamic>.from(raw)),
    ];
  }

  // --- Local store -----------------------------------------------------------------------------------------------

  Future<List<EntityRecord>> _rows(String tenantId, String entity) {
    return (_db.select(_db.entityRecords)..where(
          (EntityRecords t) =>
              t.tenantId.equals(tenantId) & t.entity.equals(entity),
        ))
        .get();
  }

  Future<EntityRecord?> _row(String tenantId, String entity, String id) {
    return (_db.select(_db.entityRecords)..where(
          (EntityRecords t) =>
              t.tenantId.equals(tenantId) &
              t.entity.equals(entity) &
              t.id.equals(id),
        ))
        .getSingleOrNull();
  }

  Future<void> _put(
    String tenantId,
    String entity,
    String id,
    Map<String, dynamic> payload,
  ) async {
    final DateTime now = DateTime.now().toUtc();
    await _db
        .into(_db.entityRecords)
        .insertOnConflictUpdate(
          EntityRecordsCompanion.insert(
            entity: entity,
            id: id,
            tenantId: tenantId,
            payload: jsonEncode(payload),
            syncStatus: SyncStatus.synced,
            localUpdatedAt: now,
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<void> _replace(
    String tenantId,
    String entity,
    Map<String, Map<String, dynamic>> items,
  ) async {
    await _db.transaction(() async {
      await (_db.delete(_db.entityRecords)..where(
            (EntityRecords t) =>
                t.tenantId.equals(tenantId) & t.entity.equals(entity),
          ))
          .go();
      for (final MapEntry<String, Map<String, dynamic>> e in items.entries) {
        await _put(tenantId, entity, e.key, e.value);
      }
    });
  }

  Future<Response<dynamic>> _guard(
    Future<Response<dynamic>> Function() call,
  ) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw mapHelpdeskError(e);
    }
  }

  static Map<String, dynamic> _map(Object? v) =>
      v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
}
