import 'dart:typed_data';

import 'package:fattura_facile/features/receivables/data/statement_exporter.dart';
import 'package:fattura_facile/features/swiss_vat/domain/swiss_vat_models.dart';
import 'package:fattura_facile/features/swiss_vat/domain/swiss_vat_repository.dart';

class FakeSwissVatExporter implements StatementExporter {
  final List<({String fileName, Uint8List bytes, String mimeType})> shared =
      <({String fileName, Uint8List bytes, String mimeType})>[];

  @override
  Future<void> share({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    shared.add((fileName: fileName, bytes: bytes, mimeType: mimeType));
  }
}

class FakeSwissVatRepository implements SwissVatRepository {
  SwissVatConfig? cacheCfg;
  SwissVatConfig remoteCfg = const SwissVatConfig(
    id: 'cfg-1',
    uidMwst: 'CHE-116.281.710 MWST',
  );

  List<SwissVatTaxCode> cacheCodes = <SwissVatTaxCode>[];
  List<SwissVatTaxCode> remoteCodes = <SwissVatTaxCode>[];

  List<SwissVatReturn> cacheReturns = <SwissVatReturn>[];
  List<SwissVatReturn> remoteReturns = <SwissVatReturn>[];
  final Map<String, SwissVatReturn> detailedReturns =
      <String, SwissVatReturn>{};

  List<BezugsteuerEntry> cacheBez = <BezugsteuerEntry>[];
  List<BezugsteuerEntry> remoteBez = <BezugsteuerEntry>[];

  List<InputTaxAdjustment> cacheAdj = <InputTaxAdjustment>[];
  List<InputTaxAdjustment> remoteAdj = <InputTaxAdjustment>[];

  List<SuisseTaxXmlExport> exports = <SuisseTaxXmlExport>[];
  List<PendingSwissVatAction> pending = <PendingSwissVatAction>[];

  SwissVatException? refreshError;
  SwissVatException? exportError;
  SwissVatActionStatus nextStatus = SwissVatActionStatus.sent;
  SuisseTaxValidationResult nextValidation = const SuisseTaxValidationResult(
    valid: true,
    xsdValid: true,
    quadraturaPassed: true,
    schemaVersion: 'eCH-0217-v2.0',
    errors: <String>[],
  );

  final List<SwissVatConfig> savedConfigs = <SwissVatConfig>[];
  final List<BezugsteuerDraft> bezDrafts = <BezugsteuerDraft>[];
  final List<String> confirmedBez = <String>[];
  final List<String> excludedBez = <String>[];
  final List<InputTaxAdjustmentDraft> adjDrafts = <InputTaxAdjustmentDraft>[];
  final List<String> approvedAdj = <String>[];
  final List<String> calculatedPeriods = <String>[];

  void _failIfOffline() {
    if (refreshError != null) {
      throw refreshError!;
    }
  }

  @override
  Future<SwissVatConfig?> cachedConfig(String tenantId) async => cacheCfg;

  @override
  Future<SwissVatConfig> refreshConfig(String tenantId) async {
    _failIfOffline();
    cacheCfg = remoteCfg;
    return remoteCfg;
  }

  @override
  Future<SwissVatActionOutcome> saveConfig(
    String tenantId,
    SwissVatConfig config,
  ) async {
    savedConfigs.add(config);
    cacheCfg = config;
    return SwissVatActionOutcome(nextStatus);
  }

  @override
  Future<List<SwissVatTaxCode>> cachedTaxCodes(String tenantId) async =>
      cacheCodes;

  @override
  Future<List<SwissVatTaxCode>> refreshTaxCodes(String tenantId) async {
    _failIfOffline();
    cacheCodes = remoteCodes;
    return remoteCodes;
  }

  @override
  Future<List<SwissVatReturn>> cachedReturns(String tenantId, int year) async =>
      cacheReturns;

  @override
  Future<List<SwissVatReturn>> refreshReturns(
    String tenantId,
    int year,
  ) async {
    _failIfOffline();
    cacheReturns = remoteReturns;
    return remoteReturns;
  }

  @override
  Future<SwissVatReturn> refreshReconciliation(
    String tenantId,
    String returnId,
  ) async {
    _failIfOffline();
    return detailedReturns[returnId] ??
        remoteReturns.firstWhere((SwissVatReturn r) => r.id == returnId);
  }

  @override
  Future<SwissVatActionOutcome> calculateReturn(
    String tenantId, {
    required int fiscalYear,
    required SwissVatFrequency periodType,
    required int periodNumber,
  }) async {
    calculatedPeriods.add('$fiscalYear-${periodType.wire}-$periodNumber');
    return SwissVatActionOutcome(nextStatus);
  }

  @override
  Future<SuisseTaxValidationResult> validateXml(String returnId) async =>
      nextValidation;

  @override
  Future<SuisseTaxXmlExport> exportXml(String returnId) async {
    if (exportError != null) {
      throw exportError!;
    }
    const SuisseTaxXmlExport rec = SuisseTaxXmlExport(
      id: 'exp-1',
      returnId: 'ret-1',
      fileName: 'suissetax-2026-Q1.xml',
      sha256Checksum: 'abcd1234',
      xsdValid: true,
      quadraturaPassed: true,
      schemaVersion: 'eCH-0217-v2.0',
    );
    exports = <SuisseTaxXmlExport>[rec];
    return rec;
  }

  @override
  Future<List<SuisseTaxXmlExport>> refreshExports(String returnId) async =>
      exports;

  @override
  Future<SwissVatFile> downloadExportXml(
    SuisseTaxXmlExport exportRecord,
  ) async {
    if (exportError != null) {
      throw exportError!;
    }
    return SwissVatFile(
      fileName: exportRecord.fileName,
      bytes: '<vatDeclaration/>'.codeUnits,
      mimeType: 'application/xml',
    );
  }

  @override
  Future<List<BezugsteuerEntry>> cachedBezugsteuer(String tenantId) async =>
      cacheBez;

  @override
  Future<List<BezugsteuerEntry>> refreshBezugsteuer(String tenantId) async {
    _failIfOffline();
    cacheBez = remoteBez;
    return remoteBez;
  }

  @override
  Future<SwissVatActionOutcome> createBezugsteuer(
    String tenantId,
    BezugsteuerDraft draft,
  ) async {
    bezDrafts.add(draft);
    cacheBez = <BezugsteuerEntry>[...cacheBez, draft.toPlaceholder('tmp-bez')];
    return SwissVatActionOutcome(nextStatus);
  }

  @override
  Future<SwissVatActionOutcome> confirmBezugsteuer(
    String tenantId,
    String entryId,
  ) async {
    confirmedBez.add(entryId);
    return SwissVatActionOutcome(nextStatus);
  }

  @override
  Future<SwissVatActionOutcome> excludeBezugsteuer(
    String tenantId,
    String entryId,
  ) async {
    excludedBez.add(entryId);
    return SwissVatActionOutcome(nextStatus);
  }

  @override
  Future<List<InputTaxAdjustment>> cachedAdjustments(
    String tenantId,
    int year,
  ) async => cacheAdj;

  @override
  Future<List<InputTaxAdjustment>> refreshAdjustments(
    String tenantId,
    int year,
  ) async {
    _failIfOffline();
    cacheAdj = remoteAdj;
    return remoteAdj;
  }

  @override
  Future<SwissVatActionOutcome> createAdjustment(
    String tenantId,
    InputTaxAdjustmentDraft draft,
  ) async {
    adjDrafts.add(draft);
    cacheAdj = <InputTaxAdjustment>[
      ...cacheAdj,
      draft.toPlaceholder('tmp-adj'),
    ];
    return SwissVatActionOutcome(nextStatus);
  }

  @override
  Future<SwissVatActionOutcome> approveAdjustment(
    String tenantId,
    String adjustmentId,
  ) async {
    approvedAdj.add(adjustmentId);
    return SwissVatActionOutcome(nextStatus);
  }

  @override
  Future<List<PendingSwissVatAction>> pendingActions(String tenantId) async =>
      pending;

  @override
  Future<void> retryAction(String tenantId, String queueUuid) async {}

  @override
  Future<void> dismissAction(String queueUuid) async {}

  @override
  Future<int> flush(String tenantId) async => 0;
}
