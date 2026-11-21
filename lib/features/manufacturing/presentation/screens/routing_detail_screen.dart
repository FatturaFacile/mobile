import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/calculators/routing_lead_time_cost_calculator.dart';
import '../../domain/entities/manufacturing_models.dart';
import '../providers/manufacturing_providers.dart';
import '../widgets/mfg_labels.dart';

/// Routing steps plus an offline lead-time / standard-cost calculator for a lot.
class RoutingDetailScreen extends ConsumerStatefulWidget {
  const RoutingDetailScreen({
    required this.tenantId,
    required this.routing,
    super.key,
  });

  final String tenantId;
  final MfgRouting routing;

  @override
  ConsumerState<RoutingDetailScreen> createState() =>
      _RoutingDetailScreenState();
}

class _RoutingDetailScreenState extends ConsumerState<RoutingDetailScreen> {
  final TextEditingController _qty = TextEditingController(text: '1');
  bool _overlap = true;
  RoutingLeadTimeCostResult? _result;
  String? _error;

  @override
  void dispose() {
    _qty.dispose();
    super.dispose();
  }

  void _calculate() {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final double? qty = double.tryParse(_qty.text.trim().replaceAll(',', '.'));
    if (qty == null || qty <= 0) {
      setState(() {
        _result = null;
        _error = l10n.mfgCalcInvalid;
      });
      return;
    }
    final Map<String, MfgWorkCenter> centers = <String, MfgWorkCenter>{
      for (final MfgWorkCenter w
          in ref.read(mfgWorkCentersProvider(widget.tenantId)).value ??
              <MfgWorkCenter>[])
        w.id: w,
    };
    final Map<String, MfgMachine> machines = <String, MfgMachine>{
      for (final MfgMachine m
          in ref.read(mfgMachinesProvider(widget.tenantId)).value ??
              <MfgMachine>[])
        m.id: m,
    };
    try {
      final RoutingLeadTimeCostResult r =
          RoutingLeadTimeCostCalculator.calculate(
            widget.routing,
            workCenters: centers,
            machines: machines,
            quantity: qty,
            includeOverlap: _overlap,
          );
      setState(() {
        _result = r;
        _error = null;
      });
    } on RoutingCalculationException {
      setState(() {
        _result = null;
        _error = l10n.mfgCalcMissingWorkCenter;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    // Keep both streams subscribed so the calculator can read their values.
    ref.watch(mfgWorkCentersProvider(widget.tenantId));
    ref.watch(mfgMachinesProvider(widget.tenantId));
    final MfgRouting r = widget.routing;
    final RoutingLeadTimeCostResult? res = _result;
    String min(double v) => l10n.mfgMinutesValue(MfgLabels.number(context, v));
    return Scaffold(
      appBar: AppBar(title: Text('${r.routingNumber} · ${r.name}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(
            '${l10n.mfgRevisionLabel(r.revision)} · ${l10n.mfgStepsCount(r.steps.length)}',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          for (final MfgRoutingStep s in r.steps)
            Card(
              key: Key('mfg-step-${s.id}'),
              child: ListTile(
                title: Text(
                  '${l10n.mfgStepTitle(s.sequence, s.operationCode)} ${s.name}',
                ),
                subtitle: Text(
                  <String>[
                    '${l10n.mfgSetupTime}: ${min(s.setupTimeMinutes)}',
                    '${l10n.mfgRunTime}: ${min(s.runTimeMinutesPerUnit)}',
                    if (s.queueTimeMinutes > 0)
                      '${l10n.mfgQueueTime}: ${min(s.queueTimeMinutes)}',
                    if (s.moveTimeMinutes > 0)
                      '${l10n.mfgMoveTime}: ${min(s.moveTimeMinutes)}',
                    if (s.isSubcontracted ||
                        s.operationType == 'external_subcontracting')
                      l10n.mfgSubcontracted,
                  ].join(' · '),
                ),
              ),
            ),
          const Divider(height: 32),
          Text(l10n.mfgCalculatorTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            key: const Key('mfg-qty'),
            controller: _qty,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: l10n.mfgLotQuantity),
          ),
          SwitchListTile(
            key: const Key('mfg-overlap'),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.mfgIncludeOverlap),
            value: _overlap,
            onChanged: (bool v) => setState(() => _overlap = v),
          ),
          FilledButton(
            key: const Key('mfg-calculate'),
            onPressed: _calculate,
            child: Text(l10n.mfgCalculate),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _error!,
                key: const Key('mfg-calc-error'),
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          if (res != null) ...<Widget>[
            const SizedBox(height: 12),
            _row(
              l10n.mfgTotalLeadTime,
              min(res.totalMinutes),
              'mfg-total-minutes',
            ),
            _row(
              l10n.mfgSerialLeadTime,
              min(res.serialMinutes),
              'mfg-serial-minutes',
            ),
            _row(
              l10n.mfgOverlapSaving,
              min(res.overlapSavingMinutes),
              'mfg-saving-minutes',
            ),
            const SizedBox(height: 8),
            _row(
              l10n.mfgTotalCost,
              MfgLabels.number(context, res.cost.total),
              'mfg-total-cost',
            ),
            _row(
              l10n.mfgUnitCost,
              MfgLabels.number(context, res.unitCost),
              'mfg-unit-cost',
            ),
            _row(
              l10n.mfgCostSetup,
              MfgLabels.number(context, res.cost.setup),
              'mfg-cost-setup',
            ),
            _row(
              l10n.mfgCostMachine,
              MfgLabels.number(context, res.cost.machineRun),
              'mfg-cost-machine',
            ),
            _row(
              l10n.mfgCostLabor,
              MfgLabels.number(context, res.cost.directLabor),
              'mfg-cost-labor',
            ),
            _row(
              l10n.mfgCostOverhead,
              MfgLabels.number(context, res.cost.overhead),
              'mfg-cost-overhead',
            ),
            _row(
              l10n.mfgCostSubcontracting,
              MfgLabels.number(context, res.cost.subcontracting),
              'mfg-cost-subcontracting',
            ),
            const SizedBox(height: 4),
            Text(l10n.mfgCostMaterialNote, style: theme.textTheme.bodySmall),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value, String key) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label)),
          Text(value, key: Key(key)),
        ],
      ),
    );
  }
}
