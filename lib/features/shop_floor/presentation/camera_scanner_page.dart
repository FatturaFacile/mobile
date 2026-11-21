import 'package:material_ui/material_ui.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../design/ff_tokens.dart';
import '../../../l10n/gen/app_localizations.dart';

/// Full-screen camera scanner (QR, Code 128 / GS1-128, DataMatrix, EAN). Pops the first decoded value.
class CameraScannerPage extends StatefulWidget {
  const CameraScannerPage({super.key});

  @override
  State<CameraScannerPage> createState() => _CameraScannerPageState();
}

class _CameraScannerPageState extends State<CameraScannerPage> {
  final MobileScannerController _controller = MobileScannerController(
    formats: const <BarcodeFormat>[
      BarcodeFormat.qrCode,
      BarcodeFormat.code128,
      BarcodeFormat.dataMatrix,
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.code39,
    ],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _done = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_done) {
      return;
    }
    for (final Barcode b in capture.barcodes) {
      final String? value = b.rawValue;
      if (value != null && value.isNotEmpty) {
        _done = true;
        Navigator.of(context).pop(value);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final FfColors colors =
        Theme.of(context).extension<FfColors>() ?? FfColors.dark;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.mfgCameraTitle)),
      body: MobileScanner(
        controller: _controller,
        onDetect: _onDetect,
        errorBuilder: (BuildContext context, MobileScannerException error) =>
            Center(
              child: Padding(
                padding: const EdgeInsets.all(FfSpace.space5),
                child: Text(
                  l10n.mfgCameraUnavailable,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.text, fontSize: FfFont.xl),
                ),
              ),
            ),
      ),
    );
  }
}
