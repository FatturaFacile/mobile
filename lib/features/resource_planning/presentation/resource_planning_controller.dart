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

  /// Applies any rebalance (resize, shift, reassign, split); a split puts both parts on the agenda.
  Future<AllocationActionOutcome> rebalance(
    ResourceAllocation allocation,
    RebalanceRequest request,
  ) => _mutate(allocation, () => _repo.rebalance(allocation.id, request));

  /// Creates an allocation and puts every affected row on the agenda.
  Future<AllocationActionOutcome> create(AllocationDraft draft) async {
    try {
      final AllocationMutationResult result = await _repo.createAllocation(
        draft,
      );
      final List<ResourceAllocation> current =
          state.data ?? const <ResourceAllocation>[];
      final Set<String> ids = <String>{
        for (final ResourceAllocation a in result.allocations) a.id,
      };
      state = state.loaded(
        _sorted(<ResourceAllocation>[
          ...current.where((ResourceAllocation a) => !ids.contains(a.id)),
          ...result.allocations,
        ]),
      );
      return AllocationActionOutcome.success(result);
    } on Object catch (e) {
      return AllocationActionOutcome.failure(_asException(e));
    }
  }

  /// Deletes the allocation and takes it off the agenda.
  Future<PlanningOutcome> delete(ResourceAllocation allocation) =>
      _guard(() async {
        await _repo.deleteAllocation(allocation.id);
        state = state.loaded(
          (state.data ?? const <ResourceAllocation>[])
              .where((ResourceAllocation a) => a.id != allocation.id)
              .toList(),
        );
      });

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

// --- Planning setup ----------------------------------------------------------------------------------------------

/// Outcome of a write that returns no data worth keeping: it either worked or failed with [error].
@immutable
class PlanningOutcome {
  const PlanningOutcome.success() : error = null;

  const PlanningOutcome.failure(ResourcePlanningException this.error);

  final ResourcePlanningException? error;

  bool get ok => error == null;
}

Future<PlanningOutcome> _guard(Future<void> Function() run) async {
  try {
    await run();
    return const PlanningOutcome.success();
  } on Object catch (e) {
    return PlanningOutcome.failure(_asException(e));
  }
}

/// Bookable employees, shared by the allocation form, the rebalance editor, the skill profiles and the targets.
class ResourcesController extends Notifier<PlanningLoad<List<ResourceLookup>>> {
  ResourcePlanningRepository get _repo =>
      ref.read(resourcePlanningRepositoryProvider);

  @override
  PlanningLoad<List<ResourceLookup>> build() =>
      const PlanningLoad<List<ResourceLookup>>();

  Future<void> load() async {
    state = state.started();
    try {
      final List<ResourceLookup> rows = await _repo.resources();
      state = state.loaded(
        <ResourceLookup>[...rows]..sort(
          (ResourceLookup a, ResourceLookup b) =>
              a.fullName.compareTo(b.fullName),
        ),
      );
    } on Object catch (e) {
      state = state.failed(_asException(e));
    }
  }
}

final NotifierProvider<ResourcesController, PlanningLoad<List<ResourceLookup>>>
resourcesProvider =
    NotifierProvider<ResourcesController, PlanningLoad<List<ResourceLookup>>>(
      ResourcesController.new,
    );

/// Search of the project picker; a failed search leaves the picker with the manual id input.
class ProjectSearchController extends Notifier<PlanningLoad<List<ProjectRef>>> {
  ResourcePlanningRepository get _repo =>
      ref.read(resourcePlanningRepositoryProvider);

  @override
  PlanningLoad<List<ProjectRef>> build() =>
      const PlanningLoad<List<ProjectRef>>();

  Future<void> search(String term) async {
    state = state.started();
    try {
      state = state.loaded(await _repo.projects(search: term));
    } on Object catch (e) {
      state = state.failed(_asException(e));
    }
  }
}

final NotifierProvider<ProjectSearchController, PlanningLoad<List<ProjectRef>>>
projectSearchProvider =
    NotifierProvider<ProjectSearchController, PlanningLoad<List<ProjectRef>>>(
      ProjectSearchController.new,
    );

/// Skill taxonomy maintenance: list, create, edit, delete.
class SkillsController extends Notifier<PlanningLoad<List<Skill>>> {
  ResourcePlanningRepository get _repo =>
      ref.read(resourcePlanningRepositoryProvider);

  @override
  PlanningLoad<List<Skill>> build() => const PlanningLoad<List<Skill>>();

  Future<void> load() async {
    state = state.started();
    try {
      state = state.loaded(_sorted(await _repo.skills()));
    } on Object catch (e) {
      state = state.failed(_asException(e));
    }
  }

  /// Creates the skill, or updates [existing] when given.
  Future<PlanningOutcome> save(SkillDraft draft, {Skill? existing}) =>
      _guard(() async {
        final Skill saved = existing == null
            ? await _repo.createSkill(draft)
            : await _repo.updateSkill(existing.id, draft);
        final List<Skill> current = state.data ?? const <Skill>[];
        state = state.loaded(
          _sorted(<Skill>[
            ...current.where((Skill s) => s.id != saved.id),
            saved,
          ]),
        );
      });

  Future<PlanningOutcome> delete(Skill skill) => _guard(() async {
    await _repo.deleteSkill(skill.id);
    state = state.loaded(
      (state.data ?? const <Skill>[])
          .where((Skill s) => s.id != skill.id)
          .toList(),
    );
  });

  List<Skill> _sorted(List<Skill> rows) =>
      <Skill>[...rows]..sort((Skill a, Skill b) {
        final int byCategory = a.category.compareTo(b.category);
        return byCategory != 0 ? byCategory : a.skillName.compareTo(b.skillName);
      });
}

final NotifierProvider<SkillsController, PlanningLoad<List<Skill>>>
skillsProvider = NotifierProvider<SkillsController, PlanningLoad<List<Skill>>>(
  SkillsController.new,
);

/// Skill profile of one employee: proficiency per skill, upsert and delete.
class SkillProfilesController
    extends Notifier<PlanningLoad<List<EmployeeSkillProfile>>> {
  ResourcePlanningRepository get _repo =>
      ref.read(resourcePlanningRepositoryProvider);

  @override
  PlanningLoad<List<EmployeeSkillProfile>> build() =>
      const PlanningLoad<List<EmployeeSkillProfile>>();

  Future<void> load(String employeeId) async {
    state = state.started();
    try {
      state = state.loaded(
        _sorted(await _repo.skillProfiles(employeeId: employeeId)),
      );
    } on Object catch (e) {
      state = state.failed(_asException(e));
    }
  }

  /// Creates the profile or raises/lowers the existing one of the same skill.
  Future<PlanningOutcome> save(SkillProfileDraft draft) => _guard(() async {
    final EmployeeSkillProfile saved = await _repo.saveSkillProfile(draft);
    final List<EmployeeSkillProfile> current =
        state.data ?? const <EmployeeSkillProfile>[];
    state = state.loaded(
      _sorted(<EmployeeSkillProfile>[
        ...current.where(
          (EmployeeSkillProfile p) =>
              p.id != saved.id && p.skillId != saved.skillId,
        ),
        saved,
      ]),
    );
  });

  Future<PlanningOutcome> delete(EmployeeSkillProfile profile) =>
      _guard(() async {
        await _repo.deleteSkillProfile(profile.id);
        state = state.loaded(
          (state.data ?? const <EmployeeSkillProfile>[])
              .where((EmployeeSkillProfile p) => p.id != profile.id)
              .toList(),
        );
      });

  List<EmployeeSkillProfile> _sorted(List<EmployeeSkillProfile> rows) =>
      <EmployeeSkillProfile>[...rows]..sort(
        (EmployeeSkillProfile a, EmployeeSkillProfile b) =>
            a.skillName.compareTo(b.skillName),
      );
}

final NotifierProvider<
  SkillProfilesController,
  PlanningLoad<List<EmployeeSkillProfile>>
>
skillProfilesProvider =
    NotifierProvider<
      SkillProfilesController,
      PlanningLoad<List<EmployeeSkillProfile>>
    >(SkillProfilesController.new);

/// Billable utilization targets: the tenant default plus one per department or cost center.
class UtilizationTargetsController
    extends Notifier<PlanningLoad<List<UtilizationTarget>>> {
  ResourcePlanningRepository get _repo =>
      ref.read(resourcePlanningRepositoryProvider);

  @override
  PlanningLoad<List<UtilizationTarget>> build() =>
      const PlanningLoad<List<UtilizationTarget>>();

  Future<void> load() async {
    state = state.started();
    try {
      state = state.loaded(_sorted(await _repo.utilizationTargets()));
    } on Object catch (e) {
      state = state.failed(_asException(e));
    }
  }

  Future<PlanningOutcome> save(UtilizationTargetDraft draft) => _guard(() async {
    final UtilizationTarget saved = await _repo.saveUtilizationTarget(draft);
    final List<UtilizationTarget> current =
        state.data ?? const <UtilizationTarget>[];
    state = state.loaded(
      _sorted(<UtilizationTarget>[
        ...current.where(
          (UtilizationTarget t) =>
              t.id != saved.id &&
              !(t.departmentId == saved.departmentId &&
                  t.costCenterId == saved.costCenterId),
        ),
        saved,
      ]),
    );
  });

  /// Default first, then departments, then cost centers.
  List<UtilizationTarget> _sorted(List<UtilizationTarget> rows) =>
      <UtilizationTarget>[...rows]..sort(
        (UtilizationTarget a, UtilizationTarget b) =>
            _rank(a).compareTo(_rank(b)),
      );

  int _rank(UtilizationTarget t) => t.isDefault
      ? 0
      : t.departmentId != null
      ? 1
      : 2;
}

final NotifierProvider<
  UtilizationTargetsController,
  PlanningLoad<List<UtilizationTarget>>
>
utilizationTargetsProvider =
    NotifierProvider<
      UtilizationTargetsController,
      PlanningLoad<List<UtilizationTarget>>
    >(UtilizationTargetsController.new);

/// Tenant local holidays: list, add, remove.
class LocalHolidaysController
    extends Notifier<PlanningLoad<List<LocalHoliday>>> {
  ResourcePlanningRepository get _repo =>
      ref.read(resourcePlanningRepositoryProvider);

  @override
  PlanningLoad<List<LocalHoliday>> build() =>
      const PlanningLoad<List<LocalHoliday>>();

  Future<void> load() async {
    state = state.started();
    try {
      state = state.loaded(_sorted(await _repo.localHolidays()));
    } on Object catch (e) {
      state = state.failed(_asException(e));
    }
  }

  Future<PlanningOutcome> add(LocalHolidayDraft draft) => _guard(() async {
    final LocalHoliday saved = await _repo.addLocalHoliday(draft);
    state = state.loaded(
      _sorted(<LocalHoliday>[...state.data ?? const <LocalHoliday>[], saved]),
    );
  });

  Future<PlanningOutcome> remove(LocalHoliday holiday) => _guard(() async {
    await _repo.deleteLocalHoliday(holiday.id);
    state = state.loaded(
      (state.data ?? const <LocalHoliday>[])
          .where((LocalHoliday h) => h.id != holiday.id)
          .toList(),
    );
  });

  List<LocalHoliday> _sorted(List<LocalHoliday> rows) =>
      <LocalHoliday>[...rows]..sort((LocalHoliday a, LocalHoliday b) {
        final int byMonth = a.month.compareTo(b.month);
        return byMonth != 0 ? byMonth : a.day.compareTo(b.day);
      });
}

final NotifierProvider<LocalHolidaysController, PlanningLoad<List<LocalHoliday>>>
localHolidaysProvider =
    NotifierProvider<LocalHolidaysController, PlanningLoad<List<LocalHoliday>>>(
      LocalHolidaysController.new,
    );
