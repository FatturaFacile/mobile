import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/error/failure.dart';
import '../domain/use_cases/decide_approval_use_case.dart';
import '../presentation/providers/pr_providers.dart';
import '../presentation/screens/pr_detail_screen.dart';
import 'pr_notification_payload.dart';

/// Outcome of handling an actionable Purchase Requisition push notification or deep link.
enum PrNotificationOutcome {
  navigatedToDetail,
  approvedOnline,
  approvedQueuedOffline,
  rejectedOnline,
  rejectedQueuedOffline,
  needsRejectionReason,
  ignored,
  failed,
}

/// Result returned by [PrNotificationHandler] after processing a payload or deep link.
class PrNotificationResult {
  const PrNotificationResult({
    required this.outcome,
    this.requisitionId,
    this.message,
  });

  final PrNotificationOutcome outcome;
  final String? requisitionId;
  final String? message;
}

/// Handles incoming push notification actions (1-tap Approve / Reject / Open) and deep links for Mod 044.
class PrNotificationHandler {
  const PrNotificationHandler(
    this._decideApprovalUseCase, {
    required this.isOnline,
  });

  final DecideApprovalUseCase _decideApprovalUseCase;
  final bool Function() isOnline;

  /// Processes an incoming push notification data map for [activeTenantId].
  Future<PrNotificationResult> handlePayload(
    Map<String, dynamic> raw, {
    required String activeTenantId,
    required String actorId,
    required String actorName,
    GlobalKey<NavigatorState>? navigatorKey,
  }) async {
    final PrNotificationPayload? payload = PrNotificationPayload.tryParse(raw);
    if (payload == null) {
      return const PrNotificationResult(outcome: PrNotificationOutcome.ignored);
    }
    return _dispatch(
      payload,
      activeTenantId: activeTenantId,
      actorId: actorId,
      actorName: actorName,
      navigatorKey: navigatorKey,
    );
  }

  /// Processes an incoming deep link URI (e.g. `fatturafacile://procurement/purchase-requisitions/{id}`).
  Future<PrNotificationResult> handleDeepLink(
    Uri uri, {
    required String activeTenantId,
    required String actorId,
    required String actorName,
    GlobalKey<NavigatorState>? navigatorKey,
  }) async {
    final PrNotificationPayload? payload = PrNotificationPayload.tryParseUri(
      uri,
    );
    if (payload == null) {
      return const PrNotificationResult(outcome: PrNotificationOutcome.ignored);
    }
    return _dispatch(
      payload,
      activeTenantId: activeTenantId,
      actorId: actorId,
      actorName: actorName,
      navigatorKey: navigatorKey,
    );
  }

  Future<PrNotificationResult> _dispatch(
    PrNotificationPayload payload, {
    required String activeTenantId,
    required String actorId,
    required String actorName,
    GlobalKey<NavigatorState>? navigatorKey,
  }) async {
    if (payload.tenantId != null && payload.tenantId != activeTenantId) {
      return PrNotificationResult(
        outcome: PrNotificationOutcome.ignored,
        requisitionId: payload.requisitionId,
      );
    }

    final bool online = isOnline();
    switch (payload.action) {
      case PrNotificationAction.approve:
        final Either<Failure, void> res = await _decideApprovalUseCase
            .executeOneClick(
              tenantId: activeTenantId,
              requisitionId: payload.requisitionId,
              approvalId: payload.approvalId,
              action: 'approve',
              token: payload.oneClickToken,
              actorId: actorId,
              actorName: actorName,
              isOnline: online,
            );
        return res.match(
          (Failure f) => PrNotificationResult(
            outcome: PrNotificationOutcome.failed,
            requisitionId: payload.requisitionId,
            message: f.message,
          ),
          (_) => PrNotificationResult(
            outcome: online
                ? PrNotificationOutcome.approvedOnline
                : PrNotificationOutcome.approvedQueuedOffline,
            requisitionId: payload.requisitionId,
          ),
        );

      case PrNotificationAction.reject:
        final String? reason = payload.rejectionReason?.trim();
        if (reason != null && reason.isNotEmpty) {
          final Either<Failure, void> res = await _decideApprovalUseCase
              .executeOneClick(
                tenantId: activeTenantId,
                requisitionId: payload.requisitionId,
                approvalId: payload.approvalId,
                action: 'reject',
                token: payload.oneClickToken,
                reason: reason,
                actorId: actorId,
                actorName: actorName,
                isOnline: online,
              );
          return res.match(
            (Failure f) => PrNotificationResult(
              outcome: PrNotificationOutcome.failed,
              requisitionId: payload.requisitionId,
              message: f.message,
            ),
            (_) => PrNotificationResult(
              outcome: online
                  ? PrNotificationOutcome.rejectedOnline
                  : PrNotificationOutcome.rejectedQueuedOffline,
              requisitionId: payload.requisitionId,
            ),
          );
        }
        _navigateToDetail(
          navigatorKey: navigatorKey,
          tenantId: activeTenantId,
          payload: payload,
          actorId: actorId,
          actorName: actorName,
          openRejectSheetOnLoad: true,
        );
        return PrNotificationResult(
          outcome: PrNotificationOutcome.needsRejectionReason,
          requisitionId: payload.requisitionId,
        );

      case PrNotificationAction.open:
        _navigateToDetail(
          navigatorKey: navigatorKey,
          tenantId: activeTenantId,
          payload: payload,
          actorId: actorId,
          actorName: actorName,
          openRejectSheetOnLoad: false,
        );
        return PrNotificationResult(
          outcome: PrNotificationOutcome.navigatedToDetail,
          requisitionId: payload.requisitionId,
        );
    }
  }

  void _navigateToDetail({
    required GlobalKey<NavigatorState>? navigatorKey,
    required String tenantId,
    required PrNotificationPayload payload,
    required String actorId,
    required String actorName,
    required bool openRejectSheetOnLoad,
  }) {
    final NavigatorState? nav = navigatorKey?.currentState;
    if (nav == null) {
      return;
    }
    nav.push(
      MaterialPageRoute<void>(
        builder: (_) => PrDetailScreen(
          tenantId: tenantId,
          requisitionId: payload.requisitionId,
          actorId: actorId,
          actorName: actorName,
          approvalId: payload.approvalId,
          oneClickToken: payload.oneClickToken,
          isManagerApproval: true,
          openRejectSheetOnLoad: openRejectSheetOnLoad,
        ),
      ),
    );
  }
}

/// Provider wiring [PrNotificationHandler] with [DecideApprovalUseCase] and connectivity state.
final Provider<PrNotificationHandler> prNotificationHandlerProvider =
    Provider<PrNotificationHandler>((Ref ref) {
      return PrNotificationHandler(
        ref.watch(decideApprovalUseCaseProvider),
        isOnline: () => ref.read(prIsOnlineProvider),
      );
    });
