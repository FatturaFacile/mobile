import 'package:material_ui/material_ui.dart';

import '../../../../design/ff_tokens.dart';
import '../../../../l10n/gen/app_localizations.dart';

/// Modal bottom sheet prompting a manager for a mandatory rejection reason.
class PrRejectBottomSheet extends StatefulWidget {
  const PrRejectBottomSheet({super.key});

  /// Opens the sheet and returns the trimmed non-empty rejection reason, or `null` if cancelled.
  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const PrRejectBottomSheet(),
    );
  }

  @override
  State<PrRejectBottomSheet> createState() => _PrRejectBottomSheetState();
}

class _PrRejectBottomSheetState extends State<PrRejectBottomSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _confirm() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    Navigator.of(context).pop(_reasonController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final FfColors colors =
        Theme.of(context).extension<FfColors>() ?? FfColors.light;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final EdgeInsets insets = MediaQuery.of(context).viewInsets;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          FfSpace.space4,
          FfSpace.space4,
          FfSpace.space4,
          FfSpace.space4 + insets.bottom,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                l10n.prRejectSheetTitle,
                style: TextStyle(
                  color: colors.text,
                  fontSize: FfFont.lg,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: FfSpace.space3),
              TextFormField(
                key: const Key('pr-reject-reason-input'),
                controller: _reasonController,
                autofocus: true,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: l10n.prRejectReasonLabel,
                  hintText: l10n.prRejectReasonHint,
                  border: const OutlineInputBorder(),
                ),
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.prRejectReasonRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: FfSpace.space4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  TextButton(
                    key: const Key('pr-reject-cancel-button'),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.prCancelAction),
                  ),
                  const SizedBox(width: FfSpace.space2),
                  FilledButton(
                    key: const Key('pr-reject-confirm-button'),
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.danger,
                      foregroundColor: colors.onPrimary,
                    ),
                    onPressed: _confirm,
                    child: Text(l10n.prRejectConfirmAction),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
