import 'package:fattura_facile/features/supplier_rebates/domain/rebate_decimal.dart';
import 'package:fattura_facile/features/supplier_rebates/domain/supplier_rebate_models.dart';
import 'package:fattura_facile/features/supplier_rebates/domain/tier_progress_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

String fixed(Dec v) => v.toFixed2();

void main() {
  group('Dec', () {
    test('parses decimal strings, ints and doubles exactly', () {
      expect(Dec.parse('1250.50').toPlain(), '1250.50');
      expect(Dec.parse('-3').toPlain(), '-3.00');
      expect(Dec.parse('.5').toPlain(), '0.50');
      expect(Dec.parse(12).toPlain(), '12.00');
      expect(Dec.parse(12.5).toPlain(), '12.50');
      expect(Dec.parse(' 7.25 ').toPlain(), '7.25');
    });

    test('rejects what is not a number', () {
      expect(Dec.tryParse('abc'), isNull);
      expect(Dec.tryParse(''), isNull);
      expect(Dec.tryParse(null), isNull);
      expect(Dec.parse('x'), Dec.zero);
      expect(Dec.parse(null, d('5')), d('5'));
    });

    test('rounds half away from zero to two decimals', () {
      expect(fixed(d('10.005')), '10.01');
      expect(fixed(d('10.0049')), '10.00');
      expect(fixed(d('-10.005')), '-10.01');
      expect(fixed(d('-0.004')), '0.00');
      expect(fixed(d('2.675')), '2.68');
    });

    test('has no binary floating point error', () {
      expect((d('0.1') + d('0.2')).toPlain(), '0.30');
      expect((d('1.10') * d('3')).toPlain(), '3.30');
    });

    test('truncates quotients at ten decimals like bcdiv', () {
      expect((d('1') / d('3')).toPlain(), '0.3333333333');
      expect((d('2') / d('3')).toPlain(), '0.6666666666');
      expect((d('5') / Dec.zero), Dec.zero);
    });

    test('compares and orders', () {
      expect(d('2.5') > d('2.49'), isTrue);
      expect(d('2.50') == d('2.5'), isTrue);
      expect(Dec.max(d('1'), d('2')), d('2'));
      expect(Dec.min(d('1'), d('2')), d('1'));
      expect(d('-1').abs, d('1'));
    });
  });

  group('retroactive scale', () {
    final List<RebateTier> tiers = scale();

    test('volume below the first tier earns nothing and points at tier one', () {
      final TierProgress p = TierProgressCalculator.progress(
        tiers,
        d('50000'),
        TierMode.retroactive,
      );

      expect(p.currentTier, isNull);
      expect(p.belowFirstTier, isTrue);
      expect(p.nextTier!.threshold, d('100000'));
      expect(fixed(p.accruedRebate), '0.00');
      expect(fixed(p.distanceToNext!), '50000.00');
      expect(fixed(p.progressPercent), '50.00');
      expect(fixed(p.projectedRebateAtNext!), '2000.00');
      expect(fixed(p.projectedGain!), '2000.00');
    });

    test('zero volume is below every tier', () {
      final TierProgress p = TierProgressCalculator.progress(
        tiers,
        Dec.zero,
        TierMode.retroactive,
      );

      expect(p.currentTier, isNull);
      expect(fixed(p.accruedRebate), '0.00');
      expect(fixed(p.progressPercent), '0.00');
      expect(fixed(p.distanceToNext!), '100000.00');
    });

    test('the rate of the highest tier reached applies to the whole volume', () {
      final TierProgress p = TierProgressCalculator.progress(
        tiers,
        d('120000'),
        TierMode.retroactive,
      );

      expect(p.currentTier!.ratePercent, d('2'));
      expect(fixed(p.accruedRebate), '2400.00');
      expect(p.nextTier!.threshold, d('250000'));
      expect(fixed(p.distanceToNext!), '130000.00');
      expect(fixed(p.progressPercent), '13.33');
      // 250000 * 3% + 500 flat
      expect(fixed(p.projectedRebateAtNext!), '8000.00');
      expect(fixed(p.projectedGain!), '5600.00');
    });

    test('the flat amount of the highest tier is added once', () {
      final TierProgress p = TierProgressCalculator.progress(
        tiers,
        d('300000'),
        TierMode.retroactive,
      );

      // 300000 * 3% + 500
      expect(fixed(p.accruedRebate), '9500.00');
      expect(fixed(p.distanceToNext!), '200000.00');
      expect(fixed(p.progressPercent), '20.00');
      expect(fixed(p.projectedRebateAtNext!), '21000.00');
      expect(fixed(p.projectedGain!), '11500.00');
    });

    test('exactly on a threshold the tier is reached', () {
      final TierProgress p = TierProgressCalculator.progress(
        tiers,
        d('250000'),
        TierMode.retroactive,
      );

      expect(p.currentTier!.threshold, d('250000'));
      expect(fixed(p.accruedRebate), '8000.00');
      expect(fixed(p.progressPercent), '0.00');
    });

    test('the top tier has no next tier, distance or projection', () {
      final TierProgress p = TierProgressCalculator.progress(
        tiers,
        d('600000'),
        TierMode.retroactive,
      );

      expect(p.isTopTier, isTrue);
      expect(p.nextTier, isNull);
      expect(p.distanceToNext, isNull);
      expect(p.projectedRebateAtNext, isNull);
      expect(p.projectedGain, isNull);
      expect(fixed(p.progressPercent), '100.00');
      // 600000 * 4% + 1000
      expect(fixed(p.accruedRebate), '25000.00');
    });

    test('unsorted tiers are ordered by threshold', () {
      final List<RebateTier> shuffled = <RebateTier>[
        tiers[2],
        tiers[0],
        tiers[1],
      ];

      expect(
        fixed(TierProgressCalculator.rebateOn(shuffled, d('300000'), TierMode.retroactive)),
        '9500.00',
      );
      expect(tiers.first.threshold, d('100000'));
    });

    test('rounds the rebate half away from zero', () {
      final List<RebateTier> one = <RebateTier>[
        RebateTier(threshold: d('1000'), ratePercent: d('1')),
      ];

      expect(fixed(TierProgressCalculator.rebateOn(one, d('1000.50'), TierMode.retroactive)), '10.01');
      expect(fixed(TierProgressCalculator.rebateOn(one, d('1000.49'), TierMode.retroactive)), '10.00');
    });

    test('top rate is the rate of the highest tier reached', () {
      expect(TierProgressCalculator.topRate(tiers, d('50000')), isNull);
      expect(TierProgressCalculator.topRate(tiers, d('260000')), d('3'));
    });

    test('matches the figures the server serves for the same volume', () {
      final TierProgress server = AgreementProgress.fromJson(progressJson()).tier!;
      final TierProgress local = TierProgressCalculator.progress(
        agreement().tiers,
        d('120000.00'),
        TierMode.retroactive,
      );

      expect(local.accruedRebate, server.accruedRebate);
      expect(local.distanceToNext, server.distanceToNext);
      expect(local.progressPercent, server.progressPercent);
      expect(local.projectedRebateAtNext, server.projectedRebateAtNext);
      expect(local.projectedGain, server.projectedGain);
      expect(local.currentTier, server.currentTier);
      expect(local.nextTier, server.nextTier);
    });
  });

  group('incremental scale', () {
    final List<RebateTier> tiers = scale();

    test('only the excess over the first threshold earns the first rate', () {
      final TierProgress p = TierProgressCalculator.progress(
        tiers,
        d('120000'),
        TierMode.incremental,
      );

      // (120000 - 100000) * 2%
      expect(fixed(p.accruedRebate), '400.00');
      // At 250000: 150000 * 2% plus the 500 flat of tier two.
      expect(fixed(p.projectedRebateAtNext!), '3500.00');
      expect(fixed(p.projectedGain!), '3100.00');
    });

    test('each band earns its own rate and the flats of all tiers reached add up', () {
      expect(
        fixed(TierProgressCalculator.rebateOn(tiers, d('300000'), TierMode.incremental)),
        // 150000 * 2% + (50000 * 3% + 500)
        '5000.00',
      );
      expect(
        fixed(TierProgressCalculator.rebateOn(tiers, d('600000'), TierMode.incremental)),
        // 150000 * 2% + (250000 * 3% + 500) + (100000 * 4% + 1000)
        '16000.00',
      );
    });

    test('below the first tier earns nothing', () {
      expect(
        fixed(TierProgressCalculator.rebateOn(tiers, d('99999.99'), TierMode.incremental)),
        '0.00',
      );
    });

    test('the incremental top tier has no next tier', () {
      final TierProgress p = TierProgressCalculator.progress(
        tiers,
        d('600000'),
        TierMode.incremental,
      );

      expect(p.isTopTier, isTrue);
      expect(fixed(p.accruedRebate), '16000.00');
      expect(p.projectedGain, isNull);
    });
  });

  group('fixed bonus', () {
    final Dec target = d('50000');
    final Dec bonus = d('2500');

    test('is earned once the volume reaches the target', () {
      expect(fixed(TierProgressCalculator.fixedBonusOn(target, bonus, d('49999.99'))), '0.00');
      expect(fixed(TierProgressCalculator.fixedBonusOn(target, bonus, d('50000'))), '2500.00');
      expect(fixed(TierProgressCalculator.fixedBonusOn(target, bonus, d('90000'))), '2500.00');
    });

    test('shows distance and progress below the target', () {
      final BonusProgress p = TierProgressCalculator.bonusProgress(target, bonus, d('30000'));

      expect(p.reached, isFalse);
      expect(fixed(p.distanceToTarget), '20000.00');
      expect(fixed(p.progressPercent), '60.00');
    });

    test('reaching the target clears the distance and caps the progress', () {
      final BonusProgress at = TierProgressCalculator.bonusProgress(target, bonus, d('50000'));
      final BonusProgress over = TierProgressCalculator.bonusProgress(target, bonus, d('70000'));

      expect(at.reached, isTrue);
      expect(fixed(at.distanceToTarget), '0.00');
      expect(fixed(at.progressPercent), '100.00');
      expect(over.reached, isTrue);
      expect(fixed(over.progressPercent), '100.00');
    });

    test('zero volume never reaches a target', () {
      final BonusProgress p = TierProgressCalculator.bonusProgress(target, bonus, Dec.zero);

      expect(p.reached, isFalse);
      expect(fixed(p.progressPercent), '0.00');
    });

    test('a zero target counts as complete', () {
      final BonusProgress p = TierProgressCalculator.bonusProgress(Dec.zero, bonus, Dec.zero);

      expect(fixed(p.progressPercent), '100.00');
    });
  });

  group('forAgreement', () {
    test('uses the scale and the mode of a tiered agreement', () {
      final TierProgress p = TierProgressCalculator.forAgreement(
        agreement(mode: 'incremental'),
        d('300000'),
      )!;

      expect(fixed(p.accruedRebate), '5000.00');
    });

    test('has no tier progress for a fixed bonus, and no bonus for a tiered agreement', () {
      final RebateAgreement bonus = agreement(type: 'fixed_bonus');

      expect(TierProgressCalculator.forAgreement(bonus, d('1')), isNull);
      expect(fixed(TierProgressCalculator.bonusForAgreement(bonus, d('30000'))!.distanceToTarget), '20000.00');
      expect(TierProgressCalculator.bonusForAgreement(agreement(), d('1')), isNull);
    });

    test('falls back to the scale of the progress payload when the agreement has none', () {
      final RebateAgreement bare = RebateAgreement.fromJson(
        agreementJson(tiers: <Map<String, dynamic>>[]),
      );
      final AgreementProgress progress = AgreementProgress.fromJson(progressJson());

      final TierProgress p = TierProgressCalculator.forAgreement(
        bare,
        d('120000'),
        fallbackTiers: <RebateTier>[for (final TierBand b in progress.tiers) b.tier],
      )!;

      expect(fixed(p.accruedRebate), '2400.00');
    });
  });
}
