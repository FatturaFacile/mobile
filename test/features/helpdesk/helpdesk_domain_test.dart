import 'package:fattura_facile/features/helpdesk/domain/helpdesk_models.dart';
import 'package:fattura_facile/features/helpdesk/notifications/helpdesk_push_payload.dart';
import 'package:fattura_facile/features/helpdesk/presentation/helpdesk_strings.dart';
import 'package:flutter_test/flutter_test.dart';

QueueTicket ticket(
  String id, {
  TicketPriority priority = TicketPriority.medium,
  double? risk,
  String status = 'open',
  String? number,
}) => QueueTicket(
  id: id,
  number: number ?? 'T-$id',
  subject: 'Subject $id',
  priority: priority,
  status: status,
  riskPercent: risk,
  targets: risk == null
      ? const <SlaTarget>[]
      : <SlaTarget>[
          SlaTarget(
            kind: SlaTargetKind.resolution,
            dueAt: DateTime.utc(2030, 1, 1, 12),
            elapsedPercent: risk,
            state: risk >= 100 ? SlaState.breached : SlaState.atRisk,
          ),
        ],
);

void main() {
  group('priority badges', () {
    test('P1 is critical and P2 is high, only those two are urgent', () {
      expect(TicketPriority.fromWire('critical').badge, 'P1');
      expect(TicketPriority.fromWire('high').badge, 'P2');
      expect(TicketPriority.fromWire('medium').badge, 'P3');
      expect(TicketPriority.fromWire('low').badge, 'P4');
      expect(TicketPriority.critical.isUrgent, isTrue);
      expect(TicketPriority.high.isUrgent, isTrue);
      expect(TicketPriority.medium.isUrgent, isFalse);
      expect(TicketPriority.fromWire('nonsense'), TicketPriority.medium);
    });
  });

  group('queue sorting', () {
    test('highest risk first, breached on top, then priority, then number', () {
      final List<QueueTicket> sorted = sortQueue(<QueueTicket>[
        ticket('low-none'),
        ticket('p1-none', priority: TicketPriority.critical),
        ticket('p3-80', risk: 80),
        ticket('p3-120', risk: 120),
        ticket('p2-80', priority: TicketPriority.high, risk: 80),
      ]);

      expect(sorted.map((QueueTicket t) => t.id), <String>[
        'p3-120',
        'p2-80',
        'p3-80',
        'p1-none',
        'low-none',
      ]);
    });

    test('merge keeps open tickets, overlays the risk and adds risk rows missing from the list', () {
      final List<QueueTicket> merged = mergeQueue(
        <QueueTicket>[
          ticket('a', priority: TicketPriority.high),
          ticket('b'),
          ticket('closed', status: 'closed'),
        ],
        <QueueTicket>[ticket('b', risk: 90), ticket('c', risk: 101)],
      );

      expect(merged.map((QueueTicket t) => t.id), <String>['c', 'b', 'a']);
      expect(merged[0].isBreached, isTrue);
      expect(merged[1].isAtRisk, isTrue);
      expect(merged[2].riskPercent, isNull);
    });

    test('parses the breach-risk row of the API', () {
      final QueueTicket t = QueueTicket.fromJson(const <String, dynamic>{
        'ticket_id': 'x1',
        'ticket_number': 'TK-9',
        'subject': 'Printer down',
        'priority': 'critical',
        'status': 'open',
        'risk_percent': 82.5,
        'targets': <Map<String, dynamic>>[
          <String, dynamic>{
            'target': 'resolution',
            'due_at': '2030-01-01T12:00:00Z',
            'elapsed_percent': 82.5,
            'state': 'at_risk',
          },
          <String, dynamic>{
            'target': 'response',
            'due_at': '2030-01-01T10:00:00Z',
            'elapsed_percent': 101,
            'state': 'breached',
          },
        ],
      });

      expect(t.id, 'x1');
      expect(t.priority, TicketPriority.critical);
      expect(t.nextDue!.kind, SlaTargetKind.response);
      expect(t.isBreached, isTrue);
      expect(QueueTicket.fromJson(t.toJson()).targets.length, 2);
    });
  });

  group('countdown', () {
    test('formats minutes, hours, days and overdue clocks', () {
      expect(formatCountdown(const Duration(minutes: 12)), '12m');
      expect(formatCountdown(const Duration(hours: 2, minutes: 5)), '2h 05m');
      expect(formatCountdown(const Duration(days: 1, hours: 3)), '1d 3h');
      expect(
        formatCountdown(const Duration(hours: -1, minutes: -5)),
        '-1h 05m',
      );
    });

    test('remaining is negative once the due date has passed', () {
      final SlaTarget t = ticket('a', risk: 100).targets.single;
      expect(t.remaining(DateTime.utc(2030, 1, 1, 13))!.isNegative, isTrue);
      expect(
        const HelpdeskStrings('en').countdown(const Duration(minutes: -30)),
        'overdue by 30m',
      );
      expect(
        const HelpdeskStrings('it').countdown(const Duration(minutes: 30)),
        'scade tra 30m',
      );
    });
  });

  group('push payload', () {
    test('parses an SLA escalation push with string values (FCM data is stringly typed)', () {
      final HelpdeskPushPayload? p = HelpdeskPushPayload.tryParse(
        <String, dynamic>{
          'type': 'helpdesk_sla_escalation',
          'ticket_id': '42',
          'ticket_number': 'TK-42',
          'priority': 'critical',
          'target': 'next_update',
          'threshold_percent': '75',
          'elapsed_percent': '101.5',
          'action': 'notify',
        },
      );

      expect(p, isNotNull);
      expect(p!.type, HelpdeskPushType.slaEscalation);
      expect(p.ticketId, '42');
      expect(p.priority, TicketPriority.critical);
      expect(p.target, SlaTargetKind.nextUpdate);
      expect(p.thresholdPercent, 75);
      expect(p.elapsedPercent, 101.5);
      expect(p.isBreach, isTrue);
      expect(p.alertLevel, HelpdeskAlertLevel.critical);
      expect(p.routeName, '/helpdesk/tickets/42');
    });

    test('an assignment is urgent for P1/P2 only', () {
      HelpdeskPushPayload parse(String priority) =>
          HelpdeskPushPayload.tryParse(<String, dynamic>{
            'type': 'helpdesk_ticket_assigned',
            'ticket_id': '1',
            'priority': priority,
          })!;

      expect(parse('critical').isUrgent, isTrue);
      expect(parse('critical').alertLevel, HelpdeskAlertLevel.critical);
      expect(parse('high').isUrgent, isTrue);
      expect(parse('high').alertLevel, HelpdeskAlertLevel.high);
      expect(parse('medium').isUrgent, isFalse);
      expect(parse('low').alertLevel, HelpdeskAlertLevel.normal);
    });

    test('an SLA warning below 100% is a high alert, not a breach', () {
      final HelpdeskPushPayload p = HelpdeskPushPayload.tryParse(
        <String, dynamic>{
          'type': 'helpdesk_sla_escalation',
          'ticket_id': '1',
          'priority': 'low',
          'elapsed_percent': 80,
        },
      )!;

      expect(p.isBreach, isFalse);
      expect(p.isUrgent, isTrue);
      expect(p.alertLevel, HelpdeskAlertLevel.high);
    });

    test('rejects other push types and payloads without a ticket', () {
      expect(
        HelpdeskPushPayload.tryParse(<String, dynamic>{
          'type': 'purchase_requisition_approval',
          'ticket_id': '1',
        }),
        isNull,
      );
      expect(
        HelpdeskPushPayload.tryParse(<String, dynamic>{
          'type': 'helpdesk_ticket_assigned',
        }),
        isNull,
      );
      expect(HelpdeskPushPayload.tryParse(<String, dynamic>{}), isNull);
    });
  });

  group('deep links', () {
    test(
      'extracts the ticket id from custom scheme, https and plain paths',
      () {
        expect(
          HelpdeskPushPayload.ticketIdOfUri(
            Uri.parse('fatturafacile://helpdesk/tickets/abc'),
          ),
          'abc',
        );
        expect(
          HelpdeskPushPayload.ticketIdOfUri(
            Uri.parse('https://app.fatturafacile.eu/helpdesk/tickets/7?x=1'),
          ),
          '7',
        );
        expect(
          HelpdeskPushPayload.ticketIdOfUri(Uri.parse('/helpdesk/tickets/9')),
          '9',
        );
      },
    );

    test('ignores unrelated or incomplete links', () {
      expect(
        HelpdeskPushPayload.ticketIdOfUri(Uri.parse('/helpdesk/tickets')),
        isNull,
      );
      expect(
        HelpdeskPushPayload.ticketIdOfUri(
          Uri.parse('/procurement/purchase-requisitions/5'),
        ),
        isNull,
      );
    });

    test('the route name round-trips through the parser', () {
      expect(
        HelpdeskPushPayload.ticketIdOfUri(
          Uri.parse(helpdeskTicketRoute('xyz')),
        ),
        'xyz',
      );
    });
  });

  group('strings', () {
    test('every locale defines every label', () {
      for (final MapEntry<String, Map<HL, String>> t
          in helpdeskLocaleTables.entries) {
        for (final HL key in HL.values) {
          expect(t.value[key], isNotNull, reason: '${t.key} misses $key');
          expect(t.value[key], isNotEmpty, reason: '${t.key} blank $key');
        }
      }
    });

    test('unknown languages fall back to English', () {
      expect(const HelpdeskStrings('es')(HL.title), 'Helpdesk queue');
    });
  });
}
