import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:fattura_facile/core/database/app_database.dart';
import 'package:fattura_facile/core/sync/sync_engine.dart';
import 'package:fattura_facile/features/receivables/data/receivables_local_data_source.dart';
import 'package:fattura_facile/features/receivables/data/receivables_remote_data_source.dart';
import 'package:fattura_facile/features/receivables/data/receivables_repository_impl.dart';
import 'package:fattura_facile/features/receivables/domain/money.dart';
import 'package:fattura_facile/features/receivables/domain/receivables_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/sync_engine_test.dart' show FakeAdapter, json;
import 'support.dart';

const String t = 't1';

ResponseBody offline(RequestOptions o) =>
    throw DioException.connectionError(requestOptions: o, reason: 'down');

ResponseBody ok(RequestOptions o) => json(200, envelope(<String, dynamic>{}));

void main() {
  late AppDatabase db;
  late FakeAdapter adapter;
  late Dio dio;
  late SyncEngine engine;
  late ReceivablesRepositoryImpl repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    adapter = FakeAdapter(ok);
    dio = Dio(
      BaseOptions(
        baseUrl: 'http://x/api/v1',
        validateStatus: (int? s) => s != null && s < 300,
      ),
    )..httpClientAdapter = adapter;
    engine = SyncEngine(db, dio);
    repo = ReceivablesRepositoryImpl(
      ReceivablesLocalDataSource(db),
      ReceivablesRemoteDataSource(dio),
      engine,
    );
  });

  tearDown(() => db.close());

  Future<void> seed(List<Map<String, dynamic>> items) async {
    adapter.handler = (RequestOptions o) => json(200, <String, dynamic>{
      'data': items,
      'meta': <String, dynamic>{'last_page': 1},
    });
    await repo.refreshItems(t, 'c1');
  }

  AllocationDraft pay(String itemId, String amount, {AllocationType? type}) =>
      AllocationDraft(
        itemId: itemId,
        type: type ?? AllocationType.payment,
        amount: Money.parse(amount),
        valueDate: DateTime(2030, 3, 4),
      );

  Iterable<RequestOptions> posts() =>
      adapter.calls.where((RequestOptions o) => o.method == 'POST');

  group('read models', () {
    test('the dashboard is stored for offline reading', () async {
      adapter.handler = (RequestOptions o) =>
          json(200, envelope(dashboardJson()));
      expect(await repo.cachedDashboard(t), isNull);

      final ReceivablesDashboard fresh = await repo.refreshDashboard(t);
      expect(fresh.kpis.totalOpen, Money.parse('1000.00'));
      expect(adapter.calls.single.path, '/invoicing/receivables/dashboard');
      expect(adapter.calls.single.queryParameters, isEmpty);

      adapter.handler = offline;
      final ReceivablesDashboard? cached = await repo.cachedDashboard(t);
      expect(cached!.kpis.totalExposure, Money.parse('1500.00'));
      expect(cached.aging.buckets.length, 4);
    });

    test(
      'the currency is a query parameter and a separate cache entry',
      () async {
        adapter.handler = (RequestOptions o) =>
            json(200, envelope(dashboardJson()));
        await repo.refreshDashboard(t, currency: 'EUR');
        expect(adapter.calls.single.queryParameters['currency'], 'EUR');
        expect(await repo.cachedDashboard(t, currency: 'EUR'), isNotNull);
        expect(await repo.cachedDashboard(t), isNull);
      },
    );

    test('the cache is per tenant', () async {
      adapter.handler = (RequestOptions o) =>
          json(200, envelope(dashboardJson()));
      await repo.refreshDashboard(t);
      expect(await repo.cachedDashboard('other'), isNull);
    });

    test('a payload that does not parse never replaces a good cache', () async {
      adapter.handler = (RequestOptions o) =>
          json(200, envelope(dashboardJson()));
      await repo.refreshDashboard(t);

      final Map<String, dynamic> broken = dashboardJson();
      (broken['kpis'] as Map<String, dynamic>)['total_open'] = 'abc';
      adapter.handler = (RequestOptions o) => json(200, envelope(broken));
      await expectLater(
        repo.refreshDashboard(t),
        throwsA(
          isA<ReceivablesException>().having(
            (ReceivablesException e) => e.kind,
            'kind',
            ReceivablesErrorKind.unknown,
          ),
        ),
      );
      final ReceivablesDashboard? cached = await repo.cachedDashboard(t);
      expect(cached!.kpis.totalOpen, Money.parse('1000.00'));
    });

    test('transport and server errors map to typed exceptions', () async {
      adapter.handler = offline;
      await expectLater(
        repo.refreshDashboard(t),
        throwsA(
          isA<ReceivablesException>().having(
            (ReceivablesException e) => e.kind,
            'kind',
            ReceivablesErrorKind.offline,
          ),
        ),
      );
      for (final (int status, ReceivablesErrorKind kind)
          in <(int, ReceivablesErrorKind)>[
            (403, ReceivablesErrorKind.forbidden),
            (404, ReceivablesErrorKind.notFound),
            (422, ReceivablesErrorKind.invalid),
            (500, ReceivablesErrorKind.unknown),
          ]) {
        adapter.handler = (RequestOptions o) =>
            json(status, <String, dynamic>{'message': 'm$status'});
        await expectLater(
          repo.refreshDashboard(t),
          throwsA(
            isA<ReceivablesException>()
                .having((ReceivablesException e) => e.kind, 'kind', kind)
                .having(
                  (ReceivablesException e) => e.detail,
                  'detail',
                  'm$status',
                ),
          ),
        );
      }
    });

    test(
      'aging, credit, risk, limits, payments, dso and provision round-trip',
      () async {
        adapter.handler = (RequestOptions o) {
          final String p = o.path;
          if (p.endsWith('/aging')) {
            return json(200, envelope(agingJson()));
          }
          if (p.endsWith('/credit')) {
            return json(200, envelope(creditJson()));
          }
          if (p.endsWith('/risk')) {
            return json(200, envelope(riskJson()));
          }
          if (p.endsWith('/credit-limits')) {
            return json(200, envelope(<Map<String, dynamic>>[limitJson()]));
          }
          if (p.endsWith('/unreconciled-payments')) {
            return json(200, envelope(<Map<String, dynamic>>[paymentJson()]));
          }
          if (p.endsWith('/dso')) {
            return json(
              200,
              envelope(<String, dynamic>{
                'period_days': 90,
                'currency': 'CHF',
                'receivables': '10.00',
                'credit_sales': '40.00',
                'dso': 22.5,
              }),
            );
          }
          return json(
            200,
            envelope(<String, dynamic>{
              'currency': 'CHF',
              'lines': <dynamic>[],
              'total_open': '10.00',
              'total_provision': '0.10',
              'net_realizable_value': '9.90',
            }),
          );
        };
        await repo.refreshAging(t, customerId: 'c1');
        await repo.refreshCredit(t, 'c1');
        await repo.refreshRisk(t, 'c1');
        await repo.refreshCreditLimits(t, 'c1');
        await repo.refreshUnreconciled(t, 'c1');
        await repo.refreshDso(t, customerId: 'c1', periodDays: 90);
        await repo.refreshProvision(t, customerId: 'c1');
        expect(adapter.calls.first.queryParameters['customer_id'], 'c1');

        adapter.handler = offline;
        expect(
          (await repo.cachedAging(t, customerId: 'c1'))!.customers.length,
          2,
        );
        expect(await repo.cachedAging(t), isNull);
        expect(
          (await repo.cachedCredit(t, 'c1'))!.exposure.isConsistent,
          isTrue,
        );
        expect((await repo.cachedRisk(t, 'c1'))!.rating, RiskRating.high);
        expect(
          (await repo.cachedCreditLimits(t, 'c1')).single.grantedLimit,
          Money.parse('1000.00'),
        );
        expect(
          (await repo.cachedUnreconciled(t, 'c1')).single.unallocated,
          Money.parse('60.00'),
        );
        expect((await repo.cachedDso(t, customerId: 'c1'))!.dso, 22.5);
        expect(
          (await repo.cachedProvision(t, customerId: 'c1'))!.totalProvision,
          Money.parse('0.10'),
        );
        expect(await repo.cachedCreditLimits(t, 'unknown'), isEmpty);
      },
    );

    test('items are read page by page and replace the customer copy', () async {
      adapter.handler = (RequestOptions o) {
        final int page = o.queryParameters['page'] as int;
        return json(200, <String, dynamic>{
          'data': page == 1
              ? <Map<String, dynamic>>[
                  itemJson('i1', days: 3),
                  itemJson('i2', days: 40),
                ]
              : <Map<String, dynamic>>[itemJson('i3')],
          'meta': <String, dynamic>{'last_page': 2},
        });
      };
      final List<ReceivableItem> fresh = await repo.refreshItems(t, 'c1');
      expect(adapter.calls.length, 2);
      expect(adapter.calls.first.queryParameters['customer_id'], 'c1');
      expect(adapter.calls.first.queryParameters['open_only'], 1);
      expect(fresh.map((ReceivableItem i) => i.id), <String>['i2', 'i1', 'i3']);

      // Another customer is stored too and must survive the refresh of c1.
      await ReceivablesLocalDataSource(db)
          .putItem(t, itemJson('x1', customerId: 'c9'));
      adapter.handler = (RequestOptions o) => json(200, <String, dynamic>{
        'data': <Map<String, dynamic>>[itemJson('i9')],
      });
      await repo.refreshItems(t, 'c1');
      expect(
        (await repo.cachedItems(t, 'c1')).map((ReceivableItem i) => i.id),
        <String>['i9'],
      );
      expect(
        (await repo.cachedItems(t, 'c9')).map((ReceivableItem i) => i.id),
        <String>['x1'],
      );
    });

    test('an item with its allocations is stored for offline detail', () async {
      adapter.handler = (RequestOptions o) => json(
        200,
        envelope(
          itemJson(
            'i1',
            allocations: <Map<String, dynamic>>[allocationJson('a1', 'i1')],
          ),
        ),
      );
      final ReceivableItem fresh = await repo.refreshItem(t, 'i1');
      expect(fresh.allocations.single.id, 'a1');
      adapter.handler = offline;
      expect((await repo.cachedItem(t, 'i1'))!.allocations.length, 1);
      expect(await repo.cachedItem(t, 'nope'), isNull);
    });

    test('a statement is cached and downloaded as a file', () async {
      adapter.handler = (RequestOptions o) =>
          json(200, envelope(statementJson()));
      await repo.refreshStatement(
        t,
        'c1',
        from: DateTime(2030, 1, 1),
        to: DateTime(2030, 2, 10),
      );
      expect(adapter.calls.single.queryParameters['from'], '2030-01-01');
      expect(adapter.calls.single.queryParameters['to'], '2030-02-10');
      adapter.handler = offline;
      expect(
        (await repo.cachedStatement(t, 'c1'))!.closingBalance,
        Money.parse('280.00'),
      );

      adapter.handler = (RequestOptions o) =>
          ResponseBody.fromBytes(<int>[37, 80, 68, 70], 200);
      final List<int> bytes = await repo.downloadStatement(
        'c1',
        StatementFormat.pdf,
        from: DateTime(2030, 1, 1),
        to: DateTime(2030, 2, 10),
      );
      expect(bytes, <int>[37, 80, 68, 70]);
      expect(
        adapter.calls.last.path,
        '/invoicing/receivables/customers/c1/statement/pdf',
      );
      expect(adapter.calls.last.queryParameters['to'], '2030-02-10');
    });

    test('a statement download fails cleanly offline', () async {
      adapter.handler = offline;
      await expectLater(
        repo.downloadStatement('c1', StatementFormat.xlsx),
        throwsA(isA<ReceivablesException>()),
      );
    });
  });

  group('allocations', () {
    test(
      'online: sent with the contract body and an idempotency key',
      () async {
        await seed(<Map<String, dynamic>>[itemJson('i1')]);
        adapter.handler = ok;
        final BookingOutcome outcome = await repo.allocate(t, <AllocationDraft>[
          AllocationDraft(
            itemId: 'i1',
            type: AllocationType.payment,
            amount: Money.parse('40'),
            valueDate: DateTime(2030, 3, 4),
            sourceId: 'le1',
            reference: 'BANK-9',
          ),
        ]);
        expect(outcome.status, BookingStatus.sent);
        final RequestOptions call = posts().single;
        expect(call.path, '/invoicing/receivables/allocations');
        expect(call.data, <String, dynamic>{
          'allocations': <Map<String, dynamic>>[
            <String, dynamic>{
              'receivable_item_id': 'i1',
              'type': 'payment',
              'amount': '40.00',
              'value_date': '2030-03-04',
              'source_id': 'le1',
              'reference': 'BANK-9',
            },
          ],
        });
        expect(call.headers['Idempotency-Key'], isNotEmpty);
        expect(await engine.queued(t, receivableAllocationEntity), isEmpty);
      },
    );

    test('offline: queued, shown at once on the cached item and in the pending list', () async {
      await seed(<Map<String, dynamic>>[itemJson('i1')]);
      adapter.handler = offline;
      final BookingOutcome outcome = await repo.allocate(t, <AllocationDraft>[
        pay('i1', '40.00'),
      ]);
      expect(outcome.status, BookingStatus.queued);

      final ReceivableItem item = (await repo.cachedItem(t, 'i1'))!;
      expect(item.openAmount, Money.parse('60.00'));
      expect(item.settledAmount, Money.parse('40.00'));
      expect(item.status, ItemStatus.partiallyPaid);
      expect(
        (await repo.cachedItems(t, 'c1')).single.openAmount,
        Money.parse('60.00'),
      );

      final List<PendingBooking> pending = await repo.pendingActions(t);
      expect(pending.single.kind, ReceivablesActionKind.allocation);
      expect(pending.single.itemId, 'i1');
      expect(pending.single.amount, Money.parse('40.00'));
      expect(pending.single.rejected, isFalse);
      expect(await repo.pendingActions(t, itemId: 'other'), isEmpty);
    });

    test('the same booking tapped twice is queued once', () async {
      await seed(<Map<String, dynamic>>[itemJson('i1', open: '100.00')]);
      adapter.handler = offline;
      await repo.allocate(t, <AllocationDraft>[pay('i1', '30.00')]);
      final BookingOutcome again = await repo.allocate(t, <AllocationDraft>[
        pay('i1', '30.00'),
      ]);
      expect(again.status, BookingStatus.queued);
      expect(await engine.queued(t, receivableAllocationEntity), hasLength(1));
      // The duplicate is not applied to the cached item a second time either.
      expect(
        (await repo.cachedItem(t, 'i1'))!.openAmount,
        Money.parse('70.00'),
      );

      // A different amount is a different booking.
      await repo.allocate(t, <AllocationDraft>[pay('i1', '20.00')]);
      expect(await engine.queued(t, receivableAllocationEntity), hasLength(2));
      expect(
        (await repo.cachedItem(t, 'i1'))!.openAmount,
        Money.parse('50.00'),
      );
    });

    test('replay sends the queued booking once, with the same key on every attempt', () async {
      await seed(<Map<String, dynamic>>[itemJson('i1')]);
      adapter.handler = offline;
      await repo.allocate(t, <AllocationDraft>[pay('i1', '40.00')]);
      final String uuid = (await engine.queued(
        t,
        receivableAllocationEntity,
      )).single.uuid;
      // Still offline on a second cycle: the request is attempted again under the same key.
      expect(await repo.flush(t), 0);

      adapter.handler = ok;
      expect(await repo.flush(t), 1);
      expect(await repo.flush(t), 0);

      final List<String?> keys = <String?>[
        for (final RequestOptions o in posts())
          o.headers['Idempotency-Key'] as String?,
      ];
      expect(keys, isNotEmpty);
      expect(keys.toSet(), <String?>{uuid});
      expect(await engine.queued(t, receivableAllocationEntity), isEmpty);
      expect(await repo.pendingActions(t), isEmpty);
    });

    test('a refused booking is parked, shown as rejected and not applied locally', () async {
      await seed(<Map<String, dynamic>>[itemJson('i1')]);
      adapter.handler = (RequestOptions o) =>
          json(422, <String, dynamic>{'message': 'Item already settled'});
      final BookingOutcome outcome = await repo.allocate(t, <AllocationDraft>[
        pay('i1', '40.00'),
      ]);
      expect(outcome.status, BookingStatus.rejected);
      expect(outcome.detail, isNotEmpty);
      expect(
        (await repo.cachedItem(t, 'i1'))!.openAmount,
        Money.parse('100.00'),
      );

      final PendingBooking parked = (await repo.pendingActions(t)).single;
      expect(parked.rejected, isTrue);

      // The refused row is not resent on every sync cycle.
      adapter.calls.clear();
      expect(await repo.flush(t), 0);
      expect(adapter.calls, isEmpty);

      // Retry puts it back in line; once the server accepts it the row is gone.
      adapter.handler = ok;
      await repo.retryAction(t, parked.queueUuid);
      expect(await repo.pendingActions(t), isEmpty);
    });

    test('dismissing a refused booking removes it from the outbox', () async {
      await seed(<Map<String, dynamic>>[itemJson('i1')]);
      adapter.handler = (RequestOptions o) => json(403, <String, dynamic>{});
      await repo.allocate(t, <AllocationDraft>[pay('i1', '1.00')]);
      final PendingBooking parked = (await repo.pendingActions(t)).single;
      expect(parked.rejected, isTrue);
      await repo.dismissAction(parked.queueUuid);
      expect(await repo.pendingActions(t), isEmpty);
    });

    test('the local status follows the server vocabulary', () async {
      final List<
        ({
          String name,
          Map<String, dynamic> item,
          AllocationType type,
          String amount,
          String open,
          String status,
        })
      >
      cases =
          <
            ({
              String name,
              Map<String, dynamic> item,
              AllocationType type,
              String amount,
              String open,
              String status,
            })
          >[
            (
              name: 'full payment',
              item: itemJson('i1'),
              type: AllocationType.payment,
              amount: '100.00',
              open: '0.00',
              status: 'paid',
            ),
            (
              name: 'full write-off',
              item: itemJson('i1'),
              type: AllocationType.writeOff,
              amount: '100.00',
              open: '0.00',
              status: 'written_off',
            ),
            (
              name: 'partial on an overdue item stays overdue',
              item: itemJson('i1', days: 10, status: 'overdue'),
              type: AllocationType.discount,
              amount: '10.00',
              open: '90.00',
              status: 'overdue',
            ),
            (
              name: 'partial on a disputed item stays disputed',
              item: itemJson('i1', status: 'disputed'),
              type: AllocationType.creditNote,
              amount: '5.00',
              open: '95.00',
              status: 'disputed',
            ),
            (
              name: 'partial on a current item',
              item: itemJson('i1'),
              type: AllocationType.payment,
              amount: '0.01',
              open: '99.99',
              status: 'partially_paid',
            ),
          ];
      for (final c in cases) {
        await db.delete(db.entityRecords).go();
        await db.delete(db.syncQueue).go();
        await seed(<Map<String, dynamic>>[c.item]);
        adapter.handler = offline;
        await repo.allocate(t, <AllocationDraft>[
          pay('i1', c.amount, type: c.type),
        ]);
        final ReceivableItem item = (await repo.cachedItem(t, 'i1'))!;
        expect(item.openAmount, Money.parse(c.open), reason: c.name);
        expect(item.status.wire, c.status, reason: c.name);
      }
    });

    test('cents never drift when many small bookings are applied', () async {
      await seed(<Map<String, dynamic>>[itemJson('i1', open: '1.00')]);
      adapter.handler = offline;
      // 0.01 + 0.02 + ... + 0.10 = 0.55, each a distinct booking.
      for (int i = 1; i <= 10; i++) {
        await repo.allocate(t, <AllocationDraft>[
          pay('i1', '0.${i.toString().padLeft(2, '0')}'),
        ]);
      }
      final ReceivableItem item = (await repo.cachedItem(t, 'i1'))!;
      expect(item.openAmount + item.settledAmount, Money.parse('1.00'));
      expect(item.settledAmount, Money.parse('0.55'));
      expect(item.openAmount, Money.parse('0.45'));
      expect(await engine.queued(t, receivableAllocationEntity), hasLength(10));
    });
  });

  group('reversal', () {
    Future<void> seedAllocated() => seed(<Map<String, dynamic>>[
      itemJson(
        'i1',
        open: '60.00',
        settled: '40.00',
        status: 'partially_paid',
        allocations: <Map<String, dynamic>>[allocationJson('a1', 'i1')],
      ),
    ]);

    test('online: posts to the reverse endpoint', () async {
      await seedAllocated();
      adapter.handler = ok;
      final BookingOutcome outcome = await repo.reverseAllocation(
        t,
        'i1',
        'a1',
      );
      expect(outcome.status, BookingStatus.sent);
      expect(
        posts().single.path,
        '/invoicing/receivables/allocations/a1/reverse',
      );
    });

    test('offline: queued, the cached item gets its amount back and the pending row knows its item', () async {
      await seedAllocated();
      adapter.handler = offline;
      final BookingOutcome outcome = await repo.reverseAllocation(
        t,
        'i1',
        'a1',
      );
      expect(outcome.status, BookingStatus.queued);

      final ReceivableItem item = (await repo.cachedItem(t, 'i1'))!;
      expect(item.openAmount, Money.parse('100.00'));
      expect(item.settledAmount, Money.zero);
      expect(item.status, ItemStatus.open);
      expect(item.allocations.single.isReversed, isTrue);

      final PendingBooking pending = (await repo.pendingActions(t)).single;
      expect(pending.kind, ReceivablesActionKind.reversal);
      expect(pending.allocationId, 'a1');
      expect(pending.itemId, 'i1');
      expect(await repo.pendingActions(t, itemId: 'i1'), hasLength(1));
    });

    test('a second reversal of the same allocation adds nothing', () async {
      await seedAllocated();
      adapter.handler = offline;
      await repo.reverseAllocation(t, 'i1', 'a1');
      final BookingOutcome again = await repo.reverseAllocation(t, 'i1', 'a1');
      expect(again.status, BookingStatus.queued);
      expect(await engine.queued(t, receivableReversalEntity), hasLength(1));
      // The amount is restored once, not twice.
      expect(
        (await repo.cachedItem(t, 'i1'))!.openAmount,
        Money.parse('100.00'),
      );
    });

    test('replay posts the reversal once with the queue key', () async {
      await seedAllocated();
      adapter.handler = offline;
      await repo.reverseAllocation(t, 'i1', 'a1');
      final String uuid = (await engine.queued(
        t,
        receivableReversalEntity,
      )).single.uuid;
      adapter.handler = ok;
      expect(await repo.flush(t), 1);
      expect(posts().last.headers['Idempotency-Key'], uuid);
      expect(await repo.flush(t), 0);
    });

    test(
      'a refused reversal is shown as rejected and not applied locally',
      () async {
        await seedAllocated();
        adapter.handler = (RequestOptions o) =>
            json(422, <String, dynamic>{'message': 'Already reversed'});
        final BookingOutcome outcome = await repo.reverseAllocation(
          t,
          'i1',
          'a1',
        );
        expect(outcome.status, BookingStatus.rejected);
        expect(
          (await repo.cachedItem(t, 'i1'))!.openAmount,
          Money.parse('60.00'),
        );
      },
    );
  });

  group('dispute', () {
    test('online: reason is trimmed and the lift sends no reason', () async {
      await seed(<Map<String, dynamic>>[itemJson('i1')]);
      adapter.handler = ok;
      await repo.setDispute(t, 'i1', disputed: true, reason: '  wrong price ');
      await repo.setDispute(t, 'i1', disputed: false, reason: 'ignored');
      expect(posts().first.path, '/invoicing/receivables/items/i1/dispute');
      expect(posts().first.data, <String, dynamic>{
        'disputed': true,
        'reason': 'wrong price',
      });
      expect(posts().last.data, <String, dynamic>{'disputed': false});
    });

    test('offline: the cached item is disputed at once and the lift restores its status', () async {
      await seed(<Map<String, dynamic>>[
        itemJson('i1', days: 5, status: 'overdue'),
        itemJson('i2'),
      ]);
      adapter.handler = offline;
      final BookingOutcome outcome = await repo.setDispute(
        t,
        'i1',
        disputed: true,
        reason: 'wrong price',
      );
      expect(outcome.status, BookingStatus.queued);
      ReceivableItem item = (await repo.cachedItem(t, 'i1'))!;
      expect(item.status, ItemStatus.disputed);
      expect(item.disputeReason, 'wrong price');
      final PendingBooking pending = (await repo.pendingActions(t)).single;
      expect(pending.kind, ReceivablesActionKind.dispute);
      expect(pending.itemId, 'i1');

      await repo.setDispute(t, 'i1', disputed: false);
      item = (await repo.cachedItem(t, 'i1'))!;
      expect(item.status, ItemStatus.overdue);
      expect(item.disputeReason, isNull);
      expect((await repo.cachedItem(t, 'i2'))!.status, ItemStatus.open);
      expect(await engine.queued(t, receivableDisputeEntity), hasLength(2));
    });

    test('the same dispute twice is queued once', () async {
      await seed(<Map<String, dynamic>>[itemJson('i1')]);
      adapter.handler = offline;
      await repo.setDispute(t, 'i1', disputed: true, reason: 'x');
      await repo.setDispute(t, 'i1', disputed: true, reason: 'x');
      expect(await engine.queued(t, receivableDisputeEntity), hasLength(1));
    });

    test('the outbox rows are decodable JSON bodies', () async {
      await seed(<Map<String, dynamic>>[itemJson('i1')]);
      adapter.handler = offline;
      await repo.setDispute(t, 'i1', disputed: true, reason: 'x');
      final String payload = (await engine.queued(
        t,
        receivableDisputeEntity,
      )).single.payload!;
      expect(jsonDecode(payload), <String, dynamic>{
        'disputed': true,
        'reason': 'x',
      });
    });
  });
}
