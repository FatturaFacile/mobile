import 'package:fattura_facile/features/purchase_orders/domain/purchase_order_models.dart';
import 'package:fattura_facile/features/purchase_orders/presentation/purchase_order_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';
import 'fixtures.dart';

void main() {
  late FakePurchaseOrderRepository repo;
  late ProviderContainer container;
  final DateTime today = DateTime(2026, 11, 23);

  setUp(() {
    repo = FakePurchaseOrderRepository();
    container = ProviderContainer(
      overrides: [
        purchaseOrderRepositoryProvider.overrideWithValue(repo),
        purchaseOrderTenantIdProvider.overrideWithValue('t1'),
        purchaseOrderClockProvider.overrideWithValue(() => today),
      ],
    );
    addTearDown(container.dispose);
  });

  PurchaseOrderHubState hub() => container.read(purchaseOrderHubProvider);

  group('hub', () {
    test('loads the three lists from the server', () async {
      repo
        ..remoteOrders = <PurchaseOrder>[order()]
        ..remoteOverdue = <OverdueOrder>[OverdueOrder.fromJson(overdueJson())]
        ..remoteDropships = <Dropship>[Dropship.fromJson(dropshipJson())];

      await container.read(purchaseOrderHubProvider.notifier).load();

      expect(hub().orders, hasLength(1));
      expect(hub().overdue, hasLength(1));
      expect(hub().dropships, hasLength(1));
      expect(hub().loading, isFalse);
      expect(hub().fromCache, isFalse);
      expect(hub().error, isNull);
      expect(repo.flushes, 1);
    });

    test('offline it keeps the cached copy and says so', () async {
      repo
        ..cacheOrders = <PurchaseOrder>[order()]
        ..refreshError = const PoException(PoErrorKind.offline);

      await container.read(purchaseOrderHubProvider.notifier).load();

      expect(hub().orders, hasLength(1));
      expect(hub().fromCache, isTrue);
      expect(hub().error?.kind, PoErrorKind.offline);
    });

    test('a missing right is reported as forbidden', () async {
      repo.refreshError = const PoException(PoErrorKind.forbidden);

      await container.read(purchaseOrderHubProvider.notifier).load();

      expect(hub().forbidden, isTrue);
    });

    test(
      'overdue orders come from the server radar and from the cached dates',
      () async {
        repo.cacheOrders = <PurchaseOrder>[
          order(
            id: 'late',
            status: 'confirmed',
            promised: '2026-11-01',
            lines: <Map<String, dynamic>>[lineJson(promised: null)],
          ),
          order(
            id: 'fine',
            status: 'confirmed',
            promised: '2026-12-31',
            lines: <Map<String, dynamic>>[lineJson(promised: null)],
          ),
          order(
            id: 'radar',
            status: 'confirmed',
            promised: '2026-12-31',
            lines: <Map<String, dynamic>>[lineJson(promised: null)],
          ),
        ];
        repo.cacheOverdue = <OverdueOrder>[
          OverdueOrder.fromJson(overdueJson(id: 'radar')),
        ];
        repo.refreshError = const PoException(PoErrorKind.offline);

        await container.read(purchaseOrderHubProvider.notifier).load();

        expect(
          hub().overdueOrders(today).map((PurchaseOrder o) => o.id),
          <String>['late', 'radar'],
        );
      },
    );

    test(
      'a reminder from the radar is sent and the lists are re-read',
      () async {
        repo.cacheOrders = <PurchaseOrder>[order(status: 'confirmed')];

        final PoActionOutcome out = await container
            .read(purchaseOrderHubProvider.notifier)
            .remind('o1');

        expect(out.status, PoActionStatus.sent);
        expect(repo.reminded, <String>['o1']);
      },
    );

    test('pendingFor counts the outbox rows of one target', () async {
      repo
        ..pending = <PoPendingAction>[
          const PoPendingAction(
            queueUuid: 'q1',
            targetId: 'o1',
            kind: PoActionKind.reminder,
          ),
          const PoPendingAction(
            queueUuid: 'q2',
            targetId: 'o2',
            kind: PoActionKind.reminder,
          ),
        ]
        ..remoteOrders = <PurchaseOrder>[order()];

      await container.read(purchaseOrderHubProvider.notifier).load();

      expect(hub().pendingFor('o1'), 1);
      expect(hub().pendingFor('zzz'), 0);
    });
  });

  group('order detail', () {
    PurchaseOrderDetailState detail() =>
        container.read(purchaseOrderDetailProvider);

    Future<void> open({String status = 'sent'}) async {
      repo
        ..cacheOrders = <PurchaseOrder>[
          order(status: status, promised: '2026-11-01'),
        ]
        ..remoteOrders = <PurchaseOrder>[
          order(status: status, promised: '2026-11-01'),
        ]
        ..confirmations = <PoConfirmation>[
          PoConfirmation.fromJson(confirmationJson()),
        ];
      await container.read(purchaseOrderDetailProvider.notifier).load('o1');
    }

    test('loads the order with its confirmations', () async {
      await open();

      expect(detail().order?.poNumber, 'PO-0001');
      expect(detail().confirmations.single.confirmationNumber, 'AB-991');
      expect(detail().canConfirm, isTrue);
      expect(detail().loading, isFalse);
    });

    test('a draft order cannot be confirmed', () async {
      await open(status: 'draft');

      expect(detail().canConfirm, isFalse);
      expect(
        await container
            .read(purchaseOrderDetailProvider.notifier)
            .confirm(const ConfirmationInput(confirmationNumber: 'X')),
        isNull,
      );
      expect(repo.confirmed, isEmpty);
    });

    test('confirming sends the input and raises the sent notice', () async {
      await open();
      const ConfirmationInput input = ConfirmationInput(
        confirmationNumber: 'AB-991',
      );

      final PoActionOutcome? out = await container
          .read(purchaseOrderDetailProvider.notifier)
          .confirm(input);

      expect(out?.status, PoActionStatus.sent);
      expect(repo.confirmed.single.orderId, 'o1');
      expect(detail().notice, PoNotice.sent);
      expect(detail().order?.status, PoStatus.confirmed);
      expect(detail().busy, isFalse);
    });

    test(
      'offline the confirmation is queued and blocks a second one',
      () async {
        await open();
        repo.nextStatus = PoActionStatus.queued;
        const ConfirmationInput input = ConfirmationInput(
          confirmationNumber: 'AB-991',
        );
        final PurchaseOrderDetailController ctrl = container.read(
          purchaseOrderDetailProvider.notifier,
        );

        await ctrl.confirm(input);

        expect(detail().notice, PoNotice.queued);
        expect(detail().pendingOf(PoActionKind.confirmation), isTrue);
        expect(detail().canConfirm, isFalse);
        expect(await ctrl.confirm(input), isNull);
        expect(repo.confirmed, hasLength(1));
      },
    );

    test(
      'a refusal raises the rejected notice with the server detail',
      () async {
        await open();
        repo
          ..nextStatus = PoActionStatus.rejected
          ..nextDetail = 'Order is closed';

        await container
            .read(purchaseOrderDetailProvider.notifier)
            .confirm(const ConfirmationInput(confirmationNumber: 'AB-991'));

        expect(detail().notice, PoNotice.rejected);
        expect(detail().noticeDetail, 'Order is closed');
      },
    );

    test(
      'canRemind needs a late open order and no reminder already waiting',
      () async {
        await open(status: 'confirmed');
        expect(detail().canRemind(today), isTrue);
        expect(detail().canRemind(DateTime(2026, 10, 1)), isFalse);

        repo.nextStatus = PoActionStatus.queued;
        await container.read(purchaseOrderDetailProvider.notifier).remind();

        expect(repo.reminded, <String>['o1']);
        expect(detail().canRemind(today), isFalse);
      },
    );

    test('clearNotice resets the one-shot message', () async {
      await open();
      await container.read(purchaseOrderDetailProvider.notifier).remind();

      container.read(purchaseOrderDetailProvider.notifier).clearNotice();

      expect(detail().notice, isNull);
    });

    test(
      'dismissing a refused write removes it from the pending list',
      () async {
        await open();
        repo.pending = <PoPendingAction>[
          const PoPendingAction(
            queueUuid: 'q1',
            targetId: 'o1',
            kind: PoActionKind.confirmation,
            rejected: true,
          ),
        ];
        await container.read(purchaseOrderDetailProvider.notifier).load('o1');
        expect(detail().pending, hasLength(1));

        await container
            .read(purchaseOrderDetailProvider.notifier)
            .dismiss('q1');

        expect(repo.dismissed, <String>['q1']);
        expect(detail().pending, isEmpty);
        expect(detail().canConfirm, isTrue);
      },
    );

    test('offline the cached order still shows with the error kept', () async {
      repo
        ..cacheOrders = <PurchaseOrder>[order()]
        ..refreshError = const PoException(PoErrorKind.offline);

      await container.read(purchaseOrderDetailProvider.notifier).load('o1');

      expect(detail().order, isNotNull);
      expect(detail().error?.kind, PoErrorKind.offline);
    });
  });

  group('dropship detail', () {
    DropshipDetailState detail() => container.read(dropshipDetailProvider);

    Future<void> open({String status = 'ddt_issued'}) async {
      repo
        ..cacheDropships = <Dropship>[
          Dropship.fromJson(dropshipJson(status: status)),
        ]
        ..remoteDropships = <Dropship>[
          Dropship.fromJson(dropshipJson(status: status)),
        ]
        ..remoteOrders = <PurchaseOrder>[order(dropship: true)]
        ..cacheOrders = <PurchaseOrder>[order(dropship: true)];
      await container.read(dropshipDetailProvider.notifier).load('d1');
    }

    test(
      'loads the shipment with the order that drives the delivery form',
      () async {
        await open();

        expect(detail().dropship?.ddtNumber, 'DDT-77');
        expect(detail().order?.id, 'o1');
        expect(detail().canRecordDelivery, isTrue);
      },
    );

    test('a delivered shipment offers no delivery recording', () async {
      await open(status: 'delivered');

      expect(detail().canRecordDelivery, isFalse);
      expect(
        await container
            .read(dropshipDetailProvider.notifier)
            .recordDelivery(const DeliveryInput()),
        isNull,
      );
    });

    test('records the delivery with its proof reference', () async {
      await open();

      final PoActionOutcome? out = await container
          .read(dropshipDetailProvider.notifier)
          .recordDelivery(const DeliveryInput(deliveryProofReference: 'POD-9'));

      expect(out?.status, PoActionStatus.sent);
      expect(repo.delivered.single.dropshipId, 'd1');
      expect(repo.delivered.single.input.deliveryProofReference, 'POD-9');
      expect(detail().notice, PoNotice.sent);
    });

    test('a queued delivery blocks a second one', () async {
      await open();
      repo.nextStatus = PoActionStatus.queued;
      final DropshipDetailController ctrl = container.read(
        dropshipDetailProvider.notifier,
      );

      await ctrl.recordDelivery(
        const DeliveryInput(deliveryProofReference: 'POD-9'),
      );

      expect(detail().deliveryPending, isTrue);
      expect(
        await ctrl.recordDelivery(
          const DeliveryInput(deliveryProofReference: 'POD-9'),
        ),
        isNull,
      );
      expect(repo.delivered, hasLength(1));
    });
  });

  group('pricing preview', () {
    test('keeps the preview of the entered line', () async {
      await container
          .read(pricingPreviewProvider.notifier)
          .calculate(PricingInputFixture.box);

      final PricingPreviewState s = container.read(pricingPreviewProvider);
      expect(s.preview?.quantityBase.toPlain(), '120.00');
      expect(s.loading, isFalse);
      expect(s.error, isNull);
    });

    test('a server refusal lands in the error', () async {
      repo.pricingError = const PoException(PoErrorKind.invalid);

      await container
          .read(pricingPreviewProvider.notifier)
          .calculate(PricingInputFixture.box);

      final PricingPreviewState s = container.read(pricingPreviewProvider);
      expect(s.preview, isNull);
      expect(s.error?.kind, PoErrorKind.invalid);
    });
  });
}
