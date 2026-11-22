import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';

/// Entity names of the offline cache and queue of the analytical accounting module in the generic entity store.
const String analyticalSnapshotEntity = 'analytical_snapshot';
const String analyticalOperationEntity = 'analytical_operation';

/// The snapshot ids of the cached read models.
const String analyticalCentersId = 'centers';
const String analyticalRunsId = 'runs';
const String analyticalMarginId = 'margin';
const String analyticalComparisonId = 'comparison';

/// State of a queued entry, kept in its payload so the generic sync engine (which only pushes `pending*` rows) never touches it.
const String operationPending = 'pending';
const String operationSent = 'sent';
const String operationFailed = 'failed';

/// A cached JSON payload with the moment it was pulled.
class AnalyticalStoredPayload {
  const AnalyticalStoredPayload(this.data, this.syncedAt);

  final dynamic data;
  final DateTime syncedAt;
}

/// An entry captured offline and waiting for the web-api.
class PendingOperation {
  const PendingOperation(this.id, this.body);

  final String id;

  /// The JSON body of the `POST /analytical/entries` request.
  final String body;
}

/// SQLite cache of the analytical read models and the offline queue of manual entries, scoped by tenant. It lives in the generic
/// entity store, so the module needs no schema of its own and works offline.
class AnalyticalLocalDataSource {
  AnalyticalLocalDataSource(this._db);

  final AppDatabase _db;

  Future<AnalyticalStoredPayload?> snapshot(String tenantId, String id) async {
    final EntityRecord? row = await _row(tenantId, analyticalSnapshotEntity, id);
    if (row == null) {
      return null;
    }
    final Map<dynamic, dynamic> wrapper =
        jsonDecode(row.payload) as Map<dynamic, dynamic>;
    return AnalyticalStoredPayload(wrapper['data'], row.updatedAt);
  }

  /// Replaces the snapshot in a single statement, so a reader sees the old or the new payload, never a mix.
  Future<void> saveSnapshot(
    String tenantId,
    String id,
    dynamic data,
    DateTime syncedAt,
  ) => _put(
    tenantId,
    analyticalSnapshotEntity,
    id,
    <String, dynamic>{'data': data},
    syncedAt,
  );

  Future<void> enqueue(
    String tenantId,
    String id,
    String body,
    DateTime now,
  ) => _put(tenantId, analyticalOperationEntity, id, <String, dynamic>{
    'status': operationPending,
    'body': body,
    'error': null,
  }, now);

  /// The entries still to be sent, oldest first.
  Future<List<PendingOperation>> pending(String tenantId) async {
    final List<EntityRecord> rows =
        await (_db.select(_db.entityRecords)
              ..where(
                (EntityRecords t) =>
                    t.tenantId.equals(tenantId) &
                    t.entity.equals(analyticalOperationEntity),
              )
              ..orderBy(<OrderingTerm Function(EntityRecords)>[
                (EntityRecords t) => OrderingTerm.asc(t.createdAt),
              ]))
            .get();
    return <PendingOperation>[
      for (final EntityRecord row in rows)
        if (_payload(row)['status'] == operationPending)
          PendingOperation(row.id, _payload(row)['body'] as String),
    ];
  }

  Future<int> pendingCount(String tenantId) async =>
      (await pending(tenantId)).length;

  Future<void> markSent(String tenantId, String id, DateTime now) =>
      _mark(tenantId, id, operationSent, null, now);

  Future<void> markFailed(
    String tenantId,
    String id,
    String reason,
    DateTime now,
  ) => _mark(tenantId, id, operationFailed, reason, now);

  Future<void> _mark(
    String tenantId,
    String id,
    String status,
    String? error,
    DateTime now,
  ) async {
    final EntityRecord? row = await _row(tenantId, analyticalOperationEntity, id);
    if (row == null) {
      return;
    }
    final Map<String, dynamic> payload = Map<String, dynamic>.from(
      _payload(row),
    )..addAll(<String, dynamic>{'status': status, 'error': error});
    await (_db.update(_db.entityRecords)..where(
          (EntityRecords t) =>
              t.tenantId.equals(tenantId) &
              t.entity.equals(analyticalOperationEntity) &
              t.id.equals(id),
        ))
        .write(
          EntityRecordsCompanion(
            payload: Value<String>(jsonEncode(payload)),
            updatedAt: Value<DateTime>(now),
            localUpdatedAt: Value<DateTime>(now),
          ),
        );
  }

  Map<dynamic, dynamic> _payload(EntityRecord row) =>
      jsonDecode(row.payload) as Map<dynamic, dynamic>;

  Future<EntityRecord?> _row(String tenantId, String entity, String id) =>
      (_db.select(_db.entityRecords)..where(
            (EntityRecords t) =>
                t.tenantId.equals(tenantId) &
                t.entity.equals(entity) &
                t.id.equals(id),
          ))
          .getSingleOrNull();

  Future<void> _put(
    String tenantId,
    String entity,
    String id,
    Map<String, dynamic> payload,
    DateTime now,
  ) => _db
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
