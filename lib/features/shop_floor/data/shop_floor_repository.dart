import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../domain/shop_floor_models.dart';
import 'local/shop_floor_tables.dart';
import 'shop_floor_outbox.dart';

/// Why a local operator action was refused (before anything is queued).
enum ShopFloorError {
  nothingToPost,
  scrapReasonRequired,
  invalidQuantity,
  orderNotExecutable,
  unknownOrder,
}

class ShopFloorException implements Exception {
  const ShopFloorException(this.error);

  final ShopFloorError error;

  @override
  String toString() => 'ShopFloorException($error)';
}

/// Counters the operator keeps for one operation next to the stopwatch.
class OperationCounters {
  const OperationCounters({
    this.good = 0,
    this.scrap = 0,
    this.scrapReason,
    this.machineWorkCenterId,
  });

  final double good;
  final double scrap;
  final String? scrapReason;

  /// Work centre the operator checked in to, if any.
  final String? machineWorkCenterId;
}

/// Local view of one operation: stopwatch plus counters.
class OperationState {
  const OperationState({
    this.timer = const OperationTimer(),
    this.counters = const OperationCounters(),
  });

  final OperationTimer timer;
  final OperationCounters counters;
}

String _qty(double v) => v.toStringAsFixed(4);

String _min(double v) => v.toStringAsFixed(2);

String _date(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Offline-first access to the shop-floor data: the UI only reads SQLite; every write lands in SQLite first and in the
/// persistent [ShopFloorOutbox] in the same transaction.
class ShopFloorRepository {
  ShopFloorRepository(
    this._db,
    this._dio,
    this.outbox, {
    Uuid? uuid,
    DateTime Function()? clock,
  }) : _uuid = uuid ?? const Uuid(),
       _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final Dio _dio;
  final ShopFloorOutbox outbox;
  final Uuid _uuid;
  final DateTime Function() _clock;

  static const String _base = '/manufacturing';

  // ---------------------------------------------------------------- reads

  ProductionOrder _order(MfgOrderRow r) =>
      ProductionOrder.fromJson(jsonDecode(r.payload) as Map<String, dynamic>);

  Stream<List<ProductionOrder>> watchOrders(String tenantId) {
    return (_db.select(_db.mfgOrders)
          ..where((MfgOrders t) => t.tenantId.equals(tenantId))
          ..orderBy(<OrderingTerm Function(MfgOrders)>[
            (MfgOrders t) => OrderingTerm.asc(t.orderNumber),
          ]))
        .watch()
        .map((List<MfgOrderRow> rows) => rows.map(_order).toList());
  }

  Stream<ProductionOrder?> watchOrder(String tenantId, String id) {
    return (_db.select(_db.mfgOrders)..where(
          (MfgOrders t) => t.tenantId.equals(tenantId) & t.id.equals(id),
        ))
        .watchSingleOrNull()
        .map((MfgOrderRow? r) => r == null ? null : _order(r));
  }

  Future<List<ProductionOrder>> orders(String tenantId) async {
    final List<MfgOrderRow> rows =
        await (_db.select(_db.mfgOrders)
              ..where((MfgOrders t) => t.tenantId.equals(tenantId))
              ..orderBy(<OrderingTerm Function(MfgOrders)>[
                (MfgOrders t) => OrderingTerm.asc(t.orderNumber),
              ]))
            .get();
    return rows.map(_order).toList();
  }

  /// Finds an order by its uuid or its order number (case-insensitive) in the local cache.
  Future<ProductionOrder?> findOrder(String tenantId, String reference) async {
    final String ref = reference.trim().toUpperCase();
    for (final ProductionOrder o in await orders(tenantId)) {
      if (o.id.toUpperCase() == ref || o.orderNumber.toUpperCase() == ref) {
        return o;
      }
    }
    return null;
  }

  Future<List<WorkCenter>> workCenters(String tenantId) async {
    final List<ShopFloorWorkCenterRow> rows = await (_db.select(
      _db.mfgWorkCenters,
    )..where((MfgWorkCenters t) => t.tenantId.equals(tenantId))).get();
    return rows
        .map(
          (ShopFloorWorkCenterRow r) => WorkCenter.fromJson(
            jsonDecode(r.payload) as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<WorkCenter?> findWorkCenter(String tenantId, String codeOrId) async {
    final String ref = codeOrId.trim().toUpperCase();
    for (final WorkCenter w in await workCenters(tenantId)) {
      if (w.code.toUpperCase() == ref || w.id.toUpperCase() == ref) {
        return w;
      }
    }
    return null;
  }

  Future<List<QualityPlan>> qualityPlans(String tenantId) async {
    final List<MfgQualityPlanRow> rows = await (_db.select(
      _db.mfgQualityPlans,
    )..where((MfgQualityPlans t) => t.tenantId.equals(tenantId))).get();
    return rows
        .map(
          (MfgQualityPlanRow r) => QualityPlan.fromJson(
            jsonDecode(r.payload) as Map<String, dynamic>,
          ),
        )
        .toList()
      ..sort((QualityPlan a, QualityPlan b) => a.code.compareTo(b.code));
  }

  // ---------------------------------------------------------------- pull

  Future<List<Map<String, dynamic>>> _getAll(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final List<Map<String, dynamic>> out = <Map<String, dynamic>>[];
    int page = 1;
    int last = 1;
    do {
      final Response<dynamic> res = await _dio.get<dynamic>(
        '$_base$path',
        queryParameters: <String, dynamic>{
          ...?query,
          'per_page': 100,
          'page': page,
        },
      );
      final dynamic body = res.data;
      final dynamic data = body is Map ? body['data'] : null;
      if (data is List) {
        out.addAll(
          data.map((dynamic e) => Map<String, dynamic>.from(e as Map)),
        );
      }
      final dynamic meta = body is Map ? body['meta'] : null;
      last = meta is Map && meta['last_page'] is num
          ? (meta['last_page'] as num).toInt()
          : 1;
      page++;
    } while (page <= last);
    return out;
  }

  /// Refreshes the executable orders (with operations and lines), work centres and quality plans. Throws [DioException]
  /// when offline; the cache is replaced atomically so a half-failed refresh keeps the previous copy.
  Future<int> refresh(String tenantId) async {
    final List<Map<String, dynamic>> open = <Map<String, dynamic>>[
      ...await _getAll(
        '/production-orders',
        query: <String, dynamic>{'status': 'released'},
      ),
      ...await _getAll(
        '/production-orders',
        query: <String, dynamic>{'status': 'in_progress'},
      ),
    ];
    final List<Map<String, dynamic>> details = <Map<String, dynamic>>[];
    for (final Map<String, dynamic> header in open) {
      final Response<dynamic> res = await _dio.get<dynamic>(
        '$_base/production-orders/${header['id']}',
      );
      final dynamic data = (res.data as Map<dynamic, dynamic>)['data'];
      details.add(data is Map ? Map<String, dynamic>.from(data) : header);
    }
    final List<Map<String, dynamic>> centers = await _getAll('/work-centers');
    final List<Map<String, dynamic>> plans = await _getAll('/quality/plans');
    final DateTime now = _clock().toUtc();
    await _db.transaction(() async {
      await (_db.delete(
        _db.mfgOrders,
      )..where((MfgOrders t) => t.tenantId.equals(tenantId))).go();
      for (final Map<String, dynamic> o in details) {
        await _db
            .into(_db.mfgOrders)
            .insertOnConflictUpdate(
              MfgOrdersCompanion.insert(
                tenantId: tenantId,
                id: '${o['id']}',
                orderNumber: '${o['order_number']}',
                status: '${o['status']}',
                payload: jsonEncode(o),
                syncedAt: now,
              ),
            );
      }
      await (_db.delete(
        _db.mfgWorkCenters,
      )..where((MfgWorkCenters t) => t.tenantId.equals(tenantId))).go();
      for (final Map<String, dynamic> w in centers) {
        await _db
            .into(_db.mfgWorkCenters)
            .insertOnConflictUpdate(
              MfgWorkCentersCompanion.insert(
                tenantId: tenantId,
                id: '${w['id']}',
                code: '${w['work_center_code']}',
                payload: jsonEncode(w),
              ),
            );
      }
      await (_db.delete(
        _db.mfgQualityPlans,
      )..where((MfgQualityPlans t) => t.tenantId.equals(tenantId))).go();
      for (final Map<String, dynamic> p in plans) {
        await _db
            .into(_db.mfgQualityPlans)
            .insertOnConflictUpdate(
              MfgQualityPlansCompanion.insert(
                tenantId: tenantId,
                id: '${p['id']}',
                payload: jsonEncode(p),
              ),
            );
      }
    });
    return details.length;
  }

  /// Online-only: lot genealogy (where-used / where-from) of an order as returned by the API.
  Future<Map<String, dynamic>> fetchGenealogy(String orderId) async {
    final Response<dynamic> res = await _dio.get<dynamic>(
      '$_base/production-orders/$orderId/genealogy',
    );
    final dynamic data = (res.data as Map<dynamic, dynamic>)['data'];
    return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
  }

  // ---------------------------------------------------------------- materials

  Stream<List<StagedLot>> watchStaged(String tenantId, String orderId) {
    return (_db.select(_db.mfgStagedLots)
          ..where(
            (MfgStagedLots t) =>
                t.tenantId.equals(tenantId) & t.orderId.equals(orderId),
          )
          ..orderBy(<OrderingTerm Function(MfgStagedLots)>[
            (MfgStagedLots t) => OrderingTerm.asc(t.createdAt),
          ]))
        .watch()
        .map(
          (List<MfgStagedLotRow> rows) => <StagedLot>[
            for (final MfgStagedLotRow r in rows)
              StagedLot(
                id: r.id,
                orderId: r.orderId,
                lineId: r.lineId,
                lotNumber: r.lotNumber,
                quantity: r.quantity,
                posted: r.outboxUuid != null,
                lotId: r.lotId,
                gtin: r.gtin,
              ),
          ],
        );
  }

  /// Holds a scanned raw-material lot against a material line until [backflush].
  Future<String> stageLot({
    required String tenantId,
    required String orderId,
    required String lineId,
    required String lotNumber,
    required double quantity,
    String? lotId,
    String? gtin,
  }) async {
    if (quantity <= 0 || quantity.isNaN || quantity.isInfinite) {
      throw const ShopFloorException(ShopFloorError.invalidQuantity);
    }
    final String id = _uuid.v7();
    await _db
        .into(_db.mfgStagedLots)
        .insert(
          MfgStagedLotsCompanion.insert(
            id: id,
            tenantId: tenantId,
            orderId: orderId,
            lineId: lineId,
            lotNumber: lotNumber,
            quantity: quantity,
            lotId: Value<String?>(lotId),
            gtin: Value<String?>(gtin),
            createdAt: _clock().toUtc(),
          ),
        );
    return id;
  }

  Future<void> unstageLot(String id) async {
    await (_db.delete(_db.mfgStagedLots)
          ..where((MfgStagedLots t) => t.id.equals(id) & t.outboxUuid.isNull()))
        .go();
  }

  /// Backflushes every staged lot of [orderId]: one `issues` request per lot (the API wants distinct lines per request),
  /// queued in scan order inside one transaction. Returns the outbox uuids.
  Future<List<String>> backflush(String tenantId, String orderId) async {
    return _db.transaction(() async {
      final List<MfgStagedLotRow> staged =
          await (_db.select(_db.mfgStagedLots)
                ..where(
                  (MfgStagedLots t) =>
                      t.tenantId.equals(tenantId) &
                      t.orderId.equals(orderId) &
                      t.outboxUuid.isNull(),
                )
                ..orderBy(<OrderingTerm Function(MfgStagedLots)>[
                  (MfgStagedLots t) => OrderingTerm.asc(t.createdAt),
                  (MfgStagedLots t) => OrderingTerm.asc(t.id),
                ]))
              .get();
      final List<String> keys = <String>[];
      for (final MfgStagedLotRow lot in staged) {
        final String key = await outbox.enqueue(
          tenantId: tenantId,
          kind: OutboxKind.issue,
          orderId: orderId,
          path: '/production-orders/$orderId/issues',
          payload: <String, dynamic>{
            'posting_date': _date(_clock()),
            'lines': <Map<String, dynamic>>[
              <String, dynamic>{
                'line_id': lot.lineId,
                'quantity': _qty(lot.quantity),
                'lot_id': ?lot.lotId,
              },
            ],
          },
        );
        await (_db.update(_db.mfgStagedLots)
              ..where((MfgStagedLots t) => t.id.equals(lot.id)))
            .write(MfgStagedLotsCompanion(outboxUuid: Value<String?>(key)));
        keys.add(key);
      }
      return keys;
    });
  }

  // ---------------------------------------------------------------- operator terminal

  OperationState _state(MfgOperationTimerRow? r) {
    if (r == null) {
      return const OperationState();
    }
    return OperationState(
      timer: OperationTimer(
        phase: TerminalPhase.values[r.phase],
        resumePhase: TerminalPhase.values[r.resumePhase],
        setupSeconds: r.setupSeconds,
        runSeconds: r.runSeconds,
        downtimeSeconds: r.downtimeSeconds,
        phaseStartedAt: r.phaseStartedAt,
      ),
      counters: OperationCounters(
        good: r.goodQuantity,
        scrap: r.scrapQuantity,
        scrapReason: r.scrapReason,
        machineWorkCenterId: r.machineWorkCenterId,
      ),
    );
  }

  Stream<OperationState> watchOperation(String tenantId, String operationId) {
    return (_db.select(_db.mfgOperationTimers)..where(
          (MfgOperationTimers t) =>
              t.tenantId.equals(tenantId) & t.operationId.equals(operationId),
        ))
        .watchSingleOrNull()
        .map(_state);
  }

  Future<OperationState> operationState(
    String tenantId,
    String operationId,
  ) async {
    final MfgOperationTimerRow? row =
        await (_db.select(_db.mfgOperationTimers)..where(
              (MfgOperationTimers t) =>
                  t.tenantId.equals(tenantId) &
                  t.operationId.equals(operationId),
            ))
            .getSingleOrNull();
    return _state(row);
  }

  Future<void> _save(
    String tenantId,
    String orderId,
    String operationId,
    OperationState s,
  ) async {
    await _db
        .into(_db.mfgOperationTimers)
        .insertOnConflictUpdate(
          MfgOperationTimersCompanion.insert(
            tenantId: tenantId,
            operationId: operationId,
            orderId: orderId,
            phase: Value<int>(s.timer.phase.index),
            resumePhase: Value<int>(s.timer.resumePhase.index),
            setupSeconds: Value<int>(s.timer.setupSeconds),
            runSeconds: Value<int>(s.timer.runSeconds),
            downtimeSeconds: Value<int>(s.timer.downtimeSeconds),
            phaseStartedAt: Value<DateTime?>(s.timer.phaseStartedAt),
            goodQuantity: Value<double>(s.counters.good),
            scrapQuantity: Value<double>(s.counters.scrap),
            scrapReason: Value<String?>(s.counters.scrapReason),
            machineWorkCenterId: Value<String?>(s.counters.machineWorkCenterId),
          ),
        );
  }

  Future<void> _transition(
    String tenantId,
    String orderId,
    String operationId,
    OperationTimer Function(OperationTimer, DateTime) f,
  ) async {
    await _db.transaction(() async {
      final OperationState s = await operationState(tenantId, operationId);
      await _save(
        tenantId,
        orderId,
        operationId,
        OperationState(
          timer: f(s.timer, _clock().toUtc()),
          counters: s.counters,
        ),
      );
    });
  }

  Future<void> startSetup(
    String tenantId,
    String orderId,
    String operationId,
  ) => _transition(
    tenantId,
    orderId,
    operationId,
    (OperationTimer t, DateTime n) => t.startSetup(n),
  );

  Future<void> startRun(String tenantId, String orderId, String operationId) =>
      _transition(
        tenantId,
        orderId,
        operationId,
        (OperationTimer t, DateTime n) => t.startRun(n),
      );

  Future<void> pause(String tenantId, String orderId, String operationId) =>
      _transition(
        tenantId,
        orderId,
        operationId,
        (OperationTimer t, DateTime n) => t.pause(n),
      );

  Future<void> resume(String tenantId, String orderId, String operationId) =>
      _transition(
        tenantId,
        orderId,
        operationId,
        (OperationTimer t, DateTime n) => t.resume(n),
      );

  /// Stores the good/scrap counters (absolute values, the screen steps them with +/-).
  Future<void> setCounters(
    String tenantId,
    String orderId,
    String operationId, {
    required double good,
    required double scrap,
    String? scrapReason,
  }) async {
    if (good < 0 || scrap < 0) {
      throw const ShopFloorException(ShopFloorError.invalidQuantity);
    }
    await _db.transaction(() async {
      final OperationState s = await operationState(tenantId, operationId);
      await _save(
        tenantId,
        orderId,
        operationId,
        OperationState(
          timer: s.timer,
          counters: OperationCounters(
            good: good,
            scrap: scrap,
            scrapReason: scrapReason,
            machineWorkCenterId: s.counters.machineWorkCenterId,
          ),
        ),
      );
    });
  }

  /// Checks the operator in to a work-centre machine: remembered locally and queued as a shop-floor execution start.
  Future<String> checkIn({
    required String tenantId,
    required String orderId,
    required String operationId,
    required WorkCenter workCenter,
    String? operatorId,
  }) async {
    return _db.transaction(() async {
      final OperationState s = await operationState(tenantId, operationId);
      await _save(
        tenantId,
        orderId,
        operationId,
        OperationState(
          timer: s.timer,
          counters: OperationCounters(
            good: s.counters.good,
            scrap: s.counters.scrap,
            scrapReason: s.counters.scrapReason,
            machineWorkCenterId: workCenter.id,
          ),
        ),
      );
      return outbox.enqueue(
        tenantId: tenantId,
        kind: OutboxKind.checkIn,
        orderId: orderId,
        path: '/shop-floor/executions',
        payload: <String, dynamic>{
          'production_order_operation_id': operationId,
          'operator_id': ?operatorId,
        },
      );
    });
  }

  /// Signs the operation off: stops the clock, builds the confirmation from the stopwatch and counters, queues it with a
  /// fresh `operation_posting_uuid` and resets the terminal for the next lot. Returns that uuid.
  Future<String> confirm({
    required String tenantId,
    required String orderId,
    required String operationId,
    bool isFinal = false,
  }) async {
    final ProductionOrder? order = await findOrder(tenantId, orderId);
    if (order != null && !order.isExecutable) {
      throw const ShopFloorException(ShopFloorError.orderNotExecutable);
    }
    return _db.transaction(() async {
      final DateTime now = _clock().toUtc();
      final OperationState s = await operationState(tenantId, operationId);
      final OperationTimer t = s.timer.snapshot(now);
      final double setup = OperationTimer.minutes(t.setupSeconds);
      final double run = OperationTimer.minutes(t.runSeconds);
      final double down = OperationTimer.minutes(t.downtimeSeconds);
      if (s.counters.good <= 0 &&
          s.counters.scrap <= 0 &&
          setup + run + down <= 0) {
        throw const ShopFloorException(ShopFloorError.nothingToPost);
      }
      final String reason = (s.counters.scrapReason ?? '').trim();
      if (s.counters.scrap > 0 && reason.isEmpty) {
        throw const ShopFloorException(ShopFloorError.scrapReasonRequired);
      }
      final String posting = _uuid.v4();
      final String key = await outbox.enqueue(
        tenantId: tenantId,
        kind: OutboxKind.confirm,
        orderId: orderId,
        uuid: posting,
        path:
            '/production-orders/$orderId/operations/$operationId/confirmations',
        payload: <String, dynamic>{
          'setup_minutes': _min(setup),
          'run_minutes': _min(run),
          'labor_minutes': _min(setup + run),
          'downtime_minutes': _min(down),
          'good_quantity': _qty(s.counters.good),
          'scrap_quantity': _qty(s.counters.scrap),
          if (s.counters.scrap > 0) 'scrap_reason': reason,
          'is_final': isFinal,
          'posting_date': _date(now.toLocal()),
          'operation_posting_uuid': posting,
        },
      );
      await _save(
        tenantId,
        orderId,
        operationId,
        OperationState(
          counters: OperationCounters(
            machineWorkCenterId: s.counters.machineWorkCenterId,
          ),
        ),
      );
      return key;
    });
  }

  /// Receives finished goods into stock.
  Future<String> receiveOutput({
    required String tenantId,
    required String orderId,
    required double quantity,
    String? lotNumber,
    String? warehouseId,
  }) async {
    if (quantity <= 0 || quantity.isNaN || quantity.isInfinite) {
      throw const ShopFloorException(ShopFloorError.invalidQuantity);
    }
    final String lot = (lotNumber ?? '').trim();
    return outbox.enqueue(
      tenantId: tenantId,
      kind: OutboxKind.receipt,
      orderId: orderId,
      path: '/production-orders/$orderId/receipts',
      payload: <String, dynamic>{
        'quantity': _qty(quantity),
        if (lot.isNotEmpty) 'lot_number': lot,
        'warehouse_id': ?warehouseId,
        'posting_date': _date(_clock()),
      },
    );
  }

  // ---------------------------------------------------------------- quality

  /// Signs a QC checklist off. [measurements] maps characteristic id to the measured value; defects are the
  /// characteristics outside their tolerance band.
  Future<String> signOffInspection({
    required String tenantId,
    required String orderId,
    required String operationId,
    required QualityPlan plan,
    required Map<String, double> measurements,
    required double quantityInspected,
    String? notes,
  }) async {
    if (quantityInspected <= 0 || measurements.isEmpty) {
      throw const ShopFloorException(ShopFloorError.nothingToPost);
    }
    int defects = 0;
    final List<Map<String, dynamic>> results = <Map<String, dynamic>>[];
    for (final QualityCharacteristic c in plan.characteristics) {
      final double? v = measurements[c.id];
      if (v == null) {
        continue;
      }
      if (!c.accepts(v)) {
        defects++;
      }
      results.add(<String, dynamic>{
        'characteristic_id': c.id,
        'measured_value': v.toStringAsFixed(4),
      });
    }
    return outbox.enqueue(
      tenantId: tenantId,
      kind: OutboxKind.inspection,
      orderId: orderId,
      path: '/quality/inspections',
      payload: <String, dynamic>{
        'quality_plan_id': plan.id,
        'inspection_point': 'operation',
        'production_order_id': orderId,
        'production_order_operation_id': operationId,
        'quantity_inspected': _qty(quantityInspected),
        'defect_count': defects,
        if ((notes ?? '').trim().isNotEmpty) 'notes': notes!.trim(),
        'characteristic_results': results,
      },
    );
  }
}
