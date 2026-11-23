import 'package:fattura_facile/features/purchase_orders/domain/purchase_order_models.dart';
import 'package:fattura_facile/features/purchase_orders/domain/purchase_order_repository.dart';

/// In-memory [PurchaseOrderRepository] with scriptable outcomes: the `cache*` fields are the offline copy, the
/// `remote*` ones what a refresh brings, and [refreshError] makes every refresh fail like a dead network.
class FakePurchaseOrderRepository implements PurchaseOrderRepository {
  List<PurchaseOrder> cacheOrders = <PurchaseOrder>[];
  List<PurchaseOrder> remoteOrders = <PurchaseOrder>[];
  List<OverdueOrder> cacheOverdue = <OverdueOrder>[];
  List<OverdueOrder> remoteOverdue = <OverdueOrder>[];
  List<Dropship> cacheDropships = <Dropship>[];
  List<Dropship> remoteDropships = <Dropship>[];
  List<PoConfirmation> confirmations = <PoConfirmation>[];
  List<PoReminder> reminders = <PoReminder>[];

  PoException? refreshError;

  /// What the next write answers; `queued` also adds an outbox row.
  PoActionStatus nextStatus = PoActionStatus.sent;
  String nextDetail = '';

  List<PoPendingAction> pending = <PoPendingAction>[];
  final List<({String orderId, ConfirmationInput input})> confirmed =
      <({String orderId, ConfirmationInput input})>[];
  final List<String> reminded = <String>[];
  final List<({String dropshipId, DeliveryInput input})> delivered =
      <({String dropshipId, DeliveryInput input})>[];
  final List<PricingInput> priced = <PricingInput>[];
  final List<String> dismissed = <String>[];
  PoException? pricingError;
  int flushes = 0;

  void _failIfOffline() {
    final PoException? e = refreshError;
    if (e != null) {
      throw e;
    }
  }

  PoActionOutcome _outcome() => PoActionOutcome(nextStatus, detail: nextDetail);

  @override
  Future<List<PurchaseOrder>> cachedOrders(String tenantId) async =>
      cacheOrders;

  @override
  Future<List<PurchaseOrder>> refreshOrders(String tenantId) async {
    _failIfOffline();
    cacheOrders = remoteOrders;
    return remoteOrders;
  }

  @override
  Future<PurchaseOrder?> cachedOrder(String tenantId, String id) async {
    for (final PurchaseOrder o in cacheOrders) {
      if (o.id == id) {
        return o;
      }
    }
    return null;
  }

  @override
  Future<PurchaseOrder> refreshOrder(String tenantId, String id) async {
    _failIfOffline();
    final PurchaseOrder fresh = remoteOrders.firstWhere(
      (PurchaseOrder o) => o.id == id,
    );
    cacheOrders = <PurchaseOrder>[
      for (final PurchaseOrder o in cacheOrders)
        if (o.id != id) o,
      fresh,
    ];
    return fresh;
  }

  @override
  Future<List<OverdueOrder>> cachedOverdue(String tenantId) async =>
      cacheOverdue;

  @override
  Future<List<OverdueOrder>> refreshOverdue(String tenantId) async {
    _failIfOffline();
    cacheOverdue = remoteOverdue;
    return remoteOverdue;
  }

  @override
  Future<List<PoConfirmation>> cachedConfirmations(
    String tenantId,
    String orderId,
  ) async => confirmations;

  @override
  Future<List<PoConfirmation>> refreshConfirmations(
    String tenantId,
    String orderId,
  ) async {
    _failIfOffline();
    return confirmations;
  }

  @override
  Future<List<PoReminder>> cachedReminders(
    String tenantId,
    String orderId,
  ) async => reminders;

  @override
  Future<List<PoReminder>> refreshReminders(
    String tenantId,
    String orderId,
  ) async {
    _failIfOffline();
    return reminders;
  }

  @override
  Future<List<Dropship>> cachedDropships(String tenantId) async =>
      cacheDropships;

  @override
  Future<List<Dropship>> refreshDropships(String tenantId) async {
    _failIfOffline();
    cacheDropships = remoteDropships;
    return remoteDropships;
  }

  @override
  Future<Dropship?> cachedDropship(String tenantId, String id) async {
    for (final Dropship d in cacheDropships) {
      if (d.id == id) {
        return d;
      }
    }
    return null;
  }

  @override
  Future<Dropship> refreshDropship(String tenantId, String id) async {
    _failIfOffline();
    final Dropship fresh = remoteDropships.firstWhere(
      (Dropship d) => d.id == id,
    );
    cacheDropships = <Dropship>[
      for (final Dropship d in cacheDropships)
        if (d.id != id) d,
      fresh,
    ];
    return fresh;
  }

  @override
  Future<PoActionOutcome> confirmOrder(
    String tenantId,
    String orderId,
    ConfirmationInput input,
  ) async {
    confirmed.add((orderId: orderId, input: input));
    if (nextStatus != PoActionStatus.rejected) {
      cacheOrders = <PurchaseOrder>[
        for (final PurchaseOrder o in cacheOrders)
          if (o.id == orderId)
            o.copyWith(
              status: PoStatus.confirmed,
              rawStatus: 'confirmed',
              supplierConfirmationNumber: input.confirmationNumber,
            )
          else
            o,
      ];
    }
    if (nextStatus == PoActionStatus.queued) {
      pending = <PoPendingAction>[
        ...pending,
        PoPendingAction(
          queueUuid: 'q${pending.length + 1}',
          targetId: orderId,
          kind: PoActionKind.confirmation,
        ),
      ];
    }
    return _outcome();
  }

  @override
  Future<PoActionOutcome> sendReminder(String tenantId, String orderId) async {
    reminded.add(orderId);
    if (nextStatus == PoActionStatus.queued) {
      pending = <PoPendingAction>[
        ...pending,
        PoPendingAction(
          queueUuid: 'q${pending.length + 1}',
          targetId: orderId,
          kind: PoActionKind.reminder,
        ),
      ];
    }
    return _outcome();
  }

  @override
  Future<PoActionOutcome> recordDelivery(
    String tenantId,
    String dropshipId,
    DeliveryInput input,
  ) async {
    delivered.add((dropshipId: dropshipId, input: input));
    if (nextStatus == PoActionStatus.queued) {
      pending = <PoPendingAction>[
        ...pending,
        PoPendingAction(
          queueUuid: 'q${pending.length + 1}',
          targetId: dropshipId,
          kind: PoActionKind.delivery,
        ),
      ];
    }
    return _outcome();
  }

  @override
  Future<PricingPreview> pricingPreview(PricingInput input) async {
    priced.add(input);
    final PoException? e = pricingError;
    if (e != null) {
      throw e;
    }
    return PoPricing.preview(input);
  }

  @override
  Future<List<PoPendingAction>> pendingActions(String tenantId) async =>
      pending;

  @override
  Future<void> retryAction(String tenantId, String queueUuid) async {}

  @override
  Future<void> dismissAction(String queueUuid) async {
    dismissed.add(queueUuid);
    pending = <PoPendingAction>[
      for (final PoPendingAction a in pending)
        if (a.queueUuid != queueUuid) a,
    ];
  }

  @override
  Future<int> flush(String tenantId) async {
    flushes++;
    return 0;
  }
}
