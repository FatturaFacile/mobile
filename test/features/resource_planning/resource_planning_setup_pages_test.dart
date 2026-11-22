import 'package:fattura_facile/design/ff_tokens.dart';
import 'package:fattura_facile/features/resource_planning/domain/resource_planning_models.dart';
import 'package:fattura_facile/features/resource_planning/domain/resource_planning_repository.dart';
import 'package:fattura_facile/features/resource_planning/presentation/resource_planning_allocation_forms.dart';
import 'package:fattura_facile/features/resource_planning/presentation/resource_planning_controller.dart';
import 'package:fattura_facile/features/resource_planning/presentation/resource_planning_pages.dart';
import 'package:fattura_facile/features/resource_planning/presentation/resource_planning_setup_pages.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'fakes.dart';

void main() {
  late FakeResourcePlanningRepository repo;

  setUp(() {
    repo = FakeResourcePlanningRepository();
    repo.skillRows = <Skill>[
      Skill.fromJson(skillJson('s1', 'Flutter')),
      Skill.fromJson(skillJson('s2', 'Dart')),
    ];
  });

  Widget host(Widget child) => ProviderScope(
    key: UniqueKey(),
    overrides: [
      resourcePlanningRepositoryProvider.overrideWithValue(repo),
      resourcePlanningClockProvider.overrideWithValue(() => DateTime(2030, 3, 6, 10)),
    ],
    child: MaterialApp(theme: ffThemeData(), home: child),
  );

  void tallScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(900, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  /// Opens [page] on top of a launcher so that the page can pop itself.
  Future<void> openPage(WidgetTester tester, Widget page) async {
    tallScreen(tester);
    await tester.pumpWidget(
      host(
        Builder(
          builder: (BuildContext ctx) => Scaffold(
            body: TextButton(
              key: const Key('open'),
              onPressed: () => Navigator.of(ctx).push<void>(
                MaterialPageRoute<void>(builder: (BuildContext _) => page),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open')));
    await tester.pumpAndSettle();
  }

  Future<void> pickFromDropdown(WidgetTester tester, String key, String label) async {
    await tester.tap(find.byKey(Key(key)));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    await tester.tap(find.byKey(Key(key)));
    await tester.pumpAndSettle();
  }

  Future<void> typeInto(WidgetTester tester, String key, String text) async {
    await tester.enterText(find.byKey(Key(key)), text);
    await tester.pump();
  }

  Future<void> openAllocations(WidgetTester tester) async {
    tallScreen(tester);
    await tester.pumpWidget(host(const ResourcePlanningHomePage()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('rp-tab-allocations')));
    await tester.pumpAndSettle();
  }

  AllocationMutationResult created(String id, {String type = 'SoftTentative'}) =>
      AllocationMutationResult.fromJson(
        mutationJson(<Map<String, dynamic>>[allocationJson(id, type: type)]),
      );

  const ResourcePlanningException overloadRefusal = ResourcePlanningException(
    ResourcePlanningErrorKind.invalid,
    violations: <ApiCode>[ApiCode('overload')],
  );

  group('create allocation form', () {
    setUp(() {
      repo.projectRows = <ProjectRef>[
        const ProjectRef(id: 'p1', name: 'Website relaunch', number: 'P-001'),
        const ProjectRef(id: 'p2', name: 'Audit', number: 'P-002'),
      ];
    });

    testWidgets('an empty form lists what is missing and sends nothing', (WidgetTester tester) async {
      await openPage(tester, const AllocationFormPage());

      await tapKey(tester, 'rp-form-save');

      expect(find.byKey(const Key('rp-form-issue-employeeRequired')), findsOneWidget);
      expect(find.byKey(const Key('rp-form-issue-referenceRequired')), findsOneWidget);
      expect(repo.createdDrafts, isEmpty);
    });

    testWidgets('a hard booking without a project is refused locally', (WidgetTester tester) async {
      await openPage(tester, const AllocationFormPage());
      await pickFromDropdown(tester, 'rp-form-employee', 'Anna Rossi');
      await tester.tap(find.text('Committed'));
      await tester.pumpAndSettle();

      await tapKey(tester, 'rp-form-save');

      expect(find.byKey(const Key('rp-form-issue-projectRequired')), findsOneWidget);
      expect(find.byKey(const Key('rp-form-opportunity')), findsNothing);
      expect(repo.createdDrafts, isEmpty);
    });

    testWidgets('an invalid hours value and a malformed opportunity are reported', (WidgetTester tester) async {
      await openPage(tester, const AllocationFormPage());
      await pickFromDropdown(tester, 'rp-form-employee', 'Anna Rossi');
      await typeInto(tester, 'rp-form-hours', '30');
      await typeInto(tester, 'rp-form-opportunity', 'not-a-uuid');

      await tapKey(tester, 'rp-form-save');

      expect(find.byKey(const Key('rp-form-issue-invalidHours')), findsOneWidget);
      expect(find.byKey(const Key('rp-form-issue-invalidOpportunityId')), findsOneWidget);
      expect(repo.createdDrafts, isEmpty);
    });

    testWidgets('a soft booking on a picked project is created with every field', (WidgetTester tester) async {
      repo.mutationResult = created('a9');
      await openPage(tester, const AllocationFormPage());
      await pickFromDropdown(tester, 'rp-form-employee', 'Bruno Bianchi');
      await tapKey(tester, 'rp-form-project-pick');
      await tapKey(tester, 'rp-project-p1');
      expect(find.text('P-001 - Website relaunch'), findsOneWidget);
      await typeInto(tester, 'rp-form-hours', '6,5');
      await typeInto(tester, 'rp-form-notes', '  kickoff  ');
      await tapKey(tester, 'rp-form-billable');
      await tapKey(tester, 'rp-form-overload');
      await tapKey(tester, 'rp-form-skill-s1');

      await tapKey(tester, 'rp-form-save');

      final AllocationDraft d = repo.createdDrafts.single;
      expect(d.employeeId, 'e2');
      expect(d.bookingType, BookingType.softTentative);
      expect(d.projectId, 'p1');
      expect(d.startDate, '2030-03-06');
      expect(d.endDate, '2030-03-10');
      expect(d.allocatedHoursPerDay, 6.5);
      expect(d.isBillable, isFalse);
      expect(d.allowOverload, isFalse);
      expect(d.notes, '  kickoff  ');
      expect(d.requiredSkillIds, <String>['s1']);
      expect(find.byKey(const Key('rp-form-save')), findsNothing);
      expect(find.text('Allocation created'), findsOneWidget);
    });

    testWidgets('a soft booking can reference only an opportunity', (WidgetTester tester) async {
      repo.mutationResult = created('a9');
      await openPage(tester, const AllocationFormPage());
      await pickFromDropdown(tester, 'rp-form-employee', 'Anna Rossi');
      await typeInto(tester, 'rp-form-opportunity', uuidA);

      await tapKey(tester, 'rp-form-save');

      final AllocationDraft d = repo.createdDrafts.single;
      expect(d.projectId, isNull);
      expect(d.opportunityId, uuidA);
    });

    testWidgets('a project can be cleared again', (WidgetTester tester) async {
      await openPage(tester, const AllocationFormPage());
      await tapKey(tester, 'rp-form-project-pick');
      await tapKey(tester, 'rp-project-p2');
      expect(find.byKey(const Key('rp-form-project-clear')), findsOneWidget);

      await tapKey(tester, 'rp-form-project-clear');

      expect(find.text('No project chosen'), findsOneWidget);
    });

    testWidgets('the created allocation shows the overload verdict and the warnings', (WidgetTester tester) async {
      repo.mutationResult = AllocationMutationResult.fromJson(
        mutationJson(
          <Map<String, dynamic>>[allocationJson('a9')],
          overloaded: true,
          peak: 120,
          warnings: <Map<String, dynamic>>[
            <String, dynamic>{'code': 'skill_missing', 'params': <String, dynamic>{}},
          ],
        ),
      );
      await openPage(tester, const AllocationFormPage(initialEmployeeId: 'e1'));
      await typeInto(tester, 'rp-form-opportunity', uuidA);

      await tapKey(tester, 'rp-form-save');

      expect(
        find.text('Allocation created - Overloaded up to 120% - Skill missing'),
        findsOneWidget,
      );
    });

    testWidgets('a refusal from the server stays on the form with the reason', (WidgetTester tester) async {
      repo.mutationResult = created('a9');
      await openPage(tester, const AllocationFormPage(initialEmployeeId: 'e1'));
      await typeInto(tester, 'rp-form-opportunity', uuidA);
      repo.failure = overloadRefusal;

      await tapKey(tester, 'rp-form-save');

      expect(find.text('The resource would be overloaded'), findsOneWidget);
      expect(find.byKey(const Key('rp-form-save')), findsOneWidget);
    });

    testWidgets('a forbidden employee list is shown with a retry', (WidgetTester tester) async {
      repo.failure = const ResourcePlanningException(ResourcePlanningErrorKind.forbidden);

      await openPage(tester, const AllocationFormPage());

      expect(find.byKey(const Key('rp-form-employees-error')), findsOneWidget);
      expect(find.text('You do not have access to this function'), findsOneWidget);
    });

    testWidgets('without employees the form says so', (WidgetTester tester) async {
      repo.resourceRows = <ResourceLookup>[];

      await openPage(tester, const AllocationFormPage());

      expect(find.byKey(const Key('rp-form-no-employees')), findsOneWidget);
    });

    testWidgets('the agenda opens the form and lists the new allocation', (WidgetTester tester) async {
      repo.allocationRows = <ResourceAllocation>[];
      repo.mutationResult = created('a9');
      await openAllocations(tester);
      expect(find.byKey(const Key('rp-allocations-empty')), findsOneWidget);

      await tapKey(tester, 'rp-add-allocation');
      await pickFromDropdown(tester, 'rp-form-employee', 'Anna Rossi');
      await typeInto(tester, 'rp-form-opportunity', uuidA);
      await tapKey(tester, 'rp-form-save');

      expect(find.byKey(const Key('rp-alloc-a9')), findsOneWidget);
      expect(find.byKey(const Key('rp-allocations-empty')), findsNothing);
    });
  });

  group('project picker', () {
    setUp(() {
      repo.projectRows = <ProjectRef>[
        const ProjectRef(id: 'p1', name: 'Website relaunch', number: 'P-001'),
        const ProjectRef(id: 'p2', name: 'Audit', number: 'P-002'),
      ];
      repo.allocationRows = <ResourceAllocation>[
        fakeAllocation('a1'),
        fakeAllocation('a3', projectId: null, start: '2030-03-18', end: '2030-03-22'),
      ];
      repo.mutationResult = AllocationMutationResult.fromJson(
        mutationJson(<Map<String, dynamic>>[allocationJson('a3', type: 'HardCommitted')]),
      );
    });

    testWidgets('committing an opportunity-only booking asks for a project and converts with it', (
      WidgetTester tester,
    ) async {
      await openAllocations(tester);

      await tapKey(tester, 'rp-convert-a3');
      expect(find.byKey(const Key('rp-project-p1')), findsOneWidget);
      expect(find.byKey(const Key('rp-project-p2')), findsOneWidget);
      await tapKey(tester, 'rp-project-p2');

      expect(repo.calls, contains('convert:a3'));
      expect(repo.lastConvertProjectId, 'p2');
      expect(find.byKey(const Key('rp-convert-a3')), findsNothing);
      expect(find.textContaining('Allocation committed'), findsOneWidget);
    });

    testWidgets('a soft booking that already has a project is committed without asking', (
      WidgetTester tester,
    ) async {
      repo.mutationResult = AllocationMutationResult.fromJson(
        mutationJson(<Map<String, dynamic>>[allocationJson('a1', type: 'HardCommitted')]),
      );
      await openAllocations(tester);

      await tapKey(tester, 'rp-convert-a1');

      expect(find.byKey(const Key('rp-project-p1')), findsNothing);
      expect(repo.lastConvertProjectId, isNull);
      expect(repo.calls, contains('convert:a1'));
    });

    testWidgets('leaving the picker commits nothing', (WidgetTester tester) async {
      await openAllocations(tester);
      await tapKey(tester, 'rp-convert-a3');

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(repo.calls.where((String c) => c.startsWith('convert')), isEmpty);
      expect(find.byKey(const Key('rp-convert-a3')), findsOneWidget);
    });

    testWidgets('searching narrows the list through the API', (WidgetTester tester) async {
      await openPage(tester, const ProjectPickerPage());
      expect(find.byKey(const Key('rp-project-p1')), findsOneWidget);

      await typeInto(tester, 'rp-project-search', 'audit');
      await tapKey(tester, 'rp-project-search-go');

      expect(repo.lastProjectSearch, 'audit');
      expect(find.byKey(const Key('rp-project-p1')), findsNothing);
      expect(find.byKey(const Key('rp-project-p2')), findsOneWidget);
    });

    testWidgets('a search without matches says so', (WidgetTester tester) async {
      await openPage(tester, const ProjectPickerPage());

      await typeInto(tester, 'rp-project-search', 'zzz');
      await tapKey(tester, 'rp-project-search-go');

      expect(find.byKey(const Key('rp-projects-empty')), findsOneWidget);
    });

    testWidgets('when the list is not available a validated project id is asked for', (
      WidgetTester tester,
    ) async {
      repo.projectsFailure = const ResourcePlanningException(ResourcePlanningErrorKind.forbidden);
      await openAllocations(tester);

      await tapKey(tester, 'rp-convert-a3');
      expect(find.byKey(const Key('rp-project-list-unavailable')), findsOneWidget);
      await typeInto(tester, 'rp-project-id-input', 'p-123');
      await tapKey(tester, 'rp-project-id-use');
      expect(find.text('The project ID is not valid'), findsOneWidget);
      expect(repo.calls.where((String c) => c.startsWith('convert')), isEmpty);

      await typeInto(tester, 'rp-project-id-input', uuidB);
      await tapKey(tester, 'rp-project-id-use');

      expect(repo.lastConvertProjectId, uuidB);
      expect(find.byKey(const Key('rp-convert-a3')), findsNothing);
    });

    testWidgets('a refused commit shows the reason and keeps the booking soft', (WidgetTester tester) async {
      await openAllocations(tester);
      repo.failure = const ResourcePlanningException(
        ResourcePlanningErrorKind.invalid,
        violations: <ApiCode>[ApiCode('project_not_allocatable')],
      );

      await tapKey(tester, 'rp-convert-a3');
      await tapKey(tester, 'rp-project-p1');

      expect(find.text('The project does not accept allocations'), findsOneWidget);
      expect(find.byKey(const Key('rp-convert-a3')), findsOneWidget);
    });
  });

  group('edit allocation', () {
    Future<void> openEdit(WidgetTester tester, {ResourceAllocation? allocation}) =>
        openPage(tester, AllocationEditPage(allocation: allocation ?? fakeAllocation('a1')));

    setUp(() {
      repo.mutationResult = AllocationMutationResult.fromJson(
        mutationJson(<Map<String, dynamic>>[allocationJson('a1')]),
      );
    });

    testWidgets('resizing the hours sends only the hours', (WidgetTester tester) async {
      await openEdit(tester);

      await typeInto(tester, 'rp-edit-hours', '6');
      await tapKey(tester, 'rp-edit-apply');

      final RebalanceRequest r = repo.rebalances.single;
      expect(r.strategy, RebalanceStrategy.resize);
      expect(r.allocatedHoursPerDay, 6);
      expect(r.startDate, isNull);
      expect(r.endDate, isNull);
      expect(find.byKey(const Key('rp-edit-apply')), findsNothing);
      expect(find.text('Allocation updated'), findsOneWidget);
    });

    testWidgets('resizing the end date sends the new end', (WidgetTester tester) async {
      await openEdit(tester);

      await tapKey(tester, 'rp-edit-end');
      await tester.tap(find.text('15'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tapKey(tester, 'rp-edit-apply');

      expect(repo.rebalances.single.endDate, '2030-03-15');
      expect(repo.rebalances.single.startDate, isNull);
      expect(repo.rebalances.single.allocatedHoursPerDay, isNull);
    });

    testWidgets('an unchanged resize and an out-of-range value are refused locally', (WidgetTester tester) async {
      await openEdit(tester);

      await tapKey(tester, 'rp-edit-apply');
      expect(find.text('Nothing to change'), findsOneWidget);

      await typeInto(tester, 'rp-edit-hours', '25');
      await tapKey(tester, 'rp-edit-apply');
      expect(find.text('Hours per day must be between 0 and 24'), findsOneWidget);
      expect(repo.rebalances, isEmpty);
    });

    testWidgets('shifting by any number of days, also backwards', (WidgetTester tester) async {
      await openEdit(tester);
      await tester.tap(find.text('Shift'));
      await tester.pumpAndSettle();

      await typeInto(tester, 'rp-edit-shift-days', '-3');
      await tapKey(tester, 'rp-edit-apply');

      expect(repo.rebalances.single.strategy, RebalanceStrategy.shift);
      expect(repo.rebalances.single.shiftDays, -3);
    });

    testWidgets('a zero or non numeric shift is refused', (WidgetTester tester) async {
      await openEdit(tester);
      await tester.tap(find.text('Shift'));
      await tester.pumpAndSettle();

      await typeInto(tester, 'rp-edit-shift-days', '0');
      await tapKey(tester, 'rp-edit-apply');
      expect(find.text('Enter a number of days other than zero'), findsOneWidget);

      await typeInto(tester, 'rp-edit-shift-days', 'abc');
      await tapKey(tester, 'rp-edit-apply');
      expect(find.text('Enter a number of days other than zero'), findsOneWidget);
      expect(repo.rebalances, isEmpty);
    });

    testWidgets('reassigning needs another employee and sends it', (WidgetTester tester) async {
      await openEdit(tester);
      await tester.tap(find.text('Reassign'));
      await tester.pumpAndSettle();

      await tapKey(tester, 'rp-edit-apply');
      expect(find.text('Choose an employee'), findsOneWidget);
      expect(repo.rebalances, isEmpty);

      await pickFromDropdown(tester, 'rp-edit-employee', 'Bruno Bianchi');
      await tapKey(tester, 'rp-edit-apply');

      expect(repo.rebalances.single.strategy, RebalanceStrategy.reassign);
      expect(repo.rebalances.single.employeeId, 'e2');
    });

    testWidgets('the current employee is not offered when reassigning', (WidgetTester tester) async {
      await openEdit(tester);
      await tester.tap(find.text('Reassign'));
      await tester.pumpAndSettle();

      await tapKey(tester, 'rp-edit-employee');

      expect(find.text('Anna Rossi'), findsOneWidget);
      expect(find.text('Bruno Bianchi'), findsOneWidget);
    });

    testWidgets('splitting sends the split date and optionally the colleague for the second part', (
      WidgetTester tester,
    ) async {
      repo.mutationResult = AllocationMutationResult.fromJson(
        mutationJson(<Map<String, dynamic>>[
          allocationJson('a1', end: '2030-03-05'),
          allocationJson('a1b', start: '2030-03-06', employeeId: 'e2', employeeName: 'Bruno Bianchi'),
        ]),
      );
      await openEdit(tester);
      await tester.tap(find.text('Split'));
      await tester.pumpAndSettle();

      await pickFromDropdown(tester, 'rp-edit-split-employee', 'Bruno Bianchi');
      await tapKey(tester, 'rp-edit-apply');

      final RebalanceRequest r = repo.rebalances.single;
      expect(r.strategy, RebalanceStrategy.split);
      expect(r.splitDate, '2030-03-06');
      expect(r.employeeId, 'e2');
    });

    testWidgets('a split of a one day allocation is refused', (WidgetTester tester) async {
      await openEdit(
        tester,
        allocation: fakeAllocation('a1', start: '2030-03-04', end: '2030-03-04'),
      );
      await tester.tap(find.text('Split'));
      await tester.pumpAndSettle();

      await tapKey(tester, 'rp-edit-apply');

      expect(find.text('The split date must fall inside the period, after its start'), findsOneWidget);
      expect(repo.rebalances, isEmpty);
    });

    testWidgets('a refused rebalance keeps the editor open with the reason', (WidgetTester tester) async {
      await openEdit(tester);
      await typeInto(tester, 'rp-edit-hours', '6');
      repo.failure = overloadRefusal;

      await tapKey(tester, 'rp-edit-apply');

      expect(find.text('The resource would be overloaded'), findsOneWidget);
      expect(find.byKey(const Key('rp-edit-apply')), findsOneWidget);
    });

    testWidgets('delete asks for a confirmation and cancelling keeps the allocation', (WidgetTester tester) async {
      await openEdit(tester);

      await tapKey(tester, 'rp-edit-delete');
      expect(find.text('Delete the allocation?'), findsOneWidget);
      await tapKey(tester, 'rp-confirm-cancel');

      expect(repo.calls.where((String c) => c.startsWith('delete')), isEmpty);
      expect(find.byKey(const Key('rp-edit-apply')), findsOneWidget);
    });

    testWidgets('a confirmed delete removes the allocation from the agenda', (WidgetTester tester) async {
      repo.allocationRows = <ResourceAllocation>[fakeAllocation('a1'), fakeAllocation('a2', start: '2030-03-11', end: '2030-03-15')];
      await openAllocations(tester);

      await tapKey(tester, 'rp-edit-a1');
      expect(find.text('Edit allocation'), findsOneWidget);
      await tapKey(tester, 'rp-edit-delete');
      expect(find.textContaining('The allocation of Anna Rossi will be deleted'), findsOneWidget);
      await tapKey(tester, 'rp-confirm-ok');

      expect(repo.calls, contains('delete:a1'));
      expect(find.byKey(const Key('rp-alloc-a1')), findsNothing);
      expect(find.byKey(const Key('rp-alloc-a2')), findsOneWidget);
      expect(find.text('Allocation deleted'), findsOneWidget);
    });

    testWidgets('a refused delete shows the reason and stays on the editor', (WidgetTester tester) async {
      await openEdit(tester);
      repo.failure = const ResourcePlanningException(ResourcePlanningErrorKind.notFound);

      await tapKey(tester, 'rp-edit-delete');
      await tapKey(tester, 'rp-confirm-ok');

      expect(find.text('Item not found'), findsOneWidget);
      expect(find.byKey(const Key('rp-edit-delete')), findsOneWidget);
    });

    testWidgets('the agenda edit button opens the editor and a split shows both parts', (WidgetTester tester) async {
      repo.allocationRows = <ResourceAllocation>[fakeAllocation('a1')];
      repo.mutationResult = AllocationMutationResult.fromJson(
        mutationJson(<Map<String, dynamic>>[
          allocationJson('a1', end: '2030-03-05'),
          allocationJson('a1b', start: '2030-03-06'),
        ]),
      );
      await openAllocations(tester);

      await tapKey(tester, 'rp-edit-a1');
      await tester.tap(find.text('Split'));
      await tester.pumpAndSettle();
      await tapKey(tester, 'rp-edit-apply');

      expect(find.byKey(const Key('rp-alloc-a1')), findsOneWidget);
      expect(find.byKey(const Key('rp-alloc-a1b')), findsOneWidget);
    });
  });

  group('setup hub', () {
    testWidgets('the setup tab lists the four configuration screens', (WidgetTester tester) async {
      tallScreen(tester);
      await tester.pumpWidget(host(const ResourcePlanningHomePage()));
      await tester.pumpAndSettle();

      await tapKey(tester, 'rp-tab-setup');

      expect(find.byKey(const Key('rp-setup-skills')), findsOneWidget);
      expect(find.byKey(const Key('rp-setup-profiles')), findsOneWidget);
      expect(find.byKey(const Key('rp-setup-targets')), findsOneWidget);
      expect(find.byKey(const Key('rp-setup-holidays')), findsOneWidget);
    });

    testWidgets('each entry opens its screen', (WidgetTester tester) async {
      tallScreen(tester);
      await tester.pumpWidget(host(const ResourcePlanningHomePage()));
      await tester.pumpAndSettle();
      await tapKey(tester, 'rp-tab-setup');

      await tapKey(tester, 'rp-setup-skills');
      expect(find.byKey(const Key('rp-skill-add')), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tapKey(tester, 'rp-setup-profiles');
      expect(find.byKey(const Key('rp-profiles-employee')), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tapKey(tester, 'rp-setup-targets');
      expect(find.byKey(const Key('rp-target-add')), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tapKey(tester, 'rp-setup-holidays');
      expect(find.byKey(const Key('rp-holiday-add')), findsOneWidget);
    });
  });

  group('skills screen', () {
    testWidgets('lists the skills with category and certificate code', (WidgetTester tester) async {
      repo.skillRows = <Skill>[
        Skill.fromJson(skillJson('s1', 'Flutter')),
        Skill.fromJson(skillJson('s3', 'Forklift', category: 'HSE', cert: true, code: 'FORK')),
      ];

      await openPage(tester, const SkillsPage());

      expect(find.text('Flutter'), findsOneWidget);
      expect(find.text('Engineering'), findsOneWidget);
      expect(find.text('HSE - FORK'), findsOneWidget);
    });

    testWidgets('an empty taxonomy shows the empty message', (WidgetTester tester) async {
      repo.skillRows = <Skill>[];

      await openPage(tester, const SkillsPage());

      expect(find.byKey(const Key('rp-skills-empty')), findsOneWidget);
    });

    testWidgets('a forbidden answer shows the access message with a retry', (WidgetTester tester) async {
      repo.failure = const ResourcePlanningException(ResourcePlanningErrorKind.forbidden);

      await openPage(tester, const SkillsPage());

      expect(find.byKey(const Key('rp-skills-error')), findsOneWidget);
      expect(find.text('You do not have access to this function'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('a form without category and name reports both, a certificate needs its code', (
      WidgetTester tester,
    ) async {
      await openPage(tester, const SkillsPage());
      await tapKey(tester, 'rp-skill-add');

      await tapKey(tester, 'rp-skill-save');
      expect(find.text('The category is required'), findsOneWidget);
      expect(find.text('The name is required'), findsOneWidget);

      await typeInto(tester, 'rp-skill-category', 'HSE');
      await typeInto(tester, 'rp-skill-name', 'Forklift');
      await tapKey(tester, 'rp-skill-requires-cert');
      await tapKey(tester, 'rp-skill-save');
      expect(find.text('Enter the certificate code'), findsOneWidget);
      expect(repo.skillDrafts, isEmpty);
    });

    testWidgets('a new skill is created and listed', (WidgetTester tester) async {
      await openPage(tester, const SkillsPage());
      await tapKey(tester, 'rp-skill-add');
      await typeInto(tester, 'rp-skill-category', 'HSE');
      await typeInto(tester, 'rp-skill-name', 'Forklift');
      await tapKey(tester, 'rp-skill-requires-cert');
      await typeInto(tester, 'rp-skill-cert-code', 'FORK');

      await tapKey(tester, 'rp-skill-save');

      expect(repo.calls, contains('skill-create'));
      expect(repo.skillDrafts.single.certificationCode, 'FORK');
      expect(find.byKey(const Key('rp-skill-sk-new-1')), findsOneWidget);
      expect(find.text('Skill saved'), findsOneWidget);
    });

    testWidgets('tapping a skill edits it', (WidgetTester tester) async {
      await openPage(tester, const SkillsPage());

      await tapKey(tester, 'rp-skill-s1');
      expect(find.text('Edit skill'), findsOneWidget);
      await typeInto(tester, 'rp-skill-name', 'Flutter 3');
      await tapKey(tester, 'rp-skill-save');

      expect(repo.calls, contains('skill-update:s1'));
      expect(find.text('Flutter 3'), findsOneWidget);
    });

    testWidgets('a refused save is shown on the form and the form stays open', (WidgetTester tester) async {
      await openPage(tester, const SkillsPage());
      await tapKey(tester, 'rp-skill-add');
      await typeInto(tester, 'rp-skill-category', 'HSE');
      await typeInto(tester, 'rp-skill-name', 'Forklift');
      repo.failure = const ResourcePlanningException(
        ResourcePlanningErrorKind.invalid,
        violations: <ApiCode>[ApiCode('certification_code_required')],
      );

      await tapKey(tester, 'rp-skill-save');

      expect(find.byKey(const Key('rp-sheet-error')), findsOneWidget);
      expect(find.text('The certificate code is required for this skill'), findsOneWidget);
      expect(find.byKey(const Key('rp-skill-save')), findsOneWidget);
    });

    testWidgets('deleting a skill asks for a confirmation', (WidgetTester tester) async {
      await openPage(tester, const SkillsPage());

      await tapKey(tester, 'rp-skill-delete-s1');
      expect(find.text('The skill Flutter will be removed from the taxonomy.'), findsOneWidget);
      await tapKey(tester, 'rp-confirm-cancel');
      expect(find.byKey(const Key('rp-skill-s1')), findsOneWidget);

      await tapKey(tester, 'rp-skill-delete-s1');
      await tapKey(tester, 'rp-confirm-ok');

      expect(repo.calls, contains('skill-delete:s1'));
      expect(find.byKey(const Key('rp-skill-s1')), findsNothing);
      expect(find.text('Skill deleted'), findsOneWidget);
    });
  });

  group('employee skill profiles screen', () {
    setUp(() {
      repo.profileRows = <EmployeeSkillProfile>[
        EmployeeSkillProfile.fromJson(
          profileJson('pr-s1', skillId: 's1', level: 3, cert: true, certStatus: 'expired', validUntil: '2029-01-31'),
        ),
      ];
    });

    testWidgets('asks to choose an employee first', (WidgetTester tester) async {
      await openPage(tester, const SkillProfilesPage());

      expect(find.byKey(const Key('rp-profiles-hint')), findsOneWidget);
      expect(find.byKey(const Key('rp-profile-add')), findsNothing);
    });

    testWidgets('choosing an employee lists the skills with level and certificate verdict', (
      WidgetTester tester,
    ) async {
      await openPage(tester, const SkillProfilesPage());

      await pickFromDropdown(tester, 'rp-profiles-employee', 'Anna Rossi');

      expect(find.text('Flutter - 3/5'), findsOneWidget);
      expect(find.textContaining('Certificate expired'), findsOneWidget);
      expect(find.textContaining('Valid until 2029-01-31'), findsOneWidget);
      expect(repo.calls, contains('profiles:e1'));
    });

    testWidgets('an employee without skills shows the empty message', (WidgetTester tester) async {
      repo.profileRows = <EmployeeSkillProfile>[];

      await openPage(tester, const SkillProfilesPage(initialEmployeeId: 'e1'));

      expect(find.byKey(const Key('rp-profiles-empty')), findsOneWidget);
    });

    testWidgets('adding a skill upserts the level and expiry', (WidgetTester tester) async {
      await openPage(tester, const SkillProfilesPage(initialEmployeeId: 'e1'));
      await tapKey(tester, 'rp-profile-add');

      await tapKey(tester, 'rp-profile-save');
      expect(find.text('Choose a skill'), findsOneWidget);
      expect(repo.profileDrafts, isEmpty);

      await pickFromDropdown(tester, 'rp-profile-skill', 'Engineering / Dart');
      await pickFromDropdown(tester, 'rp-profile-level', '5');
      await tapKey(tester, 'rp-profile-valid-until');
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tapKey(tester, 'rp-profile-save');

      final SkillProfileDraft d = repo.profileDrafts.single;
      expect(d.employeeId, 'e1');
      expect(d.skillId, 's2');
      expect(d.proficiencyLevel, 5);
      expect(d.validUntilDate, isNotNull);
      expect(find.byKey(const Key('rp-profile-pr-s2')), findsOneWidget);
      expect(find.text('Profile saved'), findsOneWidget);
    });

    testWidgets('tapping a skill edits its level and the list keeps one row per skill', (WidgetTester tester) async {
      await openPage(tester, const SkillProfilesPage(initialEmployeeId: 'e1'));

      await tester.tap(find.text('Flutter - 3/5'));
      await tester.pumpAndSettle();
      await pickFromDropdown(tester, 'rp-profile-level', '1');
      await tapKey(tester, 'rp-profile-save');

      expect(repo.profileDrafts.single.skillId, 's1');
      expect(repo.profileDrafts.single.proficiencyLevel, 1);
      expect(find.text('Flutter - 1/5'), findsOneWidget);
      expect(find.byKey(const Key('rp-profile-pr-s1')), findsOneWidget);
    });

    testWidgets('the expiry can be cleared', (WidgetTester tester) async {
      await openPage(tester, const SkillProfilesPage(initialEmployeeId: 'e1'));
      await tester.tap(find.text('Flutter - 3/5'));
      await tester.pumpAndSettle();

      await tapKey(tester, 'rp-profile-valid-clear');
      await tapKey(tester, 'rp-profile-save');

      expect(repo.profileDrafts.single.validUntilDate, isNull);
    });

    testWidgets('removing a skill asks for a confirmation', (WidgetTester tester) async {
      await openPage(tester, const SkillProfilesPage(initialEmployeeId: 'e1'));

      await tapKey(tester, 'rp-profile-delete-pr-s1');
      expect(find.text('Remove Flutter from the employee profile?'), findsOneWidget);
      await tapKey(tester, 'rp-confirm-ok');

      expect(repo.calls, contains('profile-delete:pr-s1'));
      expect(find.byKey(const Key('rp-profile-pr-s1')), findsNothing);
      expect(find.text('Skill removed from the profile'), findsOneWidget);
    });

    testWidgets('a failed load of the profiles shows the error', (WidgetTester tester) async {
      repo.failure = const ResourcePlanningException(ResourcePlanningErrorKind.offline);

      await openPage(tester, const SkillProfilesPage(initialEmployeeId: 'e1'));

      expect(find.byKey(const Key('rp-profiles-error')), findsOneWidget);
      expect(find.text('No connection: planning needs the network'), findsOneWidget);
    });
  });

  group('utilization targets screen', () {
    setUp(() {
      repo.targetRows = <UtilizationTarget>[
        const UtilizationTarget(id: 't0', targetPercent: 70),
        const UtilizationTarget(id: 'td', departmentId: 'd1', targetPercent: 80),
      ];
    });

    testWidgets('lists the default and the department with their names', (WidgetTester tester) async {
      await openPage(tester, const UtilizationTargetsPage());

      expect(find.text('Company default'), findsOneWidget);
      expect(find.text('70%'), findsOneWidget);
      expect(find.text('Department: Engineering'), findsOneWidget);
      expect(find.text('80%'), findsOneWidget);
    });

    testWidgets('no targets shows the empty message', (WidgetTester tester) async {
      repo.targetRows = <UtilizationTarget>[];

      await openPage(tester, const UtilizationTargetsPage());

      expect(find.byKey(const Key('rp-targets-empty')), findsOneWidget);
    });

    testWidgets('a department target is saved for the chosen department', (WidgetTester tester) async {
      await openPage(tester, const UtilizationTargetsPage());
      await tapKey(tester, 'rp-target-add');
      await tester.tap(find.text('Department').last);
      await tester.pumpAndSettle();

      await typeInto(tester, 'rp-target-percent', '65');
      await tapKey(tester, 'rp-target-save');
      expect(find.text('Choose the department or cost center'), findsOneWidget);
      expect(repo.targetDrafts, isEmpty);

      await pickFromDropdown(tester, 'rp-target-department', 'Sales');
      await tapKey(tester, 'rp-target-save');

      final UtilizationTargetDraft d = repo.targetDrafts.single;
      expect(d.departmentId, 'd2');
      expect(d.costCenterId, isNull);
      expect(d.targetPercent, 65);
      expect(find.text('Target saved'), findsOneWidget);
      expect(find.text('Department: Sales'), findsOneWidget);
    });

    testWidgets('a cost center target is saved for the chosen cost center', (WidgetTester tester) async {
      await openPage(tester, const UtilizationTargetsPage());
      await tapKey(tester, 'rp-target-add');
      await tester.tap(find.text('Cost center').last);
      await tester.pumpAndSettle();

      await pickFromDropdown(tester, 'rp-target-cost-center', 'CC Sales');
      await typeInto(tester, 'rp-target-percent', '55,5');
      await tapKey(tester, 'rp-target-save');

      final UtilizationTargetDraft d = repo.targetDrafts.single;
      expect(d.costCenterId, 'c-d2');
      expect(d.departmentId, isNull);
      expect(d.targetPercent, 55.5);
    });

    testWidgets('a percentage outside 0 to 100 is refused', (WidgetTester tester) async {
      await openPage(tester, const UtilizationTargetsPage());
      await tapKey(tester, 'rp-target-add');

      await typeInto(tester, 'rp-target-percent', '120');
      await tapKey(tester, 'rp-target-save');
      expect(find.text('The target must be between 0 and 100'), findsOneWidget);

      await typeInto(tester, 'rp-target-percent', '');
      await tapKey(tester, 'rp-target-save');
      expect(find.text('The target must be between 0 and 100'), findsOneWidget);
      expect(repo.targetDrafts, isEmpty);
    });

    testWidgets('tapping the default edits it without a scope', (WidgetTester tester) async {
      await openPage(tester, const UtilizationTargetsPage());

      await tapKey(tester, 'rp-target-t0');
      expect(find.text('70'), findsOneWidget);
      await typeInto(tester, 'rp-target-percent', '72');
      await tapKey(tester, 'rp-target-save');

      final UtilizationTargetDraft d = repo.targetDrafts.single;
      expect(d.departmentId, isNull);
      expect(d.costCenterId, isNull);
      expect(d.targetPercent, 72);
      expect(find.text('72%'), findsOneWidget);
    });

    testWidgets('a refused save is shown on the sheet', (WidgetTester tester) async {
      await openPage(tester, const UtilizationTargetsPage());
      await tapKey(tester, 'rp-target-add');
      await typeInto(tester, 'rp-target-percent', '60');
      repo.failure = const ResourcePlanningException(ResourcePlanningErrorKind.forbidden);

      await tapKey(tester, 'rp-target-save');

      expect(find.byKey(const Key('rp-sheet-error')), findsOneWidget);
      expect(find.text('You do not have access to this function'), findsOneWidget);
    });
  });

  group('local holidays screen', () {
    setUp(() {
      repo.holidayRows = <LocalHoliday>[
        const LocalHoliday(
          id: 'h1',
          country: 'CH',
          regionCode: 'TI',
          month: 3,
          day: 19,
          name: 'San Giuseppe',
          dayFraction: 0.5,
        ),
        const LocalHoliday(id: 'h2', country: 'IT', month: 12, day: 24, year: 2030, name: 'Closing'),
      ];
    });

    testWidgets('lists the holidays with date, scope and half day', (WidgetTester tester) async {
      await openPage(tester, const LocalHolidaysPage());

      expect(find.text('San Giuseppe'), findsOneWidget);
      expect(find.text('03-19 - Every year - CH - TI - Half day'), findsOneWidget);
      expect(find.text('2030-12-24 - IT'), findsOneWidget);
    });

    testWidgets('no holidays shows the empty message', (WidgetTester tester) async {
      repo.holidayRows = <LocalHoliday>[];

      await openPage(tester, const LocalHolidaysPage());

      expect(find.byKey(const Key('rp-holidays-empty')), findsOneWidget);
    });

    testWidgets('a holiday is added with its scope and date', (WidgetTester tester) async {
      await openPage(tester, const LocalHolidaysPage());
      await tapKey(tester, 'rp-holiday-add');

      await typeInto(tester, 'rp-holiday-name', 'Company day');
      await pickFromDropdown(tester, 'rp-holiday-country', 'IT');
      await typeInto(tester, 'rp-holiday-region', 'LOM');
      await pickFromDropdown(tester, 'rp-holiday-month', '5');
      await typeInto(tester, 'rp-holiday-day', '2');
      await typeInto(tester, 'rp-holiday-year', '2031');
      await tapKey(tester, 'rp-holiday-half');
      await tapKey(tester, 'rp-holiday-save');

      final LocalHolidayDraft d = repo.holidayDrafts.single;
      expect(d.country, 'IT');
      expect(d.regionCode, 'LOM');
      expect(d.month, 5);
      expect(d.day, 2);
      expect(d.year, 2031);
      expect(d.dayFraction, 0.5);
      expect(find.text('Company day'), findsOneWidget);
      expect(find.text('Holiday added'), findsOneWidget);
    });

    testWidgets('a missing name and an impossible date are reported', (WidgetTester tester) async {
      await openPage(tester, const LocalHolidaysPage());
      await tapKey(tester, 'rp-holiday-add');

      await tapKey(tester, 'rp-holiday-save');
      expect(find.text('The name is required'), findsOneWidget);
      expect(find.text('The date is not valid'), findsOneWidget);

      await typeInto(tester, 'rp-holiday-name', 'X');
      await pickFromDropdown(tester, 'rp-holiday-month', '2');
      await typeInto(tester, 'rp-holiday-day', '30');
      await tapKey(tester, 'rp-holiday-save');
      expect(find.text('The date is not valid'), findsOneWidget);

      await typeInto(tester, 'rp-holiday-day', '10');
      await typeInto(tester, 'rp-holiday-year', 'abcd');
      await tapKey(tester, 'rp-holiday-save');
      expect(find.text('The date is not valid'), findsOneWidget);
      expect(repo.holidayDrafts, isEmpty);
    });

    testWidgets('a refused add is shown on the sheet', (WidgetTester tester) async {
      await openPage(tester, const LocalHolidaysPage());
      await tapKey(tester, 'rp-holiday-add');
      await typeInto(tester, 'rp-holiday-name', 'X');
      await typeInto(tester, 'rp-holiday-day', '10');
      repo.failure = const ResourcePlanningException(ResourcePlanningErrorKind.offline);

      await tapKey(tester, 'rp-holiday-save');

      expect(find.byKey(const Key('rp-sheet-error')), findsOneWidget);
      expect(find.text('No connection: planning needs the network'), findsOneWidget);
    });

    testWidgets('removing a holiday asks for a confirmation', (WidgetTester tester) async {
      await openPage(tester, const LocalHolidaysPage());

      await tapKey(tester, 'rp-holiday-delete-h1');
      expect(find.text('Remove the holiday San Giuseppe?'), findsOneWidget);
      await tapKey(tester, 'rp-confirm-cancel');
      expect(find.byKey(const Key('rp-holiday-h1')), findsOneWidget);

      await tapKey(tester, 'rp-holiday-delete-h1');
      await tapKey(tester, 'rp-confirm-ok');

      expect(repo.calls, contains('holiday-delete:h1'));
      expect(find.byKey(const Key('rp-holiday-h1')), findsNothing);
      expect(find.text('Holiday removed'), findsOneWidget);
    });

    testWidgets('a forbidden answer shows the access message with a retry', (WidgetTester tester) async {
      repo.failure = const ResourcePlanningException(ResourcePlanningErrorKind.forbidden);

      await openPage(tester, const LocalHolidaysPage());

      expect(find.byKey(const Key('rp-holidays-error')), findsOneWidget);
    });
  });
}
