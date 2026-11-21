/// One production execution log used as OEE input (`POST /manufacturing/oee/logs` payload).
class OeeLogInput {
  const OeeLogInput({
    this.plannedDowntimeMinutes = 0,
    this.unplannedDowntimeMinutes = 0,
    this.goodUnits = 0,
    this.scrapUnits = 0,
    this.reworkUnits = 0,
  });

  final double plannedDowntimeMinutes;
  final double unplannedDowntimeMinutes;
  final double goodUnits;
  final double scrapUnits;
  final double reworkUnits;
}

/// Availability x performance x quality of one period.
class OeeResult {
  const OeeResult({
    required this.scheduledMinutes,
    required this.plannedProductionMinutes,
    required this.unplannedDowntimeMinutes,
    required this.operatingMinutes,
    required this.goodUnits,
    required this.scrapUnits,
    required this.reworkUnits,
    required this.totalUnits,
    required this.availability,
    required this.performance,
    required this.quality,
    required this.oee,
  });

  final double scheduledMinutes;
  final double plannedProductionMinutes;
  final double unplannedDowntimeMinutes;
  final double operatingMinutes;
  final double goodUnits;
  final double scrapUnits;
  final double reworkUnits;
  final double totalUnits;

  /// Factors in 0..1.
  final double availability;
  final double performance;
  final double quality;
  final double oee;

  double get availabilityPercent => _round(availability * 100, 2);
  double get performancePercent => _round(performance * 100, 2);
  double get qualityPercent => _round(quality * 100, 2);
  double get oeePercent => _round(oee * 100, 2);
}

/// Pure-Dart mirror of the backend `OeeCalculator::metrics` (Mod 061).
///
/// Planned production time = scheduled minutes minus planned downtime; operating time = planned minus unplanned
/// downtime. Performance = processed units x ideal cycle time / operating time. Quality = good / (good + scrap +
/// rework). Every factor is clamped to 0..1. [scheduledMinutes] comes from the work-centre calendar (server side) or
/// the window length when the work centre has no calendar.
abstract final class OeeCalculator {
  static OeeResult calculate({
    required double scheduledMinutes,
    required double idealCycleMinutesPerUnit,
    required Iterable<OeeLogInput> logs,
  }) {
    double planned = 0;
    double unplanned = 0;
    double good = 0;
    double scrap = 0;
    double rework = 0;
    for (final OeeLogInput log in logs) {
      planned += log.plannedDowntimeMinutes;
      unplanned += log.unplannedDowntimeMinutes;
      good += log.goodUnits;
      scrap += log.scrapUnits;
      rework += log.reworkUnits;
    }
    final double plannedProduction = _max0(scheduledMinutes - planned);
    final double operating = _max0(plannedProduction - unplanned);
    final double processed = good + scrap + rework;

    final double availability = plannedProduction > 0
        ? _clamp(operating / plannedProduction)
        : 0;
    final double performance = operating > 0
        ? _clamp(processed * idealCycleMinutesPerUnit / operating)
        : 0;
    final double quality = processed > 0 ? _clamp(good / processed) : 1;

    return OeeResult(
      scheduledMinutes: _round(scheduledMinutes, 3),
      plannedProductionMinutes: _round(plannedProduction, 3),
      unplannedDowntimeMinutes: _round(unplanned, 3),
      operatingMinutes: _round(operating, 3),
      goodUnits: _round(good, 4),
      scrapUnits: _round(scrap, 4),
      reworkUnits: _round(rework, 4),
      totalUnits: _round(processed, 4),
      availability: _round(availability, 6),
      performance: _round(performance, 6),
      quality: _round(quality, 6),
      oee: _round(availability * performance * quality, 6),
    );
  }

  /// Ideal cycle minutes per unit: the machine's, else the mean of the work-centre machines, else the mean routing run
  /// time per unit (same fallback order as the server).
  static double idealCycleMinutes({
    double? machineCycleSeconds,
    Iterable<double> workCenterMachineCycleSeconds = const <double>[],
    Iterable<double> routingRunMinutesPerUnit = const <double>[],
    bool machineScope = false,
  }) {
    if (machineCycleSeconds != null && machineCycleSeconds > 0) {
      return machineCycleSeconds / 60;
    }
    if (!machineScope) {
      final List<double> cycles = workCenterMachineCycleSeconds
          .where((double c) => c > 0)
          .toList();
      if (cycles.isNotEmpty) {
        return cycles.reduce((double a, double b) => a + b) /
            cycles.length /
            60;
      }
    }
    final List<double> runs = routingRunMinutesPerUnit
        .where((double r) => r > 0)
        .toList();
    return runs.isEmpty
        ? 0
        : runs.reduce((double a, double b) => a + b) / runs.length;
  }

  static double _clamp(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);
  static double _max0(double v) => v < 0 ? 0 : v;
}

double _round(double v, int digits) {
  double factor = 1;
  for (int i = 0; i < digits; i++) {
    factor *= 10;
  }
  return (v * factor).roundToDouble() / factor;
}
