import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:fattura_facile/core/database/app_database.dart';
import 'package:fattura_facile/features/shop_floor/data/local/shop_floor_tables.dart';
import 'package:fattura_facile/features/shop_floor/data/shop_floor_outbox.dart';
import 'package:fattura_facile/features/shop_floor/data/shop_floor_repository.dart';
import 'package:fattura_facile/features/shop_floor/domain/shop_floor_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

DioException _offline(RequestOptions o) =>
    DioException.connectionError(requestOptions: o, reason: 'down');

void main() {
  late Harness h;

  setUp(() async {
    h = Harness();
    await h.seed();
  });

  tearDown(() => h.close());

  group('offline scan-to-backflush', () {
    test(
      'staged lots are held locally and queued in scan order as one issue each',
      () async {
        await h.repo.stageLot(
          tenantId: tenant,
          orderId: orderId,
          lineId: lineA,
          lotNumber: 'L-1',
          quantity: 5,
          lotId: '99999999-9999-4999-8999-999999999999',
        );
        await h.repo.stageLot(
          tenantId: tenant,
          orderId: orderId,
          lineId: lineB,
          lotNumber: 'L-2',
          quantity: 2.5,
        );
        expect(
          h.posts(),
          isEmpty,
          reason: 'staging alone never talks to the server',
        );

        final List<String> keys = await h.repo.backflush(tenant, orderId);
        expect(keys, hasLength(2));

        final List<MfgOutboxRow> rows = await h.outbox.all(tenant);
        expect(rows.map((MfgOutboxRow r) => r.uuid), keys);
        expect(rows.map((MfgOutboxRow r) => r.kind).toSet(), <String>{
          OutboxKind.issue,
        });
        final Map<String, dynamic> first =
            jsonDecode(rows[0].payload) as Map<String, dynamic>;
        expect((first['lines'] as List<dynamic>).single, <String, dynamic>{
          'line_id': lineA,
          'quantity': '5.0000',
          'lot_id': '99999999-9999-4999-8999-999999999999',
        });
        final Map<String, dynamic> second =
            jsonDecode(rows[1].payload) as Map<String, dynamic>;
        expect((second['lines'] as List<dynamic>).single, <String, dynamic>{
          'line_id': lineB,
          'quantity': '2.5000',
        });

        // A second backflush does not queue the same lots twice.
        expect(await h.repo.backflush(tenant, orderId), isEmpty);
        expect(
          await h.repo.watchStaged(tenant, orderId).first,
          everyElement(predicate((dynamic s) => (s as dynamic).posted == true)),
        );
      },
    );

    test('flush sends in order, each with its own uuid as Idempotency-Key, to the right endpoint', () async {
      await h.repo.stageLot(
        tenantId: tenant,
        orderId: orderId,
        lineId: lineA,
        lotNumber: 'L-1',
        quantity: 1,
      );
      await h.repo.stageLot(
        tenantId: tenant,
        orderId: orderId,
        lineId: lineB,
        lotNumber: 'L-2',
        quantity: 2,
      );
      final List<String> keys = await h.repo.backflush(tenant, orderId);

      final OutboxFlushReport report = await h.outbox.flush(tenant);

      expect(report.sent, 2);
      final List<RequestOptions> posts = h.posts();
      expect(
        posts.map((RequestOptions r) => r.headers['Idempotency-Key']),
        keys,
      );
      expect(
        posts.every(
          (RequestOptions r) =>
              r.path == '/manufacturing/production-orders/$orderId/issues',
        ),
        isTrue,
      );
      expect(
        (await h.outbox.all(tenant))
            .every((MfgOutboxRow r) => r.state == OutboxState.done),
        isTrue,
      );
    });

    test('offline: nothing is lost, attempts are not burned and the queue drains once the network is back', () async {
      await h.repo.stageLot(
        tenantId: tenant,
        orderId: orderId,
        lineId: lineA,
        lotNumber: 'L-1',
        quantity: 1,
      );
      await h.repo.backflush(tenant, orderId);
      h.api.onPost = (RequestOptions o) => throw _offline(o);

      final OutboxFlushReport down = await h.outbox.flush(tenant);
      expect(down.offline, isTrue);
      MfgOutboxRow row = (await h.outbox.all(tenant)).single;
      expect(row.state, OutboxState.pending);
      expect(row.attempts, 0);
      expect(row.nextAttemptAt, isNull);

      h.api.onPost = null;
      expect((await h.outbox.flush(tenant)).sent, 1);
      row = (await h.outbox.all(tenant)).single;
      expect(row.state, OutboxState.done);
    });
  });

  group('idempotent retry', () {
    test('a lost response is retried with the same uuid and a 200 is recognised as an already applied replay', () async {
      await h.repo.startRun(tenant, orderId, opId);
      h.clock.advance(const Duration(minutes: 30));
      await h.repo.setCounters(tenant, orderId, opId, good: 8, scrap: 0);
      final String posting = await h.repo.confirm(
        tenantId: tenant,
        orderId: orderId,
        operationId: opId,
      );

      // Attempt 1: the server applies the posting but the response never arrives.
      h.api.onPost = (RequestOptions o) => throw DioException.receiveTimeout(
        timeout: const Duration(seconds: 30),
        requestOptions: o,
      );
      // A receive timeout is a transport error without a response: the outbox treats it as offline.
      expect((await h.outbox.flush(tenant)).offline, isTrue);

      // Attempt 2: the server recognises operation_posting_uuid and answers 200 instead of 201.
      h.api.onPost = (RequestOptions o) => jsonBody(200, <String, dynamic>{
        'data': <String, dynamic>{'id': 'conf-1'},
      });
      final OutboxFlushReport report = await h.outbox.flush(tenant);
      expect(report.sent, 1);
      expect(report.replayed, 1);

      final List<RequestOptions> posts = h.posts();
      expect(posts, hasLength(2));
      for (final RequestOptions p in posts) {
        expect(p.headers['Idempotency-Key'], posting);
        expect(
          (p.data as Map<String, dynamic>)['operation_posting_uuid'],
          posting,
        );
      }
      expect(
        posts[0].data,
        posts[1].data,
        reason: 'the retry resends the very same body',
      );
      final MfgOutboxRow row = (await h.outbox.all(tenant)).single;
      expect(row.state, OutboxState.done);
      expect(row.replayed, isTrue);
    });

    test('a 201 is a first application, not a replay', () async {
      await h.repo.setCounters(tenant, orderId, opId, good: 1, scrap: 0);
      await h.repo.confirm(
        tenantId: tenant,
        orderId: orderId,
        operationId: opId,
      );
      final OutboxFlushReport report = await h.outbox.flush(tenant);
      expect(report.replayed, 0);
      expect((await h.outbox.all(tenant)).single.replayed, isFalse);
    });

    test(
      'two confirmations of the same operation get two different posting uuids',
      () async {
        await h.repo.setCounters(tenant, orderId, opId, good: 1, scrap: 0);
        final String a = await h.repo.confirm(
          tenantId: tenant,
          orderId: orderId,
          operationId: opId,
        );
        await h.repo.setCounters(tenant, orderId, opId, good: 1, scrap: 0);
        final String b = await h.repo.confirm(
          tenantId: tenant,
          orderId: orderId,
          operationId: opId,
        );
        expect(a, isNot(b));
      },
    );
  });

  group('ordering', () {
    test(
      'a failing row blocks later rows of the same order but not other orders',
      () async {
        final String first = await h.outbox.enqueue(
          tenantId: tenant,
          kind: OutboxKind.issue,
          orderId: orderId,
          path: '/production-orders/$orderId/issues',
          payload: <String, dynamic>{'n': 1},
        );
        await h.outbox.enqueue(
          tenantId: tenant,
          kind: OutboxKind.issue,
          orderId: orderId,
          path: '/production-orders/$orderId/issues',
          payload: <String, dynamic>{'n': 2},
        );
        await h.outbox.enqueue(
          tenantId: tenant,
          kind: OutboxKind.issue,
          orderId: otherOrderId,
          path: '/production-orders/$otherOrderId/issues',
          payload: <String, dynamic>{'n': 3},
        );
        h.api.onPost = (RequestOptions o) =>
            (o.data as Map<String, dynamic>)['n'] == 1
            ? jsonBody(503, <String, dynamic>{'message': 'busy'})
            : jsonBody(201, <String, dynamic>{'data': <String, dynamic>{}});

        final OutboxFlushReport report = await h.outbox.flush(tenant);

        expect(report.failed, 1);
        expect(report.sent, 1);
        expect(report.deferred, 1);
        expect(
          h.posts().map(
            (RequestOptions r) => (r.data as Map<String, dynamic>)['n'],
          ),
          <int>[1, 3],
          reason: 'row 2 must not overtake row 1',
        );
        final List<MfgOutboxRow> rows = await h.outbox.all(tenant);
        expect(rows[0].uuid, first);
        expect(rows[0].state, OutboxState.failed);
        expect(rows[1].state, OutboxState.pending);
        expect(rows[2].state, OutboxState.done);
      },
    );

    test('rows of one order are sent strictly oldest first', () async {
      for (int n = 1; n <= 4; n++) {
        await h.outbox.enqueue(
          tenantId: tenant,
          kind: OutboxKind.issue,
          orderId: orderId,
          path: '/production-orders/$orderId/issues',
          payload: <String, dynamic>{'n': n},
        );
      }
      await h.outbox.flush(tenant);
      expect(
        h.posts().map(
          (RequestOptions r) => (r.data as Map<String, dynamic>)['n'],
        ),
        <int>[1, 2, 3, 4],
      );
    });

    test('a row waits for the row it depends on', () async {
      final String parent = await h.outbox.enqueue(
        tenantId: tenant,
        kind: OutboxKind.issue,
        orderId: otherOrderId,
        path: '/p',
        payload: <String, dynamic>{'n': 1},
      );
      await h.outbox.enqueue(
        tenantId: tenant,
        kind: OutboxKind.receipt,
        orderId: orderId,
        path: '/q',
        payload: <String, dynamic>{'n': 2},
        dependsOn: parent,
      );
      h.api.onPost = (RequestOptions o) =>
          (o.data as Map<String, dynamic>)['n'] == 1
          ? jsonBody(503, <String, dynamic>{})
          : jsonBody(201, <String, dynamic>{});
      await h.outbox.flush(tenant);
      expect(
        h.posts(),
        hasLength(1),
        reason: 'the dependent row is held back while its parent is open',
      );
    });
  });

  group('failure and backoff', () {
    test('transient failures back off exponentially up to the cap, and rows are not resent before they are due', () async {
      await h.outbox.enqueue(
        tenantId: tenant,
        kind: OutboxKind.issue,
        orderId: orderId,
        path: '/x',
        payload: <String, dynamic>{},
      );
      h.api.onPost = (RequestOptions o) =>
          jsonBody(500, <String, dynamic>{'message': 'boom'});

      expect(h.outbox.backoffFor(1), const Duration(seconds: 5));
      expect(h.outbox.backoffFor(2), const Duration(seconds: 10));
      expect(h.outbox.backoffFor(3), const Duration(seconds: 20));
      expect(h.outbox.backoffFor(30), const Duration(minutes: 15));

      await h.outbox.flush(tenant);
      MfgOutboxRow row = (await h.outbox.all(tenant)).single;
      expect(row.attempts, 1);
      expect(row.state, OutboxState.failed);
      expect(
        row.nextAttemptAt?.toUtc(),
        h.clock.now.add(const Duration(seconds: 5)),
      );
      expect(row.lastError, 'boom');

      // Not due yet: no request goes out.
      h.clock.advance(const Duration(seconds: 4));
      final OutboxFlushReport early = await h.outbox.flush(tenant);
      expect(early.deferred, 1);
      expect(h.posts(), hasLength(1));

      // Due: second attempt, second failure, doubled delay.
      h.clock.advance(const Duration(seconds: 1));
      await h.outbox.flush(tenant);
      row = (await h.outbox.all(tenant)).single;
      expect(row.attempts, 2);
      expect(
        row.nextAttemptAt?.toUtc(),
        h.clock.now.add(const Duration(seconds: 10)),
      );
      expect(h.posts(), hasLength(2));

      // Recovers once the server is healthy again, with the same uuid.
      h.api.onPost = null;
      h.clock.advance(const Duration(seconds: 10));
      expect((await h.outbox.flush(tenant)).sent, 1);
      expect(
        h
            .posts()
            .map((RequestOptions r) => r.headers['Idempotency-Key'])
            .toSet(),
        hasLength(1),
      );
    });

    test('a 422 is rejected for good, is never resent automatically and does not block the next row', () async {
      await h.outbox.enqueue(
        tenantId: tenant,
        kind: OutboxKind.confirm,
        orderId: orderId,
        path: '/bad',
        payload: <String, dynamic>{'n': 1},
      );
      await h.outbox.enqueue(
        tenantId: tenant,
        kind: OutboxKind.confirm,
        orderId: orderId,
        path: '/ok',
        payload: <String, dynamic>{'n': 2},
      );
      h.api.onPost = (RequestOptions o) => o.path.endsWith('/bad')
          ? jsonBody(422, <String, dynamic>{
              'message': 'invalid',
              'errors': <String, dynamic>{},
            })
          : jsonBody(201, <String, dynamic>{});

      final OutboxFlushReport report = await h.outbox.flush(tenant);
      expect(report.rejected, 1);
      expect(report.sent, 1);

      final List<MfgOutboxRow> rows = await h.outbox.all(tenant);
      expect(rows[0].state, OutboxState.rejected);
      expect(rows[0].lastError, 'invalid');
      expect(rows[1].state, OutboxState.done);

      final int before = h.api.calls.length;
      await h.outbox.flush(tenant);
      expect(h.api.calls.length, before, reason: 'rejected rows are parked');

      // The supervisor retries it: the row is back in line with the same uuid.
      await h.outbox.retry(rows[0].uuid);
      h.api.onPost = null;
      expect((await h.outbox.flush(tenant)).sent, 1);
    });

    test('401 stops the cycle without touching the rows', () async {
      await h.outbox.enqueue(
        tenantId: tenant,
        kind: OutboxKind.issue,
        orderId: orderId,
        path: '/x',
        payload: <String, dynamic>{},
      );
      h.api.onPost = (RequestOptions o) =>
          jsonBody(401, <String, dynamic>{'message': 'no'});
      final OutboxFlushReport report = await h.outbox.flush(tenant);
      expect(report.unauthorized, isTrue);
      expect((await h.outbox.all(tenant)).single.state, OutboxState.pending);
    });

    test('done rows are never discarded or retried', () async {
      final String key = await h.outbox.enqueue(
        tenantId: tenant,
        kind: OutboxKind.issue,
        orderId: orderId,
        path: '/x',
        payload: <String, dynamic>{},
      );
      await h.outbox.flush(tenant);
      await h.outbox.discard(key);
      expect(await h.outbox.all(tenant), hasLength(1));
    });
  });

  group('operator posting rules', () {
    test('confirm builds minutes from the stopwatch and good/scrap from the counters', () async {
      await h.repo.startSetup(tenant, orderId, opId);
      h.clock.advance(const Duration(minutes: 10));
      await h.repo.startRun(tenant, orderId, opId);
      h.clock.advance(const Duration(minutes: 45));
      await h.repo.pause(tenant, orderId, opId);
      h.clock.advance(const Duration(minutes: 5));
      await h.repo.resume(tenant, orderId, opId);
      h.clock.advance(const Duration(minutes: 15));
      await h.repo.setCounters(
        tenant,
        orderId,
        opId,
        good: 90,
        scrap: 2,
        scrapReason: 'burr',
      );

      final String key = await h.repo.confirm(
        tenantId: tenant,
        orderId: orderId,
        operationId: opId,
        isFinal: true,
      );

      final MfgOutboxRow row = (await h.outbox.all(tenant)).single;
      expect(row.uuid, key);
      expect(
        row.path,
        '/production-orders/$orderId/operations/$opId/confirmations',
      );
      final Map<String, dynamic> body =
          jsonDecode(row.payload) as Map<String, dynamic>;
      expect(body['setup_minutes'], '10.00');
      expect(body['run_minutes'], '60.00');
      expect(body['labor_minutes'], '70.00');
      expect(body['downtime_minutes'], '5.00');
      expect(body['good_quantity'], '90.0000');
      expect(body['scrap_quantity'], '2.0000');
      expect(body['scrap_reason'], 'burr');
      expect(body['is_final'], true);
      expect(body['operation_posting_uuid'], key);

      // The terminal is reset for the next lot.
      final OperationState after = await h.repo.operationState(tenant, opId);
      expect(after.counters.good, 0);
      expect(after.timer.phase, TerminalPhase.idle);
    });

    test('refuses an empty confirmation and scrap without a reason, queueing nothing', () async {
      await expectLater(
        h.repo.confirm(tenantId: tenant, orderId: orderId, operationId: opId),
        throwsA(
          isA<ShopFloorException>().having(
            (ShopFloorException e) => e.error,
            'error',
            ShopFloorError.nothingToPost,
          ),
        ),
      );
      await h.repo.setCounters(tenant, orderId, opId, good: 1, scrap: 1);
      await expectLater(
        h.repo.confirm(tenantId: tenant, orderId: orderId, operationId: opId),
        throwsA(
          isA<ShopFloorException>().having(
            (ShopFloorException e) => e.error,
            'error',
            ShopFloorError.scrapReasonRequired,
          ),
        ),
      );
      expect(await h.outbox.all(tenant), isEmpty);
    });

    test(
      'the stopwatch survives in SQLite (an app restart loses no time)',
      () async {
        await h.repo.startRun(tenant, orderId, opId);
        h.clock.advance(const Duration(minutes: 3));
        final OperationState s = await h.repo.operationState(tenant, opId);
        expect(s.timer.running, isTrue);
        expect(s.timer.snapshot(h.clock.now).runSeconds, 180);
      },
    );

    test(
      'check-in is queued as a shop-floor execution and remembered',
      () async {
        final wc = (await h.repo.findWorkCenter(tenant, 'wc-10'))!;
        await h.repo.checkIn(
          tenantId: tenant,
          orderId: orderId,
          operationId: opId,
          workCenter: wc,
          operatorId: 'u1',
        );
        final MfgOutboxRow row = (await h.outbox.all(tenant)).single;
        expect(row.path, '/shop-floor/executions');
        expect(jsonDecode(row.payload), <String, dynamic>{
          'production_order_operation_id': opId,
          'operator_id': 'u1',
        });
        expect(
          (await h.repo.operationState(
            tenant,
            opId,
          )).counters.machineWorkCenterId,
          wcId,
        );
      },
    );

    test(
      'receipt and QC sign-off are queued with the API field names',
      () async {
        await h.repo.receiveOutput(
          tenantId: tenant,
          orderId: orderId,
          quantity: 12,
          lotNumber: 'FG-LOT',
        );
        final plan = (await h.repo.qualityPlans(tenant)).single;
        await h.repo.signOffInspection(
          tenantId: tenant,
          orderId: orderId,
          operationId: opId,
          plan: plan,
          measurements: <String, double>{charId: 10.5},
          quantityInspected: 5,
          notes: 'ok',
        );
        final List<MfgOutboxRow> rows = await h.outbox.all(tenant);
        expect(rows[0].path, '/production-orders/$orderId/receipts');
        expect(
          (jsonDecode(rows[0].payload) as Map<String, dynamic>)['lot_number'],
          'FG-LOT',
        );
        final Map<String, dynamic> qc =
            jsonDecode(rows[1].payload) as Map<String, dynamic>;
        expect(rows[1].path, '/quality/inspections');
        expect(qc['inspection_point'], 'operation');
        expect(qc['defect_count'], 1, reason: '10.5 is outside 9.9..10.1');
        expect(
          (qc['characteristic_results'] as List<dynamic>).single,
          <String, dynamic>{
            'characteristic_id': charId,
            'measured_value': '10.5000',
          },
        );
      },
    );
  });
}
