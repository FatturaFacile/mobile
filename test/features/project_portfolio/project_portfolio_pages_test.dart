import 'package:fattura_facile/design/ff_tokens.dart';
import 'package:fattura_facile/features/project_portfolio/domain/project_plan.dart';
import 'package:fattura_facile/features/project_portfolio/domain/project_portfolio_models.dart';
import 'package:fattura_facile/features/project_portfolio/domain/project_portfolio_repository.dart';
import 'package:fattura_facile/features/project_portfolio/presentation/project_detail_page.dart';
import 'package:fattura_facile/features/project_portfolio/presentation/project_portfolio_controller.dart';
import 'package:fattura_facile/features/project_portfolio/presentation/project_portfolio_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class FakePortfolioRepository implements ProjectPortfolioRepository {
  FakePortfolioRepository({required this.projects, this.plan});

  final List<Project> projects;
  final ProjectPlan? plan;
  PortfolioSyncResult syncResult = const PortfolioSyncResult(
    PortfolioSyncStatus.synced,
  );
  final List<String> calls = <String>[];
  Project? lastProjectEdit;

  @override
  Stream<List<Project>> watchProjects(String tenantId) =>
      Stream<List<Project>>.value(projects);

  @override
  Stream<ProjectPlan?> watchPlan(String tenantId, String projectId) =>
      Stream<ProjectPlan?>.value(plan);

  @override
  Future<PortfolioSyncResult> sync(String tenantId) async {
    calls.add('sync');
    return syncResult;
  }

  @override
  Future<void> updateProject(String tenantId, Project edited) async {
    calls.add('updateProject');
    lastProjectEdit = edited;
  }

  @override
  Future<String> createNode(
    String tenantId, {
    required String projectId,
    required String title,
    String? parentNodeId,
    WbsNodeType nodeType = WbsNodeType.workPackage,
    double plannedHours = 0,
    double plannedCost = 0,
    double plannedRevenue = 0,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    calls.add('createNode:$title:${nodeType.wire}:${parentNodeId ?? '-'}');
    return 'new';
  }

  @override
  Future<void> updateNode(String tenantId, WbsNode edited) async {
    calls.add('updateNode:${edited.id}:${edited.percentComplete.round()}');
  }

  @override
  Future<void> deleteNode(String tenantId, String nodeId) async {
    calls.add('deleteNode:$nodeId');
  }

  @override
  Future<String> addDependency(
    String tenantId, {
    required String projectId,
    required String predecessorNodeId,
    required String successorNodeId,
    DependencyType type = DependencyType.fs,
    int lagDays = 0,
  }) async {
    calls.add('addDependency');
    throw const PortfolioException(PortfolioErrorKind.dependencyCycle);
  }

  @override
  Future<void> removeDependency(String tenantId, String dependencyId) async {
    calls.add('removeDependency:$dependencyId');
  }

  @override
  Future<String> captureBaseline(
    String tenantId, {
    required String projectId,
    required String name,
  }) async {
    calls.add('captureBaseline:$name');
    return 'b';
  }
}

Project _project(
  String id,
  String code,
  String name,
  ProjectStatus status, {
  double progress = 0,
}) => Project(
  id: id,
  tenantId: 't1',
  projectCode: code,
  name: name,
  status: status,
  percentComplete: progress,
);

WbsNode _node(
  String id,
  String code,
  String title, {
  String? parent,
  int? start,
  int? end,
  double progress = 0,
  WbsNodeType type = WbsNodeType.workPackage,
}) => WbsNode(
  id: id,
  projectId: 'p1',
  parentNodeId: parent,
  wbsCode: code,
  title: title,
  nodeType: type,
  percentComplete: progress,
  startDate: start == null ? null : DateTime.utc(2027, 1, start),
  endDate: end == null ? null : DateTime.utc(2027, 1, end),
);

ProjectPlan _plan() => ProjectPlan.build(
  project: const Project(
    id: 'p1',
    tenantId: 't1',
    projectCode: 'PRJ-1',
    name: 'Bridge',
    status: ProjectStatus.active,
    cupCode: 'B81B21000140001',
  ),
  nodes: <WbsNode>[
    _node('ph', '1', 'Design', type: WbsNodeType.phase),
    _node('a', '1.1', 'Drawings', parent: 'ph', start: 1, end: 3),
    _node('b', '1.2', 'Review', parent: 'ph', start: 1, end: 2, progress: 100),
    _node('m', '2', 'Sign-off', start: 4, end: 4, type: WbsNodeType.milestone),
  ],
  dependencies: const <TaskDependency>[
    TaskDependency(
      id: 'd1',
      projectId: 'p1',
      predecessorNodeId: 'a',
      successorNodeId: 'm',
    ),
  ],
  baselines: const <ProjectBaseline>[],
);

void main() {
  void tallScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(1000, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Widget host(FakePortfolioRepository repo, Widget child) => ProviderScope(
    key: UniqueKey(),
    overrides: [projectPortfolioRepositoryProvider.overrideWithValue(repo)],
    child: MaterialApp(theme: ffThemeData(), home: child),
  );

  testWidgets('the list filters by status and by search text', (
    WidgetTester tester,
  ) async {
    final FakePortfolioRepository repo = FakePortfolioRepository(
      projects: <Project>[
        _project('p1', 'PRJ-1', 'Bridge', ProjectStatus.active, progress: 40),
        _project('p2', 'PRJ-2', 'Tunnel', ProjectStatus.planning),
      ],
    );
    await tester.pumpWidget(host(repo, const ProjectPortfolioPage()));
    await tester.pumpAndSettle();

    expect(find.text('PRJ-1 · Bridge'), findsOneWidget);
    expect(find.text('PRJ-2 · Tunnel'), findsOneWidget);
    expect(find.text('40%'), findsOneWidget);
    expect(repo.calls, contains('sync'));

    await tester.tap(find.widgetWithText(ChoiceChip, 'Planning'));
    await tester.pumpAndSettle();
    expect(find.text('PRJ-1 · Bridge'), findsNothing);
    expect(find.text('PRJ-2 · Tunnel'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'All'));
    await tester.enterText(find.byType(TextField), 'bridge');
    await tester.pumpAndSettle();
    expect(find.text('PRJ-1 · Bridge'), findsOneWidget);
    expect(find.text('PRJ-2 · Tunnel'), findsNothing);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();
    expect(find.text('No project available'), findsOneWidget);
  });

  testWidgets('an offline sync shows the banner and keeps the data', (
    WidgetTester tester,
  ) async {
    final FakePortfolioRepository repo = FakePortfolioRepository(
      projects: <Project>[
        _project('p1', 'PRJ-1', 'Bridge', ProjectStatus.active),
      ],
    )..syncResult = const PortfolioSyncResult(PortfolioSyncStatus.offline);
    await tester.pumpWidget(host(repo, const ProjectPortfolioPage()));
    await tester.pumpAndSettle();
    expect(
      find.text('Offline: showing the data stored on this device'),
      findsOneWidget,
    );
    expect(find.text('PRJ-1 · Bridge'), findsOneWidget);
  });

  testWidgets('the detail shows the roll-up, CUP and the outline', (
    WidgetTester tester,
  ) async {
    final FakePortfolioRepository repo = FakePortfolioRepository(
      projects: const <Project>[],
      plan: _plan(),
    );
    await tester.pumpWidget(
      host(repo, const ProjectDetailPage(projectId: 'p1')),
    );
    await tester.pumpAndSettle();

    expect(find.text('PRJ-1'), findsOneWidget);
    expect(find.text('Bridge'), findsOneWidget);
    expect(find.textContaining('B81B21000140001'), findsOneWidget);
    expect(find.text('1  Design'), findsOneWidget);
    expect(find.text('1.1  Drawings'), findsOneWidget);
    expect(find.text('2  Sign-off'), findsOneWidget);
  });

  testWidgets(
    'the board puts finished work in Done and moves a card with the menu',
    (WidgetTester tester) async {
      final FakePortfolioRepository repo = FakePortfolioRepository(
        projects: const <Project>[],
        plan: _plan(),
      );
      await tester.pumpWidget(
        host(repo, const ProjectDetailPage(projectId: 'p1')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Board'));
      await tester.pumpAndSettle();

      // Summary nodes are not cards: Drawings and Sign-off are to do, Review is done.
      expect(find.text('To do (2)'), findsOneWidget);
      expect(find.text('In progress (0)'), findsOneWidget);
      expect(find.text('Done (1)'), findsOneWidget);

      await tester.tap(find.byTooltip('Move to').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Move to Done'));
      await tester.pumpAndSettle();
      expect(
        repo.calls.any(
          (String c) => c.endsWith(':100') && c.startsWith('updateNode:'),
        ),
        isTrue,
      );
    },
  );

  testWidgets('the timeline lists the critical path', (
    WidgetTester tester,
  ) async {
    final FakePortfolioRepository repo = FakePortfolioRepository(
      projects: const <Project>[],
      plan: _plan(),
    );
    await tester.pumpWidget(
      host(repo, const ProjectDetailPage(projectId: 'p1')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Timeline'));
    await tester.pumpAndSettle();
    expect(find.text('Critical path'), findsOneWidget);
    expect(find.widgetWithText(Chip, '1.1'), findsOneWidget);
    expect(find.widgetWithText(Chip, '2'), findsOneWidget);
  });

  testWidgets('the baseline tab invites to capture the first one', (
    WidgetTester tester,
  ) async {
    final FakePortfolioRepository repo = FakePortfolioRepository(
      projects: const <Project>[],
      plan: _plan(),
    );
    await tester.pumpWidget(
      host(repo, const ProjectDetailPage(projectId: 'p1')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Baseline'));
    await tester.pumpAndSettle();
    expect(find.text('No baseline captured yet'), findsOneWidget);

    await tester.tap(find.text('Capture baseline'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Kick-off');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(repo.calls, contains('captureBaseline:Kick-off'));
  });

  testWidgets('adding an element sends the typed title', (
    WidgetTester tester,
  ) async {
    final FakePortfolioRepository repo = FakePortfolioRepository(
      projects: const <Project>[],
      plan: _plan(),
    );
    tallScreen(tester);
    await tester.pumpWidget(
      host(repo, const ProjectDetailPage(projectId: 'p1')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add element'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Permits');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(repo.calls, contains('createNode:Permits:work_package:-'));
  });

  testWidgets('an invalid CUP is flagged and cannot be saved', (
    WidgetTester tester,
  ) async {
    final FakePortfolioRepository repo = FakePortfolioRepository(
      projects: const <Project>[],
      plan: _plan(),
    );
    await tester.pumpWidget(
      host(repo, const ProjectDetailPage(projectId: 'p1')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Public funding codes'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'abc');
    await tester.pump();
    expect(find.text('The CUP has 15 letters or digits'), findsOneWidget);
    final FilledButton save = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Save'),
    );
    expect(save.onPressed, isNull);

    await tester.enterText(find.byType(TextField).first, 'b81b21000140002');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(repo.lastProjectEdit?.cupCode, 'B81B21000140002');
  });

  testWidgets('a refused link shows the reason', (WidgetTester tester) async {
    final FakePortfolioRepository repo = FakePortfolioRepository(
      projects: const <Project>[],
      plan: _plan(),
    );
    tallScreen(tester);
    await tester.pumpWidget(
      host(repo, const ProjectDetailPage(projectId: 'p1')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('1.1  Drawings'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Add link'));
    await tester.tap(find.text('Add link'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('2 Sign-off').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(repo.calls, contains('addDependency'));
    expect(find.text('This link would create a loop'), findsOneWidget);
  });
}
