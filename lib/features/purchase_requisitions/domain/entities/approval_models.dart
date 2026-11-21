import 'budget_check.dart';
import 'purchase_requisition.dart';

/// Status of an individual approval workflow step (Mod 006).
enum ApprovalStepStatus {
  waiting('waiting'),
  pending('pending'),
  approved('approved'),
  rejected('rejected');

  const ApprovalStepStatus(this.wireValue);

  final String wireValue;

  /// Parses a wire value into an [ApprovalStepStatus].
  static ApprovalStepStatus fromWire(String? raw) {
    return ApprovalStepStatus.values.firstWhere(
      (ApprovalStepStatus s) => s.wireValue == raw,
      orElse: () => ApprovalStepStatus.waiting,
    );
  }
}

/// One level in the multi-level approval workflow (Mod 006).
class ApprovalLevelStep {
  const ApprovalLevelStep({
    required this.level,
    required this.roleName,
    required this.status,
    this.approverName,
    this.decidedAt,
    this.comment,
  });

  /// Parses an [ApprovalLevelStep] from JSON.
  factory ApprovalLevelStep.fromJson(Map<String, dynamic> json) {
    return ApprovalLevelStep(
      level: (json['level'] as num?)?.toInt() ?? 1,
      roleName: json['role_name']?.toString() ?? '',
      approverName: json['approver_name']?.toString(),
      status: ApprovalStepStatus.fromWire(json['status']?.toString()),
      decidedAt: json['decided_at'] != null
          ? DateTime.tryParse(json['decided_at'].toString())
          : null,
      comment: json['comment']?.toString(),
    );
  }

  final int level;
  final String roleName;
  final String? approverName;
  final ApprovalStepStatus status;
  final DateTime? decidedAt;
  final String? comment;

  /// Serializes this step for SQLite snapshot persistence.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'level': level,
    'role_name': roleName,
    if (approverName != null) 'approver_name': approverName,
    'status': status.wireValue,
    if (decidedAt != null) 'decided_at': decidedAt!.toUtc().toIso8601String(),
    if (comment != null) 'comment': comment,
  };
}

/// Immutable audit event type in a purchase requisition's history.
enum ApprovalActionType {
  submitted('submitted'),
  approved('approved'),
  rejected('rejected'),
  budgetWarning('budget_warning'),
  budgetBlocked('budget_blocked'),
  escalated('escalated'),
  converted('converted');

  const ApprovalActionType(this.wireValue);

  final String wireValue;

  /// Parses a wire value into an [ApprovalActionType].
  static ApprovalActionType fromWire(String? raw) {
    return ApprovalActionType.values.firstWhere(
      (ApprovalActionType t) => t.wireValue == raw,
      orElse: () => ApprovalActionType.submitted,
    );
  }
}

/// Originating channel for an approval audit entry.
enum ApprovalChannel {
  web('web'),
  mobileApp('mobile_app'),
  mobilePush('mobile_push'),
  emailOneClick('email_one_click'),
  system('system');

  const ApprovalChannel(this.wireValue);

  final String wireValue;

  /// Parses a wire value into an [ApprovalChannel].
  static ApprovalChannel fromWire(String? raw) {
    return ApprovalChannel.values.firstWhere(
      (ApprovalChannel c) => c.wireValue == raw,
      orElse: () => ApprovalChannel.web,
    );
  }
}

/// Immutable audit log entry cached in `local_approval_audit_logs`.
class ApprovalAuditEntry {
  const ApprovalAuditEntry({
    required this.id,
    required this.requisitionId,
    required this.level,
    required this.action,
    required this.actorName,
    required this.channel,
    required this.occurredAt,
    this.actorId,
    this.actorRole,
    this.comment,
    this.isLocalPending = false,
  });

  final String id;
  final String requisitionId;
  final int level;
  final ApprovalActionType action;
  final String? actorId;
  final String actorName;
  final String? actorRole;
  final ApprovalChannel channel;
  final String? comment;
  final DateTime occurredAt;
  final bool isLocalPending;
}

/// Manager inbox item cached in `local_pending_approvals`.
class PendingApprovalItem {
  const PendingApprovalItem({
    required this.approvalId,
    required this.tenantId,
    required this.requisitionRemoteId,
    required this.requisitionNumber,
    required this.requesterName,
    required this.costCenterCode,
    required this.costCenterName,
    required this.urgency,
    required this.totalAmount,
    required this.currency,
    required this.status,
    required this.currentLevel,
    required this.totalLevels,
    required this.budgetStatus,
    required this.syncStatus,
    required this.requestedAt,
    required this.updatedAt,
    this.projectName,
    this.oneClickToken,
    this.pendingDecision,
    this.pendingRejectionReason,
    this.syncError,
  });

  final String approvalId;
  final String tenantId;
  final String requisitionRemoteId;
  final String requisitionNumber;
  final String requesterName;
  final String costCenterCode;
  final String costCenterName;
  final String? projectName;
  final PrUrgency urgency;
  final double totalAmount;
  final PrCurrency currency;
  final PrStatus status;
  final int currentLevel;
  final int totalLevels;
  final BudgetCheckStatus budgetStatus;
  final String? oneClickToken;
  final String? pendingDecision;
  final String? pendingRejectionReason;
  final PrSyncStatus syncStatus;
  final String? syncError;
  final DateTime requestedAt;
  final DateTime updatedAt;
}

/// Event types emitted asynchronously when background sync finishes queued PR operations.
enum PrSyncEventKind {
  draftSynced,
  submitted,
  budgetBlocked,
  approvalSynced,
  syncFailed,
}

/// Notification event published by the repository when background sync completes.
class PrSyncEvent {
  const PrSyncEvent({
    required this.kind,
    required this.requisitionId,
    this.requisitionNumber,
    this.message,
    this.budgetCheck,
  });

  final PrSyncEventKind kind;
  final String requisitionId;
  final String? requisitionNumber;
  final String? message;
  final BudgetCheckResult? budgetCheck;
}
