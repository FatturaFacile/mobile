import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/providers.dart';
import '../../../design/ff_tokens.dart';
import '../domain/swiss_vat_models.dart';
import 'swiss_vat_controller.dart';
import 'swiss_vat_strings.dart';
import 'swiss_vat_widgets.dart';

SwissVatStrings _strings(WidgetRef ref) =>
    SwissVatStrings(ref.watch(requestContextProvider).languageCode);

String _locale(WidgetRef ref) => ref.watch(requestContextProvider).languageCode;

void _toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

/// Swiss VAT (MWST / IVA / TVA) Mod 024 workspace:
/// Effective & Saldosteuersatz returns with AFC boxes + quadratura + SuisseTax XML share,
/// Bezugsteuer (Art. 45 LIVA), Input Tax Adjustments (Art. 30-33 LIVA), and Regime configuration.
class SwissVatHomePage extends ConsumerStatefulWidget {
  const SwissVatHomePage({super.key});

  @override
  ConsumerState<SwissVatHomePage> createState() => _SwissVatHomePageState();
}

class _SwissVatHomePageState extends ConsumerState<SwissVatHomePage> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() => ref.read(swissVatProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final SwissVatStrings s = _strings(ref);
    final SwissVatState state = ref.watch(swissVatProvider);
    final SwissVatController ctrl = ref.read(swissVatProvider.notifier);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(s(SV.title)),
          actions: <Widget>[
            IconButton(
              key: const Key('chvat-refresh'),
              tooltip: s(SV.refresh),
              icon: const Icon(Icons.refresh),
              onPressed: ctrl.load,
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabs: <Widget>[
              Tab(key: const Key('chvat-tab-returns'), text: s(SV.tabReturns)),
              Tab(
                key: const Key('chvat-tab-bezugsteuer'),
                text: s(SV.tabBezugsteuer),
              ),
              Tab(
                key: const Key('chvat-tab-adjustments'),
                text: s(SV.tabAdjustments),
              ),
              Tab(key: const Key('chvat-tab-config'), text: s(SV.tabConfig)),
            ],
          ),
        ),
        body: Column(
          children: <Widget>[
            if (state.loading) const LinearProgressIndicator(),
            if (state.fromCache) swissVatOfflineBanner(s),
            if (state.error != null &&
                state.error!.kind != SwissVatErrorKind.offline)
              Padding(
                padding: const EdgeInsets.all(FfSpace.space3),
                child: Text(
                  state.forbidden ? s(SV.forbidden) : s.error(state.error!),
                  key: const Key('chvat-error'),
                ),
              ),
            if (state.pending.isNotEmpty)
              _PendingQueueCard(state: state, s: s, ctrl: ctrl),
            const Expanded(
              child: TabBarView(
                children: <Widget>[
                  _ReturnsTab(),
                  _BezugsteuerTab(),
                  _AdjustmentsTab(),
                  _ConfigTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingQueueCard extends StatelessWidget {
  const _PendingQueueCard({
    required this.state,
    required this.s,
    required this.ctrl,
  });

  final SwissVatState state;
  final SwissVatStrings s;
  final SwissVatController ctrl;

  @override
  Widget build(BuildContext context) {
    return SwissVatCard(
      title: s(SV.pendingActions),
      children: <Widget>[
        for (final PendingSwissVatAction a in state.pending)
          Row(
            key: Key('chvat-pending-${a.queueUuid}'),
            children: <Widget>[
              Expanded(
                child: Text(
                  '${a.kind.name}${a.targetLabel.isEmpty ? '' : ' · ${a.targetLabel}'}'
                  ' — ${a.rejected ? (a.detail.isEmpty ? s(SV.actionRejected) : a.detail) : s(SV.actionWaiting)}',
                ),
              ),
              if (a.rejected) ...<Widget>[
                TextButton(
                  key: Key('chvat-retry-${a.queueUuid}'),
                  onPressed: () => ctrl.retry(a.queueUuid),
                  child: Text(s(SV.retry)),
                ),
                TextButton(
                  key: Key('chvat-dismiss-${a.queueUuid}'),
                  onPressed: () => ctrl.dismiss(a.queueUuid),
                  child: Text(s(SV.dismiss)),
                ),
              ],
            ],
          ),
      ],
    );
  }
}

// --- Tab 1: Returns, AFC Boxes, Quadratura & SuisseTax XML ----------------------------------------------------------

class _ReturnsTab extends ConsumerWidget {
  const _ReturnsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SwissVatStrings s = _strings(ref);
    final String locale = _locale(ref);
    final SwissVatState state = ref.watch(swissVatProvider);
    final SwissVatController ctrl = ref.read(swissVatProvider.notifier);
    final SwissVatReturn? sel = state.selectedReturn;

    return RefreshIndicator(
      onRefresh: ctrl.load,
      child: ListView(
        key: const Key('chvat-returns-list'),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(FfSpace.space3),
            child: Wrap(
              spacing: FfSpace.space2,
              runSpacing: FfSpace.space2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                DropdownButton<int>(
                  key: const Key('chvat-year'),
                  value: state.year,
                  items: <DropdownMenuItem<int>>[
                    for (int y = 2022; y <= 2028; y++)
                      DropdownMenuItem<int>(value: y, child: Text('$y')),
                  ],
                  onChanged: (int? y) {
                    if (y != null) {
                      ctrl.setYear(y);
                    }
                  },
                ),
                DropdownButton<int>(
                  key: const Key('chvat-period'),
                  value: state.periodNumber,
                  items: <DropdownMenuItem<int>>[
                    for (int p = 1; p <= 4; p++)
                      DropdownMenuItem<int>(value: p, child: Text('P$p')),
                  ],
                  onChanged: (int? p) {
                    if (p != null) {
                      ctrl.setPeriodNumber(p);
                    }
                  },
                ),
                FilledButton.icon(
                  key: const Key('chvat-calc-btn'),
                  icon: const Icon(Icons.calculate),
                  label: Text(s(SV.calculateReturn)),
                  onPressed: () async {
                    final SwissVatActionOutcome out = await ctrl
                        .calculateCurrentPeriod();
                    if (context.mounted) {
                      _toast(
                        context,
                        out.status == SwissVatActionStatus.sent
                            ? s(SV.savedOk)
                            : s(SV.queuedOffline),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          if (state.returns.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: FfSpace.space3),
              child: Wrap(
                spacing: FfSpace.space2,
                children: <Widget>[
                  for (final SwissVatReturn r in state.returns)
                    ChoiceChip(
                      key: Key('chvat-return-chip-${r.id}'),
                      label: Text('${r.periodLabel} (${r.status.wire})'),
                      selected: sel?.id == r.id,
                      onSelected: (_) => ctrl.selectReturn(r.id),
                    ),
                ],
              ),
            ),
          if (sel == null)
            Padding(
              padding: const EdgeInsets.all(FfSpace.space4),
              child: Text(s(SV.noReturns), key: const Key('chvat-no-returns')),
            )
          else ...<Widget>[
            SwissVatCard(
              title:
                  '${sel.periodLabel} · ${sel.accountingMethod == SwissVatMethod.saldosteuersatz ? s(SV.methodSss) : s(SV.methodEffective)}',
              children: <Widget>[
                SwissVatKeyValueRow(
                  s(SV.box200),
                  formatChf(sel.box200TotalTurnover, locale),
                  valueKey: const Key('chvat-box-200'),
                ),
                SwissVatKeyValueRow(
                  s(SV.box289),
                  formatChf(sel.box289TotalDeductions, locale),
                ),
                SwissVatKeyValueRow(
                  s(SV.box299),
                  formatChf(sel.box299TaxableTurnover, locale),
                ),
                SwissVatKeyValueRow(
                  s(SV.box399),
                  formatChf(sel.box399TotalOutputTax, locale),
                  valueKey: const Key('chvat-box-399'),
                ),
                SwissVatKeyValueRow(
                  s(SV.box479),
                  formatChf(sel.box479TotalInputTax, locale),
                  valueKey: const Key('chvat-box-479'),
                ),
                if (sel.forfeitedInputVat > 0)
                  SwissVatKeyValueRow(
                    s(SV.forfeitedInputVat),
                    formatChf(sel.forfeitedInputVat, locale),
                  ),
                const Divider(),
                SwissVatKeyValueRow(
                  sel.box510CreditAmount > 0
                      ? s(SV.balanceCredit)
                      : s(SV.balancePayable),
                  formatChf(
                    sel.box510CreditAmount > 0
                        ? sel.box510CreditAmount
                        : sel.box500PayableAmount,
                    locale,
                  ),
                  emphasis: true,
                  valueKey: const Key('chvat-balance'),
                ),
                const SizedBox(height: FfSpace.space2),
                Wrap(
                  spacing: FfSpace.space2,
                  runSpacing: FfSpace.space2,
                  children: <Widget>[
                    OutlinedButton.icon(
                      key: const Key('chvat-validate-xml'),
                      icon: const Icon(Icons.verified_outlined),
                      label: Text(s(SV.validateXml)),
                      onPressed: () async {
                        final SuisseTaxValidationResult? res = await ctrl
                            .validateSelectedXml();
                        if (context.mounted && res != null) {
                          _toast(
                            context,
                            res.valid
                                ? s(SV.quadPassed)
                                : res.errors.join(' · '),
                          );
                        }
                      },
                    ),
                    FilledButton.icon(
                      key: const Key('chvat-export-xml'),
                      icon: const Icon(Icons.ios_share),
                      label: Text(s(SV.exportXml)),
                      onPressed: () async {
                        final SwissVatXmlShareResult res = await ctrl
                            .exportAndShareXml();
                        if (context.mounted) {
                          _toast(
                            context,
                            res.failed
                                ? (res.error == null
                                      ? s(SV.shareFailed)
                                      : s.error(res.error!))
                                : '${s(SV.xmlShared)} (${res.fileName})',
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
            SwissVatCard(
              title: s(SV.quadraturaHeader),
              trailing: Chip(
                key: const Key('chvat-quad-badge'),
                label: Text(sel.quadraturaPassed ? 'PASS' : 'FAIL'),
              ),
              children: <Widget>[
                Text(
                  sel.quadraturaPassed ? s(SV.quadPassed) : s(SV.quadFailed),
                ),
                const SizedBox(height: FfSpace.space1),
                for (final QuadraturaCheck c in sel.quadraturaReport.checks)
                  SwissVatKeyValueRow(
                    '${c.code} (${c.severity})',
                    c.passed ? 'OK' : 'Δ ${c.difference}',
                    valueKey: Key('chvat-quad-${c.code}'),
                  ),
              ],
            ),
            if (sel.boxSchedule.isNotEmpty)
              SwissVatCard(
                title: s(SV.afcBoxesHeader),
                children: <Widget>[
                  for (final AfcBoxLine b in sel.boxSchedule)
                    SwissVatKeyValueRow(
                      'Box ${b.code}${b.label.isNotEmpty ? ' · ${b.label}' : ''}',
                      formatChf(b.amount, locale),
                      valueKey: Key('chvat-afc-${b.code}'),
                    ),
                ],
              ),
            if (state.exports.isNotEmpty)
              SwissVatCard(
                title: s(SV.exportsHeader),
                children: <Widget>[
                  for (final SuisseTaxXmlExport ex in state.exports)
                    SwissVatKeyValueRow(
                      ex.fileName,
                      ex.xsdValid ? 'XSD OK' : 'INVALID',
                      valueKey: Key('chvat-export-${ex.id}'),
                    ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}

// --- Tab 2: Bezugsteuer (Art. 45 LIVA) -----------------------------------------------------------------------------

class _BezugsteuerTab extends ConsumerStatefulWidget {
  const _BezugsteuerTab();

  @override
  ConsumerState<_BezugsteuerTab> createState() => _BezugsteuerTabState();
}

class _BezugsteuerTabState extends ConsumerState<_BezugsteuerTab> {
  final TextEditingController _supplierCtrl = TextEditingController();
  final TextEditingController _countryCtrl = TextEditingController(text: 'DE');
  final TextEditingController _netCtrl = TextEditingController(text: '1000');
  final TextEditingController _descCtrl = TextEditingController(
    text: 'Cloud SaaS subscription',
  );

  @override
  void dispose() {
    _supplierCtrl.dispose();
    _countryCtrl.dispose();
    _netCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SwissVatStrings s = _strings(ref);
    final String locale = _locale(ref);
    final SwissVatState state = ref.watch(swissVatProvider);
    final SwissVatController ctrl = ref.read(swissVatProvider.notifier);

    return ListView(
      key: const Key('chvat-bezugsteuer-list'),
      children: <Widget>[
        SwissVatCard(
          title: s(SV.addBezugsteuer),
          children: <Widget>[
            TextField(
              key: const Key('chvat-bez-supplier'),
              controller: _supplierCtrl,
              decoration: InputDecoration(labelText: s(SV.supplierName)),
            ),
            TextField(
              key: const Key('chvat-bez-country'),
              controller: _countryCtrl,
              decoration: InputDecoration(labelText: s(SV.countryCode)),
            ),
            TextField(
              key: const Key('chvat-bez-net'),
              controller: _netCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(labelText: s(SV.netAmountChf)),
            ),
            TextField(
              key: const Key('chvat-bez-desc'),
              controller: _descCtrl,
              decoration: InputDecoration(labelText: s(SV.description)),
            ),
            const SizedBox(height: FfSpace.space2),
            FilledButton(
              key: const Key('chvat-bez-submit'),
              onPressed: () async {
                final double net =
                    double.tryParse(_netCtrl.text.replaceAll(',', '.')) ?? 0;
                final BezugsteuerDraft draft = BezugsteuerDraft(
                  supplierName: _supplierCtrl.text,
                  supplierCountry: _countryCtrl.text,
                  invoiceDate: DateTime(state.year, 2, 15),
                  description: _descCtrl.text,
                  netAmountChf: net,
                );
                if (draft.validate() == 'domestic_forbidden') {
                  _toast(context, s(SV.domesticForbidden));
                  return;
                }
                final SwissVatActionOutcome out = await ctrl.createBezugsteuer(
                  draft,
                );
                if (context.mounted) {
                  _toast(
                    context,
                    out.status == SwissVatActionStatus.rejected
                        ? s(SV.actionRejected)
                        : (out.status == SwissVatActionStatus.sent
                              ? s(SV.savedOk)
                              : s(SV.queuedOffline)),
                  );
                }
              },
              child: Text(s(SV.addBezugsteuer)),
            ),
          ],
        ),
        if (state.bezugsteuer.isEmpty)
          Padding(
            padding: const EdgeInsets.all(FfSpace.space4),
            child: Text(s(SV.noBezugsteuer), key: const Key('chvat-bez-empty')),
          )
        else
          for (final BezugsteuerEntry b in state.bezugsteuer)
            SwissVatCard(
              key: Key('chvat-bez-${b.id}'),
              title: '${b.supplierName} (${b.supplierCountry})',
              trailing: Text(b.status.wire),
              children: <Widget>[
                Text(b.description),
                SwissVatKeyValueRow(
                  s(SV.netAmountChf),
                  formatChf(b.netAmountChf, locale),
                ),
                SwissVatKeyValueRow(
                  'MWST (${b.afcBox})',
                  formatChf(b.taxAmountChf, locale),
                ),
                if (b.status == BezugsteuerStatus.detected)
                  Row(
                    children: <Widget>[
                      TextButton(
                        key: Key('chvat-bez-confirm-${b.id}'),
                        onPressed: () => ctrl.confirmBezugsteuer(b.id),
                        child: Text(s(SV.confirmAction)),
                      ),
                      TextButton(
                        key: Key('chvat-bez-exclude-${b.id}'),
                        onPressed: () => ctrl.excludeBezugsteuer(b.id),
                        child: Text(s(SV.excludeAction)),
                      ),
                    ],
                  ),
              ],
            ),
      ],
    );
  }
}

// --- Tab 3: Input Tax Adjustments (Art. 30-33 LIVA) ----------------------------------------------------------------

class _AdjustmentsTab extends ConsumerStatefulWidget {
  const _AdjustmentsTab();

  @override
  ConsumerState<_AdjustmentsTab> createState() => _AdjustmentsTabState();
}

class _AdjustmentsTabState extends ConsumerState<_AdjustmentsTab> {
  InputTaxAdjustmentType _type = InputTaxAdjustmentType.autoconsumo;
  bool _realEstate = false;
  final TextEditingController _descCtrl = TextEditingController(
    text: 'Equipment withdrawal',
  );
  final TextEditingController _costCtrl = TextEditingController(text: '10000');
  final TextEditingController _yearsCtrl = TextEditingController(text: '1');

  @override
  void dispose() {
    _descCtrl.dispose();
    _costCtrl.dispose();
    _yearsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SwissVatStrings s = _strings(ref);
    final String locale = _locale(ref);
    final SwissVatState state = ref.watch(swissVatProvider);
    final SwissVatController ctrl = ref.read(swissVatProvider.notifier);

    return ListView(
      key: const Key('chvat-adjustments-list'),
      children: <Widget>[
        SwissVatCard(
          title: s(SV.addAdjustment),
          children: <Widget>[
            DropdownButton<InputTaxAdjustmentType>(
              key: const Key('chvat-adj-type'),
              isExpanded: true,
              value: _type,
              items: <DropdownMenuItem<InputTaxAdjustmentType>>[
                for (final InputTaxAdjustmentType t
                    in InputTaxAdjustmentType.values)
                  DropdownMenuItem<InputTaxAdjustmentType>(
                    value: t,
                    child: Text(s.adjustmentLabel(t)),
                  ),
              ],
              onChanged: (InputTaxAdjustmentType? t) {
                if (t != null) {
                  setState(() => _type = t);
                }
              },
            ),
            TextField(
              key: const Key('chvat-adj-desc'),
              controller: _descCtrl,
              decoration: InputDecoration(labelText: s(SV.description)),
            ),
            TextField(
              key: const Key('chvat-adj-cost'),
              controller: _costCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(labelText: s(SV.originalCostChf)),
            ),
            TextField(
              key: const Key('chvat-adj-years'),
              controller: _yearsCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: s(SV.yearsElapsed)),
            ),
            CheckboxListTile(
              key: const Key('chvat-adj-realestate'),
              contentPadding: EdgeInsets.zero,
              title: Text(s(SV.realEstateAsset)),
              value: _realEstate,
              onChanged: (bool? v) => setState(() => _realEstate = v == true),
            ),
            FilledButton(
              key: const Key('chvat-adj-submit'),
              onPressed: () async {
                final double cost =
                    double.tryParse(_costCtrl.text.replaceAll(',', '.')) ?? 0;
                final int years = int.tryParse(_yearsCtrl.text) ?? 0;
                final InputTaxAdjustmentDraft draft = InputTaxAdjustmentDraft(
                  adjustmentType: _type,
                  effectiveDate: DateTime(state.year, 3, 31),
                  description: _descCtrl.text,
                  originalCostChf: cost,
                  yearsElapsed: years,
                  isRealEstate: _realEstate,
                );
                final SwissVatActionOutcome out = await ctrl.createAdjustment(
                  draft,
                );
                if (context.mounted) {
                  _toast(
                    context,
                    out.status == SwissVatActionStatus.sent
                        ? s(SV.savedOk)
                        : s(SV.queuedOffline),
                  );
                }
              },
              child: Text(s(SV.addAdjustment)),
            ),
          ],
        ),
        if (state.adjustments.isEmpty)
          Padding(
            padding: const EdgeInsets.all(FfSpace.space4),
            child: Text(
              s(SV.noAdjustments),
              key: const Key('chvat-adj-empty'),
            ),
          )
        else
          for (final InputTaxAdjustment a in state.adjustments)
            SwissVatCard(
              key: Key('chvat-adj-${a.id}'),
              title: '${s.adjustmentLabel(a.adjustmentType)} · Box ${a.afcBox}',
              trailing: Text(a.status),
              children: <Widget>[
                Text(a.description),
                SwissVatKeyValueRow(
                  a.legalBasis,
                  formatChf(a.adjustmentAmountChf, locale),
                ),
                if (a.status == 'draft')
                  TextButton(
                    key: Key('chvat-adj-approve-${a.id}'),
                    onPressed: () => ctrl.approveAdjustment(a.id),
                    child: Text(s(SV.approveAction)),
                  ),
              ],
            ),
      ],
    );
  }
}

// --- Tab 4: Regime & Tax Codes -------------------------------------------------------------------------------------

class _ConfigTab extends ConsumerStatefulWidget {
  const _ConfigTab();

  @override
  ConsumerState<_ConfigTab> createState() => _ConfigTabState();
}

class _ConfigTabState extends ConsumerState<_ConfigTab> {
  final TextEditingController _uidCtrl = TextEditingController(
    text: 'CHE-116.281.710 MWST',
  );
  SwissVatMethod _method = SwissVatMethod.effective;
  SwissVatFrequency _freq = SwissVatFrequency.quarterly;
  bool _initialized = false;

  @override
  void dispose() {
    _uidCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SwissVatStrings s = _strings(ref);
    final SwissVatState state = ref.watch(swissVatProvider);
    final SwissVatController ctrl = ref.read(swissVatProvider.notifier);

    final SwissVatConfig? cfg = state.config;
    if (!_initialized && cfg != null) {
      _initialized = true;
      _uidCtrl.text = cfg.uidMwst ?? '';
      _method = cfg.accountingMethod;
      _freq = cfg.reportingFrequency;
    }

    return ListView(
      key: const Key('chvat-config-list'),
      children: <Widget>[
        SwissVatCard(
          title: s(SV.tabConfig),
          children: <Widget>[
            TextField(
              key: const Key('chvat-cfg-uid'),
              controller: _uidCtrl,
              decoration: InputDecoration(labelText: s(SV.uidMwst)),
            ),
            const SizedBox(height: FfSpace.space2),
            DropdownButton<SwissVatMethod>(
              key: const Key('chvat-cfg-method'),
              isExpanded: true,
              value: _method,
              items: <DropdownMenuItem<SwissVatMethod>>[
                DropdownMenuItem<SwissVatMethod>(
                  value: SwissVatMethod.effective,
                  child: Text(s(SV.methodEffective)),
                ),
                DropdownMenuItem<SwissVatMethod>(
                  value: SwissVatMethod.saldosteuersatz,
                  child: Text(s(SV.methodSss)),
                ),
              ],
              onChanged: (SwissVatMethod? v) {
                if (v != null) {
                  setState(() => _method = v);
                }
              },
            ),
            DropdownButton<SwissVatFrequency>(
              key: const Key('chvat-cfg-freq'),
              isExpanded: true,
              value: _freq,
              items: <DropdownMenuItem<SwissVatFrequency>>[
                DropdownMenuItem<SwissVatFrequency>(
                  value: SwissVatFrequency.quarterly,
                  child: Text(s(SV.freqQuarterly)),
                ),
                DropdownMenuItem<SwissVatFrequency>(
                  value: SwissVatFrequency.semiannual,
                  child: Text(s(SV.freqSemiannual)),
                ),
                DropdownMenuItem<SwissVatFrequency>(
                  value: SwissVatFrequency.monthly,
                  child: Text(s(SV.freqMonthly)),
                ),
              ],
              onChanged: (SwissVatFrequency? v) {
                if (v != null) {
                  setState(() => _freq = v);
                }
              },
            ),
            const SizedBox(height: FfSpace.space2),
            FilledButton(
              key: const Key('chvat-cfg-save'),
              onPressed: () async {
                if (!SwissVatDomain.isValidUidMwst(_uidCtrl.text)) {
                  _toast(context, s(SV.uidInvalid));
                  return;
                }
                final SwissVatConfig next = SwissVatConfig(
                  id: cfg?.id ?? '',
                  uidMwst: SwissVatDomain.normalizeUid(_uidCtrl.text),
                  accountingMethod: _method,
                  considerationBasis:
                      cfg?.considerationBasis ??
                      SwissVatConsiderationBasis.agreed,
                  reportingFrequency: _freq,
                  sssRatePrimary: _method == SwissVatMethod.saldosteuersatz
                      ? (cfg?.sssRatePrimary ?? '6.20')
                      : null,
                );
                final SwissVatActionOutcome out = await ctrl.saveConfig(next);
                if (context.mounted) {
                  _toast(
                    context,
                    out.status == SwissVatActionStatus.sent
                        ? s(SV.savedOk)
                        : s(SV.queuedOffline),
                  );
                }
              },
              child: Text(s(SV.saveConfig)),
            ),
          ],
        ),
        if (state.taxCodes.isNotEmpty)
          SwissVatCard(
            title: s(SV.taxCodesHeader),
            children: <Widget>[
              for (final SwissVatTaxCode c in state.taxCodes)
                SwissVatKeyValueRow(
                  '${c.code} · ${c.name}',
                  '${c.ratePercent}% (Box ${c.afcBox})',
                  valueKey: Key('chvat-taxcode-${c.code}'),
                ),
            ],
          ),
      ],
    );
  }
}
