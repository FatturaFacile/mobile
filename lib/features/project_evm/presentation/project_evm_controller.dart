import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../data/project_evm_local_data_source.dart';
import '../data/project_evm_remote_data_source.dart';
import '../data/project_evm_repository.dart';
import '../domain/project_evm_models.dart';

final Provider<ProjectEvmRepository> projectEvmRepositoryProvider =
    Provider<ProjectEvmRepository>(
      (Ref ref) => ProjectEvmRepositoryImpl(
        ProjectEvmLocalDataSource(ref.watch(databaseProvider)),
        ProjectEvmRemoteDataSource(ref.watch(dioProvider)),
      ),
    );

class ProjectEvmState {
  const ProjectEvmState({
    this.projects = const <EvmProjectRef>[],
    this.projectId,
    this.snapshot,
    this.loading = true,
    this.syncing = false,
    this.lastSync,
  });

  final List<EvmProjectRef> projects;
  final String? projectId;

  /// The snapshot of [projectId] (from the cache or just pulled); null while there is none.
  final ProjectEvmSnapshot? snapshot;

  /// True until the cache has been read.
  final bool loading;
  final bool syncing;

  /// How the last sync attempt ended; null before the first one.
  final EvmSyncStatus? lastSync;

  /// The page is showing cached figures because the server could not be reached.
  bool get offline => lastSync == EvmSyncStatus.offline;

  ProjectEvmState copyWith({
    List<EvmProjectRef>? projects,
    String? Function()? projectId,
    ProjectEvmSnapshot? Function()? snapshot,
    bool? loading,
    bool? syncing,
    EvmSyncStatus? Function()? lastSync,
  }) => ProjectEvmState(
    projects: projects ?? this.projects,
    projectId: projectId == null ? this.projectId : projectId(),
    snapshot: snapshot == null ? this.snapshot : snapshot(),
    loading: loading ?? this.loading,
    syncing: syncing ?? this.syncing,
    lastSync: lastSync == null ? this.lastSync : lastSync(),
  );
}

/// Cache first, then network: the page shows the stored figures at once and refreshes them in the background.
class ProjectEvmController extends Notifier<ProjectEvmState> {
  int _generation = 0;

  ProjectEvmRepository get _repo => ref.read(projectEvmRepositoryProvider);
  String get _tenant => ref.read(requestContextProvider).tenantId ?? '';

  @override
  ProjectEvmState build() => const ProjectEvmState();

  /// Reads the cached project list and refreshes it; opens [initialProjectId] or the first project.
  Future<void> open({String? initialProjectId}) async {
    final int generation = ++_generation;
    List<EvmProjectRef> projects = await _repo.cachedProjects(_tenant);
    if (generation != _generation) {
      return;
    }
    state = state.copyWith(projects: projects, loading: projects.isNotEmpty);

    final EvmSyncResult result = await _repo.syncProjects(_tenant);
    if (generation != _generation) {
      return;
    }
    if (result.status == EvmSyncStatus.synced) {
      projects = await _repo.cachedProjects(_tenant);
    }
    state = state.copyWith(
      projects: projects,
      loading: false,
      lastSync: () => result.status,
    );

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
    );
    final ProjectEvmSnapshot? cached = await _repo.cached(_tenant, projectId);
    if (generation != _generation) {
      return;
    }
    state = state.copyWith(loading: false, snapshot: () => cached);
    await _sync(projectId, generation);
  }

  /// Pull-to-refresh.
  Future<void> refresh() {
    final String? id = state.projectId;
    return id == null ? Future<void>.value() : _sync(id, _generation);
  }

  Future<void> _sync(String projectId, int generation) async {
    state = state.copyWith(syncing: true);
    final EvmSyncResult result = await _repo.sync(_tenant, projectId);
    if (generation != _generation) {
      return;
    }
    ProjectEvmSnapshot? snapshot = state.snapshot;
    if (result.status == EvmSyncStatus.synced) {
      snapshot = await _repo.cached(_tenant, projectId);
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

final NotifierProvider<ProjectEvmController, ProjectEvmState>
projectEvmControllerProvider =
    NotifierProvider<ProjectEvmController, ProjectEvmState>(
      ProjectEvmController.new,
    );
