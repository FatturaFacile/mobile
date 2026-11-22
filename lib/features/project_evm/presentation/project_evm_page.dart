import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../domain/project_evm_models.dart';
import '../l10n/project_evm_strings.dart';
import 'project_evm_charts.dart';
import 'project_evm_controller.dart';

/// Project profitability and earned value: KPI traffic lights, S-curve, profitability waterfall, WBS cost breakdown and the
/// reconciliation with accounting, readable offline from the last synced snapshot.
class ProjectEvmPage extends ConsumerStatefulWidget {
  const ProjectEvmPage({super.key, this.initialProjectId});

  final String? initialProjectId;

  @override
  ConsumerState<ProjectEvmPage> createState() => _ProjectEvmPageState();
}

class _ProjectEvmPageState extends ConsumerState<ProjectEvmPage> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref
          .read(projectEvmControllerProvider.notifier)
          .open(initialProjectId: widget.initialProjectId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ProjectEvmStrings s = ProjectEvmStrings.of(context);
    final ProjectEvmState state = ref.watch(projectEvmControllerProvider);
    final ProjectEvmController controller = ref.read(
      projectEvmControllerProvider.notifier,
    );
    final ProjectEvmSnapshot? snapshot = state.snapshot;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.t(P.title)),
        bottom: state.syncing
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(minHeight: 2),
              )
            : null,
      ),
      body: RefreshIndicator(
        onRefresh: controller.refresh,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                if (state.offline)
                  _Banner(
                    key: const Key('evm-offline'),
                    text: s.t(P.offlineBanner),
                  )
                else if (state.lastSync == EvmSyncStatus.failed)
                  _Banner(
                    key: const Key('evm-failed'),
                    text: s.t(P.syncFailed),
                  ),
                if (state.projects.isEmpty && !state.loading)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(child: Text(s.t(P.noProjects))),
                  )
                else
                  _ProjectPicker(
                    strings: s,
                    projects: state.projects,
                    selected: state.projectId,
                    onSelected: controller.select,
                  ),
                if (state.loading)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                if (snapshot != null) ..._content(s, snapshot),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _content(ProjectEvmStrings s, ProjectEvmSnapshot snapshot) {
    final EvmFigures? p = snapshot.project;
    final String date =
        snapshot.snapshotDate?.toIso8601String().substring(0, 10) ?? '';
    return <Widget>[
      if (snapshot.snapshotDate != null)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            fillEvm(s.t(P.snapshotOf), <String, Object>{'date': date}),
            key: const Key('evm-snapshot-date'),
          ),
        ),
      if (p == null)
        Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(s.t(P.noSnapshot), key: const Key('evm-empty')),
          ),
        )
      else ...<Widget>[
        _Kpis(strings: s, figures: p, currency: snapshot.currency),
        _Alerts(strings: s, figures: p),
      ],
      if (snapshot.points.isNotEmpty)
        _Section(
          title: s.t(P.scurve),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              EvmScurveChart(
                points: snapshot.points,
                forecast: snapshot.forecast,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                children: <Widget>[
                  for (final (int i, P key) in <P>[
                    P.seriesPv,
                    P.seriesEv,
                    P.seriesAc,
                    P.seriesEac,
                  ].indexed)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(Icons.circle, size: 10, color: evmSeriesColors[i]),
                        const SizedBox(width: 4),
                        Text(s.t(key)),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      if (snapshot.waterfall.isNotEmpty)
        _Section(
          title: s.t(P.waterfall),
          child: _Waterfall(
            strings: s,
            steps: snapshot.waterfall,
            currency: snapshot.currency,
          ),
        ),
      if (snapshot.nodes.isNotEmpty)
        _Section(
          title: s.t(P.wbs),
          child: Column(
            children: <Widget>[
              for (final WbsNode node in snapshot.nodes)
                _WbsTile(strings: s, node: node, currency: snapshot.currency),
            ],
          ),
        ),
      if (snapshot.reconciliation != null)
        _Section(
          title: s.t(P.reconciliation),
          child: _Reconciliation(
            strings: s,
            reconciliation: snapshot.reconciliation!,
            currency: snapshot.currency,
          ),
        ),
    ];
  }
}

String _money(double value, String currency) =>
    '$currency ${value.toStringAsFixed(2)}';

class _Banner extends StatelessWidget {
  const _Banner({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.tertiaryContainer,
    child: Padding(padding: const EdgeInsets.all(12), child: Text(text)),
  );
}

class _ProjectPicker extends StatelessWidget {
  const _ProjectPicker({
    required this.strings,
    required this.projects,
    required this.selected,
    required this.onSelected,
  });

  final ProjectEvmStrings strings;
  final List<EvmProjectRef> projects;
  final String? selected;
  final Future<void> Function(String) onSelected;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    key: const Key('evm-project-picker'),
    isExpanded: true,
    initialValue: projects.any((EvmProjectRef p) => p.id == selected)
        ? selected
        : null,
    decoration: InputDecoration(labelText: strings.t(P.project)),
    items: <DropdownMenuItem<String>>[
      for (final EvmProjectRef project in projects)
        DropdownMenuItem<String>(
          value: project.id,
          child: Text(project.label, overflow: TextOverflow.ellipsis),
        ),
    ],
    onChanged: (String? id) {
      if (id != null) {
        onSelected(id);
      }
    },
  );
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16),
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    ),
  );
}

class _Kpis extends StatelessWidget {
  const _Kpis({
    required this.strings,
    required this.figures,
    required this.currency,
  });

  final ProjectEvmStrings strings;
  final EvmFigures figures;
  final String currency;

  String _lightLabel(EvmLight light) => switch (light) {
    EvmLight.green => strings.t(P.lightGreen),
    EvmLight.amber => strings.t(P.lightAmber),
    EvmLight.red => strings.t(P.lightRed),
  };

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 12,
    runSpacing: 12,
    children: <Widget>[
      _Kpi(label: strings.t(P.kpiBac), value: _money(figures.bac, currency)),
      _Kpi(
        key: const Key('evm-cpi'),
        label: strings.t(P.kpiCpi),
        value: figures.cpi?.toStringAsFixed(2) ?? '-',
        light: figures.cpiLight,
        lightLabel: _lightLabel(figures.cpiLight),
      ),
      _Kpi(
        key: const Key('evm-spi'),
        label: strings.t(P.kpiSpi),
        value: figures.spi?.toStringAsFixed(2) ?? '-',
        light: figures.spiLight,
        lightLabel: _lightLabel(figures.spiLight),
      ),
      _Kpi(
        label: strings.t(P.kpiEac),
        value: _money(figures.eac, currency),
        caption:
            '${strings.t(P.kpiVac)}: ${_money(figures.vac, currency)}'
            '${figures.manualEtc == null ? '' : ' · ${strings.t(P.manualEtc)}'}',
      ),
      _Kpi(
        label: strings.t(P.kpiMargin),
        value: _money(figures.margin, currency),
        caption: figures.marginPercent == null
            ? null
            : '${figures.marginPercent!.toStringAsFixed(2)}%',
      ),
      _Kpi(
        label: strings.t(P.kpiAbsorption),
        value: '${(figures.absorption ?? 0).toStringAsFixed(1)}%',
        progress: ((figures.absorption ?? 0) / 100).clamp(0, 1).toDouble(),
        light: absorptionWarning(figures.absorption) ? EvmLight.amber : null,
      ),
    ],
  );
}

class _Kpi extends StatelessWidget {
  const _Kpi({
    required this.label,
    required this.value,
    super.key,
    this.caption,
    this.light,
    this.lightLabel,
    this.progress,
  });

  final String label;
  final String value;
  final String? caption;
  final EvmLight? light;
  final String? lightLabel;
  final double? progress;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 180,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 4),
            Row(
              children: <Widget>[
                if (light != null && lightLabel != null) ...<Widget>[
                  Icon(Icons.circle, size: 12, color: evmLightColor(light!)),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (lightLabel != null) Text(lightLabel!),
            if (progress != null) ...<Widget>[
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: progress,
                color: light == null ? null : evmLightColor(light!),
              ),
            ],
            if (caption != null)
              Text(caption!, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    ),
  );
}

class _Alerts extends StatelessWidget {
  const _Alerts({required this.strings, required this.figures});

  final ProjectEvmStrings strings;
  final EvmFigures figures;

  @override
  Widget build(BuildContext context) {
    final int count = figures.breaches;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        spacing: 8,
        children: <Widget>[
          if (count == 0)
            Chip(
              key: const Key('evm-alerts-ok'),
              avatar: Icon(
                Icons.check_circle,
                color: evmLightColor(EvmLight.green),
              ),
              label: Text(strings.t(P.alertsOk)),
            )
          else
            Chip(
              key: const Key('evm-alerts'),
              avatar: Icon(Icons.warning, color: evmLightColor(EvmLight.red)),
              label: Text(
                fillEvm(strings.t(P.alertsBreached), <String, Object>{
                  'count': count,
                }),
              ),
            ),
          if (absorptionWarning(figures.absorption))
            Chip(
              key: const Key('evm-absorption-warning'),
              label: Text(strings.t(P.absorptionWarning)),
            ),
        ],
      ),
    );
  }
}

class _Waterfall extends StatelessWidget {
  const _Waterfall({
    required this.strings,
    required this.steps,
    required this.currency,
  });

  final ProjectEvmStrings strings;
  final List<WaterfallStep> steps;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final double top = steps.fold<double>(
      1,
      (double a, WaterfallStep s) => s.amount.abs() > a ? s.amount.abs() : a,
    );
    return Column(
      children: <Widget>[
        for (final WaterfallStep step in steps)
          Padding(
            key: Key('evm-step-${step.key}'),
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Flexible(child: Text(strings.source(step.key))),
                    Text(_money(step.amount, currency)),
                  ],
                ),
                LinearProgressIndicator(
                  value: (step.amount.abs() / top).clamp(0, 1).toDouble(),
                  color: step.isTotal
                      ? evmSeriesColors[0]
                      : evmLightColor(EvmLight.red),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _WbsTile extends StatelessWidget {
  const _WbsTile({
    required this.strings,
    required this.node,
    required this.currency,
  });

  final ProjectEvmStrings strings;
  final WbsNode node;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final EvmFigures? f = node.figures;
    final Widget title = Text(
      '${node.code} ${node.title}',
      overflow: TextOverflow.ellipsis,
    );
    final Widget? subtitle = f == null
        ? null
        : Text(
            '${strings.t(P.kpiCpi)} ${f.cpi?.toStringAsFixed(2) ?? '-'} · '
            '${strings.t(P.kpiSpi)} ${f.spi?.toStringAsFixed(2) ?? '-'} · '
            '${strings.t(P.kpiEac)} ${_money(f.eac, currency)} · '
            '${strings.t(P.etc)} ${_money(f.etc, currency)}',
          );
    final Widget? leading = f == null
        ? null
        : Icon(
            Icons.circle,
            size: 12,
            color: evmLightColor(
              f.cpiLight == EvmLight.red || f.spiLight == EvmLight.red
                  ? EvmLight.red
                  : (f.cpiLight == EvmLight.amber ||
                            f.spiLight == EvmLight.amber
                        ? EvmLight.amber
                        : EvmLight.green),
            ),
          );
    if (node.children.isEmpty) {
      return ListTile(
        key: Key('evm-wbs-${node.code}'),
        dense: true,
        leading: leading,
        title: title,
        subtitle: subtitle,
        trailing: f == null ? null : Text(_money(f.actual, currency)),
      );
    }
    return ExpansionTile(
      key: Key('evm-wbs-${node.code}'),
      leading: leading,
      title: title,
      subtitle: subtitle,
      childrenPadding: const EdgeInsets.only(left: 16),
      children: <Widget>[
        for (final WbsNode child in node.children)
          _WbsTile(strings: strings, node: child, currency: currency),
      ],
    );
  }
}

class _Reconciliation extends StatelessWidget {
  const _Reconciliation({
    required this.strings,
    required this.reconciliation,
    required this.currency,
  });

  final ProjectEvmStrings strings;
  final EvmReconciliation reconciliation;
  final String currency;

  @override
  Widget build(BuildContext context) {
    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Flexible(child: Text(label)),
          Text(value),
        ],
      ),
    );
    return Column(
      children: <Widget>[
        row(strings.t(P.standard), reconciliation.standard ?? '-'),
        row(
          strings.t(P.managerialCost),
          _money(reconciliation.managerialCost, currency),
        ),
        row(
          strings.t(P.statutoryCost),
          _money(reconciliation.statutoryCost, currency),
        ),
        if (reconciliation.difference != null)
          row(
            strings.t(P.difference),
            _money(reconciliation.difference!, currency),
          ),
        row(strings.t(P.overhead), _money(reconciliation.overhead, currency)),
        const SizedBox(height: 8),
        if (!reconciliation.hasValuation)
          Text(strings.t(P.noValuation), key: const Key('evm-no-valuation'))
        else
          Chip(
            key: const Key('evm-reconciled'),
            label: Text(
              strings.t(
                reconciliation.reconciled ? P.reconciled : P.toReconcile,
              ),
            ),
          ),
      ],
    );
  }
}
