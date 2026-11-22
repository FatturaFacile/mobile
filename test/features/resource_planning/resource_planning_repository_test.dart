import 'package:dio/dio.dart';
import 'package:fattura_facile/features/resource_planning/data/resource_planning_repository_impl.dart';
import 'package:fattura_facile/features/resource_planning/domain/resource_planning_models.dart';
import 'package:fattura_facile/features/resource_planning/domain/resource_planning_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/sync_engine_test.dart' show FakeAdapter, json;
import 'fakes.dart';

Map<String, dynamic> envelope(Object data) => <String, dynamic>{
  'success': true,
  'message': 'ok',
  'data': data,
};

void main() {
  late FakeAdapter adapter;
  late ResourcePlanningRepositoryImpl repo;

  setUp(() {
    adapter = FakeAdapter(
      (RequestOptions o) => json(200, envelope(<dynamic>[])),
    );
    final Dio dio = Dio(
      BaseOptions(
        baseUrl: 'http://x/api/v1',
        validateStatus: (int? s) => s != null && s < 300,
      ),
    )..httpClientAdapter = adapter;
    repo = ResourcePlanningRepositoryImpl(dio);
  });

  group('reads', () {
    test('the heatmap is requested with the window and the granularity and parsed', () async {
      adapter.handler = (RequestOptions o) => json(200, envelope(heatmapJson()));

      final CapacityHeatmap map = await repo.heatmap(
        from: '2030-03-04',
        to: '2030-03-24',
        departmentId: 'd1',
        employeeIds: <String>['e1', 'e2'],
      );

      final RequestOptions call = adapter.calls.single;
      expect(call.method, 'GET');
      expect(call.path, '/resource-planning/capacity/heatmap');
      expect(call.queryParameters['from'], '2030-03-04');
      expect(call.queryParameters['to'], '2030-03-24');
      expect(call.queryParameters['granularity'], 'week');
      expect(call.queryParameters['department_id'], 'd1');
      expect(call.queryParameters['employee_id[]'], <String>['e1', 'e2']);
      expect(map.rows, hasLength(2));
    });

    test('empty optional filters are not sent', () async {
      adapter.handler = (RequestOptions o) => json(200, envelope(heatmapJson()));

      await repo.heatmap(from: '2030-03-04', to: '2030-03-24');

      final Map<String, dynamic> q = adapter.calls.single.queryParameters;
      expect(q.containsKey('department_id'), isFalse);
      expect(q.containsKey('employee_id[]'), isFalse);
    });

    test('allocations are filtered by the window and the booking type', () async {
      adapter.handler = (RequestOptions o) => json(
        200,
        envelope(<Map<String, dynamic>>[
          allocationJson('a1'),
          allocationJson('a2', type: 'HardCommitted'),
        ]),
      );

      final List<ResourceAllocation> rows = await repo.allocations(
        from: '2030-03-01',
        to: '2030-04-30',
        bookingType: BookingType.hardCommitted,
        employeeId: 'e1',
      );

      final RequestOptions call = adapter.calls.single;
      expect(call.path, '/resource-planning/allocations');
      expect(call.queryParameters['booking_type'], 'HardCommitted');
      expect(call.queryParameters['employee_id'], 'e1');
      expect(rows.map((ResourceAllocation a) => a.id), <String>['a1', 'a2']);
      expect(rows.last.bookingType, BookingType.hardCommitted);
    });

    test('skills and profiles are parsed from the envelope', () async {
      adapter.handler = (RequestOptions o) => json(
        200,
        envelope(<Map<String, dynamic>>[
          <String, dynamic>{
            'id': 's1',
            'category': 'Dev',
            'skill_name': 'Flutter',
            'requires_certification': false,
            'certification_code': null,
          },
        ]),
      );

      final List<Skill> skills = await repo.skills(category: 'Dev');

      expect(adapter.calls.single.path, '/resource-planning/skills');
      expect(adapter.calls.single.queryParameters['category'], 'Dev');
      expect(skills.single.skillName, 'Flutter');

      adapter.handler = (RequestOptions o) => json(
        200,
        envelope(<Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'p1',
            'employee_id': 'e1',
            'employee_name': 'Anna',
            'skill_id': 's1',
            'skill_name': 'Flutter',
            'category': 'Dev',
            'proficiency_level': 5,
            'certification_status': 'not_required',
          },
        ]),
      );

      final List<EmployeeSkillProfile> profiles = await repo.skillProfiles(
        employeeId: 'e1',
      );

      expect(
        adapter.calls.last.path,
        '/resource-planning/employee-skill-profiles',
      );
      expect(profiles.single.proficiencyLevel, 5);
    });

    test('the billable utilization is grouped as requested', () async {
      adapter.handler = (RequestOptions o) =>
          json(200, envelope(utilizationJson()));

      final UtilizationReport report = await repo.utilization(
        from: '2030-03-01',
        to: '2030-03-31',
        groupBy: UtilizationGroup.costCenter,
      );

      final RequestOptions call = adapter.calls.single;
      expect(call.path, '/resource-planning/reports/billable-utilization');
      expect(call.queryParameters['group_by'], 'cost_center');
      expect(report.rows, hasLength(2));
    });

    test('snapshots are read for the window', () async {
      adapter.handler = (RequestOptions o) => json(
        200,
        envelope(<Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'n1',
            'employee_id': 'e1',
            'week_start_date': '2030-03-04',
            'utilization_rate_percent': 55,
          },
        ]),
      );

      final List<ResourceCapacitySnapshot> rows = await repo.snapshots(
        from: '2030-03-01',
        to: '2030-03-31',
      );

      expect(adapter.calls.single.path, '/resource-planning/capacity/snapshots');
      expect(rows.single.utilizationRatePercent, 55);
    });
  });

  group('writes', () {
    test('convert to hard posts to the allocation and returns the verdict', () async {
      adapter.handler = (RequestOptions o) => json(
        200,
        envelope(
          mutationJson(<Map<String, dynamic>>[
            allocationJson('a1', type: 'HardCommitted'),
          ], overloaded: true, peak: 110),
        ),
      );

      final AllocationMutationResult r = await repo.convertToHard(
        'a1',
        projectId: 'p1',
      );

      final RequestOptions call = adapter.calls.single;
      expect(call.method, 'POST');
      expect(call.path, '/resource-planning/allocations/a1/convert-to-hard');
      expect(call.data, <String, dynamic>{'project_id': 'p1'});
      expect(r.allocation.bookingType, BookingType.hardCommitted);
      expect(r.overload.isOverloaded, isTrue);
    });

    test('rebalance posts the strategy body and returns every affected row', () async {
      adapter.handler = (RequestOptions o) => json(
        200,
        envelope(
          mutationJson(<Map<String, dynamic>>[
            allocationJson('a1', start: '2030-03-11', end: '2030-03-15'),
          ]),
        ),
      );

      final AllocationMutationResult r = await repo.rebalance(
        'a1',
        const RebalanceRequest.shiftBy(7),
      );

      final RequestOptions call = adapter.calls.single;
      expect(call.path, '/resource-planning/allocations/a1/rebalance');
      expect(call.data, <String, dynamic>{'strategy': 'shift', 'shift_days': 7});
      expect(r.allocations.single.startDate, '2030-03-11');
    });

    test('a candidate search posts the query and parses the ranking', () async {
      adapter.handler = (RequestOptions o) => json(
        200,
        envelope(<Map<String, dynamic>>[
          candidateJson('e1', 'Anna'),
          candidateJson('e2', 'Bruno', score: 60),
        ]),
      );

      final List<Candidate> found = await repo.searchCandidates(
        const CandidateQuery(
          startDate: '2030-03-04',
          endDate: '2030-03-29',
          allocatedHoursPerDay: 4,
          requirements: <SkillRequirement>[
            SkillRequirement(skillId: 's1', minLevel: 3),
          ],
        ),
      );

      final RequestOptions call = adapter.calls.single;
      expect(call.method, 'POST');
      expect(call.path, '/resource-planning/candidates/search');
      expect((call.data as Map<String, dynamic>)['allocated_hours_per_day'], 4);
      expect(found.map((Candidate c) => c.employeeId), <String>['e1', 'e2']);
    });
  });

  group('errors', () {
    Future<ResourcePlanningException> failing(
      int status, {
      List<Map<String, dynamic>>? violations,
    }) async {
      adapter.handler = (RequestOptions o) => ResponseBody.fromString(
        '{"title":"Problem","detail":"why","status":$status${violations == null ? '' : ',"invalid_params":[{"code":"${violations.first['code']}","params":{}}]'}}',
        status,
        headers: <String, List<String>>{
          Headers.contentTypeHeader: <String>[Headers.jsonContentType],
        },
      );
      try {
        await repo.convertToHard('a1');
      } on ResourcePlanningException catch (e) {
        return e;
      }
      fail('expected a ResourcePlanningException');
    }

    test('the status codes map to the error kinds', () async {
      expect(
        (await failing(403)).kind,
        ResourcePlanningErrorKind.forbidden,
      );
      expect((await failing(404)).kind, ResourcePlanningErrorKind.notFound);
      expect((await failing(409)).kind, ResourcePlanningErrorKind.conflict);
      expect((await failing(500)).kind, ResourcePlanningErrorKind.unknown);
    });

    test('a 422 keeps the detail and the violation codes', () async {
      final ResourcePlanningException e = await failing(
        422,
        violations: <Map<String, dynamic>>[
          <String, dynamic>{'code': 'already_hard_committed'},
        ],
      );

      expect(e.kind, ResourcePlanningErrorKind.invalid);
      expect(e.detail, 'why');
      expect(e.violations.single.code, 'already_hard_committed');
    });

    test('a transport failure without a response is offline', () {
      expect(
        mapResourcePlanningError(
          DioException(requestOptions: RequestOptions(path: '/x')),
        ).kind,
        ResourcePlanningErrorKind.offline,
      );
    });

    test('an answer without data on an object endpoint is an error', () async {
      adapter.handler = (RequestOptions o) =>
          json(200, <String, dynamic>{'success': true});

      expect(
        () => repo.heatmap(from: '2030-03-04', to: '2030-03-10'),
        throwsA(isA<ResourcePlanningException>()),
      );
    });
  });
}
