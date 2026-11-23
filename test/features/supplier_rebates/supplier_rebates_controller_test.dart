import 'package:fattura_facile/features/supplier_rebates/domain/supplier_rebate_models.dart';
import 'package:fattura_facile/features/supplier_rebates/presentation/supplier_rebates_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';
import 'fixtures.dart';

void main() {
  late FakeSupplierRebatesRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = FakeSupplierRebatesRepository()
      ..remoteAgreements = <RebateAgreement>[agreement()]
      ..remoteProgress = AgreementProgress.fromJson(progressJson())
      ..remoteProposals = <SettlementProposal>[proposal()]
      ..remoteBalance = BlanketBalance.fromJson(balanceJson())
      ..contracts = <BlanketContract>[BlanketContract.fromJson(contractJson())]
      ..runs = <AccrualRun>[AccrualRun.fromJson(runJson())];
    container = ProviderContainer(
      overrides: [
        supplierRebatesRepositoryProvider.overrideWithValue(repo),
        supplierRebatesTenantIdProvider.overrideWithValue('t1'),
      ],
    );
  });

  tearDown(() => container.dispose());

  group('hub', () {
    test('load flushes the outbox first, then refreshes the three lists', () async {
      await container.read(supplierRebatesHubProvider.notifier).load();

      final SupplierRebatesHubState s = container.read(supplierRebatesHubProvider);
      expect(repo.flushes, 1);
      expect(s.agreements.single.id, 'a1');
      expect(s.proposals.single.id, 'p1');
      expect(s.contracts.single.id, 'sc1');
      expect(s.fromCache, isFalse);
      expect(s.loading, isFalse);
      expect(s.error, isNull);
    });

    test('offline keeps the cached copy and flags it', () async {
      repo
        ..cacheAgreements = <RebateAgreement>[agreement()]
        ..cacheProposals = <SettlementProposal>[proposal()]
        ..refreshError = const RebateException(RebateErrorKind.offline);

      await container.read(supplierRebatesHubProvider.notifier).load();

      final SupplierRebatesHubState s = container.read(supplierRebatesHubProvider);
      expect(s.agreements, hasLength(1));
      expect(s.proposals, hasLength(1));
      expect(s.fromCache, isTrue);
      expect(s.error!.kind, RebateErrorKind.offline);
    });

    test('a missing procurement right does not hide the rebates', () async {
      repo.contractsError = const RebateException(RebateErrorKind.forbidden);

      await container.read(supplierRebatesHubProvider.notifier).load();

      final SupplierRebatesHubState s = container.read(supplierRebatesHubProvider);
      expect(s.agreements, hasLength(1));
      expect(s.error, isNull);
      expect(s.fromCache, isFalse);
    });

    test('forbidden on the rebates is surfaced', () async {
      repo.refreshError = const RebateException(RebateErrorKind.forbidden);

      await container.read(supplierRebatesHubProvider.notifier).load();

      expect(container.read(supplierRebatesHubProvider).forbidden, isTrue);
    });

    test('counts the outbox rows of a proposal', () async {
      repo.pending = <PendingAction>[
        const PendingAction(
          queueUuid: 'q0',
          proposalId: 'p1',
          action: ProposalAction.approve,
          rejected: false,
        ),
      ];

      await container.read(supplierRebatesHubProvider.notifier).load();

      final SupplierRebatesHubState s = container.read(supplierRebatesHubProvider);
      expect(s.pendingFor('p1'), 1);
      expect(s.pendingFor('p2'), 0);
    });
  });

  group('agreement detail', () {
    test('loads the cached copy and the server data and computes the scale position', () async {
      await container.read(agreementDetailProvider.notifier).load('a1');

      final AgreementDetailState s = container.read(agreementDetailProvider);
      expect(s.agreement!.code, 'PFA-2027');
      expect(s.synced, isTrue);
      expect(s.runs, hasLength(1));
      expect(s.proposals, hasLength(1));
      expect(s.volume.toFixed2(), '120000.00');
      expect(s.tierProgress!.distanceToNext!.toFixed2(), '130000.00');
      expect(s.tierProgress!.projectedGain!.toFixed2(), '5600.00');
      expect(s.bonusProgress, isNull);
      expect(s.error, isNull);
    });

    test('offline it works from the cached tiers and the last known volume', () async {
      repo
        ..cacheAgreements = <RebateAgreement>[agreement()]
        ..cacheProgress = AgreementProgress.fromJson(progressJson(volume: '260000.00'))
        ..refreshError = const RebateException(RebateErrorKind.offline);

      await container.read(agreementDetailProvider.notifier).load('a1');

      final AgreementDetailState s = container.read(agreementDetailProvider);
      expect(s.synced, isFalse);
      expect(s.error!.kind, RebateErrorKind.offline);
      expect(s.volume.toFixed2(), '260000.00');
      // Recomputed on the phone: tier two (3% + 500 flat) and 240000 to go to tier three.
      expect(s.tierProgress!.currentTier!.threshold.toFixed2(), '250000.00');
      expect(s.tierProgress!.accruedRebate.toFixed2(), '8300.00');
      expect(s.tierProgress!.distanceToNext!.toFixed2(), '240000.00');
    });

    test('a fixed bonus agreement exposes the bonus progress', () async {
      repo
        ..remoteAgreements = <RebateAgreement>[agreement(type: 'fixed_bonus')]
        ..remoteProgress = AgreementProgress.fromJson(progressJson(volume: '30000.00'));

      await container.read(agreementDetailProvider.notifier).load('a1');

      final AgreementDetailState s = container.read(agreementDetailProvider);
      expect(s.tierProgress, isNull);
      expect(s.bonusProgress!.reached, isFalse);
      expect(s.bonusProgress!.distanceToTarget.toFixed2(), '20000.00');
    });
  });

  group('proposal detail', () {
    setUp(() {
      repo.remoteProposals = <SettlementProposal>[proposal(status: 'pending_approval')];
    });

    test('online approval is sent with the proposal version and the proposal is refreshed', () async {
      repo.statusAfterAction = ProposalStatus.approved;
      final ProposalDetailController ctrl = container.read(proposalDetailProvider.notifier);
      await ctrl.load('p1');

      await ctrl.act(ProposalAction.approve);

      expect(repo.acted.single.action, ProposalAction.approve);
      expect(repo.acted.single.version, 2);
      final ProposalDetailState s = container.read(proposalDetailProvider);
      expect(s.proposal!.status, ProposalStatus.approved);
      expect(s.notice, RebateNotice.sent);
      expect(s.busy, isFalse);
    });

    test('offline the action is queued, the buttons lock and the status stays as seen', () async {
      repo.nextStatus = ActionStatus.queued;
      final ProposalDetailController ctrl = container.read(proposalDetailProvider.notifier);
      await ctrl.load('p1');

      await ctrl.act(ProposalAction.approve);

      final ProposalDetailState s = container.read(proposalDetailProvider);
      expect(s.notice, RebateNotice.queued);
      expect(s.proposal!.status, ProposalStatus.pendingApproval);
      expect(s.actionPending(ProposalAction.approve), isTrue);
      expect(s.hasPending, isTrue);

      // A second, conflicting action is not started while one is waiting.
      await ctrl.act(ProposalAction.cancel);
      expect(repo.acted, hasLength(1));
    });

    test('a refused action reports the server detail', () async {
      repo
        ..nextStatus = ActionStatus.rejected
        ..nextDetail = 'Version conflict';
      final ProposalDetailController ctrl = container.read(proposalDetailProvider.notifier);
      await ctrl.load('p1');

      await ctrl.act(ProposalAction.approve);

      final ProposalDetailState s = container.read(proposalDetailProvider);
      expect(s.notice, RebateNotice.rejected);
      expect(s.noticeDetail, 'Version conflict');
    });

    test('an action that does not fit the status is ignored', () async {
      final ProposalDetailController ctrl = container.read(proposalDetailProvider.notifier);
      await ctrl.load('p1');

      await ctrl.act(ProposalAction.submit);

      expect(repo.acted, isEmpty);
    });

    test('the available actions follow the status', () async {
      final ProposalDetailController ctrl = container.read(proposalDetailProvider.notifier);
      await ctrl.load('p1');

      expect(container.read(proposalDetailProvider).availableActions, <ProposalAction>[
        ProposalAction.approve,
        ProposalAction.cancel,
      ]);
    });

    test('dismissing a rejected action drops it from the list', () async {
      repo.pending = <PendingAction>[
        const PendingAction(
          queueUuid: 'q0',
          proposalId: 'p1',
          action: ProposalAction.approve,
          rejected: true,
          detail: 'No',
        ),
      ];
      final ProposalDetailController ctrl = container.read(proposalDetailProvider.notifier);
      await ctrl.load('p1');
      expect(container.read(proposalDetailProvider).hasPending, isFalse);

      await ctrl.dismiss('q0');

      expect(repo.dismissed, <String>['q0']);
      expect(container.read(proposalDetailProvider).pending, isEmpty);
    });

    test('offline load shows the cached proposal', () async {
      repo
        ..cacheProposals = <SettlementProposal>[proposal(status: 'approved')]
        ..refreshError = const RebateException(RebateErrorKind.offline);

      await container.read(proposalDetailProvider.notifier).load('p1');

      final ProposalDetailState s = container.read(proposalDetailProvider);
      expect(s.proposal!.status, ProposalStatus.approved);
      expect(s.error!.kind, RebateErrorKind.offline);
    });
  });

  group('blanket balance', () {
    test('loads the contract from the cache and the balance from the server', () async {
      await container.read(blanketBalanceProvider.notifier).load('sc1');

      final BlanketBalanceState s = container.read(blanketBalanceProvider);
      expect(s.contract!.contractNumber, 'RV-2027-1');
      expect(s.balance!.alerts.single.code, BalanceAlertCode.ceilingNear);
      expect(s.error, isNull);
    });

    test('offline shows the cached balance', () async {
      repo
        ..cacheBalance = BlanketBalance.fromJson(balanceJson(exceeded: true))
        ..refreshError = const RebateException(RebateErrorKind.offline);

      await container.read(blanketBalanceProvider.notifier).load('sc1');

      final BlanketBalanceState s = container.read(blanketBalanceProvider);
      expect(s.balance!.alerts.single.code, BalanceAlertCode.ceilingExceeded);
      expect(s.error!.kind, RebateErrorKind.offline);
    });
  });
}
