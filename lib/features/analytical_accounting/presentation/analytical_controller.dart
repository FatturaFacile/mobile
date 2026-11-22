import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../data/analytical_local_data_source.dart';
import '../data/analytical_remote_data_source.dart';
import '../data/analytical_repository.dart';
import '../domain/analytical_models.dart';

final Provider<AnalyticalRepository> analyticalRepositoryProvider =
    Provider<AnalyticalRepository>(
      (Ref ref) => AnalyticalRepositoryImpl(
        AnalyticalLocalDataSource(ref.watch(databaseProvider)),
        AnalyticalRemoteDataSource(ref.watch(dioProvider)),
      ),
    );

class AnalyticalState {
  const AnalyticalState({
    this.overview = const AnalyticalOverview(),
    this.loading = true,
    this.syncing = false,
    this.lastSync,
    this.entryErrors = const <String>[],
    this.entryQueued = false,
  });

  final AnalyticalOverview overview;

  /// True until the cache has been read.
  final bool loading;
  final bool syncing;

  /// How the last sync attempt ended; null before the first one.
  final AnalyticalSyncStatus? lastSync;

  /// The error codes of the last refused entry.
  final List<String> entryErrors;

  /// The last entry was queued.
  final bool entryQueued;

  /// The page is showing cached figures because the server could not be reached.
  bool get offline => lastSync == AnalyticalSyncStatus.offline;

  AnalyticalState copyWith({
    AnalyticalOverview? overview,
    bool? loading,
    bool? syncing,
    AnalyticalSyncStatus? Function()? lastSync,
    List<String>? entryErrors,
    bool? entryQueued,
  }) => AnalyticalState(
    overview: overview ?? this.overview,
    loading: loading ?? this.loading,
    syncing: syncing ?? this.syncing,
    lastSync: lastSync == null ? this.lastSync : lastSync(),
    entryErrors: entryErrors ?? this.entryErrors,
    entryQueued: entryQueued ?? this.entryQueued,
  );
}

/// Cache first, then network: the page shows the stored figures at once, sends the entries queued offline and refreshes in the
/// background.
class AnalyticalController extends Notifier<AnalyticalState> {
  int _generation = 0;

  AnalyticalRepository get _repo => ref.read(analyticalRepositoryProvider);
  String get _tenant => ref.read(requestContextProvider).tenantId ?? '';

  @override
  AnalyticalState build() => const AnalyticalState();

  /// Reads the cache, then syncs.
  Future<void> open() async {
    final int generation = ++_generation;
    final AnalyticalOverview cached = await _repo.overview(_tenant);
    if (generation != _generation) {
      return;
    }
    state = state.copyWith(overview: cached, loading: false);
    await _sync(generation);
  }

  /// Pull-to-refresh.
  Future<void> refresh() => _sync(_generation);

  /// Captures a manual entry offline; the next sync sends it. Returns true when it was queued.
  Future<bool> queueEntry(EntryDraft draft) async {
    final List<String> errors = await _repo.queueEntry(_tenant, draft);
    final AnalyticalOverview overview = await _repo.overview(_tenant);
    state = state.copyWith(
      overview: overview,
      entryErrors: errors,
      entryQueued: errors.isEmpty,
    );
    return errors.isEmpty;
  }

  Future<void> _sync(int generation) async {
    state = state.copyWith(syncing: true);
    final AnalyticalSyncResult result = await _repo.sync(_tenant);
    if (generation != _generation) {
      return;
    }
    final AnalyticalOverview overview = await _repo.overview(_tenant);
    if (generation != _generation) {
      return;
    }
    state = state.copyWith(
      syncing: false,
      overview: overview,
      lastSync: () => result.status,
    );
  }
}

final NotifierProvider<AnalyticalController, AnalyticalState>
analyticalControllerProvider =
    NotifierProvider<AnalyticalController, AnalyticalState>(
      AnalyticalController.new,
    );
