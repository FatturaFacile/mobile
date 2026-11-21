import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/error/failure.dart';
import '../entities/purchase_requisition.dart';
import '../repositories/purchase_requisition_repository.dart';

/// Validates minimum draft invariants and saves a Purchase Requisition offline-first.
class SaveDraftPrUseCase {
  SaveDraftPrUseCase(this._repository, {Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

  final PurchaseRequisitionRepository _repository;
  final Uuid _uuid;

  /// Persists [draft] locally with `sync_status = pending_upload`, syncing immediately if [isOnline].
  Future<Either<Failure, PurchaseRequisition>> call(
    PurchaseRequisition draft, {
    required bool isOnline,
  }) async {
    if (draft.costCenterId.trim().isEmpty) {
      return const Left<Failure, PurchaseRequisition>(
        ValidationFailure(
          'Cost Center is required',
          fieldErrors: <String, List<String>>{
            'cost_center_id': <String>['required'],
          },
        ),
      );
    }

    final DateTime now = DateTime.now().toUtc();
    final String localId = draft.localId.trim().isEmpty
        ? _uuid.v7()
        : draft.localId;
    final List<PurchaseRequisitionLine> normalizedLines =
        <PurchaseRequisitionLine>[
          for (int i = 0; i < draft.lines.length; i++)
            draft.lines[i].copyWith(
              localId: draft.lines[i].localId.trim().isEmpty
                  ? _uuid.v7()
                  : draft.lines[i].localId,
              lineNumber: i + 1,
            ),
        ];

    final double computedTotal = normalizedLines.fold<double>(
      0,
      (double sum, PurchaseRequisitionLine line) => sum + line.lineTotal,
    );

    final PurchaseRequisition normalized = draft.copyWith(
      localId: localId,
      lines: normalizedLines,
      totalAmount: computedTotal,
      status: draft.status == PrStatus.budgetExceeded
          ? PrStatus.budgetExceeded
          : PrStatus.draft,
      syncStatus: PrSyncStatus.pendingUpload,
      pendingSubmit: false,
      clearSyncError: true,
      updatedAt: now,
    );

    return _repository.saveDraft(normalized, isOnline: isOnline);
  }
}
