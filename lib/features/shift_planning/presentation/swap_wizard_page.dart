import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/providers.dart';
import '../../../core/localization/translation_service.dart';
import '../../../design/ff_tokens.dart';
import '../domain/shift_models.dart';
import '../domain/shift_repository.dart';
import 'shift_controller.dart';
import 'shift_pages.dart' show issueText, shiftErrorMessage, shiftTimeRange;
import 'shift_strings.dart';

/// Step-by-step swap: pick the shift, pick an eligible colleague (or broadcast to every qualified one), optionally pick a
/// shift in exchange, review and send.
class SwapWizardPage extends ConsumerWidget {
  const SwapWizardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ShiftStrings s = ShiftStrings(
      ref.watch(requestContextProvider).languageCode,
    );
    final SwapWizardState state = ref.watch(swapWizardProvider);
    final List<String> titles = <String>[
      s(SL.stepShift),
      s(SL.stepColleague),
      s(SL.stepExchange),
      s(SL.stepReview),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(s(SL.swapWizardTitle))),
      body: state.result != null
          ? _Done(strings: s)
          : Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(FfSpace.space3),
                  child: Text(
                    '${state.step + 1}/4 · ${titles[state.step]}',
                    key: const Key('swap-step'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                LinearProgressIndicator(value: (state.step + 1) / 4),
                Expanded(child: _body(context, ref, state, s)),
                _controls(ref, state, s),
              ],
            ),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    SwapWizardState state,
    ShiftStrings s,
  ) {
    return switch (state.step) {
      swapStepShift => _ShiftStep(state: state, strings: s),
      swapStepColleague => _ColleagueStep(state: state, strings: s),
      swapStepExchange => _ExchangeStep(state: state, strings: s),
      _ => _ReviewStep(state: state, strings: s),
    };
  }

  Widget _controls(WidgetRef ref, SwapWizardState state, ShiftStrings s) {
    final SwapWizardController c = ref.read(swapWizardProvider.notifier);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(FfSpace.space3),
        child: Row(
          children: <Widget>[
            if (state.step > swapStepShift)
              OutlinedButton(
                key: const Key('swap-back'),
                onPressed: state.submitting ? null : c.back,
                child: Text(s(SL.back)),
              ),
            const Spacer(),
            if (state.step == swapStepReview)
              FilledButton(
                key: const Key('swap-send'),
                onPressed: state.submitting ? null : c.submit,
                child: state.submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(s(SL.sendRequest)),
              )
            else
              FilledButton(
                key: const Key('swap-next'),
                onPressed: state.canAdvance ? c.next : null,
                child: Text(s(SL.next)),
              ),
          ],
        ),
      ),
    );
  }
}

class _Done extends StatelessWidget {
  const _Done({required this.strings});

  final ShiftStrings strings;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(FfSpace.space5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.check_circle_outline, size: 48),
            const SizedBox(height: FfSpace.space3),
            Text(strings(SL.requestSent), key: const Key('swap-done')),
            const SizedBox(height: FfSpace.space4),
            FilledButton(
              key: const Key('swap-close'),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(strings(SL.tabSwaps)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Step 1: the shift to give away (preselected when the wizard opens from a calendar card).
class _ShiftStep extends ConsumerWidget {
  const _ShiftStep({required this.state, required this.strings});

  final SwapWizardState state;
  final ShiftStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String language = ref.watch(requestContextProvider).languageCode;
    final DateTime now = DateTime.now().toUtc();
    final List<Shift> own = ref
        .watch(shiftCalendarProvider)
        .mine
        .where((Shift s) => s.employeeId != null && s.startAt.isAfter(now))
        .toList();
    final TranslationService t = ref.watch(translationProvider);
    return ListView(
      padding: const EdgeInsets.all(FfSpace.space3),
      children: <Widget>[
        Text(strings(SL.chooseShift)),
        if (state.error != null)
          Padding(
            padding: const EdgeInsets.only(top: FfSpace.space2),
            child: Text(
              shiftErrorMessage(strings, t, state.error!),
              key: const Key('swap-error'),
            ),
          ),
        if (state.peersLoading) const LinearProgressIndicator(),
        for (final Shift shift in own)
          ListTile(
            key: Key('swap-shift-${shift.id}'),
            selected: state.shift?.id == shift.id,
            leading: Icon(
              state.shift?.id == shift.id
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
            ),
            title: Text(
              '${shift.date} · ${shift.templateCode} · ${shift.label(language)}',
            ),
            subtitle: Text(shiftTimeRange(shift)),
            onTap: () =>
                ref.read(swapWizardProvider.notifier).selectShift(shift),
          ),
      ],
    );
  }
}

/// Step 2: one eligible colleague, or every qualified colleague.
class _ColleagueStep extends ConsumerWidget {
  const _ColleagueStep({required this.state, required this.strings});

  final SwapWizardState state;
  final ShiftStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SwapWizardController c = ref.read(swapWizardProvider.notifier);
    final TranslationService t = ref.watch(translationProvider);
    return ListView(
      padding: const EdgeInsets.all(FfSpace.space3),
      children: <Widget>[
        Text(strings(SL.chooseColleague)),
        ListTile(
          key: const Key('swap-broadcast'),
          selected: state.broadcast,
          leading: Icon(
            state.broadcast
                ? Icons.radio_button_checked
                : Icons.radio_button_off,
          ),
          title: Text(strings(SL.anyColleague)),
          onTap: c.chooseBroadcast,
        ),
        if (state.peers.isEmpty)
          Padding(
            padding: const EdgeInsets.all(FfSpace.space3),
            child: Text(
              strings(SL.noColleagues),
              key: const Key('swap-no-peers'),
            ),
          ),
        for (final SwapPeer peer in state.peers)
          ListTile(
            key: Key('swap-peer-${peer.employeeId}'),
            selected: state.peerId == peer.employeeId,
            leading: Icon(
              state.peerId == peer.employeeId
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
            ),
            title: Text(peer.name),
            subtitle: peer.warnings.isEmpty
                ? null
                : Text(
                    peer.warnings
                        .map((ComplianceIssue w) => issueText(t, w))
                        .join('\n'),
                  ),
            onTap: () => c.choosePeer(peer.employeeId),
          ),
      ],
    );
  }
}

/// Step 3: optionally one of the colleague's shifts in exchange.
class _ExchangeStep extends ConsumerWidget {
  const _ExchangeStep({required this.state, required this.strings});

  final SwapWizardState state;
  final ShiftStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SwapWizardController c = ref.read(swapWizardProvider.notifier);
    final List<PeerShift> shifts = state.peer?.shifts ?? const <PeerShift>[];
    return ListView(
      padding: const EdgeInsets.all(FfSpace.space3),
      children: <Widget>[
        Text(strings(SL.chooseExchange)),
        ListTile(
          key: const Key('swap-no-exchange'),
          selected: state.counterShiftId == null,
          leading: Icon(
            state.counterShiftId == null
                ? Icons.radio_button_checked
                : Icons.radio_button_off,
          ),
          title: Text(strings(SL.noExchange)),
          onTap: () => c.chooseCounter(null),
        ),
        if (shifts.isEmpty)
          Padding(
            padding: const EdgeInsets.all(FfSpace.space3),
            child: Text(strings(SL.noSwaps), key: const Key('swap-no-counter')),
          ),
        for (final PeerShift shift in shifts)
          ListTile(
            key: Key('swap-counter-${shift.id}'),
            selected: state.counterShiftId == shift.id,
            leading: Icon(
              state.counterShiftId == shift.id
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
            ),
            title: Text('${shift.date} · ${shift.templateCode}'),
            subtitle: Text('${_hhmm(shift.startAt)}-${_hhmm(shift.endAt)}'),
            onTap: () => c.chooseCounter(shift.id),
          ),
      ],
    );
  }

  static String _hhmm(DateTime utc) {
    final DateTime l = utc.toLocal();
    return '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
  }
}

/// Step 4: what is going to be sent, and the refusal of the server when a rule is broken.
class _ReviewStep extends ConsumerWidget {
  const _ReviewStep({required this.state, required this.strings});

  final SwapWizardState state;
  final ShiftStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String language = ref.watch(requestContextProvider).languageCode;
    final TranslationService t = ref.watch(translationProvider);
    final Shift? shift = state.shift;
    final ShiftException? error = state.error;
    return ListView(
      padding: const EdgeInsets.all(FfSpace.space3),
      children: <Widget>[
        Text(
          strings(SL.reviewTitle),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (shift != null)
          ListTile(
            title: Text(
              '${shift.date} · ${shift.templateCode} · ${shift.label(language)}',
            ),
            subtitle: Text(shiftTimeRange(shift)),
          ),
        ListTile(
          key: const Key('swap-review-peer'),
          leading: const Icon(Icons.swap_horiz),
          title: Text(
            state.broadcast
                ? strings(SL.anyColleague)
                : (state.peer?.name ?? ''),
          ),
          subtitle: state.counterShiftId == null
              ? Text(strings(SL.noExchange))
              : null,
        ),
        if (error != null) ...<Widget>[
          const SizedBox(height: FfSpace.space3),
          Text(
            strings(SL.warningsTitle),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          if (error.issues.isEmpty)
            Text(
              shiftErrorMessage(strings, t, error),
              key: const Key('swap-error'),
            )
          else
            for (final ComplianceIssue i in error.issues)
              Text(issueText(t, i), key: Key('swap-issue-${i.ruleCode}')),
        ],
      ],
    );
  }
}
