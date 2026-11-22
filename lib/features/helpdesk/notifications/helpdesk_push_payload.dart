import 'package:flutter/foundation.dart';

import '../domain/helpdesk_models.dart';

/// Kind of helpdesk push.
enum HelpdeskPushType {
  /// `helpdesk_ticket_assigned`: a ticket was assigned to the operator.
  ticketAssigned('helpdesk_ticket_assigned'),

  /// `helpdesk_sla_escalation`: an SLA escalation step fired (warning threshold or breach).
  slaEscalation('helpdesk_sla_escalation');

  const HelpdeskPushType(this.wire);

  final String wire;

  static HelpdeskPushType? fromWire(Object? raw) {
    for (final HelpdeskPushType t in values) {
      if (t.wire == '$raw') {
        return t;
      }
    }
    return null;
  }
}

/// How loudly the operator must be alerted.
enum HelpdeskAlertLevel {
  /// P1, or any SLA clock already breached.
  critical,

  /// P2, or an SLA warning threshold reached.
  high,

  /// Anything else: a plain notification, no foreground alert.
  normal,
}

/// Parsed helpdesk push data (`data:` map of the FCM/APNs message) or deep link.
///
/// Wire format sent by the backend:
/// `{type, ticket_id, ticket_number, priority, target?, threshold_percent?, elapsed_percent?, action?}`.
@immutable
class HelpdeskPushPayload {
  const HelpdeskPushPayload({
    required this.type,
    required this.ticketId,
    this.ticketNumber,
    this.priority = TicketPriority.medium,
    this.target,
    this.thresholdPercent,
    this.elapsedPercent,
    this.action,
  });

  final HelpdeskPushType type;
  final String ticketId;
  final String? ticketNumber;
  final TicketPriority priority;
  final SlaTargetKind? target;
  final double? thresholdPercent;
  final double? elapsedPercent;

  /// Escalation action the backend ran (`notify`, `reassign`, ...); informational.
  final String? action;

  /// Route opened by the deep link; handled by `onGenerateRoute`.
  String get routeName => helpdeskTicketRoute(ticketId);

  bool get isSlaEvent => type == HelpdeskPushType.slaEscalation;

  /// The SLA clock ran out (100% elapsed or more).
  bool get isBreach => isSlaEvent && (elapsedPercent ?? 0) >= 100;

  /// P1/P2 assignments and every SLA escalation interrupt the operator; other assignments stay silent.
  bool get isUrgent => isSlaEvent || priority.isUrgent;

  HelpdeskAlertLevel get alertLevel {
    if (priority == TicketPriority.critical || isBreach) {
      return HelpdeskAlertLevel.critical;
    }
    if (priority == TicketPriority.high || isSlaEvent) {
      return HelpdeskAlertLevel.high;
    }
    return HelpdeskAlertLevel.normal;
  }

  /// Parses a push data map; `null` when it is not a helpdesk push or carries no ticket.
  static HelpdeskPushPayload? tryParse(Map<String, dynamic> raw) {
    final HelpdeskPushType? type = HelpdeskPushType.fromWire(
      raw['type'] ?? raw['event_type'],
    );
    if (type == null) {
      return null;
    }
    final String? ticketId = _str(raw['ticket_id']);
    if (ticketId == null) {
      return null;
    }
    return HelpdeskPushPayload(
      type: type,
      ticketId: ticketId,
      ticketNumber: _str(raw['ticket_number']),
      priority: TicketPriority.fromWire(raw['priority']),
      target: SlaTargetKind.fromWire(raw['target']),
      thresholdPercent: _num(raw['threshold_percent']),
      elapsedPercent: _num(raw['elapsed_percent']),
      action: _str(raw['action']),
    );
  }

  /// Ticket id of a deep link: `fatturafacile://helpdesk/tickets/{id}`, `https://host/helpdesk/tickets/{id}`
  /// or `/helpdesk/tickets/{id}`.
  static String? ticketIdOfUri(Uri uri) {
    final List<String> segments = <String>[
      if (uri.scheme == 'fatturafacile' && uri.host.isNotEmpty) uri.host,
      ...uri.pathSegments.where((String s) => s.isNotEmpty),
    ];
    final int at = segments.indexOf('helpdesk');
    if (at < 0 || at + 2 >= segments.length || segments[at + 1] != 'tickets') {
      return null;
    }
    final String id = segments[at + 2].trim();
    return id.isEmpty ? null : id;
  }

  static String? _str(Object? raw) {
    if (raw == null) {
      return null;
    }
    final String s = '$raw'.trim();
    return s.isEmpty ? null : s;
  }

  static double? _num(Object? v) =>
      v is num ? v.toDouble() : (v is String ? double.tryParse(v) : null);
}

/// Route of a ticket detail; also the deep link path.
String helpdeskTicketRoute(String ticketId) => '/helpdesk/tickets/$ticketId';

/// Route of the operator queue.
const String helpdeskQueueRoute = '/helpdesk/queue';
