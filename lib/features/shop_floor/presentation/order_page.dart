import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../design/ff_tokens.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../data/shop_floor_repository.dart';
import '../domain/scan_resolver.dart';
import '../domain/shop_floor_models.dart';
import 'genealogy_view.dart';
import 'operation_terminal_page.dart';
import 'shop_floor_providers.dart';
import 'terminal_widgets.dart';

/// One production order: its operations (open the operator terminal), its material lines with staged lots, output
/// receipt and genealogy. Scanning here stages lots or checks in to a machine.
class OrderPage extends ConsumerStatefulWidget {
  const OrderPage({
    required this.tenantId,
    required this.orderId,
    this.userId,
    super.key,
  });

  final String tenantId;
  final String orderId;
  final String? userId;

  @override
  ConsumerState<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends ConsumerState<OrderPage> {
  ShopFloorRepository get _repo => ref.read(shopFloorRepositoryProvider);

  Future<void> _guard(Future<void> Function() action) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    try {
      await action();
    } on ShopFloorException catch (e) {
      if (mounted) {
        showTerminalMessage(context, shopFloorErrorText(l10n, e.error));
      }
    }
  }

  Future<void> _onCode(String code, ProductionOrder order) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ScanResult r = ScanResolver.resolve(
      code,
      knownOrderNumbers: <String>[order.orderNumber],
    );
    switch (r) {
      case LotScan():
        await _stage(order, r);
      case WorkCenterScan():
        await _checkInScanned(order, r);
      case OrderScan():
        if (mounted) {
          showTerminalMessage(context, l10n.mfgScanUnknown(code));
        }
      case UnknownScan():
        if (mounted) {
          showTerminalMessage(context, l10n.mfgScanUnknown(code));
        }
    }
  }

  Future<void> _checkInScanned(
    ProductionOrder order,
    WorkCenterScan scan,
  ) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final WorkCenter? wc = await _repo.findWorkCenter(
      widget.tenantId,
      scan.code,
    );
    if (!mounted) {
      return;
    }
    if (wc == null) {
      showTerminalMessage(context, l10n.mfgScanMachineNotFound(scan.code));
      return;
    }
    // The operation that runs on this machine; otherwise the first one not yet finished.
    final Iterable<OrderOperation> ops = order.operations.where(
      (OrderOperation o) => o.status != 'completed',
    );
    final OrderOperation? op =
        ops.where((OrderOperation o) => o.workCenterId == wc.id).firstOrNull ??
        ops.firstOrNull;
    if (op == null) {
      return;
    }
    await _repo.checkIn(
      tenantId: widget.tenantId,
      orderId: order.id,
      operationId: op.id,
      workCenter: wc,
      operatorId: widget.userId,
    );
    if (mounted) {
      showTerminalMessage(
        context,
        l10n.mfgCheckedIn(wc.name.isEmpty ? wc.code : wc.name),
      );
    }
  }

  Future<void> _stage(ProductionOrder order, LotScan scan) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    if (order.lines.isEmpty) {
      return;
    }
    final _StageChoice? choice = await showModalBottomSheet<_StageChoice>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => TerminalTheme(
        child: _StageSheet(order: order, scan: scan),
      ),
    );
    if (choice == null || !mounted) {
      return;
    }
    await _guard(() async {
      await _repo.stageLot(
        tenantId: widget.tenantId,
        orderId: order.id,
        lineId: choice.line.id,
        lotNumber: scan.lotNumber,
        quantity: choice.quantity,
        lotId: scan.lotId,
        gtin: scan.gtin,
      );
      if (mounted) {
        showTerminalMessage(context, l10n.mfgLotStaged(scan.lotNumber));
      }
    });
  }

  Future<void> _backflush(ProductionOrder order) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final List<String> keys = await _repo.backflush(widget.tenantId, order.id);
    if (!mounted) {
      return;
    }
    showTerminalMessage(context, l10n.mfgBackflushQueued(keys.length));
    if (keys.isNotEmpty) {
      ref.read(shopFloorSyncProvider).syncNow(widget.tenantId);
    }
  }

  Future<void> _receive(ProductionOrder order) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ({double quantity, String lot})? r =
        await showDialog<({double quantity, String lot})>(
          context: context,
          builder: (BuildContext context) =>
              TerminalTheme(child: _ReceiptDialog(order: order)),
        );
    if (r == null || !mounted) {
      return;
    }
    await _guard(() async {
      await _repo.receiveOutput(
        tenantId: widget.tenantId,
        orderId: order.id,
        quantity: r.quantity,
        lotNumber: r.lot,
        warehouseId: order.receiptWarehouseId,
      );
      if (mounted) {
        showTerminalMessage(context, l10n.mfgReceiptQueued);
        ref.read(shopFloorSyncProvider).syncNow(widget.tenantId);
      }
    });
  }

  Future<void> _genealogy(ProductionOrder order) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    try {
      final Map<String, dynamic> data = await _repo.fetchGenealogy(order.id);
      if (!mounted) {
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: Text(l10n.mfgGenealogy),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(child: GenealogyView(data: data)),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.mfgCancel),
            ),
          ],
        ),
      );
    } on DioException {
      if (mounted) {
        showTerminalMessage(context, l10n.mfgGenealogyOffline);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ProductionOrder? order = ref
        .watch(shopFloorOrdersProvider(widget.tenantId))
        .value
        ?.where((ProductionOrder o) => o.id == widget.orderId)
        .firstOrNull;
    return TerminalTheme(
      child: DefaultTabController(
        length: 2,
        child: Builder(
          builder: (BuildContext context) => Scaffold(
            appBar: AppBar(
              title: Text(order?.orderNumber ?? ''),
              actions: <Widget>[
                if (order != null) ...<Widget>[
                  IconButton(
                    key: const Key('mfg-receipt'),
                    tooltip: l10n.mfgReceipt,
                    onPressed: () => _receive(order),
                    icon: const Icon(Icons.inventory_2),
                  ),
                  IconButton(
                    key: const Key('mfg-genealogy'),
                    tooltip: l10n.mfgGenealogy,
                    onPressed: () => _genealogy(order),
                    icon: const Icon(Icons.account_tree),
                  ),
                ],
              ],
              bottom: TabBar(
                tabs: <Widget>[
                  Tab(text: l10n.mfgOperations),
                  Tab(text: l10n.mfgMaterials),
                ],
              ),
            ),
            body: order == null
                ? const SizedBox.shrink()
                : Column(
                    children: <Widget>[
                      SyncStrip(tenantId: widget.tenantId),
                      Padding(
                        padding: const EdgeInsets.all(FfSpace.space4),
                        child: TerminalScanBar(
                          hint: l10n.mfgScanPrompt,
                          onCode: (String c) => _onCode(c, order),
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          children: <Widget>[
                            _OperationList(
                              tenantId: widget.tenantId,
                              userId: widget.userId,
                              order: order,
                            ),
                            _MaterialsTab(
                              tenantId: widget.tenantId,
                              order: order,
                              onBackflush: () => _backflush(order),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _OperationList extends StatelessWidget {
  const _OperationList({
    required this.tenantId,
    required this.order,
    this.userId,
  });

  final String tenantId;
  final String? userId;
  final ProductionOrder order;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final FfColors colors = Theme.of(context).extension<FfColors>()!;
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: FfSpace.space4),
      itemCount: order.operations.length,
      separatorBuilder: (_, _) => const SizedBox(height: FfSpace.space3),
      itemBuilder: (BuildContext context, int i) {
        final OrderOperation op = order.operations[i];
        return Card(
          color: colors.surfaceRaised,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FfRadius.lg),
            side: BorderSide(color: colors.border, width: 2),
          ),
          child: ListTile(
            key: Key('mfg-op-${op.sequence}'),
            minVerticalPadding: FfSpace.space4,
            title: Text(
              '${op.sequence}  ${op.name}',
              style: const TextStyle(
                fontSize: FfFont.xl,
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Text(
              l10n.mfgProgress(
                fmtQty(op.completedQuantity),
                fmtQty(order.targetQuantity),
                order.uom,
              ),
              style: const TextStyle(fontSize: FfFont.lg),
            ),
            trailing: const Icon(Icons.chevron_right, size: 32),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => OperationTerminalPage(
                  tenantId: tenantId,
                  userId: userId,
                  orderId: order.id,
                  operationId: op.id,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MaterialsTab extends ConsumerWidget {
  const _MaterialsTab({
    required this.tenantId,
    required this.order,
    required this.onBackflush,
  });

  final String tenantId;
  final ProductionOrder order;
  final VoidCallback onBackflush;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final List<StagedLot> staged =
        ref.watch(_stagedProvider((tenantId, order.id))).value ??
        const <StagedLot>[];
    final bool hasUnposted = staged.any((StagedLot s) => !s.posted);
    final Map<String, OrderLine> lines = <String, OrderLine>{
      for (final OrderLine l in order.lines) l.id: l,
    };
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: FfSpace.space4),
      children: <Widget>[
        for (final OrderLine l in order.lines)
          ListTile(
            key: Key('mfg-line-${l.id}'),
            title: Text(
              l.label,
              style: const TextStyle(
                fontSize: FfFont.lg,
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Text(
              l10n.mfgOpenQty(fmtQty(l.openQuantity), l.uom),
              style: const TextStyle(fontSize: FfFont.lg),
            ),
          ),
        const Divider(),
        Text(
          l10n.mfgStagedLots,
          style: const TextStyle(
            fontSize: FfFont.xl,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (staged.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: FfSpace.space3),
            child: Text(
              l10n.mfgNoStaged,
              style: const TextStyle(fontSize: FfFont.lg),
            ),
          ),
        for (final StagedLot s in staged)
          ListTile(
            key: Key('mfg-staged-${s.lotNumber}'),
            title: Text(
              s.lotNumber,
              style: const TextStyle(
                fontSize: FfFont.lg,
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Text(
              '${lines[s.lineId]?.label ?? ''} · ${fmtQty(s.quantity)} ${lines[s.lineId]?.uom ?? ''}${s.posted ? ' · ${l10n.mfgPosted}' : ''}',
            ),
            trailing: s.posted
                ? const Icon(Icons.check_circle)
                : IconButton(
                    onPressed: () =>
                        ref.read(shopFloorRepositoryProvider).unstageLot(s.id),
                    icon: const Icon(Icons.delete),
                  ),
          ),
        const SizedBox(height: FfSpace.space4),
        FilledButton.icon(
          key: const Key('mfg-backflush'),
          onPressed: hasUnposted ? onBackflush : null,
          icon: const Icon(Icons.call_made),
          label: Text(l10n.mfgBackflush),
        ),
        const SizedBox(height: FfSpace.space5),
      ],
    );
  }
}

final _stagedProvider =
    StreamProvider.family<List<StagedLot>, (String, String)>(
      (Ref ref, (String, String) key) =>
          ref.watch(shopFloorRepositoryProvider).watchStaged(key.$1, key.$2),
    );

class _StageChoice {
  const _StageChoice(this.line, this.quantity);

  final OrderLine line;
  final double quantity;
}

class _StageSheet extends StatefulWidget {
  const _StageSheet({required this.order, required this.scan});

  final ProductionOrder order;
  final LotScan scan;

  @override
  State<_StageSheet> createState() => _StageSheetState();
}

class _StageSheetState extends State<_StageSheet> {
  late OrderLine _line = widget.order.lines.firstWhere(
    (OrderLine l) =>
        l.itemCode != null &&
        widget.scan.gtin != null &&
        l.itemCode == widget.scan.gtin,
    orElse: () => widget.order.lines.first,
  );
  late final TextEditingController _qty = TextEditingController(
    text: fmtQty(widget.scan.quantity ?? _line.openQuantity),
  );

  @override
  void dispose() {
    _qty.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        FfSpace.space4,
        FfSpace.space4,
        FfSpace.space4,
        MediaQuery.of(context).viewInsets.bottom + FfSpace.space4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.mfgSelectLine(widget.scan.lotNumber),
            style: const TextStyle(
              fontSize: FfFont.xl,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: FfSpace.space3),
          RadioGroup<String>(
            groupValue: _line.id,
            onChanged: (String? id) => setState(
              () => _line = widget.order.lines.firstWhere(
                (OrderLine l) => l.id == id,
              ),
            ),
            child: Column(
              children: <Widget>[
                for (final OrderLine l in widget.order.lines)
                  RadioListTile<String>(
                    key: Key('mfg-stage-line-${l.id}'),
                    value: l.id,
                    title: Text(
                      l.label,
                      style: const TextStyle(fontSize: FfFont.lg),
                    ),
                    subtitle: Text(
                      l10n.mfgOpenQty(fmtQty(l.openQuantity), l.uom),
                    ),
                  ),
              ],
            ),
          ),
          TextField(
            key: const Key('mfg-stage-qty'),
            controller: _qty,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: FfFont.xl),
            decoration: InputDecoration(
              labelText: l10n.mfgQuantity,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: FfSpace.space4),
          FilledButton(
            key: const Key('mfg-stage-confirm'),
            onPressed: () => Navigator.of(context).pop(
              _StageChoice(
                _line,
                double.tryParse(_qty.text.replaceAll(',', '.')) ?? 0,
              ),
            ),
            child: Text(l10n.mfgAdd),
          ),
        ],
      ),
    );
  }
}

class _ReceiptDialog extends StatefulWidget {
  const _ReceiptDialog({required this.order});

  final ProductionOrder order;

  @override
  State<_ReceiptDialog> createState() => _ReceiptDialogState();
}

class _ReceiptDialogState extends State<_ReceiptDialog> {
  late final TextEditingController _qty = TextEditingController(
    text: fmtQty(
      (widget.order.targetQuantity - widget.order.completedQuantity).clamp(
        0,
        double.infinity,
      ),
    ),
  );
  final TextEditingController _lot = TextEditingController();

  @override
  void dispose() {
    _qty.dispose();
    _lot.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.mfgReceipt),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            key: const Key('mfg-receipt-qty'),
            controller: _qty,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: l10n.mfgQuantity),
          ),
          TextField(
            key: const Key('mfg-receipt-lot'),
            controller: _lot,
            decoration: InputDecoration(labelText: l10n.mfgReceiptLot),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.mfgCancel),
        ),
        FilledButton(
          key: const Key('mfg-receipt-confirm'),
          onPressed: () => Navigator.of(context).pop((
            quantity: double.tryParse(_qty.text.replaceAll(',', '.')) ?? 0,
            lot: _lot.text,
          )),
          child: Text(l10n.mfgReceipt),
        ),
      ],
    );
  }
}
