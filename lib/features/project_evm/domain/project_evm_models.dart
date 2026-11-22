/// Models of the project profitability and earned value view (Mod 082), parsed from `/projects/{id}/evm/*`.
///
/// Amounts reach the app as decimal strings; they are parsed to doubles for display only, never for accounting.
library;

enum EvmLight { green, amber, red }

/// Traffic light of an index: green from 1.00, amber from 0.90, red below; an undefined index is green.
EvmLight indexLight(double? index) {
  if (index == null || index >= 1) {
    return EvmLight.green;
  }
  return index >= 0.9 ? EvmLight.amber : EvmLight.red;
}

/// Budget absorption above 80% is a warning.
bool absorptionWarning(double? percent) => percent != null && percent > 80;

double? _number(Object? value) {
  if (value == null) {
    return null;
  }
  return value is num ? value.toDouble() : double.tryParse('$value');
}

double _amount(Object? value) => _number(value) ?? 0;

/// The figures of the project or of one WBS node.
class EvmFigures {
  const EvmFigures({
    required this.bac,
    required this.committed,
    required this.actual,
    required this.pv,
    required this.ev,
    required this.cv,
    required this.sv,
    required this.eac,
    required this.etc,
    required this.vac,
    required this.revenue,
    required this.margin,
    this.cpi,
    this.spi,
    this.absorption,
    this.marginPercent,
    this.manualEtc,
  });

  factory EvmFigures.fromJson(Map<String, dynamic> json) => EvmFigures(
    bac: _amount(json['bac']),
    committed: _amount(json['committed']),
    actual: _amount(json['actual']),
    pv: _amount(json['pv']),
    ev: _amount(json['ev']),
    cv: _amount(json['cv']),
    sv: _amount(json['sv']),
    eac: _amount(json['eac']),
    etc: _amount(json['etc']),
    vac: _amount(json['vac']),
    revenue: _amount(json['recognized_revenue']),
    margin: _amount(json['gross_margin_amount']),
    cpi: _number(json['cpi']),
    spi: _number(json['spi']),
    absorption: _number(json['budget_absorption_percent']),
    marginPercent: _number(json['gross_margin_percent']),
    manualEtc: _number(json['manual_etc_override']),
  );

  final double bac;
  final double committed;
  final double actual;
  final double pv;
  final double ev;
  final double cv;
  final double sv;
  final double eac;
  final double etc;
  final double vac;
  final double revenue;
  final double margin;
  final double? cpi;
  final double? spi;
  final double? absorption;
  final double? marginPercent;
  final double? manualEtc;

  /// Committed plus actual cost.
  double get exposure => committed + actual;

  EvmLight get cpiLight => indexLight(cpi);
  EvmLight get spiLight => indexLight(spi);

  /// Thresholds breached: CPI or SPI below 0.90 and absorption above 80%.
  int get breaches => <bool>[
    cpiLight == EvmLight.red,
    spiLight == EvmLight.red,
    absorptionWarning(absorption),
  ].where((bool breached) => breached).length;
}

/// A node of the WBS tree; `figures` is null until a snapshot exists for it.
class WbsNode {
  const WbsNode({
    required this.id,
    required this.code,
    required this.title,
    required this.children,
    this.figures,
  });

  factory WbsNode.fromJson(Map<String, dynamic> json) => WbsNode(
    id: '${json['wbs_node_id']}',
    code: '${json['wbs_code']}',
    title: '${json['title']}',
    figures: json['has_snapshot'] == true ? EvmFigures.fromJson(json) : null,
    children: _list(json['children']).map(WbsNode.fromJson).toList(),
  );

  final String id;
  final String code;
  final String title;
  final EvmFigures? figures;
  final List<WbsNode> children;
}

/// Managerial cost against the statutory valuation (OIC 23 in Italy, Swiss GAAP FER 22 in Switzerland).
class EvmReconciliation {
  const EvmReconciliation({
    required this.managerialCost,
    required this.statutoryCost,
    required this.overhead,
    required this.reconciled,
    this.standard,
    this.difference,
    this.hasValuation = false,
  });

  factory EvmReconciliation.fromJson(Map<String, dynamic> json) =>
      EvmReconciliation(
        standard: json['standard'] as String?,
        managerialCost: _amount(json['managerial_actual_cost']),
        statutoryCost: _amount(json['statutory_cumulative_cost']),
        difference: _number(json['cost_difference']),
        overhead: _amount(json['cost_center_overhead']),
        reconciled: json['is_reconciled'] == true,
        hasValuation: json['last_recognition_date'] != null,
      );

  final String? standard;
  final double managerialCost;
  final double statutoryCost;
  final double? difference;
  final double overhead;
  final bool reconciled;
  final bool hasValuation;
}

class WaterfallStep {
  const WaterfallStep({
    required this.key,
    required this.amount,
    required this.runningTotal,
    required this.isTotal,
  });

  factory WaterfallStep.fromJson(Map<String, dynamic> json) => WaterfallStep(
    key: '${json['key']}',
    amount: _amount(json['amount']),
    runningTotal: _amount(json['running_total']),
    isTotal: json['kind'] == 'total',
  );

  final String key;
  final double amount;
  final double runningTotal;
  final bool isTotal;
}

class ScurvePoint {
  const ScurvePoint({
    required this.date,
    required this.pv,
    required this.ev,
    required this.ac,
  });

  factory ScurvePoint.fromJson(Map<String, dynamic> json) => ScurvePoint(
    date: DateTime.parse('${json['date']}'),
    pv: _amount(json['pv']),
    ev: _amount(json['ev']),
    ac: _amount(json['ac']),
  );

  final DateTime date;
  final double pv;
  final double ev;
  final double ac;
}

class EacPoint {
  const EacPoint({required this.date, required this.eac});

  factory EacPoint.fromJson(Map<String, dynamic> json) => EacPoint(
    date: DateTime.parse('${json['date']}'),
    eac: _amount(json['eac']),
  );

  final DateTime date;
  final double eac;
}

/// Everything the page shows for one project, as last synced.
class ProjectEvmSnapshot {
  const ProjectEvmSnapshot({
    required this.projectId,
    required this.currency,
    required this.nodes,
    required this.waterfall,
    required this.points,
    required this.forecast,
    required this.syncedAt,
    this.snapshotDate,
    this.project,
    this.reconciliation,
  });

  /// Builds the snapshot from the three answers of the API (`wbs-breakdown`, `waterfall`, `scurve`).
  factory ProjectEvmSnapshot.fromParts({
    required Map<String, dynamic> breakdown,
    required Map<String, dynamic> waterfall,
    required Map<String, dynamic> scurve,
    required DateTime syncedAt,
  }) {
    final Object? project = breakdown['project'];
    final Object? reconciliation = breakdown['reconciliation'];
    final Object? date = breakdown['snapshot_date'];
    return ProjectEvmSnapshot(
      projectId: '${breakdown['project_id']}',
      currency: '${breakdown['currency'] ?? waterfall['currency'] ?? 'EUR'}',
      snapshotDate: date == null ? null : DateTime.parse('$date'),
      project:
          project is Map<String, dynamic> && project['has_snapshot'] == true
          ? EvmFigures.fromJson(project)
          : null,
      reconciliation: reconciliation is Map<String, dynamic>
          ? EvmReconciliation.fromJson(reconciliation)
          : null,
      nodes: _list(breakdown['nodes']).map(WbsNode.fromJson).toList(),
      waterfall: _list(waterfall['steps']).map(WaterfallStep.fromJson).toList(),
      points: _list(scurve['points']).map(ScurvePoint.fromJson).toList(),
      forecast: _list(scurve['forecast']).map(EacPoint.fromJson).toList(),
      syncedAt: syncedAt,
    );
  }

  final String projectId;
  final String currency;
  final DateTime? snapshotDate;

  /// Null until the project has a snapshot (the user recomputes it on the web).
  final EvmFigures? project;
  final EvmReconciliation? reconciliation;
  final List<WbsNode> nodes;
  final List<WaterfallStep> waterfall;
  final List<ScurvePoint> points;
  final List<EacPoint> forecast;
  final DateTime syncedAt;
}

/// A project of the picker.
class EvmProjectRef {
  const EvmProjectRef({
    required this.id,
    required this.number,
    required this.name,
  });

  factory EvmProjectRef.fromJson(Map<String, dynamic> json) => EvmProjectRef(
    id: '${json['id']}',
    number: '${json['project_number'] ?? ''}',
    name: '${json['name'] ?? ''}',
  );

  final String id;
  final String number;
  final String name;

  String get label => number.isEmpty ? name : '$number · $name';
}

enum EvmSyncStatus { synced, offline, unauthorized, forbidden, failed }

class EvmSyncResult {
  const EvmSyncResult(this.status, {this.detail = ''});

  final EvmSyncStatus status;
  final String detail;
}

List<Map<String, dynamic>> _list(Object? value) => value is List
    ? value
          .whereType<Map<dynamic, dynamic>>()
          .map((Map<dynamic, dynamic> item) => Map<String, dynamic>.from(item))
          .toList()
    : <Map<String, dynamic>>[];
