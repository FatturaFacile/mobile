import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../design/ff_tokens.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../wms/ui/scan_field.dart' show CameraScanner;
import '../data/shop_floor_repository.dart';
import 'shop_floor_providers.dart';

/// Minimum touch target of the operator terminal (gloves, wet hands): well above the 24 px WCAG floor.
const double terminalTarget = 64;

/// Quantity without trailing zeros (`12`, `2.5`).
String fmtQty(double v) {
  final String s = v.toStringAsFixed(4);
  return s.contains('.')
      ? s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '')
      : s;
}

/// `HH:MM:SS` of a stopwatch value.
String fmtClock(int seconds) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(seconds ~/ 3600)}:${two(seconds % 3600 ~/ 60)}:${two(seconds % 60)}';
}

/// Always-dark, high-contrast variant of the app theme with oversized text for shop-floor use.
class TerminalTheme extends StatelessWidget {
  const TerminalTheme({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData base = ffThemeData(brightness: Brightness.dark);
    final FfColors colors = base.extension<FfColors>()!;
    return Theme(
      data: base.copyWith(
        textTheme: base.textTheme.apply(
          bodyColor: colors.text,
          displayColor: colors.text,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(terminalTarget, terminalTarget),
            textStyle: const TextStyle(
              fontSize: FfFont.xl,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(terminalTarget, terminalTarget),
            side: BorderSide(color: colors.text, width: 2),
            textStyle: const TextStyle(
              fontSize: FfFont.xl,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      child: child,
    );
  }
}

/// Shows an operator-facing refusal as a snack bar.
void showTerminalMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: FfFont.lg)),
      ),
    );
}

String shopFloorErrorText(AppLocalizations l10n, ShopFloorError e) =>
    switch (e) {
      ShopFloorError.nothingToPost => l10n.mfgErrNothingToPost,
      ShopFloorError.scrapReasonRequired => l10n.mfgErrScrapReason,
      ShopFloorError.invalidQuantity => l10n.mfgErrQuantity,
      ShopFloorError.orderNotExecutable => l10n.mfgErrNotExecutable,
      ShopFloorError.unknownOrder => l10n.mfgErrNotExecutable,
    };

String statusText(AppLocalizations l10n, String status) => switch (status) {
  'released' => l10n.mfgStatusReleased,
  'in_progress' => l10n.mfgStatusInProgress,
  _ => status,
};

/// Type-or-scan input with a big camera button. Hardware scanners (keyboard wedge) end with Enter.
class TerminalScanBar extends ConsumerStatefulWidget {
  const TerminalScanBar({required this.onCode, this.hint, super.key});

  final Future<void> Function(String code) onCode;
  final String? hint;

  @override
  ConsumerState<TerminalScanBar> createState() => _TerminalScanBarState();
}

class _TerminalScanBarState extends ConsumerState<TerminalScanBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _submit(String raw) async {
    final String code = raw.trim();
    if (code.isEmpty) {
      return;
    }
    _controller.clear();
    await widget.onCode(code);
    if (mounted) {
      _focus.requestFocus();
    }
  }

  Future<void> _camera() async {
    final CameraScanner scan = ref.read(shopFloorCameraScannerProvider);
    final String? code = await scan(context);
    if (code != null) {
      await _submit(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Row(
      children: <Widget>[
        Expanded(
          child: TextField(
            controller: _controller,
            focusNode: _focus,
            textInputAction: TextInputAction.done,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.deny(RegExp('[\n\r]')),
            ],
            style: const TextStyle(fontSize: FfFont.xl),
            decoration: InputDecoration(
              hintText: widget.hint ?? l10n.mfgScanManualHint,
              prefixIcon: const Icon(Icons.qr_code_scanner),
              border: const OutlineInputBorder(),
            ),
            onSubmitted: _submit,
          ),
        ),
        const SizedBox(width: FfSpace.space3),
        SizedBox(
          height: terminalTarget,
          child: FilledButton.icon(
            key: const Key('mfg-camera'),
            onPressed: _camera,
            icon: const Icon(Icons.photo_camera, size: 28),
            label: Text(l10n.mfgScanButton),
          ),
        ),
      ],
    );
  }
}

/// "N waiting to send" / "Everything sent" strip with a manual sync button.
class SyncStrip extends ConsumerWidget {
  const SyncStrip({required this.tenantId, this.onOpenQueue, super.key});

  final String tenantId;
  final VoidCallback? onOpenQueue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final FfColors colors = Theme.of(context).extension<FfColors>()!;
    final int pending =
        ref.watch(shopFloorPendingProvider(tenantId)).value ?? 0;
    final bool clear = pending == 0;
    return Material(
      color: clear ? colors.successBg : colors.warningBg,
      child: InkWell(
        onTap: onOpenQueue,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: FfSpace.space4,
            vertical: FfSpace.space2,
          ),
          child: Row(
            children: <Widget>[
              Icon(
                clear ? Icons.cloud_done : Icons.cloud_upload,
                color: clear ? colors.success : colors.warning,
              ),
              const SizedBox(width: FfSpace.space3),
              Expanded(
                child: Text(
                  clear ? l10n.mfgSyncAllSent : l10n.mfgSyncPending(pending),
                  style: TextStyle(
                    fontSize: FfFont.lg,
                    fontWeight: FontWeight.w700,
                    color: colors.text,
                  ),
                ),
              ),
              TextButton(
                key: const Key('mfg-sync-now'),
                onPressed: () =>
                    ref.read(shopFloorSyncProvider).syncNow(tenantId),
                child: Text(l10n.mfgSyncNow),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
