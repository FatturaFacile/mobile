/// Result classification returned by the Mod 019 Cost Center budget check.
enum BudgetCheckStatus {
  ok('ok'),
  warning('warning'),
  hardBlock('hard_block');

  const BudgetCheckStatus(this.wireValue);

  /// REST API and SQLite wire value.
  final String wireValue;

  /// Parses a wire value into a [BudgetCheckStatus], defaulting to [BudgetCheckStatus.ok].
  static BudgetCheckStatus fromWire(String? raw) {
    return BudgetCheckStatus.values.firstWhere(
      (BudgetCheckStatus s) => s.wireValue == raw,
      orElse: () => BudgetCheckStatus.ok,
    );
  }
}

/// Real-time Cost Center budget check snapshot (`POST /budget-preview` or `/submit`).
class BudgetCheckResult {
  const BudgetCheckResult({
    required this.status,
    required this.costCenterId,
    required this.costCenterCode,
    required this.currency,
    required this.allocatedBudget,
    required this.committedAmount,
    required this.spentAmount,
    required this.availableBudget,
    required this.requestedAmount,
    required this.remainingAfterRequest,
    required this.utilizationPercent,
    required this.warningThresholdPercent,
    required this.message,
    required this.checkedAt,
    this.fiscalYear,
  });

  /// Parses a [BudgetCheckResult] from JSON payload.
  factory BudgetCheckResult.fromJson(Map<String, dynamic> json) {
    final double allocated = _toDouble(json['allocated_budget']);
    final double committed = _toDouble(json['committed_amount']);
    final double spent = _toDouble(json['spent_amount']);
    final double available = json['available_budget'] != null
        ? _toDouble(json['available_budget'])
        : (allocated - committed - spent);
    final double requested = _toDouble(json['requested_amount']);
    final double remaining = json['remaining_after_request'] != null
        ? _toDouble(json['remaining_after_request'])
        : (available - requested);
    final double utilization = json['utilization_percent'] != null
        ? _toDouble(json['utilization_percent'])
        : (allocated > 0
              ? ((committed + spent + requested) / allocated) * 100
              : 0);

    return BudgetCheckResult(
      status: BudgetCheckStatus.fromWire(json['status']?.toString()),
      costCenterId: json['cost_center_id']?.toString() ?? '',
      costCenterCode: json['cost_center_code']?.toString() ?? '',
      currency: json['currency']?.toString() ?? 'CHF',
      allocatedBudget: allocated,
      committedAmount: committed,
      spentAmount: spent,
      availableBudget: available,
      requestedAmount: requested,
      remainingAfterRequest: remaining,
      utilizationPercent: utilization,
      warningThresholdPercent: _toDouble(
        json['warning_threshold_percent'],
        fallback: 85,
      ),
      message: json['message']?.toString() ?? '',
      checkedAt:
          DateTime.tryParse(json['checked_at']?.toString() ?? '') ??
          DateTime.now().toUtc(),
      fiscalYear: (json['fiscal_year'] as num?)?.toInt(),
    );
  }

  final BudgetCheckStatus status;
  final String costCenterId;
  final String costCenterCode;
  final String currency;
  final double allocatedBudget;
  final double committedAmount;
  final double spentAmount;
  final double availableBudget;
  final double requestedAmount;
  final double remainingAfterRequest;
  final double utilizationPercent;
  final double warningThresholdPercent;
  final String message;
  final DateTime checkedAt;
  final int? fiscalYear;

  /// Serializes this snapshot to JSON for local SQLite caching (`budget_check_snapshot_json`).
  Map<String, dynamic> toJson() => <String, dynamic>{
    'status': status.wireValue,
    'cost_center_id': costCenterId,
    'cost_center_code': costCenterCode,
    'currency': currency,
    'allocated_budget': allocatedBudget,
    'committed_amount': committedAmount,
    'spent_amount': spentAmount,
    'available_budget': availableBudget,
    'requested_amount': requestedAmount,
    'remaining_after_request': remainingAfterRequest,
    'utilization_percent': utilizationPercent,
    'warning_threshold_percent': warningThresholdPercent,
    'message': message,
    'checked_at': checkedAt.toUtc().toIso8601String(),
    if (fiscalYear != null) 'fiscal_year': fiscalYear,
  };
}

/// Request line payload sent to `POST /procurement/purchase-requisitions/budget-preview`.
class BudgetPreviewLineInput {
  const BudgetPreviewLineInput({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    this.catalogItemId,
  });

  final String? catalogItemId;
  final String description;
  final double quantity;
  final double unitPrice;

  /// Serializes this line for budget preview API evaluation.
  Map<String, dynamic> toJson() => <String, dynamic>{
    if (catalogItemId != null) 'catalog_item_id': catalogItemId,
    'description': description,
    'quantity': quantity,
    'unit_price': unitPrice,
  };
}

/// Request payload for `POST /procurement/purchase-requisitions/budget-preview`.
class BudgetPreviewRequest {
  const BudgetPreviewRequest({
    required this.costCenterId,
    required this.currency,
    required this.totalAmount,
    required this.lines,
    this.projectId,
  });

  final String costCenterId;
  final String? projectId;
  final String currency;
  final double totalAmount;
  final List<BudgetPreviewLineInput> lines;

  /// Serializes the preview request body.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'cost_center_id': costCenterId,
    if (projectId != null && projectId!.isNotEmpty) 'project_id': projectId,
    'currency': currency,
    'total_amount': totalAmount,
    'lines': lines.map((BudgetPreviewLineInput l) => l.toJson()).toList(),
  };
}

double _toDouble(Object? raw, {double fallback = 0}) {
  if (raw is num) {
    return raw.toDouble();
  }
  return double.tryParse(raw?.toString() ?? '') ?? fallback;
}
