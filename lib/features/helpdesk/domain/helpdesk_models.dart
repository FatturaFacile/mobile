import 'package:flutter/foundation.dart';

/// Ticket priority. P1 is `critical`, P2 is `high` (the urgent ones the operator must see at a glance).
enum TicketPriority {
  low('low', 'P4', 0),
  medium('medium', 'P3', 1),
  high('high', 'P2', 2),
  critical('critical', 'P1', 3);

  const TicketPriority(this.wire, this.badge, this.rank);

  final String wire;

  /// Short badge shown on the queue (`P1`..`P4`), not translated: it is a fixed ITSM label.
  final String badge;

  /// Higher is more urgent.
  final int rank;

  bool get isUrgent => this == high || this == critical;

  static TicketPriority fromWire(Object? raw) {
    final String v = '$raw'.trim().toLowerCase();
    for (final TicketPriority p in values) {
      if (p.wire == v || p.badge.toLowerCase() == v) {
        return p;
      }
    }
    return medium;
  }
}

/// SLA clock a ticket is racing against.
enum SlaTargetKind {
  response('response'),
  nextUpdate('next_update'),
  resolution('resolution');

  const SlaTargetKind(this.wire);

  final String wire;

  static SlaTargetKind? fromWire(Object? raw) {
    for (final SlaTargetKind k in values) {
      if (k.wire == '$raw') {
        return k;
      }
    }
    return null;
  }
}

enum SlaState { atRisk, breached }

/// Statuses that take a ticket out of the operator queue.
const Set<String> closedTicketStatuses = <String>{
  'closed',
  'resolved',
  'merged',
  'cancelled',
};

/// One SLA clock of a ticket that is at risk or already breached.
@immutable
class SlaTarget {
  const SlaTarget({
    required this.kind,
    required this.dueAt,
    required this.elapsedPercent,
    required this.state,
  });

  factory SlaTarget.fromJson(Map<String, dynamic> json) {
    return SlaTarget(
      kind: SlaTargetKind.fromWire(json['target']) ?? SlaTargetKind.resolution,
      dueAt: DateTime.tryParse('${json['due_at']}')?.toUtc(),
      elapsedPercent: _num(json['elapsed_percent']) ?? 0,
      state: '${json['state']}' == 'breached'
          ? SlaState.breached
          : SlaState.atRisk,
    );
  }

  final SlaTargetKind kind;
  final DateTime? dueAt;
  final double elapsedPercent;
  final SlaState state;

  /// Time left until [dueAt]; negative once overdue. `null` when the server sent no due date.
  Duration? remaining(DateTime now) => dueAt?.difference(now.toUtc());

  Map<String, dynamic> toJson() => <String, dynamic>{
    'target': kind.wire,
    'due_at': dueAt?.toIso8601String(),
    'elapsed_percent': elapsedPercent,
    'state': state == SlaState.breached ? 'breached' : 'at_risk',
  };
}

/// A ticket of the operator queue, with the SLA breach risk when the server reports one.
@immutable
class QueueTicket {
  const QueueTicket({
    required this.id,
    required this.number,
    required this.subject,
    required this.priority,
    required this.status,
    this.customerId,
    this.assignedTeamId,
    this.assignedTechnicianId,
    this.riskPercent,
    this.targets = const <SlaTarget>[],
  });

  /// Reads both the `/tickets` row and the `/helpdesk/breach-risk` row.
  factory QueueTicket.fromJson(Map<String, dynamic> json) {
    final Object? id = json['ticket_id'] ?? json['id'];
    final dynamic rawTargets = json['targets'];
    return QueueTicket(
      id: '$id',
      number: _str(json['ticket_number']) ?? _str(json['number']) ?? '',
      subject: _str(json['subject']) ?? '',
      priority: TicketPriority.fromWire(json['priority']),
      status: _str(json['status']) ?? '',
      customerId: _str(json['customer_id']),
      assignedTeamId: _str(json['assigned_team_id']),
      assignedTechnicianId: _str(json['assigned_technician_id']),
      riskPercent: _num(json['risk_percent']),
      targets: <SlaTarget>[
        if (rawTargets is List)
          for (final dynamic t in rawTargets)
            if (t is Map) SlaTarget.fromJson(Map<String, dynamic>.from(t)),
      ],
    );
  }

  final String id;
  final String number;
  final String subject;
  final TicketPriority priority;
  final String status;
  final String? customerId;
  final String? assignedTeamId;
  final String? assignedTechnicianId;

  /// Worst elapsed percent of the SLA clocks; `null` when no clock is at risk.
  final double? riskPercent;
  final List<SlaTarget> targets;

  bool get isClosed => closedTicketStatuses.contains(status.toLowerCase());

  bool get isBreached =>
      targets.any((SlaTarget t) => t.state == SlaState.breached) ||
      (riskPercent ?? 0) >= 100;

  bool get isAtRisk => !isBreached && riskPercent != null;

  /// The clock that expires first (the one the countdown shows).
  SlaTarget? get nextDue {
    SlaTarget? best;
    for (final SlaTarget t in targets) {
      if (t.dueAt == null) {
        continue;
      }
      if (best == null || t.dueAt!.isBefore(best.dueAt!)) {
        best = t;
      }
    }
    return best;
  }

  QueueTicket withRisk(double? risk, List<SlaTarget> newTargets) => QueueTicket(
    id: id,
    number: number,
    subject: subject,
    priority: priority,
    status: status,
    customerId: customerId,
    assignedTeamId: assignedTeamId,
    assignedTechnicianId: assignedTechnicianId,
    riskPercent: risk,
    targets: newTargets,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'ticket_id': id,
    'ticket_number': number,
    'subject': subject,
    'priority': priority.wire,
    'status': status,
    'customer_id': customerId,
    'assigned_team_id': assignedTeamId,
    'assigned_technician_id': assignedTechnicianId,
    'risk_percent': riskPercent,
    'targets': <Map<String, dynamic>>[
      for (final SlaTarget t in targets) t.toJson(),
    ],
  };
}

/// Orders the operator queue: highest SLA risk first (breached on top), then priority (P1 before P2...), then number.
List<QueueTicket> sortQueue(Iterable<QueueTicket> tickets) {
  final List<QueueTicket> out = tickets.toList();
  out.sort((QueueTicket a, QueueTicket b) {
    final int byRisk = (b.riskPercent ?? -1).compareTo(a.riskPercent ?? -1);
    if (byRisk != 0) {
      return byRisk;
    }
    final int byPriority = b.priority.rank.compareTo(a.priority.rank);
    if (byPriority != 0) {
      return byPriority;
    }
    return a.number.compareTo(b.number);
  });
  return out;
}

/// Open tickets from `/tickets` enriched with the breach-risk rows; a risk row of a ticket missing from the list is kept.
List<QueueTicket> mergeQueue(
  Iterable<QueueTicket> tickets,
  Iterable<QueueTicket> risks,
) {
  final Map<String, QueueTicket> byId = <String, QueueTicket>{
    for (final QueueTicket t in tickets)
      if (!t.isClosed) t.id: t,
  };
  for (final QueueTicket r in risks) {
    final QueueTicket? base = byId[r.id];
    byId[r.id] = base == null ? r : base.withRisk(r.riskPercent, r.targets);
  }
  return sortQueue(byId.values);
}

/// Compact countdown: `12m`, `2h 05m`, `1d 3h`; an overdue clock gets a leading minus (`-1h 05m`).
String formatCountdown(Duration d) {
  final bool overdue = d.isNegative;
  final int totalMinutes = d.abs().inMinutes;
  final int days = totalMinutes ~/ 1440;
  final int hours = (totalMinutes % 1440) ~/ 60;
  final int minutes = totalMinutes % 60;
  final String body = days > 0
      ? '${days}d ${hours}h'
      : (hours > 0
            ? '${hours}h ${minutes.toString().padLeft(2, '0')}m'
            : '${minutes}m');
  return overdue ? '-$body' : body;
}

/// How a logged time entry was billed by the server.
enum BillingStatus {
  contractDeducted('contract_deducted'),
  partiallyDeducted('partially_deducted'),
  billablePending('billable_pending'),
  nonBillable('non_billable'),
  unknown('');

  const BillingStatus(this.wire);

  final String wire;

  static BillingStatus fromWire(Object? raw) {
    for (final BillingStatus s in values) {
      if (s.wire.isNotEmpty && s.wire == '$raw') {
        return s;
      }
    }
    return unknown;
  }
}

@immutable
class TimeEntry {
  const TimeEntry({
    required this.id,
    required this.minutes,
    this.description,
    this.isBillable = true,
    this.billingStatus = BillingStatus.unknown,
    this.loggedAt,
  });

  factory TimeEntry.fromJson(Map<String, dynamic> json) {
    return TimeEntry(
      id: '${json['id']}',
      minutes: (_num(json['minutes']) ?? 0).round(),
      description: _str(json['description']),
      isBillable: json['is_billable'] is bool
          ? json['is_billable'] as bool
          : true,
      billingStatus: BillingStatus.fromWire(json['billing_status']),
      loggedAt: DateTime.tryParse('${json['created_at'] ?? json['logged_at']}'),
    );
  }

  final String id;
  final int minutes;
  final String? description;
  final bool isBillable;
  final BillingStatus billingStatus;
  final DateTime? loggedAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'minutes': minutes,
    'description': description,
    'is_billable': isBillable,
    'billing_status': billingStatus.wire,
    'created_at': loggedAt?.toIso8601String(),
  };
}

/// One line of the customer context (a contract, an asset, an invoice, a recent ticket).
@immutable
class ContextItem {
  const ContextItem({required this.title, this.detail});

  final String title;
  final String? detail;
}

/// Customer snapshot the operator sees on the ticket: contracts with remaining hours, assets, invoices, history.
@immutable
class CustomerContext {
  const CustomerContext({
    this.contracts = const <ContextItem>[],
    this.assets = const <ContextItem>[],
    this.openInvoices = const <ContextItem>[],
    this.recentTickets = const <ContextItem>[],
  });

  factory CustomerContext.fromJson(Map<String, dynamic> json) {
    return CustomerContext(
      contracts: _items(json['contracts'], <String>[
        'name',
        'number',
        'code',
        'id',
      ], detailKey: 'remaining_hours'),
      assets: _items(json['assets'], <String>[
        'name',
        'serial_number',
        'code',
        'id',
      ], detailKey: 'serial_number'),
      openInvoices: _items(json['open_invoices'], <String>[
        'number',
        'invoice_number',
        'id',
      ], detailKey: 'total'),
      recentTickets: _items(json['recent_tickets'], <String>[
        'ticket_number',
        'number',
        'id',
      ], detailKey: 'subject'),
    );
  }

  final List<ContextItem> contracts;
  final List<ContextItem> assets;
  final List<ContextItem> openInvoices;
  final List<ContextItem> recentTickets;

  bool get isEmpty =>
      contracts.isEmpty &&
      assets.isEmpty &&
      openInvoices.isEmpty &&
      recentTickets.isEmpty;

  static List<ContextItem> _items(
    Object? raw,
    List<String> titleKeys, {
    required String detailKey,
  }) {
    if (raw is! List) {
      return const <ContextItem>[];
    }
    return <ContextItem>[
      for (final dynamic r in raw)
        if (r is Map)
          ContextItem(
            title: _firstStr(Map<String, dynamic>.from(r), titleKeys) ?? '',
            detail: _str(r[detailKey]),
          ),
    ];
  }
}

/// What an operator action ended up as.
enum ActionStatus {
  /// The server confirmed it.
  sent,

  /// No connection: parked in the outbox, resent on the next sync (idempotent).
  queued,

  /// The server refused it for good (422/403, e.g. a closed ticket); it will not be resent.
  rejected,
}

@immutable
class ActionOutcome {
  const ActionOutcome(this.status, {this.detail = ''});

  final ActionStatus status;
  final String detail;
}

enum EscalationTarget {
  fieldService('field-service'),
  rma('rma');

  const EscalationTarget(this.pathSegment);

  final String pathSegment;
}

enum PendingActionKind { timeEntry, fieldService, rma }

/// An operator action still in the outbox.
@immutable
class PendingAction {
  const PendingAction({
    required this.queueUuid,
    required this.ticketId,
    required this.kind,
    required this.rejected,
    this.minutes,
    this.detail = '',
  });

  final String queueUuid;
  final String ticketId;
  final PendingActionKind kind;

  /// Refused by the server: the user can dismiss it (it is never resent).
  final bool rejected;
  final int? minutes;
  final String detail;
}

enum HelpdeskErrorKind { forbidden, notFound, invalid, offline, unknown }

class HelpdeskException implements Exception {
  const HelpdeskException(this.kind, {this.detail = ''});

  final HelpdeskErrorKind kind;
  final String detail;

  @override
  String toString() => 'HelpdeskException($kind, $detail)';
}

String? _str(Object? v) {
  if (v == null) {
    return null;
  }
  final String s = '$v'.trim();
  return s.isEmpty || s == 'null' ? null : s;
}

String? _firstStr(Map<String, dynamic> m, List<String> keys) {
  for (final String k in keys) {
    final String? v = _str(m[k]);
    if (v != null) {
      return v;
    }
  }
  return null;
}

double? _num(Object? v) =>
    v is num ? v.toDouble() : (v is String ? double.tryParse(v) : null);
