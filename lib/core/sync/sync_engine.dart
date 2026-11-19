import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../error/failure.dart';
import '../network/api_client.dart';

/// Queue row states.
abstract final class QueueState {
  static const int pending = 0;
  static const int failed = 1;
  static const int conflict = 2;
}

/// Result of one [SyncEngine.flush] run.
class FlushReport {
  const FlushReport({this.sent = 0, this.failed = 0, this.conflicts = 0, this.offline = false});

  final int sent;
  final int failed;
  final int conflicts;
  final bool offline;
}

/// Offline-first outbox + delta pull for one device. All data is tenant-scoped.
class SyncEngine {
  SyncEngine(this._db, this._dio, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final Dio _dio;
  final Uuid _uuid;

  /// Number of writes not yet acknowledged by the server for [tenantId].
  Stream<int> watchPending(String tenantId) {
    final Expression<bool> pending = _db.syncQueue.tenantId.equals(tenantId);
    return (_db.select(_db.syncQueue)..where((SyncQueue t) => pending)).watch().map((List<QueueItem> r) => r.length);
  }

  /// Creates a record locally (UUID v7 client id) and enqueues the POST.
  /// [dependsOn] is the queue uuid of a parent create that must reach the server first.
  Future<String> create({
    required String tenantId,
    required String entity,
    required String path,
    required Map<String, dynamic> data,
    String? userId,
    String? dependsOn,
  }) async {
    final String id = _uuid.v7();
    final DateTime now = DateTime.now().toUtc();
    final Map<String, dynamic> body = <String, dynamic>{...data, 'id': id};
    await _db.transaction(() async {
      await _db.into(_db.entityRecords).insert(
            EntityRecordsCompanion.insert(
              entity: entity,
              id: id,
              tenantId: tenantId,
              payload: jsonEncode(body),
              syncStatus: SyncStatus.pendingCreate,
              localUpdatedAt: now,
              createdAt: now,
              updatedAt: now,
              createdBy: Value<String?>(userId),
              updatedBy: Value<String?>(userId),
            ),
          );
      await _enqueue(tenantId, entity, id, 'POST', path, body, dependsOn);
    });
    return id;
  }

  /// Applies [changes] locally and enqueues the PUT (merged into a pending create when possible).
  Future<void> update({
    required String tenantId,
    required String entity,
    required String id,
    required String path,
    required Map<String, dynamic> changes,
    String? userId,
  }) async {
    await _db.transaction(() async {
      final EntityRecord? row = await _find(tenantId, entity, id);
      if (row == null) {
        return;
      }
      final Map<String, dynamic> merged = <String, dynamic>{
        ...(jsonDecode(row.payload) as Map<String, dynamic>),
        ...changes,
      };
      final SyncStatus next = row.syncStatus == SyncStatus.pendingCreate ? SyncStatus.pendingCreate : SyncStatus.pendingUpdate;
      await (_db.update(_db.entityRecords)..where((EntityRecords t) => _key(t, tenantId, entity, id))).write(
        EntityRecordsCompanion(
          payload: Value<String>(jsonEncode(merged)),
          syncStatus: Value<SyncStatus>(next),
          localUpdatedAt: Value<DateTime>(DateTime.now().toUtc()),
          updatedAt: Value<DateTime>(DateTime.now().toUtc()),
          updatedBy: Value<String?>(userId),
        ),
      );
      if (row.syncStatus == SyncStatus.pendingCreate) {
        // The create has not left the device: fold the change into its payload.
        await (_db.update(_db.syncQueue)
              ..where((SyncQueue q) => q.tenantId.equals(tenantId) & q.entityId.equals(id) & q.method.equals('POST')))
            .write(SyncQueueCompanion(payload: Value<String?>(jsonEncode(merged))));
      } else {
        await _enqueue(tenantId, entity, id, 'PUT', '$path/$id', changes, null);
      }
    });
  }

  /// Soft-deletes locally and enqueues the DELETE (or drops an unsent create entirely).
  Future<void> delete({
    required String tenantId,
    required String entity,
    required String id,
    required String path,
  }) async {
    await _db.transaction(() async {
      final EntityRecord? row = await _find(tenantId, entity, id);
      if (row == null) {
        return;
      }
      if (row.syncStatus == SyncStatus.pendingCreate) {
        await (_db.delete(_db.syncQueue)..where((SyncQueue q) => q.tenantId.equals(tenantId) & q.entityId.equals(id))).go();
        await (_db.delete(_db.entityRecords)..where((EntityRecords t) => _key(t, tenantId, entity, id))).go();
        return;
      }
      final DateTime now = DateTime.now().toUtc();
      await (_db.update(_db.entityRecords)..where((EntityRecords t) => _key(t, tenantId, entity, id))).write(
        EntityRecordsCompanion(
          syncStatus: const Value<SyncStatus>(SyncStatus.pendingDelete),
          deletedAt: Value<DateTime?>(now),
          localUpdatedAt: Value<DateTime>(now),
        ),
      );
      await _enqueue(tenantId, entity, id, 'DELETE', '$path/$id', null, null);
    });
  }

  /// Live, tenant-scoped, non-deleted records of [entity].
  Stream<List<EntityRecord>> watch(String tenantId, String entity) {
    return (_db.select(_db.entityRecords)
          ..where((EntityRecords t) => t.tenantId.equals(tenantId) & t.entity.equals(entity) & t.deletedAt.isNull()))
        .watch();
  }

  /// Sends queued writes in strict FIFO order. A row whose parent is still queued is skipped.
  Future<FlushReport> flush(String tenantId) async {
    int sent = 0;
    int failed = 0;
    int conflicts = 0;
    final List<QueueItem> items = await (_db.select(_db.syncQueue)
          ..where((SyncQueue q) => q.tenantId.equals(tenantId) & q.state.isIn(<int>[QueueState.pending, QueueState.failed]))
          ..orderBy(<OrderingTerm Function(SyncQueue)>[(SyncQueue q) => OrderingTerm.asc(q.sequence)]))
        .get();
    for (final QueueItem item in items) {
      if (item.dependsOn != null && await _stillQueued(item.dependsOn!)) {
        continue;
      }
      try {
        final Response<dynamic> res = await _dio.request<dynamic>(
          item.path,
          data: item.payload == null ? null : jsonDecode(item.payload!),
          options: Options(method: item.method, headers: <String, dynamic>{'Idempotency-Key': item.uuid}),
        );
        await _acknowledge(item, res.data);
        sent++;
      } on DioException catch (e) {
        final Failure f = mapDioError(e);
        if (f is NetworkFailure) {
          return FlushReport(sent: sent, failed: failed, conflicts: conflicts, offline: true);
        }
        if (f is UnauthorizedFailure) {
          return FlushReport(sent: sent, failed: failed, conflicts: conflicts);
        }
        final bool isConflict = f is ConflictFailure;
        await _markFailed(item, f.message, isConflict);
        isConflict ? conflicts++ : failed++;
      }
    }
    return FlushReport(sent: sent, failed: failed, conflicts: conflicts);
  }

  /// Pulls every page of `/mobile/sync/{entity}` since the stored watermark (server wins).
  Future<int> pull(String tenantId, String entity) async {
    final SyncCursor? cursorRow = await (_db.select(_db.syncCursors)
          ..where((SyncCursors t) => t.tenantId.equals(tenantId) & t.entity.equals(entity)))
        .getSingleOrNull();
    final String? since = cursorRow?.serverTime;
    String? cursor;
    String? serverTime;
    int count = 0;
    bool more = true;
    while (more) {
      final Response<dynamic> res = await _dio.get<dynamic>(
        '/mobile/sync/$entity',
        queryParameters: <String, dynamic>{
          'updated_since': ?since,
          'cursor': ?cursor,
        },
      );
      final Map<String, dynamic> data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      await _db.transaction(() async {
        for (final dynamic raw in data['data'] as List<dynamic>) {
          count += await _applyServerRecord(tenantId, entity, raw as Map<String, dynamic>) ? 1 : 0;
        }
        for (final dynamic id in (data['deleted'] as List<dynamic>? ?? <dynamic>[])) {
          await (_db.update(_db.entityRecords)..where((EntityRecords t) => _key(t, tenantId, entity, '$id') & t.syncStatus.equals(SyncStatus.synced.index)))
              .write(EntityRecordsCompanion(deletedAt: Value<DateTime?>(DateTime.now().toUtc())));
        }
      });
      more = data['has_more'] == true;
      cursor = data['next_cursor'] as String?;
      serverTime = data['server_time'] as String?;
    }
    await _db.into(_db.syncCursors).insertOnConflictUpdate(
          SyncCursorsCompanion.insert(tenantId: tenantId, entity: entity, serverTime: Value<String?>(serverTime)),
        );
    return count;
  }

  /// Server record wins unless the local copy has unsent edits (then it is flagged as conflict).
  Future<bool> _applyServerRecord(String tenantId, String entity, Map<String, dynamic> record) async {
    final String id = '${record['id']}';
    final EntityRecord? local = await _find(tenantId, entity, id);
    final DateTime now = DateTime.now().toUtc();
    final DateTime serverUpdated = DateTime.tryParse('${record['updated_at']}') ?? now;
    if (local != null && local.syncStatus != SyncStatus.synced) {
      await (_db.update(_db.entityRecords)..where((EntityRecords t) => _key(t, tenantId, entity, id)))
          .write(const EntityRecordsCompanion(syncStatus: Value<SyncStatus>(SyncStatus.conflict)));
      return false;
    }
    await _db.into(_db.entityRecords).insertOnConflictUpdate(
          EntityRecordsCompanion.insert(
            entity: entity,
            id: id,
            tenantId: tenantId,
            serverId: Value<String?>(id),
            payload: jsonEncode(record),
            syncStatus: SyncStatus.synced,
            localUpdatedAt: now,
            serverUpdatedAt: Value<DateTime?>(serverUpdated),
            createdAt: DateTime.tryParse('${record['created_at']}') ?? now,
            updatedAt: serverUpdated,
            deletedAt: Value<DateTime?>(DateTime.tryParse('${record['deleted_at']}')),
          ),
        );
    return true;
  }

  Future<void> _enqueue(String tenantId, String entity, String entityId, String method, String path, Map<String, dynamic>? body, String? dependsOn) async {
    await _db.into(_db.syncQueue).insert(
          SyncQueueCompanion.insert(
            uuid: _uuid.v4(),
            tenantId: tenantId,
            entity: entity,
            entityId: entityId,
            method: method,
            path: path,
            payload: Value<String?>(body == null ? null : jsonEncode(body)),
            dependsOn: Value<String?>(dependsOn),
            createdAt: DateTime.now().toUtc(),
          ),
        );
  }

  Future<void> _acknowledge(QueueItem item, dynamic responseBody) async {
    await _db.transaction(() async {
      await (_db.delete(_db.syncQueue)..where((SyncQueue q) => q.uuid.equals(item.uuid))).go();
      final bool remaining = await (_db.select(_db.syncQueue)..where((SyncQueue q) => q.entityId.equals(item.entityId) & q.tenantId.equals(item.tenantId))).get().then((List<QueueItem> r) => r.isNotEmpty);
      if (item.method == 'DELETE') {
        await (_db.delete(_db.entityRecords)..where((EntityRecords t) => _key(t, item.tenantId, item.entity, item.entityId))).go();
        return;
      }
      String? serverId;
      if (responseBody is Map && responseBody['data'] is Map && (responseBody['data'] as Map)['id'] != null) {
        serverId = '${(responseBody['data'] as Map)['id']}';
      }
      await (_db.update(_db.entityRecords)..where((EntityRecords t) => _key(t, item.tenantId, item.entity, item.entityId))).write(
        EntityRecordsCompanion(
          serverId: Value<String?>(serverId),
          syncStatus: remaining ? const Value<SyncStatus>.absent() : const Value<SyncStatus>(SyncStatus.synced),
          serverUpdatedAt: Value<DateTime?>(DateTime.now().toUtc()),
        ),
      );
    });
  }

  Future<void> _markFailed(QueueItem item, String message, bool conflict) async {
    await (_db.update(_db.syncQueue)..where((SyncQueue q) => q.uuid.equals(item.uuid))).write(
      SyncQueueCompanion(
        attempts: Value<int>(item.attempts + 1),
        lastError: Value<String?>(message),
        state: Value<int>(conflict ? QueueState.conflict : QueueState.failed),
      ),
    );
    if (conflict) {
      await (_db.update(_db.entityRecords)..where((EntityRecords t) => _key(t, item.tenantId, item.entity, item.entityId)))
          .write(const EntityRecordsCompanion(syncStatus: Value<SyncStatus>(SyncStatus.conflict)));
    }
  }

  Future<bool> _stillQueued(String uuid) async {
    final QueueItem? row = await (_db.select(_db.syncQueue)..where((SyncQueue q) => q.uuid.equals(uuid))).getSingleOrNull();
    return row != null;
  }

  Future<EntityRecord?> _find(String tenantId, String entity, String id) {
    return (_db.select(_db.entityRecords)..where((EntityRecords t) => _key(t, tenantId, entity, id))).getSingleOrNull();
  }

  Expression<bool> _key(EntityRecords t, String tenantId, String entity, String id) {
    return t.tenantId.equals(tenantId) & t.entity.equals(entity) & t.id.equals(id);
  }
}
