import 'package:fattura_facile/design/ff_tokens.dart';
import 'package:fattura_facile/features/resource_planning/domain/resource_planning_models.dart';
import 'package:fattura_facile/features/resource_planning/domain/resource_planning_repository.dart';
import 'package:fattura_facile/features/resource_planning/presentation/resource_planning_controller.dart';
import 'package:fattura_facile/features/resource_planning/presentation/resource_planning_pages.dart';
import 'package:fattura_facile/features/resource_planning/presentation/resource_planning_strings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'fakes.dart';

void main() {
  late FakeResourcePlanningRepository repo;

  setUp(() {
    repo = FakeResourcePlanningRepository();
  });

  Widget host(Widget child) => ProviderScope(
    key: UniqueKey(),
    overrides: [
      resourcePlanningRepositoryProvider.overrideWithValue(repo),
      resourcePlanningClockProvider.overrideWithValue(
        () => DateTime(2030, 3, 6, 10),
      ),
    ],
    child: MaterialApp(theme: ffThemeData(), home: child),
  );

  Text textOf(WidgetTester tester, Finder f) =>
      tester.widget<Text>(find.descendant(of: f, matching: find.byType(Text)));

  group('capacity heatmap list', () {
    testWidgets('lists one card per employee with a colored cell per week and the peak load', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(host(const ResourcePlanningHomePage()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('rp-row-e1')), findsOneWidget);
      expect(find.byKey(const Key('rp-row-e2')), findsOneWidget);
      expect(find.text('Anna Rossi'), findsOneWidget);
      expect(find.text('Bruno Bianchi'), findsOneWidget);
      expect(find.text('Peak 90%'), findsOneWidget);
      expect(find.text('Peak 120%'), findsOneWidget);
      expect(
        find.byKey(const Key('rp-cell-e1-2030-03-04')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('rp-cell-e2-2030-03-11')),
        findsOneWidget,
      );
      expect(find.text('50%'), findsOneWidget);
      expect(find.text('120%'), findsOneWidget);
    });

    testWidgets('paints green, yellow and red bands with the theme colors', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(host(const ResourcePlanningHomePage()));
      await tester.pumpAndSettle();

      Color? fill(String key) {
        final Container box = tester.widget<Container>(
          find.byKey(Key(key)),
        );
        return (box.decoration! as BoxDecoration).color;
      }

      final FfColors c = FfColors.light;
      expect(fill('rp-cell-e1-2030-03-04'), c.successBg);
      expect(fill('rp-cell-e1-2030-03-11'), c.warningBg);
      expect(fill('rp-cell-e2-2030-03-04'), c.dangerBg);
    });

    testWidgets('shows the overload alert with the number of resources above 100 percent', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(host(const ResourcePlanningHomePage()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('rp-overload-alert')), findsOneWidget);
      expect(
        find.text('1 resources above 100% of capacity'),
        findsOneWidget,
      );
    });

    testWidgets('has no alert when nobody is overloaded', (
      WidgetTester tester,
    ) async {
      repo.heatmapResult = CapacityHeatmap.fromJson(<String, dynamic>{
        ...heatmapJson(),
        'rows': <Map<String, dynamic>>[
          rowJson('e1', 'Anna Rossi', <Map<String, dynamic>>[
            cellJson('2030-03-04'),
          ]),
        ],
      });

      await tester.pumpWidget(host(const ResourcePlanningHomePage()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('rp-overload-alert')), findsNothing);
      expect(find.byKey(const Key('rp-row-e1')), findsOneWidget);
    });

    testWidgets('a resource without capacity and bookings shows a dash on a neutral cell', (
      WidgetTester tester,
    ) async {
      repo.heatmapResult = CapacityHeatmap.fromJson(<String, dynamic>{
        ...heatmapJson(),
        'rows': <Map<String, dynamic>>[
          rowJson('e1', 'Anna Rossi', <Map<String, dynamic>>[
            cellJson(
              '2030-03-04',
              net: 0,
              hard: 0,
              load: 0,
              band: 'none',
            ),
          ]),
        ],
      });

      await tester.pumpWidget(host(const ResourcePlanningHomePage()));
      await tester.pumpAndSettle();

      expect(find.text('03-04'), findsOneWidget);
      expect(find.text('-'), findsOneWidget);
    });

    testWidgets('an empty heatmap shows the empty message', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ffThemeData(),
          home: Scaffold(
            body: CapacityHeatmapList(
              heatmap: CapacityHeatmap.fromJson(<String, dynamic>{
                'from': '2030-03-04',
                'to': '2030-03-10',
                'granularity': 'week',
              }),
              strings: const ResourcePlanningStrings('en'),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('rp-capacity-empty')), findsOneWidget);
      expect(find.text('No plannable resources'), findsOneWidget);
    });

    testWidgets('labels follow the language, also for regional variants', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ffThemeData(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: CapacityHeatmapList(
                heatmap: repo.heatmapResult,
                strings: const ResourcePlanningStrings('de-CH'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Spitze 120%'), findsOneWidget);
      expect(find.text('Überlastet'), findsOneWidget);
    });

    testWidgets('a forbidden answer shows the access message with a retry', (
      WidgetTester tester,
    ) async {
      repo.failure = const ResourcePlanningException(
        ResourcePlanningErrorKind.forbidden,
      );

      await tester.pumpWidget(host(const ResourcePlanningHomePage()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('rp-capacity-error')), findsOneWidget);
      expect(
        find.text('You do not have access to this function'),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsOneWidget);
    });
  });

  group('allocations agenda', () {
    setUp(() {
      repo.allocationRows = <ResourceAllocation>[
        fakeAllocation('a1'),
        fakeAllocation(
          'a2',
          type: 'HardCommitted',
          start: '2030-03-11',
          end: '2030-03-15',
          employeeName: 'Bruno Bianchi',
        ),
        fakeAllocation(
          'a3',
          projectId: null,
          start: '2030-03-18',
          end: '2030-03-22',
        ),
      ];
    });

    Future<void> openAllocations(WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(host(const ResourcePlanningHomePage()));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('rp-tab-allocations')));
      await tester.pumpAndSettle();
    }

    testWidgets('shows soft and hard badges and the convert action only on soft bookings', (
      WidgetTester tester,
    ) async {
      await openAllocations(tester);

      expect(textOf(tester, find.byKey(const Key('rp-badge-a1'))).data, 'Tentative');
      expect(textOf(tester, find.byKey(const Key('rp-badge-a2'))).data, 'Committed');
      expect(find.byKey(const Key('rp-convert-a1')), findsOneWidget);
      expect(find.byKey(const Key('rp-convert-a2')), findsNothing);
    });

    testWidgets('a soft booking with only an opportunity can be committed and tells that a project is asked', (
      WidgetTester tester,
    ) async {
      await openAllocations(tester);

      expect(find.text('Big deal'), findsOneWidget);
      expect(
        find.byKey(const Key('rp-alloc-needs-project-a3')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('rp-alloc-needs-project-a1')), findsNothing);
      final FilledButton convert = tester.widget<FilledButton>(
        find.byKey(const Key('rp-convert-a3')),
      );
      expect(convert.onPressed, isNotNull);
    });

    testWidgets('committing a soft booking turns its badge hard and reports the overload', (
      WidgetTester tester,
    ) async {
      repo.mutationResult = AllocationMutationResult.fromJson(
        mutationJson(<Map<String, dynamic>>[
          allocationJson('a1', type: 'HardCommitted'),
        ], overloaded: true, peak: 112),
      );
      await openAllocations(tester);

      await tester.tap(find.byKey(const Key('rp-convert-a1')));
      await tester.pumpAndSettle();

      expect(repo.calls, contains('convert:a1'));
      expect(textOf(tester, find.byKey(const Key('rp-badge-a1'))).data, 'Committed');
      expect(find.byKey(const Key('rp-convert-a1')), findsNothing);
      expect(
        find.textContaining('Allocation committed - Overloaded up to 112%'),
        findsOneWidget,
      );
    });

    testWidgets('moving an allocation sends a one week shift', (
      WidgetTester tester,
    ) async {
      repo.mutationResult = AllocationMutationResult.fromJson(
        mutationJson(<Map<String, dynamic>>[
          allocationJson('a1', start: '2030-03-11', end: '2030-03-15'),
        ]),
      );
      await openAllocations(tester);

      await tester.tap(find.byKey(const Key('rp-move-forward-a1')));
      await tester.pumpAndSettle();

      expect(repo.rebalances.single.strategy, RebalanceStrategy.shift);
      expect(repo.rebalances.single.shiftDays, 7);
      expect(find.text('Allocation moved'), findsOneWidget);
    });

    testWidgets('a refused move shows the violation and keeps the agenda', (
      WidgetTester tester,
    ) async {
      await openAllocations(tester);
      repo.failure = const ResourcePlanningException(
        ResourcePlanningErrorKind.invalid,
        violations: <ApiCode>[ApiCode('overload')],
      );

      await tester.tap(find.byKey(const Key('rp-move-back-a1')));
      await tester.pumpAndSettle();

      expect(find.text('The resource would be overloaded'), findsOneWidget);
      expect(find.byKey(const Key('rp-alloc-a1')), findsOneWidget);
    });

    testWidgets('an empty agenda shows the empty message', (
      WidgetTester tester,
    ) async {
      repo.allocationRows = <ResourceAllocation>[];

      await openAllocations(tester);

      expect(find.byKey(const Key('rp-allocations-empty')), findsOneWidget);
    });
  });

  group('candidates', () {
    testWidgets('searching for a role lists the candidates with their blockers', (
      WidgetTester tester,
    ) async {
      repo.skillRows = const <Skill>[
        Skill(id: 's1', category: 'Dev', skillName: 'Flutter'),
      ];
      repo.candidateRows = <Candidate>[
        Candidate.fromJson(candidateJson('e1', 'Anna Rossi', score: 90)),
        Candidate.fromJson(
          candidateJson(
            'e2',
            'Bruno Bianchi',
            score: 40,
            eligible: false,
            blockers: <Map<String, dynamic>>[
              <String, dynamic>{'code': 'certificate_expired', 'params': {}},
            ],
          ),
        ),
      ];
      await tester.pumpWidget(host(const ResourcePlanningHomePage()));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('rp-tab-candidates')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('rp-skill')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dev / Flutter').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('rp-search')));
      await tester.pumpAndSettle();

      expect(repo.queries.single.requirements.single.skillId, 's1');
      expect(repo.queries.single.requirements.single.minLevel, 3);
      expect(repo.queries.single.includeIneligible, isTrue);
      expect(find.byKey(const Key('rp-candidate-e1')), findsOneWidget);
      expect(find.byKey(const Key('rp-candidate-e2')), findsOneWidget);
      expect(
        find.byKey(const Key('rp-blocker-e2-certificate_expired')),
        findsOneWidget,
      );
      expect(find.text('Certificate expired'), findsOneWidget);
    });

    testWidgets('the search button stays disabled until a skill is chosen', (
      WidgetTester tester,
    ) async {
      repo.skillRows = const <Skill>[
        Skill(id: 's1', category: 'Dev', skillName: 'Flutter'),
      ];
      await tester.pumpWidget(host(const ResourcePlanningHomePage()));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('rp-tab-candidates')));
      await tester.pumpAndSettle();

      final FilledButton search = tester.widget<FilledButton>(
        find.byKey(const Key('rp-search')),
      );

      expect(search.onPressed, isNull);
    });
  });

  group('utilization', () {
    testWidgets('shows target versus actual for the totals and every resource', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(host(const ResourcePlanningHomePage()));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('rp-tab-utilization')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('rp-utilization-totals')), findsOneWidget);
      expect(find.byKey(const Key('rp-utilization-anna')), findsOneWidget);
      expect(find.byKey(const Key('rp-utilization-bruno')), findsOneWidget);
      expect(
        find.text('Actual 60% - Forecast 75% - Target 70%'),
        findsWidgets,
      );
      expect(find.text('Below target'), findsWidgets);
      expect(find.text('On target'), findsOneWidget);
      expect(find.text('Gap: -10.0'), findsWidgets);
      expect(find.text('Gap: +2.0'), findsOneWidget);
    });

    testWidgets('switching the grouping reloads the report', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(host(const ResourcePlanningHomePage()));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('rp-tab-utilization')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Department'));
      await tester.pumpAndSettle();

      expect(repo.lastGroup, UtilizationGroup.department);
    });
  });
}
