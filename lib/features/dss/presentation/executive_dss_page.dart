import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../design/ff_tokens.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../domain/dss_models.dart';
import '../domain/dss_repository.dart';
import 'dss_controller.dart';
import 'dss_format.dart';
import 'dss_pulse.dart';
import 'dss_sheets.dart';

/// Executive Pulse & DSS Command View: the board's figures, readable offline from the last synced snapshot.
class ExecutiveDssPage extends ConsumerStatefulWidget {
  const ExecutiveDssPage({super.key});

  @override
  ConsumerState<ExecutiveDssPage> createState() => _ExecutiveDssPageState();
}

class _ExecutiveDssPageState extends ConsumerState<ExecutiveDssPage> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(dssControllerProvider.notifier).open(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DssState state = ref.watch(dssControllerProvider);
    final DssController controller = ref.read(dssControllerProvider.notifier);
    final String lang = Localizations.localeOf(context).languageCode;
    final DssSnapshot? snapshot = state.snapshot;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.dssTitle),
        bottom: state.syncing
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(minHeight: 2),
              )
            : null,
      ),
      floatingActionButton: snapshot == null
          ? null
          : FloatingActionButton.extended(
              key: const Key('dss-whatif-open'),
              onPressed: () => showDssWhatIfSheet(context, snapshot, lang),
              icon: const Icon(Icons.tune),
              label: Text(l.dssWhatIfTitle),
            ),
      body: RefreshIndicator(
        onRefresh: controller.refresh,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                FfSpace.space4,
                FfSpace.space3,
                FfSpace.space4,
                96,
              ),
              children: <Widget>[
                _FilterHeader(state: state, controller: controller),
                const SizedBox(height: FfSpace.space3),
                _Notice(status: state.lastSync),
                if (state.loading)
                  const Padding(
                    padding: EdgeInsets.all(FfSpace.space5),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (snapshot == null)
                  _Empty(title: l.dssNoData, body: l.dssNoDataBody)
                else
                  ..._content(context, l, snapshot, lang),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _content(
    BuildContext context,
    AppLocalizations l,
    DssSnapshot snapshot,
    String lang,
  ) {
    final DssProfitability? products = snapshot.products;
    final DssVarianceSummary? variance = snapshot.variance;
    return <Widget>[
      DssPulseGrid(overview: snapshot.overview, languageCode: lang),
      const SizedBox(height: FfSpace.space4),
      _Title(l.dssAlertsTitle),
      if (snapshot.overview.alerts.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: FfSpace.space2),
          child: Text(l.dssNoAlerts, key: const Key('dss-no-alerts')),
        )
      else
        for (final DssAlert alert in snapshot.overview.alerts)
          _AlertTile(alert: alert, languageCode: lang),
      if (variance != null) ...<Widget>[
        const SizedBox(height: FfSpace.space4),
        _Title(l.dssVarianceTitle),
        _VarianceCard(
          variance: variance,
          currency: snapshot.overview.currency,
          languageCode: lang,
        ),
      ],
      const SizedBox(height: FfSpace.space4),
      _ProfitList(
        title: l.dssTopCustomers,
        rows: snapshot.customers.top(5),
        languageCode: lang,
        prefix: 'top-customer',
      ),
      _ProfitList(
        title: l.dssBottomCustomers,
        rows: snapshot.customers.bottom(5),
        languageCode: lang,
        prefix: 'bottom-customer',
      ),
      if (products != null) ...<Widget>[
        _ProfitList(
          title: l.dssTopProducts,
          rows: products.top(5),
          languageCode: lang,
          prefix: 'top-product',
        ),
        _ProfitList(
          title: l.dssBottomProducts,
          rows: products.bottom(5),
          languageCode: lang,
          prefix: 'bottom-product',
        ),
      ],
    ];
  }
}

class _FilterHeader extends StatelessWidget {
  const _FilterHeader({required this.state, required this.controller});

  final DssState state;
  final DssController controller;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final FfColors c =
        Theme.of(context).extension<FfColors>() ?? FfColors.light;
    final List<DssLegalEntity> entities =
        state.snapshot?.legalEntities ?? const <DssLegalEntity>[];
    final DateTime? syncedAt = state.snapshot?.syncedAt;
    final String pill = syncedAt == null
        ? l.dssNeverSynced
        : state.offline
        ? l.dssOfflineSince(DssFormat.time(syncedAt))
        : l.dssSyncedAt(DssFormat.time(syncedAt));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: FfSpace.space2,
          runSpacing: FfSpace.space2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            if (entities.isNotEmpty)
              DropdownButton<String>(
                key: const Key('dss-entity'),
                value:
                    entities.any(
                      (DssLegalEntity e) => e.id == state.filter.legalEntityId,
                    )
                    ? state.filter.legalEntityId
                    : '',
                onChanged: (String? id) => controller.setLegalEntity(id ?? ''),
                items: <DropdownMenuItem<String>>[
                  DropdownMenuItem<String>(
                    value: '',
                    child: Text(l.dssAllEntities),
                  ),
                  for (final DssLegalEntity e in entities)
                    DropdownMenuItem<String>(value: e.id, child: Text(e.name)),
                ],
              ),
            SegmentedButton<String>(
              key: const Key('dss-currency'),
              showSelectedIcon: false,
              segments: <ButtonSegment<String>>[
                for (final String currency in DssFilter.currencies)
                  ButtonSegment<String>(
                    value: currency,
                    label: Text(currency, key: Key('dss-currency-$currency')),
                  ),
              ],
              selected: <String>{state.filter.currency},
              onSelectionChanged: (Set<String> s) =>
                  controller.setCurrency(s.first),
            ),
          ],
        ),
        const SizedBox(height: FfSpace.space2),
        Wrap(
          spacing: FfSpace.space2,
          runSpacing: FfSpace.space1,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            for (final String period in DssFilter.periods)
              ChoiceChip(
                key: Key('dss-period-$period'),
                label: Text(DssFormat.periodLabel(l, period)),
                selected: state.filter.periodPreset == period,
                onSelected: (_) => controller.setPeriod(period),
              ),
            Container(
              key: const Key('dss-sync-pill'),
              padding: const EdgeInsets.symmetric(
                horizontal: FfSpace.space2,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: state.offline ? c.warningBg : c.neutralBg,
                borderRadius: BorderRadius.circular(FfRadius.lg),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    state.offline ? Icons.cloud_off : Icons.cloud_done_outlined,
                    size: 14,
                    color: state.offline ? c.warning : c.textMuted,
                  ),
                  const SizedBox(width: FfSpace.space1),
                  Text(pill, style: const TextStyle(fontSize: FfFont.xs)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.status});

  final DssSyncStatus? status;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final FfColors c =
        Theme.of(context).extension<FfColors>() ?? FfColors.light;
    final String? text = switch (status) {
      DssSyncStatus.unauthorized => l.dssErrUnauthorized,
      DssSyncStatus.forbidden => l.dssErrForbidden,
      DssSyncStatus.failed => l.dssErrFailed,
      _ => null,
    };
    if (text == null) {
      return const SizedBox.shrink();
    }
    return Container(
      key: const Key('dss-notice'),
      margin: const EdgeInsets.only(bottom: FfSpace.space3),
      padding: const EdgeInsets.all(FfSpace.space3),
      decoration: BoxDecoration(
        color: c.dangerBg,
        borderRadius: BorderRadius.circular(FfRadius.md),
      ),
      child: Text(text, style: TextStyle(color: c.danger)),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const Key('dss-empty'),
      padding: const EdgeInsets.all(FfSpace.space5),
      child: Column(
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              fontSize: FfFont.lg,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: FfSpace.space2),
          Text(body, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: FfSpace.space2),
    child: Text(
      text,
      style: const TextStyle(fontSize: FfFont.md, fontWeight: FontWeight.w600),
    ),
  );
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.alert, required this.languageCode});

  final DssAlert alert;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final FfColors c =
        Theme.of(context).extension<FfColors>() ?? FfColors.light;
    final Color color = dssSeverityColor(c, alert.severity);
    return Card(
      margin: const EdgeInsets.only(bottom: FfSpace.space2),
      child: ListTile(
        key: Key('dss-alert-${alert.code}-${alert.metric}'),
        leading: Icon(Icons.warning_amber_rounded, color: color),
        title: Text(DssFormat.alertTitle(l, alert.code)),
        subtitle: Text(DssFormat.alertSummary(l, alert, languageCode)),
        trailing: Text(
          DssFormat.severityLabel(l, alert.severity),
          style: TextStyle(color: color, fontSize: FfFont.xs),
        ),
        onTap: () => showDssAlertSheet(context, alert, languageCode),
      ),
    );
  }
}

class _VarianceCard extends StatelessWidget {
  const _VarianceCard({
    required this.variance,
    required this.currency,
    required this.languageCode,
  });

  final DssVarianceSummary variance;
  final String currency;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final FfColors c =
        Theme.of(context).extension<FfColors>() ?? FfColors.light;
    Widget line(String label, double value, {bool effect = true}) {
      final Color? color = !effect
          ? null
          : value > 0
          ? c.success
          : value < 0
          ? c.danger
          : null;
      final String text = DssFormat.compactAmount(
        value,
        currency,
        languageCode,
      );
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: <Widget>[
            Expanded(child: Text(label)),
            Text(
              effect && value > 0 ? '+$text' : text,
              style: TextStyle(color: color, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(FfSpace.space3),
        child: Column(
          key: const Key('dss-variance'),
          children: <Widget>[
            line(l.dssVarBaseline, variance.baseline, effect: false),
            line(l.dssVarVolume, variance.volume),
            line(l.dssVarPrice, variance.price),
            line(l.dssVarCogs, variance.cogs),
            line(l.dssVarOpex, variance.opex),
            line(l.dssVarFx, variance.fx),
            const Divider(),
            line(l.dssVarActual, variance.actual, effect: false),
          ],
        ),
      ),
    );
  }
}

class _ProfitList extends StatelessWidget {
  const _ProfitList({
    required this.title,
    required this.rows,
    required this.languageCode,
    required this.prefix,
  });

  final String title;
  final List<DssProfitRow> rows;
  final String languageCode;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }
    final AppLocalizations l = AppLocalizations.of(context);
    final FfColors c =
        Theme.of(context).extension<FfColors>() ?? FfColors.light;
    return Padding(
      padding: const EdgeInsets.only(bottom: FfSpace.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _Title(title),
          Card(
            child: Column(
              children: <Widget>[
                for (final DssProfitRow row in rows)
                  ListTile(
                    key: Key('dss-$prefix-${row.key}'),
                    dense: true,
                    title: Text(row.label, overflow: TextOverflow.ellipsis),
                    subtitle: row.isValueDestroying
                        ? Text(
                            l.dssValueDestroying,
                            style: TextStyle(color: c.danger),
                          )
                        : row.inParetoCore
                        ? Text(l.dssParetoCore)
                        : null,
                    trailing: Text(
                      '${l.dssNetMargin} ${DssFormat.percent(row.netMarginPct, languageCode)}',
                      style: TextStyle(
                        color: row.netMarginPct < 0 ? c.danger : c.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
