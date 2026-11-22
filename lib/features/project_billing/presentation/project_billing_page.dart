import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../project_evm/domain/project_evm_models.dart';
import '../domain/project_billing_models.dart';
import '../l10n/project_billing_strings.dart';
import 'project_billing_controller.dart';

/// Project billing: the billing position, the SAL certificates, the prepaid retainer burn-down, the guarantee retention and
/// a calculator of the next SAL, readable offline from the last synced snapshot.
class ProjectBillingPage extends ConsumerStatefulWidget {
  const ProjectBillingPage({super.key, this.initialProjectId});

  final String? initialProjectId;

  @override
  ConsumerState<ProjectBillingPage> createState() => _ProjectBillingPageState();
}

class _ProjectBillingPageState extends ConsumerState<ProjectBillingPage> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref
          .read(projectBillingControllerProvider.notifier)
          .open(initialProjectId: widget.initialProjectId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ProjectBillingStrings s = ProjectBillingStrings.of(context);
    final ProjectBillingState state = ref.watch(
      projectBillingControllerProvider,
    );
    final ProjectBillingController controller = ref.read(
      projectBillingControllerProvider.notifier,
    );
    final ProjectBillingSnapshot? snapshot = state.snapshot;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.t(PB.title)),
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
                    key: const Key('billing-offline'),
                    text: s.t(PB.offlineBanner),
                  )
                else if (state.lastSync == BillingSyncStatus.failed)
                  _Banner(
                    key: const Key('billing-failed'),
                    text: s.t(PB.syncFailed),
                  ),
                if (state.projects.isEmpty && !state.loading)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(child: Text(s.t(PB.noProjects))),
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
                if (snapshot != null)
                  ..._content(s, state, snapshot, controller)
                else if (!state.loading && state.projectId != null)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        s.t(PB.noData),
                        key: const Key('billing-empty'),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _content(
    ProjectBillingStrings s,
    ProjectBillingState state,
    ProjectBillingSnapshot snapshot,
    ProjectBillingController controller,
  ) {
    final BillingSummary sum = snapshot.summary;
    final String currency = snapshot.contract?.currency ?? sum.currency;
    final WipFigure? wip = sum.latestWip;
    return <Widget>[
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          fillBilling(s.t(PB.syncedAt), <String, Object>{
            'date': snapshot.syncedAt.toIso8601String().substring(0, 10),
          }),
          key: const Key('billing-synced'),
        ),
      ),
      _Section(
        title: s.t(PB.summary),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            _Kpi(
              label: s.t(PB.sumContract),
              value: _money(sum.contractValue, currency),
            ),
            _Kpi(
              label: s.t(PB.sumBilled),
              value: _money(sum.billedToDate, currency),
              caption:
                  '${s.t(PB.sumDrafts)}: ${_money(sum.draftBilling, currency)}',
            ),
            _Kpi(
              key: const Key('billing-unbilled'),
              label: s.t(PB.sumUnbilledTm),
              value: _money(sum.unbilledTimeAndMaterials, currency),
              caption: fillBilling(s.t(PB.sumMilestones), <String, Object>{
                'count': sum.unbilledMilestones,
              }),
            ),
            _Kpi(
              label: s.t(PB.sumOpenSal),
              value: _money(sum.openSalAmount, currency),
              caption: '${sum.openSalCount}',
            ),
            _Kpi(
              key: const Key('billing-retention'),
              label: s.t(PB.sumRetention),
              value: _money(sum.retentionHeld ?? 0, currency),
            ),
            if (wip != null)
              _Kpi(
                key: const Key('billing-wip'),
                label: s.t(PB.sumWip),
                value: _money(wip.difference, currency),
                caption: switch (wip.nature) {
                  WipNature.contractAsset => s.t(PB.wipAsset),
                  WipNature.contractLiability => s.t(PB.wipLiability),
                  WipNature.balanced => s.t(PB.wipBalanced),
                },
              ),
          ],
        ),
      ),
      if (snapshot.contract?.billsProgress ?? false)
        _Section(
          title: s.t(PB.calcTitle),
          child: _Calculator(
            strings: s,
            progress: state.progress,
            preview: state.preview,
            currency: currency,
            onChanged: controller.setProgress,
          ),
        ),
      _Section(
        title: s.t(PB.salTitle),
        child: snapshot.certificates.isEmpty
            ? Text(s.t(PB.salNone), key: const Key('billing-sal-empty'))
            : Column(
                children: <Widget>[
                  for (final SalCertificate sal in snapshot.certificates)
                    _SalTile(strings: s, sal: sal, currency: currency),
                ],
              ),
      ),
      if (snapshot.retainer != null)
        _Section(
          title: s.t(PB.retainerTitle),
          child: _Retainer(
            strings: s,
            retainer: snapshot.retainer!,
            currency: currency,
          ),
        ),
      if (snapshot.retention != null)
        _Section(
          title: s.t(PB.retentionTitle),
          child: _Retention(
            strings: s,
            retention: snapshot.retention!,
            currency: currency,
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

  final ProjectBillingStrings strings;
  final List<EvmProjectRef> projects;
  final String? selected;
  final Future<void> Function(String) onSelected;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    key: const Key('billing-project-picker'),
    isExpanded: true,
    initialValue: projects.any((EvmProjectRef p) => p.id == selected)
        ? selected
        : null,
    decoration: InputDecoration(labelText: strings.t(PB.project)),
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

class _Kpi extends StatelessWidget {
  const _Kpi({
    required this.label,
    required this.value,
    super.key,
    this.caption,
  });

  final String label;
  final String value;
  final String? caption;

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
            Text(value, style: Theme.of(context).textTheme.titleMedium),
            if (caption != null)
              Text(caption!, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    ),
  );
}

class _Calculator extends StatelessWidget {
  const _Calculator({
    required this.strings,
    required this.progress,
    required this.preview,
    required this.currency,
    required this.onChanged,
  });

  final ProjectBillingStrings strings;
  final double progress;
  final SalPreview? preview;
  final String currency;
  final void Function(double) onChanged;

  @override
  Widget build(BuildContext context) {
    final SalPreview? p = preview;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(strings.t(PB.calcHint)),
        Slider(
          key: const Key('billing-calc-slider'),
          value: progress,
          max: 100,
          divisions: 200,
          label: progress.toStringAsFixed(1),
          onChanged: onChanged,
        ),
        Text(
          fillBilling(strings.t(PB.calcProgress), <String, Object>{
            'percent': progress.toStringAsFixed(1),
          }),
        ),
        const SizedBox(height: 8),
        if (p == null)
          Text(
            strings.t(PB.calcInvalid),
            key: const Key('billing-calc-invalid'),
          )
        else ...<Widget>[
          _Line(strings.t(PB.salGross), _money(p.currentGross, currency)),
          _Line(
            strings.t(PB.salAdvance),
            '- ${_money(p.advanceDeduction, currency)}',
          ),
          _Line(strings.t(PB.calcInvoice), _money(p.invoiceAmount, currency)),
          _Line(
            strings.t(PB.salRetention),
            '- ${_money(p.retentionWithheld, currency)}',
          ),
          _Line(
            strings.t(PB.salNet),
            _money(p.netBillable, currency),
            key: const Key('billing-calc-net'),
            bold: true,
          ),
          if (p.isFinal) Text(strings.t(PB.calcFinalNote)),
        ],
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value, {super.key, this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final TextStyle? style = bold
        ? Theme.of(context).textTheme.titleSmall
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class _SalTile extends StatelessWidget {
  const _SalTile({
    required this.strings,
    required this.sal,
    required this.currency,
  });

  final ProjectBillingStrings strings;
  final SalCertificate sal;
  final String currency;

  @override
  Widget build(BuildContext context) => ExpansionTile(
    key: Key('billing-sal-${sal.number}'),
    tilePadding: EdgeInsets.zero,
    title: Text(
      fillBilling(strings.t(PB.salLine), <String, Object>{
        'number': sal.number,
        'from': sal.previousPercent.toStringAsFixed(1),
        'to': sal.cumulativePercent.toStringAsFixed(1),
      }),
    ),
    subtitle: Text(
      '${strings.status(sal.status)}${sal.isFinal ? ' · ${strings.t(PB.salFinal)}' : ''}',
    ),
    children: <Widget>[
      _Line(strings.t(PB.salGross), _money(sal.currentGross, currency)),
      _Line(strings.t(PB.salAdvance), _money(sal.advanceDeduction, currency)),
      _Line(strings.t(PB.salRetention), _money(sal.retention, currency)),
      _Line(strings.t(PB.salNet), _money(sal.net, currency), bold: true),
    ],
  );
}

class _Retainer extends StatelessWidget {
  const _Retainer({
    required this.strings,
    required this.retainer,
    required this.currency,
  });

  final ProjectBillingStrings strings;
  final RetainerBalance retainer;
  final String currency;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      LinearProgressIndicator(
        key: const Key('billing-retainer-bar'),
        value: retainer.burned,
        color: retainer.isLow ? Theme.of(context).colorScheme.error : null,
      ),
      const SizedBox(height: 8),
      Text(
        retainer.byHours
            ? fillBilling(strings.t(PB.retainerHours), <String, Object>{
                'hours': retainer.remainingHours.toStringAsFixed(2),
              })
            : '${strings.t(PB.retainerAmount)}: ${_money(retainer.remainingAmount, currency)}',
      ),
      if (retainer.isLow)
        Text(
          fillBilling(strings.t(PB.retainerLow), <String, Object>{
            'threshold': retainer.thresholdPercent.toStringAsFixed(0),
          }),
          key: const Key('billing-retainer-low'),
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
    ],
  );
}

class _Retention extends StatelessWidget {
  const _Retention({
    required this.strings,
    required this.retention,
    required this.currency,
  });

  final ProjectBillingStrings strings;
  final RetentionBalance retention;
  final String currency;

  @override
  Widget build(BuildContext context) => Column(
    children: <Widget>[
      _Line(
        strings.t(PB.retentionWithheld),
        _money(retention.withheld, currency),
      ),
      _Line(
        strings.t(PB.retentionReleased),
        _money(retention.released, currency),
      ),
      _Line(
        strings.t(PB.retentionHeld),
        _money(retention.balance, currency),
        bold: true,
      ),
    ],
  );
}
