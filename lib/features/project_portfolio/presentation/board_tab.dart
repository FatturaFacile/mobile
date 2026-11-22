import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../design/ff_tokens.dart';
import '../domain/project_plan.dart';
import '../domain/project_portfolio_models.dart';
import '../l10n/project_portfolio_strings.dart';
import 'portfolio_ui.dart';
import 'project_portfolio_controller.dart';
import 'project_portfolio_labels.dart';
import 'wbs_tab.dart';

/// Kanban view of the work packages and milestones: the column follows the progress (0% to do, 1-99% in
/// progress, 100% done), and moving a card sets it. Summary nodes are not cards, their progress is the roll-up.
class BoardTab extends ConsumerWidget {
  const BoardTab({required this.plan, super.key});

  final ProjectPlan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ProjectPortfolioStrings s = ProjectPortfolioStrings.of(context);
    final List<WbsNode> cards = <WbsNode>[
      for (final WbsNode n in plan.nodes)
        if (!plan.tree.isSummary(n.id)) n,
    ];
    if (cards.isEmpty) {
      return Center(child: Text(s.t(PP.noNodes)));
    }
    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(FfSpace.space3),
      children: <Widget>[
        for (final WbsProgressState state in WbsProgressState.values)
          _Column(
            state: state,
            title: s.progressState(state),
            cards: <WbsNode>[
              for (final WbsNode n in cards)
                if (n.progressState == state) n,
            ],
            plan: plan,
          ),
      ],
    );
  }
}

class _Column extends StatelessWidget {
  const _Column({
    required this.state,
    required this.title,
    required this.cards,
    required this.plan,
  });

  final WbsProgressState state;
  final String title;
  final List<WbsNode> cards;
  final ProjectPlan plan;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Padding(
        padding: const EdgeInsets.only(right: FfSpace.space3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '$title (${cards.length})',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: FfSpace.space2),
            Expanded(
              child: ListView(
                children: <Widget>[
                  for (final WbsNode n in cards)
                    _Card(node: n, state: state, plan: plan),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Card extends ConsumerWidget {
  const _Card({required this.node, required this.state, required this.plan});

  final WbsNode node;
  final WbsProgressState state;
  final ProjectPlan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ProjectPortfolioStrings s = ProjectPortfolioStrings.of(context);
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(FfSpace.space2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(nodeIcon(node.nodeType), size: 16),
                const SizedBox(width: FfSpace.space1),
                Expanded(
                  child: Text(
                    '${node.wbsCode}  ${node.title}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (node.isCritical)
                  Icon(
                    Icons.priority_high,
                    size: 16,
                    color: scheme.error,
                    semanticLabel: s.t(PP.critical),
                  ),
                PopupMenuButton<WbsProgressState>(
                  tooltip: s.t(PP.moveTo),
                  icon: const Icon(Icons.more_vert, size: 18),
                  onSelected: (WbsProgressState target) => guarded(
                    context,
                    s,
                    () => ref
                        .read(portfolioActionsProvider)
                        .moveNode(node, target),
                  ),
                  itemBuilder: (BuildContext _) =>
                      <PopupMenuEntry<WbsProgressState>>[
                        for (final WbsProgressState target
                            in WbsProgressState.values)
                          if (target != state)
                            PopupMenuItem<WbsProgressState>(
                              value: target,
                              child: Text(
                                '${s.t(PP.moveTo)} ${s.progressState(target)}',
                              ),
                            ),
                      ],
                ),
              ],
            ),
            Text(
              node.isMilestone
                  ? formatDate(context, node.startDate)
                  : '${formatDate(context, node.startDate)} → '
                        '${formatDate(context, node.endDate)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: FfSpace.space1),
            LinearProgressIndicator(
              value: (node.percentComplete / 100).clamp(0, 1).toDouble(),
              minHeight: 4,
            ),
          ],
        ),
      ),
    );
  }
}
