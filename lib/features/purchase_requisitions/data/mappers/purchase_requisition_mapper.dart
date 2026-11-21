import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/approval_models.dart';
import '../../domain/entities/budget_check.dart';
import '../../domain/entities/pr_reference_models.dart';
import '../../domain/entities/purchase_requisition.dart';
import '../local/purchase_requisition_dao.dart';

/// Bidirectional mapper across Domain entities, Drift SQLite rows, and REST JSON payloads.
abstract final class PurchaseRequisitionMapper {
  /// Maps a Drift joined row into a domain [PurchaseRequisition].
  static PurchaseRequisition fromRow(LocalPurchaseRequisitionWithLines row) {
    final LocalPurchaseRequisitionRow h = row.header;
    return PurchaseRequisition(
      localId: h.localId,
      remoteId: h.remoteId,
      tenantId: h.tenantId,
      requisitionNumber: h.requisitionNumber,
      requesterId: h.requesterId,
      requesterName: h.requesterName,
      costCenterId: h.costCenterId,
      costCenterCode: h.costCenterCode,
      costCenterName: h.costCenterName,
      projectId: h.projectId,
      projectCode: h.projectCode,
      projectName: h.projectName,
      urgency: PrUrgency.fromWire(h.urgency),
      requestedDeliveryDate: h.requestedDeliveryDate,
      justification: h.justification,
      currency: PrCurrency.fromWire(h.currency),
      totalAmount: h.totalAmount,
      status: PrStatus.fromWire(h.status),
      syncStatus: PrSyncStatus.fromWire(h.syncStatus),
      syncError: h.syncError,
      pendingSubmit: h.pendingSubmit,
      lines: row.lines.map(lineFromRow).toList(),
      budgetCheck: decodeBudgetCheck(h.budgetCheckSnapshotJson),
      approvalSteps: decodeApprovalSteps(h.approvalProgressJson),
      linkedRdo: (h.linkedRdoNumber != null && h.linkedRdoNumber!.isNotEmpty)
          ? LinkedDocumentRef(
              id: h.linkedRdoId ?? '',
              number: h.linkedRdoNumber!,
              type: 'rdo',
            )
          : null,
      linkedPo: (h.linkedPoNumber != null && h.linkedPoNumber!.isNotEmpty)
          ? LinkedDocumentRef(
              id: h.linkedPoId ?? '',
              number: h.linkedPoNumber!,
              type: 'po',
            )
          : null,
      createdAt: h.createdAt,
      updatedAt: h.updatedAt,
      serverUpdatedAt: h.serverUpdatedAt,
    );
  }

  /// Maps a Drift line row into a domain [PurchaseRequisitionLine].
  static PurchaseRequisitionLine lineFromRow(
    LocalPurchaseRequisitionLineRow row,
  ) {
    return PurchaseRequisitionLine(
      localId: row.localId,
      remoteId: row.remoteId,
      lineNumber: row.lineNumber,
      itemType: PrItemType.fromWire(row.itemType),
      catalogItemId: row.catalogItemId,
      catalogSku: row.catalogSku,
      description: row.description,
      quantity: row.quantity,
      unitPrice: row.unitPrice,
      uom: row.uom,
      notes: row.notes,
    );
  }

  /// Maps a domain [PurchaseRequisition] into Drift companions for transactional upsert.
  static ({
    LocalPurchaseRequisitionsCompanion header,
    List<LocalPurchaseRequisitionLinesCompanion> lines,
  })
  toCompanions(PurchaseRequisition pr) {
    final LocalPurchaseRequisitionsCompanion header =
        LocalPurchaseRequisitionsCompanion(
          localId: Value<String>(pr.localId),
          remoteId: Value<String?>(pr.remoteId),
          tenantId: Value<String>(pr.tenantId),
          requisitionNumber: Value<String?>(pr.requisitionNumber),
          requesterId: Value<String>(pr.requesterId),
          requesterName: Value<String>(pr.requesterName),
          costCenterId: Value<String>(pr.costCenterId),
          costCenterCode: Value<String>(pr.costCenterCode),
          costCenterName: Value<String>(pr.costCenterName),
          projectId: Value<String?>(pr.projectId),
          projectCode: Value<String?>(pr.projectCode),
          projectName: Value<String?>(pr.projectName),
          urgency: Value<String>(pr.urgency.wireValue),
          requestedDeliveryDate: Value<DateTime?>(pr.requestedDeliveryDate),
          justification: Value<String>(pr.justification),
          currency: Value<String>(pr.currency.wireValue),
          totalAmount: Value<double>(pr.totalAmount),
          status: Value<String>(pr.status.wireValue),
          syncStatus: Value<String>(pr.syncStatus.wireValue),
          syncError: Value<String?>(pr.syncError),
          pendingSubmit: Value<bool>(pr.pendingSubmit),
          budgetCheckSnapshotJson: Value<String?>(
            encodeBudgetCheck(pr.budgetCheck),
          ),
          approvalProgressJson: Value<String?>(
            encodeApprovalSteps(pr.approvalSteps),
          ),
          linkedRdoId: Value<String?>(pr.linkedRdo?.id),
          linkedRdoNumber: Value<String?>(pr.linkedRdo?.number),
          linkedPoId: Value<String?>(pr.linkedPo?.id),
          linkedPoNumber: Value<String?>(pr.linkedPo?.number),
          createdAt: Value<DateTime>(pr.createdAt),
          updatedAt: Value<DateTime>(pr.updatedAt),
          serverUpdatedAt: Value<DateTime?>(pr.serverUpdatedAt),
          deletedAt: const Value<DateTime?>(null),
        );

    final List<LocalPurchaseRequisitionLinesCompanion> lines = pr.lines
        .map(
          (PurchaseRequisitionLine line) =>
              LocalPurchaseRequisitionLinesCompanion(
                localId: Value<String>(line.localId),
                remoteId: Value<String?>(line.remoteId),
                tenantId: Value<String>(pr.tenantId),
                requisitionLocalId: Value<String>(pr.localId),
                lineNumber: Value<int>(line.lineNumber),
                itemType: Value<String>(line.itemType.wireValue),
                catalogItemId: Value<String?>(line.catalogItemId),
                catalogSku: Value<String?>(line.catalogSku),
                description: Value<String>(line.description),
                quantity: Value<double>(line.quantity),
                unitPrice: Value<double>(line.unitPrice),
                uom: Value<String>(line.uom),
                lineTotal: Value<double>(line.lineTotal),
                notes: Value<String?>(line.notes),
              ),
        )
        .toList();

    return (header: header, lines: lines);
  }

  /// Serializes a [PurchaseRequisition] into the REST API POST/PUT request body.
  static Map<String, dynamic> toApiRequestBody(PurchaseRequisition pr) {
    return <String, dynamic>{
      'local_id': pr.localId,
      'cost_center_id': pr.costCenterId,
      if (pr.projectId != null && pr.projectId!.isNotEmpty)
        'project_id': pr.projectId,
      'urgency': pr.urgency.wireValue,
      if (pr.requestedDeliveryDate != null)
        'requested_delivery_date': pr.requestedDeliveryDate!
            .toIso8601String()
            .substring(0, 10),
      'justification': pr.justification,
      'currency': pr.currency.wireValue,
      'lines': pr.lines
          .map(
            (PurchaseRequisitionLine l) => <String, dynamic>{
              if (l.remoteId != null) 'id': l.remoteId,
              'line_number': l.lineNumber,
              'item_type': l.itemType.wireValue,
              if (l.catalogItemId != null) 'catalog_item_id': l.catalogItemId,
              if (l.catalogSku != null) 'catalog_sku': l.catalogSku,
              'description': l.description,
              'quantity': l.quantity,
              'unit_price': l.unitPrice,
              'uom': l.uom,
              if (l.notes != null && l.notes!.isNotEmpty) 'notes': l.notes,
            },
          )
          .toList(),
    };
  }

  /// Parses an API PR JSON object into a [ServerRequisitionWrite] and extracted audit logs.
  static ({
    ServerRequisitionWrite write,
    PurchaseRequisition domain,
    List<LocalApprovalAuditLogsCompanion> auditLogs,
  })
  fromApiJson(
    Map<String, dynamic> json, {
    required String tenantId,
    String? fallbackLocalId,
    List<PurchaseRequisitionLine>? fallbackLines,
  }) {
    final DateTime now = DateTime.now().toUtc();
    final String remoteId = _str(json['id']) ?? '';
    final String localId =
        _str(json['local_id']) ?? fallbackLocalId ?? remoteId;

    final Map<String, dynamic>? costCenterMap = _asMap(json['cost_center']);
    final Map<String, dynamic>? projectMap = _asMap(json['project']);
    final Map<String, dynamic>? requesterMap = _asMap(json['requester']);
    final Map<String, dynamic>? budgetMap = _asMap(json['budget_check']);
    final Map<String, dynamic>? linkedRdoMap = _asMap(json['linked_rdo']);
    final Map<String, dynamic>? linkedPoMap = _asMap(json['linked_po']);

    final bool hasLinesKey = json.containsKey('lines') && json['lines'] is List;
    final List<dynamic> rawLines =
        (json['lines'] as List<dynamic>?) ?? <dynamic>[];
    final List<PurchaseRequisitionLine> lines = <PurchaseRequisitionLine>[];
    if (!hasLinesKey && fallbackLines != null) {
      lines.addAll(fallbackLines);
    }
    for (int i = 0; i < rawLines.length; i++) {
      final Map<String, dynamic>? lineMap = _asMap(rawLines[i]);
      if (lineMap == null) {
        continue;
      }
      final String? lineRemoteId = _str(lineMap['id']);
      final String lineLocalId =
          _str(lineMap['local_id']) ?? lineRemoteId ?? '$localId-line-${i + 1}';
      lines.add(
        PurchaseRequisitionLine(
          localId: lineLocalId,
          remoteId: lineRemoteId,
          lineNumber: (lineMap['line_number'] as num?)?.toInt() ?? (i + 1),
          itemType: PrItemType.fromWire(_str(lineMap['item_type'])),
          catalogItemId: _str(lineMap['catalog_item_id']),
          catalogSku: _str(lineMap['catalog_sku']),
          description: _str(lineMap['description']) ?? '',
          quantity: _toDouble(lineMap['quantity'], fallback: 1),
          unitPrice: _toDouble(lineMap['unit_price']),
          uom: _str(lineMap['uom']) ?? 'pz',
          notes: _str(lineMap['notes']),
        ),
      );
    }

    final List<dynamic> rawSteps =
        (json['approval_steps'] as List<dynamic>?) ??
        (json['approval_progress'] as List<dynamic>?) ??
        <dynamic>[];
    final List<ApprovalLevelStep> steps = rawSteps
        .map(_asMap)
        .whereType<Map<String, dynamic>>()
        .map(ApprovalLevelStep.fromJson)
        .toList();

    final BudgetCheckResult? budgetCheck = budgetMap != null
        ? BudgetCheckResult.fromJson(budgetMap)
        : null;
    final double computedTotal = lines.fold<double>(
      0,
      (double s, PurchaseRequisitionLine l) => s + l.lineTotal,
    );
    final double totalAmount = json['total_amount'] != null
        ? _toDouble(json['total_amount'])
        : computedTotal;

    final LinkedDocumentRef? linkedRdo =
        linkedRdoMap != null && _str(linkedRdoMap['number']) != null
        ? LinkedDocumentRef(
            id: _str(linkedRdoMap['id']) ?? '',
            number: _str(linkedRdoMap['number'])!,
            type: 'rdo',
          )
        : (_str(json['linked_rdo_number']) != null
              ? LinkedDocumentRef(
                  id: _str(json['linked_rdo_id']) ?? '',
                  number: _str(json['linked_rdo_number'])!,
                  type: 'rdo',
                )
              : null);

    final LinkedDocumentRef? linkedPo =
        linkedPoMap != null && _str(linkedPoMap['number']) != null
        ? LinkedDocumentRef(
            id: _str(linkedPoMap['id']) ?? '',
            number: _str(linkedPoMap['number'])!,
            type: 'po',
          )
        : (_str(json['linked_po_number']) != null
              ? LinkedDocumentRef(
                  id: _str(json['linked_po_id']) ?? '',
                  number: _str(json['linked_po_number'])!,
                  type: 'po',
                )
              : null);

    final DateTime createdAt =
        DateTime.tryParse(_str(json['created_at']) ?? '') ?? now;
    final DateTime updatedAt =
        DateTime.tryParse(_str(json['updated_at']) ?? '') ?? now;

    final PurchaseRequisition domain = PurchaseRequisition(
      localId: localId,
      remoteId: remoteId.isEmpty ? null : remoteId,
      tenantId: tenantId,
      requisitionNumber:
          _str(json['requisition_number']) ?? _str(json['number']),
      requesterId:
          _str(json['requester_id']) ?? _str(requesterMap?['id']) ?? '',
      requesterName:
          _str(json['requester_name']) ?? _str(requesterMap?['name']) ?? '',
      costCenterId:
          _str(json['cost_center_id']) ?? _str(costCenterMap?['id']) ?? '',
      costCenterCode:
          _str(json['cost_center_code']) ?? _str(costCenterMap?['code']) ?? '',
      costCenterName:
          _str(json['cost_center_name']) ?? _str(costCenterMap?['name']) ?? '',
      projectId: _str(json['project_id']) ?? _str(projectMap?['id']),
      projectCode: _str(json['project_code']) ?? _str(projectMap?['code']),
      projectName: _str(json['project_name']) ?? _str(projectMap?['name']),
      urgency: PrUrgency.fromWire(_str(json['urgency'])),
      requestedDeliveryDate: DateTime.tryParse(
        _str(json['requested_delivery_date']) ?? '',
      ),
      justification: _str(json['justification']) ?? '',
      currency: PrCurrency.fromWire(_str(json['currency'])),
      totalAmount: totalAmount,
      status: PrStatus.fromWire(_str(json['status'])),
      syncStatus: PrSyncStatus.synced,
      pendingSubmit: false,
      lines: lines,
      budgetCheck: budgetCheck,
      approvalSteps: steps,
      linkedRdo: linkedRdo,
      linkedPo: linkedPo,
      createdAt: createdAt,
      updatedAt: updatedAt,
      serverUpdatedAt: updatedAt,
    );

    final companions = toCompanions(domain);
    final List<dynamic> rawAuditLogs =
        (json['audit_logs'] as List<dynamic>?) ??
        (json['approval_audit_logs'] as List<dynamic>?) ??
        <dynamic>[];
    final String effectiveReqId = remoteId.isNotEmpty ? remoteId : localId;
    final List<LocalApprovalAuditLogsCompanion> auditCompanions =
        <LocalApprovalAuditLogsCompanion>[];
    for (int i = 0; i < rawAuditLogs.length; i++) {
      final Map<String, dynamic>? logMap = _asMap(rawAuditLogs[i]);
      if (logMap == null) {
        continue;
      }
      auditCompanions.add(
        auditLogFromApiJson(
          logMap,
          tenantId: tenantId,
          requisitionId: effectiveReqId,
          index: i,
        ),
      );
    }

    return (
      write: ServerRequisitionWrite(
        header: companions.header,
        lines: companions.lines,
      ),
      domain: domain,
      auditLogs: auditCompanions,
    );
  }

  /// Maps a Drift [LocalPendingApprovalRow] to a domain [PendingApprovalItem].
  static PendingApprovalItem pendingApprovalFromRow(
    LocalPendingApprovalRow row,
  ) {
    return PendingApprovalItem(
      approvalId: row.approvalId,
      tenantId: row.tenantId,
      requisitionRemoteId: row.requisitionRemoteId,
      requisitionNumber: row.requisitionNumber,
      requesterName: row.requesterName,
      costCenterCode: row.costCenterCode,
      costCenterName: row.costCenterName,
      projectName: row.projectName,
      urgency: PrUrgency.fromWire(row.urgency),
      totalAmount: row.totalAmount,
      currency: PrCurrency.fromWire(row.currency),
      status: PrStatus.fromWire(row.status),
      currentLevel: row.currentLevel,
      totalLevels: row.totalLevels,
      budgetStatus: BudgetCheckStatus.fromWire(row.budgetStatus),
      oneClickToken: row.oneClickToken,
      pendingDecision: row.pendingDecision,
      pendingRejectionReason: row.pendingRejectionReason,
      syncStatus: PrSyncStatus.fromWire(row.syncStatus),
      syncError: row.syncError,
      requestedAt: row.requestedAt,
      updatedAt: row.updatedAt,
    );
  }

  /// Maps an API pending approval item JSON into a Drift companion.
  static LocalPendingApprovalsCompanion pendingApprovalFromApiJson(
    Map<String, dynamic> json, {
    required String tenantId,
  }) {
    final DateTime now = DateTime.now().toUtc();
    final Map<String, dynamic>? requisition =
        _asMap(json['purchase_requisition']) ?? _asMap(json['requisition']);
    final Map<String, dynamic>? costCenter =
        _asMap(json['cost_center']) ?? _asMap(requisition?['cost_center']);
    final Map<String, dynamic>? project =
        _asMap(json['project']) ?? _asMap(requisition?['project']);
    final Map<String, dynamic>? requester =
        _asMap(json['requester']) ?? _asMap(requisition?['requester']);

    final String reqId =
        _str(json['requisition_id']) ??
        _str(json['purchase_requisition_id']) ??
        _str(requisition?['id']) ??
        '';
    final String approvalId =
        _str(json['approval_id']) ?? _str(json['id']) ?? reqId;

    return LocalPendingApprovalsCompanion(
      approvalId: Value<String>(approvalId),
      tenantId: Value<String>(tenantId),
      requisitionRemoteId: Value<String>(reqId),
      requisitionNumber: Value<String>(
        _str(json['requisition_number']) ??
            _str(requisition?['requisition_number']) ??
            _str(requisition?['number']) ??
            reqId,
      ),
      requesterName: Value<String>(
        _str(json['requester_name']) ?? _str(requester?['name']) ?? '',
      ),
      costCenterCode: Value<String>(
        _str(json['cost_center_code']) ?? _str(costCenter?['code']) ?? '',
      ),
      costCenterName: Value<String>(
        _str(json['cost_center_name']) ?? _str(costCenter?['name']) ?? '',
      ),
      projectName: Value<String?>(
        _str(json['project_name']) ?? _str(project?['name']),
      ),
      urgency: Value<String>(
        PrUrgency.fromWire(
          _str(json['urgency']) ?? _str(requisition?['urgency']),
        ).wireValue,
      ),
      totalAmount: Value<double>(
        _toDouble(json['total_amount'] ?? requisition?['total_amount']),
      ),
      currency: Value<String>(
        PrCurrency.fromWire(
          _str(json['currency']) ?? _str(requisition?['currency']),
        ).wireValue,
      ),
      status: Value<String>(
        PrStatus.fromWire(
          _str(json['status']) ??
              _str(requisition?['status']) ??
              'pending_approval',
        ).wireValue,
      ),
      currentLevel: Value<int>((json['current_level'] as num?)?.toInt() ?? 1),
      totalLevels: Value<int>((json['total_levels'] as num?)?.toInt() ?? 1),
      budgetStatus: Value<String>(
        BudgetCheckStatus.fromWire(
          _str(json['budget_status']) ??
              _str(_asMap(json['budget_check'])?['status']),
        ).wireValue,
      ),
      oneClickToken: Value<String?>(_str(json['one_click_token'])),
      pendingDecision: const Value<String?>(null),
      pendingRejectionReason: const Value<String?>(null),
      syncStatus: const Value<String>('synced'),
      syncError: const Value<String?>(null),
      requestedAt: Value<DateTime>(
        DateTime.tryParse(
              _str(json['requested_at']) ?? _str(json['created_at']) ?? '',
            ) ??
            now,
      ),
      updatedAt: Value<DateTime>(
        DateTime.tryParse(_str(json['updated_at']) ?? '') ?? now,
      ),
    );
  }

  /// Maps a Drift [LocalApprovalAuditLogRow] to a domain [ApprovalAuditEntry].
  static ApprovalAuditEntry auditLogFromRow(LocalApprovalAuditLogRow row) {
    return ApprovalAuditEntry(
      id: row.id,
      requisitionId: row.requisitionId,
      level: row.level,
      action: ApprovalActionType.fromWire(row.action),
      actorId: row.actorId,
      actorName: row.actorName,
      actorRole: row.actorRole,
      channel: ApprovalChannel.fromWire(row.channel),
      comment: row.comment,
      occurredAt: row.occurredAt,
      isLocalPending: row.isLocalPending,
    );
  }

  /// Maps an API audit log entry JSON into a Drift companion.
  static LocalApprovalAuditLogsCompanion auditLogFromApiJson(
    Map<String, dynamic> json, {
    required String tenantId,
    required String requisitionId,
    int index = 0,
  }) {
    final DateTime occurredAt =
        DateTime.tryParse(
          _str(json['occurred_at']) ?? _str(json['created_at']) ?? '',
        ) ??
        DateTime.now().toUtc();
    final String id =
        _str(json['id']) ??
        '$requisitionId-audit-$index-${occurredAt.millisecondsSinceEpoch}';
    return LocalApprovalAuditLogsCompanion(
      id: Value<String>(id),
      tenantId: Value<String>(tenantId),
      requisitionId: Value<String>(requisitionId),
      level: Value<int>((json['level'] as num?)?.toInt() ?? 1),
      action: Value<String>(
        ApprovalActionType.fromWire(_str(json['action'])).wireValue,
      ),
      actorId: Value<String?>(_str(json['actor_id'])),
      actorName: Value<String>(
        _str(json['actor_name']) ?? _str(json['approver_name']) ?? '',
      ),
      actorRole: Value<String?>(_str(json['actor_role'])),
      channel: Value<String>(
        ApprovalChannel.fromWire(_str(json['channel'])).wireValue,
      ),
      comment: Value<String?>(_str(json['comment']) ?? _str(json['reason'])),
      occurredAt: Value<DateTime>(occurredAt),
      isLocalPending: const Value<bool>(false),
    );
  }

  /// Decodes cached `budget_check_snapshot_json`.
  static BudgetCheckResult? decodeBudgetCheck(String? rawJson) {
    if (rawJson == null || rawJson.trim().isEmpty) {
      return null;
    }
    try {
      final dynamic decoded = jsonDecode(rawJson);
      if (decoded is Map<String, dynamic>) {
        return BudgetCheckResult.fromJson(decoded);
      }
      if (decoded is Map) {
        return BudgetCheckResult.fromJson(
          decoded.map(
            (dynamic k, dynamic v) => MapEntry<String, dynamic>('$k', v),
          ),
        );
      }
    } on FormatException {
      return null;
    }
    return null;
  }

  /// Encodes a [BudgetCheckResult] to JSON string for SQLite persistence.
  static String? encodeBudgetCheck(BudgetCheckResult? result) {
    return result == null ? null : jsonEncode(result.toJson());
  }

  /// Decodes cached `approval_progress_json`.
  static List<ApprovalLevelStep> decodeApprovalSteps(String? rawJson) {
    if (rawJson == null || rawJson.trim().isEmpty) {
      return <ApprovalLevelStep>[];
    }
    try {
      final dynamic decoded = jsonDecode(rawJson);
      if (decoded is List) {
        return decoded
            .map(_asMap)
            .whereType<Map<String, dynamic>>()
            .map(ApprovalLevelStep.fromJson)
            .toList();
      }
    } on FormatException {
      return <ApprovalLevelStep>[];
    }
    return <ApprovalLevelStep>[];
  }

  /// Encodes approval workflow steps for SQLite persistence.
  static String? encodeApprovalSteps(List<ApprovalLevelStep> steps) {
    if (steps.isEmpty) {
      return null;
    }
    return jsonEncode(steps.map((ApprovalLevelStep s) => s.toJson()).toList());
  }

  /// Maps a Cost Center record JSON into a [CostCenterOption].
  static CostCenterOption costCenterFromJson(Map<String, dynamic> json) {
    return CostCenterOption(
      id: _str(json['id']) ?? '',
      code: _str(json['code']) ?? '',
      name: _str(json['name']) ?? _str(json['title']) ?? '',
      currency: _str(json['currency']) ?? 'CHF',
    );
  }

  /// Maps a Project record JSON into a [ProjectOption].
  static ProjectOption projectFromJson(Map<String, dynamic> json) {
    return ProjectOption(
      id: _str(json['id']) ?? '',
      code: _str(json['code']) ?? '',
      name: _str(json['name']) ?? _str(json['title']) ?? '',
    );
  }

  /// Maps a Product record JSON into a [CatalogItemOption].
  static CatalogItemOption catalogItemFromJson(Map<String, dynamic> json) {
    return CatalogItemOption(
      id: _str(json['id']) ?? '',
      sku: _str(json['sku']) ?? '',
      barcode: _str(json['barcode']) ?? _str(json['ean']),
      name: _str(json['name']) ?? '',
      uom: _str(json['unit_measure']) ?? _str(json['uom']) ?? 'pz',
      unitPrice: _toDouble(
        json['cost_price'] ?? json['unit_price'] ?? json['sale_price'],
      ),
    );
  }

  static Map<String, dynamic>? _asMap(Object? raw) {
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    if (raw is Map) {
      return raw.map(
        (dynamic k, dynamic v) => MapEntry<String, dynamic>('$k', v),
      );
    }
    return null;
  }

  static String? _str(Object? raw) {
    if (raw == null) {
      return null;
    }
    final String value = '$raw'.trim();
    return value.isEmpty ? null : value;
  }

  static double _toDouble(Object? raw, {double fallback = 0}) {
    if (raw is num) {
      return raw.toDouble();
    }
    return double.tryParse(raw?.toString() ?? '') ?? fallback;
  }
}
