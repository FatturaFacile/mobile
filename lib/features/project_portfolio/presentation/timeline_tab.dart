import 'package:material_ui/material_ui.dart';

import '../../../design/ff_tokens.dart';
import '../domain/project_plan.dart';
import '../domain/project_portfolio_models.dart';
import '../domain/wbs_tree.dart';
import '../l10n/project_portfolio_strings.dart';
import 'project_portfolio_labels.dart';

const double _dayWidth = 10;
const double _rowHeight = 36;

/// Gantt-style overview: one bar per node on a shared day axis, the progress as a darker fill, milestones as
/// diamonds, critical nodes in the error color, plus the critical path as a list on top.
class TimelineTab extends StatelessWidget {
  const TimelineTab({required this.plan, super.key});

  final ProjectPlan plan;

  @override
  Widget build(BuildContext context) {
    final ProjectPortfolioStrings s = ProjectPortfolioStrings.of(context);
    final List<WbsRow> rows = plan.tree.flatten();
    final List<WbsRow> dated = <WbsRow>[
      for (final WbsRow r in rows)
        if (r.node.startDate != null) r,
    ];
    if (dated.isEmpty) {
      return Center(child: Text(s.t(PP.noNodes)));
    }
    DateTime origin = dated.first.node.startDate!;
    DateTime last = origin;
    for (final WbsRow r in dated) {
      final DateTime start = r.node.startDate!;
      final DateTime end = r.node.endDate ?? start;
      origin = start.isBefore(origin) ? start : origin;
      last = end.isAfter(last) ? end : last;
    }
    final int totalDays = last.difference(origin).inDays + 2;
    final double width = totalDays * _dayWidth;
    final DateTime today = DateTime.now();
    final int todayIndex = DateTime.utc(
      today.year,
      today.month,
      today.day,
    ).difference(origin).inDays;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: FfSpace.space3,
            vertical: FfSpace.space2,
          ),
          child: _CriticalPath(plan: plan, strings: s),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: width + FfSpace.space4,
                child: Stack(
                  children: <Widget>[
                    if (todayIndex >= 0 && todayIndex < totalDays)
                      Positioned(
                        left: todayIndex * _dayWidth,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 1,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    Column(
                      children: <Widget>[
                        for (final WbsRow r in rows)
                          _BarRow(row: r, origin: origin),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CriticalPath extends StatelessWidget {
  const _CriticalPath({required this.plan, required this.strings});

  final ProjectPlan plan;
  final ProjectPortfolioStrings strings;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    if (plan.cpm.hasCycle) {
      return Text(
        strings.t(PP.cycleDetected),
        style: text.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.error,
        ),
      );
    }
    final List<WbsNode> critical = plan.criticalNodes;
    if (critical.isEmpty) {
      return Text(strings.t(PP.noCriticalPath), style: text.bodySmall);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(strings.t(PP.criticalPath), style: text.titleSmall),
        Wrap(
          spacing: FfSpace.space1,
          children: <Widget>[
            for (final WbsNode n in critical)
              Chip(
                visualDensity: VisualDensity.compact,
                label: Text(n.wbsCode),
              ),
          ],
        ),
      ],
    );
  }
}

class _BarRow extends StatelessWidget {
  const _BarRow({required this.row, required this.origin});

  final WbsRow row;
  final DateTime origin;

  @override
  Widget build(BuildContext context) {
    final WbsNode n = row.node;
    final DateTime? start = n.startDate;
    if (start == null) {
      return const SizedBox(height: _rowHeight);
    }
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final double left = start.difference(origin).inDays * _dayWidth;
    final Color base = n.isCritical ? scheme.error : scheme.primary;
    final String label = '${n.wbsCode}  ${n.title}';
    if (n.isMilestone) {
      return SizedBox(
        height: _rowHeight,
        child: Stack(
          children: <Widget>[
            Positioned(
              left: left - 8,
              top: 8,
              child: Row(
                children: <Widget>[
                  Icon(Icons.diamond, size: 18, color: base),
                  const SizedBox(width: FfSpace.space1),
                  Text(label, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      );
    }
    final DateTime end = n.endDate ?? start;
    final double barWidth = (end.difference(start).inDays + 1) * _dayWidth;
    return SizedBox(
      height: _rowHeight,
      child: Stack(
        children: <Widget>[
          Positioned(
            left: left,
            top: 6,
            width: barWidth,
            height: 14,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(FfRadius.sm),
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  ColoredBox(color: base.withValues(alpha: 0.3)),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (n.percentComplete / 100)
                        .clamp(0, 1)
                        .toDouble(),
                    child: ColoredBox(color: base),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: left,
            top: 20,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ],
      ),
    );
  }
}
