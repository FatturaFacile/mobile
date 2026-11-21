import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/manufacturing_models.dart';
import '../providers/manufacturing_providers.dart';
import '../widgets/mfg_labels.dart';
import 'routing_detail_screen.dart';

/// Mod 061 hub: routings (with steps), machines and OEE, all read from the local SQLite mirror.
class ManufacturingHubScreen extends ConsumerStatefulWidget {
  const ManufacturingHubScreen({
    required this.tenantId,
    this.autoSync = true,
    super.key,
  });

  final String tenantId;

  /// Pulls fresh data on open when the device is online.
  final bool autoSync;

  @override
  ConsumerState<ManufacturingHubScreen> createState() =>
      _ManufacturingHubScreenState();
}

class _ManufacturingHubScreenState
    extends ConsumerState<ManufacturingHubScreen> {
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoSync) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && (ref.read(connectivityProvider).value ?? true)) {
          _sync(silent: true);
        }
      });
    }
  }

  Future<void> _sync({bool silent = false}) async {
    setState(() => _syncing = true);
    final bool failed =
        (await ref.read(manufacturingRepositoryProvider).sync(widget.tenantId))
            .isLeft();
    if (!mounted) {
      return;
    }
    setState(() => _syncing = false);
    if (failed && !silent) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).mfgSyncFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.mfgHubTitle),
          actions: <Widget>[
            if (_syncing)
              const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              IconButton(
                key: const Key('mfg-sync'),
                tooltip: l10n.mfgSyncAction,
                icon: const Icon(Icons.sync),
                onPressed: _sync,
              ),
          ],
          bottom: TabBar(
            tabs: <Widget>[
              Tab(
                key: const Key('mfg-tab-routings'),
                text: l10n.mfgTabRoutings,
              ),
              Tab(
                key: const Key('mfg-tab-machines'),
                text: l10n.mfgTabMachines,
              ),
              Tab(key: const Key('mfg-tab-oee'), text: l10n.mfgTabOee),
            ],
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            _RoutingsTab(tenantId: widget.tenantId),
            _MachinesTab(tenantId: widget.tenantId),
            _OeeTab(tenantId: widget.tenantId),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Center(child: Text(text));
}

class _RoutingsTab extends ConsumerWidget {
  const _RoutingsTab({required this.tenantId});

  final String tenantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final List<MfgRouting> routings =
        ref.watch(mfgRoutingsProvider(tenantId)).value ?? <MfgRouting>[];
    if (routings.isEmpty) {
      return _Empty(l10n.mfgEmptyRoutings);
    }
    return ListView.builder(
      key: const Key('mfg-routings-list'),
      itemCount: routings.length,
      itemBuilder: (BuildContext context, int i) {
        final MfgRouting r = routings[i];
        return ListTile(
          key: Key('mfg-routing-${r.id}'),
          title: Text('${r.routingNumber} · ${r.name}'),
          subtitle: Text(
            '${l10n.mfgRevisionLabel(r.revision)} · ${l10n.mfgStepsCount(r.steps.length)}'
            '${r.itemCode == null ? '' : ' · ${r.itemCode}'}',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  RoutingDetailScreen(tenantId: tenantId, routing: r),
            ),
          ),
        );
      },
    );
  }
}

class _MachinesTab extends ConsumerWidget {
  const _MachinesTab({required this.tenantId});

  final String tenantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final List<MfgMachine> machines =
        ref.watch(mfgMachinesProvider(tenantId)).value ?? <MfgMachine>[];
    final Map<String, MfgWorkCenter> centers = <String, MfgWorkCenter>{
      for (final MfgWorkCenter w
          in ref.watch(mfgWorkCentersProvider(tenantId)).value ??
              <MfgWorkCenter>[])
        w.id: w,
    };
    if (machines.isEmpty) {
      return _Empty(l10n.mfgEmptyMachines);
    }
    return ListView.builder(
      key: const Key('mfg-machines-list'),
      itemCount: machines.length,
      itemBuilder: (BuildContext context, int i) {
        final MfgMachine m = machines[i];
        final MfgWorkCenter? wc = centers[m.workCenterId];
        return ListTile(
          key: Key('mfg-machine-${m.id}'),
          title: Text('${m.code} · ${m.name}'),
          subtitle: Text(
            <String>[
              if (wc != null) l10n.mfgWorkCenterLabel(wc.code),
              l10n.mfgMachineStatus(m.status),
              if (m.idealCycleTimeSecondsPerUnit > 0)
                l10n.mfgIdealCycle(
                  MfgLabels.number(context, m.idealCycleTimeSecondsPerUnit),
                ),
              if (m.industria40) l10n.mfgIndustria40,
              if (m.transizione50) l10n.mfgTransizione50,
            ].join(' · '),
          ),
          trailing: m.industria40 || m.transizione50
              ? Chip(label: Text(MfgLabels.telemetry(l10n, m.telemetryStatus)))
              : null,
        );
      },
    );
  }
}

class _OeeTab extends ConsumerWidget {
  const _OeeTab({required this.tenantId});

  final String tenantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final List<MfgOeeSummary> summaries =
        ref.watch(mfgOeeProvider(tenantId)).value ?? <MfgOeeSummary>[];
    final Map<String, MfgWorkCenter> centers = <String, MfgWorkCenter>{
      for (final MfgWorkCenter w
          in ref.watch(mfgWorkCentersProvider(tenantId)).value ??
              <MfgWorkCenter>[])
        w.id: w,
    };
    if (summaries.isEmpty) {
      return _Empty(l10n.mfgEmptyOee);
    }
    final String locale = Localizations.localeOf(context).languageCode;
    final DateFormat date = DateFormat.yMMMd(locale);
    final ThemeData theme = Theme.of(context);
    return ListView.builder(
      key: const Key('mfg-oee-list'),
      itemCount: summaries.length,
      itemBuilder: (BuildContext context, int i) {
        final MfgOeeSummary s = summaries[i];
        final MfgWorkCenter? wc = centers[s.workCenterId];
        final MfgOeeMetrics m = s.metrics;
        return Card(
          key: Key('mfg-oee-${s.workCenterId}'),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  wc == null ? s.workCenterId : '${wc.code} · ${wc.name}',
                  style: theme.textTheme.titleMedium,
                ),
                Text(
                  l10n.mfgOeePeriod(
                    date.format(s.from.toLocal()),
                    date.format(s.to.toLocal()),
                  ),
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.mfgOeeValue(MfgLabels.number(context, m.oeePercent)),
                  key: Key('mfg-oee-value-${s.workCenterId}'),
                  style: theme.textTheme.headlineSmall,
                ),
                Text(
                  s.meetsTarget
                      ? l10n.mfgOeeMeetsTarget
                      : l10n.mfgOeeBelowTarget(
                          MfgLabels.number(context, s.gapToTargetPercent.abs()),
                        ),
                  style: TextStyle(
                    color: s.meetsTarget
                        ? theme.colorScheme.primary
                        : theme.colorScheme.error,
                  ),
                ),
                Text(
                  l10n.mfgOeeTarget(
                    MfgLabels.number(context, s.targetOeePercent),
                  ),
                ),
                const SizedBox(height: 8),
                _factor(context, l10n.mfgAvailability, m.availabilityPercent),
                _factor(context, l10n.mfgPerformance, m.performancePercent),
                _factor(context, l10n.mfgQuality, m.qualityPercent),
                const SizedBox(height: 8),
                Text(
                  '${l10n.mfgGoodUnits}: ${MfgLabels.number(context, m.goodUnits)} · '
                  '${l10n.mfgScrapUnits}: ${MfgLabels.number(context, m.scrapUnits)} · '
                  '${l10n.mfgReworkUnits}: ${MfgLabels.number(context, m.reworkUnits)}',
                  style: theme.textTheme.bodySmall,
                ),
                if (s.losses.values.any((double v) => v > 0)) ...<Widget>[
                  const SizedBox(height: 8),
                  Text(l10n.mfgLossesTitle, style: theme.textTheme.labelLarge),
                  for (final MapEntry<String, double> e in s.losses.entries)
                    if (e.value > 0)
                      Text(
                        '${MfgLabels.loss(l10n, e.key)}: ${MfgLabels.number(context, e.value)}',
                        style: theme.textTheme.bodySmall,
                      ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _factor(BuildContext context, String label, double percent) {
    return Row(
      children: <Widget>[
        Expanded(child: Text(label)),
        Text('${MfgLabels.number(context, percent)}%'),
      ],
    );
  }
}
