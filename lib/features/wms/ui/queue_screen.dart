import 'package:material_ui/material_ui.dart';

import '../../../design/ff_tokens.dart';
import '../../../l10n/ff_strings.dart';
import '../models/transfer.dart';
import '../state/queue_state.dart';
import 'wms_labels.dart';

/// Operator queue: outbound transfers to dispatch and inbound transfers to receive.
class QueueScreen extends StatefulWidget {
  const QueueScreen({
    super.key,
    required this.controller,
    required this.onOpen,
  });

  final TransferQueueController controller;

  /// Called when the operator opens a transfer, with the direction of the tab it was listed in.
  final void Function(Transfer transfer, TransferDirection direction) onOpen;

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.init();
  }

  @override
  Widget build(BuildContext context) {
    final s = FfStrings.of(context);
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final c = widget.controller;
        return Scaffold(
          appBar: AppBar(
            title: Text(s.t(L.queueTitle)),
            actions: [
              IconButton(
                key: const Key('queue-refresh'),
                tooltip: s.t(L.refresh),
                onPressed: c.phase == QueuePhase.loading ? null : c.refresh,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(FfSpace.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (c.warehouses.isNotEmpty)
                  DropdownButtonFormField<String>(
                    key: const Key('warehouse-select'),
                    initialValue: c.warehouseId,
                    decoration: InputDecoration(
                      labelText: s.t(L.warehouse),
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      for (final w in c.warehouses)
                        DropdownMenuItem(value: w.id, child: Text(w.label)),
                    ],
                    onChanged: (id) {
                      if (id != null) c.selectWarehouse(id);
                    },
                  ),
                const SizedBox(height: FfSpace.space3),
                SegmentedButton<TransferDirection>(
                  key: const Key('direction-toggle'),
                  segments: [
                    ButtonSegment(
                      value: TransferDirection.outbound,
                      label: Text(s.t(L.outbound)),
                    ),
                    ButtonSegment(
                      value: TransferDirection.inbound,
                      label: Text(s.t(L.inbound)),
                    ),
                  ],
                  selected: {c.direction},
                  onSelectionChanged: (set) => c.setDirection(set.first),
                ),
                const SizedBox(height: FfSpace.space3),
                Expanded(child: _body(context, s, c)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _body(BuildContext context, FfStrings s, TransferQueueController c) {
    if (c.phase == QueuePhase.loading)
      return const Center(child: CircularProgressIndicator());
    if (c.phase == QueuePhase.failed) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              c.error ?? s.t(L.unexpectedError),
              key: const Key('queue-error'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: FfSpace.space3),
            OutlinedButton(onPressed: c.refresh, child: Text(s.t(L.retry))),
          ],
        ),
      );
    }
    if (c.transfers.isEmpty)
      return Center(
        child: Text(s.t(L.noTransfers), key: const Key('queue-empty')),
      );
    return RefreshIndicator(
      onRefresh: c.refresh,
      child: ListView.separated(
        itemCount: c.transfers.length,
        separatorBuilder: (_, _) => const SizedBox(height: FfSpace.space2),
        itemBuilder: (context, i) => _TransferTile(
          transfer: c.transfers[i],
          onTap: () => widget.onOpen(c.transfers[i], c.direction),
        ),
      ),
    );
  }
}

class _TransferTile extends StatelessWidget {
  const _TransferTile({required this.transfer, required this.onTap});

  final Transfer transfer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = FfStrings.of(context);
    final colors = Theme.of(context).extension<FfColors>()!;
    return Card(
      key: Key('transfer-${transfer.id}'),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(FfRadius.lg),
        side: BorderSide(color: colors.border),
      ),
      child: ListTile(
        onTap: onTap,
        title: Text(
          transfer.transferNumber,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${purposeLabel(s, transfer.purpose)} - ${s.t(L.linesCount, {'n': '${transfer.lines.length}'})}',
          style: TextStyle(color: colors.textSecondary, fontSize: FfFont.sm),
        ),
        trailing: StatusChip(status: transfer.status),
      ),
    );
  }
}
