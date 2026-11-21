import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/database/app_database.dart';
import '../../../design/ff_tokens.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../data/local/shop_floor_tables.dart';
import '../domain/scan_resolver.dart';
import '../domain/shop_floor_models.dart';
import 'order_page.dart';
import 'shop_floor_providers.dart';
import 'terminal_widgets.dart';

/// RBAC module keys that open the shop-floor terminal.
const Set<String> shopFloorModules = <String>{
  'shop_floor',
  'manufacturing_shop_floor',
  'mes_operator',
};

/// Operator entry point: scan or pick a released production order. Reads only the local cache; a background worker keeps
/// it fresh and sends the queued postings.
class ShopFloorHomePage extends ConsumerStatefulWidget {
  const ShopFloorHomePage({required this.tenantId, this.userId, super.key});

  final String tenantId;
  final String? userId;

  @override
  ConsumerState<ShopFloorHomePage> createState() => _ShopFloorHomePageState();
}

class _ShopFloorHomePageState extends ConsumerState<ShopFloorHomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(shopFloorSyncProvider).start(widget.tenantId);
      }
    });
  }

  @override
  void dispose() {
    // Reading a provider in dispose is not allowed; the coordinator stops with the provider scope.
    super.dispose();
  }

  Future<void> _refresh() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    try {
      await ref.read(shopFloorRepositoryProvider).refresh(widget.tenantId);
    } on DioException {
      if (mounted) {
        showTerminalMessage(context, l10n.mfgRefreshFailed);
      }
    }
  }

  Future<void> _onCode(String code, List<ProductionOrder> orders) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ScanResult r = ScanResolver.resolve(
      code,
      knownOrderNumbers: orders.map((ProductionOrder o) => o.orderNumber),
    );
    if (r is OrderScan) {
      final ProductionOrder? o = await ref
          .read(shopFloorRepositoryProvider)
          .findOrder(widget.tenantId, r.reference);
      if (!mounted) {
        return;
      }
      if (o == null) {
        showTerminalMessage(context, l10n.mfgScanOrderNotFound(r.reference));
        return;
      }
      _open(o);
    } else if (r is LotScan || r is WorkCenterScan) {
      showTerminalMessage(context, l10n.mfgScanSelectOrderFirst);
    } else {
      showTerminalMessage(context, l10n.mfgScanUnknown(code));
    }
  }

  void _open(ProductionOrder o) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OrderPage(
          tenantId: widget.tenantId,
          userId: widget.userId,
          orderId: o.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final List<ProductionOrder> orders =
        ref.watch(shopFloorOrdersProvider(widget.tenantId)).value ??
        const <ProductionOrder>[];
    return TerminalTheme(
      child: Builder(
        builder: (BuildContext context) => Scaffold(
          appBar: AppBar(
            title: Text(l10n.mfgTitle),
            actions: <Widget>[
              IconButton(
                key: const Key('mfg-refresh'),
                tooltip: l10n.mfgRefresh,
                onPressed: _refresh,
                icon: const Icon(Icons.refresh),
              ),
              IconButton(
                key: const Key('mfg-open-queue'),
                tooltip: l10n.mfgQueueTitle,
                onPressed: () => _openQueue(context),
                icon: const Icon(Icons.outbox),
              ),
            ],
          ),
          body: Column(
            children: <Widget>[
              SyncStrip(
                tenantId: widget.tenantId,
                onOpenQueue: () => _openQueue(context),
              ),
              Padding(
                padding: const EdgeInsets.all(FfSpace.space4),
                child: TerminalScanBar(
                  hint: l10n.mfgScanPrompt,
                  onCode: (String c) => _onCode(c, orders),
                ),
              ),
              Expanded(
                child: orders.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(FfSpace.space5),
                          child: Text(
                            l10n.mfgOrdersEmpty,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: FfFont.xl),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: FfSpace.space4,
                        ),
                        itemCount: orders.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: FfSpace.space3),
                        itemBuilder: (BuildContext context, int i) =>
                            _OrderCard(
                              order: orders[i],
                              onTap: () => _open(orders[i]),
                            ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openQueue(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SendQueuePage(tenantId: widget.tenantId),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onTap});

  final ProductionOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final FfColors colors = Theme.of(context).extension<FfColors>()!;
    final double ratio = order.targetQuantity <= 0
        ? 0
        : (order.completedQuantity / order.targetQuantity).clamp(0, 1);
    return Card(
      color: colors.surfaceRaised,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(FfRadius.lg),
        side: BorderSide(color: colors.border, width: 2),
      ),
      child: InkWell(
        key: Key('mfg-order-${order.orderNumber}'),
        borderRadius: BorderRadius.circular(FfRadius.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(FfSpace.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      order.orderNumber,
                      style: const TextStyle(
                        fontSize: FfFont.size2xl,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    statusText(l10n, order.status),
                    style: TextStyle(
                      fontSize: FfFont.lg,
                      color: colors.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              if (order.itemCode != null || order.itemName != null)
                Text(
                  '${order.itemCode ?? ''} ${order.itemName ?? ''}'.trim(),
                  style: const TextStyle(fontSize: FfFont.lg),
                ),
              const SizedBox(height: FfSpace.space2),
              LinearProgressIndicator(value: ratio, minHeight: 10),
              const SizedBox(height: FfSpace.space1),
              Text(
                l10n.mfgProgress(
                  fmtQty(order.completedQuantity),
                  fmtQty(order.targetQuantity),
                  order.uom,
                ),
                style: const TextStyle(fontSize: FfFont.lg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Everything still waiting to be sent, with the refused postings that need a decision.
class SendQueuePage extends ConsumerWidget {
  const SendQueuePage({required this.tenantId, super.key});

  final String tenantId;

  String _kind(AppLocalizations l10n, String kind) => switch (kind) {
    OutboxKind.issue => l10n.mfgKindIssue,
    OutboxKind.confirm => l10n.mfgKindConfirm,
    OutboxKind.receipt => l10n.mfgKindReceipt,
    OutboxKind.checkIn => l10n.mfgKindCheckIn,
    OutboxKind.inspection => l10n.mfgKindInspection,
    _ => kind,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final List<MfgOutboxRow> rows =
        (ref.watch(shopFloorQueueProvider(tenantId)).value ??
                const <MfgOutboxRow>[])
            .where((MfgOutboxRow r) => r.state != OutboxState.done)
            .toList();
    return TerminalTheme(
      child: Builder(
        builder: (BuildContext context) => Scaffold(
          appBar: AppBar(title: Text(l10n.mfgQueueTitle)),
          body: rows.isEmpty
              ? Center(
                  child: Text(
                    l10n.mfgQueueEmpty,
                    style: const TextStyle(fontSize: FfFont.xl),
                  ),
                )
              : ListView.separated(
                  itemCount: rows.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (BuildContext context, int i) {
                    final MfgOutboxRow r = rows[i];
                    final bool rejected = r.state == OutboxState.rejected;
                    final DateTime? next = r.nextAttemptAt?.toLocal();
                    return ListTile(
                      key: Key('mfg-queue-${r.uuid}'),
                      title: Text(
                        _kind(l10n, r.kind),
                        style: const TextStyle(
                          fontSize: FfFont.lg,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        <String>[
                          if (rejected) l10n.mfgQueueRejected,
                          if (!rejected && next != null)
                            l10n.mfgQueueRetryAt(
                              TimeOfDay.fromDateTime(next).format(context),
                            ),
                          if ((r.lastError ?? '').isNotEmpty) r.lastError!,
                        ].join(' · '),
                      ),
                      trailing: rejected
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                TextButton(
                                  onPressed: () => ref
                                      .read(shopFloorOutboxProvider)
                                      .retry(r.uuid),
                                  child: Text(l10n.mfgQueueRetry),
                                ),
                                TextButton(
                                  onPressed: () => ref
                                      .read(shopFloorOutboxProvider)
                                      .discard(r.uuid),
                                  child: Text(l10n.mfgQueueDiscard),
                                ),
                              ],
                            )
                          : null,
                    );
                  },
                ),
        ),
      ),
    );
  }
}
