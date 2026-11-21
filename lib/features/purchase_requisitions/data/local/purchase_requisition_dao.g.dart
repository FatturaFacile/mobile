// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchase_requisition_dao.dart';

// ignore_for_file: type=lint
mixin _$PurchaseRequisitionDaoMixin on DatabaseAccessor<AppDatabase> {
  $LocalPurchaseRequisitionsTable get localPurchaseRequisitions =>
      attachedDatabase.localPurchaseRequisitions;
  $LocalPurchaseRequisitionLinesTable get localPurchaseRequisitionLines =>
      attachedDatabase.localPurchaseRequisitionLines;
  $LocalPendingApprovalsTable get localPendingApprovals =>
      attachedDatabase.localPendingApprovals;
  $LocalApprovalAuditLogsTable get localApprovalAuditLogs =>
      attachedDatabase.localApprovalAuditLogs;
  PurchaseRequisitionDaoManager get managers =>
      PurchaseRequisitionDaoManager(this);
}

class PurchaseRequisitionDaoManager {
  final _$PurchaseRequisitionDaoMixin _db;
  PurchaseRequisitionDaoManager(this._db);
  $$LocalPurchaseRequisitionsTableTableManager get localPurchaseRequisitions =>
      $$LocalPurchaseRequisitionsTableTableManager(
        _db.attachedDatabase,
        _db.localPurchaseRequisitions,
      );
  $$LocalPurchaseRequisitionLinesTableTableManager
  get localPurchaseRequisitionLines =>
      $$LocalPurchaseRequisitionLinesTableTableManager(
        _db.attachedDatabase,
        _db.localPurchaseRequisitionLines,
      );
  $$LocalPendingApprovalsTableTableManager get localPendingApprovals =>
      $$LocalPendingApprovalsTableTableManager(
        _db.attachedDatabase,
        _db.localPendingApprovals,
      );
  $$LocalApprovalAuditLogsTableTableManager get localApprovalAuditLogs =>
      $$LocalApprovalAuditLogsTableTableManager(
        _db.attachedDatabase,
        _db.localApprovalAuditLogs,
      );
}
