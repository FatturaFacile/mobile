import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';

/// Entity names of the offline cache of the profitability view in the generic entity store.
const String evmSnapshotEntity = 'project_evm_snapshot';
const String evmProjectIndexEntity = 'project_evm_index';
const String _indexId = 'projects';

/// A cached JSON payload with the moment it was pulled.
class EvmStoredPayload {
  const EvmStoredPayload(this.json, this.syncedAt);

  final Map<String, dynamic> json;
  final DateTime syncedAt;
}

/// SQLite cache of the profitability snapshots (one record per project) and of the project picker, scoped by tenant.
/// It lives in the generic entity store, so the view needs no schema of its own and works offline.
class ProjectEvmLocalDataSource {
  ProjectEvmLocalDataSource(this._db);

  final AppDatabase _db;

  Future<EvmStoredPayload?> snapshot(String tenantId, String projectId) =>
      _find(tenantId, evmSnapshotEntity, projectId);

  Future<void> saveSnapshot(
    String tenantId,
    String projectId,
    Map<String, dynamic> payload,
    DateTime syncedAt,
  ) => _save(tenantId, evmSnapshotEntity, projectId, payload, syncedAt);

  Future<EvmStoredPayload?> projectIndex(String tenantId) =>
      _find(tenantId, evmProjectIndexEntity, _indexId);

  Future<void> saveProjectIndex(
    String tenantId,
    List<dynamic> projects,
    DateTime syncedAt,
  ) => _save(tenantId, evmProjectIndexEntity, _indexId, <String, dynamic>{
    'projects': projects,
  }, syncedAt);

  Future<EvmStoredPayload?> _find(
    String tenantId,
    String entity,
    String id,
  ) async {
    final EntityRecord? row =
        await (_db.select(_db.entityRecords)..where(
              (EntityRecords t) =>
                  t.tenantId.equals(tenantId) &
                  t.entity.equals(entity) &
                  t.id.equals(id),
            ))
            .getSingleOrNull();
    if (row == null) {
      return null;
    }
    return EvmStoredPayload(
      Map<String, dynamic>.from(
        jsonDecode(row.payload) as Map<dynamic, dynamic>,
      ),
      row.updatedAt,
    );
  }

  /// Replaces the record in a single statement, so a reader sees the old or the new payload, never a mix.
  Future<void> _save(
    String tenantId,
    String entity,
    String id,
    Map<String, dynamic> payload,
    DateTime syncedAt,
  ) => _db
      .into(_db.entityRecords)
      .insertOnConflictUpdate(
        EntityRecordsCompanion.insert(
          entity: entity,
          id: id,
          tenantId: tenantId,
          payload: jsonEncode(payload),
          syncStatus: SyncStatus.synced,
          localUpdatedAt: syncedAt,
          createdAt: syncedAt,
          updatedAt: syncedAt,
        ),
      );
}
