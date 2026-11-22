import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../design/ff_tokens.dart';
import '../domain/money.dart';
import '../domain/receivables_models.dart';
import 'receivables_controller.dart';
import 'receivables_statement_page.dart';
import 'receivables_strings.dart';
import 'receivables_widgets.dart';

/// RBAC module key of the receivables and credit management screens.
const String receivablesModule = 'receivables';

void _openCustomer(
  BuildContext context,
  String customerId, {
  String customerName = '',
  String? bucket,
}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      settings: RouteSettings(name: '/receivables/customers/$customerId'),
      builder: (_) => CustomerCreditPage(
        customerId: customerId,
        customerName: customerName,
        initialBucket: bucket,
      ),
    ),
  );
}

// --- Dashboard ---------------------------------------------------------------------------------------------------

/// Receivables overview: KPIs, customers on credit block and the aging buckets with drill-down to the customers.
class ReceivablesDashboardPage extends ConsumerStatefulWidget {
  const ReceivablesDashboardPage({super.key});

  @override
  ConsumerState<ReceivablesDashboardPage> createState() =>
      _ReceivablesDashboardPageState();
}

class _ReceivablesDashboardPageState
    extends ConsumerState<ReceivablesDashboardPage> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(receivablesDashboardProvider.notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ReceivablesStrings s = ReceivablesStrings.of(context);
    final ReceivablesDashboardState state = ref.watch(
      receivablesDashboardProvider,
    );
    final ReceivablesDashboardController ctrl = ref.read(
      receivablesDashboardProvider.notifier,
    );
    final ReceivablesDashboard? d = state.dashboard;
    final String currency = d?.currency ?? state.currency ?? '';
    return Scaffold(
      appBar: AppBar(
        title: Text(s.t(RC.title)),
        actions: <Widget>[
          IconButton(
            key: const Key('receivables-refresh'),
            tooltip: s.t(RC.refresh),
            icon: const Icon(Icons.refresh),
            onPressed: ctrl.load,
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          if (state.loading) const LinearProgressIndicator(),
          if (state.fromCache ||
              state.error?.kind == ReceivablesErrorKind.offline)
            MaterialBanner(
              key: const Key('receivables-offline'),
              content: Text(s.t(RC.offlineCopy)),
              actions: const <Widget>[SizedBox.shrink()],
            ),
          if (state.pending.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: FfSpace.space3,
                vertical: FfSpace.space1,
              ),
              child: Row(
                key: const Key('receivables-pending'),
                children: <Widget>[
                  const Icon(Icons.cloud_upload_outlined, size: 18),
                  const SizedBox(width: FfSpace.space2),
                  Expanded(
                    child: Text(
                      s.f(RC.pendingBanner, <String, Object>{
                        'n': state.pending.length,
                      }),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: ctrl.load,
              child: ListView(
                padding: const EdgeInsets.all(FfSpace.space3),
                children: <Widget>[
                  if (state.error != null &&
                      state.error!.kind != ReceivablesErrorKind.offline &&
                      !state.loading)
                    Padding(
                      padding: const EdgeInsets.only(bottom: FfSpace.space3),
                      child: Text(
                        s.error(state.error!),
                        key: const Key('receivables-error'),
                      ),
                    ),
                  if (d != null) ...<Widget>[
                    if (d.aging.availableCurrencies.length > 1)
                      _CurrencyChips(
                        selected: currency,
                        available: d.aging.availableCurrencies,
                        onSelected: ctrl.setCurrency,
                      ),
                    _KpiGrid(kpis: d.kpis, currency: currency),
                    const SizedBox(height: FfSpace.space4),
                    _BlockedSection(blocked: d.blocked, currency: currency),
                    const SizedBox(height: FfSpace.space4),
                    _AgingSection(aging: d.aging, currency: currency),
                    const SizedBox(height: FfSpace.space4),
                    _CustomersSection(aging: d.aging, currency: currency),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrencyChips extends StatelessWidget {
  const _CurrencyChips({
    required this.selected,
    required this.available,
    required this.onSelected,
  });

  final String selected;
  final List<String> available;
  final void Function(String? currency) onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: FfSpace.space3),
      child: Wrap(
        spacing: FfSpace.space2,
        children: <Widget>[
          for (final String code in available)
            ChoiceChip(
              key: Key('currency-$code'),
              label: Text(code),
              selected: code == selected,
              onSelected: (_) => onSelected(code),
            ),
        ],
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.kpis, required this.currency});

  final ReceivablesKpis kpis;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final ReceivablesStrings s = ReceivablesStrings.of(context);
    final List<(String, String, String)> tiles = <(String, String, String)>[
      ('exposure', s.t(RC.kpiExposure), s.money(kpis.totalExposure, currency)),
      ('open', s.t(RC.kpiOpen), s.money(kpis.totalOpen, currency)),
      ('overdue', s.t(RC.kpiOverdue), s.money(kpis.overdueAmount, currency)),
      ('over90', s.t(RC.kpiOver90), s.money(kpis.over90, currency)),
      (
        'dso',
        s.t(RC.kpiDso),
        kpis.dso == null
            ? '-'
            : s.f(RC.daysValue, <String, Object>{
                'n': kpis.dso!.toStringAsFixed(1),
              }),
      ),
      (
        'provision',
        s.t(RC.kpiProvision),
        s.money(kpis.badDebtProvision, currency),
      ),
      ('nrv', s.t(RC.kpiNrv), s.money(kpis.netRealizableValue, currency)),
      ('blocked', s.t(RC.kpiBlocked), '${kpis.blockedCustomers}'),
      ('overrides', s.t(RC.kpiOverrides), '${kpis.activeOverrides}'),
    ];
    return Wrap(
      spacing: FfSpace.space2,
      runSpacing: FfSpace.space2,
      children: <Widget>[
        for (final (String key, String label, String value) in tiles)
          SizedBox(
            width: 168,
            child: Card(
              key: Key('kpi-$key'),
              child: Padding(
                padding: const EdgeInsets.all(FfSpace.space3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: FfFont.xs,
                        color: receivablesColors(context).textSecondary,
                      ),
                    ),
                    const SizedBox(height: FfSpace.space1),
                    Text(
                      value,
                      key: Key('kpi-$key-value'),
                      style: const TextStyle(
                        fontSize: FfFont.lg,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _BlockedSection extends StatelessWidget {
  const _BlockedSection({required this.blocked, required this.currency});

  final List<BlockedCustomer> blocked;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final ReceivablesStrings s = ReceivablesStrings.of(context);
    final FfColors c = receivablesColors(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          s.t(RC.blockedCustomers),
          style: const TextStyle(
            fontSize: FfFont.lg,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: FfSpace.space2),
        if (blocked.isEmpty)
          Text(s.t(RC.noBlocked), key: const Key('blocked-empty')),
        for (final BlockedCustomer b in blocked)
          Container(
            key: Key('blocked-${b.customerId}'),
            margin: const EdgeInsets.only(bottom: FfSpace.space2),
            decoration: BoxDecoration(
              color: c.dangerBg,
              border: Border.all(color: c.danger),
              borderRadius: BorderRadius.circular(FfRadius.md),
            ),
            child: ListTile(
              leading: Icon(Icons.block, color: c.danger),
              title: Text(
                b.customerName.isEmpty ? b.customerId : b.customerName,
              ),
              subtitle: Text(
                <String>[
                  if (b.reason.isNotEmpty) b.reason,
                  if (b.limit != null)
                    s.f(RC.blockedRow, <String, Object>{
                      'exposure': s.money(b.exposure, currency),
                      'limit': s.money(b.limit!, currency),
                    }),
                ].join('\n'),
              ),
              onTap: () => _openCustomer(
                context,
                b.customerId,
                customerName: b.customerName,
              ),
            ),
          ),
      ],
    );
  }
}

class _AgingSection extends StatelessWidget {
  const _AgingSection({required this.aging, required this.currency});

  final AgingReport aging;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final ReceivablesStrings s = ReceivablesStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          s.t(RC.agingTitle),
          style: const TextStyle(
            fontSize: FfFont.lg,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: FfSpace.space2),
        if (aging.buckets.isEmpty || !aging.totalOpen.isPositive)
          Text(s.t(RC.agingEmpty), key: const Key('aging-empty')),
        if (aging.totalOpen.isPositive)
          for (final AgingBucketDef def in aging.buckets)
            InkWell(
              key: Key('aging-bucket-${def.key}'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => AgingBucketPage(bucketKey: def.key),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: FfSpace.space2),
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(child: Text(s.bucket(def))),
                        Text(
                          s.money(aging.totalOf(def.key), currency),
                          key: Key('aging-total-${def.key}'),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    const SizedBox(height: FfSpace.space1),
                    AgingShareBar(
                      share: aging.shareOf(def.key),
                      overdue: !def.isCurrent,
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}

class _CustomersSection extends StatelessWidget {
  const _CustomersSection({required this.aging, required this.currency});

  final AgingReport aging;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final ReceivablesStrings s = ReceivablesStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          s.t(RC.customersTitle),
          style: const TextStyle(
            fontSize: FfFont.lg,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (aging.customers.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: FfSpace.space2),
            child: Text(s.t(RC.noCustomers), key: const Key('customers-empty')),
          ),
        for (final AgingCustomer c in aging.customers)
          ListTile(
            key: Key('customer-row-${c.customerId}'),
            contentPadding: EdgeInsets.zero,
            title: Text(c.customerName.isEmpty ? c.customerId : c.customerName),
            subtitle: Text(
              s.f(RC.customerOpenOverdue, <String, Object>{
                'open': s.money(c.totalOpen, currency),
                'overdue': s.money(c.totalOverdue, currency),
              }),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openCustomer(
              context,
              c.customerId,
              customerName: c.customerName,
            ),
          ),
      ],
    );
  }
}

/// Drill-down of one aging bucket: the customers with an amount in it, largest first.
class AgingBucketPage extends ConsumerWidget {
  const AgingBucketPage({required this.bucketKey, super.key});

  final String bucketKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ReceivablesStrings s = ReceivablesStrings.of(context);
    final AgingReport? aging = ref.watch(receivablesDashboardProvider).aging;
    final String currency = aging?.currency ?? '';
    AgingBucketDef? def;
    for (final AgingBucketDef b in aging?.buckets ?? <AgingBucketDef>[]) {
      if (b.key == bucketKey) {
        def = b;
      }
    }
    final List<AgingCustomer> rows =
        aging?.customersIn(bucketKey) ?? <AgingCustomer>[];
    return Scaffold(
      appBar: AppBar(title: Text(def == null ? bucketKey : s.bucket(def))),
      body: rows.isEmpty
          ? Center(
              child: Text(s.t(RC.noCustomers), key: const Key('bucket-empty')),
            )
          : ListView(
              children: <Widget>[
                for (final AgingCustomer c in rows)
                  ListTile(
                    key: Key('bucket-customer-${c.customerId}'),
                    title: Text(
                      c.customerName.isEmpty ? c.customerId : c.customerName,
                    ),
                    trailing: Text(
                      s.money(c.amountIn(bucketKey), currency),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    onTap: () => _openCustomer(
                      context,
                      c.customerId,
                      customerName: c.customerName,
                      bucket: bucketKey,
                    ),
                  ),
              ],
            ),
    );
  }
}

// --- Customer credit ---------------------------------------------------------------------------------------------

String? _noticeText(ReceivablesStrings s, CustomerCreditState st) =>
    switch (st.notice) {
      ReceivablesNotice.allocated => s.t(RC.noticeAllocated),
      ReceivablesNotice.allocationQueued => s.t(RC.noticeAllocationQueued),
      ReceivablesNotice.reversed => s.t(RC.noticeReversed),
      ReceivablesNotice.reverseQueued => s.t(RC.noticeReverseQueued),
      ReceivablesNotice.disputed => s.t(RC.noticeDisputed),
      ReceivablesNotice.disputeQueued => s.t(RC.noticeDisputeQueued),
      ReceivablesNotice.disputeLifted => s.t(RC.noticeDisputeLifted),
      ReceivablesNotice.disputeLiftQueued => s.t(RC.noticeDisputeLiftQueued),
      ReceivablesNotice.rejected =>
        st.noticeDetail.isEmpty ? s.t(RC.noticeRejected) : st.noticeDetail,
      null => null,
    };

void _listenForNotice(
  BuildContext context,
  WidgetRef ref,
  ReceivablesStrings s,
) {
  ref.listen<CustomerCreditState>(customerCreditProvider, (
    CustomerCreditState? prev,
    CustomerCreditState next,
  ) {
    final String? text = _noticeText(s, next);
    if (text != null && next.notice != prev?.notice) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(text)));
      ref.read(customerCreditProvider.notifier).clearNotice();
    }
  });
}

/// Credit status of one customer: limit, exposure, utilisation gauge, block and warning banners, overrides, risk,
/// aging chips and the open items with their bookings.
class CustomerCreditPage extends ConsumerStatefulWidget {
  const CustomerCreditPage({
    required this.customerId,
    this.customerName = '',
    this.initialBucket,
    super.key,
  });

  final String customerId;
  final String customerName;
  final String? initialBucket;

  @override
  ConsumerState<CustomerCreditPage> createState() => _CustomerCreditPageState();
}

class _CustomerCreditPageState extends ConsumerState<CustomerCreditPage> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref
          .read(customerCreditProvider.notifier)
          .load(
            widget.customerId,
            customerName: widget.customerName,
            bucket: widget.initialBucket,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ReceivablesStrings s = ReceivablesStrings.of(context);
    final CustomerCreditState st = ref.watch(customerCreditProvider);
    final CustomerCreditController ctrl = ref.read(
      customerCreditProvider.notifier,
    );
    _listenForNotice(context, ref, s);
    final CreditPosition? credit = st.credit;
    final String currency = credit?.limit?.currency ?? st.aging?.currency ?? '';
    final DateTime now = ref.watch(receivablesClockProvider)();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.customerName.isEmpty
              ? s.t(RC.customerTitle)
              : widget.customerName,
          key: const Key('customer-title'),
        ),
        actions: <Widget>[
          IconButton(
            key: const Key('open-statement'),
            tooltip: s.t(RC.statement),
            icon: const Icon(Icons.description_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => CustomerStatementPage(
                  customerId: widget.customerId,
                  customerName: widget.customerName,
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ctrl.load(
          widget.customerId,
          customerName: widget.customerName,
          bucket: st.bucket,
        ),
        child: ListView(
          padding: const EdgeInsets.all(FfSpace.space3),
          children: <Widget>[
            if (st.loading) const LinearProgressIndicator(),
            if (st.fromCache && !st.loading && st.credit != null)
              Padding(
                padding: const EdgeInsets.only(bottom: FfSpace.space2),
                child: Text(
                  s.t(RC.offlineCopy),
                  key: const Key('customer-offline'),
                ),
              ),
            if (st.error != null &&
                st.error!.kind != ReceivablesErrorKind.offline &&
                !st.loading)
              Padding(
                padding: const EdgeInsets.only(bottom: FfSpace.space2),
                child: Text(
                  s.error(st.error!),
                  key: const Key('customer-error'),
                ),
              ),
            if (credit != null) ...<Widget>[
              CreditBlockBanner(position: credit),
              for (final CreditOverride o in credit.activeOverrides(now))
                _OverrideCard(override: o),
              _CreditCard(position: credit, currency: currency),
            ],
            if (st.risk != null) _RiskRow(risk: st.risk!),
            _PendingList(
              pending: st.pending,
              onRetry: ctrl.retry,
              onDismiss: ctrl.dismiss,
            ),
            const SizedBox(height: FfSpace.space3),
            Text(
              s.t(RC.openItems),
              style: const TextStyle(
                fontSize: FfFont.lg,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (st.aging != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: FfSpace.space2),
                child: Wrap(
                  spacing: FfSpace.space2,
                  children: <Widget>[
                    ChoiceChip(
                      key: const Key('bucket-all'),
                      label: Text(s.t(RC.allBuckets)),
                      selected: st.bucket == null,
                      onSelected: (_) => ctrl.setBucket(null),
                    ),
                    for (final AgingBucketDef def in st.aging!.buckets)
                      ChoiceChip(
                        key: Key('bucket-${def.key}'),
                        label: Text(
                          '${s.bucket(def)} · ${s.money(st.aging!.totalOf(def.key))}',
                        ),
                        selected: st.bucket == def.key,
                        onSelected: (_) => ctrl.setBucket(def.key),
                      ),
                  ],
                ),
              ),
            if (st.visibleItems.isEmpty && !st.loading)
              Padding(
                padding: const EdgeInsets.all(FfSpace.space4),
                child: Center(
                  child: Text(s.t(RC.noItems), key: const Key('items-empty')),
                ),
              ),
            for (final ReceivableItem item in st.visibleItems)
              _ItemCard(item: item, pending: st.pendingFor(item.id)),
          ],
        ),
      ),
    );
  }
}

class _OverrideCard extends StatelessWidget {
  const _OverrideCard({required this.override});

  final CreditOverride override;

  @override
  Widget build(BuildContext context) {
    final ReceivablesStrings s = ReceivablesStrings.of(context);
    final FfColors c = receivablesColors(context);
    final List<String> lines = <String>[
      s.overrideScope(override.scope),
      if (override.expiresAt != null)
        s.f(RC.overrideUntil, <String, Object>{
          'date': s.date(override.expiresAt),
        }),
      if (override.authorizedBy != null)
        s.f(RC.overrideBy, <String, Object>{'name': override.authorizedBy!}),
      if (override.reason.isNotEmpty) override.reason,
    ];
    return Container(
      key: Key('override-${override.id}'),
      margin: const EdgeInsets.only(bottom: FfSpace.space3),
      padding: const EdgeInsets.all(FfSpace.space3),
      decoration: BoxDecoration(
        color: c.infoBg,
        border: Border.all(color: c.info),
        borderRadius: BorderRadius.circular(FfRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.verified_user_outlined, color: c.info),
          const SizedBox(width: FfSpace.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  s.t(RC.overrideActive),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(lines.join('\n')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CreditCard extends StatelessWidget {
  const _CreditCard({required this.position, required this.currency});

  final CreditPosition position;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final ReceivablesStrings s = ReceivablesStrings.of(context);
    final CreditLimit? limit = position.limit;
    final CreditExposure e = position.exposure;
    String m(Money v) => s.money(v, currency);
    return Card(
      key: const Key('credit-card'),
      child: Padding(
        padding: const EdgeInsets.all(FfSpace.space3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              s.t(RC.creditStatus),
              style: const TextStyle(
                fontSize: FfFont.lg,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: FfSpace.space2),
            if (limit == null)
              Text(s.t(RC.noLimit), key: const Key('credit-no-limit'))
            else ...<Widget>[
              LabeledAmount(
                label: s.t(RC.limit),
                value: m(limit.grantedLimit),
                emphasis: true,
              ),
              if (s.policy(limit.reactionPolicy).isNotEmpty)
                LabeledAmount(
                  label: s.t(RC.policy),
                  value: s.policy(limit.reactionPolicy),
                ),
              const SizedBox(height: FfSpace.space2),
              UtilisationGauge(percent: position.utilizationPercent),
              const SizedBox(height: FfSpace.space2),
              if (position.availableCredit != null)
                LabeledAmount(
                  key: const Key('credit-available'),
                  label: s.t(RC.availableCredit),
                  value: m(position.availableCredit!),
                ),
            ],
            const Divider(),
            LabeledAmount(
              label: s.t(RC.exposureOpenInvoices),
              value: m(e.openInvoices),
            ),
            LabeledAmount(
              label: s.t(RC.exposureUnbilled),
              value: m(e.unbilledDeliveryNotes),
            ),
            LabeledAmount(
              label: s.t(RC.exposureOrders),
              value: m(e.confirmedOrders),
            ),
            LabeledAmount(
              label: s.t(RC.exposureUnreconciled),
              value: m(-e.unreconciledPayments),
            ),
            LabeledAmount(
              key: const Key('credit-total'),
              label: s.t(RC.exposureTotal),
              value: m(e.totalExposure),
              emphasis: true,
            ),
            if (position.insuredCover.isPositive) ...<Widget>[
              LabeledAmount(
                label: s.t(RC.insuredCover),
                value: m(position.insuredCover),
              ),
              LabeledAmount(
                label: s.t(RC.uninsuredExposure),
                value: m(position.uninsuredExposure),
              ),
            ],
            if (e.overdueAmount.isPositive) ...<Widget>[
              LabeledAmount(
                label: s.t(RC.overdueAmount),
                value: m(e.overdueAmount),
              ),
              LabeledAmount(
                label: s.t(RC.maxDaysPastDue),
                value: s.f(RC.daysValue, <String, Object>{
                  'n': e.maxDaysPastDue,
                }),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RiskRow extends StatelessWidget {
  const _RiskRow({required this.risk});

  final RiskScore risk;

  @override
  Widget build(BuildContext context) {
    final ReceivablesStrings s = ReceivablesStrings.of(context);
    final FfColors c = receivablesColors(context);
    final Color color = switch (risk.rating) {
      RiskRating.low => c.success,
      RiskRating.medium => c.warning,
      RiskRating.high || RiskRating.critical => c.danger,
    };
    return Padding(
      padding: const EdgeInsets.only(top: FfSpace.space2),
      child: Row(
        key: const Key('risk-row'),
        children: <Widget>[
          Icon(Icons.shield_outlined, color: color),
          const SizedBox(width: FfSpace.space2),
          Expanded(child: Text(s.t(RC.riskTitle))),
          Text(
            '${s.rating(risk.rating)} · ${s.f(RC.riskScore, <String, Object>{'n': risk.score.round()})}',
            key: const Key('risk-value'),
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _PendingList extends StatelessWidget {
  const _PendingList({
    required this.pending,
    required this.onRetry,
    required this.onDismiss,
  });

  final List<PendingBooking> pending;
  final void Function(String queueUuid) onRetry;
  final void Function(String queueUuid) onDismiss;

  @override
  Widget build(BuildContext context) {
    if (pending.isEmpty) {
      return const SizedBox.shrink();
    }
    final ReceivablesStrings s = ReceivablesStrings.of(context);
    return Column(
      children: <Widget>[
        for (final PendingBooking a in pending)
          ListTile(
            key: Key('pending-${a.queueUuid}'),
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              a.rejected ? Icons.error_outline : Icons.cloud_upload_outlined,
            ),
            title: Text(switch (a.kind) {
              ReceivablesActionKind.allocation => s.t(RC.pendingAllocation),
              ReceivablesActionKind.reversal => s.t(RC.pendingReversal),
              ReceivablesActionKind.dispute => s.t(RC.pendingDispute),
            }),
            subtitle: Text(
              a.rejected
                  ? (a.detail.isEmpty ? s.t(RC.actionRejected) : a.detail)
                  : <String>[
                      s.t(RC.waitingToSend),
                      if (a.amount != null) s.money(a.amount!),
                    ].join(' · '),
            ),
            trailing: a.rejected
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextButton(
                        key: Key('pending-retry-${a.queueUuid}'),
                        onPressed: () => onRetry(a.queueUuid),
                        child: Text(s.t(RC.retry)),
                      ),
                      TextButton(
                        key: Key('pending-dismiss-${a.queueUuid}'),
                        onPressed: () => onDismiss(a.queueUuid),
                        child: Text(s.t(RC.dismiss)),
                      ),
                    ],
                  )
                : null,
          ),
      ],
    );
  }
}

class _ItemCard extends ConsumerWidget {
  const _ItemCard({required this.item, required this.pending});

  final ReceivableItem item;
  final int pending;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ReceivablesStrings s = ReceivablesStrings.of(context);
    return Card(
      key: Key('item-row-${item.id}'),
      margin: const EdgeInsets.symmetric(vertical: FfSpace.space1),
      child: InkWell(
        onTap: () {
          ref.read(customerCreditProvider.notifier).select(item.id);
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              settings: RouteSettings(name: '/receivables/items/${item.id}'),
              builder: (_) => ReceivableItemPage(itemId: item.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(FfSpace.space3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      item.documentNumber,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (pending > 0)
                    Tooltip(
                      message: s.t(RC.waitingToSend),
                      child: Icon(
                        Icons.cloud_upload_outlined,
                        key: Key('item-pending-${item.id}'),
                        size: 18,
                      ),
                    ),
                  const SizedBox(width: FfSpace.space2),
                  ItemStatusChip(status: item.status),
                ],
              ),
              const SizedBox(height: FfSpace.space1),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      <String>[
                        if (item.dueDate != null)
                          s.f(RC.dueOn, <String, Object>{
                            'date': s.date(item.dueDate),
                          }),
                        if (item.daysPastDue > 0)
                          s.f(RC.daysOverdue, <String, Object>{
                            'n': item.daysPastDue,
                          }),
                      ].join(' · '),
                    ),
                  ),
                  Text(
                    s.money(item.openAmount, item.currency),
                    key: Key('item-open-${item.id}'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Item detail and bookings -----------------------------------------------------------------------------------

/// One receivable: amounts, allocations (with reversal), booking and dispute actions. Works offline: actions are queued.
class ReceivableItemPage extends ConsumerWidget {
  const ReceivableItemPage({required this.itemId, super.key});

  final String itemId;

  Future<void> _dispute(
    BuildContext context,
    WidgetRef ref,
    ReceivablesStrings s,
    ReceivableItem item,
  ) async {
    final CustomerCreditController ctrl = ref.read(
      customerCreditProvider.notifier,
    );
    if (item.isDisputed) {
      await ctrl.setDispute(item.id, disputed: false);
      return;
    }
    final TextEditingController reason = TextEditingController();
    String? error;
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => StatefulBuilder(
        builder: (BuildContext ctx, StateSetter setState) => AlertDialog(
          title: Text(s.t(RC.dispute)),
          content: TextField(
            key: const Key('dispute-reason'),
            controller: reason,
            decoration: InputDecoration(
              labelText: s.t(RC.disputeReason),
              errorText: error,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(s.t(RC.cancel)),
            ),
            FilledButton(
              key: const Key('dispute-confirm'),
              onPressed: () {
                if (reason.text.trim().isEmpty) {
                  setState(() => error = s.t(RC.disputeReasonRequired));
                  return;
                }
                Navigator.of(ctx).pop(true);
              },
              child: Text(s.t(RC.dispute)),
            ),
          ],
        ),
      ),
    );
    final String text = reason.text;
    reason.dispose();
    if (ok == true) {
      await ctrl.setDispute(item.id, disputed: true, reason: text);
    }
  }

  Future<void> _reverse(
    BuildContext context,
    WidgetRef ref,
    ReceivablesStrings s,
    ReceivableItem item,
    ReceivableAllocation allocation,
  ) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        content: Text(s.t(RC.reverseConfirm)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(s.t(RC.cancel)),
          ),
          FilledButton(
            key: const Key('reverse-confirm'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(s.t(RC.reverse)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref
          .read(customerCreditProvider.notifier)
          .reverse(item.id, allocation.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ReceivablesStrings s = ReceivablesStrings.of(context);
    final CustomerCreditState st = ref.watch(customerCreditProvider);
    _listenForNotice(context, ref, s);
    final ReceivableItem? item = st.selected?.id == itemId ? st.selected : null;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          item == null ? s.t(RC.itemTitle) : item.documentNumber,
          key: const Key('item-title'),
        ),
      ),
      body: item == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(FfSpace.space3),
              children: <Widget>[
                if (st.busy) const LinearProgressIndicator(),
                Row(
                  children: <Widget>[
                    ItemStatusChip(status: item.status),
                    const SizedBox(width: FfSpace.space2),
                    if (item.dueDate != null)
                      Text(
                        s.f(RC.dueOn, <String, Object>{
                          'date': s.date(item.dueDate),
                        }),
                      ),
                  ],
                ),
                if (item.disputeReason != null)
                  Padding(
                    padding: const EdgeInsets.only(top: FfSpace.space2),
                    child: Text(
                      item.disputeReason!,
                      key: const Key('item-dispute-reason'),
                    ),
                  ),
                const SizedBox(height: FfSpace.space3),
                LabeledAmount(
                  label: s.t(RC.originalAmount),
                  value: s.money(item.originalAmount, item.currency),
                ),
                LabeledAmount(
                  label: s.t(RC.settledAmount),
                  value: s.money(item.settledAmount, item.currency),
                ),
                LabeledAmount(
                  key: const Key('item-detail-open'),
                  label: s.t(RC.openAmount),
                  value: s.money(item.openAmount, item.currency),
                  emphasis: true,
                ),
                const SizedBox(height: FfSpace.space3),
                Wrap(
                  spacing: FfSpace.space2,
                  children: <Widget>[
                    if (item.canAllocate)
                      FilledButton.icon(
                        key: const Key('item-allocate'),
                        icon: const Icon(Icons.payments_outlined),
                        label: Text(s.t(RC.allocate)),
                        onPressed: st.busy
                            ? null
                            : () => showAllocationSheet(context, item),
                      ),
                    if (item.status != ItemStatus.paid &&
                        item.status != ItemStatus.writtenOff)
                      OutlinedButton(
                        key: const Key('item-dispute'),
                        onPressed: st.busy
                            ? null
                            : () => _dispute(context, ref, s, item),
                        child: Text(
                          item.isDisputed
                              ? s.t(RC.liftDispute)
                              : s.t(RC.dispute),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: FfSpace.space4),
                Text(
                  s.t(RC.allocationsTitle),
                  style: const TextStyle(
                    fontSize: FfFont.lg,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (item.allocations.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: FfSpace.space2),
                    child: Text(
                      s.t(RC.noAllocations),
                      key: const Key('allocations-empty'),
                    ),
                  ),
                for (final ReceivableAllocation a in item.allocations)
                  ListTile(
                    key: Key('allocation-${a.id}'),
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '${s.allocationType(a.type)} · ${s.money(a.amount, item.currency)}',
                    ),
                    subtitle: Text(
                      <String>[
                        s.date(a.valueDate),
                        if (a.sourceReference.isNotEmpty) a.sourceReference,
                        if (a.isReversed) s.t(RC.allocationReversed),
                        if (st.reversalPending(a.id)) s.t(RC.waitingToSend),
                      ].where((String t) => t.isNotEmpty).join(' · '),
                    ),
                    trailing: a.isReversed || st.reversalPending(a.id)
                        ? null
                        : TextButton(
                            key: Key('reverse-${a.id}'),
                            onPressed: st.busy
                                ? null
                                : () => _reverse(context, ref, s, item, a),
                            child: Text(s.t(RC.reverse)),
                          ),
                  ),
                _PendingList(
                  pending: st.pending
                      .where((PendingBooking a) => a.itemId == item.id)
                      .toList(),
                  onRetry: ref.read(customerCreditProvider.notifier).retry,
                  onDismiss: ref.read(customerCreditProvider.notifier).dismiss,
                ),
              ],
            ),
    );
  }
}

/// Opens the booking form (payment, credit note, write-off or discount) for [item].
Future<void> showAllocationSheet(BuildContext context, ReceivableItem item) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => AllocationSheet(item: item),
  );
}

/// Booking form. The amount starts at the open amount; checks run before anything is queued.
class AllocationSheet extends ConsumerStatefulWidget {
  const AllocationSheet({required this.item, super.key});

  final ReceivableItem item;

  @override
  ConsumerState<AllocationSheet> createState() => _AllocationSheetState();
}

class _AllocationSheetState extends ConsumerState<AllocationSheet> {
  late final TextEditingController _amount = TextEditingController(
    text: widget.item.openAmount.toWire(),
  );
  final TextEditingController _reference = TextEditingController();
  final TextEditingController _notes = TextEditingController();
  final TextEditingController _creditNote = TextEditingController();
  AllocationType _type = AllocationType.payment;
  UnreconciledPayment? _payment;
  List<DraftIssue> _issues = const <DraftIssue>[];

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    _notes.dispose();
    _creditNote.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final Money amount = Money.tryParseInput(_amount.text) ?? Money.zero;
    final List<DraftIssue> issues = await ref
        .read(customerCreditProvider.notifier)
        .allocate(
          widget.item,
          type: _type,
          amount: amount,
          payment: _type == AllocationType.payment ? _payment : null,
          sourceId: _type == AllocationType.creditNote
              ? _creditNote.text.trim()
              : null,
          reference: _reference.text,
          notes: _notes.text,
        );
    if (!mounted) {
      return;
    }
    if (issues.isEmpty) {
      Navigator.of(context).pop();
    } else {
      setState(() => _issues = issues);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ReceivablesStrings s = ReceivablesStrings.of(context);
    final List<UnreconciledPayment> payments = ref
        .watch(customerCreditProvider)
        .unreconciled
        .where(
          (UnreconciledPayment p) =>
              p.unallocated.isPositive &&
              (p.currency.isEmpty || p.currency == widget.item.currency),
        )
        .toList();
    return Padding(
      padding: EdgeInsets.only(
        left: FfSpace.space4,
        right: FfSpace.space4,
        top: FfSpace.space4,
        bottom: MediaQuery.of(context).viewInsets.bottom + FfSpace.space4,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              s.t(RC.allocateTitle),
              style: const TextStyle(
                fontSize: FfFont.lg,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: FfSpace.space3),
            Wrap(
              spacing: FfSpace.space2,
              children: <Widget>[
                for (final AllocationType t in AllocationType.bookable)
                  ChoiceChip(
                    key: Key('allocation-type-${t.wire}'),
                    label: Text(s.allocationType(t)),
                    selected: _type == t,
                    onSelected: (_) => setState(() {
                      _type = t;
                      _issues = const <DraftIssue>[];
                    }),
                  ),
              ],
            ),
            const SizedBox(height: FfSpace.space3),
            TextField(
              key: const Key('allocation-amount'),
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText:
                    '${s.t(RC.amount)} (${s.money(widget.item.openAmount, widget.item.currency)})',
                errorText: _issues.isEmpty
                    ? null
                    : _issues.map(s.draftIssue).join('\n'),
              ),
            ),
            if (_type == AllocationType.payment &&
                payments.isNotEmpty) ...<Widget>[
              const SizedBox(height: FfSpace.space3),
              Text(s.t(RC.paymentSource)),
              Wrap(
                spacing: FfSpace.space2,
                children: <Widget>[
                  ChoiceChip(
                    key: const Key('allocation-source-none'),
                    label: Text(s.t(RC.noPaymentSource)),
                    selected: _payment == null,
                    onSelected: (_) => setState(() => _payment = null),
                  ),
                  for (final UnreconciledPayment p in payments)
                    ChoiceChip(
                      key: Key('allocation-source-${p.ledgerEntryId}'),
                      label: Text(
                        '${p.reference} · ${s.f(RC.unallocatedLeft, <String, Object>{'amount': s.money(p.unallocated, p.currency)})}',
                      ),
                      selected: _payment?.ledgerEntryId == p.ledgerEntryId,
                      onSelected: (_) => setState(() => _payment = p),
                    ),
                ],
              ),
            ],
            if (_type == AllocationType.creditNote)
              TextField(
                key: const Key('allocation-credit-note'),
                controller: _creditNote,
                decoration: InputDecoration(labelText: s.t(RC.creditNoteId)),
              ),
            TextField(
              key: const Key('allocation-reference'),
              controller: _reference,
              decoration: InputDecoration(labelText: s.t(RC.reference)),
            ),
            TextField(
              key: const Key('allocation-notes'),
              controller: _notes,
              decoration: InputDecoration(labelText: s.t(RC.notes)),
            ),
            const SizedBox(height: FfSpace.space3),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(s.t(RC.cancel)),
                ),
                const SizedBox(width: FfSpace.space2),
                FilledButton(
                  key: const Key('allocation-submit'),
                  onPressed: _submit,
                  child: Text(s.t(RC.book)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
