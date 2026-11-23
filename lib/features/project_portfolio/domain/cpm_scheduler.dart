/// Critical Path Method on the leaf nodes of the WBS, run on the device so the schedule stays consistent offline.
///
/// Time is counted in whole days from the earliest planned start. A task of `n` days starting on day `s` finishes
/// at `s + n` (exclusive), its last working day is `s + n - 1`; a milestone has no duration. A node's planned start
/// is a "start no earlier than" constraint, so a late predecessor pushes it and an early one never pulls it forward.
///
/// Supported relations, with lag `L` (negative: lead):
/// FS `start(s) >= finish(p) + L`, SS `start(s) >= start(p) + L`, FF `finish(s) >= finish(p) + L`,
/// SF `finish(s) >= start(p) + L`. Summary nodes (with children) are not part of the network: their dates come from
/// the roll-up, and dependencies that touch them are ignored by the scheduler.
library;

import 'project_portfolio_models.dart';
import 'wbs_tree.dart';

/// True when adding the link [predecessorId] -> [successorId] to [existing] would close a loop.
bool wouldCreateCycle(
  List<TaskDependency> existing,
  String predecessorId,
  String successorId,
) {
  if (predecessorId == successorId) {
    return true;
  }
  final Map<String, List<String>> next = <String, List<String>>{};
  for (final TaskDependency d in existing) {
    next
        .putIfAbsent(d.predecessorNodeId, () => <String>[])
        .add(d.successorNodeId);
  }
  final Set<String> seen = <String>{};
  final List<String> stack = <String>[successorId];
  while (stack.isNotEmpty) {
    final String current = stack.removeLast();
    if (current == predecessorId) {
      return true;
    }
    if (seen.add(current)) {
      stack.addAll(next[current] ?? const <String>[]);
    }
  }
  return false;
}

/// Schedule of one node, in absolute dates.
class CpmNode {
  const CpmNode({
    required this.earlyStart,
    required this.earlyFinish,
    required this.lateStart,
    required this.lateFinish,
    required this.totalFloatDays,
    required this.freeFloatDays,
    required this.isCritical,
  });

  final DateTime earlyStart;
  final DateTime earlyFinish;
  final DateTime lateStart;
  final DateTime lateFinish;
  final int totalFloatDays;
  final int freeFloatDays;
  final bool isCritical;
}

class CpmResult {
  const CpmResult({
    this.nodes = const <String, CpmNode>{},
    this.criticalPath = const <String>[],
    this.projectFinish,
    this.hasCycle = false,
  });

  /// Per node id; only nodes of the network (dated leaves).
  final Map<String, CpmNode> nodes;

  /// Ids of the critical nodes, in order of early start.
  final List<String> criticalPath;
  final DateTime? projectFinish;

  /// The dependencies loop, so no schedule could be computed.
  final bool hasCycle;
}

class _Item {
  _Item(this.node, this.duration, this.plannedStart);

  final WbsNode node;
  final int duration;
  final int plannedStart;
  int es = 0;
  int ls = 0;
  int lf = 0;

  int get ef => es + duration;
}

abstract final class CpmScheduler {
  static const int _day = 86400000;

  static int _dayIndex(DateTime date, DateTime origin) =>
      (DateTime.utc(date.year, date.month, date.day).millisecondsSinceEpoch -
          origin.millisecondsSinceEpoch) ~/
      _day;

  static DateTime _at(DateTime origin, int index) =>
      origin.add(Duration(days: index));

  static CpmResult schedule(
    List<WbsNode> nodes,
    List<TaskDependency> dependencies,
  ) {
    final WbsTree tree = WbsTree(nodes);
    final List<WbsNode> network = <WbsNode>[
      for (final WbsNode n in nodes)
        if (!tree.isSummary(n.id) && n.startDate != null) n,
    ];
    if (network.isEmpty) {
      return const CpmResult();
    }
    DateTime origin = network.first.startDate!;
    for (final WbsNode n in network) {
      if (n.startDate!.isBefore(origin)) {
        origin = n.startDate!;
      }
    }

    final Map<String, _Item> items = <String, _Item>{};
    for (final WbsNode n in network) {
      final DateTime start = n.startDate!;
      final DateTime end = n.endDate ?? start;
      final int span = _dayIndex(end, origin) - _dayIndex(start, origin) + 1;
      final int duration = n.isMilestone ? 0 : (span < 1 ? 1 : span);
      items[n.id] = _Item(n, duration, _dayIndex(start, origin));
    }
    final List<TaskDependency> links = <TaskDependency>[
      for (final TaskDependency d in dependencies)
        if (items.containsKey(d.predecessorNodeId) &&
            items.containsKey(d.successorNodeId))
          d,
    ];

    final List<String>? order = _topologicalOrder(items.keys, links);
    if (order == null) {
      return const CpmResult(hasCycle: true);
    }

    final Map<String, List<TaskDependency>> incoming =
        <String, List<TaskDependency>>{};
    final Map<String, List<TaskDependency>> outgoing =
        <String, List<TaskDependency>>{};
    for (final TaskDependency d in links) {
      incoming.putIfAbsent(d.successorNodeId, () => <TaskDependency>[]).add(d);
      outgoing
          .putIfAbsent(d.predecessorNodeId, () => <TaskDependency>[])
          .add(d);
    }

    // Forward pass: early start and finish.
    for (final String id in order) {
      final _Item s = items[id]!;
      int start = s.plannedStart;
      for (final TaskDependency d in incoming[id] ?? const <TaskDependency>[]) {
        final _Item p = items[d.predecessorNodeId]!;
        final int bound = switch (d.dependencyType) {
          DependencyType.fs => p.ef + d.lagDays,
          DependencyType.ss => p.es + d.lagDays,
          DependencyType.ff => p.ef + d.lagDays - s.duration,
          DependencyType.sf => p.es + d.lagDays - s.duration,
        };
        start = bound > start ? bound : start;
      }
      s.es = start;
    }
    int projectEnd = 0;
    for (final _Item i in items.values) {
      projectEnd = i.ef > projectEnd ? i.ef : projectEnd;
    }

    // Backward pass: late finish and start.
    for (final String id in order.reversed) {
      final _Item p = items[id]!;
      int lateFinish = projectEnd;
      for (final TaskDependency d in outgoing[id] ?? const <TaskDependency>[]) {
        final _Item s = items[d.successorNodeId]!;
        final int ls = s.lf - s.duration;
        final int bound = switch (d.dependencyType) {
          DependencyType.fs => ls - d.lagDays,
          DependencyType.ss => ls - d.lagDays + p.duration,
          DependencyType.ff => s.lf - d.lagDays,
          DependencyType.sf => s.lf - d.lagDays + p.duration,
        };
        lateFinish = bound < lateFinish ? bound : lateFinish;
      }
      p.lf = lateFinish;
      p.ls = lateFinish - p.duration;
    }

    final Map<String, CpmNode> result = <String, CpmNode>{};
    final List<_Item> critical = <_Item>[];
    for (final _Item i in items.values) {
      final int total = i.ls - i.es;
      int free = projectEnd - i.ef;
      for (final TaskDependency d
          in outgoing[i.node.id] ?? const <TaskDependency>[]) {
        final _Item s = items[d.successorNodeId]!;
        final int slack = switch (d.dependencyType) {
          DependencyType.fs => s.es - (i.ef + d.lagDays),
          DependencyType.ss => s.es - (i.es + d.lagDays),
          DependencyType.ff => s.ef - (i.ef + d.lagDays),
          DependencyType.sf => s.ef - (i.es + d.lagDays),
        };
        free = slack < free ? slack : free;
      }
      final bool isCritical = total <= 0;
      if (isCritical) {
        critical.add(i);
      }
      result[i.node.id] = CpmNode(
        earlyStart: _at(origin, i.es),
        earlyFinish: _at(origin, i.duration == 0 ? i.ef : i.ef - 1),
        lateStart: _at(origin, i.ls),
        lateFinish: _at(origin, i.duration == 0 ? i.lf : i.lf - 1),
        totalFloatDays: total < 0 ? 0 : total,
        freeFloatDays: free < 0 ? 0 : free,
        isCritical: isCritical,
      );
    }
    critical.sort((_Item a, _Item b) {
      final int byStart = a.es.compareTo(b.es);
      return byStart != 0
          ? byStart
          : compareWbsCodes(a.node.wbsCode, b.node.wbsCode);
    });
    return CpmResult(
      nodes: result,
      criticalPath: <String>[for (final _Item i in critical) i.node.id],
      projectFinish: _at(origin, projectEnd > 0 ? projectEnd - 1 : 0),
    );
  }

  /// Copies the computed dates, floats and critical flag onto the nodes of [result].
  static List<WbsNode> apply(List<WbsNode> nodes, CpmResult result) =>
      <WbsNode>[
        for (final WbsNode node in nodes)
          if (result.nodes[node.id] case final CpmNode cpm)
            node.copyWith(
              earlyStart: () => cpm.earlyStart,
              earlyFinish: () => cpm.earlyFinish,
              lateStart: () => cpm.lateStart,
              lateFinish: () => cpm.lateFinish,
              totalFloatDays: () => cpm.totalFloatDays,
              freeFloatDays: () => cpm.freeFloatDays,
              isCritical: cpm.isCritical,
            )
          else
            node,
      ];

  /// Kahn's algorithm; null when the links contain a loop.
  static List<String>? _topologicalOrder(
    Iterable<String> ids,
    List<TaskDependency> links,
  ) {
    final Map<String, int> inDegree = <String, int>{
      for (final String id in ids) id: 0,
    };
    final Map<String, List<String>> next = <String, List<String>>{};
    for (final TaskDependency d in links) {
      inDegree[d.successorNodeId] = (inDegree[d.successorNodeId] ?? 0) + 1;
      next
          .putIfAbsent(d.predecessorNodeId, () => <String>[])
          .add(d.successorNodeId);
    }
    final List<String> ready = <String>[
      for (final MapEntry<String, int> e in inDegree.entries)
        if (e.value == 0) e.key,
    ];
    final List<String> order = <String>[];
    while (ready.isNotEmpty) {
      final String id = ready.removeLast();
      order.add(id);
      for (final String successor in next[id] ?? const <String>[]) {
        final int left = (inDegree[successor] ?? 1) - 1;
        inDegree[successor] = left;
        if (left == 0) {
          ready.add(successor);
        }
      }
    }
    return order.length == inDegree.length ? order : null;
  }
}
