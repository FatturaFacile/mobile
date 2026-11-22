import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../../core/error/failure.dart';
import '../../../core/network/api_client.dart';
import '../domain/coverage_policy.dart';
import '../domain/signature_svg.dart';
import '../models/field_service_models.dart';
import 'field_service_outbox.dart';
import 'field_service_store.dart';

/// A work order of the queue with the names the list shows.
class FsmQueueItem {
  const FsmQueueItem({
    required this.workOrder,
    this.customerName,
    this.equipmentSerial,
    this.site = const FsmSite(),
  });

  final FsmWorkOrder workOrder;
  final String? customerName;
  final String? equipmentSerial;

  /// The work order site, completed with the equipment passport site.
  final FsmSite site;
}

/// Everything the work-order screens show, read from the phone only.
class FsmWorkOrderDetail {
  const FsmWorkOrderDetail({
    required this.workOrder,
    required this.coverage,
    required this.site,
    this.customer,
    this.equipment,
    this.parts = const <FsmPartLine>[],
    this.checklist = const <ChecklistEntry>[],
    this.photos = const <ReportPhoto>[],
    this.report,
    this.pendingOperations = 0,
  });

  final FsmWorkOrder workOrder;
  final FsmCustomer? customer;
  final FsmEquipment? equipment;
  final List<FsmPartLine> parts;
  final List<ChecklistEntry> checklist;
  final List<ReportPhoto> photos;

  /// The signed report, once the customer signed (even before the server acknowledged it).
  final StoredReport? report;
  final CoverageSummary coverage;
  final FsmSite site;

  /// Operations of this work order not yet acknowledged by the server.
  final int pendingOperations;

  bool get signed => report != null;
}

/// A local rule refused an action; [errors] maps API field names to error codes, like the server would.
class FsmException implements Exception {
  const FsmException(this.errors);

  final Map<String, String> errors;

  @override
  String toString() => 'FsmException($errors)';
}

/// Outcome of [FieldServiceRepository.refresh].
class FsmRefreshResult {
  const FsmRefreshResult({
    this.merge = const BundleMerge(),
    this.offline = false,
    this.unauthorized = false,
    this.error,
  });

  final BundleMerge merge;
  final bool offline;
  final bool unauthorized;
  final String? error;

  bool get ok => !offline && !unauthorized && error == null;
}

/// Contract of the Field Service screens (fakeable in tests). Every write returns as soon as it is safe on the device.
abstract class FieldServiceRepository {
  Stream<List<FsmQueueItem>> watchWorkQueue();

  Stream<FsmWorkOrderDetail?> watchDetail(String workOrderId);

  Stream<List<VanStockItem>> watchVanStock();

  /// Operations not yet acknowledged by the server (offline queue size).
  Stream<int> watchPending();

  /// Operations the server rejected (the conflict report).
  Stream<List<FsmOperation>> watchConflicts();

  /// Downloads the delta bundle (`GET /fsm/technicians/{id}/offline-bundle`) into the phone.
  Future<FsmRefreshResult> refresh();

  /// Sends the queue, then refreshes the bundle when the server could be reached.
  Future<FsmFlushReport> sync();

  /// Queues a `dispatched -> en_route -> on_site` step and moves the work order locally right away.
  Future<void> advanceStatus(
    String workOrderId,
    FsmStatus target, {
    DateTime? at,
  });

  Future<void> setChecklistResult(
    String workOrderId,
    String item,
    ChecklistResult result, {
    String? notes,
  });

  /// Consumes [quantity] of a van part: updates the van stock, computes covered/chargeable offline and queues the line.
  Future<FsmPartLine> consumePart(
    String workOrderId,
    VanStockItem item,
    double quantity, {
    String? lotNumber,
    String? lotOrSerialId,
  });

  /// Undoes a part line that has not been acknowledged yet.
  Future<void> removePart(String workOrderId, String clientUuid);

  Future<ReportPhoto> addPhoto(
    String workOrderId, {
    required String localPath,
    required String name,
    DateTime? takenAt,
  });

  Future<void> removePhoto(String workOrderId, String photoId);

  /// The values typed so far in the report form (kept across screen visits).
  Future<Map<String, dynamic>> loadDraft(String workOrderId);

  Future<void> saveDraft(String workOrderId, Map<String, dynamic> draft);

  /// Seals the report, completes the work order locally and queues the `service_report` operation.
  /// Throws [FsmException] with the rejected fields.
  Future<StoredReport> signAndClose(
    String workOrderId,
    ServiceReportDraft draft,
  );

  Future<void> retryOperation(String clientUuid);

  /// Drops a rejected operation and undoes its local effects (part stock, signed report, work order status).
  Future<void> discardOperation(String clientUuid);
}

/// The repository on the phone: local SQLite first, the outbox sends the rest.
class LocalFieldServiceRepository implements FieldServiceRepository {
  LocalFieldServiceRepository({
    required FieldServiceStore store,
    required Dio dio,
    required FieldServiceOutbox outbox,
    required this.tenantId,
    required this.technicianId,
    CoveragePolicy coverage = const CoveragePolicy(),
    String Function()? newUuid,
    DateTime Function()? clock,
  }) : _store = store,
       _dio = dio,
       _outbox = outbox,
       _coverage = coverage,
       _newUuid = newUuid ?? (() => const Uuid().v7()),
       _clock = clock ?? DateTime.now;

  final FieldServiceStore _store;
  final Dio _dio;
  final FieldServiceOutbox _outbox;
  final CoveragePolicy _coverage;
  final String Function() _newUuid;
  final DateTime Function() _clock;
  final String tenantId;

  /// The `service_technicians.id` whose bundle is downloaded.
  final String technicianId;

  // ------------------------------------------------------------------ reads

  @override
  Stream<List<FsmQueueItem>> watchWorkQueue() =>
      _store.watchQuery<List<FsmQueueItem>>(() async {
        final List<FsmWorkOrder> orders = await _store.workOrders(tenantId);
        final Map<String, FsmCustomer> customers = await _store.customers(
          tenantId,
        );
        final Map<String, FsmEquipment> equipment = await _store.allEquipment(
          tenantId,
        );
        return <FsmQueueItem>[
          for (final FsmWorkOrder wo in orders)
            FsmQueueItem(
              workOrder: wo,
              customerName: customers[wo.customerId]?.name,
              equipmentSerial: equipment[wo.equipmentId]?.serialNumber,
              site: wo.site.orElse(
                equipment[wo.equipmentId]?.site ?? const FsmSite(),
              ),
            ),
        ];
      });

  @override
  Stream<FsmWorkOrderDetail?> watchDetail(String workOrderId) =>
      _store.watchQuery<FsmWorkOrderDetail?>(() => _detail(workOrderId));

  Future<FsmWorkOrderDetail?> _detail(String workOrderId) async {
    final FsmWorkOrder? wo = await _store.workOrder(tenantId, workOrderId);
    if (wo == null) return null;
    final FsmEquipment? equipment = await _store.equipment(
      tenantId,
      wo.equipmentId,
    );
    final List<FsmOperation> active = await _store.activeOperations(tenantId);
    return FsmWorkOrderDetail(
      workOrder: wo,
      customer: await _store.customer(tenantId, wo.customerId),
      equipment: equipment,
      parts: await _store.parts(tenantId, wo.id),
      checklist: await _store.checklist(tenantId, wo.id, wo.checklistTemplate),
      photos: await _store.photos(tenantId, wo.id),
      report: await _store.report(tenantId, wo.id),
      coverage: _coverage.summary(wo),
      site: wo.site.orElse(equipment?.site ?? const FsmSite()),
      pendingOperations: active
          .where((FsmOperation o) => o.workOrderId == wo.id)
          .length,
    );
  }

  @override
  Stream<List<VanStockItem>> watchVanStock() => _store.watchVanStock(tenantId);

  @override
  Stream<int> watchPending() => _store.watchPending(tenantId);

  @override
  Stream<List<FsmOperation>> watchConflicts() =>
      _store.watchConflicts(tenantId);

  // ------------------------------------------------------------------- sync

  @override
  Future<FsmRefreshResult> refresh() async {
    try {
      final String? since = await _store.serverTime(tenantId);
      final Response<dynamic> res = await _dio.get<dynamic>(
        '/fsm/technicians/$technicianId/offline-bundle',
        queryParameters: <String, dynamic>{'since': ?since},
      );
      final dynamic body = res.data;
      final dynamic data = body is Map ? body['data'] : null;
      if (data is! Map) return const FsmRefreshResult(error: 'invalid_bundle');
      final BundleMerge merge = await _store.mergeBundle(
        tenantId,
        OfflineBundle.fromJson(Map<String, dynamic>.from(data)),
        _clock(),
      );
      return FsmRefreshResult(merge: merge);
    } on DioException catch (e) {
      final Failure f = mapDioError(e);
      return FsmRefreshResult(
        offline: f is NetworkFailure,
        unauthorized: f is UnauthorizedFailure,
        error: f is NetworkFailure || f is UnauthorizedFailure
            ? null
            : (f.message.isEmpty ? 'refresh_failed' : f.message),
      );
    }
  }

  @override
  Future<FsmFlushReport> sync() async {
    final FsmFlushReport report = await _outbox.flush(tenantId);
    if (!report.offline && !report.unauthorized) {
      await refresh();
    }
    return report;
  }

  // ----------------------------------------------------------------- writes

  @override
  Future<void> advanceStatus(
    String workOrderId,
    FsmStatus target, {
    DateTime? at,
  }) async {
    final FsmWorkOrder wo = await _openWorkOrder(workOrderId);
    if (wo.status == target)
      return; // A repeated tap is a no-op, like on the server.
    if (!wo.status.canMoveTo(target)) {
      throw const FsmException(<String, String>{
        'status': 'transition_invalid',
      });
    }
    final DateTime moment = at ?? _clock();
    await _store.transaction<void>(() async {
      await _store.setWorkOrderStatus(tenantId, workOrderId, target);
      await _store.enqueue(
        tenantId: tenantId,
        workOrderId: workOrderId,
        type: FsmOperationType.statusTransition,
        payload: <String, dynamic>{
          'status': target.wire,
          'at': moment.toUtc().toIso8601String(),
        },
        clientUuid: _newUuid(),
        createdAt: _clock(),
      );
    });
  }

  Future<FsmWorkOrder> _openWorkOrder(String workOrderId) async {
    final FsmWorkOrder? wo = await _store.workOrder(tenantId, workOrderId);
    if (wo == null) {
      throw const FsmException(<String, String>{'work_order_id': 'not_found'});
    }
    if (!wo.status.isOpen ||
        await _store.report(tenantId, workOrderId) != null) {
      throw const FsmException(<String, String>{
        'work_order': 'report_not_open',
      });
    }
    return wo;
  }

  @override
  Future<void> setChecklistResult(
    String workOrderId,
    String item,
    ChecklistResult result, {
    String? notes,
  }) => _store.setChecklistResult(
    tenantId,
    workOrderId,
    item,
    result,
    notes: notes,
  );

  @override
  Future<FsmPartLine> consumePart(
    String workOrderId,
    VanStockItem item,
    double quantity, {
    String? lotNumber,
    String? lotOrSerialId,
  }) async {
    final FsmWorkOrder wo = await _openWorkOrder(workOrderId);
    if (!(quantity > 0)) {
      throw const FsmException(<String, String>{'quantity': 'positive'});
    }
    final VanStockItem? onBoard = (await _store.vanStock(tenantId))
        .where((VanStockItem v) => v.productId == item.productId)
        .firstOrNull;
    if (onBoard == null || quantity > onBoard.available) {
      throw const FsmException(<String, String>{
        'quantity': 'insufficient_stock',
      });
    }
    final String lot = (lotNumber ?? '').trim();
    if (lot.length > 60) {
      throw const FsmException(<String, String>{'lot_number': 'max'});
    }
    final FsmPartLine line = FsmPartLine(
      clientUuid: _newUuid(),
      workOrderId: wo.id,
      productId: item.productId,
      sku: item.sku,
      name: item.name,
      quantity: quantity,
      unitPrice: item.unitPrice,
      covered: _coverage.coversParts(wo),
      createdAt: _clock(),
      lotNumber: lot.isEmpty ? null : lot,
      lotOrSerialId: lotOrSerialId,
    );
    await _store.transaction<void>(() async {
      await _store.insertPart(tenantId, line);
      await _store.adjustVanStock(tenantId, item.productId, -quantity);
      await _store.enqueue(
        tenantId: tenantId,
        workOrderId: wo.id,
        type: FsmOperationType.partConsumption,
        payload: line.toPayload(),
        clientUuid: line.clientUuid,
        createdAt: line.createdAt,
      );
    });
    return line;
  }

  @override
  Future<void> removePart(String workOrderId, String clientUuid) async {
    final FsmOperation? op = await _store.operation(clientUuid);
    final FsmPartLine? line = await _store.part(tenantId, clientUuid);
    if (line == null) return;
    if (op != null && op.state == FsmOutboxState.done) {
      throw const FsmException(<String, String>{'part': 'already_synced'});
    }
    await _store.transaction<void>(() async {
      if (op != null) await _store.deleteOperation(clientUuid);
      await _store.deletePart(tenantId, clientUuid);
      // Only a reserved quantity (operation still waiting) goes back on the van.
      if (op != null && op.isActive) {
        await _store.adjustVanStock(tenantId, line.productId, line.quantity);
      }
    });
  }

  @override
  Future<ReportPhoto> addPhoto(
    String workOrderId, {
    required String localPath,
    required String name,
    DateTime? takenAt,
  }) async {
    await _openWorkOrder(workOrderId);
    if ((await _store.photos(tenantId, workOrderId)).length >= 20) {
      throw const FsmException(<String, String>{'photos': 'max'});
    }
    final ReportPhoto photo = ReportPhoto(
      id: _newUuid(),
      path: 'fsm/$workOrderId/$name',
      name: name,
      takenAt: takenAt ?? _clock(),
      localPath: localPath,
    );
    await _store.insertPhoto(tenantId, workOrderId, photo);
    return photo;
  }

  @override
  Future<void> removePhoto(String workOrderId, String photoId) =>
      _store.deletePhoto(tenantId, photoId);

  @override
  Future<Map<String, dynamic>> loadDraft(String workOrderId) =>
      _store.draft(tenantId, workOrderId);

  @override
  Future<void> saveDraft(String workOrderId, Map<String, dynamic> draft) =>
      _store.saveDraft(tenantId, workOrderId, draft);

  @override
  Future<StoredReport> signAndClose(
    String workOrderId,
    ServiceReportDraft draft,
  ) async {
    final FsmWorkOrder wo = await _openWorkOrder(workOrderId);
    final Map<String, String> errors = draft.validate();
    final FsmEquipment? equipment = await _store.equipment(
      tenantId,
      wo.equipmentId,
    );
    if (equipment != null &&
        ((draft.meterReadingHours != null &&
                draft.meterReadingHours! < equipment.operatingHours) ||
            (draft.meterReadingCycles != null &&
                draft.meterReadingCycles! < equipment.cycleCount))) {
      errors['meter_reading'] = 'regression';
    }
    if (errors.isNotEmpty) throw FsmException(errors);

    final StoredReport report = StoredReport(
      workOrderId: wo.id,
      clientUuid: _newUuid(),
      signatureSha256: SignatureSvgHash.sha256Hex(draft.signatureSvg),
      signedAt: draft.signedAt,
      payload: draft.toPayload(),
    );
    await _store.transaction<void>(() async {
      await _store.saveReport(tenantId, report);
      await _store.setWorkOrderStatus(tenantId, wo.id, FsmStatus.completed);
      await _store.enqueue(
        tenantId: tenantId,
        workOrderId: wo.id,
        type: FsmOperationType.serviceReport,
        payload: report.payload,
        clientUuid: report.clientUuid,
        createdAt: _clock(),
      );
    });
    return report;
  }

  @override
  Future<void> retryOperation(String clientUuid) => _store.retry(clientUuid);

  @override
  Future<void> discardOperation(String clientUuid) async {
    final FsmOperation? op = await _store.operation(clientUuid);
    if (op == null || op.state == FsmOutboxState.done) return;
    await _store.transaction<void>(() async {
      await _store.deleteOperation(clientUuid);
      switch (op.type) {
        case FsmOperationType.partConsumption:
          final FsmPartLine? line = await _store.part(tenantId, clientUuid);
          if (line != null && op.isActive) {
            await _store.adjustVanStock(
              tenantId,
              line.productId,
              line.quantity,
            );
          }
          await _store.deletePart(tenantId, clientUuid);
        case FsmOperationType.serviceReport:
          await _store.deleteReport(tenantId, op.workOrderId);
          // Back to where the technician was: on site, able to sign again.
          await _store.setWorkOrderStatus(
            tenantId,
            op.workOrderId,
            FsmStatus.onSite,
          );
        case FsmOperationType.statusTransition:
          break; // The next refresh brings the server status back.
      }
    });
  }
}
