import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:fattura_facile/core/database/app_database.dart';
import 'package:fattura_facile/core/sync/sync_engine.dart';
import 'package:flutter_test/flutter_test.dart';

typedef Handler = ResponseBody Function(RequestOptions o);

class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.handler);

  Handler handler;
  final List<RequestOptions> calls = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    calls.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody json(int status, Object body) => ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );

void main() {
  late AppDatabase db;
  late FakeAdapter adapter;
  late SyncEngine engine;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    adapter = FakeAdapter((RequestOptions o) => json(200, <String, dynamic>{'data': <String, dynamic>{'id': 'srv'}}));
    final Dio dio = Dio(BaseOptions(baseUrl: 'http://x/api/v1', validateStatus: (int? s) => s != null && s < 300))..httpClientAdapter = adapter;
    engine = SyncEngine(db, dio);
  });

  tearDown(() => db.close());

  test('offline create is stored locally, queued and flushed with an idempotency key', () async {
    final String id = await engine.create(tenantId: 't1', entity: 'expenses', path: '/expenses', data: <String, dynamic>{'amount': 10});
    final List<EntityRecord> rows = await engine.watch('t1', 'expenses').first;
    expect(rows.single.id, id);
    expect(rows.single.syncStatus, SyncStatus.pendingCreate);

    final FlushReport report = await engine.flush('t1');
    expect(report.sent, 1);
    expect(adapter.calls.single.headers['Idempotency-Key'], isNotNull);
    final EntityRecord synced = (await engine.watch('t1', 'expenses').first).single;
    expect(synced.syncStatus, SyncStatus.synced);
    expect(synced.serverId, 'srv');
  });

  test('network failure keeps the queue and reports offline', () async {
    await engine.create(tenantId: 't1', entity: 'expenses', path: '/expenses', data: <String, dynamic>{});
    adapter.handler = (RequestOptions o) => throw DioException.connectionError(requestOptions: o, reason: 'down');
    final FlushReport report = await engine.flush('t1');
    expect(report.offline, isTrue);
    expect(await db.select(db.syncQueue).get(), hasLength(1));
  });

  test('child waits for its parent and is sent after it, in FIFO order', () async {
    await engine.create(tenantId: 't1', entity: 'work_orders', path: '/work-orders', data: <String, dynamic>{});
    final QueueItem parent = (await db.select(db.syncQueue).get()).single;
    await engine.create(tenantId: 't1', entity: 'work_order_lines', path: '/work-order-lines', data: <String, dynamic>{}, dependsOn: parent.uuid);

    adapter.handler = (RequestOptions o) => o.path == '/work-orders' ? json(422, <String, dynamic>{'message': 'bad'}) : json(200, <String, dynamic>{});
    final FlushReport blocked = await engine.flush('t1');
    expect(blocked.failed, 1);
    expect(adapter.calls.map((RequestOptions c) => c.path), <String>['/work-orders']);

    adapter.handler = (RequestOptions o) => json(200, <String, dynamic>{'data': <String, dynamic>{'id': 'x'}});
    final FlushReport ok = await engine.flush('t1');
    expect(ok.sent, 2);
    expect(adapter.calls.skip(1).map((RequestOptions c) => c.path), <String>['/work-orders', '/work-order-lines']);
  });

  test('409 marks the record as conflict', () async {
    final String id = await engine.create(tenantId: 't1', entity: 'expenses', path: '/expenses', data: <String, dynamic>{});
    adapter.handler = (RequestOptions o) => json(409, <String, dynamic>{'message': 'changed'});
    final FlushReport report = await engine.flush('t1');
    expect(report.conflicts, 1);
    final EntityRecord row = (await engine.watch('t1', 'expenses').first).single;
    expect(row.id, id);
    expect(row.syncStatus, SyncStatus.conflict);
  });

  test('deleting an unsent create removes it without any request', () async {
    final String id = await engine.create(tenantId: 't1', entity: 'expenses', path: '/expenses', data: <String, dynamic>{});
    await engine.delete(tenantId: 't1', entity: 'expenses', id: id, path: '/expenses');
    expect(await db.select(db.syncQueue).get(), isEmpty);
    expect(await engine.watch('t1', 'expenses').first, isEmpty);
  });

  test('tenants are isolated', () async {
    await engine.create(tenantId: 't1', entity: 'expenses', path: '/expenses', data: <String, dynamic>{});
    expect(await engine.watch('t2', 'expenses').first, isEmpty);
    expect((await engine.flush('t2')).sent, 0);
  });

  test('delta pull stores records, keeps unsent local edits as conflicts and saves the watermark', () async {
    final String id = await engine.create(tenantId: 't1', entity: 'expenses', path: '/expenses', data: <String, dynamic>{});
    adapter.handler = (RequestOptions o) => json(200, <String, dynamic>{
          'data': <String, dynamic>{
            'data': <Map<String, dynamic>>[
              <String, dynamic>{'id': 'a', 'updated_at': '2026-01-01T00:00:00Z'},
              <String, dynamic>{'id': id, 'updated_at': '2026-01-01T00:00:00Z'},
            ],
            'deleted': <String>[],
            'has_more': false,
            'next_cursor': null,
            'server_time': '2026-01-02T00:00:00Z',
          },
        });
    expect(await engine.pull('t1', 'expenses'), 1);
    final List<EntityRecord> rows = await engine.watch('t1', 'expenses').first;
    expect(rows.firstWhere((EntityRecord r) => r.id == id).syncStatus, SyncStatus.conflict);
    final SyncCursor cursor = await db.select(db.syncCursors).getSingle();
    expect(cursor.serverTime, '2026-01-02T00:00:00Z');
  });
}
