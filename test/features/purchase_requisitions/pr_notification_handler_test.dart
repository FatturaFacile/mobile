import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:fattura_facile/core/database/app_database.dart';
import 'package:fattura_facile/core/error/failure.dart';
import 'package:fattura_facile/design/ff_tokens.dart';
import 'package:fattura_facile/features/purchase_requisitions/data/remote/purchase_requisition_remote_data_source.dart';
import 'package:fattura_facile/features/purchase_requisitions/data/repositories/purchase_requisition_repository_impl.dart';
import 'package:fattura_facile/features/purchase_requisitions/domain/entities/approval_models.dart';
import 'package:fattura_facile/features/purchase_requisitions/domain/entities/budget_check.dart';
import 'package:fattura_facile/features/purchase_requisitions/domain/entities/pr_reference_models.dart';
import 'package:fattura_facile/features/purchase_requisitions/domain/entities/purchase_requisition.dart';
import 'package:fattura_facile/features/purchase_requisitions/domain/repositories/purchase_requisition_repository.dart';
import 'package:fattura_facile/features/purchase_requisitions/domain/use_cases/decide_approval_use_case.dart';
import 'package:fattura_facile/features/purchase_requisitions/notifications/pr_notification_handler.dart';
import 'package:fattura_facile/features/purchase_requisitions/notifications/pr_notification_payload.dart';
import 'package:fattura_facile/features/purchase_requisitions/presentation/providers/pr_providers.dart';
import 'package:fattura_facile/features/purchase_requisitions/presentation/screens/pr_detail_screen.dart';
import 'package:fattura_facile/features/purchase_requisitions/presentation/widgets/pr_reject_bottom_sheet.dart';
import 'package:fattura_facile/l10n/gen/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/sync_engine_test.dart' show FakeAdapter, json;

class _StubNavRepository implements PurchaseRequisitionRepository {
  @override
  Stream<PrSyncEvent> get syncEvents => const Stream<PrSyncEvent>.empty();

  @override
  Stream<List<PurchaseRequisition>> watchMyRequisitions(String tenantId) =>
      Stream<List<PurchaseRequisition>>.value(const <PurchaseRequisition>[]);

  @override
  Stream<PurchaseRequisition?> watchRequisition(String tenantId, String id) {
    final DateTime now = DateTime.utc(2026, 11, 21);
    return Stream<PurchaseRequisition?>.value(
      PurchaseRequisition(
        localId: id,
        remoteId: id,
        tenantId: tenantId,
        requisitionNumber: 'RDA-PUSH-1',
        requesterId: 'u1',
        requesterName: 'Luca',
        costCenterId: 'cc1',
        costCenterCode: 'CC-1',
        costCenterName: 'IT',
        urgency: PrUrgency.high,
        justification: 'Server upgrade',
        currency: PrCurrency.chf,
        totalAmount: 1500,
        status: PrStatus.pendingApproval,
        syncStatus: PrSyncStatus.synced,
        pendingSubmit: false,
        lines: const <PurchaseRequisitionLine>[],
        approvalSteps: const <ApprovalLevelStep>[],
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  @override
  Stream<List<PendingApprovalItem>> watchPendingApprovals(String tenantId) =>
      Stream<List<PendingApprovalItem>>.value(const <PendingApprovalItem>[]);

  @override
  Stream<int> watchPendingApprovalCount(String tenantId) =>
      Stream<int>.value(0);

  @override
  Stream<List<ApprovalAuditEntry>> watchAuditLogs(
    String tenantId,
    String requisitionId,
  ) => Stream<List<ApprovalAuditEntry>>.value(const <ApprovalAuditEntry>[]);

  @override
  Future<Either<Failure, PurchaseRequisition>> refreshRequisitionDetail(
    String tenantId,
    String id,
  ) async =>
      const Left<Failure, PurchaseRequisition>(NetworkFailure('offline'));

  @override
  Future<Either<Failure, void>> approveRequisition({
    required String tenantId,
    required String requisitionId,
    String? approvalId,
    required String actorId,
    required String actorName,
    String? comment,
    required bool isOnline,
  }) async => const Right<Failure, void>(null);

  @override
  Future<Either<Failure, void>> rejectRequisition({
    required String tenantId,
    required String requisitionId,
    String? approvalId,
    required String actorId,
    required String actorName,
    required String reason,
    required bool isOnline,
  }) async => const Right<Failure, void>(null);

  @override
  Future<Either<Failure, void>> executeOneClickAction({
    required String tenantId,
    required String requisitionId,
    String? approvalId,
    required String action,
    String? token,
    String? reason,
    required String actorId,
    required String actorName,
    required bool isOnline,
  }) async => const Right<Failure, void>(null);

  @override
  Future<Either<Failure, BudgetCheckResult>> previewBudget(
    BudgetPreviewRequest request,
  ) => throw UnimplementedError();

  @override
  Future<Either<Failure, PurchaseRequisition>> saveDraft(
    PurchaseRequisition draft, {
    required bool isOnline,
  }) => throw UnimplementedError();

  @override
  Future<Either<Failure, PurchaseRequisition>> submitRequisition(
    PurchaseRequisition requisition, {
    required bool isOnline,
    bool acknowledgeBudgetWarning = false,
  }) => throw UnimplementedError();

  @override
  Future<PrSyncSummary> syncAll(String tenantId) async => const PrSyncSummary();

  @override
  Future<List<CostCenterOption>> loadCostCenters(String tenantId) async =>
      const <CostCenterOption>[];

  @override
  Future<List<ProjectOption>> loadProjects(String tenantId) async =>
      const <ProjectOption>[];

  @override
  Future<List<CatalogItemOption>> searchCatalogItems(
    String tenantId,
    String query,
  ) async => const <CatalogItemOption>[];

  @override
  Future<CatalogItemOption?> findCatalogItemByBarcode(
    String tenantId,
    String code,
  ) async => null;
}

void main() {
  group('PrNotificationPayload parsing', () {
    test('parses custom scheme, https, and relative deep link URIs', () {
      final PrNotificationPayload? custom = PrNotificationPayload.tryParseUri(
        Uri.parse(
          'fatturafacile://procurement/purchase-requisitions/pr-101?approval_id=app-9&token=tok-xyz&action=approve',
        ),
      );
      expect(custom, isNotNull);
      expect(custom!.requisitionId, 'pr-101');
      expect(custom.approvalId, 'app-9');
      expect(custom.oneClickToken, 'tok-xyz');
      expect(custom.action, PrNotificationAction.approve);

      final PrNotificationPayload? https = PrNotificationPayload.tryParseUri(
        Uri.parse(
          'https://app.fatturafacile.eu/procurement/purchase-requisitions/pr-202?action=reject',
        ),
      );
      expect(https!.requisitionId, 'pr-202');
      expect(https.action, PrNotificationAction.reject);

      final PrNotificationPayload? relative = PrNotificationPayload.tryParseUri(
        Uri.parse('/procurement/purchase-requisitions/pr-303'),
      );
      expect(relative!.requisitionId, 'pr-303');
      expect(relative.action, PrNotificationAction.open);
    });
  });

  group('PrNotificationHandler execution', () {
    late AppDatabase db;
    late FakeAdapter adapter;
    late PurchaseRequisitionRepositoryImpl repo;
    late bool online;
    late PrNotificationHandler handler;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      online = true;
      adapter = FakeAdapter(
        (RequestOptions o) => json(200, <String, dynamic>{
          'data': <String, dynamic>{'status': 'approved'},
        }),
      );
      final Dio dio = Dio(BaseOptions(baseUrl: 'http://x/api/v1'))
        ..httpClientAdapter = adapter;
      repo = PurchaseRequisitionRepositoryImpl(
        db,
        db.purchaseRequisitionDao,
        PurchaseRequisitionRemoteDataSource(dio),
      );
      handler = PrNotificationHandler(
        DecideApprovalUseCase(repo),
        isOnline: () => online,
      );
    });

    tearDown(() async {
      repo.dispose();
      await db.close();
    });

    test('executes 1-tap approve via POST /one-click-action online and queues offline when disconnected', () async {
      final PrNotificationResult onlineRes = await handler.handlePayload(
        <String, dynamic>{
          'type': 'purchase_requisition_approval',
          'tenant_id': 't1',
          'requisition_id': 'pr-1',
          'approval_id': 'app-1',
          'one_click_token': 'sec-tok-1',
          'action': 'approve',
        },
        activeTenantId: 't1',
        actorId: 'mgr-1',
        actorName: 'Boss',
      );
      expect(onlineRes.outcome, PrNotificationOutcome.approvedOnline);
      expect(
        adapter.calls.single.path,
        '/procurement/purchase-requisitions/one-click-action',
      );
      final Map<String, dynamic> body =
          adapter.calls.single.data as Map<String, dynamic>;
      expect(body['action'], 'approve');
      expect(body['token'], 'sec-tok-1');
      expect(body['channel'], 'mobile_push');

      // Now offline: queues decision locally without dropping it.
      online = false;
      final PrNotificationResult offlineRes = await handler.handlePayload(
        <String, dynamic>{
          'type': 'purchase_requisition_approval',
          'tenant_id': 't1',
          'requisition_id': 'pr-2',
          'approval_id': 'app-2',
          'one_click_token': 'sec-tok-2',
          'action': 'approve',
        },
        activeTenantId: 't1',
        actorId: 'mgr-1',
        actorName: 'Boss',
      );
      expect(offlineRes.outcome, PrNotificationOutcome.approvedQueuedOffline);
      final queued = await db.purchaseRequisitionDao.getPendingOfflineDecisions(
        't1',
      );
      expect(queued, hasLength(1));
      expect(queued.single.requisitionRemoteId, 'pr-2');
      expect(queued.single.oneClickToken, 'sec-tok-2');
    });

    test('ignores payload targeted at a different tenant', () async {
      final PrNotificationResult res = await handler.handlePayload(
        <String, dynamic>{
          'type': 'purchase_requisition_approval',
          'tenant_id': 't-other',
          'requisition_id': 'pr-1',
          'action': 'approve',
        },
        activeTenantId: 't1',
        actorId: 'mgr-1',
        actorName: 'Boss',
      );
      expect(res.outcome, PrNotificationOutcome.ignored);
      expect(adapter.calls, isEmpty);
    });

    testWidgets(
      'deep link and reject-without-reason navigate directly to PrDetailScreen',
      (WidgetTester tester) async {
        final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();
        final _StubNavRepository stubRepo = _StubNavRepository();
        final PrNotificationHandler navHandler = PrNotificationHandler(
          DecideApprovalUseCase(stubRepo),
          isOnline: () => false,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              prRepositoryProvider.overrideWithValue(stubRepo),
              prIsOnlineProvider.overrideWithValue(false),
            ],
            child: MaterialApp(
              navigatorKey: navKey,
              theme: ffThemeData(),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: const Scaffold(body: Text('Home')),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final PrNotificationResult openRes = await navHandler.handleDeepLink(
          Uri.parse(
            'fatturafacile://procurement/purchase-requisitions/pr-push-99?approval_id=app-99',
          ),
          activeTenantId: 't1',
          actorId: 'mgr-1',
          actorName: 'Boss',
          navigatorKey: navKey,
        );
        expect(openRes.outcome, PrNotificationOutcome.navigatedToDetail);
        await tester.pumpAndSettle();
        expect(find.byType(PrDetailScreen), findsOneWidget);
        expect(find.text('RDA-PUSH-1'), findsAtLeastNWidgets(1));
        expect(find.byKey(const Key('pr-manager-action-bar')), findsOneWidget);

        navKey.currentState!.pop();
        await tester.pumpAndSettle();

        final PrNotificationResult rejectRes = await navHandler.handlePayload(
          <String, dynamic>{
            'type': 'purchase_requisition_approval',
            'tenant_id': 't1',
            'requisition_id': 'pr-push-99',
            'action': 'reject',
          },
          activeTenantId: 't1',
          actorId: 'mgr-1',
          actorName: 'Boss',
          navigatorKey: navKey,
        );
        expect(rejectRes.outcome, PrNotificationOutcome.needsRejectionReason);
        await tester.pumpAndSettle();
        expect(find.byType(PrRejectBottomSheet), findsOneWidget);
      },
    );
  });
}
