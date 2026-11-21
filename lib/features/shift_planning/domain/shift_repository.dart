import 'package:flutter/foundation.dart';

import 'shift_models.dart';

/// Why a call of the shift planner failed; the UI maps it to a localized message.
enum ShiftErrorKind { forbidden, notFound, conflict, invalid, offline, unknown }

class ShiftException implements Exception {
  const ShiftException(
    this.kind, {
    this.detail = '',
    this.issues = const <ComplianceIssue>[],
  });

  final ShiftErrorKind kind;

  /// `detail` of the RFC 7807 problem.
  final String detail;

  /// Findings of a 422 compliance failure (`invalid_params`), blocking and warnings.
  final List<ComplianceIssue> issues;

  @override
  String toString() => 'ShiftException($kind, $detail)';
}

/// What happened to a claim of an open shift.
enum ClaimStatus {
  /// The server assigned the shift to the employee.
  claimed,

  /// Stored in the offline outbox: it is sent, and validated, as soon as the device is online.
  queued,

  /// The server refused the claim for good (rule violation, shift taken); [ClaimOutcome.detail] says why.
  rejected,
}

@immutable
class ClaimOutcome {
  const ClaimOutcome(this.status, {this.detail = ''});

  final ClaimStatus status;
  final String detail;
}

/// A claim the server refused after it had been queued offline.
@immutable
class RejectedClaim {
  const RejectedClaim({
    required this.queueUuid,
    required this.shiftId,
    required this.detail,
  });

  final String queueUuid;
  final String shiftId;
  final String detail;
}

/// Offline-outbox picture of the claims of one tenant.
@immutable
class ClaimQueue {
  const ClaimQueue({
    this.waitingShiftIds = const <String>{},
    this.rejected = const <RejectedClaim>[],
  });

  final Set<String> waitingShiftIds;
  final List<RejectedClaim> rejected;
}

/// Backend gateway, offline cache and claim outbox of the employee self-service. Failures throw [ShiftException].
abstract interface class ShiftRepository {
  /// Shifts stored by the last successful refresh (offline reading).
  Future<List<Shift>> cachedMyShifts(String tenantId);
  Future<List<Shift>> refreshMyShifts(
    String tenantId, {
    DateTime? from,
    DateTime? to,
  });

  Future<List<Shift>> cachedTeamShifts(String tenantId);
  Future<List<Shift>> refreshTeamShifts(
    String tenantId, {
    DateTime? from,
    DateTime? to,
  });

  /// Open shifts the employee could claim (skills, certificates and rest rules already checked by the API).
  Future<List<Shift>> cachedOpenShifts(String tenantId);
  Future<List<Shift>> refreshOpenShifts(
    String tenantId, {
    DateTime? from,
    DateTime? to,
  });

  /// Queues the claim in the outbox and tries to send it right away.
  Future<ClaimOutcome> claim(String tenantId, String shiftId);
  Future<ClaimQueue> claimQueue(String tenantId);
  Future<void> retryClaim(String tenantId, String queueUuid);
  Future<void> dismissClaim(String queueUuid);

  Future<List<SwapPeer>> eligiblePeers(String shiftId);

  /// Swaps need the verdict of the server, so they are online-only. A null [peerEmployeeId] broadcasts the offer.
  Future<SwapRequest> requestSwap(
    String shiftId, {
    String? peerEmployeeId,
    String? counterShiftId,
  });

  Future<List<SwapRequest>> cachedSwaps(String tenantId);
  Future<List<SwapRequest>> refreshSwaps(String tenantId);

  /// The colleague accepts (`true`) or declines (`false`) a swap.
  Future<SwapRequest> respondToSwap(String swapId, {required bool accept});
}

/// Exports shifts to the calendar of the device or to Google Calendar. The default implementation shares an `.ics`
/// file; tests override it.
abstract interface class CalendarExportService {
  /// Hands the iCalendar [content] to the system (share sheet / calendar app).
  Future<void> shareIcs({required String fileName, required String content});

  /// Opens the Google Calendar "add event" page of one shift.
  Future<bool> openGoogleCalendar(Uri uri);
}
