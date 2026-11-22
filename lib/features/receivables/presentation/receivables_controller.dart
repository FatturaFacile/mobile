import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../app/session_controller.dart';
import '../data/receivables_local_data_source.dart';
import '../data/receivables_remote_data_source.dart';
import '../data/receivables_repository_impl.dart';
import '../data/statement_exporter.dart';
import '../domain/money.dart';
import '../domain/receivables_models.dart';
import '../domain/receivables_repository.dart';

final Provider<ReceivablesRepository> receivablesRepositoryProvider =
    Provider<ReceivablesRepository>(
      (Ref ref) => ReceivablesRepositoryImpl(
        ReceivablesLocalDataSource(ref.watch(databaseProvider)),
        ReceivablesRemoteDataSource(ref.watch(dioProvider)),
        ref.watch(syncEngineProvider),
      ),
    );

/// Active tenant of the signed-in session (`null` when signed out). Tests override it.
final Provider<String?> receivablesTenantIdProvider = Provider<String?>((
  Ref ref,
) {
  final SessionState? s = ref.watch(sessionProvider).value;
  return s is SignedIn ? s.bootstrap.tenantId : null;
});

/// Clock of the value dates and of the override expiry; tests override it.
final Provider<DateTime Function()> receivablesClockProvider =
    Provider<DateTime Function()>((Ref ref) => DateTime.now);

/// Share sheet of the statement files; tests override it.
final Provider<StatementExporter> statementExporterProvider =
    Provider<StatementExporter>((Ref ref) => const PlatformStatementExporter());

const Object _keep = Object();

// --- Dashboard ---------------------------------------------------------------------------------------------------

@immutable
class ReceivablesDashboardState {
  const ReceivablesDashboardState({
    this.dashboard,
    this.currency,
    this.loading = false,
    this.fromCache = false,
    this.error,
    this.pending = const <PendingBooking>[],
  });

  final ReceivablesDashboard? dashboard;

  /// `null` is the company currency.
  final String? currency;
  final bool loading;

  /// The figures are the offline copy because the last refresh failed.
  final bool fromCache;
  final ReceivablesException? error;
  final List<PendingBooking> pending;

  AgingReport? get aging => dashboard?.aging;

  bool get forbidden => error?.kind == ReceivablesErrorKind.forbidden;

  ReceivablesDashboardState copyWith({
    ReceivablesDashboard? dashboard,
    Object? currency = _keep,
    bool? loading,
    bool? fromCache,
    Object? error = _keep,
    List<PendingBooking>? pending,
  }) {
    return ReceivablesDashboardState(
      dashboard: dashboard ?? this.dashboard,
      currency: identical(currency, _keep)
          ? this.currency
          : currency as String?,
      loading: loading ?? this.loading,
      fromCache: fromCache ?? this.fromCache,
      error: identical(error, _keep)
          ? this.error
          : error as ReceivablesException?,
      pending: pending ?? this.pending,
    );
  }
}

/// Receivables overview, readable offline: shows the cached copy first, sends what is queued, then refreshes.
class ReceivablesDashboardController
    extends Notifier<ReceivablesDashboardState> {
  late String? _tenantId;

  ReceivablesRepository get _repo => ref.read(receivablesRepositoryProvider);

  @override
  ReceivablesDashboardState build() {
    _tenantId = ref.watch(receivablesTenantIdProvider);
    return const ReceivablesDashboardState();
  }

  /// Never throws.
  Future<void> load() async {
    final String? tenant = _tenantId;
    if (tenant == null) {
      return;
    }
    state = state.copyWith(loading: true, error: null);
    if (state.dashboard == null) {
      final ReceivablesDashboard? cached = await _repo.cachedDashboard(
        tenant,
        currency: state.currency,
      );
      if (cached != null) {
        state = state.copyWith(dashboard: cached, fromCache: true);
      }
    }
    try {
      // Queued bookings go out first, so the refreshed figures already reflect them.
      await _repo.flush(tenant);
    } catch (_) {
      // Still offline: they stay queued.
    }
    try {
      final ReceivablesDashboard fresh = await _repo.refreshDashboard(
        tenant,
        currency: state.currency,
      );
      state = state.copyWith(dashboard: fresh, fromCache: false);
    } on ReceivablesException catch (e) {
      state = e.kind == ReceivablesErrorKind.forbidden
          ? ReceivablesDashboardState(
              currency: state.currency,
              error: e,
              pending: state.pending,
            )
          : state.copyWith(error: e);
    }
    state = state.copyWith(
      loading: false,
      pending: await _repo.pendingActions(tenant),
    );
  }

  /// Switches the currency of every figure (`null` = company currency) and reloads.
  Future<void> setCurrency(String? currency) async {
    state = ReceivablesDashboardState(
      currency: currency,
      pending: state.pending,
    );
    await load();
  }
}

final NotifierProvider<
  ReceivablesDashboardController,
  ReceivablesDashboardState
>
receivablesDashboardProvider =
    NotifierProvider<ReceivablesDashboardController, ReceivablesDashboardState>(
      ReceivablesDashboardController.new,
    );

// --- One customer: credit position, items, bookings --------------------------------------------------------------

/// A one-shot message after an action, mapped to a localized snack by the page.
enum ReceivablesNotice {
  allocated,
  allocationQueued,
  reversed,
  reverseQueued,
  disputed,
  disputeQueued,
  disputeLifted,
  disputeLiftQueued,
  rejected,
}

@immutable
class CustomerCreditState {
  const CustomerCreditState({
    this.customerId = '',
    this.customerName = '',
    this.credit,
    this.risk,
    this.aging,
    this.unreconciled = const <UnreconciledPayment>[],
    this.items = const <ReceivableItem>[],
    this.bucket,
    this.selected,
    this.pending = const <PendingBooking>[],
    this.loading = false,
    this.fromCache = false,
    this.busy = false,
    this.error,
    this.notice,
    this.noticeDetail = '',
  });

  final String customerId;
  final String customerName;
  final CreditPosition? credit;
  final RiskScore? risk;
  final AgingReport? aging;
  final List<UnreconciledPayment> unreconciled;
  final List<ReceivableItem> items;

  /// Aging bucket the item list is filtered by, `null` for all.
  final String? bucket;

  /// The item opened on the detail page.
  final ReceivableItem? selected;
  final List<PendingBooking> pending;
  final bool loading;
  final bool fromCache;
  final bool busy;
  final ReceivablesException? error;
  final ReceivablesNotice? notice;
  final String noticeDetail;

  List<AgingBucketDef> get buckets =>
      aging?.buckets ?? const <AgingBucketDef>[];

  /// The items of the selected bucket.
  List<ReceivableItem> get visibleItems =>
      itemsInBucket(items, bucket, buckets);

  /// Open amount of the visible items.
  Money get visibleTotal =>
      Money.sum(visibleItems.map((ReceivableItem i) => i.openAmount));

  /// Outbox rows of one item, for the badge on its row.
  int pendingFor(String itemId) =>
      pending.where((PendingBooking a) => a.itemId == itemId).length;

  /// A reversal of [allocationId] is already waiting.
  bool reversalPending(String allocationId) => pending.any(
    (PendingBooking a) =>
        a.kind == ReceivablesActionKind.reversal &&
        a.allocationId == allocationId &&
        !a.rejected,
  );

  CustomerCreditState copyWith({
    String? customerId,
    String? customerName,
    CreditPosition? credit,
    RiskScore? risk,
    AgingReport? aging,
    List<UnreconciledPayment>? unreconciled,
    List<ReceivableItem>? items,
    Object? bucket = _keep,
    Object? selected = _keep,
    List<PendingBooking>? pending,
    bool? loading,
    bool? fromCache,
    bool? busy,
    Object? error = _keep,
    Object? notice = _keep,
    String? noticeDetail,
  }) {
    return CustomerCreditState(
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      credit: credit ?? this.credit,
      risk: risk ?? this.risk,
      aging: aging ?? this.aging,
      unreconciled: unreconciled ?? this.unreconciled,
      items: items ?? this.items,
      bucket: identical(bucket, _keep) ? this.bucket : bucket as String?,
      selected: identical(selected, _keep)
          ? this.selected
          : selected as ReceivableItem?,
      pending: pending ?? this.pending,
      loading: loading ?? this.loading,
      fromCache: fromCache ?? this.fromCache,
      busy: busy ?? this.busy,
      error: identical(error, _keep)
          ? this.error
          : error as ReceivablesException?,
      notice: identical(notice, _keep)
          ? this.notice
          : notice as ReceivablesNotice?,
      noticeDetail: noticeDetail ?? this.noticeDetail,
    );
  }
}

/// One customer: credit status, open items, aging and the bookings (payment, credit note, write-off, discount,
/// reversal, dispute), all usable offline.
class CustomerCreditController extends Notifier<CustomerCreditState> {
  late String? _tenantId;

  ReceivablesRepository get _repo => ref.read(receivablesRepositoryProvider);

  @override
  CustomerCreditState build() {
    _tenantId = ref.watch(receivablesTenantIdProvider);
    return const CustomerCreditState();
  }

  /// Offline copy first, then the server. Never throws.
  Future<void> load(
    String customerId, {
    String customerName = '',
    String? bucket,
  }) async {
    final String? tenant = _tenantId;
    if (tenant == null) {
      return;
    }
    state = CustomerCreditState(
      customerId: customerId,
      customerName: customerName,
      bucket: bucket,
      loading: true,
    );
    state = state.copyWith(
      credit: await _repo.cachedCredit(tenant, customerId),
      risk: await _repo.cachedRisk(tenant, customerId),
      aging: await _repo.cachedAging(tenant, customerId: customerId),
      unreconciled: await _repo.cachedUnreconciled(tenant, customerId),
      items: await _repo.cachedItems(tenant, customerId),
      pending: await _repo.pendingActions(tenant),
      fromCache: true,
    );
    try {
      await _repo.flush(tenant);
    } catch (_) {
      // Still offline: the bookings stay queued.
    }
    await _refreshAll(tenant);
    state = state.copyWith(
      loading: false,
      pending: await _repo.pendingActions(tenant),
    );
  }

  Future<void> _refreshAll(String tenant) async {
    final String id = state.customerId;
    try {
      state = state.copyWith(
        credit: await _repo.refreshCredit(tenant, id),
        fromCache: false,
      );
      state = state.copyWith(
        aging: await _repo.refreshAging(tenant, customerId: id),
        items: await _repo.refreshItems(tenant, id),
      );
    } on ReceivablesException catch (e) {
      state = state.copyWith(error: e);
      return;
    }
    // Risk and the unreconciled payments are extras: failing to load them must not hide the rest.
    try {
      state = state.copyWith(risk: await _repo.refreshRisk(tenant, id));
    } on ReceivablesException {
      // Keeps the cached score.
    }
    try {
      state = state.copyWith(
        unreconciled: await _repo.refreshUnreconciled(tenant, id),
      );
    } on ReceivablesException {
      // Keeps the cached list.
    }
  }

  void setBucket(String? bucket) => state = state.copyWith(bucket: bucket);

  /// Opens an item on the detail page: the offline copy first, then its allocations from the server.
  Future<void> select(String itemId) async {
    final String? tenant = _tenantId;
    if (tenant == null) {
      return;
    }
    ReceivableItem? found;
    for (final ReceivableItem i in state.items) {
      if (i.id == itemId) {
        found = i;
      }
    }
    state = state.copyWith(
      selected: await _repo.cachedItem(tenant, itemId) ?? found,
      error: null,
    );
    try {
      state = state.copyWith(selected: await _repo.refreshItem(tenant, itemId));
    } on ReceivablesException catch (e) {
      state = state.copyWith(error: e);
    }
  }

  /// Books [type] for [amount] against [item], dated [valueDate] (today when omitted). Checks the amount against the open
  /// amount first; returns the issues instead of sending when it is not valid.
  Future<List<DraftIssue>> allocate(
    ReceivableItem item, {
    required AllocationType type,
    required Money amount,
    UnreconciledPayment? payment,
    String? sourceId,
    String? reference,
    String? notes,
    DateTime? valueDate,
  }) async {
    final String? tenant = _tenantId;
    if (tenant == null || state.busy) {
      return const <DraftIssue>[];
    }
    final AllocationDraft draft = AllocationDraft(
      itemId: item.id,
      type: type,
      amount: amount,
      valueDate: valueDate ?? ref.read(receivablesClockProvider)(),
      sourceId: payment?.ledgerEntryId ?? sourceId,
      reference: reference,
      notes: notes,
    );
    final List<DraftIssue> issues = validateDraft(
      draft,
      openAmount: item.openAmount,
      sourceAvailable: payment?.unallocated,
    );
    if (issues.isNotEmpty) {
      return issues;
    }
    state = state.copyWith(busy: true, notice: null);
    final BookingOutcome outcome = await _repo.allocate(
      tenant,
      <AllocationDraft>[draft],
    );
    await _afterAction(
      tenant,
      outcome,
      sent: ReceivablesNotice.allocated,
      queued: ReceivablesNotice.allocationQueued,
      itemId: item.id,
    );
    return const <DraftIssue>[];
  }

  Future<void> reverse(String itemId, String allocationId) async {
    final String? tenant = _tenantId;
    if (tenant == null || state.busy || state.reversalPending(allocationId)) {
      return;
    }
    state = state.copyWith(busy: true, notice: null);
    final BookingOutcome outcome = await _repo.reverseAllocation(
      tenant,
      itemId,
      allocationId,
    );
    await _afterAction(
      tenant,
      outcome,
      sent: ReceivablesNotice.reversed,
      queued: ReceivablesNotice.reverseQueued,
      itemId: itemId,
    );
  }

  /// Marks the item disputed (a [reason] is required) or lifts the dispute. Returns `false` without sending when the
  /// reason is missing.
  Future<bool> setDispute(
    String itemId, {
    required bool disputed,
    String? reason,
  }) async {
    final String? tenant = _tenantId;
    if (tenant == null || state.busy) {
      return true;
    }
    if (disputed && (reason == null || reason.trim().isEmpty)) {
      return false;
    }
    state = state.copyWith(busy: true, notice: null);
    final BookingOutcome outcome = await _repo.setDispute(
      tenant,
      itemId,
      disputed: disputed,
      reason: reason,
    );
    await _afterAction(
      tenant,
      outcome,
      sent: disputed
          ? ReceivablesNotice.disputed
          : ReceivablesNotice.disputeLifted,
      queued: disputed
          ? ReceivablesNotice.disputeQueued
          : ReceivablesNotice.disputeLiftQueued,
      itemId: itemId,
    );
    return true;
  }

  Future<void> retry(String queueUuid) async {
    final String? tenant = _tenantId;
    if (tenant == null) {
      return;
    }
    await _repo.retryAction(tenant, queueUuid);
    state = state.copyWith(pending: await _repo.pendingActions(tenant));
  }

  Future<void> dismiss(String queueUuid) async {
    final String? tenant = _tenantId;
    if (tenant == null) {
      return;
    }
    await _repo.dismissAction(queueUuid);
    state = state.copyWith(
      items: await _repo.cachedItems(tenant, state.customerId),
      pending: await _repo.pendingActions(tenant),
    );
  }

  Future<void> _afterAction(
    String tenant,
    BookingOutcome outcome, {
    required ReceivablesNotice sent,
    required ReceivablesNotice queued,
    required String itemId,
  }) async {
    final ReceivablesNotice notice = switch (outcome.status) {
      BookingStatus.sent => sent,
      BookingStatus.queued => queued,
      BookingStatus.rejected => ReceivablesNotice.rejected,
    };
    // The repository already applied the booking to the cached items, so the list shows it even when queued.
    state = state.copyWith(
      items: await _repo.cachedItems(tenant, state.customerId),
      selected: await _repo.cachedItem(tenant, itemId),
      pending: await _repo.pendingActions(tenant),
    );
    if (outcome.status == BookingStatus.sent) {
      try {
        state = state.copyWith(
          credit: await _repo.refreshCredit(tenant, state.customerId),
          aging: await _repo.refreshAging(tenant, customerId: state.customerId),
          items: await _repo.refreshItems(tenant, state.customerId),
          unreconciled: await _repo.refreshUnreconciled(
            tenant,
            state.customerId,
          ),
          selected: await _repo.refreshItem(tenant, itemId),
        );
      } on ReceivablesException {
        // The booking is saved; the figures refresh on the next load.
      }
    }
    state = state.copyWith(
      busy: false,
      notice: notice,
      noticeDetail: outcome.detail,
    );
  }

  void clearNotice() => state = state.copyWith(notice: null);
}

final NotifierProvider<CustomerCreditController, CustomerCreditState>
customerCreditProvider =
    NotifierProvider<CustomerCreditController, CustomerCreditState>(
      CustomerCreditController.new,
    );

// --- Statement ---------------------------------------------------------------------------------------------------

enum ExportResult { shared, offline, failed }

@immutable
class StatementState {
  const StatementState({
    this.customerId = '',
    this.statement,
    this.from,
    this.to,
    this.loading = false,
    this.fromCache = false,
    this.exporting = false,
    this.error,
    this.export,
  });

  final String customerId;
  final CustomerStatement? statement;
  final DateTime? from;
  final DateTime? to;
  final bool loading;
  final bool fromCache;
  final bool exporting;
  final ReceivablesException? error;

  /// Result of the last share, mapped to a snack by the page.
  final ExportResult? export;

  StatementState copyWith({
    String? customerId,
    CustomerStatement? statement,
    Object? from = _keep,
    Object? to = _keep,
    bool? loading,
    bool? fromCache,
    bool? exporting,
    Object? error = _keep,
    Object? export = _keep,
  }) {
    return StatementState(
      customerId: customerId ?? this.customerId,
      statement: statement ?? this.statement,
      from: identical(from, _keep) ? this.from : from as DateTime?,
      to: identical(to, _keep) ? this.to : to as DateTime?,
      loading: loading ?? this.loading,
      fromCache: fromCache ?? this.fromCache,
      exporting: exporting ?? this.exporting,
      error: identical(error, _keep)
          ? this.error
          : error as ReceivablesException?,
      export: identical(export, _keep) ? this.export : export as ExportResult?,
    );
  }
}

/// Customer statement for a period, readable offline, with PDF/XLSX download and share.
class StatementController extends Notifier<StatementState> {
  late String? _tenantId;

  ReceivablesRepository get _repo => ref.read(receivablesRepositoryProvider);

  @override
  StatementState build() {
    _tenantId = ref.watch(receivablesTenantIdProvider);
    return const StatementState();
  }

  /// The period defaults to the start of the year until today. Never throws.
  Future<void> load(String customerId, {DateTime? from, DateTime? to}) async {
    final String? tenant = _tenantId;
    if (tenant == null) {
      return;
    }
    final DateTime today = ref.read(receivablesClockProvider)();
    final DateTime start = from ?? DateTime(today.year, 1, 1);
    final DateTime end = to ?? today;
    state = StatementState(
      customerId: customerId,
      from: start,
      to: end,
      loading: true,
    );
    final CustomerStatement? cached = await _repo.cachedStatement(
      tenant,
      customerId,
    );
    if (cached != null) {
      state = state.copyWith(statement: cached, fromCache: true);
    }
    try {
      final CustomerStatement fresh = await _repo.refreshStatement(
        tenant,
        customerId,
        from: start,
        to: end,
      );
      state = state.copyWith(statement: fresh, fromCache: false);
    } on ReceivablesException catch (e) {
      state = state.copyWith(error: e);
    }
    state = state.copyWith(loading: false);
  }

  /// Downloads the statement in [format] and opens the share sheet. Needs the network.
  Future<void> export(StatementFormat format) async {
    if (state.customerId.isEmpty || state.exporting) {
      return;
    }
    state = state.copyWith(exporting: true, export: null);
    final DateTime end = state.to ?? ref.read(receivablesClockProvider)();
    try {
      final Uint8List bytes = await _repo.downloadStatement(
        state.customerId,
        format,
        from: state.from,
        to: state.to,
      );
      await ref
          .read(statementExporterProvider)
          .share(
            fileName: statementFileName(
              state.customerId,
              end,
              format.extension,
            ),
            bytes: bytes,
            mimeType: format.mimeType,
          );
      state = state.copyWith(exporting: false, export: ExportResult.shared);
    } on ReceivablesException catch (e) {
      state = state.copyWith(
        exporting: false,
        export: e.kind == ReceivablesErrorKind.offline
            ? ExportResult.offline
            : ExportResult.failed,
      );
    } catch (_) {
      state = state.copyWith(exporting: false, export: ExportResult.failed);
    }
  }

  void clearExport() => state = state.copyWith(export: null);
}

final NotifierProvider<StatementController, StatementState> statementProvider =
    NotifierProvider<StatementController, StatementState>(
      StatementController.new,
    );
