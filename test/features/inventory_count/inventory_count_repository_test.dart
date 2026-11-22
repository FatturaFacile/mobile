import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:fattura_facile/core/database/app_database.dart';
import 'package:fattura_facile/features/inventory_count/data/inventory_count_repository.dart';
import 'package:fattura_facile/features/inventory_count/domain/inventory_count_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/sync_engine_test.dart' show json;
import 'support.dart';

void main() {
  late CountFixture f;

  setUp(() => f = CountFixture());
  tearDown(() => f.dispose());

  Future<void> recordTwo() async {
    await f.repo.recordCount(
      tenant,
      sessionId: 's1',
      lineId: 'l1',
      quantity: 4,
      notes: ' damaged box ',
    );
    await f.repo.recordCount(
      tenant,
      sessionId: 's1',
      lineId: 'l2',
      quantity: 7.5,
    );
  }

  group('sessions', () {
    test(
      'refresh asks for the own sessions and caches them with progress',
      () async {
        f.route(
          sessions: <Map<String, dynamic>>[sessionJson('s1')],
          sheet: <Map<String, dynamic>>[
            lineJson('l1'),
            lineJson('l2', sku: 'SKU-2'),
          ],
        );
        final List<CountSession> fresh = await f.repo.refreshSessions(tenant);
        expect(f.adapter.calls.single.queryParameters['assigned_to'], 'me');
        expect(fresh.single.sessionNumber, 'INV-s1');
        expect(fresh.single.warehouseName, 'Main warehouse');
        expect(fresh.single.isFrozen, isTrue);
        expect(fresh.single.totalLines, 0);

        await f.repo.refreshSheet(tenant, 's1');
        await f.repo.recordCount(
          tenant,
          sessionId: 's1',
          lineId: 'l1',
          quantity: 1,
        );
        final CountSession s = (await f.repo.cachedSessions(tenant)).single;
        expect(s.totalLines, 2);
        expect(s.countedLines, 1);
        expect(s.pendingEntries, 1);
      },
    );

    test('a session that is no longer assigned is dropped unless entries wait to be sent', () async {
      f.route(
        sessions: <Map<String, dynamic>>[sessionJson('s1'), sessionJson('s2')],
        sheet: <Map<String, dynamic>>[lineJson('l1')],
      );
      await f.repo.refreshSessions(tenant);
      await f.repo.refreshSheet(tenant, 's2');
      await f.repo.recordCount(
        tenant,
        sessionId: 's2',
        lineId: 'l1',
        quantity: 1,
      );

      f.route(sessions: <Map<String, dynamic>>[]);
      final List<CountSession> after = await f.repo.refreshSessions(tenant);
      expect(after.map((CountSession s) => s.id), <String>['s2']);
    });

    test(
      'offline refresh raises an offline error and keeps the cache',
      () async {
        f.route(sessions: <Map<String, dynamic>>[sessionJson('s1')]);
        await f.repo.refreshSessions(tenant);
        f.adapter.handler = (RequestOptions o) => throw DioException(
          requestOptions: o,
          type: DioExceptionType.connectionError,
        );
        await expectLater(
          f.repo.refreshSessions(tenant),
          throwsA(
            isA<CountException>().having(
              (CountException e) => e.kind,
              'kind',
              CountErrorKind.offline,
            ),
          ),
        );
        expect(await f.repo.cachedSessions(tenant), hasLength(1));
      },
    );
  });

  group('blind sheet', () {
    test('never stores or exposes system quantity, cost, variance or expected stock', () async {
      f.route(
        sessions: <Map<String, dynamic>>[sessionJson('s1')],
        sheet: <Map<String, dynamic>>[
          lineJson(
            'l1',
            extra: <String, dynamic>{
              'system_quantity': 99,
              'expected_quantity': 99,
              'unit_cost': 12.5,
              'variance_quantity': 3,
              'variance_value': 37.5,
            },
          ),
        ],
      );
      await f.repo.refreshSheet(tenant, 's1');

      final List<EntityRecord> rows = await (f.db.select(
        f.db.entityRecords,
      )..where((EntityRecords t) => t.entity.equals(countLineEntity))).get();
      final String stored = rows.map((EntityRecord r) => r.payload).join();
      for (final String forbidden in <String>[
        'system_quantity',
        'expected_quantity',
        'unit_cost',
        'variance',
        '99',
        '12.5',
      ]) {
        expect(stored, isNot(contains(forbidden)));
      }
      final CountLine line = (await f.repo.cachedSheet(tenant, 's1')).single;
      expect(line.toJson().keys, isNot(contains('system_quantity')));
      expect(line.firstCountedQuantity, isNull);
    });

    test('the previous count is only kept when the API reveals it', () async {
      f.route(
        sessions: <Map<String, dynamic>>[sessionJson('s1')],
        sheet: <Map<String, dynamic>>[
          lineJson('l1', recount: true, round: 1),
          lineJson('l2', recount: true, round: 1, first: 8),
        ],
      );
      final List<CountLine> lines = await f.repo.refreshSheet(tenant, 's1');
      expect(lines[0].firstCountedQuantity, isNull);
      expect(lines[0].recountRequired, isTrue);
      expect(lines[0].shownQuantity, isNull);
      expect(lines[1].firstCountedQuantity, 8);
    });

    test('pending=1 refresh merges without dropping the other lines', () async {
      f.route(
        sessions: <Map<String, dynamic>>[sessionJson('s1')],
        sheet: <Map<String, dynamic>>[lineJson('l1'), lineJson('l2')],
      );
      await f.repo.refreshSheet(tenant, 's1');
      f.route(
        sessions: <Map<String, dynamic>>[sessionJson('s1')],
        sheet: <Map<String, dynamic>>[lineJson('l2', recount: true, round: 1)],
      );
      final List<CountLine> lines = await f.repo.refreshSheet(
        tenant,
        's1',
        pendingOnly: true,
      );
      expect(f.adapter.calls.last.queryParameters['pending'], 1);
      expect(lines, hasLength(2));
      expect(lines.last.recountRequired, isTrue);
    });
  });

  group('offline entries', () {
    test('each count gets a client UUID, is stored locally and never touches the network', () async {
      await recordTwo();
      expect(f.adapter.calls, isEmpty);
      expect(await f.repo.pendingCount(tenant), 2);
      expect(await f.repo.watchPendingCount(tenant).first, 2);

      final List<EntityRecord> rows = await (f.db.select(
        f.db.entityRecords,
      )..where((EntityRecords t) => t.entity.equals(countEntryEntity))).get();
      final Set<String> ids = rows.map((EntityRecord r) => r.id).toSet();
      expect(ids, hasLength(2));
      for (final String id in ids) {
        expect(RegExp(r'^[0-9a-f-]{36}$').hasMatch(id), isTrue);
      }
      expect(
        rows.every(
          (EntityRecord r) => r.syncStatus == SyncStatus.pendingCreate,
        ),
        isTrue,
      );
    });

    test('rejects a negative or non finite quantity', () async {
      for (final double q in <double>[-1, double.nan, double.infinity]) {
        await expectLater(
          f.repo.recordCount(
            tenant,
            sessionId: 's1',
            lineId: 'l1',
            quantity: q,
          ),
          throwsA(isA<CountException>()),
        );
      }
      expect(await f.repo.pendingCount(tenant), 0);
    });

    test('a count typed twice before sending replaces the first one', () async {
      await f.repo.recordCount(
        tenant,
        sessionId: 's1',
        lineId: 'l1',
        quantity: 1,
      );
      await f.repo.recordCount(
        tenant,
        sessionId: 's1',
        lineId: 'l1',
        quantity: 2,
      );
      expect(await f.repo.pendingCount(tenant), 1);
    });

    test('flush sends one batch per session with the entries and applies the per-entry outcomes', () async {
      await recordTwo();
      f.route(
        record: (RequestOptions o) {
          final List<dynamic> entries =
              (o.data as Map<String, dynamic>)['entries'] as List<dynamic>;
          return json(200, <String, dynamic>{
            'data': <Map<String, dynamic>>[
              <String, dynamic>{
                'client_entry_id':
                    (entries[0] as Map<String, dynamic>)['client_entry_id'],
                'session_line_id': 'l1',
                'status': 'recorded',
              },
              <String, dynamic>{
                'client_entry_id':
                    (entries[1] as Map<String, dynamic>)['client_entry_id'],
                'session_line_id': 'l2',
                'status': 'recount_required',
                'recount_round': 1,
              },
            ],
          });
        },
      );

      final CountSyncReport report = await f.repo.flush(tenant);

      expect(f.adapter.calls, hasLength(1));
      expect(
        f.adapter.calls.single.path,
        endsWith('/inventory/counts/s1/record-counts'),
      );
      final List<dynamic> sent =
          (f.adapter.calls.single.data as Map<String, dynamic>)['entries']
              as List<dynamic>;
      expect(sent, hasLength(2));
      expect((sent[0] as Map<String, dynamic>)['counted_quantity'], 4);
      expect((sent[0] as Map<String, dynamic>)['notes'], 'damaged box');
      expect((sent[1] as Map<String, dynamic>).containsKey('notes'), isFalse);
      expect(report.recorded, 1);
      expect(report.recountRequired, 1);
      expect(report.stillPending, 0);
      expect(report.affectedSessionIds, <String>{'s1'});
      expect(await f.repo.pendingCount(tenant), 0);
    });

    test('a network failure keeps the entries pending and a resend reuses the same client_entry_id', () async {
      await f.repo.recordCount(
        tenant,
        sessionId: 's1',
        lineId: 'l1',
        quantity: 3,
      );
      final List<String> seen = <String>[];
      f.adapter.handler = (RequestOptions o) {
        seen.add(
          ((o.data as Map<String, dynamic>)['entries'] as List<dynamic>)
              .map(
                (dynamic e) =>
                    (e as Map<String, dynamic>)['client_entry_id'] as String,
              )
              .single,
        );
        throw DioException(
          requestOptions: o,
          type: DioExceptionType.connectionError,
        );
      };
      final CountSyncReport first = await f.repo.flush(tenant);
      expect(first.offline, isTrue);
      expect(first.stillPending, 1);
      expect(await f.repo.pendingCount(tenant), 1);

      f.route(record: CountFixture.answer('recorded'));
      final CountSyncReport second = await f.repo.flush(tenant);
      expect(second.recorded, 1);
      final dynamic resent = f.adapter.calls.last.data;
      expect(
        ((resent as Map<String, dynamic>)['entries'] as List<dynamic>)
            .single['client_entry_id'],
        seen.single,
      );
    });

    test('a 5xx keeps the entries pending without refusing them', () async {
      await f.repo.recordCount(
        tenant,
        sessionId: 's1',
        lineId: 'l1',
        quantity: 3,
      );
      f.adapter.handler = (RequestOptions o) => throw DioException(
        requestOptions: o,
        response: Response<dynamic>(requestOptions: o, statusCode: 503),
      );
      final CountSyncReport r = await f.repo.flush(tenant);
      expect(r.stillPending, 1);
      expect(r.rejected, 0);
      expect(await f.repo.pendingCount(tenant), 1);
    });

    test('a refused entry is marked rejected with the server message and the line keeps the server value', () async {
      f.route(
        sessions: <Map<String, dynamic>>[sessionJson('s1')],
        sheet: <Map<String, dynamic>>[lineJson('l1')],
        record: CountFixture.answer('rejected', message: 'Already counted'),
      );
      await f.repo.refreshSheet(tenant, 's1');
      await f.repo.recordCount(
        tenant,
        sessionId: 's1',
        lineId: 'l1',
        quantity: 5,
      );

      final CountSyncReport report = await f.repo.sync(tenant);
      expect(report.rejected, 1);
      expect(await f.repo.pendingCount(tenant), 0);

      final CountLine line = (await f.repo.cachedSheet(tenant, 's1')).single;
      expect(line.rejected, isTrue);
      expect(line.entry!.message, 'Already counted');
      expect(line.shownQuantity, isNull);
      expect(line.toCount, isTrue);

      await f.repo.dismissEntry(tenant, line.entry!.clientEntryId);
      expect((await f.repo.cachedSheet(tenant, 's1')).single.entry, isNull);
    });

    test('a 422 refuses the whole batch with the validation message', () async {
      await f.repo.recordCount(
        tenant,
        sessionId: 's1',
        lineId: 'l1',
        quantity: 5,
      );
      f.adapter.handler = (RequestOptions o) => throw DioException(
        requestOptions: o,
        response: Response<dynamic>(
          requestOptions: o,
          statusCode: 422,
          data: <String, dynamic>{
            'message': 'invalid',
            'errors': <String, dynamic>{
              'entries.0.session_line_id': <String>[
                'Line is not part of the session',
              ],
            },
          },
        ),
      );
      final CountSyncReport r = await f.repo.flush(tenant);
      expect(r.rejected, 1);
      expect(await f.repo.pendingCount(tenant), 0);
    });

    test('entries are sent in batches of at most the batch size', () async {
      for (int i = 0; i < countBatchSize + 5; i++) {
        await f.repo.recordCount(
          tenant,
          sessionId: 's1',
          lineId: 'l$i',
          quantity: 1,
        );
      }
      f.route(record: CountFixture.answer('recorded'));
      final CountSyncReport r = await f.repo.flush(tenant);
      expect(f.adapter.calls, hasLength(2));
      expect(r.recorded, countBatchSize + 5);
    });

    test('an entry the server does not answer stays pending', () async {
      await recordTwo();
      f.adapter.handler = (RequestOptions o) => json(200, <String, dynamic>{
        'data': <Map<String, dynamic>>[
          <String, dynamic>{
            'client_entry_id':
                (((o.data as Map<String, dynamic>)['entries']
                        as List<dynamic>)[0]
                    as Map<String, dynamic>)['client_entry_id'],
            'status': 'recorded',
          },
        ],
      });
      final CountSyncReport r = await f.repo.flush(tenant);
      expect(r.recorded, 1);
      expect(r.stillPending, 1);
    });

    test('sync refreshes the sheet so the new recount flag shows and answered entries are dropped', () async {
      f.route(
        sessions: <Map<String, dynamic>>[sessionJson('s1')],
        sheet: <Map<String, dynamic>>[lineJson('l1')],
        record: CountFixture.answer('recount_required', round: 1),
      );
      await f.repo.refreshSheet(tenant, 's1');
      await f.repo.recordCount(
        tenant,
        sessionId: 's1',
        lineId: 'l1',
        quantity: 5,
      );
      f.route(
        sessions: <Map<String, dynamic>>[sessionJson('s1')],
        sheet: <Map<String, dynamic>>[lineJson('l1', recount: true, round: 1)],
        record: CountFixture.answer('recount_required', round: 1),
      );

      final CountSyncReport r = await f.repo.sync(tenant);

      expect(r.recountRequired, 1);
      final CountLine line = (await f.repo.cachedSheet(tenant, 's1')).single;
      expect(line.recountRequired, isTrue);
      expect(line.recountRound, 1);
      expect(line.entry, isNull);
      expect(line.toCount, isTrue);
      expect(
        jsonEncode(line.toJson()),
        isNot(contains('"counted_quantity":5')),
      );
    });
  });
}
