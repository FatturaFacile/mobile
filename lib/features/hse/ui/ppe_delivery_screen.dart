import 'package:material_ui/material_ui.dart';

import '../../../design/ff_tokens.dart';
import '../../wms/ui/scan_field.dart';
import '../data/hse_repository.dart';
import '../l10n/hse_strings.dart';
import '../models/hse_models.dart';
import 'signature_pad.dart';

/// On-glass PPE delivery: pick the worker (badge scan or employee id), scan the PPE box (`PPE:<product>:<lot>`), read the
/// legal notice of the jurisdiction, and let the worker sign. The hand-over goes to the offline queue and the server turns it
/// into the stock movement, the hashed signature and the Verbale di Consegna PDF once the device is online.
class PpeDeliveryScreen extends StatefulWidget {
  const PpeDeliveryScreen({
    super.key,
    required this.repository,
    required this.warehouseId,
    this.jurisdiction = HseJurisdiction.italy,
    this.cameraScanner,
    this.onDone,
  });

  final HseRepository repository;

  /// Warehouse the PPE is issued from (the stock of Mod 051 is decremented there).
  final String warehouseId;
  final HseJurisdiction jurisdiction;
  final CameraScanner? cameraScanner;
  final VoidCallback? onDone;

  @override
  State<PpeDeliveryScreen> createState() => _PpeDeliveryScreenState();
}

class _PpeDeliveryScreenState extends State<PpeDeliveryScreen> {
  final SignatureController _signature = SignatureController();
  final TextEditingController _worker = TextEditingController();
  final TextEditingController _quantity = TextEditingController(text: '1');
  PpeScan? _scan;
  String? _message;
  bool _saving = false;

  @override
  void dispose() {
    _signature.dispose();
    _worker.dispose();
    _quantity.dispose();
    super.dispose();
  }

  Future<void> _onScan(String code) async {
    final s = HseStrings.of(context);
    final ppe = PpeScan.parse(code);
    setState(() {
      if (ppe == null) {
        _message = s.t(H.notAPpeLabel);
      } else {
        _scan = ppe;
        _message = null;
      }
    });
  }

  Future<void> _confirm() async {
    final s = HseStrings.of(context);
    final locale = Localizations.localeOf(context);
    final worker = _worker.text.trim();
    final quantity = double.tryParse(_quantity.text.trim().replaceAll(',', '.')) ?? 0;
    if (worker.isEmpty) return setState(() => _message = s.t(H.workerRequired));
    if (_scan == null) return setState(() => _message = s.t(H.scanPpeHint));
    if (_signature.isEmpty || quantity <= 0) return setState(() => _message = s.t(H.signatureRequired));

    setState(() => _saving = true);
    await widget.repository.queuePpeHandOver(PpeHandOver(
      employeeId: worker,
      productId: _scan!.productId,
      warehouseId: widget.warehouseId,
      lotOrSerial: _scan!.lotOrSerial,
      quantity: quantity,
      signaturePayload: _signature.toPayload(),
      signatureImage: await _signature.toPngBase64(),
      locale: locale.toLanguageTag(),
    ));
    if (!mounted) return;
    setState(() {
      _saving = false;
      _message = s.t(H.handOverQueued);
      _scan = null;
      _worker.clear();
      _signature.clear();
    });
    widget.onDone?.call();
  }

  @override
  Widget build(BuildContext context) {
    final s = HseStrings.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.t(H.ppeTitle))),
      body: ListView(
        padding: const EdgeInsets.all(FfSpace.space4),
        children: [
          TextField(
            key: const Key('ppe-worker'),
            controller: _worker,
            decoration: InputDecoration(labelText: s.t(H.workerLabel), helperText: s.t(H.workerHint)),
          ),
          const SizedBox(height: FfSpace.space3),
          Text(s.t(H.scanPpe), style: const TextStyle(fontWeight: FontWeight.w600)),
          ScanField(onScan: _onScan, cameraScanner: widget.cameraScanner),
          if (_scan != null) Text(fill(s.t(H.scannedItem), {'lot': _scan!.lotOrSerial}), key: const Key('ppe-scanned')),
          const SizedBox(height: FfSpace.space3),
          TextField(
            key: const Key('ppe-quantity'),
            controller: _quantity,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: s.t(H.quantity)),
          ),
          const SizedBox(height: FfSpace.space4),
          Text(s.legalNotice(widget.jurisdiction), key: const Key('ppe-legal')),
          const SizedBox(height: FfSpace.space3),
          Text(s.t(H.signHere), style: const TextStyle(fontWeight: FontWeight.w600)),
          SignaturePad(controller: _signature),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: _signature.clear, child: Text(s.t(H.clearSignature))),
          ),
          if (_message != null) Text(_message!, key: const Key('ppe-message')),
          const SizedBox(height: FfSpace.space3),
          FilledButton(key: const Key('ppe-confirm'), onPressed: _saving ? null : _confirm, child: Text(s.t(H.confirmHandOver))),
        ],
      ),
    );
  }
}
