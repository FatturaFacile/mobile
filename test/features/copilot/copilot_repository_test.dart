import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:fattura_facile/core/database/app_database.dart';
import 'package:fattura_facile/core/network/api_client.dart';
import 'package:fattura_facile/features/copilot/data/copilot_repository_impl.dart';
import 'package:fattura_facile/features/copilot/domain/copilot_models.dart';
import 'package:fattura_facile/features/copilot/domain/copilot_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/sync_engine_test.dart' show FakeAdapter, json;

Map<String, dynamic> message(
  String id, {
  String role = 'assistant',
  String text = 'hi',
  Map<String, dynamic>? extra,
}) => <String, dynamic>{
  'id': id,
  'conversation_id': 'c1',
  'role': role,
  'content_markdown': text,
  'citations': <dynamic>[],
  'action_status': null,
  'created_at': '2026-11-20T10:00:00Z',
  ...?extra,
};

ResponseBody sse(String body) => ResponseBody.fromString(
  body,
  200,
  headers: <String, List<String>>{
    Headers.contentTypeHeader: <String>['text/event-stream'],
  },
);

void main() {
  late AppDatabase db;
  late FakeAdapter adapter;
  late CopilotRepositoryImpl repo;
  late RequestContext ctx;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    ctx = RequestContext()..tenantId = 't1';
    adapter = FakeAdapter(
      (RequestOptions o) =>
          json(200, <String, dynamic>{'data': <String, dynamic>{}}),
    );
    final Dio dio = Dio(BaseOptions(baseUrl: 'http://x/api/v1'))
      ..httpClientAdapter = adapter
      ..interceptors.add(ContextInterceptor(ctx));
    repo = CopilotRepositoryImpl(db, dio);
  });

  tearDown(() => db.close());

  test(
    'SSE parser decodes every event type and ignores unknown ones',
    () async {
      final String body =
          'event: message.started\ndata: {}\n\n'
          'event: tool.call\ndata: {"name":"invoices.search"}\n\n'
          'event: visualization\ndata: {"type":"kpi_card","metric":"Open","value":5}\n\n'
          'event: action.proposed\ndata: {"tool":"t","module":"m","summary":"s","editable_fields":["a"]}\n\n'
          'event: token\ndata: {"text":"Ciao"}\n\n'
          'event: whatever\ndata: {}\n\n'
          'event: message.completed\ndata: {"message_id":"m1","conversation_id":"c1"}\n\n'
          'event: error\ndata: {"message":"boom"}\n\n';
      final List<CopilotEvent> events = await parseCopilotSse(
        Stream<List<int>>.value(utf8.encode(body)),
      ).toList();
      expect(
        events.map((CopilotEvent e) => e.runtimeType.toString()).toList(),
        <String>[
          'MessageStarted',
          'ToolCalled',
          'VisualizationEvent',
          'ActionProposedEvent',
          'TokenEvent',
          'MessageCompleted',
          'StreamError',
        ],
      );
      expect((events[4] as TokenEvent).text, 'Ciao');
      expect((events[2] as VisualizationEvent).visualization.type, 'kpi_card');
    },
  );

  test('sendMessage streams with SSE accept header, context and locale, then caches the server copy', () async {
    adapter.handler = (RequestOptions o) {
      if (o.method == 'POST') {
        return sse(
          'event: token\ndata: {"text":"Hello"}\n\nevent: message.completed\ndata: {"message_id":"m2","conversation_id":"c1"}\n\n',
        );
      }
      return json(200, <String, dynamic>{
        'data': <String, dynamic>{
          'id': 'c1',
          'title': 'T',
          'created_at': '2026-11-20T10:00:00Z',
          'messages': <dynamic>[
            message('m1', role: 'user', text: 'q'),
            message('m2', text: 'Hello'),
          ],
        },
      });
    };
    final List<CopilotEvent> events = await repo
        .sendMessage(
          't1',
          'c1',
          prompt: 'q',
          locale: 'it',
          context: const CopilotContext(
            route: '/contacts',
            entityType: 'contacts',
            entityId: '7',
          ),
        )
        .toList();
    expect(events.whereType<TokenEvent>().single.text, 'Hello');
    final RequestOptions post = adapter.calls.firstWhere(
      (RequestOptions o) => o.method == 'POST',
    );
    expect(post.headers['Accept'], 'text/event-stream');
    expect(post.headers['X-Tenant-Id'], 't1');
    expect(post.data, <String, dynamic>{
      'prompt': 'q',
      'locale': 'it',
      'context': <String, dynamic>{
        'route': '/contacts',
        'entity_type': 'contacts',
        'entity_id': '7',
      },
    });
    final List<CopilotMessage> cached = await repo.cachedMessages('t1', 'c1');
    expect(cached.map((CopilotMessage m) => m.id), <String>['m1', 'm2']);
    expect((await repo.cachedConversations('t1')).single.title, 'T');
  });

  test(
    'falls back to the JSON assistant message when the server does not stream',
    () async {
      adapter.handler = (RequestOptions o) =>
          json(200, <String, dynamic>{'data': message('m9', text: 'plain')});
      final List<CopilotEvent> events = await repo
          .sendMessage('t1', 'c1', prompt: 'q', locale: 'en')
          .toList();
      expect(events.whereType<TokenEvent>().single.text, 'plain');
      expect(events.last, isA<MessageCompleted>());
      expect((await repo.cachedMessages('t1', 'c1')).single.id, 'm9');
    },
  );

  test('cache is tenant scoped and readable offline', () async {
    adapter.handler = (RequestOptions o) => json(200, <String, dynamic>{
      'data': <String, dynamic>{
        'id': 'c1',
        'created_at': '2026-11-20T10:00:00Z',
        'messages': <dynamic>[message('m1')],
      },
    });
    await repo.syncMessages('t1', 'c1');
    adapter.handler = (RequestOptions o) =>
        throw DioException.connectionError(requestOptions: o, reason: 'down');
    expect((await repo.cachedMessages('t1', 'c1')), hasLength(1));
    expect(await repo.cachedMessages('t2', 'c1'), isEmpty);
    await expectLater(
      repo.syncMessages('t1', 'c1'),
      throwsA(
        isA<CopilotException>().having(
          (CopilotException e) => e.kind,
          'kind',
          CopilotErrorKind.offline,
        ),
      ),
    );
  });

  test('HTTP errors map to typed kinds', () async {
    final Map<int, CopilotErrorKind> expected = <int, CopilotErrorKind>{
      403: CopilotErrorKind.forbidden,
      404: CopilotErrorKind.notFound,
      409: CopilotErrorKind.conflict,
      422: CopilotErrorKind.invalid,
      429: CopilotErrorKind.rateLimited,
      502: CopilotErrorKind.provider,
    };
    for (final MapEntry<int, CopilotErrorKind> e in expected.entries) {
      adapter.handler = (RequestOptions o) =>
          json(e.key, <String, dynamic>{'message': 'x'});
      await expectLater(
        repo.confirmAction('t1', 'm1'),
        throwsA(
          isA<CopilotException>().having(
            (CopilotException x) => x.kind,
            'kind',
            e.value,
          ),
        ),
        reason: '${e.key}',
      );
    }
  });

  test('confirm sends dotted overrides and rejects with a reason', () async {
    adapter.handler = (RequestOptions o) => json(200, <String, dynamic>{
      'data': message(
        'm1',
        extra: <String, dynamic>{
          'action_status': 'executed',
          'proposed_action': <String, dynamic>{
            'tool': 't',
            'module': 'm',
            'summary': 's',
            'editable_fields': <String>[],
          },
        },
      ),
    });
    final CopilotMessage done = await repo.confirmAction(
      't1',
      'm1',
      overrides: <String, Object?>{'items.0.quantity': 3},
    );
    expect(done.actionStatus, ActionStatus.executed);
    expect(adapter.calls.last.path, '/copilot/actions/m1/confirm');
    expect(adapter.calls.last.data, <String, dynamic>{
      'overrides': <String, Object?>{'items.0.quantity': 3},
    });
    await repo.rejectAction('t1', 'm1', reason: 'no');
    expect(adapter.calls.last.path, '/copilot/actions/m1/reject');
    expect(adapter.calls.last.data, <String, dynamic>{'reason': 'no'});
  });

  test('visualization and citation parsing', () {
    final CopilotMessage m = CopilotMessage.fromJson(
      message(
        'm1',
        extra: <String, dynamic>{
          'citations': <dynamic>[
            <String, dynamic>{
              'type': 'entity',
              'label': 'Rossi',
              'entity_type': 'contacts',
              'entity_id': 7,
              'route': '/contacts/7',
            },
            <String, dynamic>{
              'type': 'regulatory',
              'label': 'CO 957',
              'jurisdiction': 'CH',
            },
          ],
          'visualization': <String, dynamic>{
            'type': 'table',
            'columns': <dynamic>[
              <String, dynamic>{'key': 'a', 'label': 'A'},
              'b',
            ],
            'rows': <dynamic>[
              <String, dynamic>{'a': 1, 'b': 2},
              <dynamic>[3, 4],
            ],
          },
        },
      ),
    );
    expect(m.citations.first.isEntity, isTrue);
    expect(m.citations.first.entityId, '7');
    expect(m.visualization!.columns, <String>['A', 'b']);
    expect(m.visualization!.rows, <List<Object?>>[
      <Object?>[1, 2],
      <Object?>[3, 4],
    ]);
  });
}
