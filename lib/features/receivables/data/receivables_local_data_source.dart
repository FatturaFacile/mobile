import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';

/// Local store entity of the cached read models (dashboard, aging, credit position, statement...), one row per key.
const String receivablesSnapshotEntity = 'receivables_snapshot';

/// Local store entity of the open items, one row per receivable item.
const String receivableItemEntity = 'receivable_items';

/// A cached server answer and the time it was stored.
class StoredSnapshot {
  const StoredSnapshot(this.json, this.syncedAt);

  final Map<String, dynamic> json;
  final DateTime syncedAt;
}

/// Tenant-scoped SQLite access of the receivables screens. Everything is kept as the JSON the API sent in the shared
/// `entity_records` table, so a schema change is never needed and the UI reads only from the device.
class ReceivablesLocalDataSource {
  ReceivablesLocalDataSource(this._db);

  final AppDatabase _db;

  // --- Snapshots -------------------------------------------------------------------------------------------------

  Future<StoredSnapshot?> snapshot(String tenantId, String key) async {
    final EntityRecord? r = await _row(
      tenantId,
      receivablesSnapshotEntity,
      key,
    );
    if (r == null) {
      return null;
    }
    return StoredSnapshot(_decode(r.payload), r.updatedAt);
  }

  Future<void> saveSnapshot(
    String tenantId,
    String key,
    Map<String, dynamic> json,
  ) => _put(tenantId, receivablesSnapshotEntity, key, json);

  // --- Items -----------------------------------------------------------------------------------------------------

  /// Every cached item of the tenant.
  Future<List<Map<String, dynamic>>> allItems(String tenantId) async {
    final List<EntityRecord> rows =
        await (_db.select(_db.entityRecords)..where(
              (EntityRecords t) =>
                  t.tenantId.equals(tenantId) &
                  t.entity.equals(receivableItemEntity),
            ))
            .get();
    return <Map<String, dynamic>>[
      for (final EntityRecord r in rows) _decode(r.payload),
    ];
  }

  /// Cached items of one customer, in no particular order.
  Future<List<Map<String, dynamic>>> items(
    String tenantId,
    String customerId,
  ) async => <Map<String, dynamic>>[
    for (final Map<String, dynamic> raw in await allItems(tenantId))
      if ('${raw['customer_id']}' == customerId) raw,
  ];

  Future<Map<String, dynamic>?> item(String tenantId, String id) async {
    final EntityRecord? r = await _row(tenantId, receivableItemEntity, id);
    return r == null ? null : _decode(r.payload);
  }

  Future<void> putItem(String tenantId, Map<String, dynamic> item) =>
      _put(tenantId, receivableItemEntity, '${item['id']}', item);

  /// Replaces the cached items of [customerId] with [fresh] in one transaction.
  Future<void> replaceItems(
    String tenantId,
    String customerId,
    List<Map<String, dynamic>> fresh,
  ) async {
    await _db.transaction(() async {
      for (final Map<String, dynamic> old in await items(
        tenantId,
        customerId,
      )) {
        await (_db.delete(_db.entityRecords)..where(
              (EntityRecords t) =>
                  t.tenantId.equals(tenantId) &
                  t.entity.equals(receivableItemEntity) &
                  t.id.equals('${old['id']}'),
            ))
            .go();
      }
      for (final Map<String, dynamic> item in fresh) {
        await putItem(tenantId, item);
      }
    });
  }

  // --- Plumbing --------------------------------------------------------------------------------------------------

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

  static Map<String, dynamic> _decode(String payload) {
    final Object? v = jsonDecode(payload);
    return v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
  }
}
