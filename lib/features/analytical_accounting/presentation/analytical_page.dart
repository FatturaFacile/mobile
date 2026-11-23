import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../domain/analytical_models.dart';
import '../l10n/analytical_strings.dart';
import 'analytical_controller.dart';

/// Industrial and analytical cost accounting on the phone: the center hierarchy, the contribution margin and the direct versus
/// apportioned comparison, and a manual analytical entry with an optional two-way split, all readable and capturable offline.
class AnalyticalAccountingPage extends ConsumerStatefulWidget {
  const AnalyticalAccountingPage({super.key});

  @override
  ConsumerState<AnalyticalAccountingPage> createState() =>
      _AnalyticalAccountingPageState();
}

class _AnalyticalAccountingPageState
    extends ConsumerState<AnalyticalAccountingPage> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(analyticalControllerProvider.notifier).open(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AnalyticalStrings s = AnalyticalStrings.of(context);
    final AnalyticalState state = ref.watch(analyticalControllerProvider);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(s.t(A.title)),
          bottom: TabBar(
            tabs: <Widget>[
              Tab(text: s.t(A.tabCenters)),
              Tab(text: s.t(A.tabMargin)),
              Tab(text: s.t(A.tabEntry)),
            ],
          ),
        ),
        body: Column(
          children: <Widget>[
            if (state.syncing) const LinearProgressIndicator(minHeight: 2),
            if (state.offline)
              _Banner(
                key: const Key('analytical-offline'),
                text: s.t(A.offlineBanner),
              )
            else if (state.lastSync == AnalyticalSyncStatus.failed)
              _Banner(
                key: const Key('analytical-failed'),
                text: s.t(A.syncFailed),
              )
            else if (state.lastSync == AnalyticalSyncStatus.unauthorized)
              _Banner(
                key: const Key('analytical-signin'),
                text: s.t(A.signInRequired),
              )
            else if (state.lastSync == AnalyticalSyncStatus.forbidden)
              _Banner(
                key: const Key('analytical-forbidden'),
                text: s.t(A.forbidden),
              ),
            if (state.overview.pending > 0)
              _Banner(
                key: const Key('analytical-pending'),
                text: fillAnalytical(s.t(A.pending), <String, Object>{
                  'count': state.overview.pending,
                }),
              ),
            Expanded(
              child: TabBarView(
                children: <Widget>[
                  _CentersTab(strings: s, state: state),
                  _MarginTab(strings: s, state: state),
                  _EntryTab(strings: s, state: state),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(8),
    color: Theme.of(context).colorScheme.secondaryContainer,
    child: Text(text),
  );
}

class _CentersTab extends ConsumerWidget {
  const _CentersTab({required this.strings, required this.state});

  final AnalyticalStrings strings;
  final AnalyticalState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<AnalyticalCenter> centers = flattenCenters(
      state.overview.centers,
    );
    return RefreshIndicator(
      onRefresh: ref.read(analyticalControllerProvider.notifier).refresh,
      child: centers.isEmpty && !state.loading
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(child: Text(strings.t(A.noCenters))),
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: centers.length,
              itemBuilder: (BuildContext context, int index) {
                final AnalyticalCenter center = centers[index];
                return ListTile(
                  key: Key('center-${center.id}'),
                  contentPadding: EdgeInsets.only(
                    left: 16.0 + center.depth * 20,
                    right: 16,
                  ),
                  title: Text('${center.code} ${center.name}'),
                  subtitle: Text(
                    <String>[
                      strings.centerType(center.centerType),
                      strings.centerCategory(center.category),
                      if (center.managerName != null) center.managerName!,
                      if (!center.isActive) strings.t(A.inactive),
                    ].join(' · '),
                  ),
                );
              },
            ),
    );
  }
}

class _MarginTab extends ConsumerWidget {
  const _MarginTab({required this.strings, required this.state});

  final AnalyticalStrings strings;
  final AnalyticalState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ContributionMargin? margin = state.overview.margin;
    return RefreshIndicator(
      onRefresh: ref.read(analyticalControllerProvider.notifier).refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          if (margin == null)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(child: Text(strings.t(A.noMargin))),
            )
          else ...<Widget>[
            _Line(strings.t(A.revenues), margin.revenues),
            _Line(strings.t(A.variableCosts), margin.variableCosts),
            _Line(
              strings.t(A.margin1),
              margin.margin1,
              percent: margin.margin1Percent,
              bold: true,
            ),
            _Line(strings.t(A.fixedCosts), margin.fixedCosts),
            _Line(
              strings.t(A.margin2),
              margin.margin2,
              percent: margin.margin2Percent,
              bold: true,
            ),
            _Line(strings.t(A.indirectCosts), margin.indirectCosts),
            _Line(strings.t(A.apportionedCosts), margin.apportionedCosts),
            _Line(
              strings.t(A.operatingResult),
              margin.operatingResult,
              percent: margin.operatingResultPercent,
              bold: true,
            ),
          ],
          const SizedBox(height: 16),
          Text(
            strings.t(A.comparison),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          for (final ComparisonRow row in state.overview.comparison)
            ListTile(
              key: Key('comparison-${row.centerId}'),
              contentPadding: EdgeInsets.only(left: row.depth * 16.0),
              title: Text('${row.code} ${row.name}'),
              subtitle: Text(
                '${strings.t(A.directCost)} ${row.directCost.toStringAsFixed(2)} · '
                '${strings.t(A.apportionedIn)} ${row.apportionedIn.toStringAsFixed(2)} · '
                '${strings.t(A.apportionedOut)} ${row.apportionedOut.toStringAsFixed(2)}',
              ),
              trailing: Text(row.netCost.toStringAsFixed(2)),
            ),
          const SizedBox(height: 16),
          Text(
            strings.t(A.runs),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          for (final ApportionmentRun run in state.overview.runs)
            ListTile(
              key: Key('run-${run.id}'),
              title: Text(
                '${run.periodKey} · ${strings.runStatus(run.status)}',
              ),
              subtitle: Text(
                '${strings.t(A.pool)} ${run.totalPool.toStringAsFixed(2)} · '
                '${strings.t(A.allocated)} ${run.totalAllocated.toStringAsFixed(2)}',
              ),
            ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value, {this.percent, this.bold = false});

  final String label;
  final double value;
  final double? percent;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final TextStyle? style = bold
        ? Theme.of(context).textTheme.titleSmall
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Expanded(child: Text(label, style: style)),
          Text(
            percent == null
                ? value.toStringAsFixed(2)
                : '${value.toStringAsFixed(2)} (${percent!.toStringAsFixed(2)} %)',
            style: style,
          ),
        ],
      ),
    );
  }
}

class _EntryTab extends ConsumerStatefulWidget {
  const _EntryTab({required this.strings, required this.state});

  final AnalyticalStrings strings;
  final AnalyticalState state;

  @override
  ConsumerState<_EntryTab> createState() => _EntryTabState();
}

class _EntryTabState extends ConsumerState<_EntryTab> {
  final TextEditingController _amount = TextEditingController();
  final TextEditingController _percent = TextEditingController();
  String _element = analyticalCostElementTypes.first;
  AnalyticalCenter? _first;
  AnalyticalCenter? _second;
  bool _invalidInput = false;

  @override
  void dispose() {
    _amount.dispose();
    _percent.dispose();
    super.dispose();
  }

  AllocationVector _vector(AnalyticalCenter center, double percentage) =>
      center.isCostCenter
      ? AllocationVector(costCenterId: center.id, percentage: percentage)
      : AllocationVector(profitCenterId: center.id, percentage: percentage);

  EntryDraft? _draft() {
    final double? amount = double.tryParse(_amount.text.replaceAll(',', '.'));
    final AnalyticalCenter? first = _first;
    if (amount == null || first == null) {
      return null;
    }
    final String today = DateTime.now().toIso8601String().substring(0, 10);
    final AnalyticalCenter? second = _second;
    if (second == null || _percent.text.trim().isEmpty) {
      return EntryDraft(
        postingDate: today,
        lines: <EntryLineDraft>[
          EntryLineDraft(
            amount: amount,
            costElementType: _element,
            costCenterId: first.isCostCenter ? first.id : null,
            profitCenterId: first.isCostCenter ? null : first.id,
          ),
        ],
      );
    }
    final double? percent = double.tryParse(_percent.text.replaceAll(',', '.'));
    if (percent == null || percent <= 0 || percent >= 100) {
      return null;
    }
    return EntryDraft(
      postingDate: today,
      lines: <EntryLineDraft>[
        EntryLineDraft(
          amount: amount,
          costElementType: _element,
          vectors: <AllocationVector>[
            _vector(first, percent),
            _vector(second, 100 - percent),
          ],
        ),
      ],
    );
  }

  Future<void> _queue() async {
    final EntryDraft? draft = _draft();
    setState(() => _invalidInput = draft == null);
    if (draft == null) {
      return;
    }
    final bool queued = await ref
        .read(analyticalControllerProvider.notifier)
        .queueEntry(draft);
    if (queued && mounted) {
      _amount.clear();
      _percent.clear();
      setState(() => _second = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AnalyticalStrings s = widget.strings;
    final List<AnalyticalCenter> centers = flattenCenters(
      widget.state.overview.centers,
    ).where((AnalyticalCenter c) => c.isActive).toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Text(s.t(A.newEntry), style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        TextField(
          key: const Key('entry-amount'),
          controller: _amount,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          decoration: InputDecoration(labelText: s.t(A.amount)),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: const Key('entry-element'),
          initialValue: _element,
          decoration: InputDecoration(labelText: s.t(A.costElement)),
          items: <DropdownMenuItem<String>>[
            for (final String type in analyticalCostElementTypes)
              DropdownMenuItem<String>(
                value: type,
                child: Text(s.element(type)),
              ),
          ],
          onChanged: (String? value) =>
              setState(() => _element = value ?? _element),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<AnalyticalCenter>(
          key: const Key('entry-first'),
          decoration: InputDecoration(labelText: s.t(A.firstCenter)),
          items: <DropdownMenuItem<AnalyticalCenter>>[
            for (final AnalyticalCenter c in centers)
              DropdownMenuItem<AnalyticalCenter>(
                value: c,
                child: Text('${c.code} ${c.name}'),
              ),
          ],
          onChanged: (AnalyticalCenter? value) =>
              setState(() => _first = value),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<AnalyticalCenter>(
          key: const Key('entry-second'),
          decoration: InputDecoration(labelText: s.t(A.secondCenter)),
          items: <DropdownMenuItem<AnalyticalCenter>>[
            for (final AnalyticalCenter c in centers)
              DropdownMenuItem<AnalyticalCenter>(
                value: c,
                child: Text('${c.code} ${c.name}'),
              ),
          ],
          onChanged: (AnalyticalCenter? value) =>
              setState(() => _second = value),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('entry-percent'),
          controller: _percent,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: s.t(A.splitPercent)),
        ),
        const SizedBox(height: 16),
        FilledButton(
          key: const Key('entry-queue'),
          onPressed: _queue,
          child: Text(s.t(A.queueEntry)),
        ),
        if (_invalidInput)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(s.t(A.invalidAmount), key: const Key('entry-invalid')),
          )
        else if (widget.state.entryErrors.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              widget.state.entryErrors.map(s.error).join(' '),
              key: const Key('entry-errors'),
            ),
          )
        else if (widget.state.entryQueued)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(s.t(A.entryQueued), key: const Key('entry-queued')),
          ),
      ],
    );
  }
}
