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
}
