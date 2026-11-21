import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/providers.dart';
import '../../data/local/purchase_requisition_dao.dart';
import '../../data/remote/purchase_requisition_remote_data_source.dart';
import '../../data/repositories/purchase_requisition_repository_impl.dart';
import '../../domain/entities/approval_models.dart';
import '../../domain/entities/pr_reference_models.dart';
import '../../domain/entities/purchase_requisition.dart';
import '../../domain/repositories/purchase_requisition_repository.dart';
import '../../domain/use_cases/check_budget_preview_use_case.dart';
import '../../domain/use_cases/decide_approval_use_case.dart';
import '../../domain/use_cases/save_draft_pr_use_case.dart';
import '../../domain/use_cases/submit_pr_use_case.dart';
import '../../domain/use_cases/sync_purchase_requisitions_use_case.dart';

/// Root navigator key used for deep linking and push notification routing.
final Provider<GlobalKey<NavigatorState>> navigatorKeyProvider =
    Provider<GlobalKey<NavigatorState>>(
      (Ref ref) => GlobalKey<NavigatorState>(),
    );

/// Connectivity flag derived from [connectivityProvider] (overridable in tests).
final Provider<bool> prIsOnlineProvider = Provider<bool>((Ref ref) {
  return ref.watch(connectivityProvider).value ?? true;
});

/// Drift DAO for Mod 044 local SQLite tables.
final Provider<PurchaseRequisitionDao> prDaoProvider =
    Provider<PurchaseRequisitionDao>((Ref ref) {
      return ref.watch(databaseProvider).purchaseRequisitionDao;
    });

/// REST data source aligned to `/api/v1/procurement/purchase-requisitions`.
final Provider<PurchaseRequisitionRemoteDataSource> prRemoteDataSourceProvider =
    Provider<PurchaseRequisitionRemoteDataSource>((Ref ref) {
      return PurchaseRequisitionRemoteDataSource(ref.watch(dioProvider));
    });

/// Offline-first repository for Mod 044 Purchase Requisitions & 1-Tap Approvals.
final Provider<PurchaseRequisitionRepository> prRepositoryProvider =
    Provider<PurchaseRequisitionRepository>((Ref ref) {
      final PurchaseRequisitionRepositoryImpl impl =
          PurchaseRequisitionRepositoryImpl(
            ref.watch(databaseProvider),
            ref.watch(prDaoProvider),
            ref.watch(prRemoteDataSourceProvider),
          );
      ref.onDispose(impl.dispose);
      return impl;
    });

/// Use case: save PR draft locally offline-first.
final Provider<SaveDraftPrUseCase> saveDraftPrUseCaseProvider =
    Provider<SaveDraftPrUseCase>((Ref ref) {
      return SaveDraftPrUseCase(ref.watch(prRepositoryProvider));
    });

/// Use case: real-time Cost Center budget check (`Mod 019`).
final Provider<CheckBudgetPreviewUseCase> checkBudgetPreviewUseCaseProvider =
    Provider<CheckBudgetPreviewUseCase>((Ref ref) {
      return CheckBudgetPreviewUseCase(ref.watch(prRepositoryProvider));
    });

/// Use case: validate and submit a PR (online budget check or offline queue).
final Provider<SubmitPrUseCase> submitPrUseCaseProvider =
    Provider<SubmitPrUseCase>((Ref ref) {
      return SubmitPrUseCase(ref.watch(prRepositoryProvider));
    });

/// Use case: 1-tap approval, rejection, and push notification one-click execution.
final Provider<DecideApprovalUseCase> decideApprovalUseCaseProvider =
    Provider<DecideApprovalUseCase>((Ref ref) {
      return DecideApprovalUseCase(ref.watch(prRepositoryProvider));
    });

/// Use case: background synchronization hook invoked by `SyncOrchestrator`.
final Provider<SyncPurchaseRequisitionsUseCase>
syncPurchaseRequisitionsUseCaseProvider =
    Provider<SyncPurchaseRequisitionsUseCase>((Ref ref) {
      return SyncPurchaseRequisitionsUseCase(ref.watch(prRepositoryProvider));
    });

/// Streams all tenant-scoped Purchase Requisitions ("My Requests").
final myPurchaseRequisitionsProvider =
    StreamProvider.family<List<PurchaseRequisition>, String>((
      Ref ref,
      String tenantId,
    ) {
      return ref.watch(prRepositoryProvider).watchMyRequisitions(tenantId);
    });

/// Streams one Purchase Requisition by local or remote ID.
final purchaseRequisitionDetailProvider =
    StreamProvider.family<
      PurchaseRequisition?,
      ({String tenantId, String requisitionId})
    >((Ref ref, ({String tenantId, String requisitionId}) key) {
      return ref
          .watch(prRepositoryProvider)
          .watchRequisition(key.tenantId, key.requisitionId);
    });

/// Streams manager pending approvals ("To Approve").
final pendingApprovalsProvider =
    StreamProvider.family<List<PendingApprovalItem>, String>((
      Ref ref,
      String tenantId,
    ) {
      return ref.watch(prRepositoryProvider).watchPendingApprovals(tenantId);
    });

/// Streams unread/pending approval counter badge for [tenantId].
final pendingApprovalCountProvider = StreamProvider.family<int, String>((
  Ref ref,
  String tenantId,
) {
  return ref.watch(prRepositoryProvider).watchPendingApprovalCount(tenantId);
});

/// Streams immutable approval audit logs for one Purchase Requisition.
final prAuditLogsProvider =
    StreamProvider.family<
      List<ApprovalAuditEntry>,
      ({String tenantId, String requisitionId})
    >((Ref ref, ({String tenantId, String requisitionId}) key) {
      return ref
          .watch(prRepositoryProvider)
          .watchAuditLogs(key.tenantId, key.requisitionId);
    });

/// Streams asynchronous background sync completion events.
final prSyncEventsProvider = StreamProvider<PrSyncEvent>((Ref ref) {
  return ref.watch(prRepositoryProvider).syncEvents;
});

/// Loads Cost Centers (`Mod 019`) from SQLite cache + API for [tenantId].
final prCostCentersProvider =
    FutureProvider.family<List<CostCenterOption>, String>((
      Ref ref,
      String tenantId,
    ) {
      return ref.watch(prRepositoryProvider).loadCostCenters(tenantId);
    });

/// Loads Projects (`Domain 09`) from SQLite cache + API for [tenantId].
final prProjectsProvider = FutureProvider.family<List<ProjectOption>, String>((
  Ref ref,
  String tenantId,
) {
  return ref.watch(prRepositoryProvider).loadProjects(tenantId);
});

/// Platform channel stream delivering incoming push notification action payloads.
final StreamProvider<Map<String, dynamic>>
prPushEventsStreamProvider = StreamProvider<Map<String, dynamic>>((Ref ref) {
  const MethodChannel channel = MethodChannel('fattura_facile/push_actions');
  final StreamController<Map<String, dynamic>> controller =
      StreamController<Map<String, dynamic>>();
  channel.setMethodCallHandler((MethodCall call) async {
    if (call.method == 'onPushAction' && call.arguments is Map) {
      final Map<dynamic, dynamic> raw = call.arguments as Map<dynamic, dynamic>;
      controller.add(
        raw.map((dynamic k, dynamic v) => MapEntry<String, dynamic>('$k', v)),
      );
    }
  });
  ref.onDispose(() {
    channel.setMethodCallHandler(null);
    controller.close();
  });
  return controller.stream;
});
