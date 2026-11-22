import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../design/ff_tokens.dart';
import '../domain/project_plan.dart';
import '../domain/project_portfolio_models.dart';
import '../l10n/project_portfolio_strings.dart';
import 'baseline_tab.dart';
import 'board_tab.dart';
import 'portfolio_ui.dart';
import 'project_portfolio_controller.dart';
import 'project_portfolio_labels.dart';
import 'timeline_tab.dart';
import 'wbs_forms.dart';
import 'wbs_tab.dart';

/// One project: rolled-up figures, CUP/CIG, and four views of the same offline plan (outline, board, timeline,
/// baseline). Every view reads the same [ProjectPlan] stream, so an edit in one shows in all of them at once.
class ProjectDetailPage extends ConsumerWidget {
  const ProjectDetailPage({required this.projectId, super.key});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ProjectPortfolioStrings s = ProjectPortfolioStrings.of(context);
    final AsyncValue<ProjectPlan?> plan = ref.watch(
      projectPlanProvider(projectId),
    );
    final ProjectPlan? value = plan.value;
    if (value == null) {
      return Scaffold(
        appBar: AppBar(title: Text(s.t(PP.title))),
        body: Center(
          child: plan.isLoading
              ? const CircularProgressIndicator()
              : Text(s.t(PP.errNotFound)),
        ),
      );
    }
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(value.project.projectCode),
          bottom: TabBar(
            tabs: <Widget>[
              Tab(text: s.t(PP.tabWbs)),
              Tab(text: s.t(PP.tabBoard)),
              Tab(text: s.t(PP.tabTimeline)),
              Tab(text: s.t(PP.tabBaseline)),
            ],
          ),
        ),
        body: Column(
          children: <Widget>[
            _Summary(plan: value),
            Expanded(
              child: TabBarView(
                children: <Widget>[
                  WbsTab(plan: value),
                  BoardTab(plan: value),
                  TimelineTab(plan: value),
                  BaselineTab(plan: value),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Summary extends ConsumerWidget {
  const _Summary({required this.plan});

  final ProjectPlan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ProjectPortfolioStrings s = ProjectPortfolioStrings.of(context);
    final Project p = plan.project;
    final TextTheme text = Theme.of(context).textTheme;
    final int pending = plan.unsyncedIds.length;
    return Card(
      margin: const EdgeInsets.all(FfSpace.space3),
      child: Padding(
        padding: const EdgeInsets.all(FfSpace.space3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(child: Text(p.name, style: text.titleMedium)),
                PopupMenuButton<ProjectStatus>(
                  tooltip: s.t(PP.status),
                  initialValue: p.status,
                  onSelected: (ProjectStatus next) => guarded(
                    context,
                    s,
                    () => ref
                        .read(portfolioActionsProvider)
                        .updateProject(p.copyWith(status: next)),
                  ),
                  itemBuilder: (BuildContext _) =>
                      <PopupMenuEntry<ProjectStatus>>[
                        for (final ProjectStatus st in ProjectStatus.values)
                          PopupMenuItem<ProjectStatus>(
                            value: st,
                            child: Text(s.status(st)),
                          ),
                      ],
                  child: Chip(label: Text(s.status(p.status))),
                ),
              ],
            ),
            const SizedBox(height: FfSpace.space2),
            LinearProgressIndicator(
              value: (p.percentComplete / 100).clamp(0, 1).toDouble(),
              minHeight: 6,
            ),
            const SizedBox(height: FfSpace.space2),
            Wrap(
              spacing: FfSpace.space5,
              runSpacing: FfSpace.space2,
              children: <Widget>[
                Metric(
                  label: s.t(PP.percentComplete),
                  value: formatPercent(p.percentComplete),
                ),
                Metric(
                  label: s.t(PP.plannedHours),
                  value: formatQuantity(p.plannedHours),
                ),
                Metric(
                  label: s.t(PP.actualHours),
                  value: formatQuantity(p.actualHours),
                ),
                Metric(
                  label: s.t(PP.plannedCost),
                  value: formatQuantity(p.plannedCost),
                ),
                Metric(
                  label: s.t(PP.actualCost),
                  value: formatQuantity(p.actualCost),
                ),
                Metric(
                  label: s.t(PP.plannedRevenue),
                  value: formatQuantity(p.plannedRevenue),
                ),
                Metric(
                  label: s.t(PP.projectEnd),
                  value: formatDate(context, p.targetEndDate),
                ),
                if (plan.cpm.projectFinish != null)
                  Metric(
                    label: s.t(PP.projectFinish),
                    value: formatDate(context, plan.cpm.projectFinish),
                  ),
              ],
            ),
            const SizedBox(height: FfSpace.space2),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    '${s.t(PP.cupCode)}: ${p.cupCode ?? '—'}   '
                    '${s.t(PP.cigCode)}: ${p.cigCode ?? '—'}',
                    style: text.bodySmall,
                  ),
                ),
                IconButton(
                  tooltip: s.t(PP.publicFunding),
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () async {
                    final CodesFormResult? codes = await showCodesDialog(
                      context,
                      cup: p.cupCode,
                      cig: p.cigCode,
                    );
                    if (codes == null || !context.mounted) {
                      return;
                    }
                    await guarded(
                      context,
                      s,
                      () => ref
                          .read(portfolioActionsProvider)
                          .updateProject(
                            p.copyWith(
                              cupCode: () => codes.cup,
                              cigCode: () => codes.cig,
                            ),
                          ),
                    );
                  },
                ),
              ],
            ),
            if (pending > 0)
              Text(
                s.f(PP.pendingChanges, <String, Object>{'count': pending}),
                style: text.labelSmall,
              ),
          ],
        ),
      ),
    );
  }
}
