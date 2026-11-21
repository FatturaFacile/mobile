import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/dss_models.dart';

/// The raw JSON payloads of one cached snapshot.
class DssStoredPayload {
  const DssStoredPayload({
    required this.overviewJson,
    required this.customersJson,
    required this.syncedAt,
    this.productsJson,
    this.varianceJson,
    this.inputsJson,
    this.legalEntitiesJson,
  });

  final String overviewJson;
  final String customersJson;
  final String? productsJson;
  final String? varianceJson;
  final String? inputsJson;
  final String? legalEntitiesJson;
  final DateTime syncedAt;
}

/// SQLite cache of the Executive DSS snapshots, scoped by tenant, legal entity, currency, period and baseline.
class DssLocalDataSource {
  DssLocalDataSource(this._db);

  final AppDatabase _db;

  Future<DssStoredPayload?> find(String tenantId, DssFilter filter) async {
    final DssSnapshotRow? row =
        await (_db.select(_db.dssExecutiveSnapshots)..where(
              (DssExecutiveSnapshots t) =>
                  t.tenantId.equals(tenantId) &
                  t.legalEntityId.equals(filter.legalEntityId) &
                  t.currency.equals(filter.currency) &
                  t.periodPreset.equals(filter.periodPreset) &
                  t.comparisonBaseline.equals(filter.comparisonBaseline),
            ))
            .getSingleOrNull();
    if (row == null) {
      return null;
    }
    return DssStoredPayload(
      overviewJson: row.overviewJson,
      customersJson: row.customersJson,
      productsJson: row.productsJson,
      varianceJson: row.varianceJson,
      inputsJson: row.inputsJson,
      legalEntitiesJson: row.legalEntitiesJson,
      syncedAt: row.syncedAt,
    );
  }

  /// Replaces the snapshot of the filter in a single statement, so a reader sees the old or the new one, never a mix.
  Future<void> save(
    String tenantId,
    DssFilter filter,
    DssStoredPayload payload,
  ) => _db
      .into(_db.dssExecutiveSnapshots)
      .insertOnConflictUpdate(
        DssExecutiveSnapshotsCompanion.insert(
          tenantId: tenantId,
          legalEntityId: Value<String>(filter.legalEntityId),
          currency: filter.currency,
          periodPreset: filter.periodPreset,
          comparisonBaseline: filter.comparisonBaseline,
          overviewJson: payload.overviewJson,
          customersJson: payload.customersJson,
          productsJson: Value<String?>(payload.productsJson),
          varianceJson: Value<String?>(payload.varianceJson),
          inputsJson: Value<String?>(payload.inputsJson),
          legalEntitiesJson: Value<String?>(payload.legalEntitiesJson),
          syncedAt: payload.syncedAt,
        ),
      );

  Future<int> count(String tenantId) async {
    final List<DssSnapshotRow> rows = await (_db.select(
      _db.dssExecutiveSnapshots,
    )..where((DssExecutiveSnapshots t) => t.tenantId.equals(tenantId))).get();
    return rows.length;
  }
}
