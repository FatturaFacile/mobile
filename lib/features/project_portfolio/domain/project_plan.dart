import 'cpm_scheduler.dart';
import 'project_portfolio_models.dart';
import 'wbs_tree.dart';

/// Everything the detail screens need about one project, consistent with the local edits: the figures are rolled
/// up and the schedule recomputed from what is on the device, so an offline change shows up at once.
class ProjectPlan {
  const ProjectPlan({
    required this.project,
    required this.nodes,
    required this.dependencies,
    required this.baselines,
    required this.cpm,
    this.unsyncedIds = const <String>{},
  });

  /// Roll-up, then CPM, on the raw synced and pending records.
  factory ProjectPlan.build({
    required Project project,
    required List<WbsNode> nodes,
    required List<TaskDependency> dependencies,
    required List<ProjectBaseline> baselines,
    Set<String> unsyncedIds = const <String>{},
  }) {
    final List<WbsNode> rolled = WbsRollup.apply(nodes);
    final CpmResult cpm = CpmScheduler.schedule(rolled, dependencies);
    final List<WbsNode> scheduled = cpm.hasCycle
        ? rolled
        : CpmScheduler.apply(rolled, cpm);
    scheduled.sort(
      (WbsNode a, WbsNode b) => compareWbsCodes(a.wbsCode, b.wbsCode),
    );
    final List<ProjectBaseline> orderedBaselines =
        <ProjectBaseline>[...baselines]..sort(
          (ProjectBaseline a, ProjectBaseline b) =>
              b.baselineNumber.compareTo(a.baselineNumber),
        );
    return ProjectPlan(
      project: WbsRollup.project(project, scheduled),
      nodes: scheduled,
      dependencies: dependencies,
      baselines: orderedBaselines,
      cpm: cpm,
      unsyncedIds: unsyncedIds,
    );
  }

  final Project project;

  /// Rolled-up and scheduled nodes, in outline order.
  final List<WbsNode> nodes;
  final List<TaskDependency> dependencies;

  /// Newest first.
  final List<ProjectBaseline> baselines;
  final CpmResult cpm;

  /// Ids of records with changes the server has not acknowledged yet.
  final Set<String> unsyncedIds;

  WbsTree get tree => WbsTree(nodes);

  List<WbsNode> get milestones => <WbsNode>[
    for (final WbsNode n in nodes)
      if (n.isMilestone) n,
  ];

  List<WbsNode> get criticalNodes => <WbsNode>[
    for (final String id in cpm.criticalPath)
      for (final WbsNode n in nodes)
        if (n.id == id) n,
  ];

  WbsNode? node(String id) {
    for (final WbsNode n in nodes) {
      if (n.id == id) {
        return n;
      }
    }
    return null;
  }

  List<TaskDependency> predecessorsOf(String nodeId) => <TaskDependency>[
    for (final TaskDependency d in dependencies)
      if (d.successorNodeId == nodeId) d,
  ];

  List<TaskDependency> successorsOf(String nodeId) => <TaskDependency>[
    for (final TaskDependency d in dependencies)
      if (d.predecessorNodeId == nodeId) d,
  ];
}
