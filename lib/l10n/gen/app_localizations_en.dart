// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get copilotTitle => 'Copilot';

  @override
  String get copilotTooltip => 'Open Copilot';

  @override
  String get copilotInputHint => 'Ask anything about your ERP…';

  @override
  String get copilotSend => 'Send';

  @override
  String get copilotEmptyTitle => 'How can I help?';

  @override
  String get copilotEmptyBody =>
      'Ask about invoices, stock, due dates or Swiss and Italian regulations.';

  @override
  String get copilotNewChat => 'New conversation';

  @override
  String get copilotHistory => 'History';

  @override
  String get copilotNoHistory => 'No recent conversations';

  @override
  String get copilotUntitled => 'Untitled conversation';

  @override
  String get copilotDeleteConversation => 'Delete conversation';

  @override
  String get copilotOfflineBanner =>
      'You are offline: saved conversations are read-only.';

  @override
  String get copilotThinking => 'Thinking…';

  @override
  String copilotToolRunning(String tool) {
    return 'Running $tool…';
  }

  @override
  String get copilotConfirm => 'Confirm & Execute';

  @override
  String get copilotCancel => 'Cancel';

  @override
  String get copilotActionTitle => 'Proposed action';

  @override
  String get copilotEditableFields => 'Edit values before confirming';

  @override
  String get copilotActionPending => 'Awaiting confirmation';

  @override
  String get copilotActionConfirmed => 'Confirmed';

  @override
  String get copilotActionRejected => 'Cancelled';

  @override
  String get copilotActionExecuted => 'Executed';

  @override
  String get copilotActionFailed => 'Failed';

  @override
  String get copilotSources => 'Sources';

  @override
  String get copilotRouteUnavailable =>
      'This screen is not available in the app.';

  @override
  String get copilotRetry => 'Retry';

  @override
  String get copilotErrForbidden =>
      'You do not have permission to use Copilot or this action.';

  @override
  String get copilotErrNotFound => 'Item not found.';

  @override
  String get copilotErrConflict =>
      'The action was already cancelled or has failed.';

  @override
  String get copilotErrInvalid => 'Invalid values or the action failed.';

  @override
  String get copilotErrRateLimited =>
      'Too many requests or quota exhausted. Try again later.';

  @override
  String get copilotErrProvider => 'The AI model is currently unavailable.';

  @override
  String get copilotErrOffline =>
      'You are offline. Try again when you are back online.';

  @override
  String get copilotErrUnknown => 'Something went wrong.';

  @override
  String get copilotClose => 'Close';

  @override
  String get securityTitle => 'Security';

  @override
  String get securityEncryptionSection => 'Encrypted storage';

  @override
  String get securityDbEncrypted => 'Local database is encrypted';

  @override
  String get securityDbNotEncrypted => 'Local database is not encrypted yet';

  @override
  String securityKeyStored(String backend) {
    return 'Encryption key is stored in $backend';
  }

  @override
  String get securityKeyMissing => 'No encryption key found in secure storage';

  @override
  String get securityBackendKeychain => 'Keychain';

  @override
  String get securityBackendKeystore => 'Android Keystore';

  @override
  String get securityBackendSecure => 'platform secure storage';

  @override
  String get securityLockSection => 'Session lock';

  @override
  String get securityLockEnabled => 'Lock after inactivity';

  @override
  String get securityLockTimeout => 'Lock timeout';

  @override
  String get securityTimeout30s => '30 seconds';

  @override
  String get securityTimeout1m => '1 minute';

  @override
  String get securityTimeout5m => '5 minutes';

  @override
  String get securityTimeout15m => '15 minutes';

  @override
  String get securitySetPin => 'Set PIN';

  @override
  String get securityPinHint => 'PIN (at least 4 digits)';

  @override
  String get securityPinSaved => 'PIN saved';

  @override
  String get securityPinTooShort => 'The PIN must have at least 4 digits.';

  @override
  String get securityNoLockMethod =>
      'Set a PIN or enable biometrics to use the session lock.';

  @override
  String get securityLockNow => 'Lock now';

  @override
  String get securityQueueSection => 'Audit queue';

  @override
  String securityQueuePending(int count) {
    return '$count entries waiting to sync';
  }

  @override
  String get securityQueueAllSynced => 'All audit entries are synced';

  @override
  String securityQueueLastSync(String time) {
    return 'Last sync: $time';
  }

  @override
  String securityQueueError(String error) {
    return 'Last error: $error';
  }

  @override
  String get securitySyncNow => 'Sync now';

  @override
  String get securityVerifyChain => 'Verify chain';

  @override
  String securityChainValid(int count) {
    return 'Audit chain verified ($count entries)';
  }

  @override
  String securityChainBroken(int sequence) {
    return 'Audit chain broken at entry $sequence';
  }

  @override
  String get securityLockedTitle => 'Session locked';

  @override
  String get securityUnlockBiometric => 'Unlock with biometrics';

  @override
  String get securityUnlockReason => 'Authenticate to unlock Fattura Facile';

  @override
  String get securityPinLabel => 'PIN';

  @override
  String get securityUnlock => 'Unlock';

  @override
  String get securityWrongPin => 'Wrong PIN';

  @override
  String get securityTooManyAttempts =>
      'Too many attempts. Try again in a moment.';

  @override
  String get piiUnmaskTitle => 'Reveal protected data';

  @override
  String piiUnmaskBody(String field) {
    return 'Revealing $field is recorded in the audit trail. Enter a justification.';
  }

  @override
  String get piiJustificationLabel => 'Justification (at least 10 characters)';

  @override
  String get piiJustificationTooShort =>
      'The justification must have at least 10 characters.';

  @override
  String get piiUnmaskConfirm => 'Reveal';

  @override
  String get piiUnmaskCancel => 'Cancel';

  @override
  String get piiUnmaskFailed => 'The value could not be revealed.';

  @override
  String get piiUnmaskForbidden => 'You are not allowed to reveal this field.';

  @override
  String get piiUnmaskDemo => 'Reveal protected field';

  @override
  String get cogTitle => 'AI suggestions';

  @override
  String get cogModule => 'AI review';

  @override
  String get cogCaptureHint =>
      'Dictate or type a request, e.g. \"quote 2 chairs for Muster AG\"';

  @override
  String get cogKindLabel => 'Create';

  @override
  String get cogKindSalesQuote => 'Sales quote';

  @override
  String get cogKindPurchaseOrder => 'Purchase order';

  @override
  String get cogKindSupportTicket => 'Support ticket';

  @override
  String get cogKindContact => 'Contact';

  @override
  String get cogKindAccountingCoding => 'Accounting coding';

  @override
  String get cogKindReconciliationMatch => 'Reconciliation match';

  @override
  String get cogKindAnomaly => 'Anomaly';

  @override
  String get cogKindLatePaymentRisk => 'Late payment risk';

  @override
  String get cogKindChurnRisk => 'Churn risk';

  @override
  String get cogKindReorder => 'Reorder';

  @override
  String get cogKindCashFlowAlert => 'Cash flow alert';

  @override
  String get cogKindOther => 'Suggestion';

  @override
  String get cogSend => 'Send';

  @override
  String get cogDictate => 'Dictate';

  @override
  String get cogTextTooShort => 'Write at least 10 characters.';

  @override
  String get cogCaptureSent => 'Sent. The draft is waiting for your review.';

  @override
  String get cogCaptureQueued =>
      'Saved offline. It will be sent when the connection returns.';

  @override
  String cogCaptureRejected(String detail) {
    return 'The request was not accepted: $detail';
  }

  @override
  String cogQueuedCount(int count) {
    return '$count captures waiting to be sent';
  }

  @override
  String get cogDismiss => 'Dismiss';

  @override
  String get cogConfidenceHigh => 'High';

  @override
  String get cogConfidenceMedium => 'Medium';

  @override
  String get cogConfidenceLow => 'Low';

  @override
  String cogConfidence(int percent) {
    return 'Confidence $percent%';
  }

  @override
  String get cogEmpty => 'No suggestions waiting for review';

  @override
  String get cogApprove => 'Approve';

  @override
  String get cogReject => 'Reject';

  @override
  String get cogRejectTitle => 'Reject suggestion';

  @override
  String get cogRejectReason => 'Reason (at least 3 characters)';

  @override
  String get cogReasonTooShort => 'Enter at least 3 characters.';

  @override
  String get cogCancel => 'Cancel';

  @override
  String get cogApproved => 'Suggestion approved.';

  @override
  String get cogRejected => 'Suggestion rejected.';

  @override
  String get cogErrForbidden =>
      'Your role is not allowed to use AI suggestions.';

  @override
  String get cogErrAlreadyDecided =>
      'Already decided by someone else. The list was refreshed.';

  @override
  String cogErrInvalid(String detail) {
    return 'The proposal is incomplete: $detail';
  }

  @override
  String get cogErrOffline =>
      'You are offline. Try again when you are back online.';

  @override
  String get cogErrRateLimited => 'Too many requests. Try again later.';

  @override
  String get cogErrProvider => 'The AI service is unavailable right now.';

  @override
  String get cogErrNotFound => 'This suggestion no longer exists.';

  @override
  String get cogErrUnknown => 'Something went wrong.';

  @override
  String get cogAlertTitle => 'High-priority alert';

  @override
  String get cogAlertReview => 'Review';

  @override
  String get cogPriorityHigh => 'High priority';

  @override
  String get cogRetry => 'Retry';

  @override
  String get cogOfflineCached => 'Showing saved suggestions (offline)';

  @override
  String get dssTitle => 'Executive DSS';

  @override
  String dssSyncedAt(String time) {
    return 'Synced $time';
  }

  @override
  String dssOfflineSince(String time) {
    return 'Offline · synced $time';
  }

  @override
  String get dssNeverSynced => 'Not synced yet';

  @override
  String get dssSyncing => 'Syncing…';

  @override
  String get dssAllEntities => 'All entities';

  @override
  String get dssLegalEntity => 'Legal entity';

  @override
  String get dssCurrency => 'Currency';

  @override
  String get dssPeriodMtd => 'MTD';

  @override
  String get dssPeriodQtd => 'QTD';

  @override
  String get dssPeriodYtd => 'YTD';

  @override
  String get dssPeriodL12m => 'L12M';

  @override
  String get dssKpiRevenue => 'Revenue';

  @override
  String get dssKpiGrossMargin => 'Gross margin %';

  @override
  String get dssKpiEbitda => 'EBITDA';

  @override
  String get dssKpiNetCash => 'Net cash flow';

  @override
  String get dssKpiCcc => 'Cash conversion cycle';

  @override
  String get dssKpiDso => 'DSO';

  @override
  String dssDays(String value) {
    return '$value d';
  }

  @override
  String get dssKpiUnavailable => 'No data source';

  @override
  String get dssNoData => 'No data yet';

  @override
  String get dssNoDataBody =>
      'Connect to the internet and pull down to load the executive figures.';

  @override
  String get dssVsBaseline => 'vs baseline';

  @override
  String get dssAlertsTitle => 'Strategic alerts';

  @override
  String get dssNoAlerts => 'No active alerts.';

  @override
  String get dssSeverityCritical => 'Critical';

  @override
  String get dssSeverityWarning => 'Warning';

  @override
  String get dssSeverityInfo => 'Info';

  @override
  String get dssAlertMarginErosion => 'Gross margin erosion';

  @override
  String get dssAlertDsoSpike => 'DSO spike';

  @override
  String get dssAlertCustomerConcentration => 'Single-customer concentration';

  @override
  String get dssAlertBudgetOverrun => 'Budget overrun';

  @override
  String get dssAlertOutlier => 'Outlier against history';

  @override
  String dssAlertSummaryMarginErosion(String value, String threshold) {
    return 'Gross margin fell $value pts (limit $threshold pts).';
  }

  @override
  String dssAlertSummaryDsoSpike(String value, String threshold) {
    return 'DSO rose by $value days (limit $threshold).';
  }

  @override
  String dssAlertSummaryCustomerConcentration(
    String label,
    String value,
    String threshold,
  ) {
    return '$label is $value% of revenue (limit $threshold%).';
  }

  @override
  String dssAlertSummaryBudgetOverrun(String value, String threshold) {
    return 'Over budget by $value% (limit $threshold%).';
  }

  @override
  String dssAlertSummaryOutlier(String value, String threshold) {
    return 'Deviation of $value σ (threshold $threshold σ).';
  }

  @override
  String get dssRootCause => 'Root cause';

  @override
  String get dssRecommendedAction => 'Recommended action';

  @override
  String get dssCauseMarginErosion =>
      'Cost of goods is growing faster than prices, or the mix is shifting to low-margin products.';

  @override
  String get dssActionMarginErosion =>
      'Review price lists and supplier costs; open the what-if check to size a price increase.';

  @override
  String get dssCauseDsoSpike =>
      'Customers are paying later, or large invoices are overdue.';

  @override
  String get dssActionDsoSpike =>
      'Start dunning on the oldest invoices and agree payment plans with the largest debtors.';

  @override
  String get dssCauseCustomerConcentration =>
      'One customer generates a disproportionate share of revenue.';

  @override
  String get dssActionCustomerConcentration =>
      'Diversify the customer base and secure a long-term contract with this customer.';

  @override
  String get dssCauseBudgetOverrun =>
      'Actual spending on this budget line exceeds the approved amount.';

  @override
  String get dssActionBudgetOverrun =>
      'Freeze discretionary spend on the line and ask the cost-centre owner for a recovery plan.';

  @override
  String get dssCauseOutlier =>
      'The latest value is far from its historical average.';

  @override
  String get dssActionOutlier =>
      'Check the source data for errors, then confirm whether the change is a real trend.';

  @override
  String get dssTopCustomers => 'Top 5 customers';

  @override
  String get dssBottomCustomers => 'Bottom 5 customers';

  @override
  String get dssTopProducts => 'Top 5 products';

  @override
  String get dssBottomProducts => 'Bottom 5 products';

  @override
  String get dssNetMargin => 'Net margin';

  @override
  String get dssParetoCore => 'Core';

  @override
  String get dssValueDestroying => 'Eroding value';

  @override
  String get dssVarianceTitle => 'EBITDA bridge';

  @override
  String get dssVarBaseline => 'Baseline';

  @override
  String get dssVarVolume => 'Volume';

  @override
  String get dssVarPrice => 'Price';

  @override
  String get dssVarCogs => 'COGS';

  @override
  String get dssVarOpex => 'OPEX';

  @override
  String get dssVarFx => 'FX';

  @override
  String get dssVarActual => 'Actual';

  @override
  String get dssWhatIfTitle => 'What-if quick check';

  @override
  String get dssWhatIfPrice => 'Price change';

  @override
  String get dssWhatIfCogs => 'COGS change';

  @override
  String get dssWhatIfCurrent => 'Current';

  @override
  String get dssWhatIfSimulated => 'Simulated EBITDA';

  @override
  String get dssWhatIfChange => 'Change';

  @override
  String get dssWhatIfReset => 'Reset';

  @override
  String get dssWhatIfOnDevice =>
      'Computed on this device from the last synced figures.';

  @override
  String get dssErrUnauthorized => 'Your session has expired. Sign in again.';

  @override
  String get dssErrForbidden => 'You do not have access to the Executive DSS.';

  @override
  String get dssErrFailed =>
      'The server could not provide the figures. Showing the last synced data.';

  @override
  String get dssClose => 'Close';

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

  @override
  String get mfgTitle => 'Shop floor';

  @override
  String get mfgOrdersEmpty =>
      'No released production orders on this device. Refresh when online.';

  @override
  String get mfgScanPrompt => 'Scan an order, lot or machine';

  @override
  String get mfgScanButton => 'Scan';

  @override
  String get mfgScanManualHint => 'Type or scan a code';

  @override
  String mfgScanUnknown(String code) {
    return 'Code not recognised: $code';
  }

  @override
  String mfgScanOrderNotFound(String code) {
    return 'Order $code is not on this device. Refresh when online.';
  }

  @override
  String mfgScanMachineNotFound(String code) {
    return 'Machine $code is unknown.';
  }

  @override
  String get mfgScanSelectOrderFirst => 'Select a production order first.';

  @override
  String get mfgCameraTitle => 'Point the camera at the code';

  @override
  String get mfgCameraUnavailable =>
      'Camera not available. Type the code instead.';

  @override
  String get mfgOperations => 'Operations';

  @override
  String get mfgMaterials => 'Materials';

  @override
  String get mfgQuality => 'Quality';

  @override
  String get mfgReceipt => 'Receive output';

  @override
  String get mfgGenealogy => 'Genealogy';

  @override
  String get mfgGenealogyOffline => 'Genealogy needs a connection.';

  @override
  String mfgProgress(String done, String target, String uom) {
    return '$done of $target $uom';
  }

  @override
  String mfgOpenQty(String qty, String uom) {
    return 'Open: $qty $uom';
  }

  @override
  String get mfgStagedLots => 'Staged lots';

  @override
  String get mfgNoStaged => 'No lots staged. Scan a raw-material label.';

  @override
  String mfgSelectLine(String lot) {
    return 'Which material does lot $lot belong to?';
  }

  @override
  String mfgLotStaged(String lot) {
    return 'Lot $lot staged';
  }

  @override
  String get mfgQuantity => 'Quantity';

  @override
  String get mfgBackflush => 'Backflush';

  @override
  String mfgBackflushQueued(int count) {
    return '$count issues queued';
  }

  @override
  String get mfgPosted => 'posted';

  @override
  String get mfgCheckIn => 'Check in to machine';

  @override
  String mfgCheckedIn(String machine) {
    return 'Checked in: $machine';
  }

  @override
  String get mfgSetup => 'Setup';

  @override
  String get mfgRun => 'Run';

  @override
  String get mfgStartSetup => 'Start setup';

  @override
  String get mfgStartRun => 'Start run';

  @override
  String get mfgPause => 'Pause';

  @override
  String get mfgResume => 'Resume';

  @override
  String get mfgPhaseIdle => 'Idle';

  @override
  String get mfgPhaseSetup => 'Setup in progress';

  @override
  String get mfgPhaseRun => 'Running';

  @override
  String get mfgPhasePaused => 'Paused';

  @override
  String get mfgDowntime => 'Downtime';

  @override
  String get mfgGood => 'Good';

  @override
  String get mfgScrap => 'Scrap';

  @override
  String get mfgScrapReason => 'Scrap reason';

  @override
  String get mfgFinalOperation => 'Last confirmation of this operation';

  @override
  String get mfgConfirm => 'Confirm operation';

  @override
  String get mfgConfirmQueued =>
      'Saved. It will be sent as soon as you are online.';

  @override
  String get mfgErrNothingToPost => 'Nothing to confirm yet.';

  @override
  String get mfgErrScrapReason => 'Enter a reason for the scrap.';

  @override
  String get mfgErrQuantity => 'Enter a quantity greater than zero.';

  @override
  String get mfgErrNotExecutable =>
      'This order is not released for production.';

  @override
  String get mfgQcTitle => 'QC checklist';

  @override
  String get mfgQcPlan => 'Inspection plan';

  @override
  String get mfgQcNoPlans => 'No inspection plans on this device.';

  @override
  String get mfgQcMeasured => 'Measured value';

  @override
  String mfgQcTolerance(String min, String max) {
    return 'Tolerance $min to $max';
  }

  @override
  String get mfgQcInTolerance => 'In tolerance';

  @override
  String get mfgQcOutOfTolerance => 'Out of tolerance';

  @override
  String get mfgQcInspected => 'Quantity inspected';

  @override
  String get mfgQcNotes => 'Notes';

  @override
  String get mfgQcSignOff => 'Sign off';

  @override
  String get mfgQcSignOffQueued => 'Inspection signed off and queued.';

  @override
  String get mfgReceiptLot => 'Lot number';

  @override
  String get mfgReceiptQueued => 'Receipt queued.';

  @override
  String mfgSyncPending(int count) {
    return '$count waiting to send';
  }

  @override
  String get mfgSyncAllSent => 'Everything sent';

  @override
  String get mfgSyncNow => 'Sync now';

  @override
  String get mfgRefresh => 'Refresh';

  @override
  String get mfgRefreshFailed => 'Could not refresh. Showing saved data.';

  @override
  String get mfgQueueTitle => 'Send queue';

  @override
  String get mfgQueueEmpty => 'Nothing waiting to be sent.';

  @override
  String get mfgQueueRejected => 'Refused by the server';

  @override
  String mfgQueueRetryAt(String time) {
    return 'Retrying at $time';
  }

  @override
  String get mfgQueueRetry => 'Retry';

  @override
  String get mfgQueueDiscard => 'Discard';

  @override
  String get mfgKindIssue => 'Material issue';

  @override
  String get mfgKindConfirm => 'Operation confirmation';

  @override
  String get mfgKindReceipt => 'Output receipt';

  @override
  String get mfgKindCheckIn => 'Machine check-in';

  @override
  String get mfgKindInspection => 'QC inspection';

  @override
  String get mfgStatusReleased => 'Released';

  @override
  String get mfgStatusInProgress => 'In progress';

  @override
  String get mfgCancel => 'Cancel';

  @override
  String get mfgAdd => 'Add';
}
