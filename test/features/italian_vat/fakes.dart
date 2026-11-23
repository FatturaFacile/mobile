import 'dart:typed_data';

import 'package:fattura_facile/features/general_ledger/domain/gl_amount.dart';
import 'package:fattura_facile/features/italian_vat/domain/italian_vat_models.dart';
import 'package:fattura_facile/features/italian_vat/domain/italian_vat_repository.dart';
import 'package:fattura_facile/features/receivables/data/statement_exporter.dart';

/// In-memory [ItalianVatRepository] with scriptable outcomes: the `cache*` fields are the offline copy, the `remote*`
/// ones what a refresh brings, and [refreshError] makes every refresh fail like a dead network.
class FakeItalianVatRepository implements ItalianVatRepository {
  final Map<String, VatRegister> cachedRegisters = <String, VatRegister>{};
  final Map<String, VatRegister> remoteRegisters = <String, VatRegister>{};
  List<IntentLetter> cacheLetters = <IntentLetter>[];
  List<IntentLetter> remoteLetters = <IntentLetter>[];
  List<LipeSettlement> cacheSettlements = <LipeSettlement>[];
  List<LipeSettlement> remoteSettlements = <LipeSettlement>[];
  Map<String, dynamic>? serverAnnual;
  List<WithholdingCertificate> cacheCertificates = <WithholdingCertificate>[];
  List<WithholdingCertificate> remoteCertificates = <WithholdingCertificate>[];

  ItalianVatException? refreshError;
  ItalianVatException? downloadError;

  ActionStatus nextStatus = ActionStatus.sent;
  List<PendingVatAction> pending = <PendingVatAction>[];

  final List<IntentLetterDraft> drafts = <IntentLetterDraft>[];
  final List<String> lipeRequests = <String>[];
  final List<int> certificateRequests = <int>[];
  final List<String> downloads = <String>[];
  final List<String> retried = <String>[];
  final List<String> dismissed = <String>[];
  int flushes = 0;

  static String key(VatRegisterType t, DateTime from, DateTime to) =>
      '${t.wire}|${from.toIso8601String()}|${to.toIso8601String()}';

  void _failIfOffline() {
    final ItalianVatException? e = refreshError;
    if (e != null) {
      throw e;
    }
  }

  @override
  Future<VatRegister?> cachedRegister(
    String t,
    VatRegisterType type,
    DateTime from,
    DateTime to,
  ) async => cachedRegisters[key(type, from, to)];

  @override
  Future<VatRegister> refreshRegister(
    String t,
    VatRegisterType type,
    DateTime from,
    DateTime to,
  ) async {
    _failIfOffline();
    final VatRegister r =
        remoteRegisters[key(type, from, to)] ??
        VatRegister(
          type: type,
          from: from,
          to: to,
          lines: const <VatRegisterLine>[],
        );
    cachedRegisters[key(type, from, to)] = r;
    return r;
  }

  @override
  Future<VatFile> downloadRegisterCsv(
    VatRegisterType type,
    DateTime from,
    DateTime to,
  ) => _file('register-${type.wire}.csv', 'text/csv');

  Future<VatFile> _file(String name, String mime) async {
    final ItalianVatException? e = downloadError;
    if (e != null) {
      throw e;
    }
    downloads.add(name);
    return VatFile(fileName: name, bytes: <int>[1, 2, 3], mimeType: mime);
  }

  @override
  Future<List<IntentLetter>> cachedLetters(String t) async => cacheLetters;

  @override
  Future<List<IntentLetter>> refreshLetters(String t) async {
    _failIfOffline();
    cacheLetters = remoteLetters;
    return remoteLetters;
  }

  @override
  Future<ActionOutcome> createLetter(String t, IntentLetterDraft draft) async {
    drafts.add(draft);
    if (nextStatus != ActionStatus.sent) {
      cacheLetters = <IntentLetter>[
        ...cacheLetters,
        draft.toPlaceholder('tmp-${drafts.length}'),
      ];
    }
    return ActionOutcome(nextStatus);
  }

  @override
  Future<List<LipeSettlement>> cachedSettlements(String t) async =>
      cacheSettlements;

  @override
  Future<List<LipeSettlement>> refreshSettlements(String t) async {
    _failIfOffline();
    cacheSettlements = remoteSettlements;
    return remoteSettlements;
  }

  @override
  Future<LipeSettlement> refreshSettlement(String t, String id) async {
    _failIfOffline();
    final LipeSettlement s = remoteSettlements.firstWhere(
      (LipeSettlement x) => x.id == id,
    );
    cacheSettlements = <LipeSettlement>[
      for (final LipeSettlement x in cacheSettlements)
        if (x.id == id) s else x,
    ];
    return s;
  }

  @override
  Future<VatFile> downloadLipeXml(LipeSettlement s) =>
      _file('lipe-${s.periodKey}.xml', 'application/xml');

  @override
  Future<VatFile> downloadSettlementPdf(LipeSettlement s) =>
      _file('settlement-${s.periodKey}.pdf', 'application/pdf');

  @override
  Future<ActionOutcome> requestLipe(String t, String settlementId) async {
    lipeRequests.add(settlementId);
    return ActionOutcome(nextStatus);
  }

  @override
  Future<AnnualVatSummary> cachedAnnual(String t, int year) async =>
      AnnualVatSummary.build(year, cacheSettlements, server: serverAnnual);

  @override
  Future<AnnualVatSummary> refreshAnnual(String t, int year) async {
    _failIfOffline();
    cacheSettlements = remoteSettlements;
    return AnnualVatSummary.build(
      year,
      remoteSettlements,
      server: serverAnnual,
    );
  }

  @override
  Future<List<WithholdingCertificate>> cachedCertificates(
    String t,
    int year,
  ) async => <WithholdingCertificate>[
    for (final WithholdingCertificate c in cacheCertificates)
      if (c.year == year) c,
  ];

  @override
  Future<List<WithholdingCertificate>> refreshCertificates(
    String t,
    int year,
  ) async {
    _failIfOffline();
    cacheCertificates = remoteCertificates;
    return cachedCertificates(t, year);
  }

  @override
  Future<VatFile> downloadCertificatePdf(WithholdingCertificate c) =>
      _file('cu-${c.id}.pdf', 'application/pdf');

  @override
  Future<VatFile> downloadTelematicFile(int year) =>
      _file('cu-$year.txt', 'text/plain');

  @override
  Future<ActionOutcome> requestCertificates(String t, int year) async {
    certificateRequests.add(year);
    return ActionOutcome(nextStatus);
  }

  @override
  Future<List<PendingVatAction>> pendingActions(String t) async => pending;

  @override
  Future<void> retryAction(String t, String queueUuid) async {
    retried.add(queueUuid);
    pending = <PendingVatAction>[
      for (final PendingVatAction a in pending)
        if (a.queueUuid != queueUuid) a,
    ];
  }

  @override
  Future<void> dismissAction(String queueUuid) async {
    dismissed.add(queueUuid);
    pending = <PendingVatAction>[
      for (final PendingVatAction a in pending)
        if (a.queueUuid != queueUuid) a,
    ];
  }

  @override
  Future<int> flush(String t) async => ++flushes;
}

/// Records what is shared instead of opening the system share sheet.
class FakeExporter implements StatementExporter {
  final List<String> shared = <String>[];
  bool fail = false;

  @override
  Future<void> share({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    if (fail) {
      throw StateError('no share sheet');
    }
    shared.add('$fileName|$mimeType|${bytes.length}');
  }
}

/// Amount shorthand for assertions.
Amount4 amt(String v) => amountFromJson(v);
