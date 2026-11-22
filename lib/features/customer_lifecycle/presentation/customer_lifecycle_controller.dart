import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../app/session_controller.dart';
import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_engine.dart';
import '../data/customer_lifecycle_remote_data_source.dart';
import '../domain/customer_lifecycle_models.dart';

/// Sync-queue entity of the quick-action activities queued while offline.
const String lifecycleActivityEntity = 'crm_activities';

/// Longest activity subject the web-api accepts.
const int kActivitySubjectMax = 200;

/// Quick actions of the customer 360 page and the CRM activity type each one logs.
enum LifecycleQuickAction {
  logVisit('meeting'),
  createFollowUp('follow_up');

  const LifecycleQuickAction(this.activityType);

  final String activityType;
}

/// What happened to a quick action.
enum QuickActionOutcome { sent, queued, invalid, failed }

/// Active tenant of the signed-in session (`null` when signed out). Tests override it.
final Provider<String?> lifecycleTenantIdProvider = Provider<String?>((
  Ref ref,
) {
  final SessionState? s = ref.watch(sessionProvider).value;
  return s is SignedIn ? s.bootstrap.tenantId : null;
});

final Provider<CustomerLifecycleRemoteDataSource>
customerLifecycleRemoteProvider = Provider<CustomerLifecycleRemoteDataSource>(
  (Ref ref) => CustomerLifecycleRemoteDataSource(ref.watch(dioProvider)),
);

/// The shared outbox engine (overridden in tests).
final Provider<SyncEngine> lifecycleSyncEngineProvider = Provider<SyncEngine>(
  (Ref ref) => ref.watch(syncEngineProvider),
);

class CustomerLifecycleState {
  const CustomerLifecycleState({
    this.results = const <LifecycleContact>[],
    this.selected,
    this.view,
    this.types = const <String>[],
    this.loading = false,
    this.noAccount = false,
    this.error,
  });

  final List<LifecycleContact> results;
  final LifecycleContact? selected;
  final CustomerLifecycleView? view;

  /// The timeline types the filter keeps; empty means all of them.
  final List<String> types;
  final bool loading;

  /// The selected customer has no CRM account behind it.
  final bool noAccount;
  final LifecycleErrorKind? error;

  CustomerLifecycleState copyWith({
    List<LifecycleContact>? results,
    LifecycleContact? selected,
    CustomerLifecycleView? Function()? view,
    List<String>? types,
    bool? loading,
    bool? noAccount,
    LifecycleErrorKind? Function()? error,
  }) => CustomerLifecycleState(
    results: results ?? this.results,
    selected: selected ?? this.selected,
    view: view == null ? this.view : view(),
    types: types ?? this.types,
    loading: loading ?? this.loading,
    noAccount: noAccount ?? this.noAccount,
    error: error == null ? this.error : error(),
  );
}

/// Online customer 360: search a customer, read its summary and filtered timeline from the web-api.
class CustomerLifecycleController extends Notifier<CustomerLifecycleState> {
  String? _accountId;

  CustomerLifecycleRemoteDataSource get _remote =>
      ref.read(customerLifecycleRemoteProvider);

  @override
  CustomerLifecycleState build() => const CustomerLifecycleState();

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = state.copyWith(results: <LifecycleContact>[]);
      return;
    }
    try {
      final List<LifecycleContact> found = await _remote.searchContacts(
        query.trim(),
      );
      state = state.copyWith(results: found, error: () => null);
    } on LifecycleRemoteException catch (e) {
      state = state.copyWith(error: () => e.kind);
    }
  }

  Future<void> select(LifecycleContact contact) async {
    state = state.copyWith(
      selected: contact,
      view: () => null,
      types: <String>[],
      loading: true,
      noAccount: false,
      error: () => null,
    );
    try {
      _accountId = await _remote.findAccountId(contact.id);
      final String? accountId = _accountId;
      if (accountId == null) {
        state = state.copyWith(loading: false, noAccount: true);
        return;
      }
      final CustomerLifecycleSummary summary = await _remote.summary(accountId);
      final List<CustomerTimelineEvent> timeline = await _remote.timeline(
        accountId,
      );
      state = state.copyWith(
        view: () => CustomerLifecycleView(summary: summary, timeline: timeline),
        loading: false,
      );
    } on LifecycleRemoteException catch (e) {
      state = state.copyWith(loading: false, error: () => e.kind);
    }
  }

  /// Logs a visit or follow-up on the selected account. Sent right away; when the network is unreachable the
  /// action is saved in the sync outbox (replayed by [replayPending]); validation errors are never queued.
  Future<QuickActionOutcome> quickAction(
    LifecycleQuickAction action,
    String subject, {
    DateTime? dueDate,
  }) async {
    final String? accountId = _accountId;
    final String trimmed = subject.trim();
    if (accountId == null ||
        trimmed.isEmpty ||
        trimmed.length > kActivitySubjectMax) {
      return QuickActionOutcome.invalid;
    }
    final String? due = dueDate?.toIso8601String().substring(0, 10);
    try {
      await _remote.createActivity(
        accountId: accountId,
        type: action.activityType,
        subject: trimmed,
        dueDate: due,
      );
    } on LifecycleRemoteException catch (e) {
      switch (e.kind) {
        case LifecycleErrorKind.offline:
          return _enqueue(accountId, action, trimmed, due);
        case LifecycleErrorKind.validation:
          return QuickActionOutcome.invalid;
        default:
          state = state.copyWith(error: () => e.kind);
          return QuickActionOutcome.failed;
      }
    }
    await _reloadTimeline();
    return QuickActionOutcome.sent;
  }

  Future<QuickActionOutcome> _enqueue(
    String accountId,
    LifecycleQuickAction action,
    String subject,
    String? due,
  ) async {
    final String? tenantId = ref.read(lifecycleTenantIdProvider);
    if (tenantId == null) {
      state = state.copyWith(error: () => LifecycleErrorKind.offline);
      return QuickActionOutcome.failed;
    }
    await ref
        .read(lifecycleSyncEngineProvider)
        .enqueueCommand(
          tenantId: tenantId,
          entity: lifecycleActivityEntity,
          path: CustomerLifecycleRemoteDataSource.activitiesPath,
          data: CustomerLifecycleRemoteDataSource.activityBody(
            accountId: accountId,
            type: action.activityType,
            subject: subject,
            dueDate: due,
          ),
        );
    return QuickActionOutcome.queued;
  }

  /// Number of quick actions still waiting for the network.
  Future<int> pendingCount() async {
    final String? tenantId = ref.read(lifecycleTenantIdProvider);
    if (tenantId == null) {
      return 0;
    }
    final List<QueueItem> rows = await ref
        .read(lifecycleSyncEngineProvider)
        .queued(tenantId, lifecycleActivityEntity);
    return rows
        .where(
          (QueueItem r) =>
              r.state == QueueState.pending || r.state == QueueState.failed,
        )
        .length;
  }

  /// Replays the queued actions (page open, connectivity back). Returns how many were delivered.
  Future<int> replayPending() async {
    final String? tenantId = ref.read(lifecycleTenantIdProvider);
    if (tenantId == null || await pendingCount() == 0) {
      return 0;
    }
    final FlushReport report = await ref
        .read(lifecycleSyncEngineProvider)
        .flush(tenantId);
    if (report.sent > 0) {
      await _reloadTimeline();
    }
    return report.sent;
  }

  Future<void> _reloadTimeline() async {
    final String? accountId = _accountId;
    final CustomerLifecycleView? current = state.view;
    if (accountId == null || current == null) {
      return;
    }
    try {
      final List<CustomerTimelineEvent> timeline = await _remote.timeline(
        accountId,
        types: state.types,
      );
      state = state.copyWith(
        view: () =>
            CustomerLifecycleView(summary: current.summary, timeline: timeline),
      );
    } on LifecycleRemoteException {
      // The action itself succeeded; the timeline refreshes on the next load.
    }
  }

  /// Keeps only the timeline [types] (empty keeps all) and reloads the timeline.
  Future<void> filter(List<String> types) async {
    final String? accountId = _accountId;
    final CustomerLifecycleView? current = state.view;
    if (accountId == null || current == null) {
      return;
    }
    state = state.copyWith(types: types, error: () => null);
    try {
      final List<CustomerTimelineEvent> timeline = await _remote.timeline(
        accountId,
        types: types,
      );
      state = state.copyWith(
        view: () =>
            CustomerLifecycleView(summary: current.summary, timeline: timeline),
      );
    } on LifecycleRemoteException catch (e) {
      state = state.copyWith(error: () => e.kind);
    }
  }
}

final NotifierProvider<CustomerLifecycleController, CustomerLifecycleState>
customerLifecycleControllerProvider =
    NotifierProvider<CustomerLifecycleController, CustomerLifecycleState>(
      CustomerLifecycleController.new,
    );
