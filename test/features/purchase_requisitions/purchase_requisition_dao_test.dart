import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:fattura_facile/core/database/app_database.dart';
import 'package:fattura_facile/features/purchase_requisitions/data/local/purchase_requisition_dao.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PurchaseRequisitionDao & SQLite migration v2 -> v3', () {
    test('upgrades existing v2 schema to v3 preserving existing rows and creating all 4 PR tables', () async {
      final AppDatabase migratedDb = AppDatabase(
        NativeDatabase.memory(
          setup: (dynamic rawDb) {
            rawDb.execute('''
              CREATE TABLE entity_records (
                entity TEXT NOT NULL,
                id TEXT NOT NULL,
                tenant_id TEXT NOT NULL,
                server_id TEXT,
                payload TEXT NOT NULL,
                sync_status INTEGER NOT NULL,
                local_updated_at INTEGER NOT NULL,
                server_updated_at INTEGER,
                created_at INTEGER NOT NULL,
                updated_at INTEGER NOT NULL,
                deleted_at INTEGER,
                created_by TEXT,
                updated_by TEXT,
                PRIMARY KEY (tenant_id, entity, id)
              );
              CREATE TABLE sync_queue (
                sequence INTEGER PRIMARY KEY AUTOINCREMENT,
                uuid TEXT NOT NULL UNIQUE,
                tenant_id TEXT NOT NULL,
                entity TEXT NOT NULL,
                entity_id TEXT NOT NULL,
                method TEXT NOT NULL,
                path TEXT NOT NULL,
                payload TEXT,
                depends_on TEXT,
                attempts INTEGER NOT NULL DEFAULT 0,
                last_error TEXT,
                state INTEGER NOT NULL DEFAULT 0,
                created_at INTEGER NOT NULL
              );
              CREATE TABLE sync_cursors (
                tenant_id TEXT NOT NULL,
                entity TEXT NOT NULL,
                server_time TEXT,
                cursor TEXT,
                PRIMARY KEY (tenant_id, entity)
              );
              CREATE TABLE translations (
                locale TEXT NOT NULL,
                tenant_id TEXT NOT NULL DEFAULT '',
                key TEXT NOT NULL,
                value TEXT NOT NULL,
                PRIMARY KEY (locale, tenant_id, key)
              );
              CREATE TABLE permission_snapshots (
                tenant_id TEXT NOT NULL,
                user_id TEXT NOT NULL,
                company_id TEXT NOT NULL DEFAULT '',
                payload TEXT NOT NULL,
                fetched_at INTEGER NOT NULL,
                revoked_at INTEGER,
                PRIMARY KEY (tenant_id, user_id, company_id)
              );
              INSERT INTO translations (locale, tenant_id, key, value)
              VALUES ('en', '', 'mobile.sync.online', 'Synced');
              PRAGMA user_version = 2;
            ''');
          },
        ),
      );
      addTearDown(migratedDb.close);

      final List<Translation> existingTranslations = await migratedDb
          .select(migratedDb.translations)
          .get();
      expect(existingTranslations, hasLength(1));
      expect(existingTranslations.single.value, 'Synced');

      final List<Map<String, Object?>> tables = await migratedDb
          .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
          .get()
          .then((rows) => rows.map((r) => r.data).toList());
      final Set<String> tableNames = tables
          .map((Map<String, Object?> r) => '${r['name']}')
          .toSet();
      expect(
        tableNames,
        containsAll(<String>[
          'local_purchase_requisitions',
          'local_purchase_requisition_lines',
          'local_pending_approvals',
          'local_approval_audit_logs',
        ]),
      );

      final DateTime now = DateTime.utc(2026, 11, 21, 10);
      await migratedDb.purchaseRequisitionDao.upsertRequisitionWithLines(
        LocalPurchaseRequisitionsCompanion.insert(
          localId: 'pr-mig-1',
          tenantId: 't1',
          requesterId: 'u1',
          requesterName: 'Anna',
          costCenterId: 'cc1',
          costCenterCode: 'CC-IT',
          costCenterName: 'IT Ops',
          createdAt: now,
          updatedAt: now,
        ),
        <LocalPurchaseRequisitionLinesCompanion>[
          LocalPurchaseRequisitionLinesCompanion.insert(
            localId: 'line-mig-1',
            tenantId: 't1',
            requisitionLocalId: 'pr-mig-1',
            lineNumber: 1,
            description: 'Workstation monitor',
            quantity: 2,
            unitPrice: 350,
            lineTotal: 700,
          ),
        ],
      );

      final LocalPurchaseRequisitionWithLines? loaded = await migratedDb
          .purchaseRequisitionDao
          .getRequisitionById('t1', 'pr-mig-1');
      expect(loaded, isNotNull);
      expect(loaded!.lines, hasLength(1));

      // Verify FK cascade delete on local_purchase_requisition_lines.
      await (migratedDb.delete(migratedDb.localPurchaseRequisitions)..where(
            ($LocalPurchaseRequisitionsTable t) => t.localId.equals('pr-mig-1'),
          ))
          .go();
      expect(
        await migratedDb.select(migratedDb.localPurchaseRequisitionLines).get(),
        isEmpty,
      );
    });

    late AppDatabase db;
    late PurchaseRequisitionDao dao;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      dao = db.purchaseRequisitionDao;
    });

    tearDown(() => db.close());

    test('CRUD, tenant isolation, sync transitions and pending upload preservation', () async {
      final DateTime now = DateTime.utc(2026, 11, 21, 12);

      await dao.upsertRequisitionWithLines(
        LocalPurchaseRequisitionsCompanion.insert(
          localId: 'pr-local-1',
          tenantId: 't1',
          requesterId: 'u1',
          requesterName: 'Anna',
          costCenterId: 'cc1',
          costCenterCode: 'CC-01',
          costCenterName: 'Operations',
          currency: const Value<String>('CHF'),
          totalAmount: const Value<double>(1200),
          status: const Value<String>('draft'),
          syncStatus: const Value<String>('pending_upload'),
          createdAt: now,
          updatedAt: now,
        ),
        <LocalPurchaseRequisitionLinesCompanion>[
          LocalPurchaseRequisitionLinesCompanion.insert(
            localId: 'l1',
            tenantId: 't1',
            requisitionLocalId: 'pr-local-1',
            lineNumber: 1,
            itemType: const Value<String>('catalog_item'),
            catalogItemId: const Value<String?>('prod-1'),
            catalogSku: const Value<String?>('SKU-100'),
            description: 'Safety Helmet',
            quantity: 10,
            unitPrice: 120,
            lineTotal: 1200,
          ),
        ],
      );

      await dao.upsertRequisitionWithLines(
        LocalPurchaseRequisitionsCompanion.insert(
          localId: 'pr-t2',
          tenantId: 't2',
          requesterId: 'u2',
          requesterName: 'Marco',
          costCenterId: 'cc2',
          costCenterCode: 'CC-02',
          costCenterName: 'Warehouse',
          createdAt: now,
          updatedAt: now,
        ),
        const <LocalPurchaseRequisitionLinesCompanion>[],
      );

      final List<LocalPurchaseRequisitionWithLines> t1List = await dao
          .watchMyRequisitions('t1')
          .first;
      expect(t1List, hasLength(1));
      expect(t1List.single.header.localId, 'pr-local-1');
      expect(t1List.single.lines.single.catalogSku, 'SKU-100');

      final List<LocalPurchaseRequisitionWithLines> t2List = await dao
          .watchMyRequisitions('t2')
          .first;
      expect(t2List, hasLength(1));
      expect(t2List.single.header.localId, 'pr-t2');

      // Server merge must preserve pending_upload local edits.
      await dao.upsertServerRequisitions('t1', <ServerRequisitionWrite>[
        ServerRequisitionWrite(
          header: LocalPurchaseRequisitionsCompanion.insert(
            localId: 'pr-local-1',
            remoteId: const Value<String?>('srv-1'),
            tenantId: 't1',
            requisitionNumber: const Value<String?>('RDA-2026-001'),
            requesterId: 'u1',
            requesterName: 'Anna',
            costCenterId: 'cc1',
            costCenterCode: 'CC-01',
            costCenterName: 'Old Server Value',
            createdAt: now,
            updatedAt: now,
          ),
          lines: const <LocalPurchaseRequisitionLinesCompanion>[],
        ),
      ]);
      final LocalPurchaseRequisitionWithLines? preserved = await dao
          .getRequisitionById('t1', 'pr-local-1');
      expect(preserved!.header.costCenterName, 'Operations');
      expect(preserved.header.syncStatus, 'pending_upload');

      // Transition to synced and verify getPendingUploadRequisitions clears.
      await dao.updateSyncState(
        tenantId: 't1',
        localId: 'pr-local-1',
        remoteId: 'srv-1',
        requisitionNumber: 'RDA-2026-001',
        status: 'pending_approval',
        syncStatus: 'synced',
        clearSyncError: true,
        pendingSubmit: false,
      );
      expect(await dao.getPendingUploadRequisitions('t1'), isEmpty);

      final LocalPurchaseRequisitionWithLines? byRemote = await dao
          .getRequisitionById('t1', 'srv-1');
      expect(byRemote!.header.localId, 'pr-local-1');
      expect(byRemote.header.requisitionNumber, 'RDA-2026-001');
    });

    test('pending approvals preserve queued offline decisions and update sync counters', () async {
      final DateTime now = DateTime.utc(2026, 11, 21, 13);
      await dao.replacePendingApprovals('t1', <LocalPendingApprovalsCompanion>[
        LocalPendingApprovalsCompanion.insert(
          approvalId: 'app-1',
          tenantId: 't1',
          requisitionRemoteId: 'pr-1',
          requisitionNumber: 'RDA-001',
          requesterName: 'Luca',
          costCenterCode: 'CC-10',
          costCenterName: 'Plant A',
          totalAmount: 500,
          requestedAt: now,
          updatedAt: now,
        ),
        LocalPendingApprovalsCompanion.insert(
          approvalId: 'app-2',
          tenantId: 't1',
          requisitionRemoteId: 'pr-2',
          requisitionNumber: 'RDA-002',
          requesterName: 'Sara',
          costCenterCode: 'CC-20',
          costCenterName: 'Logistics',
          totalAmount: 900,
          requestedAt: now,
          updatedAt: now,
        ),
      ]);

      expect(await dao.watchPendingApprovalCount('t1').first, 2);

      // Queue an offline rejection for app-1.
      await dao.markLocalApprovalDecision(
        tenantId: 't1',
        requisitionRemoteId: 'pr-1',
        approvalId: 'app-1',
        decision: 'reject',
        rejectionReason: 'Too expensive',
        syncStatus: 'pending_upload',
      );

      expect(await dao.watchPendingApprovalCount('t1').first, 1);
      final ({int pending, int failed}) syncCounts = await dao
          .watchPendingSyncCounts('t1')
          .first;
      expect(syncCounts.pending, 1);
      expect(syncCounts.failed, 0);

      // Server refresh keeps queued offline decision intact and updates remaining items.
      await dao.replacePendingApprovals('t1', <LocalPendingApprovalsCompanion>[
        LocalPendingApprovalsCompanion.insert(
          approvalId: 'app-1',
          tenantId: 't1',
          requisitionRemoteId: 'pr-1',
          requisitionNumber: 'RDA-001',
          requesterName: 'Luca',
          costCenterCode: 'CC-10',
          costCenterName: 'Plant A',
          totalAmount: 500,
          requestedAt: now,
          updatedAt: now,
        ),
        LocalPendingApprovalsCompanion.insert(
          approvalId: 'app-3',
          tenantId: 't1',
          requisitionRemoteId: 'pr-3',
          requisitionNumber: 'RDA-003',
          requesterName: 'Elena',
          costCenterCode: 'CC-30',
          costCenterName: 'R&D',
          totalAmount: 250,
          requestedAt: now,
          updatedAt: now,
        ),
      ]);

      final List<LocalPendingApprovalRow> queued = await dao
          .getPendingOfflineDecisions('t1');
      expect(queued, hasLength(1));
      expect(queued.single.pendingRejectionReason, 'Too expensive');
      final List<LocalPendingApprovalRow> visibleApprovals = await dao
          .watchPendingApprovals('t1')
          .first;
      expect(
        visibleApprovals.map((LocalPendingApprovalRow r) => r.approvalId),
        <String>['app-3'],
      );
    });
  });
}
