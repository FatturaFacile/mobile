import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/approval_models.dart';
import '../entities/budget_check.dart';
import '../entities/pr_reference_models.dart';
import '../entities/purchase_requisition.dart';

/// Summary of one purchase requisition offline synchronization cycle.
class PrSyncSummary {
  const PrSyncSummary({
    this.uploaded = 0,
    this.submitted = 0,
    this.approvalsSynced = 0,
    this.budgetBlocked = 0,
    this.failed = 0,
    this.offline = false,
  });

  final int uploaded;
  final int submitted;
  final int approvalsSynced;
  final int budgetBlocked;
  final int failed;
  final bool offline;
}

/// Offline-first contract for Mod 044 Purchase Requisitions (RDA / PR) & 1-Tap Approvals.
abstract interface class PurchaseRequisitionRepository {
  /// Watches all non-deleted purchase requisitions belonging to [tenantId].
  Stream<List<PurchaseRequisition>> watchMyRequisitions(String tenantId);

  /// Watches a single purchase requisition by either local or remote ID.
  Stream<PurchaseRequisition?> watchRequisition(String tenantId, String id);

  /// Watches pending approvals for managers within [tenantId].
  Stream<List<PendingApprovalItem>> watchPendingApprovals(String tenantId);

  /// Watches the count of pending manager approvals awaiting a decision.
  Stream<int> watchPendingApprovalCount(String tenantId);

  /// Watches immutable approval audit log entries for [requisitionId].
  Stream<List<ApprovalAuditEntry>> watchAuditLogs(
    String tenantId,
    String requisitionId,
  );

  /// Broadcast stream of asynchronous background sync outcomes.
  Stream<PrSyncEvent> get syncEvents;

  /// Saves a PR draft offline-first to SQLite, attempting immediate upload when online.
  Future<Either<Failure, PurchaseRequisition>> saveDraft(
    PurchaseRequisition draft, {
    required bool isOnline,
  });

  /// Runs a real-time Cost Center budget check (`POST /budget-preview`).
  Future<Either<Failure, BudgetCheckResult>> previewBudget(
    BudgetPreviewRequest request,
  );

  /// Submits a PR for approval: runs real-time budget check online or queues offline.
  Future<Either<Failure, PurchaseRequisition>> submitRequisition(
    PurchaseRequisition requisition, {
    required bool isOnline,
    bool acknowledgeBudgetWarning = false,
  });

  /// Refreshes a single PR detail, approval progress, and audit logs from the server.
  Future<Either<Failure, PurchaseRequisition>> refreshRequisitionDetail(
    String tenantId,
    String id,
  );

  /// Approves a pending requisition (online immediately or queued offline).
  Future<Either<Failure, void>> approveRequisition({
    required String tenantId,
    required String requisitionId,
    String? approvalId,
    required String actorId,
    required String actorName,
    String? comment,
    required bool isOnline,
  });

  /// Rejects a pending requisition with a mandatory reason (online or queued offline).
  Future<Either<Failure, void>> rejectRequisition({
    required String tenantId,
    required String requisitionId,
    String? approvalId,
    required String actorId,
    required String actorName,
    required String reason,
    required bool isOnline,
  });

  /// Executes a 1-click action (`approve` | `reject`) triggered from push notifications or deep links.
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
  });

  /// Flushes pending local PR drafts, queued submissions, and offline approval decisions, then refreshes server lists.
  Future<PrSyncSummary> syncAll(String tenantId);

  /// Loads available Cost Centers for [tenantId] from cache and/or API.
  Future<List<CostCenterOption>> loadCostCenters(String tenantId);

  /// Loads available Projects for [tenantId] from cache and/or API.
  Future<List<ProjectOption>> loadProjects(String tenantId);

  /// Searches catalog items locally and/or online by SKU, barcode, or description.
  Future<List<CatalogItemOption>> searchCatalogItems(
    String tenantId,
    String query,
  );

  /// Looks up a single catalog item by exact barcode or SKU match.
  Future<CatalogItemOption?> findCatalogItemByBarcode(
    String tenantId,
    String code,
  );
}
