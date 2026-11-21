import 'package:fattura_facile/features/dss/domain/dss_models.dart';
import 'package:fattura_facile/features/dss/domain/dss_parser.dart';

Map<String, dynamic> kpi(
  String key,
  String unit,
  double value, {
  double? deltaPct,
  bool? favorable,
  List<double> sparkline = const <double>[1, 2, 3],
}) => <String, dynamic>{
  'key': key,
  'unit': unit,
  'available': true,
  'value': value,
  'delta_pct': deltaPct,
  'favorable': favorable,
  'sparkline': sparkline,
};

Map<String, dynamic> overviewJson({
  String currency = 'CHF',
  double revenue = 1000,
}) => <String, dynamic>{
  'meta': <String, dynamic>{
    'currency': currency,
    'period': <String, dynamic>{'from': '2026-01-01', 'to': '2026-01-30'},
  },
  'scorecard': <String, dynamic>{
    'financial': <dynamic>[
      kpi('revenue', 'currency', revenue, deltaPct: 12.5, favorable: true),
      kpi('gross_margin_pct', 'percent', 40, deltaPct: -2, favorable: false),
      kpi('ebitda', 'currency', 100, deltaPct: 5, favorable: true),
      kpi('net_cash_flow', 'currency', 100),
    ],
    'customer': <dynamic>[],
    'efficiency': <dynamic>[
      kpi('ccc_days', 'days', 45),
      kpi('dso_days', 'days', 30),
    ],
  },
  'working_capital': <String, dynamic>{'dso_days': 30, 'ccc_days': 45},
  'alerts': <dynamic>[
    <String, dynamic>{
      'code': 'margin_erosion',
      'severity': 'CRITICAL',
      'metric': 'gross_margin_pct',
      'value': 4.2,
      'threshold': 2,
      'context': <String, dynamic>{},
    },
    <String, dynamic>{
      'code': 'customer_concentration',
      'severity': 'WARNING',
      'metric': 'customer_share_pct',
      'value': 38,
      'threshold': 25,
      'context': <String, dynamic>{'label': 'Acme AG'},
    },
  ],
};

Map<String, dynamic> profitabilityJson(String dimension, {int count = 7}) =>
    <String, dynamic>{
      'dimension': dimension,
      'pareto_cutoff_rank': 3,
      'rows': <dynamic>[
        for (int i = 1; i <= count; i++)
          <String, dynamic>{
            'key': '$dimension-$i',
            'label': '${dimension == 'customer' ? 'Customer' : 'Product'} $i',
            'rank': i,
            'net_revenue': 1000.0 * (count - i + 1),
            'gross_margin': 500.0,
            'net_operating_profit': 100.0 * (count - 2 * i),
            'net_margin_pct': 20.0 - 4 * i,
            'in_pareto_core': i <= 3,
            'is_value_destroying': i == count,
          },
      ],
    };

Map<String, dynamic> varianceJson() => <String, dynamic>{
  'ebitda_bridge': <dynamic>[
    <String, dynamic>{'key': 'baseline', 'value': 80},
    <String, dynamic>{'key': 'volume', 'value': 30},
    <String, dynamic>{'key': 'price', 'value': 10},
    <String, dynamic>{'key': 'cogs', 'value': -15},
    <String, dynamic>{'key': 'opex', 'value': -5},
    <String, dynamic>{'key': 'fx', 'value': 0},
    <String, dynamic>{'key': 'actual', 'value': 100},
  ],
};

Map<String, dynamic> simulationJson() => <String, dynamic>{
  'inputs': <String, dynamic>{
    'revenue': 1000,
    'cogs': 600,
    'opex': 300,
    'dso_days': 30,
    'net_cash_flow': 100,
    'period_days': 30,
  },
};

/// A complete snapshot as the parser builds it from the fixtures above.
DssSnapshot snapshotFor(
  DssFilter filter, {
  DateTime? syncedAt,
  List<DssLegalEntity> entities = const <DssLegalEntity>[],
}) {
  final DssOverview overview = DssParser.overview(
    overviewJson(currency: filter.currency),
  );
  return DssSnapshot(
    filter: filter,
    overview: overview,
    customers: DssParser.profitability(profitabilityJson('customer')),
    products: DssParser.profitability(profitabilityJson('product')),
    variance: DssParser.variance(varianceJson()),
    baseline: DssParser.baseline(overview, simulationJson()),
    legalEntities: entities,
    syncedAt: syncedAt ?? DateTime.utc(2026, 1, 30, 10),
  );
}
