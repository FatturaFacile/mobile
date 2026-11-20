import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/copilot_models.dart';
import '../domain/copilot_repository.dart';

/// Number of conversations kept in the offline cache per tenant.
const int copilotCachedConversations = 20;

/// Parses a `text/event-stream` byte stream into typed [CopilotEvent]s. Unknown events are ignored.
Stream<CopilotEvent> parseCopilotSse(Stream<List<int>> bytes) async* {
  String event = 'message';
  final StringBuffer data = StringBuffer();
  await for (final String line
      in bytes
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
    if (line.isEmpty) {
      final CopilotEvent? parsed = _decodeEvent(event, data.toString());
      event = 'message';
      data.clear();
      if (parsed != null) yield parsed;
    } else if (line.startsWith('event:')) {
      event = line.substring(6).trim();
    } else if (line.startsWith('data:')) {
      if (data.isNotEmpty) data.write('\n');
      data.write(line.substring(5).trimLeft());
    }
  }
  if (data.isNotEmpty) {
    final CopilotEvent? parsed = _decodeEvent(event, data.toString());
    if (parsed != null) yield parsed;
  }
}

CopilotEvent? _decodeEvent(String name, String raw) {
  Map<String, dynamic> body = <String, dynamic>{};
  if (raw.isNotEmpty) {
    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is Map) body = Map<String, dynamic>.from(decoded);
    } on FormatException {
      return null;
    }
  }
  switch (name) {
    case 'message.started':
      return const MessageStarted();
    case 'tool.call':
      return ToolCalled('${body['name'] ?? body['tool'] ?? ''}');
    case 'tool.result':
      return ToolResulted('${body['name'] ?? body['tool'] ?? ''}');
    case 'visualization':
      return VisualizationEvent(Visualization.fromJson(body));
    case 'action.proposed':
      return ActionProposedEvent(ProposedAction.fromJson(body));
    case 'token':
      return TokenEvent('${body['text'] ?? ''}');
    case 'message.completed':
      return MessageCompleted(
        messageId: '${body['message_id'] ?? ''}',
        conversationId: '${body['conversation_id'] ?? ''}',
      );
    case 'error':
      return StreamError('${body['message'] ?? ''}');
  }
  return null;
}

/// Maps an HTTP status to a [CopilotException].
CopilotException copilotFailure(DioException e) {
  final int? status = e.response?.statusCode;
  if (status == null)
    return CopilotException(CopilotErrorKind.offline, e.message ?? '');
  final CopilotErrorKind kind = switch (status) {
    403 => CopilotErrorKind.forbidden,
    404 => CopilotErrorKind.notFound,
    409 => CopilotErrorKind.conflict,
    422 => CopilotErrorKind.invalid,
    429 => CopilotErrorKind.rateLimited,
    502 => CopilotErrorKind.provider,
    _ => CopilotErrorKind.unknown,
  };
  return CopilotException(kind, '$status');
}

class CopilotRepositoryImpl implements CopilotRepository {
  CopilotRepositoryImpl(this._db, this._dio);

  final AppDatabase _db;
  final Dio _dio;

  static const String _base = '/copilot';

  dynamic _data(Response<dynamic> r) {
    final dynamic b = r.data;
    return b is Map && b.containsKey('data') ? b['data'] : b;
  }

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on DioException catch (e) {
      throw copilotFailure(e);
    }
  }

  @override
  Future<List<CopilotConversation>> cachedConversations(String tenantId) async {
    final List<CopilotConversation> rows =
        (await (_db.select(_db.copilotConversations)
                  ..where(
                    ($CopilotConversationsTable t) =>
                        t.tenantId.equals(tenantId),
                  )
                  ..orderBy(<OrderClauseGenerator<$CopilotConversationsTable>>[
                    ($CopilotConversationsTable t) =>
                        OrderingTerm.desc(t.updatedAt),
                  ])
                  ..limit(copilotCachedConversations))
                .get())
            .map(
              (CopilotConversationRow r) => CopilotConversation(
                id: r.id,
                title: r.title,
                createdAt: r.createdAt,
                updatedAt: r.updatedAt,
              ),
            )
            .toList();
    return rows;
  }

  @override
  Future<List<CopilotMessage>> cachedMessages(
    String tenantId,
    String conversationId,
  ) async {
    final List<CopilotMessageRow> rows =
        await (_db.select(_db.copilotMessages)
              ..where(
                ($CopilotMessagesTable t) =>
                    t.tenantId.equals(tenantId) &
                    t.conversationId.equals(conversationId),
              )
              ..orderBy(<OrderClauseGenerator<$CopilotMessagesTable>>[
                ($CopilotMessagesTable t) => OrderingTerm.asc(t.createdAt),
              ]))
            .get();
    return rows
        .map((CopilotMessageRow r) => CopilotMessage.fromPayload(r.payload))
        .toList();
  }

  Future<void> _storeConversations(
    String tenantId,
    List<CopilotConversation> list,
  ) async {
    await _db.batch((Batch b) {
      b.insertAllOnConflictUpdate(
        _db.copilotConversations,
        list.map(
          (CopilotConversation c) => CopilotConversationsCompanion.insert(
            tenantId: tenantId,
            id: c.id,
            title: Value<String?>(c.title),
            createdAt: c.createdAt,
            updatedAt: c.updatedAt,
          ),
        ),
      );
    });
    // Keep only the most recent conversations (and their messages).
    final List<CopilotConversation> all = await cachedConversationsUnbounded(
      tenantId,
    );
    for (final CopilotConversation old in all.skip(
      copilotCachedConversations,
    )) {
      await _dropConversation(tenantId, old.id);
    }
  }

  Future<List<CopilotConversation>> cachedConversationsUnbounded(
    String tenantId,
  ) async {
    final List<CopilotConversationRow> rows =
        await (_db.select(_db.copilotConversations)
              ..where(
                ($CopilotConversationsTable t) => t.tenantId.equals(tenantId),
              )
              ..orderBy(<OrderClauseGenerator<$CopilotConversationsTable>>[
                ($CopilotConversationsTable t) =>
                    OrderingTerm.desc(t.updatedAt),
              ]))
            .get();
    return rows
        .map(
          (CopilotConversationRow r) => CopilotConversation(
            id: r.id,
            title: r.title,
            createdAt: r.createdAt,
            updatedAt: r.updatedAt,
          ),
        )
        .toList();
  }

  Future<void> _dropConversation(String tenantId, String id) async {
    await (_db.delete(_db.copilotMessages)..where(
          ($CopilotMessagesTable t) =>
              t.tenantId.equals(tenantId) & t.conversationId.equals(id),
        ))
        .go();
    await (_db.delete(_db.copilotConversations)..where(
          ($CopilotConversationsTable t) =>
              t.tenantId.equals(tenantId) & t.id.equals(id),
        ))
        .go();
  }

  Future<void> _storeMessage(String tenantId, Map<String, dynamic> json) async {
    final CopilotMessage m = CopilotMessage.fromJson(json);
    await _db
        .into(_db.copilotMessages)
        .insertOnConflictUpdate(
          CopilotMessagesCompanion.insert(
            tenantId: tenantId,
            id: m.id,
            conversationId: m.conversationId,
            role: m.role.name,
            payload: jsonEncode(json),
            createdAt: m.createdAt,
          ),
        );
  }

  @override
  Future<List<CopilotConversation>> syncConversations(String tenantId) =>
      _guard(() async {
        final dynamic data = _data(
          await _dio.get<dynamic>('$_base/conversations'),
        );
        final List<dynamic> raw = data is Map && data['data'] is List
            ? data['data'] as List<dynamic>
            : (data is List ? data : const <dynamic>[]);
        final List<CopilotConversation> list = raw
            .whereType<Map<dynamic, dynamic>>()
            .map(
              (Map<dynamic, dynamic> m) =>
                  CopilotConversation.fromJson(Map<String, dynamic>.from(m)),
            )
            .toList();
        await _storeConversations(tenantId, list);
        return cachedConversations(tenantId);
      });

  @override
  Future<CopilotConversation> createConversation(String tenantId) =>
      _guard(() async {
        final dynamic data = _data(
          await _dio.post<dynamic>(
            '$_base/conversations',
            data: <String, dynamic>{},
          ),
        );
        final CopilotConversation c = CopilotConversation.fromJson(
          Map<String, dynamic>.from(data as Map),
        );
        await _storeConversations(tenantId, <CopilotConversation>[c]);
        return c;
      });

  @override
  Future<List<CopilotMessage>> syncMessages(
    String tenantId,
    String conversationId,
  ) => _guard(() async {
    final dynamic data = _data(
      await _dio.get<dynamic>('$_base/conversations/$conversationId'),
    );
    final Map<String, dynamic> map = Map<String, dynamic>.from(data as Map);
    await _storeConversations(tenantId, <CopilotConversation>[
      CopilotConversation.fromJson(map),
    ]);
    final List<dynamic> msgs = map['messages'] is List
        ? map['messages'] as List<dynamic>
        : const <dynamic>[];
    for (final Map<dynamic, dynamic> m
        in msgs.whereType<Map<dynamic, dynamic>>()) {
      final Map<String, dynamic> json = Map<String, dynamic>.from(m);
      json.putIfAbsent('conversation_id', () => conversationId);
      await _storeMessage(tenantId, json);
    }
    return cachedMessages(tenantId, conversationId);
  });

  @override
  Future<void> deleteConversation(String tenantId, String conversationId) =>
      _guard(() async {
        await _dio.delete<dynamic>('$_base/conversations/$conversationId');
        await _dropConversation(tenantId, conversationId);
      });

  @override
  Stream<CopilotEvent> sendMessage(
    String tenantId,
    String conversationId, {
    required String prompt,
    required String locale,
    CopilotContext? context,
  }) async* {
    final Map<String, dynamic> body = <String, dynamic>{
      'prompt': prompt,
      'locale': locale,
      if (context != null && !context.isEmpty) 'context': context.toJson(),
    };
    final String path = '$_base/conversations/$conversationId/messages';
    Response<ResponseBody> res;
    try {
      res = await _dio.post<ResponseBody>(
        path,
        data: body,
        options: Options(
          responseType: ResponseType.stream,
          headers: <String, dynamic>{'Accept': 'text/event-stream'},
        ),
      );
    } on DioException catch (e) {
      throw copilotFailure(e);
    }
    final String type = res.headers.value(Headers.contentTypeHeader) ?? '';
    if (type.contains('text/event-stream')) {
      bool completed = false;
      try {
        await for (final CopilotEvent ev in parseCopilotSse(res.data!.stream)) {
          if (ev is MessageCompleted) completed = true;
          yield ev;
        }
      } on DioException catch (e) {
        throw copilotFailure(e);
      }
      if (completed) {
        // Refresh the cache with the authoritative server copy; offline-safe.
        try {
          await syncMessages(tenantId, conversationId);
        } on CopilotException {
          // The streamed answer is still shown; the cache refreshes on the next sync.
        }
      }
      return;
    }
    // Streaming unavailable: the server answered with the plain JSON assistant message.
    final String raw = await utf8.decodeStream(
      res.data!.stream.cast<List<int>>(),
    );
    final dynamic decoded = jsonDecode(raw);
    final dynamic data = decoded is Map && decoded.containsKey('data')
        ? decoded['data']
        : decoded;
    final Map<String, dynamic> json = Map<String, dynamic>.from(data as Map);
    json.putIfAbsent('conversation_id', () => conversationId);
    await _storeMessage(tenantId, json);
    final CopilotMessage m = CopilotMessage.fromJson(json);
    yield const MessageStarted();
    if (m.visualization != null) yield VisualizationEvent(m.visualization!);
    if (m.proposedAction != null) yield ActionProposedEvent(m.proposedAction!);
    yield TokenEvent(m.content);
    yield MessageCompleted(messageId: m.id, conversationId: conversationId);
  }

  Future<CopilotMessage> _action(
    String tenantId,
    String messageId,
    String verb,
    Map<String, dynamic> body,
  ) => _guard(() async {
    final dynamic data = _data(
      await _dio.post<dynamic>('$_base/actions/$messageId/$verb', data: body),
    );
    final Map<String, dynamic> json = Map<String, dynamic>.from(data as Map);
    final CopilotMessage parsed = CopilotMessage.fromJson(json);
    if (parsed.conversationId.isNotEmpty) await _storeMessage(tenantId, json);
    return parsed;
  });

  @override
  Future<CopilotMessage> confirmAction(
    String tenantId,
    String messageId, {
    Map<String, Object?> overrides = const <String, Object?>{},
  }) => _action(tenantId, messageId, 'confirm', <String, dynamic>{
    if (overrides.isNotEmpty) 'overrides': overrides,
  });

  @override
  Future<CopilotMessage> rejectAction(
    String tenantId,
    String messageId, {
    String? reason,
  }) => _action(tenantId, messageId, 'reject', <String, dynamic>{
    if (reason != null && reason.isNotEmpty) 'reason': reason,
  });
}
