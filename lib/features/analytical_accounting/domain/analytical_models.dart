import 'dart:convert';

/// The enum values of the industrial and analytical cost accounting contract (Mod 018), identical on the web-api, the web
/// frontend, the desktop and the mobile client.
const List<String> analyticalCenterTypes = <String>[
  'COST_CENTER',
  'PROFIT_CENTER',
];
const List<String> analyticalCenterCategories = <String>[
  'STRUCTURAL',
  'AUXILIARY',
  'PRODUCTION',
  'LOGISTICS',
  'COMMERCIAL',
  'PROFIT',
];
const List<String> analyticalDriverTypes = <String>[
  'AREA_SQM',
  'HEADCOUNT_FTE',
  'MACHINE_HOURS',
  'REVENUE_VOLUME',
  'FIXED_PERCENTAGE',
  'CUSTOM',
];
const List<String> analyticalCostElementTypes = <String>[
  'VARIABLE_DIRECT',
  'FIXED_DIRECT',
  'INDIRECT_AUXILIARY',
  'REVENUE',
  'NON_OPERATING',
];
const List<String> analyticalRunStatuses = <String>[
  'PREVIEW',
  'CONSOLIDATED',
  'REVERSED',
];

/// How a sync of the module ended.
enum AnalyticalSyncStatus { synced, offline, unauthorized, forbidden, failed }

/// The outcome of a sync: the status, the entries the server accepted or refused from the offline queue and the failure detail.
class AnalyticalSyncResult {
  const AnalyticalSyncResult(
    this.status, {
    this.sent = 0,
    this.failed = 0,
    this.detail = '',
  });

  final AnalyticalSyncStatus status;
  final int sent;
  final int failed;
  final String detail;
}

/// A payload of the endpoints that does not have the expected shape; it never replaces a good cache.
class AnalyticalFormatException implements Exception {
  const AnalyticalFormatException(this.message);

  final String message;

  @override
  String toString() => 'AnalyticalFormatException($message)';
}

String _text(Map<dynamic, dynamic> json, String key) {
  final dynamic value = json[key];
  if (value is! String) {
    throw AnalyticalFormatException('missing text $key');
  }
  return value;
}

String? _optionalText(Map<dynamic, dynamic> json, String key) {
  final dynamic value = json[key];
  return value is String ? value : null;
}

/// Amounts arrive as decimal strings (or numbers); a missing or malformed one is a format error.
double _amount(Map<dynamic, dynamic> json, String key) {
  final dynamic value = json[key];
  final double? parsed = switch (value) {
    final num number => number.toDouble(),
    final String text => double.tryParse(text),
    _ => null,
  };
  if (parsed == null) {
    throw AnalyticalFormatException('invalid amount $key');
  }
  return parsed;
}

/// A cost or profit center with its children, as the tree endpoint returns it.
class AnalyticalCenter {
  const AnalyticalCenter({
    required this.id,
    required this.parentId,
    required this.code,
    required this.name,
    required this.centerType,
    required this.category,
    required this.managerName,
    required this.isActive,
    required this.depth,
    required this.children,
  });

  factory AnalyticalCenter.fromJson(Map<dynamic, dynamic> json) {
    final dynamic children = json['children'];
    return AnalyticalCenter(
      id: _text(json, 'id'),
      parentId: _optionalText(json, 'parent_id'),
      code: _text(json, 'code'),
      name: _text(json, 'name'),
      centerType: _text(json, 'center_type'),
      category: _text(json, 'category'),
      managerName: _optionalText(json, 'manager_name'),
      isActive: json['is_active'] != false,
      depth: json['depth'] is int ? json['depth'] as int : 0,
      children: children is List
          ? children
                .map(
                  (dynamic c) =>
                      AnalyticalCenter.fromJson(c as Map<dynamic, dynamic>),
                )
                .toList()
          : <AnalyticalCenter>[],
    );
  }

  final String id;
  final String? parentId;
  final String code;
  final String name;
  final String centerType;
  final String category;
  final String? managerName;
  final bool isActive;
  final int depth;
  final List<AnalyticalCenter> children;

  bool get isCostCenter => centerType == 'COST_CENTER';

  /// This center and its descendants, parents first.
  List<AnalyticalCenter> flatten() => <AnalyticalCenter>[
    this,
    for (final AnalyticalCenter child in children) ...child.flatten(),
  ];
}

/// Parses the `data` array of the center tree endpoint.
List<AnalyticalCenter> parseCenters(dynamic data) {
  if (data is! List) {
    throw const AnalyticalFormatException('the center tree must be a list');
  }
  return data
      .map(
        (dynamic c) => AnalyticalCenter.fromJson(c as Map<dynamic, dynamic>),
      )
      .toList();
}

/// Every center of a forest, depth first.
List<AnalyticalCenter> flattenCenters(List<AnalyticalCenter> roots) =>
    <AnalyticalCenter>[
      for (final AnalyticalCenter root in roots) ...root.flatten(),
    ];

/// The multi-level contribution margin income statement; percentages are on the operating revenues.
class ContributionMargin {
  const ContributionMargin({
    required this.revenues,
    required this.variableCosts,
    required this.margin1,
    required this.margin1Percent,
    required this.fixedCosts,
    required this.margin2,
    required this.margin2Percent,
    required this.indirectCosts,
    required this.apportionedCosts,
    required this.operatingResult,
    required this.operatingResultPercent,
  });

  factory ContributionMargin.fromJson(Map<dynamic, dynamic> data) {
    final dynamic statement = data['statement'];
    if (statement is! Map) {
      throw const AnalyticalFormatException('the margin has no statement');
    }
    return ContributionMargin(
      revenues: _amount(statement, 'operating_revenues'),
      variableCosts: _amount(statement, 'direct_variable_costs'),
      margin1: _amount(statement, 'contribution_margin_1'),
      margin1Percent: _amount(statement, 'contribution_margin_1_pct'),
      fixedCosts: _amount(statement, 'direct_fixed_costs'),
      margin2: _amount(statement, 'contribution_margin_2'),
      margin2Percent: _amount(statement, 'contribution_margin_2_pct'),
      indirectCosts: _amount(statement, 'indirect_costs'),
      apportionedCosts: _amount(statement, 'apportioned_costs'),
      operatingResult: _amount(statement, 'operating_result'),
      operatingResultPercent: _amount(statement, 'operating_result_pct'),
    );
  }

  final double revenues;
  final double variableCosts;
  final double margin1;
  final double margin1Percent;
  final double fixedCosts;
  final double margin2;
  final double margin2Percent;
  final double indirectCosts;
  final double apportionedCosts;
  final double operatingResult;
  final double operatingResultPercent;

  /// True when the reported levels follow from the cost blocks (checked on cents, so no float noise).
  bool get isConsistent =>
      cents(margin1) == cents(revenues) - cents(variableCosts) &&
      cents(margin2) == cents(margin1) - cents(fixedCosts) &&
      cents(operatingResult) ==
          cents(margin2) - cents(indirectCosts) - cents(apportionedCosts);
}

/// One center of the direct-versus-apportioned cost comparison.
class ComparisonRow {
  const ComparisonRow({
    required this.centerId,
    required this.code,
    required this.name,
    required this.depth,
    required this.directCost,
    required this.apportionedIn,
    required this.apportionedOut,
    required this.netCost,
    required this.variance,
    required this.sharePercent,
  });

  factory ComparisonRow.fromJson(Map<dynamic, dynamic> json) => ComparisonRow(
    centerId: _text(json, 'center_id'),
    code: _text(json, 'code'),
    name: _text(json, 'name'),
    depth: json['depth'] is int ? json['depth'] as int : 0,
    directCost: _amount(json, 'direct_cost'),
    apportionedIn: _amount(json, 'apportioned_in'),
    apportionedOut: _amount(json, 'apportioned_out'),
    netCost: _amount(json, 'net_cost'),
    variance: _amount(json, 'variance'),
    sharePercent: _amount(json, 'share_pct'),
  );

  final String centerId;
  final String code;
  final String name;
  final int depth;
  final double directCost;
  final double apportionedIn;
  final double apportionedOut;
  final double netCost;
  final double variance;
  final double sharePercent;
}

/// Parses the `data` object of the comparison report.
List<ComparisonRow> parseComparison(dynamic data) {
  final dynamic rows = data is Map ? data['rows'] : null;
  if (rows is! List) {
    throw const AnalyticalFormatException('the comparison has no rows');
  }
  return rows
      .map((dynamic r) => ComparisonRow.fromJson(r as Map<dynamic, dynamic>))
      .toList();
}

/// One step-down apportionment run of the history.
class ApportionmentRun {
  const ApportionmentRun({
    required this.id,
    required this.periodKey,
    required this.status,
    required this.totalPool,
    required this.totalAllocated,
    required this.totalUnallocated,
  });

  factory ApportionmentRun.fromJson(Map<dynamic, dynamic> json) =>
      ApportionmentRun(
        id: _text(json, 'id'),
        periodKey: _text(json, 'period_key'),
        status: _text(json, 'status'),
        totalPool: _amount(json, 'total_pool'),
        totalAllocated: _amount(json, 'total_allocated'),
        totalUnallocated: _amount(json, 'total_unallocated'),
      );

  final String id;
  final String periodKey;
  final String status;
  final double totalPool;
  final double totalAllocated;
  final double totalUnallocated;
}

/// Parses the `data` array of the run history.
List<ApportionmentRun> parseRuns(dynamic data) {
  if (data is! List) {
    throw const AnalyticalFormatException('the run history must be a list');
  }
  return data
      .map(
        (dynamic r) => ApportionmentRun.fromJson(r as Map<dynamic, dynamic>),
      )
      .toList();
}

/// Everything the page shows, read from the local cache.
class AnalyticalOverview {
  const AnalyticalOverview({
    this.centers = const <AnalyticalCenter>[],
    this.runs = const <ApportionmentRun>[],
    this.margin,
    this.comparison = const <ComparisonRow>[],
    this.syncedAt,
    this.pending = 0,
  });

  final List<AnalyticalCenter> centers;
  final List<ApportionmentRun> runs;
  final ContributionMargin? margin;
  final List<ComparisonRow> comparison;
  final DateTime? syncedAt;

  /// How many entries wait in the offline queue.
  final int pending;
}

/// One analytical allocation vector of a posting line: where a share of the line goes, by percentage or by exact amount.
class AllocationVector {
  const AllocationVector({
    this.costCenterId,
    this.profitCenterId,
    this.projectId,
    this.productLineId,
    this.costElementType,
    this.percentage,
    this.amount,
  });

  final String? costCenterId;
  final String? profitCenterId;
  final String? projectId;
  final String? productLineId;
  final String? costElementType;
  final double? percentage;
  final double? amount;

  bool get hasTarget =>
      costCenterId != null || profitCenterId != null || projectId != null;

  Map<String, dynamic> toJson() => <String, dynamic>{
    if (costCenterId != null) 'cost_center_id': costCenterId,
    if (profitCenterId != null) 'profit_center_id': profitCenterId,
    if (projectId != null) 'project_id': projectId,
    if (productLineId != null) 'product_line_id': productLineId,
    if (costElementType != null) 'cost_element_type': costElementType,
    if (percentage != null) 'percentage': percentage,
    if (amount != null) 'amount': amount!.toStringAsFixed(2),
  };
}

/// Decimal amount to cents, rounded half away from zero.
int cents(double amount) {
  final double scaled = amount.abs() * 100;
  final int rounded = (scaled + 0.5 + 1e-9).floor();
  return amount < 0 ? -rounded : rounded;
}

/// Cents back to a two decimals text.
String centsText(int value) {
  final String sign = value < 0 ? '-' : '';
  final int abs = value.abs();
  return '$sign${abs ~/ 100}.${(abs % 100).toString().padLeft(2, '0')}';
}

/// Largest Remainder (Hamilton) split of cents over non-negative weights (in ten thousandths): the shares always add up to the
/// total, a tie goes to the earliest weight.
List<int> allocateCents(int totalCents, List<int> weights) {
  final int sum = weights.fold<int>(0, (int a, int b) => a + b);
  if (sum <= 0) {
    return List<int>.filled(weights.length, 0);
  }
  final int magnitude = totalCents.abs();
  final List<int> shares = <int>[
    for (final int w in weights) (magnitude * w) ~/ sum,
  ];
  final List<int> remainders = <int>[
    for (final int w in weights) (magnitude * w) % sum,
  ];
  int leftover = magnitude - shares.fold<int>(0, (int a, int b) => a + b);
  final List<int> order = List<int>.generate(weights.length, (int i) => i)
    ..sort((int a, int b) {
      final int byRemainder = remainders[b].compareTo(remainders[a]);
      return byRemainder != 0 ? byRemainder : a.compareTo(b);
    });
  for (int i = 0; leftover > 0; i = (i + 1) % order.length, leftover--) {
    shares[order[i]]++;
  }
  return totalCents < 0 ? <int>[for (final int s in shares) -s] : shares;
}

/// The result of splitting a line over vectors: the error codes (string keys of the labels) or the cents of every vector.
class SplitResult {
  const SplitResult({this.errors = const <String>[], this.amounts = const <int>[]});

  final List<String> errors;
  final List<int> amounts;

  bool get isValid => errors.isEmpty;
}

/// Validates the allocation vectors of a line and splits its amount: by percentage (adding up to exactly 100) or by exact amount
/// (adding up to the line amount), with the Largest Remainder method so the parts never drift from the total.
SplitResult splitVectors(double lineAmount, List<AllocationVector> vectors) {
  if (vectors.isEmpty) {
    return const SplitResult(errors: <String>['vectorRequired']);
  }
  final int byPercentage = vectors
      .where((AllocationVector v) => v.percentage != null)
      .length;
  final int byAmount = vectors
      .where((AllocationVector v) => v.amount != null && v.percentage == null)
      .length;
  final List<String> errors = <String>[
    if (byPercentage > 0 && byAmount > 0) 'vectorMixedModes',
    if (!vectors.every((AllocationVector v) => v.hasTarget))
      'vectorTargetRequired',
  ];
  if (errors.isEmpty && byPercentage + byAmount != vectors.length) {
    errors.add('vectorValueRequired');
  }
  if (errors.isNotEmpty) {
    return SplitResult(errors: errors);
  }
  final int total = cents(lineAmount);
  if (byPercentage == vectors.length) {
    final List<int> weights = <int>[
      for (final AllocationVector v in vectors) (v.percentage! * 10000).round(),
    ];
    if (weights.fold<int>(0, (int a, int b) => a + b) != 1000000) {
      return const SplitResult(errors: <String>['vectorPercentSum']);
    }
    return SplitResult(amounts: allocateCents(total, weights));
  }
  final List<int> amounts = <int>[
    for (final AllocationVector v in vectors) cents(v.amount!),
  ];
  return amounts.fold<int>(0, (int a, int b) => a + b) == total
      ? SplitResult(amounts: amounts)
      : const SplitResult(errors: <String>['vectorAmountSum']);
}

/// One line of a manual analytical entry.
class EntryLineDraft {
  const EntryLineDraft({
    required this.amount,
    required this.costElementType,
    this.costCenterId,
    this.profitCenterId,
    this.vectors = const <AllocationVector>[],
  });

  final double amount;
  final String costElementType;
  final String? costCenterId;
  final String? profitCenterId;
  final List<AllocationVector> vectors;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'amount': amount.toStringAsFixed(2),
    'cost_element_type': costElementType,
    if (costCenterId != null) 'cost_center_id': costCenterId,
    if (profitCenterId != null) 'profit_center_id': profitCenterId,
    if (vectors.isNotEmpty)
      'vectors': <Map<String, dynamic>>[
        for (final AllocationVector v in vectors) v.toJson(),
      ],
  };
}

/// A manual analytical adjustment captured on the phone, queued offline and sent to `POST /analytical/entries`. It writes the
/// management ledger only, never the statutory ledger.
class EntryDraft {
  const EntryDraft({
    required this.postingDate,
    required this.lines,
    this.description,
  });

  /// `YYYY-MM-DD`.
  final String postingDate;
  final String? description;
  final List<EntryLineDraft> lines;

  /// The error codes of the draft; empty when it can be queued.
  List<String> validate() {
    if (lines.isEmpty) {
      return const <String>['entryNeedsLines'];
    }
    final Set<String> errors = <String>{};
    for (final EntryLineDraft line in lines) {
      if (!analyticalCostElementTypes.contains(line.costElementType)) {
        errors.add('invalidCostElement');
      }
      if (line.vectors.isNotEmpty) {
        errors.addAll(splitVectors(line.amount, line.vectors).errors);
      } else if (line.costCenterId == null && line.profitCenterId == null) {
        errors.add('vectorTargetRequired');
      }
    }
    return errors.toList();
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'posting_date': postingDate,
    if (description != null && description!.trim().isNotEmpty)
      'description': description,
    'lines': <Map<String, dynamic>>[
      for (final EntryLineDraft l in lines) l.toJson(),
    ],
  };

  String toJsonText() => jsonEncode(toJson());
}
