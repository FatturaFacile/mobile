import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/providers.dart';
import '../../../design/ff_tokens.dart';
import '../domain/gl_amount.dart';
import '../domain/gl_models.dart';
import '../domain/gl_repository.dart';
import 'gl_controller.dart';
import 'gl_strings.dart';

/// RBAC module key of the general ledger (prima nota, journals, trial balance).
const String generalLedgerModule = 'general_ledger';

GlStrings _strings(WidgetRef ref) =>
    GlStrings(ref.watch(requestContextProvider).languageCode);

String _language(WidgetRef ref) =>
    ref.watch(requestContextProvider).languageCode;

DateTime _parseDay(String day) => DateTime.tryParse(day) ?? DateTime.now();

/// General ledger on the phone: prima nota entry, journal list with storno, trial balance and mastrino.
class GlHomePage extends ConsumerWidget {
  const GlHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GlStrings s = _strings(ref);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(s(GL.title)),
          bottom: TabBar(
            tabs: <Widget>[
              Tab(key: const Key('gl-tab-entry'), text: s(GL.tabEntry)),
              Tab(key: const Key('gl-tab-journals'), text: s(GL.tabJournals)),
              Tab(key: const Key('gl-tab-trial'), text: s(GL.tabTrial)),
            ],
          ),
        ),
        body: const TabBarView(
          children: <Widget>[
            JournalEntryTab(),
            JournalsTab(),
            TrialBalanceTab(),
          ],
        ),
      ),
    );
  }
}

// --- Prima nota entry --------------------------------------------------------------------------------------------

class JournalEntryTab extends ConsumerStatefulWidget {
  const JournalEntryTab({super.key});

  @override
  ConsumerState<JournalEntryTab> createState() => _JournalEntryTabState();
}

class _JournalEntryTabState extends ConsumerState<JournalEntryTab> {
  AccountingTemplate? _template;
  final TextEditingController _amount = TextEditingController();
  final TextEditingController _rate = TextEditingController();
  final Map<String, GlAccount> _chosen = <String, GlAccount>{};

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() => ref.read(glReferenceProvider.notifier).load());
  }

  @override
  void dispose() {
    _amount.dispose();
    _rate.dispose();
    super.dispose();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickDate(GlFormState form) async {
    final DateTime now = DateTime.now();
    final DateTime? day = await showDatePicker(
      context: context,
      initialDate: _parseDay(form.postingDate),
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 2),
    );
    if (day != null) {
      ref.read(glFormProvider.notifier).setPostingDate(glDay(day));
    }
  }

  void _apply(GlStrings s, String language, GlReferenceState ref0) {
    final AccountingTemplate? t = _template;
    final Amount4? amount = parseAmount(_amount.text);
    if (t == null || amount == null || amount <= 0) {
      return;
    }
    final TemplateHydration h = ref
        .read(glFormProvider.notifier)
        .applyTemplate(
          t,
          amount: amount,
          taxRate: parseAmount(_rate.text) ?? 0,
          chosen: _chosen,
          known: ref0.accounts,
          language: language,
        );
    if (h.missingAccountKeys.isNotEmpty) {
      _toast(s(GL.problemAccount));
    }
  }

  @override
  Widget build(BuildContext context) {
    final GlStrings s = _strings(ref);
    final String language = _language(ref);
    final GlFormState form = ref.watch(glFormProvider);
    final GlReferenceState reference = ref.watch(glReferenceProvider);
    ref.listen<GlFormOutcome>(
      glFormProvider.select((GlFormState f) => f.outcome),
      (GlFormOutcome? _, GlFormOutcome next) {
        if (next == GlFormOutcome.none) {
          return;
        }
        final String detail = ref.read(glFormProvider).detail;
        _toast(switch (next) {
          GlFormOutcome.draftSaved => s(GL.draftSaved),
          GlFormOutcome.posted => s(GL.postedOk),
          GlFormOutcome.queued => s(GL.queuedOffline),
          GlFormOutcome.rejected =>
            detail.isEmpty ? s(GL.refused) : '${s(GL.refused)}: $detail',
          GlFormOutcome.failed => s(GL.errorInvalid),
          GlFormOutcome.none => '',
        });
        ref.read(glFormProvider.notifier).clearOutcome();
      },
    );
    final String? tenant = ref.watch(glTenantIdProvider);
    final JournalEntry? entry = tenant == null ? null : form.toEntry(tenant);
    final bool postable = entry != null && entry.isPostable && !form.busy;
    final List<JournalProblem> problems = entry?.problems ?? <JournalProblem>[];
    final List<GlAccount> accounts = reference.postable;
    final Amount4 difference = form.difference;
    return ListView(
      padding: const EdgeInsets.all(FfSpace.space4),
      children: <Widget>[
        _templateCard(s, language, reference),
        const SizedBox(height: FfSpace.space3),
        Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton.icon(
                key: const Key('gl-date'),
                icon: const Icon(Icons.event_outlined),
                label: Text('${s(GL.postingDate)}: ${form.postingDate}'),
                onPressed: () => _pickDate(form),
              ),
            ),
          ],
        ),
        const SizedBox(height: FfSpace.space3),
        TextFormField(
          key: Key('gl-description-${form.revision}'),
          initialValue: form.description,
          decoration: InputDecoration(labelText: s(GL.description)),
          onChanged: ref.read(glFormProvider.notifier).setDescription,
        ),
        const SizedBox(height: FfSpace.space3),
        Text(s(GL.ledgerBook), style: Theme.of(context).textTheme.titleSmall),
        Wrap(
          spacing: FfSpace.space2,
          children: <Widget>[
            for (final LedgerBook b in LedgerBook.values)
              ChoiceChip(
                key: Key('gl-book-${b.code}'),
                label: Text(s.book(b)),
                selected: form.ledger == b,
                onSelected: (bool _) =>
                    ref.read(glFormProvider.notifier).setLedger(b),
              ),
          ],
        ),
        Text(s(GL.alsoPostTo), style: Theme.of(context).textTheme.bodySmall),
        Wrap(
          spacing: FfSpace.space2,
          children: <Widget>[
            for (final LedgerBook b in LedgerBook.values)
              if (b != form.ledger)
                FilterChip(
                  key: Key('gl-also-${b.code}'),
                  label: Text(s.book(b)),
                  selected: form.alsoPostTo.contains(b),
                  onSelected: (bool on) =>
                      ref.read(glFormProvider.notifier).toggleAlsoPostTo(b, on),
                ),
          ],
        ),
        const SizedBox(height: FfSpace.space3),
        Text(s(GL.lines), style: Theme.of(context).textTheme.titleSmall),
        for (int i = 0; i < form.lines.length; i++)
          _lineCard(s, form, form.lines[i], i, accounts),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: const Key('gl-add-line'),
            icon: const Icon(Icons.add),
            label: Text(s(GL.addLine)),
            onPressed: ref.read(glFormProvider.notifier).addLine,
          ),
        ),
        const Divider(),
        _totals(s, language, form, difference),
        const SizedBox(height: FfSpace.space2),
        if (!postable && problems.isNotEmpty && !form.busy)
          Text(
            problems.map(s.problem).join(' · '),
            key: const Key('gl-problems'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        const SizedBox(height: FfSpace.space3),
        Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton(
                key: const Key('gl-save-draft'),
                onPressed: postable
                    ? ref.read(glFormProvider.notifier).saveDraft
                    : null,
                child: Text(s(GL.saveDraft)),
              ),
            ),
            const SizedBox(width: FfSpace.space3),
            Expanded(
              child: FilledButton(
                key: const Key('gl-post'),
                onPressed: postable
                    ? ref.read(glFormProvider.notifier).post
                    : null,
                child: Text(s(GL.post)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _totals(
    GlStrings s,
    String language,
    GlFormState form,
    Amount4 difference,
  ) {
    final TextStyle? style = Theme.of(context).textTheme.bodyMedium;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(s(GL.totalDebit), style: style),
            Text(
              formatAmount(form.totalDebit, language: language),
              key: const Key('gl-total-debit'),
              style: style,
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(s(GL.totalCredit), style: style),
            Text(
              formatAmount(form.totalCredit, language: language),
              key: const Key('gl-total-credit'),
              style: style,
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              s(GL.difference),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Text(
              formatAmount(difference, language: language),
              key: const Key('gl-difference'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
        Text(
          difference == 0 && form.totalDebit > 0
              ? s(GL.balanced)
              : s(GL.postBlocked),
          key: const Key('gl-balance-hint'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _lineCard(
    GlStrings s,
    GlFormState form,
    FormLine line,
    int index,
    List<GlAccount> accounts,
  ) {
    final bool known = accounts.any((GlAccount a) => a.id == line.accountId);
    return Card(
      key: Key('gl-line-${line.uid}'),
      child: Padding(
        padding: const EdgeInsets.all(FfSpace.space3),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: DropdownButtonFormField<String>(
                    key: Key('gl-account-${line.uid}-${form.revision}'),
                    isExpanded: true,
                    initialValue: line.accountId.isEmpty
                        ? null
                        : line.accountId,
                    decoration: InputDecoration(labelText: s(GL.account)),
                    items: <DropdownMenuItem<String>>[
                      if (!known && line.accountId.isNotEmpty)
                        DropdownMenuItem<String>(
                          value: line.accountId,
                          child: Text(
                            '${line.accountCode} ${line.accountName}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      for (final GlAccount a in accounts)
                        DropdownMenuItem<String>(
                          value: a.id,
                          child: Text(a.label, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: (String? id) {
                      for (final GlAccount a in accounts) {
                        if (a.id == id) {
                          ref
                              .read(glFormProvider.notifier)
                              .updateLine(line.uid, account: a);
                        }
                      }
                    },
                  ),
                ),
                IconButton(
                  key: Key('gl-remove-${line.uid}'),
                  tooltip: s(GL.removeLine),
                  icon: const Icon(Icons.delete_outline),
                  onPressed: form.lines.length <= 1
                      ? null
                      : () => ref
                            .read(glFormProvider.notifier)
                            .removeLine(line.uid),
                ),
              ],
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextFormField(
                    key: Key('gl-debit-${line.uid}-${form.revision}'),
                    initialValue: amountToInput(line.debit),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(labelText: s(GL.debit)),
                    onChanged: (String v) => ref
                        .read(glFormProvider.notifier)
                        .updateLine(line.uid, debit: parseAmount(v) ?? 0),
                  ),
                ),
                const SizedBox(width: FfSpace.space3),
                Expanded(
                  child: TextFormField(
                    key: Key('gl-credit-${line.uid}-${form.revision}'),
                    initialValue: amountToInput(line.credit),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(labelText: s(GL.credit)),
                    onChanged: (String v) => ref
                        .read(glFormProvider.notifier)
                        .updateLine(line.uid, credit: parseAmount(v) ?? 0),
                  ),
                ),
              ],
            ),
            TextFormField(
              key: Key('gl-note-${line.uid}-${form.revision}'),
              initialValue: line.description,
              decoration: InputDecoration(labelText: s(GL.lineDescription)),
              onChanged: (String v) => ref
                  .read(glFormProvider.notifier)
                  .updateLine(line.uid, description: v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _templateCard(
    GlStrings s,
    String language,
    GlReferenceState reference,
  ) {
    final AccountingTemplate? t = _template;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(FfSpace.space3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            DropdownButtonFormField<String>(
              key: const Key('gl-template'),
              isExpanded: true,
              initialValue: t?.id,
              decoration: InputDecoration(labelText: s(GL.template)),
              items: <DropdownMenuItem<String>>[
                for (final AccountingTemplate x in reference.templates)
                  DropdownMenuItem<String>(
                    value: x.id,
                    child: Text(
                      x.label(language),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (String? id) => setState(() {
                _chosen.clear();
                _template = null;
                for (final AccountingTemplate x in reference.templates) {
                  if (x.id == id) {
                    _template = x;
                  }
                }
              }),
            ),
            if (t != null) ...<Widget>[
              TextField(
                key: const Key('gl-template-amount'),
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(labelText: s(GL.templateAmount)),
              ),
              if (t.needsRate)
                TextField(
                  key: const Key('gl-template-rate'),
                  controller: _rate,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(labelText: s(GL.templateRate)),
                ),
              for (final String key in t.accountKeys)
                DropdownButtonFormField<String>(
                  key: Key('gl-template-account-$key'),
                  isExpanded: true,
                  initialValue: _chosen[key]?.id,
                  decoration: InputDecoration(
                    labelText: '${s(GL.templateAccount)}: $key',
                  ),
                  items: <DropdownMenuItem<String>>[
                    for (final GlAccount a in reference.postable)
                      DropdownMenuItem<String>(
                        value: a.id,
                        child: Text(a.label, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (String? id) {
                    final GlAccount? a = reference.accountById(id ?? '');
                    if (a != null) {
                      _chosen[key] = a;
                    }
                  },
                ),
              Padding(
                padding: const EdgeInsets.only(top: FfSpace.space2),
                child: FilledButton.tonal(
                  key: const Key('gl-template-apply'),
                  onPressed: () => _apply(s, language, reference),
                  child: Text(s(GL.applyTemplate)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// --- Journal list ------------------------------------------------------------------------------------------------

class JournalsTab extends ConsumerStatefulWidget {
  const JournalsTab({super.key});

  @override
  ConsumerState<JournalsTab> createState() => _JournalsTabState();
}

class _JournalsTabState extends ConsumerState<JournalsTab> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(glJournalsControllerProvider.notifier).refresh(),
    );
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _storno(JournalEntry entry, GlStrings s) async {
    final TextEditingController reason = TextEditingController();
    String date = glDay(DateTime.now());
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => StatefulBuilder(
        builder: (BuildContext ctx, StateSetter set) => AlertDialog(
          title: Text(s(GL.stornoTitle)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              OutlinedButton.icon(
                key: const Key('gl-storno-date'),
                icon: const Icon(Icons.event_outlined),
                label: Text('${s(GL.reversalDate)}: $date'),
                onPressed: () async {
                  final DateTime now = DateTime.now();
                  final DateTime? d = await showDatePicker(
                    context: ctx,
                    initialDate: _parseDay(date),
                    firstDate: DateTime(now.year - 5),
                    lastDate: DateTime(now.year + 2),
                  );
                  if (d != null) {
                    set(() => date = glDay(d));
                  }
                },
              ),
              TextField(
                key: const Key('gl-storno-reason'),
                controller: reason,
                decoration: InputDecoration(labelText: s(GL.reason)),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(s(GL.cancel)),
            ),
            FilledButton(
              key: const Key('gl-storno-confirm'),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(s(GL.confirm)),
            ),
          ],
        ),
      ),
    );
    final String text = reason.text.trim();
    reason.dispose();
    if (ok != true) {
      return;
    }
    final SubmitOutcome? o = await ref
        .read(glJournalsControllerProvider.notifier)
        .reverse(entry, reversalDate: date, reason: text);
    if (!mounted || o == null) {
      return;
    }
    _toast(switch (o.status) {
      SubmitStatus.synced => s(GL.stornoDone),
      SubmitStatus.queued => s(GL.stornoQueued),
      SubmitStatus.rejected => '${s(GL.refused)}: ${o.detail}',
    });
  }

  @override
  Widget build(BuildContext context) {
    final GlStrings s = _strings(ref);
    final String language = _language(ref);
    final AsyncValue<List<JournalEntry>> journals = ref.watch(
      glJournalsProvider,
    );
    final GlJournalsState state = ref.watch(glJournalsControllerProvider);
    final List<JournalEntry> items = journals.value ?? const <JournalEntry>[];
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(glJournalsControllerProvider.notifier).refresh(),
      child: ListView(
        padding: const EdgeInsets.all(FfSpace.space4),
        children: <Widget>[
          if (state.fromCache)
            Padding(
              padding: const EdgeInsets.only(bottom: FfSpace.space3),
              child: Text(s(GL.offlineCopy), key: const Key('gl-cached')),
            ),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(FfSpace.space5),
              child: Center(
                child: Text(s(GL.noJournals), key: const Key('gl-empty')),
              ),
            ),
          for (final JournalEntry e in items) _card(e, s, language),
        ],
      ),
    );
  }

  Widget _card(JournalEntry e, GlStrings s, String language) {
    final bool canReverse =
        e.serverId != null &&
        e.status == JournalStatus.posted &&
        !e.isReversal &&
        e.syncState == JournalSyncState.synced;
    return Card(
      key: Key('gl-journal-${e.id}'),
      child: Padding(
        padding: const EdgeInsets.all(FfSpace.space3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    e.description,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Text(formatAmount(e.totalDebit, language: language)),
              ],
            ),
            Text(
              '${e.postingDate} · ${s.book(e.ledger)}'
              '${e.entryNumber == null ? '' : ' · ${e.entryNumber}'}',
            ),
            if (e.isReversal)
              Text(
                '${s(GL.reversalOf)}: ${e.reversalReason ?? ''}',
                key: Key('gl-reversal-${e.id}'),
              ),
            Wrap(
              spacing: FfSpace.space1,
              children: <Widget>[
                Chip(
                  key: Key('gl-status-${e.id}'),
                  label: Text(s.status(e.status)),
                  visualDensity: VisualDensity.compact,
                ),
                Chip(
                  key: Key('gl-sync-${e.id}'),
                  label: Text(s.syncState(e.syncState)),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            if (e.syncState == JournalSyncState.rejected &&
                (e.lastError ?? '').isNotEmpty)
              Text(
                '${s(GL.refused)}: ${e.lastError}',
                key: Key('gl-error-${e.id}'),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                if (canReverse)
                  TextButton.icon(
                    key: Key('gl-reverse-${e.id}'),
                    icon: const Icon(Icons.undo),
                    label: Text(s(GL.storno)),
                    onPressed: () => _storno(e, s),
                  ),
                if (e.isEditable)
                  TextButton.icon(
                    key: Key('gl-discard-${e.id}'),
                    icon: const Icon(Icons.delete_outline),
                    label: Text(s(GL.discard)),
                    onPressed: () => ref
                        .read(glJournalsControllerProvider.notifier)
                        .discard(e),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// --- Trial balance -----------------------------------------------------------------------------------------------

class TrialBalanceTab extends ConsumerStatefulWidget {
  const TrialBalanceTab({super.key});

  @override
  ConsumerState<TrialBalanceTab> createState() => _TrialBalanceTabState();
}

class _TrialBalanceTabState extends ConsumerState<TrialBalanceTab> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() => ref.read(glTrialProvider.notifier).load());
  }

  Future<void> _pick(GlTrialState state, {required bool from}) async {
    final DateTime now = DateTime.now();
    final DateTime? day = await showDatePicker(
      context: context,
      initialDate: _parseDay(from ? state.from : state.to),
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 2),
    );
    if (day == null) {
      return;
    }
    await ref
        .read(glTrialProvider.notifier)
        .setFilter(
          from: from ? glDay(day) : null,
          to: from ? null : glDay(day),
        );
  }

  @override
  Widget build(BuildContext context) {
    final GlStrings s = _strings(ref);
    final String language = _language(ref);
    final GlTrialState state = ref.watch(glTrialProvider);
    final TrialBalance? data = state.data;
    return RefreshIndicator(
      onRefresh: () => ref.read(glTrialProvider.notifier).load(),
      child: ListView(
        padding: const EdgeInsets.all(FfSpace.space4),
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  key: const Key('gl-trial-from'),
                  onPressed: () => _pick(state, from: true),
                  child: Text('${s(GL.from)}: ${state.from}'),
                ),
              ),
              const SizedBox(width: FfSpace.space2),
              Expanded(
                child: OutlinedButton(
                  key: const Key('gl-trial-to'),
                  onPressed: () => _pick(state, from: false),
                  child: Text('${s(GL.to)}: ${state.to}'),
                ),
              ),
            ],
          ),
          const SizedBox(height: FfSpace.space2),
          Wrap(
            spacing: FfSpace.space2,
            children: <Widget>[
              for (final LedgerBook b in LedgerBook.values)
                ChoiceChip(
                  key: Key('gl-trial-book-${b.code}'),
                  label: Text(s.book(b)),
                  selected: state.ledger == b,
                  onSelected: (bool _) =>
                      ref.read(glTrialProvider.notifier).setFilter(ledger: b),
                ),
            ],
          ),
          const SizedBox(height: FfSpace.space2),
          SegmentedButton<int>(
            key: const Key('gl-trial-columns'),
            segments: <ButtonSegment<int>>[
              ButtonSegment<int>(value: 2, label: Text(s(GL.columns2))),
              ButtonSegment<int>(value: 4, label: Text(s(GL.columns4))),
            ],
            selected: <int>{state.columns},
            onSelectionChanged: (Set<int> v) =>
                ref.read(glTrialProvider.notifier).setFilter(columns: v.first),
          ),
          if (state.fromCache)
            Padding(
              padding: const EdgeInsets.only(top: FfSpace.space3),
              child: Text(s(GL.offlineCopy), key: const Key('gl-trial-cached')),
            ),
          if (state.error != null && data == null)
            Padding(
              padding: const EdgeInsets.only(top: FfSpace.space3),
              child: Text(
                s.error(state.error!),
                key: const Key('gl-trial-error'),
              ),
            ),
          const SizedBox(height: FfSpace.space3),
          if (state.loading && data == null)
            const Center(child: CircularProgressIndicator())
          else if (data == null || data.rows.isEmpty)
            Padding(
              padding: const EdgeInsets.all(FfSpace.space5),
              child: Center(
                child: Text(s(GL.noData), key: const Key('gl-trial-empty')),
              ),
            )
          else ...<Widget>[
            for (final TrialBalanceRow r in data.rows)
              _row(context, s, language, state, data, r),
            const Divider(),
            _totalsRow(context, s, language, data),
          ],
        ],
      ),
    );
  }

  Widget _value(String label, Amount4 value, String language, {Key? key}) {
    return Padding(
      padding: const EdgeInsets.only(right: FfSpace.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          Text(formatAmount(value, language: language), key: key),
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context,
    GlStrings s,
    String language,
    GlTrialState state,
    TrialBalance data,
    TrialBalanceRow r,
  ) {
    return Card(
      key: Key('gl-trial-row-${r.code}'),
      child: ListTile(
        title: Text('${r.code} ${r.name}'),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: FfSpace.space1),
          child: Wrap(
            children: data.columns == 2
                ? <Widget>[
                    _value(s(GL.debitBalance), r.debitBalance, language),
                    _value(s(GL.creditBalance), r.creditBalance, language),
                  ]
                : <Widget>[
                    _value(s(GL.opening), r.opening, language),
                    _value(s(GL.debit), r.debit, language),
                    _value(s(GL.credit), r.credit, language),
                    _value(s(GL.closing), r.closing, language),
                  ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => AccountLedgerPage(
              accountId: r.accountId,
              accountLabel: '${r.code} ${r.name}',
              from: state.from,
              to: state.to,
              ledger: state.ledger,
            ),
          ),
        ),
      ),
    );
  }

  Widget _totalsRow(
    BuildContext context,
    GlStrings s,
    String language,
    TrialBalance data,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(s(GL.totals), style: Theme.of(context).textTheme.titleSmall),
        Wrap(
          children: <Widget>[
            _value(
              data.columns == 2 ? s(GL.debitBalance) : s(GL.debit),
              data.totalDebit,
              language,
              key: const Key('gl-trial-total-debit'),
            ),
            _value(
              data.columns == 2 ? s(GL.creditBalance) : s(GL.credit),
              data.totalCredit,
              language,
              key: const Key('gl-trial-total-credit'),
            ),
          ],
        ),
        Text(
          data.isBalanced ? s(GL.balanced) : s(GL.notBalanced),
          key: const Key('gl-trial-balanced'),
        ),
      ],
    );
  }
}

// --- Mastrino ----------------------------------------------------------------------------------------------------

/// The account ledger of one account: opening balance, movements with the running balance, closing balance.
class AccountLedgerPage extends ConsumerStatefulWidget {
  const AccountLedgerPage({
    required this.accountId,
    required this.accountLabel,
    required this.from,
    required this.to,
    required this.ledger,
    super.key,
  });

  final String accountId;
  final String accountLabel;
  final String from;
  final String to;
  final LedgerBook ledger;

  @override
  ConsumerState<AccountLedgerPage> createState() => _AccountLedgerPageState();
}

class _AccountLedgerPageState extends ConsumerState<AccountLedgerPage> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref
          .read(glLedgerProvider.notifier)
          .load(
            accountId: widget.accountId,
            from: widget.from,
            to: widget.to,
            ledger: widget.ledger,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final GlStrings s = _strings(ref);
    final String language = _language(ref);
    final GlLedgerState state = ref.watch(glLedgerProvider);
    final AccountLedger? data = state.data;
    return Scaffold(
      appBar: AppBar(title: Text('${s(GL.mastrino)} · ${widget.accountLabel}')),
      body: ListView(
        padding: const EdgeInsets.all(FfSpace.space4),
        children: <Widget>[
          Text(
            '${s.book(widget.ledger)} · ${widget.from} - ${widget.to}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (state.fromCache)
            Text(s(GL.offlineCopy), key: const Key('gl-ledger-cached')),
          if (state.error != null && data == null)
            Text(s.error(state.error!), key: const Key('gl-ledger-error')),
          if (state.loading && data == null)
            const Center(child: CircularProgressIndicator())
          else if (data != null) ...<Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(s(GL.opening)),
                Text(
                  formatAmount(data.opening, language: language),
                  key: const Key('gl-ledger-opening'),
                ),
              ],
            ),
            if (data.lines.isEmpty)
              Padding(
                padding: const EdgeInsets.all(FfSpace.space5),
                child: Center(
                  child: Text(
                    s(GL.noMovements),
                    key: const Key('gl-ledger-empty'),
                  ),
                ),
              ),
            for (final AccountLedgerLine l in data.lines)
              Card(
                child: ListTile(
                  title: Text(l.description),
                  subtitle: Text(
                    '${l.postingDate} · ${s(GL.debit)} '
                    '${formatAmount(l.debit, language: language)} · ${s(GL.credit)} '
                    '${formatAmount(l.credit, language: language)}',
                  ),
                  trailing: Text(
                    formatAmount(l.runningBalance, language: language),
                  ),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  s(GL.closing),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  formatAmount(data.closing, language: language),
                  key: const Key('gl-ledger-closing'),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
