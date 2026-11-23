import 'package:fattura_facile/features/supplier_rebates/domain/supplier_rebate_models.dart';
import 'package:fattura_facile/features/supplier_rebates/domain/supplier_rebates_repository.dart';

/// In-memory [SupplierRebatesRepository] with scriptable outcomes: the `cache*` fields are the offline copy, the
/// `remote*` ones what a refresh brings, and [refreshError] makes every refresh fail like a dead network.
class FakeSupplierRebatesRepository implements SupplierRebatesRepository {
  List<RebateAgreement> cacheAgreements = <RebateAgreement>[];
  List<RebateAgreement> remoteAgreements = <RebateAgreement>[];
  AgreementProgress? cacheProgress;
  AgreementProgress? remoteProgress;
  List<AccrualRun> runs = <AccrualRun>[];
  List<SettlementProposal> cacheProposals = <SettlementProposal>[];
  List<SettlementProposal> remoteProposals = <SettlementProposal>[];
  List<BlanketContract> contracts = <BlanketContract>[];
  BlanketBalance? cacheBalance;
  BlanketBalance? remoteBalance;

  RebateException? refreshError;
  RebateException? contractsError;

  /// What the next [act] answers; `queued` also adds an outbox row.
  ActionStatus nextStatus = ActionStatus.sent;
  String nextDetail = '';

  /// The status a proposal has on the server after a sent action.
  ProposalStatus? statusAfterAction;

  List<PendingAction> pending = <PendingAction>[];
  final List<({String proposalId, ProposalAction action, int? version})> acted =
      <({String proposalId, ProposalAction action, int? version})>[];
  final List<String> dismissed = <String>[];
  int flushes = 0;

  void _failIfOffline() {
    final RebateException? e = refreshError;
    if (e != null) {
      throw e;
    }
  }

  @override
  Future<List<RebateAgreement>> cachedAgreements(String tenantId) async =>
      cacheAgreements;

  @override
  Future<List<RebateAgreement>> refreshAgreements(String tenantId) async {
    _failIfOffline();
    cacheAgreements = remoteAgreements;
    return remoteAgreements;
  }

  @override
  Future<RebateAgreement?> cachedAgreement(String tenantId, String id) async {
    for (final RebateAgreement a in cacheAgreements) {
      if (a.id == id) {
        return a;
      }
    }
    return null;
  }

  @override
  Future<RebateAgreement> refreshAgreement(String tenantId, String id) async {
    _failIfOffline();
    return remoteAgreements.firstWhere((RebateAgreement a) => a.id == id);
  }

  @override
  Future<AgreementProgress?> cachedProgress(String t, String id) async =>
      cacheProgress;

  @override
  Future<AgreementProgress> refreshProgress(String t, String id) async {
    _failIfOffline();
    return remoteProgress!;
  }

  @override
  Future<List<AccrualRun>> cachedRuns(String t, String id) async => runs;

  @override
  Future<List<AccrualRun>> refreshRuns(String t, String id) async {
    _failIfOffline();
    return runs;
  }

  @override
  Future<List<SettlementProposal>> cachedProposals(
    String tenantId, {
    String? agreementId,
  }) async => <SettlementProposal>[
    for (final SettlementProposal p in cacheProposals)
      if (agreementId == null || p.agreementId == agreementId) p,
  ];

  @override
  Future<List<SettlementProposal>> refreshProposals(
    String tenantId, {
    String? agreementId,
  }) async {
    _failIfOffline();
    cacheProposals = remoteProposals;
    return <SettlementProposal>[
      for (final SettlementProposal p in remoteProposals)
        if (agreementId == null || p.agreementId == agreementId) p,
    ];
  }

  @override
  Future<SettlementProposal?> cachedProposal(String tenantId, String id) async {
    for (final SettlementProposal p in cacheProposals) {
      if (p.id == id) {
        return p;
      }
    }
    return null;
  }

  @override
  Future<SettlementProposal> refreshProposal(String tenantId, String id) async {
    _failIfOffline();
    final SettlementProposal p = remoteProposals.firstWhere(
      (SettlementProposal x) => x.id == id,
    );
    final ProposalStatus? after = statusAfterAction;
    return after == null ? p : p.copyWith(status: after);
  }

  @override
  Future<List<BlanketContract>> cachedContracts(String tenantId) async =>
      contracts;

  @override
  Future<List<BlanketContract>> refreshContracts(String tenantId) async {
    final RebateException? e = contractsError;
    if (e != null) {
      throw e;
    }
    _failIfOffline();
    return contracts;
  }

  @override
  Future<BlanketBalance?> cachedBalance(String t, String id) async =>
      cacheBalance;

  @override
  Future<BlanketBalance> refreshBalance(String t, String id) async {
    _failIfOffline();
    return remoteBalance!;
  }

  @override
  Future<ActionOutcome> act(
    String tenantId,
    String proposalId,
    ProposalAction action, {
    int? version,
  }) async {
    acted.add((proposalId: proposalId, action: action, version: version));
    if (nextStatus == ActionStatus.queued) {
      pending = <PendingAction>[
        ...pending,
        PendingAction(
          queueUuid: 'q${pending.length}',
          proposalId: proposalId,
          action: action,
          rejected: false,
        ),
      ];
    }
    return ActionOutcome(nextStatus, detail: nextDetail);
  }

  @override
  Future<List<PendingAction>> pendingActions(
    String tenantId, {
    String? proposalId,
  }) async => <PendingAction>[
    for (final PendingAction a in pending)
      if (proposalId == null || a.proposalId == proposalId) a,
  ];

  @override
  Future<void> retryAction(String tenantId, String queueUuid) async {}

  @override
  Future<void> dismissAction(String queueUuid) async {
    dismissed.add(queueUuid);
    pending = <PendingAction>[
      for (final PendingAction a in pending)
        if (a.queueUuid != queueUuid) a,
    ];
  }

  @override
  Future<int> flush(String tenantId) async {
    flushes++;
    return 0;
  }
}
