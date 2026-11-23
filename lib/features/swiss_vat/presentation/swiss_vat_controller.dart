import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../app/session_controller.dart';
import '../../receivables/data/statement_exporter.dart';
import '../data/swiss_vat_repository_impl.dart';
import '../domain/swiss_vat_models.dart';
import '../domain/swiss_vat_repository.dart';

final Provider<SwissVatRepository> swissVatRepositoryProvider =
    Provider<SwissVatRepository>(
      (Ref ref) => SwissVatRepositoryImpl(
        ref.watch(databaseProvider),
        ref.watch(dioProvider),
        ref.watch(syncEngineProvider),
      ),
    );

final Provider<String?> swissVatTenantIdProvider = Provider<String?>((Ref ref) {
  final SessionState? s = ref.watch(sessionProvider).value;
  return s is SignedIn ? s.bootstrap.tenantId : null;
});

final Provider<DateTime> swissVatNowProvider = Provider<DateTime>(
  (Ref ref) => DateTime.now(),
);

final Provider<StatementExporter> swissVatExporterProvider =
    Provider<StatementExporter>(
      (Ref ref) => const PlatformStatementExporter(),
    );

class SwissVatXmlShareResult {
  const SwissVatXmlShareResult.shared(this.fileName)
    : error = null,
      failed = false;

  const SwissVatXmlShareResult.failure({this.error})
    : fileName = null,
      failed = true;

  final String? fileName;
  final SwissVatException? error;
  final bool failed;
}

@immutable
class SwissVatState {
  const SwissVatState({
    required this.year,
    this.periodNumber = 1,
    this.config,
    this.taxCodes = const <SwissVatTaxCode>[],
    this.returns = const <SwissVatReturn>[],
    this.selectedReturnId,
    this.exports = const <SuisseTaxXmlExport>[],
    this.validationResult,
    this.bezugsteuer = const <BezugsteuerEntry>[],
    this.adjustments = const <InputTaxAdjustment>[],
    this.pending = const <PendingSwissVatAction>[],
    this.loading = false,
    this.fromCache = false,
    this.error,
  });

  final int year;
  final int periodNumber;
  final SwissVatConfig? config;
  final List<SwissVatTaxCode> taxCodes;
  final List<SwissVatReturn> returns;
  final String? selectedReturnId;
  final List<SuisseTaxXmlExport> exports;
  final SuisseTaxValidationResult? validationResult;
  final List<BezugsteuerEntry> bezugsteuer;
  final List<InputTaxAdjustment> adjustments;
  final List<PendingSwissVatAction> pending;
  final bool loading;
  final bool fromCache;
  final SwissVatException? error;

  bool get forbidden => error?.kind == SwissVatErrorKind.forbidden;

  SwissVatReturn? get selectedReturn {
    if (returns.isEmpty) {
      return null;
    }
    if (selectedReturnId != null) {
      for (final SwissVatReturn r in returns) {
        if (r.id == selectedReturnId) {
          return r;
        }
      }
    }
    return returns.first;
  }

  SwissVatState copyWith({
    int? year,
    int? periodNumber,
    Object? config = _keep,
    List<SwissVatTaxCode>? taxCodes,
    List<SwissVatReturn>? returns,
    Object? selectedReturnId = _keep,
    List<SuisseTaxXmlExport>? exports,
    Object? validationResult = _keep,
    List<BezugsteuerEntry>? bezugsteuer,
    List<InputTaxAdjustment>? adjustments,
    List<PendingSwissVatAction>? pending,
    bool? loading,
    bool? fromCache,
    Object? error = _keep,
  }) => SwissVatState(
    year: year ?? this.year,
    periodNumber: periodNumber ?? this.periodNumber,
    config: identical(config, _keep) ? this.config : config as SwissVatConfig?,
    taxCodes: taxCodes ?? this.taxCodes,
    returns: returns ?? this.returns,
    selectedReturnId: identical(selectedReturnId, _keep)
        ? this.selectedReturnId
        : selectedReturnId as String?,
    exports: exports ?? this.exports,
    validationResult: identical(validationResult, _keep)
        ? this.validationResult
        : validationResult as SuisseTaxValidationResult?,
    bezugsteuer: bezugsteuer ?? this.bezugsteuer,
    adjustments: adjustments ?? this.adjustments,
    pending: pending ?? this.pending,
    loading: loading ?? this.loading,
    fromCache: fromCache ?? this.fromCache,
    error: identical(error, _keep) ? this.error : error as SwissVatException?,
  );
}

const Object _keep = Object();

class SwissVatController extends Notifier<SwissVatState> {
  String? _tenantId;

  SwissVatRepository get _repo => ref.read(swissVatRepositoryProvider);
  StatementExporter get _exporter => ref.read(swissVatExporterProvider);

  @override
  SwissVatState build() {
    _tenantId = ref.watch(swissVatTenantIdProvider);
    final DateTime now = ref.watch(swissVatNowProvider);
    return SwissVatState(
      year: now.year,
      periodNumber: ((now.month - 1) ~/ 3) + 1,
    );
  }

  Future<void> load() async {
    final String? t = _tenantId;
    if (t == null) {
      return;
    }
    state = state.copyWith(loading: true, error: null);
    await _readCache(t);
    await _refreshAll(t);
  }

  Future<void> _readCache(String tenantId) async {
    final SwissVatConfig? cfg = await _repo.cachedConfig(tenantId);
    final List<SwissVatTaxCode> codes = await _repo.cachedTaxCodes(tenantId);
    final List<SwissVatReturn> rets = await _repo.cachedReturns(
      tenantId,
      state.year,
    );
    final List<BezugsteuerEntry> bez = await _repo.cachedBezugsteuer(tenantId);
    final List<InputTaxAdjustment> adj = await _repo.cachedAdjustments(
      tenantId,
      state.year,
    );
    final List<PendingSwissVatAction> pend = await _repo.pendingActions(
      tenantId,
    );
    state = state.copyWith(
      config: cfg,
      taxCodes: codes,
      returns: rets,
      selectedReturnId: rets.isNotEmpty ? rets.first.id : null,
      bezugsteuer: bez,
      adjustments: adj,
      pending: pend,
    );
  }

  Future<void> _refreshAll(String tenantId) async {
    bool offline = false;
    SwissVatException? firstErr;
    Future<void> run(Future<void> Function() op) async {
      try {
        await op();
      } on SwissVatException catch (e) {
        if (e.kind == SwissVatErrorKind.offline) {
          offline = true;
        }
        firstErr ??= e;
      }
    }

    await run(() async {
      final SwissVatConfig cfg = await _repo.refreshConfig(tenantId);
      state = state.copyWith(config: cfg);
    });
    await run(() async {
      final List<SwissVatTaxCode> codes = await _repo.refreshTaxCodes(tenantId);
      state = state.copyWith(taxCodes: codes);
    });
    await run(() async {
      final List<SwissVatReturn> rets = await _repo.refreshReturns(
        tenantId,
        state.year,
      );
      state = state.copyWith(
        returns: rets,
        selectedReturnId: rets.isNotEmpty ? rets.first.id : null,
      );
    });
    await run(() async {
      final List<BezugsteuerEntry> bez = await _repo.refreshBezugsteuer(
        tenantId,
      );
      state = state.copyWith(bezugsteuer: bez);
    });
    await run(() async {
      final List<InputTaxAdjustment> adj = await _repo.refreshAdjustments(
        tenantId,
        state.year,
      );
      state = state.copyWith(adjustments: adj);
    });

    final SwissVatReturn? sel = state.selectedReturn;
    if (sel != null) {
      await run(() async {
        final SwissVatReturn detailed = await _repo.refreshReconciliation(
          tenantId,
          sel.id,
        );
        final List<SuisseTaxXmlExport> ex = await _repo.refreshExports(sel.id);
        state = state.copyWith(
          returns: <SwissVatReturn>[
            for (final SwissVatReturn r in state.returns)
              r.id == detailed.id ? detailed : r,
          ],
          exports: ex,
        );
      });
    }

    final List<PendingSwissVatAction> pend = await _repo.pendingActions(
      tenantId,
    );
    state = state.copyWith(
      loading: false,
      fromCache: offline,
      error: offline ? null : firstErr,
      pending: pend,
    );
  }

  Future<void> setYear(int year) async {
    state = state.copyWith(year: year);
    await load();
  }

  void setPeriodNumber(int period) {
    state = state.copyWith(periodNumber: period);
  }

  Future<void> selectReturn(String id) async {
    final String? t = _tenantId;
    state = state.copyWith(selectedReturnId: id, validationResult: null);
    if (t == null) {
      return;
    }
    try {
      final SwissVatReturn detailed = await _repo.refreshReconciliation(t, id);
      final List<SuisseTaxXmlExport> ex = await _repo.refreshExports(id);
      state = state.copyWith(
        returns: <SwissVatReturn>[
          for (final SwissVatReturn r in state.returns)
            r.id == detailed.id ? detailed : r,
        ],
        exports: ex,
      );
    } on SwissVatException catch (e) {
      state = state.copyWith(
        fromCache: e.kind == SwissVatErrorKind.offline,
        error: e.kind == SwissVatErrorKind.offline ? null : e,
      );
    }
  }

  Future<SwissVatActionOutcome> calculateCurrentPeriod() async {
    final String? t = _tenantId;
    if (t == null) {
      return const SwissVatActionOutcome(SwissVatActionStatus.rejected);
    }
    final SwissVatFrequency freq =
        state.config?.reportingFrequency ?? SwissVatFrequency.quarterly;
    final SwissVatActionOutcome out = await _repo.calculateReturn(
      t,
      fiscalYear: state.year,
      periodType: freq,
      periodNumber: state.periodNumber,
    );
    if (out.status == SwissVatActionStatus.sent) {
      await _refreshAll(t);
    } else {
      state = state.copyWith(pending: await _repo.pendingActions(t));
    }
    return out;
  }

  Future<SuisseTaxValidationResult?> validateSelectedXml() async {
    final SwissVatReturn? sel = state.selectedReturn;
    if (sel == null) {
      return null;
    }
    try {
      final SuisseTaxValidationResult res = await _repo.validateXml(sel.id);
      state = state.copyWith(validationResult: res);
      return res;
    } on SwissVatException catch (e) {
      state = state.copyWith(error: e);
      return null;
    }
  }

  Future<SwissVatXmlShareResult> exportAndShareXml() async {
    final SwissVatReturn? sel = state.selectedReturn;
    if (sel == null) {
      return const SwissVatXmlShareResult.failure();
    }
    try {
      final SuisseTaxXmlExport record = await _repo.exportXml(sel.id);
      final SwissVatFile file = await _repo.downloadExportXml(record);
      await _exporter.share(
        fileName: file.fileName,
        bytes: Uint8List.fromList(file.bytes),
        mimeType: file.mimeType,
      );
      final List<SuisseTaxXmlExport> ex = await _repo.refreshExports(sel.id);
      state = state.copyWith(exports: ex);
      return SwissVatXmlShareResult.shared(file.fileName);
    } on SwissVatException catch (e) {
      return SwissVatXmlShareResult.failure(error: e);
    }
  }

  Future<SwissVatActionOutcome> createBezugsteuer(BezugsteuerDraft draft) async {
    final String? t = _tenantId;
    if (t == null) {
      return const SwissVatActionOutcome(SwissVatActionStatus.rejected);
    }
    final SwissVatActionOutcome out = await _repo.createBezugsteuer(t, draft);
    state = state.copyWith(
      bezugsteuer: await _repo.cachedBezugsteuer(t),
      pending: await _repo.pendingActions(t),
    );
    if (out.status == SwissVatActionStatus.sent) {
      await _refreshAll(t);
    }
    return out;
  }

  Future<SwissVatActionOutcome> confirmBezugsteuer(String entryId) async {
    final String? t = _tenantId;
    if (t == null) {
      return const SwissVatActionOutcome(SwissVatActionStatus.rejected);
    }
    final SwissVatActionOutcome out = await _repo.confirmBezugsteuer(
      t,
      entryId,
    );
    state = state.copyWith(pending: await _repo.pendingActions(t));
    if (out.status == SwissVatActionStatus.sent) {
      await _refreshAll(t);
    }
    return out;
  }

  Future<SwissVatActionOutcome> excludeBezugsteuer(String entryId) async {
    final String? t = _tenantId;
    if (t == null) {
      return const SwissVatActionOutcome(SwissVatActionStatus.rejected);
    }
    final SwissVatActionOutcome out = await _repo.excludeBezugsteuer(
      t,
      entryId,
    );
    state = state.copyWith(pending: await _repo.pendingActions(t));
    if (out.status == SwissVatActionStatus.sent) {
      await _refreshAll(t);
    }
    return out;
  }

  Future<SwissVatActionOutcome> createAdjustment(
    InputTaxAdjustmentDraft draft,
  ) async {
    final String? t = _tenantId;
    if (t == null) {
      return const SwissVatActionOutcome(SwissVatActionStatus.rejected);
    }
    final SwissVatActionOutcome out = await _repo.createAdjustment(t, draft);
    state = state.copyWith(
      adjustments: await _repo.cachedAdjustments(t, state.year),
      pending: await _repo.pendingActions(t),
    );
    if (out.status == SwissVatActionStatus.sent) {
      await _refreshAll(t);
    }
    return out;
  }

  Future<SwissVatActionOutcome> approveAdjustment(String id) async {
    final String? t = _tenantId;
    if (t == null) {
      return const SwissVatActionOutcome(SwissVatActionStatus.rejected);
    }
    final SwissVatActionOutcome out = await _repo.approveAdjustment(t, id);
    state = state.copyWith(pending: await _repo.pendingActions(t));
    if (out.status == SwissVatActionStatus.sent) {
      await _refreshAll(t);
    }
    return out;
  }

  Future<SwissVatActionOutcome> saveConfig(SwissVatConfig config) async {
    final String? t = _tenantId;
    if (t == null) {
      return const SwissVatActionOutcome(SwissVatActionStatus.rejected);
    }
    final SwissVatActionOutcome out = await _repo.saveConfig(t, config);
    state = state.copyWith(
      config: config,
      pending: await _repo.pendingActions(t),
    );
    return out;
  }

  Future<void> retry(String queueUuid) async {
    final String? t = _tenantId;
    if (t == null) {
      return;
    }
    await _repo.retryAction(t, queueUuid);
    await _refreshAll(t);
  }

  Future<void> dismiss(String queueUuid) async {
    final String? t = _tenantId;
    if (t == null) {
      return;
    }
    await _repo.dismissAction(queueUuid);
    await _readCache(t);
  }
}

final NotifierProvider<SwissVatController, SwissVatState> swissVatProvider =
    NotifierProvider<SwissVatController, SwissVatState>(SwissVatController.new);
