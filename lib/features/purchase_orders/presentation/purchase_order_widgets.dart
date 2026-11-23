import 'package:material_ui/material_ui.dart';

import '../../../design/ff_tokens.dart';
import '../../supplier_rebates/domain/rebate_decimal.dart';
import '../../supplier_rebates/presentation/supplier_rebates_format.dart';
import '../../supplier_rebates/presentation/supplier_rebates_widgets.dart';
import '../domain/purchase_order_models.dart';
import 'purchase_order_strings.dart';

/// Chip kind of an order status (see `RebateChip`).
String poStatusKind(PoStatus status) => switch (status) {
  PoStatus.confirmed || PoStatus.received => 'success',
  PoStatus.sent || PoStatus.approved => 'info',
  PoStatus.pendingApproval || PoStatus.partiallyReceived => 'warning',
  PoStatus.cancelled => 'danger',
  PoStatus.draft || PoStatus.closed || PoStatus.unknown => 'neutral',
};

String dropshipStatusKind(DropshipStatus status) => switch (status) {
  DropshipStatus.delivered => 'success',
  DropshipStatus.partiallyDelivered => 'warning',
  DropshipStatus.ddtIssued => 'info',
  DropshipStatus.pending || DropshipStatus.unknown => 'neutral',
};

/// The ordered quantity in the purchase unit and, when it differs from the stock unit, the stock quantity next to it:
/// `10 BOX = 120 PCS`.
String dualQuantityText(
  Dec? quantity,
  String uom,
  PoLine line,
  String languageCode,
) {
  if (quantity == null) {
    return '';
  }
  final String own = '${RebateFormat.quantity(quantity, languageCode)} $uom'
      .trim();
  final Dec? factor = line.uomConversionFactor;
  if (!line.isDualUom || factor == null) {
    return own;
  }
  final String base = RebateFormat.quantity(quantity * factor, languageCode);
  return '$own = $base ${line.baseUom}';
}

/// `1 BOX = 12 PCS`.
String conversionText(PoLine line, String languageCode) => line.isDualUom
    ? '1 ${line.uom} = ${RebateFormat.quantity(line.uomConversionFactor!, languageCode)} ${line.baseUom}'
    : '';

/// `10% + 5%` for a discount cascade (empty when there is none).
String cascadeText(List<Dec> cascade, String languageCode) =>
    cascade.map((Dec d) => RebateFormat.percent(d, languageCode)).join(' + ');

class PoStatusChip extends StatelessWidget {
  const PoStatusChip({required this.order, required this.s, super.key});

  final PurchaseOrder order;
  final PurchaseOrderStrings s;

  @override
  Widget build(BuildContext context) => RebateChip(
    key: const Key('po-status-chip'),
    label: s.status(order),
    kind: poStatusKind(order.status),
  );
}

class DropshipStatusChip extends StatelessWidget {
  const DropshipStatusChip({
    required this.dropship,
    required this.s,
    super.key,
  });

  final Dropship dropship;
  final PurchaseOrderStrings s;

  @override
  Widget build(BuildContext context) => RebateChip(
    key: const Key('dropship-status-chip'),
    label: s.dropshipStatus(dropship),
    kind: dropshipStatusKind(dropship.status),
  );
}

/// A label with its value on one line.
class PoRow extends StatelessWidget {
  const PoRow({
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
  Widget build(BuildContext context) {
    final FfColors c = rebateColors(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: FfSpace.space1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(color: c.textSecondary, fontSize: FfFont.sm),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value,
              key: valueKey,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: c.text,
                fontSize: FfFont.sm,
                fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Orders list item: number, supplier, status, dropship and overdue marks, promised date and total.
class PoOrderCard extends StatelessWidget {
  const PoOrderCard({
    required this.order,
    required this.s,
    required this.today,
    required this.pending,
    required this.onTap,
    super.key,
  });

  final PurchaseOrder order;
  final PurchaseOrderStrings s;
  final DateTime today;

  /// Writes of this order still in the outbox.
  final int pending;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final FfColors c = rebateColors(context);
    final String lang = s.languageCode;
    final int late = order.daysOverdue(today);
    final DateTime? due =
        order.promisedDeliveryDate ?? order.expectedDeliveryDate;
    return Card(
      key: Key('po-card-${order.id}'),
      child: InkWell(
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
                      order.poNumber,
                      style: TextStyle(
                        color: c.text,
                        fontWeight: FontWeight.w700,
                        fontSize: FfFont.md,
                      ),
                    ),
                  ),
                  PoStatusChip(order: order, s: s),
                ],
              ),
              if (order.supplierName.isNotEmpty)
                Text(
                  order.supplierName,
                  style: TextStyle(color: c.textSecondary, fontSize: FfFont.sm),
                ),
              const SizedBox(height: FfSpace.space2),
              Wrap(
                spacing: FfSpace.space2,
                runSpacing: FfSpace.space1,
                children: <Widget>[
                  if (order.isDropship)
                    RebateChip(
                      key: Key('po-dropship-${order.id}'),
                      label: s(PO.dropshipBadge),
                      kind: 'info',
                    ),
                  if (late > 0)
                    RebateChip(
                      key: Key('po-overdue-${order.id}'),
                      label: s.count(PO.overdueBadge, late),
                      kind: 'danger',
                    ),
                  if (order.reminderCount > 0)
                    RebateChip(
                      key: Key('po-reminders-${order.id}'),
                      label: s.count(PO.remindersSent, order.reminderCount),
                      kind: 'warning',
                    ),
                  if (pending > 0)
                    RebateChip(
                      key: Key('po-pending-${order.id}'),
                      label: s(PO.outboxWaiting),
                      kind: 'warning',
                    ),
                ],
              ),
              const SizedBox(height: FfSpace.space2),
              if (due != null)
                PoRow(
                  label: order.promisedDeliveryDate != null
                      ? s(PO.promisedDate)
                      : s(PO.expectedDate),
                  value: RebateFormat.date(due, lang),
                ),
              if (order.totalAmount != null)
                PoRow(
                  label: s(PO.total),
                  value: RebateFormat.money(
                    order.totalAmount!,
                    order.currency,
                    lang,
                  ),
                  strong: true,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One row of the overdue radar with the reminder state and the "send reminder" button.
class PoOverdueCard extends StatelessWidget {
  const PoOverdueCard({
    required this.row,
    required this.s,
    required this.pending,
    required this.onOpen,
    required this.onRemind,
    super.key,
  });

  final OverdueOrder row;
  final PurchaseOrderStrings s;

  /// A reminder of this order already waits in the outbox.
  final bool pending;
  final VoidCallback onOpen;
  final VoidCallback onRemind;

  @override
  Widget build(BuildContext context) {
    final FfColors c = rebateColors(context);
    final PurchaseOrder o = row.order;
    return Card(
      key: Key('overdue-card-${o.id}'),
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(FfSpace.space3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      o.poNumber,
                      style: TextStyle(
                        color: c.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  RebateChip(
                    label: s.count(PO.overdueBadge, row.daysOverdue),
                    kind: 'danger',
                  ),
                ],
              ),
              Text(
                o.supplierName,
                style: TextStyle(color: c.textSecondary, fontSize: FfFont.sm),
              ),
              const SizedBox(height: FfSpace.space2),
              Text(
                s.count(PO.remindersSent, row.reminderCount),
                style: TextStyle(color: c.textSecondary, fontSize: FfFont.sm),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonal(
                  key: Key('overdue-remind-${o.id}'),
                  onPressed: pending || !row.nextReminderDue ? null : onRemind,
                  child: Text(
                    pending
                        ? s(PO.outboxWaiting)
                        : row.nextReminderDue
                        ? s(PO.sendReminder)
                        : s(PO.reminderWait),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Banner counting the overdue orders (shown over the order list).
class PoOverdueBanner extends StatelessWidget {
  const PoOverdueBanner({required this.count, required this.s, super.key});

  final int count;
  final PurchaseOrderStrings s;

  @override
  Widget build(BuildContext context) {
    final FfColors c = rebateColors(context);
    return Container(
      key: const Key('po-overdue-banner'),
      width: double.infinity,
      color: c.dangerBg,
      padding: const EdgeInsets.all(FfSpace.space3),
      child: Row(
        children: <Widget>[
          Icon(Icons.warning_amber_rounded, color: c.danger),
          const SizedBox(width: FfSpace.space2),
          Expanded(
            child: Text(
              s.count(PO.overdueAlert, count),
              style: TextStyle(color: c.danger, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dropshipment list item.
class DropshipCard extends StatelessWidget {
  const DropshipCard({
    required this.dropship,
    required this.s,
    required this.pending,
    required this.onTap,
    super.key,
  });

  final Dropship dropship;
  final PurchaseOrderStrings s;
  final int pending;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final FfColors c = rebateColors(context);
    return Card(
      key: Key('dropship-card-${dropship.id}'),
      child: InkWell(
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
                      dropship.recipientName,
                      style: TextStyle(
                        color: c.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  DropshipStatusChip(dropship: dropship, s: s),
                ],
              ),
              if (dropship.recipientAddress.isNotEmpty)
                Text(
                  dropship.recipientAddress,
                  style: TextStyle(color: c.textSecondary, fontSize: FfFont.sm),
                ),
              if (dropship.ddtNumber != null)
                PoRow(label: s(PO.ddtNumber), value: dropship.ddtNumber!),
              if (pending > 0)
                RebateChip(
                  key: Key('dropship-pending-${dropship.id}'),
                  label: s(PO.outboxWaiting),
                  kind: 'warning',
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// An order line with ordered / received / confirmed quantities (dual unit of measure), price and discounts.
class PoLineTile extends StatelessWidget {
  const PoLineTile({
    required this.line,
    required this.currency,
    required this.s,
    super.key,
  });

  final PoLine line;
  final String currency;
  final PurchaseOrderStrings s;

  @override
  Widget build(BuildContext context) {
    final FfColors c = rebateColors(context);
    final String lang = s.languageCode;
    return Padding(
      key: Key('po-line-${line.id}'),
      padding: const EdgeInsets.symmetric(vertical: FfSpace.space2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '${line.lineNumber}. ${line.description}',
            style: TextStyle(color: c.text, fontWeight: FontWeight.w600),
          ),
          PoRow(
            label: s(PO.ordered),
            value: dualQuantityText(line.quantityOrdered, line.uom, line, lang),
            valueKey: Key('po-line-ordered-${line.id}'),
          ),
          if (line.isDualUom)
            PoRow(
              label: s(PO.conversionFactor),
              value: conversionText(line, lang),
              valueKey: Key('po-line-factor-${line.id}'),
            ),
          if (line.quantityReceived != null)
            PoRow(
              label: s(PO.received),
              value: dualQuantityText(
                line.quantityReceived,
                line.uom,
                line,
                lang,
              ),
            ),
          if (line.quantityConfirmed != null)
            PoRow(
              label: s(PO.confirmed),
              value: dualQuantityText(
                line.quantityConfirmed,
                line.uom,
                line,
                lang,
              ),
            ),
          if (line.unitPrice != null)
            PoRow(
              label: s(PO.unitPrice),
              value: RebateFormat.money(line.unitPrice!, currency, lang),
            ),
          if (line.discountCascade.isNotEmpty)
            PoRow(
              label: s(PO.discountCascade),
              value: cascadeText(line.discountCascade, lang),
              valueKey: Key('po-line-cascade-${line.id}'),
            ),
          if (line.dueDate != null)
            PoRow(
              label: s(PO.promisedDate),
              value: RebateFormat.date(line.dueDate, lang),
            ),
        ],
      ),
    );
  }
}

/// Variances of one recorded confirmation.
class PoConfirmationCard extends StatelessWidget {
  const PoConfirmationCard({
    required this.confirmation,
    required this.currency,
    required this.s,
    super.key,
  });

  final PoConfirmation confirmation;
  final String currency;
  final PurchaseOrderStrings s;

  @override
  Widget build(BuildContext context) {
    final String lang = s.languageCode;
    return Card(
      key: Key('confirmation-${confirmation.id}'),
      child: Padding(
        padding: const EdgeInsets.all(FfSpace.space3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    confirmation.confirmationNumber,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                if (confirmation.requiresReview)
                  RebateChip(label: s(PO.requiresReview), kind: 'danger')
                else if (confirmation.hasVariance)
                  RebateChip(label: s(PO.hasVariance), kind: 'warning'),
              ],
            ),
            if (confirmation.confirmedAt != null)
              PoRow(
                label: s(PO.confirmedOn),
                value: RebateFormat.date(confirmation.confirmedAt, lang),
              ),
            if (confirmation.quantityVarianceTotal != null &&
                !confirmation.quantityVarianceTotal!.isZero)
              PoRow(
                label: s(PO.quantityVariance),
                value: RebateFormat.quantity(
                  confirmation.quantityVarianceTotal!,
                  lang,
                ),
              ),
            if (confirmation.priceVarianceTotal != null &&
                !confirmation.priceVarianceTotal!.isZero)
              PoRow(
                label: s(PO.priceVariance),
                value: RebateFormat.money(
                  confirmation.priceVarianceTotal!,
                  currency,
                  lang,
                ),
              ),
            for (final ConfirmationLine l in confirmation.lines)
              if (l.hasVariance && l.deliveryDelayDays != 0)
                PoRow(label: s(PO.delayDays), value: '${l.deliveryDelayDays}'),
          ],
        ),
      ),
    );
  }
}

/// Result of a pricing preview, with the stock-unit figures of the dual unit of measure.
class PricingPreviewCard extends StatelessWidget {
  const PricingPreviewCard({
    required this.preview,
    required this.currency,
    required this.baseUom,
    required this.s,
    super.key,
  });

  final PricingPreview preview;
  final String currency;
  final String baseUom;
  final PurchaseOrderStrings s;

  @override
  Widget build(BuildContext context) {
    final String lang = s.languageCode;
    String money(Dec v) => RebateFormat.money(v, currency, lang).trim();
    return Card(
      key: const Key('pricing-result'),
      child: Padding(
        padding: const EdgeInsets.all(FfSpace.space3),
        child: Column(
          children: <Widget>[
            if (preview.discountCascade.isNotEmpty)
              PoRow(
                label: s(PO.effectiveDiscount),
                value: RebateFormat.percent(
                  preview.effectiveDiscountPercent,
                  lang,
                ),
                valueKey: const Key('pricing-effective-discount'),
              ),
            PoRow(
              label: s(PO.netUnitPrice),
              value: money(preview.netUnitPrice),
              valueKey: const Key('pricing-net-unit'),
            ),
            PoRow(
              label: s(PO.quantityBase),
              value:
                  '${RebateFormat.quantity(preview.quantityBase, lang)} $baseUom'
                      .trim(),
              valueKey: const Key('pricing-quantity-base'),
            ),
            PoRow(
              label: s(PO.netPerBaseUnit),
              value: money(preview.netPricePerBaseUnit),
              valueKey: const Key('pricing-net-per-base'),
            ),
            PoRow(label: s(PO.lineNet), value: money(preview.lineNetAmount)),
            PoRow(label: s(PO.lineTax), value: money(preview.lineTaxAmount)),
            PoRow(
              label: s(PO.lineTotal),
              value: money(preview.lineTotalAmount),
              strong: true,
              valueKey: const Key('pricing-line-total'),
            ),
            if (preview.lineNetAmountCompanyCurrency != null)
              PoRow(
                label: s(PO.companyCurrency),
                value: RebateFormat.money(
                  preview.lineNetAmountCompanyCurrency!,
                  '',
                  lang,
                ).trim(),
              ),
            if (preview.estimated)
              Padding(
                padding: const EdgeInsets.only(top: FfSpace.space2),
                child: Text(
                  s(PO.estimatedOffline),
                  key: const Key('pricing-estimated'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Outbox rows of one order or dropshipment, with retry / discard for the refused ones.
class PoPendingList extends StatelessWidget {
  const PoPendingList({
    required this.pending,
    required this.s,
    required this.onRetry,
    required this.onDismiss,
    super.key,
  });

  final List<PoPendingAction> pending;
  final PurchaseOrderStrings s;
  final void Function(String queueUuid) onRetry;
  final void Function(String queueUuid) onDismiss;

  @override
  Widget build(BuildContext context) {
    if (pending.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      key: const Key('po-pending'),
      children: <Widget>[
        for (final PoPendingAction a in pending)
          ListTile(
            key: Key('po-pending-${a.queueUuid}'),
            dense: true,
            leading: Icon(a.rejected ? Icons.error_outline : Icons.schedule),
            title: Text(
              a.rejected ? s(PO.outboxRejected) : s(PO.outboxWaiting),
            ),
            subtitle: a.detail.isEmpty ? null : Text(a.detail),
            trailing: a.rejected
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextButton(
                        key: Key('po-retry-${a.queueUuid}'),
                        onPressed: () => onRetry(a.queueUuid),
                        child: Text(s(PO.retry)),
                      ),
                      TextButton(
                        key: Key('po-discard-${a.queueUuid}'),
                        onPressed: () => onDismiss(a.queueUuid),
                        child: Text(s(PO.discard)),
                      ),
                    ],
                  )
                : null,
          ),
      ],
    );
  }
}
