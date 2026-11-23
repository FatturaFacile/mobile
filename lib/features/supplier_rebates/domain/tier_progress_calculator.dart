import 'rebate_decimal.dart';
import 'supplier_rebate_models.dart';

/// Pure arithmetic of the rebate scale, a port of the backend `RebateTierCalculator` so the progress screen works offline
/// from the cached tiers and the last known volume and agrees with the server to the cent.
///
/// Retroactive: the rate of the highest tier reached applies to the whole volume, plus the flat amount of that tier.
/// Incremental: every band of volume up to the next threshold earns the rate of its own tier, plus the flat amounts of all
/// the tiers reached. Volume below the first threshold earns nothing.
abstract final class TierProgressCalculator {
  /// The tiers in ascending threshold order (the input is never modified).
  static List<RebateTier> sorted(Iterable<RebateTier> tiers) =>
      List<RebateTier>.of(tiers)..sort(
        (RebateTier a, RebateTier b) => a.threshold.compareTo(b.threshold),
      );

  /// Rebate earned on [volume], rounded to two decimals half away from zero.
  static Dec rebateOn(List<RebateTier> tiers, Dec volume, TierMode mode) {
    if (!volume.isPositive) {
      return Dec.zero;
    }
    final List<RebateTier> reached = <RebateTier>[
      for (final RebateTier t in sorted(tiers))
        if (volume >= t.threshold) t,
    ];
    if (reached.isEmpty) {
      return Dec.zero;
    }
    if (mode == TierMode.retroactive) {
      final RebateTier top = reached.last;
      return (volume * top.ratePercent / Dec.hundred + top.flat).round2();
    }
    Dec total = Dec.zero;
    for (int i = 0; i < reached.length; i++) {
      final RebateTier tier = reached[i];
      final Dec upper = i + 1 < reached.length
          ? reached[i + 1].threshold
          : volume;
      final Dec band = upper - tier.threshold;
      total = total + band * tier.ratePercent / Dec.hundred + tier.flat;
    }
    return total.round2();
  }

  /// Rate of the highest tier reached, `null` below the first tier.
  static Dec? topRate(List<RebateTier> tiers, Dec volume) {
    if (!volume.isPositive) {
      return null;
    }
    Dec? rate;
    for (final RebateTier t in sorted(tiers)) {
      if (volume >= t.threshold) {
        rate = t.ratePercent;
      }
    }
    return rate;
  }

  /// Fixed target bonus: the whole bonus once the volume reaches the target.
  static Dec fixedBonusOn(Dec target, Dec bonus, Dec volume) =>
      volume >= target && volume.isPositive ? bonus.round2() : Dec.zero;

  /// Where [volume] stands on the scale: current and next tier, distance to the next, the rebate at that threshold
  /// and the extra rebate reaching it brings.
  static TierProgress progress(
    List<RebateTier> tiers,
    Dec volume,
    TierMode mode,
  ) {
    RebateTier? current;
    RebateTier? next;
    for (final RebateTier t in sorted(tiers)) {
      if (volume >= t.threshold && volume.isPositive) {
        current = t;
      } else {
        next ??= t;
      }
    }

    final Dec accrued = rebateOn(tiers, volume, mode);
    final Dec? distance = next == null
        ? null
        : (next.threshold - volume).round2();
    final Dec? projected = next == null
        ? null
        : rebateOn(tiers, next.threshold, mode);
    final Dec floor = current?.threshold ?? Dec.zero;
    final Dec span = next == null ? Dec.zero : next.threshold - floor;

    Dec percent;
    if (next == null) {
      percent = Dec.hundred;
    } else if (span.isPositive) {
      percent = ((volume - floor) * Dec.hundred / span).round2();
    } else {
      percent = Dec.zero;
    }
    if (percent.isNegative) {
      percent = Dec.zero;
    }

    return TierProgress(
      currentTier: current,
      nextTier: next,
      accruedRebate: accrued,
      distanceToNext: distance,
      progressPercent: percent,
      projectedRebateAtNext: projected,
      projectedGain: projected == null ? null : (projected - accrued).round2(),
    );
  }

  /// Progress of a fixed target bonus (the backend `bonusProgress`).
  static BonusProgress bonusProgress(Dec target, Dec bonus, Dec volume) {
    final bool reached = volume.isPositive && volume >= target;
    Dec percent = target.isPositive
        ? (volume * Dec.hundred / target).round2()
        : Dec.hundred;
    if (percent > Dec.hundred) {
      percent = Dec.hundred;
    } else if (percent.isNegative) {
      percent = Dec.zero;
    }
    return BonusProgress(
      target: target,
      bonus: bonus,
      reached: reached,
      distanceToTarget: reached ? Dec.zero : (target - volume).round2(),
      progressPercent: percent,
    );
  }

  /// The position of [agreement] for [volume], from its cached scale, as the progress screen shows it.
  static TierProgress? forAgreement(
    RebateAgreement agreement,
    Dec volume, {
    List<RebateTier> fallbackTiers = const <RebateTier>[],
  }) {
    if (!agreement.isTiered) {
      return null;
    }
    final List<RebateTier> tiers = agreement.tiers.isNotEmpty
        ? agreement.tiers
        : fallbackTiers;
    return progress(tiers, volume, agreement.tierMode);
  }

  /// The bonus position of a fixed-bonus [agreement], `null` for the other kinds.
  static BonusProgress? bonusForAgreement(
    RebateAgreement agreement,
    Dec volume,
  ) {
    if (!agreement.isFixedBonus) {
      return null;
    }
    return bonusProgress(
      agreement.fixedBonusTarget ?? Dec.zero,
      agreement.fixedBonusAmount ?? Dec.zero,
      volume,
    );
  }
}
