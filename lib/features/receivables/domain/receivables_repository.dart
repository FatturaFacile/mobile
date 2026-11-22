import 'dart:typed_data';

import 'receivables_models.dart';

/// Accounts receivable and credit management: read-through offline caches and an outbox for the bookings.
///
/// `cached*` read the device only and answer `null` (or an empty list) when nothing was loaded yet; `refresh*` ask the
/// server, store the answer and throw [ReceivablesException] when that fails. [currency] `null` is the company currency.
abstract interface class ReceivablesRepository {
  Future<ReceivablesDashboard?> cachedDashboard(
    String tenantId, {
    String? currency,
  });
  Future<ReceivablesDashboard> refreshDashboard(
    String tenantId, {
    String? currency,
  });

  /// Aging of all customers, or of [customerId] only.
  Future<AgingReport?> cachedAging(
    String tenantId, {
    String? customerId,
    String? currency,
  });
  Future<AgingReport> refreshAging(
    String tenantId, {
    String? customerId,
    String? currency,
  });

  Future<CreditPosition?> cachedCredit(String tenantId, String customerId);
  Future<CreditPosition> refreshCredit(String tenantId, String customerId);

  Future<RiskScore?> cachedRisk(String tenantId, String customerId);
  Future<RiskScore> refreshRisk(String tenantId, String customerId);

  Future<List<CreditLimit>> cachedCreditLimits(
    String tenantId,
    String customerId,
  );
  Future<List<CreditLimit>> refreshCreditLimits(
    String tenantId,
    String customerId,
  );

  Future<List<UnreconciledPayment>> cachedUnreconciled(
    String tenantId,
    String customerId,
  );
  Future<List<UnreconciledPayment>> refreshUnreconciled(
    String tenantId,
    String customerId,
  );

  Future<DsoResult?> cachedDso(
    String tenantId, {
    String? customerId,
    String? currency,
  });
  Future<DsoResult> refreshDso(
    String tenantId, {
    String? customerId,
    String? currency,
    int? periodDays,
  });

  Future<ProvisionReport?> cachedProvision(
    String tenantId, {
    String? customerId,
    String? currency,
  });
  Future<ProvisionReport> refreshProvision(
    String tenantId, {
    String? customerId,
    String? currency,
  });

  /// Cached open items of a customer, most overdue first.
  Future<List<ReceivableItem>> cachedItems(String tenantId, String customerId);
  Future<List<ReceivableItem>> refreshItems(
    String tenantId,
    String customerId, {
    String? currency,
  });

  Future<ReceivableItem?> cachedItem(String tenantId, String itemId);

  /// One item with its allocations.
  Future<ReceivableItem> refreshItem(String tenantId, String itemId);

  Future<CustomerStatement?> cachedStatement(
    String tenantId,
    String customerId, {
    String? currency,
  });
  Future<CustomerStatement> refreshStatement(
    String tenantId,
    String customerId, {
    DateTime? from,
    DateTime? to,
    String? currency,
  });

  /// The statement as a PDF or XLSX file. Online only.
  Future<Uint8List> downloadStatement(
    String customerId,
    StatementFormat format, {
    DateTime? from,
    DateTime? to,
    String? currency,
  });

  /// Books the [drafts] against their items. Offline the request is queued (replayed with the same idempotency key) and
  /// the cached items already show the new open amounts. An identical request still waiting adds nothing.
  Future<BookingOutcome> allocate(
    String tenantId,
    List<AllocationDraft> drafts,
  );

  /// Reverses an allocation of [itemId].
  Future<BookingOutcome> reverseAllocation(
    String tenantId,
    String itemId,
    String allocationId,
  );

  /// Marks the item disputed (with a [reason]) or lifts the dispute.
  Future<BookingOutcome> setDispute(
    String tenantId,
    String itemId, {
    required bool disputed,
    String? reason,
  });

  /// Bookings of [itemId] (or of every item when `null`) still in the outbox.
  Future<List<PendingBooking>> pendingActions(
    String tenantId, {
    String? itemId,
  });

  Future<void> retryAction(String tenantId, String queueUuid);
  Future<void> dismissAction(String queueUuid);

  /// Resends the outbox; returns the number of rows the server acknowledged.
  Future<int> flush(String tenantId);
}
