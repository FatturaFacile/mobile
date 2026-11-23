import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:fattura_facile/core/database/app_database.dart';
import 'package:fattura_facile/core/sync/sync_engine.dart';
import 'package:fattura_facile/features/purchase_orders/data/purchase_order_repository_impl.dart';
import 'package:fattura_facile/features/purchase_orders/domain/purchase_order_models.dart';
import 'package:fattura_facile/features/supplier_rebates/domain/rebate_decimal.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/sync_engine_test.dart' show FakeAdapter, json;
import 'fixtures.dart';

Never offline(RequestOptions o) =>
    throw DioException.connectionError(requestOptions: o, reason: 'down');

Object envelope(Object data) => <String, dynamic>{'data': data};

void main() {
  late AppDatabase db;
  late FakeAdapter adapter;
  late Dio dio;
  late PurchaseOrderRepositoryImpl repo;
  final DateTime now = DateTime(2026, 11, 23, 10);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    adapter = FakeAdapter(
      (RequestOptions o) => json(200, envelope(<dynamic>[])),
    );
    dio = Dio(
      BaseOptions(
        baseUrl: 'http://x/api/v1',
        validateStatus: (int? s) => s != null && s < 300,
      ),
    )..httpClientAdapter = adapter;
    repo = PurchaseOrderRepositoryImpl(
      db,
      dio,
      SyncEngine(db, dio),
      clock: () => now,
    );
  });

  tearDown(() => db.close());

  Future<void> seedOrder({String status = 'sent', int reminders = 0}) async {
    adapter.handler = (RequestOptions o) => json(
      200,
      envelope(<Map<String, dynamic>>[
        orderJson(status: status, reminders: reminders),
      ]),
    );
    await repo.refreshOrders('t1');
  }

  group('orders', () {
    test('refresh asks the procurement list and stores an offline copy, newest first', () async {
      adapter.handler = (RequestOptions o) => json(
        200,
        envelope(<String, dynamic>{
          'data': <Map<String, dynamic>>[
            orderJson(id: 'o1', number: 'PO-1'),
            orderJson(id: 'o2', number: 'PO-2')..['order_date'] = '2026-11-01',
          ],
        }),
      );

      final List<PurchaseOrder> fresh = await repo.refreshOrders('t1');

      expect(adapter.calls.single.path, '/procurement/purchase-orders');
      expect(fresh.map((PurchaseOrder o) => o.id), <String>['o2', 'o1']);

      adapter.handler = offline;
      final List<PurchaseOrder> cached = await repo.cachedOrders('t1');
      expect(cached.map((PurchaseOrder o) => o.id), <String>['o2', 'o1']);
      expect(cached.last.lines.single.baseUom, 'PCS');
    });

    test(
      'the copy is tenant scoped and drops orders that left the list',
      () async {
        await seedOrder();
        expect(await repo.cachedOrders('t2'), isEmpty);

        adapter.handler = (RequestOptions o) =>
            json(200, envelope(<dynamic>[]));
        await repo.refreshOrders('t1');

        expect(await repo.cachedOrders('t1'), isEmpty);
      },
    );

    test(
      'a failed refresh surfaces as an offline exception and keeps the copy',
      () async {
        await seedOrder();
        adapter.handler = offline;

        await expectLater(
          repo.refreshOrders('t1'),
          throwsA(
            isA<PoException>().having(
              (PoException e) => e.kind,
              'kind',
              PoErrorKind.offline,
            ),
          ),
        );
        expect(await repo.cachedOrders('t1'), hasLength(1));
      },
    );

    test('a 403 maps to forbidden and keeps the RFC 7807 detail', () async {
      adapter.handler = (RequestOptions o) =>
          json(403, <String, dynamic>{'detail': 'No right'});

      await expectLater(
        repo.refreshOrders('t1'),
        throwsA(
          isA<PoException>().having(
            (PoException e) => e.kind,
            'kind',
            PoErrorKind.forbidden,
          ),
        ),
      );
    });

    test('the detail accepts a bare or a wrapped resource', () async {
      adapter.handler = (RequestOptions o) => json(200, orderJson());
      expect((await repo.refreshOrder('t1', 'o1')).poNumber, 'PO-0001');

      adapter.handler = (RequestOptions o) =>
          json(200, envelope(orderJson(number: 'PO-9')));
      expect((await repo.refreshOrder('t1', 'o1')).poNumber, 'PO-9');
      expect((await repo.cachedOrder('t1', 'o1'))!.poNumber, 'PO-9');
    });
  });

  group('overdue', () {
    test('stores the radar rows, most late first', () async {
      adapter.handler = (RequestOptions o) => json(
        200,
        envelope(<Map<String, dynamic>>[
          overdueJson(id: 'o1', days: 3),
          overdueJson(id: 'o2', days: 20),
        ]),
      );

      final List<OverdueOrder> rows = await repo.refreshOverdue('t1');

      expect(adapter.calls.single.path, '/procurement/purchase-orders/overdue');
      expect(rows.map((OverdueOrder r) => r.order.id), <String>['o2', 'o1']);
      adapter.handler = offline;
      expect(await repo.cachedOverdue('t1'), hasLength(2));
    });
  });

  group('supplier confirmation', () {
    final ConfirmationInput input = ConfirmationInput(
      confirmationNumber: 'AB-991',
      confirmedAt: DateTime(2026, 11, 14),
      lines: <ConfirmationLineInput>[
        ConfirmationLineInput(
          purchaseOrderLineId: 'l1',
          confirmedQuantity: Dec.parse('8'),
          confirmedUnitPrice: Dec.parse('105'),
          confirmedDeliveryDate: DateTime(2026, 12, 2),
          varianceReason: 'shortage',
        ),
      ],
    );

    test('posts the variances and the order turns confirmed locally', () async {
      await seedOrder();
      adapter.handler = (RequestOptions o) => json(201, confirmationJson());

      final PoActionOutcome out = await repo.confirmOrder('t1', 'o1', input);

      expect(out.status, PoActionStatus.sent);
      final RequestOptions call = adapter.calls.last;
      expect(call.method, 'POST');
      expect(call.path, '/procurement/purchase-orders/o1/confirmations');
      expect(call.headers['Idempotency-Key'], isNotNull);
      final Map<String, dynamic> body =
          jsonDecode(jsonEncode(call.data)) as Map<String, dynamic>;
      expect(body['confirmation_number'], 'AB-991');
      final Map<String, dynamic> line =
          (body['lines'] as List<dynamic>).single as Map<String, dynamic>;
      expect(line['confirmed_quantity'], '8.00');
      expect(line['variance_reason'], 'shortage');

      final PurchaseOrder o = (await repo.cachedOrder('t1', 'o1'))!;
      expect(o.status, PoStatus.confirmed);
      expect(o.supplierConfirmationNumber, 'AB-991');
      expect(o.promisedDeliveryDate, DateTime(2026, 12, 2));
      expect(o.lines.single.quantityConfirmed, Dec.parse('8'));
      expect(o.lines.single.unitPrice, Dec.parse('105'));
    });

    test(
      'offline it is queued, shown as pending and keeps the optimistic order',
      () async {
        await seedOrder();
        adapter.handler = offline;

        final PoActionOutcome out = await repo.confirmOrder('t1', 'o1', input);

        expect(out.status, PoActionStatus.queued);
        final List<PoPendingAction> pending = await repo.pendingActions('t1');
        expect(pending.single.kind, PoActionKind.confirmation);
        expect(pending.single.targetId, 'o1');
        expect(
          (await repo.cachedOrder('t1', 'o1'))!.status,
          PoStatus.confirmed,
        );
      },
    );

    test(
      'a refresh does not overwrite an order that still has a queued write',
      () async {
        await seedOrder();
        adapter.handler = offline;
        await repo.confirmOrder('t1', 'o1', input);

        adapter.handler = (RequestOptions o) =>
            json(200, envelope(<Map<String, dynamic>>[orderJson()]));
        final List<PurchaseOrder> list = await repo.refreshOrders('t1');

        expect(list.single.status, PoStatus.confirmed);
      },
    );

    test('once sent, the next refresh brings the server state back', () async {
      await seedOrder();
      adapter.handler = offline;
      await repo.confirmOrder('t1', 'o1', input);
      adapter.handler = (RequestOptions o) => json(201, confirmationJson());
      expect(await repo.flush('t1'), 1);

      adapter.handler = (RequestOptions o) => json(
        200,
        envelope(<Map<String, dynamic>>[
          orderJson(status: 'confirmed', promised: '2026-12-05'),
        ]),
      );
      final List<PurchaseOrder> list = await repo.refreshOrders('t1');

      expect(list.single.promisedDeliveryDate, DateTime(2026, 12, 5));
      expect(await repo.pendingActions('t1'), isEmpty);
    });

    test('a 422 parks the row as rejected with the server message', () async {
      await seedOrder();
      adapter.handler = (RequestOptions o) =>
          json(422, <String, dynamic>{'message': 'Order is closed'});

      final PoActionOutcome out = await repo.confirmOrder('t1', 'o1', input);

      expect(out.status, PoActionStatus.rejected);
      final List<PoPendingAction> pending = await repo.pendingActions('t1');
      expect(pending.single.rejected, isTrue);
      await repo.dismissAction(pending.single.queueUuid);
      expect(await repo.pendingActions('t1'), isEmpty);
    });

    test('the confirmation log is cached per order', () async {
      adapter.handler = (RequestOptions o) =>
          json(200, envelope(<Map<String, dynamic>>[confirmationJson()]));

      final List<PoConfirmation> fresh = await repo.refreshConfirmations(
        't1',
        'o1',
      );

      expect(
        adapter.calls.single.path,
        '/procurement/purchase-orders/o1/confirmations',
      );
      expect(fresh.single.requiresReview, isTrue);
      adapter.handler = offline;
      expect(await repo.cachedConfirmations('t1', 'o1'), hasLength(1));
      expect(await repo.cachedConfirmations('t1', 'other'), isEmpty);
    });
  });

  group('reminders', () {
    test('sends the reminder and bumps the local counter at once', () async {
      await seedOrder(status: 'confirmed', reminders: 1);
      adapter.handler = (RequestOptions o) => json(201, <String, dynamic>{
        'id': 'r1',
        'purchase_order_id': 'o1',
        'level': 2,
        'channel': 'email',
        'trigger': 'manual',
        'days_overdue': 5,
        'sent_at': '2026-11-23T10:00:00+00:00',
      });

      final PoActionOutcome out = await repo.sendReminder('t1', 'o1');

      expect(out.status, PoActionStatus.sent);
      expect(
        adapter.calls.last.path,
        '/procurement/purchase-orders/o1/reminders',
      );
      final PurchaseOrder o = (await repo.cachedOrder('t1', 'o1'))!;
      expect(o.reminderCount, 2);
      expect(o.lastReminderAt, now);
    });

    test(
      'a second tap while one waits in the outbox does not queue another',
      () async {
        await seedOrder(status: 'confirmed');
        adapter.handler = offline;

        expect(
          (await repo.sendReminder('t1', 'o1')).status,
          PoActionStatus.queued,
        );
        expect(
          (await repo.sendReminder('t1', 'o1')).status,
          PoActionStatus.queued,
        );

        expect(await repo.pendingActions('t1'), hasLength(1));
        expect((await repo.cachedOrder('t1', 'o1'))!.reminderCount, 1);
      },
    );

    test('the reminder history is cached per order', () async {
      adapter.handler = (RequestOptions o) => json(
        200,
        envelope(<Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'r1',
            'purchase_order_id': 'o1',
            'level': 1,
            'channel': 'email',
            'sent_at': '2026-11-15T08:00:00+00:00',
          },
        ]),
      );

      await repo.refreshReminders('t1', 'o1');

      adapter.handler = offline;
      expect((await repo.cachedReminders('t1', 'o1')).single.level, 1);
    });
  });

  group('dropshipments', () {
    Future<void> seedDropship() async {
      adapter.handler = (RequestOptions o) => json(
        200,
        envelope(<String, dynamic>{
          'data': <Map<String, dynamic>>[dropshipJson()],
        }),
      );
      await repo.refreshDropships('t1');
    }

    test('lists the shipments with the open ones first', () async {
      adapter.handler = (RequestOptions o) => json(
        200,
        envelope(<Map<String, dynamic>>[
          dropshipJson(id: 'd1', status: 'delivered'),
          dropshipJson(id: 'd2'),
        ]),
      );

      final List<Dropship> list = await repo.refreshDropships('t1');

      expect(adapter.calls.single.path, '/procurement/dropshipments');
      expect(list.map((Dropship d) => d.id), <String>['d2', 'd1']);
    });

    test('the detail carries the virtual stock movements', () async {
      adapter.handler = (RequestOptions o) => json(200, dropshipJson());

      final Dropship d = await repo.refreshDropship('t1', 'd1');

      expect(adapter.calls.single.path, '/procurement/dropshipments/d1');
      expect(d.movements, hasLength(1));
      expect(
        (await repo.cachedDropship('t1', 'd1'))!.recipientName,
        'Rossi SA',
      );
    });

    test('records the delivery with its proof and marks the shipment delivered locally', () async {
      await seedDropship();
      adapter.handler = (RequestOptions o) =>
          json(200, dropshipJson(status: 'delivered'));

      final PoActionOutcome out = await repo.recordDelivery(
        't1',
        'd1',
        DeliveryInput(
          deliveredAt: DateTime(2026, 11, 22),
          deliveryProofReference: 'POD-9',
          supplierShipmentReference: 'TRK-1',
        ),
      );

      expect(out.status, PoActionStatus.sent);
      final RequestOptions call = adapter.calls.last;
      expect(call.path, '/procurement/dropshipments/d1/deliveries');
      expect(call.method, 'POST');
      final Map<String, dynamic> body =
          jsonDecode(jsonEncode(call.data)) as Map<String, dynamic>;
      expect(body['delivery_proof_reference'], 'POD-9');
      expect(body['delivered_at'], '2026-11-22');
      final Dropship d = (await repo.cachedDropship('t1', 'd1'))!;
      expect(d.status, DropshipStatus.delivered);
      expect(d.deliveryProofReference, 'POD-9');
      expect(d.supplierShipmentReference, 'TRK-1');
    });

    test(
      'with line quantities the local status is partially delivered',
      () async {
        await seedDropship();
        adapter.handler = offline;

        await repo.recordDelivery(
          't1',
          'd1',
          DeliveryInput(
            deliveryProofReference: 'POD-9',
            lines: <DeliveryLineInput>[
              DeliveryLineInput(
                purchaseOrderLineId: 'l1',
                quantityDelivered: Dec.parse('4'),
              ),
            ],
          ),
        );

        expect(
          (await repo.cachedDropship('t1', 'd1'))!.status,
          DropshipStatus.partiallyDelivered,
        );
        final List<PoPendingAction> pending = await repo.pendingActions('t1');
        expect(pending.single.kind, PoActionKind.delivery);
        expect(pending.single.targetId, 'd1');
      },
    );

    test(
      'a shipment with a queued delivery keeps its optimistic copy on refresh',
      () async {
        await seedDropship();
        adapter.handler = offline;
        await repo.recordDelivery(
          't1',
          'd1',
          const DeliveryInput(deliveryProofReference: 'POD-9'),
        );

        adapter.handler = (RequestOptions o) =>
            json(200, envelope(<Map<String, dynamic>>[dropshipJson()]));
        final List<Dropship> list = await repo.refreshDropships('t1');

        expect(list.single.status, DropshipStatus.delivered);
      },
    );
  });

  group('pricing preview', () {
    final PricingInput input = PricingInput(
      quantity: Dec.parse('10'),
      unitPrice: Dec.parse('100'),
      discountCascade: <Dec>[Dec.parse('10'), Dec.parse('5')],
      uomConversionFactor: Dec.parse('12'),
      taxRate: Dec.parse('8.1'),
    );

    test('uses the server answer when reachable', () async {
      adapter.handler = (RequestOptions o) =>
          json(200, envelope(previewJson()));

      final PricingPreview p = await repo.pricingPreview(input);

      expect(
        adapter.calls.single.path,
        '/procurement/purchase-orders/pricing-preview',
      );
      expect(p.estimated, isFalse);
      expect(p.lineTotalAmount, Dec.parse('924.26'));
      final Map<String, dynamic> body = jsonDecode(
        jsonEncode(adapter.calls.single.data),
      ) as Map<String, dynamic>;
      expect(body['discount_cascade'], <dynamic>['10.00', '5.00']);
      expect(body['uom_conversion_factor'], '12.00');
    });

    test(
      'falls back to the offline estimate when the server is unreachable',
      () async {
        adapter.handler = offline;

        final PricingPreview p = await repo.pricingPreview(input);

        expect(p.estimated, isTrue);
        expect(p.lineTotalAmount, Dec.parse('924.26'));
      },
    );

    test('a validation refusal is not hidden behind an estimate', () async {
      adapter.handler = (RequestOptions o) => json(422, <String, dynamic>{
        'message': 'quantity must be greater than 0',
      });

      await expectLater(
        repo.pricingPreview(input),
        throwsA(
          isA<PoException>().having(
            (PoException e) => e.kind,
            'kind',
            PoErrorKind.invalid,
          ),
        ),
      );
    });
  });
}
