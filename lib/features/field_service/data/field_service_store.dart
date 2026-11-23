import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../models/field_service_models.dart';

/// What [FieldServiceStore.mergeBundle] did.
class BundleMerge {
  const BundleMerge({this.updated = 0, this.removed = 0});

  /// Work orders inserted or refreshed from the bundle.
  final int updated;

  /// Work orders that left the technician's queue and were dropped from the phone.
  final int removed;
}

/// The local SQLite side of the Field Service workflow, in the app database (`AppDatabase`).
///
/// The tables (`fsm_*`) are created on first use with `CREATE TABLE IF NOT EXISTS` through plain SQL: the feature adds no
/// generated Drift code, so the shared schema version and the generated `app_database.g.dart` stay untouched. Every row is
/// scoped by `tenant_id` and the UI reads only from here. Changes are announced on an in-process stream that the `watch*`
/// methods re-read from.
class FieldServiceStore {
  FieldServiceStore(this._db);

  final AppDatabase _db;
  final StreamController<void> _changes = StreamController<void>.broadcast();
  Future<void>? _ready;

  /// Creates the tables once. Every public method awaits it.
  Future<void> ensureSchema() => _ready ??= _create();

  Future<void> dispose() => _changes.close();

  /// Runs [body] as one SQLite transaction (a local change and the operation that carries it commit together).
  Future<T> transaction<T>(Future<T> Function() body) async {
    await ensureSchema();
    return _db.transaction(body);
  }

  /// A stream that re-runs [read] whenever the store changes.
  Stream<T> watchQuery<T>(Future<T> Function() read) => _watch<T>(read);

  static const List<String> _ddl = <String>[
    'CREATE TABLE IF NOT EXISTS fsm_work_orders ('
        'tenant_id TEXT NOT NULL, id TEXT NOT NULL, work_order_number TEXT NOT NULL, '
        'status TEXT NOT NULL, scheduled_start TEXT, payload TEXT NOT NULL, synced_at TEXT NOT NULL, '
        'PRIMARY KEY (tenant_id, id))',
    'CREATE TABLE IF NOT EXISTS fsm_customers ('
        'tenant_id TEXT NOT NULL, id TEXT NOT NULL, payload TEXT NOT NULL, PRIMARY KEY (tenant_id, id))',
    'CREATE TABLE IF NOT EXISTS fsm_equipment ('
        'tenant_id TEXT NOT NULL, id TEXT NOT NULL, payload TEXT NOT NULL, PRIMARY KEY (tenant_id, id))',
    'CREATE TABLE IF NOT EXISTS fsm_van_stock ('
        'tenant_id TEXT NOT NULL, product_id TEXT NOT NULL, payload TEXT NOT NULL, '
        'PRIMARY KEY (tenant_id, product_id))',
    'CREATE TABLE IF NOT EXISTS fsm_meta ('
        'tenant_id TEXT NOT NULL, meta_key TEXT NOT NULL, meta_value TEXT NOT NULL, '
        'PRIMARY KEY (tenant_id, meta_key))',
    'CREATE TABLE IF NOT EXISTS fsm_checklist ('
        'tenant_id TEXT NOT NULL, work_order_id TEXT NOT NULL, item TEXT NOT NULL, '
        'result TEXT NOT NULL, notes TEXT, PRIMARY KEY (tenant_id, work_order_id, item))',
    'CREATE TABLE IF NOT EXISTS fsm_drafts ('
        'tenant_id TEXT NOT NULL, work_order_id TEXT NOT NULL, payload TEXT NOT NULL, '
        'PRIMARY KEY (tenant_id, work_order_id))',
    'CREATE TABLE IF NOT EXISTS fsm_parts ('
        'tenant_id TEXT NOT NULL, client_uuid TEXT NOT NULL, work_order_id TEXT NOT NULL, '
        'payload TEXT NOT NULL, created_at TEXT NOT NULL, PRIMARY KEY (tenant_id, client_uuid))',
    'CREATE TABLE IF NOT EXISTS fsm_photos ('
        'tenant_id TEXT NOT NULL, id TEXT NOT NULL, work_order_id TEXT NOT NULL, path TEXT NOT NULL, '
        'name TEXT NOT NULL, taken_at TEXT NOT NULL, local_path TEXT, stage TEXT, caption TEXT, server_id TEXT, '
        'PRIMARY KEY (tenant_id, id))',
    'CREATE TABLE IF NOT EXISTS fsm_reports ('
        'tenant_id TEXT NOT NULL, work_order_id TEXT NOT NULL, client_uuid TEXT NOT NULL, '
        'signature_sha256 TEXT NOT NULL, signed_at TEXT NOT NULL, payload TEXT NOT NULL, '
        'report_number TEXT, server_hash TEXT, PRIMARY KEY (tenant_id, work_order_id))',
    'CREATE TABLE IF NOT EXISTS fsm_outbox ('
        'sequence INTEGER PRIMARY KEY AUTOINCREMENT, client_uuid TEXT NOT NULL UNIQUE, '
        'tenant_id TEXT NOT NULL, work_order_id TEXT NOT NULL, type TEXT NOT NULL, payload TEXT NOT NULL, '
        'state INTEGER NOT NULL DEFAULT 0, attempts INTEGER NOT NULL DEFAULT 0, last_error TEXT, '
        'errors TEXT, replayed INTEGER NOT NULL DEFAULT 0, next_attempt_at TEXT, result TEXT, '
        'created_at TEXT NOT NULL, completed_at TEXT)',
    'CREATE INDEX IF NOT EXISTS idx_fsm_outbox_tenant_state ON fsm_outbox (tenant_id, state)',
  ];

  Future<void> _create() async {
    for (final String statement in _ddl) {
      await _db.customStatement(statement);
    }
    // Photos created before the upload existed lack these columns (no schema bump: the tables live outside Drift).
    final List<QueryRow> columns = await _db
        .customSelect('PRAGMA table_info(fsm_photos)')
        .get();
    final Set<String> have = <String>{
      for (final QueryRow c in columns) '${c.data['name']}',
    };
    for (final String column in <String>['stage', 'caption', 'server_id']) {
      if (!have.contains(column)) {
        await _db.customStatement(
          'ALTER TABLE fsm_photos ADD COLUMN $column TEXT',
        );
      }
    }
  }

  // ---------------------------------------------------------------- plumbing

  List<Variable<Object>> _vars(List<Object?> args) => <Variable<Object>>[
    for (final Object? a in args)
      switch (a) {
        final String s => Variable<String>(s),
        final int i => Variable<int>(i),
        final double d => Variable<double>(d),
        final bool b => Variable<int>(b ? 1 : 0),
        _ => const Variable<String>(null),
      },
  ];

  Future<List<Map<String, Object?>>> _rows(
    String sql,
    List<Object?> args,
  ) async {
    await ensureSchema();
    final List<QueryRow> rows = await _db
        .customSelect(sql, variables: _vars(args))
        .get();
    return <Map<String, Object?>>[for (final QueryRow r in rows) r.data];
  }

  Future<void> _exec(
    String sql, [
    List<Object?> args = const <Object?>[],
  ]) async {
    await ensureSchema();
    await _db.customStatement(sql, args);
  }

  void _notify() {
    if (!_changes.isClosed) _changes.add(null);
  }

  Stream<T> _watch<T>(Future<T> Function() read) {
    late final StreamController<T> controller;
    StreamSubscription<void>? subscription;
    Future<void> emit() async {
      try {
        final T value = await read();
        if (!controller.isClosed) controller.add(value);
      } on Object catch (e, s) {
        if (!controller.isClosed) controller.addError(e, s);
      }
    }

    controller = StreamController<T>(
      onListen: () {
        subscription = _changes.stream.listen((_) => emit());
        emit();
      },
      onCancel: () => subscription?.cancel(),
    );
    return controller.stream;
  }

  Map<String, dynamic> _json(Object? raw) => raw is String && raw.isNotEmpty
      ? Map<String, dynamic>.from(jsonDecode(raw) as Map<dynamic, dynamic>)
      : <String, dynamic>{};

  String _iso(DateTime t) => t.toUtc().toIso8601String();

  // ------------------------------------------------------------------ bundle

  /// Applies an offline bundle: upserts the changed work orders, customers and equipment, replaces the van catalog and drops
  /// the work orders that left the queue.
  ///
  /// Work orders with operations still waiting to be synced keep their local (further along) status, and the van quantities
  /// are reduced by the parts already consumed but not yet acknowledged, so the screens never go back in time.
  Future<BundleMerge> mergeBundle(
    String tenantId,
    OfflineBundle bundle,
    DateTime now,
  ) async {
    await ensureSchema();
    var updated = 0;
    var removed = 0;
    await _db.transaction(() async {
      final Set<String> busy = await _workOrdersWithActiveOperations(tenantId);

      for (final FsmWorkOrder incoming in bundle.workOrders) {
        FsmWorkOrder next = incoming;
        if (busy.contains(incoming.id)) {
          final FsmWorkOrder? local = await workOrder(tenantId, incoming.id);
          if (local != null &&
              (local.status.rank > incoming.status.rank ||
                  local.status == FsmStatus.completed)) {
            next = incoming.copyWith(status: local.status);
          }
        }
        await _upsertWorkOrder(tenantId, next, now);
        updated++;
      }

      final Set<String> open = bundle.openWorkOrderIds.toSet();
      for (final FsmWorkOrder stored in await workOrders(tenantId)) {
        if (!open.contains(stored.id) && !busy.contains(stored.id)) {
          await _deleteWorkOrder(tenantId, stored.id);
          removed++;
        }
      }

      for (final FsmCustomer c in bundle.customers) {
        await _exec(
          'INSERT OR REPLACE INTO fsm_customers (tenant_id, id, payload) VALUES (?, ?, ?)',
          <Object?>[tenantId, c.id, jsonEncode(c.toJson())],
        );
      }
      for (final FsmEquipment e in bundle.equipment) {
        await _exec(
          'INSERT OR REPLACE INTO fsm_equipment (tenant_id, id, payload) VALUES (?, ?, ?)',
          <Object?>[tenantId, e.id, jsonEncode(e.toJson())],
        );
      }

      final Map<String, double> reserved = await _reservedVanQuantities(
        tenantId,
      );
      await _exec('DELETE FROM fsm_van_stock WHERE tenant_id = ?', <Object?>[
        tenantId,
      ]);
      for (final VanStockItem item in bundle.vanStock) {
        final double left = item.available - (reserved[item.productId] ?? 0);
        await _exec(
          'INSERT OR REPLACE INTO fsm_van_stock (tenant_id, product_id, payload) VALUES (?, ?, ?)',
          <Object?>[
            tenantId,
            item.productId,
            jsonEncode(item.withAvailable(left < 0 ? 0 : left).toJson()),
          ],
        );
      }

      await setMeta(tenantId, 'server_time', bundle.serverTime);
      await setMeta(
        tenantId,
        'technician',
        jsonEncode(bundle.technician.toJson()),
      );
    });
    _notify();
    return BundleMerge(updated: updated, removed: removed);
  }

  Future<Set<String>> _workOrdersWithActiveOperations(String tenantId) async {
    final List<Map<String, Object?>> rows = await _rows(
      'SELECT DISTINCT work_order_id FROM fsm_outbox WHERE tenant_id = ? AND state IN (0, 1)',
      <Object?>[tenantId],
    );
    return <String>{
      for (final Map<String, Object?> r in rows) '${r['work_order_id']}',
    };
  }

  Future<Map<String, double>> _reservedVanQuantities(String tenantId) async {
    final List<Map<String, Object?>> rows = await _rows(
      'SELECT p.payload AS payload FROM fsm_parts p '
      'JOIN fsm_outbox o ON o.client_uuid = p.client_uuid AND o.tenant_id = p.tenant_id '
      'WHERE p.tenant_id = ? AND o.state IN (0, 1)',
      <Object?>[tenantId],
    );
    final Map<String, double> totals = <String, double>{};
    for (final Map<String, Object?> r in rows) {
      final FsmPartLine line = FsmPartLine.fromJson(_json(r['payload']));
      totals[line.productId] = (totals[line.productId] ?? 0) + line.quantity;
    }
    return totals;
  }

  Future<void> _upsertWorkOrder(
    String tenantId,
    FsmWorkOrder wo,
    DateTime now,
  ) => _exec(
    'INSERT OR REPLACE INTO fsm_work_orders '
    '(tenant_id, id, work_order_number, status, scheduled_start, payload, synced_at) '
    'VALUES (?, ?, ?, ?, ?, ?, ?)',
    <Object?>[
      tenantId,
      wo.id,
      wo.number,
      wo.status.wire,
      wo.scheduledStart == null ? null : _iso(wo.scheduledStart!),
      jsonEncode(wo.toJson()),
      _iso(now),
    ],
  );

  Future<void> _deleteWorkOrder(String tenantId, String id) async {
    await _exec(
      'DELETE FROM fsm_work_orders WHERE tenant_id = ? AND id = ?',
      <Object?>[tenantId, id],
    );
    for (final String table in <String>[
      'fsm_checklist',
      'fsm_drafts',
      'fsm_parts',
      'fsm_photos',
      'fsm_reports',
    ]) {
      await _exec(
        'DELETE FROM $table WHERE tenant_id = ? AND work_order_id = ?',
        <Object?>[tenantId, id],
      );
    }
  }

  // -------------------------------------------------------------------- meta

  Future<void> setMeta(String tenantId, String key, String value) => _exec(
    'INSERT OR REPLACE INTO fsm_meta (tenant_id, meta_key, meta_value) VALUES (?, ?, ?)',
    <Object?>[tenantId, key, value],
  );

  Future<String?> meta(String tenantId, String key) async {
    final List<Map<String, Object?>> rows = await _rows(
      'SELECT meta_value FROM fsm_meta WHERE tenant_id = ? AND meta_key = ?',
      <Object?>[tenantId, key],
    );
    return rows.isEmpty ? null : rows.first['meta_value'] as String?;
  }

  /// `server_time` of the last bundle, the `since` of the next delta.
  Future<String?> serverTime(String tenantId) => meta(tenantId, 'server_time');

  Future<FsmTechnician?> technician(String tenantId) async {
    final String? raw = await meta(tenantId, 'technician');
    return raw == null ? null : FsmTechnician.fromJson(_json(raw));
  }

  // ------------------------------------------------------------- work orders

  Future<List<FsmWorkOrder>> workOrders(String tenantId) async {
    final List<Map<String, Object?>> rows = await _rows(
      'SELECT status, payload FROM fsm_work_orders WHERE tenant_id = ? '
      'ORDER BY scheduled_start IS NULL, scheduled_start, work_order_number',
      <Object?>[tenantId],
    );
    return <FsmWorkOrder>[
      for (final Map<String, Object?> r in rows) _workOrderOf(r),
    ];
  }

  FsmWorkOrder _workOrderOf(Map<String, Object?> row) =>
      FsmWorkOrder.fromJson(_json(row['payload']))
          .copyWith(status: FsmStatus.fromWire(row['status'] as String?));

  Stream<List<FsmWorkOrder>> watchWorkOrders(String tenantId) =>
      _watch<List<FsmWorkOrder>>(() => workOrders(tenantId));

  Future<FsmWorkOrder?> workOrder(String tenantId, String id) async {
    final List<Map<String, Object?>> rows = await _rows(
      'SELECT status, payload FROM fsm_work_orders WHERE tenant_id = ? AND id = ?',
      <Object?>[tenantId, id],
    );
    return rows.isEmpty ? null : _workOrderOf(rows.first);
  }

  Future<void> setWorkOrderStatus(
    String tenantId,
    String id,
    FsmStatus status,
  ) async {
    final FsmWorkOrder? current = await workOrder(tenantId, id);
    if (current == null) return;
    await _exec(
      'UPDATE fsm_work_orders SET status = ?, payload = ? WHERE tenant_id = ? AND id = ?',
      <Object?>[
        status.wire,
        jsonEncode(current.copyWith(status: status).toJson()),
        tenantId,
        id,
      ],
    );
    _notify();
  }

  Future<FsmCustomer?> customer(String tenantId, String? id) async {
    if (id == null) return null;
    final List<Map<String, Object?>> rows = await _rows(
      'SELECT payload FROM fsm_customers WHERE tenant_id = ? AND id = ?',
      <Object?>[tenantId, id],
    );
    return rows.isEmpty
        ? null
        : FsmCustomer.fromJson(_json(rows.first['payload']));
  }

  Future<Map<String, FsmCustomer>> customers(String tenantId) async {
    final List<Map<String, Object?>> rows = await _rows(
      'SELECT payload FROM fsm_customers WHERE tenant_id = ?',
      <Object?>[tenantId],
    );
    return <String, FsmCustomer>{
      for (final Map<String, Object?> r in rows)
        FsmCustomer.fromJson(_json(r['payload'])).id: FsmCustomer.fromJson(
          _json(r['payload']),
        ),
    };
  }

  Future<FsmEquipment?> equipment(String tenantId, String? id) async {
    if (id == null) return null;
    final List<Map<String, Object?>> rows = await _rows(
      'SELECT payload FROM fsm_equipment WHERE tenant_id = ? AND id = ?',
      <Object?>[tenantId, id],
    );
    return rows.isEmpty
        ? null
        : FsmEquipment.fromJson(_json(rows.first['payload']));
  }

  Future<Map<String, FsmEquipment>> allEquipment(String tenantId) async {
    final List<Map<String, Object?>> rows = await _rows(
      'SELECT payload FROM fsm_equipment WHERE tenant_id = ?',
      <Object?>[tenantId],
    );
    return <String, FsmEquipment>{
      for (final Map<String, Object?> r in rows)
        FsmEquipment.fromJson(_json(r['payload'])).id: FsmEquipment.fromJson(
          _json(r['payload']),
        ),
    };
  }

  // --------------------------------------------------------------- van stock

  Future<List<VanStockItem>> vanStock(String tenantId) async {
    final List<Map<String, Object?>> rows = await _rows(
      'SELECT payload FROM fsm_van_stock WHERE tenant_id = ?',
      <Object?>[tenantId],
    );
    final List<VanStockItem> items =
        <VanStockItem>[
          for (final Map<String, Object?> r in rows)
            VanStockItem.fromJson(_json(r['payload'])),
        ]..sort(
          (VanStockItem a, VanStockItem b) =>
              a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
    return items;
  }

  Stream<List<VanStockItem>> watchVanStock(String tenantId) =>
      _watch<List<VanStockItem>>(() => vanStock(tenantId));

  /// Adds [delta] (negative to consume) to the quantity on board of [productId], never below zero.
  Future<void> adjustVanStock(
    String tenantId,
    String productId,
    double delta,
  ) async {
    final List<Map<String, Object?>> rows = await _rows(
      'SELECT payload FROM fsm_van_stock WHERE tenant_id = ? AND product_id = ?',
      <Object?>[tenantId, productId],
    );
    if (rows.isEmpty) return;
    final VanStockItem item = VanStockItem.fromJson(
      _json(rows.first['payload']),
    );
    final double next = item.available + delta;
    await _exec(
      'UPDATE fsm_van_stock SET payload = ? WHERE tenant_id = ? AND product_id = ?',
      <Object?>[
        jsonEncode(item.withAvailable(next < 0 ? 0 : next).toJson()),
        tenantId,
        productId,
      ],
    );
    _notify();
  }

  // --------------------------------------------------------------- checklist

  /// The answers for [template], in template order; unanswered points are `pending`.
  Future<List<ChecklistEntry>> checklist(
    String tenantId,
    String workOrderId,
    List<String> template,
  ) async {
    final List<Map<String, Object?>> rows = await _rows(
      'SELECT item, result, notes FROM fsm_checklist WHERE tenant_id = ? AND work_order_id = ?',
      <Object?>[tenantId, workOrderId],
    );
    final Map<String, Map<String, Object?>> byItem =
        <String, Map<String, Object?>>{
          for (final Map<String, Object?> r in rows) '${r['item']}': r,
        };
    return <ChecklistEntry>[
      for (final String item in template)
        ChecklistEntry(
          item: item,
          result: ChecklistResult.fromWire(byItem[item]?['result'] as String?),
          notes: byItem[item]?['notes'] as String?,
        ),
    ];
  }

  Future<void> setChecklistResult(
    String tenantId,
    String workOrderId,
    String item,
    ChecklistResult result, {
    String? notes,
  }) async {
    await _exec(
      'INSERT OR REPLACE INTO fsm_checklist (tenant_id, work_order_id, item, result, notes) '
      'VALUES (?, ?, ?, ?, ?)',
      <Object?>[tenantId, workOrderId, item, result.wire, notes],
    );
    _notify();
  }

  // ------------------------------------------------------------------- draft

  Future<void> saveDraft(
    String tenantId,
    String workOrderId,
    Map<String, dynamic> draft,
  ) async {
    await _exec(
      'INSERT OR REPLACE INTO fsm_drafts (tenant_id, work_order_id, payload) VALUES (?, ?, ?)',
      <Object?>[tenantId, workOrderId, jsonEncode(draft)],
    );
  }

  Future<Map<String, dynamic>> draft(
    String tenantId,
    String workOrderId,
  ) async {
    final List<Map<String, Object?>> rows = await _rows(
      'SELECT payload FROM fsm_drafts WHERE tenant_id = ? AND work_order_id = ?',
      <Object?>[tenantId, workOrderId],
    );
    return rows.isEmpty ? <String, dynamic>{} : _json(rows.first['payload']);
  }

  // ------------------------------------------------------------------- parts

  Future<List<FsmPartLine>> parts(String tenantId, String workOrderId) async {
    final List<Map<String, Object?>> rows = await _rows(
      'SELECT payload FROM fsm_parts WHERE tenant_id = ? AND work_order_id = ? ORDER BY created_at, client_uuid',
      <Object?>[tenantId, workOrderId],
    );
    return <FsmPartLine>[
      for (final Map<String, Object?> r in rows)
        FsmPartLine.fromJson(_json(r['payload'])),
    ];
  }

  Future<void> insertPart(String tenantId, FsmPartLine line) async {
    await _exec(
      'INSERT OR REPLACE INTO fsm_parts (tenant_id, client_uuid, work_order_id, payload, created_at) '
      'VALUES (?, ?, ?, ?, ?)',
      <Object?>[
        tenantId,
        line.clientUuid,
        line.workOrderId,
        jsonEncode(line.toJson()),
        _iso(line.createdAt),
      ],
    );
    _notify();
  }

  Future<FsmPartLine?> part(String tenantId, String clientUuid) async {
    final List<Map<String, Object?>> rows = await _rows(
      'SELECT payload FROM fsm_parts WHERE tenant_id = ? AND client_uuid = ?',
      <Object?>[tenantId, clientUuid],
    );
    return rows.isEmpty
        ? null
        : FsmPartLine.fromJson(_json(rows.first['payload']));
  }

  Future<void> deletePart(String tenantId, String clientUuid) async {
    await _exec(
      'DELETE FROM fsm_parts WHERE tenant_id = ? AND client_uuid = ?',
      <Object?>[tenantId, clientUuid],
    );
    _notify();
  }

  // ------------------------------------------------------------------ photos

  /// The photos of a work order with their upload state, derived from the upload operation (same id as the photo).
  Future<List<ReportPhoto>> photos(String tenantId, String workOrderId) async {
    final List<Map<String, Object?>> rows = await _rows(
      'SELECT p.id, p.path, p.name, p.taken_at, p.local_path, p.stage, p.caption, p.server_id, '
      'o.state AS op_state FROM fsm_photos p LEFT JOIN fsm_outbox o ON o.client_uuid = p.id '
      'WHERE p.tenant_id = ? AND p.work_order_id = ? ORDER BY p.taken_at, p.id',
      <Object?>[tenantId, workOrderId],
    );
    return <ReportPhoto>[
      for (final Map<String, Object?> r in rows)
        ReportPhoto(
          id: '${r['id']}',
          path: '${r['path']}',
          name: '${r['name']}',
          takenAt: DateTime.parse('${r['taken_at']}'),
          localPath: r['local_path'] as String?,
          stage: FsmPhotoStage.fromWire(r['stage'] as String?),
          caption: r['caption'] as String?,
          serverId: r['server_id'] as String?,
          upload: _uploadState(
            r['server_id'] as String?,
            r['op_state'] as int?,
          ),
        ),
    ];
  }

  FsmPhotoUpload _uploadState(String? serverId, int? opState) {
    if (serverId != null || opState == FsmOutboxState.done) {
      return FsmPhotoUpload.uploaded;
    }
    // No operation at all: a photo taken before the upload existed, nothing will ever send it.
    if (opState == null || opState == FsmOutboxState.rejected) {
      return FsmPhotoUpload.failed;
    }
    return FsmPhotoUpload.queued;
  }

  Future<void> insertPhoto(
    String tenantId,
    String workOrderId,
    ReportPhoto photo,
  ) async {
    await _exec(
      'INSERT OR REPLACE INTO fsm_photos '
      '(tenant_id, id, work_order_id, path, name, taken_at, local_path, stage, caption, server_id) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      <Object?>[
        tenantId,
        photo.id,
        workOrderId,
        photo.path,
        photo.name,
        _iso(photo.takenAt),
        photo.localPath,
        photo.stage?.wire,
        photo.caption,
        photo.serverId,
      ],
    );
    _notify();
  }

  /// Remembers the id the server gave to an uploaded photo.
  Future<void> setPhotoServerId(
    String tenantId,
    String id,
    String serverId,
  ) async {
    await _exec(
      'UPDATE fsm_photos SET server_id = ? WHERE tenant_id = ? AND id = ?',
      <Object?>[serverId, tenantId, id],
    );
    _notify();
  }

  /// Server ids of the photos of a work order already uploaded, oldest first (the report's `photo_ids`).
  Future<List<String>> photoServerIds(
    String tenantId,
    String workOrderId,
  ) async {
    final List<Map<String, Object?>> rows = await _rows(
      'SELECT server_id FROM fsm_photos WHERE tenant_id = ? AND work_order_id = ? AND server_id IS NOT NULL '
      'ORDER BY taken_at, id',
      <Object?>[tenantId, workOrderId],
    );
    return <String>[
      for (final Map<String, Object?> r in rows) '${r['server_id']}',
    ];
  }

  Future<void> deletePhoto(String tenantId, String id) async {
    await _exec(
      'DELETE FROM fsm_photos WHERE tenant_id = ? AND id = ?',
      <Object?>[tenantId, id],
    );
    _notify();
  }

  // ----------------------------------------------------------------- reports

  Future<void> saveReport(String tenantId, StoredReport report) async {
    await _exec(
      'INSERT OR REPLACE INTO fsm_reports '
      '(tenant_id, work_order_id, client_uuid, signature_sha256, signed_at, payload, report_number, server_hash) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      <Object?>[
        tenantId,
        report.workOrderId,
        report.clientUuid,
        report.signatureSha256,
        _iso(report.signedAt),
        jsonEncode(report.payload),
        report.reportNumber,
        report.serverSealHash,
      ],
    );
    _notify();
  }

  Future<StoredReport?> report(String tenantId, String workOrderId) async {
    final List<Map<String, Object?>> rows = await _rows(
      'SELECT * FROM fsm_reports WHERE tenant_id = ? AND work_order_id = ?',
      <Object?>[tenantId, workOrderId],
    );
    if (rows.isEmpty) return null;
    final Map<String, Object?> r = rows.first;
    return StoredReport(
      workOrderId: '${r['work_order_id']}',
      clientUuid: '${r['client_uuid']}',
      signatureSha256: '${r['signature_sha256']}',
      signedAt: DateTime.parse('${r['signed_at']}'),
      payload: _json(r['payload']),
      reportNumber: r['report_number'] as String?,
      serverSealHash: r['server_hash'] as String?,
    );
  }

  Future<void> deleteReport(String tenantId, String workOrderId) async {
    await _exec(
      'DELETE FROM fsm_reports WHERE tenant_id = ? AND work_order_id = ?',
      <Object?>[tenantId, workOrderId],
    );
    _notify();
  }

  Future<void> markReportAcknowledged(
    String tenantId,
    String clientUuid, {
    String? reportNumber,
    String? serverSealHash,
  }) async {
    await _exec(
      'UPDATE fsm_reports SET report_number = ?, server_hash = ? WHERE tenant_id = ? AND client_uuid = ?',
      <Object?>[reportNumber, serverSealHash, tenantId, clientUuid],
    );
    _notify();
  }

  // ------------------------------------------------------------------ outbox

  /// Queues one operation. [clientUuid] is the idempotency key and never changes afterwards.
  Future<FsmOperation> enqueue({
    required String tenantId,
    required String workOrderId,
    required FsmOperationType type,
    required Map<String, dynamic> payload,
    required String clientUuid,
    required DateTime createdAt,
  }) async {
    await _exec(
      'INSERT INTO fsm_outbox (client_uuid, tenant_id, work_order_id, type, payload, created_at) '
      'VALUES (?, ?, ?, ?, ?, ?)',
      <Object?>[
        clientUuid,
        tenantId,
        workOrderId,
        type.wire,
        jsonEncode(payload),
        _iso(createdAt),
      ],
    );
    _notify();
    return (await operation(clientUuid))!;
  }

  FsmOperation _operationOf(Map<String, Object?> r) {
    final Map<String, List<String>> errors = <String, List<String>>{};
    _json(r['errors']).forEach((String k, dynamic v) {
      errors[k] = <String>[for (final dynamic e in (v as List<dynamic>)) '$e'];
    });
    return FsmOperation(
      sequence: r['sequence'] as int,
      clientUuid: '${r['client_uuid']}',
      tenantId: '${r['tenant_id']}',
      workOrderId: '${r['work_order_id']}',
      type: FsmOperationType.fromWire('${r['type']}'),
      payload: _json(r['payload']),
      state: r['state'] as int,
      attempts: r['attempts'] as int,
      createdAt: DateTime.parse('${r['created_at']}'),
      lastError: r['last_error'] as String?,
      errors: errors,
      replayed: (r['replayed'] as int) == 1,
      nextAttemptAt: r['next_attempt_at'] == null
          ? null
          : DateTime.parse('${r['next_attempt_at']}'),
      result: _json(r['result']),
    );
  }

  Future<FsmOperation?> operation(String clientUuid) async {
    final List<Map<String, Object?>> rows = await _rows(
      'SELECT * FROM fsm_outbox WHERE client_uuid = ?',
      <Object?>[clientUuid],
    );
    return rows.isEmpty ? null : _operationOf(rows.first);
  }

  /// Every operation of the tenant, oldest first.
  Future<List<FsmOperation>> operations(
    String tenantId, {
    List<int>? states,
  }) async {
    final String filter = states == null || states.isEmpty
        ? ''
        : ' AND state IN (${states.join(', ')})';
    final List<Map<String, Object?>> rows = await _rows(
      'SELECT * FROM fsm_outbox WHERE tenant_id = ?$filter ORDER BY sequence',
      <Object?>[tenantId],
    );
    return <FsmOperation>[
      for (final Map<String, Object?> r in rows) _operationOf(r),
    ];
  }

  /// Operations still to send (pending or failed), oldest first.
  Future<List<FsmOperation>> activeOperations(String tenantId) => operations(
    tenantId,
    states: <int>[FsmOutboxState.pending, FsmOutboxState.failed],
  );

  /// Operations the server rejected: the conflict report shown to the technician.
  Future<List<FsmOperation>> conflicts(String tenantId) =>
      operations(tenantId, states: <int>[FsmOutboxState.rejected]);

  Stream<List<FsmOperation>> watchConflicts(String tenantId) =>
      _watch<List<FsmOperation>>(() => conflicts(tenantId));

  /// Number of operations not yet acknowledged and not rejected.
  Stream<int> watchPending(String tenantId) =>
      _watch<int>(() async => (await activeOperations(tenantId)).length);

  Future<void> markDone(
    String clientUuid, {
    required bool replayed,
    required Map<String, dynamic> result,
    required DateTime now,
  }) async {
    await _exec(
      'UPDATE fsm_outbox SET state = ?, replayed = ?, result = ?, last_error = NULL, errors = NULL, '
      'next_attempt_at = NULL, completed_at = ? WHERE client_uuid = ?',
      <Object?>[
        FsmOutboxState.done,
        replayed ? 1 : 0,
        jsonEncode(result),
        _iso(now),
        clientUuid,
      ],
    );
    _notify();
  }

  Future<void> markRejected(
    String clientUuid, {
    required Map<String, List<String>> errors,
    String? message,
  }) async {
    await _exec(
      'UPDATE fsm_outbox SET state = ?, attempts = attempts + 1, errors = ?, last_error = ?, '
      'next_attempt_at = NULL WHERE client_uuid = ?',
      <Object?>[
        FsmOutboxState.rejected,
        jsonEncode(errors),
        message,
        clientUuid,
      ],
    );
    _notify();
  }

  Future<void> markFailed(
    String clientUuid, {
    required String message,
    required DateTime nextAttemptAt,
  }) async {
    await _exec(
      'UPDATE fsm_outbox SET state = ?, attempts = attempts + 1, last_error = ?, next_attempt_at = ? '
      'WHERE client_uuid = ?',
      <Object?>[
        FsmOutboxState.failed,
        message,
        _iso(nextAttemptAt),
        clientUuid,
      ],
    );
    _notify();
  }

  /// Puts a rejected or failed operation back in line, keeping its `client_uuid`.
  Future<void> retry(String clientUuid) async {
    await _exec(
      'UPDATE fsm_outbox SET state = ?, last_error = NULL, errors = NULL, next_attempt_at = NULL '
      'WHERE client_uuid = ? AND state IN (1, 2)',
      <Object?>[FsmOutboxState.pending, clientUuid],
    );
    _notify();
  }

  /// Deletes an operation that was not acknowledged.
  Future<void> deleteOperation(String clientUuid) async {
    await _exec(
      'DELETE FROM fsm_outbox WHERE client_uuid = ? AND state <> 3',
      <Object?>[clientUuid],
    );
    _notify();
  }

  /// Announces a change made outside this store (a refresh that finished).
  void notifyChanged() => _notify();
}
