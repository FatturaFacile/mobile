import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/providers.dart';
import '../../../design/ff_tokens.dart';
import '../domain/helpdesk_models.dart';
import '../notifications/helpdesk_push_payload.dart';
import 'helpdesk_controller.dart';
import 'helpdesk_strings.dart';

/// RBAC module key of the helpdesk operator queue.
const String helpdeskModule = 'helpdesk';

FfColors _colors(BuildContext context) =>
    Theme.of(context).extension<FfColors>() ?? FfColors.light;

HelpdeskStrings _strings(WidgetRef ref) =>
    HelpdeskStrings(ref.watch(requestContextProvider).languageCode);

/// `P1`/`P2` are loud (danger / warning), the rest are neutral.
class PriorityBadge extends StatelessWidget {
  const PriorityBadge({required this.priority, super.key});

  final TicketPriority priority;

  @override
  Widget build(BuildContext context) {
    final FfColors c = _colors(context);
    final (Color fg, Color bg) = switch (priority) {
      TicketPriority.critical => (c.onPrimary, c.danger),
      TicketPriority.high => (c.onPrimary, c.warning),
      _ => (c.textSecondary, c.neutralBg),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: FfSpace.space2,
        vertical: FfSpace.space1,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(FfRadius.sm),
      ),
      child: Text(
        priority.badge,
        style: TextStyle(
          color: fg,
          fontSize: FfFont.xs,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Re-renders its child every 30 seconds so the SLA countdowns stay current.
class _Ticking extends StatefulWidget {
  const _Ticking({required this.builder});

  final Widget Function(BuildContext context) builder;

  @override
  State<_Ticking> createState() => _TickingState();
}

class _TickingState extends State<_Ticking> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}

/// SLA state of a ticket: breached / at risk with the countdown of the clock that expires first.
class SlaChip extends ConsumerWidget {
  const SlaChip({required this.ticket, super.key});

  final QueueTicket ticket;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ticket.riskPercent == null) {
      return const SizedBox.shrink();
    }
    final HelpdeskStrings s = _strings(ref);
    final FfColors c = _colors(context);
    final DateTime Function() clock = ref.watch(helpdeskClockProvider);
    final bool breached = ticket.isBreached;
    final Color color = breached ? c.danger : c.warning;
    return _Ticking(
      builder: (BuildContext context) {
        final SlaTarget? due = ticket.nextDue;
        final Duration? left = due?.remaining(clock());
        final String label = breached ? s(HL.breached) : s(HL.atRisk);
        return Container(
          key: Key('ticket-sla-${ticket.id}'),
          padding: const EdgeInsets.symmetric(
            horizontal: FfSpace.space2,
            vertical: FfSpace.space1,
          ),
          decoration: BoxDecoration(
            color: breached ? c.dangerBg : c.warningBg,
            borderRadius: BorderRadius.circular(FfRadius.sm),
          ),
          child: Text(
            <String>[
              label,
              '${ticket.riskPercent!.round()}%',
              ?(due == null || left == null)
                  ? null
                  : '${s.slaTarget(due.kind)} ${s.countdown(left)}',
            ].join(' · '),
            style: TextStyle(
              color: color,
              fontSize: FfFont.xs,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      },
    );
  }
}

/// Operator ticket queue: P1/P2 and imminent SLA breaches on top, readable offline.
class HelpdeskQueuePage extends ConsumerStatefulWidget {
  const HelpdeskQueuePage({super.key});

  @override
  ConsumerState<HelpdeskQueuePage> createState() => _HelpdeskQueuePageState();
}

class _HelpdeskQueuePageState extends ConsumerState<HelpdeskQueuePage> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(helpdeskQueueProvider.notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final HelpdeskStrings s = _strings(ref);
    final HelpdeskQueueState state = ref.watch(helpdeskQueueProvider);
    final HelpdeskQueueController ctrl = ref.read(
      helpdeskQueueProvider.notifier,
    );
    final List<QueueTicket> items = state.visible;
    return Scaffold(
      appBar: AppBar(
        title: Text(s(HL.title)),
        actions: <Widget>[
          IconButton(
            key: const Key('queue-refresh'),
            tooltip: s(HL.refresh),
            icon: const Icon(Icons.refresh),
            onPressed: ctrl.load,
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          if (state.loading) const LinearProgressIndicator(),
          if (state.fromCache || state.error?.kind == HelpdeskErrorKind.offline)
            MaterialBanner(
              key: const Key('queue-offline'),
              content: Text(s(HL.offlineCopy)),
              actions: const <Widget>[SizedBox.shrink()],
            ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: FfSpace.space3,
              vertical: FfSpace.space2,
            ),
            child: Wrap(
              spacing: FfSpace.space2,
              children: <Widget>[
                for (final (QueueFilter f, HL label) in <(QueueFilter, HL)>[
                  (QueueFilter.all, HL.filterAll),
                  (QueueFilter.urgent, HL.filterUrgent),
                  (QueueFilter.atRisk, HL.filterAtRisk),
                ])
                  ChoiceChip(
                    key: Key('queue-filter-${f.name}'),
                    label: Text(s(label)),
                    selected: state.filter == f,
                    onSelected: (_) => ctrl.setFilter(f),
                  ),
              ],
            ),
          ),
          if (state.error != null &&
              state.error!.kind != HelpdeskErrorKind.offline &&
              !state.loading)
            Padding(
              padding: const EdgeInsets.all(FfSpace.space3),
              child: Text(s.error(state.error!)),
            ),
          Expanded(
            child: items.isEmpty && !state.loading
                ? Center(
                    child: Text(
                      s(HL.queueEmpty),
                      key: const Key('queue-empty'),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: ctrl.load,
                    child: ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (BuildContext context, int i) => _QueueCard(
                        ticket: items[i],
                        pending: state.pendingFor(items[i].id),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _QueueCard extends ConsumerWidget {
  const _QueueCard({required this.ticket, required this.pending});

  final QueueTicket ticket;
  final int pending;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final HelpdeskStrings s = _strings(ref);
    return Card(
      key: Key('ticket-card-${ticket.id}'),
      margin: const EdgeInsets.symmetric(
        horizontal: FfSpace.space3,
        vertical: FfSpace.space1,
      ),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            settings: RouteSettings(name: helpdeskTicketRoute(ticket.id)),
            builder: (_) => HelpdeskTicketPage(ticketId: ticket.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(FfSpace.space3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  PriorityBadge(priority: ticket.priority),
                  const SizedBox(width: FfSpace.space2),
                  Expanded(
                    child: Text(
                      ticket.number,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (pending > 0)
                    Tooltip(
                      message: s(HL.waitingToSend),
                      child: Icon(
                        Icons.cloud_upload_outlined,
                        key: Key('ticket-pending-${ticket.id}'),
                        size: 18,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: FfSpace.space1),
              Text(
                ticket.subject,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (ticket.riskPercent != null) ...<Widget>[
                const SizedBox(height: FfSpace.space2),
                SlaChip(ticket: ticket),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Ticket detail: SLA, customer context, time logging and one-tap escalation.
class HelpdeskTicketPage extends ConsumerStatefulWidget {
  const HelpdeskTicketPage({required this.ticketId, super.key});

  final String ticketId;

  @override
  ConsumerState<HelpdeskTicketPage> createState() => _HelpdeskTicketPageState();
}

class _HelpdeskTicketPageState extends ConsumerState<HelpdeskTicketPage> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(ticketDetailProvider.notifier).load(widget.ticketId),
    );
  }

  Future<void> _logTime(HelpdeskStrings s) async {
    final TextEditingController minutes = TextEditingController();
    final TextEditingController description = TextEditingController();
    bool billable = true;
    String? error;
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => StatefulBuilder(
        builder: (BuildContext ctx, StateSetter setState) => AlertDialog(
          title: Text(s(HL.logTime)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                key: const Key('time-minutes'),
                controller: minutes,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: InputDecoration(
                  labelText: s(HL.minutes),
                  errorText: error,
                ),
              ),
              TextField(
                key: const Key('time-description'),
                controller: description,
                decoration: InputDecoration(labelText: s(HL.description)),
              ),
              SwitchListTile(
                key: const Key('time-billable'),
                contentPadding: EdgeInsets.zero,
                title: Text(s(HL.billable)),
                value: billable,
                onChanged: (bool v) => setState(() => billable = v),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(s(HL.cancel)),
            ),
            FilledButton(
              key: const Key('time-save'),
              onPressed: () {
                final int? m = int.tryParse(minutes.text);
                if (m == null || m <= 0) {
                  setState(() => error = s(HL.invalidMinutes));
                  return;
                }
                Navigator.of(ctx).pop(true);
              },
              child: Text(s(HL.save)),
            ),
          ],
        ),
      ),
    );
    final int? m = int.tryParse(minutes.text);
    if (ok == true && m != null && m > 0) {
      await ref
          .read(ticketDetailProvider.notifier)
          .logTime(
            minutes: m,
            description: description.text,
            isBillable: billable,
          );
    }
    minutes.dispose();
    description.dispose();
  }

  Future<void> _escalate(HelpdeskStrings s, EscalationTarget target) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        content: Text(
          target == EscalationTarget.fieldService
              ? s(HL.escalateConfirmFieldService)
              : s(HL.escalateConfirmRma),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(s(HL.cancel)),
          ),
          FilledButton(
            key: const Key('escalate-confirm'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(s(HL.escalateTitle)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(ticketDetailProvider.notifier).escalate(target);
    }
  }

  String? _noticeText(HelpdeskStrings s, TicketDetailState st) =>
      switch (st.notice) {
        HelpdeskNotice.timeSent => s(HL.timeSent),
        HelpdeskNotice.timeQueued => s(HL.timeQueued),
        HelpdeskNotice.escalateSent => s(HL.escalateSent),
        HelpdeskNotice.escalateQueued => s(HL.escalateQueued),
        HelpdeskNotice.rejected =>
          st.noticeDetail.isEmpty ? s(HL.errorInvalid) : st.noticeDetail,
        null => null,
      };

  @override
  Widget build(BuildContext context) {
    final HelpdeskStrings s = _strings(ref);
    final TicketDetailState st = ref.watch(ticketDetailProvider);
    ref.listen<TicketDetailState>(ticketDetailProvider, (
      TicketDetailState? prev,
      TicketDetailState next,
    ) {
      final String? text = _noticeText(s, next);
      if (text != null && next.notice != prev?.notice) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(text)));
        ref.read(ticketDetailProvider.notifier).clearNotice();
      }
    });
    final QueueTicket? t = st.ticket;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          t == null || t.number.isEmpty ? s(HL.ticket) : t.number,
          key: const Key('ticket-title'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(FfSpace.space3),
        children: <Widget>[
          if (st.loading) const LinearProgressIndicator(),
          if (st.error != null && st.error!.kind != HelpdeskErrorKind.offline)
            Text(s.error(st.error!)),
          if (t != null) ...<Widget>[
            Row(
              children: <Widget>[
                PriorityBadge(priority: t.priority),
                const SizedBox(width: FfSpace.space2),
                Expanded(child: Text(t.subject)),
              ],
            ),
            const SizedBox(height: FfSpace.space2),
            SlaChip(ticket: t),
          ],
          const SizedBox(height: FfSpace.space4),
          _section(context, s(HL.escalateTitle)),
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton.tonalIcon(
                  key: const Key('escalate-field-service'),
                  icon: const Icon(Icons.engineering_outlined),
                  label: Text(s(HL.escalateFieldService)),
                  onPressed:
                      st.busy ||
                          st.escalationPending(EscalationTarget.fieldService)
                      ? null
                      : () => _escalate(s, EscalationTarget.fieldService),
                ),
              ),
              const SizedBox(width: FfSpace.space2),
              Expanded(
                child: FilledButton.tonalIcon(
                  key: const Key('escalate-rma'),
                  icon: const Icon(Icons.assignment_return_outlined),
                  label: Text(s(HL.escalateRma)),
                  onPressed:
                      st.busy || st.escalationPending(EscalationTarget.rma)
                      ? null
                      : () => _escalate(s, EscalationTarget.rma),
                ),
              ),
            ],
          ),
          for (final PendingAction a in st.pending) _pendingRow(s, a),
          const SizedBox(height: FfSpace.space4),
          Row(
            children: <Widget>[
              Expanded(child: _section(context, s(HL.timeTitle))),
              TextButton.icon(
                key: const Key('log-time'),
                icon: const Icon(Icons.timer_outlined),
                label: Text(s(HL.logTime)),
                onPressed: st.busy ? null : () => _logTime(s),
              ),
            ],
          ),
          if (st.entries.isEmpty)
            Text(s(HL.noTimeEntries))
          else
            for (final TimeEntry e in st.entries)
              ListTile(
                key: Key('time-entry-${e.id}'),
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text('${e.minutes} min'),
                subtitle: Text(
                  <String>[
                    if (e.description != null) e.description!,
                    s.billing(e.billingStatus),
                  ].where((String x) => x.isNotEmpty).join(' · '),
                ),
              ),
          const SizedBox(height: FfSpace.space4),
          _section(context, s(HL.customerContext)),
          ..._contextBlock(s, st.context),
        ],
      ),
    );
  }

  Widget _pendingRow(HelpdeskStrings s, PendingAction a) {
    final String what = switch (a.kind) {
      PendingActionKind.timeEntry => '${s(HL.logTime)} ${a.minutes ?? ''}',
      PendingActionKind.fieldService => s(HL.escalateFieldService),
      PendingActionKind.rma => s(HL.escalateRma),
    };
    return ListTile(
      key: Key('pending-${a.queueUuid}'),
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        a.rejected ? Icons.error_outline : Icons.cloud_upload_outlined,
      ),
      title: Text(what),
      subtitle: Text(
        a.rejected
            ? (a.detail.isEmpty ? s(HL.actionRejected) : a.detail)
            : s(HL.waitingToSend),
      ),
      trailing: a.rejected
          ? TextButton(
              key: Key('pending-dismiss-${a.queueUuid}'),
              onPressed: () =>
                  ref.read(ticketDetailProvider.notifier).dismiss(a.queueUuid),
              child: Text(s(HL.dismiss)),
            )
          : null,
    );
  }

  Widget _section(BuildContext context, String title) => Padding(
    padding: const EdgeInsets.only(bottom: FfSpace.space2),
    child: Text(title, style: Theme.of(context).textTheme.titleSmall),
  );

  List<Widget> _contextBlock(HelpdeskStrings s, CustomerContext? c) {
    if (c == null || c.isEmpty) {
      return <Widget>[Text(s(HL.noContext))];
    }
    Widget group(HL title, List<ContextItem> items, {String suffix = ''}) =>
        items.isEmpty
        ? const SizedBox.shrink()
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                s(title),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              for (final ContextItem i in items)
                Text(
                  i.detail == null
                      ? i.title
                      : '${i.title} · ${i.detail}$suffix',
                ),
              const SizedBox(height: FfSpace.space2),
            ],
          );
    return <Widget>[
      group(HL.contracts, c.contracts, suffix: ' ${s(HL.hoursLeft)}'),
      group(HL.assets, c.assets),
      group(HL.openInvoices, c.openInvoices),
      group(HL.recentTickets, c.recentTickets),
    ];
  }
}
