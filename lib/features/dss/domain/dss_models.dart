import 'what_if_calculator.dart';

/// The strategic filter of the Executive DSS: also the key under which a snapshot is cached.
class DssFilter {
  const DssFilter({
    this.legalEntityId = '',
    this.currency = 'CHF',
    this.periodPreset = 'YTD',
    this.comparisonBaseline = 'PRIOR_YEAR',
  });

  /// Reporting currencies of the DSS.
  static const List<String> currencies = <String>['CHF', 'EUR'];

  /// Period presets offered on the phone (a custom range is a desktop and web feature).
  static const List<String> periods = <String>['MTD', 'QTD', 'YTD', 'L12M'];

  /// Server legal entity, or an empty string for every legal entity.
  final String legalEntityId;
  final String currency;
  final String periodPreset;
  final String comparisonBaseline;

  DssFilter copyWith({
    String? legalEntityId,
    String? currency,
    String? periodPreset,
    String? comparisonBaseline,
  }) => DssFilter(
    legalEntityId: legalEntityId ?? this.legalEntityId,
    currency: currency ?? this.currency,
    periodPreset: periodPreset ?? this.periodPreset,
    comparisonBaseline: comparisonBaseline ?? this.comparisonBaseline,
  );

  /// Query parameters of the API (`legal_entity_ids[]` is repeated by Dio).
  Map<String, dynamic> toQuery() => <String, dynamic>{
    'currency': currency,
    'period_preset': periodPreset,
    'comparison_baseline': comparisonBaseline,
    if (legalEntityId.isNotEmpty) 'legal_entity_ids[]': <String>[legalEntityId],
  };

  /// JSON body of the POST endpoints.
  Map<String, dynamic> toBody() => <String, dynamic>{
    'currency': currency,
    'period_preset': periodPreset,
    'comparison_baseline': comparisonBaseline,
    if (legalEntityId.isNotEmpty) 'legal_entity_ids': <String>[legalEntityId],
  };

  @override
  bool operator ==(Object other) =>
      other is DssFilter &&
      other.legalEntityId == legalEntityId &&
      other.currency == currency &&
      other.periodPreset == periodPreset &&
      other.comparisonBaseline == comparisonBaseline;

  @override
  int get hashCode =>
      Object.hash(legalEntityId, currency, periodPreset, comparisonBaseline);
}

/// One Balanced Scorecard indicator.
class DssKpi {
  const DssKpi({
    required this.key,
    required this.group,
    required this.unit,
    required this.available,
    this.value,
    this.comparisonValue,
    this.delta,
    this.deltaPct,
    this.favorable,
    this.sparkline = const <double>[],
    this.target,
  });

  final String key;
  final String group;

  /// `currency`, `percent`, `days` or `ratio`.
  final String unit;

  /// False while the indicator has no data source.
  final bool available;
  final double? value;
  final double? comparisonValue;
  final double? delta;
  final double? deltaPct;

  /// Whether the change is an improvement; null without a comparison.
  final bool? favorable;
  final List<double> sparkline;
  final double? target;
}

/// A strategic alert: a stable code, the offending value and, when it names one, the customer.
class DssAlert {
  const DssAlert({
    required this.code,
    required this.severity,
    required this.metric,
    required this.value,
    required this.threshold,
    this.label,
  });

  final String code;

  /// `CRITICAL`, `WARNING` or `INFO`.
  final String severity;
  final String metric;
  final double value;
  final double threshold;
  final String? label;
}

class DssOverview {
  const DssOverview({
    required this.currency,
    required this.periodFrom,
    required this.periodTo,
    required this.kpis,
    required this.alerts,
    required this.dsoDays,
    required this.cccDays,
  });

  final String currency;
  final String periodFrom;
  final String periodTo;
  final List<DssKpi> kpis;
  final List<DssAlert> alerts;
  final double dsoDays;
  final double cccDays;

  DssKpi? kpi(String key) {
    for (final DssKpi kpi in kpis) {
      if (kpi.key == key) {
        return kpi;
      }
    }
    return null;
  }
}

/// A row of the profitability matrix (a customer or a product).
class DssProfitRow {
  const DssProfitRow({
    required this.key,
    required this.label,
    required this.rank,
    required this.netRevenue,
    required this.grossMargin,
    required this.netOperatingProfit,
    required this.netMarginPct,
    required this.inParetoCore,
    required this.isValueDestroying,
  });

  final String key;
  final String label;
  final int rank;
  final double netRevenue;
  final double grossMargin;
  final double netOperatingProfit;
  final double netMarginPct;
  final bool inParetoCore;
  final bool isValueDestroying;
}

class DssProfitability {
  const DssProfitability({
    required this.dimension,
    required this.rows,
    required this.paretoCutoffRank,
  });

  final String dimension;

  /// Ranked by net operating profit, best first.
  final List<DssProfitRow> rows;
  final int paretoCutoffRank;

  /// The [count] most profitable entities.
  List<DssProfitRow> top(int count) => rows.take(count).toList();

  /// The [count] least profitable entities, worst first. With fewer than twice [count] rows the two ends overlap.
  List<DssProfitRow> bottom(int count) {
    final int skip = rows.length > count ? rows.length - count : 0;
    final List<DssProfitRow> tail = rows.skip(skip).toList();
    return tail.reversed.toList();
  }

  int get erodingCount =>
      rows.where((DssProfitRow row) => row.isValueDestroying).length;
}

/// The EBITDA bridge reduced to its effects.
class DssVarianceSummary {
  const DssVarianceSummary({
    required this.baseline,
    required this.actual,
    required this.volume,
    required this.price,
    required this.cogs,
    required this.opex,
    required this.fx,
  });

  final double baseline;
  final double actual;
  final double volume;
  final double price;
  final double cogs;
  final double opex;
  final double fx;
}

class DssLegalEntity {
  const DssLegalEntity({
    required this.id,
    required this.name,
    required this.currency,
  });

  final String id;
  final String name;
  final String currency;
}

/// Everything the page shows for one filter, with the instant it was pulled.
class DssSnapshot {
  const DssSnapshot({
    required this.filter,
    required this.overview,
    required this.customers,
    required this.baseline,
    required this.syncedAt,
    this.products,
    this.variance,
    this.legalEntities = const <DssLegalEntity>[],
  });

  final DssFilter filter;
  final DssOverview overview;
  final DssProfitability customers;
  final DssProfitability? products;
  final DssVarianceSummary? variance;

  /// The actuals the offline what-if runs on.
  final WhatIfBaseline baseline;
  final List<DssLegalEntity> legalEntities;
  final DateTime syncedAt;
}
