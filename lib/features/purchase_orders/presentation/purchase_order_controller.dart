import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../app/session_controller.dart';
import '../data/purchase_order_repository_impl.dart';
import '../domain/purchase_order_models.dart';
import '../domain/purchase_order_repository.dart';

final Provider<PurchaseOrderRepository> purchaseOrderRepositoryProvider =
    Provider<PurchaseOrderRepository>(
      (Ref ref) => PurchaseOrderRepositoryImpl(
        ref.watch(databaseProvider),
        ref.watch(dioProvider),
        ref.watch(syncEngineProvider),
      ),
    );

/// Active tenant of the signed-in session (`null` when signed out). Tests override it.
final Provider<String?> purchaseOrderTenantIdProvider = Provider<String?>((
  Ref ref,
) {
  final SessionState? s = ref.watch(sessionProvider).value;
  return s is SignedIn ? s.bootstrap.tenantId : null;
});

/// "Today" for the overdue alerts; tests override it to pin the clock.
final Provider<DateTime Function()> purchaseOrderClockProvider =
    Provider<DateTime Function()>((Ref ref) => DateTime.now);

/// A one-shot message after a write, mapped to a localized snack by the page.
enum PoNotice { sent, queued, rejected }

PoNotice _noticeOf(PoActionStatus s) => switch (s) {
  PoActionStatus.sent => PoNotice.sent,
  PoActionStatus.queued => PoNotice.queued,
  PoActionStatus.rejected => PoNotice.rejected,
};

/// Orders, overdue radar and dropshipments of the workspace, readable offline: the cached copy shows first, then the
/// server refreshes it.
@immutable
class PurchaseOrderHubState {
  const PurchaseOrderHubState({
    this.orders = const <PurchaseOrder>[],
    this.overdue = const <OverdueOrder>[],
    this.dropships = const <Dropship>[],
    this.pending = const <PoPendingAction>[],
    this.loading = false,
    this.fromCache = false,
    this.error,
  });

  final List<PurchaseOrder> orders;
  final List<OverdueOrder> overdue;
  final List<Dropship> dropships;
  final List<PoPendingAction> pending;
  final bool loading;

  /// The lists are the offline copy because the last refresh failed.
  final bool fromCache;
  final PoException? error;

  bool get forbidden => error?.kind == PoErrorKind.forbidden;

  /// Outbox rows of one order or dropshipment, for the badge on its card.
  int pendingFor(String targetId) =>
      pending.where((PoPendingAction a) => a.targetId == targetId).length;

  /// Open orders past their due date. The server list is used when it is cached; otherwise (or for orders it has
  /// not listed yet) the dates of the cached orders decide, so the alerts also work offline.
  List<PurchaseOrder> overdueOrders(DateTime today) {
    final Set<String> fromServer = <String>{
      for (final OverdueOrder o in overdue) o.order.id,
    };
    return <PurchaseOrder>[
      for (final PurchaseOrder o in orders)
        if (fromServer.contains(o.id) || o.isOverdue(today)) o,
    ];
  }

  PurchaseOrderHubState copyWith({
    List<PurchaseOrder>? orders,
    List<OverdueOrder>? overdue,
    List<Dropship>? dropships,
    List<PoPendingAction>? pending,
    bool? loading,
    bool? fromCache,
    Object? error = _keep,
  }) => PurchaseOrderHubState(
    orders: orders ?? this.orders,
    overdue: overdue ?? this.overdue,
    dropships: dropships ?? this.dropships,
    pending: pending ?? this.pending,
    loading: loading ?? this.loading,
    fromCache: fromCache ?? this.fromCache,
    error: identical(error, _keep) ? this.error : error as PoException?,
  );

  static const Object _keep = Object();
}

class PurchaseOrderHubController extends Notifier<PurchaseOrderHubState> {
  late String? _tenantId;

  PurchaseOrderRepository get _repo =>
      ref.read(purchaseOrderRepositoryProvider);

  @override
  PurchaseOrderHubState build() {
    _tenantId = ref.watch(purchaseOrderTenantIdProvider);
    return const PurchaseOrderHubState();
  }

  /// Never throws.
  Future<void> load() async {
    final String? tenant = _tenantId;
    if (tenant == null) {
      return;
    }
    state = state.copyWith(loading: true, error: null);
    if (state.orders.isEmpty &&
        state.overdue.isEmpty &&
        state.dropships.isEmpty) {
      final List<PurchaseOrder> orders = await _repo.cachedOrders(tenant);
      final List<OverdueOrder> overdue = await _repo.cachedOverdue(tenant);
      final List<Dropship> dropships = await _repo.cachedDropships(tenant);
      state = state.copyWith(
        orders: orders,
        overdue: overdue,
        dropships: dropships,
        pending: await _repo.pendingActions(tenant),
        fromCache:
            orders.isNotEmpty || overdue.isNotEmpty || dropships.isNotEmpty,
      );
    }
    try {
      // Queued writes go out first, so the refreshed lists already reflect them.
      await _repo.flush(tenant);
    } catch (_) {
      // Still offline: they stay queued.
    }

    PoException? failure;
    bool anyFresh = false;
    try {
      state = state.copyWith(orders: await _repo.refreshOrders(tenant));
      anyFresh = true;
    } on PoException catch (e) {
      failure = e;
    }
    try {
      state = state.copyWith(overdue: await _repo.refreshOverdue(tenant));
      anyFresh = true;
    } on PoException catch (e) {
      failure ??= e;
    }
    try {
      state = state.copyWith(dropships: await _repo.refreshDropships(tenant));
      anyFresh = true;
    } on PoException catch (e) {
      failure ??= e;
    }
    state = state.copyWith(
      loading: false,
      fromCache: failure != null && !anyFresh,
      error: failure,
      pending: await _repo.pendingActions(tenant),
    );
  }

  /// Sends the next reminder of an overdue order from the radar (works offline); the lists are re-read afterwards.
  /// Never throws.
  Future<PoActionOutcome> remind(String orderId) async {
    final String? tenant = _tenantId;
    if (tenant == null) {
      return const PoActionOutcome(PoActionStatus.rejected);
    }
    try {
      final PoActionOutcome out = await _repo.sendReminder(tenant, orderId);
      state = state.copyWith(
        orders: await _repo.cachedOrders(tenant),
        overdue: await _repo.cachedOverdue(tenant),
        pending: await _repo.pendingActions(tenant),
      );
      return out;
    } on PoException catch (e) {
      return PoActionOutcome(PoActionStatus.rejected, detail: e.detail);
    }
  }
}

final NotifierProvider<PurchaseOrderHubController, PurchaseOrderHubState>
purchaseOrderHubProvider =
    NotifierProvider<PurchaseOrderHubController, PurchaseOrderHubState>(
      PurchaseOrderHubController.new,
    );

/// One purchase order with its confirmations, reminders and the writes the buyer can start.
@immutable
class PurchaseOrderDetailState {
  const PurchaseOrderDetailState({
    this.orderId = '',
    this.order,
    this.confirmations = const <PoConfirmation>[],
    this.reminders = const <PoReminder>[],
    this.pending = const <PoPendingAction>[],
    this.loading = false,
    this.busy = false,
    this.error,
    this.notice,
    this.noticeDetail = '',
  });

  final String orderId;
  final PurchaseOrder? order;
  final List<PoConfirmation> confirmations;
  final List<PoReminder> reminders;
  final List<PoPendingAction> pending;
  final bool loading;
  final bool busy;
  final PoException? error;
  final PoNotice? notice;
  final String noticeDetail;

  bool pendingOf(PoActionKind kind) =>
      pending.any((PoPendingAction a) => a.kind == kind && !a.rejected);

  /// The supplier confirmation can be entered now.
  bool get canConfirm =>
      (order?.status.canConfirm ?? false) &&
      !pendingOf(PoActionKind.confirmation);

  /// A reminder makes sense for an open order that is late; one already waiting in the outbox blocks a second.
  bool canRemind(DateTime today) =>
      (order?.isOverdue(today) ?? false) && !pendingOf(PoActionKind.reminder);

  PurchaseOrderDetailState copyWith({
    PurchaseOrder? order,
    List<PoConfirmation>? confirmations,
    List<PoReminder>? reminders,
    List<PoPendingAction>? pending,
    bool? loading,
    bool? busy,
    Object? error = _keep,
    Object? notice = _keep,
    String? noticeDetail,
  }) => PurchaseOrderDetailState(
    orderId: orderId,
    order: order ?? this.order,
    confirmations: confirmations ?? this.confirmations,
    reminders: reminders ?? this.reminders,
    pending: pending ?? this.pending,
    loading: loading ?? this.loading,
    busy: busy ?? this.busy,
    error: identical(error, _keep) ? this.error : error as PoException?,
    notice: identical(notice, _keep) ? this.notice : notice as PoNotice?,
    noticeDetail: noticeDetail ?? this.noticeDetail,
  );

  static const Object _keep = Object();
}

class PurchaseOrderDetailController extends Notifier<PurchaseOrderDetailState> {
  late String? _tenantId;

  PurchaseOrderRepository get _repo =>
      ref.read(purchaseOrderRepositoryProvider);

  @override
  PurchaseOrderDetailState build() {
    _tenantId = ref.watch(purchaseOrderTenantIdProvider);
    return const PurchaseOrderDetailState();
  }

  /// Offline copy first, then the server. Never throws.
  Future<void> load(String orderId) async {
    final String? tenant = _tenantId;
    if (tenant == null) {
      return;
    }
    state = PurchaseOrderDetailState(orderId: orderId, loading: true);
    state = state.copyWith(
      order: await _repo.cachedOrder(tenant, orderId),
      confirmations: await _repo.cachedConfirmations(tenant, orderId),
      reminders: await _repo.cachedReminders(tenant, orderId),
      pending: await _pendingOf(tenant, orderId),
    );
    PoException? failure;
    try {
      await _repo.flush(tenant);
    } catch (_) {
      // Still offline.
    }
    try {
      state = state.copyWith(order: await _repo.refreshOrder(tenant, orderId));
      state = state.copyWith(
        confirmations: await _repo.refreshConfirmations(tenant, orderId),
        reminders: await _repo.refreshReminders(tenant, orderId),
      );
    } on PoException catch (e) {
      failure = e;
    }
    state = state.copyWith(
      loading: false,
      error: failure,
      pending: await _pendingOf(tenant, orderId),
    );
  }

  Future<List<PoPendingAction>> _pendingOf(String tenant, String id) async =>
      <PoPendingAction>[
        for (final PoPendingAction a in await _repo.pendingActions(tenant))
          if (a.targetId == id) a,
      ];

  /// Records the supplier confirmation (works offline). Returns the outcome; never throws.
  Future<PoActionOutcome?> confirm(ConfirmationInput input) async {
    final String? tenant = _tenantId;
    if (tenant == null || state.busy || !state.canConfirm) {
      return null;
    }
    return _write(
      tenant,
      () => _repo.confirmOrder(tenant, state.orderId, input),
    );
  }

  /// Sends the next reminder to the supplier (works offline).
  Future<PoActionOutcome?> remind() async {
    final String? tenant = _tenantId;
    if (tenant == null || state.busy) {
      return null;
    }
    return _write(tenant, () => _repo.sendReminder(tenant, state.orderId));
  }

  Future<PoActionOutcome?> _write(
    String tenant,
    Future<PoActionOutcome> Function() action,
  ) async {
    state = state.copyWith(busy: true, notice: null, error: null);
    try {
      final PoActionOutcome out = await action();
      state = state.copyWith(
        busy: false,
        order: await _repo.cachedOrder(tenant, state.orderId),
        pending: await _pendingOf(tenant, state.orderId),
        notice: _noticeOf(out.status),
        noticeDetail: out.detail,
      );
      return out;
    } on PoException catch (e) {
      state = state.copyWith(busy: false, error: e);
      return null;
    }
  }

  /// Retries or drops a refused write.
  Future<void> retry(String queueUuid) async {
    final String? tenant = _tenantId;
    if (tenant != null) {
      await _repo.retryAction(tenant, queueUuid);
      state = state.copyWith(pending: await _pendingOf(tenant, state.orderId));
    }
  }

  Future<void> dismiss(String queueUuid) async {
    final String? tenant = _tenantId;
    if (tenant != null) {
      await _repo.dismissAction(queueUuid);
      state = state.copyWith(pending: await _pendingOf(tenant, state.orderId));
    }
  }

  /// The page showed the notice.
  void clearNotice() => state = state.copyWith(notice: null, noticeDetail: '');
}

final NotifierProvider<PurchaseOrderDetailController, PurchaseOrderDetailState>
purchaseOrderDetailProvider =
    NotifierProvider<PurchaseOrderDetailController, PurchaseOrderDetailState>(
      PurchaseOrderDetailController.new,
    );

/// One dropshipment: recipient, DDT, proof of delivery and the order lines it carries.
@immutable
class DropshipDetailState {
  const DropshipDetailState({
    this.dropshipId = '',
    this.dropship,
    this.order,
    this.pending = const <PoPendingAction>[],
    this.loading = false,
    this.busy = false,
    this.error,
    this.notice,
    this.noticeDetail = '',
  });

  final String dropshipId;
  final Dropship? dropship;

  /// The purchase order the shipment belongs to (its lines drive the delivery form).
  final PurchaseOrder? order;
  final List<PoPendingAction> pending;
  final bool loading;
  final bool busy;
  final PoException? error;
  final PoNotice? notice;
  final String noticeDetail;

  bool get deliveryPending => pending.any(
    (PoPendingAction a) => a.kind == PoActionKind.delivery && !a.rejected,
  );

  bool get canRecordDelivery =>
      (dropship?.status.canRecordDelivery ?? false) && !deliveryPending;

  DropshipDetailState copyWith({
    Dropship? dropship,
    PurchaseOrder? order,
    List<PoPendingAction>? pending,
    bool? loading,
    bool? busy,
    Object? error = _keep,
    Object? notice = _keep,
    String? noticeDetail,
  }) => DropshipDetailState(
    dropshipId: dropshipId,
    dropship: dropship ?? this.dropship,
    order: order ?? this.order,
    pending: pending ?? this.pending,
    loading: loading ?? this.loading,
    busy: busy ?? this.busy,
    error: identical(error, _keep) ? this.error : error as PoException?,
    notice: identical(notice, _keep) ? this.notice : notice as PoNotice?,
    noticeDetail: noticeDetail ?? this.noticeDetail,
  );

  static const Object _keep = Object();
}

class DropshipDetailController extends Notifier<DropshipDetailState> {
  late String? _tenantId;

  PurchaseOrderRepository get _repo =>
      ref.read(purchaseOrderRepositoryProvider);

  @override
  DropshipDetailState build() {
    _tenantId = ref.watch(purchaseOrderTenantIdProvider);
    return const DropshipDetailState();
  }

  Future<List<PoPendingAction>> _pendingOf(String tenant, String id) async =>
      <PoPendingAction>[
        for (final PoPendingAction a in await _repo.pendingActions(tenant))
          if (a.targetId == id) a,
      ];

  /// Offline copy first, then the server. Never throws.
  Future<void> load(String dropshipId) async {
    final String? tenant = _tenantId;
    if (tenant == null) {
      return;
    }
    state = DropshipDetailState(dropshipId: dropshipId, loading: true);
    final Dropship? cached = await _repo.cachedDropship(tenant, dropshipId);
    state = state.copyWith(
      dropship: cached,
      order: cached == null
          ? null
          : await _repo.cachedOrder(tenant, cached.purchaseOrderId),
      pending: await _pendingOf(tenant, dropshipId),
    );
    PoException? failure;
    try {
      await _repo.flush(tenant);
    } catch (_) {
      // Still offline.
    }
    try {
      final Dropship fresh = await _repo.refreshDropship(tenant, dropshipId);
      state = state.copyWith(dropship: fresh);
      state = state.copyWith(
        order: await _repo.refreshOrder(tenant, fresh.purchaseOrderId),
      );
    } on PoException catch (e) {
      failure = e;
    }
    state = state.copyWith(
      loading: false,
      error: failure,
      pending: await _pendingOf(tenant, dropshipId),
    );
  }

  /// Records the supplier's delivery notice with its proof reference (works offline). Never throws.
  Future<PoActionOutcome?> recordDelivery(DeliveryInput input) async {
    final String? tenant = _tenantId;
    if (tenant == null || state.busy || !state.canRecordDelivery) {
      return null;
    }
    state = state.copyWith(busy: true, notice: null, error: null);
    try {
      final PoActionOutcome out = await _repo.recordDelivery(
        tenant,
        state.dropshipId,
        input,
      );
      state = state.copyWith(
        busy: false,
        dropship: await _repo.cachedDropship(tenant, state.dropshipId),
        pending: await _pendingOf(tenant, state.dropshipId),
        notice: _noticeOf(out.status),
        noticeDetail: out.detail,
      );
      return out;
    } on PoException catch (e) {
      state = state.copyWith(busy: false, error: e);
      return null;
    }
  }

  Future<void> retry(String queueUuid) async {
    final String? tenant = _tenantId;
    if (tenant != null) {
      await _repo.retryAction(tenant, queueUuid);
      state = state.copyWith(
        pending: await _pendingOf(tenant, state.dropshipId),
      );
    }
  }

  Future<void> dismiss(String queueUuid) async {
    final String? tenant = _tenantId;
    if (tenant != null) {
      await _repo.dismissAction(queueUuid);
      state = state.copyWith(
        pending: await _pendingOf(tenant, state.dropshipId),
      );
    }
  }

  void clearNotice() => state = state.copyWith(notice: null, noticeDetail: '');
}

final NotifierProvider<DropshipDetailController, DropshipDetailState>
dropshipDetailProvider =
    NotifierProvider<DropshipDetailController, DropshipDetailState>(
      DropshipDetailController.new,
    );

/// The pricing preview of the line being entered; the server answer, or the offline estimate.
@immutable
class PricingPreviewState {
  const PricingPreviewState({this.preview, this.loading = false, this.error});

  final PricingPreview? preview;
  final bool loading;
  final PoException? error;
}

class PricingPreviewController extends Notifier<PricingPreviewState> {
  PurchaseOrderRepository get _repo =>
      ref.read(purchaseOrderRepositoryProvider);

  @override
  PricingPreviewState build() => const PricingPreviewState();

  /// Never throws; a server refusal (invalid input) lands in [PricingPreviewState.error].
  Future<void> calculate(PricingInput input) async {
    state = const PricingPreviewState(loading: true);
    try {
      state = PricingPreviewState(preview: await _repo.pricingPreview(input));
    } on PoException catch (e) {
      state = PricingPreviewState(error: e);
    }
  }
}

final NotifierProvider<PricingPreviewController, PricingPreviewState>
pricingPreviewProvider =
    NotifierProvider<PricingPreviewController, PricingPreviewState>(
      PricingPreviewController.new,
    );
