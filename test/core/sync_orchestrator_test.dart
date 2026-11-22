import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:fattura_facile/core/database/app_database.dart';
import 'package:fattura_facile/core/sync/sync_engine.dart';
import 'package:fattura_facile/core/sync/sync_orchestrator.dart';
import 'package:flutter_test/flutter_test.dart';

import 'sync_engine_test.dart' show FakeAdapter, Handler, json;

void main() {
  late AppDatabase db;
  late FakeAdapter adapter;
  late SyncEngine engine;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    adapter = FakeAdapter((RequestOptions o) {
      if (o.path.startsWith('/mobile/sync/')) {
        return json(200, <String, dynamic>{
          'data': <String, dynamic>{
            'data': <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 'c1',
                'company_name': 'Acme',
                'updated_at': '2026-01-01T00:00:00Z',
              },
            ],
            'deleted': <String>[],
            'has_more': false,
            'server_time': '2026-01-02T00:00:00Z',
          },
        });
      }
      return json(200, <String, dynamic>{
        'data': <String, dynamic>{'id': 'srv'},
      });
    });
    final Dio dio = Dio(
      BaseOptions(
        baseUrl: 'http://x/api/v1',
        validateStatus: (int? s) => s != null && s < 300,
      ),
    )..httpClientAdapter = adapter;
    engine = SyncEngine(db, dio);
  });

  tearDown(() => db.close());

  test('a cycle flushes the outbox before pulling every entity', () async {
    await engine.create(
      tenantId: 't1',
      entity: 'expenses',
      path: '/expenses',
      data: <String, dynamic>{'amount_gross': 5},
    );
    await SyncOrchestrator(engine).run('t1', <String>['contacts']);

    expect(adapter.calls.first.method, 'POST');
    expect(
      adapter.calls.map((RequestOptions c) => c.path),
      contains('/mobile/sync/contacts'),
    );
    expect((await engine.watch('t1', 'contacts').first).single.id, 'c1');
    expect(await db.select(db.syncQueue).get(), isEmpty);
  });

  test('offline cycles stop before pulling and never throw', () async {
    await engine.create(
      tenantId: 't1',
      entity: 'expenses',
      path: '/expenses',
      data: <String, dynamic>{},
    );
    adapter.handler = (RequestOptions o) =>
        throw DioException.connectionError(requestOptions: o, reason: 'down');
    await SyncOrchestrator(engine).run('t1', <String>['contacts']);
    expect(
      adapter.calls.where(
        (RequestOptions c) => c.path.startsWith('/mobile/sync/'),
      ),
      isEmpty,
    );
    expect(await db.select(db.syncQueue).get(), hasLength(1));
  });

  test('a failing feed does not block the other entities', () async {
    final FakeAdapter inner = adapter;
    final Handler base = inner.handler;
    inner.handler = (RequestOptions o) =>
        o.path == '/mobile/sync/products' ? throw StateError('boom') : base(o);
    await SyncOrchestrator(engine).run('t1', <String>['products', 'contacts']);
    expect((await engine.watch('t1', 'contacts').first), hasLength(1));
  });

  test('commands are queued without a local record and sent with the idempotency key', () async {
    final String id = await engine.enqueueCommand(
      tenantId: 't1',
      entity: 'approval_decisions',
      path: '/mobile/approvals/s1/decision',
      data: <String, dynamic>{'decision': 'approved'},
    );
    expect(id, isNotEmpty);
    expect(await engine.watch('t1', 'approval_decisions').first, isEmpty);
    final FlushReport report = await engine.flush('t1');
    expect(report.sent, 1);
    expect(adapter.calls.single.headers['Idempotency-Key'], isNotNull);
    expect(jsonDecode(jsonEncode(adapter.calls.single.data)), <String, dynamic>{
      'decision': 'approved',
    });
  });

  test(
    'a conflicting write can be retried or replaced by the server version',
    () async {
      final String id = await engine.create(
        tenantId: 't1',
        entity: 'contacts',
        path: '/crm/contacts',
        data: <String, dynamic>{'company_name': 'Mine'},
      );
      adapter.handler = (RequestOptions o) =>
          json(409, <String, dynamic>{'message': 'stale'});
      expect((await engine.flush('t1')).conflicts, 1);

      final List<QueueItem> issues = await engine.watchIssues('t1').first;
      expect(issues.single.state, QueueState.conflict);

      await engine.retry(issues.single.uuid);
      expect(await engine.watchIssues('t1').first, isEmpty);

      adapter.handler = (RequestOptions o) =>
          json(409, <String, dynamic>{'message': 'stale'});
      await engine.flush('t1');
      final QueueItem again = (await engine.watchIssues('t1').first).single;
      await engine.discard(again.uuid);
      expect(await db.select(db.syncQueue).get(), isEmpty);
      expect(
        await engine
            .watch('t1', 'contacts')
            .first
            .then(
              (List<EntityRecord> r) => r.where((EntityRecord e) => e.id == id),
            ),
        isEmpty,
      );
      expect(await db.select(db.syncCursors).get(), isEmpty);
    },
  );
}
