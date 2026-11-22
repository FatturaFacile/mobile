import 'package:fattura_facile/design/ff_tokens.dart';
import 'package:fattura_facile/features/receivables/domain/money.dart';
import 'package:fattura_facile/features/receivables/domain/receivables_models.dart';
import 'package:fattura_facile/features/receivables/presentation/receivables_controller.dart';
import 'package:fattura_facile/features/receivables/presentation/receivables_pages.dart';
import 'package:fattura_facile/features/receivables/presentation/receivables_statement_page.dart';
import 'package:fattura_facile/features/receivables/presentation/receivables_widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support.dart';

const List<LocalizationsDelegate<dynamic>> _delegates =
    <LocalizationsDelegate<dynamic>>[
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ];

void main() {
  late FakeReceivablesRepository repo;
  late FakeStatementExporter exporter;

  setUp(() {
    repo = FakeReceivablesRepository()
      ..dashboardRemote = ReceivablesDashboard.fromJson(dashboardJson())
      ..agingRemote = AgingReport.fromJson(agingJson())
      ..agingCache = AgingReport.fromJson(agingJson())
      ..credit = CreditPosition.fromJson(creditJson())
      ..risk = RiskScore.fromJson(riskJson())
      ..unreconciled = <UnreconciledPayment>[
        UnreconciledPayment.fromJson(paymentJson()),
      ]
      ..items = <ReceivableItem>[
        item('i1', days: 0, open: '100.00', number: 'FT-1'),
        item('i2', days: 7, open: '200.00', number: 'FT-2', status: 'overdue'),
        item('i3', days: 30, open: '50.00', number: 'FT-3', status: 'overdue'),
      ]
      ..statementRemote = CustomerStatement.fromJson(statementJson());
    exporter = FakeStatementExporter();
  });

  Widget host(Widget child, {Locale locale = const Locale('en')}) =>
      ProviderScope(
        key: UniqueKey(),
        overrides: [
          receivablesRepositoryProvider.overrideWithValue(repo),
          receivablesTenantIdProvider.overrideWithValue('t1'),
          receivablesClockProvider.overrideWithValue(
            () => DateTime(2030, 3, 4),
          ),
          statementExporterProvider.overrideWithValue(exporter),
        ],
        child: MaterialApp(
          theme: ffThemeData(),
          locale: locale,
          localizationsDelegates: _delegates,
          home: child,
        ),
      );

  void tall(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  String textOf(WidgetTester tester, String key) =>
      tester.widget<Text>(find.byKey(Key(key))).data!;

  Future<void> openCustomer(
    WidgetTester tester, {
    String? bucket,
    Locale locale = const Locale('en'),
  }) async {
    tall(tester);
    await tester.pumpWidget(
      host(
        CustomerCreditPage(
          customerId: 'c1',
          customerName: 'Rossi SA',
          initialBucket: bucket,
        ),
        locale: locale,
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openItem(WidgetTester tester, String id) async {
    await openCustomer(tester);
    await tester.tap(find.byKey(Key('item-row-$id')));
    await tester.pumpAndSettle();
  }

  group('dashboard', () {
    testWidgets('shows the KPIs, the blocked customers and the customers', (
      WidgetTester tester,
    ) async {
      tall(tester);
      await tester.pumpWidget(host(const ReceivablesDashboardPage()));
      await tester.pumpAndSettle();

      expect(find.text('Receivables'), findsOneWidget);
      expect(textOf(tester, 'kpi-exposure-value'), 'CHF 1,500.00');
      expect(textOf(tester, 'kpi-open-value'), 'CHF 1,000.00');
      expect(textOf(tester, 'kpi-overdue-value'), 'CHF 500.00');
      expect(textOf(tester, 'kpi-dso-value'), '42.5 days');
      expect(textOf(tester, 'kpi-provision-value'), 'CHF 12.50');
      expect(textOf(tester, 'kpi-blocked-value'), '1');

      expect(find.byKey(const Key('blocked-c2')), findsOneWidget);
      expect(find.textContaining('limit_exceeded'), findsOneWidget);
      expect(find.byKey(const Key('customer-row-c1')), findsOneWidget);
      expect(find.text('Rossi SA'), findsOneWidget);
      expect(find.byKey(const Key('receivables-offline')), findsNothing);
    });

    testWidgets('renders the buckets the server sent, not a hardcoded set', (
      WidgetTester tester,
    ) async {
      tall(tester);
      await tester.pumpWidget(host(const ReceivablesDashboardPage()));
      await tester.pumpAndSettle();

      for (final String key in <String>[
        'current',
        '1_15',
        '16_45',
        '46_plus',
      ]) {
        expect(find.byKey(Key('aging-bucket-$key')), findsOneWidget);
      }
      expect(find.byKey(const Key('aging-bucket-1_30')), findsNothing);
      expect(find.byKey(const Key('aging-bucket-121_plus')), findsNothing);
      expect(find.text('Not yet due'), findsOneWidget);
      expect(find.text('1-15 days'), findsOneWidget);
      expect(find.text('16-45 days'), findsOneWidget);
      expect(find.text('46+ days'), findsOneWidget);
      expect(textOf(tester, 'aging-total-1_15'), 'CHF 300.00');
      expect(textOf(tester, 'aging-total-46_plus'), 'CHF 50.00');
    });

    testWidgets('a bucket drills down to its customers and then to the items', (
      WidgetTester tester,
    ) async {
      tall(tester);
      await tester.pumpWidget(host(const ReceivablesDashboardPage()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('aging-bucket-16_45')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('bucket-customer-c2')), findsOneWidget);
      expect(find.byKey(const Key('bucket-customer-c1')), findsNothing);
      expect(find.text('CHF 150.00'), findsOneWidget);

      await tester.tap(find.byKey(const Key('bucket-customer-c2')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('customer-title')), findsOneWidget);
      expect(find.text('Bianchi Sagl'), findsOneWidget);
      // The bucket filter of the drill-down is selected.
      expect(
        tester
            .widget<ChoiceChip>(find.byKey(const Key('bucket-16_45')))
            .selected,
        isTrue,
      );
    });

    testWidgets('a bucket without customers says so', (
      WidgetTester tester,
    ) async {
      tall(tester);
      await tester.pumpWidget(host(const AgingBucketPage(bucketKey: '1_30')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('bucket-empty')), findsOneWidget);
    });

    testWidgets('a blocked customer opens its credit page', (
      WidgetTester tester,
    ) async {
      tall(tester);
      await tester.pumpWidget(host(const ReceivablesDashboardPage()));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('blocked-c2')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('credit-card')), findsOneWidget);
    });

    testWidgets(
      'offline shows the cached copy with a banner and the pending count',
      (WidgetTester tester) async {
        tall(tester);
        repo
          ..dashboardCache = ReceivablesDashboard.fromJson(dashboardJson())
          ..refreshError = const ReceivablesException(
            ReceivablesErrorKind.offline,
          )
          ..pending = const <PendingBooking>[
            PendingBooking(
              queueUuid: 'q1',
              kind: ReceivablesActionKind.allocation,
              rejected: false,
              itemId: 'i1',
            ),
            PendingBooking(
              queueUuid: 'q2',
              kind: ReceivablesActionKind.dispute,
              rejected: false,
              itemId: 'i2',
            ),
          ];
        await tester.pumpWidget(host(const ReceivablesDashboardPage()));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('receivables-offline')), findsOneWidget);
        expect(textOf(tester, 'kpi-open-value'), 'CHF 1,000.00');
        expect(find.byKey(const Key('receivables-error')), findsNothing);
        expect(find.text('2 bookings waiting to sync'), findsOneWidget);
      },
    );

    testWidgets('a user without access sees the forbidden message', (
      WidgetTester tester,
    ) async {
      repo.refreshError = const ReceivablesException(
        ReceivablesErrorKind.forbidden,
      );
      await tester.pumpWidget(host(const ReceivablesDashboardPage()));
      await tester.pumpAndSettle();
      expect(
        find.text('You do not have access to this function'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('kpi-open')), findsNothing);
    });

    testWidgets('several currencies offer a switch that reloads', (
      WidgetTester tester,
    ) async {
      tall(tester);
      final Map<String, dynamic> json = dashboardJson();
      json['aging'] = agingJson(currencies: <String>['CHF', 'EUR']);
      repo.dashboardRemote = ReceivablesDashboard.fromJson(json);
      await tester.pumpWidget(host(const ReceivablesDashboardPage()));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<ChoiceChip>(find.byKey(const Key('currency-CHF')))
            .selected,
        isTrue,
      );
      await tester.tap(find.byKey(const Key('currency-EUR')));
      await tester.pumpAndSettle();
      expect(repo.dashboardCurrencies.last, 'EUR');
    });

    testWidgets('an empty portfolio shows the empty states', (
      WidgetTester tester,
    ) async {
      tall(tester);
      final Map<String, dynamic> json = dashboardJson();
      json['aging'] = <String, dynamic>{
        'buckets': customBuckets,
        'totals': <String, dynamic>{},
        'total_open': '0.00',
        'customers': <dynamic>[],
      };
      json['blocked'] = <dynamic>[];
      repo.dashboardRemote = ReceivablesDashboard.fromJson(json);
      await tester.pumpWidget(host(const ReceivablesDashboardPage()));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('blocked-empty')), findsOneWidget);
      expect(find.byKey(const Key('aging-empty')), findsOneWidget);
      expect(find.byKey(const Key('customers-empty')), findsOneWidget);
    });

    testWidgets('follows the Italian and German locales', (
      WidgetTester tester,
    ) async {
      tall(tester);
      await tester.pumpWidget(
        host(const ReceivablesDashboardPage(), locale: const Locale('it')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Crediti clienti'), findsOneWidget);
      expect(textOf(tester, 'kpi-open-value'), 'CHF 1.000,00');
      expect(find.text('1-15 giorni'), findsOneWidget);

      await tester.pumpWidget(
        host(const ReceivablesDashboardPage(), locale: const Locale('de')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Debitoren'), findsOneWidget);
      expect(textOf(tester, 'kpi-open-value'), 'CHF 1’000.00');
      expect(find.text('1-15 Tage'), findsOneWidget);
    });
  });

  group('customer credit', () {
    testWidgets(
      'shows limit, exposure components, gauge, available credit and risk',
      (WidgetTester tester) async {
        await openCustomer(tester);

        expect(find.text('Rossi SA'), findsOneWidget);
        expect(find.text('CHF 1,000.00'), findsOneWidget); // limit
        expect(find.text('Block orders'), findsOneWidget);
        expect(textOf(tester, 'utilisation-value'), '50.0%');
        expect(
          tester
              .widget<LinearProgressIndicator>(
                find.byKey(const Key('utilisation-gauge')),
              )
              .value,
          0.5,
        );
        expect(find.text('CHF 600.00'), findsOneWidget); // open invoices
        expect(
          find.text('CHF 100.00'),
          findsWidgets,
        ); // unbilled delivery notes
        expect(
          find.text('CHF -50.00'),
          findsOneWidget,
        ); // unreconciled payments
        expect(find.text('CHF 700.00'), findsOneWidget); // total exposure
        expect(find.text('CHF 300.00'), findsWidgets); // available credit
        expect(find.text('High · Score 62'), findsOneWidget);
      },
    );

    testWidgets('a blocked customer gets the red banner with the reason', (
      WidgetTester tester,
    ) async {
      repo.credit = CreditPosition.fromJson(
        creditJson(blocked: true, outcome: 'block', utilization: 105),
      );
      await openCustomer(tester);
      expect(find.byKey(const Key('credit-banner-blocked')), findsOneWidget);
      expect(find.byKey(const Key('credit-banner-warning')), findsNothing);
      expect(find.text('Credit block'), findsOneWidget);
      expect(textOf(tester, 'credit-banner-reason'), 'Limit exceeded');
      expect(textOf(tester, 'utilisation-value'), '105.0%');
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byKey(const Key('utilisation-gauge')),
            )
            .value,
        1.0,
      );
    });

    testWidgets('a customer close to the limit gets the warning banner', (
      WidgetTester tester,
    ) async {
      repo.credit = CreditPosition.fromJson(
        creditJson(outcome: 'warning', utilization: 90),
      );
      await openCustomer(tester);
      expect(find.byKey(const Key('credit-banner-warning')), findsOneWidget);
      expect(find.byKey(const Key('credit-banner-blocked')), findsNothing);
      expect(textOf(tester, 'utilisation-value'), '90.0%');
    });

    testWidgets(
      'active overrides are listed with scope, expiry and authoriser',
      (WidgetTester tester) async {
        repo.credit = CreditPosition.fromJson(
          creditJson(
            overrides: <Map<String, dynamic>>[
              overrideJson(expiresAt: '2031-01-01T00:00:00Z'),
              overrideJson(id: 'o2', revokedAt: '2030-01-06T00:00:00Z'),
              overrideJson(id: 'o3', expiresAt: '2030-01-10T00:00:00Z'),
            ],
          ),
        );
        await openCustomer(tester);
        expect(find.byKey(const Key('override-o1')), findsOneWidget);
        // Revoked and expired ones are not shown.
        expect(find.byKey(const Key('override-o2')), findsNothing);
        expect(find.byKey(const Key('override-o3')), findsNothing);
        expect(find.text('Override active'), findsOneWidget);
        expect(find.textContaining('orders'), findsWidgets);
        expect(find.textContaining('authorized by Anna'), findsOneWidget);
        expect(find.textContaining('until 2031-01-01'), findsOneWidget);
      },
    );

    testWidgets('without a limit there is no gauge and no available credit', (
      WidgetTester tester,
    ) async {
      repo.credit = CreditPosition.fromJson(creditJson(withLimit: false));
      await openCustomer(tester);
      expect(find.byKey(const Key('credit-no-limit')), findsOneWidget);
      expect(find.byKey(const Key('utilisation-gauge')), findsNothing);
      expect(find.byKey(const Key('credit-available')), findsNothing);
    });

    testWidgets(
      'lists the open items with status, due date and amount, most overdue first',
      (WidgetTester tester) async {
        await openCustomer(tester);
        expect(find.byKey(const Key('item-row-i1')), findsOneWidget);
        expect(textOf(tester, 'item-open-i2'), 'CHF 200.00');
        expect(find.textContaining('30 days overdue'), findsOneWidget);
        expect(find.text('Overdue'), findsNWidgets(2));
        final double i3 = tester
            .getTopLeft(find.byKey(const Key('item-row-i3')))
            .dy;
        final double i2 = tester
            .getTopLeft(find.byKey(const Key('item-row-i2')))
            .dy;
        final double i1 = tester
            .getTopLeft(find.byKey(const Key('item-row-i1')))
            .dy;
        expect(i3, lessThan(i2));
        expect(i2, lessThan(i1));
      },
    );

    testWidgets('the aging chips filter the items by the server buckets', (
      WidgetTester tester,
    ) async {
      await openCustomer(tester);
      expect(find.byKey(const Key('bucket-all')), findsOneWidget);
      for (final String key in <String>[
        'current',
        '1_15',
        '16_45',
        '46_plus',
      ]) {
        expect(find.byKey(Key('bucket-$key')), findsOneWidget);
      }
      await tester.tap(find.byKey(const Key('bucket-1_15')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('item-row-i2')), findsOneWidget);
      expect(find.byKey(const Key('item-row-i1')), findsNothing);
      expect(find.byKey(const Key('item-row-i3')), findsNothing);

      await tester.tap(find.byKey(const Key('bucket-46_plus')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('items-empty')), findsOneWidget);

      await tester.tap(find.byKey(const Key('bucket-all')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('item-row-i1')), findsOneWidget);
    });

    testWidgets('offline shows the cached copy', (WidgetTester tester) async {
      repo.refreshError = const ReceivablesException(
        ReceivablesErrorKind.offline,
      );
      await openCustomer(tester);
      expect(find.byKey(const Key('customer-offline')), findsOneWidget);
      expect(find.byKey(const Key('credit-card')), findsOneWidget);
      expect(find.byKey(const Key('item-row-i1')), findsOneWidget);
    });

    testWidgets(
      'a queued booking is flagged on its item and a refused one offers retry and dismiss',
      (WidgetTester tester) async {
        repo.pending = const <PendingBooking>[
          PendingBooking(
            queueUuid: 'q1',
            kind: ReceivablesActionKind.allocation,
            rejected: false,
            itemId: 'i1',
          ),
          PendingBooking(
            queueUuid: 'q2',
            kind: ReceivablesActionKind.dispute,
            rejected: true,
            itemId: 'i2',
            detail: 'Item already settled',
          ),
        ];
        await openCustomer(tester);
        expect(find.byKey(const Key('item-pending-i1')), findsOneWidget);
        expect(find.byKey(const Key('item-pending-i2')), findsOneWidget);
        expect(find.text('Item already settled'), findsOneWidget);
        expect(find.byKey(const Key('pending-retry-q1')), findsNothing);

        await tester.tap(find.byKey(const Key('pending-retry-q2')));
        await tester.pumpAndSettle();
        expect(repo.retried, <String>['q2']);
        await tester.tap(find.byKey(const Key('pending-dismiss-q2')));
        await tester.pumpAndSettle();
        expect(repo.dismissed, <String>['q2']);
      },
    );

    testWidgets('opens the customer statement', (WidgetTester tester) async {
      await openCustomer(tester);
      await tester.tap(find.byKey(const Key('open-statement')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('statement-period')), findsOneWidget);
    });
  });

  group('bookings', () {
    testWidgets(
      'an amount above the open amount is refused before anything is queued',
      (WidgetTester tester) async {
        await openItem(tester, 'i2');
        expect(textOf(tester, 'item-detail-open'), 'CHF 200.00');

        await tester.tap(find.byKey(const Key('item-allocate')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('allocation-amount')),
          '250',
        );
        await tester.tap(find.byKey(const Key('allocation-submit')));
        await tester.pumpAndSettle();

        expect(
          find.text('The amount is higher than the open amount'),
          findsOneWidget,
        );
        expect(repo.allocations, isEmpty);
        expect(find.byKey(const Key('allocation-submit')), findsOneWidget);
      },
    );

    testWidgets(
      'a valid payment is booked, the sheet closes and the user is told',
      (WidgetTester tester) async {
        await openItem(tester, 'i2');
        await tester.tap(find.byKey(const Key('item-allocate')));
        await tester.pumpAndSettle();

        // The amount starts at the open amount.
        expect(
          tester
              .widget<TextField>(find.byKey(const Key('allocation-amount')))
              .controller!
              .text,
          '200.00',
        );
        await tester.enterText(
          find.byKey(const Key('allocation-amount')),
          '60,5',
        );
        await tester.enterText(
          find.byKey(const Key('allocation-reference')),
          'BANK-9',
        );
        await tester.tap(find.byKey(const Key('allocation-submit')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('allocation-submit')), findsNothing);
        final AllocationDraft sent = repo.allocations.single.single;
        expect(sent.itemId, 'i2');
        expect(sent.type, AllocationType.payment);
        expect(sent.amount, Money.parse('60.50'));
        expect(sent.reference, 'BANK-9');
        expect(sent.valueDate, DateTime(2030, 3, 4));
        expect(find.text('Booking saved'), findsWidgets);
        // The open amount on the detail page follows the booking.
        expect(textOf(tester, 'item-detail-open'), 'CHF 139.50');
      },
    );

    testWidgets('a payment can be taken from an unreconciled payment', (
      WidgetTester tester,
    ) async {
      await openItem(tester, 'i2');
      await tester.tap(find.byKey(const Key('item-allocate')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('allocation-source-le1')), findsOneWidget);
      await tester.tap(find.byKey(const Key('allocation-source-le1')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('allocation-amount')), '70');
      await tester.tap(find.byKey(const Key('allocation-submit')));
      await tester.pumpAndSettle();
      expect(
        find.text('The amount is higher than what is left on the payment'),
        findsOneWidget,
      );
      expect(repo.allocations, isEmpty);

      await tester.enterText(find.byKey(const Key('allocation-amount')), '60');
      await tester.tap(find.byKey(const Key('allocation-submit')));
      await tester.pumpAndSettle();
      expect(repo.allocations.single.single.sourceId, 'le1');
    });

    testWidgets('a credit note needs its ID', (WidgetTester tester) async {
      await openItem(tester, 'i2');
      await tester.tap(find.byKey(const Key('item-allocate')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('allocation-type-credit_note')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('allocation-amount')), '10');
      await tester.tap(find.byKey(const Key('allocation-submit')));
      await tester.pumpAndSettle();
      expect(find.text('The credit note ID is required'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('allocation-credit-note')),
        'cn-1',
      );
      await tester.tap(find.byKey(const Key('allocation-submit')));
      await tester.pumpAndSettle();
      final AllocationDraft sent = repo.allocations.single.single;
      expect(sent.type, AllocationType.creditNote);
      expect(sent.sourceId, 'cn-1');
    });

    testWidgets(
      'write-off and discount are offered, a debit adjustment is not',
      (WidgetTester tester) async {
        await openItem(tester, 'i2');
        await tester.tap(find.byKey(const Key('item-allocate')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('allocation-type-write_off')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('allocation-type-discount')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('allocation-type-debit_adjustment')),
          findsNothing,
        );
      },
    );

    testWidgets('offline the booking is queued and the message says so', (
      WidgetTester tester,
    ) async {
      repo.nextStatus = BookingStatus.queued;
      await openItem(tester, 'i2');
      await tester.tap(find.byKey(const Key('item-allocate')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('allocation-submit')));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'No connection: the booking is sent as soon as you are online',
        ),
        findsWidgets,
      );
      expect(repo.allocations, hasLength(1));
    });

    testWidgets('a settled item cannot be booked', (WidgetTester tester) async {
      repo.items = <ReceivableItem>[
        item('i9', open: '0.00', status: 'paid', number: 'FT-9'),
      ];
      await openItem(tester, 'i9');
      expect(find.byKey(const Key('item-allocate')), findsNothing);
      expect(find.byKey(const Key('item-dispute')), findsNothing);
    });

    testWidgets('a dispute needs a reason and is then sent', (
      WidgetTester tester,
    ) async {
      await openItem(tester, 'i2');
      await tester.tap(find.byKey(const Key('item-dispute')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('dispute-confirm')));
      await tester.pumpAndSettle();
      expect(find.text('Enter the reason of the dispute'), findsOneWidget);
      expect(repo.disputes, isEmpty);

      await tester.enterText(
        find.byKey(const Key('dispute-reason')),
        'wrong price',
      );
      await tester.tap(find.byKey(const Key('dispute-confirm')));
      await tester.pumpAndSettle();
      expect(repo.disputes.single, (
        itemId: 'i2',
        disputed: true,
        reason: 'wrong price',
      ));
      expect(find.text('Item marked as disputed'), findsWidgets);
    });

    testWidgets(
      'a disputed item offers to lift the dispute without asking for a reason',
      (WidgetTester tester) async {
        repo.items = <ReceivableItem>[
          ReceivableItem.fromJson(
            itemJson('i5', status: 'disputed', disputeReason: 'wrong price'),
          ),
        ];
        await openItem(tester, 'i5');
        expect(textOf(tester, 'item-dispute-reason'), 'wrong price');
        await tester.tap(find.byKey(const Key('item-dispute')));
        await tester.pumpAndSettle();
        expect(repo.disputes.single, (
          itemId: 'i5',
          disputed: false,
          reason: null,
        ));
      },
    );

    testWidgets(
      'an allocation can be reversed after confirmation, a reversed one cannot',
      (WidgetTester tester) async {
        repo.items = <ReceivableItem>[
          item(
            'i4',
            open: '60.00',
            status: 'partially_paid',
            allocations: <Map<String, dynamic>>[
              allocationJson('a1', 'i4'),
              allocationJson('a2', 'i4', reversedAt: '2030-01-11T10:00:00Z'),
            ],
          ),
        ];
        await openItem(tester, 'i4');
        expect(find.byKey(const Key('allocation-a1')), findsOneWidget);
        expect(find.byKey(const Key('reverse-a1')), findsOneWidget);
        expect(find.byKey(const Key('reverse-a2')), findsNothing);
        expect(find.textContaining('Reversed'), findsOneWidget);

        await tester.tap(find.byKey(const Key('reverse-a1')));
        await tester.pumpAndSettle();
        expect(find.text('Reverse this allocation?'), findsOneWidget);
        await tester.tap(find.byKey(const Key('reverse-confirm')));
        await tester.pumpAndSettle();
        expect(repo.reversals.single, (itemId: 'i4', allocationId: 'a1'));
        expect(find.text('Allocation reversed'), findsWidgets);
      },
    );

    testWidgets('cancelling the confirmation reverses nothing', (
      WidgetTester tester,
    ) async {
      repo.items = <ReceivableItem>[
        item(
          'i4',
          allocations: <Map<String, dynamic>>[allocationJson('a1', 'i4')],
        ),
      ];
      await openItem(tester, 'i4');
      await tester.tap(find.byKey(const Key('reverse-a1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(repo.reversals, isEmpty);
    });
  });

  group('statement', () {
    testWidgets('shows the balances and the movements', (
      WidgetTester tester,
    ) async {
      tall(tester);
      await tester.pumpWidget(
        host(
          const CustomerStatementPage(
            customerId: 'c1',
            customerName: 'Rossi SA',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Customer statement · Rossi SA'), findsOneWidget);
      expect(textOf(tester, 'statement-period'), '2030-01-01 to 2030-02-10');
      expect(find.text('CHF 100.00'), findsWidgets); // opening balance
      expect(find.text('CHF 280.00'), findsWidgets); // closing balance
      expect(find.byKey(const Key('movement-0')), findsOneWidget);
      expect(find.byKey(const Key('movement-1')), findsOneWidget);
      expect(find.text('CHF -120.00'), findsOneWidget);
      expect(find.byKey(const Key('statement-offline')), findsNothing);
    });

    testWidgets('offline shows the cached statement', (
      WidgetTester tester,
    ) async {
      tall(tester);
      repo
        ..statementCache = CustomerStatement.fromJson(statementJson())
        ..refreshError = const ReceivablesException(
          ReceivablesErrorKind.offline,
        );
      await tester.pumpWidget(
        host(const CustomerStatementPage(customerId: 'c1')),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('statement-offline')), findsOneWidget);
      expect(find.byKey(const Key('movement-0')), findsOneWidget);
    });

    testWidgets('PDF and XLSX are downloaded and shared', (
      WidgetTester tester,
    ) async {
      tall(tester);
      await tester.pumpWidget(
        host(const CustomerStatementPage(customerId: 'c1')),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('export-pdf')));
      await tester.pumpAndSettle();
      expect(find.text('Statement ready to share'), findsOneWidget);
      expect(exporter.shared.single.mimeType, 'application/pdf');
      expect(exporter.shared.single.fileName, endsWith('.pdf'));

      await tester.tap(find.byKey(const Key('export-xlsx')));
      await tester.pumpAndSettle();
      expect(exporter.shared.last.fileName, endsWith('.xlsx'));
      expect(repo.downloads.map((d) => d.format), <StatementFormat>[
        StatementFormat.pdf,
        StatementFormat.xlsx,
      ]);
    });

    testWidgets('exporting offline explains that a connection is needed', (
      WidgetTester tester,
    ) async {
      tall(tester);
      repo.downloadError = const ReceivablesException(
        ReceivablesErrorKind.offline,
      );
      await tester.pumpWidget(
        host(const CustomerStatementPage(customerId: 'c1')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('export-pdf')));
      await tester.pumpAndSettle();
      expect(find.text('Connect to download the statement'), findsOneWidget);
      expect(exporter.shared, isEmpty);
    });

    testWidgets('a failing share sheet shows the failure', (
      WidgetTester tester,
    ) async {
      tall(tester);
      exporter.failWith = StateError('no share target');
      await tester.pumpWidget(
        host(const CustomerStatementPage(customerId: 'c1')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('export-xlsx')));
      await tester.pumpAndSettle();
      expect(find.text('The statement could not be exported'), findsOneWidget);
    });
  });

  group('shared widgets', () {
    Widget wrap(Widget child) => MaterialApp(
      theme: ffThemeData(),
      localizationsDelegates: _delegates,
      home: Scaffold(body: child),
    );

    testWidgets('CreditBlockBanner is hidden for a healthy position', (
      WidgetTester tester,
    ) async {
      final CreditPosition ok = CreditPosition.fromJson(<String, dynamic>{
        ...creditJson(),
        'exposure': <String, dynamic>{},
      });
      await tester.pumpWidget(wrap(CreditBlockBanner(position: ok)));
      expect(find.byKey(const Key('credit-banner-blocked')), findsNothing);
      expect(find.byKey(const Key('credit-banner-warning')), findsNothing);
    });

    testWidgets('CreditBlockBanner tells a credit hold apart from a block', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          CreditBlockBanner(
            position: CreditPosition.fromJson(creditJson(hold: true)),
          ),
        ),
      );
      expect(find.text('The customer is on credit hold.'), findsOneWidget);
      await tester.pumpWidget(
        wrap(
          CreditBlockBanner(
            position: CreditPosition.fromJson(creditJson(blocked: true)),
          ),
        ),
      );
      expect(
        find.text(
          'New orders or delivery notes for this customer are blocked.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('UtilisationGauge clamps the bar and prints the percentage', (
      WidgetTester tester,
    ) async {
      for (final (double? percent, double bar, String text)
          in <(double?, double, String)>[
            (null, 0, '-'),
            (0, 0, '0.0%'),
            (79.5, 0.795, '79.5%'),
            (100, 1, '100.0%'),
            (250, 1, '250.0%'),
          ]) {
        await tester.pumpWidget(wrap(UtilisationGauge(percent: percent)));
        expect(
          tester
              .widget<LinearProgressIndicator>(
                find.byKey(const Key('utilisation-gauge')),
              )
              .value,
          closeTo(bar, 1e-9),
        );
        expect(textOf(tester, 'utilisation-value'), text);
      }
    });

    testWidgets('UtilisationGauge changes colour at 80 and 100 percent', (
      WidgetTester tester,
    ) async {
      final FfColors c = FfColors.light;
      Color colorAt() {
        final LinearProgressIndicator bar = tester
            .widget<LinearProgressIndicator>(
              find.byKey(const Key('utilisation-gauge')),
            );
        return bar.color!;
      }

      await tester.pumpWidget(wrap(const UtilisationGauge(percent: 50)));
      expect(colorAt(), c.success);
      await tester.pumpWidget(wrap(const UtilisationGauge(percent: 85)));
      expect(colorAt(), c.warning);
      await tester.pumpWidget(wrap(const UtilisationGauge(percent: 100)));
      expect(colorAt(), c.danger);
    });
  });
}
