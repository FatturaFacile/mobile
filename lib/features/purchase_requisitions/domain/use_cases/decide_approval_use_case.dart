import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../repositories/purchase_requisition_repository.dart';

/// Executes manager 1-tap approval, rejection (with mandatory reason), or push one-click actions.
class DecideApprovalUseCase {
  const DecideApprovalUseCase(this._repository);

  final PurchaseRequisitionRepository _repository;

  /// Approves a pending requisition via standard manager action.
  Future<Either<Failure, void>> approve({
    required String tenantId,
    required String requisitionId,
    String? approvalId,
    required String actorId,
    required String actorName,
    String? comment,
    required bool isOnline,
  }) {
    return _repository.approveRequisition(
      tenantId: tenantId,
      requisitionId: requisitionId,
      approvalId: approvalId,
      actorId: actorId,
      actorName: actorName,
      comment: comment,
      isOnline: isOnline,
    );
  }

  /// Rejects a pending requisition; rejects immediately with [ValidationFailure] if [reason] is blank.
  Future<Either<Failure, void>> reject({
    required String tenantId,
    required String requisitionId,
    String? approvalId,
    required String actorId,
    required String actorName,
    required String reason,
    required bool isOnline,
  }) async {
    final String trimmed = reason.trim();
    if (trimmed.isEmpty) {
      return const Left<Failure, void>(
        ValidationFailure(
          'Rejection reason is required',
          fieldErrors: <String, List<String>>{
            'reason': <String>['required'],
          },
        ),
      );
    }

    return _repository.rejectRequisition(
      tenantId: tenantId,
      requisitionId: requisitionId,
      approvalId: approvalId,
      actorId: actorId,
      actorName: actorName,
      reason: trimmed,
      isOnline: isOnline,
    );
  }

  /// Executes a 1-click decision from a push notification action or deep link.
  Future<Either<Failure, void>> executeOneClick({
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
    final String normalizedAction = action.trim().toLowerCase();
    if (normalizedAction != 'approve' && normalizedAction != 'reject') {
      return const Left<Failure, void>(
        ValidationFailure(
          'Invalid one-click action',
          fieldErrors: <String, List<String>>{
            'action': <String>['invalid'],
          },
        ),
      );
    }
    if (normalizedAction == 'reject' &&
        (reason == null || reason.trim().isEmpty)) {
      return const Left<Failure, void>(
        ValidationFailure(
          'Rejection reason is required',
          fieldErrors: <String, List<String>>{
            'reason': <String>['required'],
          },
        ),
      );
    }

    return _repository.executeOneClickAction(
      tenantId: tenantId,
      requisitionId: requisitionId,
      approvalId: approvalId,
      action: normalizedAction,
      token: token,
      reason: reason?.trim(),
      actorId: actorId,
      actorName: actorName,
      isOnline: isOnline,
    );
  }
}
