import 'package:material_ui/material_ui.dart';

import '../../../design/ff_tokens.dart';
import '../../../l10n/ff_strings.dart';
import '../data/wms_repository.dart';
import '../state/dispatch_state.dart';
import 'scan_field.dart';
import 'wms_labels.dart';

/// Step 1: scan every line of an approved transfer, then confirm the dispatch.
class DispatchScreen extends StatefulWidget {
  const DispatchScreen({super.key, required this.controller, this.cameraScanner, this.onDone});

  final DispatchController controller;
  final CameraScanner? cameraScanner;

  /// Called when the operator leaves the screen after a confirmed dispatch.
  final VoidCallback? onDone;

  @override
  State<DispatchScreen> createState() => _DispatchScreenState();
}

class _DispatchScreenState extends State<DispatchScreen> {
  final _carrier = TextEditingController();
  final _packages = TextEditingController();
  final _weight = TextEditingController();

  @override
  void dispose() {
    _carrier.dispose();
    _packages.dispose();
    _weight.dispose();
    super.dispose();
  }

  ShipmentInput _shipment() => ShipmentInput(
        carrierName: _carrier.text,
        packagesCount: int.tryParse(_packages.text.trim()),
        grossWeightKg: double.tryParse(_weight.text.trim().replaceAll(',', '.')),
      );

  @override
  Widget build(BuildContext context) {
    final s = FfStrings.of(context);
    final colors = Theme.of(context).extension<FfColors>()!;
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final c = widget.controller;
        final shipped = c.phase == DispatchPhase.shipped;
        return Scaffold(
          appBar: AppBar(title: Text(s.t(L.dispatchTitle, {'number': c.transfer.transferNumber}))),
          body: ListView(
            padding: const EdgeInsets.all(FfSpace.space4),
            children: [
              ScanField(
                onScan: (code) async {
                  await c.scan(code);
                },
                enabled: !shipped && c.phase != DispatchPhase.shipping,
                cameraScanner: widget.cameraScanner,
              ),
              const SizedBox(height: FfSpace.space3),
              if (c.lastScanned != null && c.error == null)
                Text(
                  s.t(L.scanMatched, {'line': c.lastScanned!.description}),
                  key: const Key('scan-feedback'),
                  style: TextStyle(color: colors.success),
                ),
              if (c.error != null) Text(c.error!, key: const Key('dispatch-error'), style: TextStyle(color: colors.danger)),
              const SizedBox(height: FfSpace.space3),
              Text(
                s.t(L.scannedProgress, {
                  'done': '${c.checklist.scannedCount}',
                  'total': '${c.checklist.lines.length}',
                }),
                key: const Key('dispatch-progress'),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: FfSpace.space2),
              for (final line in c.checklist.lines)
                ListTile(
                  key: Key('line-${line.id}'),
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    c.checklist.isScanned(line.id) ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: c.checklist.isScanned(line.id) ? colors.success : colors.textMuted,
                  ),
                  title: Text(line.description),
                  subtitle: Text(
                    c.checklist.isScanned(line.id) ? s.t(L.lineScanned) : s.t(L.lineNotScanned),
                  ),
                  trailing: Text(formatQty(line.quantity), style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              const Divider(),
              TextField(
                key: const Key('carrier-input'),
                controller: _carrier,
                decoration: InputDecoration(labelText: s.t(L.carrier), border: const OutlineInputBorder()),
              ),
              const SizedBox(height: FfSpace.space3),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('packages-input'),
                      controller: _packages,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: s.t(L.packagesCount), border: const OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: FfSpace.space3),
                  Expanded(
                    child: TextField(
                      key: const Key('weight-input'),
                      controller: _weight,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(labelText: s.t(L.grossWeight), border: const OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: FfSpace.space4),
              if (!c.checklist.isReady && !shipped)
                Padding(
                  padding: const EdgeInsets.only(bottom: FfSpace.space2),
                  child: Text(s.t(L.dispatchHint), style: TextStyle(color: colors.textSecondary)),
                ),
              if (shipped) ...[
                Text(
                  s.t(L.dispatchDone, {'status': statusLabel(s, c.transfer.status)}),
                  key: const Key('dispatch-done'),
                  style: TextStyle(color: colors.success, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: FfSpace.space3),
                OutlinedButton(onPressed: widget.onDone, child: Text(s.t(L.backToQueue))),
              ] else
                FilledButton(
                  key: const Key('dispatch-confirm'),
                  onPressed: c.canConfirm ? () => c.confirm(_shipment()) : null,
                  child: c.phase == DispatchPhase.shipping
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(s.t(L.confirmDispatch)),
                ),
            ],
          ),
        );
      },
    );
  }
}
