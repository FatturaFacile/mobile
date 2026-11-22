import 'package:fattura_facile/features/resource_planning/domain/resource_planning_models.dart';
import 'package:fattura_facile/features/resource_planning/domain/resource_planning_repository.dart';

Map<String, dynamic> cellJson(
  String periodStart, {
  double net = 40,
  double hard = 20,
  double soft = 0,
  double load = 50,
  String band = 'green',
  bool overloaded = false,
}) => <String, dynamic>{
  'period_start': periodStart,
  'contractual_hours': 40,
  'leave_and_holiday_hours': 40 - net,
  'net_available_hours': net,
  'hard_booked_hours': hard,
  'soft_booked_hours': soft,
  'billable_booked_hours': hard,
  'internal_booked_hours': soft,
  'load_percent': load,
  'band': band,
  'is_overloaded': overloaded,
};

Map<String, dynamic> rowJson(
  String id,
  String name,
  List<Map<String, dynamic>> cells,
) => <String, dynamic>{
  'employee_id': id,
  'employee_name': name,
  'department_id': 'd1',
  'department_name': 'Engineering',
  'cost_center_id': 'c1',
  'weekly_contract_hours': 40,
  'cells': cells,
};

Map<String, dynamic> heatmapJson() => <String, dynamic>{
  'from': '2030-03-04',
  'to': '2030-03-24',
  'granularity': 'week',
  'thresholds': <String, dynamic>{'yellow': 80, 'red': 100},
  'periods': <String>['2030-03-04', '2030-03-11'],
  'rows': <Map<String, dynamic>>[
    rowJson('e1', 'Anna Rossi', <Map<String, dynamic>>[
      cellJson('2030-03-04', hard: 20, load: 50),
      cellJson('2030-03-11', hard: 30, soft: 6, load: 90, band: 'yellow'),
    ]),
    rowJson('e2', 'Bruno Bianchi', <Map<String, dynamic>>[
      cellJson(
        '2030-03-04',
        hard: 40,
        soft: 8,
        load: 120,
        band: 'red',
        overloaded: true,
      ),
      cellJson('2030-03-11', hard: 10, load: 25),
    ]),
  ],
};

Map<String, dynamic> allocationJson(
  String id, {
  String type = 'SoftTentative',
  String? projectId = 'p1',
  String employeeId = 'e1',
  String employeeName = 'Anna Rossi',
  String start = '2030-03-04',
  String end = '2030-03-08',
  bool overloaded = false,
  double peak = 50,
}) => <String, dynamic>{
  'id': id,
  'project_id': projectId,
  'project_name': projectId == null ? null : 'Website relaunch',
  'wbs_node_id': null,
  'wbs_node_title': null,
  'employee_id': employeeId,
  'employee_name': employeeName,
  'role_id': null,
  'booking_type': type,
  'start_date': start,
  'end_date': end,
  'allocated_hours_per_day': 4,
  'total_allocated_hours': 20,
  'is_billable': true,
  'crm_opportunity_id': projectId == null ? 'o1' : null,
  'crm_opportunity_name': projectId == null ? 'Big deal' : null,
  'is_overloaded': overloaded,
  'peak_load_percent': peak,
  'notes': null,
};

Map<String, dynamic> mutationJson(
  List<Map<String, dynamic>> allocations, {
  bool overloaded = false,
  double peak = 70,
  List<Map<String, dynamic>> warnings = const <Map<String, dynamic>>[],
}) => <String, dynamic>{
  'allocation': allocations.first,
  'allocations': allocations,
  'overload': <String, dynamic>{
    'is_overloaded': overloaded,
    'peak_load_percent': peak,
    'weeks': overloaded
        ? <Map<String, dynamic>>[
            <String, dynamic>{'week_start': '2030-03-04', 'load_percent': peak},
          ]
        : <Map<String, dynamic>>[],
  },
  'warnings': warnings,
};

ResourceAllocation fakeAllocation(
  String id, {
  String type = 'SoftTentative',
  String? projectId = 'p1',
  String start = '2030-03-04',
  String end = '2030-03-08',
  String employeeName = 'Anna Rossi',
}) => ResourceAllocation.fromJson(
  allocationJson(
    id,
    type: type,
    projectId: projectId,
    start: start,
    end: end,
    employeeName: employeeName,
  ),
);

Map<String, dynamic> candidateJson(
  String id,
  String name, {
  double score = 80,
  bool eligible = true,
  List<Map<String, dynamic>> blockers = const <Map<String, dynamic>>[],
  double peakAfter = 70,
}) => <String, dynamic>{
  'employee_id': id,
  'employee_name': name,
  'department_name': 'Engineering',
  'score': score,
  'eligible': eligible,
  'matched_skills': <Map<String, dynamic>>[
    <String, dynamic>{
      'skill_id': 's1',
      'skill_name': 'Flutter',
      'level': 4,
      'min_level': 3,
      'valid_until_date': null,
      'certification_status': 'not_required',
    },
  ],
  'blockers': blockers,
  'available_hours': 60,
  'requested_hours': 40,
  'residual_hours_per_day': 2,
  'peak_load_after_percent': peakAfter,
  'hourly_cost': 55,
};

Map<String, dynamic> utilizationRowJson(
  String name, {
  double actual = 60,
  double forecast = 75,
  double target = 70,
  double gap = -10,
  String status = 'below_target',
}) => <String, dynamic>{
  'key_id': name.toLowerCase(),
  'key_name': name,
  'net_available_hours': 160,
  'billable_committed_hours': 96,
  'billable_booked_hours': 120,
  'internal_booked_hours': 8,
  'tentative_booked_hours': 24,
  'actual_billable_percent': actual,
  'forecast_billable_percent': forecast,
  'target_percent': target,
  'gap_percent': gap,
  'status': status,
};

Map<String, dynamic> utilizationJson() => <String, dynamic>{
  'from': '2030-03-01',
  'to': '2030-03-31',
  'group_by': 'resource',
  'default_target_percent': 70,
  'rows': <Map<String, dynamic>>[
    utilizationRowJson('Anna'),
    utilizationRowJson(
      'Bruno',
      actual: 72,
      forecast: 80,
      gap: 2,
      status: 'on_target',
    ),
  ],
  'totals': utilizationRowJson('Total'),
};

/// In-memory repository; every call is recorded and each result can be replaced or made to fail.
class FakeResourcePlanningRepository implements ResourcePlanningRepository {
  CapacityHeatmap heatmapResult = CapacityHeatmap.fromJson(heatmapJson());
  List<ResourceAllocation> allocationRows = <ResourceAllocation>[];
  List<Skill> skillRows = const <Skill>[];
  List<Candidate> candidateRows = <Candidate>[];
  UtilizationReport utilizationResult = UtilizationReport.fromJson(
    utilizationJson(),
  );
  AllocationMutationResult? mutationResult;
  ResourcePlanningException? failure;

  final List<String> calls = <String>[];
  final List<RebalanceRequest> rebalances = <RebalanceRequest>[];
  final List<CandidateQuery> queries = <CandidateQuery>[];
  UtilizationGroup? lastGroup;

  void _maybeFail() {
    final ResourcePlanningException? f = failure;
    if (f != null) {
      throw f;
    }
  }

  @override
  Future<CapacityHeatmap> heatmap({
    required String from,
    required String to,
    String granularity = 'week',
    String? departmentId,
    List<String> employeeIds = const <String>[],
  }) async {
    calls.add('heatmap:$from:$to');
    _maybeFail();
    return heatmapResult;
  }

  @override
  Future<List<ResourceAllocation>> allocations({
    required String from,
    required String to,
    String? employeeId,
    String? projectId,
    BookingType? bookingType,
  }) async {
    calls.add('allocations:$from:$to');
    _maybeFail();
    return allocationRows;
  }

  @override
  Future<AllocationMutationResult> convertToHard(
    String allocationId, {
    String? projectId,
    String? wbsNodeId,
  }) async {
    calls.add('convert:$allocationId');
    _maybeFail();
    return mutationResult!;
  }

  @override
  Future<AllocationMutationResult> rebalance(
    String allocationId,
    RebalanceRequest request,
  ) async {
    calls.add('rebalance:$allocationId');
    rebalances.add(request);
    _maybeFail();
    return mutationResult!;
  }

  @override
  Future<List<Skill>> skills({String? category}) async {
    calls.add('skills');
    _maybeFail();
    return skillRows;
  }

  @override
  Future<List<EmployeeSkillProfile>> skillProfiles({
    String? employeeId,
    String? skillId,
  }) async => const <EmployeeSkillProfile>[];

  @override
  Future<List<ResourceCapacitySnapshot>> snapshots({
    required String from,
    required String to,
    String? employeeId,
  }) async => const <ResourceCapacitySnapshot>[];

  @override
  Future<List<Candidate>> searchCandidates(CandidateQuery query) async {
    calls.add('candidates');
    queries.add(query);
    _maybeFail();
    return candidateRows;
  }

  @override
  Future<UtilizationReport> utilization({
    required String from,
    required String to,
    UtilizationGroup groupBy = UtilizationGroup.resource,
  }) async {
    calls.add('utilization:$from:$to');
    lastGroup = groupBy;
    _maybeFail();
    return utilizationResult;
  }
}
