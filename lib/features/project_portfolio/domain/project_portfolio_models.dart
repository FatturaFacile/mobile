/// Models of the project portfolio and WBS (Mod 078), parsed from the sync payloads of `projects`, `wbs_nodes`,
/// `task_dependencies` and `project_baselines`.
///
/// Amounts and hours reach the app as decimal strings; they are parsed to doubles for display and for the local
/// roll-up and scheduling only, never for accounting. Enum values are read tolerantly: `on_hold`, `onHold` and
/// `ON_HOLD` are the same value, an unknown value falls back to a safe default.
library;

import 'dart:convert';

String _norm(Object? value) =>
    '$value'.replaceAll(RegExp('[_\\-\\s]'), '').toLowerCase();

T _enumFrom<T extends Enum>(List<T> values, Object? raw, T fallback) {
  final String wanted = _norm(raw);
  for (final T value in values) {
    if (_norm(value.name) == wanted) {
      return value;
    }
  }
  return fallback;
}

double? _number(Object? value) {
  if (value == null) {
    return null;
  }
  return value is num ? value.toDouble() : double.tryParse('$value');
}

double _amount(Object? value) => _number(value) ?? 0;

DateTime? _date(Object? value) {
  if (value == null || '$value'.isEmpty) {
    return null;
  }
  final DateTime? parsed = DateTime.tryParse('$value');
  if (parsed == null) {
    return null;
  }
  return DateTime.utc(parsed.year, parsed.month, parsed.day);
}

String? _dateOut(DateTime? value) => value == null
    ? null
    : '${value.year.toString().padLeft(4, '0')}-'
          '${value.month.toString().padLeft(2, '0')}-'
          '${value.day.toString().padLeft(2, '0')}';

String? _text(Object? value) {
  final String? text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

enum ProjectType {
  clientBillable('client_billable'),
  internalRAndD('internal_r_and_d'),
  capexInvestment('capex_investment');

  const ProjectType(this.wire);

  final String wire;
}

enum BillingModel {
  timeAndMaterials('time_and_materials'),
  fixedPrice('fixed_price'),
  salProgress('sal_progress'),
  retainer('retainer');

  const BillingModel(this.wire);

  final String wire;
}

enum ProjectStatus {
  planning('planning'),
  active('active'),
  onHold('on_hold'),
  completed('completed'),
  cancelled('cancelled');

  const ProjectStatus(this.wire);

  final String wire;
}

enum WbsNodeType {
  phase('phase'),
  deliverable('deliverable'),
  workPackage('work_package'),
  milestone('milestone');

  const WbsNodeType(this.wire);

  final String wire;
}

/// Precedence relation between two nodes: finish-to-start, start-to-start, finish-to-finish, start-to-finish.
enum DependencyType {
  fs('fs'),
  ss('ss'),
  ff('ff'),
  sf('sf');

  const DependencyType(this.wire);

  final String wire;
}

/// Kanban column of a node, derived from its progress (the contract has no separate task status).
enum WbsProgressState { notStarted, inProgress, done }

/// A commessa of the portfolio with the figures rolled up from its WBS.
class Project {
  const Project({
    required this.id,
    required this.tenantId,
    required this.projectCode,
    required this.name,
    this.legalEntityId,
    this.customerId,
    this.projectManagerId,
    this.projectType = ProjectType.clientBillable,
    this.billingModel = BillingModel.timeAndMaterials,
    this.costCenterId,
    this.startDate,
    this.targetEndDate,
    this.status = ProjectStatus.planning,
    this.cupCode,
    this.cigCode,
    this.plannedHours = 0,
    this.actualHours = 0,
    this.plannedCost = 0,
    this.actualCost = 0,
    this.plannedRevenue = 0,
    this.percentComplete = 0,
  });

  factory Project.fromJson(Map<String, dynamic> json) => Project(
    id: '${json['id']}',
    tenantId: '${json['tenant_id'] ?? ''}',
    legalEntityId: _text(json['legal_entity_id']),
    projectCode: '${json['project_code'] ?? ''}',
    name: '${json['name'] ?? ''}',
    customerId: _text(json['customer_id']),
    projectManagerId: _text(json['project_manager_id']),
    projectType: _enumFrom(
      ProjectType.values,
      json['project_type'],
      ProjectType.clientBillable,
    ),
    billingModel: _enumFrom(
      BillingModel.values,
      json['billing_model'],
      BillingModel.timeAndMaterials,
    ),
    costCenterId: _text(json['cost_center_id']),
    startDate: _date(json['start_date']),
    targetEndDate: _date(json['target_end_date']),
    status: _enumFrom(
      ProjectStatus.values,
      json['status'],
      ProjectStatus.planning,
    ),
    cupCode: _text(json['cup_code']),
    cigCode: _text(json['cig_code']),
    plannedHours: _amount(json['planned_hours']),
    actualHours: _amount(json['actual_hours']),
    plannedCost: _amount(json['planned_cost']),
    actualCost: _amount(json['actual_cost']),
    plannedRevenue: _amount(json['planned_revenue']),
    percentComplete: _amount(json['percent_complete']),
  );

  final String id;
  final String tenantId;
  final String? legalEntityId;
  final String projectCode;
  final String name;
  final String? customerId;
  final String? projectManagerId;
  final ProjectType projectType;
  final BillingModel billingModel;
  final String? costCenterId;
  final DateTime? startDate;
  final DateTime? targetEndDate;
  final ProjectStatus status;

  /// Codice Unico di Progetto (public investment), 15 alphanumeric characters.
  final String? cupCode;

  /// Codice Identificativo di Gara (public tender), 10 alphanumeric characters.
  final String? cigCode;
  final double plannedHours;
  final double actualHours;
  final double plannedCost;
  final double actualCost;
  final double plannedRevenue;
  final double percentComplete;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'tenant_id': tenantId,
    'legal_entity_id': legalEntityId,
    'project_code': projectCode,
    'name': name,
    'customer_id': customerId,
    'project_manager_id': projectManagerId,
    'project_type': projectType.wire,
    'billing_model': billingModel.wire,
    'cost_center_id': costCenterId,
    'start_date': _dateOut(startDate),
    'target_end_date': _dateOut(targetEndDate),
    'status': status.wire,
    'cup_code': cupCode,
    'cig_code': cigCode,
    'planned_hours': plannedHours,
    'actual_hours': actualHours,
    'planned_cost': plannedCost,
    'actual_cost': actualCost,
    'planned_revenue': plannedRevenue,
    'percent_complete': percentComplete,
  };

  Project copyWith({
    String? name,
    ProjectStatus? status,
    String? Function()? cupCode,
    String? Function()? cigCode,
    double? plannedHours,
    double? actualHours,
    double? plannedCost,
    double? actualCost,
    double? plannedRevenue,
    double? percentComplete,
  }) => Project(
    id: id,
    tenantId: tenantId,
    legalEntityId: legalEntityId,
    projectCode: projectCode,
    name: name ?? this.name,
    customerId: customerId,
    projectManagerId: projectManagerId,
    projectType: projectType,
    billingModel: billingModel,
    costCenterId: costCenterId,
    startDate: startDate,
    targetEndDate: targetEndDate,
    status: status ?? this.status,
    cupCode: cupCode == null ? this.cupCode : cupCode(),
    cigCode: cigCode == null ? this.cigCode : cigCode(),
    plannedHours: plannedHours ?? this.plannedHours,
    actualHours: actualHours ?? this.actualHours,
    plannedCost: plannedCost ?? this.plannedCost,
    actualCost: actualCost ?? this.actualCost,
    plannedRevenue: plannedRevenue ?? this.plannedRevenue,
    percentComplete: percentComplete ?? this.percentComplete,
  );
}

/// One node of the work breakdown structure: a phase, a deliverable, a work package or a milestone.
class WbsNode {
  const WbsNode({
    required this.id,
    required this.projectId,
    required this.wbsCode,
    required this.title,
    this.parentNodeId,
    this.nodeType = WbsNodeType.workPackage,
    this.plannedHours = 0,
    this.actualHours = 0,
    this.plannedCost = 0,
    this.actualCost = 0,
    this.plannedRevenue = 0,
    this.startDate,
    this.endDate,
    this.percentComplete = 0,
    this.sortOrder = 0,
    this.earlyStart,
    this.earlyFinish,
    this.lateStart,
    this.lateFinish,
    this.totalFloatDays,
    this.freeFloatDays,
    this.isCritical = false,
  });

  factory WbsNode.fromJson(Map<String, dynamic> json) => WbsNode(
    id: '${json['id']}',
    projectId: '${json['project_id'] ?? ''}',
    parentNodeId: _text(json['parent_node_id']),
    wbsCode: '${json['wbs_code'] ?? ''}',
    title: '${json['title'] ?? ''}',
    nodeType: _enumFrom(
      WbsNodeType.values,
      json['node_type'],
      WbsNodeType.workPackage,
    ),
    plannedHours: _amount(json['planned_hours']),
    actualHours: _amount(json['actual_hours']),
    plannedCost: _amount(json['planned_cost']),
    actualCost: _amount(json['actual_cost']),
    plannedRevenue: _amount(json['planned_revenue']),
    startDate: _date(json['start_date']),
    endDate: _date(json['end_date']),
    percentComplete: _amount(json['percent_complete']),
    sortOrder: _number(json['sort_order'])?.toInt() ?? 0,
    earlyStart: _date(json['early_start']),
    earlyFinish: _date(json['early_finish']),
    lateStart: _date(json['late_start']),
    lateFinish: _date(json['late_finish']),
    totalFloatDays: _number(json['total_float_days'])?.toInt(),
    freeFloatDays: _number(json['free_float_days'])?.toInt(),
    isCritical: json['is_critical'] == true || json['is_critical'] == 1,
  );

  final String id;
  final String projectId;
  final String? parentNodeId;

  /// Dotted outline code: `1`, `1.1`, `1.1.1`.
  final String wbsCode;
  final String title;
  final WbsNodeType nodeType;
  final double plannedHours;
  final double actualHours;
  final double plannedCost;
  final double actualCost;
  final double plannedRevenue;
  final DateTime? startDate;
  final DateTime? endDate;
  final double percentComplete;
  final int sortOrder;
  final DateTime? earlyStart;
  final DateTime? earlyFinish;
  final DateTime? lateStart;
  final DateTime? lateFinish;
  final int? totalFloatDays;
  final int? freeFloatDays;
  final bool isCritical;

  bool get isMilestone => nodeType == WbsNodeType.milestone;

  /// Depth in the outline, from the number of dots of the code (`1` is 0, `1.2.3` is 2).
  int get level => wbsCode.isEmpty ? 0 : '.'.allMatches(wbsCode).length;

  WbsProgressState get progressState => percentComplete >= 100
      ? WbsProgressState.done
      : percentComplete > 0
      ? WbsProgressState.inProgress
      : WbsProgressState.notStarted;

  /// The writable fields of the node, as sent to the server.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'project_id': projectId,
    'parent_node_id': parentNodeId,
    'wbs_code': wbsCode,
    'title': title,
    'node_type': nodeType.wire,
    'planned_hours': plannedHours,
    'actual_hours': actualHours,
    'planned_cost': plannedCost,
    'actual_cost': actualCost,
    'planned_revenue': plannedRevenue,
    'start_date': _dateOut(startDate),
    'end_date': _dateOut(endDate),
    'percent_complete': percentComplete,
    'sort_order': sortOrder,
  };

  WbsNode copyWith({
    String? wbsCode,
    String? title,
    WbsNodeType? nodeType,
    double? plannedHours,
    double? actualHours,
    double? plannedCost,
    double? actualCost,
    double? plannedRevenue,
    DateTime? Function()? startDate,
    DateTime? Function()? endDate,
    double? percentComplete,
    int? sortOrder,
    DateTime? Function()? earlyStart,
    DateTime? Function()? earlyFinish,
    DateTime? Function()? lateStart,
    DateTime? Function()? lateFinish,
    int? Function()? totalFloatDays,
    int? Function()? freeFloatDays,
    bool? isCritical,
  }) => WbsNode(
    id: id,
    projectId: projectId,
    parentNodeId: parentNodeId,
    wbsCode: wbsCode ?? this.wbsCode,
    title: title ?? this.title,
    nodeType: nodeType ?? this.nodeType,
    plannedHours: plannedHours ?? this.plannedHours,
    actualHours: actualHours ?? this.actualHours,
    plannedCost: plannedCost ?? this.plannedCost,
    actualCost: actualCost ?? this.actualCost,
    plannedRevenue: plannedRevenue ?? this.plannedRevenue,
    startDate: startDate == null ? this.startDate : startDate(),
    endDate: endDate == null ? this.endDate : endDate(),
    percentComplete: percentComplete ?? this.percentComplete,
    sortOrder: sortOrder ?? this.sortOrder,
    earlyStart: earlyStart == null ? this.earlyStart : earlyStart(),
    earlyFinish: earlyFinish == null ? this.earlyFinish : earlyFinish(),
    lateStart: lateStart == null ? this.lateStart : lateStart(),
    lateFinish: lateFinish == null ? this.lateFinish : lateFinish(),
    totalFloatDays: totalFloatDays == null
        ? this.totalFloatDays
        : totalFloatDays(),
    freeFloatDays: freeFloatDays == null ? this.freeFloatDays : freeFloatDays(),
    isCritical: isCritical ?? this.isCritical,
  );
}

/// A precedence link between two nodes of one project, with a lag (negative: lead) in days.
class TaskDependency {
  const TaskDependency({
    required this.id,
    required this.projectId,
    required this.predecessorNodeId,
    required this.successorNodeId,
    this.dependencyType = DependencyType.fs,
    this.lagDays = 0,
  });

  factory TaskDependency.fromJson(Map<String, dynamic> json) => TaskDependency(
    id: '${json['id']}',
    projectId: '${json['project_id'] ?? ''}',
    predecessorNodeId: '${json['predecessor_node_id'] ?? ''}',
    successorNodeId: '${json['successor_node_id'] ?? ''}',
    dependencyType: _enumFrom(
      DependencyType.values,
      json['dependency_type'],
      DependencyType.fs,
    ),
    lagDays: _number(json['lag_days'])?.toInt() ?? 0,
  );

  final String id;
  final String projectId;
  final String predecessorNodeId;
  final String successorNodeId;
  final DependencyType dependencyType;
  final int lagDays;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'project_id': projectId,
    'predecessor_node_id': predecessorNodeId,
    'successor_node_id': successorNodeId,
    'dependency_type': dependencyType.wire,
    'lag_days': lagDays,
  };
}

/// A frozen copy of the plan: the nodes as they were when the baseline was captured.
class ProjectBaseline {
  const ProjectBaseline({
    required this.id,
    required this.projectId,
    required this.baselineNumber,
    required this.name,
    required this.capturedAt,
    required this.snapshotJson,
  });

  factory ProjectBaseline.fromJson(Map<String, dynamic> json) {
    final Object? snapshot = json['snapshot_json'];
    return ProjectBaseline(
      id: '${json['id']}',
      projectId: '${json['project_id'] ?? ''}',
      baselineNumber: _number(json['baseline_number'])?.toInt() ?? 0,
      name: '${json['name'] ?? ''}',
      capturedAt:
          DateTime.tryParse('${json['captured_at']}')?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      snapshotJson: snapshot is String
          ? snapshot
          : snapshot == null
          ? '{}'
          : jsonEncode(snapshot),
    );
  }

  final String id;
  final String projectId;
  final int baselineNumber;
  final String name;
  final DateTime capturedAt;

  /// JSON text of the frozen plan: `{"nodes": [{id, wbs_code, title, start_date, end_date, planned_hours,
  /// planned_cost, planned_revenue}]}`. Parsed by `BaselineVariance`.
  final String snapshotJson;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'project_id': projectId,
    'baseline_number': baselineNumber,
    'name': name,
    'captured_at': capturedAt.toUtc().toIso8601String(),
    'snapshot_json': snapshotJson,
  };
}
