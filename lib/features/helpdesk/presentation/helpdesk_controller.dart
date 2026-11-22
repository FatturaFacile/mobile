import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../app/session_controller.dart';
import '../data/helpdesk_repository_impl.dart';
import '../domain/helpdesk_models.dart';
import '../domain/helpdesk_repository.dart';
import '../notifications/helpdesk_push_handler.dart';

final Provider<HelpdeskRepository> helpdeskRepositoryProvider =
    Provider<HelpdeskRepository>(
      (Ref ref) => HelpdeskRepositoryImpl(
        ref.watch(databaseProvider),
        ref.watch(dioProvider),
        ref.watch(syncEngineProvider),
      ),
    );

/// Active tenant of the signed-in session (`null` when signed out). Tests override it.
final Provider<String?> helpdeskTenantIdProvider = Provider<String?>((Ref ref) {
  final SessionState? s = ref.watch(sessionProvider).value;
  return s is SignedIn ? s.bootstrap.tenantId : null;
});

/// Technician (user) of the session, sent with the time entries. Tests override it.
final Provider<String?> helpdeskUserIdProvider = Provider<String?>((Ref ref) {
  final SessionState? s = ref.watch(sessionProvider).value;
  return s is SignedIn ? s.bootstrap.userId : null;
});

/// Clock of the countdowns; tests override it.
final Provider<DateTime Function()> helpdeskClockProvider =
    Provider<DateTime Function()>((Ref ref) => DateTime.now);

final Provider<HelpdeskPushHandler> helpdeskPushHandlerProvider =
    Provider<HelpdeskPushHandler>((Ref ref) => const HelpdeskPushHandler());

/// Queue filter chips.
enum QueueFilter { all, urgent, atRisk }

@immutable
class HelpdeskQueueState {
  const HelpdeskQueueState({
    this.tickets = const <QueueTicket>[],
    this.filter = QueueFilter.all,
    this.loading = false,
    this.fromCache = false,
    this.error,
    this.pending = const <PendingAction>[],
  });

  /// Sorted by SLA risk, then priority.
  final List<QueueTicket> tickets;
  final QueueFilter filter;
  final bool loading;

  /// The list is the offline copy because the last refresh failed.
  final bool fromCache;
  final HelpdeskException? error;
  final List<PendingAction> pending;

  List<QueueTicket> get visible => switch (filter) {
    QueueFilter.all => tickets,
    QueueFilter.urgent =>
      tickets.where((QueueTicket t) => t.priority.isUrgent).toList(),
    QueueFilter.atRisk =>
      tickets.where((QueueTicket t) => t.riskPercent != null).toList(),
  };

  bool get forbidden => error?.kind == HelpdeskErrorKind.forbidden;

  /// Outbox rows of one ticket, for the badge on the queue card.
  int pendingFor(String ticketId) =>
      pending.where((PendingAction a) => a.ticketId == ticketId).length;

  HelpdeskQueueState copyWith({
    List<QueueTicket>? tickets,
    QueueFilter? filter,
    bool? loading,
    bool? fromCache,
    Object? error = _keep,
    List<PendingAction>? pending,
  }) {
    return HelpdeskQueueState(
      tickets: tickets ?? this.tickets,
      filter: filter ?? this.filter,
      loading: loading ?? this.loading,
      fromCache: fromCache ?? this.fromCache,
      error: identical(error, _keep) ? this.error : error as HelpdeskException?,
      pending: pending ?? this.pending,
    );
  }

  static const Object _keep = Object();
}

/// Operator queue, readable offline: shows the cached copy first, then refreshes.
class HelpdeskQueueController extends Notifier<HelpdeskQueueState> {
  late String? _tenantId;

  HelpdeskRepository get _repo => ref.read(helpdeskRepositoryProvider);

  @override
  HelpdeskQueueState build() {
    _tenantId = ref.watch(helpdeskTenantIdProvider);
    return const HelpdeskQueueState();
  }

  /// Never throws.
  Future<void> load() async {
    final String? tenant = _tenantId;
    if (tenant == null) {
      return;
    }
    state = state.copyWith(loading: true, error: null);
    if (state.tickets.isEmpty) {
      final List<QueueTicket> cached = await _repo.cachedQueue(tenant);
      state = state.copyWith(tickets: cached, fromCache: cached.isNotEmpty);
    }
    try {
      // Queued time logs and escalations go out first, so the refreshed queue already reflects them.
      await _repo.flush(tenant);
    } catch (_) {
      // Still offline: they stay queued.
    }
    try {
      final List<QueueTicket> fresh = await _repo.refreshQueue(tenant);
      state = state.copyWith(tickets: fresh, fromCache: false);
    } on HelpdeskException catch (e) {
      state = e.kind == HelpdeskErrorKind.forbidden
          ? state.copyWith(
              tickets: const <QueueTicket>[],
              fromCache: false,
              error: e,
            )
          : state.copyWith(error: e);
    }
    state = state.copyWith(
      loading: false,
      pending: await _repo.pendingActions(tenant),
    );
  }

  void setFilter(QueueFilter filter) => state = state.copyWith(filter: filter);
}

final NotifierProvider<HelpdeskQueueController, HelpdeskQueueState>
helpdeskQueueProvider =
    NotifierProvider<HelpdeskQueueController, HelpdeskQueueState>(
      HelpdeskQueueController.new,
    );

/// A one-shot message after an action, mapped to a localized snack by the page.
enum HelpdeskNotice {
  timeSent,
  timeQueued,
  escalateSent,
  escalateQueued,
  rejected,
}

@immutable
class TicketDetailState {
  const TicketDetailState({
    this.ticketId = '',
    this.ticket,
    this.context,
    this.entries = const <TimeEntry>[],
    this.pending = const <PendingAction>[],
    this.loading = false,
    this.busy = false,
    this.error,
    this.notice,
    this.noticeDetail = '',
  });

  final String ticketId;
  final QueueTicket? ticket;
  final CustomerContext? context;
  final List<TimeEntry> entries;
  final List<PendingAction> pending;
  final bool loading;
  final bool busy;
  final HelpdeskException? error;
  final HelpdeskNotice? notice;
  final String noticeDetail;

  /// An escalation of [target] is already waiting in the outbox (the one-tap button is then disabled).
  bool escalationPending(EscalationTarget target) {
    final PendingActionKind kind = target == EscalationTarget.fieldService
        ? PendingActionKind.fieldService
        : PendingActionKind.rma;
    return pending.any((PendingAction a) => a.kind == kind && !a.rejected);
  }

  TicketDetailState copyWith({
    String? ticketId,
    QueueTicket? ticket,
    CustomerContext? context,
    List<TimeEntry>? entries,
    List<PendingAction>? pending,
    bool? loading,
    bool? busy,
    Object? error = _keep,
    Object? notice = _keep,
    String? noticeDetail,
  }) {
    return TicketDetailState(
      ticketId: ticketId ?? this.ticketId,
      ticket: ticket ?? this.ticket,
      context: context ?? this.context,
      entries: entries ?? this.entries,
      pending: pending ?? this.pending,
      loading: loading ?? this.loading,
      busy: busy ?? this.busy,
      error: identical(error, _keep) ? this.error : error as HelpdeskException?,
      notice: identical(notice, _keep)
          ? this.notice
          : notice as HelpdeskNotice?,
      noticeDetail: noticeDetail ?? this.noticeDetail,
    );
  }

  static const Object _keep = Object();
}

/// One ticket: customer context, time entries, time logging and escalation, all usable offline.
class TicketDetailController extends Notifier<TicketDetailState> {
  late String? _tenantId;

  HelpdeskRepository get _repo => ref.read(helpdeskRepositoryProvider);

  @override
  TicketDetailState build() {
    _tenantId = ref.watch(helpdeskTenantIdProvider);
    return const TicketDetailState();
  }

  /// Offline copy first, then the server. Never throws.
  Future<void> load(String ticketId) async {
    final String? tenant = _tenantId;
    if (tenant == null) {
      return;
    }
    state = TicketDetailState(ticketId: ticketId, loading: true);
    state = state.copyWith(
      ticket: await _repo.cachedTicket(tenant, ticketId),
      context: await _repo.cachedContext(tenant, ticketId),
      entries: await _repo.cachedTimeEntries(tenant, ticketId),
      pending: await _repo.pendingActions(tenant, ticketId: ticketId),
    );
    try {
      final CustomerContext ctx = await _repo.refreshContext(tenant, ticketId);
      state = state.copyWith(context: ctx);
      final List<TimeEntry> entries = await _repo.refreshTimeEntries(
        tenant,
        ticketId,
      );
      state = state.copyWith(entries: entries);
    } on HelpdeskException catch (e) {
      state = state.copyWith(error: e);
    }
    state = state.copyWith(loading: false);
  }

  Future<void> logTime({
    required int minutes,
    String? description,
    bool isBillable = true,
  }) async {
    final String? tenant = _tenantId;
    if (tenant == null || state.ticketId.isEmpty || state.busy) {
      return;
    }
    state = state.copyWith(busy: true, notice: null);
    final ActionOutcome outcome = await _repo.logTime(
      tenant,
      state.ticketId,
      minutes: minutes,
      technicianId: ref.read(helpdeskUserIdProvider),
      description: description,
      isBillable: isBillable,
    );
    await _afterAction(
      tenant,
      outcome,
      sent: HelpdeskNotice.timeSent,
      queued: HelpdeskNotice.timeQueued,
      refreshEntries: true,
    );
  }

  Future<void> escalate(EscalationTarget target) async {
    final String? tenant = _tenantId;
    if (tenant == null ||
        state.ticketId.isEmpty ||
        state.busy ||
        state.escalationPending(target)) {
      return;
    }
    state = state.copyWith(busy: true, notice: null);
    final ActionOutcome outcome = await _repo.escalate(
      tenant,
      state.ticketId,
      target,
    );
    await _afterAction(
      tenant,
      outcome,
      sent: HelpdeskNotice.escalateSent,
      queued: HelpdeskNotice.escalateQueued,
    );
  }

  Future<void> retry(String queueUuid) async {
    final String? tenant = _tenantId;
    if (tenant == null) {
      return;
    }
    await _repo.retryAction(tenant, queueUuid);
    state = state.copyWith(
      pending: await _repo.pendingActions(tenant, ticketId: state.ticketId),
    );
  }

  Future<void> dismiss(String queueUuid) async {
    final String? tenant = _tenantId;
    if (tenant == null) {
      return;
    }
    await _repo.dismissAction(queueUuid);
    state = state.copyWith(
      pending: await _repo.pendingActions(tenant, ticketId: state.ticketId),
    );
  }

  Future<void> _afterAction(
    String tenant,
    ActionOutcome outcome, {
    required HelpdeskNotice sent,
    required HelpdeskNotice queued,
    bool refreshEntries = false,
  }) async {
    final HelpdeskNotice notice = switch (outcome.status) {
      ActionStatus.sent => sent,
      ActionStatus.queued => queued,
      ActionStatus.rejected => HelpdeskNotice.rejected,
    };
    List<TimeEntry>? entries;
    if (refreshEntries && outcome.status == ActionStatus.sent) {
      try {
        entries = await _repo.refreshTimeEntries(tenant, state.ticketId);
      } on HelpdeskException {
        // The entry is saved; the list refreshes on the next load.
      }
    }
    state = state.copyWith(
      busy: false,
      notice: notice,
      noticeDetail: outcome.detail,
      entries: entries,
      pending: await _repo.pendingActions(tenant, ticketId: state.ticketId),
    );
  }

  void clearNotice() => state = state.copyWith(notice: null);
}

final NotifierProvider<TicketDetailController, TicketDetailState>
ticketDetailProvider =
    NotifierProvider<TicketDetailController, TicketDetailState>(
      TicketDetailController.new,
    );
