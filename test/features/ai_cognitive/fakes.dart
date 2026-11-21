import 'package:fattura_facile/features/ai_cognitive/domain/ai_models.dart';
import 'package:fattura_facile/features/ai_cognitive/domain/ai_repository.dart';

Suggestion fakeSuggestion(
  String id, {
  String kind = 'sales_quote',
  double confidence = 0.95,
  String priority = 'normal',
  String? reasoning,
  DateTime? createdAt,
}) => Suggestion(
  id: id,
  kind: kind,
  status: 'pending',
  priority: priority,
  confidence: confidence,
  reasoning: reasoning,
  createdAt: createdAt,
);

/// In-memory repository; set the `*Error` / `*Outcome` fields to script failures.
class FakeAiRepository implements AiCognitiveRepository {
  List<Suggestion> remote = <Suggestion>[];
  List<Suggestion> cache = <Suggestion>[];
  AiException? refreshError;
  AiException? decisionError;
  CaptureOutcome captureOutcome = const CaptureOutcome(CaptureStatus.sent);
  CaptureQueue queue = const CaptureQueue();
  int refreshCount = 0;
  final List<String> approved = <String>[];
  final List<({String id, String reason})> rejected =
      <({String id, String reason})>[];
  final List<({CaptureKind kind, String text})> captures =
      <({CaptureKind kind, String text})>[];

  @override
  Future<List<Suggestion>> cached(String tenantId) async => cache;

  @override
  Future<SuggestionsPage> refresh(String tenantId) async {
    refreshCount++;
    final AiException? e = refreshError;
    if (e != null) {
      throw e;
    }
    cache = remote;
    return SuggestionsPage(remote, total: remote.length);
  }

  @override
  Future<CaptureOutcome> capture(
    String tenantId, {
    required CaptureKind kind,
    required String text,
    required String locale,
  }) async {
    if (text.trim().length < 10) {
      return const CaptureOutcome(CaptureStatus.tooShort);
    }
    captures.add((kind: kind, text: text));
    return captureOutcome;
  }

  @override
  Future<CaptureQueue> captureQueue(String tenantId) async => queue;

  @override
  Future<void> retryCapture(String tenantId, String queueUuid) async {}

  @override
  Future<void> dismissCapture(String queueUuid) async {
    queue = const CaptureQueue();
  }

  @override
  Future<Suggestion> approve(
    String tenantId,
    String id, {
    Map<String, dynamic>? editedPayload,
    String? feedback,
  }) async {
    final AiException? e = decisionError;
    if (e != null) {
      throw e;
    }
    approved.add(id);
    return fakeSuggestion(id);
  }

  @override
  Future<Suggestion> reject(
    String tenantId,
    String id, {
    required String reason,
  }) async {
    final AiException? e = decisionError;
    if (e != null) {
      throw e;
    }
    rejected.add((id: id, reason: reason));
    return fakeSuggestion(id);
  }
}
