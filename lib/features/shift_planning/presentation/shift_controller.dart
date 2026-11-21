import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../app/session_controller.dart';
import '../data/platform_calendar_export.dart';
import '../data/shift_repository_impl.dart';
import '../domain/ical_exporter.dart';
import '../domain/shift_models.dart';
import '../domain/shift_repository.dart';

final Provider<ShiftRepository> shiftRepositoryProvider =
    Provider<ShiftRepository>(
      (Ref ref) => ShiftRepositoryImpl(
        ref.watch(databaseProvider),
        ref.watch(dioProvider),
        ref.watch(syncEngineProvider),
      ),
    );

/// Calendar hand-off (share sheet, Google Calendar); tests override it.
final Provider<CalendarExportService> calendarExportProvider =
    Provider<CalendarExportService>(
      (Ref ref) => const PlatformCalendarExport(),
    );

final Provider<IcalExporter> icalExporterProvider = Provider<IcalExporter>(
  (Ref ref) => const IcalExporter(),
);

/// Active tenant of the signed-in session (`null` when signed out). Tests override it.
final Provider<String?> shiftTenantIdProvider = Provider<String?>((Ref ref) {
  final SessionState? s = ref.watch(sessionProvider).value;
  return s is SignedIn ? s.bootstrap.tenantId : null;
});

// --- Calendar --------------------------------------------------------------------------------------------------

@immutable
class ShiftCalendarState {
  const ShiftCalendarState({
    this.mine = const <Shift>[],
    this.team = const <Shift>[],
    this.showTeam = false,
    this.loading = false,
    this.fromCache = false,
    this.error,
  });

  final List<Shift> mine;
  final List<Shift> team;
  final bool showTeam;
  final bool loading;

  /// The agenda shows the offline copy because the last refresh failed.
  final bool fromCache;
  final ShiftException? error;

  bool get forbidden => error?.kind == ShiftErrorKind.forbidden;

  /// The shifts on screen, oldest first: the own ones, plus the colleagues' when the team toggle is on.
  List<Shift> get visible {
    final List<Shift> all = showTeam ? <Shift>[...mine, ...team] : mine;
    return <Shift>[...all]
      ..sort((Shift a, Shift b) => a.startAt.compareTo(b.startAt));
  }

  /// The employee of the signed-in user, known as soon as one own shift is loaded.
  String? get myEmployeeId {
    for (final Shift s in mine) {
      if (s.employeeId != null) {
        return s.employeeId;
      }
    }
    return null;
  }

  ShiftCalendarState copyWith({
    List<Shift>? mine,
    List<Shift>? team,
    bool? showTeam,
    bool? loading,
    bool? fromCache,
    Object? error = _keep,
  }) {
    return ShiftCalendarState(
      mine: mine ?? this.mine,
      team: team ?? this.team,
      showTeam: showTeam ?? this.showTeam,
      loading: loading ?? this.loading,
      fromCache: fromCache ?? this.fromCache,
      error: identical(error, _keep) ? this.error : error as ShiftException?,
    );
  }

  static const Object _keep = Object();
}

/// Personal and team agenda of the published shifts, readable offline, with the calendar export.
class ShiftCalendarController extends Notifier<ShiftCalendarState> {
  late String? _tenantId;

  ShiftRepository get _repo => ref.read(shiftRepositoryProvider);

  @override
  ShiftCalendarState build() {
    // Re-created (and therefore emptied) when the tenant changes.
    _tenantId = ref.watch(shiftTenantIdProvider);
    return const ShiftCalendarState();
  }

  /// Shows the offline copy first, then refreshes from the API. Never throws.
  Future<void> load() async {
    final String? tenant = _tenantId;
    if (tenant == null) {
      return;
    }
    state = state.copyWith(loading: true, error: null);
    if (state.mine.isEmpty) {
      final List<Shift> cached = await _repo.cachedMyShifts(tenant);
      state = state.copyWith(mine: cached, fromCache: cached.isNotEmpty);
    }
    try {
      final List<Shift> mine = await _repo.refreshMyShifts(tenant);
      state = state.copyWith(mine: mine, fromCache: false);
      if (state.showTeam) {
        await _loadTeam(tenant);
      }
    } on ShiftException catch (e) {
      // Offline or server trouble keeps the cached agenda; "forbidden" means this role has no self-service.
      state = e.kind == ShiftErrorKind.forbidden
          ? state.copyWith(mine: const <Shift>[], fromCache: false, error: e)
          : state.copyWith(error: e);
    }
    state = state.copyWith(loading: false);
  }

  /// Turns the colleagues' shifts on or off; they are loaded the first time.
  Future<void> setShowTeam(bool value) async {
    state = state.copyWith(showTeam: value);
    final String? tenant = _tenantId;
    if (value && tenant != null && state.team.isEmpty) {
      final List<Shift> cached = await _repo.cachedTeamShifts(tenant);
      state = state.copyWith(team: cached);
      await _loadTeam(tenant);
    }
  }

  Future<void> _loadTeam(String tenant) async {
    try {
      state = state.copyWith(team: await _repo.refreshTeamShifts(tenant));
    } on ShiftException catch (e) {
      if (e.kind != ShiftErrorKind.offline) {
        state = state.copyWith(error: e);
      }
    }
  }

  /// Shares the own shifts from today on as an `.ics` file.
  Future<void> exportIcs(String languageCode, {DateTime? now}) async {
    final DateTime from = (now ?? DateTime.now()).toUtc();
    final List<Shift> upcoming = state.mine
        .where((Shift s) => s.endAt.isAfter(from))
        .toList();
    final String content = ref
        .read(icalExporterProvider)
        .build(upcoming, languageCode: languageCode, now: now);
    await ref
        .read(calendarExportProvider)
        .shareIcs(fileName: 'shifts.ics', content: content);
  }

  /// Opens the Google Calendar "add event" page of one shift.
  Future<bool> addToGoogleCalendar(Shift shift, String languageCode) {
    final Uri uri = ref
        .read(icalExporterProvider)
        .googleCalendarUri(shift, languageCode: languageCode);
    return ref.read(calendarExportProvider).openGoogleCalendar(uri);
  }
}

final NotifierProvider<ShiftCalendarController, ShiftCalendarState>
shiftCalendarProvider =
    NotifierProvider<ShiftCalendarController, ShiftCalendarState>(
      ShiftCalendarController.new,
    );

// --- Open shifts marketplace -----------------------------------------------------------------------------------

@immutable
class OpenShiftsState {
  const OpenShiftsState({
    this.shifts = const <Shift>[],
    this.loading = false,
    this.fromCache = false,
    this.error,
    this.busyIds = const <String>{},
    this.queue = const ClaimQueue(),
  });

  final List<Shift> shifts;
  final bool loading;
  final bool fromCache;
  final ShiftException? error;

  /// Claims in flight (the button is disabled).
  final Set<String> busyIds;
  final ClaimQueue queue;

  OpenShiftsState copyWith({
    List<Shift>? shifts,
    bool? loading,
    bool? fromCache,
    Object? error = _keep,
    Set<String>? busyIds,
    ClaimQueue? queue,
  }) {
    return OpenShiftsState(
      shifts: shifts ?? this.shifts,
      loading: loading ?? this.loading,
      fromCache: fromCache ?? this.fromCache,
      error: identical(error, _keep) ? this.error : error as ShiftException?,
      busyIds: busyIds ?? this.busyIds,
      queue: queue ?? this.queue,
    );
  }

  static const Object _keep = Object();
}

/// Open shifts that match the employee's skills and certificates, with a one-tap claim that is queued when offline.
class OpenShiftsController extends Notifier<OpenShiftsState> {
  late String? _tenantId;

  ShiftRepository get _repo => ref.read(shiftRepositoryProvider);

  @override
  OpenShiftsState build() {
    _tenantId = ref.watch(shiftTenantIdProvider);
    return const OpenShiftsState();
  }

  Future<void> load() async {
    final String? tenant = _tenantId;
    if (tenant == null) {
      return;
    }
    state = state.copyWith(loading: true, error: null);
    if (state.shifts.isEmpty) {
      final List<Shift> cached = await _repo.cachedOpenShifts(tenant);
      state = state.copyWith(shifts: cached, fromCache: cached.isNotEmpty);
    }
    try {
      state = state.copyWith(
        shifts: await _repo.refreshOpenShifts(tenant),
        fromCache: false,
      );
    } on ShiftException catch (e) {
      state = e.kind == ShiftErrorKind.forbidden
          ? state.copyWith(shifts: const <Shift>[], fromCache: false, error: e)
          : state.copyWith(error: e);
    }
    state = state.copyWith(
      loading: false,
      queue: await _repo.claimQueue(tenant),
    );
  }

  /// Claims a shift: validated at once when online, queued (and validated on delivery) when offline.
  Future<ClaimOutcome> claim(String shiftId) async {
    final String? tenant = _tenantId;
    if (tenant == null) {
      return const ClaimOutcome(ClaimStatus.queued);
    }
    state = state.copyWith(busyIds: <String>{...state.busyIds, shiftId});
    final ClaimOutcome outcome = await _repo.claim(tenant, shiftId);
    state = state.copyWith(
      busyIds: state.busyIds.where((String id) => id != shiftId).toSet(),
      queue: await _repo.claimQueue(tenant),
      shifts: outcome.status == ClaimStatus.claimed
          ? state.shifts.where((Shift s) => s.id != shiftId).toList()
          : state.shifts,
    );
    if (outcome.status == ClaimStatus.claimed) {
      // The shift is now one of the own ones.
      await ref.read(shiftCalendarProvider.notifier).load();
    }
    return outcome;
  }

  Future<void> retryClaim(String queueUuid) async {
    final String? tenant = _tenantId;
    if (tenant == null) {
      return;
    }
    await _repo.retryClaim(tenant, queueUuid);
    await load();
  }

  Future<void> dismissClaim(String queueUuid) async {
    final String? tenant = _tenantId;
    if (tenant == null) {
      return;
    }
    await _repo.dismissClaim(queueUuid);
    state = state.copyWith(queue: await _repo.claimQueue(tenant));
  }
}

final NotifierProvider<OpenShiftsController, OpenShiftsState>
openShiftsProvider = NotifierProvider<OpenShiftsController, OpenShiftsState>(
  OpenShiftsController.new,
);

// --- Peer swap wizard ------------------------------------------------------------------------------------------

/// Steps of the wizard: 0 shift, 1 colleague, 2 exchange (skipped for a broadcast), 3 review.
const int swapStepShift = 0;
const int swapStepColleague = 1;
const int swapStepExchange = 2;
const int swapStepReview = 3;

@immutable
class SwapWizardState {
  const SwapWizardState({
    this.step = swapStepShift,
    this.shift,
    this.peers = const <SwapPeer>[],
    this.peersLoading = false,
    this.peerId,
    this.broadcast = false,
    this.counterShiftId,
    this.submitting = false,
    this.error,
    this.result,
  });

  final int step;
  final Shift? shift;
  final List<SwapPeer> peers;
  final bool peersLoading;
  final String? peerId;
  final bool broadcast;
  final String? counterShiftId;
  final bool submitting;
  final ShiftException? error;
  final SwapRequest? result;

  SwapPeer? get peer {
    for (final SwapPeer p in peers) {
      if (p.employeeId == peerId) {
        return p;
      }
    }
    return null;
  }

  /// Whether the current step has what it needs to move on.
  bool get canAdvance => switch (step) {
    swapStepShift => shift != null && !peersLoading,
    swapStepColleague => broadcast || peerId != null,
    swapStepExchange => true,
    _ => false,
  };

  SwapWizardState copyWith({
    int? step,
    Object? shift = _keep,
    List<SwapPeer>? peers,
    bool? peersLoading,
    Object? peerId = _keep,
    bool? broadcast,
    Object? counterShiftId = _keep,
    bool? submitting,
    Object? error = _keep,
    Object? result = _keep,
  }) {
    return SwapWizardState(
      step: step ?? this.step,
      shift: identical(shift, _keep) ? this.shift : shift as Shift?,
      peers: peers ?? this.peers,
      peersLoading: peersLoading ?? this.peersLoading,
      peerId: identical(peerId, _keep) ? this.peerId : peerId as String?,
      broadcast: broadcast ?? this.broadcast,
      counterShiftId: identical(counterShiftId, _keep)
          ? this.counterShiftId
          : counterShiftId as String?,
      submitting: submitting ?? this.submitting,
      error: identical(error, _keep) ? this.error : error as ShiftException?,
      result: identical(result, _keep) ? this.result : result as SwapRequest?,
    );
  }

  static const Object _keep = Object();
}

/// Guided swap: pick the shift, pick an eligible colleague (or broadcast to every qualified one), optionally pick a
/// shift in exchange, review and send.
class SwapWizardController extends Notifier<SwapWizardState> {
  ShiftRepository get _repo => ref.read(shiftRepositoryProvider);

  @override
  SwapWizardState build() => const SwapWizardState();

  void reset() => state = const SwapWizardState();

  /// Chooses the shift to give away and loads the colleagues that could take it.
  Future<void> selectShift(Shift shift) async {
    state = SwapWizardState(shift: shift, peersLoading: true);
    try {
      final List<SwapPeer> peers = await _repo.eligiblePeers(shift.id);
      state = state.copyWith(peers: peers, peersLoading: false);
    } on ShiftException catch (e) {
      state = state.copyWith(peersLoading: false, error: e);
    }
  }

  void choosePeer(String employeeId) {
    state = state.copyWith(
      peerId: employeeId,
      broadcast: false,
      counterShiftId: null,
    );
  }

  void chooseBroadcast() {
    state = state.copyWith(peerId: null, broadcast: true, counterShiftId: null);
  }

  void chooseCounter(String? shiftId) {
    state = state.copyWith(counterShiftId: shiftId);
  }

  void next() {
    if (!state.canAdvance) {
      return;
    }
    final int target = switch (state.step) {
      swapStepShift => swapStepColleague,
      // A broadcast has no colleague yet, so there is no shift to take in exchange.
      swapStepColleague => state.broadcast ? swapStepReview : swapStepExchange,
      _ => swapStepReview,
    };
    state = state.copyWith(step: target, error: null);
  }

  void back() {
    final int target = switch (state.step) {
      swapStepReview => state.broadcast ? swapStepColleague : swapStepExchange,
      swapStepExchange => swapStepColleague,
      _ => swapStepShift,
    };
    state = state.copyWith(step: target, error: null);
  }

  /// Sends the request. The server checks both employees again; a refusal keeps the wizard on the review step.
  Future<SwapRequest?> submit() async {
    final Shift? shift = state.shift;
    if (shift == null ||
        state.submitting ||
        (!state.broadcast && state.peerId == null)) {
      return null;
    }
    state = state.copyWith(submitting: true, error: null);
    try {
      final SwapRequest request = await _repo.requestSwap(
        shift.id,
        peerEmployeeId: state.broadcast ? null : state.peerId,
        counterShiftId: state.broadcast ? null : state.counterShiftId,
      );
      state = state.copyWith(submitting: false, result: request);
      await ref.read(incomingSwapsProvider.notifier).load();
      return request;
    } on ShiftException catch (e) {
      state = state.copyWith(submitting: false, error: e);
      return null;
    }
  }
}

final NotifierProvider<SwapWizardController, SwapWizardState>
swapWizardProvider = NotifierProvider<SwapWizardController, SwapWizardState>(
  SwapWizardController.new,
);

// --- Swap inbox ------------------------------------------------------------------------------------------------

@immutable
class IncomingSwapsState {
  const IncomingSwapsState({
    this.swaps = const <SwapRequest>[],
    this.loading = false,
    this.fromCache = false,
    this.error,
    this.busyIds = const <String>{},
  });

  final List<SwapRequest> swaps;
  final bool loading;
  final bool fromCache;
  final ShiftException? error;
  final Set<String> busyIds;

  IncomingSwapsState copyWith({
    List<SwapRequest>? swaps,
    bool? loading,
    bool? fromCache,
    Object? error = _keep,
    Set<String>? busyIds,
  }) {
    return IncomingSwapsState(
      swaps: swaps ?? this.swaps,
      loading: loading ?? this.loading,
      fromCache: fromCache ?? this.fromCache,
      error: identical(error, _keep) ? this.error : error as ShiftException?,
      busyIds: busyIds ?? this.busyIds,
    );
  }

  /// Requests that wait for the answer of the signed-in employee.
  List<SwapRequest> incoming(String? myEmployeeId) => swaps
      .where(
        (SwapRequest s) =>
            s.status == SwapStatus.pendingPeerAcceptance &&
            s.requesterEmployeeId != myEmployeeId,
      )
      .toList();

  /// Requests the signed-in employee made.
  List<SwapRequest> mine(String? myEmployeeId) => swaps
      .where((SwapRequest s) => s.requesterEmployeeId == myEmployeeId)
      .toList();

  static const Object _keep = Object();
}

/// The swap requests addressed to the employee (accept / decline) and the ones the employee made.
class IncomingSwapsController extends Notifier<IncomingSwapsState> {
  late String? _tenantId;

  ShiftRepository get _repo => ref.read(shiftRepositoryProvider);

  @override
  IncomingSwapsState build() {
    _tenantId = ref.watch(shiftTenantIdProvider);
    return const IncomingSwapsState();
  }

  Future<void> load() async {
    final String? tenant = _tenantId;
    if (tenant == null) {
      return;
    }
    state = state.copyWith(loading: true, error: null);
    if (state.swaps.isEmpty) {
      final List<SwapRequest> cached = await _repo.cachedSwaps(tenant);
      state = state.copyWith(swaps: cached, fromCache: cached.isNotEmpty);
    }
    try {
      state = state.copyWith(
        swaps: await _repo.refreshSwaps(tenant),
        fromCache: false,
      );
    } on ShiftException catch (e) {
      state = state.copyWith(error: e);
    }
    state = state.copyWith(loading: false);
  }

  /// Accepts or declines a request. Returns `null` on success, otherwise the failure (the list is refreshed on 409/422).
  Future<ShiftException?> respond(String swapId, {required bool accept}) async {
    state = state.copyWith(busyIds: <String>{...state.busyIds, swapId});
    try {
      await _repo.respondToSwap(swapId, accept: accept);
      state = state.copyWith(
        busyIds: state.busyIds.where((String id) => id != swapId).toSet(),
      );
      await load();
      return null;
    } on ShiftException catch (e) {
      state = state.copyWith(
        busyIds: state.busyIds.where((String id) => id != swapId).toSet(),
      );
      if (e.kind == ShiftErrorKind.conflict ||
          e.kind == ShiftErrorKind.invalid) {
        await load();
      }
      return e;
    }
  }
}

final NotifierProvider<IncomingSwapsController, IncomingSwapsState>
incomingSwapsProvider =
    NotifierProvider<IncomingSwapsController, IncomingSwapsState>(
      IncomingSwapsController.new,
    );
