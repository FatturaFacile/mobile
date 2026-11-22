import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:fattura_facile/app/providers.dart';
import 'package:fattura_facile/core/database/app_database.dart';
import 'package:fattura_facile/core/localization/translation_service.dart';
import 'package:fattura_facile/design/ff_tokens.dart';
import 'package:fattura_facile/features/helpdesk/domain/helpdesk_models.dart';
import 'package:fattura_facile/features/helpdesk/notifications/helpdesk_push_handler.dart';
import 'package:fattura_facile/features/helpdesk/presentation/helpdesk_controller.dart';
import 'package:fattura_facile/features/helpdesk/presentation/helpdesk_pages.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'fakes.dart';
import 'helpdesk_domain_test.dart' show ticket;

void main() {
  late AppDatabase db;
  late FakeHelpdeskRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = FakeHelpdeskRepository()
      ..remote = <QueueTicket>[
        ticket('a', number: 'TK-A'),
        ticket('b', number: 'TK-B', priority: TicketPriority.critical),
        ticket('c', number: 'TK-C', priority: TicketPriority.high, risk: 95),
        ticket('d', number: 'TK-D', risk: 120),
      ]
      ..context = const CustomerContext(
        contracts: <ContextItem>[ContextItem(title: 'Gold', detail: '12.5')],
        openInvoices: <ContextItem>[ContextItem(title: 'F-1', detail: '100')],
      )
      ..entries = <TimeEntry>[
        const TimeEntry(
          id: 'e1',
          minutes: 30,
          billingStatus: BillingStatus.contractDeducted,
        ),
      ];
  });

  tearDown(() => db.close());

  Widget host(Widget child, {GlobalKey<NavigatorState>? navKey}) =>
      ProviderScope(
        key: UniqueKey(),
        overrides: [
          helpdeskRepositoryProvider.overrideWithValue(repo),
          helpdeskTenantIdProvider.overrideWithValue('t1'),
          helpdeskUserIdProvider.overrideWithValue('u1'),
          helpdeskClockProvider.overrideWithValue(
            () => DateTime.utc(2030, 1, 1, 11),
          ),
          translationProvider.overrideWithValue(TranslationService(db, Dio())),
        ],
        child: MaterialApp(
          theme: ffThemeData(),
          navigatorKey: navKey,
          home: child,
        ),
      );

  List<String> cardOrder() => <String>[
    for (final Element e
        in find
            .byWidgetPredicate(
              (Widget w) =>
                  w.key is ValueKey<String> &&
                  (w.key! as ValueKey<String>).value.startsWith('ticket-card-'),
            )
            .evaluate())
      (e.widget.key! as ValueKey<String>).value,
  ];

  testWidgets(
    'the queue shows the most urgent tickets first with P1/P2 badges and the SLA countdown',
    (WidgetTester tester) async {
      await tester.pumpWidget(host(const HelpdeskQueuePage()));
      await tester.pumpAndSettle();

      expect(cardOrder(), <String>[
        'ticket-card-d',
        'ticket-card-c',
        'ticket-card-b',
        'ticket-card-a',
      ]);
      expect(find.text('P1'), findsOneWidget);
      expect(find.text('P2'), findsOneWidget);
      // Breached (120%): the chip reads "SLA breached", then the percentage and the countdown.
      expect(
        find.descendant(
          of: find.byKey(const Key('ticket-sla-d')),
          matching: find.textContaining('SLA breached'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('ticket-sla-c')),
          matching: find.textContaining('due in 1h 00m'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('ticket-sla-a')), findsNothing);
    },
  );

  testWidgets('the P1/P2 filter hides the other tickets', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(host(const HelpdeskQueuePage()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('queue-filter-urgent')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('ticket-card-b')), findsOneWidget);
    expect(find.byKey(const Key('ticket-card-c')), findsOneWidget);
    expect(find.byKey(const Key('ticket-card-a')), findsNothing);
    expect(find.byKey(const Key('ticket-card-d')), findsNothing);
  });

  testWidgets(
    'an unreachable server shows the offline copy with a pending marker',
    (WidgetTester tester) async {
      repo
        ..cache = <QueueTicket>[ticket('a', number: 'TK-A')]
        ..refreshError = const HelpdeskException(HelpdeskErrorKind.offline)
        ..pending = <PendingAction>[
          const PendingAction(
            queueUuid: 'q',
            ticketId: 'a',
            kind: PendingActionKind.rma,
            rejected: false,
          ),
        ];

      await tester.pumpWidget(host(const HelpdeskQueuePage()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('queue-offline')), findsOneWidget);
      expect(find.byKey(const Key('ticket-card-a')), findsOneWidget);
      expect(find.byKey(const Key('ticket-pending-a')), findsOneWidget);
    },
  );

  testWidgets('an empty queue says so', (WidgetTester tester) async {
    repo.remote = <QueueTicket>[];

    await tester.pumpWidget(host(const HelpdeskQueuePage()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('queue-empty')), findsOneWidget);
  });

  testWidgets(
    'the ticket detail lists the context and time entries and logs time',
    (WidgetTester tester) async {
      repo.cache = <QueueTicket>[ticket('c', number: 'TK-C', risk: 95)];

      await tester.pumpWidget(host(const HelpdeskTicketPage(ticketId: 'c')));
      await tester.pumpAndSettle();

      expect(find.text('TK-C'), findsOneWidget);
      expect(find.textContaining('Gold · 12.5 h left'), findsOneWidget);
      expect(find.byKey(const Key('time-entry-e1')), findsOneWidget);
      expect(find.text('Deducted from contract'), findsOneWidget);

      await tester.tap(find.byKey(const Key('log-time')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('time-save')));
      await tester.pumpAndSettle();
      expect(find.text('Enter the minutes spent'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('time-minutes')), '45');
      await tester.tap(find.byKey(const Key('time-save')));
      await tester.pumpAndSettle();

      expect(repo.loggedTime.single.minutes, 45);
      expect(repo.loggedTime.single.ticketId, 'c');
      expect(find.text('Time logged'), findsOneWidget);
    },
  );

  testWidgets(
    'one tap escalates to field service after a confirmation; offline it is queued and the button locks',
    (WidgetTester tester) async {
      repo
        ..cache = <QueueTicket>[ticket('c', number: 'TK-C')]
        ..nextStatus = ActionStatus.queued;

      await tester.pumpWidget(host(const HelpdeskTicketPage(ticketId: 'c')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('escalate-field-service')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('escalate-confirm')));
      await tester.pumpAndSettle();

      expect(repo.escalations.single.target, EscalationTarget.fieldService);
      expect(
        find.textContaining('No connection: the escalation is sent'),
        findsOneWidget,
      );
      final FilledButton button = tester.widget<FilledButton>(
        find.byKey(const Key('escalate-field-service')),
      );
      expect(button.onPressed, isNull);
      expect(find.text('Waiting to be sent'), findsOneWidget);
      // RMA is a different escalation and stays available.
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('escalate-rma')))
            .onPressed,
        isNotNull,
      );
    },
  );

  group('push deep link', () {
    testWidgets(
      'a P1 assignment push opens the ticket route and asks for an alert',
      (WidgetTester tester) async {
        final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();
        final List<String?> routes = <String?>[];
        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: navKey,
            home: const SizedBox.shrink(),
            onGenerateRoute: (RouteSettings s) {
              routes.add(s.name);
              return MaterialPageRoute<void>(
                settings: s,
                builder: (_) => const SizedBox.shrink(),
              );
            },
          ),
        );

        final HelpdeskPushResult result = const HelpdeskPushHandler().handle(
          <String, dynamic>{
            'type': 'helpdesk_ticket_assigned',
            'ticket_id': '42',
            'ticket_number': 'TK-42',
            'priority': 'critical',
          },
          navigatorKey: navKey,
        );
        await tester.pumpAndSettle();

        expect(result.outcome, HelpdeskPushOutcome.navigatedUrgent);
        expect(result.alert, isTrue);
        expect(routes.last, '/helpdesk/tickets/42');
      },
    );

    testWidgets(
      'a P3 assignment navigates without an alert, unrelated pushes are ignored',
      (WidgetTester tester) async {
        final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();
        final List<String?> routes = <String?>[];
        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: navKey,
            home: const SizedBox.shrink(),
            onGenerateRoute: (RouteSettings s) {
              routes.add(s.name);
              return MaterialPageRoute<void>(
                settings: s,
                builder: (_) => const SizedBox.shrink(),
              );
            },
          ),
        );
        const HelpdeskPushHandler handler = HelpdeskPushHandler();

        final HelpdeskPushResult calm = handler.handle(<String, dynamic>{
          'type': 'helpdesk_ticket_assigned',
          'ticket_id': '5',
          'priority': 'medium',
        }, navigatorKey: navKey);
        final HelpdeskPushResult other = handler.handle(<String, dynamic>{
          'type': 'purchase_requisition_approval',
          'requisition_id': '1',
        }, navigatorKey: navKey);
        await tester.pumpAndSettle();

        expect(calm.outcome, HelpdeskPushOutcome.navigated);
        expect(calm.alert, isFalse);
        expect(other.outcome, HelpdeskPushOutcome.ignored);
        expect(
          routes.where((String? r) => r == '/helpdesk/tickets/5'),
          hasLength(1),
        );
        expect(
          routes.where((String? r) => r?.contains('purchase') ?? false),
          isEmpty,
        );
      },
    );

    testWidgets('the ticket already on screen is not pushed again', (
      WidgetTester tester,
    ) async {
      final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();
      final List<String?> routes = <String?>[];
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navKey,
          home: const SizedBox.shrink(),
          onGenerateRoute: (RouteSettings s) {
            routes.add(s.name);
            return MaterialPageRoute<void>(
              settings: s,
              builder: (_) => const SizedBox.shrink(),
            );
          },
        ),
      );

      final HelpdeskPushResult r = const HelpdeskPushHandler().handle(
        <String, dynamic>{
          'type': 'helpdesk_sla_escalation',
          'ticket_id': '8',
          'priority': 'high',
          'elapsed_percent': 100,
        },
        navigatorKey: navKey,
        activeTicketId: '8',
      );
      await tester.pumpAndSettle();

      expect(r.alert, isTrue);
      expect(routes.where((String? n) => n == '/helpdesk/tickets/8'), isEmpty);
    });
  });
}
