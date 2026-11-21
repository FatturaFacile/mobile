import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/budget_check.dart';
import '../entities/purchase_requisition.dart';
import '../repositories/purchase_requisition_repository.dart';

/// Evaluates real-time Cost Center budget availability (`Mod 019`) via `/budget-preview`.
class CheckBudgetPreviewUseCase {
  const CheckBudgetPreviewUseCase(this._repository);

  final PurchaseRequisitionRepository _repository;

  /// Requests a live budget check for the specified requisition fields and lines.
  Future<Either<Failure, BudgetCheckResult>> call({
    required String costCenterId,
    required String currency,
    required List<PurchaseRequisitionLine> lines,
    String? projectId,
  }) async {
    if (costCenterId.trim().isEmpty) {
      return const Left<Failure, BudgetCheckResult>(
        ValidationFailure(
          'Cost Center is required for budget preview',
          fieldErrors: <String, List<String>>{
            'cost_center_id': <String>['required'],
          },
        ),
      );
    }

    final double totalAmount = lines.fold<double>(
      0,
      (double sum, PurchaseRequisitionLine line) => sum + line.lineTotal,
    );

    final BudgetPreviewRequest request = BudgetPreviewRequest(
      costCenterId: costCenterId,
      projectId: projectId,
      currency: currency,
      totalAmount: totalAmount,
      lines: lines
          .map(
            (PurchaseRequisitionLine l) => BudgetPreviewLineInput(
              catalogItemId: l.catalogItemId,
              description: l.description,
              quantity: l.quantity,
              unitPrice: l.unitPrice,
            ),
          )
          .toList(),
    );

    return _repository.previewBudget(request);
  }
}
