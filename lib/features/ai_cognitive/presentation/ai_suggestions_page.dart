import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/providers.dart';
import '../../../design/ff_tokens.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../copilot/presentation/copilot_controller.dart' show copilotStrings;
import '../domain/ai_models.dart';
import '../domain/ai_repository.dart';
import 'ai_controller.dart';

/// Localized label of a suggestion kind; unknown kinds fall back to a neutral "Suggestion".
String aiKindLabel(AppLocalizations l, String kind) => switch (kind) {
  'sales_quote' => l.cogKindSalesQuote,
  'purchase_order' => l.cogKindPurchaseOrder,
  'support_ticket' => l.cogKindSupportTicket,
  'contact' => l.cogKindContact,
  'accounting_coding' => l.cogKindAccountingCoding,
  'reconciliation_match' => l.cogKindReconciliationMatch,
  'anomaly' => l.cogKindAnomaly,
  'late_payment_risk' => l.cogKindLatePaymentRisk,
  'churn_risk' => l.cogKindChurnRisk,
  'reorder' => l.cogKindReorder,
  'cash_flow_alert' => l.cogKindCashFlowAlert,
  _ => l.cogKindOther,
};

String _captureKindLabel(AppLocalizations l, CaptureKind k) =>
    aiKindLabel(l, k.wire);

String aiErrorMessage(AppLocalizations l, AiException e) => switch (e.kind) {
  AiErrorKind.forbidden => l.cogErrForbidden,
  AiErrorKind.notFound => l.cogErrNotFound,
  AiErrorKind.alreadyDecided => l.cogErrAlreadyDecided,
  AiErrorKind.invalid => l.cogErrInvalid(e.detail),
  AiErrorKind.rateLimited => l.cogErrRateLimited,
  AiErrorKind.unavailable => l.cogErrProvider,
  AiErrorKind.offline => l.cogErrOffline,
  AiErrorKind.unknown => l.cogErrUnknown,
};

/// Capture box, offline capture status and the list of open suggestions with Approve / Reject.
class AiSuggestionsPage extends ConsumerStatefulWidget {
  const AiSuggestionsPage({super.key});

  @override
  ConsumerState<AiSuggestionsPage> createState() => _AiSuggestionsPageState();
}

class _AiSuggestionsPageState extends ConsumerState<AiSuggestionsPage> {
  final TextEditingController _text = TextEditingController();
  CaptureKind _kind = CaptureKind.salesQuote;
  String? _textError;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(aiSuggestionsProvider.notifier).load(),
    );
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  AppLocalizations get _l =>
      copilotStrings(ref.read(requestContextProvider).languageCode);

  void _toast(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _send() async {
    final AppLocalizations l = _l;
    final CaptureOutcome outcome = await ref
        .read(aiSuggestionsProvider.notifier)
        .capture(_kind, _text.text);
    if (!mounted) {
      return;
    }
    switch (outcome.status) {
      case CaptureStatus.tooShort:
        setState(() => _textError = l.cogTextTooShort);
      case CaptureStatus.sent:
        setState(() => _textError = null);
        _text.clear();
        _toast(l.cogCaptureSent);
      case CaptureStatus.queued:
        setState(() => _textError = null);
        _text.clear();
        _toast(l.cogCaptureQueued);
      case CaptureStatus.rejected:
        setState(() => _textError = null);
        _text.clear();
        _toast(l.cogCaptureRejected(outcome.detail));
    }
  }

  Future<void> _dictate() async {
    final String locale = ref.read(requestContextProvider).languageCode;
    final String? heard = await ref
        .read(dictationProvider)
        .listen(locale: locale);
    if (heard != null && heard.trim().isNotEmpty && mounted) {
      _text.text = _text.text.isEmpty
          ? heard.trim()
          : '${_text.text.trim()} ${heard.trim()}';
    }
  }

  Future<void> _approve(Suggestion s) async {
    final AppLocalizations l = _l;
    final AiException? error = await ref
        .read(aiSuggestionsProvider.notifier)
        .approve(s.id);
    if (mounted) {
      _toast(error == null ? l.cogApproved : aiErrorMessage(l, error));
    }
  }

  Future<void> _reject(Suggestion s) async {
    final AppLocalizations l = _l;
    final String? reason = await showDialog<String>(
      context: context,
      builder: (BuildContext _) => _RejectDialog(strings: l),
    );
    if (reason == null || !mounted) {
      return;
    }
    final AiException? error = await ref
        .read(aiSuggestionsProvider.notifier)
        .reject(s.id, reason);
    if (mounted) {
      _toast(error == null ? l.cogRejected : aiErrorMessage(l, error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = copilotStrings(
      ref.watch(requestContextProvider).languageCode,
    );
    final AiSuggestionsState state = ref.watch(aiSuggestionsProvider);
    final DictationService dictation = ref.watch(dictationProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.cogTitle)),
      body: state.forbidden
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(FfSpace.space5),
                child: Text(
                  l.cogErrForbidden,
                  key: const Key('ai-forbidden'),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: () => ref.read(aiSuggestionsProvider.notifier).load(),
              child: ListView(
                padding: const EdgeInsets.all(FfSpace.space4),
                children: <Widget>[
                  _captureCard(l, dictation),
                  if (state.queue.waiting > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: FfSpace.space3),
                      child: Text(
                        l.cogQueuedCount(state.queue.waiting),
                        key: const Key('ai-queued'),
                      ),
                    ),
                  for (final RejectedCapture r in state.queue.rejected)
                    _rejectedCapture(l, r),
                  if (state.fromCache)
                    Padding(
                      padding: const EdgeInsets.only(top: FfSpace.space3),
                      child: Text(
                        l.cogOfflineCached,
                        key: const Key('ai-cached'),
                      ),
                    ),
                  if (state.error != null &&
                      !state.fromCache &&
                      state.suggestions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: FfSpace.space3),
                      child: Text(
                        aiErrorMessage(l, state.error!),
                        key: const Key('ai-error'),
                      ),
                    ),
                  const SizedBox(height: FfSpace.space3),
                  if (state.loading && state.suggestions.isEmpty)
                    const Center(child: CircularProgressIndicator())
                  else if (state.suggestions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(FfSpace.space5),
                      child: Center(
                        child: Text(l.cogEmpty, key: const Key('ai-empty')),
                      ),
                    )
                  else
                    for (final Suggestion s in state.suggestions)
                      SuggestionCard(
                        suggestion: s,
                        strings: l,
                        busy: state.busyIds.contains(s.id),
                        onApprove: () => _approve(s),
                        onReject: () => _reject(s),
                      ),
                ],
              ),
            ),
    );
  }

  Widget _captureCard(AppLocalizations l, DictationService dictation) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(FfSpace.space3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextField(
              key: const Key('ai-text'),
              controller: _text,
              minLines: 2,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: l.cogCaptureHint,
                errorText: _textError,
              ),
            ),
            const SizedBox(height: FfSpace.space2),
            Row(
              children: <Widget>[
                Text(l.cogKindLabel),
                const SizedBox(width: FfSpace.space2),
                Expanded(
                  child: DropdownButton<CaptureKind>(
                    key: const Key('ai-kind'),
                    value: _kind,
                    isExpanded: true,
                    items: <DropdownMenuItem<CaptureKind>>[
                      for (final CaptureKind k in CaptureKind.values)
                        DropdownMenuItem<CaptureKind>(
                          value: k,
                          child: Text(_captureKindLabel(l, k)),
                        ),
                    ],
                    onChanged: (CaptureKind? k) =>
                        setState(() => _kind = k ?? _kind),
                  ),
                ),
                if (dictation.available)
                  IconButton(
                    key: const Key('ai-dictate'),
                    tooltip: l.cogDictate,
                    icon: const Icon(Icons.mic),
                    onPressed: _dictate,
                  ),
                FilledButton(
                  key: const Key('ai-send'),
                  onPressed: _send,
                  child: Text(l.cogSend),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _rejectedCapture(AppLocalizations l, RejectedCapture r) {
    final FfColors c = Theme.of(context).extension<FfColors>()!;
    return Container(
      key: Key('ai-rejected-${r.queueUuid}'),
      margin: const EdgeInsets.only(top: FfSpace.space3),
      padding: const EdgeInsets.all(FfSpace.space3),
      decoration: BoxDecoration(
        color: c.dangerBg,
        borderRadius: BorderRadius.circular(FfRadius.md),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              l.cogCaptureRejected(r.detail),
              style: TextStyle(color: c.danger),
            ),
          ),
          TextButton(
            key: Key('ai-dismiss-${r.queueUuid}'),
            onPressed: () => ref
                .read(aiSuggestionsProvider.notifier)
                .dismissCapture(r.queueUuid),
            child: Text(l.cogDismiss),
          ),
        ],
      ),
    );
  }
}

/// Colored pill with the confidence band (`>= 0.90` high, `>= 0.70` medium, else low) and percentage.
class ConfidenceBadge extends StatelessWidget {
  const ConfidenceBadge({
    required this.confidence,
    required this.strings,
    super.key,
  });

  final double confidence;
  final AppLocalizations strings;

  @override
  Widget build(BuildContext context) {
    final FfColors c = Theme.of(context).extension<FfColors>()!;
    final ConfidenceBand band = ConfidenceBand.of(confidence);
    final (Color fg, Color bg, String label) = switch (band) {
      ConfidenceBand.high => (
        c.success,
        c.successBg,
        strings.cogConfidenceHigh,
      ),
      ConfidenceBand.medium => (
        c.warning,
        c.warningBg,
        strings.cogConfidenceMedium,
      ),
      ConfidenceBand.low => (c.danger, c.dangerBg, strings.cogConfidenceLow),
    };
    return Semantics(
      label: '$label, ${strings.cogConfidence((confidence * 100).round())}',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: FfSpace.space2,
          vertical: FfSpace.space1,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(FfRadius.md),
        ),
        child: Text(
          '$label ${(confidence * 100).round()}%',
          style: TextStyle(color: fg, fontSize: FfFont.xs),
        ),
      ),
    );
  }
}

class SuggestionCard extends StatelessWidget {
  const SuggestionCard({
    required this.suggestion,
    required this.strings,
    required this.onApprove,
    required this.onReject,
    this.busy = false,
    super.key,
  });

  final Suggestion suggestion;
  final AppLocalizations strings;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final Suggestion s = suggestion;
    final String? reasoning = s.reasoning;
    return Card(
      key: Key('sugg-${s.id}'),
      child: Padding(
        padding: const EdgeInsets.all(FfSpace.space3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    aiKindLabel(strings, s.kind),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                if (s.priority == SuggestionPriority.high)
                  Padding(
                    padding: const EdgeInsets.only(right: FfSpace.space2),
                    child: Icon(
                      Icons.priority_high,
                      key: Key('priority-${s.id}'),
                      size: 18,
                      semanticLabel: strings.cogPriorityHigh,
                    ),
                  ),
                ConfidenceBadge(
                  key: Key('badge-${s.id}'),
                  confidence: s.confidence,
                  strings: strings,
                ),
              ],
            ),
            if (s.amount != null) Text(s.amount!.toStringAsFixed(2)),
            if (reasoning != null && reasoning.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: FfSpace.space2),
                child: Text(reasoning),
              ),
            const SizedBox(height: FfSpace.space2),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                TextButton(
                  key: Key('reject-${s.id}'),
                  onPressed: busy ? null : onReject,
                  child: Text(strings.cogReject),
                ),
                const SizedBox(width: FfSpace.space2),
                FilledButton(
                  key: Key('approve-${s.id}'),
                  onPressed: busy ? null : onApprove,
                  child: Text(strings.cogApprove),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Asks for the rejection reason (at least 3 characters) and pops it, or `null` on cancel.
class _RejectDialog extends StatefulWidget {
  const _RejectDialog({required this.strings});

  final AppLocalizations strings;

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final TextEditingController _reason = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _submit() {
    final String reason = _reason.text.trim();
    if (reason.length < 3) {
      setState(() => _error = widget.strings.cogReasonTooShort);
      return;
    }
    Navigator.of(context).pop(reason);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = widget.strings;
    return AlertDialog(
      title: Text(l.cogRejectTitle),
      content: TextField(
        key: const Key('reject-reason'),
        controller: _reason,
        autofocus: true,
        decoration: InputDecoration(
          labelText: l.cogRejectReason,
          errorText: _error,
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.cogCancel),
        ),
        FilledButton(
          key: const Key('reject-confirm'),
          onPressed: _submit,
          child: Text(l.cogReject),
        ),
      ],
    );
  }
}

/// Prominent alert for the newest pending high-priority anomaly. Renders nothing otherwise.
/// Loads the queue once when it first appears (the app has no push channel wired, see report).
class AiAlertBanner extends ConsumerStatefulWidget {
  const AiAlertBanner({required this.onOpen, super.key});

  final VoidCallback onOpen;

  @override
  ConsumerState<AiAlertBanner> createState() => _AiAlertBannerState();
}

class _AiAlertBannerState extends ConsumerState<AiAlertBanner> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(aiSuggestionsProvider.notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Suggestion? alert = ref.watch(
      aiSuggestionsProvider.select((AiSuggestionsState s) => s.alert),
    );
    if (alert == null) {
      return const SizedBox.shrink();
    }
    final AppLocalizations l = copilotStrings(
      ref.watch(requestContextProvider).languageCode,
    );
    final FfColors c = Theme.of(context).extension<FfColors>()!;
    return Semantics(
      liveRegion: true,
      child: Material(
        key: const Key('ai-alert-banner'),
        color: c.dangerBg,
        child: InkWell(
          onTap: widget.onOpen,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: FfSpace.space4,
              vertical: FfSpace.space3,
            ),
            child: Row(
              children: <Widget>[
                Icon(Icons.warning_amber_rounded, color: c.danger),
                const SizedBox(width: FfSpace.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        l.cogAlertTitle,
                        style: TextStyle(
                          color: c.danger,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if ((alert.reasoning ?? '').isNotEmpty)
                        Text(
                          alert.reasoning!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: widget.onOpen,
                  child: Text(l.cogAlertReview),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
