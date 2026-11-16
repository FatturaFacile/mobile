import 'package:material_ui/material_ui.dart';

import '../../../design/ff_tokens.dart';
import '../../../l10n/ff_strings.dart';
import '../models/transfer.dart';
import '../state/receipt_state.dart';
import 'scan_field.dart';
import 'wms_labels.dart';

/// Step 2: scan each line, enter good / damaged quantities and confirm the receipt.
class ReceiptScreen extends StatelessWidget {
  const ReceiptScreen({super.key, required this.controller, this.cameraScanner, this.onDone});

  final ReceiptController controller;
  final CameraScanner? cameraScanner;
  final VoidCallback? onDone;

  @override
  Widget build(BuildContext context) {
    final s = FfStrings.of(context);
    final colors = Theme.of(context).extension<FfColors>()!;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final c = controller;
        final draft = c.draft;
        final submitted = c.phase == ReceiptPhase.submitted;
        return Scaffold(
          appBar: AppBar(title: Text(s.t(L.receiptTitle, {'number': c.transfer.transferNumber}))),
          body: ListView(
            padding: const EdgeInsets.all(FfSpace.space4),
            children: [
              if (draft.lines.isEmpty)
                Text(s.t(L.nothingOutstanding), key: const Key('receipt-nothing'))
              else ...[
                ScanField(
                  onScan: (code) async {
                    await c.scan(code);
                  },
                  enabled: !submitted && c.phase != ReceiptPhase.submitting,
                  cameraScanner: cameraScanner,
                ),
                if (c.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: FfSpace.space2),
                    child: Text(c.error!, key: const Key('receipt-error'), style: TextStyle(color: colors.danger)),
                  ),
                const SizedBox(height: FfSpace.space3),
                for (final line in draft.lines)
                  _ReceiptLineCard(
                    key: Key('receipt-line-${line.line.id}'),
                    line: line,
                    locked: submitted,
                    controller: c,
                  ),
                SwitchListTile(
                  key: const Key('partial-switch'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(s.t(L.partialReceipt)),
                  subtitle: Text(s.t(L.partialReceiptHint)),
                  value: draft.partial,
                  onChanged: submitted ? null : c.setPartial,
                ),
                Text(
                  s.t(switch (draft.expectedOutcome) {
                    ReceiptOutcome.received => L.expectedReceived,
                    ReceiptOutcome.discrepancyPending => L.expectedDiscrepancy,
                    ReceiptOutcome.partiallyReceived => L.expectedPartial,
                  }),
                  key: const Key('expected-outcome'),
                  style: TextStyle(color: colors.textSecondary),
                ),
                const SizedBox(height: FfSpace.space3),
                if (submitted)
                  _Result(transfer: c.result!, onDone: onDone)
                else
                  FilledButton(
                    key: const Key('receipt-confirm'),
                    onPressed: c.canSubmit ? c.submit : null,
                    child: c.phase == ReceiptPhase.submitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(s.t(L.confirmReceipt)),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({required this.transfer, required this.onDone});

  final Transfer transfer;
  final VoidCallback? onDone;

  @override
  Widget build(BuildContext context) {
    final s = FfStrings.of(context);
    final colors = Theme.of(context).extension<FfColors>()!;
    final needsApproval = transfer.status == TransferStatus.discrepancyPending;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.t(L.receiptResult, {'status': statusLabel(s, transfer.status)}),
          key: const Key('receipt-result'),
          style: TextStyle(color: colors.success, fontWeight: FontWeight.w600),
        ),
        if (needsApproval) ...[
          const SizedBox(height: FfSpace.space2),
          Container(
            key: const Key('manager-approval'),
            padding: const EdgeInsets.all(FfSpace.space3),
            decoration: BoxDecoration(color: colors.warningBg, borderRadius: BorderRadius.circular(FfRadius.md)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.t(L.needsManagerApproval),
                  style: TextStyle(color: colors.warning, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: FfSpace.space1),
                Text(s.t(L.managerApprovalNote), style: TextStyle(color: colors.text, fontSize: FfFont.sm)),
                for (final d in transfer.discrepancies)
                  Text(
                    '${s.t(L.shortageQty)}: ${formatQty(d.shortageQty)} / ${s.t(L.damagedQty)}: ${formatQty(d.damageQty)}',
                    style: TextStyle(color: colors.text, fontSize: FfFont.sm),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: FfSpace.space3),
        OutlinedButton(onPressed: onDone, child: Text(s.t(L.backToQueue))),
      ],
    );
  }
}

class _ReceiptLineCard extends StatelessWidget {
  const _ReceiptLineCard({super.key, required this.line, required this.locked, required this.controller});

  final ReceiptLineDraft line;
  final bool locked;
  final ReceiptController controller;

  @override
  Widget build(BuildContext context) {
    final s = FfStrings.of(context);
    final colors = Theme.of(context).extension<FfColors>()!;
    final id = line.line.id;
    final issue = line.issue;
    return Card(
      margin: const EdgeInsets.only(bottom: FfSpace.space3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(FfRadius.lg),
        side: BorderSide(color: line.scanned ? colors.success : colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(FfSpace.space3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  line.scanned ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: line.scanned ? colors.success : colors.textMuted,
                ),
                const SizedBox(width: FfSpace.space2),
                Expanded(child: Text(line.line.description, style: const TextStyle(fontWeight: FontWeight.w600))),
                Text('${s.t(L.outstanding)}: ${formatQty(line.outstanding)}', key: Key('outstanding-$id')),
              ],
            ),
            const SizedBox(height: FfSpace.space2),
            if (!line.scanned)
              Text(s.t(L.scanFirst), style: TextStyle(color: colors.textSecondary))
            else ...[
              Row(
                children: [
                  Expanded(
                    child: QuantityField(
                      fieldKey: Key('good-$id'),
                      label: s.t(L.goodQty),
                      value: line.good,
                      enabled: !locked,
                      onChanged: (v) => controller.setGood(id, v),
                    ),
                  ),
                  const SizedBox(width: FfSpace.space3),
                  Expanded(
                    child: QuantityField(
                      fieldKey: Key('damaged-$id'),
                      label: s.t(L.damagedQty),
                      value: line.damaged,
                      enabled: !locked,
                      onChanged: (v) => controller.setDamaged(id, v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: FfSpace.space2),
              Text(
                '${s.t(L.shortageQty)}: ${formatQty(line.shortage)}',
                key: Key('shortage-$id'),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: line.shortage > 0 ? colors.danger : colors.textSecondary,
                ),
              ),
              if (issue != null)
                Text(
                  s.t(issue == LineIssue.negative ? L.negativeQuantity : L.exceedsOutstanding),
                  key: Key('issue-$id'),
                  style: TextStyle(color: colors.danger, fontSize: FfFont.sm),
                ),
              if (line.hasDiscrepancy) ...[
                const SizedBox(height: FfSpace.space2),
                TextField(
                  key: Key('reason-$id'),
                  enabled: !locked,
                  decoration: InputDecoration(labelText: s.t(L.reason), border: const OutlineInputBorder()),
                  onChanged: (v) => controller.setReason(id, v),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// Numeric text field bound to a draft value. Invalid text is reported as -1 so the line is flagged and
/// the confirmation stays disabled until the operator fixes it.
class QuantityField extends StatefulWidget {
  const QuantityField({
    super.key,
    required this.fieldKey,
    required this.label,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final Key fieldKey;
  final String label;
  final double value;
  final bool enabled;
  final ValueChanged<double> onChanged;

  @override
  State<QuantityField> createState() => _QuantityFieldState();
}

class _QuantityFieldState extends State<QuantityField> {
  late final TextEditingController _text = TextEditingController(text: formatQty(widget.value));
  bool _invalid = false;

  @override
  void didUpdateWidget(QuantityField old) {
    super.didUpdateWidget(old);
    final typed = parseQuantityInput(_text.text);
    // Keep what the operator typed unless the draft changed from elsewhere (e.g. a scan pre-fill).
    if (typed != null && typed != widget.value) _text.text = formatQty(widget.value);
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = FfStrings.of(context);
    return TextField(
      key: widget.fieldKey,
      controller: _text,
      enabled: widget.enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: widget.label,
        border: const OutlineInputBorder(),
        errorText: _invalid ? s.t(L.invalidNumber) : null,
      ),
      onChanged: (raw) {
        final parsed = parseQuantityInput(raw);
        setState(() => _invalid = parsed == null);
        widget.onChanged(parsed ?? -1);
      },
    );
  }
}
