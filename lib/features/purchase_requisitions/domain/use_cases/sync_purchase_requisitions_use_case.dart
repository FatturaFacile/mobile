import '../repositories/purchase_requisition_repository.dart';

/// Synchronizes offline PR drafts, queued submissions, and pending approval decisions.
class SyncPurchaseRequisitionsUseCase {
  const SyncPurchaseRequisitionsUseCase(this._repository);

  final PurchaseRequisitionRepository _repository;

  /// Runs one complete PR upload + approval flush + pull cycle for [tenantId].
  Future<PrSyncSummary> call(String tenantId) => _repository.syncAll(tenantId);
}
