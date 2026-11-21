// ignore_for_file: deprecated_member_use

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get prModuleTitle => 'Purchase Requisitions';

  @override
  String get prHubTitle => 'Purchase Requisitions';

  @override
  String get prTabMyRequests => 'My Requests';

  @override
  String get prTabToApprove => 'To Approve';

  @override
  String get prEmptyMyRequests => 'No purchase requisitions yet';

  @override
  String get prEmptyToApprove => 'No requisitions waiting for your approval';

  @override
  String get prCreateAction => 'New Requisition';

  @override
  String get prRefreshTooltip => 'Refresh';

  @override
  String get prDraftLocalNumber => 'Local Draft';

  @override
  String get prOfflineBanner =>
      'Offline mode: drafts and approvals will sync automatically when online';

  @override
  String get prStatusDraft => 'Draft';

  @override
  String get prStatusPendingApproval => 'Pending Approval';

  @override
  String get prStatusApproved => 'Approved';

  @override
  String get prStatusRejected => 'Rejected';

  @override
  String get prStatusBudgetExceeded => 'Budget Exceeded';

  @override
  String get prStatusConvertedToRdo => 'Converted to RDO';

  @override
  String get prStatusConvertedToPo => 'Converted to PO';

  @override
  String get prStatusCancelled => 'Cancelled';

  @override
  String get prSyncSynced => 'Synced';

  @override
  String get prSyncPendingUpload => 'Pending sync';

  @override
  String get prSyncError => 'Sync error';

  @override
  String get prSyncRetry => 'Retry sync';

  @override
  String get prQueuedForSync => 'Queued for automatic sync when online';

  @override
  String get prDraftSavedOffline => 'Draft saved locally';

  @override
  String get prSubmittedSuccess =>
      'Purchase requisition submitted for approval';

  @override
  String prSyncCompletedSubmitted(String number) {
    return 'Requisition $number synced and submitted';
  }

  @override
  String prSyncCompletedBudgetBlocked(String number) {
    return 'Requisition $number blocked by budget check after sync';
  }

  @override
  String get prSyncCompletedApproval => 'Approval decision synced';

  @override
  String get prUrgencyLow => 'Low';

  @override
  String get prUrgencyNormal => 'Normal';

  @override
  String get prUrgencyHigh => 'High';

  @override
  String get prUrgencyCritical => 'Critical';

  @override
  String prLinkedRdoLabel(String number) {
    return 'RDO $number';
  }

  @override
  String prLinkedPoLabel(String number) {
    return 'PO $number';
  }

  @override
  String get prLinkedDocumentsTitle => 'Linked Procurement Documents';

  @override
  String get prCreateTitle => 'New Purchase Requisition';

  @override
  String get prEditTitle => 'Edit Requisition';

  @override
  String get prCostCenterLabel => 'Cost Center';

  @override
  String get prCostCenterRequired => 'Select a Cost Center';

  @override
  String get prProjectLabel => 'Project (Optional)';

  @override
  String get prProjectNone => 'No project';

  @override
  String get prUrgencyLabel => 'Urgency';

  @override
  String get prCurrencyLabel => 'Currency';

  @override
  String get prDeliveryDateLabel => 'Requested Delivery Date';

  @override
  String get prDeliveryDateHint => 'Select date';

  @override
  String get prJustificationLabel => 'Economic Justification';

  @override
  String get prJustificationHint =>
      'Explain business need or operational impact';

  @override
  String get prJustificationRequired =>
      'Economic justification is required to submit';

  @override
  String get prLinesSectionTitle => 'Line Items';

  @override
  String get prLinesEmpty => 'No line items added yet';

  @override
  String get prLinesRequired => 'Add at least one line item before submitting';

  @override
  String get prAddLineAction => 'Add Item';

  @override
  String get prScanBarcodeAction => 'Scan Barcode';

  @override
  String get prSaveDraftOffline => 'Save Draft (Offline)';

  @override
  String get prSubmitForApproval => 'Submit for Approval';

  @override
  String get prTotalAmountLabel => 'Total Amount';

  @override
  String get prLineTypeCatalog => 'Catalog Search';

  @override
  String get prLineTypeFreeText => 'Free-Text Entry';

  @override
  String get prCatalogSearchHint => 'Search catalog by SKU, barcode, or name';

  @override
  String get prCatalogEmpty => 'No matching catalog items found';

  @override
  String prBarcodeMatched(String item) {
    return 'Added catalog item: $item';
  }

  @override
  String prBarcodeNotFound(String code) {
    return 'No catalog item found for code \"$code\"';
  }

  @override
  String get prLineDescriptionLabel => 'Description';

  @override
  String get prLineQuantityLabel => 'Quantity';

  @override
  String get prLineUnitPriceLabel => 'Unit Price';

  @override
  String get prLineUomLabel => 'Unit of Measure';

  @override
  String get prLineNotesLabel => 'Notes (Optional)';

  @override
  String get prLineAddConfirm => 'Add to Requisition';

  @override
  String get prFieldRequired => 'This field is required';

  @override
  String get prInvalidNumber => 'Enter a valid number';

  @override
  String get prMustBePositive => 'Value must be greater than zero';

  @override
  String get prBudgetTitle => 'Cost Center Budget';

  @override
  String get prBudgetOfflineInfo =>
      'Offline: real-time budget check will run automatically upon sync.';

  @override
  String get prBudgetChecking => 'Checking Cost Center budget...';

  @override
  String get prBudgetStatusOk => 'Within Budget';

  @override
  String get prBudgetStatusWarning => 'Budget Warning';

  @override
  String get prBudgetStatusHardBlock => 'Budget Exceeded (Blocked)';

  @override
  String get prBudgetAllocated => 'Allocated';

  @override
  String get prBudgetCommitted => 'Committed';

  @override
  String get prBudgetAvailable => 'Available';

  @override
  String get prBudgetRequested => 'Requested';

  @override
  String get prBudgetRemaining => 'Remaining';

  @override
  String prBudgetUtilization(String percent) {
    return '$percent% utilized';
  }

  @override
  String get prBudgetWarningDialogTitle => 'Budget Threshold Warning';

  @override
  String get prBudgetWarningDialogBody =>
      'This requisition exceeds the Cost Center warning threshold. Do you want to submit it anyway?';

  @override
  String get prBudgetWarningProceed => 'Submit Anyway';

  @override
  String get prBudgetHardBlockSubmitBlocked =>
      'Submission blocked: Cost Center budget exceeded.';

  @override
  String get prDetailTitle => 'Requisition Detail';

  @override
  String get prRequesterLabel => 'Requester';

  @override
  String get prRequestedDateLabel => 'Requested on';

  @override
  String get prApprovalProgressTitle => 'Approval Workflow';

  @override
  String prApprovalLevelLabel(int level) {
    return 'Level $level';
  }

  @override
  String get prApprovalStepApproved => 'Approved';

  @override
  String get prApprovalStepPending => 'Pending';

  @override
  String get prApprovalStepRejected => 'Rejected';

  @override
  String get prApprovalStepWaiting => 'Waiting';

  @override
  String get prAuditTrailTitle => 'Approval Audit Trail';

  @override
  String get prAuditTrailEmpty => 'No approval events recorded yet';

  @override
  String get prAuditActionSubmitted => 'Submitted';

  @override
  String get prAuditActionApproved => 'Approved';

  @override
  String get prAuditActionRejected => 'Rejected';

  @override
  String get prAuditActionBudgetWarning => 'Budget Warning';

  @override
  String get prAuditActionBudgetBlocked => 'Budget Blocked';

  @override
  String get prAuditActionEscalated => 'Escalated';

  @override
  String get prAuditActionConverted => 'Converted';

  @override
  String get prChannelWeb => 'Web';

  @override
  String get prChannelMobileApp => 'Mobile App';

  @override
  String get prChannelMobilePush => 'Push 1-Tap';

  @override
  String get prChannelEmailOneClick => 'Email 1-Click';

  @override
  String get prChannelSystem => 'System';

  @override
  String get prPendingSyncTag => 'Pending sync';

  @override
  String get prApproveOneTap => '1-Tap Approve';

  @override
  String get prRejectAction => 'Reject';

  @override
  String get prApprovedConfirmation => 'Requisition approved';

  @override
  String get prApprovedQueuedOffline =>
      'Approval queued offline and will sync on reconnection';

  @override
  String get prRejectedConfirmation => 'Requisition rejected';

  @override
  String get prRejectedQueuedOffline =>
      'Rejection queued offline and will sync on reconnection';

  @override
  String get prRejectSheetTitle => 'Reject Requisition';

  @override
  String get prRejectReasonLabel => 'Rejection Reason';

  @override
  String get prRejectReasonHint =>
      'Provide a clear reason for rejecting this requisition';

  @override
  String get prRejectReasonRequired => 'A rejection reason is mandatory';

  @override
  String get prRejectConfirmAction => 'Confirm Rejection';

  @override
  String get prCancelAction => 'Cancel';

  @override
  String get prNotFound => 'Purchase requisition not found';

  @override
  String get prGenericError =>
      'Unable to complete the operation. Please try again.';

  @override
  String prLevelBadge(int current, int total) {
    return 'Level $current/$total';
  }
}
