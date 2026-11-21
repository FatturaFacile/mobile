import 'package:fpdart/fpdart.dart' hide State;
import 'package:material_ui/material_ui.dart';

import '../../../core/error/failure.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../data/pii_unmask_repository.dart';

/// Performs the unmask call for a validated justification.
typedef UnmaskCall = Future<Either<Failure, String>> Function(
  String justification,
);

/// Asks for a justification (>= 10 characters) and reveals the field. Resolves with the revealed
/// value, or `null` when the user cancels.
Future<String?> showPiiUnmaskDialog(
  BuildContext context, {
  required AppLocalizations strings,
  required String field,
  required UnmaskCall onUnmask,
}) {
  return showDialog<String>(
    context: context,
    builder: (BuildContext _) =>
        PiiUnmaskDialog(strings: strings, field: field, onUnmask: onUnmask),
  );
}

class PiiUnmaskDialog extends StatefulWidget {
  const PiiUnmaskDialog({
    required this.strings,
    required this.field,
    required this.onUnmask,
    super.key,
  });

  final AppLocalizations strings;
  final String field;
  final UnmaskCall onUnmask;

  @override
  State<PiiUnmaskDialog> createState() => _PiiUnmaskDialogState();
}

class _PiiUnmaskDialogState extends State<PiiUnmaskDialog> {
  final TextEditingController _justification = TextEditingController();
  bool _touched = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _justification.dispose();
    super.dispose();
  }

  bool get _valid => isValidJustification(_justification.text);

  Future<void> _submit() async {
    if (!_valid || _busy) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final Either<Failure, String> result = await widget.onUnmask(
      _justification.text.trim(),
    );
    if (!mounted) {
      return;
    }
    result.match(
      (Failure f) => setState(() {
        _busy = false;
        _error = f is ForbiddenFailure
            ? widget.strings.piiUnmaskForbidden
            : widget.strings.piiUnmaskFailed;
      }),
      (String value) => Navigator.of(context).pop(value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = widget.strings;
    return AlertDialog(
      key: const Key('pii-unmask-dialog'),
      title: Text(l.piiUnmaskTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(l.piiUnmaskBody(widget.field)),
          const SizedBox(height: 12),
          TextField(
            key: const Key('pii-justification'),
            controller: _justification,
            minLines: 2,
            maxLines: 4,
            enabled: !_busy,
            onChanged: (_) => setState(() => _touched = true),
            decoration: InputDecoration(
              labelText: l.piiJustificationLabel,
              errorText: _touched && !_valid
                  ? l.piiJustificationTooShort
                  : _error,
            ),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          key: const Key('pii-cancel'),
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: Text(l.piiUnmaskCancel),
        ),
        FilledButton(
          key: const Key('pii-confirm'),
          onPressed: _valid && !_busy ? _submit : null,
          child: Text(l.piiUnmaskConfirm),
        ),
      ],
    );
  }
}

/// Masked value with a reveal button that goes through [showPiiUnmaskDialog].
class PiiMaskedField extends StatefulWidget {
  const PiiMaskedField({
    required this.strings,
    required this.field,
    required this.masked,
    required this.onUnmask,
    super.key,
  });

  final AppLocalizations strings;
  final String field;
  final String masked;
  final UnmaskCall onUnmask;

  @override
  State<PiiMaskedField> createState() => _PiiMaskedFieldState();
}

class _PiiMaskedFieldState extends State<PiiMaskedField> {
  String? _revealed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(_revealed ?? widget.masked, key: const Key('pii-value')),
        if (_revealed == null)
          IconButton(
            key: const Key('pii-reveal'),
            tooltip: widget.strings.piiUnmaskDemo,
            icon: const Icon(Icons.visibility_outlined),
            onPressed: () async {
              final String? value = await showPiiUnmaskDialog(
                context,
                strings: widget.strings,
                field: widget.field,
                onUnmask: widget.onUnmask,
              );
              if (value != null && mounted) {
                setState(() => _revealed = value);
              }
            },
          ),
      ],
    );
  }
}
