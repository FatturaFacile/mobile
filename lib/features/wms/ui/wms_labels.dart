import 'package:material_ui/material_ui.dart';

import '../../../design/ff_tokens.dart';
import '../../../l10n/ff_strings.dart';
import '../models/transfer.dart';

String purposeLabel(FfStrings s, TransferPurpose purpose) =>
    s.t(switch (purpose) {
      TransferPurpose.interWarehouse => L.purposeInterWarehouse,
      TransferPurpose.technicianVan => L.purposeTechnicianVan,
      TransferPurpose.interCompany => L.purposeInterCompany,
      TransferPurpose.customerConsignment => L.purposeCustomerConsignment,
      TransferPurpose.consignmentReturn => L.purposeConsignmentReturn,
      TransferPurpose.subcontracting => L.purposeSubcontracting,
      TransferPurpose.subcontractingReturn => L.purposeSubcontractingReturn,
      TransferPurpose.unknown => L.purposeUnknown,
    });

String statusLabel(FfStrings s, TransferStatus status) => s.t(switch (status) {
  TransferStatus.draft => L.statusDraft,
  TransferStatus.approved => L.statusApproved,
  TransferStatus.inTransit => L.statusInTransit,
  TransferStatus.partiallyReceived => L.statusPartiallyReceived,
  TransferStatus.received => L.statusReceived,
  TransferStatus.discrepancyPending => L.statusDiscrepancyPending,
  TransferStatus.closed => L.statusClosed,
  TransferStatus.cancelled => L.statusCancelled,
  TransferStatus.unknown => L.statusUnknown,
});

/// Formats a quantity without trailing zeros ("12", "2.5").
String formatQty(double value) {
  final rounded = roundQty(value);
  if (rounded == rounded.truncateToDouble()) return rounded.toStringAsFixed(0);
  return rounded.toStringAsFixed(4).replaceFirst(RegExp(r'0+$'), '');
}

/// Colours of a status chip taken from the design tokens.
({Color fg, Color bg}) statusColors(FfColors c, TransferStatus status) =>
    switch (status) {
      TransferStatus.approved => (fg: c.info, bg: c.infoBg),
      TransferStatus.inTransit => (fg: c.warning, bg: c.warningBg),
      TransferStatus.partiallyReceived => (fg: c.warning, bg: c.warningBg),
      TransferStatus.received ||
      TransferStatus.closed => (fg: c.success, bg: c.successBg),
      TransferStatus.discrepancyPending => (fg: c.danger, bg: c.dangerBg),
      _ => (fg: c.neutral, bg: c.neutralBg),
    };

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final TransferStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = statusColors(
      Theme.of(context).extension<FfColors>()!,
      status,
    );
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: FfSpace.space3,
        vertical: FfSpace.space1,
      ),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(FfRadius.lg),
      ),
      child: Text(
        statusLabel(FfStrings.of(context), status),
        style: TextStyle(
          color: colors.fg,
          fontSize: FfFont.xs,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
