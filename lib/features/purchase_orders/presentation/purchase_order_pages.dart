import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/providers.dart';
import '../../../design/ff_tokens.dart';
import '../../supplier_rebates/domain/rebate_decimal.dart';
import '../../supplier_rebates/presentation/supplier_rebates_format.dart';
import '../domain/purchase_order_models.dart';
import 'purchase_order_controller.dart';
import 'purchase_order_strings.dart';
import 'purchase_order_widgets.dart';

PurchaseOrderStrings _strings(WidgetRef ref) =>
    PurchaseOrderStrings(ref.watch(requestContextProvider).languageCode);

DateTime _today(WidgetRef ref) => ref.watch(purchaseOrderClockProvider)();

Widget _offlineBanner(PurchaseOrderStrings s) => MaterialBanner(
  key: const Key('po-offline'),
  content: Text(s(PO.offlineCopy)),
  actions: const <Widget>[SizedBox.shrink()],
);

void _toast(BuildContext context, PurchaseOrderStrings s, PoNotice notice) {
  final String text = switch (notice) {
    PoNotice.sent => s(PO.noticeSent),
    PoNotice.queued => s(PO.noticeQueued),
    PoNotice.rejected => s(PO.noticeRejected),
  };
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}

/// Parses a decimal typed by the user (`12,5` or `12.5`); `null` when it is not a number.
Dec? parseInputDecimal(String raw) =>
    Dec.tryParse(raw.trim().replaceAll(',', '.'));

/// Parses `10, 5` / `10; 5` into a discount cascade; `null` when any step is not a number between 0 and 100.
List<Dec>? parseCascade(String raw) {
  final List<String> parts = raw
      .split(RegExp(r'[;\s]+|,\s+'))
      .where((String p) => p.trim().isNotEmpty)
      .toList();
  final List<Dec> out = <Dec>[];
  for (final String p in parts) {
    final Dec? d = parseInputDecimal(p);
    if (d == null || d.isNegative || d > Dec.hundred) {
      return null;
    }
    out.add(d);
  }
  return out;
}

/// Workspace of the purchase orders: the order list with the overdue alert, the overdue radar with reminders and the
/// dropshipments, all readable offline.
class PurchaseOrdersHomePage extends ConsumerStatefulWidget {
  const PurchaseOrdersHomePage({super.key});

  @override
  ConsumerState<PurchaseOrdersHomePage> createState() =>
      _PurchaseOrdersHomePageState();
}

class _PurchaseOrdersHomePageState
    extends ConsumerState<PurchaseOrdersHomePage> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(purchaseOrderHubProvider.notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final PurchaseOrderStrings s = _strings(ref);
    final PurchaseOrderHubState state = ref.watch(purchaseOrderHubProvider);
    final PurchaseOrderHubController ctrl = ref.read(
      purchaseOrderHubProvider.notifier,
    );
    final DateTime today = _today(ref);
    final int late = state.overdueOrders(today).length;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(s(PO.title)),
          actions: <Widget>[
            IconButton(
              key: const Key('po-refresh'),
              tooltip: s(PO.refresh),
              icon: const Icon(Icons.refresh),
              onPressed: ctrl.load,
            ),
            IconButton(
              key: const Key('po-open-pricing'),
              tooltip: s(PO.pricingPreview),
              icon: const Icon(Icons.calculate_outlined),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const PricingPreviewPage(),
                ),
              ),
            ),
          ],
          bottom: TabBar(
            tabs: <Widget>[
              Tab(key: const Key('po-tab-orders'), text: s(PO.tabOrders)),
              Tab(key: const Key('po-tab-overdue'), text: s(PO.tabOverdue)),
              Tab(key: const Key('po-tab-dropships'), text: s(PO.tabDropships)),
            ],
          ),
        ),
        body: Column(
          children: <Widget>[
            if (state.loading) const LinearProgressIndicator(),
            if (state.fromCache || state.error?.kind == PoErrorKind.offline)
              _offlineBanner(s),
            if (state.error != null && state.error!.kind != PoErrorKind.offline)
              Padding(
                padding: const EdgeInsets.all(FfSpace.space3),
                child: Text(
                  state.forbidden ? s.error(state.error!) : s(PO.loadError),
                  key: const Key('po-error'),
                ),
              ),
            if (late > 0) PoOverdueBanner(count: late, s: s),
            Expanded(
              child: TabBarView(
                children: <Widget>[
                  _OrderList(
                    state: state,
                    s: s,
                    today: today,
                    onRefresh: ctrl.load,
                  ),
                  _OverdueList(state: state, s: s, onRefresh: ctrl.load),
                  _DropshipList(state: state, s: s, onRefresh: ctrl.load),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _list({
  required Future<void> Function() onRefresh,
  required List<Widget> children,
  required String empty,
  required Key emptyKey,
}) => RefreshIndicator(
  onRefresh: onRefresh,
  child: children.isEmpty
      ? ListView(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(FfSpace.space5),
              child: Center(child: Text(empty, key: emptyKey)),
            ),
          ],
        )
      : ListView(
          padding: const EdgeInsets.all(FfSpace.space2),
          children: children,
        ),
);

class _OrderList extends StatelessWidget {
  const _OrderList({
    required this.state,
    required this.s,
    required this.today,
    required this.onRefresh,
  });

  final PurchaseOrderHubState state;
  final PurchaseOrderStrings s;
  final DateTime today;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) => _list(
    onRefresh: onRefresh,
    empty: s(PO.empty),
    emptyKey: const Key('po-empty'),
    children: <Widget>[
      for (final PurchaseOrder o in state.orders)
        PoOrderCard(
          order: o,
          s: s,
          today: today,
          pending: state.pendingFor(o.id),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => PurchaseOrderDetailPage(orderId: o.id),
            ),
          ),
        ),
    ],
  );
}

class _OverdueList extends ConsumerWidget {
  const _OverdueList({
    required this.state,
    required this.s,
    required this.onRefresh,
  });

  final PurchaseOrderHubState state;
  final PurchaseOrderStrings s;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DateTime today = _today(ref);
    // The server radar when cached, else the overdue orders the phone derives from the cached dates.
    final List<OverdueOrder> rows = state.overdue.isNotEmpty
        ? state.overdue
        : <OverdueOrder>[
            for (final PurchaseOrder o in state.orders)
              if (o.isOverdue(today))
                OverdueOrder(
                  order: o,
                  daysOverdue: o.daysOverdue(today),
                  overdueLineIds: <String>[
                    for (final PoLine l in o.overdueLines(today)) l.id,
                  ],
                  reminderCount: o.reminderCount,
                  lastReminderAt: o.lastReminderAt,
                  nextReminderDue:
                      o.lastReminderAt == null ||
                      today.difference(o.lastReminderAt!).inDays >= 7,
                ),
          ];
    return _list(
      onRefresh: onRefresh,
      empty: s(PO.noOverdue),
      emptyKey: const Key('po-overdue-empty'),
      children: <Widget>[
        for (final OverdueOrder r in rows)
          PoOverdueCard(
            row: r,
            s: s,
            pending: state.pending.any(
              (PoPendingAction a) =>
                  a.kind == PoActionKind.reminder &&
                  a.targetId == r.order.id &&
                  !a.rejected,
            ),
            onOpen: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PurchaseOrderDetailPage(orderId: r.order.id),
              ),
            ),
            onRemind: () async {
              final PoActionOutcome out = await ref
                  .read(purchaseOrderHubProvider.notifier)
                  .remind(r.order.id);
              if (context.mounted) {
                _toast(context, s, switch (out.status) {
                  PoActionStatus.sent => PoNotice.sent,
                  PoActionStatus.queued => PoNotice.queued,
                  PoActionStatus.rejected => PoNotice.rejected,
                });
              }
            },
          ),
      ],
    );
  }
}

class _DropshipList extends StatelessWidget {
  const _DropshipList({
    required this.state,
    required this.s,
    required this.onRefresh,
  });

  final PurchaseOrderHubState state;
  final PurchaseOrderStrings s;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) => _list(
    onRefresh: onRefresh,
    empty: s(PO.noDropships),
    emptyKey: const Key('po-dropships-empty'),
    children: <Widget>[
      for (final Dropship d in state.dropships)
        DropshipCard(
          dropship: d,
          s: s,
          pending: state.pendingFor(d.id),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => DropshipDetailPage(dropshipId: d.id),
            ),
          ),
        ),
    ],
  );
}

/// One purchase order: header, lines with the dual unit of measure, confirmations, reminders and the buyer actions.
class PurchaseOrderDetailPage extends ConsumerStatefulWidget {
  const PurchaseOrderDetailPage({required this.orderId, super.key});

  final String orderId;

  @override
  ConsumerState<PurchaseOrderDetailPage> createState() =>
      _PurchaseOrderDetailPageState();
}

class _PurchaseOrderDetailPageState
    extends ConsumerState<PurchaseOrderDetailPage> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(purchaseOrderDetailProvider.notifier).load(widget.orderId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final PurchaseOrderStrings s = _strings(ref);
    final String lang = s.languageCode;
    final DateTime today = _today(ref);
    final PurchaseOrderDetailState state = ref.watch(
      purchaseOrderDetailProvider,
    );
    final PurchaseOrderDetailController ctrl = ref.read(
      purchaseOrderDetailProvider.notifier,
    );
    ref.listen<PoNotice?>(
      purchaseOrderDetailProvider.select(
        (PurchaseOrderDetailState d) => d.notice,
      ),
      (PoNotice? _, PoNotice? next) {
        if (next != null) {
          _toast(context, s, next);
          ctrl.clearNotice();
        }
      },
    );
    final PurchaseOrder? o = state.order;
    return Scaffold(
      appBar: AppBar(title: Text(o?.poNumber ?? s(PO.title))),
      body: o == null
          ? Center(
              child: state.loading
                  ? const CircularProgressIndicator()
                  : Text(
                      state.error == null
                          ? s(PO.loadError)
                          : s.error(state.error!),
                      key: const Key('po-detail-error'),
                    ),
            )
          : ListView(
              padding: const EdgeInsets.all(FfSpace.space3),
              children: <Widget>[
                if (state.loading) const LinearProgressIndicator(),
                Row(
                  children: <Widget>[
                    PoStatusChip(order: o, s: s),
                    const SizedBox(width: FfSpace.space2),
                    if (o.isDropship)
                      Text(
                        s(PO.dropshipBadge),
                        key: const Key('po-detail-dropship'),
                      ),
                  ],
                ),
                const SizedBox(height: FfSpace.space2),
                PoRow(label: s(PO.supplier), value: o.supplierName),
                PoRow(
                  label: s(PO.orderDate),
                  value: RebateFormat.date(o.orderDate, lang),
                ),
                PoRow(
                  label: s(PO.expectedDate),
                  value: RebateFormat.date(o.expectedDeliveryDate, lang),
                ),
                if (o.promisedDeliveryDate != null)
                  PoRow(
                    label: s(PO.promisedDate),
                    value: RebateFormat.date(o.promisedDeliveryDate, lang),
                    valueKey: const Key('po-detail-promised'),
                  ),
                if (o.supplierConfirmationNumber != null)
                  PoRow(
                    label: s(PO.confirmationNumber),
                    value: o.supplierConfirmationNumber!,
                    valueKey: const Key('po-detail-confirmation-number'),
                  ),
                if (o.totalAmount != null)
                  PoRow(
                    label: s(PO.total),
                    value: RebateFormat.money(o.totalAmount!, o.currency, lang),
                    strong: true,
                  ),
                if (o.isOverdue(today))
                  Padding(
                    padding: const EdgeInsets.only(top: FfSpace.space2),
                    child: PoOverdueBanner(count: 1, s: s),
                  ),
                PoPendingList(
                  pending: state.pending,
                  s: s,
                  onRetry: ctrl.retry,
                  onDismiss: ctrl.dismiss,
                ),
                const SizedBox(height: FfSpace.space3),
                Wrap(
                  spacing: FfSpace.space2,
                  children: <Widget>[
                    if (state.canConfirm)
                      FilledButton(
                        key: const Key('po-confirm-button'),
                        onPressed: state.busy
                            ? null
                            : () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      SupplierConfirmationPage(order: o),
                                ),
                              ),
                        child: Text(s(PO.confirmOrder)),
                      ),
                    if (state.canRemind(today))
                      FilledButton.tonal(
                        key: const Key('po-remind-button'),
                        onPressed: state.busy ? null : ctrl.remind,
                        child: Text(s(PO.sendReminder)),
                      ),
                  ],
                ),
                const Divider(),
                Text(
                  s(PO.lines),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                for (final PoLine l in o.lines)
                  PoLineTile(line: l, currency: o.currency, s: s),
                const Divider(),
                Text(
                  s(PO.confirmations),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (state.confirmations.isEmpty)
                  Text(
                    s(PO.noConfirmations),
                    key: const Key('po-no-confirmations'),
                  )
                else
                  for (final PoConfirmation c in state.confirmations)
                    PoConfirmationCard(
                      confirmation: c,
                      currency: o.currency,
                      s: s,
                    ),
                const Divider(),
                Text(
                  s(PO.reminderHistory),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (state.reminders.isEmpty)
                  Text(s(PO.noReminders), key: const Key('po-no-reminders'))
                else
                  for (final PoReminder r in state.reminders)
                    ListTile(
                      key: Key('reminder-${r.id}'),
                      dense: true,
                      title: Text('${s(PO.level)} ${r.level} · ${r.channel}'),
                      subtitle: Text(RebateFormat.date(r.sentAt, lang)),
                    ),
              ],
            ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.fieldKey,
    required this.label,
    required this.value,
    required this.languageCode,
    required this.onChanged,
  });

  final Key fieldKey;
  final String label;
  final DateTime? value;
  final String languageCode;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) => ListTile(
    key: fieldKey,
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    subtitle: Text(RebateFormat.date(value, languageCode)),
    trailing: const Icon(Icons.calendar_today_outlined),
    onTap: () async {
      final DateTime now = DateTime.now();
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: value ?? now,
        firstDate: DateTime(now.year - 1),
        lastDate: DateTime(now.year + 5),
      );
      if (picked != null) {
        onChanged(picked);
      }
    },
  );
}

/// Supplier confirmation form: number, date and, per line, the confirmed quantity, price and delivery date with the
/// reason of any variance. Works offline: the confirmation is queued and the order turns `confirmed` at once.
class SupplierConfirmationPage extends ConsumerStatefulWidget {
  const SupplierConfirmationPage({required this.order, super.key});

  final PurchaseOrder order;

  @override
  ConsumerState<SupplierConfirmationPage> createState() =>
      _SupplierConfirmationPageState();
}

class _LineForm {
  _LineForm(this.line)
    : quantity = TextEditingController(
        text: line.quantityOrdered?.toPlain() ?? '',
      ),
      price = TextEditingController(text: line.unitPrice?.toPlain() ?? ''),
      reason = TextEditingController(),
      date = line.dueDate;

  final PoLine line;
  final TextEditingController quantity;
  final TextEditingController price;
  final TextEditingController reason;
  DateTime? date;

  void dispose() {
    quantity.dispose();
    price.dispose();
    reason.dispose();
  }
}

class _SupplierConfirmationPageState
    extends ConsumerState<SupplierConfirmationPage> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final TextEditingController _number = TextEditingController();
  final TextEditingController _notes = TextEditingController();
  late final List<_LineForm> _lines = <_LineForm>[
    for (final PoLine l in widget.order.lines)
      if (!l.isClosed) _LineForm(l),
  ];
  DateTime _confirmedAt = DateTime.now();

  @override
  void dispose() {
    _number.dispose();
    _notes.dispose();
    for (final _LineForm l in _lines) {
      l.dispose();
    }
    super.dispose();
  }

  String? _decimalError(String? v, PurchaseOrderStrings s) {
    final String t = (v ?? '').trim();
    if (t.isEmpty) {
      return null;
    }
    final Dec? d = parseInputDecimal(t);
    return d == null || d.isNegative ? s(PO.invalidNumber) : null;
  }

  Future<void> _submit(PurchaseOrderStrings s) async {
    if (!(_form.currentState?.validate() ?? false)) {
      return;
    }
    final ConfirmationInput input = ConfirmationInput(
      confirmationNumber: _number.text,
      confirmedAt: _confirmedAt,
      notes: _notes.text,
      lines: <ConfirmationLineInput>[
        for (final _LineForm l in _lines)
          ConfirmationLineInput(
            purchaseOrderLineId: l.line.id,
            confirmedQuantity: parseInputDecimal(l.quantity.text),
            confirmedUnitPrice: parseInputDecimal(l.price.text),
            confirmedDeliveryDate: l.date,
            varianceReason: l.reason.text,
          ),
      ],
    );
    final PoActionOutcome? out = await ref
        .read(purchaseOrderDetailProvider.notifier)
        .confirm(input);
    if (out != null && out.status != PoActionStatus.rejected && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final PurchaseOrderStrings s = _strings(ref);
    final String lang = s.languageCode;
    final PurchaseOrderDetailState state = ref.watch(
      purchaseOrderDetailProvider,
    );
    String? required(String? v) =>
        (v ?? '').trim().isEmpty ? s(PO.fieldRequired) : null;
    return Scaffold(
      appBar: AppBar(title: Text(s(PO.confirmOrder))),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(FfSpace.space3),
          children: <Widget>[
            Text(widget.order.poNumber),
            TextFormField(
              key: const Key('confirm-number'),
              controller: _number,
              decoration: InputDecoration(labelText: s(PO.confirmationNumber)),
              validator: required,
            ),
            _DateField(
              fieldKey: const Key('confirm-date'),
              label: s(PO.confirmedOn),
              value: _confirmedAt,
              languageCode: lang,
              onChanged: (DateTime d) => setState(() => _confirmedAt = d),
            ),
            for (final _LineForm l in _lines) ...<Widget>[
              const Divider(),
              Text('${l.line.lineNumber}. ${l.line.description}'),
              Text(
                dualQuantityText(
                  l.line.quantityOrdered,
                  l.line.uom,
                  l.line,
                  lang,
                ),
              ),
              TextFormField(
                key: Key('confirm-qty-${l.line.id}'),
                controller: l.quantity,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: '${s(PO.confirmedQuantity)} (${l.line.uom})',
                ),
                validator: (String? v) => _decimalError(v, s),
              ),
              TextFormField(
                key: Key('confirm-price-${l.line.id}'),
                controller: l.price,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(labelText: s(PO.confirmedPrice)),
                validator: (String? v) => _decimalError(v, s),
              ),
              _DateField(
                fieldKey: Key('confirm-line-date-${l.line.id}'),
                label: s(PO.confirmedDeliveryDate),
                value: l.date,
                languageCode: lang,
                onChanged: (DateTime d) => setState(() => l.date = d),
              ),
              TextFormField(
                key: Key('confirm-reason-${l.line.id}'),
                controller: l.reason,
                decoration: InputDecoration(labelText: s(PO.varianceReason)),
              ),
            ],
            const Divider(),
            TextFormField(
              key: const Key('confirm-notes'),
              controller: _notes,
              decoration: InputDecoration(labelText: s(PO.notes)),
              maxLines: 2,
            ),
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.only(top: FfSpace.space2),
                child: Text(
                  s.error(state.error!),
                  key: const Key('confirm-error'),
                ),
              ),
            const SizedBox(height: FfSpace.space3),
            FilledButton(
              key: const Key('confirm-submit'),
              onPressed: state.busy ? null : () => _submit(s),
              child: Text(s(PO.submitConfirmation)),
            ),
          ],
        ),
      ),
    );
  }
}

/// A dropshipment: recipient, DDT, proof of delivery, virtual stock movements and the delivery recording.
class DropshipDetailPage extends ConsumerStatefulWidget {
  const DropshipDetailPage({required this.dropshipId, super.key});

  final String dropshipId;

  @override
  ConsumerState<DropshipDetailPage> createState() => _DropshipDetailPageState();
}

class _DropshipDetailPageState extends ConsumerState<DropshipDetailPage> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(dropshipDetailProvider.notifier).load(widget.dropshipId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final PurchaseOrderStrings s = _strings(ref);
    final String lang = s.languageCode;
    final DropshipDetailState state = ref.watch(dropshipDetailProvider);
    final DropshipDetailController ctrl = ref.read(
      dropshipDetailProvider.notifier,
    );
    ref.listen<PoNotice?>(
      dropshipDetailProvider.select((DropshipDetailState d) => d.notice),
      (PoNotice? _, PoNotice? next) {
        if (next != null) {
          _toast(context, s, next);
          ctrl.clearNotice();
        }
      },
    );
    final Dropship? d = state.dropship;
    return Scaffold(
      appBar: AppBar(title: Text(s(PO.tabDropships))),
      body: d == null
          ? Center(
              child: state.loading
                  ? const CircularProgressIndicator()
                  : Text(
                      state.error == null
                          ? s(PO.loadError)
                          : s.error(state.error!),
                      key: const Key('dropship-error'),
                    ),
            )
          : ListView(
              padding: const EdgeInsets.all(FfSpace.space3),
              children: <Widget>[
                if (state.loading) const LinearProgressIndicator(),
                DropshipStatusChip(dropship: d, s: s),
                PoRow(label: s(PO.recipient), value: d.recipientName),
                PoRow(label: s(PO.address), value: d.recipientAddress),
                if (d.recipientPhone != null)
                  PoRow(label: s(PO.phone), value: d.recipientPhone!),
                if (d.ddtNumber != null)
                  PoRow(label: s(PO.ddtNumber), value: d.ddtNumber!),
                if (d.supplierShipmentReference != null)
                  PoRow(
                    label: s(PO.shipmentReference),
                    value: d.supplierShipmentReference!,
                    valueKey: const Key('dropship-shipment-ref'),
                  ),
                if (d.deliveryProofReference != null)
                  PoRow(
                    label: s(PO.proofReference),
                    value: d.deliveryProofReference!,
                    valueKey: const Key('dropship-proof-ref'),
                  ),
                if (d.deliveredAt != null)
                  PoRow(
                    label: s(PO.deliveredOn),
                    value: RebateFormat.date(d.deliveredAt, lang),
                  ),
                if (d.billingAuthorized)
                  PoRow(label: s(PO.billingAuthorized), value: '✓'),
                if (d.deliveryNotes.isNotEmpty)
                  PoRow(label: s(PO.deliveryNotes), value: d.deliveryNotes),
                PoPendingList(
                  pending: state.pending,
                  s: s,
                  onRetry: ctrl.retry,
                  onDismiss: ctrl.dismiss,
                ),
                if (state.canRecordDelivery)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: FfSpace.space3,
                    ),
                    child: FilledButton(
                      key: const Key('dropship-record-delivery'),
                      onPressed: state.busy
                          ? null
                          : () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => DeliveryFormPage(
                                  dropship: d,
                                  order: state.order,
                                ),
                              ),
                            ),
                      child: Text(s(PO.recordDelivery)),
                    ),
                  ),
                if (d.movements.isNotEmpty) ...<Widget>[
                  const Divider(),
                  Text(
                    s(PO.virtualMovements),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  for (final DropshipMovement m in d.movements)
                    ListTile(
                      dense: true,
                      title: Text(
                        '${m.direction} ${RebateFormat.quantity(m.quantityBase ?? Dec.zero, lang)} ${m.baseUom}',
                      ),
                      subtitle: Text(RebateFormat.date(m.movedAt, lang)),
                    ),
                ],
              ],
            ),
    );
  }
}

/// Delivery notice form of a dropshipment: date, proof reference, supplier shipment reference and the delivered
/// quantity of each order line. Works offline.
class DeliveryFormPage extends ConsumerStatefulWidget {
  const DeliveryFormPage({required this.dropship, this.order, super.key});

  final Dropship dropship;

  /// The purchase order of the shipment; its lines are what can be delivered.
  final PurchaseOrder? order;

  @override
  ConsumerState<DeliveryFormPage> createState() => _DeliveryFormPageState();
}

class _DeliveryFormPageState extends ConsumerState<DeliveryFormPage> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final TextEditingController _proof = TextEditingController();
  late final TextEditingController _shipment = TextEditingController(
    text: widget.dropship.supplierShipmentReference ?? '',
  );
  late final Map<String, TextEditingController> _quantities =
      <String, TextEditingController>{
        for (final PoLine l in widget.order?.lines ?? const <PoLine>[])
          if (!l.isClosed)
            l.id: TextEditingController(
              text: l.quantityOrdered?.toPlain() ?? '',
            ),
      };
  DateTime _deliveredAt = DateTime.now();

  @override
  void dispose() {
    _proof.dispose();
    _shipment.dispose();
    for (final TextEditingController c in _quantities.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) {
      return;
    }
    final DeliveryInput input = DeliveryInput(
      deliveredAt: _deliveredAt,
      deliveryProofReference: _proof.text,
      supplierShipmentReference: _shipment.text,
      lines: <DeliveryLineInput>[
        for (final MapEntry<String, TextEditingController> e
            in _quantities.entries)
          if (parseInputDecimal(e.value.text) case final Dec q
              when q.isPositive)
            DeliveryLineInput(purchaseOrderLineId: e.key, quantityDelivered: q),
      ],
    );
    final PoActionOutcome? out = await ref
        .read(dropshipDetailProvider.notifier)
        .recordDelivery(input);
    if (out != null && out.status != PoActionStatus.rejected && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final PurchaseOrderStrings s = _strings(ref);
    final String lang = s.languageCode;
    final DropshipDetailState state = ref.watch(dropshipDetailProvider);
    return Scaffold(
      appBar: AppBar(title: Text(s(PO.recordDelivery))),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(FfSpace.space3),
          children: <Widget>[
            Text(widget.dropship.recipientName),
            _DateField(
              fieldKey: const Key('delivery-date'),
              label: s(PO.deliveredOn),
              value: _deliveredAt,
              languageCode: lang,
              onChanged: (DateTime d) => setState(() => _deliveredAt = d),
            ),
            TextFormField(
              key: const Key('delivery-proof'),
              controller: _proof,
              decoration: InputDecoration(labelText: s(PO.proofReference)),
              validator: (String? v) =>
                  (v ?? '').trim().isEmpty ? s(PO.fieldRequired) : null,
            ),
            TextFormField(
              key: const Key('delivery-shipment'),
              controller: _shipment,
              decoration: InputDecoration(labelText: s(PO.shipmentReference)),
            ),
            for (final PoLine l in widget.order?.lines ?? const <PoLine>[])
              if (_quantities.containsKey(l.id)) ...<Widget>[
                const Divider(),
                Text('${l.lineNumber}. ${l.description}'),
                TextFormField(
                  key: Key('delivery-qty-${l.id}'),
                  controller: _quantities[l.id],
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: '${s(PO.quantityDelivered)} (${l.uom})',
                    helperText: dualQuantityText(
                      l.quantityOrdered,
                      l.uom,
                      l,
                      lang,
                    ),
                  ),
                  validator: (String? v) {
                    final String t = (v ?? '').trim();
                    if (t.isEmpty) {
                      return null;
                    }
                    final Dec? q = parseInputDecimal(t);
                    return q == null || q.isNegative
                        ? s(PO.invalidNumber)
                        : null;
                  },
                ),
              ],
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.only(top: FfSpace.space2),
                child: Text(
                  s.error(state.error!),
                  key: const Key('delivery-error'),
                ),
              ),
            const SizedBox(height: FfSpace.space3),
            FilledButton(
              key: const Key('delivery-submit'),
              onPressed: state.busy ? null : _submit,
              child: Text(s(PO.submitDelivery)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Price preview of one line: cascading discounts, dual unit of measure, tax and exchange rate. The server answers
/// when reachable, otherwise the phone estimates with the same arithmetic.
class PricingPreviewPage extends ConsumerStatefulWidget {
  const PricingPreviewPage({super.key});

  @override
  ConsumerState<PricingPreviewPage> createState() => _PricingPreviewPageState();
}

class _PricingPreviewPageState extends ConsumerState<PricingPreviewPage> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final TextEditingController _quantity = TextEditingController();
  final TextEditingController _price = TextEditingController();
  final TextEditingController _cascade = TextEditingController();
  final TextEditingController _factor = TextEditingController();
  final TextEditingController _rate = TextEditingController();
  final TextEditingController _tax = TextEditingController();

  @override
  void dispose() {
    for (final TextEditingController c in <TextEditingController>[
      _quantity,
      _price,
      _cascade,
      _factor,
      _rate,
      _tax,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _calculate() async {
    if (!(_form.currentState?.validate() ?? false)) {
      return;
    }
    await ref
        .read(pricingPreviewProvider.notifier)
        .calculate(
          PricingInput(
            quantity: parseInputDecimal(_quantity.text)!,
            unitPrice: parseInputDecimal(_price.text)!,
            discountCascade: parseCascade(_cascade.text) ?? const <Dec>[],
            uomConversionFactor: parseInputDecimal(_factor.text),
            exchangeRate: parseInputDecimal(_rate.text),
            taxRate: parseInputDecimal(_tax.text),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final PurchaseOrderStrings s = _strings(ref);
    final PricingPreviewState state = ref.watch(pricingPreviewProvider);
    String? positive(String? v) {
      final Dec? d = parseInputDecimal(v ?? '');
      return (v ?? '').trim().isEmpty
          ? s(PO.fieldRequired)
          : d == null || d.isNegative
          ? s(PO.invalidNumber)
          : null;
    }

    String? optional(String? v) {
      if ((v ?? '').trim().isEmpty) {
        return null;
      }
      final Dec? d = parseInputDecimal(v!);
      return d == null || d.isNegative ? s(PO.invalidNumber) : null;
    }

    return Scaffold(
      appBar: AppBar(title: Text(s(PO.pricingPreview))),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(FfSpace.space3),
          children: <Widget>[
            TextFormField(
              key: const Key('pricing-quantity'),
              controller: _quantity,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(labelText: s(PO.quantity)),
              validator: (String? v) {
                final String? e = positive(v);
                return e ??
                    (parseInputDecimal(v!)!.isZero
                        ? s(PO.invalidNumber)
                        : null);
              },
            ),
            TextFormField(
              key: const Key('pricing-price'),
              controller: _price,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(labelText: s(PO.unitPrice)),
              validator: positive,
            ),
            TextFormField(
              key: const Key('pricing-cascade'),
              controller: _cascade,
              decoration: InputDecoration(
                labelText: s(PO.discountCascade),
                helperText: s(PO.discountCascadeHint),
              ),
              validator: (String? v) =>
                  parseCascade(v ?? '') == null ? s(PO.invalidNumber) : null,
            ),
            TextFormField(
              key: const Key('pricing-factor'),
              controller: _factor,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(labelText: s(PO.conversionFactor)),
              validator: optional,
            ),
            TextFormField(
              key: const Key('pricing-rate'),
              controller: _rate,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(labelText: s(PO.exchangeRate)),
              validator: optional,
            ),
            TextFormField(
              key: const Key('pricing-tax'),
              controller: _tax,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(labelText: s(PO.taxRate)),
              validator: optional,
            ),
            const SizedBox(height: FfSpace.space3),
            FilledButton(
              key: const Key('pricing-calculate'),
              onPressed: state.loading ? null : _calculate,
              child: Text(s(PO.calculate)),
            ),
            if (state.error != null)
              Text(s.error(state.error!), key: const Key('pricing-error')),
            if (state.preview != null)
              PricingPreviewCard(
                preview: state.preview!,
                currency: '',
                baseUom: '',
                s: s,
              ),
          ],
        ),
      ),
    );
  }
}
