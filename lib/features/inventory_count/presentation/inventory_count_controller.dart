import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart'
    show BuildContext, MaterialPageRoute, Navigator;

import '../../../app/providers.dart';
import '../../../app/session_controller.dart';
import '../../shop_floor/presentation/camera_scanner_page.dart';
import '../../wms/ui/scan_field.dart' show CameraScanner;
import '../data/inventory_count_repository.dart';
import '../domain/inventory_count_models.dart';

final Provider<InventoryCountRepository> inventoryCountRepositoryProvider =
    Provider<InventoryCountRepository>(
      (Ref ref) => InventoryCountRepository(
        ref.watch(databaseProvider),
        ref.watch(dioProvider),
      ),
    );

/// Active tenant of the signed-in session (`null` when signed out). Tests override it.
final Provider<String?> inventoryCountTenantProvider = Provider<String?>((
  Ref ref,
) {
  final SessionState? s = ref.watch(sessionProvider).value;
  return s is SignedIn ? s.bootstrap.tenantId : null;
});

/// Opens the camera and returns the decoded code; tests override it with a fake.
final Provider<CameraScanner> inventoryCountCameraScannerProvider =
    Provider<CameraScanner>(
      (Ref ref) =>
          (BuildContext context) => Navigator.of(context).push<String>(
            MaterialPageRoute<String>(
              builder: (_) => const CameraScannerPage(),
            ),
          ),
    );

/// Entries waiting to be sent for one tenant, live.
final inventoryCountPendingProvider = StreamProvider.family<int, String>(
  (Ref ref, String tenantId) =>
      ref.watch(inventoryCountRepositoryProvider).watchPendingCount(tenantId),
);

/// Feature hook of the sync orchestrator: sends the pending entries and refreshes the sheets they touched.
Future<void> syncInventoryCounts(Ref ref, String tenantId) async {
  await ref.read(inventoryCountRepositoryProvider).sync(tenantId);
}

/// One-shot message for the screen (translated by the page).
enum CountNotice {
  saved,
  queuedOffline,
  recountRequested,
  syncDone,
  syncError,
  scanNoMatch,
}

// --- My counts -----------------------------------------------------------------------------------------------------

@immutable
class CountListState {
  const CountListState({
    this.sessions = const <CountSession>[],
    this.loading = false,
    this.fromCache = false,
    this.error,
  });

  final List<CountSession> sessions;
  final bool loading;

  /// The list is the offline copy because the last refresh failed.
  final bool fromCache;
  final CountException? error;

  CountListState copyWith({
    List<CountSession>? sessions,
    bool? loading,
    bool? fromCache,
    Object? error = _keep,
  }) => CountListState(
    sessions: sessions ?? this.sessions,
    loading: loading ?? this.loading,
    fromCache: fromCache ?? this.fromCache,
    error: identical(error, _keep) ? this.error : error as CountException?,
  );

  static const Object _keep = Object();
}

/// Sessions assigned to the user, readable offline.
class CountListController extends Notifier<CountListState> {
  late String? _tenantId;

  InventoryCountRepository get _repo =>
      ref.read(inventoryCountRepositoryProvider);

  @override
  CountListState build() {
    _tenantId = ref.watch(inventoryCountTenantProvider);
    return const CountListState();
  }

  /// Shows the offline copy first, sends what is pending, then refreshes from the API. Never throws.
  Future<void> load() async {
    final String? tenant = _tenantId;
    if (tenant == null) {
      return;
    }
    state = state.copyWith(loading: true, error: null);
    state = state.copyWith(
      sessions: await _repo.cachedSessions(tenant),
      fromCache: true,
    );
    try {
      await _repo.sync(tenant);
      state = state.copyWith(
        sessions: await _repo.refreshSessions(tenant),
        fromCache: false,
      );
    } on CountException catch (e) {
      state = state.copyWith(error: e);
    }
    state = state.copyWith(loading: false);
  }

  /// Re-reads the local progress (after the pending entries changed).
  Future<void> reloadLocal() async {
    final String? tenant = _tenantId;
    if (tenant != null) {
      state = state.copyWith(sessions: await _repo.cachedSessions(tenant));
    }
  }
}

final NotifierProvider<CountListController, CountListState> countListProvider =
    NotifierProvider<CountListController, CountListState>(
      CountListController.new,
    );

// --- Count sheet ---------------------------------------------------------------------------------------------------

enum CountFilter { toCount, counted, all }

@immutable
class CountSheetState {
  const CountSheetState({
    this.lines = const <CountLine>[],
    this.query = '',
    this.filter = CountFilter.toCount,
    this.loading = false,
    this.syncing = false,
    this.fromCache = false,
    this.error,
    this.notice,
    this.focusLineId,
  });

  final List<CountLine> lines;
  final String query;
  final CountFilter filter;
  final bool loading;
  final bool syncing;
  final bool fromCache;
  final CountException? error;
  final CountNotice? notice;

  /// Line the last scan resolved to (the page opens its entry sheet).
  final String? focusLineId;

  /// Lines on screen: recounts first, then by bin and SKU (the repository order).
  List<CountLine> get visible {
    final String q = query.trim().toLowerCase();
    final List<CountLine> shown = <CountLine>[
      for (final CountLine l in lines)
        if (l.matches(q) &&
            switch (filter) {
              CountFilter.toCount => l.toCount,
              CountFilter.counted => !l.toCount,
              CountFilter.all => true,
            })
          l,
    ];
    return <CountLine>[
      ...shown.where((CountLine l) => l.recountRequired),
      ...shown.where((CountLine l) => !l.recountRequired),
    ];
  }

  int get countedLines => lines.where((CountLine l) => !l.toCount).length;
  int get recountLines =>
      lines.where((CountLine l) => l.recountRequired).length;

  CountSheetState copyWith({
    List<CountLine>? lines,
    String? query,
    CountFilter? filter,
    bool? loading,
    bool? syncing,
    bool? fromCache,
    Object? error = _keep,
    Object? notice = _keep,
    Object? focusLineId = _keep,
  }) => CountSheetState(
    lines: lines ?? this.lines,
    query: query ?? this.query,
    filter: filter ?? this.filter,
    loading: loading ?? this.loading,
    syncing: syncing ?? this.syncing,
    fromCache: fromCache ?? this.fromCache,
    error: identical(error, _keep) ? this.error : error as CountException?,
    notice: identical(notice, _keep) ? this.notice : notice as CountNotice?,
    focusLineId: identical(focusLineId, _keep)
        ? this.focusLineId
        : focusLineId as String?,
  );

  static const Object _keep = Object();
}

/// Blind count sheet of one session: search, scan, quantity entry (offline outbox) and recounts.
class CountSheetController extends Notifier<CountSheetState> {
  CountSheetController(this.sessionId);

  final String sessionId;
  late String? _tenantId;

  InventoryCountRepository get _repo =>
      ref.read(inventoryCountRepositoryProvider);

  @override
  CountSheetState build() {
    _tenantId = ref.watch(inventoryCountTenantProvider);
    return const CountSheetState();
  }

  /// Offline copy first, then pending entries are sent and the sheet is refreshed. Never throws.
  Future<void> load() async {
    final String? tenant = _tenantId;
    if (tenant == null) {
      return;
    }
    state = state.copyWith(loading: true, error: null);
    state = state.copyWith(
      lines: await _repo.cachedSheet(tenant, sessionId),
      fromCache: true,
    );
    try {
      await _repo.sync(tenant);
      state = state.copyWith(
        lines: await _repo.refreshSheet(tenant, sessionId),
        fromCache: false,
      );
    } on CountException catch (e) {
      state = state.copyWith(error: e);
    }
    state = state.copyWith(loading: false);
  }

  void setQuery(String value) =>
      state = state.copyWith(query: value, focusLineId: null);

  void setFilter(CountFilter value) => state = state.copyWith(filter: value);

  void clearNotice() => state = state.copyWith(notice: null);

  void clearFocus() => state = state.copyWith(focusLineId: null);

  /// Applies a scanned or typed code: it becomes the search, and a single match is focused for quantity entry.
  void scan(String code) {
    final String q = code.trim();
    if (q.isEmpty) {
      return;
    }
    final String lower = q.toLowerCase();
    final List<CountLine> matches = <CountLine>[
      for (final CountLine l in state.lines)
        if (l.matches(lower)) l,
    ];
    if (matches.isEmpty) {
      state = state.copyWith(
        query: q,
        filter: CountFilter.all,
        notice: CountNotice.scanNoMatch,
        focusLineId: null,
      );
      return;
    }
    // A scan finds the line wherever it is: counted lines stay reachable for a correction.
    final List<CountLine> open = matches
        .where((CountLine l) => l.toCount)
        .toList();
    final CountLine? single = open.length == 1
        ? open.first
        : (matches.length == 1 ? matches.first : null);
    state = state.copyWith(
      query: q,
      filter: open.isEmpty ? CountFilter.all : CountFilter.toCount,
      focusLineId: single?.id,
      notice: null,
    );
  }

  /// Saves one count locally, then tries to send it. Returns false when the quantity is invalid.
  Future<bool> save(CountLine line, double quantity, {String? notes}) async {
    final String? tenant = _tenantId;
    if (tenant == null) {
      return false;
    }
    try {
      await _repo.recordCount(
        tenant,
        sessionId: sessionId,
        lineId: line.id,
        quantity: quantity,
        notes: notes,
      );
    } on CountException catch (e) {
      state = state.copyWith(error: e);
      return false;
    }
    state = state.copyWith(
      lines: await _repo.cachedSheet(tenant, sessionId),
      error: null,
      notice: CountNotice.queuedOffline,
      focusLineId: null,
    );
    final CountSyncReport report = await _repo.sync(tenant);
    final List<CountLine> lines = await _repo.cachedSheet(tenant, sessionId);
    final CountLine? now = _find(lines, line.id);
    state = state.copyWith(
      lines: lines,
      notice: report.stillPending > 0 || report.offline
          ? CountNotice.queuedOffline
          : (now?.recountRequired ?? false)
          ? CountNotice.recountRequested
          : CountNotice.saved,
    );
    return true;
  }

  /// "Sync now": sends every pending entry of the tenant and refreshes this sheet.
  Future<void> syncNow() async {
    final String? tenant = _tenantId;
    if (tenant == null) {
      return;
    }
    state = state.copyWith(syncing: true, notice: null);
    final CountSyncReport report = await _repo.sync(tenant);
    CountNotice notice = report.offline || report.stillPending > 0
        ? CountNotice.syncError
        : CountNotice.syncDone;
    try {
      state = state.copyWith(
        lines: await _repo.refreshSheet(tenant, sessionId),
        fromCache: false,
      );
    } on CountException {
      notice = CountNotice.syncError;
      state = state.copyWith(lines: await _repo.cachedSheet(tenant, sessionId));
    }
    state = state.copyWith(syncing: false, notice: notice);
  }

  /// Hides a refused entry once the operator has read the server decision.
  Future<void> dismiss(CountLine line) async {
    final String? tenant = _tenantId;
    final CountEntry? e = line.entry;
    if (tenant == null || e == null) {
      return;
    }
    await _repo.dismissEntry(tenant, e.clientEntryId);
    state = state.copyWith(lines: await _repo.cachedSheet(tenant, sessionId));
  }

  static CountLine? _find(List<CountLine> lines, String id) {
    for (final CountLine l in lines) {
      if (l.id == id) {
        return l;
      }
    }
    return null;
  }
}

final countSheetProvider =
    NotifierProvider.family<CountSheetController, CountSheetState, String>(
      CountSheetController.new,
    );
