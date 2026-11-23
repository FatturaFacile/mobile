import 'dart:convert';

import 'package:fattura_facile/features/supplier_rebates/domain/supplier_rebate_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

/// Decodes what `toJson` produced the way the entity store does (through JSON text).
Map<String, dynamic> roundTrip(Map<String, dynamic> json) =>
    jsonDecode(jsonEncode(json)) as Map<String, dynamic>;

void main() {
  group('agreement', () {
    test('parses the endpoint payload with tiers and contributions', () {
      final RebateAgreement a = RebateAgreement.fromJson(
        agreementJson(
          contributions: <Map<String, dynamic>>[contributionJson()],
          supplierContractId: 'sc1',
        ),
      );

      expect(a.id, 'a1');
      expect(a.code, 'PFA-2027');
      expect(a.contactName, 'Alpina AG');
      expect(a.tierMode, TierMode.retroactive);
      expect(a.rebateType, RebateType.tieredVolume);
      expect(a.status, AgreementStatus.active);
      expect(a.currency, 'CHF');
      expect(a.startsOn, DateTime(2027));
      expect(a.endsOn, DateTime(2027, 12, 31));
      expect(a.supplierContractId, 'sc1');
      expect(a.accrualFrequency, 'quarterly');
      expect(a.version, 3);
      expect(a.openRebate!.toFixed2(), '1200.00');
      expect(a.tiers, hasLength(3));
      expect(a.tiers[1].flatAmount!.toFixed2(), '500.00');
      expect(a.tiers[0].flatAmount, isNull);
      expect(a.contributions.single.kind, 'marketing');
      expect(a.contributions.single.status, ContributionStatus.planned);
      expect(a.contributions.single.dueOn, DateTime(2027, 6, 30));
      expect(a.isTiered, isTrue);
    });

    test('survives a trip through JSON text unchanged', () {
      final RebateAgreement a = RebateAgreement.fromJson(
        agreementJson(contributions: <Map<String, dynamic>>[contributionJson()]),
      );

      final RebateAgreement b = RebateAgreement.fromJson(roundTrip(a.toJson()));

      expect(b.toJson(), a.toJson());
      expect(b.tiers, a.tiers);
      expect(b.startsOn, a.startsOn);
    });

    test('unknown or missing enum values fall back to safe defaults', () {
      final RebateAgreement a = RebateAgreement.fromJson(<String, dynamic>{
        'id': 'x',
        'tier_mode': 'weird',
        'rebate_type': 'weird',
        'status': 'weird',
      });

      expect(a.tierMode, TierMode.retroactive);
      expect(a.rebateType, RebateType.tieredVolume);
      expect(a.status, AgreementStatus.draft);
      expect(a.tiers, isEmpty);
      expect(a.version, 1);
    });

    test('copyWith replaces only what it is given', () {
      final RebateAgreement a = agreement();

      final RebateAgreement b = a.copyWith(status: AgreementStatus.closed, version: 9);

      expect(b.status, AgreementStatus.closed);
      expect(b.version, 9);
      expect(b.code, a.code);
      expect(b.tiers, a.tiers);
    });

    test('a fixed bonus agreement carries its target and amount', () {
      final RebateAgreement a = agreement(type: 'fixed_bonus');

      expect(a.isFixedBonus, isTrue);
      expect(a.fixedBonusTarget!.toFixed2(), '50000.00');
      expect(a.fixedBonusAmount!.toFixed2(), '2500.00');
    });
  });

  group('progress', () {
    test('parses the tier, contributions and scale of the endpoint', () {
      final AgreementProgress p = AgreementProgress.fromJson(progressJson());

      expect(p.qualifyingVolume.toFixed2(), '120000.00');
      expect(p.earnedRebate.toFixed2(), '2400.00');
      expect(p.accruedRebate.toFixed2(), '1200.00');
      expect(p.tier!.currentTier!.ratePercent.toFixed2(), '2.00');
      expect(p.tier!.distanceToNext!.toFixed2(), '130000.00');
      expect(p.tier!.projectedGain!.toFixed2(), '5600.00');
      expect(p.bonus, isNull);
      expect(p.contributions.planned.toFixed2(), '800.00');
      expect(p.tiers, hasLength(3));
      expect(p.tiers.first.maxThreshold!.toFixed2(), '250000.00');
      expect(p.tiers.last.maxThreshold, isNull);
      expect(p.asOf, DateTime(2027, 3, 31));
    });

    test('round trips through JSON text', () {
      final AgreementProgress p = AgreementProgress.fromJson(progressJson());

      final AgreementProgress q = AgreementProgress.fromJson(roundTrip(p.toJson()));

      expect(q.toJson(), p.toJson());
    });

    test('parses the bonus object', () {
      final AgreementProgress p = AgreementProgress.fromJson(<String, dynamic>{
        'qualifying_volume': '30000.00',
        'earned_rebate': '0.00',
        'accrued_rebate': '0.00',
        'settled_rebate': '0.00',
        'tier': null,
        'bonus': <String, dynamic>{
          'target': '50000.00',
          'bonus': '2500.00',
          'reached': false,
          'distance_to_target': '20000.00',
          'progress_percent': '60.00',
        },
      });

      expect(p.tier, isNull);
      expect(p.bonus!.reached, isFalse);
      expect(p.bonus!.distanceToTarget.toFixed2(), '20000.00');
      expect(p.contributions.planned.isZero, isTrue);
    });

    test('copyWith swaps the volume', () {
      final AgreementProgress p = AgreementProgress.fromJson(progressJson());

      expect(p.copyWith(qualifyingVolume: d('5')).qualifyingVolume, d('5'));
      expect(p.copyWith(qualifyingVolume: d('5')).tiers, hasLength(3));
    });
  });

  group('accrual runs', () {
    test('parse with their invoice lines and round trip', () {
      final AccrualRun r = AccrualRun.fromJson(runJson());

      expect(r.status, RunStatus.posted);
      expect(r.periodEnd, DateTime(2027, 3, 31));
      expect(r.deltaAmount.toFixed2(), '2400.00');
      expect(r.journalEntryId, isNull);
      expect(r.lines.single.invoiceNumber, 'INV-1');
      expect(r.lines.single.invoiceDate, DateTime(2027, 2, 10));
      expect(AccrualRun.fromJson(roundTrip(r.toJson())).toJson(), r.toJson());
    });
  });

  group('settlement proposals', () {
    test('parse the totals, mode, version and analytical lines', () {
      final SettlementProposal p = proposal(status: 'pending_approval');

      expect(p.status, ProposalStatus.pendingApproval);
      expect(p.executionMode, ExecutionMode.apSetOff);
      expect(p.amount.toFixed2(), '2400.00');
      expect(p.grossAmount.toFixed2(), '2594.40');
      expect(p.taxAmount.toFixed2(), '194.40');
      expect(p.taxRate.toFixed2(), '8.10');
      expect(p.version, 2);
      expect(p.agreementCode, 'PFA-2027');
      expect(p.lines, hasLength(2));
      expect(p.lines[1].type, ProposalLineType.creditNote);
      expect(p.lines[1].netAmount.toFixed2(), '-1000.00');
      expect(p.lines[1].rebateAmount.toFixed2(), '-20.00');
    });

    test('round trip through JSON text keeps everything', () {
      final SettlementProposal p = proposal(status: 'approved');

      final SettlementProposal q = SettlementProposal.fromJson(roundTrip(p.toJson()));

      expect(q.toJson(), p.toJson());
      expect(q.createdAt, p.createdAt);
    });

    test('a missing gross amount defaults to the net amount', () {
      final SettlementProposal p = SettlementProposal.fromJson(<String, dynamic>{
        'id': 'p',
        'amount': '10.00',
      });

      expect(p.grossAmount.toFixed2(), '10.00');
      expect(p.status, ProposalStatus.draft);
    });

    test('copyWith changes the status and keeps the lines', () {
      final SettlementProposal p = proposal();

      final SettlementProposal q = p.copyWith(status: ProposalStatus.approved, version: 3);

      expect(q.status, ProposalStatus.approved);
      expect(q.version, 3);
      expect(q.lines, hasLength(2));
    });

    test('sortProposals puts open ones first, then newest first', () {
      final List<SettlementProposal> sorted = sortProposals(<SettlementProposal>[
        SettlementProposal.fromJson(proposalJson(id: 'old-open', createdAt: '2027-01-01T00:00:00Z')),
        SettlementProposal.fromJson(proposalJson(id: 'settled', status: 'settled', createdAt: '2027-09-01T00:00:00Z')),
        SettlementProposal.fromJson(proposalJson(id: 'new-open', status: 'approved', createdAt: '2027-05-01T00:00:00Z')),
      ]);

      expect(sorted.map((SettlementProposal p) => p.id), <String>['new-open', 'old-open', 'settled']);
    });
  });

  group('workflow actions per status', () {
    Set<ProposalAction> allowed(ProposalStatus s) => <ProposalAction>{
      for (final ProposalAction a in ProposalAction.values)
        if (a.allowedIn(s)) a,
    };

    test('draft can be submitted or cancelled', () {
      expect(allowed(ProposalStatus.draft), <ProposalAction>{ProposalAction.submit, ProposalAction.cancel});
    });

    test('pending approval can be approved or cancelled', () {
      expect(allowed(ProposalStatus.pendingApproval), <ProposalAction>{ProposalAction.approve, ProposalAction.cancel});
    });

    test('approved can only be cancelled on the phone (execute is web/desktop)', () {
      expect(allowed(ProposalStatus.approved), <ProposalAction>{ProposalAction.cancel});
    });

    test('settled and cancelled offer nothing', () {
      expect(allowed(ProposalStatus.settled), isEmpty);
      expect(allowed(ProposalStatus.cancelled), isEmpty);
    });

    test('the path segment of an action parses back', () {
      expect(ProposalAction.fromWire('approve'), ProposalAction.approve);
      expect(ProposalAction.fromWire('execute'), isNull);
    });
  });

  group('blanket agreements', () {
    test('a contract list row accepts numbers sent as floats', () {
      final BlanketContract c = BlanketContract.fromJson(contractJson());

      expect(c.contractNumber, 'RV-2027-1');
      expect(c.ceiling.toFixed2(), '100000.00');
      expect(c.minimumSpend!.toFixed2(), '60000.00');
      expect(c.alertThresholdPercent.toFixed2(), '80.00');
      expect(c.startsAt, DateTime(2027));
      expect(BlanketContract.fromJson(roundTrip(c.toJson())).toJson(), c.toJson());
    });

    test('a balance parses meters, lines and alerts and round trips', () {
      final BlanketBalance b = BlanketBalance.fromJson(balanceJson());

      expect(b.hasCeiling, isTrue);
      expect(b.ceilingUsedPercent!.toFixed2(), '85.00');
      expect(b.remainingCeiling!.toFixed2(), '15000.00');
      expect(b.minimumReachedPercent!.toFixed2(), '141.67');
      expect(b.lines.single.remainingQuantity!.toFixed2(), '1200.00');
      expect(b.lines.single.committedQuantity!.toFixed2(), '8000.00');
      expect(b.alerts.single.code, BalanceAlertCode.ceilingNear);
      expect(b.alerts.single.isCritical, isFalse);
      expect(BlanketBalance.fromJson(roundTrip(b.toJson())).toJson(), b.toJson());
    });

    test('a critical alert and unknown alert codes', () {
      final Map<String, dynamic> json = balanceJson(exceeded: true);
      (json['alerts'] as List<dynamic>).add(<String, dynamic>{'code': 'from_the_future', 'severity': 'warning'});

      final BlanketBalance b = BlanketBalance.fromJson(json);

      expect(b.alerts, hasLength(1));
      expect(b.alerts.single.code, BalanceAlertCode.ceilingExceeded);
      expect(b.alerts.single.isCritical, isTrue);
      expect(b.remainingCeiling!.isNegative, isTrue);
    });

    test('a zero ceiling means there is none', () {
      final Map<String, dynamic> json = balanceJson()..['ceiling_amount'] = '0.00';

      expect(BlanketBalance.fromJson(json).hasCeiling, isFalse);
    });
  });
}
