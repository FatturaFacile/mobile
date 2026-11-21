import 'package:material_ui/material_ui.dart';

import '../../../../design/ff_tokens.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/entities/budget_check.dart';
import '../../domain/entities/purchase_requisition.dart';
import 'pr_labels.dart';

/// Displays live or cached Mod 019 Cost Center budget check feedback (OK, Warning, Hard-Block, or Offline).
class PrBudgetBanner extends StatelessWidget {
  const PrBudgetBanner({
    required this.isOnline,
    this.budgetCheck,
    this.isLoading = false,
    this.currency = PrCurrency.chf,
    super.key,
  });

  final bool isOnline;
  final BudgetCheckResult? budgetCheck;
  final bool isLoading;
  final PrCurrency currency;

  @override
  Widget build(BuildContext context) {
    final FfColors colors =
        Theme.of(context).extension<FfColors>() ?? FfColors.light;
    final AppLocalizations l10n = AppLocalizations.of(context);

    if (isLoading) {
      return Container(
        key: const Key('budget-banner-loading'),
        padding: const EdgeInsets.all(FfSpace.space3),
        decoration: BoxDecoration(
          color: colors.infoBg,
          borderRadius: BorderRadius.circular(FfRadius.lg),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: FfSpace.space4,
              height: FfSpace.space4,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.info,
              ),
            ),
            const SizedBox(width: FfSpace.space3),
            Expanded(
              child: Text(
                l10n.prBudgetChecking,
                style: TextStyle(
                  color: colors.info,
                  fontSize: FfFont.sm,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final BudgetCheckResult? check = budgetCheck;
    if (check == null) {
      if (isOnline) {
        return const SizedBox.shrink();
      }
      return Container(
        key: const Key('budget-banner-offline'),
        padding: const EdgeInsets.all(FfSpace.space3),
        decoration: BoxDecoration(
          color: colors.infoBg,
          borderRadius: BorderRadius.circular(FfRadius.lg),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: <Widget>[
            Icon(Icons.cloud_off_outlined, size: FfFont.lg, color: colors.info),
            const SizedBox(width: FfSpace.space2),
            Expanded(
              child: Text(
                l10n.prBudgetOfflineInfo,
                style: TextStyle(color: colors.info, fontSize: FfFont.sm),
              ),
            ),
          ],
        ),
      );
    }

    final ({Color fg, Color bg, IconData icon, Key bannerKey}) style =
        switch (check.status) {
          BudgetCheckStatus.ok => (
            fg: colors.success,
            bg: colors.successBg,
            icon: Icons.check_circle_outline,
            bannerKey: const Key('budget-banner-ok'),
          ),
          BudgetCheckStatus.warning => (
            fg: colors.warning,
            bg: colors.warningBg,
            icon: Icons.warning_amber_rounded,
            bannerKey: const Key('budget-banner-warning'),
          ),
          BudgetCheckStatus.hardBlock => (
            fg: colors.danger,
            bg: colors.dangerBg,
            icon: Icons.block,
            bannerKey: const Key('budget-banner-hard-block'),
          ),
        };

    final PrCurrency resolvedCurrency = PrCurrency.fromWire(
      check.currency.isNotEmpty ? check.currency : currency.wireValue,
    );
    final double ratio = check.allocatedBudget > 0
        ? (check.utilizationPercent / 100).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      key: style.bannerKey,
      padding: const EdgeInsets.all(FfSpace.space3),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(FfRadius.lg),
        border: Border.all(color: style.fg.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(style.icon, color: style.fg, size: FfFont.xl),
              const SizedBox(width: FfSpace.space2),
              Expanded(
                child: Text(
                  '${l10n.prBudgetTitle} · ${PrLabels.budgetStatus(l10n, check.status)}',
                  style: TextStyle(
                    color: style.fg,
                    fontSize: FfFont.sm,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                l10n.prBudgetUtilization(
                  check.utilizationPercent.toStringAsFixed(0),
                ),
                style: TextStyle(
                  color: style.fg,
                  fontSize: FfFont.xs,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (check.message.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: FfSpace.space2),
            Text(
              check.message,
              style: TextStyle(color: colors.text, fontSize: FfFont.sm),
            ),
          ],
          const SizedBox(height: FfSpace.space2),
          ClipRRect(
            borderRadius: BorderRadius.circular(FfRadius.sm),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: FfSpace.space2,
              backgroundColor: colors.surface,
              valueColor: AlwaysStoppedAnimation<Color>(style.fg),
            ),
          ),
          const SizedBox(height: FfSpace.space2),
          Wrap(
            spacing: FfSpace.space4,
            runSpacing: FfSpace.space1,
            children: <Widget>[
              _Metric(
                label: l10n.prBudgetAllocated,
                value: PrLabels.formatAmount(
                  context,
                  check.allocatedBudget,
                  resolvedCurrency,
                ),
                colors: colors,
              ),
              _Metric(
                label: l10n.prBudgetAvailable,
                value: PrLabels.formatAmount(
                  context,
                  check.availableBudget,
                  resolvedCurrency,
                ),
                colors: colors,
              ),
              _Metric(
                label: l10n.prBudgetRequested,
                value: PrLabels.formatAmount(
                  context,
                  check.requestedAmount,
                  resolvedCurrency,
                ),
                colors: colors,
              ),
              _Metric(
                label: l10n.prBudgetRemaining,
                value: PrLabels.formatAmount(
                  context,
                  check.remainingAfterRequest,
                  resolvedCurrency,
                ),
                colors: colors,
                emphasizeDanger: check.remainingAfterRequest < 0,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.colors,
    this.emphasizeDanger = false,
  });

  final String label;
  final String value;
  final FfColors colors;
  final bool emphasizeDanger;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label,
          style: TextStyle(color: colors.textSecondary, fontSize: FfFont.xs),
        ),
        Text(
          value,
          style: TextStyle(
            color: emphasizeDanger ? colors.danger : colors.text,
            fontSize: FfFont.sm,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
