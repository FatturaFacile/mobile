import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../app/session_controller.dart';
import '../data/ai_repository_impl.dart';
import '../domain/ai_models.dart';
import '../domain/ai_repository.dart';

final Provider<AiCognitiveRepository> aiRepositoryProvider =
    Provider<AiCognitiveRepository>(
      (Ref ref) => AiCognitiveRepositoryImpl(
        ref.watch(databaseProvider),
        ref.watch(dioProvider),
        ref.watch(syncEngineProvider),
      ),
    );

/// Speech-to-text hook; override with a real implementation once a speech plugin is added.
final Provider<DictationService> dictationProvider = Provider<DictationService>(
  (Ref ref) => const NoopDictationService(),
);

/// Active tenant of the signed-in session (`null` when signed out). Tests override it.
final Provider<String?> aiTenantIdProvider = Provider<String?>((Ref ref) {
  final SessionState? s = ref.watch(sessionProvider).value;
  return s is SignedIn ? s.bootstrap.tenantId : null;
});

@immutable
class AiSuggestionsState {
  const AiSuggestionsState({
    this.suggestions = const <Suggestion>[],
    this.loading = false,
    this.fromCache = false,
    this.error,
    this.busyIds = const <String>{},
    this.queue = const CaptureQueue(),
    this.openByKind = const <String, int>{},
  });

  final List<Suggestion> suggestions;
  final bool loading;

  /// The list shows the offline copy because the last refresh failed.
  final bool fromCache;
  final AiException? error;

  /// Suggestions with a decision request in flight (buttons disabled).
  final Set<String> busyIds;
  final CaptureQueue queue;
  final Map<String, int> openByKind;

  bool get forbidden => error?.kind == AiErrorKind.forbidden;

  /// The alert for the app shell, if any.
  Suggestion? get alert => selectAlertBanner(suggestions);

  AiSuggestionsState copyWith({
    List<Suggestion>? suggestions,
    bool? loading,
    bool? fromCache,
    Object? error = _keep,
    Set<String>? busyIds,
    CaptureQueue? queue,
    Map<String, int>? openByKind,
  }) {
    return AiSuggestionsState(
      suggestions: suggestions ?? this.suggestions,
      loading: loading ?? this.loading,
      fromCache: fromCache ?? this.fromCache,
      error: identical(error, _keep) ? this.error : error as AiException?,
      busyIds: busyIds ?? this.busyIds,
      queue: queue ?? this.queue,
      openByKind: openByKind ?? this.openByKind,
    );
  }

  static const Object _keep = Object();
}

/// State container of the suggestion queue, the offline capture queue and the app-shell alert.
class AiSuggestionsController extends Notifier<AiSuggestionsState> {
  late String? _tenantId;

  AiCognitiveRepository get _repo => ref.read(aiRepositoryProvider);

  @override
  AiSuggestionsState build() {
    // Re-created (and therefore emptied) when the tenant changes.
    _tenantId = ref.watch(aiTenantIdProvider);
    return const AiSuggestionsState();
  }

  /// Shows the offline copy first, then refreshes from the API. Never throws.
  Future<void> load() async {
    final String? tenant = _tenantId;
    if (tenant == null) {
      return;
    }
    state = state.copyWith(loading: true, error: null);
    if (state.suggestions.isEmpty) {
      final List<Suggestion> cached = await _repo.cached(tenant);
      state = state.copyWith(suggestions: cached, fromCache: cached.isNotEmpty);
    }
    try {
      final SuggestionsPage page = await _repo.refresh(tenant);
      state = state.copyWith(
        suggestions: page.items,
        openByKind: page.openByKind,
        fromCache: false,
        error: null,
      );
    } on AiException catch (e) {
      // Offline or provider trouble keeps the cached list; "forbidden" means this role must not see any.
      state = e.kind == AiErrorKind.forbidden
          ? state.copyWith(
              suggestions: const <Suggestion>[],
              fromCache: false,
              error: e,
            )
          : state.copyWith(error: e);
    }
    state = state.copyWith(
      loading: false,
      queue: await _repo.captureQueue(tenant),
    );
  }

  /// Sends (or queues) a text capture. The text must have at least [aiCaptureMinChars] characters.
  Future<CaptureOutcome> capture(CaptureKind kind, String text) async {
    final String? tenant = _tenantId;
    if (tenant == null) {
      return const CaptureOutcome(CaptureStatus.queued);
    }
    final CaptureOutcome outcome = await _repo.capture(
      tenant,
      kind: kind,
      text: text,
      locale: ref.read(requestContextProvider).languageCode,
    );
    state = state.copyWith(queue: await _repo.captureQueue(tenant));
    if (outcome.status == CaptureStatus.sent) {
      await load();
    }
    return outcome;
  }

  Future<void> retryCapture(String queueUuid) async {
    final String? tenant = _tenantId;
    if (tenant == null) {
      return;
    }
    await _repo.retryCapture(tenant, queueUuid);
    await load();
  }

  Future<void> dismissCapture(String queueUuid) async {
    final String? tenant = _tenantId;
    if (tenant == null) {
      return;
    }
    await _repo.dismissCapture(queueUuid);
    state = state.copyWith(queue: await _repo.captureQueue(tenant));
  }

  /// Approves a suggestion. Returns `null` on success, otherwise the failure (409 refreshes the list).
  Future<AiException?> approve(
    String id, {
    Map<String, dynamic>? editedPayload,
    String? feedback,
  }) {
    return _decide(
      id,
      (String tenant) => _repo.approve(
        tenant,
        id,
        editedPayload: editedPayload,
        feedback: feedback,
      ),
    );
  }

  /// Rejects a suggestion; [reason] needs at least 3 characters (checked here and by the backend).
  Future<AiException?> reject(String id, String reason) {
    if (reason.trim().length < 3) {
      return Future<AiException?>.value(const AiException(AiErrorKind.invalid));
    }
    return _decide(
      id,
      (String tenant) => _repo.reject(tenant, id, reason: reason),
    );
  }

  Future<AiException?> _decide(
    String id,
    Future<Suggestion> Function(String tenant) call,
  ) async {
    final String? tenant = _tenantId;
    if (tenant == null) {
      return const AiException(AiErrorKind.unknown);
    }
    state = state.copyWith(busyIds: <String>{...state.busyIds, id});
    try {
      await call(tenant);
      state = state.copyWith(suggestions: _without(id), busyIds: _idle(id));
      return null;
    } on AiException catch (e) {
      // 409/404: somebody else decided it; the repository already dropped the local row.
      final bool gone =
          e.kind == AiErrorKind.alreadyDecided ||
          e.kind == AiErrorKind.notFound;
      // 422 keeps the suggestion pending so the user can see the problem and decide again.
      state = state.copyWith(
        suggestions: gone ? _without(id) : state.suggestions,
        busyIds: _idle(id),
      );
      return e;
    }
  }

  List<Suggestion> _without(String id) =>
      state.suggestions.where((Suggestion s) => s.id != id).toList();

  Set<String> _idle(String id) =>
      state.busyIds.where((String b) => b != id).toSet();
}

final NotifierProvider<AiSuggestionsController, AiSuggestionsState>
aiSuggestionsProvider =
    NotifierProvider<AiSuggestionsController, AiSuggestionsState>(
      AiSuggestionsController.new,
    );
