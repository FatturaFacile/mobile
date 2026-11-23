import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../design/ff_tokens.dart';
import '../domain/project_plan.dart';
import '../domain/project_portfolio_models.dart';
import '../domain/wbs_tree.dart';
import '../l10n/project_portfolio_strings.dart';
import 'portfolio_ui.dart';
import 'project_portfolio_controller.dart';
import 'project_portfolio_labels.dart';
import 'wbs_forms.dart';

IconData nodeIcon(WbsNodeType type) => switch (type) {
  WbsNodeType.phase => Icons.folder_outlined,
  WbsNodeType.deliverable => Icons.inventory_2_outlined,
  WbsNodeType.workPackage => Icons.task_alt_outlined,
  WbsNodeType.milestone => Icons.flag_outlined,
};

/// The outline: phases, deliverables, work packages and milestones with their rolled-up progress. Tap a row for
/// its detail, dates, float and links.
class WbsTab extends ConsumerStatefulWidget {
  const WbsTab({required this.plan, super.key});

  final ProjectPlan plan;

  @override
  ConsumerState<WbsTab> createState() => _WbsTabState();
}

class _WbsTabState extends ConsumerState<WbsTab> {
  final Set<String> _collapsed = <String>{};

  Future<void> _add(ProjectPortfolioStrings s, {String? parentId}) async {
    final NodeFormResult? form = await showNodeForm(context);
    if (form == null || !mounted) {
      return;
    }
    await guarded(
      context,
      s,
      () => ref
          .read(portfolioActionsProvider)
          .createNode(
            projectId: widget.plan.project.id,
            title: form.title,
            parentNodeId: parentId,
            nodeType: form.nodeType,
            plannedHours: form.plannedHours,
            plannedCost: form.plannedCost,
            plannedRevenue: form.plannedRevenue,
            startDate: form.startDate,
            endDate: form.endDate,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ProjectPortfolioStrings s = ProjectPortfolioStrings.of(context);
    final List<WbsRow> rows = widget.plan.tree.flatten(collapsed: _collapsed);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => _add(s),
        icon: const Icon(Icons.add),
        label: Text(s.t(PP.addNode)),
      ),
      body: rows.isEmpty
          ? Center(child: Text(s.t(PP.noNodes)))
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 96),
              itemCount: rows.length,
              itemBuilder: (BuildContext context, int index) {
                final WbsRow row = rows[index];
                return _NodeRow(
                  row: row,
                  plan: widget.plan,
                  collapsed: _collapsed.contains(row.node.id),
                  onToggle: () => setState(() {
                    if (!_collapsed.remove(row.node.id)) {
                      _collapsed.add(row.node.id);
                    }
                  }),
                  onOpen: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (BuildContext _) => NodeDetailSheet(
                      projectId: widget.plan.project.id,
                      nodeId: row.node.id,
                      onAddChild: () => _add(s, parentId: row.node.id),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _NodeRow extends StatelessWidget {
  const _NodeRow({
    required this.row,
    required this.plan,
    required this.collapsed,
    required this.onToggle,
    required this.onOpen,
  });

  final WbsRow row;
  final ProjectPlan plan;
  final bool collapsed;
  final VoidCallback onToggle;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final ProjectPortfolioStrings s = ProjectPortfolioStrings.of(context);
    final WbsNode n = row.node;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onOpen,
      child: Padding(
        padding: EdgeInsets.only(
          left: FfSpace.space2 + row.depth * FfSpace.space5,
          right: FfSpace.space3,
          top: FfSpace.space1,
          bottom: FfSpace.space1,
        ),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 32,
              child: row.hasChildren
                  ? IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        collapsed ? Icons.chevron_right : Icons.expand_more,
                      ),
                      onPressed: onToggle,
                    )
                  : null,
            ),
            Icon(nodeIcon(n.nodeType), size: 20),
            const SizedBox(width: FfSpace.space2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '${n.wbsCode}  ${n.title}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    n.isMilestone
                        ? formatDate(context, n.startDate)
                        : '${formatDate(context, n.startDate)} → '
                              '${formatDate(context, n.endDate)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (n.isCritical)
              Padding(
                padding: const EdgeInsets.only(right: FfSpace.space2),
                child: Icon(
                  Icons.priority_high,
                  size: 18,
                  color: scheme.error,
                  semanticLabel: s.t(PP.critical),
                ),
              ),
            if (plan.unsyncedIds.contains(n.id))
              const Padding(
                padding: EdgeInsets.only(right: FfSpace.space2),
                child: Icon(Icons.cloud_upload_outlined, size: 16),
              ),
            Text(formatPercent(n.percentComplete)),
          ],
        ),
      ),
    );
  }
}

/// Detail of one node: figures, schedule, links, and the actions on it.
class NodeDetailSheet extends ConsumerWidget {
  const NodeDetailSheet({
    required this.projectId,
    required this.nodeId,
    required this.onAddChild,
    super.key,
  });

  final String projectId;
  final String nodeId;
  final VoidCallback onAddChild;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ProjectPortfolioStrings s = ProjectPortfolioStrings.of(context);
    final ProjectPlan? plan = ref.watch(projectPlanProvider(projectId)).value;
    final WbsNode? n = plan?.node(nodeId);
    if (plan == null || n == null) {
      return Padding(
        padding: const EdgeInsets.all(FfSpace.space5),
        child: Text(s.t(PP.errNotFound)),
      );
    }
    final PortfolioActions actions = ref.read(portfolioActionsProvider);
    final bool summary = plan.tree.isSummary(n.id);
    final TextTheme text = Theme.of(context).textTheme;
    final List<TaskDependency> links = <TaskDependency>[
      ...plan.predecessorsOf(n.id),
      ...plan.successorsOf(n.id),
    ];
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(FfSpace.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text('${n.wbsCode}  ${n.title}', style: text.titleMedium),
            Text(s.nodeType(n.nodeType), style: text.bodySmall),
            const SizedBox(height: FfSpace.space3),
            Wrap(
              spacing: FfSpace.space5,
              runSpacing: FfSpace.space2,
              children: <Widget>[
                Metric(
                  label: s.t(PP.percentComplete),
                  value: formatPercent(n.percentComplete),
                ),
                if (!n.isMilestone) ...<Widget>[
                  Metric(
                    label: s.t(PP.plannedHours),
                    value: formatQuantity(n.plannedHours),
                  ),
                  Metric(
                    label: s.t(PP.actualHours),
                    value: formatQuantity(n.actualHours),
                  ),
                ],
                Metric(
                  label: s.t(PP.plannedCost),
                  value: formatQuantity(n.plannedCost),
                ),
                Metric(
                  label: s.t(PP.actualCost),
                  value: formatQuantity(n.actualCost),
                ),
                Metric(
                  label: s.t(PP.plannedRevenue),
                  value: formatQuantity(n.plannedRevenue),
                ),
              ],
            ),
            if (n.earlyStart != null) ...<Widget>[
              const Divider(),
              Text(
                '${s.t(PP.earlyDates)}: ${formatDate(context, n.earlyStart)}'
                ' → ${formatDate(context, n.earlyFinish)}',
              ),
              Text(
                '${s.t(PP.lateDates)}: ${formatDate(context, n.lateStart)}'
                ' → ${formatDate(context, n.lateFinish)}',
              ),
              Text(
                '${s.t(PP.totalFloat)}: '
                '${s.f(PP.days, <String, Object>{'count': n.totalFloatDays ?? 0})}'
                '   ${s.t(PP.freeFloat)}: '
                '${s.f(PP.days, <String, Object>{'count': n.freeFloatDays ?? 0})}',
              ),
              if (n.isCritical)
                Chip(
                  label: Text(s.t(PP.critical)),
                  avatar: const Icon(Icons.priority_high, size: 16),
                ),
            ],
            const Divider(),
            Text(s.t(PP.dependencies), style: text.titleSmall),
            if (links.isEmpty) Text(s.t(PP.noDependencies)),
            for (final TaskDependency d in links)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  '${plan.node(d.predecessorNodeId)?.wbsCode ?? '?'} → '
                  '${plan.node(d.successorNodeId)?.wbsCode ?? '?'}  '
                  '${d.dependencyType.wire.toUpperCase()}'
                  '${d.lagDays == 0 ? '' : ' ${d.lagDays > 0 ? '+' : ''}${d.lagDays}d'}',
                ),
                trailing: IconButton(
                  tooltip: s.t(PP.removeDependency),
                  icon: const Icon(Icons.link_off),
                  onPressed: () =>
                      guarded(context, s, () => actions.removeDependency(d.id)),
                ),
              ),
            const SizedBox(height: FfSpace.space3),
            Wrap(
              spacing: FfSpace.space2,
              children: <Widget>[
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(s.t(PP.edit)),
                  onPressed: () async {
                    final NodeFormResult? form = await showNodeForm(
                      context,
                      node: n,
                      isSummary: summary,
                    );
                    if (form == null || !context.mounted) {
                      return;
                    }
                    await guarded(
                      context,
                      s,
                      () => actions.updateNode(
                        n.copyWith(
                          title: form.title,
                          nodeType: form.nodeType,
                          plannedHours: form.plannedHours,
                          actualHours: form.actualHours,
                          plannedCost: form.plannedCost,
                          actualCost: form.actualCost,
                          plannedRevenue: form.plannedRevenue,
                          startDate: () => form.startDate,
                          endDate: () => form.endDate,
                          percentComplete: form.percentComplete,
                        ),
                      ),
                    );
                  },
                ),
                if (!n.isMilestone)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.subdirectory_arrow_right),
                    label: Text(s.t(PP.addChild)),
                    onPressed: () {
                      Navigator.of(context).pop();
                      onAddChild();
                    },
                  ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.link),
                  label: Text(s.t(PP.addDependency)),
                  onPressed: () async {
                    final DependencyFormResult? form = await showDependencyForm(
                      context,
                      plan,
                      fixedNodeId: n.id,
                    );
                    if (form == null || !context.mounted) {
                      return;
                    }
                    await guarded(
                      context,
                      s,
                      () => actions.addDependency(
                        projectId: projectId,
                        predecessorNodeId: form.predecessorNodeId,
                        successorNodeId: form.successorNodeId,
                        type: form.type,
                        lagDays: form.lagDays,
                      ),
                    );
                  },
                ),
                TextButton.icon(
                  icon: const Icon(Icons.delete_outline),
                  label: Text(s.t(PP.delete)),
                  onPressed: () async {
                    final bool confirmed = await _confirmDelete(context, s, n);
                    if (!confirmed || !context.mounted) {
                      return;
                    }
                    final NavigatorState navigator = Navigator.of(context);
                    if (await guarded(
                      context,
                      s,
                      () => actions.deleteNode(n.id),
                    )) {
                      navigator.pop();
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(
    BuildContext context,
    ProjectPortfolioStrings s,
    WbsNode n,
  ) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialog) => AlertDialog(
        title: Text(s.t(PP.deleteNodeTitle)),
        content: Text(
          s.f(PP.deleteNodeMessage, <String, Object>{'title': n.title}),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: Text(s.t(PP.cancel)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialog).pop(true),
            child: Text(s.t(PP.delete)),
          ),
        ],
      ),
    );
    return ok ?? false;
  }
}
