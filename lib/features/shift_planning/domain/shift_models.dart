import 'package:flutter/foundation.dart';

/// Severity of one finding of the compliance check (`blocking_error` stops the action, `warning` informs).
enum IssueSeverity { blocking, warning }

/// One finding of the real-time compliance check. [translationKey] is a key of the API dictionary.
@immutable
class ComplianceIssue {
  const ComplianceIssue({
    required this.severity,
    required this.ruleCode,
    required this.translationKey,
    this.params = const <String, Object>{},
  });

  factory ComplianceIssue.fromJson(Map<String, dynamic> json) {
    final Object? params = json['params'];
    return ComplianceIssue(
      severity: json['severity'] == 'blocking_error'
          ? IssueSeverity.blocking
          : IssueSeverity.warning,
      ruleCode: '${json['rule_code'] ?? ''}',
      translationKey: '${json['translation_key'] ?? ''}',
      params: <String, Object>{
        if (params is Map)
          for (final MapEntry<dynamic, dynamic> e in params.entries)
            if (e.value != null) '${e.key}': e.value as Object,
      },
    );
  }

  final IssueSeverity severity;
  final String ruleCode;
  final String translationKey;
  final Map<String, Object> params;

  bool get isBlocking => severity == IssueSeverity.blocking;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'severity': isBlocking ? 'blocking_error' : 'warning',
    'rule_code': ruleCode,
    'translation_key': translationKey,
    'params': params,
  };
}

/// The surcharge tags of a shift that payroll pays extra.
enum SurchargeTag {
  night('night'),
  sunday('sunday'),
  holiday('holiday'),
  onCall('on_call');

  const SurchargeTag(this.wire);

  final String wire;

  static SurchargeTag? fromWire(String value) {
    for (final SurchargeTag t in SurchargeTag.values) {
      if (t.wire == value) {
        return t;
      }
    }
    return null;
  }
}

/// A shift of a published roster, as the employee sees it (never with its labour cost).
@immutable
class Shift {
  const Shift({
    required this.id,
    required this.date,
    required this.startAt,
    required this.endAt,
    required this.templateCode,
    this.periodId = '',
    this.employeeId,
    this.employeeName,
    this.colorHex = '#1890FF',
    this.templateName = const <String, String>{},
    this.tags = const <SurchargeTag>[],
    this.roleOrSkillId,
    this.warnings = const <ComplianceIssue>[],
  });

  factory Shift.fromJson(Map<String, dynamic> json) {
    final Object? template = json['template'];
    final Map<String, dynamic> t = template is Map
        ? Map<String, dynamic>.from(template)
        : <String, dynamic>{};
    final Object? breakdown = json['surcharge_breakdown'];
    final Object? rawTags =
        json['tags'] ?? (breakdown is Map ? breakdown['tags'] : null);
    final Object? issues =
        json['claim_warnings'] ?? json['compliance_warnings'];
    final Object? name = t['name'];
    return Shift(
      id: '${json['id']}',
      periodId: '${json['roster_schedule_period_id'] ?? ''}',
      employeeId: json['employee_id'] as String?,
      employeeName: json['employee_name'] as String?,
      date: '${json['shift_date']}',
      startAt: DateTime.parse('${json['start_at']}').toUtc(),
      endAt: DateTime.parse('${json['end_at']}').toUtc(),
      templateCode: '${t['code'] ?? json['template_code'] ?? ''}',
      colorHex: '${t['color_hex'] ?? '#1890FF'}',
      templateName: <String, String>{
        if (name is Map)
          for (final MapEntry<dynamic, dynamic> e in name.entries)
            '${e.key}': '${e.value}',
      },
      tags: <SurchargeTag>[
        if (rawTags is List)
          for (final Object? tag in rawTags)
            if (SurchargeTag.fromWire('$tag') case final SurchargeTag found)
              found,
      ],
      roleOrSkillId: json['required_role_or_skill_id'] as String?,
      warnings: <ComplianceIssue>[
        if (issues is List)
          for (final Object? i in issues)
            if (i is Map)
              ComplianceIssue.fromJson(Map<String, dynamic>.from(i)),
      ],
    );
  }

  final String id;
  final String periodId;
  final String? employeeId;
  final String? employeeName;

  /// Local calendar day of the shift (`yyyy-MM-dd`), the day it starts.
  final String date;
  final DateTime startAt;
  final DateTime endAt;
  final String templateCode;
  final String colorHex;
  final Map<String, String> templateName;
  final List<SurchargeTag> tags;
  final String? roleOrSkillId;
  final List<ComplianceIssue> warnings;

  bool get isOpen => employeeId == null;

  Duration get length => endAt.difference(startAt);

  /// Name of the template in [languageCode], falling back to English and then to the code.
  String label(String languageCode) =>
      templateName[languageCode] ?? templateName['en'] ?? templateCode;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'roster_schedule_period_id': periodId,
    'employee_id': employeeId,
    'employee_name': employeeName,
    'shift_date': date,
    'start_at': startAt.toIso8601String(),
    'end_at': endAt.toIso8601String(),
    'template': <String, dynamic>{
      'code': templateCode,
      'color_hex': colorHex,
      'name': templateName,
    },
    'tags': <String>[for (final SurchargeTag t in tags) t.wire],
    'required_role_or_skill_id': roleOrSkillId,
    'compliance_warnings': <Map<String, dynamic>>[
      for (final ComplianceIssue i in warnings) i.toJson(),
    ],
  };
}

/// A shift of a colleague that can be taken in exchange.
@immutable
class PeerShift {
  const PeerShift({
    required this.id,
    required this.date,
    required this.templateCode,
    required this.startAt,
    required this.endAt,
  });

  factory PeerShift.fromJson(Map<String, dynamic> json) => PeerShift(
    id: '${json['id']}',
    date: '${json['shift_date']}',
    templateCode: '${json['template_code'] ?? ''}',
    startAt: DateTime.parse('${json['start_at']}').toUtc(),
    endAt: DateTime.parse('${json['end_at']}').toUtc(),
  );

  final String id;
  final String date;
  final String templateCode;
  final DateTime startAt;
  final DateTime endAt;
}

/// A colleague who could take the shift without breaking a blocking rule.
@immutable
class SwapPeer {
  const SwapPeer({
    required this.employeeId,
    required this.name,
    this.warnings = const <ComplianceIssue>[],
    this.shifts = const <PeerShift>[],
  });

  factory SwapPeer.fromJson(Map<String, dynamic> json) {
    final Object? warnings = json['warnings'];
    final Object? shifts = json['shifts'];
    return SwapPeer(
      employeeId: '${json['employee_id']}',
      name: '${json['name'] ?? ''}',
      warnings: <ComplianceIssue>[
        if (warnings is List)
          for (final Object? w in warnings)
            if (w is Map)
              ComplianceIssue.fromJson(Map<String, dynamic>.from(w)),
      ],
      shifts: <PeerShift>[
        if (shifts is List)
          for (final Object? s in shifts)
            if (s is Map) PeerShift.fromJson(Map<String, dynamic>.from(s)),
      ],
    );
  }

  final String employeeId;
  final String name;
  final List<ComplianceIssue> warnings;
  final List<PeerShift> shifts;
}

/// Where a swap is in its two-step approval.
enum SwapStatus {
  pendingPeerAcceptance('pending_peer_acceptance'),
  pendingManagerApproval('pending_manager_approval'),
  approved('approved'),
  rejected('rejected');

  const SwapStatus(this.wire);

  final String wire;

  static SwapStatus fromWire(String value) => SwapStatus.values.firstWhere(
    (SwapStatus s) => s.wire == value,
    orElse: () => SwapStatus.pendingPeerAcceptance,
  );
}

@immutable
class SwapRequest {
  const SwapRequest({
    required this.id,
    required this.requesterEmployeeId,
    required this.shiftAssignmentId,
    required this.status,
    this.targetPeerEmployeeId,
    this.targetShiftAssignmentId,
    this.rejectionReason,
    this.assignment,
    this.targetAssignment,
  });

  factory SwapRequest.fromJson(Map<String, dynamic> json) {
    final Object? assignment = json['assignment'];
    final Object? target = json['target_assignment'];
    return SwapRequest(
      id: '${json['id']}',
      requesterEmployeeId: '${json['requester_employee_id']}',
      targetPeerEmployeeId: json['target_peer_employee_id'] as String?,
      shiftAssignmentId: '${json['shift_assignment_id']}',
      targetShiftAssignmentId: json['target_shift_assignment_id'] as String?,
      status: SwapStatus.fromWire('${json['status']}'),
      rejectionReason: json['rejection_reason'] as String?,
      assignment: assignment is Map
          ? Shift.fromJson(Map<String, dynamic>.from(assignment))
          : null,
      targetAssignment: target is Map
          ? Shift.fromJson(Map<String, dynamic>.from(target))
          : null,
    );
  }

  final String id;
  final String requesterEmployeeId;
  final String? targetPeerEmployeeId;
  final String shiftAssignmentId;
  final String? targetShiftAssignmentId;
  final SwapStatus status;
  final String? rejectionReason;
  final Shift? assignment;
  final Shift? targetAssignment;

  bool get isBroadcast => targetPeerEmployeeId == null;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'requester_employee_id': requesterEmployeeId,
    'target_peer_employee_id': targetPeerEmployeeId,
    'shift_assignment_id': shiftAssignmentId,
    'target_shift_assignment_id': targetShiftAssignmentId,
    'status': status.wire,
    'rejection_reason': rejectionReason,
    'assignment': assignment?.toJson(),
    'target_assignment': targetAssignment?.toJson(),
  };
}
