import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../data/copilot_repository_impl.dart';
import '../domain/copilot_models.dart';
import '../domain/copilot_repository.dart';

final Provider<CopilotRepository> copilotRepositoryProvider =
    Provider<CopilotRepository>(
      (Ref ref) => CopilotRepositoryImpl(
        ref.watch(databaseProvider),
        ref.watch(dioProvider),
      ),
    );

/// Holds the context of the screen currently on top (fed by [CopilotRouteObserver]).
class CopilotContextTracker {
  CopilotContext current = const CopilotContext();
}

final Provider<CopilotContextTracker> copilotContextTrackerProvider =
    Provider<CopilotContextTracker>((Ref ref) => CopilotContextTracker());

/// Captures the active screen as Copilot context: route name plus, when a route carries a
/// [CopilotContext] as its arguments, the entity being viewed. Overlays (sheets, dialogs) are ignored.
class CopilotRouteObserver extends NavigatorObserver {
  CopilotRouteObserver(this._tracker);

  final CopilotContextTracker _tracker;

  void _capture(Route<dynamic>? route) {
    if (route is! PageRoute<dynamic>) return;
    final Object? args = route.settings.arguments;
    final String? name = route.settings.name;
    if (args is CopilotContext) {
      _tracker.current = CopilotContext(
        route: args.route ?? name,
        entityType: args.entityType,
        entityId: args.entityId,
      );
    } else {
      _tracker.current = CopilotContext(route: name);
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _capture(route);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _capture(newRoute);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute<dynamic>) _capture(previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _capture(previousRoute);
}

class CopilotState {
  const CopilotState({
    this.conversationId,
    this.messages = const <CopilotMessage>[],
    this.history = const <CopilotConversation>[],
    this.busy = false,
    this.activity,
    this.error,
    this.offline = false,
    this.loading = false,
  });

  final String? conversationId;
  final List<CopilotMessage> messages;
  final List<CopilotConversation> history;
  final bool busy;

  /// Name of the tool currently running, if any.
  final String? activity;
  final CopilotErrorKind? error;
  final bool offline;
  final bool loading;

  CopilotState copyWith({
    String? conversationId,
    List<CopilotMessage>? messages,
    List<CopilotConversation>? history,
    bool? busy,
    String? activity,
    bool clearActivity = false,
    CopilotErrorKind? error,
    bool clearError = false,
    bool? offline,
    bool? loading,
    bool clearConversation = false,
  }) => CopilotState(
    conversationId: clearConversation
        ? null
        : (conversationId ?? this.conversationId),
    messages: messages ?? this.messages,
    history: history ?? this.history,
    busy: busy ?? this.busy,
    activity: clearActivity ? null : (activity ?? this.activity),
    error: clearError ? null : (error ?? this.error),
    offline: offline ?? this.offline,
    loading: loading ?? this.loading,
  );
}

/// Localized message for a Copilot failure.
String copilotErrorText(AppLocalizations l, CopilotErrorKind kind) =>
    switch (kind) {
      CopilotErrorKind.forbidden => l.copilotErrForbidden,
      CopilotErrorKind.notFound => l.copilotErrNotFound,
      CopilotErrorKind.conflict => l.copilotErrConflict,
      CopilotErrorKind.invalid => l.copilotErrInvalid,
      CopilotErrorKind.rateLimited => l.copilotErrRateLimited,
      CopilotErrorKind.provider => l.copilotErrProvider,
      CopilotErrorKind.offline => l.copilotErrOffline,
      CopilotErrorKind.unknown => l.copilotErrUnknown,
    };

/// Strings for the active app language (the app has no Localizations delegate wired globally).
AppLocalizations copilotStrings(String languageCode) => lookupAppLocalizations(
  Locale(
    languageCode == 'it' || languageCode == 'de' || languageCode == 'fr'
        ? languageCode
        : 'en',
  ),
);

class CopilotController extends Notifier<CopilotState> {
  int _localSeq = 0;

  CopilotRepository get _repo => ref.read(copilotRepositoryProvider);
  String get _tenant => ref.read(requestContextProvider).tenantId ?? '';

  @override
  CopilotState build() => const CopilotState();

  /// Shows the cached conversation immediately, then refreshes from the API when online.
  Future<void> open() async {
    state = state.copyWith(loading: true, clearError: true);
    final List<CopilotConversation> cached = await _repo.cachedConversations(
      _tenant,
    );
    String? id =
        state.conversationId ?? (cached.isEmpty ? null : cached.first.id);
    List<CopilotMessage> messages = state.messages;
    if (id != null && messages.isEmpty)
      messages = await _repo.cachedMessages(_tenant, id);
    state = state.copyWith(
      history: cached,
      conversationId: id,
      messages: messages,
    );
    try {
      final List<CopilotConversation> fresh = await _repo.syncConversations(
        _tenant,
      );
      id ??= fresh.isEmpty ? null : fresh.first.id;
      if (id != null && !state.busy)
        messages = await _repo.syncMessages(_tenant, id);
      state = state.copyWith(
        history: fresh,
        conversationId: id,
        messages: state.busy ? state.messages : messages,
        offline: false,
        loading: false,
      );
    } on CopilotException catch (e) {
      state = state.copyWith(
        offline: e.kind == CopilotErrorKind.offline,
        error: e.kind == CopilotErrorKind.offline ? null : e.kind,
        loading: false,
      );
    }
  }

  void newChat() => state = state.copyWith(
    clearConversation: true,
    messages: const <CopilotMessage>[],
    clearError: true,
  );

  Future<void> select(String id) async {
    state = state.copyWith(
      conversationId: id,
      messages: await _repo.cachedMessages(_tenant, id),
      clearError: true,
    );
    try {
      final List<CopilotMessage> fresh = await _repo.syncMessages(_tenant, id);
      if (state.conversationId == id)
        state = state.copyWith(messages: fresh, offline: false);
    } on CopilotException catch (e) {
      state = state.copyWith(offline: e.kind == CopilotErrorKind.offline);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _repo.deleteConversation(_tenant, id);
      final List<CopilotConversation> history = state.history
          .where((CopilotConversation c) => c.id != id)
          .toList();
      state = state.copyWith(history: history);
      if (state.conversationId == id) newChat();
    } on CopilotException catch (e) {
      state = state.copyWith(error: e.kind);
    }
  }

  void clearError() => state = state.copyWith(clearError: true);

  /// Sends a prompt with the active screen context and streams the answer into the message list.
  Future<void> send(String prompt) async {
    final String text = prompt.trim();
    if (text.isEmpty || state.busy) return;
    state = state.copyWith(busy: true, clearError: true, clearActivity: true);
    try {
      String? convId = state.conversationId;
      convId ??= (await _repo.createConversation(_tenant)).id;
      final int n = ++_localSeq;
      final DateTime now = DateTime.now();
      final CopilotMessage user = CopilotMessage(
        id: 'local-user-$n',
        conversationId: convId,
        role: MessageRole.user,
        content: text,
        createdAt: now,
      );
      CopilotMessage answer = CopilotMessage(
        id: 'local-assistant-$n',
        conversationId: convId,
        role: MessageRole.assistant,
        content: '',
        createdAt: now,
        streaming: true,
      );
      state = state.copyWith(
        conversationId: convId,
        messages: <CopilotMessage>[...state.messages, user, answer],
      );

      void put(CopilotMessage m) {
        answer = m;
        state = state.copyWith(
          messages: <CopilotMessage>[
            for (final CopilotMessage x in state.messages)
              x.id == m.id || x.id == 'local-assistant-$n' ? m : x,
          ],
        );
      }

      final CopilotContext context = ref
          .read(copilotContextTrackerProvider)
          .current;
      final Stream<CopilotEvent> events = _repo.sendMessage(
        _tenant,
        convId,
        prompt: text,
        locale: ref.read(requestContextProvider).languageCode,
        context: context,
      );
      await for (final CopilotEvent ev in events) {
        switch (ev) {
          case MessageStarted():
            break;
          case ToolCalled(:final String name):
            state = state.copyWith(activity: name);
          case ToolResulted():
            state = state.copyWith(clearActivity: true);
          case VisualizationEvent(:final Visualization visualization):
            put(answer.copyWith(visualization: visualization));
          case ActionProposedEvent(:final ProposedAction action):
            put(
              answer.copyWith(
                proposedAction: action,
                actionStatus: ActionStatus.pending,
              ),
            );
          case TokenEvent(:final String text):
            put(answer.copyWith(content: answer.content + text));
          case MessageCompleted(:final String messageId):
            put(answer.copyWith(id: messageId, streaming: false));
          case StreamError():
            state = state.copyWith(error: CopilotErrorKind.provider);
        }
      }
      put(answer.copyWith(streaming: false));
      final List<CopilotMessage> stored = await _repo.cachedMessages(
        _tenant,
        convId,
      );
      if (stored.isNotEmpty &&
          stored.any((CopilotMessage m) => m.id == answer.id)) {
        state = state.copyWith(messages: stored);
      }
      state = state.copyWith(offline: false);
      unawaited(_refreshHistory());
    } on CopilotException catch (e) {
      state = state.copyWith(
        error: e.kind,
        offline: e.kind == CopilotErrorKind.offline,
      );
      _dropEmptyPlaceholder();
    } finally {
      state = state.copyWith(busy: false, clearActivity: true);
    }
  }

  void _dropEmptyPlaceholder() {
    state = state.copyWith(
      messages: state.messages
          .where(
            (CopilotMessage m) =>
                !(m.streaming &&
                    m.content.isEmpty &&
                    m.visualization == null &&
                    m.proposedAction == null),
          )
          .toList(),
    );
  }

  Future<void> _refreshHistory() async {
    state = state.copyWith(history: await _repo.cachedConversations(_tenant));
  }

  void _replace(CopilotMessage updated) {
    state = state.copyWith(
      messages: <CopilotMessage>[
        for (final CopilotMessage m in state.messages)
          m.id == updated.id ? updated : m,
      ],
    );
  }

  /// Confirms a proposed action, sending only the overrides the user changed.
  Future<void> confirm(String messageId, Map<String, Object?> overrides) async {
    try {
      _replace(
        (await _repo.confirmAction(_tenant, messageId, overrides: overrides)),
      );
    } on CopilotException catch (e) {
      state = state.copyWith(error: e.kind);
      if (e.kind == CopilotErrorKind.conflict) await _reload();
    }
  }

  Future<void> reject(String messageId) async {
    try {
      _replace(await _repo.rejectAction(_tenant, messageId));
    } on CopilotException catch (e) {
      state = state.copyWith(error: e.kind);
      if (e.kind == CopilotErrorKind.conflict) await _reload();
    }
  }

  Future<void> _reload() async {
    final String? id = state.conversationId;
    if (id == null) return;
    try {
      state = state.copyWith(messages: await _repo.syncMessages(_tenant, id));
    } on CopilotException {
      // Keep the local copy.
    }
  }
}

final NotifierProvider<CopilotController, CopilotState>
copilotControllerProvider = NotifierProvider<CopilotController, CopilotState>(
  CopilotController.new,
);
