import 'package:drift/drift.dart';

import '../../features/manufacturing/data/local/manufacturing_dao.dart';
import '../../features/manufacturing/data/local/manufacturing_tables.dart';
import '../../features/purchase_requisitions/data/local/purchase_requisition_dao.dart';
import '../../features/purchase_requisitions/data/local/purchase_requisition_tables.dart';

part 'app_database.g.dart';

/// Lifecycle of a locally stored record.
enum SyncStatus {
  synced,
  pendingCreate,
  pendingUpdate,
  pendingDelete,
  conflict,
}

/// Generic tenant-scoped entity store; the JSON payload mirrors the API resource.
@DataClassName('EntityRecord')
class EntityRecords extends Table {
  TextColumn get entity => text()();
  TextColumn get id => text()();
  TextColumn get tenantId => text()();
  TextColumn get serverId => text().nullable()();
  TextColumn get payload => text()();
  IntColumn get syncStatus =>
      integer().map(const EnumIndexConverter<SyncStatus>(SyncStatus.values))();
  DateTimeColumn get localUpdatedAt => dateTime()();
  DateTimeColumn get serverUpdatedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get createdBy => text().nullable()();
  TextColumn get updatedBy => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{tenantId, entity, id};
}

/// Outbox of pending writes, flushed in sequence (FIFO) honouring dependencies.
@DataClassName('QueueItem')
class SyncQueue extends Table {
  IntColumn get sequence => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  TextColumn get tenantId => text()();
  TextColumn get entity => text()();
  TextColumn get entityId => text()();
  TextColumn get method => text()();
  TextColumn get path => text()();
  TextColumn get payload => text().nullable()();

  /// UUID of a queue row that must succeed first (e.g. parent invoice before its lines).
  TextColumn get dependsOn => text().nullable()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();

  /// 0 pending, 1 failed (retry later), 2 conflict.
  IntColumn get state => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
}

/// Delta-sync watermark per tenant and entity.
class SyncCursors extends Table {
  TextColumn get tenantId => text()();
  TextColumn get entity => text()();
  TextColumn get serverTime => text().nullable()();
  TextColumn get cursor => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{tenantId, entity};
}

/// Cached API translation dictionaries (empty tenant id = global).
class Translations extends Table {
  TextColumn get locale => text()();
  TextColumn get tenantId => text().withDefault(const Constant(''))();
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{locale, tenantId, key};
}

/// Recent Copilot conversations cached for offline reading (tenant scoped).
@DataClassName('CopilotConversationRow')
class CopilotConversations extends Table {
  TextColumn get tenantId => text()();
  TextColumn get id => text()();
  TextColumn get title => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{tenantId, id};
}

/// Copilot messages; `payload` holds the full API message resource as JSON.
@DataClassName('CopilotMessageRow')
class CopilotMessages extends Table {
  TextColumn get tenantId => text()();
  TextColumn get id => text()();
  TextColumn get conversationId => text()();
  TextColumn get role => text()();
  TextColumn get payload => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{tenantId, id};
}

/// Last Executive DSS read models pulled from the API for one filter, kept for offline reading (tenant scoped).
/// The payloads are the `data` objects of the API answers, stored as received.
@DataClassName('DssSnapshotRow')
class DssExecutiveSnapshots extends Table {
  TextColumn get tenantId => text()();

  /// Server legal entity id; empty for the snapshot that spans every legal entity.
  TextColumn get legalEntityId => text().withDefault(const Constant(''))();
  TextColumn get currency => text()();
  TextColumn get periodPreset => text()();
  TextColumn get comparisonBaseline => text()();
  TextColumn get overviewJson => text()();
  TextColumn get customersJson => text()();
  TextColumn get productsJson => text().nullable()();
  TextColumn get varianceJson => text().nullable()();
  TextColumn get inputsJson => text().nullable()();
  TextColumn get legalEntitiesJson => text().nullable()();
  DateTimeColumn get syncedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{
    tenantId,
    legalEntityId,
    currency,
    periodPreset,
    comparisonBaseline,
  };
}

/// Offline, hash-chained security audit queue (one chain per tenant).
///
/// The signed fields (sequence, hashes, payload, metadata) are immutable once written; only the
/// sync bookkeeping columns (`syncedAt`, `syncAttempts`, `lastError`, `serverReceipt`) ever change.
@DataClassName('AuditQueueRow')
class AuditQueueEntries extends Table {
  TextColumn get tenantId => text()();
  IntColumn get sequenceNumber => integer()();
  TextColumn get uuid => text().unique()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get action => text()();
  TextColumn get payloadJson => text()();
  TextColumn get metadataJson => text()();
  TextColumn get previousHash => text()();
  TextColumn get payloadHash => text()();
  TextColumn get recordHash => text()();
  DateTimeColumn get occurredAt => dateTime()();
  DateTimeColumn get syncedAt => dateTime().nullable()();
  IntColumn get syncAttempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  TextColumn get serverReceipt => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{
    tenantId,
    sequenceNumber,
  };
}

/// Cached permission snapshots, one per tenant, user and company (empty company id = whole tenant). The payload holds the
/// permissions and field policies only; a revoked row is never read back.
@DataClassName('PermissionSnapshotRow')
class PermissionSnapshots extends Table {
  TextColumn get tenantId => text()();
  TextColumn get userId => text()();
  TextColumn get companyId => text().withDefault(const Constant(''))();
  TextColumn get payload => text()();
  DateTimeColumn get fetchedAt => dateTime()();
  DateTimeColumn get revokedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{
    tenantId,
    userId,
    companyId,
  };
}

@DriftDatabase(
  tables: <Type>[
    EntityRecords,
    SyncQueue,
    SyncCursors,
    Translations,
    CopilotConversations,
    CopilotMessages,
    AuditQueueEntries,
    DssExecutiveSnapshots,
    PermissionSnapshots,
    LocalPurchaseRequisitions,
    LocalPurchaseRequisitionLines,
    LocalPendingApprovals,
    LocalApprovalAuditLogs,
    MfgLocalWorkCenters,
    MfgLocalMachines,
    MfgLocalRoutings,
    MfgLocalRoutingSteps,
    MfgLocalOeeSummaries,
  ],
  daos: <Type>[PurchaseRequisitionDao, ManufacturingDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 6;

  /// Two release lines used the same version numbers for different tables, so a device may be at version 2–4
  /// with either set. Every step creates its tables only when they are missing.
  Future<void> _ensureTable(Migrator m, TableInfo<Table, dynamic> table) async {
    final List<QueryRow> found = await customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
      variables: <Variable<Object>>[Variable<String>(table.actualTableName)],
    ).get();
    if (found.isEmpty) {
      await m.createTable(table);
    }
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) => m.createAll(),
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 5) {
        await _ensureTable(m, copilotConversations);
        await _ensureTable(m, copilotMessages);
        await _ensureTable(m, auditQueueEntries);
        await _ensureTable(m, dssExecutiveSnapshots);
        await _ensureTable(m, permissionSnapshots);
        await _ensureTable(m, localPurchaseRequisitions);
        await _ensureTable(m, localPurchaseRequisitionLines);
        await _ensureTable(m, localPendingApprovals);
        await _ensureTable(m, localApprovalAuditLogs);
      }
      if (from < 6) {
        await _ensureTable(m, mfgLocalWorkCenters);
        await _ensureTable(m, mfgLocalMachines);
        await _ensureTable(m, mfgLocalRoutings);
        await _ensureTable(m, mfgLocalRoutingSteps);
        await _ensureTable(m, mfgLocalOeeSummaries);
      }
    },
    beforeOpen: (OpeningDetails details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
