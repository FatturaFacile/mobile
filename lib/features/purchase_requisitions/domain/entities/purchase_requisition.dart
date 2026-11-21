import 'approval_models.dart';
import 'budget_check.dart';

/// Synchronization state of a local purchase requisition or offline decision.
enum PrSyncStatus {
  synced('synced'),
  pendingUpload('pending_upload'),
  syncError('sync_error');

  const PrSyncStatus(this.wireValue);

  final String wireValue;

  /// Parses a wire value into a [PrSyncStatus].
  static PrSyncStatus fromWire(String? raw) {
    return PrSyncStatus.values.firstWhere(
      (PrSyncStatus s) => s.wireValue == raw,
      orElse: () => PrSyncStatus.pendingUpload,
    );
  }
}

/// Business lifecycle status of a purchase requisition (RDA / PR).
enum PrStatus {
  draft('draft'),
  pendingApproval('pending_approval'),
  approved('approved'),
  rejected('rejected'),
  budgetExceeded('budget_exceeded'),
  convertedToRdo('converted_to_rdo'),
  convertedToPo('converted_to_po'),
  cancelled('cancelled');

  const PrStatus(this.wireValue);

  final String wireValue;

  /// Parses a wire value into a [PrStatus].
  static PrStatus fromWire(String? raw) {
    return PrStatus.values.firstWhere(
      (PrStatus s) => s.wireValue == raw,
      orElse: () => PrStatus.draft,
    );
  }
}

/// Priority/urgency of a purchase requisition.
enum PrUrgency {
  low('low'),
  normal('normal'),
  high('high'),
  critical('critical');

  const PrUrgency(this.wireValue);

  final String wireValue;

  /// Parses a wire value into a [PrUrgency].
  static PrUrgency fromWire(String? raw) {
    return PrUrgency.values.firstWhere(
      (PrUrgency u) => u.wireValue == raw,
      orElse: () => PrUrgency.normal,
    );
  }
}

/// Source type of a purchase requisition line item.
enum PrItemType {
  catalogItem('catalog_item'),
  freeText('free_text');

  const PrItemType(this.wireValue);

  final String wireValue;

  /// Parses a wire value into a [PrItemType].
  static PrItemType fromWire(String? raw) {
    return PrItemType.values.firstWhere(
      (PrItemType t) => t.wireValue == raw,
      orElse: () => PrItemType.freeText,
    );
  }
}

/// Supported purchase requisition currencies (`CHF` and `EUR`).
enum PrCurrency {
  chf('CHF'),
  eur('EUR');

  const PrCurrency(this.wireValue);

  final String wireValue;

  /// Parses a currency code into a [PrCurrency], defaulting to [PrCurrency.chf].
  static PrCurrency fromWire(String? raw) {
    final String normalized = (raw ?? '').trim().toUpperCase();
    return PrCurrency.values.firstWhere(
      (PrCurrency c) => c.wireValue == normalized,
      orElse: () => PrCurrency.chf,
    );
  }
}

/// Reference to a downstream procurement document (`RDO` Mod 045 or `PO` Mod 046).
class LinkedDocumentRef {
  const LinkedDocumentRef({
    required this.id,
    required this.number,
    required this.type,
  });

  final String id;
  final String number;

  /// `'rdo'` or `'po'`.
  final String type;
}

/// One line item belonging to a [PurchaseRequisition].
class PurchaseRequisitionLine {
  const PurchaseRequisitionLine({
    required this.localId,
    required this.lineNumber,
    required this.itemType,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.uom,
    this.remoteId,
    this.catalogItemId,
    this.catalogSku,
    this.notes,
  });

  final String localId;
  final String? remoteId;
  final int lineNumber;
  final PrItemType itemType;
  final String? catalogItemId;
  final String? catalogSku;
  final String description;
  final double quantity;
  final double unitPrice;
  final String uom;
  final String? notes;

  /// Extended amount for this line (`quantity * unitPrice`).
  double get lineTotal => quantity * unitPrice;

  /// Returns a modified copy of this line item.
  PurchaseRequisitionLine copyWith({
    String? localId,
    String? remoteId,
    int? lineNumber,
    PrItemType? itemType,
    String? catalogItemId,
    String? catalogSku,
    String? description,
    double? quantity,
    double? unitPrice,
    String? uom,
    String? notes,
  }) {
    return PurchaseRequisitionLine(
      localId: localId ?? this.localId,
      remoteId: remoteId ?? this.remoteId,
      lineNumber: lineNumber ?? this.lineNumber,
      itemType: itemType ?? this.itemType,
      catalogItemId: catalogItemId ?? this.catalogItemId,
      catalogSku: catalogSku ?? this.catalogSku,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      uom: uom ?? this.uom,
      notes: notes ?? this.notes,
    );
  }
}

/// Immutable Purchase Requisition (RDA / PR) aggregate root.
class PurchaseRequisition {
  const PurchaseRequisition({
    required this.localId,
    required this.tenantId,
    required this.requesterId,
    required this.requesterName,
    required this.costCenterId,
    required this.costCenterCode,
    required this.costCenterName,
    required this.urgency,
    required this.justification,
    required this.currency,
    required this.totalAmount,
    required this.status,
    required this.syncStatus,
    required this.pendingSubmit,
    required this.lines,
    required this.approvalSteps,
    required this.createdAt,
    required this.updatedAt,
    this.remoteId,
    this.requisitionNumber,
    this.projectId,
    this.projectCode,
    this.projectName,
    this.requestedDeliveryDate,
    this.syncError,
    this.budgetCheck,
    this.linkedRdo,
    this.linkedPo,
    this.serverUpdatedAt,
  });

  final String localId;
  final String? remoteId;
  final String tenantId;
  final String? requisitionNumber;
  final String requesterId;
  final String requesterName;
  final String costCenterId;
  final String costCenterCode;
  final String costCenterName;
  final String? projectId;
  final String? projectCode;
  final String? projectName;
  final PrUrgency urgency;
  final DateTime? requestedDeliveryDate;
  final String justification;
  final PrCurrency currency;
  final double totalAmount;
  final PrStatus status;
  final PrSyncStatus syncStatus;
  final String? syncError;
  final bool pendingSubmit;
  final List<PurchaseRequisitionLine> lines;
  final BudgetCheckResult? budgetCheck;
  final List<ApprovalLevelStep> approvalSteps;
  final LinkedDocumentRef? linkedRdo;
  final LinkedDocumentRef? linkedPo;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? serverUpdatedAt;

  /// Sum of all line totals.
  double get computedTotal => lines.fold<double>(
    0,
    (double acc, PurchaseRequisitionLine line) => acc + line.lineTotal,
  );

  /// Canonical identifier used for routing and API calls once synced.
  String get effectiveId =>
      (remoteId != null && remoteId!.isNotEmpty) ? remoteId! : localId;

  /// Whether the user can still modify or resubmit this requisition.
  bool get isEditable =>
      status == PrStatus.draft || status == PrStatus.budgetExceeded;

  /// Returns a modified copy of this requisition.
  PurchaseRequisition copyWith({
    String? localId,
    String? remoteId,
    String? tenantId,
    String? requisitionNumber,
    String? requesterId,
    String? requesterName,
    String? costCenterId,
    String? costCenterCode,
    String? costCenterName,
    String? projectId,
    bool clearProject = false,
    String? projectCode,
    String? projectName,
    PrUrgency? urgency,
    DateTime? requestedDeliveryDate,
    bool clearDeliveryDate = false,
    String? justification,
    PrCurrency? currency,
    double? totalAmount,
    PrStatus? status,
    PrSyncStatus? syncStatus,
    String? syncError,
    bool clearSyncError = false,
    bool? pendingSubmit,
    List<PurchaseRequisitionLine>? lines,
    BudgetCheckResult? budgetCheck,
    bool clearBudgetCheck = false,
    List<ApprovalLevelStep>? approvalSteps,
    LinkedDocumentRef? linkedRdo,
    LinkedDocumentRef? linkedPo,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? serverUpdatedAt,
  }) {
    return PurchaseRequisition(
      localId: localId ?? this.localId,
      remoteId: remoteId ?? this.remoteId,
      tenantId: tenantId ?? this.tenantId,
      requisitionNumber: requisitionNumber ?? this.requisitionNumber,
      requesterId: requesterId ?? this.requesterId,
      requesterName: requesterName ?? this.requesterName,
      costCenterId: costCenterId ?? this.costCenterId,
      costCenterCode: costCenterCode ?? this.costCenterCode,
      costCenterName: costCenterName ?? this.costCenterName,
      projectId: clearProject ? null : (projectId ?? this.projectId),
      projectCode: clearProject ? null : (projectCode ?? this.projectCode),
      projectName: clearProject ? null : (projectName ?? this.projectName),
      urgency: urgency ?? this.urgency,
      requestedDeliveryDate: clearDeliveryDate
          ? null
          : (requestedDeliveryDate ?? this.requestedDeliveryDate),
      justification: justification ?? this.justification,
      currency: currency ?? this.currency,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      syncStatus: syncStatus ?? this.syncStatus,
      syncError: clearSyncError ? null : (syncError ?? this.syncError),
      pendingSubmit: pendingSubmit ?? this.pendingSubmit,
      lines: lines ?? this.lines,
      budgetCheck: clearBudgetCheck ? null : (budgetCheck ?? this.budgetCheck),
      approvalSteps: approvalSteps ?? this.approvalSteps,
      linkedRdo: linkedRdo ?? this.linkedRdo,
      linkedPo: linkedPo ?? this.linkedPo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      serverUpdatedAt: serverUpdatedAt ?? this.serverUpdatedAt,
    );
  }
}
