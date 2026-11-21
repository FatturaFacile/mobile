/// Domain models of the shop-floor (MES) client. Quantities arrive as decimal strings from the API.
double _num(Object? v) =>
    v == null ? 0 : (v is num ? v.toDouble() : double.tryParse('$v') ?? 0);

String? _str(Object? v) => v == null ? null : '$v';

List<Map<String, dynamic>> _maps(Object? v) => <Map<String, dynamic>>[
  for (final dynamic e in (v as List<dynamic>? ?? const <dynamic>[]))
    Map<String, dynamic>.from(e as Map),
];

/// One material line of a production order (component to be issued or backflushed).
class OrderLine {
  const OrderLine({
    required this.id,
    required this.itemId,
    required this.issueMethod,
    required this.requiredQuantity,
    required this.issuedQuantity,
    required this.uom,
    this.operationSequence,
    this.itemCode,
    this.itemName,
  });

  factory OrderLine.fromJson(Map<String, dynamic> j) => OrderLine(
    id: '${j['id']}',
    itemId: '${j['mfg_item_id']}',
    issueMethod: '${j['issue_method'] ?? 'manual'}',
    requiredQuantity: _num(j['required_quantity']),
    issuedQuantity: _num(j['issued_quantity']),
    uom: '${j['uom'] ?? ''}',
    operationSequence: j['operation_sequence'] is num
        ? (j['operation_sequence'] as num).toInt()
        : null,
    itemCode: _str(j['item_code']),
    itemName: _str(j['item_name']),
  );

  final String id;
  final String itemId;
  final String issueMethod;
  final double requiredQuantity;
  final double issuedQuantity;
  final String uom;
  final int? operationSequence;
  final String? itemCode;
  final String? itemName;

  double get openQuantity =>
      (requiredQuantity - issuedQuantity).clamp(0, double.infinity);

  /// Name shown to the operator.
  String get label => itemCode ?? itemName ?? itemId;
}

/// One routing step of a production order.
class OrderOperation {
  const OrderOperation({
    required this.id,
    required this.sequence,
    required this.code,
    required this.name,
    required this.workCenterId,
    required this.status,
    required this.plannedSetupMinutes,
    required this.plannedRunMinutes,
    required this.completedQuantity,
    required this.scrappedQuantity,
    this.subcontracted = false,
  });

  factory OrderOperation.fromJson(Map<String, dynamic> j) => OrderOperation(
    id: '${j['id']}',
    sequence: (j['sequence'] as num?)?.toInt() ?? 0,
    code: '${j['operation_code'] ?? ''}',
    name: '${j['name'] ?? ''}',
    workCenterId: '${j['work_center_id'] ?? ''}',
    status: '${j['status'] ?? ''}',
    plannedSetupMinutes: _num(j['planned_setup_minutes']),
    plannedRunMinutes: _num(j['planned_run_minutes']),
    completedQuantity: _num(j['completed_quantity']),
    scrappedQuantity: _num(j['scrapped_quantity']),
    subcontracted: j['is_subcontracted'] == true,
  );

  final String id;
  final int sequence;
  final String code;
  final String name;
  final String workCenterId;
  final String status;
  final double plannedSetupMinutes;
  final double plannedRunMinutes;
  final double completedQuantity;
  final double scrappedQuantity;
  final bool subcontracted;
}

/// A production order as cached for the operator (header, operations and material lines).
class ProductionOrder {
  const ProductionOrder({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.targetQuantity,
    required this.completedQuantity,
    required this.scrappedQuantity,
    required this.uom,
    this.itemCode,
    this.itemName,
    this.receiptWarehouseId,
    this.operations = const <OrderOperation>[],
    this.lines = const <OrderLine>[],
  });

  factory ProductionOrder.fromJson(Map<String, dynamic> j) => ProductionOrder(
    id: '${j['id']}',
    orderNumber: '${j['order_number'] ?? ''}',
    status: '${j['status'] ?? ''}',
    targetQuantity: _num(j['target_quantity']),
    completedQuantity: _num(j['completed_quantity']),
    scrappedQuantity: _num(j['scrapped_quantity']),
    uom: '${j['uom'] ?? ''}',
    itemCode: _str(j['item_code']),
    itemName: _str(j['item_name']),
    receiptWarehouseId: _str(j['receipt_warehouse_id']),
    operations: _maps(j['operations']).map(OrderOperation.fromJson).toList()
      ..sort(
        (OrderOperation a, OrderOperation b) =>
            a.sequence.compareTo(b.sequence),
      ),
    lines: _maps(j['lines']).map(OrderLine.fromJson).toList(),
  );

  final String id;
  final String orderNumber;
  final String status;
  final double targetQuantity;
  final double completedQuantity;
  final double scrappedQuantity;
  final String uom;
  final String? itemCode;
  final String? itemName;
  final String? receiptWarehouseId;
  final List<OrderOperation> operations;
  final List<OrderLine> lines;

  bool get isExecutable => status == 'released' || status == 'in_progress';
}

class WorkCenter {
  const WorkCenter({required this.id, required this.code, required this.name});

  factory WorkCenter.fromJson(Map<String, dynamic> j) => WorkCenter(
    id: '${j['id']}',
    code: '${j['work_center_code'] ?? ''}',
    name: '${j['name'] ?? ''}',
  );

  final String id;
  final String code;
  final String name;
}

class QualityCharacteristic {
  const QualityCharacteristic({
    required this.id,
    required this.name,
    this.target,
    this.min,
    this.max,
    this.uom,
    this.critical = false,
  });

  factory QualityCharacteristic.fromJson(Map<String, dynamic> j) =>
      QualityCharacteristic(
        id: '${j['id']}',
        name: '${j['characteristic_name'] ?? ''}',
        target: j['target_value'] == null ? null : _num(j['target_value']),
        min: j['min_tolerance'] == null ? null : _num(j['min_tolerance']),
        max: j['max_tolerance'] == null ? null : _num(j['max_tolerance']),
        uom: _str(j['uom']),
        critical: j['is_critical'] == true,
      );

  final String id;
  final String name;
  final double? target;
  final double? min;
  final double? max;
  final String? uom;
  final bool critical;

  /// Whether [value] lies inside the tolerance band (an open side is unbounded).
  bool accepts(double value) =>
      (min == null || value >= min!) && (max == null || value <= max!);
}

class QualityPlan {
  const QualityPlan({
    required this.id,
    required this.code,
    required this.name,
    required this.characteristics,
    this.itemId,
  });

  factory QualityPlan.fromJson(Map<String, dynamic> j) => QualityPlan(
    id: '${j['id']}',
    code: '${j['plan_code'] ?? ''}',
    name: '${j['name'] ?? ''}',
    itemId: _str(j['mfg_item_id']),
    characteristics: _maps(j['characteristics'])
        .map(QualityCharacteristic.fromJson)
        .toList(),
  );

  final String id;
  final String code;
  final String name;
  final String? itemId;
  final List<QualityCharacteristic> characteristics;
}

/// A raw-material lot scanned at the line and held locally until it is backflushed.
class StagedLot {
  const StagedLot({
    required this.id,
    required this.orderId,
    required this.lineId,
    required this.lotNumber,
    required this.quantity,
    required this.posted,
    this.lotId,
    this.gtin,
  });

  final String id;
  final String orderId;
  final String lineId;
  final String lotNumber;
  final double quantity;
  final bool posted;
  final String? lotId;
  final String? gtin;
}

/// Phase of the operator terminal for one operation.
enum TerminalPhase { idle, setup, run, paused }

/// Local stopwatch state of one operation (persisted so an app restart does not lose the running clock).
class OperationTimer {
  const OperationTimer({
    this.phase = TerminalPhase.idle,
    this.setupSeconds = 0,
    this.runSeconds = 0,
    this.downtimeSeconds = 0,
    this.phaseStartedAt,
    this.resumePhase = TerminalPhase.run,
  });

  final TerminalPhase phase;
  final int setupSeconds;
  final int runSeconds;
  final int downtimeSeconds;
  final DateTime? phaseStartedAt;
  final TerminalPhase resumePhase;

  OperationTimer _close(DateTime now) {
    final DateTime? since = phaseStartedAt;
    if (since == null || phase == TerminalPhase.idle) {
      return this;
    }
    final int elapsed = now.difference(since).inSeconds.clamp(0, 1 << 30);
    return OperationTimer(
      phase: phase,
      setupSeconds: setupSeconds + (phase == TerminalPhase.setup ? elapsed : 0),
      runSeconds: runSeconds + (phase == TerminalPhase.run ? elapsed : 0),
      downtimeSeconds:
          downtimeSeconds + (phase == TerminalPhase.paused ? elapsed : 0),
      phaseStartedAt: now,
      resumePhase: resumePhase,
    );
  }

  OperationTimer _into(
    TerminalPhase next,
    DateTime now, {
    TerminalPhase? resume,
  }) {
    final OperationTimer c = _close(now);
    return OperationTimer(
      phase: next,
      setupSeconds: c.setupSeconds,
      runSeconds: c.runSeconds,
      downtimeSeconds: c.downtimeSeconds,
      phaseStartedAt: next == TerminalPhase.idle ? null : now,
      resumePhase: resume ?? c.resumePhase,
    );
  }

  OperationTimer startSetup(DateTime now) => _into(TerminalPhase.setup, now);

  OperationTimer startRun(DateTime now) => _into(TerminalPhase.run, now);

  /// Pauses setup or run; the pause counts as downtime and [resume] returns to the interrupted phase.
  OperationTimer pause(DateTime now) {
    if (!running) {
      return this;
    }
    return _into(TerminalPhase.paused, now, resume: phase);
  }

  OperationTimer resume(DateTime now) =>
      phase == TerminalPhase.paused ? _into(resumePhase, now) : this;

  /// Stops the clock keeping the totals (used right before posting).
  OperationTimer stop(DateTime now) => _into(TerminalPhase.idle, now);

  /// Totals including the phase that is still running.
  OperationTimer snapshot(DateTime now) => _close(now);

  bool get running =>
      phase == TerminalPhase.setup || phase == TerminalPhase.run;

  static double minutes(int seconds) => (seconds / 60 * 100).round() / 100;
}
