import 'package:flutter/foundation.dart';

import 'resource_planning_models.dart';

/// Why a call of the resource planning API failed; the UI maps it to a localized message.
enum ResourcePlanningErrorKind {
  forbidden,
  notFound,
  conflict,
  invalid,
  offline,
  unknown,
}

class ResourcePlanningException implements Exception {
  const ResourcePlanningException(
    this.kind, {
    this.detail = '',
    this.violations = const <ApiCode>[],
  });

  final ResourcePlanningErrorKind kind;

  /// `detail` of the RFC 7807 problem.
  final String detail;

  /// Domain violations of a 422 (`invalid_params`), e.g. `already_hard_committed`.
  final List<ApiCode> violations;

  @override
  String toString() => 'ResourcePlanningException($kind, $detail)';
}

/// Body of `POST /allocations/{id}/rebalance`.
@immutable
class RebalanceRequest {
  const RebalanceRequest({
    required this.strategy,
    this.employeeId,
    this.startDate,
    this.endDate,
    this.splitDate,
    this.shiftDays,
    this.allocatedHoursPerDay,
  });

  /// Moves the allocation by [days] days, keeping its duration.
  const RebalanceRequest.shiftBy(int days)
    : this(strategy: RebalanceStrategy.shift, shiftDays: days);

  /// Hands the allocation over to a colleague.
  const RebalanceRequest.reassignTo(String employeeId)
    : this(strategy: RebalanceStrategy.reassign, employeeId: employeeId);

  final RebalanceStrategy strategy;
  final String? employeeId;
  final String? startDate;
  final String? endDate;
  final String? splitDate;
  final int? shiftDays;
  final double? allocatedHoursPerDay;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'strategy': strategy.name,
    'employee_id': ?employeeId,
    'start_date': ?startDate,
    'end_date': ?endDate,
    'split_date': ?splitDate,
    'shift_days': ?shiftDays,
    'allocated_hours_per_day': ?allocatedHoursPerDay,
  };
}

/// Backend gateway of the resource planning module. The planning data is computed by the server, so the gateway is
/// online-only; failures throw [ResourcePlanningException].
abstract interface class ResourcePlanningRepository {
  Future<List<Skill>> skills({String? category});

  Future<List<EmployeeSkillProfile>> skillProfiles({
    String? employeeId,
    String? skillId,
  });

  Future<List<ResourceAllocation>> allocations({
    required String from,
    required String to,
    String? employeeId,
    String? projectId,
    BookingType? bookingType,
  });

  /// Soft bookings are turned hard; [projectId] is required when the soft booking only has an opportunity.
  Future<AllocationMutationResult> convertToHard(
    String allocationId, {
    String? projectId,
    String? wbsNodeId,
  });

  Future<AllocationMutationResult> rebalance(
    String allocationId,
    RebalanceRequest request,
  );

  Future<CapacityHeatmap> heatmap({
    required String from,
    required String to,
    String granularity = 'week',
    String? departmentId,
    List<String> employeeIds = const <String>[],
  });

  Future<List<ResourceCapacitySnapshot>> snapshots({
    required String from,
    required String to,
    String? employeeId,
  });

  Future<List<Candidate>> searchCandidates(CandidateQuery query);

  Future<UtilizationReport> utilization({
    required String from,
    required String to,
    UtilizationGroup groupBy = UtilizationGroup.resource,
  });
}
