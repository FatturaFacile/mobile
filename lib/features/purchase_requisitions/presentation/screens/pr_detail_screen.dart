import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../design/ff_tokens.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../wms/ui/scan_field.dart' show CameraScanner;
import '../../domain/entities/approval_models.dart';
import '../../domain/entities/purchase_requisition.dart';
import '../providers/pr_detail_controller.dart';
import '../providers/pr_providers.dart';
import '../widgets/pr_approval_progress.dart';
import '../widgets/pr_budget_banner.dart';
import '../widgets/pr_labels.dart';
import '../widgets/pr_reject_bottom_sheet.dart';
import '../widgets/pr_status_chip.dart';
import 'pr_create_screen.dart';

/// Purchase Requisition detail, multi-level approval workflow, audit trail, and manager 1-tap actions.
class PrDetailScreen extends ConsumerStatefulWidget {
  const PrDetailScreen({
    required this.tenantId,
    required this.requisitionId,
    required this.actorId,
    required this.actorName,
    this.approvalId,
    this.oneClickToken,
    this.isManagerApproval = false,
    this.openRejectSheetOnLoad = false,
    this.cameraScanner,
    super.key,
  });

  final String tenantId;
  final String requisitionId;
  final String actorId;
  final String actorName;
  final String? approvalId;
  final String? oneClickToken;
  final bool isManagerApproval;
  final bool openRejectSheetOnLoad;
  final CameraScanner? cameraScanner;

  @override
  ConsumerState<PrDetailScreen> createState() => _PrDetailScreenState();
}

class _PrDetailScreenState extends ConsumerState<PrDetailScreen> {
  late final PrDetailArgs _args;

  @override
  void initState() {
    super.initState();
    _args = PrDetailArgs(
      tenantId: widget.tenantId,
      requisitionId: widget.requisitionId,
      actorId: widget.actorId,
      actorName: widget.actorName,
      approvalId: widget.approvalId,
      oneClickToken: widget.oneClickToken,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      await ref.read(prDetailControllerProvider(_args).notifier).refresh();
      if (mounted && widget.openRejectSheetOnLoad) {
        await _handleReject();
      }
    });
  }

  Future<void> _handleApprove() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final PrDetailOutcome outcome = await ref
        .read(prDetailControllerProvider(_args).notifier)
        .approve();
    if (!mounted) {
      return;
    }
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    switch (outcome.kind) {
      case PrDetailOutcomeKind.approvedOnline:
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.prApprovedConfirmation)),
        );
        Navigator.of(context).maybePop(true);
      case PrDetailOutcomeKind.approvedQueuedOffline:
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.prApprovedQueuedOffline)),
        );
        Navigator.of(context).maybePop(true);
      case PrDetailOutcomeKind.error:
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              outcome.message?.isNotEmpty == true
                  ? outcome.message!
                  : l10n.prGenericError,
            ),
          ),
        );
      case PrDetailOutcomeKind.rejectedOnline:
      case PrDetailOutcomeKind.rejectedQueuedOffline:
        break;
    }
  }

  Future<void> _handleReject() async {
    final String? reason = await PrRejectBottomSheet.show(context);
    if (reason == null || reason.trim().isEmpty || !mounted) {
      return;
    }
    final AppLocalizations l10n = AppLocalizations.of(context);
    final PrDetailOutcome outcome = await ref
        .read(prDetailControllerProvider(_args).notifier)
        .reject(reason);
    if (!mounted) {
      return;
    }
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    switch (outcome.kind) {
      case PrDetailOutcomeKind.rejectedOnline:
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.prRejectedConfirmation)),
        );
        Navigator.of(context).maybePop(true);
      case PrDetailOutcomeKind.rejectedQueuedOffline:
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.prRejectedQueuedOffline)),
        );
        Navigator.of(context).maybePop(true);
      case PrDetailOutcomeKind.error:
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              outcome.message?.isNotEmpty == true
                  ? outcome.message!
                  : l10n.prGenericError,
            ),
          ),
        );
      case PrDetailOutcomeKind.approvedOnline:
      case PrDetailOutcomeKind.approvedQueuedOffline:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final FfColors colors =
        Theme.of(context).extension<FfColors>() ?? FfColors.light;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final PrDetailState uiState = ref.watch(prDetailControllerProvider(_args));
    final bool isOnline = ref.watch(prIsOnlineProvider);

    final AsyncValue<PurchaseRequisition?> prAsync = ref.watch(
      purchaseRequisitionDetailProvider((
        tenantId: widget.tenantId,
        requisitionId: widget.requisitionId,
      )),
    );
    final PurchaseRequisition? pr = prAsync.value;

    final List<PendingApprovalItem> pendingItems =
        ref.watch(pendingApprovalsProvider(widget.tenantId)).value ??
        const <PendingApprovalItem>[];
    final PendingApprovalItem? matchingApproval = pendingItems
        .cast<PendingApprovalItem?>()
        .firstWhere(
          (PendingApprovalItem? item) =>
              item != null &&
              (item.requisitionRemoteId == widget.requisitionId ||
                  (widget.approvalId != null &&
                      item.approvalId == widget.approvalId)),
          orElse: () => null,
        );

    final List<ApprovalAuditEntry> auditLogs =
        ref
            .watch(
              prAuditLogsProvider((
                tenantId: widget.tenantId,
                requisitionId: widget.requisitionId,
              )),
            )
            .value ??
        const <ApprovalAuditEntry>[];

    final PrStatus resolvedStatus =
        pr?.status ?? matchingApproval?.status ?? PrStatus.pendingApproval;
    final bool showManagerBar =
        (widget.isManagerApproval ||
            widget.approvalId != null ||
            matchingApproval != null) &&
        resolvedStatus == PrStatus.pendingApproval;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          pr?.requisitionNumber ??
              matchingApproval?.requisitionNumber ??
              l10n.prDetailTitle,
        ),
        actions: <Widget>[
          if (pr != null && pr.isEditable && !widget.isManagerApproval)
            IconButton(
              key: const Key('pr-detail-edit-button'),
              tooltip: l10n.prEditTitle,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PrCreateScreen(
                      tenantId: widget.tenantId,
                      userId: widget.actorId,
                      userName: widget.actorName,
                      defaultCurrency: pr.currency.wireValue,
                      existing: pr,
                      cameraScanner: widget.cameraScanner,
                    ),
                  ),
                );
              },
            ),
          IconButton(
            key: const Key('pr-detail-refresh-button'),
            tooltip: l10n.prRefreshTooltip,
            icon: const Icon(Icons.refresh),
            onPressed: uiState.isRefreshing
                ? null
                : () => ref
                      .read(prDetailControllerProvider(_args).notifier)
                      .refresh(),
          ),
        ],
      ),
      body: pr == null && matchingApproval == null
          ? (prAsync.isLoading || uiState.isRefreshing
                ? const Center(child: CircularProgressIndicator())
                : Center(
                    child: Text(
                      l10n.prNotFound,
                      key: const Key('pr-detail-not-found'),
                    ),
                  ))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(FfSpace.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _HeaderSummaryCard(
                    pr: pr,
                    approval: matchingApproval,
                    colors: colors,
                    l10n: l10n,
                  ),
                  if (pr != null &&
                      (pr.linkedRdo != null ||
                          pr.linkedPo != null)) ...<Widget>[
                    const SizedBox(height: FfSpace.space3),
                    Card(
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(FfRadius.lg),
                        side: BorderSide(color: colors.border),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(FfSpace.space4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              l10n.prLinkedDocumentsTitle,
                              style: TextStyle(
                                color: colors.text,
                                fontSize: FfFont.md,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: FfSpace.space2),
                            Wrap(
                              spacing: FfSpace.space2,
                              runSpacing: FfSpace.space2,
                              children: <Widget>[
                                if (pr.linkedRdo != null)
                                  PrLinkedDocBadge(doc: pr.linkedRdo!),
                                if (pr.linkedPo != null)
                                  PrLinkedDocBadge(doc: pr.linkedPo!),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (pr?.budgetCheck != null) ...<Widget>[
                    const SizedBox(height: FfSpace.space3),
                    PrBudgetBanner(
                      isOnline: isOnline,
                      budgetCheck: pr!.budgetCheck,
                      currency: pr.currency,
                    ),
                  ],
                  if (pr != null) ...<Widget>[
                    const SizedBox(height: FfSpace.space3),
                    _LineItemsCard(pr: pr, colors: colors, l10n: l10n),
                    if (pr.approvalSteps.isNotEmpty) ...<Widget>[
                      const SizedBox(height: FfSpace.space3),
                      PrApprovalProgress(steps: pr.approvalSteps),
                    ],
                  ],
                  const SizedBox(height: FfSpace.space3),
                  _AuditTrailCard(logs: auditLogs, colors: colors, l10n: l10n),
                ],
              ),
            ),
      bottomNavigationBar: showManagerBar
          ? SafeArea(
              child: Container(
                key: const Key('pr-manager-action-bar'),
                padding: const EdgeInsets.all(FfSpace.space3),
                decoration: BoxDecoration(
                  color: colors.surface,
                  border: Border(top: BorderSide(color: colors.border)),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const Key('pr-reject-button'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colors.danger,
                          side: BorderSide(color: colors.danger),
                        ),
                        icon: const Icon(Icons.close),
                        onPressed: uiState.isSubmitting ? null : _handleReject,
                        label: Text(l10n.prRejectAction),
                      ),
                    ),
                    const SizedBox(width: FfSpace.space3),
                    Expanded(
                      child: FilledButton.icon(
                        key: const Key('pr-approve-button'),
                        style: FilledButton.styleFrom(
                          backgroundColor: colors.success,
                          foregroundColor: colors.onPrimary,
                        ),
                        icon: const Icon(Icons.check),
                        onPressed: uiState.isSubmitting ? null : _handleApprove,
                        label: uiState.isSubmitting
                            ? SizedBox(
                                width: FfSpace.space4,
                                height: FfSpace.space4,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colors.onPrimary,
                                ),
                              )
                            : Text(l10n.prApproveOneTap),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}

class _HeaderSummaryCard extends StatelessWidget {
  const _HeaderSummaryCard({
    required this.pr,
    required this.approval,
    required this.colors,
    required this.l10n,
  });

  final PurchaseRequisition? pr;
  final PendingApprovalItem? approval;
  final FfColors colors;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final String number =
        pr?.requisitionNumber ??
        approval?.requisitionNumber ??
        l10n.prDraftLocalNumber;
    final PrStatus status =
        pr?.status ?? approval?.status ?? PrStatus.pendingApproval;
    final PrSyncStatus syncStatus =
        pr?.syncStatus ?? approval?.syncStatus ?? PrSyncStatus.synced;
    final PrUrgency urgency =
        pr?.urgency ?? approval?.urgency ?? PrUrgency.normal;
    final PrCurrency currency =
        pr?.currency ?? approval?.currency ?? PrCurrency.chf;
    final double totalAmount = pr?.totalAmount ?? approval?.totalAmount ?? 0;
    final String costCenterLabel = pr != null
        ? '${pr!.costCenterCode} · ${pr!.costCenterName}'.trim()
        : '${approval!.costCenterCode} · ${approval!.costCenterName}'.trim();
    final String? projectLabel = pr?.projectName ?? approval?.projectName;
    final String requester = pr?.requesterName ?? approval?.requesterName ?? '';
    final DateTime createdAt = pr?.createdAt ?? approval!.requestedAt;

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(FfRadius.lg),
        side: BorderSide(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(FfSpace.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Text(
                    number,
                    style: TextStyle(
                      color: colors.text,
                      fontSize: FfFont.xl,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  PrLabels.formatAmount(context, totalAmount, currency),
                  style: TextStyle(
                    color: colors.primary,
                    fontSize: FfFont.lg,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: FfSpace.space2),
            Wrap(
              spacing: FfSpace.space2,
              runSpacing: FfSpace.space1,
              children: <Widget>[
                PrStatusChip(status: status),
                PrUrgencyBadge(urgency: urgency),
                PrSyncBadge(syncStatus: syncStatus),
              ],
            ),
            const SizedBox(height: FfSpace.space3),
            _DetailField(
              label: l10n.prCostCenterLabel,
              value: costCenterLabel,
              colors: colors,
            ),
            if (projectLabel != null && projectLabel.isNotEmpty)
              _DetailField(
                label: l10n.prProjectLabel,
                value: projectLabel,
                colors: colors,
              ),
            if (requester.isNotEmpty)
              _DetailField(
                label: l10n.prRequesterLabel,
                value: requester,
                colors: colors,
              ),
            _DetailField(
              label: l10n.prRequestedDateLabel,
              value: PrLabels.formatDate(context, createdAt),
              colors: colors,
            ),
            if (pr?.requestedDeliveryDate != null)
              _DetailField(
                label: l10n.prDeliveryDateLabel,
                value: PrLabels.formatDate(context, pr!.requestedDeliveryDate!),
                colors: colors,
              ),
            if (pr != null && pr!.justification.isNotEmpty) ...<Widget>[
              const SizedBox(height: FfSpace.space2),
              Text(
                l10n.prJustificationLabel,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: FfFont.xs,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: FfSpace.space1),
              Text(
                pr!.justification,
                style: TextStyle(color: colors.text, fontSize: FfFont.sm),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailField extends StatelessWidget {
  const _DetailField({
    required this.label,
    required this.value,
    required this.colors,
  });

  final String label;
  final String value;
  final FfColors colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: FfSpace.space1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: FfFont.xs,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: colors.text,
                fontSize: FfFont.sm,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LineItemsCard extends StatelessWidget {
  const _LineItemsCard({
    required this.pr,
    required this.colors,
    required this.l10n,
  });

  final PurchaseRequisition pr;
  final FfColors colors;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(FfRadius.lg),
        side: BorderSide(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(FfSpace.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              l10n.prLinesSectionTitle,
              style: TextStyle(
                color: colors.text,
                fontSize: FfFont.md,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: FfSpace.space2),
            if (pr.lines.isEmpty)
              Text(
                l10n.prLinesEmpty,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: FfFont.sm,
                ),
              )
            else
              for (int i = 0; i < pr.lines.length; i++) ...<Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: FfSpace.space2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              pr.lines[i].description,
                              style: TextStyle(
                                color: colors.text,
                                fontSize: FfFont.sm,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${pr.lines[i].quantity} ${pr.lines[i].uom} × '
                              '${PrLabels.formatAmount(context, pr.lines[i].unitPrice, pr.currency)}'
                              '${pr.lines[i].catalogSku != null ? ' · ${pr.lines[i].catalogSku}' : ''}',
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: FfFont.xs,
                              ),
                            ),
                            if (pr.lines[i].notes != null &&
                                pr.lines[i].notes!.isNotEmpty)
                              Text(
                                pr.lines[i].notes!,
                                style: TextStyle(
                                  color: colors.textMuted,
                                  fontSize: FfFont.xs,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: FfSpace.space2),
                      Text(
                        PrLabels.formatAmount(
                          context,
                          pr.lines[i].lineTotal,
                          pr.currency,
                        ),
                        style: TextStyle(
                          color: colors.text,
                          fontSize: FfFont.sm,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < pr.lines.length - 1)
                  Divider(height: 1, color: colors.borderSubtle),
              ],
          ],
        ),
      ),
    );
  }
}

class _AuditTrailCard extends StatelessWidget {
  const _AuditTrailCard({
    required this.logs,
    required this.colors,
    required this.l10n,
  });

  final List<ApprovalAuditEntry> logs;
  final FfColors colors;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('pr-audit-trail-card'),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(FfRadius.lg),
        side: BorderSide(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(FfSpace.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              l10n.prAuditTrailTitle,
              style: TextStyle(
                color: colors.text,
                fontSize: FfFont.md,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: FfSpace.space2),
            if (logs.isEmpty)
              Text(
                l10n.prAuditTrailEmpty,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: FfFont.sm,
                ),
              )
            else
              for (int i = 0; i < logs.length; i++) ...<Widget>[
                _AuditEntryTile(entry: logs[i], colors: colors, l10n: l10n),
                if (i < logs.length - 1)
                  Divider(height: 1, color: colors.borderSubtle),
              ],
          ],
        ),
      ),
    );
  }
}

class _AuditEntryTile extends StatelessWidget {
  const _AuditEntryTile({
    required this.entry,
    required this.colors,
    required this.l10n,
  });

  final ApprovalAuditEntry entry;
  final FfColors colors;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final Color accent = switch (entry.action) {
      ApprovalActionType.approved => colors.success,
      ApprovalActionType.rejected ||
      ApprovalActionType.budgetBlocked => colors.danger,
      ApprovalActionType.budgetWarning ||
      ApprovalActionType.escalated => colors.warning,
      _ => colors.info,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: FfSpace.space2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                PrLabels.auditAction(l10n, entry.action),
                style: TextStyle(
                  color: accent,
                  fontSize: FfFont.sm,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: FfSpace.space2),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: FfSpace.space2,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: colors.neutralBg,
                  borderRadius: BorderRadius.circular(FfRadius.sm),
                ),
                child: Text(
                  PrLabels.channel(l10n, entry.channel),
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: FfFont.xs,
                  ),
                ),
              ),
              if (entry.isLocalPending) ...<Widget>[
                const SizedBox(width: FfSpace.space1),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: FfSpace.space2,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colors.warningBg,
                    borderRadius: BorderRadius.circular(FfRadius.sm),
                  ),
                  child: Text(
                    l10n.prPendingSyncTag,
                    style: TextStyle(
                      color: colors.warning,
                      fontSize: FfFont.xs,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              Text(
                PrLabels.formatDateTime(context, entry.occurredAt),
                style: TextStyle(color: colors.textMuted, fontSize: FfFont.xs),
              ),
            ],
          ),
          const SizedBox(height: FfSpace.space1),
          Text(
            '${entry.actorName} · ${l10n.prApprovalLevelLabel(entry.level)}',
            style: TextStyle(color: colors.textSecondary, fontSize: FfFont.xs),
          ),
          if (entry.comment != null && entry.comment!.isNotEmpty) ...<Widget>[
            const SizedBox(height: FfSpace.space1),
            Text(
              entry.comment!,
              style: TextStyle(color: colors.text, fontSize: FfFont.sm),
            ),
          ],
        ],
      ),
    );
  }
}
