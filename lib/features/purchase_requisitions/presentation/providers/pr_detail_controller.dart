import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/purchase_requisition.dart';
import 'pr_providers.dart';

/// Immutable family key identifying a PR Detail view and actor context.
class PrDetailArgs {
  const PrDetailArgs({
    required this.tenantId,
    required this.requisitionId,
    required this.actorId,
    required this.actorName,
    this.approvalId,
    this.oneClickToken,
  });

  final String tenantId;
  final String requisitionId;
  final String actorId;
  final String actorName;
  final String? approvalId;
  final String? oneClickToken;

  @override
  bool operator ==(Object other) {
    return other is PrDetailArgs &&
        other.tenantId == tenantId &&
        other.requisitionId == requisitionId &&
        other.approvalId == approvalId &&
        other.oneClickToken == oneClickToken &&
        other.actorId == actorId;
  }

  @override
  int get hashCode =>
      Object.hash(tenantId, requisitionId, approvalId, oneClickToken, actorId);
}

/// Outcome of a manager 1-tap action on [PrDetailController].
enum PrDetailOutcomeKind {
  approvedOnline,
  approvedQueuedOffline,
  rejectedOnline,
  rejectedQueuedOffline,
  error,
}

/// Structured result of an approval/rejection action.
class PrDetailOutcome {
  const PrDetailOutcome({required this.kind, this.message});

  final PrDetailOutcomeKind kind;
  final String? message;
}

/// UI state of the Purchase Requisition Detail screen.
class PrDetailState {
  const PrDetailState({
    this.isRefreshing = false,
    this.isSubmitting = false,
    this.errorMessage,
  });

  final bool isRefreshing;
  final bool isSubmitting;
  final String? errorMessage;

  /// Returns a modified copy of [PrDetailState].
  PrDetailState copyWith({
    bool? isRefreshing,
    bool? isSubmitting,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return PrDetailState(
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Manages detail refresh and manager 1-tap approval / rejection actions.
class PrDetailController extends Notifier<PrDetailState> {
  PrDetailController(this.arg);

  final PrDetailArgs arg;
  bool _disposed = false;

  @override
  PrDetailState build() {
    ref.onDispose(() => _disposed = true);
    return const PrDetailState();
  }

  /// Refreshes detail, budget snapshot, approval progress, and audit logs when online.
  Future<void> refresh() async {
    if (!ref.read(prIsOnlineProvider)) {
      return;
    }
    state = state.copyWith(isRefreshing: true, clearErrorMessage: true);
    final Either<Failure, PurchaseRequisition> res = await ref
        .read(prRepositoryProvider)
        .refreshRequisitionDetail(arg.tenantId, arg.requisitionId);
    if (_disposed) {
      return;
    }
    state = state.copyWith(
      isRefreshing: false,
      errorMessage: res.fold((Failure f) => f.message, (_) => null),
    );
  }

  /// Executes 1-Tap Approval (online or queued offline).
  Future<PrDetailOutcome> approve({String? comment}) async {
    state = state.copyWith(isSubmitting: true, clearErrorMessage: true);
    final bool isOnline = ref.read(prIsOnlineProvider);
    final bool useOneClick =
        arg.oneClickToken != null && arg.oneClickToken!.isNotEmpty;

    final Either<Failure, void> res = useOneClick
        ? await ref
              .read(decideApprovalUseCaseProvider)
              .executeOneClick(
                tenantId: arg.tenantId,
                requisitionId: arg.requisitionId,
                approvalId: arg.approvalId,
                action: 'approve',
                token: arg.oneClickToken,
                actorId: arg.actorId,
                actorName: arg.actorName,
                isOnline: isOnline,
              )
        : await ref
              .read(decideApprovalUseCaseProvider)
              .approve(
                tenantId: arg.tenantId,
                requisitionId: arg.requisitionId,
                approvalId: arg.approvalId,
                actorId: arg.actorId,
                actorName: arg.actorName,
                comment: comment,
                isOnline: isOnline,
              );

    if (_disposed) {
      return const PrDetailOutcome(kind: PrDetailOutcomeKind.error);
    }

    return res.match(
      (Failure failure) {
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: failure.message,
        );
        return PrDetailOutcome(
          kind: PrDetailOutcomeKind.error,
          message: failure.message,
        );
      },
      (_) {
        state = state.copyWith(isSubmitting: false);
        return PrDetailOutcome(
          kind: isOnline
              ? PrDetailOutcomeKind.approvedOnline
              : PrDetailOutcomeKind.approvedQueuedOffline,
        );
      },
    );
  }

  /// Executes Rejection with a mandatory reason (online or queued offline).
  Future<PrDetailOutcome> reject(String reason) async {
    state = state.copyWith(isSubmitting: true, clearErrorMessage: true);
    final bool isOnline = ref.read(prIsOnlineProvider);
    final bool useOneClick =
        arg.oneClickToken != null && arg.oneClickToken!.isNotEmpty;

    final Either<Failure, void> res = useOneClick
        ? await ref
              .read(decideApprovalUseCaseProvider)
              .executeOneClick(
                tenantId: arg.tenantId,
                requisitionId: arg.requisitionId,
                approvalId: arg.approvalId,
                action: 'reject',
                token: arg.oneClickToken,
                reason: reason,
                actorId: arg.actorId,
                actorName: arg.actorName,
                isOnline: isOnline,
              )
        : await ref
              .read(decideApprovalUseCaseProvider)
              .reject(
                tenantId: arg.tenantId,
                requisitionId: arg.requisitionId,
                approvalId: arg.approvalId,
                actorId: arg.actorId,
                actorName: arg.actorName,
                reason: reason,
                isOnline: isOnline,
              );

    if (_disposed) {
      return const PrDetailOutcome(kind: PrDetailOutcomeKind.error);
    }

    return res.match(
      (Failure failure) {
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: failure.message,
        );
        return PrDetailOutcome(
          kind: PrDetailOutcomeKind.error,
          message: failure.message,
        );
      },
      (_) {
        state = state.copyWith(isSubmitting: false);
        return PrDetailOutcome(
          kind: isOnline
              ? PrDetailOutcomeKind.rejectedOnline
              : PrDetailOutcomeKind.rejectedQueuedOffline,
        );
      },
    );
  }
}

/// Provider for [PrDetailController], parameterized by [PrDetailArgs].
final prDetailControllerProvider = NotifierProvider.autoDispose
    .family<PrDetailController, PrDetailState, PrDetailArgs>(
      PrDetailController.new,
    );
