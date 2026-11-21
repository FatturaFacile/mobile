import 'package:material_ui/material_ui.dart';

import '../../../design/ff_tokens.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../domain/copilot_models.dart';

/// Human-in-the-loop card: summary, details, editable fields (only `editable_fields`) and
/// thumb-sized Confirm / Cancel buttons.
class ActionCard extends StatefulWidget {
  const ActionCard({
    required this.message,
    required this.strings,
    required this.onConfirm,
    required this.onReject,
    super.key,
  });

  final CopilotMessage message;
  final AppLocalizations strings;
  final Future<void> Function(Map<String, Object?> overrides) onConfirm;
  final Future<void> Function() onReject;

  @override
  State<ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<ActionCard> {
  final Map<String, TextEditingController> _controllers =
      <String, TextEditingController>{};
  bool _submitted = false;

  ProposedAction get _action => widget.message.proposedAction!;

  @override
  void initState() {
    super.initState();
    for (final String path in _action.editableFields) {
      _controllers[path] = TextEditingController(
        text: '${_action.valueAt(path) ?? ''}',
      );
    }
  }

  @override
  void dispose() {
    for (final TextEditingController c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// Only fields the user actually changed, coerced to the original value type.
  Map<String, Object?> _overrides() {
    final Map<String, Object?> out = <String, Object?>{};
    _controllers.forEach((String path, TextEditingController c) {
      final Object? original = _action.valueAt(path);
      final String text = c.text.trim();
      if (text == '${original ?? ''}') return;
      out[path] = switch (original) {
        int() => int.tryParse(text) ?? num.tryParse(text) ?? text,
        num() => num.tryParse(text.replaceAll(',', '.')) ?? text,
        bool() => text == 'true',
        _ => text,
      };
    });
    return out;
  }

  Future<void> _run(Future<void> call) async {
    setState(() => _submitted = true);
    await call;
    if (mounted) setState(() => _submitted = false);
  }

  @override
  void didUpdateWidget(ActionCard old) {
    super.didUpdateWidget(old);
    if (widget.message.actionStatus != ActionStatus.pending) _submitted = false;
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = widget.strings;
    final ActionStatus status = widget.message.actionStatus;
    final bool pending = status == ActionStatus.pending;
    final FfColors c =
        Theme.of(context).extension<FfColors>() ?? FfColors.light;
    final (String, Color, Color) badge = switch (status) {
      ActionStatus.executed => (
        l.copilotActionExecuted,
        c.successBg,
        c.success,
      ),
      ActionStatus.confirmed => (l.copilotActionConfirmed, c.infoBg, c.info),
      ActionStatus.rejected => (
        l.copilotActionRejected,
        c.neutralBg,
        c.neutral,
      ),
      ActionStatus.failed => (l.copilotActionFailed, c.dangerBg, c.danger),
      _ => (l.copilotActionPending, c.warningBg, c.warning),
    };
    return Card(
      key: const Key('action-card'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(FfSpace.space3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    l.copilotActionTitle,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Container(
                  key: const Key('action-status'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: FfSpace.space2,
                    vertical: FfSpace.space1,
                  ),
                  decoration: BoxDecoration(
                    color: badge.$2,
                    borderRadius: BorderRadius.circular(FfRadius.lg),
                  ),
                  child: Text(
                    badge.$1,
                    style: TextStyle(
                      color: badge.$3,
                      fontSize: FfFont.xs,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: FfSpace.space2),
            Text(_action.summary),
            for (final MapEntry<String, dynamic> e in _action.details.entries)
              Padding(
                padding: const EdgeInsets.only(top: FfSpace.space1),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      flex: 2,
                      child: Text(
                        e.key,
                        style: TextStyle(
                          fontSize: FfFont.sm,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        '${e.value}',
                        style: const TextStyle(fontSize: FfFont.sm),
                      ),
                    ),
                  ],
                ),
              ),
            if (pending && _controllers.isNotEmpty) ...<Widget>[
              const SizedBox(height: FfSpace.space3),
              Text(
                l.copilotEditableFields,
                style: const TextStyle(
                  fontSize: FfFont.sm,
                  fontWeight: FontWeight.w600,
                ),
              ),
              for (final MapEntry<String, TextEditingController> e
                  in _controllers.entries)
                Padding(
                  padding: const EdgeInsets.only(top: FfSpace.space2),
                  child: TextField(
                    key: Key('edit-${e.key}'),
                    controller: e.value,
                    keyboardType: _action.valueAt(e.key) is num
                        ? const TextInputType.numberWithOptions(decimal: true)
                        : TextInputType.text,
                    decoration: InputDecoration(
                      labelText: e.key,
                      isDense: true,
                    ),
                  ),
                ),
            ],
            if (status == ActionStatus.failed &&
                _action.error != null) ...<Widget>[
              const SizedBox(height: FfSpace.space2),
              Text(
                _action.error!,
                style: TextStyle(color: c.danger, fontSize: FfFont.sm),
              ),
            ],
            if (pending) ...<Widget>[
              const SizedBox(height: FfSpace.space3),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      key: const Key('action-cancel'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      onPressed: _submitted
                          ? null
                          : () => _run(widget.onReject()),
                      child: Text(l.copilotCancel),
                    ),
                  ),
                  const SizedBox(width: FfSpace.space3),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      key: const Key('action-confirm'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      onPressed: _submitted
                          ? null
                          : () => _run(widget.onConfirm(_overrides())),
                      child: Text(l.copilotConfirm),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
