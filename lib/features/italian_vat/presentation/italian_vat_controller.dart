import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../app/session_controller.dart';
import '../../receivables/data/statement_exporter.dart';
import '../data/italian_vat_repository_impl.dart';
import '../domain/italian_vat_models.dart';
import '../domain/italian_vat_repository.dart';

final Provider<ItalianVatRepository> italianVatRepositoryProvider =
    Provider<ItalianVatRepository>(
      (Ref ref) => ItalianVatRepositoryImpl(
        ref.watch(databaseProvider),
        ref.watch(dioProvider),
        ref.watch(syncEngineProvider),
      ),
    );

/// Active tenant of the signed-in session (`null` when signed out). Tests override it.
final Provider<String?> italianVatTenantIdProvider = Provider<String?>((
  Ref ref,
) {
  final SessionState? s = ref.watch(sessionProvider).value;
  return s is SignedIn ? s.bootstrap.tenantId : null;
});

/// "Today" of the workspace, so the default period and the validity checks are testable.
final Provider<DateTime> italianVatNowProvider = Provider<DateTime>(
  (Ref ref) => DateTime.now(),
);

/// Hands a downloaded file to the system share sheet. Tests override it.
final Provider<StatementExporter> italianVatExporterProvider =
    Provider<StatementExporter>((Ref ref) => const PlatformStatementExporter());

/// Length of the register period shown.
enum RegisterPeriodKind { month, quarter, year }

/// First and last day of a register period.
abstract final class VatPeriods {
  /// [index] is the month (1-12) or the quarter (1-4); ignored for a whole year.
  static ({DateTime from, DateTime to}) range(
    RegisterPeriodKind kind,
    int year,
    int index,
  ) {
    switch (kind) {
      case RegisterPeriodKind.month:
        return (from: DateTime(year, index), to: DateTime(year, index + 1, 0));
      case RegisterPeriodKind.quarter:
        final int first = (index - 1) * 3 + 1;
        return (from: DateTime(year, first), to: DateTime(year, first + 3, 0));
      case RegisterPeriodKind.year:
        return (from: DateTime(year), to: DateTime(year, 12, 31));
    }
  }

  static int currentIndex(RegisterPeriodKind kind, DateTime now) =>
      switch (kind) {
        RegisterPeriodKind.month => now.month,
        RegisterPeriodKind.quarter => (now.month - 1) ~/ 3 + 1,
        RegisterPeriodKind.year => 1,
      };

  static int count(RegisterPeriodKind kind) => switch (kind) {
    RegisterPeriodKind.month => 12,
    RegisterPeriodKind.quarter => 4,
    RegisterPeriodKind.year => 1,
  };
}

/// What happened to a file the user asked to share.
class ExportResult {
  const ExportResult.shared(this.fileName) : error = null, failed = false;

  const ExportResult.failure({this.error}) : fileName = null, failed = true;

  final String? fileName;
  final ItalianVatException? error;
  final bool failed;
}

@immutable
class ItalianVatState {
  const ItalianVatState({
    required this.year,
    this.registerType = VatRegisterType.sales,
    this.periodKind = RegisterPeriodKind.quarter,
    this.periodIndex = 1,
    this.sectional,
    this.register,
    this.letters = const <IntentLetter>[],
    this.settlements = const <LipeSettlement>[],
    this.annual,
    this.certificates = const <WithholdingCertificate>[],
    this.pending = const <PendingVatAction>[],
    this.loading = false,
    this.fromCache = false,
    this.error,
  });

  /// Year of the register period and of the annual / CU tab.
  final int year;
  final VatRegisterType registerType;
  final RegisterPeriodKind periodKind;
  final int periodIndex;

  /// Sectional the register is filtered by (`null` shows them all).
  final String? sectional;
  final VatRegister? register;
  final List<IntentLetter> letters;
  final List<LipeSettlement> settlements;
  final AnnualVatSummary? annual;
  final List<WithholdingCertificate> certificates;
  final List<PendingVatAction> pending;
  final bool loading;

  /// The screen shows the offline copy because the last refresh failed for lack of network.
  final bool fromCache;
  final ItalianVatException? error;

  bool get forbidden => error?.kind == ItalianVatErrorKind.forbidden;

  ({DateTime from, DateTime to}) get range =>
      VatPeriods.range(periodKind, year, periodIndex);

  CertificateTotals get certificateTotals => CertificateTotals.of(certificates);

  List<PendingVatAction> pendingOf(VatActionKind kind) => <PendingVatAction>[
    for (final PendingVatAction a in pending)
      if (a.kind == kind) a,
  ];

  ItalianVatState copyWith({
    int? year,
    VatRegisterType? registerType,
    RegisterPeriodKind? periodKind,
    int? periodIndex,
    Object? sectional = _keep,
    Object? register = _keep,
    List<IntentLetter>? letters,
    List<LipeSettlement>? settlements,
    Object? annual = _keep,
    List<WithholdingCertificate>? certificates,
    List<PendingVatAction>? pending,
    bool? loading,
    bool? fromCache,
    Object? error = _keep,
  }) => ItalianVatState(
    year: year ?? this.year,
    registerType: registerType ?? this.registerType,
    periodKind: periodKind ?? this.periodKind,
    periodIndex: periodIndex ?? this.periodIndex,
    sectional: identical(sectional, _keep)
        ? this.sectional
        : sectional as String?,
    register: identical(register, _keep)
        ? this.register
        : register as VatRegister?,
    letters: letters ?? this.letters,
    settlements: settlements ?? this.settlements,
    annual: identical(annual, _keep)
        ? this.annual
        : annual as AnnualVatSummary?,
    certificates: certificates ?? this.certificates,
    pending: pending ?? this.pending,
    loading: loading ?? this.loading,
    fromCache: fromCache ?? this.fromCache,
    error: identical(error, _keep) ? this.error : error as ItalianVatException?,
  );
}

const Object _keep = Object();

/// State of the whole workspace: reads the cached copy first (so everything works offline), then refreshes each part
/// from the server independently, so one failing part never hides the others.
class ItalianVatController extends Notifier<ItalianVatState> {
  String? _tenantId;

  ItalianVatRepository get _repo => ref.read(italianVatRepositoryProvider);

  @override
  ItalianVatState build() {
    _tenantId = ref.watch(italianVatTenantIdProvider);
    final DateTime now = ref.read(italianVatNowProvider);
    return ItalianVatState(
      year: now.year,
      periodIndex: VatPeriods.currentIndex(RegisterPeriodKind.quarter, now),
    );
  }

  /// Offline copy first, then the server.
  Future<void> load() async {
    final String? tenant = _tenantId;
    if (tenant == null) {
      return;
    }
    state = state.copyWith(loading: true, error: null);
    await _showCached(tenant);
    ItalianVatException? failure;
    for (final Future<void> Function() step in <Future<void> Function()>[
      () => _refreshRegister(tenant),
      () async =>
          state = state.copyWith(letters: await _repo.refreshLetters(tenant)),
      () async => state = state.copyWith(
        settlements: await _repo.refreshSettlements(tenant),
      ),
      () async => state = state.copyWith(
        annual: await _repo.refreshAnnual(tenant, state.year),
      ),
      () async => state = state.copyWith(
        certificates: await _repo.refreshCertificates(tenant, state.year),
      ),
    ]) {
      try {
        await step();
      } on ItalianVatException catch (e) {
        failure ??= e;
        if (e.kind == ItalianVatErrorKind.offline) {
          break;
        }
      }
    }
    final List<PendingVatAction> pending = await _repo.pendingActions(tenant);
    state = state.copyWith(
      loading: false,
      pending: pending,
      fromCache: failure?.kind == ItalianVatErrorKind.offline,
      error: failure,
    );
  }

  Future<void> _showCached(String tenant) async {
    final ({DateTime from, DateTime to}) r = state.range;
    state = state.copyWith(
      register: await _repo.cachedRegister(
        tenant,
        state.registerType,
        r.from,
        r.to,
      ),
      letters: await _repo.cachedLetters(tenant),
      settlements: await _repo.cachedSettlements(tenant),
      annual: await _repo.cachedAnnual(tenant, state.year),
      certificates: await _repo.cachedCertificates(tenant, state.year),
      pending: await _repo.pendingActions(tenant),
    );
  }

  Future<void> _refreshRegister(String tenant) async {
    final ({DateTime from, DateTime to}) r = state.range;
    final VatRegister fresh = await _repo.refreshRegister(
      tenant,
      state.registerType,
      r.from,
      r.to,
    );
    // A newer selection may have been made while the answer was on its way.
    if (fresh.type == state.registerType &&
        fresh.from == r.from &&
        fresh.to == r.to) {
      state = state.copyWith(register: fresh);
    }
  }

  // --- Registers ---------------------------------------------------------------------------------------------------

  Future<void> selectRegister(VatRegisterType type) async {
    state = state.copyWith(registerType: type, sectional: null);
    await reloadRegister();
  }

  Future<void> selectPeriod(RegisterPeriodKind kind, int index) async {
    final int bounded = index.clamp(1, VatPeriods.count(kind));
    state = state.copyWith(
      periodKind: kind,
      periodIndex: bounded,
      sectional: null,
    );
    await reloadRegister();
  }

  /// Changes the year of the register period, the annual summary and the certificates.
  Future<void> selectYear(int year) async {
    state = state.copyWith(year: year, sectional: null);
    final String? tenant = _tenantId;
    if (tenant != null) {
      state = state.copyWith(
        annual: await _repo.cachedAnnual(tenant, year),
        certificates: await _repo.cachedCertificates(tenant, year),
      );
    }
    await reloadRegister();
    await refreshAnnual();
  }

  void selectSectional(String? code) => state = state.copyWith(sectional: code);

  /// Shows the cached register of the selection, then refreshes it.
  Future<void> reloadRegister() async {
    final String? tenant = _tenantId;
    if (tenant == null) {
      return;
    }
    final ({DateTime from, DateTime to}) r = state.range;
    state = state.copyWith(
      register: await _repo.cachedRegister(
        tenant,
        state.registerType,
        r.from,
        r.to,
      ),
      loading: true,
      error: null,
    );
    try {
      await _refreshRegister(tenant);
      state = state.copyWith(loading: false, fromCache: false);
    } on ItalianVatException catch (e) {
      state = state.copyWith(
        loading: false,
        fromCache: e.kind == ItalianVatErrorKind.offline,
        error: e,
      );
    }
  }

  /// Refreshes the annual summary and the certificates of the selected year.
  Future<void> refreshAnnual() async {
    final String? tenant = _tenantId;
    if (tenant == null) {
      return;
    }
    try {
      final AnnualVatSummary annual = await _repo.refreshAnnual(
        tenant,
        state.year,
      );
      final List<WithholdingCertificate> certs = await _repo
          .refreshCertificates(tenant, state.year);
      state = state.copyWith(
        annual: annual,
        certificates: certs,
        settlements: await _repo.cachedSettlements(tenant),
        fromCache: false,
        error: null,
      );
    } on ItalianVatException catch (e) {
      state = state.copyWith(
        fromCache: e.kind == ItalianVatErrorKind.offline,
        error: e,
      );
    }
  }

  // --- Letters of intent -------------------------------------------------------------------------------------------

  Future<ActionOutcome> createLetter(IntentLetterDraft draft) async {
    final String? tenant = _tenantId;
    if (tenant == null) {
      return const ActionOutcome(ActionStatus.rejected);
    }
    final ActionOutcome outcome = await _repo.createLetter(tenant, draft);
    state = state.copyWith(
      letters: await _repo.cachedLetters(tenant),
      pending: await _repo.pendingActions(tenant),
    );
    return outcome;
  }

  // --- LIPE --------------------------------------------------------------------------------------------------------

  /// Pulls the detail of a settlement (LIPE file status, Erario c/IVA reconciliation).
  Future<void> openSettlement(String id) async {
    final String? tenant = _tenantId;
    if (tenant == null) {
      return;
    }
    try {
      await _repo.refreshSettlement(tenant, id);
      state = state.copyWith(
        settlements: await _repo.cachedSettlements(tenant),
        error: null,
      );
    } on ItalianVatException catch (e) {
      state = state.copyWith(
        error: e.kind == ItalianVatErrorKind.offline ? null : e,
        fromCache: e.kind == ItalianVatErrorKind.offline,
      );
    }
  }

  Future<ActionOutcome> requestLipe(String settlementId) async {
    final String? tenant = _tenantId;
    if (tenant == null) {
      return const ActionOutcome(ActionStatus.rejected);
    }
    final ActionOutcome outcome = await _repo.requestLipe(tenant, settlementId);
    await _afterWrite(tenant, refreshSettlementId: settlementId);
    return outcome;
  }

  // --- Certificazione Unica ----------------------------------------------------------------------------------------

  Future<ActionOutcome> requestCertificates() async {
    final String? tenant = _tenantId;
    if (tenant == null) {
      return const ActionOutcome(ActionStatus.rejected);
    }
    final ActionOutcome outcome = await _repo.requestCertificates(
      tenant,
      state.year,
    );
    await _afterWrite(tenant);
    if (outcome.status == ActionStatus.sent) {
      await refreshAnnual();
    }
    return outcome;
  }

  Future<void> _afterWrite(String tenant, {String? refreshSettlementId}) async {
    state = state.copyWith(pending: await _repo.pendingActions(tenant));
    if (refreshSettlementId != null &&
        state.pending.every(
          (PendingVatAction a) => a.targetId != refreshSettlementId,
        )) {
      await openSettlement(refreshSettlementId);
    }
  }

  // --- Outbox ------------------------------------------------------------------------------------------------------

  Future<void> retry(String queueUuid) async {
    final String? tenant = _tenantId;
    if (tenant == null) {
      return;
    }
    await _repo.retryAction(tenant, queueUuid);
    state = state.copyWith(
      pending: await _repo.pendingActions(tenant),
      letters: await _repo.cachedLetters(tenant),
    );
  }

  Future<void> dismiss(String queueUuid) async {
    final String? tenant = _tenantId;
    if (tenant == null) {
      return;
    }
    await _repo.dismissAction(queueUuid);
    state = state.copyWith(
      pending: await _repo.pendingActions(tenant),
      letters: await _repo.cachedLetters(tenant),
    );
  }

  // --- Files -------------------------------------------------------------------------------------------------------

  Future<ExportResult> exportRegisterCsv() {
    final ({DateTime from, DateTime to}) r = state.range;
    return _share(
      () => _repo.downloadRegisterCsv(state.registerType, r.from, r.to),
    );
  }

  Future<ExportResult> shareLipeXml(LipeSettlement s) =>
      _share(() => _repo.downloadLipeXml(s));

  Future<ExportResult> shareSettlementPdf(LipeSettlement s) =>
      _share(() => _repo.downloadSettlementPdf(s));

  Future<ExportResult> shareCertificatePdf(WithholdingCertificate c) =>
      _share(() => _repo.downloadCertificatePdf(c));

  Future<ExportResult> shareTelematicFile() =>
      _share(() => _repo.downloadTelematicFile(state.year));

  Future<ExportResult> _share(Future<VatFile> Function() download) async {
    try {
      final VatFile file = await download();
      await ref
          .read(italianVatExporterProvider)
          .share(
            fileName: file.fileName,
            bytes: Uint8List.fromList(file.bytes),
            mimeType: file.mimeType,
          );
      return ExportResult.shared(file.fileName);
    } on ItalianVatException catch (e) {
      return ExportResult.failure(error: e);
    } catch (_) {
      // The share sheet or the file system refused: nothing the server can fix.
      return const ExportResult.failure();
    }
  }
}

final NotifierProvider<ItalianVatController, ItalianVatState>
italianVatProvider = NotifierProvider<ItalianVatController, ItalianVatState>(
  ItalianVatController.new,
);
