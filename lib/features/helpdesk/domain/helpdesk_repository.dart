import 'helpdesk_models.dart';

/// Operator ticket queue: read-through offline caches and an outbox for time logging and escalations.
abstract interface class HelpdeskRepository {
  /// The offline copy of the queue, already sorted ([sortQueue]).
  Future<List<QueueTicket>> cachedQueue(String tenantId);

  /// Open tickets merged with the breach-risk rows, stored for offline reading.
  Future<List<QueueTicket>> refreshQueue(
    String tenantId, {
    int riskPercent = 75,
    int limit = 100,
  });

  /// One ticket of the offline copy, `null` when it was never loaded.
  Future<QueueTicket?> cachedTicket(String tenantId, String ticketId);

  Future<CustomerContext?> cachedContext(String tenantId, String ticketId);
  Future<CustomerContext> refreshContext(String tenantId, String ticketId);

  Future<List<TimeEntry>> cachedTimeEntries(String tenantId, String ticketId);
  Future<List<TimeEntry>> refreshTimeEntries(String tenantId, String ticketId);

  /// Logs time on the ticket; offline it is queued and replayed with the same idempotency key.
  Future<ActionOutcome> logTime(
    String tenantId,
    String ticketId, {
    required int minutes,
    String? technicianId,
    String? description,
    bool isBillable = true,
  });

  /// One-tap escalation to field service or RMA. A second tap while one is still queued adds nothing.
  Future<ActionOutcome> escalate(
    String tenantId,
    String ticketId,
    EscalationTarget target,
  );

  /// Actions of [ticketId] (or of every ticket when `null`) still in the outbox.
  Future<List<PendingAction>> pendingActions(
    String tenantId, {
    String? ticketId,
  });

  Future<void> retryAction(String tenantId, String queueUuid);
  Future<void> dismissAction(String queueUuid);

  /// Resends the outbox; returns the number of rows the server acknowledged.
  Future<int> flush(String tenantId);
}
