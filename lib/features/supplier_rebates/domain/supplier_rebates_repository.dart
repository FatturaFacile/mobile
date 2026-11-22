import 'supplier_rebate_models.dart';

/// Supplier rebates (premi fornitori) and blanket agreements: read-through offline caches and an outbox for the settlement
/// workflow actions. Every `cached*` read is local and never throws; every `refresh*` pulls from the server, stores the
/// answer for offline use and throws a [RebateException] when it fails.
abstract interface class SupplierRebatesRepository {
  /// Purchase agreements of the offline copy, newest first.
  Future<List<RebateAgreement>> cachedAgreements(String tenantId);

  Future<List<RebateAgreement>> refreshAgreements(String tenantId);

  Future<RebateAgreement?> cachedAgreement(String tenantId, String id);

  /// One agreement with its contributions.
  Future<RebateAgreement> refreshAgreement(String tenantId, String id);

  Future<AgreementProgress?> cachedProgress(String tenantId, String agreementId);

  Future<AgreementProgress> refreshProgress(String tenantId, String agreementId);

  Future<List<AccrualRun>> cachedRuns(String tenantId, String agreementId);

  Future<List<AccrualRun>> refreshRuns(String tenantId, String agreementId);

  /// Settlement proposals, optionally of one agreement, newest first.
  Future<List<SettlementProposal>> cachedProposals(
    String tenantId, {
    String? agreementId,
  });

  Future<List<SettlementProposal>> refreshProposals(
    String tenantId, {
    String? agreementId,
  });

  Future<SettlementProposal?> cachedProposal(String tenantId, String id);

  Future<SettlementProposal> refreshProposal(String tenantId, String id);

  Future<List<BlanketContract>> cachedContracts(String tenantId);

  Future<List<BlanketContract>> refreshContracts(String tenantId);

  Future<BlanketBalance?> cachedBalance(String tenantId, String contractId);

  Future<BlanketBalance> refreshBalance(String tenantId, String contractId);

  /// Submits, approves or cancels a proposal. Offline the action is queued and replayed with the same idempotency key;
  /// a second tap while the same action is still queued adds nothing. [version] is the proposal version the user saw.
  Future<ActionOutcome> act(
    String tenantId,
    String proposalId,
    ProposalAction action, {
    int? version,
  });

  /// Actions of [proposalId] (or of every proposal when `null`) still in the outbox.
  Future<List<PendingAction>> pendingActions(
    String tenantId, {
    String? proposalId,
  });

  Future<void> retryAction(String tenantId, String queueUuid);

  Future<void> dismissAction(String queueUuid);

  /// Resends the outbox; returns the number of rows the server acknowledged.
  Future<int> flush(String tenantId);
}
