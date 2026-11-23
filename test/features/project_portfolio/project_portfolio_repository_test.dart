import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:fattura_facile/core/database/app_database.dart';
import 'package:fattura_facile/core/sync/sync_engine.dart';
import 'package:fattura_facile/features/project_portfolio/data/project_portfolio_repository_impl.dart';
import 'package:fattura_facile/features/project_portfolio/domain/project_plan.dart';
import 'package:fattura_facile/features/project_portfolio/domain/project_portfolio_models.dart';
import 'package:fattura_facile/features/project_portfolio/domain/project_portfolio_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/sync_engine_test.dart' show FakeAdapter, json;

const String _tenant = 't1';
const String _project = 'p1';

void main() {
  late AppDatabase db;
  late FakeAdapter adapter;
  late SyncEngine engine;
  late ProjectPortfolioRepositoryImpl repo;

  Future<void> seed(String entity, String id, Map<String, dynamic> payload) =>
      db
          .into(db.entityRecords)
          .insert(
            EntityRecordsCompanion.insert(
              entity: entity,
              id: id,
              tenantId: _tenant,
              payload: jsonEncode(<String, dynamic>{'id': id, ...payload}),
              syncStatus: SyncStatus.synced,
              localUpdatedAt: DateTime.utc(2027),
              createdAt: DateTime.utc(2027),
              updatedAt: DateTime.utc(2027),
            ),
          );

  Future<void> seedProject() => seed(projectEntity, _project, <String, dynamic>{
    'project_code': 'PRJ-1',
    'name': 'Bridge',
    'status': 'active',
  });

  Future<void> seedNode(
    String id,
    String code, {
    String? parent,
    String? start,
    String? end,
    String type = 'work_package',
    num hours = 0,
  }) => seed(wbsNodeEntity, id, <String, dynamic>{
    'project_id': _project,
    'parent_node_id': parent,
    'wbs_code': code,
    'title': 'Node $id',
    'node_type': type,
    'start_date': start,
    'end_date': end,
    'planned_hours': hours,
  });

  Future<ProjectPlan> plan() async =>
      (await repo.watchPlan(_tenant, _project).first)!;

  Future<List<QueueItem>> queue() => db.select(db.syncQueue).get();

  void goOffline() =>
      adapter.handler = (RequestOptions o) =>
          throw DioException.connectionError(requestOptions: o, reason: 'down');

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    adapter = FakeAdapter(
      (RequestOptions o) => json(200, <String, dynamic>{
        'data': <String, dynamic>{'id': 'srv'},
      }),
    );
    final Dio dio = Dio(
      BaseOptions(
        baseUrl: 'http://x/api/v1',
        validateStatus: (int? s) => s != null && s < 300,
      ),
    )..httpClientAdapter = adapter;
    engine = SyncEngine(db, dio);
    repo = ProjectPortfolioRepositoryImpl(db, engine);
    await seedProject();
  });

  tearDown(() => db.close());

  test(
    'the project list and the plan come from SQLite, scoped by tenant',
    () async {
      await seedNode(
        'a',
        '1',
        start: '2027-01-01',
        end: '2027-01-03',
        hours: 8,
      );
      await db
          .into(db.entityRecords)
          .insert(
            EntityRecordsCompanion.insert(
              entity: projectEntity,
              id: 'other',
              tenantId: 'someone-else',
              payload: jsonEncode(<String, dynamic>{
                'id': 'other',
                'project_code': 'X',
              }),
              syncStatus: SyncStatus.synced,
              localUpdatedAt: DateTime.utc(2027),
              createdAt: DateTime.utc(2027),
              updatedAt: DateTime.utc(2027),
            ),
          );
      final List<Project> projects = await repo.watchProjects(_tenant).first;
      expect(projects.single.projectCode, 'PRJ-1');
      final ProjectPlan p = await plan();
      expect(p.project.plannedHours, 8);
      expect(await repo.watchPlan(_tenant, 'missing').first, isNull);
    },
  );

  test('a deleted record is not shown', () async {
    await seedNode('a', '1');
    await (db.update(
      db.entityRecords,
    )..where((EntityRecords t) => t.id.equals('a'))).write(
      EntityRecordsCompanion(deletedAt: Value<DateTime?>(DateTime.utc(2027))),
    );
    expect((await plan()).nodes, isEmpty);
  });

  test('creating nodes offline stores them, numbers them and queues the POSTs in order', () async {
    goOffline();
    final String phase = await repo.createNode(
      _tenant,
      projectId: _project,
      title: 'Design',
      nodeType: WbsNodeType.phase,
    );
    final String child = await repo.createNode(
      _tenant,
      projectId: _project,
      title: 'Drawings',
      parentNodeId: phase,
      plannedHours: 16,
      startDate: DateTime.utc(2027, 1, 4),
      endDate: DateTime.utc(2027, 1, 8),
    );
    final String second = await repo.createNode(
      _tenant,
      projectId: _project,
      title: 'Review',
      parentNodeId: phase,
      nodeType: WbsNodeType.milestone,
      startDate: DateTime.utc(2027, 1, 9),
      endDate: DateTime.utc(2027, 1, 20),
    );

    final ProjectPlan p = await plan();
    expect(p.node(phase)!.wbsCode, '1');
    expect(p.node(child)!.wbsCode, '1.1');
    expect(p.node(second)!.wbsCode, '1.2');
    // The milestone has no span and no hours, and the summary rolled up the leaf.
    expect(p.node(second)!.endDate, DateTime.utc(2027, 1, 9));
    expect(p.node(phase)!.plannedHours, 16);
    expect(p.unsyncedIds, containsAll(<String>[phase, child, second]));

    final List<QueueItem> items = await queue();
    expect(items.map((QueueItem i) => i.method), everyElement('POST'));
    expect(
      items.map((QueueItem i) => i.path),
      everyElement('/projects/p1/wbs-nodes'),
    );
    expect(items.map((QueueItem i) => i.entityId), <String>[
      phase,
      child,
      second,
    ]);
    // A child waits for the create of its parent.
    expect(items[1].dependsOn, items[0].uuid);
    expect(items[0].dependsOn, isNull);
  });

  test('a flush after a write sends it and marks the record synced', () async {
    final String id = await repo.createNode(
      _tenant,
      projectId: _project,
      title: 'Online',
    );
    expect(await queue(), isEmpty);
    expect((await plan()).unsyncedIds, isNot(contains(id)));
    expect(adapter.calls.single.method, 'POST');
    expect(adapter.calls.single.headers['Idempotency-Key'], isNotNull);
  });

  test('invalid input is refused before it reaches the outbox', () async {
    goOffline();
    Future<void> expectKind(
      Future<Object?> action,
      PortfolioErrorKind kind,
    ) async {
      await expectLater(
        action,
        throwsA(
          isA<PortfolioException>().having(
            (PortfolioException e) => e.kind,
            'kind',
            kind,
          ),
        ),
      );
    }

    await expectKind(
      repo.createNode(_tenant, projectId: _project, title: '  '),
      PortfolioErrorKind.invalidTitle,
    );
    await expectKind(
      repo.createNode(
        _tenant,
        projectId: _project,
        title: 'x',
        startDate: DateTime.utc(2027, 1, 5),
        endDate: DateTime.utc(2027, 1, 1),
      ),
      PortfolioErrorKind.invalidDates,
    );
    await expectKind(
      repo.createNode(
        _tenant,
        projectId: _project,
        title: 'x',
        plannedCost: -1,
      ),
      PortfolioErrorKind.invalidAmount,
    );
    await expectKind(
      repo.createNode(
        _tenant,
        projectId: _project,
        title: 'x',
        parentNodeId: 'nope',
      ),
      PortfolioErrorKind.notFound,
    );
    await seedNode('a', '1');
    final WbsNode a = (await plan()).node('a')!;
    await expectKind(
      repo.updateNode(_tenant, a.copyWith(percentComplete: 101)),
      PortfolioErrorKind.invalidProgress,
    );
    expect(await queue(), isEmpty);
  });

  test('updating a node queues only the changed fields', () async {
    await seedNode('a', '1', start: '2027-01-01', end: '2027-01-03', hours: 8);
    goOffline();
    final WbsNode a = (await plan()).node('a')!;
    await repo.updateNode(
      _tenant,
      a.copyWith(percentComplete: 60, actualHours: 5),
    );

    final QueueItem put = (await queue()).single;
    expect(put.method, 'PUT');
    expect(put.path, '/projects/wbs-nodes/a');
    expect(jsonDecode(put.payload!), <String, dynamic>{
      'actual_hours': 5.0,
      'percent_complete': 60.0,
    });
    final WbsNode after = (await plan()).node('a')!;
    expect(after.percentComplete, 60);
    expect(after.actualHours, 5);

    // Saving the same values again queues nothing more.
    await repo.updateNode(_tenant, after);
    expect(await queue(), hasLength(1));
  });

  test(
    'editing a node that is still a pending create folds into the POST',
    () async {
      goOffline();
      final String id = await repo.createNode(
        _tenant,
        projectId: _project,
        title: 'Draft',
      );
      final WbsNode n = (await plan()).node(id)!;
      await repo.updateNode(_tenant, n.copyWith(title: 'Final'));
      final QueueItem only = (await queue()).single;
      expect(only.method, 'POST');
      expect(jsonDecode(only.payload!)['title'], 'Final');
    },
  );

  test('deleting a node removes its subtree and the links that touch it, deepest first', () async {
    await seedNode('a', '1');
    await seedNode('a1', '1.1', parent: 'a');
    await seedNode('b', '2');
    await seed(taskDependencyEntity, 'd1', <String, dynamic>{
      'project_id': _project,
      'predecessor_node_id': 'a1',
      'successor_node_id': 'b',
    });
    goOffline();
    await repo.deleteNode(_tenant, 'a');

    final ProjectPlan p = await plan();
    expect(p.nodes.map((WbsNode n) => n.id), <String>['b']);
    expect(p.dependencies, isEmpty);
    final List<String> paths = (await queue())
        .map((QueueItem i) => i.path)
        .toList();
    expect(paths, <String>[
      '/projects/task-dependencies/d1',
      '/projects/wbs-nodes/a1',
      '/projects/wbs-nodes/a',
    ]);
    await expectLater(
      repo.deleteNode(_tenant, 'ghost'),
      throwsA(isA<PortfolioException>()),
    );
  });

  test(
    'a dependency that closes a loop or repeats a link is refused',
    () async {
      await seedNode('a', '1', start: '2027-01-01', end: '2027-01-02');
      await seedNode('b', '2', start: '2027-01-01', end: '2027-01-02');
      await seedNode('c', '3', start: '2027-01-01', end: '2027-01-02');
      goOffline();
      await repo.addDependency(
        _tenant,
        projectId: _project,
        predecessorNodeId: 'a',
        successorNodeId: 'b',
      );
      await repo.addDependency(
        _tenant,
        projectId: _project,
        predecessorNodeId: 'b',
        successorNodeId: 'c',
        type: DependencyType.ss,
        lagDays: 2,
      );

      Future<void> expectKind(
        Future<Object?> action,
        PortfolioErrorKind kind,
      ) => expectLater(
        action,
        throwsA(
          isA<PortfolioException>().having(
            (PortfolioException e) => e.kind,
            'kind',
            kind,
          ),
        ),
      );

      await expectKind(
        repo.addDependency(
          _tenant,
          projectId: _project,
          predecessorNodeId: 'c',
          successorNodeId: 'a',
        ),
        PortfolioErrorKind.dependencyCycle,
      );
      await expectKind(
        repo.addDependency(
          _tenant,
          projectId: _project,
          predecessorNodeId: 'a',
          successorNodeId: 'a',
        ),
        PortfolioErrorKind.dependencyCycle,
      );
      await expectKind(
        repo.addDependency(
          _tenant,
          projectId: _project,
          predecessorNodeId: 'a',
          successorNodeId: 'b',
        ),
        PortfolioErrorKind.duplicateDependency,
      );
      await expectKind(
        repo.addDependency(
          _tenant,
          projectId: _project,
          predecessorNodeId: 'a',
          successorNodeId: 'zzz',
        ),
        PortfolioErrorKind.crossProject,
      );
      final List<QueueItem> items = await queue();
      expect(items, hasLength(2));
      expect(items.first.path, '/projects/p1/dependencies');
      final Map<String, dynamic> body =
          jsonDecode(items.last.payload!) as Map<String, dynamic>;
      expect(body['dependency_type'], 'ss');
      expect(body['lag_days'], 2);

      // The schedule of the plan already reflects the new links.
      final ProjectPlan p = await plan();
      expect(p.node('b')!.earlyStart, DateTime.utc(2027, 1, 3));
      expect(p.node('c')!.earlyStart, DateTime.utc(2027, 1, 5));
      expect(p.node('c')!.isCritical, isTrue);
    },
  );

  test('removing a dependency queues its DELETE', () async {
    await seedNode('a', '1');
    await seedNode('b', '2');
    await seed(taskDependencyEntity, 'd1', <String, dynamic>{
      'project_id': _project,
      'predecessor_node_id': 'a',
      'successor_node_id': 'b',
    });
    goOffline();
    await repo.removeDependency(_tenant, 'd1');
    expect((await plan()).dependencies, isEmpty);
    final QueueItem del = (await queue()).single;
    expect(del.method, 'DELETE');
    expect(del.path, '/projects/task-dependencies/d1');
  });

  test(
    'capturing a baseline numbers it, freezes the plan and queues it',
    () async {
      await seedNode(
        'a',
        '1',
        start: '2027-01-01',
        end: '2027-01-05',
        hours: 10,
      );
      goOffline();
      final String first = await repo.captureBaseline(
        _tenant,
        projectId: _project,
        name: 'Kick-off',
      );
      await repo.captureBaseline(_tenant, projectId: _project, name: '');
      final ProjectPlan p = await plan();
      expect(p.baselines.map((ProjectBaseline b) => b.baselineNumber), <int>[
        2,
        1,
      ]);
      expect(p.baselines.first.name, 'B2');
      final ProjectBaseline kickoff = p.baselines.firstWhere(
        (ProjectBaseline b) => b.id == first,
      );
      expect(kickoff.snapshotJson, contains('"wbs_code":"1"'));
      final QueueItem item = (await queue()).first;
      expect(item.path, '/projects/p1/baselines');
      expect(jsonDecode(item.payload!)['baseline_number'], 1);
    },
  );

  test('project edits validate CUP and CIG, normalize them and send only the changes', () async {
    goOffline();
    final Project project = (await plan()).project;
    await expectLater(
      repo.updateProject(_tenant, project.copyWith(cupCode: () => 'SHORT')),
      throwsA(
        isA<PortfolioException>().having(
          (PortfolioException e) => e.kind,
          'kind',
          PortfolioErrorKind.invalidCup,
        ),
      ),
    );
    await expectLater(
      repo.updateProject(_tenant, project.copyWith(cigCode: () => '123')),
      throwsA(
        isA<PortfolioException>().having(
          (PortfolioException e) => e.kind,
          'kind',
          PortfolioErrorKind.invalidCig,
        ),
      ),
    );
    await repo.updateProject(
      _tenant,
      project.copyWith(
        status: ProjectStatus.onHold,
        cupCode: () => 'b81b21000140001',
        cigCode: () => '8383838b2c',
      ),
    );
    final QueueItem put = (await queue()).single;
    expect(put.path, '/projects/p1');
    expect(jsonDecode(put.payload!), <String, dynamic>{
      'status': 'on_hold',
      'cup_code': 'B81B21000140001',
      'cig_code': '8383838B2C',
    });
    final Project after = (await plan()).project;
    expect(after.status, ProjectStatus.onHold);
    expect(after.cupCode, 'B81B21000140001');
  });

  test('sync flushes the outbox and pulls the four entities', () async {
    adapter.handler = (RequestOptions o) {
      if (o.path.startsWith('/mobile/sync/')) {
        return json(200, <String, dynamic>{
          'data': <String, dynamic>{
            'data': <dynamic>[],
            'deleted': <dynamic>[],
            'has_more': false,
            'server_time': '2027-01-01T00:00:00Z',
          },
        });
      }
      return json(200, <String, dynamic>{
        'data': <String, dynamic>{'id': 'srv'},
      });
    };
    final PortfolioSyncResult result = await repo.sync(_tenant);
    expect(result.status, PortfolioSyncStatus.synced);
    expect(
      adapter.calls.map((RequestOptions c) => c.path),
      portfolioEntities.map((String e) => '/mobile/sync/$e'),
    );
  });

  test('sync reports offline and a failed pull', () async {
    goOffline();
    expect((await repo.sync(_tenant)).status, PortfolioSyncStatus.offline);

    adapter.handler = (RequestOptions o) =>
        json(500, <String, dynamic>{'message': 'boom'});
    final PortfolioSyncResult failed = await repo.sync(_tenant);
    expect(failed.status, PortfolioSyncStatus.failed);
    expect(failed.pending, portfolioEntities.length);
  });
}
