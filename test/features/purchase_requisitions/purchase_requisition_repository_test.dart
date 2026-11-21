import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:fattura_facile/core/database/app_database.dart';
import 'package:fattura_facile/core/error/failure.dart';
import 'package:fattura_facile/core/sync/sync_engine.dart';
import 'package:fattura_facile/core/sync/sync_orchestrator.dart';
import 'package:fattura_facile/features/purchase_requisitions/data/remote/purchase_requisition_remote_data_source.dart';
import 'package:fattura_facile/features/purchase_requisitions/data/repositories/purchase_requisition_repository_impl.dart';
import 'package:fattura_facile/features/purchase_requisitions/domain/entities/approval_models.dart';
import 'package:fattura_facile/features/purchase_requisitions/domain/entities/budget_check.dart';
import 'package:fattura_facile/features/purchase_requisitions/domain/entities/purchase_requisition.dart';
import 'package:fattura_facile/features/purchase_requisitions/domain/repositories/purchase_requisition_repository.dart';
import 'package:fattura_facile/features/purchase_requisitions/domain/use_cases/decide_approval_use_case.dart';
import 'package:fattura_facile/features/purchase_requisitions/domain/use_cases/save_draft_pr_use_case.dart';
import 'package:fattura_facile/features/purchase_requisitions/domain/use_cases/submit_pr_use_case.dart';
import 'package:fattura_facile/features/purchase_requisitions/domain/use_cases/sync_purchase_requisitions_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../core/sync_engine_test.dart' show FakeAdapter, json;

PurchaseRequisition _samplePr({
  String localId = '',
  String tenantId = 't1',
  String justification = 'Urgent spare parts',
  double unitPrice = 100,
}) {
  final DateTime now = DateTime.utc(2026, 11, 21, 9);
  return PurchaseRequisition(
    localId: localId,
    tenantId: tenantId,
    requesterId: 'u1',
    requesterName: 'Anna Rossi',
    costCenterId: 'cc-1',
    costCenterCode: 'CC-OPS',
    costCenterName: 'Operations',
    urgency: PrUrgency.high,
    justification: justification,
    currency: PrCurrency.chf,
    totalAmount: unitPrice * 2,
    status: PrStatus.draft,
    syncStatus: PrSyncStatus.pendingUpload,
    pendingSubmit: false,
    lines: <PurchaseRequisitionLine>[
      PurchaseRequisitionLine(
        localId: '',
        lineNumber: 1,
        itemType: PrItemType.catalogItem,
        catalogItemId: 'prod-1',
        catalogSku: 'SKU-01',
        description: 'Hydraulic Valve',
        quantity: 2,
        unitPrice: unitPrice,
        uom: 'pz',
      ),
    ],
    approvalSteps: const <ApprovalLevelStep>[],
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late AppDatabase db;
  late FakeAdapter adapter;
  late PurchaseRequisitionRepositoryImpl repository;
  late SaveDraftPrUseCase saveDraftUseCase;
  late SubmitPrUseCase submitUseCase;
  late DecideApprovalUseCase decideUseCase;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    adapter = FakeAdapter(
      (RequestOptions o) => json(200, <String, dynamic>{'data': <dynamic>[]}),
    );
    final Dio dio = Dio(
      BaseOptions(
        baseUrl: 'http://x/api/v1',
        validateStatus: (int? s) => s != null && s < 300,
      ),
    )..httpClientAdapter = adapter;
    repository = PurchaseRequisitionRepositoryImpl(
      db,
      db.purchaseRequisitionDao,
      PurchaseRequisitionRemoteDataSource(dio),
    );
    saveDraftUseCase = SaveDraftPrUseCase(repository);
    submitUseCase = SubmitPrUseCase(repository);
    decideUseCase = DecideApprovalUseCase(repository);
  });

  tearDown(() async {
    repository.dispose();
    await db.close();
  });

  test('offline draft save persists locally with pending_upload and zero HTTP requests', () async {
    final Either<Failure, PurchaseRequisition> res = await saveDraftUseCase(
      _samplePr(),
      isOnline: false,
    );

    expect(res.isRight(), isTrue);
    final PurchaseRequisition saved = res.getOrElse(
      (_) => throw StateError('unexpected'),
    );
    expect(saved.status, PrStatus.draft);
    expect(saved.syncStatus, PrSyncStatus.pendingUpload);
    expect(adapter.calls, isEmpty);

    final List<PurchaseRequisition> localList = await repository
        .watchMyRequisitions('t1')
        .first;
    expect(localList, hasLength(1));
    expect(localList.single.localId, saved.localId);
    expect(localList.single.totalAmount, 200);
  });

  test('offline submission queues and syncs upon reconnection via SyncOrchestrator hook', () async {
    final Either<Failure, PurchaseRequisition> queuedRes = await submitUseCase(
      _samplePr(),
      isOnline: false,
    );
    final PurchaseRequisition queued = queuedRes.getOrElse(
      (_) => throw StateError('unexpected'),
    );
    expect(queued.pendingSubmit, isTrue);
    expect(queued.status, PrStatus.pendingApproval);
    expect(queued.syncStatus, PrSyncStatus.pendingUpload);
    expect(adapter.calls, isEmpty);

    final List<ApprovalAuditEntry> localLogs = await repository
        .watchAuditLogs('t1', queued.localId)
        .first;
    expect(localLogs, hasLength(1));
    expect(localLogs.single.isLocalPending, isTrue);
    expect(localLogs.single.action, ApprovalActionType.submitted);

    adapter.handler = (RequestOptions o) {
      if (o.method == 'POST' &&
          o.path == '/procurement/purchase-requisitions') {
        return json(201, <String, dynamic>{
          'data': <String, dynamic>{
            'id': 'srv-pr-1',
            'local_id': queued.localId,
            'requisition_number': 'RDA-2026-044',
            'status': 'draft',
            'cost_center_id': 'cc-1',
            'cost_center_code': 'CC-OPS',
            'cost_center_name': 'Operations',
            'currency': 'CHF',
            'total_amount': 200,
            'lines': <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 'srv-l-1',
                'line_number': 1,
                'item_type': 'catalog_item',
                'description': 'Hydraulic Valve',
                'quantity': 2,
                'unit_price': 100,
                'uom': 'pz',
              },
            ],
          },
        });
      }
      if (o.method == 'POST' &&
          o.path == '/procurement/purchase-requisitions/srv-pr-1/submit') {
        return json(200, <String, dynamic>{
          'data': <String, dynamic>{
            'id': 'srv-pr-1',
            'local_id': queued.localId,
            'requisition_number': 'RDA-2026-044',
            'status': 'pending_approval',
            'cost_center_id': 'cc-1',
            'cost_center_code': 'CC-OPS',
            'cost_center_name': 'Operations',
            'currency': 'CHF',
            'total_amount': 200,
            'audit_logs': <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 'audit-1',
                'level': 1,
                'action': 'submitted',
                'actor_name': 'Anna Rossi',
                'channel': 'mobile_app',
                'occurred_at': '2026-11-21T09:05:00Z',
              },
            ],
          },
        });
      }
      if (o.path == '/procurement/purchase-requisitions') {
        return json(200, <String, dynamic>{'data': <dynamic>[]});
      }
      if (o.path == '/procurement/purchase-requisitions/pending-approvals') {
        return json(200, <String, dynamic>{'data': <dynamic>[]});
      }
      return json(200, <String, dynamic>{'data': <dynamic>[]});
    };

    final List<PrSyncEvent> emitted = <PrSyncEvent>[];
    final sub = repository.syncEvents.listen(emitted.add);
    addTearDown(sub.cancel);

    final Dio syncDio = Dio(BaseOptions(baseUrl: 'http://x/api/v1'))
      ..httpClientAdapter = adapter;
    final SyncOrchestrator orchestrator = SyncOrchestrator(
      SyncEngine(db, syncDio),
      hooks: <SyncHook>[
        (String tenantId) =>
            SyncPurchaseRequisitionsUseCase(repository).call(tenantId),
      ],
    );
    await orchestrator.run('t1', const <String>[]);
    await Future<void>.delayed(Duration.zero);

    final RequestOptions createCall = adapter.calls.firstWhere(
      (RequestOptions c) =>
          c.path == '/procurement/purchase-requisitions' && c.method == 'POST',
    );
    final RequestOptions submitCall = adapter.calls.firstWhere(
      (RequestOptions c) =>
          c.path == '/procurement/purchase-requisitions/srv-pr-1/submit',
    );
    expect(createCall.headers['Idempotency-Key'], isNotEmpty);
    expect(submitCall.headers['Idempotency-Key'], isNotEmpty);

    final PurchaseRequisition? synced = await repository
        .watchRequisition('t1', 'srv-pr-1')
        .first;
    expect(synced, isNotNull);
    expect(synced!.syncStatus, PrSyncStatus.synced);
    expect(synced.status, PrStatus.pendingApproval);
    expect(synced.requisitionNumber, 'RDA-2026-044');
    expect(
      emitted.any((PrSyncEvent e) => e.kind == PrSyncEventKind.submitted),
      isTrue,
    );
  });

  test('reconnection submission blocked by 422 budget hard-block updates status to budget_exceeded', () async {
    final PurchaseRequisition queued = (await submitUseCase(
      _samplePr(unitPrice: 5000),
      isOnline: false,
    )).getOrElse((_) => throw StateError('fail'));

    adapter.handler = (RequestOptions o) {
      if (o.method == 'POST' &&
          o.path == '/procurement/purchase-requisitions') {
        return json(201, <String, dynamic>{
          'data': <String, dynamic>{
            'id': 'srv-pr-blk',
            'local_id': queued.localId,
            'requisition_number': 'RDA-2026-099',
            'status': 'draft',
            'cost_center_id': 'cc-1',
            'cost_center_code': 'CC-OPS',
            'cost_center_name': 'Operations',
            'currency': 'CHF',
            'total_amount': 10000,
          },
        });
      }
      if (o.method == 'POST' &&
          o.path == '/procurement/purchase-requisitions/srv-pr-blk/submit') {
        return json(422, <String, dynamic>{
          'code': 'budget_hard_block',
          'message': 'Budget exceeded by 2000 CHF',
          'budget_check': <String, dynamic>{
            'status': 'hard_block',
            'cost_center_id': 'cc-1',
            'cost_center_code': 'CC-OPS',
            'currency': 'CHF',
            'allocated_budget': 10000,
            'committed_amount': 2000,
            'spent_amount': 0,
            'available_budget': 8000,
            'requested_amount': 10000,
            'remaining_after_request': -2000,
            'utilization_percent': 120,
            'warning_threshold_percent': 85,
            'message': 'Budget exceeded by 2000 CHF',
          },
        });
      }
      return json(200, <String, dynamic>{'data': <dynamic>[]});
    };

    final List<PrSyncEvent> emitted = <PrSyncEvent>[];
    final sub = repository.syncEvents.listen(emitted.add);
    addTearDown(sub.cancel);

    final PrSyncSummary summary = await repository.syncAll('t1');
    await Future<void>.delayed(Duration.zero);

    expect(summary.budgetBlocked, 1);
    final PurchaseRequisition? blocked = await repository
        .watchRequisition('t1', 'srv-pr-blk')
        .first;
    expect(blocked!.status, PrStatus.budgetExceeded);
    expect(blocked.syncStatus, PrSyncStatus.syncError);
    expect(blocked.budgetCheck?.status, BudgetCheckStatus.hardBlock);
    expect(
      emitted.any((PrSyncEvent e) => e.kind == PrSyncEventKind.budgetBlocked),
      isTrue,
    );
  });

  test('online submit warns first and completes when acknowledgeBudgetWarning is true', () async {
    adapter.handler = (RequestOptions o) {
      if (o.path == '/procurement/purchase-requisitions/budget-preview') {
        return json(200, <String, dynamic>{
          'data': <String, dynamic>{
            'status': 'warning',
            'cost_center_id': 'cc-1',
            'cost_center_code': 'CC-OPS',
            'currency': 'CHF',
            'allocated_budget': 1000,
            'committed_amount': 700,
            'spent_amount': 0,
            'available_budget': 300,
            'requested_amount': 200,
            'remaining_after_request': 100,
            'utilization_percent': 90,
            'warning_threshold_percent': 85,
            'message': 'Near annual limit',
          },
        });
      }
      if (o.method == 'POST' &&
          o.path == '/procurement/purchase-requisitions') {
        return json(201, <String, dynamic>{
          'data': <String, dynamic>{
            'id': 'srv-warn-1',
            'status': 'draft',
            'cost_center_id': 'cc-1',
            'cost_center_code': 'CC-OPS',
            'cost_center_name': 'Operations',
          },
        });
      }
      if (o.method == 'POST' &&
          o.path == '/procurement/purchase-requisitions/srv-warn-1/submit') {
        return json(200, <String, dynamic>{
          'data': <String, dynamic>{
            'id': 'srv-warn-1',
            'requisition_number': 'RDA-WARN-1',
            'status': 'pending_approval',
            'cost_center_id': 'cc-1',
            'cost_center_code': 'CC-OPS',
            'cost_center_name': 'Operations',
          },
        });
      }
      return json(200, <String, dynamic>{'data': <dynamic>[]});
    };

    final PurchaseRequisition pr = _samplePr();
    final PurchaseRequisition firstPass = (await submitUseCase(
      pr,
      isOnline: true,
    )).getOrElse((_) => throw StateError('fail'));
    expect(firstPass.status, PrStatus.draft);
    expect(firstPass.budgetCheck?.status, BudgetCheckStatus.warning);
    expect(
      adapter.calls.where((RequestOptions c) => c.path.endsWith('/submit')),
      isEmpty,
    );

    final PurchaseRequisition secondPass = (await submitUseCase(
      firstPass,
      isOnline: true,
      acknowledgeBudgetWarning: true,
    )).getOrElse((_) => throw StateError('fail'));
    expect(secondPass.status, PrStatus.pendingApproval);
    expect(secondPass.syncStatus, PrSyncStatus.synced);
  });

  test('reject enforces mandatory reason and offline approval/rejection sync on reconnection', () async {
    final Either<Failure, void> blankReject = await decideUseCase.reject(
      tenantId: 't1',
      requisitionId: 'srv-1',
      actorId: 'mgr-1',
      actorName: 'Elena Manager',
      reason: '   ',
      isOnline: true,
    );
    expect(blankReject.isLeft(), isTrue);
    expect(blankReject.getLeft().toNullable(), isA<ValidationFailure>());
    expect(adapter.calls, isEmpty);

    // Offline approve + offline reject queue into SQLite without network calls.
    final Either<Failure, void> offApprove = await decideUseCase.approve(
      tenantId: 't1',
      requisitionId: 'srv-1',
      approvalId: 'app-1',
      actorId: 'mgr-1',
      actorName: 'Elena Manager',
      isOnline: false,
    );
    final Either<Failure, void> offReject = await decideUseCase.reject(
      tenantId: 't1',
      requisitionId: 'srv-2',
      approvalId: 'app-2',
      actorId: 'mgr-1',
      actorName: 'Elena Manager',
      reason: 'Missing vendor quote',
      isOnline: false,
    );
    expect(offApprove.isRight(), isTrue);
    expect(offReject.isRight(), isTrue);
    expect(adapter.calls, isEmpty);

    final List<ApprovalAuditEntry> offLogs = await repository
        .watchAuditLogs('t1', 'srv-2')
        .first;
    expect(offLogs.single.action, ApprovalActionType.rejected);
    expect(offLogs.single.comment, 'Missing vendor quote');
    expect(offLogs.single.isLocalPending, isTrue);

    adapter.handler = (RequestOptions o) {
      if (o.path == '/procurement/purchase-requisitions/srv-1/approve') {
        return json(200, <String, dynamic>{
          'data': <String, dynamic>{'status': 'approved'},
        });
      }
      if (o.path == '/procurement/purchase-requisitions/srv-2/reject') {
        return json(200, <String, dynamic>{
          'data': <String, dynamic>{'status': 'rejected'},
        });
      }
      return json(200, <String, dynamic>{'data': <dynamic>[]});
    };

    final PrSyncSummary summary = await repository.syncAll('t1');
    expect(summary.approvalsSynced, 2);
    expect(
      adapter.calls.where(
        (RequestOptions c) =>
            c.path == '/procurement/purchase-requisitions/srv-1/approve',
      ),
      hasLength(1),
    );
    final RequestOptions rejectCall = adapter.calls.firstWhere(
      (RequestOptions c) =>
          c.path == '/procurement/purchase-requisitions/srv-2/reject',
    );
    expect(
      (rejectCall.data as Map<String, dynamic>)['reason'],
      'Missing vendor quote',
    );
    expect(
      await db.purchaseRequisitionDao.getPendingOfflineDecisions('t1'),
      isEmpty,
    );
  });
}
