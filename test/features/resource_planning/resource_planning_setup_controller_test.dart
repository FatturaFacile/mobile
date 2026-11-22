import 'package:fattura_facile/features/resource_planning/domain/resource_planning_models.dart';
import 'package:fattura_facile/features/resource_planning/domain/resource_planning_repository.dart';
import 'package:fattura_facile/features/resource_planning/presentation/resource_planning_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  late FakeResourcePlanningRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = FakeResourcePlanningRepository();
    container = ProviderContainer(
      overrides: [
        resourcePlanningRepositoryProvider.overrideWithValue(repo),
        resourcePlanningClockProvider.overrideWithValue(() => DateTime(2030, 3, 6, 10)),
      ],
    );
    addTearDown(container.dispose);
  });

  const ResourcePlanningException refused = ResourcePlanningException(
    ResourcePlanningErrorKind.invalid,
    violations: <ApiCode>[ApiCode('overload')],
  );

  group('allocations: create, rebalance, delete', () {
    setUp(() async {
      repo.allocationRows = <ResourceAllocation>[
        fakeAllocation('a1'),
        fakeAllocation('a2', start: '2030-03-11', end: '2030-03-15'),
      ];
      await container.read(allocationsProvider.notifier).load();
    });

    List<String> ids() => container
        .read(allocationsProvider)
        .data!
        .map((ResourceAllocation a) => a.id)
        .toList();

    const AllocationDraft draft = AllocationDraft(
      employeeId: 'e1',
      bookingType: BookingType.hardCommitted,
      startDate: '2030-03-18',
      endDate: '2030-03-22',
      allocatedHoursPerDay: 4,
      projectId: 'p1',
    );

    test('a created allocation is added to the agenda in date order and reports the verdict', () async {
      repo.mutationResult = AllocationMutationResult.fromJson(
        mutationJson(
          <Map<String, dynamic>>[allocationJson('a9', type: 'HardCommitted', start: '2030-03-18', end: '2030-03-22')],
          overloaded: true,
          peak: 115,
        ),
      );

      final AllocationActionOutcome outcome =
          await container.read(allocationsProvider.notifier).create(draft);

      expect(outcome.ok, isTrue);
      expect(outcome.result!.overload.peakLoadPercent, 115);
      expect(repo.createdDrafts.single, same(draft));
      expect(ids(), <String>['a1', 'a2', 'a9']);
    });

    test('a refused create keeps the agenda and returns the failure', () async {
      repo.failure = refused;

      final AllocationActionOutcome outcome =
          await container.read(allocationsProvider.notifier).create(draft);

      expect(outcome.ok, isFalse);
      expect(outcome.error!.violations.single.code, 'overload');
      expect(ids(), <String>['a1', 'a2']);
    });

    test('a resize replaces the row of the allocation', () async {
      repo.mutationResult = AllocationMutationResult.fromJson(
        mutationJson(<Map<String, dynamic>>[allocationJson('a1', end: '2030-03-15')]),
      );
      final ResourceAllocation a1 = container.read(allocationsProvider).data!.first;

      final AllocationActionOutcome outcome = await container
          .read(allocationsProvider.notifier)
          .rebalance(
            a1,
            const RebalanceRequest(strategy: RebalanceStrategy.resize, endDate: '2030-03-15'),
          );

      expect(outcome.ok, isTrue);
      expect(repo.rebalances.single.endDate, '2030-03-15');
      expect(ids(), <String>['a1', 'a2']);
      expect(container.read(allocationsProvider).data!.first.endDate, '2030-03-15');
    });

    test('a split replaces the allocation with its two parts', () async {
      repo.mutationResult = AllocationMutationResult.fromJson(
        mutationJson(<Map<String, dynamic>>[
          allocationJson('a1', end: '2030-03-05'),
          allocationJson('a1b', start: '2030-03-06', end: '2030-03-08'),
        ]),
      );
      final ResourceAllocation a1 = container.read(allocationsProvider).data!.first;

      await container.read(allocationsProvider.notifier).rebalance(
        a1,
        const RebalanceRequest(strategy: RebalanceStrategy.split, splitDate: '2030-03-06'),
      );

      expect(ids(), <String>['a1', 'a1b', 'a2']);
    });

    test('a refused rebalance leaves the agenda untouched', () async {
      repo.failure = refused;
      final ResourceAllocation a1 = container.read(allocationsProvider).data!.first;

      final AllocationActionOutcome outcome = await container
          .read(allocationsProvider.notifier)
          .rebalance(a1, const RebalanceRequest.shiftBy(3));

      expect(outcome.ok, isFalse);
      expect(ids(), <String>['a1', 'a2']);
    });

    test('a deleted allocation leaves the agenda', () async {
      final ResourceAllocation a1 = container.read(allocationsProvider).data!.first;

      final PlanningOutcome outcome =
          await container.read(allocationsProvider.notifier).delete(a1);

      expect(outcome.ok, isTrue);
      expect(repo.calls, contains('delete:a1'));
      expect(ids(), <String>['a2']);
    });

    test('a refused delete keeps the allocation and carries the error', () async {
      repo.failure = const ResourcePlanningException(ResourcePlanningErrorKind.notFound);
      final ResourceAllocation a1 = container.read(allocationsProvider).data!.first;

      final PlanningOutcome outcome =
          await container.read(allocationsProvider.notifier).delete(a1);

      expect(outcome.ok, isFalse);
      expect(outcome.error!.kind, ResourcePlanningErrorKind.notFound);
      expect(ids(), <String>['a1', 'a2']);
    });

    test('committing with a picked project sends that project', () async {
      repo.allocationRows = <ResourceAllocation>[fakeAllocation('a3', projectId: null)];
      await container.read(allocationsProvider.notifier).load();
      repo.mutationResult = AllocationMutationResult.fromJson(
        mutationJson(<Map<String, dynamic>>[allocationJson('a3', type: 'HardCommitted')]),
      );
      final ResourceAllocation a3 = container.read(allocationsProvider).data!.single;

      final AllocationActionOutcome outcome = await container
          .read(allocationsProvider.notifier)
          .convertToHard(a3, projectId: uuidA);

      expect(outcome.ok, isTrue);
      expect(repo.lastConvertProjectId, uuidA);
      expect(container.read(allocationsProvider).data!.single.bookingType, BookingType.hardCommitted);
    });
  });

  group('lookups', () {
    test('resources are loaded sorted by name', () async {
      repo.resourceRows = <ResourceLookup>[
        ResourceLookup.fromJson(resourceJson('e2', 'Zed')),
        ResourceLookup.fromJson(resourceJson('e1', 'Anna')),
      ];

      await container.read(resourcesProvider.notifier).load();

      expect(
        container.read(resourcesProvider).data!.map((ResourceLookup r) => r.fullName),
        <String>['Anna', 'Zed'],
      );
    });

    test('a failed resources load keeps the error', () async {
      repo.failure = const ResourcePlanningException(ResourcePlanningErrorKind.forbidden);

      await container.read(resourcesProvider.notifier).load();

      expect(container.read(resourcesProvider).forbidden, isTrue);
    });

    test('the project search passes the term and keeps the matches', () async {
      repo.projectRows = <ProjectRef>[
        const ProjectRef(id: 'p1', name: 'Relaunch', number: 'P-001'),
        const ProjectRef(id: 'p2', name: 'Audit', number: 'P-002'),
      ];

      await container.read(projectSearchProvider.notifier).search('audit');

      expect(repo.lastProjectSearch, 'audit');
      expect(
        container.read(projectSearchProvider).data!.map((ProjectRef p) => p.id),
        <String>['p2'],
      );
    });

    test('a failed project search surfaces the error so the picker can offer the manual id', () async {
      repo.projectsFailure = const ResourcePlanningException(ResourcePlanningErrorKind.forbidden);

      await container.read(projectSearchProvider.notifier).search('');

      expect(container.read(projectSearchProvider).error!.kind, ResourcePlanningErrorKind.forbidden);
      expect(container.read(projectSearchProvider).data, isNull);
    });
  });

  group('skills', () {
    setUp(() async {
      repo.skillRows = <Skill>[
        Skill.fromJson(skillJson('s2', 'Zebra', category: 'B')),
        Skill.fromJson(skillJson('s1', 'Flutter', category: 'A')),
      ];
      await container.read(skillsProvider.notifier).load();
    });

    List<String> names() =>
        container.read(skillsProvider).data!.map((Skill s) => s.skillName).toList();

    test('skills are sorted by category then name', () {
      expect(names(), <String>['Flutter', 'Zebra']);
    });

    test('a created skill joins the sorted list', () async {
      final PlanningOutcome outcome = await container
          .read(skillsProvider.notifier)
          .save(const SkillDraft(category: 'A', skillName: 'Angular'));

      expect(outcome.ok, isTrue);
      expect(repo.calls, contains('skill-create'));
      expect(names(), <String>['Angular', 'Flutter', 'Zebra']);
    });

    test('an edited skill replaces the old row', () async {
      final Skill flutter = container.read(skillsProvider).data!.first;

      await container
          .read(skillsProvider.notifier)
          .save(const SkillDraft(category: 'A', skillName: 'Flutter 3'), existing: flutter);

      expect(repo.calls, contains('skill-update:s1'));
      expect(names(), <String>['Flutter 3', 'Zebra']);
    });

    test('a deleted skill leaves the list', () async {
      final Skill flutter = container.read(skillsProvider).data!.first;

      final PlanningOutcome outcome =
          await container.read(skillsProvider.notifier).delete(flutter);

      expect(outcome.ok, isTrue);
      expect(names(), <String>['Zebra']);
    });

    test('a refused save returns the error and keeps the list', () async {
      repo.failure = const ResourcePlanningException(
        ResourcePlanningErrorKind.invalid,
        violations: <ApiCode>[ApiCode('certification_code_required')],
      );

      final PlanningOutcome outcome = await container
          .read(skillsProvider.notifier)
          .save(const SkillDraft(category: 'A', skillName: 'X', requiresCertification: true));

      expect(outcome.ok, isFalse);
      expect(outcome.error!.violations.single.code, 'certification_code_required');
      expect(names(), <String>['Flutter', 'Zebra']);
    });
  });

  group('skill profiles', () {
    setUp(() async {
      repo.skillRows = <Skill>[
        Skill.fromJson(skillJson('s1', 'Flutter')),
        Skill.fromJson(skillJson('s2', 'Dart')),
      ];
      repo.profileRows = <EmployeeSkillProfile>[
        EmployeeSkillProfile.fromJson(profileJson('pr-s1', skillId: 's1', skillName: 'Flutter', level: 3)),
        EmployeeSkillProfile.fromJson(profileJson('px', employeeId: 'e2', skillId: 's1')),
      ];
      await container.read(skillProfilesProvider.notifier).load('e1');
    });

    test('only the employee profile is loaded', () {
      expect(repo.calls, contains('profiles:e1'));
      expect(container.read(skillProfilesProvider).data!.single.id, 'pr-s1');
    });

    test('saving an existing skill replaces its level instead of duplicating it', () async {
      final PlanningOutcome outcome = await container.read(skillProfilesProvider.notifier).save(
        const SkillProfileDraft(employeeId: 'e1', skillId: 's1', proficiencyLevel: 5),
      );

      expect(outcome.ok, isTrue);
      final List<EmployeeSkillProfile> rows = container.read(skillProfilesProvider).data!;
      expect(rows, hasLength(1));
      expect(rows.single.proficiencyLevel, 5);
    });

    test('a new skill is added and the list stays sorted by skill name', () async {
      await container.read(skillProfilesProvider.notifier).save(
        const SkillProfileDraft(employeeId: 'e1', skillId: 's2', proficiencyLevel: 2, validUntilDate: '2031-01-31'),
      );

      final List<EmployeeSkillProfile> rows = container.read(skillProfilesProvider).data!;
      expect(rows.map((EmployeeSkillProfile p) => p.skillName), <String>['Dart', 'Flutter']);
      expect(rows.first.validUntilDate, '2031-01-31');
    });

    test('a deleted profile leaves the list', () async {
      final EmployeeSkillProfile p = container.read(skillProfilesProvider).data!.single;

      final PlanningOutcome outcome =
          await container.read(skillProfilesProvider.notifier).delete(p);

      expect(outcome.ok, isTrue);
      expect(repo.calls, contains('profile-delete:pr-s1'));
      expect(container.read(skillProfilesProvider).data, isEmpty);
    });

    test('a failed save returns the failure', () async {
      repo.failure = const ResourcePlanningException(ResourcePlanningErrorKind.offline);

      final PlanningOutcome outcome = await container.read(skillProfilesProvider.notifier).save(
        const SkillProfileDraft(employeeId: 'e1', skillId: 's2', proficiencyLevel: 2),
      );

      expect(outcome.ok, isFalse);
      expect(outcome.error!.kind, ResourcePlanningErrorKind.offline);
    });
  });

  group('utilization targets', () {
    setUp(() async {
      repo.targetRows = <UtilizationTarget>[
        const UtilizationTarget(id: 'tc', costCenterId: 'c1', targetPercent: 60),
        const UtilizationTarget(id: 'td', departmentId: 'd1', targetPercent: 75),
        const UtilizationTarget(id: 't0', targetPercent: 70),
      ];
      await container.read(utilizationTargetsProvider.notifier).load();
    });

    List<String> ids() =>
        container.read(utilizationTargetsProvider).data!.map((UtilizationTarget t) => t.id).toList();

    test('the default comes first, then departments, then cost centers', () {
      expect(ids(), <String>['t0', 'td', 'tc']);
    });

    test('saving the target of a scope replaces the previous one of that scope', () async {
      final PlanningOutcome outcome = await container
          .read(utilizationTargetsProvider.notifier)
          .save(const UtilizationTargetDraft(targetPercent: 85, departmentId: 'd1'));

      expect(outcome.ok, isTrue);
      final List<UtilizationTarget> rows = container.read(utilizationTargetsProvider).data!;
      expect(rows, hasLength(3));
      expect(rows.singleWhere((UtilizationTarget t) => t.departmentId == 'd1').targetPercent, 85);
    });

    test('a target of a new scope is added', () async {
      await container
          .read(utilizationTargetsProvider.notifier)
          .save(const UtilizationTargetDraft(targetPercent: 50, departmentId: 'd9'));

      expect(container.read(utilizationTargetsProvider).data, hasLength(4));
      expect(repo.targetDrafts.single.departmentId, 'd9');
    });

    test('saving the tenant default updates the default row', () async {
      await container
          .read(utilizationTargetsProvider.notifier)
          .save(const UtilizationTargetDraft(targetPercent: 72));

      final List<UtilizationTarget> rows = container.read(utilizationTargetsProvider).data!;
      expect(rows, hasLength(3));
      expect(rows.first.isDefault, isTrue);
      expect(rows.first.targetPercent, 72);
    });

    test('a refused save returns the failure', () async {
      repo.failure = refused;

      final PlanningOutcome outcome = await container
          .read(utilizationTargetsProvider.notifier)
          .save(const UtilizationTargetDraft(targetPercent: 72));

      expect(outcome.ok, isFalse);
    });
  });

  group('local holidays', () {
    setUp(() async {
      repo.holidayRows = <LocalHoliday>[
        const LocalHoliday(id: 'h2', country: 'CH', month: 12, day: 24, name: 'Closing'),
        const LocalHoliday(id: 'h1', country: 'CH', month: 3, day: 19, name: 'San Giuseppe'),
      ];
      await container.read(localHolidaysProvider.notifier).load();
    });

    List<String> ids() =>
        container.read(localHolidaysProvider).data!.map((LocalHoliday h) => h.id).toList();

    test('holidays are sorted by month and day', () {
      expect(ids(), <String>['h1', 'h2']);
    });

    test('an added holiday is inserted in date order', () async {
      final PlanningOutcome outcome = await container.read(localHolidaysProvider.notifier).add(
        const LocalHolidayDraft(country: 'CH', month: 8, day: 1, name: 'National day'),
      );

      expect(outcome.ok, isTrue);
      expect(container.read(localHolidaysProvider).data!.map((LocalHoliday h) => h.name), <String>[
        'San Giuseppe',
        'National day',
        'Closing',
      ]);
    });

    test('a removed holiday leaves the list', () async {
      final LocalHoliday h = container.read(localHolidaysProvider).data!.first;

      final PlanningOutcome outcome =
          await container.read(localHolidaysProvider.notifier).remove(h);

      expect(outcome.ok, isTrue);
      expect(repo.calls, contains('holiday-delete:h1'));
      expect(ids(), <String>['h2']);
    });

    test('a failed remove keeps the list and returns the failure', () async {
      repo.failure = const ResourcePlanningException(ResourcePlanningErrorKind.notFound);
      final LocalHoliday h = container.read(localHolidaysProvider).data!.first;

      final PlanningOutcome outcome =
          await container.read(localHolidaysProvider.notifier).remove(h);

      expect(outcome.ok, isFalse);
      expect(ids(), <String>['h1', 'h2']);
    });
  });
}
