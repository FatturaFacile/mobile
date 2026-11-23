import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_engine.dart';
import '../domain/swiss_vat_models.dart';
import '../domain/swiss_vat_repository.dart';

/// Outbox queue entities registered in [SyncEngine.defaultTerminalEntities].
const String swissVatBezugsteuerReqEntity = 'swiss_vat_bezugsteuer_requests';
const String swissVatAdjustmentReqEntity = 'swiss_vat_adjustment_requests';
const String swissVatReturnReqEntity = 'swiss_vat_return_requests';

/// Offline SQLite entity store keys inside Drift `EntityRecords` (no schema migration required).
const String swissVatConfigEntity = 'swiss_vat_config';
const String swissVatTaxCodeEntity = 'swiss_vat_tax_codes';
const String swissVatReturnEntity = 'swiss_vat_returns';
const String swissVatBezugsteuerEntity = 'swiss_vat_bezugsteuer';
const String swissVatAdjustmentEntity = 'swiss_vat_adjustments';
const String swissVatExportEntity = 'swiss_vat_exports';

const String _chVat = '/swiss-vat';

SwissVatException mapSwissVatError(DioException e) {
  final Response<dynamic>? r = e.response;
  if (r == null) {
    return const SwissVatException(SwissVatErrorKind.offline);
  }
  final dynamic body = r.data;
  String detail = '';
  if (body is Map) {
    final dynamic d = body['detail'] ?? body['message'] ?? body['title'];
    detail = d is String ? d : '';
  }
  return switch (r.statusCode) {
    403 => SwissVatException(SwissVatErrorKind.forbidden, detail: detail),
    404 => SwissVatException(SwissVatErrorKind.notFound, detail: detail),
    409 || 422 => SwissVatException(SwissVatErrorKind.invalid, detail: detail),
    _ => SwissVatException(SwissVatErrorKind.unknown, detail: detail),
  };
}

class SwissVatRepositoryImpl implements SwissVatRepository {
  SwissVatRepositoryImpl(this._db, this._dio, this._engine);

  final AppDatabase _db;
  final Dio _dio;
  final SyncEngine _engine;

  // --- Config & Tax Codes -----------------------------------------------------------------------------------------

  @override
  Future<SwissVatConfig?> cachedConfig(String tenantId) async {
    final EntityRecord? row = await _row(
      tenantId,
      swissVatConfigEntity,
      'current',
    );
    return row == null ? null : SwissVatConfig.fromJson(_decode(row.payload));
  }

  @override
  Future<SwissVatConfig> refreshConfig(String tenantId) async {
    final Response<dynamic> res = await _guard(
      () => _dio.get<dynamic>('$_chVat/config'),
    );
    final SwissVatConfig cfg = SwissVatConfig.fromJson(
      _unwrapDataMap(res.data),
    );
    await _put(tenantId, swissVatConfigEntity, 'current', cfg.toJson());
    return cfg;
  }

  @override
  Future<SwissVatActionOutcome> saveConfig(
    String tenantId,
    SwissVatConfig config,
  ) async {
    if (config.uidMwst != null &&
        config.uidMwst!.trim().isNotEmpty &&
        !SwissVatDomain.isValidUidMwst(config.uidMwst)) {
      return const SwissVatActionOutcome(
        SwissVatActionStatus.rejected,
        detail: 'invalid_uid_mwst',
      );
    }
    await _put(tenantId, swissVatConfigEntity, 'current', config.toJson());
    try {
      await _guard(
        () => _dio.put<dynamic>('$_chVat/config', data: config.toJson()),
      );
      return const SwissVatActionOutcome(SwissVatActionStatus.sent);
    } on SwissVatException catch (e) {
      if (e.kind == SwissVatErrorKind.offline) {
        await _queueOnce(
          tenantId,
          swissVatReturnReqEntity,
          '$_chVat/config',
          config.toJson(),
        );
        return const SwissVatActionOutcome(SwissVatActionStatus.queued);
      }
      return SwissVatActionOutcome(
        SwissVatActionStatus.rejected,
        detail: e.detail,
      );
    }
  }

  @override
  Future<List<SwissVatTaxCode>> cachedTaxCodes(String tenantId) async =>
      <SwissVatTaxCode>[
        for (final EntityRecord r in await _rows(
          tenantId,
          swissVatTaxCodeEntity,
        ))
          SwissVatTaxCode.fromJson(_decode(r.payload)),
      ];

  @override
  Future<List<SwissVatTaxCode>> refreshTaxCodes(String tenantId) async {
    final Response<dynamic> res = await _guard(
      () => _dio.get<dynamic>('$_chVat/tax-codes'),
    );
    final List<SwissVatTaxCode> codes = <SwissVatTaxCode>[
      for (final Map<String, dynamic> j in _list(res.data))
        SwissVatTaxCode.fromJson(j),
    ];
    await _replace(
      tenantId,
      swissVatTaxCodeEntity,
      <String, Map<String, dynamic>>{
        for (final SwissVatTaxCode c in codes) c.id: c.toJson(),
      },
    );
    return codes;
  }

  // --- Returns, AFC Reconciliation & SuisseTax XML ----------------------------------------------------------------

  @override
  Future<List<SwissVatReturn>> cachedReturns(String tenantId, int year) async =>
      _sortReturns(<SwissVatReturn>[
        for (final EntityRecord r in await _rows(
          tenantId,
          swissVatReturnEntity,
        ))
          if (SwissVatReturn.fromJson(_decode(r.payload)).fiscalYear == year)
            SwissVatReturn.fromJson(_decode(r.payload)),
      ]);

  @override
  Future<List<SwissVatReturn>> refreshReturns(String tenantId, int year) async {
    final Response<dynamic> res = await _guard(
      () => _dio.get<dynamic>(
        '$_chVat/returns',
        queryParameters: <String, dynamic>{'year': year},
      ),
    );
    final List<SwissVatReturn> list = <SwissVatReturn>[
      for (final Map<String, dynamic> j in _list(res.data))
        SwissVatReturn.fromJson(j),
    ];
    final Map<String, SwissVatReturn> existing = <String, SwissVatReturn>{
      for (final SwissVatReturn r in await cachedReturns(tenantId, year))
        r.id: r,
    };
    await _db.transaction(() async {
      for (final SwissVatReturn old in existing.values) {
        await _delete(tenantId, swissVatReturnEntity, old.id);
      }
      for (final SwissVatReturn r in list) {
        final SwissVatReturn? prev = existing[r.id];
        final SwissVatReturn merged =
            r.boxSchedule.isEmpty && prev != null && prev.boxSchedule.isNotEmpty
            ? r.withReconciliation(r.quadraturaReport, prev.boxSchedule)
            : r;
        await _put(tenantId, swissVatReturnEntity, merged.id, merged.toJson());
      }
    });
    return _sortReturns(list);
  }

  @override
  Future<SwissVatReturn> refreshReconciliation(
    String tenantId,
    String returnId,
  ) async {
    final Response<dynamic> res = await _guard(
      () => _dio.get<dynamic>('$_chVat/returns/$returnId/reconciliation'),
    );
    final Map<String, dynamic> data = _unwrapDataMap(res.data);
    final QuadraturaReport quad = data['quadratura_report'] is Map
        ? QuadraturaReport.fromJson(_map(data['quadratura_report']))
        : QuadraturaReport.empty;
    final List<AfcBoxLine> boxes = <AfcBoxLine>[
      for (final Map<String, dynamic> b in _maps(data['box_schedule']))
        AfcBoxLine.fromJson(b),
    ];

    final EntityRecord? cached = await _row(
      tenantId,
      swissVatReturnEntity,
      returnId,
    );
    final SwissVatReturn base = cached != null
        ? SwissVatReturn.fromJson(_decode(cached.payload))
        : (await () async {
            final Response<dynamic> retRes = await _guard(
              () => _dio.get<dynamic>('$_chVat/returns/$returnId'),
            );
            return SwissVatReturn.fromJson(_unwrapDataMap(retRes.data));
          }());

    final SwissVatReturn enriched = base.withReconciliation(quad, boxes);
    await _put(tenantId, swissVatReturnEntity, enriched.id, enriched.toJson());
    return enriched;
  }

  @override
  Future<SwissVatActionOutcome> calculateReturn(
    String tenantId, {
    required int fiscalYear,
    required SwissVatFrequency periodType,
    required int periodNumber,
  }) => _queueOnce(
    tenantId,
    swissVatReturnReqEntity,
    '$_chVat/returns/calculate',
    <String, dynamic>{
      'fiscal_year': fiscalYear,
      'period_type': periodType.wire,
      'period_number': periodNumber,
    },
  );

  @override
  Future<SuisseTaxValidationResult> validateXml(String returnId) async {
    final Response<dynamic> res = await _guard(
      () => _dio.post<dynamic>('$_chVat/returns/$returnId/validate'),
    );
    return SuisseTaxValidationResult.fromJson(_unwrapDataMap(res.data));
  }

  @override
  Future<SuisseTaxXmlExport> exportXml(String returnId) async {
    final Response<dynamic> res = await _guard(
      () => _dio.post<dynamic>('$_chVat/returns/$returnId/export-xml'),
    );
    return SuisseTaxXmlExport.fromJson(_unwrapDataMap(res.data));
  }

  @override
  Future<List<SuisseTaxXmlExport>> refreshExports(String returnId) async {
    final Response<dynamic> res = await _guard(
      () => _dio.get<dynamic>('$_chVat/returns/$returnId/exports'),
    );
    return <SuisseTaxXmlExport>[
      for (final Map<String, dynamic> j in _list(res.data))
        SuisseTaxXmlExport.fromJson(j),
    ];
  }

  @override
  Future<SwissVatFile> downloadExportXml(
    SuisseTaxXmlExport exportRecord,
  ) async {
    final Response<dynamic> res = await _guard(
      () => _dio.get<dynamic>(
        '$_chVat/exports/${exportRecord.id}/download',
        options: Options(responseType: ResponseType.bytes),
      ),
    );
    final dynamic body = res.data;
    final List<int> bytes = body is List<int> ? body : utf8.encode('$body');
    return SwissVatFile(
      fileName: exportRecord.fileName.isEmpty
          ? 'suissetax-${exportRecord.periodLabel}.xml'
          : exportRecord.fileName,
      bytes: bytes,
      mimeType: 'application/xml',
    );
  }

  // --- Bezugsteuer ------------------------------------------------------------------------------------------------

  @override
  Future<List<BezugsteuerEntry>> cachedBezugsteuer(String tenantId) async =>
      <BezugsteuerEntry>[
        for (final EntityRecord r in await _rows(
          tenantId,
          swissVatBezugsteuerEntity,
        ))
          BezugsteuerEntry.fromJson(_decode(r.payload)),
      ];

  @override
  Future<List<BezugsteuerEntry>> refreshBezugsteuer(String tenantId) async {
    final Response<dynamic> res = await _guard(
      () => _dio.get<dynamic>('$_chVat/bezugsteuer'),
    );
    final List<BezugsteuerEntry> fresh = <BezugsteuerEntry>[
      for (final Map<String, dynamic> j in _list(res.data))
        BezugsteuerEntry.fromJson(j),
    ];
    final Set<String> waiting = <String>{
      for (final QueueItem q in await _engine.queued(
        tenantId,
        swissVatBezugsteuerEntity,
      ))
        q.entityId,
    };
    final List<BezugsteuerEntry> keep = <BezugsteuerEntry>[
      for (final BezugsteuerEntry e in await cachedBezugsteuer(tenantId))
        if (e.pending && waiting.contains(e.id)) e,
    ];
    await _replace(
      tenantId,
      swissVatBezugsteuerEntity,
      <String, Map<String, dynamic>>{
        for (final BezugsteuerEntry e in <BezugsteuerEntry>[...fresh, ...keep])
          e.id: e.toJson(),
      },
    );
    return <BezugsteuerEntry>[...fresh, ...keep];
  }

  @override
  Future<SwissVatActionOutcome> createBezugsteuer(
    String tenantId,
    BezugsteuerDraft draft,
  ) async {
    if (draft.validate() != null) {
      return const SwissVatActionOutcome(SwissVatActionStatus.rejected);
    }
    final String entityId = await _engine.enqueueCommand(
      tenantId: tenantId,
      entity: swissVatBezugsteuerEntity,
      path: '$_chVat/bezugsteuer',
      data: draft.toJson(),
    );
    await _put(
      tenantId,
      swissVatBezugsteuerEntity,
      entityId,
      draft.toPlaceholder(entityId).toJson(),
    );
    return _afterSend(tenantId, swissVatBezugsteuerEntity, entityId);
  }

  @override
  Future<SwissVatActionOutcome> confirmBezugsteuer(
    String tenantId,
    String entryId,
  ) => _queueOnce(
    tenantId,
    swissVatBezugsteuerReqEntity,
    '$_chVat/bezugsteuer/$entryId/confirm',
    const <String, dynamic>{},
  );

  @override
  Future<SwissVatActionOutcome> excludeBezugsteuer(
    String tenantId,
    String entryId,
  ) => _queueOnce(
    tenantId,
    swissVatBezugsteuerReqEntity,
    '$_chVat/bezugsteuer/$entryId/exclude',
    const <String, dynamic>{},
  );

  // --- Input Tax Adjustments --------------------------------------------------------------------------------------

  @override
  Future<List<InputTaxAdjustment>> cachedAdjustments(
    String tenantId,
    int year,
  ) async => <InputTaxAdjustment>[
    for (final EntityRecord r in await _rows(
      tenantId,
      swissVatAdjustmentEntity,
    ))
      if (InputTaxAdjustment.fromJson(_decode(r.payload)).fiscalYear == year)
        InputTaxAdjustment.fromJson(_decode(r.payload)),
  ];

  @override
  Future<List<InputTaxAdjustment>> refreshAdjustments(
    String tenantId,
    int year,
  ) async {
    final Response<dynamic> res = await _guard(
      () => _dio.get<dynamic>(
        '$_chVat/adjustments',
        queryParameters: <String, dynamic>{'year': year},
      ),
    );
    final List<InputTaxAdjustment> fresh = <InputTaxAdjustment>[
      for (final Map<String, dynamic> j in _list(res.data))
        InputTaxAdjustment.fromJson(j),
    ];
    final Set<String> waiting = <String>{
      for (final QueueItem q in await _engine.queued(
        tenantId,
        swissVatAdjustmentEntity,
      ))
        q.entityId,
    };
    final List<InputTaxAdjustment> keep = <InputTaxAdjustment>[
      for (final InputTaxAdjustment a in await cachedAdjustments(tenantId, year))
        if (a.pending && waiting.contains(a.id)) a,
    ];
    await _replace(
      tenantId,
      swissVatAdjustmentEntity,
      <String, Map<String, dynamic>>{
        for (final InputTaxAdjustment a in <InputTaxAdjustment>[
          ...fresh,
          ...keep,
        ])
          a.id: a.toJson(),
      },
    );
    return <InputTaxAdjustment>[...fresh, ...keep];
  }

  @override
  Future<SwissVatActionOutcome> createAdjustment(
    String tenantId,
    InputTaxAdjustmentDraft draft,
  ) async {
    if (draft.validate() != null) {
      return const SwissVatActionOutcome(SwissVatActionStatus.rejected);
    }
    final String entityId = await _engine.enqueueCommand(
      tenantId: tenantId,
      entity: swissVatAdjustmentEntity,
      path: '$_chVat/adjustments',
      data: draft.toJson(),
    );
    await _put(
      tenantId,
      swissVatAdjustmentEntity,
      entityId,
      draft.toPlaceholder(entityId).toJson(),
    );
    return _afterSend(tenantId, swissVatAdjustmentEntity, entityId);
  }

  @override
  Future<SwissVatActionOutcome> approveAdjustment(
    String tenantId,
    String adjustmentId,
  ) => _queueOnce(
    tenantId,
    swissVatAdjustmentReqEntity,
    '$_chVat/adjustments/$adjustmentId/approve',
    const <String, dynamic>{},
  );

  // --- Outbox -----------------------------------------------------------------------------------------------------

  Future<SwissVatActionOutcome> _queueOnce(
    String tenantId,
    String entity,
    String path,
    Map<String, dynamic> data,
  ) async {
    final String wanted = jsonEncode(data);
    for (final QueueItem r in await _engine.queued(tenantId, entity)) {
      if (r.path == path && (r.payload ?? '{}') == wanted && !_refused(r)) {
        return const SwissVatActionOutcome(SwissVatActionStatus.queued);
      }
    }
    final String entityId = await _engine.enqueueCommand(
      tenantId: tenantId,
      entity: entity,
      path: path,
      data: data,
    );
    return _afterSend(tenantId, entity, entityId);
  }

  Future<SwissVatActionOutcome> _afterSend(
    String tenantId,
    String entity,
    String entityId,
  ) async {
    try {
      await _engine.flush(tenantId);
    } catch (_) {
      // Queued for next sync cycle.
    }
    for (final QueueItem r in await _engine.queued(tenantId, entity)) {
      if (r.entityId == entityId) {
        return _refused(r)
            ? SwissVatActionOutcome(
                SwissVatActionStatus.rejected,
                detail: r.lastError ?? '',
              )
            : const SwissVatActionOutcome(SwissVatActionStatus.queued);
      }
    }
    return const SwissVatActionOutcome(SwissVatActionStatus.sent);
  }

  static bool _refused(QueueItem item) =>
      item.state == QueueState.rejected || item.state == QueueState.conflict;

  @override
  Future<List<PendingSwissVatAction>> pendingActions(String tenantId) async {
    final List<PendingSwissVatAction> out = <PendingSwissVatAction>[];
    for (final String entity in <String>[
      swissVatBezugsteuerEntity,
      swissVatBezugsteuerReqEntity,
      swissVatAdjustmentEntity,
      swissVatAdjustmentReqEntity,
      swissVatReturnReqEntity,
    ]) {
      for (final QueueItem r in await _engine.queued(tenantId, entity)) {
        final SwissVatActionKind kind = _inferKind(entity, r.path);
        out.add(
          PendingSwissVatAction(
            queueUuid: r.uuid,
            kind: kind,
            rejected: _refused(r),
            targetLabel: _targetLabel(r),
            detail: r.lastError ?? '',
          ),
        );
      }
    }
    return out;
  }

  static SwissVatActionKind _inferKind(String entity, String path) {
    if (entity == swissVatBezugsteuerEntity) {
      return SwissVatActionKind.bezugsteuerCreate;
    }
    if (entity == swissVatBezugsteuerReqEntity) {
      return path.endsWith('/exclude')
          ? SwissVatActionKind.bezugsteuerExclude
          : SwissVatActionKind.bezugsteuerConfirm;
    }
    if (entity == swissVatAdjustmentEntity) {
      return SwissVatActionKind.adjustmentCreate;
    }
    if (entity == swissVatAdjustmentReqEntity) {
      return SwissVatActionKind.adjustmentApprove;
    }
    if (path.endsWith('/config')) {
      return SwissVatActionKind.configSave;
    }
    return SwissVatActionKind.returnCalculate;
  }

  static String _targetLabel(QueueItem r) {
    final Map<String, dynamic> p = r.payload == null || r.payload!.isEmpty
        ? <String, dynamic>{}
        : _decode(r.payload!);
    return '${p['supplier_name'] ?? p['description'] ?? p['fiscal_year'] ?? ''}';
  }

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

  // --- Helpers & Local Store --------------------------------------------------------------------------------------

  static List<SwissVatReturn> _sortReturns(List<SwissVatReturn> list) => list
    ..sort((SwissVatReturn a, SwissVatReturn b) {
      final int y = b.fiscalYear.compareTo(a.fiscalYear);
      return y != 0 ? y : b.periodNumber.compareTo(a.periodNumber);
    });

  static Map<String, dynamic> _unwrapDataMap(Object? raw) {
    final Map<String, dynamic> top = _map(raw);
    return top['data'] is Map ? _map(top['data']) : top;
  }

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

  static List<Map<String, dynamic>> _maps(Object? raw) => <Map<String, dynamic>>[
    if (raw is List)
      for (final dynamic i in raw)
        if (i is Map) Map<String, dynamic>.from(i),
  ];

  static Map<String, dynamic> _decode(String payload) =>
      Map<String, dynamic>.from(jsonDecode(payload) as Map<dynamic, dynamic>);

  static Map<String, dynamic> _map(Object? v) =>
      v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

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
    Map<String, dynamic> payload,
  ) async {
    final DateTime now = DateTime.now().toUtc();
    await _db
        .into(_db.entityRecords)
        .insertOnConflictUpdate(
          EntityRecordsCompanion.insert(
            entity: entity,
            id: id,
            tenantId: tenantId,
            payload: jsonEncode(payload),
            syncStatus: SyncStatus.synced,
            localUpdatedAt: now,
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<void> _delete(String tenantId, String entity, String id) {
    return (_db.delete(_db.entityRecords)..where(
          (EntityRecords t) =>
              t.tenantId.equals(tenantId) &
              t.entity.equals(entity) &
              t.id.equals(id),
        ))
        .go();
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
      throw mapSwissVatError(e);
    }
  }
}
