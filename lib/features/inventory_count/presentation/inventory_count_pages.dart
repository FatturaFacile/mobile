import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/providers.dart';
import '../../../core/localization/translation_service.dart';
import '../../../design/ff_tokens.dart';
import '../../wms/ui/scan_field.dart' show CameraScanner;
import '../domain/inventory_count_models.dart';
import 'inventory_count_controller.dart';

const String _k = 'mobile.inventory_count.';

String _t(
  TranslationService t,
  String key, {
  Map<String, Object> params = const <String, Object>{},
}) => t.t('$_k$key', params: params);

String? _noticeText(TranslationService t, CountNotice? n) => switch (n) {
  null => null,
  CountNotice.saved => _t(t, 'count_saved'),
  CountNotice.queuedOffline => _t(t, 'queued_offline'),
  CountNotice.recountRequested => _t(t, 'recount_requested'),
  CountNotice.syncDone => _t(t, 'sync_done'),
  CountNotice.syncError => _t(t, 'sync_error'),
  CountNotice.scanNoMatch => _t(t, 'scan_no_match'),
};

/// "N counts to sync" bar with the "sync now" button. Hidden when nothing is pending.
class CountPendingBar extends ConsumerWidget {
  const CountPendingBar({
    required this.tenantId,
    required this.onSyncNow,
    this.busy = false,
    super.key,
  });

  final String tenantId;
  final Future<void> Function() onSyncNow;
  final bool busy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TranslationService t = ref.watch(translationProvider);
    final int pending =
        ref.watch(inventoryCountPendingProvider(tenantId)).value ?? 0;
    if (pending == 0) {
      return const SizedBox.shrink();
    }
    final FfColors colors =
        Theme.of(context).extension<FfColors>() ?? FfColors.dark;
    return Container(
      key: const Key('count-pending-bar'),
      color: colors.warningBg,
      padding: const EdgeInsets.symmetric(
        horizontal: FfSpace.space4,
        vertical: FfSpace.space2,
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.sync_problem, color: colors.warning),
          const SizedBox(width: FfSpace.space2),
          Expanded(
            child: Text(
              _t(t, 'sync_pending', params: <String, Object>{'count': pending}),
              key: const Key('count-pending-label'),
              style: TextStyle(color: colors.text),
            ),
          ),
          TextButton(
            key: const Key('count-sync-now'),
            onPressed: busy ? null : onSyncNow,
            child: Text(_t(t, 'sync_now')),
          ),
        ],
      ),
    );
  }
}

/// "My counts": the sessions assigned to the user, readable offline.
class InventoryCountListPage extends ConsumerStatefulWidget {
  const InventoryCountListPage({super.key});

  @override
  ConsumerState<InventoryCountListPage> createState() =>
      _InventoryCountListPageState();
}

class _InventoryCountListPageState
    extends ConsumerState<InventoryCountListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(countListProvider.notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TranslationService t = ref.watch(translationProvider);
    final CountListState state = ref.watch(countListProvider);
    final String? tenant = ref.watch(inventoryCountTenantProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(_t(t, 'my_counts')),
        actions: <Widget>[
          IconButton(
            key: const Key('count-refresh'),
            tooltip: _t(t, 'sync_now'),
            icon: const Icon(Icons.refresh),
            onPressed: state.loading
                ? null
                : () => ref.read(countListProvider.notifier).load(),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          if (tenant != null)
            CountPendingBar(
              tenantId: tenant,
              busy: state.loading,
              onSyncNow: () => ref.read(countListProvider.notifier).load(),
            ),
          if (state.loading) const LinearProgressIndicator(),
          if (state.error != null && state.sessions.isEmpty)
            Padding(
              padding: const EdgeInsets.all(FfSpace.space4),
              child: Text(
                _t(t, 'load_error'),
                key: const Key('count-load-error'),
              ),
            ),
          if (state.fromCache &&
              state.sessions.isNotEmpty &&
              state.error != null)
            Padding(
              padding: const EdgeInsets.all(FfSpace.space2),
              child: Text(
                _t(t, 'offline_copy'),
                key: const Key('count-offline-copy'),
              ),
            ),
          Expanded(
            child: state.sessions.isEmpty
                ? (state.loading || state.error != null
                      ? const SizedBox.shrink()
                      : Center(
                          child: Text(
                            _t(t, 'no_counts'),
                            key: const Key('count-empty'),
                          ),
                        ))
                : ListView(
                    children: <Widget>[
                      for (final CountSession s in state.sessions)
                        _SessionCard(
                          session: s,
                          t: t,
                          onOpen: () async {
                            await Navigator.of(context).push<void>(
                              MaterialPageRoute<void>(
                                builder: (_) => CountSheetPage(session: s),
                              ),
                            );
                            await ref
                                .read(countListProvider.notifier)
                                .reloadLocal();
                          },
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.session,
    required this.t,
    required this.onOpen,
  });

  final CountSession session;
  final TranslationService t;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final FfColors colors =
        Theme.of(context).extension<FfColors>() ?? FfColors.dark;
    final String where = <String>[
      if (session.warehouseName != null)
        '${_t(t, 'warehouse')}: ${session.warehouseName}',
      if (session.zoneName != null) '${_t(t, 'zone')}: ${session.zoneName}',
    ].join(' / ');
    final double progress = session.totalLines == 0
        ? 0
        : session.countedLines / session.totalLines;
    return Card(
      key: Key('count-session-${session.id}'),
      margin: const EdgeInsets.symmetric(
        horizontal: FfSpace.space3,
        vertical: FfSpace.space2,
      ),
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(FfSpace.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      session.sessionNumber,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (session.isFrozen)
                    Chip(
                      key: Key('count-frozen-${session.id}'),
                      avatar: Icon(Icons.lock, size: 16, color: colors.warning),
                      label: Text(_t(t, 'frozen')),
                    ),
                ],
              ),
              if (where.isNotEmpty) Text(where),
              const SizedBox(height: FfSpace.space2),
              LinearProgressIndicator(value: progress),
              const SizedBox(height: FfSpace.space1),
              Row(
                children: <Widget>[
                  Text(
                    _t(
                      t,
                      'progress',
                      params: <String, Object>{
                        'counted': session.countedLines,
                        'total': session.totalLines,
                      },
                    ),
                    key: Key('count-progress-${session.id}'),
                  ),
                  const Spacer(),
                  if (session.pendingEntries > 0)
                    Text(
                      _t(
                        t,
                        'sync_pending',
                        params: <String, Object>{
                          'count': session.pendingEntries,
                        },
                      ),
                      key: Key('count-session-pending-${session.id}'),
                      style: TextStyle(color: colors.warning),
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

/// The blind count sheet of one session.
class CountSheetPage extends ConsumerStatefulWidget {
  const CountSheetPage({required this.session, super.key});

  final CountSession session;

  @override
  ConsumerState<CountSheetPage> createState() => _CountSheetPageState();
}

class _CountSheetPageState extends ConsumerState<CountSheetPage> {
  final TextEditingController _search = TextEditingController();

  CountSheetController get _ctl =>
      ref.read(countSheetProvider(widget.session.id).notifier);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ctl.load());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _scanWithCamera() async {
    final CameraScanner scanner = ref.read(inventoryCountCameraScannerProvider);
    final String? code = await scanner(context);
    if (code != null && mounted) {
      _search.text = code;
      _ctl.scan(code);
    }
  }

  Future<void> _openEntry(CountLine line) async {
    final TranslationService t = ref.read(translationProvider);
    final ({double quantity, String? notes})? result =
        await showModalBottomSheet<({double quantity, String? notes})>(
          context: context,
          isScrollControlled: true,
          builder: (_) => _EntrySheet(line: line, t: t),
        );
    if (result != null) {
      await _ctl.save(line, result.quantity, notes: result.notes);
    }
  }

  @override
  Widget build(BuildContext context) {
    final TranslationService t = ref.watch(translationProvider);
    final CountSheetState state = ref.watch(
      countSheetProvider(widget.session.id),
    );
    final String? tenant = ref.watch(inventoryCountTenantProvider);
    final FfColors colors =
        Theme.of(context).extension<FfColors>() ?? FfColors.dark;

    ref.listen<CountSheetState>(countSheetProvider(widget.session.id), (
      CountSheetState? prev,
      CountSheetState next,
    ) {
      final String? message = _noticeText(t, next.notice);
      if (message != null && next.notice != prev?.notice) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
        _ctl.clearNotice();
      }
      final String? focus = next.focusLineId;
      if (focus != null && focus != prev?.focusLineId) {
        for (final CountLine l in next.lines) {
          if (l.id == focus) {
            _ctl.clearFocus();
            _openEntry(l);
            break;
          }
        }
      }
    });

    final List<CountLine> visible = state.visible;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.session.sessionNumber),
        actions: <Widget>[
          IconButton(
            key: const Key('count-sheet-refresh'),
            tooltip: _t(t, 'sync_now'),
            icon: const Icon(Icons.refresh),
            onPressed: state.syncing || state.loading ? null : _ctl.syncNow,
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Container(
            key: const Key('count-blind-notice'),
            width: double.infinity,
            color: colors.primarySubtle,
            padding: const EdgeInsets.all(FfSpace.space3),
            child: Row(
              children: <Widget>[
                Icon(Icons.visibility_off, color: colors.primary),
                const SizedBox(width: FfSpace.space2),
                Expanded(child: Text(_t(t, 'blind_notice'))),
              ],
            ),
          ),
          if (tenant != null)
            CountPendingBar(
              tenantId: tenant,
              busy: state.syncing,
              onSyncNow: _ctl.syncNow,
            ),
          if (state.loading || state.syncing) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(FfSpace.space3),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    key: const Key('count-search'),
                    controller: _search,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      labelText: _t(t, 'scan_or_search'),
                      prefixIcon: const Icon(Icons.qr_code_scanner),
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: _ctl.setQuery,
                    onSubmitted: _ctl.scan,
                  ),
                ),
                IconButton(
                  key: const Key('count-camera'),
                  tooltip: _t(t, 'scan_or_search'),
                  icon: const Icon(Icons.photo_camera),
                  onPressed: _scanWithCamera,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: FfSpace.space3),
            child: SegmentedButton<CountFilter>(
              key: const Key('count-filter'),
              showSelectedIcon: false,
              segments: <ButtonSegment<CountFilter>>[
                ButtonSegment<CountFilter>(
                  value: CountFilter.toCount,
                  label: Text(_t(t, 'to_count')),
                ),
                ButtonSegment<CountFilter>(
                  value: CountFilter.counted,
                  label: Text(_t(t, 'counted')),
                ),
                ButtonSegment<CountFilter>(
                  value: CountFilter.all,
                  label: Text(_t(t, 'filter_all')),
                ),
              ],
              selected: <CountFilter>{state.filter},
              onSelectionChanged: (Set<CountFilter> s) =>
                  _ctl.setFilter(s.first),
            ),
          ),
          if (state.error != null && state.lines.isEmpty)
            Padding(
              padding: const EdgeInsets.all(FfSpace.space4),
              child: Text(
                _t(t, 'load_error'),
                key: const Key('count-load-error'),
              ),
            ),
          Expanded(
            child: visible.isEmpty
                ? Center(
                    child: Text(
                      state.lines.isEmpty
                          ? _t(t, 'no_lines')
                          : _t(t, 'no_match'),
                      key: const Key('count-no-lines'),
                    ),
                  )
                : ListView.builder(
                    itemCount: visible.length,
                    itemBuilder: (BuildContext context, int i) => _LineTile(
                      line: visible[i],
                      t: t,
                      onTap: () => _openEntry(visible[i]),
                      onDismiss: () => _ctl.dismiss(visible[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _LineTile extends StatelessWidget {
  const _LineTile({
    required this.line,
    required this.t,
    required this.onTap,
    required this.onDismiss,
  });

  final CountLine line;
  final TranslationService t;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final FfColors colors =
        Theme.of(context).extension<FfColors>() ?? FfColors.dark;
    final String detail = <String>[
      if (line.binBarcode != null) '${_t(t, 'bin')}: ${line.binBarcode}',
      if (line.sku != null) '${_t(t, 'sku')}: ${line.sku}',
      if (line.lotId != null) '${_t(t, 'lot')}: ${line.lotId}',
    ].join('  ');
    final double? shown = line.shownQuantity;
    final CountEntry? entry = line.entry;
    return Card(
      key: Key('count-line-${line.id}'),
      margin: const EdgeInsets.symmetric(
        horizontal: FfSpace.space3,
        vertical: FfSpace.space1,
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(FfSpace.space3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      line.itemName ?? line.sku ?? line.id,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  if (shown != null)
                    Text(
                      formatQuantity(shown),
                      key: Key('count-qty-${line.id}'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                ],
              ),
              if (detail.isNotEmpty) Text(detail),
              Wrap(
                spacing: FfSpace.space2,
                children: <Widget>[
                  if (line.recountRequired)
                    Chip(
                      key: Key('count-recount-${line.id}'),
                      avatar: Icon(
                        Icons.replay,
                        size: 16,
                        color: colors.danger,
                      ),
                      label: Text(
                        '${_t(t, 'recount_required')} '
                        '(${_t(t, 'recount_round', params: <String, Object>{'round': line.recountRound})})',
                      ),
                    ),
                  if (line.pendingSync)
                    Chip(
                      key: Key('count-pending-${line.id}'),
                      avatar: Icon(
                        Icons.schedule,
                        size: 16,
                        color: colors.warning,
                      ),
                      label: Text(_t(t, 'pending_sync')),
                    ),
                ],
              ),
              if (line.recountRequired) ...<Widget>[
                Text(
                  _t(t, 'recount_hint'),
                  key: Key('count-recount-hint-${line.id}'),
                ),
                if (line.recountReason != null) Text(line.recountReason!),
                // Only shown when the server policy reveals the previous count.
                if (line.firstCountedQuantity != null)
                  Text(
                    '${_t(t, 'first_count')}: '
                    '${formatQuantity(line.firstCountedQuantity!)}',
                    key: Key('count-first-${line.id}'),
                  ),
              ],
              if (line.rejected && entry != null)
                Row(
                  children: <Widget>[
                    Icon(Icons.error_outline, size: 18, color: colors.danger),
                    const SizedBox(width: FfSpace.space1),
                    Expanded(
                      child: Text(
                        '${_t(t, 'rejected')}: '
                        '${entry.message ?? _t(t, 'conflict_server_wins')}',
                        key: Key('count-rejected-${line.id}'),
                        style: TextStyle(color: colors.danger),
                      ),
                    ),
                    TextButton(
                      key: Key('count-dismiss-${line.id}'),
                      onPressed: onDismiss,
                      child: Text(_t(t, 'dismiss')),
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

/// Quantity and notes entry for one line. Shows nothing but what the operator types (blind).
class _EntrySheet extends StatefulWidget {
  const _EntrySheet({required this.line, required this.t});

  final CountLine line;
  final TranslationService t;

  @override
  State<_EntrySheet> createState() => _EntrySheetState();
}

class _EntrySheetState extends State<_EntrySheet> {
  final TextEditingController _qty = TextEditingController();
  final TextEditingController _notes = TextEditingController();
  bool _invalid = false;

  @override
  void dispose() {
    _qty.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _submit() {
    final double? q = parseQuantity(_qty.text.trim());
    if (q == null || !q.isFinite || q < 0) {
      setState(() => _invalid = true);
      return;
    }
    final String notes = _notes.text.trim();
    Navigator.of(context)
        .pop((quantity: q, notes: notes.isEmpty ? null : notes));
  }

  @override
  Widget build(BuildContext context) {
    final TranslationService t = widget.t;
    final CountLine line = widget.line;
    return Padding(
      padding: EdgeInsets.only(
        left: FfSpace.space4,
        right: FfSpace.space4,
        top: FfSpace.space4,
        bottom: MediaQuery.of(context).viewInsets.bottom + FfSpace.space4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            line.itemName ?? line.sku ?? line.id,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (line.binBarcode != null)
            Text('${_t(t, 'bin')}: ${line.binBarcode}'),
          if (line.recountRequired) ...<Widget>[
            const SizedBox(height: FfSpace.space2),
            Text(
              _t(t, 'recount_hint'),
              key: const Key('count-entry-recount-hint'),
            ),
          ],
          const SizedBox(height: FfSpace.space3),
          TextField(
            key: const Key('count-qty'),
            controller: _qty,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            decoration: InputDecoration(
              labelText: _t(t, 'counted_quantity'),
              errorText: _invalid ? _t(t, 'quantity_invalid') : null,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: FfSpace.space3),
          TextField(
            key: const Key('count-notes'),
            controller: _notes,
            decoration: InputDecoration(
              labelText: _t(t, 'notes'),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: FfSpace.space4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              TextButton(
                key: const Key('count-cancel'),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(_t(t, 'cancel')),
              ),
              const SizedBox(width: FfSpace.space2),
              FilledButton(
                key: const Key('count-save'),
                onPressed: _submit,
                child: Text(_t(t, 'save_count')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
