import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/providers.dart';
import '../../../design/ff_tokens.dart';
import '../domain/rebate_decimal.dart';
import '../domain/supplier_rebate_models.dart';
import 'supplier_rebates_controller.dart';
import 'supplier_rebates_format.dart';
import 'supplier_rebates_strings.dart';
import 'supplier_rebates_widgets.dart';

SupplierRebatesStrings _strings(WidgetRef ref) =>
    SupplierRebatesStrings(ref.watch(requestContextProvider).languageCode);

String _lang(WidgetRef ref) => ref.watch(requestContextProvider).languageCode;

Widget _offlineBanner(SupplierRebatesStrings s) => MaterialBanner(
  key: const Key('rebates-offline'),
  content: Text(s(RB.offlineCopy)),
  actions: const <Widget>[SizedBox.shrink()],
);

/// Workspace of the supplier rebates: agreements with their live tier progress, settlement proposals to approve and the
/// blanket agreement balances, all readable offline.
class SupplierRebatesHomePage extends ConsumerStatefulWidget {
  const SupplierRebatesHomePage({super.key});

  @override
  ConsumerState<SupplierRebatesHomePage> createState() =>
      _SupplierRebatesHomePageState();
}

class _SupplierRebatesHomePageState
    extends ConsumerState<SupplierRebatesHomePage> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(supplierRebatesHubProvider.notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final SupplierRebatesStrings s = _strings(ref);
    final String lang = _lang(ref);
    final SupplierRebatesHubState state = ref.watch(supplierRebatesHubProvider);
    final SupplierRebatesHubController ctrl = ref.read(
      supplierRebatesHubProvider.notifier,
    );
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(s(RB.title)),
          actions: <Widget>[
            IconButton(
              key: const Key('rebates-refresh'),
              tooltip: s(RB.refresh),
              icon: const Icon(Icons.refresh),
              onPressed: ctrl.load,
            ),
          ],
          bottom: TabBar(
            tabs: <Widget>[
              Tab(key: const Key('rebates-tab-agreements'), text: s(RB.tabAgreements)),
              Tab(key: const Key('rebates-tab-proposals'), text: s(RB.tabProposals)),
              Tab(key: const Key('rebates-tab-blankets'), text: s(RB.tabBlankets)),
            ],
          ),
        ),
        body: Column(
          children: <Widget>[
            if (state.loading) const LinearProgressIndicator(),
            if (state.fromCache || state.error?.kind == RebateErrorKind.offline)
              _offlineBanner(s),
            if (state.error != null &&
                state.error!.kind != RebateErrorKind.offline)
              Padding(
                padding: const EdgeInsets.all(FfSpace.space3),
                child: Text(
                  state.forbidden ? s.error(state.error!) : s(RB.loadError),
                  key: const Key('rebates-error'),
                ),
              ),
            Expanded(
              child: TabBarView(
                children: <Widget>[
                  _AgreementList(state: state, lang: lang, s: s, onRefresh: ctrl.load),
                  _ProposalList(state: state, lang: lang, s: s, onRefresh: ctrl.load),
                  _ContractList(state: state, lang: lang, s: s, onRefresh: ctrl.load),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgreementList extends StatelessWidget {
  const _AgreementList({
    required this.state,
    required this.lang,
    required this.s,
    required this.onRefresh,
  });

  final SupplierRebatesHubState state;
  final String lang;
  final SupplierRebatesStrings s;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (state.agreements.isEmpty) {
      return _Empty(text: s(RB.empty), keyName: 'rebates-empty');
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(FfSpace.space3),
        children: <Widget>[
          for (final RebateAgreement a in state.agreements)
            Card(
              key: Key('agreement-card-${a.id}'),
              child: ListTile(
                title: Text('${a.code} · ${a.name}'),
                subtitle: Text(
                  <String>[
                    ?a.contactName,
                    s.rebateType(a.rebateType),
                    RebateFormat.range(a.startsOn, a.endsOn, lang),
                    if (a.openRebate != null && a.openRebate!.isPositive)
                      '${s(RB.openRebate)}: ${RebateFormat.money(a.openRebate!, a.currency, lang)}',
                  ].join('\n'),
                ),
                isThreeLine: true,
                trailing: RebateChip(
                  label: s.agreementStatus(a.status),
                  kind: agreementStatusKind(a.status),
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => AgreementDetailPage(agreementId: a.id),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProposalList extends StatelessWidget {
  const _ProposalList({
    required this.state,
    required this.lang,
    required this.s,
    required this.onRefresh,
  });

  final SupplierRebatesHubState state;
  final String lang;
  final SupplierRebatesStrings s;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (state.proposals.isEmpty) {
      return _Empty(text: s(RB.noProposals), keyName: 'proposals-empty');
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(FfSpace.space3),
        children: <Widget>[
          for (final SettlementProposal p in state.proposals)
            Card(
              key: Key('proposal-card-${p.id}'),
              child: ListTile(
                title: Text(
                  p.agreementCode == null
                      ? RebateFormat.money(p.amount, p.currency, lang)
                      : '${p.agreementCode} · ${RebateFormat.money(p.amount, p.currency, lang)}',
                ),
                subtitle: Text(
                  <String>[
                    ?p.agreementName,
                    s.executionMode(p.executionMode),
                    if (state.pendingFor(p.id) > 0) s(RB.waitingToSend),
                  ].join('\n'),
                ),
                isThreeLine: true,
                trailing: RebateChip(
                  label: s.proposalStatus(p.status),
                  kind: proposalStatusKind(p.status),
                ),
                // The status may have changed on the detail page: reload the lists when coming back.
                onTap: () => Navigator.of(context)
                    .push(
                      MaterialPageRoute<void>(
                        builder: (_) => ProposalDetailPage(proposalId: p.id),
                      ),
                    )
                    .then((_) => onRefresh()),
              ),
            ),
        ],
      ),
    );
  }
}

class _ContractList extends StatelessWidget {
  const _ContractList({
    required this.state,
    required this.lang,
    required this.s,
    required this.onRefresh,
  });

  final SupplierRebatesHubState state;
  final String lang;
  final SupplierRebatesStrings s;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (state.contracts.isEmpty) {
      return _Empty(text: s(RB.noContracts), keyName: 'contracts-empty');
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(FfSpace.space3),
        children: <Widget>[
          for (final BlanketContract c in state.contracts)
            Card(
              key: Key('contract-card-${c.id}'),
              child: ListTile(
                title: Text('${c.contractNumber} · ${c.title}'),
                subtitle: Text(
                  <String>[
                    if (c.ceiling.isPositive)
                      '${s(RB.ceiling)}: ${RebateFormat.money(c.ceiling, c.currency, lang)}',
                    if (c.minimumSpend != null)
                      '${s(RB.minimumSpend)}: ${RebateFormat.money(c.minimumSpend!, c.currency, lang)}',
                    RebateFormat.range(c.startsAt, c.endsAt, lang),
                  ].join('\n'),
                ),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => BlanketBalancePage(contractId: c.id),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.text, required this.keyName});

  final String text;
  final String keyName;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(FfSpace.space5),
      child: Text(text, key: Key(keyName)),
    ),
  );
}

/// One agreement: tier ladder with live progress, fixed bonus progress, contributions, accrual runs and its proposals.
class AgreementDetailPage extends ConsumerStatefulWidget {
  const AgreementDetailPage({required this.agreementId, super.key});

  final String agreementId;

  @override
  ConsumerState<AgreementDetailPage> createState() =>
      _AgreementDetailPageState();
}

class _AgreementDetailPageState extends ConsumerState<AgreementDetailPage> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref
          .read(agreementDetailProvider.notifier)
          .load(widget.agreementId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final SupplierRebatesStrings s = _strings(ref);
    final String lang = _lang(ref);
    final AgreementDetailState st = ref.watch(agreementDetailProvider);
    final RebateAgreement? a = st.agreement;
    final TierProgress? tier = st.tierProgress;
    final BonusProgress? bonus = st.bonusProgress;
    return Scaffold(
      appBar: AppBar(
        title: Text(a == null ? s(RB.title) : a.code, key: const Key('agreement-title')),
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(agreementDetailProvider.notifier).load(widget.agreementId),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(FfSpace.space3),
          children: <Widget>[
            if (st.loading) const LinearProgressIndicator(),
            if (st.error != null && st.error!.kind == RebateErrorKind.offline)
              _offlineBanner(s)
            else if (st.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: FfSpace.space2),
                child: Text(s.error(st.error!)),
              ),
            if (a != null) ...<Widget>[
              RebateSection(
                title: a.name,
                trailing: RebateChip(
                  label: s.agreementStatus(a.status),
                  kind: agreementStatusKind(a.status),
                ),
                child: Column(
                  children: <Widget>[
                    if (a.contactName != null)
                      RebateInfoRow(label: s(RB.supplier), value: a.contactName!),
                    RebateInfoRow(
                      label: s(RB.rebateType),
                      value: s.rebateType(a.rebateType),
                    ),
                    if (a.isTiered)
                      RebateInfoRow(
                        label: s(RB.tierMode),
                        value: s.tierMode(a.tierMode),
                      ),
                    RebateInfoRow(
                      label: s(RB.validFrom),
                      value: RebateFormat.range(a.startsOn, a.endsOn, lang),
                    ),
                    if (s.frequencyName(a.accrualFrequency).isNotEmpty)
                      RebateInfoRow(
                        label: s(RB.frequency),
                        value: s.frequencyName(a.accrualFrequency),
                      ),
                    if (st.progress != null)
                      RebateInfoRow(
                        label: s(RB.earnedRebate),
                        value: RebateFormat.money(
                          st.progress!.earnedRebate,
                          a.currency,
                          lang,
                        ),
                      ),
                    if (st.progress != null)
                      RebateInfoRow(
                        label: s(RB.settledRebate),
                        value: RebateFormat.money(
                          st.progress!.settledRebate,
                          a.currency,
                          lang,
                        ),
                      ),
                  ],
                ),
              ),
              if (tier != null)
                TierProgressCard(
                  progress: tier,
                  volume: st.volume,
                  currency: a.currency,
                  languageCode: lang,
                  recomputedOffline: !st.synced && st.progress != null,
                ),
              if (a.isTiered && a.tiers.isNotEmpty)
                TierLadder(
                  tiers: a.tiers,
                  volume: st.volume,
                  currency: a.currency,
                  languageCode: lang,
                ),
              if (bonus != null)
                BonusProgressCard(
                  bonus: bonus,
                  volume: st.volume,
                  currency: a.currency,
                  languageCode: lang,
                ),
              if (a.contributions.isNotEmpty)
                RebateSection(
                  title: s(RB.contributions),
                  child: Column(
                    children: <Widget>[
                      for (final RebateContribution c in a.contributions)
                        ListTile(
                          key: Key('contribution-${c.id}'),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            c.description ?? s.contributionKind(c.kind),
                          ),
                          subtitle: Text(
                            <String>[
                              s.contributionKind(c.kind),
                              s.contributionStatus(c.status),
                              if (c.dueOn != null)
                                '${s(RB.dueOn)} ${RebateFormat.date(c.dueOn, lang)}',
                            ].join(' · '),
                          ),
                          trailing: Text(
                            RebateFormat.money(c.amount, a.currency, lang),
                          ),
                        ),
                    ],
                  ),
                ),
              RebateSection(
                title: s(RB.accrualRuns),
                child: st.runs.isEmpty
                    ? Text(s(RB.noRuns), key: const Key('runs-empty'))
                    : Column(
                        children: <Widget>[
                          for (final AccrualRun r in st.runs)
                            _RunTile(run: r, currency: a.currency, lang: lang, s: s),
                        ],
                      ),
              ),
              RebateSection(
                title: s(RB.proposals),
                child: st.proposals.isEmpty
                    ? Text(s(RB.noProposals))
                    : Column(
                        children: <Widget>[
                          for (final SettlementProposal p in st.proposals)
                            ListTile(
                              key: Key('agreement-proposal-${p.id}'),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                RebateFormat.money(p.amount, p.currency, lang),
                              ),
                              subtitle: Text(s.executionMode(p.executionMode)),
                              trailing: RebateChip(
                                label: s.proposalStatus(p.status),
                                kind: proposalStatusKind(p.status),
                              ),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      ProposalDetailPage(proposalId: p.id),
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
              if (a.supplierContractId != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    key: const Key('agreement-open-balance'),
                    icon: const Icon(Icons.account_balance_wallet_outlined),
                    label: Text(s(RB.blanketBalance)),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => BlanketBalancePage(
                          contractId: a.supplierContractId!,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RunTile extends StatelessWidget {
  const _RunTile({
    required this.run,
    required this.currency,
    required this.lang,
    required this.s,
  });

  final AccrualRun run;
  final String currency;
  final String lang;
  final SupplierRebatesStrings s;

  @override
  Widget build(BuildContext context) {
    String money(Dec v) => RebateFormat.money(v, currency, lang);
    return ExpansionTile(
      key: Key('run-${run.id}'),
      tilePadding: EdgeInsets.zero,
      title: Text(RebateFormat.range(run.periodStart, run.periodEnd, lang)),
      subtitle: Text(
        '${s(RB.delta)}: ${money(run.deltaAmount)} · ${s.runStatus(run.status)}',
      ),
      children: <Widget>[
        RebateInfoRow(label: s(RB.baseAmount), value: money(run.baseAmount)),
        RebateInfoRow(
          label: s(RB.cumulative),
          value: money(run.cumulativeRebate),
        ),
        if (run.journalEntryId == null)
          Align(
            alignment: Alignment.centerLeft,
            child: Text(s(RB.notPosted)),
          ),
        if (run.lines.isNotEmpty) ...<Widget>[
          const SizedBox(height: FfSpace.space2),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              s(RB.contributingInvoices),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          for (final RunLine l in run.lines)
            RebateInfoRow(
              label:
                  '${l.invoiceNumber} · ${RebateFormat.date(l.invoiceDate, lang)}',
              value: money(l.netAmount),
            ),
        ],
      ],
    );
  }
}

/// One settlement proposal: figures, analytical breakdown and the workflow buttons.
class ProposalDetailPage extends ConsumerStatefulWidget {
  const ProposalDetailPage({required this.proposalId, super.key});

  final String proposalId;

  @override
  ConsumerState<ProposalDetailPage> createState() => _ProposalDetailPageState();
}

class _ProposalDetailPageState extends ConsumerState<ProposalDetailPage> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () =>
          ref.read(proposalDetailProvider.notifier).load(widget.proposalId),
    );
  }

  Future<void> _confirm(SupplierRebatesStrings s, ProposalAction action) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        content: Text(s.confirm(action)),
        actions: <Widget>[
          TextButton(
            key: const Key('rebate-dialog-dismiss'),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(s(RB.cancel)),
          ),
          FilledButton(
            key: const Key('rebate-confirm'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(s.action(action)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(proposalDetailProvider.notifier).act(action);
    }
  }

  String? _noticeText(SupplierRebatesStrings s, ProposalDetailState st) =>
      switch (st.notice) {
        RebateNotice.sent => s(RB.actionSent),
        RebateNotice.queued => s(RB.actionQueued),
        RebateNotice.rejected =>
          st.noticeDetail.isEmpty ? s(RB.errorInvalid) : st.noticeDetail,
        null => null,
      };

  @override
  Widget build(BuildContext context) {
    final SupplierRebatesStrings s = _strings(ref);
    final String lang = _lang(ref);
    final ProposalDetailState st = ref.watch(proposalDetailProvider);
    ref.listen<ProposalDetailState>(proposalDetailProvider, (
      ProposalDetailState? prev,
      ProposalDetailState next,
    ) {
      final String? text = _noticeText(s, next);
      if (text != null && next.notice != prev?.notice) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(text)));
        ref.read(proposalDetailProvider.notifier).clearNotice();
      }
    });
    final SettlementProposal? p = st.proposal;
    String money(Dec v) => RebateFormat.money(v, p?.currency ?? 'CHF', lang);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          p?.agreementCode ?? s(RB.proposals),
          key: const Key('proposal-title'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(FfSpace.space3),
        children: <Widget>[
          if (st.loading) const LinearProgressIndicator(),
          if (st.error != null && st.error!.kind == RebateErrorKind.offline)
            _offlineBanner(s)
          else if (st.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: FfSpace.space2),
              child: Text(s.error(st.error!)),
            ),
          if (p != null) ...<Widget>[
            RebateSection(
              title: p.agreementName ?? s(RB.proposals),
              trailing: RebateChip(
                label: s.proposalStatus(p.status),
                kind: proposalStatusKind(p.status),
              ),
              child: Column(
                children: <Widget>[
                  RebateInfoRow(
                    label: s(RB.executionMode),
                    value: s.executionMode(p.executionMode),
                  ),
                  RebateInfoRow(
                    label: s(RB.net),
                    value: money(p.amount),
                    valueKey: const Key('proposal-net'),
                    strong: true,
                  ),
                  RebateInfoRow(
                    label: '${s(RB.tax)} ${RebateFormat.percent(p.taxRate, lang)}',
                    value: money(p.taxAmount),
                  ),
                  RebateInfoRow(
                    label: s(RB.gross),
                    value: money(p.grossAmount),
                    valueKey: const Key('proposal-gross'),
                    strong: true,
                  ),
                ],
              ),
            ),
            RebateSection(
              title: s(RB.breakdown),
              child: Column(
                children: <Widget>[
                  for (final (int i, ProposalLine l) in p.lines.indexed)
                    ListTile(
                      key: Key('proposal-line-$i'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        <String>[
                          s.lineType(l.type),
                          if (l.reference.isNotEmpty) l.reference,
                        ].join(' · '),
                      ),
                      subtitle: Text(
                        <String>[
                          if (l.referenceDate != null)
                            RebateFormat.date(l.referenceDate, lang),
                          money(l.netAmount),
                        ].join(' · '),
                      ),
                      trailing: Text(
                        money(l.rebateAmount),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            ),
            for (final PendingAction a in st.pending)
              ListTile(
                key: Key('pending-${a.queueUuid}'),
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  a.rejected ? Icons.error_outline : Icons.cloud_upload_outlined,
                ),
                title: Text(s.action(a.action)),
                subtitle: Text(
                  a.rejected
                      ? (a.detail.isEmpty ? s(RB.actionRejected) : a.detail)
                      : s(RB.waitingToSend),
                ),
                trailing: a.rejected
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          TextButton(
                            key: Key('pending-retry-${a.queueUuid}'),
                            onPressed: () => ref
                                .read(proposalDetailProvider.notifier)
                                .retry(a.queueUuid),
                            child: Text(s(RB.retry)),
                          ),
                          TextButton(
                            key: Key('pending-dismiss-${a.queueUuid}'),
                            onPressed: () => ref
                                .read(proposalDetailProvider.notifier)
                                .dismiss(a.queueUuid),
                            child: Text(s(RB.dismiss)),
                          ),
                        ],
                      )
                    : null,
              ),
            const SizedBox(height: FfSpace.space2),
            ProposalActionButtons(
              status: p.status,
              languageCode: lang,
              busy: st.busy,
              pending: <ProposalAction>{
                for (final PendingAction a in st.pending)
                  if (!a.rejected) a.action,
              },
              onAction: (ProposalAction action) => _confirm(s, action),
            ),
          ],
        ],
      ),
    );
  }
}

/// Ceiling, minimum spend and call-off position of one blanket agreement, with its alerts.
class BlanketBalancePage extends ConsumerStatefulWidget {
  const BlanketBalancePage({required this.contractId, super.key});

  final String contractId;

  @override
  ConsumerState<BlanketBalancePage> createState() => _BlanketBalancePageState();
}

class _BlanketBalancePageState extends ConsumerState<BlanketBalancePage> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(blanketBalanceProvider.notifier).load(widget.contractId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final SupplierRebatesStrings s = _strings(ref);
    final String lang = _lang(ref);
    final BlanketBalanceState st = ref.watch(blanketBalanceProvider);
    final BlanketBalance? b = st.balance;
    final BlanketContract? c = st.contract;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          c == null ? s(RB.blanketBalance) : '${c.contractNumber} · ${c.title}',
          key: const Key('balance-title'),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(blanketBalanceProvider.notifier).load(widget.contractId),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(FfSpace.space3),
          children: <Widget>[
            if (st.loading) const LinearProgressIndicator(),
            if (st.error != null && st.error!.kind == RebateErrorKind.offline)
              _offlineBanner(s)
            else if (st.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: FfSpace.space2),
                child: Text(s.error(st.error!)),
              ),
            if (b != null) ...<Widget>[
              BalanceMeters(balance: b, languageCode: lang),
              if (b.lines.isNotEmpty)
                RebateSection(
                  title: s(RB.committedQty),
                  child: Column(
                    children: <Widget>[
                      for (final (int i, BlanketLine l) in b.lines.indexed)
                        ListTile(
                          key: Key('balance-line-$i'),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(l.description),
                          subtitle: Text(
                            <String>[
                              if (l.committedQuantity != null)
                                '${s(RB.committedQty)} ${RebateFormat.quantity(l.committedQuantity!, lang)}',
                              '${s(RB.releasedQty)} ${RebateFormat.quantity(l.releasedQuantity, lang)}',
                              if (l.remainingQuantity != null)
                                '${s(RB.remainingQty)} ${RebateFormat.quantity(l.remainingQuantity!, lang)}',
                            ].join('\n'),
                          ),
                          isThreeLine: true,
                          trailing: Text(
                            RebateFormat.money(l.orderedAmount, b.currency, lang),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
