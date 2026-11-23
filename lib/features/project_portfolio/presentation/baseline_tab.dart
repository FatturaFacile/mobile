import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../design/ff_tokens.dart';
import '../domain/baseline_variance.dart';
import '../domain/project_plan.dart';
import '../domain/project_portfolio_models.dart';
import '../l10n/project_portfolio_strings.dart';
import 'portfolio_ui.dart';
import 'project_portfolio_controller.dart';
import 'project_portfolio_labels.dart';
import 'wbs_forms.dart';

/// Baselines of the project and the drift of the current plan from the chosen one.
class BaselineTab extends ConsumerStatefulWidget {
  const BaselineTab({required this.plan, super.key});

  final ProjectPlan plan;

  @override
  ConsumerState<BaselineTab> createState() => _BaselineTabState();
}

class _BaselineTabState extends ConsumerState<BaselineTab> {
  String? _selectedId;

  ProjectBaseline? get _selected {
    for (final ProjectBaseline b in widget.plan.baselines) {
      if (b.id == _selectedId) {
        return b;
      }
    }
    return widget.plan.baselines.isEmpty ? null : widget.plan.baselines.first;
  }

  Future<void> _capture(ProjectPortfolioStrings s) async {
    final String? name = await showNameDialog(
      context,
      title: s.t(PP.captureBaseline),
      label: s.t(PP.baselineName),
    );
    if (name == null || !mounted) {
      return;
    }
    await guarded(
      context,
      s,
      () => ref
          .read(portfolioActionsProvider)
          .captureBaseline(projectId: widget.plan.project.id, name: name),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ProjectPortfolioStrings s = ProjectPortfolioStrings.of(context);
    final ProjectBaseline? selected = _selected;
    final List<NodeVariance> drift = selected == null
        ? const <NodeVariance>[]
        : <NodeVariance>[
            for (final NodeVariance v in BaselineVariance.compare(
              selected,
              widget.plan.nodes,
            ))
              if (v.hasDrift) v,
          ];
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => _capture(s),
        icon: const Icon(Icons.bookmark_add_outlined),
        label: Text(s.t(PP.captureBaseline)),
      ),
      body: selected == null
          ? Center(child: Text(s.t(PP.noBaselines)))
          : ListView(
              padding: const EdgeInsets.only(bottom: 96),
              children: <Widget>[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(FfSpace.space3),
                  child: Row(
                    children: <Widget>[
                      for (final ProjectBaseline b in widget.plan.baselines)
                        Padding(
                          padding: const EdgeInsets.only(right: FfSpace.space2),
                          child: ChoiceChip(
                            label: Text('#${b.baselineNumber} ${b.name}'),
                            selected: b.id == selected.id,
                            onSelected: (bool _) =>
                                setState(() => _selectedId = b.id),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: FfSpace.space3,
                  ),
                  child: Text(
                    '${s.t(PP.variance)} · '
                    '${MaterialLocalizations.of(context).formatShortDate(selected.capturedAt.toLocal())}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                if (drift.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(FfSpace.space4),
                    child: Text(s.t(PP.onPlan)),
                  ),
                for (final NodeVariance v in drift)
                  _VarianceTile(variance: v, strings: s),
              ],
            ),
    );
  }
}

class _VarianceTile extends StatelessWidget {
  const _VarianceTile({required this.variance, required this.strings});

  final NodeVariance variance;
  final ProjectPortfolioStrings strings;

  @override
  Widget build(BuildContext context) {
    final NodeVariance v = variance;
    final List<String> lines = <String>[
      if (v.addedSinceBaseline) strings.t(PP.addedSinceBaseline),
      if (v.removedSinceBaseline) strings.t(PP.removedSinceBaseline),
      if ((v.startSlipDays ?? 0) != 0)
        '${strings.t(PP.startDate)}: ${strings.slip(v.startSlipDays)}',
      if ((v.finishSlipDays ?? 0) != 0)
        '${strings.t(PP.endDate)}: ${strings.slip(v.finishSlipDays)}',
      if (v.hoursDelta != 0)
        '${strings.t(PP.hoursDelta)}: ${_signed(v.hoursDelta)}',
      if (v.costDelta != 0)
        '${strings.t(PP.costDelta)}: ${_signed(v.costDelta)}',
    ];
    return ListTile(
      title: Text('${v.wbsCode}  ${v.title}'),
      subtitle: Text(lines.join('\n')),
      isThreeLine: lines.length > 1,
    );
  }

  static String _signed(double value) =>
      '${value > 0 ? '+' : ''}${formatQuantity(value)}';
}
