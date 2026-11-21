import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_engine.dart';
import '../domain/ai_models.dart';
import '../domain/ai_repository.dart';

/// Offline-queue entity of the text captures. Listed in [SyncEngine.defaultTerminalEntities].
const String aiCaptureEntity = 'ai_captures';

/// Local store entity of the cached open suggestions.
const String aiSuggestionEntity = 'ai_suggestions';

/// Backend minimum for `text` of the extract endpoint.
const int aiCaptureMinChars = 10;
const int aiCaptureMaxChars = 20000;

const String _extractPath = '/ai/suggestions/extract';

/// Maps a transport error to an [AiException]; RFC 7807 `detail` is kept for the UI.
AiException mapAiError(DioException e) {
  final Response<dynamic>? r = e.response;
  if (r == null) {
    return const AiException(AiErrorKind.offline);
  }
  final dynamic body = r.data;
  String detail = '';
  if (body is Map) {
    final dynamic d = body['detail'] ?? body['message'] ?? body['title'];
    detail = d is String ? d : '';
  }
  return switch (r.statusCode) {
    403 => AiException(AiErrorKind.forbidden, detail),
    404 => AiException(AiErrorKind.notFound, detail),
    409 => AiException(AiErrorKind.alreadyDecided, detail),
    422 => AiException(AiErrorKind.invalid, detail),
    429 => AiException(AiErrorKind.rateLimited, detail),
    502 || 503 || 504 => AiException(AiErrorKind.unavailable, detail),
    _ => AiException(AiErrorKind.unknown, detail),
  };
}

class AiCognitiveRepositoryImpl implements AiCognitiveRepository {
  AiCognitiveRepositoryImpl(this._db, this._dio, this._engine, {Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final Dio _dio;
  final SyncEngine _engine;
  final Uuid _uuid;

  @override
  Future<List<Suggestion>> cached(String tenantId) async {
    final List<EntityRecord> rows =
        await (_db.select(_db.entityRecords)..where(
              (EntityRecords t) =>
                  t.tenantId.equals(tenantId) &
                  t.entity.equals(aiSuggestionEntity),
            ))
            .get();
    final List<Suggestion> items = <Suggestion>[
      for (final EntityRecord r in rows)
        Suggestion.fromJson(jsonDecode(r.payload) as Map<String, dynamic>),
    ];
    items.sort(_mostUrgentFirst);
    return items;
  }

  @override
  Future<SuggestionsPage> refresh(String tenantId) async {
    final Response<dynamic> res = await _guard(
      () => _dio.get<dynamic>(
        '/ai/suggestions',
        queryParameters: <String, dynamic>{'per_page': 50},
      ),
    );
    final Map<String, dynamic> body = _map(res.data);
    final List<Suggestion> items = <Suggestion>[
      for (final dynamic raw in (body['data'] as List<dynamic>? ?? <dynamic>[]))
        Suggestion.fromJson(Map<String, dynamic>.from(raw as Map)),
    ];
    final Map<String, dynamic> meta = _map(body['meta']);
    final Map<String, dynamic> byKind = _map(meta['open_by_kind']);
    await _db.transaction(() async {
      await (_db.delete(_db.entityRecords)..where(
            (EntityRecords t) =>
                t.tenantId.equals(tenantId) &
                t.entity.equals(aiSuggestionEntity),
          ))
          .go();
      for (final Suggestion s in items) {
        await _store(tenantId, s);
      }
    });
    return SuggestionsPage(
      items,
      total: (meta['total'] as num?)?.toInt() ?? items.length,
      openByKind: <String, int>{
        for (final MapEntry<String, dynamic> e in byKind.entries)
          if (e.value is num) e.key: (e.value as num).toInt(),
      },
    );
  }

  @override
  Future<CaptureOutcome> capture(
    String tenantId, {
    required CaptureKind kind,
    required String text,
    required String locale,
  }) async {
    final String trimmed = text.trim();
    if (trimmed.length < aiCaptureMinChars) {
      return const CaptureOutcome(CaptureStatus.tooShort);
    }
    final String body = trimmed.length > aiCaptureMaxChars
        ? trimmed.substring(0, aiCaptureMaxChars)
        : trimmed;
    // The reference is generated once and stored inside the queued body, so every resend of this capture
    // carries the same value and the backend never creates a duplicate suggestion.
    final String entityId = await _engine.enqueueCommand(
      tenantId: tenantId,
      entity: aiCaptureEntity,
      path: _extractPath,
      data: <String, dynamic>{
        'kind': kind.wire,
        'source_type': kind.sourceType,
        'text': body,
        'source_reference': 'mobile-${_uuid.v7()}',
        if (const <String>{'it', 'en', 'de', 'fr'}.contains(locale))
          'locale': locale,
      },
    );
    return _deliver(tenantId, entityId);
  }

  /// Flushes the outbox and reports what happened to the capture identified by [entityId].
  Future<CaptureOutcome> _deliver(String tenantId, String entityId) async {
    try {
      await _engine.flush(tenantId);
    } catch (_) {
      // Whatever went wrong, the capture is safely queued and the next sync cycle resends it.
    }
    final QueueItem? item = await _find(tenantId, entityId);
    if (item == null) {
      return const CaptureOutcome(CaptureStatus.sent);
    }
    if (item.state == QueueState.rejected) {
      return CaptureOutcome(
        CaptureStatus.rejected,
        detail: item.lastError ?? '',
      );
    }
    return const CaptureOutcome(CaptureStatus.queued);
  }

  Future<QueueItem?> _find(String tenantId, String entityId) async {
    final List<QueueItem> rows = await _engine.queued(
      tenantId,
      aiCaptureEntity,
    );
    for (final QueueItem r in rows) {
      if (r.entityId == entityId) {
        return r;
      }
    }
    return null;
  }

  @override
  Future<CaptureQueue> captureQueue(String tenantId) async {
    final List<QueueItem> rows = await _engine.queued(
      tenantId,
      aiCaptureEntity,
    );
    return CaptureQueue(
      waiting: rows
          .where((QueueItem r) => r.state != QueueState.rejected)
          .length,
      rejected: <RejectedCapture>[
        for (final QueueItem r in rows)
          if (r.state == QueueState.rejected)
            RejectedCapture(queueUuid: r.uuid, detail: r.lastError ?? ''),
      ],
    );
  }

  @override
  Future<void> retryCapture(String tenantId, String queueUuid) async {
    await _engine.retry(queueUuid);
    await _engine.flush(tenantId);
  }

  @override
  Future<void> dismissCapture(String queueUuid) => _engine.discard(queueUuid);

  @override
  Future<Suggestion> approve(
    String tenantId,
    String id, {
    Map<String, dynamic>? editedPayload,
    String? feedback,
  }) {
    return _decide(tenantId, id, 'approve', <String, dynamic>{
      'edited_payload': editedPayload,
      'feedback': feedback,
    });
  }

  @override
  Future<Suggestion> reject(
    String tenantId,
    String id, {
    required String reason,
  }) {
    return _decide(tenantId, id, 'reject', <String, dynamic>{
      'reason': reason.trim(),
    });
  }

  /// Decisions need the server's verdict (409/422), so they are online-only. A 409 means somebody else
  /// already decided: the stale local row is dropped so the list stops offering it.
  Future<Suggestion> _decide(
    String tenantId,
    String id,
    String action,
    Map<String, dynamic> body,
  ) async {
    try {
      final Response<dynamic> res = await _guard(
        () => _dio.post<dynamic>('/ai/suggestions/$id/$action', data: body),
      );
      await _forget(tenantId, id);
      return Suggestion.fromJson(_map(_map(res.data)['data']));
    } on AiException catch (e) {
      if (e.kind == AiErrorKind.alreadyDecided ||
          e.kind == AiErrorKind.notFound) {
        await _forget(tenantId, id);
      }
      rethrow;
    }
  }

  Future<void> _forget(String tenantId, String id) async {
    await (_db.delete(_db.entityRecords)..where(
          (EntityRecords t) =>
              t.tenantId.equals(tenantId) &
              t.entity.equals(aiSuggestionEntity) &
              t.id.equals(id),
        ))
        .go();
  }

  Future<void> _store(String tenantId, Suggestion s) async {
    final DateTime now = DateTime.now().toUtc();
    await _db
        .into(_db.entityRecords)
        .insertOnConflictUpdate(
          EntityRecordsCompanion.insert(
            entity: aiSuggestionEntity,
            id: s.id,
            tenantId: tenantId,
            payload: jsonEncode(s.toJson()),
            syncStatus: SyncStatus.synced,
            localUpdatedAt: now,
            createdAt: s.createdAt ?? now,
            updatedAt: now,
          ),
        );
  }

  Future<Response<dynamic>> _guard(
    Future<Response<dynamic>> Function() call,
  ) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw mapAiError(e);
    }
  }

  static Map<String, dynamic> _map(Object? v) =>
      v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

  static int _mostUrgentFirst(Suggestion a, Suggestion b) {
    int rank(String p) => switch (p) {
      'high' => 0,
      'normal' => 1,
      _ => 2,
    };
    final int byPriority = rank(a.priority).compareTo(rank(b.priority));
    if (byPriority != 0) {
      return byPriority;
    }
    return (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(
      a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
