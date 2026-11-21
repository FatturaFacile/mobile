import 'dart:async';

import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:fattura_facile/core/error/failure.dart';
import 'package:fattura_facile/design/ff_tokens.dart';
import 'package:fattura_facile/features/purchase_requisitions/domain/entities/approval_models.dart';
import 'package:fattura_facile/features/purchase_requisitions/domain/entities/budget_check.dart';
import 'package:fattura_facile/features/purchase_requisitions/domain/entities/pr_reference_models.dart';
import 'package:fattura_facile/features/purchase_requisitions/domain/entities/purchase_requisition.dart';
import 'package:fattura_facile/features/purchase_requisitions/domain/repositories/purchase_requisition_repository.dart';
import 'package:fattura_facile/features/purchase_requisitions/presentation/providers/pr_providers.dart';
import 'package:fattura_facile/features/purchase_requisitions/presentation/screens/pr_create_screen.dart';
import 'package:fattura_facile/features/purchase_requisitions/presentation/screens/pr_detail_screen.dart';
import 'package:fattura_facile/features/purchase_requisitions/presentation/screens/pr_hub_screen.dart';
import 'package:fattura_facile/l10n/gen/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:material_ui/material_ui.dart';

class _FakePurchaseRequisitionRepository
    implements PurchaseRequisitionRepository {
  final List<PurchaseRequisition> requisitions = <PurchaseRequisition>[];
  final List<PendingApprovalItem> approvals = <PendingApprovalItem>[];
  final Map<String, List<ApprovalAuditEntry>> auditLogs =
      <String, List<ApprovalAuditEntry>>{};
  final List<CostCenterOption> costCenters = <CostCenterOption>[
    const CostCenterOption(
      id: 'cc-1',
      code: 'CC-OPS',
      name: 'Operations',
      currency: 'CHF',
    ),
    const CostCenterOption(
      id: 'cc-2',
      code: 'CC-IT',
      name: 'IT Infrastructure',
      currency: 'EUR',
    ),
  ];
  final List<ProjectOption> projects = <ProjectOption>[
    const ProjectOption(id: 'prj-1', code: 'PRJ-09', name: 'Plant Expansion'),
  ];
  final List<CatalogItemOption> catalog = <CatalogItemOption>[
    const CatalogItemOption(
      id: 'cat-1',
      sku: 'SKU-42',
      barcode: 'EAN-999',
      name: 'Precision Torque Wrench',
      uom: 'pz',
      unitPrice: 150,
    ),
    const CatalogItemOption(
      id: 'cat-2',
      sku: 'SKU-77',
      barcode: 'EAN-777',
      name: 'Industrial Server Rack',
      uom: 'pz',
      unitPrice: 2500,
    ),
  ];

  BudgetCheckStatus nextBudgetStatus = BudgetCheckStatus.ok;
  final List<String> recordedCalls = <String>[];
  String? lastRejectionReason;

  final StreamController<List<PurchaseRequisition>> _reqCtrl =
      StreamController<List<PurchaseRequisition>>.broadcast();
  final StreamController<List<PendingApprovalItem>> _appCtrl =
      StreamController<List<PendingApprovalItem>>.broadcast();
  final StreamController<PrSyncEvent> _syncCtrl =
      StreamController<PrSyncEvent>.broadcast();

  void dispose() {
    _reqCtrl.close();
    _appCtrl.close();
    _syncCtrl.close();
  }

  @override
  Stream<PrSyncEvent> get syncEvents => _syncCtrl.stream;

  @override
  Stream<List<PurchaseRequisition>> watchMyRequisitions(
    String tenantId,
  ) async* {
    yield requisitions
        .where((PurchaseRequisition r) => r.tenantId == tenantId)
        .toList();
    yield* _reqCtrl.stream.map(
      (List<PurchaseRequisition> list) => list
          .where((PurchaseRequisition r) => r.tenantId == tenantId)
          .toList(),
    );
  }

  @override
  Stream<PurchaseRequisition?> watchRequisition(
    String tenantId,
    String id,
  ) async* {
    PurchaseRequisition? find(List<PurchaseRequisition> list) {
      for (final PurchaseRequisition r in list) {
        if (r.tenantId == tenantId && (r.localId == id || r.remoteId == id)) {
          return r;
        }
      }
      return null;
    }

    yield find(requisitions);
    yield* _reqCtrl.stream.map(find);
  }

  @override
  Stream<List<PendingApprovalItem>> watchPendingApprovals(
    String tenantId,
  ) async* {
    yield approvals
        .where(
          (PendingApprovalItem a) =>
              a.tenantId == tenantId && a.pendingDecision == null,
        )
        .toList();
    yield* _appCtrl.stream.map(
      (List<PendingApprovalItem> list) => list
          .where(
            (PendingApprovalItem a) =>
                a.tenantId == tenantId && a.pendingDecision == null,
          )
          .toList(),
    );
  }

  @override
  Stream<int> watchPendingApprovalCount(String tenantId) =>
      watchPendingApprovals(tenantId)
          .map((List<PendingApprovalItem> items) => items.length);

  @override
  Stream<List<ApprovalAuditEntry>> watchAuditLogs(
    String tenantId,
    String requisitionId,
  ) => Stream<List<ApprovalAuditEntry>>.value(
    auditLogs[requisitionId] ?? const <ApprovalAuditEntry>[],
  );

  @override
  Future<Either<Failure, PurchaseRequisition>> saveDraft(
    PurchaseRequisition draft, {
    required bool isOnline,
  }) async {
    recordedCalls.add('saveDraft:${draft.localId}:online=$isOnline');
    final PurchaseRequisition saved = draft.copyWith(
      status: PrStatus.draft,
      syncStatus: isOnline ? PrSyncStatus.synced : PrSyncStatus.pendingUpload,
    );
    _upsertReq(saved);
    return Right<Failure, PurchaseRequisition>(saved);
  }

  @override
  Future<Either<Failure, BudgetCheckResult>> previewBudget(
    BudgetPreviewRequest request,
  ) async {
    recordedCalls.add(
      'previewBudget:${request.costCenterId}:${request.totalAmount}',
    );
    final BudgetCheckResult result = _buildBudgetCheck(
      request.costCenterId,
      request.currency,
      request.totalAmount,
    );
    return Right<Failure, BudgetCheckResult>(result);
  }

  @override
  Future<Either<Failure, PurchaseRequisition>> submitRequisition(
    PurchaseRequisition requisition, {
    required bool isOnline,
    bool acknowledgeBudgetWarning = false,
  }) async {
    recordedCalls.add(
      'submit:${requisition.localId}:online=$isOnline:ack=$acknowledgeBudgetWarning',
    );
    if (!isOnline) {
      final PurchaseRequisition queued = requisition.copyWith(
        status: PrStatus.pendingApproval,
        syncStatus: PrSyncStatus.pendingUpload,
        pendingSubmit: true,
      );
      _upsertReq(queued);
      return Right<Failure, PurchaseRequisition>(queued);
    }

    final BudgetCheckResult check = _buildBudgetCheck(
      requisition.costCenterId,
      requisition.currency.wireValue,
      requisition.totalAmount,
    );
    if (check.status == BudgetCheckStatus.hardBlock) {
      final PurchaseRequisition blocked = requisition.copyWith(
        status: PrStatus.budgetExceeded,
        syncStatus: PrSyncStatus.syncError,
        budgetCheck: check,
      );
      _upsertReq(blocked);
      return Right<Failure, PurchaseRequisition>(blocked);
    }
    if (check.status == BudgetCheckStatus.warning &&
        !acknowledgeBudgetWarning) {
      final PurchaseRequisition warned = requisition.copyWith(
        status: PrStatus.draft,
        budgetCheck: check,
      );
      _upsertReq(warned);
      return Right<Failure, PurchaseRequisition>(warned);
    }

    final PurchaseRequisition submitted = requisition.copyWith(
      remoteId: 'srv-${requisition.localId}',
      requisitionNumber: 'RDA-2026-NEW',
      status: PrStatus.pendingApproval,
      syncStatus: PrSyncStatus.synced,
      budgetCheck: check,
    );
    _upsertReq(submitted);
    return Right<Failure, PurchaseRequisition>(submitted);
  }

  @override
  Future<Either<Failure, PurchaseRequisition>> refreshRequisitionDetail(
    String tenantId,
    String id,
  ) async {
    for (final PurchaseRequisition r in requisitions) {
      if (r.tenantId == tenantId && (r.localId == id || r.remoteId == id)) {
        return Right<Failure, PurchaseRequisition>(r);
      }
    }
    return const Left<Failure, PurchaseRequisition>(
      ServerFailure('Not found', statusCode: 404),
    );
  }

  @override
  Future<Either<Failure, void>> approveRequisition({
    required String tenantId,
    required String requisitionId,
    String? approvalId,
    required String actorId,
    required String actorName,
    String? comment,
    required bool isOnline,
  }) async {
    recordedCalls.add('approve:$requisitionId:online=$isOnline');
    approvals.removeWhere(
      (PendingApprovalItem a) => a.requisitionRemoteId == requisitionId,
    );
    _appCtrl.add(List<PendingApprovalItem>.from(approvals));
    return const Right<Failure, void>(null);
  }

  @override
  Future<Either<Failure, void>> rejectRequisition({
    required String tenantId,
    required String requisitionId,
    String? approvalId,
    required String actorId,
    required String actorName,
    required String reason,
    required bool isOnline,
  }) async {
    recordedCalls.add('reject:$requisitionId:online=$isOnline');
    lastRejectionReason = reason;
    approvals.removeWhere(
      (PendingApprovalItem a) => a.requisitionRemoteId == requisitionId,
    );
    _appCtrl.add(List<PendingApprovalItem>.from(approvals));
    return const Right<Failure, void>(null);
  }

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
  }) async {
    recordedCalls.add('oneClick:$action:$requisitionId');
    return const Right<Failure, void>(null);
  }

  @override
  Future<PrSyncSummary> syncAll(String tenantId) async => const PrSyncSummary();

  @override
  Future<List<CostCenterOption>> loadCostCenters(String tenantId) async =>
      costCenters;

  @override
  Future<List<ProjectOption>> loadProjects(String tenantId) async => projects;

  @override
  Future<List<CatalogItemOption>> searchCatalogItems(
    String tenantId,
    String query,
  ) async {
    final String q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return catalog;
    }
    return catalog
        .where(
          (CatalogItemOption item) =>
              item.name.toLowerCase().contains(q) ||
              item.sku.toLowerCase().contains(q) ||
              (item.barcode?.toLowerCase().contains(q) ?? false),
        )
        .toList();
  }

  @override
  Future<CatalogItemOption?> findCatalogItemByBarcode(
    String tenantId,
    String code,
  ) async {
    final String normalized = code.trim().toLowerCase();
    for (final CatalogItemOption item in catalog) {
      if (item.barcode?.toLowerCase() == normalized ||
          item.sku.toLowerCase() == normalized) {
        return item;
      }
    }
    return null;
  }

  void _upsertReq(PurchaseRequisition pr) {
    final int idx = requisitions.indexWhere(
      (PurchaseRequisition r) => r.localId == pr.localId,
    );
    if (idx == -1) {
      requisitions.add(pr);
    } else {
      requisitions[idx] = pr;
    }
    _reqCtrl.add(List<PurchaseRequisition>.from(requisitions));
  }

  BudgetCheckResult _buildBudgetCheck(
    String ccId,
    String currency,
    double requested,
  ) {
    return switch (nextBudgetStatus) {
      BudgetCheckStatus.ok => BudgetCheckResult(
        status: BudgetCheckStatus.ok,
        costCenterId: ccId,
        costCenterCode: 'CC-OPS',
        currency: currency,
        allocatedBudget: 10000,
        committedAmount: 1000,
        spentAmount: 1000,
        availableBudget: 8000,
        requestedAmount: requested,
        remainingAfterRequest: 8000 - requested,
        utilizationPercent: 30,
        warningThresholdPercent: 85,
        message: 'Budget available',
        checkedAt: DateTime.utc(2026, 11, 21),
      ),
      BudgetCheckStatus.warning => BudgetCheckResult(
        status: BudgetCheckStatus.warning,
        costCenterId: ccId,
        costCenterCode: 'CC-OPS',
        currency: currency,
        allocatedBudget: 1000,
        committedAmount: 750,
        spentAmount: 0,
        availableBudget: 250,
        requestedAmount: requested,
        remainingAfterRequest: 250 - requested,
        utilizationPercent: 90,
        warningThresholdPercent: 85,
        message: 'Threshold 85% exceeded',
        checkedAt: DateTime.utc(2026, 11, 21),
      ),
      BudgetCheckStatus.hardBlock => BudgetCheckResult(
        status: BudgetCheckStatus.hardBlock,
        costCenterId: ccId,
        costCenterCode: 'CC-OPS',
        currency: currency,
        allocatedBudget: 1000,
        committedAmount: 950,
        spentAmount: 0,
        availableBudget: 50,
        requestedAmount: requested,
        remainingAfterRequest: 50 - requested,
        utilizationPercent: 120,
        warningThresholdPercent: 85,
        message: 'Cost Center annual cap exceeded',
        checkedAt: DateTime.utc(2026, 11, 21),
      ),
    };
  }
}

Widget _prTestApp(
  Widget child, {
  required _FakePurchaseRequisitionRepository repo,
  bool isOnline = true,
  Locale locale = const Locale('en'),
}) {
  return ProviderScope(
    overrides: <Override>[
      prRepositoryProvider.overrideWithValue(repo),
      prIsOnlineProvider.overrideWithValue(isOnline),
    ],
    child: MaterialApp(
      theme: ffThemeData(),
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: child,
    ),
  );
}

void main() {
  late _FakePurchaseRequisitionRepository repo;

  setUp(() {
    repo = _FakePurchaseRequisitionRepository();
    final DateTime now = DateTime.utc(2026, 11, 21, 10);
    repo.requisitions.addAll(<PurchaseRequisition>[
      PurchaseRequisition(
        localId: 'pr-1',
        remoteId: 'srv-1',
        tenantId: 't1',
        requisitionNumber: 'RDA-2026-001',
        requesterId: 'u1',
        requesterName: 'Anna Rossi',
        costCenterId: 'cc-1',
        costCenterCode: 'CC-OPS',
        costCenterName: 'Operations',
        projectId: 'prj-1',
        projectCode: 'PRJ-09',
        projectName: 'Plant Expansion',
        urgency: PrUrgency.high,
        justification: 'Replacement pumps',
        currency: PrCurrency.chf,
        totalAmount: 1450,
        status: PrStatus.convertedToPo,
        syncStatus: PrSyncStatus.synced,
        pendingSubmit: false,
        lines: const <PurchaseRequisitionLine>[
          PurchaseRequisitionLine(
            localId: 'l1',
            lineNumber: 1,
            itemType: PrItemType.catalogItem,
            catalogItemId: 'cat-1',
            catalogSku: 'SKU-42',
            description: 'Precision Torque Wrench',
            quantity: 2,
            unitPrice: 150,
            uom: 'pz',
          ),
        ],
        approvalSteps: <ApprovalLevelStep>[
          ApprovalLevelStep(
            level: 1,
            roleName: 'Department Manager',
            approverName: 'Elena Bianchi',
            status: ApprovalStepStatus.approved,
            decidedAt: now,
          ),
        ],
        linkedRdo: const LinkedDocumentRef(
          id: 'rdo-1',
          number: 'RDO-88',
          type: 'rdo',
        ),
        linkedPo: const LinkedDocumentRef(
          id: 'po-1',
          number: 'PO-55',
          type: 'po',
        ),
        createdAt: now,
        updatedAt: now,
      ),
      PurchaseRequisition(
        localId: 'pr-2',
        remoteId: 'srv-2',
        tenantId: 't1',
        requisitionNumber: 'RDA-2026-002',
        requesterId: 'u1',
        requesterName: 'Anna Rossi',
        costCenterId: 'cc-2',
        costCenterCode: 'CC-IT',
        costCenterName: 'IT Infrastructure',
        urgency: PrUrgency.critical,
        justification: 'Emergency rack',
        currency: PrCurrency.eur,
        totalAmount: 5000,
        status: PrStatus.budgetExceeded,
        syncStatus: PrSyncStatus.syncError,
        pendingSubmit: false,
        lines: const <PurchaseRequisitionLine>[],
        approvalSteps: const <ApprovalLevelStep>[],
        createdAt: now,
        updatedAt: now,
      ),
    ]);

    repo.approvals.add(
      PendingApprovalItem(
        approvalId: 'app-1',
        tenantId: 't1',
        requisitionRemoteId: 'srv-3',
        requisitionNumber: 'RDA-2026-003',
        requesterName: 'Marco Verdi',
        costCenterCode: 'CC-OPS',
        costCenterName: 'Operations',
        projectName: 'Plant Expansion',
        urgency: PrUrgency.high,
        totalAmount: 780,
        currency: PrCurrency.chf,
        status: PrStatus.pendingApproval,
        currentLevel: 1,
        totalLevels: 2,
        budgetStatus: BudgetCheckStatus.warning,
        syncStatus: PrSyncStatus.synced,
        requestedAt: now,
        updatedAt: now,
      ),
    );
  });

  tearDown(() => repo.dispose());

  group('PrHubScreen', () {
    testWidgets(
      'shows segmented tabs, pending badge, budget exceeded & linked RDO/PO badges',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _prTestApp(
            const PrHubScreen(
              tenantId: 't1',
              userId: 'u1',
              userName: 'Anna Rossi',
            ),
            repo: repo,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('RDA-2026-001'), findsOneWidget);
        expect(find.text('RDA-2026-002'), findsOneWidget);
        expect(find.text('Budget Exceeded'), findsOneWidget);
        expect(find.text('RDO RDO-88'), findsOneWidget);
        expect(find.text('PO PO-55'), findsOneWidget);
        expect(find.byKey(const Key('pr-to-approve-badge')), findsOneWidget);
        expect(find.text('1'), findsOneWidget);

        await tester.tap(find.byKey(const Key('pr-tab-to-approve')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('pr-approval-card-app-1')), findsOneWidget);
        expect(find.text('RDA-2026-003'), findsOneWidget);
        expect(find.text('Level 1/2'), findsOneWidget);
        expect(find.text('Budget Warning'), findsOneWidget);
      },
    );

    testWidgets('renders localized labels in Italian, German and French', (
      WidgetTester tester,
    ) async {
      for (final ({Locale locale, String expectedTitle}) entry
          in <({Locale locale, String expectedTitle})>[
            (
              locale: const Locale('it'),
              expectedTitle: 'Richieste di Acquisto (RDA)',
            ),
            (
              locale: const Locale('de'),
              expectedTitle: 'Bestellanforderungen (BANF)',
            ),
            (
              locale: const Locale('fr'),
              expectedTitle: "Demandes d'achat (DA)",
            ),
          ]) {
        await tester.pumpWidget(
          _prTestApp(
            const PrHubScreen(
              tenantId: 't1',
              userId: 'u1',
              userName: 'Anna Rossi',
            ),
            repo: repo,
            locale: entry.locale,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(entry.expectedTitle), findsOneWidget);
      }
    });
  });

  group('PrCreateScreen', () {
    testWidgets(
      'saves draft offline and supports barcode scan & free-text line entry',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _prTestApp(
            PrCreateScreen(
              tenantId: 't1',
              userId: 'u1',
              userName: 'Anna Rossi',
              cameraScanner: (_) async => 'EAN-999',
            ),
            repo: repo,
            isOnline: false,
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('pr-create-offline-banner')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('budget-banner-offline')), findsOneWidget);

        // Select Cost Center.
        await tester.tap(find.byKey(const Key('pr-cost-center-picker')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('CC-OPS · Operations').last);
        await tester.pumpAndSettle();

        // Add line via barcode scan hook.
        await tester.ensureVisible(
          find.byKey(const Key('pr-scan-barcode-button')),
        );
        await tester.tap(find.byKey(const Key('pr-scan-barcode-button')));
        await tester.pumpAndSettle();
        expect(find.text('Precision Torque Wrench'), findsOneWidget);

        // Add line via Free-Text Entry sheet.
        await tester.ensureVisible(find.byKey(const Key('pr-add-line-button')));
        await tester.tap(find.byKey(const Key('pr-add-line-button')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Free-Text Entry'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('pr-line-description-input')),
          'Custom Mounting Bracket',
        );
        await tester.enterText(find.byKey(const Key('pr-line-qty-input')), '3');
        await tester.enterText(
          find.byKey(const Key('pr-line-price-input')),
          '50',
        );
        await tester.tap(find.byKey(const Key('pr-line-add-confirm')));
        await tester.pumpAndSettle();
        expect(find.text('Custom Mounting Bracket'), findsOneWidget);

        // Save Draft Offline.
        await tester.tap(find.byKey(const Key('pr-save-draft-button')));
        await tester.pumpAndSettle();
        expect(
          repo.recordedCalls.any(
            (String c) =>
                c.startsWith('saveDraft:') && c.endsWith('online=false'),
          ),
          isTrue,
        );
      },
    );

    testWidgets(
      'shows live Budget Warning confirmation dialog and proceeds when acknowledged',
      (WidgetTester tester) async {
        repo.nextBudgetStatus = BudgetCheckStatus.warning;
        await tester.pumpWidget(
          _prTestApp(
            PrCreateScreen(
              tenantId: 't1',
              userId: 'u1',
              userName: 'Anna Rossi',
              cameraScanner: (_) async => 'EAN-999',
            ),
            repo: repo,
            isOnline: true,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('pr-cost-center-picker')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('CC-OPS · Operations').last);
        await tester.pumpAndSettle();

        await tester.ensureVisible(
          find.byKey(const Key('pr-justification-input')),
        );
        await tester.enterText(
          find.byKey(const Key('pr-justification-input')),
          'Maintenance stock',
        );
        await tester.ensureVisible(
          find.byKey(const Key('pr-scan-barcode-button')),
        );
        await tester.tap(find.byKey(const Key('pr-scan-barcode-button')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('budget-banner-warning')), findsOneWidget);

        await tester.tap(find.byKey(const Key('pr-submit-button')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('pr-budget-warning-dialog')),
          findsOneWidget,
        );

        await tester.tap(find.byKey(const Key('pr-budget-warning-proceed')));
        await tester.pumpAndSettle();
        expect(
          repo.recordedCalls.any((String c) => c.contains('ack=true')),
          isTrue,
        );
      },
    );

    testWidgets(
      'shows live Budget Hard-Block banner and disables Submit button',
      (WidgetTester tester) async {
        repo.nextBudgetStatus = BudgetCheckStatus.hardBlock;
        await tester.pumpWidget(
          _prTestApp(
            PrCreateScreen(
              tenantId: 't1',
              userId: 'u1',
              userName: 'Anna Rossi',
              cameraScanner: (_) async => 'EAN-777',
            ),
            repo: repo,
            isOnline: true,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('pr-cost-center-picker')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('CC-OPS · Operations').last);
        await tester.pumpAndSettle();
        await tester.ensureVisible(
          find.byKey(const Key('pr-scan-barcode-button')),
        );
        await tester.tap(find.byKey(const Key('pr-scan-barcode-button')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('budget-banner-hard-block')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('pr-hard-block-submit-note')),
          findsOneWidget,
        );
        final FilledButton submitBtn = tester.widget<FilledButton>(
          find.byKey(const Key('pr-submit-button')),
        );
        expect(submitBtn.onPressed, isNull);
      },
    );
  });

  group('PrDetailScreen', () {
    void seedDetailPr() {
      final DateTime now = DateTime.utc(2026, 11, 21, 11);
      repo.requisitions.add(
        PurchaseRequisition(
          localId: 'pr-3',
          remoteId: 'srv-3',
          tenantId: 't1',
          requisitionNumber: 'RDA-2026-003',
          requesterId: 'u2',
          requesterName: 'Marco Verdi',
          costCenterId: 'cc-1',
          costCenterCode: 'CC-OPS',
          costCenterName: 'Operations',
          urgency: PrUrgency.high,
          justification: 'Workshop calibration kit',
          currency: PrCurrency.chf,
          totalAmount: 780,
          status: PrStatus.pendingApproval,
          syncStatus: PrSyncStatus.synced,
          pendingSubmit: false,
          lines: const <PurchaseRequisitionLine>[
            PurchaseRequisitionLine(
              localId: 'l3',
              lineNumber: 1,
              itemType: PrItemType.freeText,
              description: 'Calibration Kit',
              quantity: 1,
              unitPrice: 780,
              uom: 'pz',
            ),
          ],
          approvalSteps: const <ApprovalLevelStep>[
            ApprovalLevelStep(
              level: 1,
              roleName: 'Plant Lead',
              status: ApprovalStepStatus.pending,
            ),
            ApprovalLevelStep(
              level: 2,
              roleName: 'CFO',
              status: ApprovalStepStatus.waiting,
            ),
          ],
          linkedRdo: const LinkedDocumentRef(
            id: 'rdo-3',
            number: 'RDO-300',
            type: 'rdo',
          ),
          createdAt: now,
          updatedAt: now,
        ),
      );
      repo.auditLogs['srv-3'] = <ApprovalAuditEntry>[
        ApprovalAuditEntry(
          id: 'aud-1',
          requisitionId: 'srv-3',
          level: 1,
          action: ApprovalActionType.submitted,
          actorName: 'Marco Verdi',
          channel: ApprovalChannel.mobileApp,
          occurredAt: now,
        ),
      ];
    }

    testWidgets(
      'displays audit trail, approval progress, linked docs, and executes 1-tap approve',
      (WidgetTester tester) async {
        seedDetailPr();
        await tester.pumpWidget(
          _prTestApp(
            const PrDetailScreen(
              tenantId: 't1',
              requisitionId: 'srv-3',
              actorId: 'mgr-1',
              actorName: 'Elena Manager',
              approvalId: 'app-1',
              isManagerApproval: true,
            ),
            repo: repo,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Calibration Kit'), findsOneWidget);
        expect(find.text('RDO RDO-300'), findsOneWidget);
        expect(find.text('Level 1 · Plant Lead'), findsOneWidget);
        expect(find.byKey(const Key('pr-audit-trail-card')), findsOneWidget);
        expect(find.text('Mobile App'), findsOneWidget);

        await tester.tap(find.byKey(const Key('pr-approve-button')));
        await tester.pumpAndSettle();
        expect(repo.recordedCalls, contains('approve:srv-3:online=true'));
      },
    );

    testWidgets(
      'reject bottom sheet validates mandatory reason and submits non-empty reason',
      (WidgetTester tester) async {
        seedDetailPr();
        await tester.pumpWidget(
          _prTestApp(
            const PrDetailScreen(
              tenantId: 't1',
              requisitionId: 'srv-3',
              actorId: 'mgr-1',
              actorName: 'Elena Manager',
              approvalId: 'app-1',
              isManagerApproval: true,
            ),
            repo: repo,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('pr-reject-button')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('pr-reject-confirm-button')));
        await tester.pumpAndSettle();
        expect(find.text('A rejection reason is mandatory'), findsOneWidget);
        expect(repo.lastRejectionReason, isNull);

        await tester.enterText(
          find.byKey(const Key('pr-reject-reason-input')),
          'Use existing supplier contract',
        );
        await tester.tap(find.byKey(const Key('pr-reject-confirm-button')));
        await tester.pumpAndSettle();
        expect(repo.lastRejectionReason, 'Use existing supplier contract');
        expect(repo.recordedCalls, contains('reject:srv-3:online=true'));
      },
    );
  });
}
