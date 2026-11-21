import 'dart:math' as math;

/// The sliders of the what-if simulator. Percentages are whole numbers (5 means +5%).
class WhatIfScenario {
  const WhatIfScenario({
    this.pricePct = 0,
    this.cogsPct = 0,
    this.opexPct = 0,
    this.dsoDaysDelta = 0,
    this.fxShiftPct = 0,
    this.fteDelta = 0,
  });

  final double pricePct;
  final double cogsPct;
  final double opexPct;
  final double dsoDaysDelta;
  final double fxShiftPct;
  final double fteDelta;

  /// True when no slider moved.
  bool get isNeutral =>
      pricePct.abs() < 1e-9 &&
      cogsPct.abs() < 1e-9 &&
      opexPct.abs() < 1e-9 &&
      dsoDaysDelta.abs() < 1e-9 &&
      fxShiftPct.abs() < 1e-9 &&
      fteDelta.abs() < 1e-9;

  WhatIfScenario copyWith({
    double? pricePct,
    double? cogsPct,
    double? opexPct,
    double? dsoDaysDelta,
    double? fxShiftPct,
    double? fteDelta,
  }) => WhatIfScenario(
    pricePct: pricePct ?? this.pricePct,
    cogsPct: cogsPct ?? this.cogsPct,
    opexPct: opexPct ?? this.opexPct,
    dsoDaysDelta: dsoDaysDelta ?? this.dsoDaysDelta,
    fxShiftPct: fxShiftPct ?? this.fxShiftPct,
    fteDelta: fteDelta ?? this.fteDelta,
  );
}

/// The actuals a scenario is simulated on, in the reporting currency of the period.
class WhatIfBaseline {
  const WhatIfBaseline({
    required this.revenue,
    required this.cogs,
    required this.opex,
    required this.dsoDays,
    required this.netCashFlow,
    required this.periodDays,
    this.fteAnnualCost = 0,
    this.revenueFxShare = 0,
    this.costFxShare = 0,
  });

  final double revenue;
  final double cogs;
  final double opex;
  final double dsoDays;
  final double netCashFlow;
  final int periodDays;
  final double fteAnnualCost;
  final double revenueFxShare;
  final double costFxShare;
}

/// The figures of one side of a simulation.
class WhatIfFigures {
  const WhatIfFigures({
    required this.revenue,
    required this.cogs,
    required this.opex,
    required this.ebitda,
    required this.ebitdaMarginPct,
    required this.netCashFlow,
    this.breakEvenRevenue,
    this.breakEvenHeadroomPct,
  });

  final double revenue;
  final double cogs;
  final double opex;
  final double ebitda;
  final double ebitdaMarginPct;
  final double netCashFlow;

  /// Null while the contribution margin is not positive.
  final double? breakEvenRevenue;
  final double? breakEvenHeadroomPct;
}

class WhatIfDelta {
  const WhatIfDelta({
    required this.revenue,
    required this.ebitda,
    required this.ebitdaMarginPct,
    required this.netCashFlow,
    this.breakEvenRevenue,
  });

  final double revenue;
  final double ebitda;
  final double ebitdaMarginPct;
  final double netCashFlow;
  final double? breakEvenRevenue;
}

class WhatIfResult {
  const WhatIfResult({
    required this.baseline,
    required this.simulated,
    required this.delta,
  });

  final WhatIfFigures baseline;
  final WhatIfFigures simulated;
  final WhatIfDelta delta;
}

/// Rounds half away from zero, like PHP `round()` on the server.
double _round(double value, int decimals) {
  final double factor = math.pow(10, decimals).toDouble();
  return (value * factor).roundToDouble() / factor;
}

WhatIfFigures _figures(
  double revenue,
  double cogs,
  double opex,
  double ebitda,
  double netCash,
) {
  final double ratio = revenue > 0 ? (revenue - cogs) / revenue : 0;
  final double? breakEven = ratio > 0 ? opex / ratio : null;
  return WhatIfFigures(
    revenue: _round(revenue, 4),
    cogs: _round(cogs, 4),
    opex: _round(opex, 4),
    ebitda: _round(ebitda, 4),
    ebitdaMarginPct: revenue > 0 ? _round(ebitda / revenue * 100, 2) : 0,
    netCashFlow: _round(netCash, 4),
    breakEvenRevenue: breakEven == null ? null : _round(breakEven, 4),
    breakEvenHeadroomPct: breakEven != null && revenue > 0
        ? _round((revenue - breakEven) / revenue * 100, 2)
        : null,
  );
}

/// Offline what-if engine. It reproduces, formula by formula, the server side `WhatIfScenarioSimulator` of the web-api, so the
/// phone gives the same answer with or without a connection:
///
///     revenue'  = revenue  x (1 + price%)  x (1 + fx% x revenueFxShare)
///     cogs'     = cogs     x (1 + cogs%)   x (1 + fx% x costFxShare)
///     opex'     = (opex x (1 + opex%) + fteDelta x fteAnnualCost x periodDays / 365) x (1 + fx% x costFxShare)
///     EBITDA'   = revenue' - cogs' - opex'
///     netCash'  = netCash + (EBITDA' - EBITDA) - (receivables' - receivables), receivables = revenue x DSO / periodDays
///     breakEven = opex' / ((revenue' - cogs') / revenue')   (null while the contribution margin is not positive)
WhatIfResult simulateWhatIf(WhatIfBaseline baseline, WhatIfScenario scenario) {
  final int days = math.max(baseline.periodDays, 1);
  final double price = scenario.pricePct / 100;
  final double cogsPct = scenario.cogsPct / 100;
  final double opexPct = scenario.opexPct / 100;
  final double fx = scenario.fxShiftPct / 100;

  final double revenueSim =
      baseline.revenue * (1 + price) * (1 + fx * baseline.revenueFxShare);
  final double cogsSim =
      baseline.cogs * (1 + cogsPct) * (1 + fx * baseline.costFxShare);
  final double opexSim =
      (baseline.opex * (1 + opexPct) +
          scenario.fteDelta * baseline.fteAnnualCost * days / 365) *
      (1 + fx * baseline.costFxShare);

  final double ebitda = baseline.revenue - baseline.cogs - baseline.opex;
  final double ebitdaSim = revenueSim - cogsSim - opexSim;

  final double receivables = baseline.revenue * baseline.dsoDays / days;
  final double receivablesSim =
      revenueSim * math.max(baseline.dsoDays + scenario.dsoDaysDelta, 0) / days;
  final double netCashSim =
      baseline.netCashFlow +
      (ebitdaSim - ebitda) -
      (receivablesSim - receivables);

  final WhatIfFigures before = _figures(
    baseline.revenue,
    baseline.cogs,
    baseline.opex,
    ebitda,
    baseline.netCashFlow,
  );
  final WhatIfFigures after = _figures(
    revenueSim,
    cogsSim,
    opexSim,
    ebitdaSim,
    netCashSim,
  );

  final double? beforeBreakEven = before.breakEvenRevenue;
  final double? afterBreakEven = after.breakEvenRevenue;
  return WhatIfResult(
    baseline: before,
    simulated: after,
    delta: WhatIfDelta(
      revenue: _round(after.revenue - before.revenue, 4),
      ebitda: _round(after.ebitda - before.ebitda, 4),
      ebitdaMarginPct: _round(
        after.ebitdaMarginPct - before.ebitdaMarginPct,
        2,
      ),
      netCashFlow: _round(after.netCashFlow - before.netCashFlow, 4),
      breakEvenRevenue: beforeBreakEven != null && afterBreakEven != null
          ? _round(afterBreakEven - beforeBreakEven, 4)
          : null,
    ),
  );
}
