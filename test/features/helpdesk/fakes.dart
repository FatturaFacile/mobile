import 'package:fattura_facile/features/helpdesk/domain/helpdesk_models.dart';
import 'package:fattura_facile/features/helpdesk/domain/helpdesk_repository.dart';

/// In-memory [HelpdeskRepository] with scriptable outcomes.
class FakeHelpdeskRepository implements HelpdeskRepository {
  List<QueueTicket> cache = <QueueTicket>[];
  List<QueueTicket> remote = <QueueTicket>[];
  HelpdeskException? refreshError;

  CustomerContext? context;
  List<TimeEntry> entries = <TimeEntry>[];

  /// What the next logTime/escalate answers.
  ActionStatus nextStatus = ActionStatus.sent;
  String nextDetail = '';

  List<PendingAction> pending = <PendingAction>[];
  final List<({String ticketId, int minutes, bool billable, String? tech})>
  loggedTime =
      <({String ticketId, int minutes, bool billable, String? tech})>[];
  final List<({String ticketId, EscalationTarget target})> escalations =
      <({String ticketId, EscalationTarget target})>[];
  final List<String> dismissed = <String>[];
  int flushes = 0;

  @override
  Future<List<QueueTicket>> cachedQueue(String tenantId) async =>
      sortQueue(cache);

  @override
  Future<List<QueueTicket>> refreshQueue(
    String tenantId, {
    int riskPercent = 75,
    int limit = 100,
  }) async {
    final HelpdeskException? e = refreshError;
    if (e != null) {
      throw e;
    }
    cache = sortQueue(remote);
    return cache;
  }

  @override
  Future<QueueTicket?> cachedTicket(String tenantId, String ticketId) async {
    for (final QueueTicket t in cache) {
      if (t.id == ticketId) {
        return t;
      }
    }
    return null;
  }

  @override
  Future<CustomerContext?> cachedContext(String t, String id) async => context;

  @override
  Future<CustomerContext> refreshContext(String t, String id) async {
    final HelpdeskException? e = refreshError;
    if (e != null) {
      throw e;
    }
    return context ?? const CustomerContext();
  }

  @override
  Future<List<TimeEntry>> cachedTimeEntries(String t, String id) async =>
      entries;

  @override
  Future<List<TimeEntry>> refreshTimeEntries(String t, String id) async =>
      entries;

  @override
  Future<ActionOutcome> logTime(
    String tenantId,
    String ticketId, {
    required int minutes,
    String? technicianId,
    String? description,
    bool isBillable = true,
  }) async {
    loggedTime.add((
      ticketId: ticketId,
      minutes: minutes,
      billable: isBillable,
      tech: technicianId,
    ));
    if (nextStatus == ActionStatus.queued) {
      pending = <PendingAction>[
        ...pending,
        PendingAction(
          queueUuid: 'q${pending.length}',
          ticketId: ticketId,
          kind: PendingActionKind.timeEntry,
          rejected: false,
          minutes: minutes,
        ),
      ];
    }
    return ActionOutcome(nextStatus, detail: nextDetail);
  }

  @override
  Future<ActionOutcome> escalate(
    String tenantId,
    String ticketId,
    EscalationTarget target,
  ) async {
    escalations.add((ticketId: ticketId, target: target));
    if (nextStatus == ActionStatus.queued) {
      pending = <PendingAction>[
        ...pending,
        PendingAction(
          queueUuid: 'q${pending.length}',
          ticketId: ticketId,
          kind: target == EscalationTarget.rma
              ? PendingActionKind.rma
              : PendingActionKind.fieldService,
          rejected: false,
        ),
      ];
    }
    return ActionOutcome(nextStatus, detail: nextDetail);
  }

  @override
  Future<List<PendingAction>> pendingActions(
    String tenantId, {
    String? ticketId,
  }) async => <PendingAction>[
    for (final PendingAction a in pending)
      if (ticketId == null || a.ticketId == ticketId) a,
  ];

  @override
  Future<void> retryAction(String tenantId, String queueUuid) async {}

  @override
  Future<void> dismissAction(String queueUuid) async {
    dismissed.add(queueUuid);
    pending = <PendingAction>[
      for (final PendingAction a in pending)
        if (a.queueUuid != queueUuid) a,
    ];
  }

  @override
  Future<int> flush(String tenantId) async {
    flushes++;
    return 0;
  }
}
