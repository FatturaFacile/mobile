import 'package:fattura_facile/app/providers.dart';
import 'package:fattura_facile/core/network/api_client.dart';
import 'package:fattura_facile/design/ff_tokens.dart';
import 'package:fattura_facile/features/purchase_orders/domain/purchase_order_models.dart';
import 'package:fattura_facile/features/purchase_orders/presentation/purchase_order_controller.dart';
import 'package:fattura_facile/features/purchase_orders/presentation/purchase_order_pages.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'fakes.dart';
import 'fixtures.dart';

void main() {
  late FakePurchaseOrderRepository repo;

  PurchaseOrder lateOrder() => order(
    id: 'o1',
    status: 'confirmed',
    promised: '2026-11-10',
    lines: <Map<String, dynamic>>[lineJson(promised: null)],
  );

  PurchaseOrder dropshipOrder() => order(
    id: 'o2',
    number: 'PO-0002',
    dropship: true,
    promised: '2026-12-20',
    lines: <Map<String, dynamic>>[lineJson(id: 'l2', promised: null)],
  );

  setUp(() {
    repo = FakePurchaseOrderRepository()
      ..remoteOrders = <PurchaseOrder>[lateOrder(), dropshipOrder()]
      ..remoteOverdue = <OverdueOrder>[OverdueOrder.fromJson(overdueJson())]
      ..remoteDropships = <Dropship>[
        Dropship.fromJson(dropshipJson(orderId: 'o2')),
      ]
      ..confirmations = <PoConfirmation>[
        PoConfirmation.fromJson(confirmationJson()),
      ];
  });

  Widget host(Widget child, {String language = 'en'}) => ProviderScope(
    key: UniqueKey(),
    overrides: [
      purchaseOrderRepositoryProvider.overrideWithValue(repo),
      purchaseOrderTenantIdProvider.overrideWithValue('t1'),
      purchaseOrderClockProvider.overrideWithValue(
        () => DateTime(2026, 11, 23),
      ),
      requestContextProvider.overrideWithValue(
        RequestContext()..languageCode = language,
      ),
    ],
    child: MaterialApp(theme: ffThemeData(), home: child),
  );

  /// Pumps [page] on a tall surface, so the lazily built lists are built whole.
  Future<void> pumpPage(WidgetTester tester, Widget page) {
    tester.view.physicalSize = const Size(800, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    return tester.pumpWidget(page);
  }

  group('workspace', () {
    testWidgets(
      'lists the orders with status, dropship mark and the overdue alert',
      (WidgetTester tester) async {
        await pumpPage(tester, host(const PurchaseOrdersHomePage()));
        await tester.pumpAndSettle();

        expect(find.text('Purchase orders'), findsOneWidget);
        expect(find.byKey(const Key('po-card-o1')), findsOneWidget);
        expect(find.text('Confirmed'), findsOneWidget);
        expect(find.text('Sent'), findsOneWidget);
        expect(find.byKey(const Key('po-overdue-o1')), findsOneWidget);
        expect(find.text('Overdue 13 d'), findsOneWidget);
        expect(find.byKey(const Key('po-overdue-o2')), findsNothing);
        expect(find.byKey(const Key('po-dropship-o2')), findsOneWidget);
        expect(find.text('1 orders are overdue'), findsOneWidget);
        expect(find.textContaining('CHF 924.26'), findsWidgets);
        expect(find.byKey(const Key('po-offline')), findsNothing);
      },
    );

    testWidgets('offline it shows the cached copy under an offline banner', (
      WidgetTester tester,
    ) async {
      repo
        ..cacheOrders = <PurchaseOrder>[lateOrder()]
        ..refreshError = const PoException(PoErrorKind.offline);

      await pumpPage(tester, host(const PurchaseOrdersHomePage()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('po-offline')), findsOneWidget);
      expect(find.byKey(const Key('po-card-o1')), findsOneWidget);
      expect(find.byKey(const Key('po-overdue-banner')), findsOneWidget);
    });

    testWidgets('an empty workspace says so', (WidgetTester tester) async {
      repo
        ..remoteOrders = <PurchaseOrder>[]
        ..remoteOverdue = <OverdueOrder>[]
        ..remoteDropships = <Dropship>[];

      await pumpPage(tester, host(const PurchaseOrdersHomePage()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('po-empty')), findsOneWidget);
      expect(find.byKey(const Key('po-overdue-banner')), findsNothing);
    });

    testWidgets('a write waiting in the outbox is marked on the card', (
      WidgetTester tester,
    ) async {
      repo.pending = <PoPendingAction>[
        const PoPendingAction(
          queueUuid: 'q1',
          targetId: 'o1',
          kind: PoActionKind.confirmation,
        ),
      ];

      await pumpPage(tester, host(const PurchaseOrdersHomePage()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('po-pending-o1')), findsOneWidget);
      expect(find.byKey(const Key('po-pending-o2')), findsNothing);
    });

    testWidgets('speaks the language of the session', (
      WidgetTester tester,
    ) async {
      await pumpPage(
        tester,
        host(const PurchaseOrdersHomePage(), language: 'de-CH'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bestellungen'), findsWidgets);
      expect(find.text('Bestätigt'), findsOneWidget);
      expect(find.text('13 T überfällig'), findsOneWidget);
    });

    testWidgets('the overdue tab sends a reminder from the radar', (
      WidgetTester tester,
    ) async {
      await pumpPage(tester, host(const PurchaseOrdersHomePage()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('po-tab-overdue')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('overdue-card-o1')), findsOneWidget);
      await tester.tap(find.byKey(const Key('overdue-remind-o1')));
      await tester.pumpAndSettle();

      expect(repo.reminded, <String>['o1']);
      expect(find.text('Saved.'), findsOneWidget);
    });

    testWidgets('a reminder that is not yet due cannot be sent', (
      WidgetTester tester,
    ) async {
      repo.remoteOverdue = <OverdueOrder>[
        OverdueOrder.fromJson(overdueJson(due: false)),
      ];

      await pumpPage(tester, host(const PurchaseOrdersHomePage()));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('po-tab-overdue')));
      await tester.pumpAndSettle();

      final FilledButton b = tester.widget<FilledButton>(
        find.byKey(const Key('overdue-remind-o1')),
      );
      expect(b.onPressed, isNull);
      expect(find.text('Reminder interval not elapsed'), findsOneWidget);
    });

    testWidgets('an empty overdue radar says so', (WidgetTester tester) async {
      repo
        ..remoteOverdue = <OverdueOrder>[]
        ..remoteOrders = <PurchaseOrder>[dropshipOrder()];

      await pumpPage(tester, host(const PurchaseOrdersHomePage()));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('po-tab-overdue')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('po-overdue-empty')), findsOneWidget);
    });

    testWidgets('the dropshipments tab lists the shipments with their status', (
      WidgetTester tester,
    ) async {
      await pumpPage(tester, host(const PurchaseOrdersHomePage()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('po-tab-dropships')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('dropship-card-d1')), findsOneWidget);
      expect(find.text('Rossi SA'), findsOneWidget);
      expect(find.text('Shipping note issued'), findsOneWidget);
      expect(find.text('DDT-77'), findsOneWidget);
    });
  });

  group('order detail', () {
    testWidgets(
      'shows both units of a dual unit of measure line with the discounts',
      (WidgetTester tester) async {
        await pumpPage(
          tester,
          host(const PurchaseOrderDetailPage(orderId: 'o1')),
        );
        await tester.pumpAndSettle();

        expect(find.text('PO-0001'), findsOneWidget);
        expect(
          tester.widget<Text>(find.byKey(const Key('po-line-ordered-l1'))).data,
          '10 BOX = 120 PCS',
        );
        expect(
          tester.widget<Text>(find.byKey(const Key('po-line-factor-l1'))).data,
          '1 BOX = 12 PCS',
        );
        expect(
          tester.widget<Text>(find.byKey(const Key('po-line-cascade-l1'))).data,
          '10% + 5%',
        );
      },
    );

    testWidgets(
      'lists the confirmations with their variances and review flag',
      (WidgetTester tester) async {
        await pumpPage(
          tester,
          host(const PurchaseOrderDetailPage(orderId: 'o1')),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('confirmation-c1')), findsOneWidget);
        expect(find.text('AB-991'), findsOneWidget);
        expect(find.text('Needs review'), findsOneWidget);
      },
    );

    testWidgets(
      'an overdue open order offers the reminder and the confirmation',
      (WidgetTester tester) async {
        await pumpPage(
          tester,
          host(const PurchaseOrderDetailPage(orderId: 'o1')),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('po-confirm-button')), findsOneWidget);
        expect(find.byKey(const Key('po-remind-button')), findsOneWidget);

        await tester.tap(find.byKey(const Key('po-remind-button')));
        await tester.pumpAndSettle();

        expect(repo.reminded, <String>['o1']);
      },
    );

    testWidgets('a received order offers neither action', (
      WidgetTester tester,
    ) async {
      repo.remoteOrders = <PurchaseOrder>[order(status: 'received')];

      await pumpPage(
        tester,
        host(const PurchaseOrderDetailPage(orderId: 'o1')),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('po-confirm-button')), findsNothing);
      expect(find.byKey(const Key('po-remind-button')), findsNothing);
    });

    testWidgets('a refused write can be retried or discarded', (
      WidgetTester tester,
    ) async {
      repo.pending = <PoPendingAction>[
        const PoPendingAction(
          queueUuid: 'q1',
          targetId: 'o1',
          kind: PoActionKind.confirmation,
          rejected: true,
          detail: 'Order is closed',
        ),
      ];

      await pumpPage(
        tester,
        host(const PurchaseOrderDetailPage(orderId: 'o1')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Order is closed'), findsOneWidget);
      await tester.tap(find.byKey(const Key('po-discard-q1')));
      await tester.pumpAndSettle();

      expect(repo.dismissed, <String>['q1']);
      expect(find.byKey(const Key('po-pending-q1')), findsNothing);
    });
  });

  group('supplier confirmation form', () {
    Future<void> openForm(WidgetTester tester) async {
      await pumpPage(
        tester,
        host(const PurchaseOrderDetailPage(orderId: 'o1')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('po-confirm-button')));
      await tester.pumpAndSettle();
    }

    testWidgets('requires the confirmation number', (
      WidgetTester tester,
    ) async {
      await openForm(tester);

      await tester.tap(find.byKey(const Key('confirm-submit')));
      await tester.pumpAndSettle();

      expect(find.text('Required'), findsOneWidget);
      expect(repo.confirmed, isEmpty);
    });

    testWidgets('rejects a malformed quantity', (WidgetTester tester) async {
      await openForm(tester);

      await tester.enterText(find.byKey(const Key('confirm-number')), 'AB-991');
      await tester.enterText(find.byKey(const Key('confirm-qty-l1')), 'abc');
      await tester.tap(find.byKey(const Key('confirm-submit')));
      await tester.pumpAndSettle();

      expect(find.text('Invalid number'), findsOneWidget);
      expect(repo.confirmed, isEmpty);
    });

    testWidgets(
      'sends the confirmed quantity, price and reason, then returns to the order',
      (WidgetTester tester) async {
        await openForm(tester);

        await tester.enterText(
          find.byKey(const Key('confirm-number')),
          'AB-991',
        );
        await tester.enterText(find.byKey(const Key('confirm-qty-l1')), '8,5');
        await tester.enterText(
          find.byKey(const Key('confirm-price-l1')),
          '105',
        );
        await tester.enterText(
          find.byKey(const Key('confirm-reason-l1')),
          'shortage',
        );
        await tester.tap(find.byKey(const Key('confirm-submit')));
        await tester.pumpAndSettle();

        expect(repo.confirmed, hasLength(1));
        final ConfirmationInput input = repo.confirmed.single.input;
        expect(input.confirmationNumber, 'AB-991');
        final ConfirmationLineInput line = input.lines.single;
        expect(line.purchaseOrderLineId, 'l1');
        expect(line.confirmedQuantity?.toPlain(), '8.50');
        expect(line.confirmedUnitPrice?.toPlain(), '105.00');
        expect(line.varianceReason, 'shortage');
        expect(find.byKey(const Key('confirm-submit')), findsNothing);
        expect(
          find.byKey(const Key('po-detail-confirmation-number')),
          findsOneWidget,
        );
      },
    );
  });

  group('dropship tracking', () {
    Future<void> openDetail(WidgetTester tester, {String? status}) async {
      if (status != null) {
        repo.remoteDropships = <Dropship>[
          Dropship.fromJson(dropshipJson(status: status, orderId: 'o2')),
        ];
      }
      await pumpPage(tester, host(const DropshipDetailPage(dropshipId: 'd1')));
      await tester.pumpAndSettle();
    }

    testWidgets(
      'shows the recipient, the shipping note and the virtual stock movement',
      (WidgetTester tester) async {
        await openDetail(tester);

        expect(find.text('Rossi SA'), findsOneWidget);
        expect(find.text('Via Roma 12, 6900 Lugano, CH'), findsOneWidget);
        expect(find.text('DDT-77'), findsOneWidget);
        expect(find.textContaining('in 120 PCS'), findsOneWidget);
      },
    );

    testWidgets(
      'records the delivery with the proof reference and the delivered quantity',
      (WidgetTester tester) async {
        await openDetail(tester);

        await tester.tap(find.byKey(const Key('dropship-record-delivery')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('delivery-proof')),
          'POD-9',
        );
        await tester.enterText(find.byKey(const Key('delivery-qty-l2')), '4');
        await tester.tap(find.byKey(const Key('delivery-submit')));
        await tester.pumpAndSettle();

        expect(repo.delivered, hasLength(1));
        final DeliveryInput input = repo.delivered.single.input;
        expect(input.deliveryProofReference, 'POD-9');
        expect(input.lines.single.purchaseOrderLineId, 'l2');
        expect(input.lines.single.quantityDelivered.toPlain(), '4.00');
        expect(find.byKey(const Key('delivery-submit')), findsNothing);
      },
    );

    testWidgets('the proof reference is mandatory', (
      WidgetTester tester,
    ) async {
      await openDetail(tester);

      await tester.tap(find.byKey(const Key('dropship-record-delivery')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('delivery-submit')));
      await tester.pumpAndSettle();

      expect(find.text('Required'), findsOneWidget);
      expect(repo.delivered, isEmpty);
    });

    testWidgets(
      'a delivered shipment shows its proof and no recording button',
      (WidgetTester tester) async {
        repo.remoteDropships = <Dropship>[
          Dropship.fromJson(
            dropshipJson(status: 'delivered', orderId: 'o2')
              ..['delivery_proof_reference'] = 'POD-1'
              ..['delivered_at'] = '2026-11-20T10:00:00+00:00',
          ),
        ];

        await pumpPage(
          tester,
          host(const DropshipDetailPage(dropshipId: 'd1')),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('dropship-record-delivery')), findsNothing);
        expect(
          tester.widget<Text>(find.byKey(const Key('dropship-proof-ref'))).data,
          'POD-1',
        );
        expect(find.text('Delivered'), findsOneWidget);
      },
    );
  });

  group('pricing preview', () {
    testWidgets('previews the cascade and the stock unit price of a box', (
      WidgetTester tester,
    ) async {
      await pumpPage(tester, host(const PricingPreviewPage()));

      await tester.enterText(find.byKey(const Key('pricing-quantity')), '10');
      await tester.enterText(find.byKey(const Key('pricing-price')), '100');
      await tester.enterText(find.byKey(const Key('pricing-cascade')), '10, 5');
      await tester.enterText(find.byKey(const Key('pricing-factor')), '12');
      await tester.enterText(find.byKey(const Key('pricing-tax')), '8.1');
      await tester.tap(find.byKey(const Key('pricing-calculate')));
      await tester.pumpAndSettle();

      expect(repo.priced.single.discountCascade, hasLength(2));
      expect(
        tester
            .widget<Text>(find.byKey(const Key('pricing-effective-discount')))
            .data,
        '14.5%',
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('pricing-net-unit'))).data,
        '85.50',
      );
      expect(
        tester
            .widget<Text>(find.byKey(const Key('pricing-quantity-base')))
            .data,
        '120',
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('pricing-net-per-base'))).data,
        '7.13',
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('pricing-line-total'))).data,
        '924.26',
      );
    });

    testWidgets('validates before calling the server', (
      WidgetTester tester,
    ) async {
      await pumpPage(tester, host(const PricingPreviewPage()));

      await tester.enterText(find.byKey(const Key('pricing-quantity')), '0');
      await tester.enterText(find.byKey(const Key('pricing-price')), '100');
      await tester.enterText(
        find.byKey(const Key('pricing-cascade')),
        '10, abc',
      );
      await tester.tap(find.byKey(const Key('pricing-calculate')));
      await tester.pumpAndSettle();

      expect(find.text('Invalid number'), findsWidgets);
      expect(repo.priced, isEmpty);
    });
  });

  group('input parsing', () {
    test('accepts a decimal comma and rejects text', () {
      expect(parseInputDecimal('12,5')?.toPlain(), '12.50');
      expect(parseInputDecimal(' 3 ')?.toPlain(), '3.00');
      expect(parseInputDecimal('abc'), isNull);
      expect(parseInputDecimal(''), isNull);
    });

    test('a discount cascade is a list of percentages from 0 to 100', () {
      expect(parseCascade('10, 5')?.map((d) => d.toPlain()), <String>[
        '10.00',
        '5.00',
      ]);
      expect(parseCascade('10;5')?.length, 2);
      expect(parseCascade(''), isEmpty);
      expect(parseCascade('101'), isNull);
      expect(parseCascade('-1'), isNull);
      expect(parseCascade('10, x'), isNull);
    });
  });
}
