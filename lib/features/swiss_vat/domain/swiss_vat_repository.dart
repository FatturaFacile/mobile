import 'swiss_vat_models.dart';

/// Repository contract for the Swiss VAT (MWST / IVA / TVA) Mod 024 feature.
/// Reads return cached offline SQLite snapshots via Drift `EntityRecords`; mutations enqueue to [SyncEngine].
abstract interface class SwissVatRepository {
  // --- Config & Tax Codes ---

  Future<SwissVatConfig?> cachedConfig(String tenantId);

  Future<SwissVatConfig> refreshConfig(String tenantId);

  Future<SwissVatActionOutcome> saveConfig(
    String tenantId,
    SwissVatConfig config,
  );

  Future<List<SwissVatTaxCode>> cachedTaxCodes(String tenantId);

  Future<List<SwissVatTaxCode>> refreshTaxCodes(String tenantId);

  // --- Returns, AFC Reconciliation & SuisseTax XML ---

  Future<List<SwissVatReturn>> cachedReturns(String tenantId, int year);

  Future<List<SwissVatReturn>> refreshReturns(String tenantId, int year);

  Future<SwissVatReturn> refreshReconciliation(String tenantId, String returnId);

  Future<SwissVatActionOutcome> calculateReturn(
    String tenantId, {
    required int fiscalYear,
    required SwissVatFrequency periodType,
    required int periodNumber,
  });

  Future<SuisseTaxValidationResult> validateXml(String returnId);

  Future<SuisseTaxXmlExport> exportXml(String returnId);

  Future<List<SuisseTaxXmlExport>> refreshExports(String returnId);

  Future<SwissVatFile> downloadExportXml(SuisseTaxXmlExport exportRecord);

  // --- Bezugsteuer ---

  Future<List<BezugsteuerEntry>> cachedBezugsteuer(String tenantId);

  Future<List<BezugsteuerEntry>> refreshBezugsteuer(String tenantId);

  Future<SwissVatActionOutcome> createBezugsteuer(
    String tenantId,
    BezugsteuerDraft draft,
  );

  Future<SwissVatActionOutcome> confirmBezugsteuer(
    String tenantId,
    String entryId,
  );

  Future<SwissVatActionOutcome> excludeBezugsteuer(
    String tenantId,
    String entryId,
  );

  // --- Input Tax Adjustments ---

  Future<List<InputTaxAdjustment>> cachedAdjustments(String tenantId, int year);

  Future<List<InputTaxAdjustment>> refreshAdjustments(
    String tenantId,
    int year,
  );

  Future<SwissVatActionOutcome> createAdjustment(
    String tenantId,
    InputTaxAdjustmentDraft draft,
  );

  Future<SwissVatActionOutcome> approveAdjustment(
    String tenantId,
    String adjustmentId,
  );

  // --- Outbox ---

  Future<List<PendingSwissVatAction>> pendingActions(String tenantId);

  Future<void> retryAction(String tenantId, String queueUuid);

  Future<void> dismissAction(String queueUuid);

  Future<int> flush(String tenantId);
}
