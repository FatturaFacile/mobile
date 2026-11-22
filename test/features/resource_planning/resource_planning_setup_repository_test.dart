import 'package:dio/dio.dart';
import 'package:fattura_facile/features/resource_planning/data/resource_planning_repository_impl.dart';
import 'package:fattura_facile/features/resource_planning/domain/resource_planning_models.dart';
import 'package:fattura_facile/features/resource_planning/domain/resource_planning_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/sync_engine_test.dart' show FakeAdapter, json;
import 'fakes.dart';

Map<String, dynamic> envelope(Object? data) => <String, dynamic>{
  'success': true,
  'message': 'ok',
  'data': data,
};

ResponseBody noContent() => ResponseBody.fromString('', 204);

void main() {
  late FakeAdapter adapter;
  late ResourcePlanningRepositoryImpl repo;

  setUp(() {
    adapter = FakeAdapter((RequestOptions o) => json(200, envelope(<dynamic>[])));
    final Dio dio = Dio(
      BaseOptions(
        baseUrl: 'http://x/api/v1',
        validateStatus: (int? s) => s != null && s < 300,
      ),
    )..httpClientAdapter = adapter;
    repo = ResourcePlanningRepositoryImpl(dio);
  });

  RequestOptions only() => adapter.calls.single;

  group('lookups', () {
    test('resources are read from the module and parsed', () async {
      adapter.handler = (RequestOptions o) => json(
        200,
        envelope(<Map<String, dynamic>>[resourceJson('e1', 'Anna Rossi')]),
      );

      final List<ResourceLookup> rows = await repo.resources(departmentId: 'd1');

      expect(only().method, 'GET');
      expect(only().path, '/resource-planning/resources');
      expect(only().queryParameters['department_id'], 'd1');
      expect(rows.single.fullName, 'Anna Rossi');
    });

    test('projects are searched on the projects endpoint, not on the module', () async {
      adapter.handler = (RequestOptions o) => json(
        200,
        envelope(<Map<String, dynamic>>[
          <String, dynamic>{'id': 'p1', 'project_number': 'P-001', 'name': 'Relaunch'},
        ]),
      );

      final List<ProjectRef> rows = await repo.projects(search: ' relaunch ');

      expect(only().path, '/projects');
      expect(only().queryParameters['search'], 'relaunch');
      expect(only().queryParameters['per_page'], projectPageSize);
      expect(rows.single.label, 'P-001 - Relaunch');
    });

    test('a project listing without a term sends no search parameter', () async {
      await repo.projects();

      expect(only().queryParameters.containsKey('search'), isFalse);
    });

    test('a refused project listing is a forbidden error the picker can fall back from', () async {
      adapter.handler = (RequestOptions o) => json(403, <String, dynamic>{'detail': 'no'});

      await expectLater(
        repo.projects(),
        throwsA(
          isA<ResourcePlanningException>().having(
            (ResourcePlanningException e) => e.kind,
            'kind',
            ResourcePlanningErrorKind.forbidden,
          ),
        ),
      );
    });
  });

  group('allocations', () {
    test('creating posts the draft and returns the verdict', () async {
      adapter.handler = (RequestOptions o) => json(
        201,
        envelope(
          mutationJson(
            <Map<String, dynamic>>[allocationJson('a9')],
            warnings: <Map<String, dynamic>>[
              <String, dynamic>{'code': 'skill_missing', 'params': <String, dynamic>{'skill_id': 's1'}},
            ],
          ),
        ),
      );

      final AllocationMutationResult r = await repo.createAllocation(
        const AllocationDraft(
          employeeId: 'e1',
          bookingType: BookingType.hardCommitted,
          startDate: '2030-03-04',
          endDate: '2030-03-08',
          allocatedHoursPerDay: 4,
          projectId: 'p1',
          requiredSkillIds: <String>['s1'],
        ),
      );

      expect(only().method, 'POST');
      expect(only().path, '/resource-planning/allocations');
      final Map<String, dynamic> body = only().data as Map<String, dynamic>;
      expect(body['employee_id'], 'e1');
      expect(body['booking_type'], 'HardCommitted');
      expect(body['project_id'], 'p1');
      expect(body['required_skill_ids'], <String>['s1']);
      expect(r.allocation.id, 'a9');
      expect(r.warnings.single.code, 'skill_missing');
    });

    test('deleting sends a DELETE and accepts the empty 204 answer', () async {
      adapter.handler = (RequestOptions o) => noContent();

      await repo.deleteAllocation('a1');

      expect(only().method, 'DELETE');
      expect(only().path, '/resource-planning/allocations/a1');
    });

    test('a rebalance resize sends only the fields that change', () async {
      adapter.handler = (RequestOptions o) => json(
        200,
        envelope(mutationJson(<Map<String, dynamic>>[allocationJson('a1')])),
      );

      await repo.rebalance(
        'a1',
        const RebalanceRequest(
          strategy: RebalanceStrategy.resize,
          endDate: '2030-03-15',
          allocatedHoursPerDay: 6,
        ),
      );

      expect(only().data, <String, dynamic>{
        'strategy': 'resize',
        'end_date': '2030-03-15',
        'allocated_hours_per_day': 6.0,
      });
    });

    test('a split returns both parts', () async {
      adapter.handler = (RequestOptions o) => json(
        200,
        envelope(
          mutationJson(<Map<String, dynamic>>[
            allocationJson('a1', end: '2030-03-05'),
            allocationJson('a2', start: '2030-03-06', employeeId: 'e2', employeeName: 'Bruno Bianchi'),
          ]),
        ),
      );

      final AllocationMutationResult r = await repo.rebalance(
        'a1',
        const RebalanceRequest(
          strategy: RebalanceStrategy.split,
          splitDate: '2030-03-06',
          employeeId: 'e2',
        ),
      );

      expect(only().data, <String, dynamic>{
        'strategy': 'split',
        'employee_id': 'e2',
        'split_date': '2030-03-06',
      });
      expect(r.allocations.map((ResourceAllocation a) => a.id), <String>['a1', 'a2']);
    });

    test('converting a soft booking with only an opportunity sends the picked project', () async {
      adapter.handler = (RequestOptions o) => json(
        200,
        envelope(
          mutationJson(<Map<String, dynamic>>[allocationJson('a3', type: 'HardCommitted')]),
        ),
      );

      await repo.convertToHard('a3', projectId: uuidA);

      expect(only().path, '/resource-planning/allocations/a3/convert-to-hard');
      expect(only().data, <String, dynamic>{'project_id': uuidA});
    });

    test('a refused create keeps the violation codes', () async {
      adapter.handler = (RequestOptions o) => ResponseBody.fromString(
        '{"detail":"no","invalid_params":[{"code":"overload","params":{}}]}',
        422,
        headers: <String, List<String>>{
          Headers.contentTypeHeader: <String>[Headers.jsonContentType],
        },
      );

      await expectLater(
        repo.createAllocation(
          const AllocationDraft(
            employeeId: 'e1',
            bookingType: BookingType.softTentative,
            startDate: '2030-03-04',
            endDate: '2030-03-08',
            allocatedHoursPerDay: 4,
            projectId: 'p1',
            allowOverload: false,
          ),
        ),
        throwsA(
          isA<ResourcePlanningException>()
              .having((ResourcePlanningException e) => e.kind, 'kind', ResourcePlanningErrorKind.invalid)
              .having((ResourcePlanningException e) => e.violations.single.code, 'code', 'overload'),
        ),
      );
    });
  });

  group('skills and profiles', () {
    test('creating a skill posts the draft', () async {
      adapter.handler = (RequestOptions o) => json(
        201,
        envelope(skillJson('s1', 'Forklift', category: 'HSE', cert: true, code: 'FORK')),
      );

      final Skill k = await repo.createSkill(
        const SkillDraft(
          category: 'HSE',
          skillName: 'Forklift',
          requiresCertification: true,
          certificationCode: 'FORK',
        ),
      );

      expect(only().method, 'POST');
      expect(only().path, '/resource-planning/skills');
      expect(only().data, <String, dynamic>{
        'category': 'HSE',
        'skill_name': 'Forklift',
        'requires_certification': true,
        'certification_code': 'FORK',
      });
      expect(k.certificationCode, 'FORK');
    });

    test('updating a skill puts to its id', () async {
      adapter.handler = (RequestOptions o) =>
          json(200, envelope(skillJson('s1', 'Flutter 3')));

      final Skill k = await repo.updateSkill(
        's1',
        const SkillDraft(category: 'Engineering', skillName: 'Flutter 3'),
      );

      expect(only().method, 'PUT');
      expect(only().path, '/resource-planning/skills/s1');
      expect(k.skillName, 'Flutter 3');
    });

    test('deleting a skill sends a DELETE', () async {
      adapter.handler = (RequestOptions o) => noContent();

      await repo.deleteSkill('s1');

      expect(only().method, 'DELETE');
      expect(only().path, '/resource-planning/skills/s1');
    });

    test('a profile is upserted with a POST and parsed with its certificate verdict', () async {
      adapter.handler = (RequestOptions o) => json(
        200,
        envelope(profileJson('pr1', level: 5, cert: true, certStatus: 'expired', validUntil: '2031-01-31')),
      );

      final EmployeeSkillProfile p = await repo.saveSkillProfile(
        const SkillProfileDraft(
          employeeId: 'e1',
          skillId: 's1',
          proficiencyLevel: 5,
          validUntilDate: '2031-01-31',
        ),
      );

      expect(only().method, 'POST');
      expect(only().path, '/resource-planning/employee-skill-profiles');
      expect(only().data, <String, dynamic>{
        'employee_id': 'e1',
        'skill_id': 's1',
        'proficiency_level': 5,
        'valid_until_date': '2031-01-31',
      });
      expect(p.certificationStatus, CertificationStatus.expired);
    });

    test('deleting a profile sends a DELETE', () async {
      adapter.handler = (RequestOptions o) => noContent();

      await repo.deleteSkillProfile('pr1');

      expect(only().method, 'DELETE');
      expect(only().path, '/resource-planning/employee-skill-profiles/pr1');
    });
  });

  group('targets and holidays', () {
    test('targets are listed', () async {
      adapter.handler = (RequestOptions o) => json(
        200,
        envelope(<Map<String, dynamic>>[
          <String, dynamic>{'id': 't1', 'department_id': null, 'cost_center_id': null, 'target_percent': 70},
          <String, dynamic>{'id': 't2', 'department_id': 'd1', 'cost_center_id': null, 'target_percent': 80},
        ]),
      );

      final List<UtilizationTarget> rows = await repo.utilizationTargets();

      expect(only().path, '/resource-planning/utilization-targets');
      expect(rows.first.isDefault, isTrue);
      expect(rows.last.departmentId, 'd1');
    });

    test('a target is upserted with a PUT', () async {
      adapter.handler = (RequestOptions o) => json(
        200,
        envelope(<String, dynamic>{'id': 't2', 'department_id': 'd1', 'cost_center_id': null, 'target_percent': 82.5}),
      );

      final UtilizationTarget t = await repo.saveUtilizationTarget(
        const UtilizationTargetDraft(targetPercent: 82.5, departmentId: 'd1'),
      );

      expect(only().method, 'PUT');
      expect(only().path, '/resource-planning/utilization-targets');
      expect(only().data, <String, dynamic>{'department_id': 'd1', 'target_percent': 82.5});
      expect(t.targetPercent, 82.5);
    });

    test('local holidays are listed, added and removed', () async {
      adapter.handler = (RequestOptions o) => json(
        200,
        envelope(<Map<String, dynamic>>[
          <String, dynamic>{'id': 'h1', 'country': 'CH', 'month': 3, 'day': 19, 'year': null, 'name': 'San Giuseppe', 'day_fraction': 1},
        ]),
      );
      final List<LocalHoliday> rows = await repo.localHolidays();
      expect(only().path, '/resource-planning/local-holidays');
      expect(rows.single.name, 'San Giuseppe');

      adapter.calls.clear();
      adapter.handler = (RequestOptions o) => json(
        201,
        envelope(<String, dynamic>{'id': 'h2', 'country': 'IT', 'month': 12, 'day': 24, 'year': 2030, 'name': 'Closing', 'day_fraction': 0.5}),
      );
      final LocalHoliday added = await repo.addLocalHoliday(
        const LocalHolidayDraft(country: 'IT', month: 12, day: 24, year: 2030, name: 'Closing', dayFraction: 0.5),
      );
      expect(only().method, 'POST');
      expect(only().path, '/resource-planning/local-holidays');
      expect(only().data, <String, dynamic>{
        'country': 'IT',
        'month': 12,
        'day': 24,
        'year': 2030,
        'name': 'Closing',
        'day_fraction': 0.5,
      });
      expect(added.id, 'h2');

      adapter.calls.clear();
      adapter.handler = (RequestOptions o) => noContent();
      await repo.deleteLocalHoliday('h2');
      expect(only().method, 'DELETE');
      expect(only().path, '/resource-planning/local-holidays/h2');
    });

    test('a missing holiday on delete is a not-found error', () async {
      adapter.handler = (RequestOptions o) => json(404, <String, dynamic>{'detail': 'gone'});

      await expectLater(
        repo.deleteLocalHoliday('zz'),
        throwsA(
          isA<ResourcePlanningException>().having(
            (ResourcePlanningException e) => e.kind,
            'kind',
            ResourcePlanningErrorKind.notFound,
          ),
        ),
      );
    });
  });
}
