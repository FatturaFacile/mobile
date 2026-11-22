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
        // Wednesday 6 March 2030.
        resourcePlanningClockProvider.overrideWithValue(
          () => DateTime(2030, 3, 6, 10),
        ),
      ],
    );
    addTearDown(container.dispose);
  });

  group('date helpers', () {
    test('ymd pads month and day', () {
      expect(ymd(DateTime(2030, 3, 6)), '2030-03-06');
    });

    test('mondayOf returns the Monday of the week, also for a Sunday', () {
      expect(ymd(mondayOf(DateTime(2030, 3, 6))), '2030-03-04');
      expect(ymd(mondayOf(DateTime(2030, 3, 4))), '2030-03-04');
      expect(ymd(mondayOf(DateTime(2030, 3, 10))), '2030-03-04');
    });
  });

  group('capacity', () {
    test('loads eight weeks starting from the Monday of the current week', () async {
      await container.read(capacityProvider.notifier).load();

      final PlanningLoad<CapacityHeatmap> state = container.read(
        capacityProvider,
      );
      expect(repo.calls.single, 'heatmap:2030-03-04:2030-04-28');
      expect(state.data?.rows, hasLength(2));
      expect(state.loading, isFalse);
      expect(state.error, isNull);
    });

    test('a failure is kept, the previous data survives and forbidden is flagged', () async {
      final CapacityController c = container.read(capacityProvider.notifier);
      await c.load();
      repo.failure = const ResourcePlanningException(
        ResourcePlanningErrorKind.forbidden,
      );

      await c.load();

      final PlanningLoad<CapacityHeatmap> state = container.read(
        capacityProvider,
      );
      expect(state.forbidden, isTrue);
      expect(state.data, isNotNull);
    });

    test('an unexpected exception becomes an unknown failure', () async {
      repo.failure = null;
      final ProviderContainer broken = ProviderContainer(
        overrides: [
          resourcePlanningRepositoryProvider.overrideWithValue(
            _ThrowingRepository(),
          ),
          resourcePlanningClockProvider.overrideWithValue(DateTime.now),
        ],
      );
      addTearDown(broken.dispose);

      await broken.read(capacityProvider.notifier).load();

      expect(
        broken.read(capacityProvider).error?.kind,
        ResourcePlanningErrorKind.unknown,
      );
    });
  });

  group('allocations', () {
    test('loads the next 60 days oldest first', () async {
      repo.allocationRows = <ResourceAllocation>[
        fakeAllocation('b', start: '2030-03-11', end: '2030-03-15'),
        fakeAllocation('a'),
      ];

      await container.read(allocationsProvider.notifier).load();

      expect(repo.calls.single, 'allocations:2030-03-06:2030-05-05');
      expect(
        container
            .read(allocationsProvider)
            .data!
            .map((ResourceAllocation a) => a.id),
        <String>['a', 'b'],
      );
    });

    test('converting a soft booking replaces it with the hard one and returns the overload verdict', () async {
      repo.allocationRows = <ResourceAllocation>[
        fakeAllocation('a'),
        fakeAllocation('b', start: '2030-03-11', end: '2030-03-15'),
      ];
      repo.mutationResult = AllocationMutationResult.fromJson(
        mutationJson(<Map<String, dynamic>>[
          allocationJson('a', type: 'HardCommitted'),
        ], overloaded: true, peak: 108),
      );
      final AllocationsController c = container.read(
        allocationsProvider.notifier,
      );
      await c.load();

      final AllocationActionOutcome outcome = await c.convertToHard(
        fakeAllocation('a'),
      );

      expect(outcome.ok, isTrue);
      expect(outcome.result!.overload.peakLoadPercent, 108);
      final List<ResourceAllocation> rows = container
          .read(allocationsProvider)
          .data!;
      expect(rows.map((ResourceAllocation a) => a.id), <String>['a', 'b']);
      expect(rows.first.bookingType, BookingType.hardCommitted);
      expect(repo.calls, contains('convert:a'));
    });

    test('moving by a week sends a shift and reorders the agenda', () async {
      repo.allocationRows = <ResourceAllocation>[
        fakeAllocation('a'),
        fakeAllocation('b', start: '2030-03-06', end: '2030-03-08'),
      ];
      repo.mutationResult = AllocationMutationResult.fromJson(
        mutationJson(<Map<String, dynamic>>[
          allocationJson('a', start: '2030-03-11', end: '2030-03-15'),
        ]),
      );
      final AllocationsController c = container.read(
        allocationsProvider.notifier,
      );
      await c.load();

      final AllocationActionOutcome outcome = await c.move(
        fakeAllocation('a'),
        7,
      );

      expect(outcome.ok, isTrue);
      expect(repo.rebalances.single.strategy, RebalanceStrategy.shift);
      expect(repo.rebalances.single.shiftDays, 7);
      expect(
        container
            .read(allocationsProvider)
            .data!
            .map((ResourceAllocation a) => a.id),
        <String>['b', 'a'],
      );
    });

    test('a split result adds the second part to the agenda', () async {
      repo.allocationRows = <ResourceAllocation>[fakeAllocation('a')];
      repo.mutationResult = AllocationMutationResult.fromJson(
        mutationJson(<Map<String, dynamic>>[
          allocationJson('a', end: '2030-03-05'),
          allocationJson('a2', start: '2030-03-06'),
        ]),
      );
      final AllocationsController c = container.read(
        allocationsProvider.notifier,
      );
      await c.load();

      await c.reassign(fakeAllocation('a'), 'e9');

      expect(repo.rebalances.single.strategy, RebalanceStrategy.reassign);
      expect(repo.rebalances.single.employeeId, 'e9');
      expect(
        container
            .read(allocationsProvider)
            .data!
            .map((ResourceAllocation a) => a.id),
        <String>['a', 'a2'],
      );
    });

    test('a refused action leaves the agenda untouched and reports the violation', () async {
      repo.allocationRows = <ResourceAllocation>[fakeAllocation('a')];
      final AllocationsController c = container.read(
        allocationsProvider.notifier,
      );
      await c.load();
      repo.failure = const ResourcePlanningException(
        ResourcePlanningErrorKind.invalid,
        violations: <ApiCode>[ApiCode('already_hard_committed')],
      );
      repo.mutationResult = null;

      final AllocationActionOutcome outcome = await c.convertToHard(
        fakeAllocation('a'),
      );

      expect(outcome.ok, isFalse);
      expect(outcome.error!.violations.single.code, 'already_hard_committed');
      expect(
        container
            .read(allocationsProvider)
            .data!
            .map((ResourceAllocation a) => a.bookingType),
        <BookingType>[BookingType.softTentative],
      );
    });
  });

  group('candidates', () {
    test('loads the taxonomy and ranks the candidates by score', () async {
      repo.skillRows = const <Skill>[
        Skill(id: 's1', category: 'Dev', skillName: 'Flutter'),
      ];
      repo.candidateRows = <Candidate>[
        Candidate.fromJson(candidateJson('e2', 'Bruno', score: 55)),
        Candidate.fromJson(candidateJson('e1', 'Anna', score: 91)),
      ];
      final CandidatesController c = container.read(
        candidatesProvider.notifier,
      );

      await c.loadSkills();
      await c.search(
        const CandidateQuery(
          startDate: '2030-03-06',
          endDate: '2030-04-03',
          allocatedHoursPerDay: 8,
          requirements: <SkillRequirement>[
            SkillRequirement(skillId: 's1', minLevel: 3),
          ],
        ),
      );

      final CandidatesState state = container.read(candidatesProvider);
      expect(state.skills.data!.single.skillName, 'Flutter');
      expect(state.candidates!.map((Candidate k) => k.employeeId), <String>[
        'e1',
        'e2',
      ]);
      expect(state.searching, isFalse);
      expect(repo.queries.single.requirements.single.skillId, 's1');
    });

    test('a failed search keeps the error and no result list', () async {
      repo.failure = const ResourcePlanningException(
        ResourcePlanningErrorKind.offline,
      );

      await container
          .read(candidatesProvider.notifier)
          .search(
            const CandidateQuery(
              startDate: '2030-03-06',
              endDate: '2030-04-03',
              allocatedHoursPerDay: 8,
              requirements: <SkillRequirement>[],
            ),
          );

      final CandidatesState state = container.read(candidatesProvider);
      expect(state.error?.kind, ResourcePlanningErrorKind.offline);
      expect(state.candidates, isNull);
      expect(state.searching, isFalse);
    });
  });

  group('utilization', () {
    test('loads the current month for the chosen grouping', () async {
      await container
          .read(utilizationProvider.notifier)
          .load(groupBy: UtilizationGroup.department);

      expect(repo.calls.single, 'utilization:2030-03-01:2030-03-31');
      expect(repo.lastGroup, UtilizationGroup.department);
      expect(container.read(utilizationProvider).data!.rows, hasLength(2));
    });

    test('February ends on the 28th in a non-leap year', () async {
      final ProviderContainer feb = ProviderContainer(
        overrides: [
          resourcePlanningRepositoryProvider.overrideWithValue(repo),
          resourcePlanningClockProvider.overrideWithValue(
            () => DateTime(2030, 2, 10),
          ),
        ],
      );
      addTearDown(feb.dispose);

      await feb.read(utilizationProvider.notifier).load();

      expect(repo.calls.single, 'utilization:2030-02-01:2030-02-28');
    });
  });
}

/// Repository whose calls fail with something that is not a [ResourcePlanningException].
class _ThrowingRepository extends FakeResourcePlanningRepository {
  @override
  Future<CapacityHeatmap> heatmap({
    required String from,
    required String to,
    String granularity = 'week',
    String? departmentId,
    List<String> employeeIds = const <String>[],
  }) async => throw StateError('boom');
}
