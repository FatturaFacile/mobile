import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../design/ff_tokens.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../wms/ui/scan_field.dart' show CameraScanner;
import '../../domain/entities/approval_models.dart';
import '../../domain/entities/budget_check.dart';
import '../../domain/entities/purchase_requisition.dart';
import '../providers/pr_hub_controller.dart';
import '../providers/pr_providers.dart';
import '../widgets/pr_labels.dart';
import '../widgets/pr_status_chip.dart';
import 'pr_create_screen.dart';
import 'pr_detail_screen.dart';

/// Purchase Requisitions Hub: segmented tabs for "My Requests" and "To Approve" with offline sync feedback.
class PrHubScreen extends ConsumerStatefulWidget {
  const PrHubScreen({
    required this.tenantId,
    required this.userId,
    required this.userName,
    this.defaultCurrency = 'CHF',
    this.cameraScanner,
    super.key,
  });

  final String tenantId;
  final String userId;
  final String userName;
  final String defaultCurrency;
  final CameraScanner? cameraScanner;

  @override
  ConsumerState<PrHubScreen> createState() => _PrHubScreenState();
}

class _PrHubScreenState extends ConsumerState<PrHubScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ref.read(prIsOnlineProvider)) {
        ref.read(prHubControllerProvider.notifier).refresh(widget.tenantId);
      }
    });
  }

  void _openCreate() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PrCreateScreen(
          tenantId: widget.tenantId,
          userId: widget.userId,
          userName: widget.userName,
          defaultCurrency: widget.defaultCurrency,
          cameraScanner: widget.cameraScanner,
        ),
      ),
    );
  }

  void _openDetail(
    String requisitionId, {
    String? approvalId,
    String? oneClickToken,
    bool isManagerApproval = false,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PrDetailScreen(
          tenantId: widget.tenantId,
          requisitionId: requisitionId,
          actorId: widget.userId,
          actorName: widget.userName,
          approvalId: approvalId,
          oneClickToken: oneClickToken,
          isManagerApproval: isManagerApproval,
          cameraScanner: widget.cameraScanner,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final FfColors colors =
        Theme.of(context).extension<FfColors>() ?? FfColors.light;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final PrHubState hubState = ref.watch(prHubControllerProvider);
    final PrHubController hubController = ref.read(
      prHubControllerProvider.notifier,
    );
    final bool isOnline = ref.watch(prIsOnlineProvider);

    final int pendingCount =
        ref.watch(pendingApprovalCountProvider(widget.tenantId)).value ?? 0;

    ref.listen<AsyncValue<PrSyncEvent>>(prSyncEventsProvider, (
      AsyncValue<PrSyncEvent>? _,
      AsyncValue<PrSyncEvent> next,
    ) {
      final PrSyncEvent? event = next.value;
      if (event == null || !mounted) {
        return;
      }
      final String number = event.requisitionNumber ?? event.requisitionId;
      final String? msg = switch (event.kind) {
        PrSyncEventKind.submitted => l10n.prSyncCompletedSubmitted(number),
        PrSyncEventKind.budgetBlocked => l10n.prSyncCompletedBudgetBlocked(
          number,
        ),
        PrSyncEventKind.approvalSynced => l10n.prSyncCompletedApproval,
        PrSyncEventKind.draftSynced || PrSyncEventKind.syncFailed => null,
      };
      if (msg != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.prHubTitle),
        actions: <Widget>[
          IconButton(
            key: const Key('pr-hub-refresh'),
            tooltip: l10n.prRefreshTooltip,
            onPressed: hubState.isRefreshing
                ? null
                : () => hubController.refresh(widget.tenantId),
            icon: hubState.isRefreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('pr-create-fab'),
        onPressed: _openCreate,
        icon: const Icon(Icons.add),
        label: Text(l10n.prCreateAction),
      ),
      body: Padding(
        padding: const EdgeInsets.all(FfSpace.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (!isOnline) ...<Widget>[
              Container(
                key: const Key('pr-hub-offline-banner'),
                padding: const EdgeInsets.all(FfSpace.space3),
                decoration: BoxDecoration(
                  color: colors.infoBg,
                  borderRadius: BorderRadius.circular(FfRadius.md),
                ),
                child: Row(
                  children: <Widget>[
                    Icon(
                      Icons.cloud_off_outlined,
                      color: colors.info,
                      size: FfFont.lg,
                    ),
                    const SizedBox(width: FfSpace.space2),
                    Expanded(
                      child: Text(
                        l10n.prOfflineBanner,
                        style: TextStyle(
                          color: colors.info,
                          fontSize: FfFont.xs,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: FfSpace.space3),
            ],
            SegmentedButton<PrHubTab>(
              key: const Key('pr-hub-tabs'),
              segments: <ButtonSegment<PrHubTab>>[
                ButtonSegment<PrHubTab>(
                  value: PrHubTab.myRequests,
                  label: Text(
                    l10n.prTabMyRequests,
                    key: const Key('pr-tab-my-requests'),
                  ),
                ),
                ButtonSegment<PrHubTab>(
                  value: PrHubTab.toApprove,
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        l10n.prTabToApprove,
                        key: const Key('pr-tab-to-approve'),
                      ),
                      if (pendingCount > 0) ...<Widget>[
                        const SizedBox(width: FfSpace.space2),
                        Container(
                          key: const Key('pr-to-approve-badge'),
                          padding: const EdgeInsets.symmetric(
                            horizontal: FfSpace.space2,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colors.danger,
                            borderRadius: BorderRadius.circular(FfRadius.lg),
                          ),
                          child: Text(
                            '$pendingCount',
                            style: TextStyle(
                              color: colors.onPrimary,
                              fontSize: FfFont.xs,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              selected: <PrHubTab>{hubState.activeTab},
              onSelectionChanged: (Set<PrHubTab> selection) =>
                  hubController.selectTab(selection.first),
            ),
            const SizedBox(height: FfSpace.space3),
            Expanded(
              child: switch (hubState.activeTab) {
                PrHubTab.myRequests => _MyRequestsTab(
                  tenantId: widget.tenantId,
                  onRefresh: () => hubController.refresh(widget.tenantId),
                  onTap: (PurchaseRequisition pr) =>
                      _openDetail(pr.effectiveId),
                ),
                PrHubTab.toApprove => _ToApproveTab(
                  tenantId: widget.tenantId,
                  onRefresh: () => hubController.refresh(widget.tenantId),
                  onTap: (PendingApprovalItem item) => _openDetail(
                    item.requisitionRemoteId,
                    approvalId: item.approvalId,
                    oneClickToken: item.oneClickToken,
                    isManagerApproval: true,
                  ),
                ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MyRequestsTab extends ConsumerWidget {
  const _MyRequestsTab({
    required this.tenantId,
    required this.onRefresh,
    required this.onTap,
  });

  final String tenantId;
  final Future<void> Function() onRefresh;
  final ValueChanged<PurchaseRequisition> onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FfColors colors =
        Theme.of(context).extension<FfColors>() ?? FfColors.light;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<List<PurchaseRequisition>> asyncList = ref.watch(
      myPurchaseRequisitionsProvider(tenantId),
    );

    return asyncList.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object err, StackTrace _) =>
          Center(child: Text(l10n.prGenericError)),
      data: (List<PurchaseRequisition> items) {
        if (items.isEmpty) {
          return Center(
            child: Text(
              l10n.prEmptyMyRequests,
              key: const Key('pr-my-requests-empty'),
              style: TextStyle(color: colors.textSecondary),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: FfSpace.space2),
            itemBuilder: (BuildContext context, int i) {
              final PurchaseRequisition pr = items[i];
              return _RequisitionCard(
                pr: pr,
                colors: colors,
                l10n: l10n,
                onTap: () => onTap(pr),
              );
            },
          ),
        );
      },
    );
  }
}

class _ToApproveTab extends ConsumerWidget {
  const _ToApproveTab({
    required this.tenantId,
    required this.onRefresh,
    required this.onTap,
  });

  final String tenantId;
  final Future<void> Function() onRefresh;
  final ValueChanged<PendingApprovalItem> onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FfColors colors =
        Theme.of(context).extension<FfColors>() ?? FfColors.light;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<List<PendingApprovalItem>> asyncList = ref.watch(
      pendingApprovalsProvider(tenantId),
    );

    return asyncList.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object err, StackTrace _) =>
          Center(child: Text(l10n.prGenericError)),
      data: (List<PendingApprovalItem> items) {
        if (items.isEmpty) {
          return Center(
            child: Text(
              l10n.prEmptyToApprove,
              key: const Key('pr-to-approve-empty'),
              style: TextStyle(color: colors.textSecondary),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: FfSpace.space2),
            itemBuilder: (BuildContext context, int i) {
              final PendingApprovalItem item = items[i];
              return _PendingApprovalCard(
                item: item,
                colors: colors,
                l10n: l10n,
                onTap: () => onTap(item),
              );
            },
          ),
        );
      },
    );
  }
}

class _RequisitionCard extends StatelessWidget {
  const _RequisitionCard({
    required this.pr,
    required this.colors,
    required this.l10n,
    required this.onTap,
  });

  final PurchaseRequisition pr;
  final FfColors colors;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String title =
        (pr.requisitionNumber != null && pr.requisitionNumber!.isNotEmpty)
        ? pr.requisitionNumber!
        : l10n.prDraftLocalNumber;
    final String costCenter = pr.costCenterCode.isEmpty
        ? pr.costCenterName
        : '${pr.costCenterCode} · ${pr.costCenterName}';

    return Card(
      key: Key('pr-card-${pr.localId}'),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(FfRadius.lg),
        side: BorderSide(color: colors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(FfRadius.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(FfSpace.space3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: colors.text,
                        fontSize: FfFont.md,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    PrLabels.formatAmount(context, pr.totalAmount, pr.currency),
                    style: TextStyle(
                      color: colors.primary,
                      fontSize: FfFont.md,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: FfSpace.space1),
              Text(
                costCenter,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: FfFont.sm,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (pr.projectName != null && pr.projectName!.isNotEmpty)
                Text(
                  pr.projectCode != null && pr.projectCode!.isNotEmpty
                      ? '${pr.projectCode} · ${pr.projectName}'
                      : pr.projectName!,
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: FfFont.xs,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: FfSpace.space2),
              Wrap(
                spacing: FfSpace.space2,
                runSpacing: FfSpace.space1,
                children: <Widget>[
                  PrStatusChip(status: pr.status),
                  PrUrgencyBadge(urgency: pr.urgency),
                  PrSyncBadge(syncStatus: pr.syncStatus),
                  if (pr.linkedRdo != null)
                    PrLinkedDocBadge(doc: pr.linkedRdo!),
                  if (pr.linkedPo != null) PrLinkedDocBadge(doc: pr.linkedPo!),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingApprovalCard extends StatelessWidget {
  const _PendingApprovalCard({
    required this.item,
    required this.colors,
    required this.l10n,
    required this.onTap,
  });

  final PendingApprovalItem item;
  final FfColors colors;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String costCenter = item.costCenterCode.isEmpty
        ? item.costCenterName
        : '${item.costCenterCode} · ${item.costCenterName}';

    return Card(
      key: Key('pr-approval-card-${item.approvalId}'),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(FfRadius.lg),
        side: BorderSide(color: colors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(FfRadius.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(FfSpace.space3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      item.requisitionNumber,
                      style: TextStyle(
                        color: colors.text,
                        fontSize: FfFont.md,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    PrLabels.formatAmount(
                      context,
                      item.totalAmount,
                      item.currency,
                    ),
                    style: TextStyle(
                      color: colors.primary,
                      fontSize: FfFont.md,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: FfSpace.space1),
              Text(
                '${item.requesterName} · $costCenter',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: FfFont.sm,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (item.projectName != null && item.projectName!.isNotEmpty)
                Text(
                  item.projectName!,
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: FfFont.xs,
                  ),
                ),
              const SizedBox(height: FfSpace.space2),
              Wrap(
                spacing: FfSpace.space2,
                runSpacing: FfSpace.space1,
                children: <Widget>[
                  PrStatusChip(status: item.status),
                  PrUrgencyBadge(urgency: item.urgency),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: FfSpace.space2,
                      vertical: FfSpace.space1,
                    ),
                    decoration: BoxDecoration(
                      color: colors.infoBg,
                      borderRadius: BorderRadius.circular(FfRadius.md),
                    ),
                    child: Text(
                      l10n.prLevelBadge(item.currentLevel, item.totalLevels),
                      style: TextStyle(
                        color: colors.info,
                        fontSize: FfFont.xs,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (item.budgetStatus != BudgetCheckStatus.ok)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: FfSpace.space2,
                        vertical: FfSpace.space1,
                      ),
                      decoration: BoxDecoration(
                        color: item.budgetStatus == BudgetCheckStatus.hardBlock
                            ? colors.dangerBg
                            : colors.warningBg,
                        borderRadius: BorderRadius.circular(FfRadius.md),
                      ),
                      child: Text(
                        PrLabels.budgetStatus(l10n, item.budgetStatus),
                        style: TextStyle(
                          color:
                              item.budgetStatus == BudgetCheckStatus.hardBlock
                              ? colors.danger
                              : colors.warning,
                          fontSize: FfFont.xs,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
