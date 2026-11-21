import 'package:material_ui/material_ui.dart';

import '../../../../design/ff_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/purchase_requisition.dart';
import 'pr_labels.dart';

/// Status chip displaying the business status of a Purchase Requisition (including `Budget Exceeded`).
class PrStatusChip extends StatelessWidget {
  const PrStatusChip({required this.status, super.key});

  final PrStatus status;

  @override
  Widget build(BuildContext context) {
    final FfColors colors =
        Theme.of(context).extension<FfColors>() ?? FfColors.light;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ({Color fg, Color bg}) style = PrLabels.statusColors(colors, status);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: FfSpace.space2,
        vertical: FfSpace.space1,
      ),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(FfRadius.lg),
      ),
      child: Text(
        PrLabels.status(l10n, status),
        style: TextStyle(
          color: style.fg,
          fontSize: FfFont.xs,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Compact badge showing synchronization state (`synced`, `pending_upload`, `sync_error`).
class PrSyncBadge extends StatelessWidget {
  const PrSyncBadge({required this.syncStatus, super.key});

  final PrSyncStatus syncStatus;

  @override
  Widget build(BuildContext context) {
    final FfColors colors =
        Theme.of(context).extension<FfColors>() ?? FfColors.light;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ({Color fg, Color bg, IconData icon}) style = PrLabels.syncColors(
      colors,
      syncStatus,
    );
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: FfSpace.space2,
        vertical: FfSpace.space1,
      ),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(FfRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(style.icon, size: FfFont.sm, color: style.fg),
          const SizedBox(width: FfSpace.space1),
          Text(
            PrLabels.syncStatus(l10n, syncStatus),
            style: TextStyle(
              color: style.fg,
              fontSize: FfFont.xs,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact urgency pill for a Purchase Requisition.
class PrUrgencyBadge extends StatelessWidget {
  const PrUrgencyBadge({required this.urgency, super.key});

  final PrUrgency urgency;

  @override
  Widget build(BuildContext context) {
    final FfColors colors =
        Theme.of(context).extension<FfColors>() ?? FfColors.light;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ({Color fg, Color bg}) style = PrLabels.urgencyColors(
      colors,
      urgency,
    );
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: FfSpace.space2,
        vertical: FfSpace.space1,
      ),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(FfRadius.md),
      ),
      child: Text(
        PrLabels.urgency(l10n, urgency),
        style: TextStyle(
          color: style.fg,
          fontSize: FfFont.xs,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Badge indicating a linked downstream `RDO` (Mod 045) or `PO` (Mod 046) document.
class PrLinkedDocBadge extends StatelessWidget {
  const PrLinkedDocBadge({required this.doc, super.key});

  final LinkedDocumentRef doc;

  @override
  Widget build(BuildContext context) {
    final FfColors colors =
        Theme.of(context).extension<FfColors>() ?? FfColors.light;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String label = doc.type == 'rdo'
        ? l10n.prLinkedRdoLabel(doc.number)
        : l10n.prLinkedPoLabel(doc.number);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: FfSpace.space2,
        vertical: FfSpace.space1,
      ),
      decoration: BoxDecoration(
        color: colors.primarySubtle,
        borderRadius: BorderRadius.circular(FfRadius.md),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            doc.type == 'rdo'
                ? Icons.request_quote_outlined
                : Icons.receipt_long_outlined,
            size: FfFont.sm,
            color: colors.primary,
          ),
          const SizedBox(width: FfSpace.space1),
          Text(
            label,
            style: TextStyle(
              color: colors.primary,
              fontSize: FfFont.xs,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
