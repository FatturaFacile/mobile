import 'package:drift/drift.dart';

/// Offline-first SQLite header table for Purchase Requisitions (RDA / PR).
@DataClassName('LocalPurchaseRequisitionRow')
class LocalPurchaseRequisitions extends Table {
  @override
  String get tableName => 'local_purchase_requisitions';

  TextColumn get localId => text().named('local_id')();
  TextColumn get remoteId => text().named('remote_id').nullable()();
  TextColumn get tenantId => text().named('tenant_id')();
  TextColumn get requisitionNumber =>
      text().named('requisition_number').nullable()();
  TextColumn get requesterId => text().named('requester_id')();
  TextColumn get requesterName => text().named('requester_name')();
  TextColumn get costCenterId => text().named('cost_center_id')();
  TextColumn get costCenterCode => text().named('cost_center_code')();
  TextColumn get costCenterName => text().named('cost_center_name')();
  TextColumn get projectId => text().named('project_id').nullable()();
  TextColumn get projectCode => text().named('project_code').nullable()();
  TextColumn get projectName => text().named('project_name').nullable()();
  TextColumn get urgency => text().withDefault(const Constant('normal'))();
  DateTimeColumn get requestedDeliveryDate =>
      dateTime().named('requested_delivery_date').nullable()();
  TextColumn get justification => text().withDefault(const Constant(''))();
  TextColumn get currency => text().withDefault(const Constant('CHF'))();
  RealColumn get totalAmount =>
      real().named('total_amount').withDefault(const Constant(0))();
  TextColumn get status => text().withDefault(const Constant('draft'))();

  /// `synced`, `pending_upload`, or `sync_error`.
  TextColumn get syncStatus => text()
      .named('sync_status')
      .withDefault(const Constant('pending_upload'))();
  TextColumn get syncError => text().named('sync_error').nullable()();
  BoolColumn get pendingSubmit =>
      boolean().named('pending_submit').withDefault(const Constant(false))();
  TextColumn get budgetCheckSnapshotJson =>
      text().named('budget_check_snapshot_json').nullable()();
  TextColumn get approvalProgressJson =>
      text().named('approval_progress_json').nullable()();
  TextColumn get linkedRdoId => text().named('linked_rdo_id').nullable()();
  TextColumn get linkedRdoNumber =>
      text().named('linked_rdo_number').nullable()();
  TextColumn get linkedPoId => text().named('linked_po_id').nullable()();
  TextColumn get linkedPoNumber =>
      text().named('linked_po_number').nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
  DateTimeColumn get serverUpdatedAt =>
      dateTime().named('server_updated_at').nullable()();
  DateTimeColumn get deletedAt => dateTime().named('deleted_at').nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{localId};
}

/// Offline-first SQLite line items table for Purchase Requisitions.
@DataClassName('LocalPurchaseRequisitionLineRow')
class LocalPurchaseRequisitionLines extends Table {
  @override
  String get tableName => 'local_purchase_requisition_lines';

  TextColumn get localId => text().named('local_id')();
  TextColumn get remoteId => text().named('remote_id').nullable()();
  TextColumn get tenantId => text().named('tenant_id')();
  TextColumn get requisitionLocalId => text()
      .named('requisition_local_id')
      .references(
        LocalPurchaseRequisitions,
        #localId,
        onDelete: KeyAction.cascade,
      )();
  IntColumn get lineNumber => integer().named('line_number')();

  /// `catalog_item` or `free_text`.
  TextColumn get itemType =>
      text().named('item_type').withDefault(const Constant('free_text'))();
  TextColumn get catalogItemId => text().named('catalog_item_id').nullable()();
  TextColumn get catalogSku => text().named('catalog_sku').nullable()();
  TextColumn get description => text()();
  RealColumn get quantity => real()();
  RealColumn get unitPrice => real().named('unit_price')();
  TextColumn get uom => text().withDefault(const Constant('pz'))();
  RealColumn get lineTotal => real().named('line_total')();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{localId};
}

/// Cached manager pending approvals and queued offline 1-tap approval/rejection decisions.
@DataClassName('LocalPendingApprovalRow')
class LocalPendingApprovals extends Table {
  @override
  String get tableName => 'local_pending_approvals';

  TextColumn get approvalId => text().named('approval_id')();
  TextColumn get tenantId => text().named('tenant_id')();
  TextColumn get requisitionRemoteId => text().named('requisition_remote_id')();
  TextColumn get requisitionNumber => text().named('requisition_number')();
  TextColumn get requesterName => text().named('requester_name')();
  TextColumn get costCenterCode => text().named('cost_center_code')();
  TextColumn get costCenterName => text().named('cost_center_name')();
  TextColumn get projectName => text().named('project_name').nullable()();
  TextColumn get urgency => text().withDefault(const Constant('normal'))();
  RealColumn get totalAmount => real().named('total_amount')();
  TextColumn get currency => text().withDefault(const Constant('CHF'))();
  TextColumn get status =>
      text().withDefault(const Constant('pending_approval'))();
  IntColumn get currentLevel =>
      integer().named('current_level').withDefault(const Constant(1))();
  IntColumn get totalLevels =>
      integer().named('total_levels').withDefault(const Constant(1))();
  TextColumn get budgetStatus =>
      text().named('budget_status').withDefault(const Constant('ok'))();
  TextColumn get oneClickToken => text().named('one_click_token').nullable()();

  /// `'approve'` or `'reject'` while queued offline; `null` when awaiting manager action.
  TextColumn get pendingDecision =>
      text().named('pending_decision').nullable()();
  TextColumn get pendingRejectionReason =>
      text().named('pending_rejection_reason').nullable()();
  TextColumn get syncStatus =>
      text().named('sync_status').withDefault(const Constant('synced'))();
  TextColumn get syncError => text().named('sync_error').nullable()();
  DateTimeColumn get requestedAt => dateTime().named('requested_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{approvalId};
}

/// Cached immutable approval audit trail entries (plus local optimistic pending events).
@DataClassName('LocalApprovalAuditLogRow')
class LocalApprovalAuditLogs extends Table {
  @override
  String get tableName => 'local_approval_audit_logs';

  TextColumn get id => text()();
  TextColumn get tenantId => text().named('tenant_id')();
  TextColumn get requisitionId => text().named('requisition_id')();
  IntColumn get level => integer().withDefault(const Constant(1))();
  TextColumn get action => text()();
  TextColumn get actorId => text().named('actor_id').nullable()();
  TextColumn get actorName => text().named('actor_name')();
  TextColumn get actorRole => text().named('actor_role').nullable()();
  TextColumn get channel => text().withDefault(const Constant('web'))();
  TextColumn get comment => text().nullable()();
  DateTimeColumn get occurredAt => dateTime().named('occurred_at')();
  BoolColumn get isLocalPending =>
      boolean().named('is_local_pending').withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}
