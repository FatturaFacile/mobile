import 'package:dio/dio.dart';

import '../domain/resource_planning_models.dart';
import '../domain/resource_planning_repository.dart';

const String _base = '/resource-planning';

/// Rows requested by the project picker.
const int projectPageSize = 50;

/// Maps a transport error to a [ResourcePlanningException]; the RFC 7807 `detail` and the violations are kept.
ResourcePlanningException mapResourcePlanningError(DioException e) {
  final Response<dynamic>? r = e.response;
  if (r == null) {
    return const ResourcePlanningException(ResourcePlanningErrorKind.offline);
  }
  final dynamic body = r.data;
  String detail = '';
  List<ApiCode> violations = const <ApiCode>[];
  if (body is Map) {
    final dynamic d = body['detail'] ?? body['message'] ?? body['title'];
    detail = d is String ? d : '';
    final dynamic raw = body['invalid_params'];
    if (raw is List) {
      violations = <ApiCode>[
        for (final dynamic i in raw)
          if (i is Map) ApiCode.fromJson(Map<String, dynamic>.from(i)),
      ];
    }
  }
  return switch (r.statusCode) {
    403 => ResourcePlanningException(
      ResourcePlanningErrorKind.forbidden,
      detail: detail,
    ),
    404 => ResourcePlanningException(
      ResourcePlanningErrorKind.notFound,
      detail: detail,
    ),
    409 => ResourcePlanningException(
      ResourcePlanningErrorKind.conflict,
      detail: detail,
    ),
    422 => ResourcePlanningException(
      ResourcePlanningErrorKind.invalid,
      detail: detail,
      violations: violations,
    ),
    _ => ResourcePlanningException(
      ResourcePlanningErrorKind.unknown,
      detail: detail,
    ),
  };
}

/// REST client of `/api/v1/resource-planning`.
class ResourcePlanningRepositoryImpl implements ResourcePlanningRepository {
  ResourcePlanningRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<Skill>> skills({String? category}) async {
    final dynamic data = await _get(
      '$_base/skills',
      <String, dynamic>{'category': ?category},
    );
    return <Skill>[for (final Map<String, dynamic> m in _rows(data)) Skill.fromJson(m)];
  }

  @override
  Future<List<EmployeeSkillProfile>> skillProfiles({
    String? employeeId,
    String? skillId,
  }) async {
    final dynamic data = await _get(
      '$_base/employee-skill-profiles',
      <String, dynamic>{'employee_id': ?employeeId, 'skill_id': ?skillId},
    );
    return <EmployeeSkillProfile>[
      for (final Map<String, dynamic> m in _rows(data))
        EmployeeSkillProfile.fromJson(m),
    ];
  }

  @override
  Future<List<ResourceAllocation>> allocations({
    required String from,
    required String to,
    String? employeeId,
    String? projectId,
    BookingType? bookingType,
  }) async {
    final dynamic data = await _get('$_base/allocations', <String, dynamic>{
      'from': from,
      'to': to,
      'employee_id': ?employeeId,
      'project_id': ?projectId,
      'booking_type': ?bookingType?.wire,
    });
    return <ResourceAllocation>[
      for (final Map<String, dynamic> m in _rows(data))
        ResourceAllocation.fromJson(m),
    ];
  }

  @override
  Future<AllocationMutationResult> convertToHard(
    String allocationId, {
    String? projectId,
    String? wbsNodeId,
  }) async {
    final dynamic data = await _post(
      '$_base/allocations/$allocationId/convert-to-hard',
      <String, dynamic>{'project_id': ?projectId, 'wbs_node_id': ?wbsNodeId},
    );
    return AllocationMutationResult.fromJson(_object(data));
  }

  @override
  Future<AllocationMutationResult> rebalance(
    String allocationId,
    RebalanceRequest request,
  ) async {
    final dynamic data = await _post(
      '$_base/allocations/$allocationId/rebalance',
      request.toJson(),
    );
    return AllocationMutationResult.fromJson(_object(data));
  }

  @override
  Future<CapacityHeatmap> heatmap({
    required String from,
    required String to,
    String granularity = 'week',
    String? departmentId,
    List<String> employeeIds = const <String>[],
  }) async {
    final dynamic data = await _get('$_base/capacity/heatmap', <String, dynamic>{
      'from': from,
      'to': to,
      'granularity': granularity,
      'department_id': ?departmentId,
      if (employeeIds.isNotEmpty) 'employee_id[]': employeeIds,
    });
    return CapacityHeatmap.fromJson(_object(data));
  }

  @override
  Future<List<ResourceCapacitySnapshot>> snapshots({
    required String from,
    required String to,
    String? employeeId,
  }) async {
    final dynamic data = await _get(
      '$_base/capacity/snapshots',
      <String, dynamic>{'from': from, 'to': to, 'employee_id': ?employeeId},
    );
    return <ResourceCapacitySnapshot>[
      for (final Map<String, dynamic> m in _rows(data))
        ResourceCapacitySnapshot.fromJson(m),
    ];
  }

  @override
  Future<List<Candidate>> searchCandidates(CandidateQuery query) async {
    final dynamic data = await _post('$_base/candidates/search', query.toJson());
    return <Candidate>[
      for (final Map<String, dynamic> m in _rows(data)) Candidate.fromJson(m),
    ];
  }

  @override
  Future<UtilizationReport> utilization({
    required String from,
    required String to,
    UtilizationGroup groupBy = UtilizationGroup.resource,
  }) async {
    final dynamic data = await _get(
      '$_base/reports/billable-utilization',
      <String, dynamic>{'from': from, 'to': to, 'group_by': groupBy.wire},
    );
    return UtilizationReport.fromJson(_object(data));
  }

  // --- Lookups -----------------------------------------------------------------------------------------------------

  @override
  Future<List<ResourceLookup>> resources({String? departmentId}) async {
    final dynamic data = await _get('$_base/resources', <String, dynamic>{
      'department_id': ?departmentId,
    });
    return <ResourceLookup>[
      for (final Map<String, dynamic> m in _rows(data))
        ResourceLookup.fromJson(m),
    ];
  }

  @override
  Future<List<ProjectRef>> projects({String? search}) async {
    final String term = search?.trim() ?? '';
    final dynamic data = await _get('/projects', <String, dynamic>{
      if (term.isNotEmpty) 'search': term,
      'per_page': projectPageSize,
    });
    // The list endpoint is paginated: the rows are the `data` list of the envelope.
    return <ProjectRef>[
      for (final Map<String, dynamic> m in _rows(data)) ProjectRef.fromJson(m),
    ];
  }

  // --- Allocation writes -------------------------------------------------------------------------------------------

  @override
  Future<AllocationMutationResult> createAllocation(
    AllocationDraft draft,
  ) async {
    final dynamic data = await _post('$_base/allocations', draft.toJson());
    return AllocationMutationResult.fromJson(_object(data));
  }

  @override
  Future<void> deleteAllocation(String allocationId) =>
      _delete('$_base/allocations/$allocationId');

  // --- Skills and profiles -----------------------------------------------------------------------------------------

  @override
  Future<Skill> createSkill(SkillDraft draft) async =>
      Skill.fromJson(_object(await _post('$_base/skills', draft.toJson())));

  @override
  Future<Skill> updateSkill(String skillId, SkillDraft draft) async =>
      Skill.fromJson(
        _object(await _put('$_base/skills/$skillId', draft.toJson())),
      );

  @override
  Future<void> deleteSkill(String skillId) => _delete('$_base/skills/$skillId');

  @override
  Future<EmployeeSkillProfile> saveSkillProfile(
    SkillProfileDraft draft,
  ) async => EmployeeSkillProfile.fromJson(
    _object(await _post('$_base/employee-skill-profiles', draft.toJson())),
  );

  @override
  Future<void> deleteSkillProfile(String profileId) =>
      _delete('$_base/employee-skill-profiles/$profileId');

  // --- Targets and holidays ----------------------------------------------------------------------------------------

  @override
  Future<List<UtilizationTarget>> utilizationTargets() async {
    final dynamic data = await _get(
      '$_base/utilization-targets',
      <String, dynamic>{},
    );
    return <UtilizationTarget>[
      for (final Map<String, dynamic> m in _rows(data))
        UtilizationTarget.fromJson(m),
    ];
  }

  @override
  Future<UtilizationTarget> saveUtilizationTarget(
    UtilizationTargetDraft draft,
  ) async => UtilizationTarget.fromJson(
    _object(await _put('$_base/utilization-targets', draft.toJson())),
  );

  @override
  Future<List<LocalHoliday>> localHolidays() async {
    final dynamic data = await _get('$_base/local-holidays', <String, dynamic>{});
    return <LocalHoliday>[
      for (final Map<String, dynamic> m in _rows(data)) LocalHoliday.fromJson(m),
    ];
  }

  @override
  Future<LocalHoliday> addLocalHoliday(LocalHolidayDraft draft) async =>
      LocalHoliday.fromJson(
        _object(await _post('$_base/local-holidays', draft.toJson())),
      );

  @override
  Future<void> deleteLocalHoliday(String holidayId) =>
      _delete('$_base/local-holidays/$holidayId');

  // --- Transport ---------------------------------------------------------------------------------------------------

  Future<dynamic> _get(String path, Map<String, dynamic> query) =>
      _send(() => _dio.get<dynamic>(path, queryParameters: query));

  Future<dynamic> _post(String path, Map<String, dynamic> body) =>
      _send(() => _dio.post<dynamic>(path, data: body));

  Future<dynamic> _put(String path, Map<String, dynamic> body) =>
      _send(() => _dio.put<dynamic>(path, data: body));

  Future<dynamic> _delete(String path) =>
      _send(() => _dio.delete<dynamic>(path));

  /// Returns the `data` member of the envelope.
  Future<dynamic> _send(Future<Response<dynamic>> Function() run) async {
    try {
      final Response<dynamic> res = await run();
      final dynamic body = res.data;
      return body is Map ? body['data'] : null;
    } on DioException catch (e) {
      throw mapResourcePlanningError(e);
    }
  }

  List<Map<String, dynamic>> _rows(dynamic data) => <Map<String, dynamic>>[
    if (data is List)
      for (final dynamic e in data)
        if (e is Map) Map<String, dynamic>.from(e),
  ];

  Map<String, dynamic> _object(dynamic data) {
    if (data is! Map) {
      throw const ResourcePlanningException(
        ResourcePlanningErrorKind.unknown,
        detail: 'no data',
      );
    }
    return Map<String, dynamic>.from(data);
  }
}
