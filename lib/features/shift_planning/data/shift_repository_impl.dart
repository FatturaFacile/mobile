import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_engine.dart';
import '../domain/shift_models.dart';
import '../domain/shift_repository.dart';

/// Offline-queue entity of the claims of open shifts. Listed in [SyncEngine.defaultTerminalEntities].
const String shiftClaimEntity = 'shift_claims';

/// Local store entities of the cached lists.
const String shiftMyEntity = 'shift_my';
const String shiftTeamEntity = 'shift_team';
const String shiftOpenEntity = 'shift_open';
const String shiftSwapEntity = 'shift_swaps';

const String _base = '/shift-planning/my';

/// Maps a transport error to a [ShiftException]; the RFC 7807 `detail` and the compliance findings are kept.
ShiftException mapShiftError(DioException e) {
  final Response<dynamic>? r = e.response;
  if (r == null) {
    return const ShiftException(ShiftErrorKind.offline);
  }
  final dynamic body = r.data;
  String detail = '';
  List<ComplianceIssue> issues = const <ComplianceIssue>[];
  if (body is Map) {
    final dynamic d = body['detail'] ?? body['message'] ?? body['title'];
    detail = d is String ? d : '';
    final dynamic raw = body['invalid_params'];
    if (raw is List) {
      issues = <ComplianceIssue>[
        for (final dynamic i in raw)
          if (i is Map) ComplianceIssue.fromJson(Map<String, dynamic>.from(i)),
      ];
    }
  }
  return switch (r.statusCode) {
    403 => ShiftException(ShiftErrorKind.forbidden, detail: detail),
    404 => ShiftException(ShiftErrorKind.notFound, detail: detail),
    409 => ShiftException(ShiftErrorKind.conflict, detail: detail),
    422 => ShiftException(
      ShiftErrorKind.invalid,
      detail: detail,
      issues: issues,
    ),
    _ => ShiftException(ShiftErrorKind.unknown, detail: detail),
  };
}

class ShiftRepositoryImpl implements ShiftRepository {
  ShiftRepositoryImpl(this._db, this._dio, this._engine);

  final AppDatabase _db;
  final Dio _dio;
  final SyncEngine _engine;

  // --- Own shifts, team calendar, open shifts: read-through caches -----------------------------------------------

  @override
  Future<List<Shift>> cachedMyShifts(String tenantId) =>
      _cachedShifts(tenantId, shiftMyEntity);

  @override
  Future<List<Shift>> refreshMyShifts(
    String tenantId, {
    DateTime? from,
    DateTime? to,
  }) => _refreshShifts(tenantId, shiftMyEntity, '$_base/shifts', from, to);

  @override
  Future<List<Shift>> cachedTeamShifts(String tenantId) =>
      _cachedShifts(tenantId, shiftTeamEntity);

  @override
  Future<List<Shift>> refreshTeamShifts(
    String tenantId, {
    DateTime? from,
    DateTime? to,
  }) =>
      _refreshShifts(tenantId, shiftTeamEntity, '$_base/team-shifts', from, to);

  @override
  Future<List<Shift>> cachedOpenShifts(String tenantId) =>
      _cachedShifts(tenantId, shiftOpenEntity);

  @override
  Future<List<Shift>> refreshOpenShifts(
    String tenantId, {
    DateTime? from,
    DateTime? to,
  }) =>
      _refreshShifts(tenantId, shiftOpenEntity, '$_base/open-shifts', from, to);

  Future<List<Shift>> _cachedShifts(String tenantId, String entity) async {
    final List<Shift> items = <Shift>[
      for (final EntityRecord r in await _rows(tenantId, entity))
        Shift.fromJson(jsonDecode(r.payload) as Map<String, dynamic>),
    ];
    items.sort((Shift a, Shift b) => a.startAt.compareTo(b.startAt));
    return items;
  }

  Future<List<Shift>> _refreshShifts(
    String tenantId,
    String entity,
    String path,
    DateTime? from,
    DateTime? to,
  ) async {
    final DateTime start =
        from ?? DateTime.now().toUtc().subtract(const Duration(days: 7));
    final DateTime end = to ?? start.add(const Duration(days: 67));
    final Response<dynamic> res = await _guard(
      () => _dio.get<dynamic>(
        path,
        queryParameters: <String, dynamic>{
          'from': _day(start),
          'to': _day(end),
        },
      ),
    );
    final List<Shift> items = <Shift>[
      for (final dynamic raw in _list(_map(res.data)['data']))
        if (raw is Map) Shift.fromJson(Map<String, dynamic>.from(raw)),
    ];
    await _replace(tenantId, entity, <String, Map<String, dynamic>>{
      for (final Shift s in items) s.id: s.toJson(),
    });
    items.sort((Shift a, Shift b) => a.startAt.compareTo(b.startAt));
    return items;
  }

  // --- Claims: offline outbox, validated by the server when sent -------------------------------------------------

  @override
  Future<ClaimOutcome> claim(String tenantId, String shiftId) async {
    final String entityId = await _engine.enqueueCommand(
      tenantId: tenantId,
      entity: shiftClaimEntity,
      path: '$_base/open-shifts/$shiftId/claim',
    );
    try {
      await _engine.flush(tenantId);
    } catch (_) {
      // Whatever went wrong, the claim is safely queued and the next sync cycle resends it.
    }
    final QueueItem? item = await _find(tenantId, entityId);
    if (item == null) {
      await _forget(tenantId, shiftOpenEntity, shiftId);
      return const ClaimOutcome(ClaimStatus.claimed);
    }
    if (_refused(item)) {
      return ClaimOutcome(ClaimStatus.rejected, detail: item.lastError ?? '');
    }
    return const ClaimOutcome(ClaimStatus.queued);
  }

  @override
  Future<ClaimQueue> claimQueue(String tenantId) async {
    final List<QueueItem> rows = await _engine.queued(
      tenantId,
      shiftClaimEntity,
    );
    return ClaimQueue(
      waitingShiftIds: <String>{
        for (final QueueItem r in rows)
          if (!_refused(r)) _shiftIdOf(r.path),
      },
      rejected: <RejectedClaim>[
        for (final QueueItem r in rows)
          if (_refused(r))
            RejectedClaim(
              queueUuid: r.uuid,
              shiftId: _shiftIdOf(r.path),
              detail: r.lastError ?? '',
            ),
      ],
    );
  }

  @override
  Future<void> retryClaim(String tenantId, String queueUuid) async {
    await _engine.retry(queueUuid);
    await _engine.flush(tenantId);
  }

  @override
  Future<void> dismissClaim(String queueUuid) => _engine.discard(queueUuid);

  /// A 422/403 parks the claim as rejected; a 409 (somebody was faster) leaves it as a conflict: neither is resent.
  bool _refused(QueueItem item) =>
      item.state == QueueState.rejected || item.state == QueueState.conflict;

  /// The shift of a queued claim: `/shift-planning/my/open-shifts/{id}/claim`.
  static String _shiftIdOf(String path) {
    final List<String> parts = path.split('/');
    final int at = parts.indexOf('open-shifts');
    return at >= 0 && at + 1 < parts.length ? parts[at + 1] : '';
  }

  Future<QueueItem?> _find(String tenantId, String entityId) async {
    for (final QueueItem r in await _engine.queued(
      tenantId,
      shiftClaimEntity,
    )) {
      if (r.entityId == entityId) {
        return r;
      }
    }
    return null;
  }

  // --- Swaps: online-only, the server decides --------------------------------------------------------------------

  @override
  Future<List<SwapPeer>> eligiblePeers(String shiftId) async {
    final Response<dynamic> res = await _guard(
      () => _dio.get<dynamic>('$_base/shifts/$shiftId/eligible-peers'),
    );
    return <SwapPeer>[
      for (final dynamic raw in _list(_map(res.data)['data']))
        if (raw is Map) SwapPeer.fromJson(Map<String, dynamic>.from(raw)),
    ];
  }

  @override
  Future<SwapRequest> requestSwap(
    String shiftId, {
    String? peerEmployeeId,
    String? counterShiftId,
  }) async {
    final Response<dynamic> res = await _guard(
      () => _dio.post<dynamic>(
        '$_base/swaps',
        data: <String, dynamic>{
          'shift_assignment_id': shiftId,
          'target_peer_employee_id': ?peerEmployeeId,
          'target_shift_assignment_id': ?counterShiftId,
        },
      ),
    );
    return SwapRequest.fromJson(_map(_map(res.data)['data']));
  }

  @override
  Future<List<SwapRequest>> cachedSwaps(String tenantId) async => <SwapRequest>[
    for (final EntityRecord r in await _rows(tenantId, shiftSwapEntity))
      SwapRequest.fromJson(jsonDecode(r.payload) as Map<String, dynamic>),
  ];

  @override
  Future<List<SwapRequest>> refreshSwaps(String tenantId) async {
    final Response<dynamic> res = await _guard(
      () => _dio.get<dynamic>('$_base/swaps'),
    );
    final List<SwapRequest> items = <SwapRequest>[
      for (final dynamic raw in _list(_map(res.data)['data']))
        if (raw is Map) SwapRequest.fromJson(Map<String, dynamic>.from(raw)),
    ];
    await _replace(tenantId, shiftSwapEntity, <String, Map<String, dynamic>>{
      for (final SwapRequest s in items) s.id: s.toJson(),
    });
    return items;
  }

  @override
  Future<SwapRequest> respondToSwap(
    String swapId, {
    required bool accept,
  }) async {
    final Response<dynamic> res = await _guard(
      () => _dio.post<dynamic>(
        '$_base/swaps/$swapId/respond',
        data: <String, dynamic>{'decision': accept ? 'approve' : 'reject'},
      ),
    );
    return SwapRequest.fromJson(_map(_map(res.data)['data']));
  }

  // --- Local store -----------------------------------------------------------------------------------------------

  Future<List<EntityRecord>> _rows(String tenantId, String entity) {
    return (_db.select(_db.entityRecords)..where(
          (EntityRecords t) =>
              t.tenantId.equals(tenantId) & t.entity.equals(entity),
        ))
        .get();
  }

  Future<void> _replace(
    String tenantId,
    String entity,
    Map<String, Map<String, dynamic>> items,
  ) async {
    final DateTime now = DateTime.now().toUtc();
    await _db.transaction(() async {
      await (_db.delete(_db.entityRecords)..where(
            (EntityRecords t) =>
                t.tenantId.equals(tenantId) & t.entity.equals(entity),
          ))
          .go();
      for (final MapEntry<String, Map<String, dynamic>> e in items.entries) {
        await _db
            .into(_db.entityRecords)
            .insertOnConflictUpdate(
              EntityRecordsCompanion.insert(
                entity: entity,
                id: e.key,
                tenantId: tenantId,
                payload: jsonEncode(e.value),
                syncStatus: SyncStatus.synced,
                localUpdatedAt: now,
                createdAt: now,
                updatedAt: now,
              ),
            );
      }
    });
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

  Future<Response<dynamic>> _guard(
    Future<Response<dynamic>> Function() call,
  ) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw mapShiftError(e);
    }
  }

  static String _day(DateTime d) {
    final DateTime u = d.toUtc();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${u.year.toString().padLeft(4, '0')}-${two(u.month)}-${two(u.day)}';
  }

  static Map<String, dynamic> _map(Object? v) =>
      v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

  static List<dynamic> _list(Object? v) => v is List ? v : <dynamic>[];
}
