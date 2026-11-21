import 'package:fattura_facile/features/shift_planning/domain/shift_models.dart';
import 'package:fattura_facile/features/shift_planning/domain/shift_repository.dart';

/// A published shift; [tags] are the wire names of the surcharge tags.
Shift fakeShift(
  String id, {
  String date = '2026-12-07',
  String code = 'MAT',
  String? employeeId = 'e1',
  String? employeeName,
  List<SurchargeTag> tags = const <SurchargeTag>[],
  List<ComplianceIssue> warnings = const <ComplianceIssue>[],
  DateTime? startAt,
}) {
  final DateTime start = startAt ?? DateTime.parse('${date}T05:00:00Z');
  return Shift(
    id: id,
    periodId: 'p1',
    employeeId: employeeId,
    employeeName: employeeName,
    date: date,
    startAt: start,
    endAt: start.add(const Duration(hours: 8)),
    templateCode: code,
    templateName: const <String, String>{'en': 'Morning', 'it': 'Mattina'},
    tags: tags,
    warnings: warnings,
  );
}

SwapRequest fakeSwap(
  String id, {
  String requester = 'e2',
  String? peer = 'e1',
  SwapStatus status = SwapStatus.pendingPeerAcceptance,
  Shift? assignment,
}) {
  return SwapRequest(
    id: id,
    requesterEmployeeId: requester,
    targetPeerEmployeeId: peer,
    shiftAssignmentId: 'a-$id',
    status: status,
    assignment: assignment ?? fakeShift('a-$id', employeeId: requester),
  );
}

class FakeShiftRepository implements ShiftRepository {
  List<Shift> myCache = <Shift>[];
  List<Shift> myRemote = <Shift>[];
  List<Shift> teamCache = <Shift>[];
  List<Shift> teamRemote = <Shift>[];
  List<Shift> openCache = <Shift>[];
  List<Shift> openRemote = <Shift>[];
  List<SwapRequest> swapCache = <SwapRequest>[];
  List<SwapRequest> swapRemote = <SwapRequest>[];
  List<SwapPeer> peers = <SwapPeer>[];

  ShiftException? refreshError;
  ShiftException? peersError;
  ShiftException? swapError;
  ShiftException? respondError;
  ClaimOutcome claimOutcome = const ClaimOutcome(ClaimStatus.claimed);
  ClaimQueue queue = const ClaimQueue();

  final List<String> claimed = <String>[];
  final List<String> retried = <String>[];
  final List<String> dismissed = <String>[];
  final List<({String shiftId, String? peer, String? counter})> swapRequests =
      <({String shiftId, String? peer, String? counter})>[];
  final List<({String id, bool accept})> responses =
      <({String id, bool accept})>[];

  @override
  Future<List<Shift>> cachedMyShifts(String tenantId) async => myCache;

  @override
  Future<List<Shift>> refreshMyShifts(
    String tenantId, {
    DateTime? from,
    DateTime? to,
  }) async {
    if (refreshError != null) {
      throw refreshError!;
    }
    return myRemote;
  }

  @override
  Future<List<Shift>> cachedTeamShifts(String tenantId) async => teamCache;

  @override
  Future<List<Shift>> refreshTeamShifts(
    String tenantId, {
    DateTime? from,
    DateTime? to,
  }) async {
    if (refreshError != null) {
      throw refreshError!;
    }
    return teamRemote;
  }

  @override
  Future<List<Shift>> cachedOpenShifts(String tenantId) async => openCache;

  @override
  Future<List<Shift>> refreshOpenShifts(
    String tenantId, {
    DateTime? from,
    DateTime? to,
  }) async {
    if (refreshError != null) {
      throw refreshError!;
    }
    return openRemote;
  }

  @override
  Future<ClaimOutcome> claim(String tenantId, String shiftId) async {
    claimed.add(shiftId);
    return claimOutcome;
  }

  @override
  Future<ClaimQueue> claimQueue(String tenantId) async => queue;

  @override
  Future<void> retryClaim(String tenantId, String queueUuid) async =>
      retried.add(queueUuid);

  @override
  Future<void> dismissClaim(String queueUuid) async => dismissed.add(queueUuid);

  @override
  Future<List<SwapPeer>> eligiblePeers(String shiftId) async {
    if (peersError != null) {
      throw peersError!;
    }
    return peers;
  }

  @override
  Future<SwapRequest> requestSwap(
    String shiftId, {
    String? peerEmployeeId,
    String? counterShiftId,
  }) async {
    swapRequests.add((
      shiftId: shiftId,
      peer: peerEmployeeId,
      counter: counterShiftId,
    ));
    if (swapError != null) {
      throw swapError!;
    }
    return fakeSwap('new', requester: 'e1', peer: peerEmployeeId);
  }

  @override
  Future<List<SwapRequest>> cachedSwaps(String tenantId) async => swapCache;

  @override
  Future<List<SwapRequest>> refreshSwaps(String tenantId) async {
    if (refreshError != null) {
      throw refreshError!;
    }
    return swapRemote;
  }

  @override
  Future<SwapRequest> respondToSwap(
    String swapId, {
    required bool accept,
  }) async {
    responses.add((id: swapId, accept: accept));
    if (respondError != null) {
      throw respondError!;
    }
    return fakeSwap(
      swapId,
      status: accept ? SwapStatus.pendingManagerApproval : SwapStatus.rejected,
    );
  }
}

class FakeCalendarExport implements CalendarExportService {
  final List<({String fileName, String content})> shared =
      <({String fileName, String content})>[];
  final List<Uri> opened = <Uri>[];

  @override
  Future<void> shareIcs({
    required String fileName,
    required String content,
  }) async {
    shared.add((fileName: fileName, content: content));
  }

  @override
  Future<bool> openGoogleCalendar(Uri uri) async {
    opened.add(uri);
    return true;
  }
}
