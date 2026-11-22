import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';

/// Entity name of the offline cache of the billing view in the generic entity store.
const String billingSnapshotEntity = 'project_billing_snapshot';

/// A cached JSON payload with the moment it was pulled.
class BillingStoredPayload {
  const BillingStoredPayload(this.json, this.syncedAt);

  final Map<String, dynamic> json;
  final DateTime syncedAt;
}

/// SQLite cache of the billing snapshot of each project (SAL certificates, retention, retainer, contract terms), scoped by
/// tenant. It lives in the generic entity store, so the view needs no schema of its own and works offline.
class ProjectBillingLocalDataSource {
  ProjectBillingLocalDataSource(this._db);

  final AppDatabase _db;

  Future<BillingStoredPayload?> snapshot(
    String tenantId,
    String projectId,
  ) async {
    final EntityRecord? row =
        await (_db.select(_db.entityRecords)..where(
              (EntityRecords t) =>
                  t.tenantId.equals(tenantId) &
                  t.entity.equals(billingSnapshotEntity) &
                  t.id.equals(projectId),
            ))
            .getSingleOrNull();
    if (row == null) {
      return null;
    }
    return BillingStoredPayload(
      Map<String, dynamic>.from(
        jsonDecode(row.payload) as Map<dynamic, dynamic>,
      ),
      row.updatedAt,
    );
  }

  /// Replaces the record in a single statement, so a reader sees the old or the new payload, never a mix.
  Future<void> saveSnapshot(
    String tenantId,
    String projectId,
    Map<String, dynamic> payload,
    DateTime syncedAt,
  ) => _db
      .into(_db.entityRecords)
      .insertOnConflictUpdate(
        EntityRecordsCompanion.insert(
          entity: billingSnapshotEntity,
          id: projectId,
          tenantId: tenantId,
          payload: jsonEncode(payload),
          syncStatus: SyncStatus.synced,
          localUpdatedAt: syncedAt,
          createdAt: syncedAt,
          updatedAt: syncedAt,
        ),
      );
}
