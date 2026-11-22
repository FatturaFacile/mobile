import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../data/resource_planning_repository_impl.dart';
import '../domain/resource_planning_models.dart';
import '../domain/resource_planning_repository.dart';

final Provider<ResourcePlanningRepository> resourcePlanningRepositoryProvider =
    Provider<ResourcePlanningRepository>(
      (Ref ref) => ResourcePlanningRepositoryImpl(ref.watch(dioProvider)),
    );

/// Current time of the module; tests override it.
final Provider<DateTime Function()> resourcePlanningClockProvider =
    Provider<DateTime Function()>((Ref ref) => DateTime.now);

/// `Y-m-d` of a date, as the API expects it.
String ymd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// Monday of the week of [d].
DateTime mondayOf(DateTime d) {
  final DateTime day = DateTime.utc(d.year, d.month, d.day);
  return day.subtract(Duration(days: day.weekday - DateTime.monday));
}

/// Number of weeks the capacity view looks ahead.
const int capacityHorizonWeeks = 8;

/// Days the allocation agenda looks ahead.
const int agendaHorizonDays = 60;

/// Remote data of one screen: the last loaded value, whether a call is running and the last failure.
@immutable
class PlanningLoad<T> {
  const PlanningLoad({this.data, this.loading = false, this.error});

  final T? data;
  final bool loading;
  final ResourcePlanningException? error;

  bool get forbidden => error?.kind == ResourcePlanningErrorKind.forbidden;

  PlanningLoad<T> started() => PlanningLoad<T>(data: data, loading: true);

  PlanningLoad<T> loaded(T value) => PlanningLoad<T>(data: value);

  PlanningLoad<T> failed(ResourcePlanningException e) =>
      PlanningLoad<T>(data: data, error: e);
}

ResourcePlanningException _asException(Object e) =>
    e is ResourcePlanningException
    ? e
    : const ResourcePlanningException(ResourcePlanningErrorKind.unknown);

// --- Capacity --------------------------------------------------------------------------------------------------

/// Saturation heatmap of the next weeks, one row per employee.
class CapacityController extends Notifier<PlanningLoad<CapacityHeatmap>> {
  ResourcePlanningRepository get _repo =>
      ref.read(resourcePlanningRepositoryProvider);

  @override
  PlanningLoad<CapacityHeatmap> build() =>
      const PlanningLoad<CapacityHeatmap>();

  Future<void> load() async {
    state = state.started();
    final DateTime from = mondayOf(ref.read(resourcePlanningClockProvider)());
    final DateTime to = from.add(
      const Duration(days: capacityHorizonWeeks * 7 - 1),
    );
    try {
      state = state.loaded(
        await _repo.heatmap(from: ymd(from), to: ymd(to), granularity: 'week'),
      );
    } on Object catch (e) {
      state = state.failed(_asException(e));
    }
  }
}

final NotifierProvider<CapacityController, PlanningLoad<CapacityHeatmap>>
capacityProvider =
    NotifierProvider<CapacityController, PlanningLoad<CapacityHeatmap>>(
      CapacityController.new,
    );

// --- Allocations -----------------------------------------------------------------------------------------------

/// What an allocation action produced: either a result (with the overload verdict) or the failure.
@immutable
class AllocationActionOutcome {
  const AllocationActionOutcome.success(AllocationMutationResult this.result)
    : error = null;

  const AllocationActionOutcome.failure(ResourcePlanningException this.error)
    : result = null;

  final AllocationMutationResult? result;
  final ResourcePlanningException? error;

  bool get ok => result != null;
}

/// Agenda of the allocations with the convert-to-hard and move actions.
class AllocationsController
    extends Notifier<PlanningLoad<List<ResourceAllocation>>> {
  ResourcePlanningRepository get _repo =>
      ref.read(resourcePlanningRepositoryProvider);

  @override
  PlanningLoad<List<ResourceAllocation>> build() =>
      const PlanningLoad<List<ResourceAllocation>>();

  Future<void> load() async {
    state = state.started();
    final DateTime from = ref.read(resourcePlanningClockProvider)();
    final DateTime to = from.add(const Duration(days: agendaHorizonDays));
    try {
      final List<ResourceAllocation> rows = await _repo.allocations(
        from: ymd(from),
        to: ymd(to),
      );
      state = state.loaded(_sorted(rows));
    } on Object catch (e) {
      state = state.failed(_asException(e));
    }
  }

  /// Turns a soft booking into a hard one. [projectId] is needed when the booking only has an opportunity.
  Future<AllocationActionOutcome> convertToHard(
    ResourceAllocation allocation, {
    String? projectId,
  }) => _mutate(
    allocation,
    () => _repo.convertToHard(allocation.id, projectId: projectId),
  );

  /// Moves the allocation by [days] days (negative = earlier), keeping its duration.
  Future<AllocationActionOutcome> move(
    ResourceAllocation allocation,
    int days,
  ) => _mutate(
    allocation,
    () => _repo.rebalance(allocation.id, RebalanceRequest.shiftBy(days)),
  );

  /// Hands the allocation over to a colleague.
  Future<AllocationActionOutcome> reassign(
    ResourceAllocation allocation,
    String employeeId,
  ) => _mutate(
    allocation,
    () => _repo.rebalance(allocation.id, RebalanceRequest.reassignTo(employeeId)),
  );

  Future<AllocationActionOutcome> _mutate(
    ResourceAllocation allocation,
    Future<AllocationMutationResult> Function() call,
  ) async {
    try {
      final AllocationMutationResult result = await call();
      final List<ResourceAllocation> current =
          state.data ?? const <ResourceAllocation>[];
      final Set<String> replacedIds = <String>{
        allocation.id,
        for (final ResourceAllocation a in result.allocations) a.id,
      };
      state = state.loaded(
        _sorted(<ResourceAllocation>[
          ...current.where((ResourceAllocation a) => !replacedIds.contains(a.id)),
          ...result.allocations,
        ]),
      );
      return AllocationActionOutcome.success(result);
    } on Object catch (e) {
      return AllocationActionOutcome.failure(_asException(e));
    }
  }

  List<ResourceAllocation> _sorted(List<ResourceAllocation> rows) =>
      <ResourceAllocation>[...rows]..sort((
        ResourceAllocation a,
        ResourceAllocation b,
      ) {
        final int byDate = a.startDate.compareTo(b.startDate);
        return byDate != 0 ? byDate : a.employeeName.compareTo(b.employeeName);
      });
}

final NotifierProvider<
  AllocationsController,
  PlanningLoad<List<ResourceAllocation>>
>
allocationsProvider =
    NotifierProvider<
      AllocationsController,
      PlanningLoad<List<ResourceAllocation>>
    >(AllocationsController.new);

// --- Candidates ------------------------------------------------------------------------------------------------

/// State of the candidate suggestions for a role.
@immutable
class CandidatesState {
  const CandidatesState({
    this.skills = const PlanningLoad<List<Skill>>(),
    this.candidates,
    this.searching = false,
    this.error,
  });

  final PlanningLoad<List<Skill>> skills;

  /// Result of the last search; null before the first one.
  final List<Candidate>? candidates;
  final bool searching;
  final ResourcePlanningException? error;

  CandidatesState copyWith({
    PlanningLoad<List<Skill>>? skills,
    List<Candidate>? Function()? candidates,
    bool? searching,
    ResourcePlanningException? Function()? error,
  }) => CandidatesState(
    skills: skills ?? this.skills,
    candidates: candidates == null ? this.candidates : candidates(),
    searching: searching ?? this.searching,
    error: error == null ? this.error : error(),
  );
}

class CandidatesController extends Notifier<CandidatesState> {
  ResourcePlanningRepository get _repo =>
      ref.read(resourcePlanningRepositoryProvider);

  @override
  CandidatesState build() => const CandidatesState();

  /// Loads the skill taxonomy used to describe the role.
  Future<void> loadSkills() async {
    state = state.copyWith(skills: state.skills.started());
    try {
      final List<Skill> skills = await _repo.skills();
      state = state.copyWith(skills: state.skills.loaded(skills));
    } on Object catch (e) {
      state = state.copyWith(skills: state.skills.failed(_asException(e)));
    }
  }

  Future<void> search(CandidateQuery query) async {
    state = state.copyWith(searching: true, error: () => null);
    try {
      final List<Candidate> found = await _repo.searchCandidates(query);
      state = state.copyWith(
        searching: false,
        candidates: () => <Candidate>[
          ...found,
        ]..sort((Candidate a, Candidate b) => b.score.compareTo(a.score)),
      );
    } on Object catch (e) {
      state = state.copyWith(searching: false, error: () => _asException(e));
    }
  }
}

final NotifierProvider<CandidatesController, CandidatesState>
candidatesProvider = NotifierProvider<CandidatesController, CandidatesState>(
  CandidatesController.new,
);

// --- Utilization -----------------------------------------------------------------------------------------------

/// Billable utilization of the current month, target versus actual.
class UtilizationController extends Notifier<PlanningLoad<UtilizationReport>> {
  ResourcePlanningRepository get _repo =>
      ref.read(resourcePlanningRepositoryProvider);

  @override
  PlanningLoad<UtilizationReport> build() =>
      const PlanningLoad<UtilizationReport>();

  Future<void> load({
    UtilizationGroup groupBy = UtilizationGroup.resource,
  }) async {
    state = state.started();
    final DateTime now = ref.read(resourcePlanningClockProvider)();
    final DateTime from = DateTime.utc(now.year, now.month);
    final DateTime to = DateTime.utc(now.year, now.month + 1, 0);
    try {
      state = state.loaded(
        await _repo.utilization(
          from: ymd(from),
          to: ymd(to),
          groupBy: groupBy,
        ),
      );
    } on Object catch (e) {
      state = state.failed(_asException(e));
    }
  }
}

final NotifierProvider<UtilizationController, PlanningLoad<UtilizationReport>>
utilizationProvider =
    NotifierProvider<UtilizationController, PlanningLoad<UtilizationReport>>(
      UtilizationController.new,
    );
