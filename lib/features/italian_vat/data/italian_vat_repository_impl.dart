import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_engine.dart';
import '../domain/italian_vat_models.dart';
import '../domain/italian_vat_repository.dart';

/// Offline-queue entities of the module. All three are in [SyncEngine.defaultTerminalEntities]: a 422/403 (invalid
/// protocol, missing right) parks the row as rejected instead of resending it forever. The letters are cached under the
/// same entity, so discarding a queued letter also removes its local placeholder.
const String vatLetterEntity = 'vat_intent_letters';
const String vatLipeRequestEntity = 'vat_lipe_requests';
const String vatCertificateRequestEntity = 'vat_cu_requests';

/// Entities of the cached reads in the generic entity store (no schema of their own, so no Drift migration).
const String vatRegisterEntity = 'vat_registers';
const String vatSettlementEntity = 'vat_settlements';
const String vatAnnualEntity = 'vat_annual';
const String vatCertificateEntity = 'vat_certificates';

const String _ledger = '/general-ledger';
const String _vat = '/vat';

/// Maps a transport error to an [ItalianVatException]; the RFC 7807 `detail` is kept.
ItalianVatException mapItalianVatError(DioException e) {
  final Response<dynamic>? r = e.response;
  if (r == null) {
    return const ItalianVatException(ItalianVatErrorKind.offline);
  }
  final dynamic body = r.data;
  String detail = '';
  if (body is Map) {
    final dynamic d = body['detail'] ?? body['message'] ?? body['title'];
    detail = d is String ? d : '';
  }
  return switch (r.statusCode) {
    403 => ItalianVatException(ItalianVatErrorKind.forbidden, detail: detail),
    404 => ItalianVatException(ItalianVatErrorKind.notFound, detail: detail),
    409 ||
    422 => ItalianVatException(ItalianVatErrorKind.invalid, detail: detail),
    _ => ItalianVatException(ItalianVatErrorKind.unknown, detail: detail),
  };
}

/// REST client plus offline copy of the Italian VAT workspace.
class ItalianVatRepositoryImpl implements ItalianVatRepository {
  ItalianVatRepositoryImpl(this._db, this._dio, this._engine);

  final AppDatabase _db;
  final Dio _dio;
  final SyncEngine _engine;

  // --- Registers ---------------------------------------------------------------------------------------------------

  static String _registerId(VatRegisterType type, DateTime from, DateTime to) =>
      '${type.wire}|${_day(from)}|${_day(to)}';

  @override
  Future<VatRegister?> cachedRegister(
    String tenantId,
    VatRegisterType type,
    DateTime from,
    DateTime to,
  ) async {
    final EntityRecord? r = await _row(
      tenantId,
      vatRegisterEntity,
      _registerId(type, from, to),
    );
    return r == null ? null : VatRegister.fromCache(_decode(r.payload));
  }

  @override
  Future<VatRegister> refreshRegister(
    String tenantId,
    VatRegisterType type,
    DateTime from,
    DateTime to,
  ) async {
    final Response<dynamic> res = await _guard(
      () => _dio.get<dynamic>(
        '$_ledger/vat-registers/${type.wire}',
        queryParameters: <String, dynamic>{'from': _day(from), 'to': _day(to)},
      ),
    );
    final VatRegister register = VatRegister.fromJson(
      _map(res.data),
      type: type,
      from: from,
      to: to,
      fetchedAt: DateTime.now().toUtc(),
    );
    await _put(
      tenantId,
      vatRegisterEntity,
      _registerId(type, from, to),
      register.toJson(),
    );
    return register;
  }

  @override
  Future<VatFile> downloadRegisterCsv(
    VatRegisterType type,
    DateTime from,
    DateTime to,
  ) => _download(
    '$_ledger/vat-registers/${type.wire}',
    query: <String, dynamic>{
      'from': _day(from),
      'to': _day(to),
      'format': 'csv',
    },
    fallbackName: 'vat-register-${type.wire}-${_day(from)}-${_day(to)}.csv',
    mimeType: 'text/csv',
  );

  // --- Letters of intent -------------------------------------------------------------------------------------------

  @override
  Future<List<IntentLetter>> cachedLetters(String tenantId) async =>
      _byValidity(<IntentLetter>[
        for (final EntityRecord r in await _rows(tenantId, vatLetterEntity))
          IntentLetter.fromJson(_decode(r.payload)),
      ]);

  @override
  Future<List<IntentLetter>> refreshLetters(String tenantId) async {
    final Response<dynamic> res = await _guard(
      () => _dio.get<dynamic>(
        '$_vat/intent-letters',
        queryParameters: <String, dynamic>{'per_page': 100},
      ),
    );
    final List<IntentLetter> fresh = <IntentLetter>[
      for (final Map<String, dynamic> j in _list(res.data))
        IntentLetter.fromJson(j),
    ];
    // Letters still waiting in the outbox stay visible until the server confirms them.
    final Set<String> waiting = <String>{
      for (final QueueItem q in await _engine.queued(tenantId, vatLetterEntity))
        q.entityId,
    };
    final List<IntentLetter> keep = <IntentLetter>[
      for (final IntentLetter l in await cachedLetters(tenantId))
        if (l.pending && waiting.contains(l.id)) l,
    ];
    await _replace(tenantId, vatLetterEntity, <String, Map<String, dynamic>>{
      for (final IntentLetter l in <IntentLetter>[...fresh, ...keep])
        l.id: l.toJson(),
    });
    return _byValidity(<IntentLetter>[...fresh, ...keep]);
  }

  @override
  Future<ActionOutcome> createLetter(
    String tenantId,
    IntentLetterDraft draft,
  ) async {
    if (draft.issue != null) {
      return const ActionOutcome(ActionStatus.rejected);
    }
    final String entityId = await _engine.enqueueCommand(
      tenantId: tenantId,
      entity: vatLetterEntity,
      path: '$_vat/intent-letters',
      data: draft.toJson(),
    );
    await _put(
      tenantId,
      vatLetterEntity,
      entityId,
      draft.toPlaceholder(entityId).toJson(),
    );
    return _afterSend(tenantId, vatLetterEntity, entityId);
  }

  static List<IntentLetter> _byValidity(List<IntentLetter> letters) =>
      letters..sort((IntentLetter a, IntentLetter b) {
        final DateTime? x = a.validTo;
        final DateTime? y = b.validTo;
        if (x != null && y != null && x != y) {
          return y.compareTo(x);
        }
        return a.customerName.compareTo(b.customerName);
      });

  // --- Periodic settlements and LIPE -------------------------------------------------------------------------------

  @override
  Future<List<LipeSettlement>> cachedSettlements(String tenantId) async =>
      _byPeriod(<LipeSettlement>[
        for (final EntityRecord r in await _rows(tenantId, vatSettlementEntity))
          LipeSettlement.fromJson(_decode(r.payload)),
      ]);

  @override
  Future<List<LipeSettlement>> refreshSettlements(String tenantId) async {
    final Response<dynamic> res = await _guard(
      () => _dio.get<dynamic>(
        '$_vat/settlements',
        queryParameters: <String, dynamic>{'per_page': 100},
      ),
    );
    final List<LipeSettlement> fresh = <LipeSettlement>[
      for (final Map<String, dynamic> j in _list(res.data))
        LipeSettlement.fromJson(j),
    ];
    // The list may omit the LIPE file and reconciliation blocks that a detail pull stored: keep those.
    final Map<String, LipeSettlement> old = <String, LipeSettlement>{
      for (final LipeSettlement s in await cachedSettlements(tenantId)) s.id: s,
    };
    final List<LipeSettlement> merged = <LipeSettlement>[
      for (final LipeSettlement s in fresh) _keepDetail(s, old[s.id]),
    ];
    await _replace(
      tenantId,
      vatSettlementEntity,
      <String, Map<String, dynamic>>{
        for (final LipeSettlement s in merged) s.id: s.toJson(),
      },
    );
    return _byPeriod(merged);
  }

  static LipeSettlement _keepDetail(LipeSettlement fresh, LipeSettlement? old) {
    if (old == null || fresh.file.generated || fresh.erarioBalance != null) {
      return fresh;
    }
    return LipeSettlement(
      id: fresh.id,
      year: fresh.year,
      period: fresh.period,
      periodType: fresh.periodType,
      output: fresh.output,
      input: fresh.input,
      previousDebit: fresh.previousDebit,
      previousCredit: fresh.previousCredit,
      interest: fresh.interest,
      payable: fresh.payable,
      status: fresh.status,
      periodFrom: fresh.periodFrom,
      periodTo: fresh.periodTo,
      paidAt: fresh.paidAt,
      currency: fresh.currency,
      file: old.file,
      erarioBalance: old.erarioBalance,
    );
  }

  @override
  Future<LipeSettlement> refreshSettlement(String tenantId, String id) async {
    final Response<dynamic> res = await _guard(
      () => _dio.get<dynamic>('$_vat/settlements/$id'),
    );
    final LipeSettlement s = LipeSettlement.fromJson(
      _map(_map(res.data)['data']),
    );
    await _put(tenantId, vatSettlementEntity, s.id, s.toJson());
    return s;
  }

  @override
  Future<VatFile> downloadLipeXml(LipeSettlement settlement) => _download(
    '$_vat/settlements/${settlement.id}/export-xml',
    fallbackName: 'lipe-${settlement.periodKey}.xml',
    mimeType: 'application/xml',
  );

  @override
  Future<VatFile> downloadSettlementPdf(LipeSettlement settlement) => _download(
    '$_vat/settlements/${settlement.id}/export-pdf',
    fallbackName: 'vat-settlement-${settlement.periodKey}.pdf',
    mimeType: 'application/pdf',
  );

  @override
  Future<ActionOutcome> requestLipe(String tenantId, String settlementId) =>
      _queueOnce(
        tenantId,
        vatLipeRequestEntity,
        '$_vat/settlements/$settlementId/lipe',
        const <String, dynamic>{},
      );

  static List<LipeSettlement> _byPeriod(List<LipeSettlement> list) =>
      list..sort((LipeSettlement a, LipeSettlement b) {
        final int y = b.year.compareTo(a.year);
        return y != 0 ? y : b.period.compareTo(a.period);
      });

  // --- Annual VAT --------------------------------------------------------------------------------------------------

  @override
  Future<AnnualVatSummary> cachedAnnual(String tenantId, int year) async {
    final EntityRecord? r = await _row(tenantId, vatAnnualEntity, '$year');
    return AnnualVatSummary.build(
      year,
      await cachedSettlements(tenantId),
      server: r == null ? null : _decode(r.payload),
    );
  }

  @override
  Future<AnnualVatSummary> refreshAnnual(String tenantId, int year) async {
    await refreshSettlements(tenantId);
    try {
      final Response<dynamic> res = await _guard(
        () => _dio.get<dynamic>('$_vat/annual-returns/$year'),
      );
      await _put(
        tenantId,
        vatAnnualEntity,
        '$year',
        _map(_map(res.data)['data']),
      );
    } on ItalianVatException catch (e) {
      // No annual summary yet on the server: the sum of the settlements stands in for it.
      if (e.kind != ItalianVatErrorKind.notFound) {
        rethrow;
      }
    }
    return cachedAnnual(tenantId, year);
  }

  // --- Certificazione Unica ----------------------------------------------------------------------------------------

  @override
  Future<List<WithholdingCertificate>> cachedCertificates(
    String tenantId,
    int year,
  ) async => _byName(<WithholdingCertificate>[
    for (final EntityRecord r in await _rows(tenantId, vatCertificateEntity))
      if (WithholdingCertificate.fromJson(_decode(r.payload)).year == year)
        WithholdingCertificate.fromJson(_decode(r.payload)),
  ]);

  @override
  Future<List<WithholdingCertificate>> refreshCertificates(
    String tenantId,
    int year,
  ) async {
    final Response<dynamic> res = await _guard(
      () => _dio.get<dynamic>(
        '$_ledger/withholding-certificates',
        queryParameters: <String, dynamic>{'year': year, 'per_page': 200},
      ),
    );
    final List<WithholdingCertificate> fresh = <WithholdingCertificate>[
      for (final Map<String, dynamic> j in _list(res.data))
        WithholdingCertificate.fromJson(j),
    ];
    await _db.transaction(() async {
      for (final WithholdingCertificate old in await cachedCertificates(
        tenantId,
        year,
      )) {
        await _delete(tenantId, vatCertificateEntity, old.id);
      }
      for (final WithholdingCertificate c in fresh) {
        await _put(tenantId, vatCertificateEntity, c.id, c.toJson());
      }
    });
    return _byName(fresh);
  }

  @override
  Future<VatFile> downloadCertificatePdf(WithholdingCertificate certificate) =>
      _download(
        '$_ledger/withholding-certificates/${certificate.id}/pdf',
        fallbackName:
            'cu-${certificate.year}-${_safe(certificate.recipientName)}.pdf',
        mimeType: 'application/pdf',
      );

  @override
  Future<VatFile> downloadTelematicFile(int year) => _download(
    '$_ledger/withholding-certificates/telematic-file',
    query: <String, dynamic>{'year': year},
    fallbackName: 'cu-$year.txt',
    mimeType: 'text/plain',
  );

  @override
  Future<ActionOutcome> requestCertificates(String tenantId, int year) =>
      _queueOnce(
        tenantId,
        vatCertificateRequestEntity,
        '$_ledger/withholding-certificates/generate',
        <String, dynamic>{'year': year},
      );

  static List<WithholdingCertificate> _byName(
    List<WithholdingCertificate> list,
  ) => list
    ..sort(
      (WithholdingCertificate a, WithholdingCertificate b) =>
          a.recipientName.compareTo(b.recipientName),
    );

  static String _safe(String name) =>
      name.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');

  // --- Outbox ------------------------------------------------------------------------------------------------------

  /// Queues a command unless an identical one is still waiting; sends right away when online.
  Future<ActionOutcome> _queueOnce(
    String tenantId,
    String entity,
    String path,
    Map<String, dynamic> data,
  ) async {
    final String wanted = jsonEncode(data);
    for (final QueueItem r in await _engine.queued(tenantId, entity)) {
      if (r.path == path && (r.payload ?? '{}') == wanted && !_refused(r)) {
        // Already waiting: a second tap must not queue a second request.
        return const ActionOutcome(ActionStatus.queued);
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

  Future<ActionOutcome> _afterSend(
    String tenantId,
    String entity,
    String entityId,
  ) async {
    try {
      await _engine.flush(tenantId);
    } catch (_) {
      // Whatever went wrong, the write is safely queued and the next sync cycle resends it.
    }
    for (final QueueItem r in await _engine.queued(tenantId, entity)) {
      if (r.entityId == entityId) {
        return _refused(r)
            ? ActionOutcome(ActionStatus.rejected, detail: r.lastError ?? '')
            : const ActionOutcome(ActionStatus.queued);
      }
    }
    return const ActionOutcome(ActionStatus.sent);
  }

  bool _refused(QueueItem item) =>
      item.state == QueueState.rejected || item.state == QueueState.conflict;

  @override
  Future<List<PendingVatAction>> pendingActions(String tenantId) async {
    final List<PendingVatAction> out = <PendingVatAction>[];
    for (final (String entity, VatActionKind kind) in <(String, VatActionKind)>[
      (vatLetterEntity, VatActionKind.intentLetter),
      (vatLipeRequestEntity, VatActionKind.lipeGeneration),
      (vatCertificateRequestEntity, VatActionKind.certificateGeneration),
    ]) {
      for (final QueueItem r in await _engine.queued(tenantId, entity)) {
        out.add(
          PendingVatAction(
            queueUuid: r.uuid,
            kind: kind,
            rejected: _refused(r),
            targetId: _target(kind, r),
            detail: r.lastError ?? '',
          ),
        );
      }
    }
    return out;
  }

  /// Settlement id of a LIPE request (`/vat/settlements/{id}/lipe`), year of a certificate request, customer of a letter.
  static String _target(VatActionKind kind, QueueItem r) {
    switch (kind) {
      case VatActionKind.lipeGeneration:
        final List<String> parts = r.path.split('/');
        final int at = parts.indexOf('settlements');
        return at >= 0 && at + 1 < parts.length ? parts[at + 1] : '';
      case VatActionKind.certificateGeneration:
        return '${_decodeOrEmpty(r.payload)['year'] ?? ''}';
      case VatActionKind.intentLetter:
        return '${_decodeOrEmpty(r.payload)['customer_name'] ?? ''}';
    }
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

  // --- Downloads ---------------------------------------------------------------------------------------------------

  Future<VatFile> _download(
    String path, {
    Map<String, dynamic>? query,
    required String fallbackName,
    required String mimeType,
  }) async {
    final Response<dynamic> res = await _guard(
      () => _dio.get<dynamic>(
        path,
        queryParameters: query,
        options: Options(responseType: ResponseType.bytes),
      ),
    );
    final dynamic body = res.data;
    final List<int> bytes = body is List<int> ? body : utf8.encode('$body');
    final String? header = res.headers.value('content-disposition');
    final String? named = header == null
        ? null
        : RegExp('filename="?([^";]+)"?').firstMatch(header)?.group(1);
    return VatFile(
      fileName: named == null || named.isEmpty ? fallbackName : named,
      bytes: bytes,
      mimeType: res.headers.value('content-type')?.split(';').first ?? mimeType,
    );
  }

  // --- Parsing -----------------------------------------------------------------------------------------------------

  static String _day(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

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

  static Map<String, dynamic> _decode(String payload) =>
      Map<String, dynamic>.from(jsonDecode(payload) as Map<dynamic, dynamic>);

  static Map<String, dynamic> _decodeOrEmpty(String? payload) =>
      payload == null || payload.isEmpty
      ? <String, dynamic>{}
      : _decode(payload);

  static Map<String, dynamic> _map(Object? v) =>
      v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

  // --- Local store -------------------------------------------------------------------------------------------------

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
      throw mapItalianVatError(e);
    }
  }
}
