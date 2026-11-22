import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_engine.dart';
import '../domain/baseline_variance.dart';
import '../domain/cpm_scheduler.dart';
import '../domain/project_plan.dart';
import '../domain/project_portfolio_models.dart';
import '../domain/project_portfolio_repository.dart';
import '../domain/wbs_tree.dart';

/// Entities of the portfolio in the generic entity store and in `/mobile/sync/{entity}`.
const String projectEntity = 'projects';
const String wbsNodeEntity = 'wbs_nodes';
const String taskDependencyEntity = 'task_dependencies';
const String projectBaselineEntity = 'project_baselines';

const List<String> portfolioEntities = <String>[
  projectEntity,
  wbsNodeEntity,
  taskDependencyEntity,
  projectBaselineEntity,
];

const String _projects = '/projects';

/// Offline-first repository on the generic entity store: no table of its own, so no schema migration. Derived
/// figures (roll-up, schedule) are never stored, they are recomputed from the records on every read.
class ProjectPortfolioRepositoryImpl implements ProjectPortfolioRepository {
  ProjectPortfolioRepositoryImpl(this._db, this._engine);

  final AppDatabase _db;
  final SyncEngine _engine;

  // --- Reads ----------------------------------------------------------------------------------------------------

  @override
  Stream<List<Project>> watchProjects(String tenantId) =>
      _watch(tenantId, <String>[projectEntity]).map(
        (List<EntityRecord> rows) =>
            <Project>[
              for (final EntityRecord r in rows) Project.fromJson(_json(r)),
            ]..sort(
              (Project a, Project b) => a.projectCode.compareTo(b.projectCode),
            ),
      );

  @override
  Stream<ProjectPlan?> watchPlan(String tenantId, String projectId) =>
      _watch(tenantId, portfolioEntities).map(
        (List<EntityRecord> rows) => _plan(rows, projectId),
      );

  Stream<List<EntityRecord>> _watch(String tenantId, List<String> entities) {
    return (_db.select(_db.entityRecords)..where(
          (EntityRecords t) =>
              t.tenantId.equals(tenantId) &
              t.entity.isIn(entities) &
              t.deletedAt.isNull(),
        ))
        .watch();
  }

  Future<List<EntityRecord>> _read(String tenantId) =>
      _watch(tenantId, portfolioEntities).first;

  static Map<String, dynamic> _json(EntityRecord row) =>
      Map<String, dynamic>.from(jsonDecode(row.payload) as Map<dynamic, dynamic>);

  static ProjectPlan? _plan(List<EntityRecord> rows, String projectId) {
    Project? project;
    final List<WbsNode> nodes = <WbsNode>[];
    final List<TaskDependency> dependencies = <TaskDependency>[];
    final List<ProjectBaseline> baselines = <ProjectBaseline>[];
    final Set<String> unsynced = <String>{};
    for (final EntityRecord row in rows) {
      final Map<String, dynamic> json = _json(row);
      if (row.entity == projectEntity) {
        if (row.id == projectId) {
          project = Project.fromJson(json);
        }
        continue;
      }
      if ('${json['project_id']}' != projectId) {
        continue;
      }
      if (row.syncStatus != SyncStatus.synced) {
        unsynced.add(row.id);
      }
      switch (row.entity) {
        case wbsNodeEntity:
          nodes.add(WbsNode.fromJson(json));
        case taskDependencyEntity:
          dependencies.add(TaskDependency.fromJson(json));
        case projectBaselineEntity:
          baselines.add(ProjectBaseline.fromJson(json));
      }
    }
    if (project == null) {
      return null;
    }
    return ProjectPlan.build(
      project: project,
      nodes: nodes,
      dependencies: dependencies,
      baselines: baselines,
      unsyncedIds: unsynced,
    );
  }

  // --- Sync -----------------------------------------------------------------------------------------------------

  @override
  Future<PortfolioSyncResult> sync(String tenantId) async {
    try {
      await _engine.flush(tenantId);
    } on DioException catch (e) {
      if (e.response == null) {
        return const PortfolioSyncResult(PortfolioSyncStatus.offline);
      }
    }
    int failedPulls = 0;
    for (final String entity in portfolioEntities) {
      try {
        await _engine.pull(tenantId, entity);
      } on DioException catch (e) {
        if (e.response == null) {
          return const PortfolioSyncResult(PortfolioSyncStatus.offline);
        }
        failedPulls++;
      } on TypeError {
        failedPulls++;
      }
    }
    return failedPulls == 0
        ? const PortfolioSyncResult(PortfolioSyncStatus.synced)
        : PortfolioSyncResult(
            PortfolioSyncStatus.failed,
            pending: failedPulls,
          );
  }

  /// Sends the outbox right after a write; whatever goes wrong, the write is safe in the queue and the next sync
  /// cycle resends it.
  Future<void> _tryFlush(String tenantId) async {
    try {
      await _engine.flush(tenantId);
    } catch (_) {
      // Offline or refused: nothing to do here, the outbox keeps the write.
    }
  }

  // --- Projects -------------------------------------------------------------------------------------------------

  @override
  Future<void> updateProject(String tenantId, Project edited) async {
    final EntityRecord? row = await _find(tenantId, projectEntity, edited.id);
    if (row == null) {
      throw const PortfolioException(PortfolioErrorKind.notFound);
    }
    if (edited.name.trim().isEmpty) {
      throw const PortfolioException(PortfolioErrorKind.invalidTitle);
    }
    final String? cup = ProcurementCodes.normalize(edited.cupCode);
    final String? cig = ProcurementCodes.normalize(edited.cigCode);
    if (!ProcurementCodes.isValidCup(cup)) {
      throw const PortfolioException(PortfolioErrorKind.invalidCup);
    }
    if (!ProcurementCodes.isValidCig(cig)) {
      throw const PortfolioException(PortfolioErrorKind.invalidCig);
    }
    final Map<String, dynamic> stored = Project.fromJson(_json(row)).toJson();
    final Map<String, dynamic> next = edited
        .copyWith(
          name: edited.name.trim(),
          cupCode: () => cup,
          cigCode: () => cig,
        )
        .toJson();
    final Map<String, dynamic> changes = _diff(stored, next, const <String>{
      'name',
      'status',
      'cup_code',
      'cig_code',
    });
    if (changes.isEmpty) {
      return;
    }
    await _engine.update(
      tenantId: tenantId,
      entity: projectEntity,
      id: edited.id,
      path: _projects,
      changes: changes,
    );
    await _tryFlush(tenantId);
  }

  // --- WBS nodes ------------------------------------------------------------------------------------------------

  @override
  Future<String> createNode(
    String tenantId, {
    required String projectId,
    required String title,
    String? parentNodeId,
    WbsNodeType nodeType = WbsNodeType.workPackage,
    double plannedHours = 0,
    double plannedCost = 0,
    double plannedRevenue = 0,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final ProjectPlan? plan = _plan(await _read(tenantId), projectId);
    if (plan == null) {
      throw const PortfolioException(PortfolioErrorKind.notFound);
    }
    final WbsTree tree = plan.tree;
    if (parentNodeId != null && tree.byId(parentNodeId) == null) {
      throw const PortfolioException(PortfolioErrorKind.notFound);
    }
    final bool milestone = nodeType == WbsNodeType.milestone;
    final DateTime? start = startDate;
    final DateTime? end = milestone ? startDate : endDate;
    _validate(
      title: title,
      start: start,
      end: end,
      progress: 0,
      amounts: <double>[plannedHours, plannedCost, plannedRevenue],
    );
    final List<WbsNode> siblings = parentNodeId == null
        ? tree.roots
        : tree.childrenOf(parentNodeId);
    int sortOrder = 0;
    for (final WbsNode s in siblings) {
      sortOrder = s.sortOrder >= sortOrder ? s.sortOrder + 1 : sortOrder;
    }
    final Map<String, dynamic> data = WbsNode(
      id: '',
      projectId: projectId,
      parentNodeId: parentNodeId,
      wbsCode: tree.nextChildCode(parentNodeId),
      title: title.trim(),
      nodeType: nodeType,
      plannedHours: milestone ? 0 : plannedHours,
      plannedCost: plannedCost,
      plannedRevenue: plannedRevenue,
      startDate: start,
      endDate: end,
      sortOrder: sortOrder,
    ).toJson()..remove('id');
    final String id = await _engine.create(
      tenantId: tenantId,
      entity: wbsNodeEntity,
      path: '$_projects/$projectId/wbs-nodes',
      data: data,
      dependsOn: parentNodeId == null
          ? null
          : await _pendingCreate(tenantId, wbsNodeEntity, parentNodeId),
    );
    await _tryFlush(tenantId);
    return id;
  }

  @override
  Future<void> updateNode(String tenantId, WbsNode edited) async {
    final EntityRecord? row = await _find(tenantId, wbsNodeEntity, edited.id);
    if (row == null) {
      throw const PortfolioException(PortfolioErrorKind.notFound);
    }
    final WbsNode stored = WbsNode.fromJson(_json(row));
    final bool milestone = edited.nodeType == WbsNodeType.milestone;
    final WbsNode next = milestone
        ? edited.copyWith(
            plannedHours: 0,
            endDate: () => edited.startDate,
          )
        : edited;
    _validate(
      title: next.title,
      start: next.startDate,
      end: next.endDate,
      progress: next.percentComplete,
      amounts: <double>[
        next.plannedHours,
        next.actualHours,
        next.plannedCost,
        next.actualCost,
        next.plannedRevenue,
      ],
    );
    final Map<String, dynamic> changes = _diff(
      stored.toJson(),
      next.copyWith(title: next.title.trim()).toJson(),
      const <String>{
        'title',
        'node_type',
        'planned_hours',
        'actual_hours',
        'planned_cost',
        'actual_cost',
        'planned_revenue',
        'start_date',
        'end_date',
        'percent_complete',
        'sort_order',
      },
    );
    if (changes.isEmpty) {
      return;
    }
    await _engine.update(
      tenantId: tenantId,
      entity: wbsNodeEntity,
      id: edited.id,
      path: '$_projects/wbs-nodes',
      changes: changes,
    );
    await _tryFlush(tenantId);
  }

  @override
  Future<void> deleteNode(String tenantId, String nodeId) async {
    final List<EntityRecord> rows = await _read(tenantId);
    final EntityRecord? row = _row(rows, wbsNodeEntity, nodeId);
    if (row == null) {
      throw const PortfolioException(PortfolioErrorKind.notFound);
    }
    final String projectId = '${_json(row)['project_id']}';
    final WbsTree tree = WbsTree(<WbsNode>[
      for (final EntityRecord r in rows)
        if (r.entity == wbsNodeEntity && '${_json(r)['project_id']}' == projectId)
          WbsNode.fromJson(_json(r)),
    ]);
    final List<String> doomed = tree.subtreeIds(nodeId);
    for (final EntityRecord r in rows) {
      if (r.entity != taskDependencyEntity) {
        continue;
      }
      final TaskDependency d = TaskDependency.fromJson(_json(r));
      if (doomed.contains(d.predecessorNodeId) ||
          doomed.contains(d.successorNodeId)) {
        await _engine.delete(
          tenantId: tenantId,
          entity: taskDependencyEntity,
          id: d.id,
          path: '$_projects/task-dependencies',
        );
      }
    }
    // Deepest first, so the server never sees a parent deleted before its children.
    for (final String id in doomed.reversed) {
      await _engine.delete(
        tenantId: tenantId,
        entity: wbsNodeEntity,
        id: id,
        path: '$_projects/wbs-nodes',
      );
    }
    await _tryFlush(tenantId);
  }

  // --- Dependencies ---------------------------------------------------------------------------------------------

  @override
  Future<String> addDependency(
    String tenantId, {
    required String projectId,
    required String predecessorNodeId,
    required String successorNodeId,
    DependencyType type = DependencyType.fs,
    int lagDays = 0,
  }) async {
    final ProjectPlan? plan = _plan(await _read(tenantId), projectId);
    if (plan == null) {
      throw const PortfolioException(PortfolioErrorKind.notFound);
    }
    if (plan.node(predecessorNodeId) == null ||
        plan.node(successorNodeId) == null) {
      throw const PortfolioException(PortfolioErrorKind.crossProject);
    }
    for (final TaskDependency d in plan.dependencies) {
      if (d.predecessorNodeId == predecessorNodeId &&
          d.successorNodeId == successorNodeId) {
        throw const PortfolioException(PortfolioErrorKind.duplicateDependency);
      }
    }
    if (wouldCreateCycle(plan.dependencies, predecessorNodeId, successorNodeId)) {
      throw const PortfolioException(PortfolioErrorKind.dependencyCycle);
    }
    final String id = await _engine.create(
      tenantId: tenantId,
      entity: taskDependencyEntity,
      path: '$_projects/$projectId/dependencies',
      data: TaskDependency(
        id: '',
        projectId: projectId,
        predecessorNodeId: predecessorNodeId,
        successorNodeId: successorNodeId,
        dependencyType: type,
        lagDays: lagDays,
      ).toJson()..remove('id'),
      dependsOn:
          await _pendingCreate(tenantId, wbsNodeEntity, successorNodeId) ??
          await _pendingCreate(tenantId, wbsNodeEntity, predecessorNodeId),
    );
    await _tryFlush(tenantId);
    return id;
  }

  @override
  Future<void> removeDependency(String tenantId, String dependencyId) async {
    final EntityRecord? row = await _find(
      tenantId,
      taskDependencyEntity,
      dependencyId,
    );
    if (row == null) {
      throw const PortfolioException(PortfolioErrorKind.notFound);
    }
    await _engine.delete(
      tenantId: tenantId,
      entity: taskDependencyEntity,
      id: dependencyId,
      path: '$_projects/task-dependencies',
    );
    await _tryFlush(tenantId);
  }

  // --- Baselines ------------------------------------------------------------------------------------------------

  @override
  Future<String> captureBaseline(
    String tenantId, {
    required String projectId,
    required String name,
  }) async {
    final ProjectPlan? plan = _plan(await _read(tenantId), projectId);
    if (plan == null) {
      throw const PortfolioException(PortfolioErrorKind.notFound);
    }
    int number = 0;
    for (final ProjectBaseline b in plan.baselines) {
      number = b.baselineNumber > number ? b.baselineNumber : number;
    }
    number++;
    final String label = name.trim().isEmpty ? 'B$number' : name.trim();
    final String id = await _engine.create(
      tenantId: tenantId,
      entity: projectBaselineEntity,
      path: '$_projects/$projectId/baselines',
      data: <String, dynamic>{
        'project_id': projectId,
        'baseline_number': number,
        'name': label,
        'captured_at': DateTime.now().toUtc().toIso8601String(),
        'snapshot_json': BaselineVariance.snapshotOf(plan.nodes),
      },
    );
    await _tryFlush(tenantId);
    return id;
  }

  // --- Helpers --------------------------------------------------------------------------------------------------

  static void _validate({
    required String title,
    required DateTime? start,
    required DateTime? end,
    required double progress,
    required List<double> amounts,
  }) {
    if (title.trim().isEmpty) {
      throw const PortfolioException(PortfolioErrorKind.invalidTitle);
    }
    if (start != null && end != null && end.isBefore(start)) {
      throw const PortfolioException(PortfolioErrorKind.invalidDates);
    }
    if (progress < 0 || progress > 100) {
      throw const PortfolioException(PortfolioErrorKind.invalidProgress);
    }
    if (amounts.any((double a) => a < 0)) {
      throw const PortfolioException(PortfolioErrorKind.invalidAmount);
    }
  }

  static Map<String, dynamic> _diff(
    Map<String, dynamic> before,
    Map<String, dynamic> after,
    Set<String> writable,
  ) => <String, dynamic>{
    for (final String key in writable)
      if (before[key] != after[key]) key: after[key],
  };

  static EntityRecord? _row(List<EntityRecord> rows, String entity, String id) {
    for (final EntityRecord r in rows) {
      if (r.entity == entity && r.id == id) {
        return r;
      }
    }
    return null;
  }

  Future<EntityRecord?> _find(String tenantId, String entity, String id) =>
      (_db.select(_db.entityRecords)..where(
            (EntityRecords t) =>
                t.tenantId.equals(tenantId) &
                t.entity.equals(entity) &
                t.id.equals(id) &
                t.deletedAt.isNull(),
          ))
          .getSingleOrNull();

  /// Queue uuid of the unsent create of [id], so a child is not sent before its parent.
  Future<String?> _pendingCreate(
    String tenantId,
    String entity,
    String id,
  ) async {
    for (final QueueItem item in await _engine.queued(tenantId, entity)) {
      if (item.entityId == id && item.method == 'POST') {
        return item.uuid;
      }
    }
    return null;
  }
}
