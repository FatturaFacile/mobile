import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_engine.dart';
import '../domain/purchase_order_models.dart';
import '../domain/purchase_order_repository.dart';

/// Outbox entities of the three writes. They are listed in [SyncEngine.defaultTerminalEntities]: a 422/403 (wrong
/// state, validation, missing right) parks the row as rejected instead of resending it on every cycle.
const String poConfirmationQueue = 'po_confirmations';
const String poReminderQueue = 'po_reminders';
const String poDeliveryQueue = 'po_dropship_deliveries';

/// Cached reads in the generic entity store (no schema of their own, so no Drift migration).
const String poOrderEntity = 'po_orders';
const String poOverdueEntity = 'po_overdue';
const String poDropshipEntity = 'po_dropships';
const String poConfirmationEntity = 'po_confirmation_log';
const String poReminderEntity = 'po_reminder_log';

const String _procurement = '/procurement';

/// Maps a transport error to a [PoException]; the RFC 7807 `detail` is kept.
PoException mapPoError(DioException e) {
  final Response<dynamic>? r = e.response;
  if (r == null) {
    return const PoException(PoErrorKind.offline);
  }
  final dynamic body = r.data;
  String detail = '';
  if (body is Map) {
    final dynamic d = body['detail'] ?? body['message'] ?? body['title'];
    detail = d is String ? d : '';
  }
  return switch (r.statusCode) {
    403 => PoException(PoErrorKind.forbidden, detail: detail),
    404 => PoException(PoErrorKind.notFound, detail: detail),
    409 || 422 => PoException(PoErrorKind.invalid, detail: detail),
    _ => PoException(PoErrorKind.unknown, detail: detail),
  };
}

class PurchaseOrderRepositoryImpl implements PurchaseOrderRepository {
  PurchaseOrderRepositoryImpl(
    this._db,
    this._dio,
    this._engine, {
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final Dio _dio;
  final SyncEngine _engine;
  final DateTime Function() _clock;

  // --- Orders ----------------------------------------------------------------------------------------------------

  @override
  Future<List<PurchaseOrder>> cachedOrders(String tenantId) async =>
      _orderedByDate(<PurchaseOrder>[
        for (final EntityRecord r in await _rows(tenantId, poOrderEntity))
          PurchaseOrder.fromJson(_decode(r.payload)),
      ]);

  @override
  Future<List<PurchaseOrder>> refreshOrders(String tenantId) async {
    final Response<dynamic> res = await _guard(
      () => _dio.get<dynamic>(
        '$_procurement/purchase-orders',
        queryParameters: <String, dynamic>{'per_page': 100},
      ),
    );
    final Set<String> waiting = await _waitingTargets(tenantId);
    final List<PurchaseOrder> fresh = <PurchaseOrder>[
      for (final Map<String, dynamic> j in _list(res.data))
        PurchaseOrder.fromJson(j),
    ];
    // An order with a queued write keeps its optimistic copy until the server has acknowledged it.
    final Map<String, PurchaseOrder> local = <String, PurchaseOrder>{
      for (final PurchaseOrder o in await cachedOrders(tenantId)) o.id: o,
    };
    final List<PurchaseOrder> merged = <PurchaseOrder>[
      for (final PurchaseOrder o in fresh)
        if (waiting.contains(o.id) && local.containsKey(o.id))
          local[o.id]!
        else
          o,
    ];
    await _replace(tenantId, poOrderEntity, <String, Map<String, dynamic>>{
      for (final PurchaseOrder o in merged) o.id: o.toJson(),
    });
    return _orderedByDate(merged);
  }

  @override
  Future<PurchaseOrder?> cachedOrder(String tenantId, String id) async {
    final EntityRecord? r = await _row(tenantId, poOrderEntity, id);
    return r == null ? null : PurchaseOrder.fromJson(_decode(r.payload));
  }

  @override
  Future<PurchaseOrder> refreshOrder(String tenantId, String id) async {
    final Response<dynamic> res = await _guard(
      () => _dio.get<dynamic>('$_procurement/purchase-orders/$id'),
    );
    final PurchaseOrder order = PurchaseOrder.fromJson(_item(res.data));
    if (!(await _waitingTargets(tenantId)).contains(order.id)) {
      await _put(tenantId, poOrderEntity, order.id, order.toJson());
    }
    return order;
  }

  // --- Overdue ---------------------------------------------------------------------------------------------------

  @override
  Future<List<OverdueOrder>> cachedOverdue(String tenantId) async =>
      _byLateness(<OverdueOrder>[
        for (final EntityRecord r in await _rows(tenantId, poOverdueEntity))
          OverdueOrder.fromJson(_decode(r.payload)),
      ]);

  @override
  Future<List<OverdueOrder>> refreshOverdue(String tenantId) async {
    final Response<dynamic> res = await _guard(
      () => _dio.get<dynamic>('$_procurement/purchase-orders/overdue'),
    );
    final List<OverdueOrder> rows = <OverdueOrder>[
      for (final Map<String, dynamic> j in _list(res.data))
        OverdueOrder.fromJson(j),
    ];
    await _replace(tenantId, poOverdueEntity, <String, Map<String, dynamic>>{
      for (final OverdueOrder o in rows) o.order.id: o.toJson(),
    });
    return _byLateness(rows);
  }

  // --- Confirmations and reminders -------------------------------------------------------------------------------

  @override
  Future<List<PoConfirmation>> cachedConfirmations(
    String tenantId,
    String orderId,
  ) async => <PoConfirmation>[
    for (final EntityRecord r in await _rows(tenantId, poConfirmationEntity))
      if (_decode(r.payload)['purchase_order_id'] == orderId)
        PoConfirmation.fromJson(_decode(r.payload)),
  ];

  @override
  Future<List<PoConfirmation>> refreshConfirmations(
    String tenantId,
    String orderId,
  ) async {
    final Response<dynamic> res = await _guard(
      () => _dio.get<dynamic>(
        '$_procurement/purchase-orders/$orderId/confirmations',
      ),
    );
    final List<Map<String, dynamic>> raw = _list(res.data);
    for (final Map<String, dynamic> j in raw) {
      await _put(tenantId, poConfirmationEntity, '${j['id']}', j);
    }
    return <PoConfirmation>[
      for (final Map<String, dynamic> j in raw) PoConfirmation.fromJson(j),
    ];
  }

  @override
  Future<List<PoReminder>> cachedReminders(
    String tenantId,
    String orderId,
  ) async => <PoReminder>[
    for (final EntityRecord r in await _rows(tenantId, poReminderEntity))
      if (_decode(r.payload)['purchase_order_id'] == orderId)
        PoReminder.fromJson(_decode(r.payload)),
  ];

  @override
  Future<List<PoReminder>> refreshReminders(
    String tenantId,
    String orderId,
  ) async {
    final Response<dynamic> res = await _guard(
      () =>
          _dio.get<dynamic>('$_procurement/purchase-orders/$orderId/reminders'),
    );
    final List<Map<String, dynamic>> raw = _list(res.data);
    for (final Map<String, dynamic> j in raw) {
      await _put(tenantId, poReminderEntity, '${j['id']}', j);
    }
    return <PoReminder>[
      for (final Map<String, dynamic> j in raw) PoReminder.fromJson(j),
    ];
  }

  // --- Dropshipments ---------------------------------------------------------------------------------------------

  @override
  Future<List<Dropship>> cachedDropships(String tenantId) async => <Dropship>[
    for (final EntityRecord r in await _rows(tenantId, poDropshipEntity))
      Dropship.fromJson(_decode(r.payload)),
  ]..sort(_openFirst);

  @override
  Future<List<Dropship>> refreshDropships(String tenantId) async {
    final Response<dynamic> res = await _guard(
      () => _dio.get<dynamic>(
        '$_procurement/dropshipments',
        queryParameters: <String, dynamic>{'per_page': 100},
      ),
    );
    final Set<String> waiting = await _waitingTargets(tenantId);
    final Map<String, Dropship> local = <String, Dropship>{
      for (final Dropship d in await cachedDropships(tenantId)) d.id: d,
    };
    final List<Dropship> merged = <Dropship>[
      for (final Map<String, dynamic> j in _list(res.data))
        _keepWaiting(Dropship.fromJson(j), waiting, local),
    ];
    await _replace(tenantId, poDropshipEntity, <String, Map<String, dynamic>>{
      for (final Dropship d in merged) d.id: d.toJson(),
    });
    return merged..sort(_openFirst);
  }

  @override
  Future<Dropship?> cachedDropship(String tenantId, String id) async {
    final EntityRecord? r = await _row(tenantId, poDropshipEntity, id);
    return r == null ? null : Dropship.fromJson(_decode(r.payload));
  }

  @override
  Future<Dropship> refreshDropship(String tenantId, String id) async {
    final Response<dynamic> res = await _guard(
      () => _dio.get<dynamic>('$_procurement/dropshipments/$id'),
    );
    final Dropship fresh = Dropship.fromJson(_item(res.data));
    final Dropship? local = await cachedDropship(tenantId, id);
    final Dropship kept = _keepWaiting(
      fresh,
      await _waitingTargets(tenantId),
      <String, Dropship>{id: ?local},
    );
    await _put(tenantId, poDropshipEntity, kept.id, kept.toJson());
    return kept;
  }

  static Dropship _keepWaiting(
    Dropship fresh,
    Set<String> waiting,
    Map<String, Dropship> local,
  ) => waiting.contains(fresh.id) && local.containsKey(fresh.id)
      ? local[fresh.id]!
      : fresh;

  // --- Writes (outbox) -------------------------------------------------------------------------------------------

  @override
  Future<PoActionOutcome> confirmOrder(
    String tenantId,
    String orderId,
    ConfirmationInput input,
  ) async {
    final String path = '$_procurement/purchase-orders/$orderId/confirmations';
    final PurchaseOrder? order = await cachedOrder(tenantId, orderId);
    if (order != null) {
      await _put(
        tenantId,
        poOrderEntity,
        orderId,
        _applyConfirmation(order, input).toJson(),
        status: SyncStatus.pendingUpdate,
      );
    }
    return _enqueue(
      tenantId,
      queue: poConfirmationQueue,
      path: path,
      data: input.toJson(),
    );
  }

  /// What the order looks like once the server accepted the confirmation: status `confirmed`, the promised date and the
  /// confirmed quantity, price and date of each line.
  PurchaseOrder _applyConfirmation(PurchaseOrder order, ConfirmationInput i) {
    final Map<String, ConfirmationLineInput> byLine =
        <String, ConfirmationLineInput>{
          for (final ConfirmationLineInput l in i.lines)
            l.purchaseOrderLineId: l,
        };
    DateTime? latest = i.confirmedDeliveryDate;
    final List<PoLine> lines = <PoLine>[
      for (final PoLine l in order.lines)
        if (byLine[l.id] case final ConfirmationLineInput c)
          l.copyWith(
            quantityConfirmed: c.confirmedQuantity,
            unitPrice: c.confirmedUnitPrice,
            confirmedDeliveryDate:
                c.confirmedDeliveryDate ?? i.confirmedDeliveryDate,
          )
        else
          l,
    ];
    for (final ConfirmationLineInput c in i.lines) {
      final DateTime? d = c.confirmedDeliveryDate;
      if (d != null && (latest == null || d.isAfter(latest))) {
        latest = d;
      }
    }
    return order.copyWith(
      status: PoStatus.confirmed,
      rawStatus: PoStatus.confirmed.wire,
      supplierConfirmationNumber: i.confirmationNumber.trim(),
      confirmedAt: i.confirmedAt ?? _clock(),
      promisedDeliveryDate: latest,
      lines: lines,
    );
  }

  @override
  Future<PoActionOutcome> sendReminder(String tenantId, String orderId) async {
    final String path = '$_procurement/purchase-orders/$orderId/reminders';
    for (final QueueItem r in await _engine.queued(tenantId, poReminderQueue)) {
      if (r.path == path && !_refused(r)) {
        // Already waiting: a second tap must not send a second reminder.
        return const PoActionOutcome(PoActionStatus.queued);
      }
    }
    final DateTime now = _clock();
    final PurchaseOrder? order = await cachedOrder(tenantId, orderId);
    if (order != null) {
      await _put(
        tenantId,
        poOrderEntity,
        orderId,
        order
            .copyWith(
              reminderCount: order.reminderCount + 1,
              lastReminderAt: now,
            )
            .toJson(),
        status: SyncStatus.pendingUpdate,
      );
    }
    final EntityRecord? row = await _row(tenantId, poOverdueEntity, orderId);
    if (row != null) {
      final OverdueOrder o = OverdueOrder.fromJson(_decode(row.payload));
      await _put(
        tenantId,
        poOverdueEntity,
        orderId,
        OverdueOrder(
          order: o.order.copyWith(
            reminderCount: o.reminderCount + 1,
            lastReminderAt: now,
          ),
          daysOverdue: o.daysOverdue,
          overdueLineIds: o.overdueLineIds,
          reminderCount: o.reminderCount + 1,
          lastReminderAt: now,
        ).toJson(),
        status: SyncStatus.pendingUpdate,
      );
    }
    return _enqueue(tenantId, queue: poReminderQueue, path: path);
  }

  @override
  Future<PoActionOutcome> recordDelivery(
    String tenantId,
    String dropshipId,
    DeliveryInput input,
  ) async {
    final String path = '$_procurement/dropshipments/$dropshipId/deliveries';
    final Dropship? ship = await cachedDropship(tenantId, dropshipId);
    if (ship != null) {
      // Without line quantities the notice closes the whole shipment; with them the server decides partial/complete.
      final bool complete = input.lines.isEmpty;
      final DropshipStatus next = complete
          ? DropshipStatus.delivered
          : DropshipStatus.partiallyDelivered;
      await _put(
        tenantId,
        poDropshipEntity,
        dropshipId,
        ship
            .copyWith(
              status: next,
              rawStatus: next.wire,
              deliveredAt: input.deliveredAt ?? _clock(),
              deliveryProofReference:
                  input.deliveryProofReference.trim().isEmpty
                  ? null
                  : input.deliveryProofReference.trim(),
              supplierShipmentReference:
                  input.supplierShipmentReference.trim().isEmpty
                  ? null
                  : input.supplierShipmentReference.trim(),
            )
            .toJson(),
        status: SyncStatus.pendingUpdate,
      );
    }
    return _enqueue(
      tenantId,
      queue: poDeliveryQueue,
      path: path,
      data: input.toJson(),
    );
  }

  Future<PoActionOutcome> _enqueue(
    String tenantId, {
    required String queue,
    required String path,
    Map<String, dynamic>? data,
  }) async {
    final String entityId = await _engine.enqueueCommand(
      tenantId: tenantId,
      entity: queue,
      path: path,
      data: data,
    );
    try {
      await _engine.flush(tenantId);
    } catch (_) {
      // Whatever went wrong, the write is safely queued and the next sync cycle resends it.
    }
    for (final QueueItem r in await _engine.queued(tenantId, queue)) {
      if (r.entityId == entityId) {
        return _refused(r)
            ? PoActionOutcome(
                PoActionStatus.rejected,
                detail: r.lastError ?? '',
              )
            : const PoActionOutcome(PoActionStatus.queued);
      }
    }
    return const PoActionOutcome(PoActionStatus.sent);
  }

  // --- Pricing ---------------------------------------------------------------------------------------------------

  @override
  Future<PricingPreview> pricingPreview(PricingInput input) async {
    try {
      final Response<dynamic> res = await _dio.post<dynamic>(
        '$_procurement/purchase-orders/pricing-preview',
        data: input.toJson(),
      );
      return PricingPreview.fromJson(_item(res.data));
    } on DioException catch (e) {
      final PoException err = mapPoError(e);
      if (err.kind == PoErrorKind.offline || err.kind == PoErrorKind.unknown) {
        return PoPricing.preview(input);
      }
      throw err;
    }
  }

  // --- Outbox ----------------------------------------------------------------------------------------------------

  @override
  Future<List<PoPendingAction>> pendingActions(String tenantId) async {
    final List<PoPendingAction> out = <PoPendingAction>[];
    for (final (String queue, PoActionKind kind) in _queues) {
      for (final QueueItem r in await _engine.queued(tenantId, queue)) {
        final String? target = _targetOf(r.path, kind);
        if (target != null) {
          out.add(
            PoPendingAction(
              queueUuid: r.uuid,
              targetId: target,
              kind: kind,
              rejected: _refused(r),
              detail: r.lastError ?? '',
            ),
          );
        }
      }
    }
    return out;
  }

  static const List<(String, PoActionKind)> _queues = <(String, PoActionKind)>[
    (poConfirmationQueue, PoActionKind.confirmation),
    (poReminderQueue, PoActionKind.reminder),
    (poDeliveryQueue, PoActionKind.delivery),
  ];

  /// `/procurement/purchase-orders/{id}/confirmations|reminders` or `/procurement/dropshipments/{id}/deliveries`.
  static String? _targetOf(String path, PoActionKind kind) {
    final List<String> parts = path.split('/');
    final int at = parts.indexOf(
      kind == PoActionKind.delivery ? 'dropshipments' : 'purchase-orders',
    );
    return at < 0 || at + 1 >= parts.length ? null : parts[at + 1];
  }

  Future<Set<String>> _waitingTargets(String tenantId) async => <String>{
    for (final PoPendingAction a in await pendingActions(tenantId))
      if (!a.rejected) a.targetId,
  };

  bool _refused(QueueItem item) =>
      item.state == QueueState.rejected || item.state == QueueState.conflict;

  @override
  Future<void> retryAction(String tenantId, String queueUuid) async {
    await _engine.retry(queueUuid);
    await _engine.flush(tenantId);
  }

  @override
  Future<void> dismissAction(String queueUuid) => _engine.discard(queueUuid);

  @override
  Future<int> flush(String tenantId) async =>
      (await _engine.flush(tenantId)).sent;

  // --- Ordering and parsing --------------------------------------------------------------------------------------

  static List<PurchaseOrder> _orderedByDate(List<PurchaseOrder> orders) =>
      orders..sort((PurchaseOrder a, PurchaseOrder b) {
        final DateTime? x = a.orderDate;
        final DateTime? y = b.orderDate;
        if (x != null && y != null && x != y) {
          return y.compareTo(x);
        }
        return b.poNumber.compareTo(a.poNumber);
      });

  static List<OverdueOrder> _byLateness(List<OverdueOrder> rows) => rows
    ..sort(
      (OverdueOrder a, OverdueOrder b) =>
          b.daysOverdue.compareTo(a.daysOverdue),
    );

  /// Shipments still on the road first, delivered ones last.
  static int _openFirst(Dropship a, Dropship b) {
    final int x = a.status == DropshipStatus.delivered ? 1 : 0;
    final int y = b.status == DropshipStatus.delivered ? 1 : 0;
    return x != y ? x.compareTo(y) : b.id.compareTo(a.id);
  }

  /// `data` is either the list itself or a paginator `{data: [...]}`.
  static List<Map<String, dynamic>> _list(Object? body) {
    Object? data = _map(body)['data'];
    if (data is Map) {
      data = data['data'];
    }
    return <Map<String, dynamic>>[
      if (data is List)
        for (final dynamic raw in data)
          if (raw is Map) Map<String, dynamic>.from(raw),
    ];
  }

  /// A single resource, wrapped in `data` or bare.
  static Map<String, dynamic> _item(Object? body) {
    final Map<String, dynamic> m = _map(body);
    final Object? data = m['data'];
    return data is Map ? Map<String, dynamic>.from(data) : m;
  }

  static Map<String, dynamic> _decode(String payload) =>
      Map<String, dynamic>.from(jsonDecode(payload) as Map<dynamic, dynamic>);

  static Map<String, dynamic> _map(Object? v) =>
      v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

  // --- Local store -----------------------------------------------------------------------------------------------

  Future<List<EntityRecord>> _rows(String tenantId, String entity) {
    return (_db.select(_db.entityRecords)..where(
          (EntityRecords t) =>
              t.tenantId.equals(tenantId) & t.entity.equals(entity),
        ))
        .get();
  }

  Future<EntityRecord?> _row(String tenantId, String entity, String id) {
    return (_db.select(_db.entityRecords)..where(
          (EntityRecords t) =>
              t.tenantId.equals(tenantId) &
              t.entity.equals(entity) &
              t.id.equals(id),
        ))
        .getSingleOrNull();
  }

  Future<void> _put(
    String tenantId,
    String entity,
    String id,
    Map<String, dynamic> payload, {
    SyncStatus status = SyncStatus.synced,
  }) async {
    final DateTime now = DateTime.now().toUtc();
    await _db
        .into(_db.entityRecords)
        .insertOnConflictUpdate(
          EntityRecordsCompanion.insert(
            entity: entity,
            id: id,
            tenantId: tenantId,
            payload: jsonEncode(payload),
            syncStatus: status,
            localUpdatedAt: now,
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<void> _replace(
    String tenantId,
    String entity,
    Map<String, Map<String, dynamic>> items,
  ) async {
    await _db.transaction(() async {
      await (_db.delete(_db.entityRecords)..where(
            (EntityRecords t) =>
                t.tenantId.equals(tenantId) & t.entity.equals(entity),
          ))
          .go();
      for (final MapEntry<String, Map<String, dynamic>> e in items.entries) {
        await _put(tenantId, entity, e.key, e.value);
      }
    });
  }

  Future<Response<dynamic>> _guard(
    Future<Response<dynamic>> Function() call,
  ) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw mapPoError(e);
    }
  }
}
