/// Parses decimal strings / numbers produced by the API (`"12.500"`) into a double.
double mfgNum(Object? value, [double fallback = 0]) {
  if (value == null) {
    return fallback;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value.toString()) ?? fallback;
}

double? mfgNumOrNull(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value.toString());
}

int mfgInt(Object? value, [int fallback = 0]) {
  if (value == null) {
    return fallback;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value.toString()) ?? fallback;
}

String? mfgStr(Object? value) => value?.toString();

/// Work centre (`GET /manufacturing/work-centers`).
class MfgWorkCenter {
  const MfgWorkCenter({
    required this.id,
    required this.code,
    required this.name,
    this.status = 'active',
    this.departmentCode,
    this.costCenterId,
    this.capacityHoursPerDay = 0,
    this.efficiencyPercent = 100,
    this.parallelCapacityUnits = 1,
    this.oeeTargetPercent = 85,
    this.hourlyCostRate = 0,
    this.hourlyOverheadRate = 0,
    this.hourlySetupCostRate = 0,
    this.hourlyMachineRunCostRate = 0,
    this.defaultQueueWaitMinutes = 0,
    this.defaultMoveTimeMinutes = 0,
    this.currencyCode = 'EUR',
  });

  factory MfgWorkCenter.fromJson(Map<String, dynamic> json) {
    return MfgWorkCenter(
      id: json['id'].toString(),
      code: (json['work_center_code'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      status: (json['status'] ?? 'active').toString(),
      departmentCode: mfgStr(json['department_code']),
      costCenterId: mfgStr(json['cost_center_id']),
      capacityHoursPerDay: mfgNum(json['capacity_hours_per_day']),
      efficiencyPercent: mfgNum(
        json['efficiency_factor_percent'] ?? json['efficiency_rate'],
        100,
      ),
      parallelCapacityUnits: mfgInt(json['parallel_capacity_units'], 1),
      oeeTargetPercent: mfgNum(json['oee_target_percent'], 85),
      hourlyCostRate: mfgNum(
        json['hourly_labor_cost_rate'] ?? json['hourly_cost_rate'],
      ),
      hourlyOverheadRate: mfgNum(json['hourly_overhead_rate']),
      hourlySetupCostRate: mfgNum(json['hourly_setup_cost_rate']),
      hourlyMachineRunCostRate: mfgNum(json['hourly_machine_run_cost_rate']),
      defaultQueueWaitMinutes: mfgNum(json['default_queue_wait_minutes']),
      defaultMoveTimeMinutes: mfgNum(json['default_move_time_minutes']),
      currencyCode: (json['currency_code'] ?? 'EUR').toString(),
    );
  }

  final String id;
  final String code;
  final String name;
  final String status;
  final String? departmentCode;
  final String? costCenterId;
  final double capacityHoursPerDay;
  final double efficiencyPercent;
  final int parallelCapacityUnits;
  final double oeeTargetPercent;
  final double hourlyCostRate;
  final double hourlyOverheadRate;
  final double hourlySetupCostRate;
  final double hourlyMachineRunCostRate;
  final double defaultQueueWaitMinutes;
  final double defaultMoveTimeMinutes;
  final String currencyCode;
}

/// Machine of a work centre (`GET /manufacturing/machines`).
class MfgMachine {
  const MfgMachine({
    required this.id,
    required this.code,
    required this.name,
    required this.workCenterId,
    this.status = 'active',
    this.manufacturer,
    this.model,
    this.serialNumber,
    this.industria40 = false,
    this.transizione50 = false,
    this.telemetryStatus,
    this.telemetryLastSeenAt,
    this.idealCycleTimeSecondsPerUnit = 0,
    this.parallelCapacityUnits = 1,
    this.efficiencyFactorPercent,
    this.hourlyMachineRunCostRateOverride,
  });

  factory MfgMachine.fromJson(Map<String, dynamic> json) {
    final String? seen = mfgStr(json['telemetry_last_seen_at']);
    return MfgMachine(
      id: json['id'].toString(),
      code: (json['machine_code'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      workCenterId: (json['work_center_id'] ?? '').toString(),
      status: (json['status'] ?? 'active').toString(),
      manufacturer: mfgStr(json['manufacturer']),
      model: mfgStr(json['model']),
      serialNumber: mfgStr(json['serial_number']),
      industria40: json['is_industria_40_enabled'] == true,
      transizione50: json['is_transizione_50_enabled'] == true,
      telemetryStatus: mfgStr(json['telemetry_status']),
      telemetryLastSeenAt: seen == null ? null : DateTime.tryParse(seen),
      idealCycleTimeSecondsPerUnit: mfgNum(
        json['ideal_cycle_time_seconds_per_unit'],
      ),
      parallelCapacityUnits: mfgInt(json['parallel_capacity_units'], 1),
      efficiencyFactorPercent: mfgNumOrNull(json['efficiency_factor_percent']),
      hourlyMachineRunCostRateOverride: mfgNumOrNull(
        json['hourly_machine_run_cost_rate_override'],
      ),
    );
  }

  final String id;
  final String code;
  final String name;
  final String workCenterId;
  final String status;
  final String? manufacturer;
  final String? model;
  final String? serialNumber;
  final bool industria40;
  final bool transizione50;
  final String? telemetryStatus;
  final DateTime? telemetryLastSeenAt;
  final double idealCycleTimeSecondsPerUnit;
  final int parallelCapacityUnits;
  final double? efficiencyFactorPercent;
  final double? hourlyMachineRunCostRateOverride;
}

/// One operation step of a routing.
class MfgRoutingStep {
  const MfgRoutingStep({
    required this.id,
    required this.sequence,
    required this.operationCode,
    required this.name,
    required this.workCenterId,
    this.machineCenterId,
    this.operationType = 'internal_machining',
    this.setupTimeMinutes = 0,
    this.runTimeMinutesPerUnit = 0,
    this.laborTimeMinutesPerUnit = 0,
    this.queueTimeMinutes = 0,
    this.postOperationWaitMinutes = 0,
    this.moveTimeMinutes = 0,
    this.overlapTransferBatchQty,
    this.requiredOperators = 1,
    this.isSubcontracted = false,
    this.subcontractUnitCost = 0,
  });

  factory MfgRoutingStep.fromJson(Map<String, dynamic> json) {
    return MfgRoutingStep(
      id: json['id'].toString(),
      sequence: mfgInt(json['sequence']),
      operationCode: (json['operation_code'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      workCenterId: (json['work_center_id'] ?? '').toString(),
      machineCenterId: mfgStr(json['machine_center_id']),
      operationType: (json['operation_type'] ?? 'internal_machining')
          .toString(),
      setupTimeMinutes: mfgNum(json['setup_time_minutes']),
      runTimeMinutesPerUnit: mfgNum(json['run_time_minutes_per_unit']),
      laborTimeMinutesPerUnit: mfgNum(json['labor_time_minutes_per_unit']),
      queueTimeMinutes: mfgNum(json['queue_time_minutes']),
      postOperationWaitMinutes: mfgNum(json['post_operation_wait_minutes']),
      moveTimeMinutes: mfgNum(json['move_time_minutes']),
      overlapTransferBatchQty: mfgNumOrNull(json['overlap_transfer_batch_qty']),
      requiredOperators: mfgInt(json['required_operators'], 1),
      isSubcontracted: json['is_subcontracted'] == true,
      subcontractUnitCost: mfgNum(json['subcontract_unit_cost']),
    );
  }

  final String id;
  final int sequence;
  final String operationCode;
  final String name;
  final String workCenterId;
  final String? machineCenterId;
  final String operationType;
  final double setupTimeMinutes;
  final double runTimeMinutesPerUnit;
  final double laborTimeMinutesPerUnit;
  final double queueTimeMinutes;
  final double postOperationWaitMinutes;
  final double moveTimeMinutes;
  final double? overlapTransferBatchQty;
  final int requiredOperators;
  final bool isSubcontracted;
  final double subcontractUnitCost;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'sequence': sequence,
    'operation_code': operationCode,
    'name': name,
    'work_center_id': workCenterId,
    'machine_center_id': machineCenterId,
    'operation_type': operationType,
    'setup_time_minutes': setupTimeMinutes,
    'run_time_minutes_per_unit': runTimeMinutesPerUnit,
    'labor_time_minutes_per_unit': laborTimeMinutesPerUnit,
    'queue_time_minutes': queueTimeMinutes,
    'post_operation_wait_minutes': postOperationWaitMinutes,
    'move_time_minutes': moveTimeMinutes,
    'overlap_transfer_batch_qty': overlapTransferBatchQty,
    'required_operators': requiredOperators,
    'is_subcontracted': isSubcontracted,
    'subcontract_unit_cost': subcontractUnitCost,
  };
}

/// Routing with its ordered steps (`GET /manufacturing/routings`).
class MfgRouting {
  const MfgRouting({
    required this.id,
    required this.routingNumber,
    required this.name,
    required this.revision,
    required this.status,
    this.isDefault = false,
    this.itemCode,
    this.itemName,
    this.effectiveFrom,
    this.effectiveTo,
    this.steps = const <MfgRoutingStep>[],
  });

  factory MfgRouting.fromJson(Map<String, dynamic> json) {
    final Object? ops = json['operations'];
    final List<MfgRoutingStep> steps = ops is List
        ? (ops
              .whereType<Map<dynamic, dynamic>>()
              .map(
                (Map<dynamic, dynamic> m) =>
                    MfgRoutingStep.fromJson(Map<String, dynamic>.from(m)),
              )
              .toList()
            ..sort(
              (MfgRoutingStep a, MfgRoutingStep b) =>
                  a.sequence.compareTo(b.sequence),
            ))
        : <MfgRoutingStep>[];
    return MfgRouting(
      id: json['id'].toString(),
      routingNumber: (json['routing_number'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      revision: (json['revision'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      isDefault: json['is_default'] == true,
      itemCode: mfgStr(json['item_code']),
      itemName: mfgStr(json['item_name']),
      effectiveFrom: mfgStr(json['effective_from']),
      effectiveTo: mfgStr(json['effective_to']),
      steps: steps,
    );
  }

  final String id;
  final String routingNumber;
  final String name;
  final String revision;
  final String status;
  final bool isDefault;
  final String? itemCode;
  final String? itemName;
  final String? effectiveFrom;
  final String? effectiveTo;
  final List<MfgRoutingStep> steps;
}

/// One factor block of an OEE period (`data.summary`).
class MfgOeeMetrics {
  const MfgOeeMetrics({
    this.scheduledMinutes = 0,
    this.plannedProductionMinutes = 0,
    this.unplannedDowntimeMinutes = 0,
    this.operatingMinutes = 0,
    this.goodUnits = 0,
    this.scrapUnits = 0,
    this.reworkUnits = 0,
    this.totalUnits = 0,
    this.availabilityPercent = 0,
    this.performancePercent = 0,
    this.qualityPercent = 0,
    this.oeePercent = 0,
  });

  factory MfgOeeMetrics.fromJson(Map<String, dynamic> json) {
    return MfgOeeMetrics(
      scheduledMinutes: mfgNum(json['scheduled_minutes']),
      plannedProductionMinutes: mfgNum(json['planned_production_minutes']),
      unplannedDowntimeMinutes: mfgNum(json['unplanned_downtime_minutes']),
      operatingMinutes: mfgNum(json['operating_minutes']),
      goodUnits: mfgNum(json['good_units']),
      scrapUnits: mfgNum(json['scrap_units']),
      reworkUnits: mfgNum(json['rework_units']),
      totalUnits: mfgNum(json['total_units']),
      availabilityPercent: mfgNum(json['availability_percent']),
      performancePercent: mfgNum(json['performance_percent']),
      qualityPercent: mfgNum(json['quality_percent']),
      oeePercent: mfgNum(json['oee_percent']),
    );
  }

  final double scheduledMinutes;
  final double plannedProductionMinutes;
  final double unplannedDowntimeMinutes;
  final double operatingMinutes;
  final double goodUnits;
  final double scrapUnits;
  final double reworkUnits;
  final double totalUnits;
  final double availabilityPercent;
  final double performancePercent;
  final double qualityPercent;
  final double oeePercent;
}

/// `GET /manufacturing/oee/summary` for a work centre (optionally one machine) and period.
class MfgOeeSummary {
  const MfgOeeSummary({
    required this.workCenterId,
    required this.from,
    required this.to,
    required this.metrics,
    required this.targetOeePercent,
    required this.meetsTarget,
    required this.gapToTargetPercent,
    this.machineCenterId,
    this.losses = const <String, double>{},
  });

  factory MfgOeeSummary.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> targets = json['targets_percent'] is Map
        ? Map<String, dynamic>.from(json['targets_percent'] as Map)
        : <String, dynamic>{};
    final Map<String, double> losses = <String, double>{};
    final Object? raw = json['six_big_losses'];
    if (raw is Map) {
      raw.forEach((Object? key, Object? value) {
        if (value is Map) {
          losses[key.toString()] = mfgNum(value['minutes']);
        }
      });
    }
    return MfgOeeSummary(
      workCenterId: json['work_center_id'].toString(),
      machineCenterId: mfgStr(json['machine_center_id']),
      from: DateTime.parse(json['from'].toString()),
      to: DateTime.parse(json['to'].toString()),
      metrics: MfgOeeMetrics.fromJson(
        json['summary'] is Map
            ? Map<String, dynamic>.from(json['summary'] as Map)
            : <String, dynamic>{},
      ),
      targetOeePercent: mfgNum(targets['oee']),
      meetsTarget: json['meets_target'] == true,
      gapToTargetPercent: mfgNum(json['gap_to_target_percent']),
      losses: losses,
    );
  }

  final String workCenterId;
  final String? machineCenterId;
  final DateTime from;
  final DateTime to;
  final MfgOeeMetrics metrics;
  final double targetOeePercent;
  final bool meetsTarget;
  final double gapToTargetPercent;

  /// Lost minutes per big-loss category.
  final Map<String, double> losses;
}
