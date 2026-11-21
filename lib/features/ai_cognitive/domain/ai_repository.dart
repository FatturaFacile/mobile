import 'package:flutter/foundation.dart';

import 'ai_models.dart';

/// Why an AI call failed; the UI maps it to a localized message.
enum AiErrorKind {
  forbidden,
  notFound,
  alreadyDecided,
  invalid,
  rateLimited,
  unavailable,
  offline,
  unknown,
}

class AiException implements Exception {
  const AiException(this.kind, [this.detail = '']);

  final AiErrorKind kind;

  /// `detail` of the RFC 7807 problem, shown for [AiErrorKind.invalid].
  final String detail;

  @override
  String toString() => 'AiException($kind, $detail)';
}

/// Result of [AiCognitiveRepository.capture].
enum CaptureStatus {
  /// Accepted by the server: the draft now waits in the review queue.
  sent,

  /// Stored in the offline queue (no connection, provider unavailable or quota); it will be resent.
  queued,

  /// The server refused it for good; [CaptureOutcome.detail] says why. It is not retried.
  rejected,

  /// Not sent: the text is shorter than the backend minimum.
  tooShort,
}

@immutable
class CaptureOutcome {
  const CaptureOutcome(this.status, {this.detail = ''});

  final CaptureStatus status;
  final String detail;
}

/// A capture the server refused (422/403) and that stays parked until the user dismisses or retries it.
@immutable
class RejectedCapture {
  const RejectedCapture({required this.queueUuid, required this.detail});

  final String queueUuid;
  final String detail;
}

/// Offline-queue picture of the captures of one tenant.
@immutable
class CaptureQueue {
  const CaptureQueue({
    this.waiting = 0,
    this.rejected = const <RejectedCapture>[],
  });

  final int waiting;
  final List<RejectedCapture> rejected;
}

/// Backend gateway, offline capture queue and suggestion cache. Failures throw [AiException].
abstract interface class AiCognitiveRepository {
  /// Open suggestions stored by the last successful [refresh] (offline reading).
  Future<List<Suggestion>> cached(String tenantId);

  /// Loads the open queue from the API and replaces the cache.
  Future<SuggestionsPage> refresh(String tenantId);

  /// Queues the text in the offline outbox and tries to send it right away.
  Future<CaptureOutcome> capture(
    String tenantId, {
    required CaptureKind kind,
    required String text,
    required String locale,
  });

  Future<CaptureQueue> captureQueue(String tenantId);

  /// Resends a rejected capture / drops it for good.
  Future<void> retryCapture(String tenantId, String queueUuid);
  Future<void> dismissCapture(String queueUuid);

  Future<Suggestion> approve(
    String tenantId,
    String id, {
    Map<String, dynamic>? editedPayload,
    String? feedback,
  });

  Future<Suggestion> reject(
    String tenantId,
    String id, {
    required String reason,
  });
}

/// Speech-to-text hook. No speech plugin is a dependency yet, so the default implementation is a no-op and
/// the UI hides the microphone; a real implementation only has to be provided through `dictationProvider`.
abstract interface class DictationService {
  bool get available;

  /// Listens and returns the recognised text, or `null` when nothing was said or recognition was cancelled.
  Future<String?> listen({required String locale});
}

class NoopDictationService implements DictationService {
  const NoopDictationService();

  @override
  bool get available => false;

  @override
  Future<String?> listen({required String locale}) async => null;
}
