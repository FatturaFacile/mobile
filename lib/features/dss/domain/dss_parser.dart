import 'dss_models.dart';
import 'what_if_calculator.dart';

/// Reads the `data` objects of the Executive DSS endpoints into read models. Missing or null fields are tolerated, so a server that
/// adds or drops a field does not break a cached snapshot.
abstract final class DssParser {
  static const List<String> _groups = <String>[
    'financial',
    'customer',
    'efficiency',
  ];

  static DssOverview overview(Map<String, dynamic> data) {
    final Map<String, dynamic> meta = _map(data['meta']);
    final Map<String, dynamic> period = _map(meta['period']);
    final Map<String, dynamic> scorecard = _map(data['scorecard']);
    final List<DssKpi> kpis = <DssKpi>[
      for (final String group in _groups)
        for (final Map<String, dynamic> item in _list(scorecard[group]))
          _kpi(item, group),
    ];
    final Map<String, dynamic> capital = _map(data['working_capital']);
    return DssOverview(
      currency: _text(meta['currency']) ?? 'CHF',
      periodFrom: _text(period['from']) ?? '',
      periodTo: _text(period['to']) ?? '',
      kpis: kpis,
      alerts: <DssAlert>[
        for (final Map<String, dynamic> item in _list(data['alerts']))
          _alert(item),
      ],
      dsoDays: _num(capital['dso_days']) ?? 0,
      cccDays: _num(capital['ccc_days']) ?? 0,
    );
  }

  static DssProfitability profitability(Map<String, dynamic> data) =>
      DssProfitability(
        dimension: _text(data['dimension']) ?? 'customer',
        rows: <DssProfitRow>[
          for (final Map<String, dynamic> row in _list(data['rows']))
            DssProfitRow(
              key: _text(row['key']) ?? '',
              label: _text(row['label']) ?? '',
              rank: (_num(row['rank']) ?? 0).round(),
              netRevenue: _num(row['net_revenue']) ?? 0,
              grossMargin: _num(row['gross_margin']) ?? 0,
              netOperatingProfit: _num(row['net_operating_profit']) ?? 0,
              netMarginPct: _num(row['net_margin_pct']) ?? 0,
              inParetoCore: row['in_pareto_core'] == true,
              isValueDestroying: row['is_value_destroying'] == true,
            ),
        ],
        paretoCutoffRank: (_num(data['pareto_cutoff_rank']) ?? 0).round(),
      );

  /// The EBITDA bridge as its baseline, effects and actual; null when the bridge has no steps.
  static DssVarianceSummary? variance(Map<String, dynamic> data) {
    final Map<String, double> steps = <String, double>{
      for (final Map<String, dynamic> step in _list(data['ebitda_bridge']))
        if (_text(step['key']) != null)
          _text(step['key'])!: _num(step['value']) ?? 0,
    };
    if (steps.isEmpty) {
      return null;
    }
    return DssVarianceSummary(
      baseline: steps['baseline'] ?? 0,
      actual: steps['actual'] ?? 0,
      volume: steps['volume'] ?? 0,
      price: steps['price'] ?? 0,
      cogs: steps['cogs'] ?? 0,
      opex: steps['opex'] ?? 0,
      fx: steps['fx'] ?? 0,
    );
  }

  static List<DssLegalEntity> legalEntities(Object? data) => <DssLegalEntity>[
    for (final Map<String, dynamic> item in _list(data))
      DssLegalEntity(
        id: _text(item['id']) ?? '',
        name: _text(item['name']) ?? '',
        currency: _text(item['currency']) ?? '',
      ),
  ];

  /// The actuals of the offline simulator. The server inputs are used when they were fetched; otherwise they are derived from the
  /// scorecard (revenue, gross margin, EBITDA, DSO, net cash flow and the period), without FX exposure and FTE cost.
  static WhatIfBaseline baseline(
    DssOverview overview,
    Map<String, dynamic>? simulation,
  ) {
    final Map<String, dynamic> inputs = _map(simulation?['inputs']);
    final double? revenue = _num(inputs['revenue']);
    if (revenue != null) {
      return WhatIfBaseline(
        revenue: revenue,
        cogs: _num(inputs['cogs']) ?? 0,
        opex: _num(inputs['opex']) ?? 0,
        dsoDays: _num(inputs['dso_days']) ?? 0,
        netCashFlow: _num(inputs['net_cash_flow']) ?? 0,
        periodDays: (_num(inputs['period_days']) ?? _periodDays(overview))
            .round(),
        fteAnnualCost: _num(inputs['fte_annual_cost']) ?? 0,
        revenueFxShare: _num(inputs['revenue_fx_share']) ?? 0,
        costFxShare: _num(inputs['cost_fx_share']) ?? 0,
      );
    }
    final double derivedRevenue = overview.kpi('revenue')?.value ?? 0;
    final double margin = overview.kpi('gross_margin_pct')?.value ?? 0;
    final double ebitda = overview.kpi('ebitda')?.value ?? 0;
    final double cogs = derivedRevenue * (1 - margin / 100);
    return WhatIfBaseline(
      revenue: derivedRevenue,
      cogs: cogs,
      opex: derivedRevenue - cogs - ebitda,
      dsoDays: overview.dsoDays,
      netCashFlow: overview.kpi('net_cash_flow')?.value ?? 0,
      periodDays: _periodDays(overview),
    );
  }

  static int _periodDays(DssOverview overview) {
    final DateTime? from = DateTime.tryParse(overview.periodFrom);
    final DateTime? to = DateTime.tryParse(overview.periodTo);
    if (from == null || to == null) {
      return 1;
    }
    final int days = to.difference(from).inDays + 1;
    return days < 1 ? 1 : days;
  }

  static DssKpi _kpi(Map<String, dynamic> item, String group) => DssKpi(
    key: _text(item['key']) ?? '',
    group: group,
    unit: _text(item['unit']) ?? 'ratio',
    available: item['available'] != false,
    value: _num(item['value']),
    comparisonValue: _num(item['comparison_value']),
    delta: _num(item['delta']),
    deltaPct: _num(item['delta_pct']),
    favorable: item['favorable'] is bool ? item['favorable'] as bool : null,
    sparkline: <double>[
      for (final Object? point in _objects(item['sparkline']))
        if (point is num) point.toDouble(),
    ],
    target: _num(item['target']),
  );

  static DssAlert _alert(Map<String, dynamic> item) => DssAlert(
    code: _text(item['code']) ?? '',
    severity: _text(item['severity']) ?? 'INFO',
    metric: _text(item['metric']) ?? '',
    value: _num(item['value']) ?? 0,
    threshold: _num(item['threshold']) ?? 0,
    label: _text(_map(item['context'])['label']),
  );

  static Map<String, dynamic> _map(Object? value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  static List<Object?> _objects(Object? value) =>
      value is List ? value.cast<Object?>() : const <Object?>[];

  static List<Map<String, dynamic>> _list(Object? value) =>
      <Map<String, dynamic>>[
        for (final Object? item in _objects(value))
          if (item is Map) Map<String, dynamic>.from(item),
      ];

  static String? _text(Object? value) => value is String ? value : null;

  static double? _num(Object? value) => value is num ? value.toDouble() : null;
}
