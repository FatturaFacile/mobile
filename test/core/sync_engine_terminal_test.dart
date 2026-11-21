import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:fattura_facile/core/database/app_database.dart';
import 'package:fattura_facile/core/sync/sync_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'sync_engine_test.dart' show FakeAdapter, json;

void main() {
  late AppDatabase db;
  late FakeAdapter adapter;
  late SyncEngine engine;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    adapter = FakeAdapter(
      (RequestOptions o) =>
          json(422, <String, dynamic>{'detail': 'unreadable', 'status': 422}),
    );
    final Dio dio = Dio(
      BaseOptions(
        baseUrl: 'http://x/api/v1',
        validateStatus: (int? s) => s != null && s < 300,
      ),
    )..httpClientAdapter = adapter;
    engine = SyncEngine(db, dio);
  });

  tearDown(() => db.close());

  test('a 422 on a terminal entity is parked as rejected, shown as an issue and never resent', () async {
    await engine.enqueueCommand(
      tenantId: 't1',
      entity: 'ai_captures',
      path: '/ai/suggestions/extract',
      data: <String, dynamic>{'text': 'x'},
    );
    final FlushReport first = await engine.flush('t1');
    expect(first.failed, 1);
    await engine.flush('t1');
    expect(adapter.calls, hasLength(1));

    final QueueItem item = (await db.select(db.syncQueue).get()).single;
    expect(item.state, QueueState.rejected);
    expect(item.lastError, 'unreadable', reason: 'RFC 7807 detail is surfaced');
    expect((await engine.watchIssues('t1').first).single.uuid, item.uuid);
  });

  test('retry puts a rejected row back in line', () async {
    await engine.enqueueCommand(
      tenantId: 't1',
      entity: 'ai_captures',
      path: '/ai/suggestions/extract',
      data: <String, dynamic>{},
    );
    await engine.flush('t1');
    final QueueItem item = (await db.select(db.syncQueue).get()).single;
    await engine.retry(item.uuid);
    await engine.flush('t1');
    expect(adapter.calls, hasLength(2));
  });

  test('other entities keep the existing behaviour: a 422 is retried on the next flush', () async {
    await engine.enqueueCommand(
      tenantId: 't1',
      entity: 'expenses',
      path: '/expenses',
      data: <String, dynamic>{},
    );
    await engine.flush('t1');
    await engine.flush('t1');
    expect(adapter.calls, hasLength(2));
    expect(
      (await db.select(db.syncQueue).get()).single.state,
      QueueState.failed,
    );
  });

  test('watchQueue is scoped to the tenant and entity', () async {
    await engine.enqueueCommand(
      tenantId: 't1',
      entity: 'ai_captures',
      path: '/p',
      data: <String, dynamic>{},
    );
    await engine.enqueueCommand(
      tenantId: 't1',
      entity: 'expenses',
      path: '/e',
      data: <String, dynamic>{},
    );
    await engine.enqueueCommand(
      tenantId: 't2',
      entity: 'ai_captures',
      path: '/p',
      data: <String, dynamic>{},
    );
    expect(await engine.queued('t1', 'ai_captures'), hasLength(1));
  });
}
