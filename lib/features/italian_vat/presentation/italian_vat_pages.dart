import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/providers.dart';
import '../../../design/ff_tokens.dart';
import '../../general_ledger/domain/gl_amount.dart';
import '../domain/italian_vat_models.dart';
import 'italian_vat_controller.dart';
import 'italian_vat_strings.dart';
import 'italian_vat_widgets.dart';

ItalianVatStrings _strings(WidgetRef ref) =>
    ItalianVatStrings(ref.watch(requestContextProvider).languageCode);

String _lang(WidgetRef ref) => ref.watch(requestContextProvider).languageCode;

void _toast(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}

/// Italian VAT workspace (Mod 029): VAT registers, plafond of the letters of intent, periodic settlements with the
/// LIPE file, and the annual reconciliation with the Certificazioni Uniche. Everything is readable offline.
class ItalianVatHomePage extends ConsumerStatefulWidget {
  const ItalianVatHomePage({super.key});

  @override
  ConsumerState<ItalianVatHomePage> createState() => _ItalianVatHomePageState();
}

class _ItalianVatHomePageState extends ConsumerState<ItalianVatHomePage> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() => ref.read(italianVatProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final ItalianVatStrings s = _strings(ref);
    final ItalianVatState state = ref.watch(italianVatProvider);
    final ItalianVatController ctrl = ref.read(italianVatProvider.notifier);
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(s(IV.title)),
          actions: <Widget>[
            IconButton(
              key: const Key('ivat-refresh'),
              tooltip: s(IV.refresh),
              icon: const Icon(Icons.refresh),
              onPressed: ctrl.load,
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabs: <Widget>[
              Tab(
                key: const Key('ivat-tab-registers'),
                text: s(IV.tabRegisters),
              ),
              Tab(key: const Key('ivat-tab-plafond'), text: s(IV.tabPlafond)),
              Tab(key: const Key('ivat-tab-lipe'), text: s(IV.tabLipe)),
              Tab(key: const Key('ivat-tab-annual'), text: s(IV.tabAnnual)),
            ],
          ),
        ),
        body: Column(
          children: <Widget>[
            if (state.loading) const LinearProgressIndicator(),
            if (state.fromCache) vatOfflineBanner(s),
            if (state.error != null &&
                state.error!.kind != ItalianVatErrorKind.offline)
              Padding(
                padding: const EdgeInsets.all(FfSpace.space3),
                child: Text(
                  state.forbidden ? s.error(state.error!) : s(IV.loadError),
                  key: const Key('ivat-error'),
                ),
              ),
            if (state.pending.isNotEmpty)
              _PendingList(state: state, s: s, ctrl: ctrl),
            const Expanded(
              child: TabBarView(
                children: <Widget>[
                  _RegistersTab(),
                  _PlafondTab(),
                  _LipeTab(),
                  _AnnualTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Writes waiting in the outbox, with retry / dismiss for the refused ones.
class _PendingList extends StatelessWidget {
  const _PendingList({
    required this.state,
    required this.s,
    required this.ctrl,
  });

  final ItalianVatState state;
  final ItalianVatStrings s;
  final ItalianVatController ctrl;

  @override
  Widget build(BuildContext context) {
    return VatCard(
      title: s(IV.pendingActions),
      children: <Widget>[
        for (final PendingVatAction a in state.pending)
          Row(
            key: Key('ivat-pending-${a.queueUuid}'),
            children: <Widget>[
              Expanded(
                child: Text(
                  '${s.action(a.kind)}${a.targetId.isEmpty ? '' : ' · ${a.targetId}'}'
                  ' — ${a.rejected ? (a.detail.isEmpty ? s(IV.actionRejected) : a.detail) : s(IV.actionWaiting)}',
                ),
              ),
              if (a.rejected) ...<Widget>[
                TextButton(
                  key: Key('ivat-retry-${a.queueUuid}'),
                  onPressed: () => ctrl.retry(a.queueUuid),
                  child: Text(s(IV.retry)),
                ),
                TextButton(
                  key: Key('ivat-dismiss-${a.queueUuid}'),
                  onPressed: () => ctrl.dismiss(a.queueUuid),
                  child: Text(s(IV.dismiss)),
                ),
              ],
            ],
          ),
      ],
    );
  }
}

// --- Registers -----------------------------------------------------------------------------------------------------

class _RegistersTab extends ConsumerWidget {
  const _RegistersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ItalianVatStrings s = _strings(ref);
    final String lang = _lang(ref);
    final ItalianVatState state = ref.watch(italianVatProvider);
    final ItalianVatController ctrl = ref.read(italianVatProvider.notifier);
    final VatRegister? reg = state.register;
    final List<VatRegisterLine> lines =
        reg?.linesOf(state.sectional) ?? const <VatRegisterLine>[];
    final String currency = reg?.currency ?? 'EUR';
    return RefreshIndicator(
      onRefresh: ctrl.reloadRegister,
      child: ListView(
        key: const Key('ivat-registers-list'),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(FfSpace.space3),
            child: Wrap(
              spacing: FfSpace.space2,
              children: <Widget>[
                for (final VatRegisterType t in VatRegisterType.values)
                  ChoiceChip(
                    key: Key('ivat-reg-${t.wire}'),
                    label: Text(s.register(t)),
                    selected: state.registerType == t,
                    onSelected: (_) => ctrl.selectRegister(t),
                  ),
              ],
            ),
          ),
          _PeriodPicker(state: state, s: s, ctrl: ctrl),
          if (reg != null) ...<Widget>[
            _LockCard(reg: reg, s: s, lang: lang),
            if (reg.sectionalCodes.isNotEmpty)
              _SectionalPicker(reg: reg, state: state, s: s, ctrl: ctrl),
            if (reg.hasProRata) _ProRataCard(reg: reg, s: s, lang: lang),
            if (reg.type == VatRegisterType.receipts && reg.ventilationEnabled)
              _VentilationCard(reg: reg, s: s, lang: lang),
            _TotalsCard(reg: reg, lines: lines, s: s, lang: lang),
          ],
          if (reg == null || lines.isEmpty)
            Padding(
              padding: const EdgeInsets.all(FfSpace.space4),
              child: Text(s(IV.noLines), key: const Key('ivat-no-lines')),
            )
          else
            for (final VatRegisterLine l in lines)
              _LineTile(
                line: l,
                reg: reg,
                s: s,
                lang: lang,
                currency: currency,
              ),
          Padding(
            padding: const EdgeInsets.all(FfSpace.space3),
            child: OutlinedButton.icon(
              key: const Key('ivat-export-csv'),
              icon: const Icon(Icons.ios_share),
              label: Text(s(IV.exportCsv)),
              onPressed: () async {
                final ExportResult r = await ctrl.exportRegisterCsv();
                if (context.mounted) {
                  _toast(
                    context,
                    r.failed
                        ? (r.error == null
                              ? s(IV.shareFailed)
                              : s.error(r.error!))
                        : s(IV.shared),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodPicker extends StatelessWidget {
  const _PeriodPicker({
    required this.state,
    required this.s,
    required this.ctrl,
  });

  final ItalianVatState state;
  final ItalianVatStrings s;
  final ItalianVatController ctrl;

  String _kind(RegisterPeriodKind k) => switch (k) {
    RegisterPeriodKind.month => s(IV.periodMonth),
    RegisterPeriodKind.quarter => s(IV.periodQuarter),
    RegisterPeriodKind.year => s(IV.periodYear),
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FfSpace.space3),
      child: Wrap(
        spacing: FfSpace.space2,
        runSpacing: FfSpace.space2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          for (final RegisterPeriodKind k in RegisterPeriodKind.values)
            ChoiceChip(
              key: Key('ivat-period-${k.name}'),
              label: Text(_kind(k)),
              selected: state.periodKind == k,
              onSelected: (_) => ctrl.selectPeriod(
                k,
                VatPeriods.currentIndex(k, DateTime.now()),
              ),
            ),
          if (state.periodKind != RegisterPeriodKind.year)
            DropdownButton<int>(
              key: const Key('ivat-period-index'),
              value: state.periodIndex,
              items: <DropdownMenuItem<int>>[
                for (int i = 1; i <= VatPeriods.count(state.periodKind); i++)
                  DropdownMenuItem<int>(
                    value: i,
                    child: Text(
                      state.periodKind == RegisterPeriodKind.quarter
                          ? 'Q$i'
                          : i.toString().padLeft(2, '0'),
                    ),
                  ),
              ],
              onChanged: (int? i) {
                if (i != null) {
                  ctrl.selectPeriod(state.periodKind, i);
                }
              },
            ),
          IconButton(
            key: const Key('ivat-year-prev'),
            tooltip: s(IV.year),
            icon: const Icon(Icons.chevron_left),
            onPressed: () => ctrl.selectYear(state.year - 1),
          ),
          Text('${state.year}', key: const Key('ivat-year')),
          IconButton(
            key: const Key('ivat-year-next'),
            tooltip: s(IV.year),
            icon: const Icon(Icons.chevron_right),
            onPressed: () => ctrl.selectYear(state.year + 1),
          ),
        ],
      ),
    );
  }
}

class _LockCard extends StatelessWidget {
  const _LockCard({required this.reg, required this.s, required this.lang});

  final VatRegister reg;
  final ItalianVatStrings s;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final bool locked = reg.lock.definitive;
    final int? last = reg.lastProtocol;
    return VatCard(
      title: s.register(reg.type),
      trailing: VatChip(
        locked ? s(IV.definitive) : s(IV.provisional),
        locked ? VatTone.good : VatTone.warn,
        key: const Key('ivat-lock-chip'),
      ),
      children: <Widget>[
        if (locked && reg.lock.lockedAt != null)
          VatRow(s(IV.lockedOn), VatFormat.date(reg.lock.lockedAt, lang)),
        if (last != null) VatRow(s(IV.lastProtocol), '$last'),
        if (reg.lock.stampDutyPages != null)
          VatRow(s(IV.stampDutyPages), '${reg.lock.stampDutyPages}'),
        if (!locked && reg.unnumbered > 0)
          VatRow(
            s(IV.unnumbered),
            '${reg.unnumbered}',
            valueKey: const Key('ivat-unnumbered'),
          ),
      ],
    );
  }
}

class _SectionalPicker extends StatelessWidget {
  const _SectionalPicker({
    required this.reg,
    required this.state,
    required this.s,
    required this.ctrl,
  });

  final VatRegister reg;
  final ItalianVatState state;
  final ItalianVatStrings s;
  final ItalianVatController ctrl;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FfSpace.space3),
      child: Wrap(
        spacing: FfSpace.space2,
        children: <Widget>[
          ChoiceChip(
            key: const Key('ivat-sectional-all'),
            label: Text(s(IV.allSectionals)),
            selected: state.sectional == null,
            onSelected: (_) => ctrl.selectSectional(null),
          ),
          for (final String code in reg.sectionalCodes)
            ChoiceChip(
              key: Key('ivat-sectional-$code'),
              label: Text('${s(IV.sectional)} $code'),
              selected: state.sectional == code,
              onSelected: (_) => ctrl.selectSectional(code),
            ),
        ],
      ),
    );
  }
}

class _ProRataCard extends StatelessWidget {
  const _ProRataCard({required this.reg, required this.s, required this.lang});

  final VatRegister reg;
  final ItalianVatStrings s;
  final String lang;

  @override
  Widget build(BuildContext context) {
    return VatCard(
      title: s(IV.proRata),
      children: <Widget>[
        Text(s(IV.proRataHint), style: Theme.of(context).textTheme.bodySmall),
        VatRow(
          s(IV.proRata),
          VatFormat.percent(reg.effectiveProRata, lang),
          valueKey: const Key('ivat-prorata'),
        ),
        VatRow(
          s(IV.deductible),
          VatFormat.money(reg.totalDeductible, reg.currency, lang),
          valueKey: const Key('ivat-deductible'),
        ),
        VatRow(
          s(IV.nonDeductible),
          VatFormat.money(reg.totalNonDeductible, reg.currency, lang),
          valueKey: const Key('ivat-non-deductible'),
        ),
      ],
    );
  }
}

class _VentilationCard extends StatelessWidget {
  const _VentilationCard({
    required this.reg,
    required this.s,
    required this.lang,
  });

  final VatRegister reg;
  final ItalianVatStrings s;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final List<VentilatedShare> shares = reg.ventilatedShares;
    return VatCard(
      title: s(IV.ventilation),
      children: <Widget>[
        Text(
          s(IV.ventilationHint),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        for (final VentilatedShare share in shares) ...<Widget>[
          VatRow(
            '${s(IV.ventilatedGross)} ${VatFormat.percent(share.vatRate, lang)}',
            VatFormat.money(share.gross, reg.currency, lang),
            valueKey: Key('ivat-vent-gross-${share.vatRate}'),
          ),
          VatRow(
            '${s(IV.taxable)} / ${s(IV.vat)}',
            '${VatFormat.money(share.taxable, reg.currency, lang)} / ${VatFormat.money(share.vat, reg.currency, lang)}',
          ),
        ],
      ],
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({
    required this.reg,
    required this.lines,
    required this.s,
    required this.lang,
  });

  final VatRegister reg;
  final List<VatRegisterLine> lines;
  final ItalianVatStrings s;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final Amount4 taxable = lines.fold(
      0,
      (Amount4 a, VatRegisterLine l) => a + l.taxable,
    );
    final Amount4 vat = lines.fold(
      0,
      (Amount4 a, VatRegisterLine l) => a + l.vat,
    );
    return VatCard(
      title: s(IV.totals),
      children: <Widget>[
        VatRow(
          s(IV.taxable),
          VatFormat.money(taxable, reg.currency, lang),
          valueKey: const Key('ivat-total-taxable'),
        ),
        VatRow(
          s(IV.vat),
          VatFormat.money(vat, reg.currency, lang),
          emphasis: true,
          valueKey: const Key('ivat-total-vat'),
        ),
        if (reg.byRate.length > 1) ...<Widget>[
          const Divider(),
          Text(s(IV.byRate), style: Theme.of(context).textTheme.labelMedium),
          for (final RateTotal r in reg.byRate)
            VatRow(
              VatFormat.percent(r.vatRate, lang),
              '${VatFormat.money(r.taxable, reg.currency, lang)} · ${VatFormat.money(r.vat, reg.currency, lang)}',
            ),
        ],
      ],
    );
  }
}

class _LineTile extends StatelessWidget {
  const _LineTile({
    required this.line,
    required this.reg,
    required this.s,
    required this.lang,
    required this.currency,
  });

  final VatRegisterLine line;
  final VatRegister reg;
  final ItalianVatStrings s;
  final String lang;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final bool purchases = reg.type == VatRegisterType.purchases;
    final Amount4 nonDeductible = line.nonDeductibleWith(reg.effectiveProRata);
    return ListTile(
      key: Key('ivat-line-${line.protocolNumber ?? line.documentNumber}'),
      dense: true,
      leading: Text(
        line.protocolNumber == null ? vatNoValue : '${line.protocolNumber}',
      ),
      title: Text(
        '${line.documentNumber}${line.partnerName == null ? '' : ' · ${line.partnerName}'}',
      ),
      subtitle: Text(
        '${VatFormat.date(line.documentDate ?? line.postingDate, lang)} · ${VatFormat.percent(line.vatRate, lang)}'
        '${line.sectional == null ? '' : ' · ${s(IV.sectional)} ${line.sectional}'}'
        '${purchases && nonDeductible > 0 ? ' · ${s(IV.nonDeductible)} ${VatFormat.money(nonDeductible, currency, lang)}' : ''}',
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Text(VatFormat.money(line.taxable, currency, lang)),
          Text(
            VatFormat.money(line.vat, currency, lang),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

// --- Plafond and letters of intent ---------------------------------------------------------------------------------

class _PlafondTab extends ConsumerWidget {
  const _PlafondTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ItalianVatStrings s = _strings(ref);
    final String lang = _lang(ref);
    final ItalianVatState state = ref.watch(italianVatProvider);
    final ItalianVatController ctrl = ref.read(italianVatProvider.notifier);
    return ListView(
      key: const Key('ivat-letters-list'),
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(FfSpace.space3),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  s(IV.letters),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              FilledButton.icon(
                key: const Key('ivat-add-letter'),
                icon: const Icon(Icons.add),
                label: Text(s(IV.addLetter)),
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => const _LetterDialog(),
                ),
              ),
            ],
          ),
        ),
        if (state.letters.isEmpty)
          Padding(
            padding: const EdgeInsets.all(FfSpace.space4),
            child: Text(s(IV.noLetters), key: const Key('ivat-no-letters')),
          ),
        for (final IntentLetter l in state.letters)
          _LetterCard(letter: l, s: s, lang: lang, ctrl: ctrl),
      ],
    );
  }
}

class _LetterCard extends StatelessWidget {
  const _LetterCard({
    required this.letter,
    required this.s,
    required this.lang,
    required this.ctrl,
  });

  final IntentLetter letter;
  final ItalianVatStrings s;
  final String lang;
  final ItalianVatController ctrl;

  @override
  Widget build(BuildContext context) {
    final VatTone tone = switch (letter.status) {
      IntentLetterStatus.active => VatTone.good,
      IntentLetterStatus.exhausted => VatTone.warn,
      _ => VatTone.bad,
    };
    return VatCard(
      key: Key('ivat-letter-${letter.id}'),
      title: letter.customerName,
      trailing: VatChip(
        letter.pending ? s(IV.waitingToSend) : s.letterStatus(letter.status),
        letter.pending ? VatTone.neutral : tone,
      ),
      children: <Widget>[
        VatRow(
          s(IV.adeProtocol),
          letter.protocol.isEmpty ? vatNoValue : letter.protocol,
        ),
        VatRow(s(IV.letterKind), s.kind(letter.kind)),
        VatRow(
          s(IV.validity),
          '${VatFormat.date(letter.validFrom, lang)} – ${VatFormat.date(letter.validTo, lang)}',
        ),
        const SizedBox(height: FfSpace.space2),
        PlafondBar(letter: letter),
        const SizedBox(height: FfSpace.space2),
        VatRow(
          s(IV.authorized),
          VatFormat.money(letter.authorized, letter.currency, lang),
        ),
        VatRow(
          s(IV.consumed),
          VatFormat.money(letter.consumed, letter.currency, lang),
        ),
        VatRow(
          s(IV.remaining),
          VatFormat.money(letter.remaining, letter.currency, lang),
          emphasis: true,
          valueKey: Key('ivat-remaining-${letter.id}'),
        ),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton(
            key: Key('ivat-check-${letter.id}'),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => _CheckDialog(letter: letter),
            ),
            child: Text(s(IV.checkInvoice)),
          ),
        ),
      ],
    );
  }
}

/// Checks an invoice without VAT against the plafond of one letter (art. 8 c. 1 lett. c DPR 633/1972).
class _CheckDialog extends ConsumerStatefulWidget {
  const _CheckDialog({required this.letter});

  final IntentLetter letter;

  @override
  ConsumerState<_CheckDialog> createState() => _CheckDialogState();
}

class _CheckDialogState extends ConsumerState<_CheckDialog> {
  final TextEditingController _amount = TextEditingController();
  PlafondCheck? _result;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ItalianVatStrings s = _strings(ref);
    final String lang = _lang(ref);
    final IntentLetter letter = widget.letter;
    final PlafondCheck? r = _result;
    return AlertDialog(
      title: Text(s(IV.checkInvoice)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(s(IV.plafondLaw), style: Theme.of(context).textTheme.bodySmall),
          TextField(
            key: const Key('ivat-check-amount'),
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: s(IV.invoiceAmount)),
          ),
          if (r != null) ...<Widget>[
            const SizedBox(height: FfSpace.space3),
            VatChip(
              s.plafond(r.result),
              plafondTone(r.result),
              key: const Key('ivat-check-result'),
            ),
            const SizedBox(height: FfSpace.space2),
            VatRow(
              s(IV.remainingAfter),
              VatFormat.money(r.remainingAfter, letter.currency, lang),
            ),
            if (r.excess > 0)
              VatRow(
                s(IV.excess),
                VatFormat.money(r.excess, letter.currency, lang),
              ),
          ],
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(s(IV.cancel)),
        ),
        FilledButton(
          key: const Key('ivat-check-run'),
          onPressed: () => setState(() {
            _result = PlafondGuard.evaluate(
              letter,
              parseAmount(_amount.text) ?? 0,
              ref.read(italianVatNowProvider),
            );
          }),
          child: Text(s(IV.check)),
        ),
      ],
    );
  }
}

/// Registers a received letter of intent; it is saved at once and sent through the outbox.
class _LetterDialog extends ConsumerStatefulWidget {
  const _LetterDialog();

  @override
  ConsumerState<_LetterDialog> createState() => _LetterDialogState();
}

class _LetterDialogState extends ConsumerState<_LetterDialog> {
  final TextEditingController _customer = TextEditingController();
  final TextEditingController _protocol = TextEditingController();
  final TextEditingController _amount = TextEditingController();
  IntentLetterKind _kind = IntentLetterKind.upToAmount;
  late DateTime _from;
  late DateTime _to;
  String? _issue;

  @override
  void initState() {
    super.initState();
    final DateTime now = ref.read(italianVatNowProvider);
    _from = DateTime(now.year);
    _to = DateTime(now.year, 12, 31);
  }

  @override
  void dispose() {
    _customer.dispose();
    _protocol.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _pick(bool start) async {
    final DateTime? d = await showDatePicker(
      context: context,
      initialDate: start ? _from : _to,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null) {
      setState(() => start ? _from = d : _to = d);
    }
  }

  Future<void> _save(ItalianVatStrings s) async {
    final IntentLetterDraft draft = IntentLetterDraft(
      customerName: _customer.text,
      protocol: _protocol.text,
      authorized: parseAmount(_amount.text) ?? 0,
      kind: _kind,
      validFrom: _from,
      validTo: _to,
      receivedOn: ref.read(italianVatNowProvider),
    );
    final IntentLetterDraftIssue? issue = draft.issue;
    if (issue != null) {
      setState(() => _issue = s.draftIssue(issue));
      return;
    }
    final NavigatorState nav = Navigator.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final ActionOutcome outcome = await ref
        .read(italianVatProvider.notifier)
        .createLetter(draft);
    nav.pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          s.outcome(
            outcome,
            queued: IV.letterQueued,
            sent: IV.letterSent,
            rejected: IV.letterRejected,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ItalianVatStrings s = _strings(ref);
    final String lang = _lang(ref);
    return AlertDialog(
      title: Text(s(IV.addLetter)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              key: const Key('ivat-letter-customer'),
              controller: _customer,
              decoration: InputDecoration(labelText: s(IV.customer)),
            ),
            TextField(
              key: const Key('ivat-letter-protocol'),
              controller: _protocol,
              decoration: InputDecoration(
                labelText: s(IV.adeProtocol),
                hintText: '12345678901234567-000001',
              ),
            ),
            TextField(
              key: const Key('ivat-letter-amount'),
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(labelText: s(IV.authorized)),
            ),
            DropdownButton<IntentLetterKind>(
              key: const Key('ivat-letter-kind'),
              value: _kind,
              isExpanded: true,
              items: <DropdownMenuItem<IntentLetterKind>>[
                for (final IntentLetterKind k in IntentLetterKind.values)
                  DropdownMenuItem<IntentLetterKind>(
                    value: k,
                    child: Text(s.kind(k)),
                  ),
              ],
              onChanged: (IntentLetterKind? k) =>
                  setState(() => _kind = k ?? _kind),
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextButton(
                    key: const Key('ivat-letter-from'),
                    onPressed: () => _pick(true),
                    child: Text(
                      '${s(IV.validFrom)} ${VatFormat.date(_from, lang)}',
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    key: const Key('ivat-letter-to'),
                    onPressed: () => _pick(false),
                    child: Text(
                      '${s(IV.validTo)} ${VatFormat.date(_to, lang)}',
                    ),
                  ),
                ),
              ],
            ),
            if (_issue != null)
              Text(
                _issue!,
                key: const Key('ivat-letter-issue'),
                style: TextStyle(color: vatColors(context).danger),
              ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(s(IV.cancel)),
        ),
        FilledButton(
          key: const Key('ivat-letter-save'),
          onPressed: () => _save(s),
          child: Text(s(IV.save)),
        ),
      ],
    );
  }
}

// --- LIPE ----------------------------------------------------------------------------------------------------------

class _LipeTab extends ConsumerWidget {
  const _LipeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ItalianVatStrings s = _strings(ref);
    final String lang = _lang(ref);
    final ItalianVatState state = ref.watch(italianVatProvider);
    final ItalianVatController ctrl = ref.read(italianVatProvider.notifier);
    return ListView(
      key: const Key('ivat-settlements-list'),
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(FfSpace.space3),
          child: Text(
            s(IV.settlements),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        if (state.settlements.isEmpty)
          Padding(
            padding: const EdgeInsets.all(FfSpace.space4),
            child: Text(
              s(IV.noSettlements),
              key: const Key('ivat-no-settlements'),
            ),
          ),
        for (final LipeSettlement st in state.settlements)
          _SettlementCard(settlement: st, s: s, lang: lang, ctrl: ctrl),
      ],
    );
  }
}

class _SettlementCard extends StatelessWidget {
  const _SettlementCard({
    required this.settlement,
    required this.s,
    required this.lang,
    required this.ctrl,
  });

  final LipeSettlement settlement;
  final ItalianVatStrings s;
  final String lang;
  final ItalianVatController ctrl;

  Future<void> _share(
    BuildContext context,
    Future<ExportResult> Function() run,
  ) async {
    final ExportResult r = await run();
    if (context.mounted) {
      _toast(
        context,
        r.failed
            ? (r.error == null ? s(IV.shareFailed) : s.error(r.error!))
            : s(IV.shared),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final LipeSettlement st = settlement;
    final LipeReconciliation recon = st.reconciliation;
    final LipeFileStatus file = st.file;
    final String cur = st.currency;
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: FfSpace.space3,
        vertical: FfSpace.space2,
      ),
      child: ExpansionTile(
        key: Key('ivat-settlement-${st.id}'),
        title: Text(st.periodKey),
        subtitle: Text(
          '${s(IV.netVat)}: ${VatFormat.money(st.netVat, cur, lang)}',
        ),
        trailing: VatChip(
          s.settlementStatus(st),
          st.paid ? VatTone.good : VatTone.neutral,
        ),
        onExpansionChanged: (bool open) {
          if (open) {
            ctrl.openSettlement(st.id);
          }
        },
        childrenPadding: const EdgeInsets.all(FfSpace.space3),
        children: <Widget>[
          VatRow(s(IV.outputVat), VatFormat.money(st.output, cur, lang)),
          VatRow(s(IV.inputVat), VatFormat.money(st.input, cur, lang)),
          VatRow(
            s(IV.previousDebit),
            VatFormat.money(st.previousDebit, cur, lang),
          ),
          VatRow(
            s(IV.previousCredit),
            VatFormat.money(st.previousCredit, cur, lang),
          ),
          VatRow(s(IV.interest), VatFormat.money(st.interest, cur, lang)),
          VatRow(
            s(IV.payable),
            VatFormat.money(st.payable, cur, lang),
            emphasis: true,
          ),
          const Divider(),
          Text(s(IV.erario), style: Theme.of(context).textTheme.labelLarge),
          VatChip(
            s.reconciliation(recon.state),
            reconciliationTone(recon.state),
            key: Key('ivat-recon-${st.id}'),
          ),
          if (recon.erarioBalance != null) ...<Widget>[
            VatRow(
              s(IV.erarioLedger),
              VatFormat.money(recon.erarioBalance!, cur, lang),
            ),
            VatRow(
              s(IV.erarioExpected),
              VatFormat.money(recon.expected ?? 0, cur, lang),
            ),
            VatRow(
              s(IV.erarioDifference),
              VatFormat.money(recon.difference, cur, lang),
              valueKey: Key('ivat-recon-diff-${st.id}'),
            ),
          ],
          const Divider(),
          Text(s(IV.lipeFile), style: Theme.of(context).textTheme.labelLarge),
          if (!file.generated)
            Text(s(IV.notGenerated), key: Key('ivat-lipe-none-${st.id}'))
          else ...<Widget>[
            Text(s.xsd(file.xsdValid), key: Key('ivat-lipe-xsd-${st.id}')),
            for (final String e in file.xsdErrors)
              Text(e, style: Theme.of(context).textTheme.bodySmall),
            Text(
              s.signature(file.signature),
              key: Key('ivat-lipe-sig-${st.id}'),
            ),
            if (file.readyToTransmit)
              VatChip(
                s(IV.readyToTransmit),
                VatTone.good,
                key: Key('ivat-lipe-ready-${st.id}'),
              ),
          ],
          const SizedBox(height: FfSpace.space2),
          Wrap(
            spacing: FfSpace.space2,
            children: <Widget>[
              FilledButton(
                key: Key('ivat-lipe-generate-${st.id}'),
                onPressed: () async {
                  final ActionOutcome o = await ctrl.requestLipe(st.id);
                  if (context.mounted) {
                    _toast(
                      context,
                      s.outcome(
                        o,
                        queued: IV.requestQueued,
                        sent: IV.requestSent,
                        rejected: IV.requestRejected,
                      ),
                    );
                  }
                },
                child: Text(s(IV.generateLipe)),
              ),
              OutlinedButton(
                key: Key('ivat-lipe-xml-${st.id}'),
                onPressed: () => _share(context, () => ctrl.shareLipeXml(st)),
                child: Text(s(IV.downloadXml)),
              ),
              OutlinedButton(
                key: Key('ivat-settlement-pdf-${st.id}'),
                onPressed: () =>
                    _share(context, () => ctrl.shareSettlementPdf(st)),
                child: Text(s(IV.downloadPdf)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- Annual VAT and CU ---------------------------------------------------------------------------------------------

class _AnnualTab extends ConsumerWidget {
  const _AnnualTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ItalianVatStrings s = _strings(ref);
    final String lang = _lang(ref);
    final ItalianVatState state = ref.watch(italianVatProvider);
    final ItalianVatController ctrl = ref.read(italianVatProvider.notifier);
    final AnnualVatSummary? a = state.annual;
    final CertificateTotals totals = state.certificateTotals;
    final String cur = a?.currency ?? 'EUR';
    Future<void> shareResult(Future<ExportResult> Function() run) async {
      final ExportResult r = await run();
      if (context.mounted) {
        _toast(
          context,
          r.failed
              ? (r.error == null ? s(IV.shareFailed) : s.error(r.error!))
              : s(IV.shared),
        );
      }
    }

    return RefreshIndicator(
      onRefresh: ctrl.refreshAnnual,
      child: ListView(
        key: const Key('ivat-annual-list'),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(FfSpace.space3),
            child: Row(
              children: <Widget>[
                IconButton(
                  key: const Key('ivat-annual-prev'),
                  icon: const Icon(Icons.chevron_left),
                  tooltip: s(IV.year),
                  onPressed: () => ctrl.selectYear(state.year - 1),
                ),
                Text(
                  '${s(IV.year)} ${state.year}',
                  key: const Key('ivat-annual-year'),
                ),
                IconButton(
                  key: const Key('ivat-annual-next'),
                  icon: const Icon(Icons.chevron_right),
                  tooltip: s(IV.year),
                  onPressed: () => ctrl.selectYear(state.year + 1),
                ),
              ],
            ),
          ),
          if (a != null)
            VatCard(
              title: s(IV.annualVat),
              trailing: VatChip(
                s.reconciliation(a.reconciliation),
                reconciliationTone(a.reconciliation),
                key: const Key('ivat-annual-recon'),
              ),
              children: <Widget>[
                VatRow(s(IV.outputVat), VatFormat.money(a.output, cur, lang)),
                VatRow(s(IV.inputVat), VatFormat.money(a.input, cur, lang)),
                VatRow(
                  a.balance >= 0 ? s(IV.balanceDue) : s(IV.balanceCredit),
                  VatFormat.money(a.balance.abs(), cur, lang),
                  emphasis: true,
                  valueKey: const Key('ivat-annual-balance'),
                ),
                VatRow(s(IV.paidAmount), VatFormat.money(a.paid, cur, lang)),
                VatRow(
                  s(IV.stillDue),
                  VatFormat.money(a.stillDue, cur, lang),
                  valueKey: const Key('ivat-annual-due'),
                ),
                if (a.creditCarriedForward != null)
                  VatRow(
                    s(IV.creditForward),
                    VatFormat.money(a.creditCarriedForward!, cur, lang),
                  ),
                if (a.erarioBalance != null) ...<Widget>[
                  VatRow(
                    s(IV.erarioLedger),
                    VatFormat.money(a.erarioBalance!, cur, lang),
                  ),
                  VatRow(
                    s(IV.erarioDifference),
                    VatFormat.money(a.erarioDifference, cur, lang),
                  ),
                ],
                if (a.missingQuarters.isNotEmpty && a.periods.isNotEmpty)
                  VatRow(
                    s(IV.missingQuarters),
                    a.missingQuarters.map((int q) => 'Q$q').join(', '),
                    valueKey: const Key('ivat-annual-missing'),
                  ),
                Text(
                  a.fromServer ? s(IV.fromServer) : s(IV.computedOnPhone),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          VatCard(
            title: s(IV.certificates),
            children: <Widget>[
              if (state.certificates.isEmpty)
                Text(
                  s(IV.noCertificates),
                  key: const Key('ivat-no-certificates'),
                )
              else ...<Widget>[
                VatRow(s(IV.gross), VatFormat.money(totals.gross, cur, lang)),
                VatRow(
                  s(IV.withheld),
                  VatFormat.money(totals.withheld, cur, lang),
                  valueKey: const Key('ivat-cu-withheld'),
                ),
                VatRow(
                  s(IV.openWithholding),
                  VatFormat.money(totals.f24Open, cur, lang),
                  valueKey: const Key('ivat-cu-open'),
                ),
              ],
              const SizedBox(height: FfSpace.space2),
              Wrap(
                spacing: FfSpace.space2,
                children: <Widget>[
                  FilledButton(
                    key: const Key('ivat-cu-generate'),
                    onPressed: () async {
                      final ActionOutcome o = await ctrl.requestCertificates();
                      if (context.mounted) {
                        _toast(
                          context,
                          s.outcome(
                            o,
                            queued: IV.requestQueued,
                            sent: IV.requestSent,
                            rejected: IV.requestRejected,
                          ),
                        );
                      }
                    },
                    child: Text(s(IV.generateCertificates)),
                  ),
                  OutlinedButton(
                    key: const Key('ivat-cu-telematic'),
                    onPressed: state.certificates.isEmpty
                        ? null
                        : () => shareResult(ctrl.shareTelematicFile),
                    child: Text(s(IV.telematicFile)),
                  ),
                ],
              ),
            ],
          ),
          for (final WithholdingCertificate c in state.certificates)
            VatCard(
              key: Key('ivat-cu-${c.id}'),
              title: c.recipientName,
              trailing: VatChip(s.f24(c.f24Status), f24Tone(c.f24Status)),
              children: <Widget>[
                VatRow(s(IV.recipient), s.recipientKind(c.kind)),
                if (c.taxCode != null || c.vatNumber != null)
                  VatRow('CF / P.IVA', c.taxCode ?? c.vatNumber ?? ''),
                VatRow(s(IV.causale), c.causale),
                VatRow(s(IV.gross), VatFormat.money(c.gross, c.currency, lang)),
                VatRow(
                  s(IV.withheld),
                  VatFormat.money(c.withheld, c.currency, lang),
                ),
                VatRow(
                  s(IV.f24Status),
                  '${VatFormat.money(c.f24Paid, c.currency, lang)}'
                  '${c.f24PaidOn == null ? '' : ' · ${VatFormat.date(c.f24PaidOn, lang)}'}',
                ),
                VatRow(s(IV.f24Code), c.f24Code),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    key: Key('ivat-cu-pdf-${c.id}'),
                    onPressed: c.pdfAvailable
                        ? () => shareResult(() => ctrl.shareCertificatePdf(c))
                        : null,
                    child: Text(s(IV.downloadPdf)),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
