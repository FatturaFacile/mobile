import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:fattura_facile/core/database/app_database.dart';
import 'package:fattura_facile/core/sync/sync_engine.dart';
import 'package:fattura_facile/features/ai_cognitive/data/ai_repository_impl.dart';
import 'package:fattura_facile/features/ai_cognitive/domain/ai_models.dart';
import 'package:fattura_facile/features/ai_cognitive/domain/ai_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/sync_engine_test.dart' show FakeAdapter, json;

Map<String, dynamic> suggestionJson(
  String id, {
  String kind = 'sales_quote',
  double confidence = 0.9,
  String priority = 'normal',
  String createdAt = '2026-11-20T10:00:00Z',
}) => <String, dynamic>{
  'id': id,
  'kind': kind,
  'status': 'pending',
  'priority': priority,
  'confidence': confidence,
  'proposed_payload': <String, dynamic>{'a': 1},
  'created_at': createdAt,
};

Map<String, dynamic> envelope(Object data, {Map<String, dynamic>? meta}) =>
    <String, dynamic>{
      'success': true,
      'message': 'ok',
      'data': data,
      'meta': ?meta,
    };

Map<String, dynamic> problem(int status, String detail) => <String, dynamic>{
  'title': 'Problem',
  'detail': detail,
  'status': status,
};

void main() {
  late AppDatabase db;
  late FakeAdapter adapter;
  late AiCognitiveRepositoryImpl repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    adapter = FakeAdapter(
      (RequestOptions o) => json(201, envelope(suggestionJson('new'))),
    );
    final Dio dio = Dio(
      BaseOptions(
        baseUrl: 'http://x/api/v1',
        validateStatus: (int? s) => s != null && s < 300,
      ),
    )..httpClientAdapter = adapter;
    repo = AiCognitiveRepositoryImpl(db, dio, SyncEngine(db, dio));
  });

  tearDown(() => db.close());

  Future<CaptureOutcome> capture([
    String text = 'quote 2 chairs for Muster AG',
  ]) {
    return repo.capture(
      't1',
      kind: CaptureKind.salesQuote,
      text: text,
      locale: 'en',
    );
  }

  Map<String, dynamic> bodyOf(RequestOptions o) =>
      Map<String, dynamic>.from(o.data as Map);

  group('capture', () {
    test(
      'online: sends the extract request and leaves nothing queued',
      () async {
        final CaptureOutcome out = await capture();
        expect(out.status, CaptureStatus.sent);
        final RequestOptions call = adapter.calls.single;
        expect(call.method, 'POST');
        expect(call.path, '/ai/suggestions/extract');
        final Map<String, dynamic> body = bodyOf(call);
        expect(body['kind'], 'sales_quote');
        expect(body['source_type'], 'document');
        expect(body['text'], 'quote 2 chairs for Muster AG');
        expect(body['locale'], 'en');
        expect(body['source_reference'], startsWith('mobile-'));
        expect(call.headers['Idempotency-Key'], isNotNull);
        expect((await repo.captureQueue('t1')).waiting, 0);
      },
    );

    test('text shorter than 10 characters is not sent nor queued', () async {
      final CaptureOutcome out = await capture('too short');
      expect(out.status, CaptureStatus.tooShort);
      expect(adapter.calls, isEmpty);
      expect(await db.select(db.syncQueue).get(), isEmpty);
    });

    test('offline: stays queued, and is sent with the same reference once the connection returns', () async {
      adapter.handler = (RequestOptions o) =>
          throw DioException.connectionError(requestOptions: o, reason: 'down');
      expect((await capture()).status, CaptureStatus.queued);
      expect((await repo.captureQueue('t1')).waiting, 1);
      final Map<String, dynamic> firstBody = bodyOf(adapter.calls.single);
      final Object? firstKey = adapter.calls.single.headers['Idempotency-Key'];

      adapter.handler = (RequestOptions o) =>
          json(201, envelope(suggestionJson('new')));
      final SyncEngine engine = SyncEngine(
        db,
        Dio(
          BaseOptions(
            baseUrl: 'http://x/api/v1',
            validateStatus: (int? s) => s != null && s < 300,
          ),
        )..httpClientAdapter = adapter,
      );
      final FlushReport report = await engine.flush('t1');
      expect(report.sent, 1);
      expect(adapter.calls, hasLength(2));
      expect(
        bodyOf(adapter.calls.last)['source_reference'],
        firstBody['source_reference'],
      );
      expect(adapter.calls.last.headers['Idempotency-Key'], firstKey);
      expect((await repo.captureQueue('t1')).waiting, 0);
    });

    test('503 keeps it queued and every retry reuses reference and idempotency key', () async {
      adapter.handler = (RequestOptions o) =>
          json(503, problem(503, 'AI provider unavailable'));
      expect((await capture()).status, CaptureStatus.queued);
      final QueueItem item = (await db.select(db.syncQueue).get()).single;
      expect(item.state, QueueState.failed);

      await repo.retryCapture('t1', item.uuid);
      final SyncEngine engine = SyncEngine(
        db,
        Dio(
          BaseOptions(
            baseUrl: 'http://x/api/v1',
            validateStatus: (int? s) => s != null && s < 300,
          ),
        )..httpClientAdapter = adapter,
      );
      await engine.flush('t1');
      expect(adapter.calls.length, greaterThanOrEqualTo(3));
      expect(
        adapter.calls
            .map((RequestOptions c) => bodyOf(c)['source_reference'])
            .toSet(),
        hasLength(1),
      );
      expect(
        adapter.calls
            .map((RequestOptions c) => c.headers['Idempotency-Key'])
            .toSet(),
        hasLength(1),
      );
      expect((await repo.captureQueue('t1')).waiting, 1);
    });

    test('429 is retried later, not parked', () async {
      adapter.handler = (RequestOptions o) => json(429, problem(429, 'quota'));
      expect((await capture()).status, CaptureStatus.queued);
      expect(
        (await db.select(db.syncQueue).get()).single.state,
        QueueState.failed,
      );
    });

    test(
      '422 surfaces the problem detail and is not resent on later flushes',
      () async {
        adapter.handler = (RequestOptions o) =>
            json(422, problem(422, 'The text is unreadable'));
        final CaptureOutcome out = await capture();
        expect(out.status, CaptureStatus.rejected);
        expect(out.detail, 'The text is unreadable');
        expect(adapter.calls, hasLength(1));

        final SyncEngine engine = SyncEngine(
          db,
          Dio(
            BaseOptions(
              baseUrl: 'http://x/api/v1',
              validateStatus: (int? s) => s != null && s < 300,
            ),
          )..httpClientAdapter = adapter,
        );
        await engine.flush('t1');
        await engine.flush('t1');
        expect(adapter.calls, hasLength(1));

        final CaptureQueue q = await repo.captureQueue('t1');
        expect(q.waiting, 0);
        expect(q.rejected.single.detail, 'The text is unreadable');
      },
    );

    test('403 is terminal as well', () async {
      adapter.handler = (RequestOptions o) =>
          json(403, problem(403, 'Not allowed'));
      expect((await capture()).status, CaptureStatus.rejected);
      expect((await repo.captureQueue('t1')).rejected, hasLength(1));
    });

    test('a rejected capture can be retried or dismissed', () async {
      adapter.handler = (RequestOptions o) => json(422, problem(422, 'bad'));
      await capture();
      final String uuid = (await repo.captureQueue('t1'))
          .rejected
          .single
          .queueUuid;

      adapter.handler = (RequestOptions o) =>
          json(201, envelope(suggestionJson('new')));
      await repo.retryCapture('t1', uuid);
      expect((await repo.captureQueue('t1')).rejected, isEmpty);
      expect(await db.select(db.syncQueue).get(), isEmpty);

      adapter.handler = (RequestOptions o) => json(422, problem(422, 'bad'));
      await capture();
      final String again = (await repo.captureQueue('t1'))
          .rejected
          .single
          .queueUuid;
      await repo.dismissCapture(again);
      expect(await db.select(db.syncQueue).get(), isEmpty);
    });

    test('captures are tenant scoped', () async {
      adapter.handler = (RequestOptions o) => json(503, problem(503, 'down'));
      await capture();
      expect((await repo.captureQueue('t2')).waiting, 0);
      expect((await repo.captureQueue('t1')).waiting, 1);
    });

    test('two captures of the same text get distinct references', () async {
      await capture();
      await capture();
      final Set<Object?> refs = adapter.calls
          .map((RequestOptions c) => bodyOf(c)['source_reference'])
          .toSet();
      expect(refs, hasLength(2));
    });
  });

  group('refresh and cache', () {
    test(
      'parses data and meta and serves the cache offline, most urgent first',
      () async {
        adapter.handler = (RequestOptions o) {
          expect(o.path, '/ai/suggestions');
          return json(
            200,
            envelope(
              <Map<String, dynamic>>[
                suggestionJson('q1'),
                suggestionJson('an', kind: 'anomaly', priority: 'high'),
              ],
              meta: <String, dynamic>{
                'total': 2,
                'open_by_kind': <String, dynamic>{
                  'sales_quote': 1,
                  'anomaly': 1,
                },
              },
            ),
          );
        };
        final SuggestionsPage page = await repo.refresh('t1');
        expect(page.items, hasLength(2));
        expect(page.total, 2);
        expect(page.openByKind, <String, int>{'sales_quote': 1, 'anomaly': 1});

        final List<Suggestion> cached = await repo.cached('t1');
        expect(cached.map((Suggestion s) => s.id), <String>['an', 'q1']);
        expect(await repo.cached('t2'), isEmpty);
      },
    );

    test('a failed refresh keeps the previous cache', () async {
      adapter.handler = (RequestOptions o) =>
          json(200, envelope(<Map<String, dynamic>>[suggestionJson('q1')]));
      await repo.refresh('t1');
      adapter.handler = (RequestOptions o) =>
          throw DioException.connectionError(requestOptions: o, reason: 'down');
      await expectLater(
        repo.refresh('t1'),
        throwsA(
          isA<AiException>().having(
            (AiException e) => e.kind,
            'kind',
            AiErrorKind.offline,
          ),
        ),
      );
      expect((await repo.cached('t1')).single.id, 'q1');
    });

    test('403 maps to forbidden', () async {
      adapter.handler = (RequestOptions o) =>
          json(403, problem(403, 'no module'));
      await expectLater(
        repo.refresh('t1'),
        throwsA(
          isA<AiException>().having(
            (AiException e) => e.kind,
            'kind',
            AiErrorKind.forbidden,
          ),
        ),
      );
    });
  });

  group('decisions', () {
    Future<void> seed() async {
      adapter.handler = (RequestOptions o) =>
          json(200, envelope(<Map<String, dynamic>>[suggestionJson('q1')]));
      await repo.refresh('t1');
    }

    test(
      'approve posts the payload and drops the row from the cache',
      () async {
        await seed();
        adapter.handler = (RequestOptions o) =>
            json(200, envelope(suggestionJson('q1')..['status'] = 'approved'));
        final Suggestion s = await repo.approve(
          't1',
          'q1',
          editedPayload: <String, dynamic>{'a': 2},
          feedback: 'ok',
        );
        expect(s.status, 'approved');
        final RequestOptions call = adapter.calls.last;
        expect(call.path, '/ai/suggestions/q1/approve');
        expect(bodyOf(call), <String, dynamic>{
          'edited_payload': <String, dynamic>{'a': 2},
          'feedback': 'ok',
        });
        expect(await repo.cached('t1'), isEmpty);
      },
    );

    test('reject posts the trimmed reason', () async {
      await seed();
      adapter.handler = (RequestOptions o) =>
          json(200, envelope(suggestionJson('q1')..['status'] = 'rejected'));
      await repo.reject('t1', 'q1', reason: '  wrong customer ');
      final RequestOptions call = adapter.calls.last;
      expect(call.path, '/ai/suggestions/q1/reject');
      expect(bodyOf(call), <String, dynamic>{'reason': 'wrong customer'});
    });

    test('409 reports alreadyDecided and drops the stale row', () async {
      await seed();
      adapter.handler = (RequestOptions o) =>
          json(409, problem(409, 'already decided'));
      await expectLater(
        repo.approve('t1', 'q1'),
        throwsA(
          isA<AiException>().having(
            (AiException e) => e.kind,
            'kind',
            AiErrorKind.alreadyDecided,
          ),
        ),
      );
      expect(await repo.cached('t1'), isEmpty);
    });

    test('422 keeps the row and exposes the problem detail', () async {
      await seed();
      adapter.handler = (RequestOptions o) =>
          json(422, problem(422, 'customer is missing'));
      await expectLater(
        repo.approve('t1', 'q1'),
        throwsA(
          isA<AiException>()
              .having((AiException e) => e.kind, 'kind', AiErrorKind.invalid)
              .having(
                (AiException e) => e.detail,
                'detail',
                'customer is missing',
              ),
        ),
      );
      expect(await repo.cached('t1'), hasLength(1));
    });

    test('404 maps to notFound', () async {
      adapter.handler = (RequestOptions o) => json(404, problem(404, 'nope'));
      await expectLater(
        repo.reject('t1', 'zz', reason: 'because'),
        throwsA(
          isA<AiException>().having(
            (AiException e) => e.kind,
            'kind',
            AiErrorKind.notFound,
          ),
        ),
      );
    });
  });

  test('queue payload is valid JSON for the extract contract', () async {
    adapter.handler = (RequestOptions o) => json(503, problem(503, 'down'));
    await capture();
    final QueueItem item = (await db.select(db.syncQueue).get()).single;
    expect(item.path, '/ai/suggestions/extract');
    expect(item.entity, aiCaptureEntity);
    final Map<String, dynamic> body =
        jsonDecode(item.payload!) as Map<String, dynamic>;
    expect(
      body.keys,
      containsAll(<String>['kind', 'source_type', 'text', 'source_reference']),
    );
  });
}
