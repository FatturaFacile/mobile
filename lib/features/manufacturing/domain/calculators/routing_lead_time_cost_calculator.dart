import '../entities/manufacturing_models.dart';

/// Lead time and standard cost of one routing step for a lot.
class RoutingStepResult {
  const RoutingStepResult({
    required this.operationId,
    required this.sequence,
    required this.operationCode,
    required this.queueMinutes,
    required this.setupMinutes,
    required this.runMinutes,
    required this.postOperationWaitMinutes,
    required this.moveMinutes,
    required this.durationMinutes,
    required this.startOffsetMinutes,
    required this.endOffsetMinutes,
    required this.overlapApplied,
    required this.cost,
  });

  final String operationId;
  final int sequence;
  final String operationCode;
  final double queueMinutes;
  final double setupMinutes;
  final double runMinutes;
  final double postOperationWaitMinutes;
  final double moveMinutes;
  final double durationMinutes;
  final double startOffsetMinutes;
  final double endOffsetMinutes;
  final bool overlapApplied;
  final RoutingCostBreakdown cost;
}

/// Standard cost split (same keys as the API `cost` block).
class RoutingCostBreakdown {
  const RoutingCostBreakdown({
    this.setup = 0,
    this.machineRun = 0,
    this.directLabor = 0,
    this.overhead = 0,
    this.subcontracting = 0,
    this.material = 0,
  });

  final double setup;
  final double machineRun;
  final double directLabor;
  final double overhead;
  final double subcontracting;

  /// Always 0 offline: the BOM component costs are not mirrored on the device.
  final double material;

  double get total =>
      setup + machineRun + directLabor + overhead + subcontracting + material;
}

/// Result of [RoutingLeadTimeCostCalculator.calculate].
class RoutingLeadTimeCostResult {
  const RoutingLeadTimeCostResult({
    required this.quantity,
    required this.includeOverlap,
    required this.totalMinutes,
    required this.serialMinutes,
    required this.overlapSavingMinutes,
    required this.steps,
    required this.cost,
    required this.unitCost,
  });

  final double quantity;
  final bool includeOverlap;
  final double totalMinutes;
  final double serialMinutes;
  final double overlapSavingMinutes;
  final List<RoutingStepResult> steps;
  final RoutingCostBreakdown cost;
  final double unitCost;
}

/// Thrown when the inputs cannot be calculated (mirrors `ManufacturingOperationException`).
class RoutingCalculationException implements Exception {
  const RoutingCalculationException(this.field);

  /// `quantity`, `routing_id` or `work_center_id`.
  final String field;

  @override
  String toString() => 'RoutingCalculationException($field)';
}

/// Pure-Dart mirror of the backend `RoutingLeadTimeCostCalculator` (Mod 061).
///
/// Effective run time = run per unit x quantity / (parallel units x efficiency / 100); setup is a lot time and is not
/// scaled. Queue, post-operation wait and move are clock-time waits. Overlap: when a step has a transfer batch below
/// the lot, the next step starts after the first batch has been queued, set up, run, cooled and moved, but cannot end
/// before the last batch of the lot reached it and was processed there.
///
/// Differences from the server: no working-calendar projection (`start_at`/`end_at`) and no BOM material cost.
abstract final class RoutingLeadTimeCostCalculator {
  static RoutingLeadTimeCostResult calculate(
    MfgRouting routing, {
    required Map<String, MfgWorkCenter> workCenters,
    Map<String, MfgMachine> machines = const <String, MfgMachine>{},
    double quantity = 1,
    bool includeOverlap = true,
  }) {
    if (quantity <= 0) {
      throw const RoutingCalculationException('quantity');
    }
    if (routing.steps.isEmpty) {
      throw const RoutingCalculationException('routing_id');
    }
    final List<_Step> steps = <_Step>[
      for (final MfgRoutingStep s in routing.steps)
        _step(s, workCenters, machines, quantity),
    ];
    final _Timeline timeline = _timeline(steps, quantity, includeOverlap);
    final double serial = steps.fold<double>(
      0,
      (double sum, _Step s) => sum + s.duration,
    );

    final List<RoutingCostBreakdown> costs = steps
        .map((_Step s) => _cost(s, quantity))
        .toList();
    final RoutingCostBreakdown total = RoutingCostBreakdown(
      setup: _round4(costs.fold<double>(0, (double a, c) => a + c.setup)),
      machineRun: _round4(
        costs.fold<double>(0, (double a, c) => a + c.machineRun),
      ),
      directLabor: _round4(
        costs.fold<double>(0, (double a, c) => a + c.directLabor),
      ),
      overhead: _round4(costs.fold<double>(0, (double a, c) => a + c.overhead)),
      subcontracting: _round4(
        costs.fold<double>(0, (double a, c) => a + c.subcontracting),
      ),
    );

    return RoutingLeadTimeCostResult(
      quantity: _round4(quantity),
      includeOverlap: includeOverlap,
      totalMinutes: _round3(timeline.total),
      serialMinutes: _round3(serial),
      overlapSavingMinutes: _round3(serial - timeline.total),
      unitCost: _round4(total.total / quantity),
      cost: total,
      steps: <RoutingStepResult>[
        for (int i = 0; i < steps.length; i++)
          RoutingStepResult(
            operationId: steps[i].id,
            sequence: steps[i].sequence,
            operationCode: steps[i].code,
            queueMinutes: _round3(steps[i].queue),
            setupMinutes: _round3(steps[i].setup),
            runMinutes: _round3(steps[i].run),
            postOperationWaitMinutes: _round3(steps[i].post),
            moveMinutes: _round3(steps[i].move),
            durationMinutes: _round3(steps[i].duration),
            startOffsetMinutes: _round3(timeline.starts[i]),
            endOffsetMinutes: _round3(timeline.ends[i]),
            overlapApplied: timeline.overlapped[i],
            cost: RoutingCostBreakdown(
              setup: _round4(costs[i].setup),
              machineRun: _round4(costs[i].machineRun),
              directLabor: _round4(costs[i].directLabor),
              overhead: _round4(costs[i].overhead),
              subcontracting: _round4(costs[i].subcontracting),
            ),
          ),
      ],
    );
  }

  static _Step _step(
    MfgRoutingStep op,
    Map<String, MfgWorkCenter> workCenters,
    Map<String, MfgMachine> machines,
    double qty,
  ) {
    final MfgWorkCenter? wc = workCenters[op.workCenterId];
    if (wc == null) {
      throw const RoutingCalculationException('work_center_id');
    }
    final MfgMachine? machine = op.machineCenterId == null
        ? null
        : machines[op.machineCenterId];
    final bool subcontracted =
        op.operationType == 'external_subcontracting' || op.isSubcontracted;

    final int parallel =
        (machine?.parallelCapacityUnits ?? wc.parallelCapacityUnits).clamp(
          1,
          1 << 30,
        );
    double efficiency =
        machine?.efficiencyFactorPercent ?? wc.efficiencyPercent;
    if (efficiency <= 0) {
      efficiency = 100;
    }
    final double divisor = parallel * (efficiency / 100);

    final double run = (op.runTimeMinutesPerUnit * qty) / divisor;
    final double laborPerUnit = op.laborTimeMinutesPerUnit > 0
        ? op.laborTimeMinutesPerUnit
        : op.runTimeMinutesPerUnit;
    final double labor = (laborPerUnit * qty) / divisor;
    final double queue = op.queueTimeMinutes > 0
        ? op.queueTimeMinutes
        : wc.defaultQueueWaitMinutes;
    final double move = op.moveTimeMinutes > 0
        ? op.moveTimeMinutes
        : wc.defaultMoveTimeMinutes;
    final double overlap = op.overlapTransferBatchQty ?? 0;

    return _Step(
      id: op.id,
      sequence: op.sequence,
      code: op.operationCode,
      subcontracted: subcontracted,
      machineCosted: op.operationType == 'internal_machining' && !subcontracted,
      queue: queue,
      setup: op.setupTimeMinutes,
      run: run,
      labor: labor,
      post: op.postOperationWaitMinutes,
      move: move,
      overlapBatch: overlap > 0 && overlap < qty ? overlap : null,
      operators: op.requiredOperators < 1 ? 1 : op.requiredOperators,
      setupRate: wc.hourlySetupCostRate,
      machineRate:
          machine?.hourlyMachineRunCostRateOverride ??
          wc.hourlyMachineRunCostRate,
      laborRate: wc.hourlyCostRate,
      overheadRate: wc.hourlyOverheadRate,
      subcontractUnitCost: op.subcontractUnitCost,
    );
  }

  static _Timeline _timeline(List<_Step> steps, double qty, bool overlap) {
    final List<double> starts = <double>[];
    final List<double> ends = <double>[];
    final List<bool> overlapped = <bool>[];
    double start = 0;
    double floor = 0;
    for (int i = 0; i < steps.length; i++) {
      final _Step step = steps[i];
      final double end = (start + step.duration) > floor
          ? start + step.duration
          : floor;
      starts.add(start);
      ends.add(end);
      final double? batch = overlap ? step.overlapBatch : null;
      final bool hasNext = i + 1 < steps.length;
      overlapped.add(batch != null && hasNext);
      if (batch != null && hasNext) {
        final _Step next = steps[i + 1];
        start +=
            step.queue +
            step.setup +
            (step.run * batch / qty) +
            step.post +
            step.move;
        floor = end + (next.run * batch / qty) + next.post + next.move;
      } else {
        start = end;
        floor = 0;
      }
    }
    return _Timeline(
      starts,
      ends,
      overlapped,
      ends.reduce((double a, double b) => a > b ? a : b),
    );
  }

  static RoutingCostBreakdown _cost(_Step s, double qty) {
    if (s.subcontracted) {
      return RoutingCostBreakdown(subcontracting: s.subcontractUnitCost * qty);
    }
    final double basis = s.setup + s.run;
    return RoutingCostBreakdown(
      setup: (s.setup / 60) * s.setupRate,
      machineRun: s.machineCosted ? (s.run / 60) * s.machineRate : 0,
      directLabor: (s.labor / 60) * s.laborRate * s.operators,
      overhead: (basis / 60) * s.overheadRate,
    );
  }

  static double _round3(double v) => (v * 1000).roundToDouble() / 1000;
  static double _round4(double v) => (v * 10000).roundToDouble() / 10000;
}

class _Step {
  const _Step({
    required this.id,
    required this.sequence,
    required this.code,
    required this.subcontracted,
    required this.machineCosted,
    required this.queue,
    required this.setup,
    required this.run,
    required this.labor,
    required this.post,
    required this.move,
    required this.overlapBatch,
    required this.operators,
    required this.setupRate,
    required this.machineRate,
    required this.laborRate,
    required this.overheadRate,
    required this.subcontractUnitCost,
  });

  final String id;
  final int sequence;
  final String code;
  final bool subcontracted;
  final bool machineCosted;
  final double queue;
  final double setup;
  final double run;
  final double labor;
  final double post;
  final double move;
  final double? overlapBatch;
  final int operators;
  final double setupRate;
  final double machineRate;
  final double laborRate;
  final double overheadRate;
  final double subcontractUnitCost;

  double get duration => queue + setup + run + post + move;
}

class _Timeline {
  const _Timeline(this.starts, this.ends, this.overlapped, this.total);

  final List<double> starts;
  final List<double> ends;
  final List<bool> overlapped;
  final double total;
}
