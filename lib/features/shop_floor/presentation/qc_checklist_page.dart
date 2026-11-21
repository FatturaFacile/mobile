import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../design/ff_tokens.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../data/shop_floor_repository.dart';
import '../domain/shop_floor_models.dart';
import 'shop_floor_providers.dart';
import 'terminal_widgets.dart';

final _plansProvider = FutureProvider.family<List<QualityPlan>, String>(
  (Ref ref, String tenantId) =>
      ref.watch(shopFloorRepositoryProvider).qualityPlans(tenantId),
);

/// QC checklist of one operation: one measured value per characteristic of the chosen inspection plan, judged against
/// its tolerance band as the operator types, then signed off into the offline queue.
class QcChecklistPage extends ConsumerStatefulWidget {
  const QcChecklistPage({
    required this.tenantId,
    required this.order,
    required this.operation,
    super.key,
  });

  final String tenantId;
  final ProductionOrder order;
  final OrderOperation operation;

  @override
  ConsumerState<QcChecklistPage> createState() => _QcChecklistPageState();
}

class _QcChecklistPageState extends ConsumerState<QcChecklistPage> {
  QualityPlan? _plan;
  final Map<String, TextEditingController> _values =
      <String, TextEditingController>{};
  final TextEditingController _inspected = TextEditingController(text: '1');
  final TextEditingController _notes = TextEditingController();

  @override
  void dispose() {
    for (final TextEditingController c in _values.values) {
      c.dispose();
    }
    _inspected.dispose();
    _notes.dispose();
    super.dispose();
  }

  TextEditingController _ctrl(String id) =>
      _values.putIfAbsent(id, () => TextEditingController());

  double? _parse(String text) =>
      double.tryParse(text.trim().replaceAll(',', '.'));

  Future<void> _signOff() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final QualityPlan? plan =
        _plan ?? ref.read(_plansProvider(widget.tenantId)).value?.firstOrNull;
    if (plan == null) {
      return;
    }
    final Map<String, double> measured = <String, double>{
      for (final QualityCharacteristic c in plan.characteristics)
        if (_parse(_ctrl(c.id).text) case final double v) c.id: v,
    };
    try {
      await ref
          .read(shopFloorRepositoryProvider)
          .signOffInspection(
            tenantId: widget.tenantId,
            orderId: widget.order.id,
            operationId: widget.operation.id,
            plan: plan,
            measurements: measured,
            quantityInspected: _parse(_inspected.text) ?? 0,
            notes: _notes.text,
          );
      if (!mounted) {
        return;
      }
      showTerminalMessage(context, l10n.mfgQcSignOffQueued);
      ref.read(shopFloorSyncProvider).syncNow(widget.tenantId);
      Navigator.of(context).pop();
    } on ShopFloorException catch (e) {
      if (mounted) {
        showTerminalMessage(context, shopFloorErrorText(l10n, e.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final List<QualityPlan> plans =
        ref.watch(_plansProvider(widget.tenantId)).value ??
        const <QualityPlan>[];
    final QualityPlan? plan = _plan ?? (plans.isEmpty ? null : plans.first);
    final FfColors colors = FfColors.dark;
    return TerminalTheme(
      child: Builder(
        builder: (BuildContext context) => Scaffold(
          appBar: AppBar(title: Text(l10n.mfgQcTitle)),
          body: plan == null
              ? Center(
                  child: Text(
                    l10n.mfgQcNoPlans,
                    style: const TextStyle(fontSize: FfFont.xl),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(FfSpace.space4),
                  children: <Widget>[
                    DropdownButtonFormField<String>(
                      key: const Key('mfg-qc-plan'),
                      initialValue: plan.id,
                      decoration: InputDecoration(
                        labelText: l10n.mfgQcPlan,
                        border: const OutlineInputBorder(),
                      ),
                      items: <DropdownMenuItem<String>>[
                        for (final QualityPlan p in plans)
                          DropdownMenuItem<String>(
                            value: p.id,
                            child: Text('${p.code} ${p.name}'),
                          ),
                      ],
                      onChanged: (String? id) => setState(
                        () => _plan = plans.firstWhere(
                          (QualityPlan p) => p.id == id,
                        ),
                      ),
                    ),
                    const SizedBox(height: FfSpace.space4),
                    for (final QualityCharacteristic c
                        in plan.characteristics) ...<Widget>[
                      Builder(
                        builder: (BuildContext context) {
                          final double? v = _parse(_ctrl(c.id).text);
                          final bool? ok = v == null ? null : c.accepts(v);
                          final Color border = ok == null
                              ? colors.border
                              : (ok ? colors.success : colors.danger);
                          return Container(
                            padding: const EdgeInsets.all(FfSpace.space3),
                            decoration: BoxDecoration(
                              border: Border.all(color: border, width: 3),
                              borderRadius: BorderRadius.circular(FfRadius.lg),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  '${c.name}${c.uom == null ? '' : ' (${c.uom})'}',
                                  style: const TextStyle(
                                    fontSize: FfFont.xl,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  l10n.mfgQcTolerance(
                                    c.min == null ? '–' : fmtQty(c.min!),
                                    c.max == null ? '–' : fmtQty(c.max!),
                                  ),
                                  style: const TextStyle(fontSize: FfFont.lg),
                                ),
                                TextField(
                                  key: Key('mfg-qc-${c.id}'),
                                  controller: _ctrl(c.id),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                        signed: true,
                                      ),
                                  style: const TextStyle(
                                    fontSize: FfFont.size2xl,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: l10n.mfgQcMeasured,
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                                if (ok != null)
                                  Text(
                                    ok
                                        ? l10n.mfgQcInTolerance
                                        : l10n.mfgQcOutOfTolerance,
                                    key: Key('mfg-qc-verdict-${c.id}'),
                                    style: TextStyle(
                                      fontSize: FfFont.xl,
                                      fontWeight: FontWeight.w800,
                                      color: border,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: FfSpace.space3),
                    ],
                    TextField(
                      key: const Key('mfg-qc-inspected'),
                      controller: _inspected,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: const TextStyle(fontSize: FfFont.xl),
                      decoration: InputDecoration(
                        labelText: l10n.mfgQcInspected,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: FfSpace.space3),
                    TextField(
                      controller: _notes,
                      maxLines: 2,
                      style: const TextStyle(fontSize: FfFont.lg),
                      decoration: InputDecoration(
                        labelText: l10n.mfgQcNotes,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: FfSpace.space4),
                    FilledButton.icon(
                      key: const Key('mfg-qc-signoff'),
                      onPressed: _signOff,
                      icon: const Icon(Icons.draw),
                      label: Text(l10n.mfgQcSignOff),
                    ),
                    const SizedBox(height: FfSpace.space5),
                  ],
                ),
        ),
      ),
    );
  }
}
