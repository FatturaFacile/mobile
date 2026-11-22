import 'package:material_ui/material_ui.dart';

import '../../../design/ff_tokens.dart';
import '../domain/rebate_decimal.dart';
import '../domain/supplier_rebate_models.dart';
import '../domain/tier_progress_calculator.dart';
import 'supplier_rebates_format.dart';
import 'supplier_rebates_strings.dart';

FfColors rebateColors(BuildContext context) =>
    Theme.of(context).extension<FfColors>() ?? FfColors.light;

/// A progress bar for a 0..100 [percent] (clamped).
class RebateBar extends StatelessWidget {
  const RebateBar({
    required this.percent,
    required this.color,
    super.key,
    this.height = 10,
  });

  final Dec percent;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final FfColors c = rebateColors(context);
    final double value = (percent.toDouble() / 100).clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(FfRadius.sm),
      child: LinearProgressIndicator(
        value: value,
        minHeight: height,
        color: color,
        backgroundColor: c.neutralBg,
      ),
    );
  }
}

/// A small coloured label (status of an agreement, proposal or run).
class RebateChip extends StatelessWidget {
  const RebateChip({required this.label, required this.kind, super.key});

  final String label;

  /// `success`, `warning`, `danger`, `info` or anything else for neutral.
  final String kind;

  @override
  Widget build(BuildContext context) {
    final FfColors c = rebateColors(context);
    final (Color fg, Color bg) = switch (kind) {
      'success' => (c.success, c.successBg),
      'warning' => (c.warning, c.warningBg),
      'danger' => (c.danger, c.dangerBg),
      'info' => (c.info, c.infoBg),
      _ => (c.textSecondary, c.neutralBg),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: FfSpace.space2,
        vertical: FfSpace.space1,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(FfRadius.sm),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: FfFont.xs,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Chip kind of an agreement status.
String agreementStatusKind(AgreementStatus status) => switch (status) {
  AgreementStatus.active => 'success',
  AgreementStatus.draft => 'info',
  AgreementStatus.closed => 'neutral',
  AgreementStatus.cancelled => 'danger',
};

/// Chip kind of a settlement proposal status.
String proposalStatusKind(ProposalStatus status) => switch (status) {
  ProposalStatus.draft => 'info',
  ProposalStatus.pendingApproval => 'warning',
  ProposalStatus.approved => 'success',
  ProposalStatus.settled => 'neutral',
  ProposalStatus.cancelled => 'danger',
};

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.valueKey,
    this.strong = false,
  });

  final String label;
  final String value;
  final Key? valueKey;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final FfColors c = rebateColors(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: FfSpace.space1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: c.textSecondary,
                fontSize: FfFont.sm,
              ),
            ),
          ),
          const SizedBox(width: FfSpace.space3),
          Text(
            value,
            key: valueKey,
            style: TextStyle(
              color: c.text,
              fontSize: FfFont.md,
              fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// A titled card section.
class RebateSection extends StatelessWidget {
  const RebateSection({
    required this.title,
    required this.child,
    super.key,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final FfColors c = rebateColors(context);
    return Card(
      margin: const EdgeInsets.only(bottom: FfSpace.space3),
      child: Padding(
        padding: const EdgeInsets.all(FfSpace.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: c.text,
                      fontSize: FfFont.lg,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: FfSpace.space2),
            child,
          ],
        ),
      ),
    );
  }
}

/// Live position on the rebate scale: qualifying spend, current and next tier, the progress bar inside the current band,
/// the distance to the next tier and the extra rebate reaching it brings. It renders whatever [progress] holds, so it
/// works from cached data alone.
class TierProgressCard extends StatelessWidget {
  const TierProgressCard({
    required this.progress,
    required this.volume,
    required this.currency,
    required this.languageCode,
    super.key,
    this.recomputedOffline = false,
  });

  final TierProgress progress;
  final Dec volume;
  final String currency;
  final String languageCode;

  /// Shows the note that the figures were computed on the phone from the last known volume.
  final bool recomputedOffline;

  @override
  Widget build(BuildContext context) {
    final SupplierRebatesStrings s = SupplierRebatesStrings(languageCode);
    final FfColors c = rebateColors(context);
    String money(Dec v) => RebateFormat.money(v, currency, languageCode);
    final RebateTier? current = progress.currentTier;
    final RebateTier? next = progress.nextTier;
    return RebateSection(
      title: s(RB.progress),
      child: Column(
        key: const Key('rebate-progress-card'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _Row(
            label: s(RB.qualifyingSpend),
            value: money(volume),
            valueKey: const Key('rebate-volume'),
            strong: true,
          ),
          _Row(
            label: s(RB.accruedRebate),
            value: money(progress.accruedRebate),
            valueKey: const Key('rebate-accrued'),
          ),
          const SizedBox(height: FfSpace.space2),
          _Row(
            label: s(RB.currentTier),
            value: current == null
                ? s(RB.noTier)
                : RebateFormat.percent(current.ratePercent, languageCode),
            valueKey: const Key('rebate-current-tier'),
          ),
          const SizedBox(height: FfSpace.space2),
          RebateBar(
            key: const Key('rebate-progress-bar'),
            percent: progress.progressPercent,
            color: c.primary,
          ),
          const SizedBox(height: FfSpace.space1),
          Text(
            RebateFormat.percent(progress.progressPercent, languageCode),
            key: const Key('rebate-progress-percent'),
            style: TextStyle(color: c.textSecondary, fontSize: FfFont.xs),
          ),
          const SizedBox(height: FfSpace.space2),
          if (next == null && current != null)
            Text(
              s(RB.topTier),
              key: const Key('rebate-top-tier'),
              style: TextStyle(
                color: c.success,
                fontWeight: FontWeight.w700,
                fontSize: FfFont.md,
              ),
            )
          else if (next != null) ...<Widget>[
            _Row(
              label: s(RB.nextTier),
              value:
                  '${money(next.threshold)} · ${RebateFormat.percent(next.ratePercent, languageCode)}',
              valueKey: const Key('rebate-next-tier'),
            ),
            if (progress.distanceToNext != null)
              _Row(
                label: s(RB.distanceToNext),
                value: money(progress.distanceToNext!),
                valueKey: const Key('rebate-distance'),
                strong: true,
              ),
            if (progress.projectedRebateAtNext != null)
              _Row(
                label: s(RB.projectedAtNext),
                value: money(progress.projectedRebateAtNext!),
                valueKey: const Key('rebate-projected'),
              ),
            if (progress.projectedGain != null)
              _Row(
                label: s(RB.projectedGain),
                value: '+${money(progress.projectedGain!)}',
                valueKey: const Key('rebate-projected-gain'),
              ),
          ],
          if (recomputedOffline) ...<Widget>[
            const SizedBox(height: FfSpace.space2),
            Text(
              s(RB.recomputedOffline),
              key: const Key('rebate-recomputed'),
              style: TextStyle(color: c.textMuted, fontSize: FfFont.xs),
            ),
          ],
        ],
      ),
    );
  }
}

/// The scale, tier by tier, with the tier the volume is in marked.
class TierLadder extends StatelessWidget {
  const TierLadder({
    required this.tiers,
    required this.volume,
    required this.currency,
    required this.languageCode,
    super.key,
  });

  final List<RebateTier> tiers;
  final Dec volume;
  final String currency;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final SupplierRebatesStrings s = SupplierRebatesStrings(languageCode);
    final FfColors c = rebateColors(context);
    final List<RebateTier> ordered = TierProgressCalculator.sorted(tiers);
    final TierProgress position = TierProgressCalculator.progress(
      ordered,
      volume,
      TierMode.retroactive,
    );
    return RebateSection(
      title: s(RB.tiers),
      child: Column(
        children: <Widget>[
          for (final (int i, RebateTier t) in ordered.indexed)
            Container(
              key: Key('rebate-tier-$i'),
              margin: const EdgeInsets.symmetric(vertical: FfSpace.space1),
              padding: const EdgeInsets.all(FfSpace.space2),
              decoration: BoxDecoration(
                color: position.currentTier == t ? c.primarySubtle : null,
                borderRadius: BorderRadius.circular(FfRadius.sm),
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    volume >= t.threshold && volume.isPositive
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    size: 18,
                    color: volume >= t.threshold && volume.isPositive
                        ? c.success
                        : c.textMuted,
                  ),
                  const SizedBox(width: FfSpace.space2),
                  Expanded(
                    child: Text(
                      '${RebateFormat.money(t.threshold, currency, languageCode)}'
                      '${i + 1 < ordered.length ? ' – ${RebateFormat.money(ordered[i + 1].threshold, currency, languageCode)}' : ' · ${s(RB.openEnded)}'}',
                      style: TextStyle(color: c.text, fontSize: FfFont.sm),
                    ),
                  ),
                  Text(
                    RebateFormat.percent(t.ratePercent, languageCode) +
                        (t.flatAmount != null && t.flatAmount!.isPositive
                            ? ' + ${RebateFormat.money(t.flatAmount!, currency, languageCode)}'
                            : ''),
                    style: TextStyle(
                      color: c.text,
                      fontSize: FfFont.sm,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Progress of a fixed target bonus.
class BonusProgressCard extends StatelessWidget {
  const BonusProgressCard({
    required this.bonus,
    required this.volume,
    required this.currency,
    required this.languageCode,
    super.key,
  });

  final BonusProgress bonus;
  final Dec volume;
  final String currency;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final SupplierRebatesStrings s = SupplierRebatesStrings(languageCode);
    final FfColors c = rebateColors(context);
    String money(Dec v) => RebateFormat.money(v, currency, languageCode);
    return RebateSection(
      title: s(RB.progress),
      child: Column(
        key: const Key('rebate-bonus-card'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _Row(
            label: s(RB.qualifyingSpend),
            value: money(volume),
            valueKey: const Key('rebate-volume'),
            strong: true,
          ),
          _Row(label: s(RB.bonusTarget), value: money(bonus.target)),
          _Row(label: s(RB.bonusAmount), value: money(bonus.bonus)),
          const SizedBox(height: FfSpace.space2),
          RebateBar(
            key: const Key('rebate-progress-bar'),
            percent: bonus.progressPercent,
            color: bonus.reached ? c.success : c.primary,
          ),
          const SizedBox(height: FfSpace.space2),
          if (bonus.reached)
            Text(
              s(RB.targetReached),
              key: const Key('rebate-target-reached'),
              style: TextStyle(
                color: c.success,
                fontWeight: FontWeight.w700,
                fontSize: FfFont.md,
              ),
            )
          else
            _Row(
              label: s(RB.distanceToTarget),
              value: money(bonus.distanceToTarget),
              valueKey: const Key('rebate-distance'),
              strong: true,
            ),
        ],
      ),
    );
  }
}

/// The workflow buttons of a settlement proposal. Which ones show follows the status (draft: submit and cancel; pending
/// approval: approve and cancel; approved: cancel; settled and cancelled: none). An action already waiting in the outbox
/// disables its button, and so does a running request. Executing the set-off is deliberately not offered here.
class ProposalActionButtons extends StatelessWidget {
  const ProposalActionButtons({
    required this.status,
    required this.languageCode,
    required this.onAction,
    super.key,
    this.pending = const <ProposalAction>{},
    this.busy = false,
  });

  final ProposalStatus status;
  final String languageCode;
  final void Function(ProposalAction action) onAction;
  final Set<ProposalAction> pending;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final SupplierRebatesStrings s = SupplierRebatesStrings(languageCode);
    final FfColors c = rebateColors(context);
    final List<ProposalAction> actions = <ProposalAction>[
      for (final ProposalAction a in ProposalAction.values)
        if (a.allowedIn(status)) a,
    ];
    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }
    final bool locked = busy || pending.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: FfSpace.space2,
          runSpacing: FfSpace.space2,
          children: <Widget>[
            for (final ProposalAction a in actions)
              if (a == ProposalAction.cancel)
                OutlinedButton(
                  key: Key('proposal-action-${a.wire}'),
                  onPressed: locked ? null : () => onAction(a),
                  style: OutlinedButton.styleFrom(foregroundColor: c.danger),
                  child: Text(s.action(a)),
                )
              else
                FilledButton(
                  key: Key('proposal-action-${a.wire}'),
                  onPressed: locked ? null : () => onAction(a),
                  child: Text(s.action(a)),
                ),
          ],
        ),
        if (status == ProposalStatus.approved) ...<Widget>[
          const SizedBox(height: FfSpace.space2),
          Text(
            s(RB.executeOnWeb),
            key: const Key('proposal-execute-on-web'),
            style: TextStyle(color: c.textMuted, fontSize: FfFont.xs),
          ),
        ],
      ],
    );
  }
}

/// Ceiling and minimum spend meters of a blanket agreement balance, with its alerts.
class BalanceMeters extends StatelessWidget {
  const BalanceMeters({
    required this.balance,
    required this.languageCode,
    super.key,
  });

  final BlanketBalance balance;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final SupplierRebatesStrings s = SupplierRebatesStrings(languageCode);
    final FfColors c = rebateColors(context);
    String money(Dec v) =>
        RebateFormat.money(v, balance.currency, languageCode);
    final bool exceeded = balance.alerts.any(
      (BalanceAlert a) => a.code == BalanceAlertCode.ceilingExceeded,
    );
    final bool near = balance.alerts.any(
      (BalanceAlert a) => a.code == BalanceAlertCode.ceilingNear,
    );
    final Dec? minimumReached = balance.minimumReachedPercent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (final BalanceAlert a in balance.alerts)
          Container(
            key: Key('balance-alert-${a.code.wire}'),
            margin: const EdgeInsets.only(bottom: FfSpace.space2),
            padding: const EdgeInsets.all(FfSpace.space3),
            decoration: BoxDecoration(
              color: a.isCritical ? c.dangerBg : c.warningBg,
              borderRadius: BorderRadius.circular(FfRadius.md),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  a.isCritical ? Icons.error : Icons.warning_amber,
                  color: a.isCritical ? c.danger : c.warning,
                ),
                const SizedBox(width: FfSpace.space2),
                Expanded(
                  child: Text(
                    s.alert(a.code),
                    style: TextStyle(
                      color: a.isCritical ? c.danger : c.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        RebateSection(
          title: s(RB.ceiling),
          child: balance.hasCeiling
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    RebateBar(
                      key: const Key('balance-ceiling-bar'),
                      percent: balance.ceilingUsedPercent ?? Dec.zero,
                      color: exceeded
                          ? c.danger
                          : (near ? c.warning : c.primary),
                    ),
                    const SizedBox(height: FfSpace.space2),
                    _Row(label: s(RB.ceiling), value: money(balance.ceiling)),
                    _Row(
                      label: s(RB.ordered),
                      value:
                          '${money(balance.orderedAmount)} (${RebateFormat.percent(balance.ceilingUsedPercent ?? Dec.zero, languageCode)})',
                      valueKey: const Key('balance-ordered'),
                    ),
                    if (balance.remainingCeiling != null)
                      _Row(
                        label: s(RB.remainingCeiling),
                        value: money(balance.remainingCeiling!),
                        valueKey: const Key('balance-remaining'),
                        strong: true,
                      ),
                  ],
                )
              : Text(
                  s(RB.noCeiling),
                  key: const Key('balance-no-ceiling'),
                  style: TextStyle(color: c.textSecondary),
                ),
        ),
        if (balance.minimumSpend != null)
          RebateSection(
            title: s(RB.minimumSpend),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                RebateBar(
                  key: const Key('balance-minimum-bar'),
                  percent: minimumReached ?? Dec.zero,
                  color:
                      balance.alerts.any(
                        (BalanceAlert a) =>
                            a.code == BalanceAlertCode.minimumNotMet,
                      )
                      ? c.danger
                      : (balance.alerts.any(
                              (BalanceAlert a) =>
                                  a.code == BalanceAlertCode.minimumAtRisk,
                            )
                            ? c.warning
                            : c.success),
                ),
                const SizedBox(height: FfSpace.space2),
                _Row(
                  label: s(RB.minimumSpend),
                  value: money(balance.minimumSpend!),
                ),
                if (balance.minimumShortfall != null)
                  _Row(
                    label: s(RB.shortfall),
                    value: money(balance.minimumShortfall!),
                    valueKey: const Key('balance-shortfall'),
                    strong: true,
                  ),
              ],
            ),
          ),
        RebateSection(
          title: s(RB.blanketBalance),
          child: Column(
            children: <Widget>[
              _Row(label: s(RB.ordered), value: money(balance.orderedAmount)),
              _Row(label: s(RB.received), value: money(balance.receivedAmount)),
              _Row(label: s(RB.invoiced), value: money(balance.invoicedAmount)),
            ],
          ),
        ),
      ],
    );
  }
}

/// A label/value row for the detail pages.
class RebateInfoRow extends StatelessWidget {
  const RebateInfoRow({
    required this.label,
    required this.value,
    super.key,
    this.valueKey,
    this.strong = false,
  });

  final String label;
  final String value;
  final Key? valueKey;
  final bool strong;

  @override
  Widget build(BuildContext context) =>
      _Row(label: label, value: value, valueKey: valueKey, strong: strong);
}
