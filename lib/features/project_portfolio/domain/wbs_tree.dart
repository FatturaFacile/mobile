/// Pure helpers over the WBS outline: tree building, bottom-up roll-up, outline codes. No I/O, so they are cheap to
/// run on every change while the device is offline.
library;

import 'project_portfolio_models.dart';

/// Compares dotted codes numerically segment by segment (`1.2` before `1.10`).
int compareWbsCodes(String a, String b) {
  final List<String> left = a.split('.');
  final List<String> right = b.split('.');
  for (int i = 0; i < left.length && i < right.length; i++) {
    final int? x = int.tryParse(left[i]);
    final int? y = int.tryParse(right[i]);
    final int result = (x != null && y != null)
        ? x.compareTo(y)
        : left[i].compareTo(right[i]);
    if (result != 0) {
      return result;
    }
  }
  return left.length.compareTo(right.length);
}

/// A node with its position in the outline.
class WbsRow {
  const WbsRow(this.node, this.depth, this.hasChildren);

  final WbsNode node;
  final int depth;
  final bool hasChildren;
}

/// Parent/child index of the nodes of one project.
class WbsTree {
  WbsTree(Iterable<WbsNode> nodes)
    : _byId = <String, WbsNode>{for (final WbsNode n in nodes) n.id: n},
      _children = <String?, List<WbsNode>>{} {
    for (final WbsNode node in _byId.values) {
      // A node whose parent is unknown (not synced yet) is shown at the root rather than lost.
      final String? parent = _byId.containsKey(node.parentNodeId)
          ? node.parentNodeId
          : null;
      _children.putIfAbsent(parent, () => <WbsNode>[]).add(node);
    }
    for (final List<WbsNode> siblings in _children.values) {
      siblings.sort(_order);
    }
  }

  final Map<String, WbsNode> _byId;
  final Map<String?, List<WbsNode>> _children;

  static int _order(WbsNode a, WbsNode b) {
    final int bySort = a.sortOrder.compareTo(b.sortOrder);
    return bySort != 0 ? bySort : compareWbsCodes(a.wbsCode, b.wbsCode);
  }

  WbsNode? byId(String id) => _byId[id];

  List<WbsNode> get roots => _children[null] ?? const <WbsNode>[];

  List<WbsNode> childrenOf(String id) => _children[id] ?? const <WbsNode>[];

  bool isSummary(String id) => childrenOf(id).isNotEmpty;

  /// Ids of [id] and of every node below it.
  List<String> subtreeIds(String id) {
    final List<String> result = <String>[id];
    for (final WbsNode child in childrenOf(id)) {
      result.addAll(subtreeIds(child.id));
    }
    return result;
  }

  /// The outline in reading order; the children of a node in [collapsed] are left out.
  List<WbsRow> flatten({Set<String> collapsed = const <String>{}}) {
    final List<WbsRow> rows = <WbsRow>[];
    void walk(WbsNode node, int depth) {
      final bool hasChildren = isSummary(node.id);
      rows.add(WbsRow(node, depth, hasChildren));
      if (hasChildren && !collapsed.contains(node.id)) {
        for (final WbsNode child in childrenOf(node.id)) {
          walk(child, depth + 1);
        }
      }
    }

    for (final WbsNode root in roots) {
      walk(root, 0);
    }
    return rows;
  }

  /// The code the next child of [parentId] (the next root when null) gets: the highest sibling segment plus one.
  String nextChildCode(String? parentId) {
    final String prefix = parentId == null
        ? ''
        : '${_byId[parentId]?.wbsCode ?? ''}.';
    int highest = 0;
    for (final WbsNode sibling in childrenOf(parentId ?? '')) {
      highest = _lastSegment(sibling.wbsCode) > highest
          ? _lastSegment(sibling.wbsCode)
          : highest;
    }
    if (parentId == null) {
      for (final WbsNode root in roots) {
        highest = _lastSegment(root.wbsCode) > highest
            ? _lastSegment(root.wbsCode)
            : highest;
      }
    }
    return '$prefix${highest + 1}';
  }

  static int _lastSegment(String code) =>
      int.tryParse(code.split('.').last) ?? 0;

  /// True when [candidateParentId] is [nodeId] or one of its descendants (moving there would create a loop).
  bool isInSubtree(String nodeId, String candidateParentId) =>
      subtreeIds(nodeId).contains(candidateParentId);
}

/// Bottom-up roll-up of the figures of the WBS.
///
/// A summary node (one with children) always shows the sum of its children; progress is weighted by planned hours
/// (a plain average when no child has hours) and the dates span the children. Leaves keep their own values.
abstract final class WbsRollup {
  static List<WbsNode> apply(List<WbsNode> nodes) {
    final WbsTree tree = WbsTree(nodes);
    final Map<String, WbsNode> rolled = <String, WbsNode>{};

    WbsNode visit(WbsNode node) {
      final List<WbsNode> children = tree.childrenOf(node.id);
      if (children.isEmpty) {
        rolled[node.id] = node;
        return node;
      }
      final List<WbsNode> done = children.map(visit).toList();
      final WbsNode result = node.copyWith(
        plannedHours: _sum(done, (WbsNode n) => n.plannedHours),
        actualHours: _sum(done, (WbsNode n) => n.actualHours),
        plannedCost: _sum(done, (WbsNode n) => n.plannedCost),
        actualCost: _sum(done, (WbsNode n) => n.actualCost),
        plannedRevenue: _sum(done, (WbsNode n) => n.plannedRevenue),
        percentComplete: weightedProgress(done),
        startDate: () => _earliest(done.map((WbsNode n) => n.startDate)),
        endDate: () => _latest(done.map((WbsNode n) => n.endDate)),
      );
      rolled[node.id] = result;
      return result;
    }

    for (final WbsNode root in tree.roots) {
      visit(root);
    }
    return <WbsNode>[for (final WbsNode node in nodes) rolled[node.id] ?? node];
  }

  /// Project-level figures from the already rolled-up [nodes]: the sum of the root nodes.
  static Project project(Project project, List<WbsNode> nodes) {
    final List<WbsNode> roots = WbsTree(nodes).roots;
    if (roots.isEmpty) {
      return project;
    }
    return project.copyWith(
      plannedHours: _sum(roots, (WbsNode n) => n.plannedHours),
      actualHours: _sum(roots, (WbsNode n) => n.actualHours),
      plannedCost: _sum(roots, (WbsNode n) => n.plannedCost),
      actualCost: _sum(roots, (WbsNode n) => n.actualCost),
      plannedRevenue: _sum(roots, (WbsNode n) => n.plannedRevenue),
      percentComplete: weightedProgress(roots),
    );
  }

  /// Hours-weighted progress of [nodes], clamped to 0..100.
  static double weightedProgress(List<WbsNode> nodes) {
    if (nodes.isEmpty) {
      return 0;
    }
    final double hours = _sum(nodes, (WbsNode n) => n.plannedHours);
    final double value = hours > 0
        ? _sum(nodes, (WbsNode n) => n.percentComplete * n.plannedHours) / hours
        : _sum(nodes, (WbsNode n) => n.percentComplete) / nodes.length;
    return value.clamp(0, 100).toDouble();
  }

  static double _sum(List<WbsNode> nodes, double Function(WbsNode) pick) {
    double total = 0;
    for (final WbsNode node in nodes) {
      total += pick(node);
    }
    return total;
  }

  static DateTime? _earliest(Iterable<DateTime?> dates) {
    DateTime? best;
    for (final DateTime? date in dates) {
      if (date != null && (best == null || date.isBefore(best))) {
        best = date;
      }
    }
    return best;
  }

  static DateTime? _latest(Iterable<DateTime?> dates) {
    DateTime? best;
    for (final DateTime? date in dates) {
      if (date != null && (best == null || date.isAfter(best))) {
        best = date;
      }
    }
    return best;
  }
}
