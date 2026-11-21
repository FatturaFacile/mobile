import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/error/failure.dart';
import '../entities/purchase_requisition.dart';
import '../repositories/purchase_requisition_repository.dart';

/// Validates and submits a Purchase Requisition for approval (online budget-checked or queued offline).
class SubmitPrUseCase {
  SubmitPrUseCase(this._repository, {Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

  final PurchaseRequisitionRepository _repository;
  final Uuid _uuid;

  /// Validates mandatory submission fields and forwards to [PurchaseRequisitionRepository.submitRequisition].
  Future<Either<Failure, PurchaseRequisition>> call(
    PurchaseRequisition requisition, {
    required bool isOnline,
    bool acknowledgeBudgetWarning = false,
  }) async {
    final Map<String, List<String>> errors = <String, List<String>>{};
    if (requisition.costCenterId.trim().isEmpty) {
      errors['cost_center_id'] = <String>['required'];
    }
    if (requisition.justification.trim().isEmpty) {
      errors['justification'] = <String>['required'];
    }
    if (requisition.lines.isEmpty) {
      errors['lines'] = <String>['min_one_line'];
    } else {
      for (final PurchaseRequisitionLine line in requisition.lines) {
        if (line.description.trim().isEmpty ||
            line.quantity <= 0 ||
            line.unitPrice < 0) {
          errors['lines'] = <String>['invalid_line'];
          break;
        }
      }
    }
    if (errors.isNotEmpty) {
      return Left<Failure, PurchaseRequisition>(
        ValidationFailure(
          'Purchase requisition validation failed',
          fieldErrors: errors,
        ),
      );
    }

    final DateTime now = DateTime.now().toUtc();
    final String localId = requisition.localId.trim().isEmpty
        ? _uuid.v7()
        : requisition.localId;
    final List<PurchaseRequisitionLine> normalizedLines =
        <PurchaseRequisitionLine>[
          for (int i = 0; i < requisition.lines.length; i++)
            requisition.lines[i].copyWith(
              localId: requisition.lines[i].localId.trim().isEmpty
                  ? _uuid.v7()
                  : requisition.lines[i].localId,
              lineNumber: i + 1,
            ),
        ];

    final double computedTotal = normalizedLines.fold<double>(
      0,
      (double sum, PurchaseRequisitionLine line) => sum + line.lineTotal,
    );

    final PurchaseRequisition normalized = requisition.copyWith(
      localId: localId,
      lines: normalizedLines,
      totalAmount: computedTotal,
      clearSyncError: true,
      updatedAt: now,
    );

    return _repository.submitRequisition(
      normalized,
      isOnline: isOnline,
      acknowledgeBudgetWarning: acknowledgeBudgetWarning,
    );
  }
}
