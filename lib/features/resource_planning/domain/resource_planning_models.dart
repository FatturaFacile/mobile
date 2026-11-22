import 'package:flutter/foundation.dart';

double _num(Object? v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;

int _int(Object? v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;

String _str(Object? v) => v is String ? v : '';

String? _strOrNull(Object? v) => v is String && v.isNotEmpty ? v : null;

bool _bool(Object? v, {bool fallback = false}) => v is bool ? v : fallback;

Map<String, dynamic> _map(Object? v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

List<Map<String, dynamic>> _maps(Object? v) => <Map<String, dynamic>>[
  if (v is List)
    for (final dynamic e in v)
      if (e is Map) Map<String, dynamic>.from(e),
];

/// Load percentage from which a resource is flagged yellow (contract `thresholds.yellow`).
const double defaultYellowThreshold = 80;

/// Load percentage above which a resource is overloaded (contract `thresholds.red`).
const double defaultRedThreshold = 100;

/// Load reported by the API for a resource with bookings but no net capacity.
const double overloadLoadCap = 999;

/// Booking kind of an allocation: a tentative (soft) proposal or a firm (hard) commitment.
enum BookingType {
  softTentative('SoftTentative'),
  hardCommitted('HardCommitted');

  const BookingType(this.wire);

  final String wire;

  bool get isSoft => this == BookingType.softTentative;

  static BookingType fromWire(Object? value) => BookingType.values.firstWhere(
    (BookingType t) => t.wire == value,
    orElse: () => BookingType.softTentative,
  );
}

/// Saturation band of a resource in a period.
enum SaturationBand {
  none,
  green,
  yellow,
  red;

  static SaturationBand fromWire(Object? value) => SaturationBand.values
      .firstWhere((SaturationBand b) => b.name == value, orElse: () => none);

  /// Band of a load, using the contract rules: `none` without net capacity and without bookings, green below
  /// [yellowAt], yellow up to [redAt] included, red above it.
  static SaturationBand fromLoad({
    required double loadPercent,
    required double netHours,
    required double bookedHours,
    double yellowAt = defaultYellowThreshold,
    double redAt = defaultRedThreshold,
  }) {
    if (netHours <= 0 && bookedHours <= 0) {
      return none;
    }
    if (loadPercent > redAt) {
      return red;
    }
    if (loadPercent >= yellowAt) {
      return yellow;
    }
    return green;
  }
}

/// Outcome of the certificate check of a skill profile.
enum CertificationStatus {
  notRequired('not_required'),
  valid('valid'),
  missing('missing'),
  expired('expired');

  const CertificationStatus(this.wire);

  final String wire;

  bool get isBlocking => this == missing || this == expired;

  static CertificationStatus fromWire(Object? value) =>
      CertificationStatus.values.firstWhere(
        (CertificationStatus s) => s.wire == value,
        orElse: () => CertificationStatus.notRequired,
      );
}

/// Whether the billable share of a resource met its target.
enum UtilizationStatus {
  onTarget('on_target'),
  belowTarget('below_target'),
  aboveTarget('above_target');

  const UtilizationStatus(this.wire);

  final String wire;

  static UtilizationStatus fromWire(Object? value) =>
      UtilizationStatus.values.firstWhere(
        (UtilizationStatus s) => s.wire == value,
        orElse: () => UtilizationStatus.onTarget,
      );
}

/// Grouping of the billable utilization report.
enum UtilizationGroup {
  resource,
  department,
  costCenter('cost_center');

  const UtilizationGroup([String? wire]) : _wire = wire;

  final String? _wire;

  String get wire => _wire ?? name;
}

/// Strategy of the rebalance endpoint.
enum RebalanceStrategy { shift, reassign, split, resize }

/// A code with parameters, used by warnings and by blocking rule violations (`invalid_params`).
@immutable
class ApiCode {
  const ApiCode(this.code, [this.params = const <String, dynamic>{}]);

  factory ApiCode.fromJson(Map<String, dynamic> json) =>
      ApiCode(_str(json['code']), _map(json['params']));

  final String code;
  final Map<String, dynamic> params;
}

/// A skill of the tenant taxonomy.
@immutable
class Skill {
  const Skill({
    required this.id,
    required this.category,
    required this.skillName,
    this.requiresCertification = false,
    this.certificationCode,
  });

  factory Skill.fromJson(Map<String, dynamic> json) => Skill(
    id: _str(json['id']),
    category: _str(json['category']),
    skillName: _str(json['skill_name']),
    requiresCertification: _bool(json['requires_certification']),
    certificationCode: _strOrNull(json['certification_code']),
  );

  final String id;
  final String category;
  final String skillName;
  final bool requiresCertification;
  final String? certificationCode;
}

/// Proficiency of an employee in a skill, with the certificate verdict.
@immutable
class EmployeeSkillProfile {
  const EmployeeSkillProfile({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.skillId,
    required this.skillName,
    required this.category,
    required this.proficiencyLevel,
    this.validUntilDate,
    this.isValid = true,
    this.requiresCertification = false,
    this.certificationCode,
    this.certificationStatus = CertificationStatus.notRequired,
    this.certificationValidUntil,
  });

  factory EmployeeSkillProfile.fromJson(Map<String, dynamic> json) =>
      EmployeeSkillProfile(
        id: _str(json['id']),
        employeeId: _str(json['employee_id']),
        employeeName: _str(json['employee_name']),
        skillId: _str(json['skill_id']),
        skillName: _str(json['skill_name']),
        category: _str(json['category']),
        proficiencyLevel: _int(json['proficiency_level']),
        validUntilDate: _strOrNull(json['valid_until_date']),
        isValid: _bool(json['is_valid'], fallback: true),
        requiresCertification: _bool(json['requires_certification']),
        certificationCode: _strOrNull(json['certification_code']),
        certificationStatus: CertificationStatus.fromWire(
          json['certification_status'],
        ),
        certificationValidUntil: _strOrNull(json['certification_valid_until']),
      );

  final String id;
  final String employeeId;
  final String employeeName;
  final String skillId;
  final String skillName;
  final String category;

  /// 1 (novice) to 5 (expert).
  final int proficiencyLevel;
  final String? validUntilDate;
  final bool isValid;
  final bool requiresCertification;
  final String? certificationCode;
  final CertificationStatus certificationStatus;
  final String? certificationValidUntil;
}

/// A week whose load exceeds the capacity.
@immutable
class OverloadWeek {
  const OverloadWeek({required this.weekStart, required this.loadPercent});

  factory OverloadWeek.fromJson(Map<String, dynamic> json) => OverloadWeek(
    weekStart: _str(json['week_start']),
    loadPercent: _num(json['load_percent']),
  );

  final String weekStart;
  final double loadPercent;
}

/// Overload verdict attached to an allocation mutation.
@immutable
class OverloadInfo {
  const OverloadInfo({
    this.isOverloaded = false,
    this.peakLoadPercent = 0,
    this.weeks = const <OverloadWeek>[],
  });

  factory OverloadInfo.fromJson(Map<String, dynamic> json) => OverloadInfo(
    isOverloaded: _bool(json['is_overloaded']),
    peakLoadPercent: _num(json['peak_load_percent']),
    weeks: <OverloadWeek>[
      for (final Map<String, dynamic> w in _maps(json['weeks']))
        OverloadWeek.fromJson(w),
    ],
  );

  final bool isOverloaded;
  final double peakLoadPercent;
  final List<OverloadWeek> weeks;
}

/// Booking of an employee on a project (or an opportunity) over a period.
@immutable
class ResourceAllocation {
  const ResourceAllocation({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.bookingType,
    required this.startDate,
    required this.endDate,
    required this.allocatedHoursPerDay,
    required this.totalAllocatedHours,
    this.projectId,
    this.projectName,
    this.wbsNodeId,
    this.wbsNodeTitle,
    this.roleId,
    this.isBillable = true,
    this.crmOpportunityId,
    this.crmOpportunityName,
    this.isOverloaded = false,
    this.peakLoadPercent = 0,
    this.notes,
  });

  factory ResourceAllocation.fromJson(Map<String, dynamic> json) =>
      ResourceAllocation(
        id: _str(json['id']),
        projectId: _strOrNull(json['project_id']),
        projectName: _strOrNull(json['project_name']),
        wbsNodeId: _strOrNull(json['wbs_node_id']),
        wbsNodeTitle: _strOrNull(json['wbs_node_title']),
        employeeId: _str(json['employee_id']),
        employeeName: _str(json['employee_name']),
        roleId: _strOrNull(json['role_id']),
        bookingType: BookingType.fromWire(json['booking_type']),
        startDate: _str(json['start_date']),
        endDate: _str(json['end_date']),
        allocatedHoursPerDay: _num(json['allocated_hours_per_day']),
        totalAllocatedHours: _num(json['total_allocated_hours']),
        isBillable: _bool(json['is_billable'], fallback: true),
        crmOpportunityId: _strOrNull(json['crm_opportunity_id']),
        crmOpportunityName: _strOrNull(json['crm_opportunity_name']),
        isOverloaded: _bool(json['is_overloaded']),
        peakLoadPercent: _num(json['peak_load_percent']),
        notes: _strOrNull(json['notes']),
      );

  final String id;
  final String? projectId;
  final String? projectName;
  final String? wbsNodeId;
  final String? wbsNodeTitle;
  final String employeeId;
  final String employeeName;
  final String? roleId;
  final BookingType bookingType;

  /// `Y-m-d`.
  final String startDate;

  /// `Y-m-d`.
  final String endDate;
  final double allocatedHoursPerDay;
  final double totalAllocatedHours;
  final bool isBillable;
  final String? crmOpportunityId;
  final String? crmOpportunityName;
  final bool isOverloaded;
  final double peakLoadPercent;
  final String? notes;

  bool get isSoft => bookingType.isSoft;

  /// Whether a soft booking can be turned into a hard one without further input: the project must be known.
  bool get canConvertWithoutProject => isSoft && projectId != null;

  /// Name shown on the agenda: the project, else the opportunity.
  String? get referenceName => projectName ?? crmOpportunityName;

  ResourceAllocation copyWith({
    BookingType? bookingType,
    String? startDate,
    String? endDate,
  }) => ResourceAllocation(
    id: id,
    projectId: projectId,
    projectName: projectName,
    wbsNodeId: wbsNodeId,
    wbsNodeTitle: wbsNodeTitle,
    employeeId: employeeId,
    employeeName: employeeName,
    roleId: roleId,
    bookingType: bookingType ?? this.bookingType,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    allocatedHoursPerDay: allocatedHoursPerDay,
    totalAllocatedHours: totalAllocatedHours,
    isBillable: isBillable,
    crmOpportunityId: crmOpportunityId,
    crmOpportunityName: crmOpportunityName,
    isOverloaded: isOverloaded,
    peakLoadPercent: peakLoadPercent,
    notes: notes,
  );
}

/// Result of an allocation mutation (convert, rebalance, create).
@immutable
class AllocationMutationResult {
  const AllocationMutationResult({
    required this.allocation,
    this.allocations = const <ResourceAllocation>[],
    this.overload = const OverloadInfo(),
    this.warnings = const <ApiCode>[],
  });

  factory AllocationMutationResult.fromJson(Map<String, dynamic> json) {
    final ResourceAllocation main = ResourceAllocation.fromJson(
      _map(json['allocation']),
    );
    final List<ResourceAllocation> all = <ResourceAllocation>[
      for (final Map<String, dynamic> a in _maps(json['allocations']))
        ResourceAllocation.fromJson(a),
    ];
    return AllocationMutationResult(
      allocation: main,
      allocations: all.isEmpty ? <ResourceAllocation>[main] : all,
      overload: OverloadInfo.fromJson(_map(json['overload'])),
      warnings: <ApiCode>[
        for (final Map<String, dynamic> w in _maps(json['warnings']))
          ApiCode.fromJson(w),
      ],
    );
  }

  final ResourceAllocation allocation;

  /// Every affected row (two for a split).
  final List<ResourceAllocation> allocations;
  final OverloadInfo overload;
  final List<ApiCode> warnings;
}

/// One resource in one period of the heatmap.
@immutable
class HeatmapCell {
  const HeatmapCell({
    required this.periodStart,
    required this.contractualHours,
    required this.leaveAndHolidayHours,
    required this.netAvailableHours,
    required this.hardBookedHours,
    required this.softBookedHours,
    required this.billableBookedHours,
    required this.internalBookedHours,
    required this.loadPercent,
    required this.band,
    required this.isOverloaded,
  });

  factory HeatmapCell.fromJson(Map<String, dynamic> json) => HeatmapCell(
    periodStart: _str(json['period_start']),
    contractualHours: _num(json['contractual_hours']),
    leaveAndHolidayHours: _num(json['leave_and_holiday_hours']),
    netAvailableHours: _num(json['net_available_hours']),
    hardBookedHours: _num(json['hard_booked_hours']),
    softBookedHours: _num(json['soft_booked_hours']),
    billableBookedHours: _num(json['billable_booked_hours']),
    internalBookedHours: _num(json['internal_booked_hours']),
    loadPercent: _num(json['load_percent']),
    band: SaturationBand.fromWire(json['band']),
    isOverloaded: _bool(json['is_overloaded']),
  );

  final String periodStart;
  final double contractualHours;
  final double leaveAndHolidayHours;
  final double netAvailableHours;
  final double hardBookedHours;
  final double softBookedHours;
  final double billableBookedHours;
  final double internalBookedHours;
  final double loadPercent;
  final SaturationBand band;
  final bool isOverloaded;

  double get bookedHours => hardBookedHours + softBookedHours;

  /// Hours still free in the period (never negative).
  double get freeHours {
    final double free = netAvailableHours - bookedHours;
    return free < 0 ? 0 : free;
  }
}

/// One employee of the heatmap with a cell per period.
@immutable
class HeatmapRow {
  const HeatmapRow({
    required this.employeeId,
    required this.employeeName,
    required this.weeklyContractHours,
    required this.cells,
    this.departmentId,
    this.departmentName,
    this.costCenterId,
  });

  factory HeatmapRow.fromJson(Map<String, dynamic> json) => HeatmapRow(
    employeeId: _str(json['employee_id']),
    employeeName: _str(json['employee_name']),
    departmentId: _strOrNull(json['department_id']),
    departmentName: _strOrNull(json['department_name']),
    costCenterId: _strOrNull(json['cost_center_id']),
    weeklyContractHours: _num(json['weekly_contract_hours']),
    cells: <HeatmapCell>[
      for (final Map<String, dynamic> c in _maps(json['cells']))
        HeatmapCell.fromJson(c),
    ],
  );

  final String employeeId;
  final String employeeName;
  final String? departmentId;
  final String? departmentName;
  final String? costCenterId;
  final double weeklyContractHours;
  final List<HeatmapCell> cells;

  /// Highest load of the shown periods.
  double get peakLoadPercent => cells.fold<double>(
    0,
    (double peak, HeatmapCell c) => c.loadPercent > peak ? c.loadPercent : peak,
  );

  /// Worst band of the shown periods (red > yellow > green > none).
  SaturationBand get worstBand => cells.fold<SaturationBand>(
    SaturationBand.none,
    (SaturationBand worst, HeatmapCell c) =>
        c.band.index > worst.index ? c.band : worst,
  );

  bool get isOverloaded => cells.any((HeatmapCell c) => c.isOverloaded);
}

/// Saturation of the resources over a window.
@immutable
class CapacityHeatmap {
  const CapacityHeatmap({
    required this.from,
    required this.to,
    required this.granularity,
    required this.periods,
    required this.rows,
    this.yellowThreshold = defaultYellowThreshold,
    this.redThreshold = defaultRedThreshold,
  });

  factory CapacityHeatmap.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> thresholds = _map(json['thresholds']);
    return CapacityHeatmap(
      from: _str(json['from']),
      to: _str(json['to']),
      granularity: _str(json['granularity']),
      yellowThreshold: thresholds.containsKey('yellow')
          ? _num(thresholds['yellow'])
          : defaultYellowThreshold,
      redThreshold: thresholds.containsKey('red')
          ? _num(thresholds['red'])
          : defaultRedThreshold,
      periods: <String>[
        if (json['periods'] is List)
          for (final dynamic p in json['periods'] as List<dynamic>) _str(p),
      ],
      rows: <HeatmapRow>[
        for (final Map<String, dynamic> r in _maps(json['rows']))
          HeatmapRow.fromJson(r),
      ],
    );
  }

  final String from;
  final String to;

  /// `week` or `day`.
  final String granularity;
  final double yellowThreshold;
  final double redThreshold;
  final List<String> periods;
  final List<HeatmapRow> rows;

  /// Rows with at least one overloaded period, most loaded first.
  List<HeatmapRow> get overloadedRows =>
      <HeatmapRow>[...rows.where((HeatmapRow r) => r.isOverloaded)]..sort(
        (HeatmapRow a, HeatmapRow b) =>
            b.peakLoadPercent.compareTo(a.peakLoadPercent),
      );
}

/// Stored weekly capacity snapshot of an employee.
@immutable
class ResourceCapacitySnapshot {
  const ResourceCapacitySnapshot({
    required this.id,
    required this.employeeId,
    required this.weekStartDate,
    required this.contractualHours,
    required this.leaveAndHolidayHours,
    required this.netAvailableHours,
    required this.billableBookedHours,
    required this.internalBookedHours,
    required this.utilizationRatePercent,
    this.departmentId,
    this.costCenterId,
  });

  factory ResourceCapacitySnapshot.fromJson(Map<String, dynamic> json) =>
      ResourceCapacitySnapshot(
        id: _str(json['id']),
        employeeId: _str(json['employee_id']),
        weekStartDate: _str(json['week_start_date']),
        contractualHours: _num(json['contractual_hours']),
        leaveAndHolidayHours: _num(json['leave_and_holiday_hours']),
        netAvailableHours: _num(json['net_available_hours']),
        billableBookedHours: _num(json['billable_booked_hours']),
        internalBookedHours: _num(json['internal_booked_hours']),
        utilizationRatePercent: _num(json['utilization_rate_percent']),
        departmentId: _strOrNull(json['department_id']),
        costCenterId: _strOrNull(json['cost_center_id']),
      );

  final String id;
  final String employeeId;
  final String weekStartDate;
  final double contractualHours;
  final double leaveAndHolidayHours;
  final double netAvailableHours;
  final double billableBookedHours;
  final double internalBookedHours;
  final double utilizationRatePercent;
  final String? departmentId;
  final String? costCenterId;
}

/// A skill required by a candidate search.
@immutable
class SkillRequirement {
  const SkillRequirement({required this.skillId, required this.minLevel});

  final String skillId;
  final int minLevel;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'skill_id': skillId,
    'min_level': minLevel,
  };
}

/// Parameters of a candidate search for a role.
@immutable
class CandidateQuery {
  const CandidateQuery({
    required this.startDate,
    required this.endDate,
    required this.allocatedHoursPerDay,
    required this.requirements,
    this.projectId,
    this.departmentId,
    this.requireValidCertificates = true,
    this.includeIneligible = false,
    this.limit = 10,
  });

  final String startDate;
  final String endDate;
  final double allocatedHoursPerDay;
  final List<SkillRequirement> requirements;
  final String? projectId;
  final String? departmentId;
  final bool requireValidCertificates;
  final bool includeIneligible;
  final int limit;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'start_date': startDate,
    'end_date': endDate,
    'allocated_hours_per_day': allocatedHoursPerDay,
    'requirements': <Map<String, dynamic>>[
      for (final SkillRequirement r in requirements) r.toJson(),
    ],
    'project_id': ?projectId,
    'department_id': ?departmentId,
    'require_valid_certificates': requireValidCertificates,
    'include_ineligible': includeIneligible,
    'limit': limit,
  };
}

/// A skill of a candidate that satisfies a requirement.
@immutable
class MatchedSkill {
  const MatchedSkill({
    required this.skillId,
    required this.skillName,
    required this.level,
    required this.minLevel,
    this.validUntilDate,
    this.certificationStatus = CertificationStatus.notRequired,
  });

  factory MatchedSkill.fromJson(Map<String, dynamic> json) => MatchedSkill(
    skillId: _str(json['skill_id']),
    skillName: _str(json['skill_name']),
    level: _int(json['level']),
    minLevel: _int(json['min_level']),
    validUntilDate: _strOrNull(json['valid_until_date']),
    certificationStatus: CertificationStatus.fromWire(
      json['certification_status'],
    ),
  );

  final String skillId;
  final String skillName;
  final int level;
  final int minLevel;
  final String? validUntilDate;
  final CertificationStatus certificationStatus;
}

/// Why a candidate is not eligible. [code] is one of `skill_missing`, `proficiency_too_low`, `skill_expired`,
/// `certificate_missing`, `certificate_expired`, `insufficient_availability`.
@immutable
class CandidateBlocker {
  const CandidateBlocker({
    required this.code,
    this.skillId,
    this.params = const <String, dynamic>{},
  });

  factory CandidateBlocker.fromJson(Map<String, dynamic> json) =>
      CandidateBlocker(
        code: _str(json['code']),
        skillId: _strOrNull(json['skill_id']),
        params: _map(json['params']),
      );

  final String code;
  final String? skillId;
  final Map<String, dynamic> params;
}

/// A suggested resource for a role, ranked by score.
@immutable
class Candidate {
  const Candidate({
    required this.employeeId,
    required this.employeeName,
    required this.score,
    required this.eligible,
    required this.matchedSkills,
    required this.blockers,
    required this.availableHours,
    required this.requestedHours,
    required this.residualHoursPerDay,
    required this.peakLoadAfterPercent,
    required this.hourlyCost,
    this.departmentName,
  });

  factory Candidate.fromJson(Map<String, dynamic> json) => Candidate(
    employeeId: _str(json['employee_id']),
    employeeName: _str(json['employee_name']),
    departmentName: _strOrNull(json['department_name']),
    score: _num(json['score']),
    eligible: _bool(json['eligible']),
    matchedSkills: <MatchedSkill>[
      for (final Map<String, dynamic> m in _maps(json['matched_skills']))
        MatchedSkill.fromJson(m),
    ],
    blockers: <CandidateBlocker>[
      for (final Map<String, dynamic> b in _maps(json['blockers']))
        CandidateBlocker.fromJson(b),
    ],
    availableHours: _num(json['available_hours']),
    requestedHours: _num(json['requested_hours']),
    residualHoursPerDay: _num(json['residual_hours_per_day']),
    peakLoadAfterPercent: _num(json['peak_load_after_percent']),
    hourlyCost: _num(json['hourly_cost']),
  );

  final String employeeId;
  final String employeeName;
  final String? departmentName;

  /// 0 to 100.
  final double score;
  final bool eligible;
  final List<MatchedSkill> matchedSkills;
  final List<CandidateBlocker> blockers;
  final double availableHours;
  final double requestedHours;
  final double residualHoursPerDay;
  final double peakLoadAfterPercent;
  final double hourlyCost;

  /// The assignment would push the candidate over the capacity.
  bool get wouldOverload => peakLoadAfterPercent > defaultRedThreshold;
}

/// One line of the billable utilization report.
@immutable
class UtilizationRow {
  const UtilizationRow({
    required this.keyName,
    required this.netAvailableHours,
    required this.billableCommittedHours,
    required this.billableBookedHours,
    required this.internalBookedHours,
    required this.tentativeBookedHours,
    required this.actualBillablePercent,
    required this.forecastBillablePercent,
    required this.targetPercent,
    required this.gapPercent,
    required this.status,
    this.keyId,
  });

  factory UtilizationRow.fromJson(Map<String, dynamic> json) => UtilizationRow(
    keyId: _strOrNull(json['key_id']),
    keyName: _str(json['key_name']),
    netAvailableHours: _num(json['net_available_hours']),
    billableCommittedHours: _num(json['billable_committed_hours']),
    billableBookedHours: _num(json['billable_booked_hours']),
    internalBookedHours: _num(json['internal_booked_hours']),
    tentativeBookedHours: _num(json['tentative_booked_hours']),
    actualBillablePercent: _num(json['actual_billable_percent']),
    forecastBillablePercent: _num(json['forecast_billable_percent']),
    targetPercent: _num(json['target_percent']),
    gapPercent: _num(json['gap_percent']),
    status: UtilizationStatus.fromWire(json['status']),
  );

  final String? keyId;
  final String keyName;
  final double netAvailableHours;
  final double billableCommittedHours;
  final double billableBookedHours;
  final double internalBookedHours;
  final double tentativeBookedHours;
  final double actualBillablePercent;
  final double forecastBillablePercent;
  final double targetPercent;
  final double gapPercent;
  final UtilizationStatus status;
}

/// Billable utilization of a window, target versus actual.
@immutable
class UtilizationReport {
  const UtilizationReport({
    required this.from,
    required this.to,
    required this.groupBy,
    required this.defaultTargetPercent,
    required this.rows,
    required this.totals,
  });

  factory UtilizationReport.fromJson(Map<String, dynamic> json) =>
      UtilizationReport(
        from: _str(json['from']),
        to: _str(json['to']),
        groupBy: _str(json['group_by']),
        defaultTargetPercent: _num(json['default_target_percent']),
        rows: <UtilizationRow>[
          for (final Map<String, dynamic> r in _maps(json['rows']))
            UtilizationRow.fromJson(r),
        ],
        totals: UtilizationRow.fromJson(_map(json['totals'])),
      );

  final String from;
  final String to;
  final String groupBy;
  final double defaultTargetPercent;
  final List<UtilizationRow> rows;
  final UtilizationRow totals;
}
