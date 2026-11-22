import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../data/project_portfolio_repository_impl.dart';
import '../domain/project_plan.dart';
import '../domain/project_portfolio_models.dart';
import '../domain/project_portfolio_repository.dart';

final Provider<ProjectPortfolioRepository> projectPortfolioRepositoryProvider =
    Provider<ProjectPortfolioRepository>(
      (Ref ref) => ProjectPortfolioRepositoryImpl(
        ref.watch(databaseProvider),
        ref.watch(syncEngineProvider),
      ),
    );

String _tenant(Ref ref) => ref.read(requestContextProvider).tenantId ?? '';

/// The projects of the tenant, live from SQLite.
final StreamProvider<List<Project>> portfolioProjectsProvider =
    StreamProvider.autoDispose<List<Project>>(
      (Ref ref) => ref
          .watch(projectPortfolioRepositoryProvider)
          .watchProjects(_tenant(ref)),
    );

/// The plan of one project (roll-up and schedule included), live from SQLite.
final projectPlanProvider = StreamProvider.autoDispose
    .family<ProjectPlan?, String>(
      (Ref ref, String projectId) => ref
          .watch(projectPortfolioRepositoryProvider)
          .watchPlan(_tenant(ref), projectId),
    );

class PortfolioSyncState {
  const PortfolioSyncState({this.syncing = false, this.lastStatus});

  final bool syncing;

  /// How the last attempt ended; null before the first one.
  final PortfolioSyncStatus? lastStatus;

  bool get offline => lastStatus == PortfolioSyncStatus.offline;
  bool get failed => lastStatus == PortfolioSyncStatus.failed;
}

/// Pull-to-refresh and first-open sync. The screens read SQLite only; this just keeps SQLite fresh.
class PortfolioSyncController extends Notifier<PortfolioSyncState> {
  @override
  PortfolioSyncState build() => const PortfolioSyncState();

  Future<void> refresh() async {
    if (state.syncing) {
      return;
    }
    state = PortfolioSyncState(syncing: true, lastStatus: state.lastStatus);
    final PortfolioSyncResult result = await ref
        .read(projectPortfolioRepositoryProvider)
        .sync(_tenant(ref));
    state = PortfolioSyncState(lastStatus: result.status);
  }
}

final NotifierProvider<PortfolioSyncController, PortfolioSyncState>
portfolioSyncControllerProvider =
    NotifierProvider<PortfolioSyncController, PortfolioSyncState>(
      PortfolioSyncController.new,
    );

/// Filter and search of the portfolio list.
class PortfolioFilter {
  const PortfolioFilter({this.status, this.query = ''});

  final ProjectStatus? status;
  final String query;

  PortfolioFilter copyWith({
    ProjectStatus? Function()? status,
    String? query,
  }) => PortfolioFilter(
    status: status == null ? this.status : status(),
    query: query ?? this.query,
  );

  List<Project> apply(List<Project> projects) {
    final String needle = query.trim().toLowerCase();
    return <Project>[
      for (final Project p in projects)
        if ((status == null || p.status == status) &&
            (needle.isEmpty ||
                p.projectCode.toLowerCase().contains(needle) ||
                p.name.toLowerCase().contains(needle)))
          p,
    ];
  }
}

class PortfolioFilterController extends Notifier<PortfolioFilter> {
  @override
  PortfolioFilter build() => const PortfolioFilter();

  void setStatus(ProjectStatus? status) =>
      state = state.copyWith(status: () => status);

  void setQuery(String query) => state = state.copyWith(query: query);
}

final NotifierProvider<PortfolioFilterController, PortfolioFilter>
portfolioFilterProvider =
    NotifierProvider<PortfolioFilterController, PortfolioFilter>(
      PortfolioFilterController.new,
    );

/// The writes of the detail screens: thin wrappers that bind the tenant and let the UI stay free of it.
class PortfolioActions {
  PortfolioActions(this._ref);

  final Ref _ref;

  ProjectPortfolioRepository get _repo =>
      _ref.read(projectPortfolioRepositoryProvider);
  String get _tenantId => _tenant(_ref);

  Future<void> updateProject(Project edited) =>
      _repo.updateProject(_tenantId, edited);

  Future<String> createNode({
    required String projectId,
    required String title,
    String? parentNodeId,
    WbsNodeType nodeType = WbsNodeType.workPackage,
    double plannedHours = 0,
    double plannedCost = 0,
    double plannedRevenue = 0,
    DateTime? startDate,
    DateTime? endDate,
  }) => _repo.createNode(
    _tenantId,
    projectId: projectId,
    title: title,
    parentNodeId: parentNodeId,
    nodeType: nodeType,
    plannedHours: plannedHours,
    plannedCost: plannedCost,
    plannedRevenue: plannedRevenue,
    startDate: startDate,
    endDate: endDate,
  );

  Future<void> updateNode(WbsNode edited) =>
      _repo.updateNode(_tenantId, edited);

  /// Moves a node between the board columns: not started is 0%, done is 100%, in progress keeps a started value
  /// (50% when it had none).
  Future<void> moveNode(WbsNode node, WbsProgressState target) {
    final double percent = switch (target) {
      WbsProgressState.notStarted => 0,
      WbsProgressState.done => 100,
      WbsProgressState.inProgress =>
        node.percentComplete > 0 && node.percentComplete < 100
            ? node.percentComplete
            : 50,
    };
    return _repo.updateNode(_tenantId, node.copyWith(percentComplete: percent));
  }

  Future<void> deleteNode(String nodeId) => _repo.deleteNode(_tenantId, nodeId);

  Future<String> addDependency({
    required String projectId,
    required String predecessorNodeId,
    required String successorNodeId,
    DependencyType type = DependencyType.fs,
    int lagDays = 0,
  }) => _repo.addDependency(
    _tenantId,
    projectId: projectId,
    predecessorNodeId: predecessorNodeId,
    successorNodeId: successorNodeId,
    type: type,
    lagDays: lagDays,
  );

  Future<void> removeDependency(String dependencyId) =>
      _repo.removeDependency(_tenantId, dependencyId);

  Future<String> captureBaseline({
    required String projectId,
    required String name,
  }) => _repo.captureBaseline(_tenantId, projectId: projectId, name: name);
}

final Provider<PortfolioActions> portfolioActionsProvider =
    Provider<PortfolioActions>(PortfolioActions.new);
