import 'package:material_ui/material_ui.dart';

import '../../../design/ff_tokens.dart';
import '../domain/receivables_models.dart';
import 'receivables_strings.dart';

FfColors receivablesColors(BuildContext context) =>
    Theme.of(context).extension<FfColors>() ?? FfColors.light;

/// Red banner when the customer is on credit block or hold, amber when close to or over the limit or overdue; nothing
/// when the position is fine. Meant for any screen that creates orders or delivery notes for the customer.
class CreditBlockBanner extends StatelessWidget {
  const CreditBlockBanner({required this.position, super.key});

  final CreditPosition position;

  @override
  Widget build(BuildContext context) {
    final CreditAlert alert = position.alert;
    if (alert == CreditAlert.none) {
      return const SizedBox.shrink();
    }
    final ReceivablesStrings s = ReceivablesStrings.of(context);
    final FfColors c = receivablesColors(context);
    final bool blocked = alert == CreditAlert.blocked;
    final String title = blocked
        ? s.t(RC.alertBlockedTitle)
        : s.t(RC.alertWarningTitle);
    final String body = blocked
        ? (position.isCreditHold && !position.isBlocked
              ? s.t(RC.alertHoldBody)
              : s.t(RC.alertBlockedBody))
        : s.t(RC.alertWarningBody);
    final String reason = position.decision.reason;
    return Container(
      key: Key(blocked ? 'credit-banner-blocked' : 'credit-banner-warning'),
      margin: const EdgeInsets.only(bottom: FfSpace.space3),
      padding: const EdgeInsets.all(FfSpace.space3),
      decoration: BoxDecoration(
        color: blocked ? c.dangerBg : c.warningBg,
        border: Border.all(color: blocked ? c.danger : c.warning),
        borderRadius: BorderRadius.circular(FfRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            blocked ? Icons.block : Icons.warning_amber_rounded,
            color: blocked ? c.danger : c.warning,
          ),
          const SizedBox(width: FfSpace.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: FfSpace.space1),
                Text(body),
                if (reason.isNotEmpty) ...<Widget>[
                  const SizedBox(height: FfSpace.space1),
                  Text(
                    reason,
                    key: const Key('credit-banner-reason'),
                    style: TextStyle(color: c.textSecondary),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Utilisation of the credit line: a bar that fills up to 100% and changes colour at 80% and 100%.
class UtilisationGauge extends StatelessWidget {
  const UtilisationGauge({required this.percent, super.key});

  /// Percent of the limit used; `null` when there is no limit.
  final double? percent;

  @override
  Widget build(BuildContext context) {
    final ReceivablesStrings s = ReceivablesStrings.of(context);
    final FfColors c = receivablesColors(context);
    final UtilisationLevel level = utilisationLevel(percent);
    final Color color = switch (level) {
      UtilisationLevel.ok => c.success,
      UtilisationLevel.warning => c.warning,
      UtilisationLevel.exceeded => c.danger,
    };
    final double fraction = ((percent ?? 0) / 100).clamp(0.0, 1.0).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: Text(s.t(RC.utilisation))),
            Text(
              percent == null ? '-' : s.percent(percent!),
              key: const Key('utilisation-value'),
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: FfSpace.space1),
        ClipRRect(
          borderRadius: BorderRadius.circular(FfRadius.sm),
          child: LinearProgressIndicator(
            key: const Key('utilisation-gauge'),
            value: fraction,
            minHeight: 10,
            color: color,
            backgroundColor: c.neutralBg,
          ),
        ),
      ],
    );
  }
}

/// Thin bar of the share of one aging bucket.
class AgingShareBar extends StatelessWidget {
  const AgingShareBar({required this.share, required this.overdue, super.key});

  /// `0..1`.
  final double share;

  /// Overdue buckets are drawn in the warning colour, the current one in the primary colour.
  final bool overdue;

  @override
  Widget build(BuildContext context) {
    final FfColors c = receivablesColors(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(FfRadius.sm),
      child: LinearProgressIndicator(
        value: share.clamp(0.0, 1.0).toDouble(),
        minHeight: 6,
        color: overdue ? c.warning : c.primary,
        backgroundColor: c.neutralBg,
      ),
    );
  }
}

/// Small coloured chip with the status of an item.
class ItemStatusChip extends StatelessWidget {
  const ItemStatusChip({required this.status, super.key});

  final ItemStatus status;

  @override
  Widget build(BuildContext context) {
    final ReceivablesStrings s = ReceivablesStrings.of(context);
    final FfColors c = receivablesColors(context);
    final (Color fg, Color bg) = switch (status) {
      ItemStatus.overdue || ItemStatus.disputed => (c.danger, c.dangerBg),
      ItemStatus.partiallyPaid => (c.warning, c.warningBg),
      ItemStatus.paid => (c.success, c.successBg),
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
        s.status(status),
        style: TextStyle(
          color: fg,
          fontSize: FfFont.xs,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Label on the left, value on the right.
class LabeledAmount extends StatelessWidget {
  const LabeledAmount({
    required this.label,
    required this.value,
    this.emphasis = false,
    super.key,
  });

  final String label;
  final String value;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final TextStyle style = TextStyle(
      fontWeight: emphasis ? FontWeight.w700 : FontWeight.w400,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: FfSpace.space1),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}
