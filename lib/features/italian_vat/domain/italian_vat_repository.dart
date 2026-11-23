import 'italian_vat_models.dart';

/// Data access of the Italian VAT workspace (Mod 029): every `cached*` read answers from the local SQLite copy without
/// the network, every `refresh*` asks the server and replaces that copy (and throws [ItalianVatException] on failure).
abstract interface class ItalianVatRepository {
  // --- Registers ---------------------------------------------------------------------------------------------------

  Future<VatRegister?> cachedRegister(
    String tenantId,
    VatRegisterType type,
    DateTime from,
    DateTime to,
  );

  Future<VatRegister> refreshRegister(
    String tenantId,
    VatRegisterType type,
    DateTime from,
    DateTime to,
  );

  /// The register as a CSV file for the system share sheet.
  Future<VatFile> downloadRegisterCsv(
    VatRegisterType type,
    DateTime from,
    DateTime to,
  );

  // --- Letters of intent -------------------------------------------------------------------------------------------

  Future<List<IntentLetter>> cachedLetters(String tenantId);

  Future<List<IntentLetter>> refreshLetters(String tenantId);

  /// Registers a received letter: stored locally at once (`pending`) and sent through the outbox.
  Future<ActionOutcome> createLetter(String tenantId, IntentLetterDraft draft);

  // --- Periodic settlements and LIPE -------------------------------------------------------------------------------

  Future<List<LipeSettlement>> cachedSettlements(String tenantId);

  Future<List<LipeSettlement>> refreshSettlements(String tenantId);

  /// One settlement with its LIPE file and Erario c/IVA reconciliation.
  Future<LipeSettlement> refreshSettlement(String tenantId, String id);

  Future<VatFile> downloadLipeXml(LipeSettlement settlement);

  Future<VatFile> downloadSettlementPdf(LipeSettlement settlement);

  /// Asks the server to generate, validate and sign the LIPE file of a settlement (outbox).
  Future<ActionOutcome> requestLipe(String tenantId, String settlementId);

  // --- Annual VAT --------------------------------------------------------------------------------------------------

  Future<AnnualVatSummary> cachedAnnual(String tenantId, int year);

  Future<AnnualVatSummary> refreshAnnual(String tenantId, int year);

  // --- Certificazione Unica ----------------------------------------------------------------------------------------

  Future<List<WithholdingCertificate>> cachedCertificates(
    String tenantId,
    int year,
  );

  Future<List<WithholdingCertificate>> refreshCertificates(
    String tenantId,
    int year,
  );

  Future<VatFile> downloadCertificatePdf(WithholdingCertificate certificate);

  /// The ministerial telematic file of the whole year.
  Future<VatFile> downloadTelematicFile(int year);

  /// Asks the server to (re)generate the certificates of a year (outbox).
  Future<ActionOutcome> requestCertificates(String tenantId, int year);

  // --- Outbox ------------------------------------------------------------------------------------------------------

  Future<List<PendingVatAction>> pendingActions(String tenantId);

  Future<void> retryAction(String tenantId, String queueUuid);

  Future<void> dismissAction(String queueUuid);

  /// Sends what is waiting in the outbox; returns how many writes the server accepted.
  Future<int> flush(String tenantId);
}
