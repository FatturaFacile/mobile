import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../design/ff_tokens.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../data/shop_floor_repository.dart';
import '../domain/shop_floor_models.dart';
import 'qc_checklist_page.dart';
import 'shop_floor_providers.dart';
import 'terminal_widgets.dart';

final _operationProvider =
    StreamProvider.family<OperationState, (String, String)>(
      (Ref ref, (String, String) key) =>
          ref.watch(shopFloorRepositoryProvider).watchOperation(key.$1, key.$2),
    );

/// Touch terminal of one operation: big start/pause buttons for setup and run, good and scrap counters and the final
/// confirmation. Every state change is written to SQLite immediately, so a restart or a dead battery loses nothing.
class OperationTerminalPage extends ConsumerStatefulWidget {
  const OperationTerminalPage({
    required this.tenantId,
    required this.orderId,
    required this.operationId,
    this.userId,
    super.key,
  });

  final String tenantId;
  final String orderId;
  final String operationId;
  final String? userId;

  @override
  ConsumerState<OperationTerminalPage> createState() =>
      _OperationTerminalPageState();
}

class _OperationTerminalPageState extends ConsumerState<OperationTerminalPage> {
  Timer? _ticker;
  bool _final = false;
  final TextEditingController _reason = TextEditingController();
  bool _reasonLoaded = false;

  ShopFloorRepository get _repo => ref.read(shopFloorRepositoryProvider);

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    try {
      await action();
    } on ShopFloorException catch (e) {
      if (mounted) {
        showTerminalMessage(context, shopFloorErrorText(l10n, e.error));
      }
    }
  }

  Future<void> _count(OperationState s, {double good = 0, double scrap = 0}) {
    final double g = (s.counters.good + good).clamp(0, 1e9);
    final double sc = (s.counters.scrap + scrap).clamp(0, 1e9);
    return _run(
      () => _repo.setCounters(
        widget.tenantId,
        widget.orderId,
        widget.operationId,
        good: g,
        scrap: sc,
        scrapReason: _reason.text,
      ),
    );
  }

  Future<void> _confirm(OperationState s) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    await _run(() async {
      await _repo.setCounters(
        widget.tenantId,
        widget.orderId,
        widget.operationId,
        good: s.counters.good,
        scrap: s.counters.scrap,
        scrapReason: _reason.text,
      );
      await _repo.confirm(
        tenantId: widget.tenantId,
        orderId: widget.orderId,
        operationId: widget.operationId,
        isFinal: _final,
      );
      _reason.clear();
      if (mounted) {
        setState(() => _final = false);
        showTerminalMessage(context, l10n.mfgConfirmQueued);
        ref.read(shopFloorSyncProvider).syncNow(widget.tenantId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final OperationState s =
        ref
            .watch(_operationProvider((widget.tenantId, widget.operationId)))
            .value ??
        const OperationState();
    if (!_reasonLoaded && (s.counters.scrapReason ?? '').isNotEmpty) {
      _reason.text = s.counters.scrapReason!;
      _reasonLoaded = true;
    }
    final ProductionOrder? order = ref
        .watch(shopFloorOrdersProvider(widget.tenantId))
        .value
        ?.where((ProductionOrder o) => o.id == widget.orderId)
        .firstOrNull;
    final OrderOperation? op = order?.operations
        .where((OrderOperation o) => o.id == widget.operationId)
        .firstOrNull;
    final OperationTimer live = s.timer.snapshot(DateTime.now().toUtc());
    final FfColors colors = FfColors.dark;
    final String phase = switch (s.timer.phase) {
      TerminalPhase.idle => l10n.mfgPhaseIdle,
      TerminalPhase.setup => l10n.mfgPhaseSetup,
      TerminalPhase.run => l10n.mfgPhaseRun,
      TerminalPhase.paused => l10n.mfgPhasePaused,
    };
    return TerminalTheme(
      child: Builder(
        builder: (BuildContext context) => Scaffold(
          appBar: AppBar(
            title: Text(
              op == null
                  ? ''
                  : '${order?.orderNumber ?? ''} · ${op.sequence} ${op.name}',
            ),
            actions: <Widget>[
              IconButton(
                key: const Key('mfg-qc'),
                tooltip: l10n.mfgQcTitle,
                icon: const Icon(Icons.fact_check),
                onPressed: order == null || op == null
                    ? null
                    : () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => QcChecklistPage(
                            tenantId: widget.tenantId,
                            order: order,
                            operation: op,
                          ),
                        ),
                      ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(FfSpace.space4),
            children: <Widget>[
              SyncStrip(tenantId: widget.tenantId),
              const SizedBox(height: FfSpace.space4),
              Container(
                padding: const EdgeInsets.all(FfSpace.space4),
                decoration: BoxDecoration(
                  color: colors.surfaceRaised,
                  border: Border.all(
                    color: s.timer.running ? colors.success : colors.border,
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(FfRadius.lg),
                ),
                child: Column(
                  children: <Widget>[
                    Text(
                      phase,
                      key: const Key('mfg-phase'),
                      style: TextStyle(
                        fontSize: FfFont.size2xl,
                        fontWeight: FontWeight.w800,
                        color: s.timer.running ? colors.success : colors.text,
                      ),
                    ),
                    const SizedBox(height: FfSpace.space2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        _Clock(
                          label: l10n.mfgSetup,
                          seconds: live.setupSeconds,
                          keyName: 'mfg-clock-setup',
                        ),
                        _Clock(
                          label: l10n.mfgRun,
                          seconds: live.runSeconds,
                          keyName: 'mfg-clock-run',
                        ),
                        _Clock(
                          label: l10n.mfgDowntime,
                          seconds: live.downtimeSeconds,
                          keyName: 'mfg-clock-down',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: FfSpace.space4),
              Row(
                children: <Widget>[
                  Expanded(
                    child: FilledButton(
                      key: const Key('mfg-start-setup'),
                      onPressed: s.timer.phase == TerminalPhase.setup
                          ? null
                          : () => _run(
                              () => _repo.startSetup(
                                widget.tenantId,
                                widget.orderId,
                                widget.operationId,
                              ),
                            ),
                      child: Text(l10n.mfgStartSetup),
                    ),
                  ),
                  const SizedBox(width: FfSpace.space3),
                  Expanded(
                    child: FilledButton(
                      key: const Key('mfg-start-run'),
                      onPressed: s.timer.phase == TerminalPhase.run
                          ? null
                          : () => _run(
                              () => _repo.startRun(
                                widget.tenantId,
                                widget.orderId,
                                widget.operationId,
                              ),
                            ),
                      child: Text(l10n.mfgStartRun),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: FfSpace.space3),
              if (s.timer.phase == TerminalPhase.paused)
                OutlinedButton(
                  key: const Key('mfg-resume'),
                  onPressed: () => _run(
                    () => _repo.resume(
                      widget.tenantId,
                      widget.orderId,
                      widget.operationId,
                    ),
                  ),
                  child: Text(l10n.mfgResume),
                )
              else
                OutlinedButton(
                  key: const Key('mfg-pause'),
                  onPressed: s.timer.running
                      ? () => _run(
                          () => _repo.pause(
                            widget.tenantId,
                            widget.orderId,
                            widget.operationId,
                          ),
                        )
                      : null,
                  child: Text(l10n.mfgPause),
                ),
              const SizedBox(height: FfSpace.space5),
              _Counter(
                keyName: 'good',
                label: l10n.mfgGood,
                value: s.counters.good,
                color: colors.success,
                onChange: (double d) => _count(s, good: d),
              ),
              const SizedBox(height: FfSpace.space3),
              _Counter(
                keyName: 'scrap',
                label: l10n.mfgScrap,
                value: s.counters.scrap,
                color: colors.danger,
                onChange: (double d) => _count(s, scrap: d),
              ),
              if (s.counters.scrap > 0) ...<Widget>[
                const SizedBox(height: FfSpace.space3),
                TextField(
                  key: const Key('mfg-scrap-reason'),
                  controller: _reason,
                  style: const TextStyle(fontSize: FfFont.xl),
                  decoration: InputDecoration(
                    labelText: l10n.mfgScrapReason,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
              const SizedBox(height: FfSpace.space3),
              SwitchListTile(
                key: const Key('mfg-final'),
                contentPadding: EdgeInsets.zero,
                value: _final,
                onChanged: (bool v) => setState(() => _final = v),
                title: Text(
                  l10n.mfgFinalOperation,
                  style: const TextStyle(fontSize: FfFont.lg),
                ),
              ),
              const SizedBox(height: FfSpace.space3),
              FilledButton.icon(
                key: const Key('mfg-confirm'),
                onPressed: () => _confirm(s),
                icon: const Icon(Icons.check, size: 32),
                label: Text(l10n.mfgConfirm),
              ),
              const SizedBox(height: FfSpace.space5),
            ],
          ),
        ),
      ),
    );
  }
}

class _Clock extends StatelessWidget {
  const _Clock({
    required this.label,
    required this.seconds,
    required this.keyName,
  });

  final String label;
  final int seconds;
  final String keyName;

  @override
  Widget build(BuildContext context) => Column(
    children: <Widget>[
      Text(label, style: const TextStyle(fontSize: FfFont.lg)),
      Text(
        fmtClock(seconds),
        key: Key(keyName),
        style: const TextStyle(
          fontSize: FfFont.size2xl,
          fontWeight: FontWeight.w800,
          fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
        ),
      ),
    ],
  );
}

class _Counter extends StatelessWidget {
  const _Counter({
    required this.keyName,
    required this.label,
    required this.value,
    required this.color,
    required this.onChange,
  });

  final String keyName;
  final String label;
  final double value;
  final Color color;
  final void Function(double delta) onChange;

  @override
  Widget build(BuildContext context) {
    final FfColors colors = Theme.of(context).extension<FfColors>()!;
    Widget step(String text, double delta, String k) => SizedBox(
      width: terminalTarget + 8,
      height: terminalTarget,
      child: OutlinedButton(
        key: Key('mfg-$keyName-$k'),
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          side: BorderSide(color: color, width: 3),
        ),
        onPressed: () => onChange(delta),
        child: Text(text),
      ),
    );
    return Container(
      padding: const EdgeInsets.all(FfSpace.space3),
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        border: Border.all(color: color, width: 3),
        borderRadius: BorderRadius.circular(FfRadius.lg),
      ),
      child: Column(
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              fontSize: FfFont.xl,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            fmtQty(value),
            key: Key('mfg-$keyName-value'),
            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              step('-10', -10, 'm10'),
              step('-1', -1, 'm1'),
              step('+1', 1, 'p1'),
              step('+10', 10, 'p10'),
            ],
          ),
        ],
      ),
    );
  }
}
