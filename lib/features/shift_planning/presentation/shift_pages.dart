import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/providers.dart';
import '../../../core/localization/translation_service.dart';
import '../../../design/ff_tokens.dart';
import '../domain/shift_models.dart';
import '../domain/shift_repository.dart';
import 'shift_controller.dart';
import 'shift_strings.dart';
import 'swap_wizard_page.dart';

/// RBAC module key of the employee self-service (agenda, open shifts, swaps).
const String shiftSelfServiceModule = 'shift_planning_self';

/// Text of one compliance finding: the API dictionary entry, or the stable rule code while the dictionary lacks it.
String issueText(TranslationService t, ComplianceIssue issue) {
  final String text = t.t(issue.translationKey, params: issue.params);
  return text.isEmpty ? issue.ruleCode : text;
}

/// User-facing message of a failed call. A rule violation names the first blocking rule, then the server detail.
String shiftErrorMessage(
  ShiftStrings s,
  TranslationService t,
  ShiftException e,
) {
  switch (e.kind) {
    case ShiftErrorKind.invalid:
      ComplianceIssue? first;
      for (final ComplianceIssue i in e.issues) {
        if (i.isBlocking) {
          first = i;
          break;
        }
      }
      first ??= e.issues.isEmpty ? null : e.issues.first;
      if (first != null) {
        return issueText(t, first);
      }
      return e.detail.isEmpty ? s(SL.errorInvalid) : e.detail;
    case ShiftErrorKind.forbidden:
      return s(SL.errorForbidden);
    case ShiftErrorKind.notFound:
      return s(SL.errorNotFound);
    case ShiftErrorKind.conflict:
      return s(SL.errorConflict);
    case ShiftErrorKind.offline:
      return s(SL.errorOffline);
    case ShiftErrorKind.unknown:
      return s(SL.errorUnknown);
  }
}

String _two(int n) => n.toString().padLeft(2, '0');

String _clock(DateTime utc) {
  final DateTime l = utc.toLocal();
  return '${_two(l.hour)}:${_two(l.minute)}';
}

/// `HH:mm-HH:mm` of a shift in the time zone of the device.
String shiftTimeRange(Shift s) => '${_clock(s.startAt)}-${_clock(s.endAt)}';

Color _colorOf(String hex) {
  final String h = hex.replaceFirst('#', '');
  final int? value = int.tryParse(h.length == 6 ? 'FF$h' : h, radix: 16);
  return Color(value ?? 0xFF1890FF);
}

/// Employee self-service: personal and team calendar, open shifts marketplace and shift swaps.
class ShiftHomePage extends ConsumerWidget {
  const ShiftHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ShiftStrings s = ShiftStrings(
      ref.watch(requestContextProvider).languageCode,
    );
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(s(SL.title)),
          bottom: TabBar(
            tabs: <Widget>[
              Tab(key: const Key('tab-calendar'), text: s(SL.tabCalendar)),
              Tab(key: const Key('tab-open'), text: s(SL.tabOpen)),
              Tab(key: const Key('tab-swaps'), text: s(SL.tabSwaps)),
            ],
          ),
        ),
        body: const TabBarView(
          children: <Widget>[ShiftCalendarTab(), OpenShiftsTab(), SwapsTab()],
        ),
      ),
    );
  }
}

// --- Calendar --------------------------------------------------------------------------------------------------

class ShiftCalendarTab extends ConsumerStatefulWidget {
  const ShiftCalendarTab({super.key});

  @override
  ConsumerState<ShiftCalendarTab> createState() => _ShiftCalendarTabState();
}

class _ShiftCalendarTabState extends ConsumerState<ShiftCalendarTab> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(shiftCalendarProvider.notifier).load(),
    );
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _export(String language, ShiftStrings s) async {
    await ref.read(shiftCalendarProvider.notifier).exportIcs(language);
    if (mounted) {
      _toast(s(SL.exportDone));
    }
  }

  @override
  Widget build(BuildContext context) {
    final String language = ref.watch(requestContextProvider).languageCode;
    final ShiftStrings s = ShiftStrings(language);
    final TranslationService t = ref.watch(translationProvider);
    final ShiftCalendarState state = ref.watch(shiftCalendarProvider);
    if (state.forbidden) {
      return Center(
        child: Text(s(SL.errorForbidden), key: const Key('shift-forbidden')),
      );
    }
    final List<Shift> shifts = state.visible;
    return RefreshIndicator(
      onRefresh: () => ref.read(shiftCalendarProvider.notifier).load(),
      child: ListView(
        padding: const EdgeInsets.all(FfSpace.space4),
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: SegmentedButton<bool>(
                  key: const Key('shift-scope'),
                  segments: <ButtonSegment<bool>>[
                    ButtonSegment<bool>(value: false, label: Text(s(SL.mine))),
                    ButtonSegment<bool>(value: true, label: Text(s(SL.team))),
                  ],
                  selected: <bool>{state.showTeam},
                  onSelectionChanged: (Set<bool> v) => ref
                      .read(shiftCalendarProvider.notifier)
                      .setShowTeam(v.first),
                ),
              ),
              IconButton(
                key: const Key('shift-export'),
                tooltip: s(SL.exportIcs),
                icon: const Icon(Icons.event_available_outlined),
                onPressed: state.mine.isEmpty
                    ? null
                    : () => _export(language, s),
              ),
            ],
          ),
          if (state.fromCache)
            Padding(
              padding: const EdgeInsets.only(top: FfSpace.space3),
              child: Text(s(SL.offlineCopy), key: const Key('shift-cached')),
            ),
          if (state.error != null && !state.fromCache && shifts.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: FfSpace.space3),
              child: Text(
                shiftErrorMessage(s, t, state.error!),
                key: const Key('shift-error'),
              ),
            ),
          const SizedBox(height: FfSpace.space3),
          if (state.loading && shifts.isEmpty)
            const Center(child: CircularProgressIndicator())
          else if (shifts.isEmpty)
            Padding(
              padding: const EdgeInsets.all(FfSpace.space5),
              child: Center(
                child: Text(s(SL.noShifts), key: const Key('shift-empty')),
              ),
            )
          else
            ..._agenda(shifts, s, language),
        ],
      ),
    );
  }

  List<Widget> _agenda(List<Shift> shifts, ShiftStrings s, String language) {
    final List<Widget> out = <Widget>[];
    String? day;
    for (final Shift shift in shifts) {
      if (shift.date != day) {
        day = shift.date;
        final DateTime date = DateTime.parse(shift.date);
        out.add(
          Padding(
            padding: const EdgeInsets.only(
              top: FfSpace.space3,
              bottom: FfSpace.space1,
            ),
            child: Text(
              MaterialLocalizations.of(context).formatFullDate(date),
              key: Key('shift-day-${shift.date}'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        );
      }
      out.add(
        ShiftCard(
          shift: shift,
          strings: s,
          language: language,
          onSwap: _swapOf(shift),
        ),
      );
    }
    return out;
  }

  /// Only the own, future shifts can be offered to a colleague.
  VoidCallback? _swapOf(Shift shift) {
    final ShiftCalendarState state = ref.read(shiftCalendarProvider);
    final bool own =
        shift.employeeId != null && shift.employeeId == state.myEmployeeId;
    if (!own || !shift.startAt.isAfter(DateTime.now().toUtc())) {
      return null;
    }
    return () {
      ref.read(swapWizardProvider.notifier).reset();
      ref.read(swapWizardProvider.notifier).selectShift(shift);
      Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const SwapWizardPage()));
    };
  }
}

/// One shift: template, time, surcharge tags, warnings, and the actions of the calendar menu.
class ShiftCard extends ConsumerWidget {
  const ShiftCard({
    required this.shift,
    required this.strings,
    required this.language,
    this.onSwap,
    this.trailing,
    super.key,
  });

  final Shift shift;
  final ShiftStrings strings;
  final String language;

  /// Starts the swap wizard for this shift; null hides the menu entry.
  final VoidCallback? onSwap;

  /// Replaces the menu (the marketplace shows a claim button instead).
  final Widget? trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TranslationService t = ref.watch(translationProvider);
    final String? who = shift.employeeName;
    return Card(
      key: Key('shift-card-${shift.id}'),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(width: 6, color: _colorOf(shift.colorHex)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(FfSpace.space3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '${shift.templateCode} · ${shift.label(language)}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(shiftTimeRange(shift)),
                    if (who != null)
                      Text(who, key: Key('shift-who-${shift.id}')),
                    if (shift.tags.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: FfSpace.space1),
                        child: Wrap(
                          spacing: FfSpace.space1,
                          children: <Widget>[
                            for (final SurchargeTag tag in shift.tags)
                              Chip(
                                key: Key('shift-tag-${shift.id}-${tag.wire}'),
                                label: Text(strings.tag(tag.wire)),
                                visualDensity: VisualDensity.compact,
                              ),
                          ],
                        ),
                      ),
                    for (final ComplianceIssue w in shift.warnings.where(
                      (ComplianceIssue i) => !i.isBlocking,
                    ))
                      Padding(
                        padding: const EdgeInsets.only(top: FfSpace.space1),
                        child: Text(
                          '${strings(SL.warningsTitle)}: ${issueText(t, w)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (trailing != null)
              Padding(
                padding: const EdgeInsets.all(FfSpace.space2),
                child: Center(child: trailing),
              )
            else if (shift.employeeName == null)
              PopupMenuButton<String>(
                key: Key('shift-menu-${shift.id}'),
                onSelected: (String action) {
                  if (action == 'google') {
                    ref
                        .read(shiftCalendarProvider.notifier)
                        .addToGoogleCalendar(shift, language);
                  } else if (action == 'swap') {
                    onSwap?.call();
                  }
                },
                itemBuilder: (BuildContext _) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'google',
                    child: Text(strings(SL.addToGoogle)),
                  ),
                  if (onSwap != null)
                    PopupMenuItem<String>(
                      value: 'swap',
                      child: Text(strings(SL.startSwap)),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// --- Open shifts -----------------------------------------------------------------------------------------------

class OpenShiftsTab extends ConsumerStatefulWidget {
  const OpenShiftsTab({super.key});

  @override
  ConsumerState<OpenShiftsTab> createState() => _OpenShiftsTabState();
}

class _OpenShiftsTabState extends ConsumerState<OpenShiftsTab> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() => ref.read(openShiftsProvider.notifier).load());
  }

  Future<void> _claim(Shift shift, ShiftStrings s) async {
    final ClaimOutcome outcome = await ref
        .read(openShiftsProvider.notifier)
        .claim(shift.id);
    if (!mounted) {
      return;
    }
    final String message = switch (outcome.status) {
      ClaimStatus.claimed => s(SL.claimed),
      ClaimStatus.queued => s(SL.claimQueued),
      ClaimStatus.rejected => '${s(SL.claimRejected)}: ${outcome.detail}',
    };
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final String language = ref.watch(requestContextProvider).languageCode;
    final ShiftStrings s = ShiftStrings(language);
    final TranslationService t = ref.watch(translationProvider);
    final OpenShiftsState state = ref.watch(openShiftsProvider);
    return RefreshIndicator(
      onRefresh: () => ref.read(openShiftsProvider.notifier).load(),
      child: ListView(
        padding: const EdgeInsets.all(FfSpace.space4),
        children: <Widget>[
          Text(
            s(SL.openShiftsTitle),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (state.fromCache)
            Padding(
              padding: const EdgeInsets.only(top: FfSpace.space2),
              child: Text(s(SL.offlineCopy), key: const Key('open-cached')),
            ),
          if (state.error != null && !state.fromCache && state.shifts.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: FfSpace.space2),
              child: Text(
                shiftErrorMessage(s, t, state.error!),
                key: const Key('open-error'),
              ),
            ),
          for (final RejectedClaim r in state.queue.rejected)
            Card(
              key: Key('claim-rejected-${r.queueUuid}'),
              child: ListTile(
                title: Text('${s(SL.claimRejected)}: ${r.detail}'),
                trailing: Wrap(
                  children: <Widget>[
                    TextButton(
                      key: Key('claim-retry-${r.queueUuid}'),
                      onPressed: () => ref
                          .read(openShiftsProvider.notifier)
                          .retryClaim(r.queueUuid),
                      child: Text(s(SL.retry)),
                    ),
                    TextButton(
                      key: Key('claim-dismiss-${r.queueUuid}'),
                      onPressed: () => ref
                          .read(openShiftsProvider.notifier)
                          .dismissClaim(r.queueUuid),
                      child: Text(s(SL.dismiss)),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: FfSpace.space3),
          if (state.loading && state.shifts.isEmpty)
            const Center(child: CircularProgressIndicator())
          else if (state.shifts.isEmpty)
            Padding(
              padding: const EdgeInsets.all(FfSpace.space5),
              child: Center(
                child: Text(s(SL.noOpenShifts), key: const Key('open-empty')),
              ),
            )
          else
            for (final Shift shift in state.shifts)
              ShiftCard(
                shift: shift,
                strings: s,
                language: language,
                trailing: _claimButton(state, shift, s),
              ),
        ],
      ),
    );
  }

  Widget _claimButton(OpenShiftsState state, Shift shift, ShiftStrings s) {
    if (state.queue.waitingShiftIds.contains(shift.id)) {
      return Chip(
        key: Key('claim-waiting-${shift.id}'),
        label: Text(s(SL.waitingToSend)),
      );
    }
    return FilledButton(
      key: Key('claim-${shift.id}'),
      onPressed: state.busyIds.contains(shift.id)
          ? null
          : () => _claim(shift, s),
      child: Text(s(SL.claimShift)),
    );
  }
}

// --- Swaps -----------------------------------------------------------------------------------------------------

class SwapsTab extends ConsumerStatefulWidget {
  const SwapsTab({super.key});

  @override
  ConsumerState<SwapsTab> createState() => _SwapsTabState();
}

class _SwapsTabState extends ConsumerState<SwapsTab> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(incomingSwapsProvider.notifier).load(),
    );
  }

  Future<void> _respond(
    SwapRequest swap, {
    required bool accept,
    required ShiftStrings s,
    required TranslationService t,
  }) async {
    final ShiftException? error = await ref
        .read(incomingSwapsProvider.notifier)
        .respond(swap.id, accept: accept);
    if (!mounted) {
      return;
    }
    final String message = error == null
        ? (accept ? s(SL.swapAccepted) : s(SL.swapDeclined))
        : shiftErrorMessage(s, t, error);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String _status(ShiftStrings s, SwapStatus status) => switch (status) {
    SwapStatus.pendingPeerAcceptance => s(SL.statusPeer),
    SwapStatus.pendingManagerApproval => s(SL.statusManager),
    SwapStatus.approved => s(SL.statusApproved),
    SwapStatus.rejected => s(SL.statusRejected),
  };

  @override
  Widget build(BuildContext context) {
    final String language = ref.watch(requestContextProvider).languageCode;
    final ShiftStrings s = ShiftStrings(language);
    final TranslationService t = ref.watch(translationProvider);
    final IncomingSwapsState state = ref.watch(incomingSwapsProvider);
    final String? me = ref.watch(shiftCalendarProvider).myEmployeeId;
    final List<SwapRequest> incoming = state.incoming(me);
    final List<SwapRequest> mine = state.mine(me);
    return RefreshIndicator(
      onRefresh: () => ref.read(incomingSwapsProvider.notifier).load(),
      child: ListView(
        padding: const EdgeInsets.all(FfSpace.space4),
        children: <Widget>[
          FilledButton.icon(
            key: const Key('swap-start'),
            icon: const Icon(Icons.swap_horiz),
            label: Text(s(SL.swapWizardTitle)),
            onPressed: () {
              ref.read(swapWizardProvider.notifier).reset();
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SwapWizardPage()),
              );
            },
          ),
          const SizedBox(height: FfSpace.space4),
          Text(
            s(SL.incomingSwaps),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (incoming.isEmpty)
            Padding(
              padding: const EdgeInsets.all(FfSpace.space3),
              child: Text(s(SL.noSwaps), key: const Key('swap-incoming-empty')),
            ),
          for (final SwapRequest swap in incoming)
            Card(
              key: Key('swap-incoming-${swap.id}'),
              child: Padding(
                padding: const EdgeInsets.all(FfSpace.space3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      swap.isBroadcast
                          ? s(SL.offerBroadcast)
                          : s(SL.offerToYou),
                    ),
                    if (swap.assignment != null)
                      Text(
                        '${swap.assignment!.date} · ${swap.assignment!.templateCode} · ${shiftTimeRange(swap.assignment!)}',
                      ),
                    Row(
                      children: <Widget>[
                        FilledButton(
                          key: Key('swap-accept-${swap.id}'),
                          onPressed: state.busyIds.contains(swap.id)
                              ? null
                              : () => _respond(swap, accept: true, s: s, t: t),
                          child: Text(s(SL.accept)),
                        ),
                        const SizedBox(width: FfSpace.space2),
                        OutlinedButton(
                          key: Key('swap-decline-${swap.id}'),
                          onPressed: state.busyIds.contains(swap.id)
                              ? null
                              : () => _respond(swap, accept: false, s: s, t: t),
                          child: Text(s(SL.decline)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: FfSpace.space4),
          Text(s(SL.mySwaps), style: Theme.of(context).textTheme.titleMedium),
          if (mine.isEmpty)
            Padding(
              padding: const EdgeInsets.all(FfSpace.space3),
              child: Text(s(SL.noSwaps), key: const Key('swap-mine-empty')),
            ),
          for (final SwapRequest swap in mine)
            ListTile(
              key: Key('swap-mine-${swap.id}'),
              title: Text(
                swap.assignment == null
                    ? swap.shiftAssignmentId
                    : '${swap.assignment!.date} · ${swap.assignment!.templateCode}',
              ),
              subtitle: Text(
                swap.status == SwapStatus.rejected &&
                        (swap.rejectionReason ?? '').isNotEmpty
                    ? '${_status(s, swap.status)}: ${swap.rejectionReason}'
                    : _status(s, swap.status),
              ),
            ),
        ],
      ),
    );
  }
}
