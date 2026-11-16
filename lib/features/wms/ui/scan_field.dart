import 'package:material_ui/material_ui.dart';

import '../../../design/ff_tokens.dart';
import '../../../l10n/ff_strings.dart';

/// Camera scanner hook: returns the decoded code or null when the user cancels.
typedef CameraScanner = Future<String?> Function(BuildContext context);

/// Barcode/SKU input. Hardware scanners (keyboard wedge) type the code and send Enter; the optional
/// [cameraScanner] adds a camera button. Both feed [onScan].
class ScanField extends StatefulWidget {
  const ScanField({super.key, required this.onScan, this.enabled = true, this.cameraScanner});

  final Future<void> Function(String code) onScan;
  final bool enabled;
  final CameraScanner? cameraScanner;

  @override
  State<ScanField> createState() => _ScanFieldState();
}

class _ScanFieldState extends State<ScanField> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _submit([String? code]) async {
    final value = (code ?? _controller.text).trim();
    if (value.isEmpty) return;
    _controller.clear();
    await widget.onScan(value);
    if (mounted) _focus.requestFocus();
  }

  Future<void> _camera() async {
    final code = await widget.cameraScanner!(context);
    if (code != null && mounted) await _submit(code);
  }

  @override
  Widget build(BuildContext context) {
    final s = FfStrings.of(context);
    return Row(
      children: [
        Expanded(
          child: TextField(
            key: const Key('scan-input'),
            controller: _controller,
            focusNode: _focus,
            enabled: widget.enabled,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: s.t(L.scanLabel),
              prefixIcon: const Icon(Icons.qr_code_scanner),
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _submit(),
          ),
        ),
        if (widget.cameraScanner != null)
          IconButton(
            key: const Key('scan-camera'),
            tooltip: s.t(L.scanAction),
            onPressed: widget.enabled ? _camera : null,
            icon: const Icon(Icons.photo_camera),
          ),
        const SizedBox(width: FfSpace.space2),
        FilledButton(
          key: const Key('scan-submit'),
          onPressed: widget.enabled ? _submit : null,
          child: Text(s.t(L.scanAction)),
        ),
      ],
    );
  }
}
