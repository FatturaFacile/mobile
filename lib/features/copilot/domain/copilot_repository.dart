import 'copilot_models.dart';

/// Why a Copilot call failed; mapped to a localized message by the UI.
enum CopilotErrorKind {
  forbidden,
  notFound,
  conflict,
  invalid,
  rateLimited,
  provider,
  offline,
  unknown,
}

class CopilotException implements Exception {
  const CopilotException(this.kind, [this.detail = '']);

  final CopilotErrorKind kind;
  final String detail;

  @override
  String toString() => 'CopilotException($kind, $detail)';
}

/// Backend gateway plus offline cache for the ERP Copilot. Failures throw [CopilotException].
abstract interface class CopilotRepository {
  /// Cached conversations (newest first) for offline reading.
  Future<List<CopilotConversation>> cachedConversations(String tenantId);

  /// Cached messages of one conversation, oldest first.
  Future<List<CopilotMessage>> cachedMessages(
    String tenantId,
    String conversationId,
  );

  /// Refreshes the conversation list from the API and updates the cache.
  Future<List<CopilotConversation>> syncConversations(String tenantId);

  Future<CopilotConversation> createConversation(String tenantId);

  /// Loads a conversation with its messages from the API and updates the cache.
  Future<List<CopilotMessage>> syncMessages(
    String tenantId,
    String conversationId,
  );

  Future<void> deleteConversation(String tenantId, String conversationId);

  /// Streams the answer as SSE events; falls back to a single JSON answer when streaming is unavailable.
  Stream<CopilotEvent> sendMessage(
    String tenantId,
    String conversationId, {
    required String prompt,
    required String locale,
    CopilotContext? context,
  });

  /// Confirms an action; [overrides] keys are dotted paths from `editable_fields`.
  Future<CopilotMessage> confirmAction(
    String tenantId,
    String messageId, {
    Map<String, Object?> overrides = const <String, Object?>{},
  });

  Future<CopilotMessage> rejectAction(
    String tenantId,
    String messageId, {
    String? reason,
  });
}
