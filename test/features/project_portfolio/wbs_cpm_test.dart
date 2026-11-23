import 'package:fattura_facile/features/project_portfolio/domain/baseline_variance.dart';
import 'package:fattura_facile/features/project_portfolio/domain/cpm_scheduler.dart';
import 'package:fattura_facile/features/project_portfolio/domain/project_plan.dart';
import 'package:fattura_facile/features/project_portfolio/domain/project_portfolio_models.dart';
import 'package:fattura_facile/features/project_portfolio/domain/wbs_tree.dart';
import 'package:flutter_test/flutter_test.dart';

DateTime _d(int day) => DateTime.utc(2027, 1, day);

WbsNode _node(
  String id,
  String code, {
  int? start,
  int? end,
  String? parent,
  WbsNodeType type = WbsNodeType.workPackage,
  double hours = 0,
  double cost = 0,
  double progress = 0,
  int sort = 0,
}) => WbsNode(
  id: id,
  projectId: 'p1',
  parentNodeId: parent,
  wbsCode: code,
  title: 'Node $id',
  nodeType: type,
  plannedHours: hours,
  plannedCost: cost,
  percentComplete: progress,
  startDate: start == null ? null : _d(start),
  endDate: end == null ? null : _d(end),
  sortOrder: sort,
);

TaskDependency _dep(
  String from,
  String to, {
  DependencyType type = DependencyType.fs,
  int lag = 0,
}) => TaskDependency(
  id: '$from-$to',
  projectId: 'p1',
  predecessorNodeId: from,
  successorNodeId: to,
  dependencyType: type,
  lagDays: lag,
);

void main() {
  group('models', () {
    test('project parses decimals, camelCase and snake_case enums', () {
      final Project p = Project.fromJson(<String, dynamic>{
        'id': 'p1',
        'tenant_id': 't1',
        'project_code': 'PRJ-1',
        'name': 'Bridge',
        'project_type': 'INTERNAL_R_AND_D',
        'billing_model': 'salProgress',
        'status': 'on_hold',
        'start_date': '2027-01-05T00:00:00Z',
        'cup_code': ' B81B21000140001 ',
        'cig_code': '',
        'planned_hours': '120.50',
        'actual_cost': 99,
        'percent_complete': '33.3',
      });
      expect(p.projectType, ProjectType.internalRAndD);
      expect(p.billingModel, BillingModel.salProgress);
      expect(p.status, ProjectStatus.onHold);
      expect(p.startDate, DateTime.utc(2027, 1, 5));
      expect(p.cupCode, 'B81B21000140001');
      expect(p.cigCode, isNull);
      expect(p.plannedHours, 120.5);
      expect(p.actualCost, 99);
      expect(p.toJson()['status'], 'on_hold');
      expect(p.toJson()['start_date'], '2027-01-05');
    });

    test('an unknown enum value falls back to a safe default', () {
      final Project p = Project.fromJson(<String, dynamic>{
        'id': 'p1',
        'status': 'archived',
        'project_type': '???',
      });
      expect(p.status, ProjectStatus.planning);
      expect(p.projectType, ProjectType.clientBillable);
    });

    test('node level, progress state and critical flag', () {
      final WbsNode n = WbsNode.fromJson(<String, dynamic>{
        'id': 'n1',
        'project_id': 'p1',
        'wbs_code': '1.2.3',
        'title': 'Leaf',
        'node_type': 'milestone',
        'percent_complete': '100',
        'is_critical': 1,
        'total_float_days': '0',
      });
      expect(n.level, 2);
      expect(n.isMilestone, isTrue);
      expect(n.progressState, WbsProgressState.done);
      expect(n.isCritical, isTrue);
      expect(n.totalFloatDays, 0);
      expect(
        _node('a', '1', progress: 40).progressState,
        WbsProgressState.inProgress,
      );
      expect(_node('a', '1').progressState, WbsProgressState.notStarted);
    });

    test('dependency and baseline round trip', () {
      final TaskDependency d = TaskDependency.fromJson(<String, dynamic>{
        'id': 'd1',
        'project_id': 'p1',
        'predecessor_node_id': 'a',
        'successor_node_id': 'b',
        'dependency_type': 'SF',
        'lag_days': '-2',
      });
      expect(d.dependencyType, DependencyType.sf);
      expect(d.lagDays, -2);
      expect(d.toJson()['dependency_type'], 'sf');

      final ProjectBaseline b = ProjectBaseline.fromJson(<String, dynamic>{
        'id': 'b1',
        'project_id': 'p1',
        'baseline_number': 2,
        'name': 'Re-plan',
        'captured_at': '2027-02-01T10:00:00Z',
        'snapshot_json': <String, dynamic>{'nodes': <dynamic>[]},
      });
      expect(b.baselineNumber, 2);
      expect(b.snapshotJson, '{"nodes":[]}');
      expect(b.capturedAt, DateTime.utc(2027, 2, 1, 10));
    });
  });

  group('WBS tree and roll-up', () {
    test('codes compare numerically segment by segment', () {
      expect(compareWbsCodes('1.2', '1.10'), lessThan(0));
      expect(compareWbsCodes('2', '1.9'), greaterThan(0));
      expect(compareWbsCodes('1', '1.1'), lessThan(0));
      expect(compareWbsCodes('1.1', '1.1'), 0);
    });

    test('next child code follows the highest sibling', () {
      final WbsTree tree = WbsTree(<WbsNode>[
        _node('a', '1'),
        _node('b', '2'),
        _node('a1', '1.1', parent: 'a'),
        _node('a2', '1.2', parent: 'a'),
      ]);
      expect(tree.nextChildCode(null), '3');
      expect(tree.nextChildCode('a'), '1.3');
      expect(tree.nextChildCode('b'), '2.1');
      expect(tree.nextChildCode('a2'), '1.2.1');
    });

    test(
      'flatten honours collapsed nodes and a missing parent goes to the root',
      () {
        final WbsTree tree = WbsTree(<WbsNode>[
          _node('a', '1'),
          _node('a1', '1.1', parent: 'a'),
          _node('a11', '1.1.1', parent: 'a1'),
          _node('orphan', '9', parent: 'not-synced-yet'),
        ]);
        expect(tree.flatten().map((WbsRow r) => r.node.id), <String>[
          'a',
          'a1',
          'a11',
          'orphan',
        ]);
        expect(
          tree.flatten(collapsed: <String>{'a'}).map((WbsRow r) => r.node.id),
          <String>['a', 'orphan'],
        );
        expect(tree.flatten()[2].depth, 2);
        expect(tree.subtreeIds('a'), <String>['a', 'a1', 'a11']);
        expect(tree.isInSubtree('a', 'a11'), isTrue);
        expect(tree.isInSubtree('a1', 'a'), isFalse);
      },
    );

    test(
      'a summary shows the sum of its children and hours-weighted progress',
      () {
        final List<WbsNode> rolled = WbsRollup.apply(<WbsNode>[
          _node('p', '1', hours: 999, progress: 99),
          _node(
            'c1',
            '1.1',
            parent: 'p',
            hours: 10,
            cost: 100,
            progress: 100,
            start: 1,
            end: 3,
          ),
          _node(
            'c2',
            '1.2',
            parent: 'p',
            hours: 30,
            cost: 300,
            progress: 0,
            start: 5,
            end: 10,
          ),
        ]);
        final WbsNode parent = rolled.firstWhere((WbsNode n) => n.id == 'p');
        expect(parent.plannedHours, 40);
        expect(parent.plannedCost, 400);
        expect(parent.percentComplete, 25);
        expect(parent.startDate, _d(1));
        expect(parent.endDate, _d(10));
        // The leaves are untouched and the order of the input is kept.
        expect(rolled.map((WbsNode n) => n.id), <String>['p', 'c1', 'c2']);
        expect(rolled[1].plannedHours, 10);
      },
    );

    test('progress falls back to a plain average when no child has hours', () {
      final List<WbsNode> rolled = WbsRollup.apply(<WbsNode>[
        _node('p', '1'),
        _node('c1', '1.1', parent: 'p', progress: 100),
        _node('c2', '1.2', parent: 'p', progress: 0),
      ]);
      expect(rolled.first.percentComplete, 50);
    });

    test('roll-up runs through several levels and feeds the project', () {
      final List<WbsNode> rolled = WbsRollup.apply(<WbsNode>[
        _node('p', '1'),
        _node('d', '1.1', parent: 'p'),
        _node('w', '1.1.1', parent: 'd', hours: 8, cost: 80, progress: 50),
        _node('q', '2', hours: 2, cost: 20, progress: 100),
      ]);
      expect(rolled.firstWhere((WbsNode n) => n.id == 'p').plannedHours, 8);
      final Project project = WbsRollup.project(
        const Project(id: 'p1', tenantId: 't1', projectCode: 'P', name: 'N'),
        rolled,
      );
      expect(project.plannedHours, 10);
      expect(project.plannedCost, 100);
      expect(project.percentComplete, closeTo(60, 0.001));
    });
  });

  group('critical path', () {
    test(
      'finish to start chain is critical, a short parallel task has float',
      () {
        final List<WbsNode> nodes = <WbsNode>[
          _node('a', '1', start: 1, end: 3),
          _node('b', '2', start: 1, end: 2),
          _node('c', '3', start: 1, end: 1),
        ];
        final CpmResult r = CpmScheduler.schedule(nodes, <TaskDependency>[
          _dep('a', 'b'),
        ]);
        expect(r.hasCycle, isFalse);
        expect(r.nodes['b']!.earlyStart, _d(4));
        expect(r.nodes['b']!.earlyFinish, _d(5));
        expect(r.projectFinish, _d(5));
        expect(r.nodes['a']!.isCritical, isTrue);
        expect(r.nodes['b']!.isCritical, isTrue);
        expect(r.nodes['c']!.isCritical, isFalse);
        expect(r.nodes['c']!.totalFloatDays, 4);
        expect(r.nodes['c']!.freeFloatDays, 4);
        expect(r.criticalPath, <String>['a', 'b']);
      },
    );

    test(
      'start to start with lag delays the successor and leaves it float',
      () {
        final CpmResult r = CpmScheduler.schedule(
          <WbsNode>[
            _node('a', '1', start: 1, end: 5),
            _node('b', '2', start: 1, end: 2),
          ],
          <TaskDependency>[_dep('a', 'b', type: DependencyType.ss, lag: 2)],
        );
        expect(r.nodes['b']!.earlyStart, _d(3));
        expect(r.nodes['b']!.totalFloatDays, 1);
        expect(r.nodes['b']!.isCritical, isFalse);
        expect(r.nodes['a']!.isCritical, isTrue);
      },
    );

    test('finish to finish pulls the successor start so both end together', () {
      final CpmResult r = CpmScheduler.schedule(
        <WbsNode>[
          _node('a', '1', start: 1, end: 3),
          _node('b', '2', start: 1, end: 1),
        ],
        <TaskDependency>[_dep('a', 'b', type: DependencyType.ff)],
      );
      expect(r.nodes['b']!.earlyStart, _d(3));
      expect(r.nodes['b']!.earlyFinish, _d(3));
      expect(r.nodes['a']!.isCritical, isTrue);
      expect(r.nodes['b']!.isCritical, isTrue);
    });

    test('start to finish with lag', () {
      final CpmResult r = CpmScheduler.schedule(
        <WbsNode>[
          _node('a', '1', start: 1, end: 4),
          _node('b', '2', start: 1, end: 2),
        ],
        <TaskDependency>[_dep('a', 'b', type: DependencyType.sf, lag: 3)],
      );
      expect(r.nodes['b']!.earlyStart, _d(2));
      expect(r.nodes['b']!.earlyFinish, _d(3));
    });

    test('a negative lag is a lead', () {
      final CpmResult r = CpmScheduler.schedule(
        <WbsNode>[
          _node('a', '1', start: 1, end: 3),
          _node('b', '2', start: 1, end: 2),
        ],
        <TaskDependency>[_dep('a', 'b', lag: -1)],
      );
      expect(r.nodes['b']!.earlyStart, _d(3));
    });

    test('the planned start is a start-no-earlier-than constraint', () {
      final CpmResult r = CpmScheduler.schedule(
        <WbsNode>[
          _node('a', '1', start: 1, end: 3),
          _node('b', '2', start: 10, end: 11),
        ],
        <TaskDependency>[_dep('a', 'b')],
      );
      expect(r.nodes['b']!.earlyStart, _d(10));
      expect(r.nodes['a']!.totalFloatDays, 6);
      expect(r.nodes['b']!.isCritical, isTrue);
    });

    test('a milestone has no duration', () {
      final CpmResult r = CpmScheduler.schedule(
        <WbsNode>[
          _node('a', '1', start: 1, end: 3),
          _node('m', '2', start: 1, end: 1, type: WbsNodeType.milestone),
        ],
        <TaskDependency>[_dep('a', 'm')],
      );
      expect(r.nodes['m']!.earlyStart, _d(4));
      expect(r.nodes['m']!.earlyFinish, _d(4));
    });

    test(
      'summary nodes are outside the network and their links are ignored',
      () {
        final List<WbsNode> nodes = <WbsNode>[
          _node('p', '1', start: 1, end: 5),
          _node('c', '1.1', parent: 'p', start: 1, end: 5),
          _node('x', '2', start: 1, end: 2),
        ];
        final CpmResult r = CpmScheduler.schedule(nodes, <TaskDependency>[
          _dep('p', 'x'),
        ]);
        expect(r.nodes.containsKey('p'), isFalse);
        expect(r.nodes['x']!.earlyStart, _d(1));
      },
    );

    test('undated nodes are skipped and an empty plan has no result', () {
      expect(
        CpmScheduler.schedule(<WbsNode>[
          _node('a', '1'),
        ], const <TaskDependency>[]).nodes,
        isEmpty,
      );
    });

    test('a loop in the links is reported instead of looping', () {
      final CpmResult r = CpmScheduler.schedule(
        <WbsNode>[
          _node('a', '1', start: 1, end: 2),
          _node('b', '2', start: 1, end: 2),
        ],
        <TaskDependency>[_dep('a', 'b'), _dep('b', 'a')],
      );
      expect(r.hasCycle, isTrue);
      expect(r.nodes, isEmpty);
    });

    test('cycle check on a new link', () {
      final List<TaskDependency> deps = <TaskDependency>[
        _dep('a', 'b'),
        _dep('b', 'c'),
      ];
      expect(wouldCreateCycle(deps, 'c', 'a'), isTrue);
      expect(wouldCreateCycle(deps, 'b', 'a'), isTrue);
      expect(wouldCreateCycle(deps, 'a', 'c'), isFalse);
      expect(wouldCreateCycle(deps, 'a', 'a'), isTrue);
      expect(wouldCreateCycle(const <TaskDependency>[], 'a', 'b'), isFalse);
    });

    test('the plan applies the schedule on top of the roll-up', () {
      final ProjectPlan plan = ProjectPlan.build(
        project: const Project(
          id: 'p1',
          tenantId: 't1',
          projectCode: 'P',
          name: 'N',
        ),
        nodes: <WbsNode>[
          _node('ph', '1', hours: 1),
          _node('a', '1.1', parent: 'ph', start: 1, end: 3, hours: 10),
          _node('b', '1.2', parent: 'ph', start: 1, end: 2, hours: 5),
        ],
        dependencies: <TaskDependency>[_dep('a', 'b')],
        baselines: const <ProjectBaseline>[],
        unsyncedIds: <String>{'a'},
      );
      expect(plan.project.plannedHours, 15);
      expect(plan.node('ph')!.plannedHours, 15);
      expect(plan.node('b')!.earlyStart, _d(4));
      expect(plan.node('b')!.isCritical, isTrue);
      expect(plan.criticalNodes.map((WbsNode n) => n.id), <String>['a', 'b']);
      expect(plan.predecessorsOf('b').single.predecessorNodeId, 'a');
      expect(plan.successorsOf('a').single.successorNodeId, 'b');
      expect(plan.unsyncedIds, <String>{'a'});
    });
  });

  group('CUP and CIG', () {
    test('format checks accept the right length, any case, and empty', () {
      expect(ProcurementCodes.isValidCup('B81B21000140001'), isTrue);
      expect(ProcurementCodes.isValidCup(' b81b21000140001 '), isTrue);
      expect(ProcurementCodes.isValidCup('ABC'), isFalse);
      expect(ProcurementCodes.isValidCup('B81B2100014000!'), isFalse);
      expect(ProcurementCodes.isValidCup(null), isTrue);
      expect(ProcurementCodes.isValidCig('8383838B2C'), isTrue);
      expect(ProcurementCodes.isValidCig('8383838B2'), isFalse);
      expect(ProcurementCodes.isValidCig(''), isTrue);
      expect(ProcurementCodes.normalize(' ab 12 '), 'AB12');
      expect(ProcurementCodes.normalize('   '), isNull);
    });
  });

  group('baseline variance', () {
    ProjectBaseline baselineOf(List<WbsNode> nodes) => ProjectBaseline(
      id: 'b1',
      projectId: 'p1',
      baselineNumber: 1,
      name: 'B1',
      capturedAt: DateTime.utc(2027),
      snapshotJson: BaselineVariance.snapshotOf(nodes),
    );

    test('reports slips, deltas, new and removed nodes, in outline order', () {
      final List<WbsNode> original = <WbsNode>[
        _node('a', '1', start: 1, end: 5, hours: 10, cost: 100),
        _node('b', '2', start: 6, end: 8, hours: 4),
        _node('gone', '3', start: 1, end: 1),
      ];
      final ProjectBaseline baseline = baselineOf(original);
      final List<WbsNode> current = <WbsNode>[
        _node('a', '1', start: 3, end: 7, hours: 15, cost: 100),
        _node('b', '2', start: 6, end: 8, hours: 4),
        _node('new', '4', start: 9, end: 9),
      ];
      final List<NodeVariance> result = BaselineVariance.compare(
        baseline,
        current,
      );
      expect(result.map((NodeVariance v) => v.nodeId), <String>[
        'a',
        'b',
        'new',
        'gone',
      ]);

      final NodeVariance a = result[0];
      expect(a.startSlipDays, 2);
      expect(a.finishSlipDays, 2);
      expect(a.hoursDelta, 5);
      expect(a.costDelta, 0);
      expect(a.hasDrift, isTrue);

      expect(result[1].hasDrift, isFalse);
      expect(result[2].addedSinceBaseline, isTrue);
      expect(result[3].removedSinceBaseline, isTrue);
    });

    test('an early finish is a negative slip', () {
      final ProjectBaseline baseline = baselineOf(<WbsNode>[
        _node('a', '1', start: 1, end: 9),
      ]);
      final NodeVariance v = BaselineVariance.compare(baseline, <WbsNode>[
        _node('a', '1', start: 1, end: 6),
      ]).single;
      expect(v.finishSlipDays, -3);
      expect(v.startSlipDays, 0);
    });

    test('a snapshot that does not parse yields no nodes', () {
      final ProjectBaseline broken = ProjectBaseline(
        id: 'b',
        projectId: 'p1',
        baselineNumber: 1,
        name: 'x',
        capturedAt: DateTime.utc(2027),
        snapshotJson: '{not json',
      );
      expect(BaselineVariance.nodesOf(broken), isEmpty);
      expect(
        BaselineVariance.compare(broken, <WbsNode>[
          _node('a', '1'),
        ]).single.addedSinceBaseline,
        isTrue,
      );
    });
  });
}
