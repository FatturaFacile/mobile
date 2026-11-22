import 'package:fattura_facile/features/helpdesk/domain/helpdesk_models.dart';
import 'package:fattura_facile/features/helpdesk/presentation/helpdesk_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';
import 'helpdesk_domain_test.dart' show ticket;

void main() {
  late FakeHelpdeskRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = FakeHelpdeskRepository()
      ..remote = <QueueTicket>[
        ticket('a'),
        ticket('b', priority: TicketPriority.critical),
        ticket('c', risk: 95),
      ];
    container = ProviderContainer(
      overrides: [
        helpdeskRepositoryProvider.overrideWithValue(repo),
        helpdeskTenantIdProvider.overrideWithValue('t1'),
        helpdeskUserIdProvider.overrideWithValue('u1'),
      ],
    );
  });

  tearDown(() => container.dispose());

  group('queue', () {
    test(
      'load flushes the outbox, refreshes and sorts by risk then priority',
      () async {
        await container.read(helpdeskQueueProvider.notifier).load();

        final HelpdeskQueueState s = container.read(helpdeskQueueProvider);
        expect(s.tickets.map((QueueTicket t) => t.id), <String>['c', 'b', 'a']);
        expect(s.fromCache, isFalse);
        expect(s.loading, isFalse);
        expect(repo.flushes, 1);
      },
    );

    test('offline keeps the cached queue and flags it as a copy', () async {
      repo
        ..cache = <QueueTicket>[ticket('old', priority: TicketPriority.high)]
        ..refreshError = const HelpdeskException(HelpdeskErrorKind.offline);

      await container.read(helpdeskQueueProvider.notifier).load();

      final HelpdeskQueueState s = container.read(helpdeskQueueProvider);
      expect(s.tickets.single.id, 'old');
      expect(s.error!.kind, HelpdeskErrorKind.offline);
    });

    test(
      'filters narrow the list to P1/P2 or to tickets at SLA risk',
      () async {
        final HelpdeskQueueController ctrl = container.read(
          helpdeskQueueProvider.notifier,
        );
        await ctrl.load();

        ctrl.setFilter(QueueFilter.urgent);
        expect(
          container
              .read(helpdeskQueueProvider)
              .visible
              .map((QueueTicket t) => t.id),
          <String>['b'],
        );
        ctrl.setFilter(QueueFilter.atRisk);
        expect(
          container
              .read(helpdeskQueueProvider)
              .visible
              .map((QueueTicket t) => t.id),
          <String>['c'],
        );
      },
    );

    test('forbidden empties the queue', () async {
      repo.refreshError = const HelpdeskException(HelpdeskErrorKind.forbidden);

      await container.read(helpdeskQueueProvider.notifier).load();

      final HelpdeskQueueState s = container.read(helpdeskQueueProvider);
      expect(s.forbidden, isTrue);
      expect(s.tickets, isEmpty);
    });
  });

  group('ticket detail', () {
    test(
      'logs time as the signed-in technician and reports it as sent',
      () async {
        final TicketDetailController ctrl = container.read(
          ticketDetailProvider.notifier,
        );
        await ctrl.load('a');

        await ctrl.logTime(minutes: 30, isBillable: false);

        expect(repo.loggedTime.single.minutes, 30);
        expect(repo.loggedTime.single.tech, 'u1');
        expect(repo.loggedTime.single.billable, isFalse);
        expect(
          container.read(ticketDetailProvider).notice,
          HelpdeskNotice.timeSent,
        );
        expect(container.read(ticketDetailProvider).busy, isFalse);
      },
    );

    test(
      'offline escalation is queued, shown as pending and cannot be sent twice',
      () async {
        repo.nextStatus = ActionStatus.queued;
        final TicketDetailController ctrl = container.read(
          ticketDetailProvider.notifier,
        );
        await ctrl.load('a');

        await ctrl.escalate(EscalationTarget.fieldService);
        await ctrl.escalate(EscalationTarget.fieldService);

        final TicketDetailState s = container.read(ticketDetailProvider);
        expect(repo.escalations, hasLength(1));
        expect(s.notice, HelpdeskNotice.escalateQueued);
        expect(s.escalationPending(EscalationTarget.fieldService), isTrue);
        expect(s.escalationPending(EscalationTarget.rma), isFalse);
      },
    );

    test(
      'a refused action surfaces the server detail and can be dismissed',
      () async {
        repo
          ..nextStatus = ActionStatus.rejected
          ..nextDetail = 'Ticket is closed'
          ..pending = <PendingAction>[
            const PendingAction(
              queueUuid: 'r1',
              ticketId: 'a',
              kind: PendingActionKind.rma,
              rejected: true,
              detail: 'Ticket is closed',
            ),
          ];
        final TicketDetailController ctrl = container.read(
          ticketDetailProvider.notifier,
        );
        await ctrl.load('a');

        await ctrl.escalate(EscalationTarget.rma);
        expect(
          container.read(ticketDetailProvider).notice,
          HelpdeskNotice.rejected,
        );
        expect(
          container.read(ticketDetailProvider).noticeDetail,
          'Ticket is closed',
        );
        // A refused row does not block a new attempt.
        expect(
          container
              .read(ticketDetailProvider)
              .escalationPending(EscalationTarget.rma),
          isFalse,
        );

        await ctrl.dismiss('r1');
        expect(repo.dismissed, <String>['r1']);
        expect(container.read(ticketDetailProvider).pending, isEmpty);
      },
    );

    test(
      'load shows the offline copy when the server is unreachable',
      () async {
        repo
          ..cache = <QueueTicket>[ticket('a')]
          ..context = const CustomerContext(
            contracts: <ContextItem>[ContextItem(title: 'Gold', detail: '3')],
          )
          ..refreshError = const HelpdeskException(HelpdeskErrorKind.offline);

        await container.read(ticketDetailProvider.notifier).load('a');

        final TicketDetailState s = container.read(ticketDetailProvider);
        expect(s.ticket!.number, 'T-a');
        expect(s.context!.contracts.single.title, 'Gold');
        expect(s.error!.kind, HelpdeskErrorKind.offline);
        expect(s.loading, isFalse);
      },
    );
  });
}
