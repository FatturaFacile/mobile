import 'purchase_order_models.dart';

/// Offline-first access to the purchase order workspace of Mod 046. `cached*` reads only the local store (never
/// throws); `refresh*` pulls from the server, replaces the copy and throws [PoException] when the call fails.
abstract interface class PurchaseOrderRepository {
  Future<List<PurchaseOrder>> cachedOrders(String tenantId);

  Future<List<PurchaseOrder>> refreshOrders(String tenantId);

  Future<PurchaseOrder?> cachedOrder(String tenantId, String id);

  Future<PurchaseOrder> refreshOrder(String tenantId, String id);

  Future<List<OverdueOrder>> cachedOverdue(String tenantId);

  Future<List<OverdueOrder>> refreshOverdue(String tenantId);

  Future<List<PoConfirmation>> cachedConfirmations(
    String tenantId,
    String orderId,
  );

  Future<List<PoConfirmation>> refreshConfirmations(
    String tenantId,
    String orderId,
  );

  Future<List<PoReminder>> cachedReminders(String tenantId, String orderId);

  Future<List<PoReminder>> refreshReminders(String tenantId, String orderId);

  Future<List<Dropship>> cachedDropships(String tenantId);

  Future<List<Dropship>> refreshDropships(String tenantId);

  Future<Dropship?> cachedDropship(String tenantId, String id);

  Future<Dropship> refreshDropship(String tenantId, String id);

  /// Records the supplier confirmation: the cached order turns `confirmed` at once and the request is queued, so it
  /// works without a network. A 422/403 parks the row as rejected.
  Future<PoActionOutcome> confirmOrder(
    String tenantId,
    String orderId,
    ConfirmationInput input,
  );

  /// Sends the next reminder level to the supplier of an overdue order.
  Future<PoActionOutcome> sendReminder(String tenantId, String orderId);

  /// Records the delivery notice of a dropshipment with its proof reference.
  Future<PoActionOutcome> recordDelivery(
    String tenantId,
    String dropshipId,
    DeliveryInput input,
  );

  /// Server preview of a line price; falls back to the offline estimate ([PricingPreview.estimated]) when unreachable.
  Future<PricingPreview> pricingPreview(PricingInput input);

  Future<List<PoPendingAction>> pendingActions(String tenantId);

  Future<void> retryAction(String tenantId, String queueUuid);

  Future<void> dismissAction(String queueUuid);

  /// Sends the outbox now; returns how many requests the server accepted.
  Future<int> flush(String tenantId);
}
