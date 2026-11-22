import 'package:material_ui/material_ui.dart';

import '../../../design/ff_tokens.dart';
import '../data/field_service_repository.dart';
import '../device/field_service_device_services.dart';
import '../domain/coverage_policy.dart';
import '../domain/scan_codes.dart';
import '../l10n/field_service_strings.dart';
import '../models/field_service_models.dart';

/// Bottom sheet that picks a van part (by list or by scanning its label), the quantity and the lot, and shows right away
/// whether the warranty or contract covers it (computed on the phone from the coverage rules). Confirming consumes the part
/// through the repository: the van stock drops and the line is queued for sync.
class PartPicker extends StatefulWidget {
  const PartPicker({
    super.key,
    required this.repository,
    required this.workOrder,
    this.device = const FieldServiceDeviceHooks(),
    this.coverage = const CoveragePolicy(),
  });

  final FieldServiceRepository repository;
  final FsmWorkOrder workOrder;
  final FieldServiceDeviceHooks device;
  final CoveragePolicy coverage;

  @override
  State<PartPicker> createState() => _PartPickerState();
}

class _PartPickerState extends State<PartPicker> {
  final TextEditingController _quantity = TextEditingController(text: '1');
  final TextEditingController _lot = TextEditingController();
  VanStockItem? _selected;
  String? _message;
  bool _saving = false;
  late final Stream<List<VanStockItem>> _van = widget.repository
      .watchVanStock();

  @override
  void dispose() {
    _quantity.dispose();
    _lot.dispose();
    super.dispose();
  }

  Future<void> _scan(List<VanStockItem> van) async {
    final FieldServiceStrings s = FieldServiceStrings.of(context);
    final String? code = await widget.device.scanCode!(context);
    if (!mounted || code == null) return;
    final PartScan? scan = PartScan.parse(code);
    final VanStockItem? item = scan?.resolve(van);
    setState(() {
      if (item == null) {
        _message = s.t(FsmText.partNotOnVan);
      } else {
        _selected = item;
        _message = null;
        if (scan!.lotNumber != null) _lot.text = scan.lotNumber!;
      }
    });
  }

  Future<void> _confirm() async {
    final FieldServiceStrings s = FieldServiceStrings.of(context);
    final VanStockItem? item = _selected;
    if (item == null)
      return setState(() => _message = s.t(FsmText.partNotOnVan));
    final double? quantity = double.tryParse(
      _quantity.text.trim().replaceAll(',', '.'),
    );
    if (quantity == null || quantity <= 0) {
      return setState(() => _message = s.t(FsmText.partQuantityInvalid));
    }
    setState(() => _saving = true);
    try {
      await widget.repository.consumePart(
        widget.workOrder.id,
        item,
        quantity,
        lotNumber: _lot.text,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on FsmException catch (e) {
      if (!mounted) return;
      final MapEntry<String, String> first = e.errors.entries.first;
      setState(() {
        _saving = false;
        _message = s.error(first.key, first.value);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final FieldServiceStrings s = FieldServiceStrings.of(context);
    final bool covered = widget.coverage.coversParts(widget.workOrder);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: StreamBuilder<List<VanStockItem>>(
        stream: _van,
        builder:
            (BuildContext context, AsyncSnapshot<List<VanStockItem>> snap) {
              final List<VanStockItem> van =
                  snap.data ?? const <VanStockItem>[];
              return ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.all(FfSpace.space4),
                children: <Widget>[
                  Text(
                    s.t(FsmText.addPart),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (widget.device.scanCode != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        key: const Key('fsm-scan-part'),
                        icon: const Icon(Icons.qr_code_scanner),
                        onPressed: () => _scan(van),
                        label: Text(s.t(FsmText.scanPart)),
                      ),
                    ),
                  for (final VanStockItem item in van)
                    ListTile(
                      key: Key('fsm-van-${item.productId}'),
                      dense: true,
                      selected: _selected?.productId == item.productId,
                      title: Text('${item.sku} · ${item.name}'),
                      subtitle: Text(
                        fill(s.t(FsmText.onVan), <String, Object>{
                          'qty': _qty(item.available),
                        }),
                      ),
                      onTap: () => setState(() {
                        _selected = item;
                        _message = null;
                      }),
                    ),
                  if (_selected != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: FfSpace.space2,
                      ),
                      child: Chip(
                        key: const Key('fsm-part-coverage'),
                        label: Text(
                          s.t(covered ? FsmText.covered : FsmText.chargeable),
                        ),
                      ),
                    ),
                  TextField(
                    key: const Key('fsm-part-qty'),
                    controller: _quantity,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: s.t(FsmText.quantity),
                    ),
                  ),
                  TextField(
                    key: const Key('fsm-part-lot'),
                    controller: _lot,
                    maxLength: 60,
                    decoration: InputDecoration(
                      labelText: s.t(FsmText.lotNumber),
                    ),
                  ),
                  if (_message != null)
                    Text(
                      _message!,
                      key: const Key('fsm-part-message'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  const SizedBox(height: FfSpace.space3),
                  FilledButton(
                    key: const Key('fsm-part-confirm'),
                    onPressed: _saving ? null : _confirm,
                    child: Text(s.t(FsmText.addPart)),
                  ),
                ],
              );
            },
      ),
    );
  }
}

/// A quantity without a trailing `.0`.
String _qty(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toString();

/// Shared by the detail screen and the picker: `12` or `2.5`.
String formatQuantity(double value) => _qty(value);
