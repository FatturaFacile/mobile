import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../design/ff_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/approval_models.dart';
import '../../domain/entities/budget_check.dart';
import '../../domain/entities/purchase_requisition.dart';

/// Shared localized labels, formatting helpers, and design-token color mappings for Mod 044.
abstract final class PrLabels {
  /// Formats a monetary amount in `CHF` or `EUR` using the active locale.
  static String formatAmount(
    BuildContext context,
    double amount,
    PrCurrency currency,
  ) {
    final String locale = Localizations.localeOf(context).languageCode;
    final NumberFormat fmt = NumberFormat.currency(
      locale: locale,
      name: currency.wireValue,
      symbol: currency.wireValue,
      decimalDigits: 2,
    );
    return fmt.format(amount);
  }

  /// Formats a calendar date in short localized style.
  static String formatDate(BuildContext context, DateTime date) {
    final String locale = Localizations.localeOf(context).languageCode;
    return DateFormat.yMMMd(locale).format(date.toLocal());
  }

  /// Formats a timestamp for the audit trail.
  static String formatDateTime(BuildContext context, DateTime dateTime) {
    final String locale = Localizations.localeOf(context).languageCode;
    return DateFormat.yMMMd(locale).add_Hm().format(dateTime.toLocal());
  }

  /// Localized label for [PrStatus].
  static String status(AppLocalizations l10n, PrStatus status) =>
      switch (status) {
        PrStatus.draft => l10n.prStatusDraft,
        PrStatus.pendingApproval => l10n.prStatusPendingApproval,
        PrStatus.approved => l10n.prStatusApproved,
        PrStatus.rejected => l10n.prStatusRejected,
        PrStatus.budgetExceeded => l10n.prStatusBudgetExceeded,
        PrStatus.convertedToRdo => l10n.prStatusConvertedToRdo,
        PrStatus.convertedToPo => l10n.prStatusConvertedToPo,
        PrStatus.cancelled => l10n.prStatusCancelled,
      };

  /// Semantic colors from [FfColors] for [PrStatus].
  static ({Color fg, Color bg}) statusColors(FfColors c, PrStatus status) =>
      switch (status) {
        PrStatus.approved ||
        PrStatus.convertedToRdo ||
        PrStatus.convertedToPo => (fg: c.success, bg: c.successBg),
        PrStatus.pendingApproval => (fg: c.info, bg: c.infoBg),
        PrStatus.budgetExceeded ||
        PrStatus.rejected => (fg: c.danger, bg: c.dangerBg),
        PrStatus.draft ||
        PrStatus.cancelled => (fg: c.neutral, bg: c.neutralBg),
      };

  /// Localized label for [PrSyncStatus].
  static String syncStatus(AppLocalizations l10n, PrSyncStatus syncStatus) =>
      switch (syncStatus) {
        PrSyncStatus.synced => l10n.prSyncSynced,
        PrSyncStatus.pendingUpload => l10n.prSyncPendingUpload,
        PrSyncStatus.syncError => l10n.prSyncError,
      };

  /// Semantic colors from [FfColors] for [PrSyncStatus].
  static ({Color fg, Color bg, IconData icon}) syncColors(
    FfColors c,
    PrSyncStatus syncStatus,
  ) => switch (syncStatus) {
    PrSyncStatus.synced => (
      fg: c.success,
      bg: c.successBg,
      icon: Icons.cloud_done_outlined,
    ),
    PrSyncStatus.pendingUpload => (
      fg: c.warning,
      bg: c.warningBg,
      icon: Icons.cloud_upload_outlined,
    ),
    PrSyncStatus.syncError => (
      fg: c.danger,
      bg: c.dangerBg,
      icon: Icons.sync_problem_outlined,
    ),
  };

  /// Localized label for [PrUrgency].
  static String urgency(AppLocalizations l10n, PrUrgency urgency) =>
      switch (urgency) {
        PrUrgency.low => l10n.prUrgencyLow,
        PrUrgency.normal => l10n.prUrgencyNormal,
        PrUrgency.high => l10n.prUrgencyHigh,
        PrUrgency.critical => l10n.prUrgencyCritical,
      };

  /// Semantic colors from [FfColors] for [PrUrgency].
  static ({Color fg, Color bg}) urgencyColors(FfColors c, PrUrgency urgency) =>
      switch (urgency) {
        PrUrgency.critical => (fg: c.danger, bg: c.dangerBg),
        PrUrgency.high => (fg: c.warning, bg: c.warningBg),
        PrUrgency.normal => (fg: c.info, bg: c.infoBg),
        PrUrgency.low => (fg: c.neutral, bg: c.neutralBg),
      };

  /// Localized label for [BudgetCheckStatus].
  static String budgetStatus(AppLocalizations l10n, BudgetCheckStatus status) =>
      switch (status) {
        BudgetCheckStatus.ok => l10n.prBudgetStatusOk,
        BudgetCheckStatus.warning => l10n.prBudgetStatusWarning,
        BudgetCheckStatus.hardBlock => l10n.prBudgetStatusHardBlock,
      };

  /// Localized label for [ApprovalStepStatus].
  static String stepStatus(AppLocalizations l10n, ApprovalStepStatus status) =>
      switch (status) {
        ApprovalStepStatus.approved => l10n.prApprovalStepApproved,
        ApprovalStepStatus.pending => l10n.prApprovalStepPending,
        ApprovalStepStatus.rejected => l10n.prApprovalStepRejected,
        ApprovalStepStatus.waiting => l10n.prApprovalStepWaiting,
      };

  /// Localized label for [ApprovalActionType].
  static String auditAction(AppLocalizations l10n, ApprovalActionType action) =>
      switch (action) {
        ApprovalActionType.submitted => l10n.prAuditActionSubmitted,
        ApprovalActionType.approved => l10n.prAuditActionApproved,
        ApprovalActionType.rejected => l10n.prAuditActionRejected,
        ApprovalActionType.budgetWarning => l10n.prAuditActionBudgetWarning,
        ApprovalActionType.budgetBlocked => l10n.prAuditActionBudgetBlocked,
        ApprovalActionType.escalated => l10n.prAuditActionEscalated,
        ApprovalActionType.converted => l10n.prAuditActionConverted,
      };

  /// Localized label for [ApprovalChannel].
  static String channel(AppLocalizations l10n, ApprovalChannel channel) =>
      switch (channel) {
        ApprovalChannel.web => l10n.prChannelWeb,
        ApprovalChannel.mobileApp => l10n.prChannelMobileApp,
        ApprovalChannel.mobilePush => l10n.prChannelMobilePush,
        ApprovalChannel.emailOneClick => l10n.prChannelEmailOneClick,
        ApprovalChannel.system => l10n.prChannelSystem,
      };
}
