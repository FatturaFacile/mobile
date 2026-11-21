import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../data/dss_local_data_source.dart';
import '../data/dss_remote_data_source.dart';
import '../data/dss_repository_impl.dart';
import '../domain/dss_models.dart';
import '../domain/dss_repository.dart';

final Provider<DssRepository> dssRepositoryProvider = Provider<DssRepository>(
  (Ref ref) => DssRepositoryImpl(
    DssLocalDataSource(ref.watch(databaseProvider)),
    DssRemoteDataSource(ref.watch(dioProvider)),
  ),
);

class DssState {
  const DssState({
    this.filter = const DssFilter(),
    this.snapshot,
    this.loading = true,
    this.syncing = false,
    this.lastSync,
  });

  final DssFilter filter;

  /// The snapshot of [filter] (from the cache or just pulled); null while there is none.
  final DssSnapshot? snapshot;

  /// True until the cache of the filter has been read.
  final bool loading;
  final bool syncing;

  /// How the last sync attempt ended; null before the first one.
  final DssSyncStatus? lastSync;

  /// The page is showing cached figures because the server could not be reached.
  bool get offline => lastSync == DssSyncStatus.offline;

  DssState copyWith({
    DssFilter? filter,
    DssSnapshot? Function()? snapshot,
    bool? loading,
    bool? syncing,
    DssSyncStatus? Function()? lastSync,
  }) => DssState(
    filter: filter ?? this.filter,
    snapshot: snapshot == null ? this.snapshot : snapshot(),
    loading: loading ?? this.loading,
    syncing: syncing ?? this.syncing,
    lastSync: lastSync == null ? this.lastSync : lastSync(),
  );
}

/// Cache first, then network: the page shows the stored snapshot at once and refreshes it in the background.
class DssController extends Notifier<DssState> {
  int _generation = 0;

  DssRepository get _repo => ref.read(dssRepositoryProvider);
  String get _tenant => ref.read(requestContextProvider).tenantId ?? '';

  @override
  DssState build() => const DssState();

  Future<void> open() => _load(state.filter);

  Future<void> setFilter(DssFilter filter) {
    if (filter == state.filter) {
      return Future<void>.value();
    }
    return _load(filter);
  }

  Future<void> setCurrency(String currency) =>
      setFilter(state.filter.copyWith(currency: currency));

  Future<void> setPeriod(String period) =>
      setFilter(state.filter.copyWith(periodPreset: period));

  Future<void> setLegalEntity(String legalEntityId) =>
      setFilter(state.filter.copyWith(legalEntityId: legalEntityId));

  /// Pull-to-refresh.
  Future<void> refresh() => _sync(state.filter, _generation);

  Future<void> _load(DssFilter filter) async {
    final int generation = ++_generation;
    state = state.copyWith(
      filter: filter,
      loading: true,
      snapshot: () => null,
      lastSync: () => null,
    );
    final DssSnapshot? cached = await _repo.cached(_tenant, filter);
    if (generation != _generation) {
      return;
    }
    state = state.copyWith(loading: false, snapshot: () => cached);
    await _sync(filter, generation);
  }

  Future<void> _sync(DssFilter filter, int generation) async {
    state = state.copyWith(syncing: true);
    final DssSyncResult result = await _repo.sync(_tenant, filter);
    if (generation != _generation) {
      return;
    }
    DssSnapshot? snapshot = state.snapshot;
    if (result.status == DssSyncStatus.synced) {
      snapshot = await _repo.cached(_tenant, filter);
      if (generation != _generation) {
        return;
      }
    }
    state = state.copyWith(
      syncing: false,
      snapshot: () => snapshot,
      lastSync: () => result.status,
    );
  }
}

final NotifierProvider<DssController, DssState> dssControllerProvider =
    NotifierProvider<DssController, DssState>(DssController.new);
