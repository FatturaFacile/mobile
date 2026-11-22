import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../project_evm/data/project_evm_local_data_source.dart';
import '../../project_evm/data/project_evm_remote_data_source.dart';
import '../../project_evm/data/project_evm_repository.dart';
import '../../project_evm/domain/project_evm_models.dart';
import '../data/project_billing_local_data_source.dart';
import '../data/project_billing_remote_data_source.dart';
import '../data/project_billing_repository.dart';
import '../domain/project_billing_models.dart';

final Provider<ProjectBillingRepository> projectBillingRepositoryProvider =
    Provider<ProjectBillingRepository>(
      (Ref ref) => ProjectBillingRepositoryImpl(
        ProjectBillingLocalDataSource(ref.watch(databaseProvider)),
        ProjectBillingRemoteDataSource(ref.watch(dioProvider)),
      ),
    );

/// The project picker is the one of the profitability view: same cache, same list.
final Provider<ProjectEvmRepository> _projectIndexProvider =
    Provider<ProjectEvmRepository>(
      (Ref ref) => ProjectEvmRepositoryImpl(
        ProjectEvmLocalDataSource(ref.watch(databaseProvider)),
        ProjectEvmRemoteDataSource(ref.watch(dioProvider)),
      ),
    );

class ProjectBillingState {
  const ProjectBillingState({
    this.projects = const <EvmProjectRef>[],
    this.projectId,
    this.snapshot,
    this.loading = true,
    this.syncing = false,
    this.lastSync,
    this.progress = 0,
  });

  final List<EvmProjectRef> projects;
  final String? projectId;

  /// The snapshot of [projectId] (from the cache or just pulled); null while there is none.
  final ProjectBillingSnapshot? snapshot;

  /// True until the cache has been read.
  final bool loading;
  final bool syncing;

  /// How the last sync attempt ended; null before the first one.
  final BillingSyncStatus? lastSync;

  /// Cumulative progress (0-100) chosen on the SAL calculator.
  final double progress;

  /// The page is showing cached figures because the server could not be reached.
  bool get offline => lastSync == BillingSyncStatus.offline;

  /// The next SAL at the chosen progress, or null when it cannot be previewed.
  SalPreview? get preview => snapshot?.previewNext(progress);

  ProjectBillingState copyWith({
    List<EvmProjectRef>? projects,
    String? Function()? projectId,
    ProjectBillingSnapshot? Function()? snapshot,
    bool? loading,
    bool? syncing,
    BillingSyncStatus? Function()? lastSync,
    double? progress,
  }) => ProjectBillingState(
    projects: projects ?? this.projects,
    projectId: projectId == null ? this.projectId : projectId(),
    snapshot: snapshot == null ? this.snapshot : snapshot(),
    loading: loading ?? this.loading,
    syncing: syncing ?? this.syncing,
    lastSync: lastSync == null ? this.lastSync : lastSync(),
    progress: progress ?? this.progress,
  );
}

/// Cache first, then network: the page shows the stored figures at once and refreshes them in the background.
class ProjectBillingController extends Notifier<ProjectBillingState> {
  int _generation = 0;

  ProjectBillingRepository get _repo =>
      ref.read(projectBillingRepositoryProvider);
  ProjectEvmRepository get _index => ref.read(_projectIndexProvider);
  String get _tenant => ref.read(requestContextProvider).tenantId ?? '';

  @override
  ProjectBillingState build() => const ProjectBillingState();

  /// Reads the cached project list and refreshes it; opens [initialProjectId] or the first project.
  Future<void> open({String? initialProjectId}) async {
    final int generation = ++_generation;
    List<EvmProjectRef> projects = await _index.cachedProjects(_tenant);
    if (generation != _generation) {
      return;
    }
    state = state.copyWith(projects: projects, loading: projects.isNotEmpty);

    final EvmSyncResult result = await _index.syncProjects(_tenant);
    if (generation != _generation) {
      return;
    }
    if (result.status == EvmSyncStatus.synced) {
      projects = await _index.cachedProjects(_tenant);
    }
    state = state.copyWith(projects: projects, loading: false);

    final String? target =
        initialProjectId ??
        state.projectId ??
        (projects.isEmpty ? null : projects.first.id);
    if (target != null) {
      await select(target);
    }
  }

  Future<void> select(String projectId) async {
    final int generation = ++_generation;
    state = state.copyWith(
      projectId: () => projectId,
      loading: true,
      snapshot: () => null,
      progress: 0,
    );
    final ProjectBillingSnapshot? cached = await _repo.cached(
      _tenant,
      projectId,
    );
    if (generation != _generation) {
      return;
    }
    state = state.copyWith(
      loading: false,
      snapshot: () => cached,
      progress: _startProgress(cached),
    );
    await _sync(projectId, generation);
  }

  /// The SAL calculator slider.
  void setProgress(double percent) =>
      state = state.copyWith(progress: percent.clamp(0, 100).toDouble());

  /// Pull-to-refresh.
  Future<void> refresh() {
    final String? id = state.projectId;
    return id == null ? Future<void>.value() : _sync(id, _generation);
  }

  Future<void> _sync(String projectId, int generation) async {
    state = state.copyWith(syncing: true);
    final BillingSyncResult result = await _repo.sync(_tenant, projectId);
    if (generation != _generation) {
      return;
    }
    ProjectBillingSnapshot? snapshot = state.snapshot;
    if (result.status == BillingSyncStatus.synced) {
      snapshot = await _repo.cached(_tenant, projectId);
      if (generation != _generation) {
        return;
      }
    }
    state = state.copyWith(
      syncing: false,
      snapshot: () => snapshot,
      lastSync: () => result.status,
      progress: state.progress == 0 ? _startProgress(snapshot) : null,
    );
  }

  /// The calculator starts at the progress of the last live certificate, so the first step forward is a valid SAL.
  static double _startProgress(ProjectBillingSnapshot? snapshot) =>
      snapshot?.lastLive?.cumulativePercent ?? 0;
}

final NotifierProvider<ProjectBillingController, ProjectBillingState>
projectBillingControllerProvider =
    NotifierProvider<ProjectBillingController, ProjectBillingState>(
      ProjectBillingController.new,
    );
