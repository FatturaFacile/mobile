import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../app/session_controller.dart';
import '../data/supplier_rebates_repository_impl.dart';
import '../domain/rebate_decimal.dart';
import '../domain/supplier_rebate_models.dart';
import '../domain/supplier_rebates_repository.dart';
import '../domain/tier_progress_calculator.dart';

final Provider<SupplierRebatesRepository> supplierRebatesRepositoryProvider =
    Provider<SupplierRebatesRepository>(
      (Ref ref) => SupplierRebatesRepositoryImpl(
        ref.watch(databaseProvider),
        ref.watch(dioProvider),
        ref.watch(syncEngineProvider),
      ),
    );

/// Active tenant of the signed-in session (`null` when signed out). Tests override it.
final Provider<String?> supplierRebatesTenantIdProvider = Provider<String?>((
  Ref ref,
) {
  final SessionState? s = ref.watch(sessionProvider).value;
  return s is SignedIn ? s.bootstrap.tenantId : null;
});

/// The three lists of the workspace, readable offline: the cached copy shows first, then the server refreshes it.
@immutable
class SupplierRebatesHubState {
  const SupplierRebatesHubState({
    this.agreements = const <RebateAgreement>[],
    this.proposals = const <SettlementProposal>[],
    this.contracts = const <BlanketContract>[],
    this.pending = const <PendingAction>[],
    this.loading = false,
    this.fromCache = false,
    this.error,
  });

  final List<RebateAgreement> agreements;
  final List<SettlementProposal> proposals;
  final List<BlanketContract> contracts;
  final List<PendingAction> pending;
  final bool loading;

  /// The lists are the offline copy because the last refresh failed.
  final bool fromCache;
  final RebateException? error;

  bool get forbidden => error?.kind == RebateErrorKind.forbidden;

  /// Outbox rows of one proposal, for the badge on its card.
  int pendingFor(String proposalId) =>
      pending.where((PendingAction a) => a.proposalId == proposalId).length;

  SupplierRebatesHubState copyWith({
    List<RebateAgreement>? agreements,
    List<SettlementProposal>? proposals,
    List<BlanketContract>? contracts,
    List<PendingAction>? pending,
    bool? loading,
    bool? fromCache,
    Object? error = _keep,
  }) => SupplierRebatesHubState(
    agreements: agreements ?? this.agreements,
    proposals: proposals ?? this.proposals,
    contracts: contracts ?? this.contracts,
    pending: pending ?? this.pending,
    loading: loading ?? this.loading,
    fromCache: fromCache ?? this.fromCache,
    error: identical(error, _keep) ? this.error : error as RebateException?,
  );

  static const Object _keep = Object();
}

class SupplierRebatesHubController extends Notifier<SupplierRebatesHubState> {
  late String? _tenantId;

  SupplierRebatesRepository get _repo =>
      ref.read(supplierRebatesRepositoryProvider);

  @override
  SupplierRebatesHubState build() {
    _tenantId = ref.watch(supplierRebatesTenantIdProvider);
    return const SupplierRebatesHubState();
  }

  /// Never throws.
  Future<void> load() async {
    final String? tenant = _tenantId;
    if (tenant == null) {
      return;
    }
    state = state.copyWith(loading: true, error: null);
    if (state.agreements.isEmpty &&
        state.proposals.isEmpty &&
        state.contracts.isEmpty) {
      final List<RebateAgreement> agreements = await _repo.cachedAgreements(
        tenant,
      );
      final List<SettlementProposal> proposals = await _repo.cachedProposals(
        tenant,
      );
      final List<BlanketContract> contracts = await _repo.cachedContracts(
        tenant,
      );
      state = state.copyWith(
        agreements: agreements,
        proposals: proposals,
        contracts: contracts,
        fromCache:
            agreements.isNotEmpty ||
            proposals.isNotEmpty ||
            contracts.isNotEmpty,
      );
    }
    try {
      // Queued approvals go out first, so the refreshed proposals already reflect them.
      await _repo.flush(tenant);
    } catch (_) {
      // Still offline: they stay queued.
    }

    RebateException? failure;
    bool anyFresh = false;
    try {
      state = state.copyWith(agreements: await _repo.refreshAgreements(tenant));
      anyFresh = true;
    } on RebateException catch (e) {
      failure = e;
    }
    try {
      state = state.copyWith(proposals: await _repo.refreshProposals(tenant));
      anyFresh = true;
    } on RebateException catch (e) {
      failure ??= e;
    }
    try {
      state = state.copyWith(contracts: await _repo.refreshContracts(tenant));
      anyFresh = true;
    } on RebateException catch (e) {
      // The blanket agreements belong to the procurement module, which the user may not have.
      if (e.kind != RebateErrorKind.forbidden) {
        failure ??= e;
      }
    }
    state = state.copyWith(
      loading: false,
      fromCache: failure != null && !anyFresh,
      error: failure,
      pending: await _repo.pendingActions(tenant),
    );
  }
}

final NotifierProvider<SupplierRebatesHubController, SupplierRebatesHubState>
supplierRebatesHubProvider =
    NotifierProvider<SupplierRebatesHubController, SupplierRebatesHubState>(
      SupplierRebatesHubController.new,
    );

/// One agreement: scale, live progress, contributions, accrual runs and its proposals.
@immutable
class AgreementDetailState {
  const AgreementDetailState({
    this.agreementId = '',
    this.agreement,
    this.progress,
    this.runs = const <AccrualRun>[],
    this.proposals = const <SettlementProposal>[],
    this.loading = false,
    this.synced = false,
    this.error,
  });

  final String agreementId;
  final RebateAgreement? agreement;
  final AgreementProgress? progress;
  final List<AccrualRun> runs;
  final List<SettlementProposal> proposals;
  final bool loading;

  /// The progress came from the server in this session (otherwise it is the cached volume).
  final bool synced;
  final RebateException? error;

  /// Last known qualifying volume.
  Dec get volume => progress?.qualifyingVolume ?? Dec.zero;

  /// The scale position, always computed by the calculator from the cached tiers and the last known volume, so the
  /// screen works offline and agrees with the server.
  TierProgress? get tierProgress {
    final RebateAgreement? a = agreement;
    return a == null
        ? null
        : TierProgressCalculator.forAgreement(
            a,
            volume,
            fallbackTiers: <RebateTier>[
              for (final TierBand b in progress?.tiers ?? const <TierBand>[])
                b.tier,
            ],
          );
  }

  BonusProgress? get bonusProgress {
    final RebateAgreement? a = agreement;
    return a == null ? null : TierProgressCalculator.bonusForAgreement(a, volume);
  }

  AgreementDetailState copyWith({
    RebateAgreement? agreement,
    AgreementProgress? progress,
    List<AccrualRun>? runs,
    List<SettlementProposal>? proposals,
    bool? loading,
    bool? synced,
    Object? error = _keep,
  }) => AgreementDetailState(
    agreementId: agreementId,
    agreement: agreement ?? this.agreement,
    progress: progress ?? this.progress,
    runs: runs ?? this.runs,
    proposals: proposals ?? this.proposals,
    loading: loading ?? this.loading,
    synced: synced ?? this.synced,
    error: identical(error, _keep) ? this.error : error as RebateException?,
  );

  static const Object _keep = Object();
}

class AgreementDetailController extends Notifier<AgreementDetailState> {
  late String? _tenantId;

  SupplierRebatesRepository get _repo =>
      ref.read(supplierRebatesRepositoryProvider);

  @override
  AgreementDetailState build() {
    _tenantId = ref.watch(supplierRebatesTenantIdProvider);
    return const AgreementDetailState();
  }

  /// Offline copy first, then the server. Never throws.
  Future<void> load(String agreementId) async {
    final String? tenant = _tenantId;
    if (tenant == null) {
      return;
    }
    state = AgreementDetailState(agreementId: agreementId, loading: true);
    state = state.copyWith(
      agreement: await _repo.cachedAgreement(tenant, agreementId),
      progress: await _repo.cachedProgress(tenant, agreementId),
      runs: await _repo.cachedRuns(tenant, agreementId),
      proposals: await _repo.cachedProposals(tenant, agreementId: agreementId),
    );
    RebateException? failure;
    try {
      state = state.copyWith(
        agreement: await _repo.refreshAgreement(tenant, agreementId),
      );
      state = state.copyWith(
        progress: await _repo.refreshProgress(tenant, agreementId),
        synced: true,
      );
    } on RebateException catch (e) {
      failure = e;
    }
    if (failure == null) {
      try {
        state = state.copyWith(runs: await _repo.refreshRuns(tenant, agreementId));
        state = state.copyWith(
          proposals: await _repo.refreshProposals(
            tenant,
            agreementId: agreementId,
          ),
        );
      } on RebateException catch (e) {
        failure = e;
      }
    }
    state = state.copyWith(loading: false, error: failure);
  }
}

final NotifierProvider<AgreementDetailController, AgreementDetailState>
agreementDetailProvider =
    NotifierProvider<AgreementDetailController, AgreementDetailState>(
      AgreementDetailController.new,
    );

/// A one-shot message after a workflow action, mapped to a localized snack by the page.
enum RebateNotice { sent, queued, rejected }

/// One settlement proposal with its workflow actions.
@immutable
class ProposalDetailState {
  const ProposalDetailState({
    this.proposalId = '',
    this.proposal,
    this.pending = const <PendingAction>[],
    this.loading = false,
    this.busy = false,
    this.error,
    this.notice,
    this.noticeDetail = '',
  });

  final String proposalId;
  final SettlementProposal? proposal;
  final List<PendingAction> pending;
  final bool loading;
  final bool busy;
  final RebateException? error;
  final RebateNotice? notice;
  final String noticeDetail;

  /// [action] is already waiting in the outbox (its button is then disabled).
  bool actionPending(ProposalAction action) => pending.any(
    (PendingAction a) => a.action == action && !a.rejected,
  );

  /// Any action of this proposal is waiting, so a second, conflicting one must not be started.
  bool get hasPending => pending.any((PendingAction a) => !a.rejected);

  /// The workflow buttons shown for the current status (execute stays on web and desktop).
  List<ProposalAction> get availableActions {
    final SettlementProposal? p = proposal;
    return p == null
        ? const <ProposalAction>[]
        : <ProposalAction>[
            for (final ProposalAction a in ProposalAction.values)
              if (a.allowedIn(p.status)) a,
          ];
  }

  ProposalDetailState copyWith({
    SettlementProposal? proposal,
    List<PendingAction>? pending,
    bool? loading,
    bool? busy,
    Object? error = _keep,
    Object? notice = _keep,
    String? noticeDetail,
  }) => ProposalDetailState(
    proposalId: proposalId,
    proposal: proposal ?? this.proposal,
    pending: pending ?? this.pending,
    loading: loading ?? this.loading,
    busy: busy ?? this.busy,
    error: identical(error, _keep) ? this.error : error as RebateException?,
    notice: identical(notice, _keep) ? this.notice : notice as RebateNotice?,
    noticeDetail: noticeDetail ?? this.noticeDetail,
  );

  static const Object _keep = Object();
}

class ProposalDetailController extends Notifier<ProposalDetailState> {
  late String? _tenantId;

  SupplierRebatesRepository get _repo =>
      ref.read(supplierRebatesRepositoryProvider);

  @override
  ProposalDetailState build() {
    _tenantId = ref.watch(supplierRebatesTenantIdProvider);
    return const ProposalDetailState();
  }

  /// Offline copy first, then the server. Never throws.
  Future<void> load(String proposalId) async {
    final String? tenant = _tenantId;
    if (tenant == null) {
      return;
    }
    state = ProposalDetailState(proposalId: proposalId, loading: true);
    state = state.copyWith(
      proposal: await _repo.cachedProposal(tenant, proposalId),
      pending: await _repo.pendingActions(tenant, proposalId: proposalId),
    );
    try {
      state = state.copyWith(
        proposal: await _repo.refreshProposal(tenant, proposalId),
      );
    } on RebateException catch (e) {
      state = state.copyWith(error: e);
    }
    state = state.copyWith(loading: false);
  }

  /// Submits, approves or cancels the proposal; offline the action waits in the outbox. Never throws.
  Future<void> act(ProposalAction action) async {
    final String? tenant = _tenantId;
    final SettlementProposal? proposal = state.proposal;
    if (tenant == null ||
        proposal == null ||
        state.busy ||
        state.hasPending ||
        !action.allowedIn(proposal.status)) {
      return;
    }
    state = state.copyWith(busy: true, notice: null, error: null);
    final ActionOutcome outcome = await _repo.act(
      tenant,
      proposal.id,
      action,
      version: proposal.version,
    );
    SettlementProposal? fresh;
    RebateException? failure;
    if (outcome.status == ActionStatus.sent) {
      try {
        fresh = await _repo.refreshProposal(tenant, proposal.id);
      } on RebateException catch (e) {
        // The action is done; the proposal refreshes on the next load.
        failure = e;
      }
    }
    state = state.copyWith(
      busy: false,
      proposal: fresh,
      notice: switch (outcome.status) {
        ActionStatus.sent => RebateNotice.sent,
        ActionStatus.queued => RebateNotice.queued,
        ActionStatus.rejected => RebateNotice.rejected,
      },
      noticeDetail: outcome.detail,
      error: failure,
      pending: await _repo.pendingActions(tenant, proposalId: proposal.id),
    );
  }

  Future<void> retry(String queueUuid) async {
    final String? tenant = _tenantId;
    if (tenant == null) {
      return;
    }
    await _repo.retryAction(tenant, queueUuid);
    state = state.copyWith(
      pending: await _repo.pendingActions(tenant, proposalId: state.proposalId),
    );
  }

  Future<void> dismiss(String queueUuid) async {
    final String? tenant = _tenantId;
    if (tenant == null) {
      return;
    }
    await _repo.dismissAction(queueUuid);
    state = state.copyWith(
      pending: await _repo.pendingActions(tenant, proposalId: state.proposalId),
    );
  }

  void clearNotice() => state = state.copyWith(notice: null);
}

final NotifierProvider<ProposalDetailController, ProposalDetailState>
proposalDetailProvider =
    NotifierProvider<ProposalDetailController, ProposalDetailState>(
      ProposalDetailController.new,
    );

/// Balance of one blanket agreement, usable offline from the last pull.
@immutable
class BlanketBalanceState {
  const BlanketBalanceState({
    this.contractId = '',
    this.contract,
    this.balance,
    this.loading = false,
    this.error,
  });

  final String contractId;
  final BlanketContract? contract;
  final BlanketBalance? balance;
  final bool loading;
  final RebateException? error;

  BlanketBalanceState copyWith({
    BlanketContract? contract,
    BlanketBalance? balance,
    bool? loading,
    Object? error = _keep,
  }) => BlanketBalanceState(
    contractId: contractId,
    contract: contract ?? this.contract,
    balance: balance ?? this.balance,
    loading: loading ?? this.loading,
    error: identical(error, _keep) ? this.error : error as RebateException?,
  );

  static const Object _keep = Object();
}

class BlanketBalanceController extends Notifier<BlanketBalanceState> {
  late String? _tenantId;

  SupplierRebatesRepository get _repo =>
      ref.read(supplierRebatesRepositoryProvider);

  @override
  BlanketBalanceState build() {
    _tenantId = ref.watch(supplierRebatesTenantIdProvider);
    return const BlanketBalanceState();
  }

  /// Offline copy first, then the server. Never throws.
  Future<void> load(String contractId) async {
    final String? tenant = _tenantId;
    if (tenant == null) {
      return;
    }
    state = BlanketBalanceState(contractId: contractId, loading: true);
    BlanketContract? contract;
    for (final BlanketContract c in await _repo.cachedContracts(tenant)) {
      if (c.id == contractId) {
        contract = c;
      }
    }
    state = state.copyWith(
      contract: contract,
      balance: await _repo.cachedBalance(tenant, contractId),
    );
    try {
      state = state.copyWith(
        balance: await _repo.refreshBalance(tenant, contractId),
      );
    } on RebateException catch (e) {
      state = state.copyWith(error: e);
    }
    state = state.copyWith(loading: false);
  }
}

final NotifierProvider<BlanketBalanceController, BlanketBalanceState>
blanketBalanceProvider =
    NotifierProvider<BlanketBalanceController, BlanketBalanceState>(
      BlanketBalanceController.new,
    );
