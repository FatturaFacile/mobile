import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../../design/ff_tokens.dart';
import '../data/field_service_outbox.dart';
import '../data/field_service_repository.dart';
import '../device/field_service_device_services.dart';
import '../l10n/field_service_strings.dart';
import '../models/field_service_models.dart';
import 'work_order_detail_page.dart';

/// The technician's offline work queue: the open work orders assigned to them, read from the phone. A refresh downloads the
/// delta bundle when online; the banner shows what waits to sync and the conflicts the server refused.
class WorkQueuePage extends StatefulWidget {
  const WorkQueuePage({
    super.key,
    required this.repository,
    this.device = const FieldServiceDeviceHooks(),
    this.refreshOnOpen = true,
  });

  final FieldServiceRepository repository;
  final FieldServiceDeviceHooks device;

  /// Download the bundle when the page opens (tests switch it off).
  final bool refreshOnOpen;

  @override
  State<WorkQueuePage> createState() => _WorkQueuePageState();
}

class _WorkQueuePageState extends State<WorkQueuePage> {
  bool _offline = false;
  bool _busy = false;
  late final Stream<List<FsmQueueItem>> _queue = widget.repository
      .watchWorkQueue();

  @override
  void initState() {
    super.initState();
    if (widget.refreshOnOpen) unawaited(_refresh());
  }

  Future<void> _refresh() async {
    final FsmRefreshResult result = await widget.repository.refresh();
    if (!mounted) return;
    setState(() => _offline = result.offline);
    if (result.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            FieldServiceStrings.of(context).t(FsmText.refreshFailed),
          ),
        ),
      );
    }
  }

  Future<void> _sync() async {
    final FieldServiceStrings s = FieldServiceStrings.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    final FsmFlushReport report = await widget.repository.sync();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _offline = report.offline;
    });
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          report.offline
              ? s.t(FsmText.syncOffline)
              : report.unauthorized
              ? s.t(FsmText.syncUnauthorized)
              : fill(s.t(FsmText.syncDone), <String, Object>{
                  'count': report.sent,
                }),
        ),
      ),
    );
  }

  void _open(FsmQueueItem item) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => WorkOrderDetailPage(
          repository: widget.repository,
          workOrderId: item.workOrder.id,
          device: widget.device,
        ),
      ),
    );
  }

  void _showConflicts() {
    showDialog<void>(
      context: context,
      builder: (BuildContext _) =>
          SyncConflictsDialog(repository: widget.repository),
    );
  }

  @override
  Widget build(BuildContext context) {
    final FieldServiceStrings s = FieldServiceStrings.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.t(FsmText.workQueueTitle)),
        actions: <Widget>[
          IconButton(
            key: const Key('fsm-refresh'),
            tooltip: s.t(FsmText.refresh),
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
          IconButton(
            key: const Key('fsm-sync'),
            tooltip: s.t(FsmText.syncNow),
            icon: const Icon(Icons.sync),
            onPressed: _busy ? null : _sync,
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          if (_offline)
            ListTile(
              key: const Key('fsm-offline'),
              dense: true,
              leading: const Icon(Icons.cloud_off),
              title: Text(s.t(FsmText.offlineNotice)),
            ),
          _SyncBanner(
            repository: widget.repository,
            onConflicts: _showConflicts,
          ),
          Expanded(
            child: StreamBuilder<List<FsmQueueItem>>(
              stream: _queue,
              builder:
                  (
                    BuildContext context,
                    AsyncSnapshot<List<FsmQueueItem>> snap,
                  ) {
                    final List<FsmQueueItem> items =
                        snap.data ?? const <FsmQueueItem>[];
                    if (items.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(FfSpace.space5),
                          child: Text(
                            s.t(FsmText.emptyQueue),
                            key: const Key('fsm-empty'),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (BuildContext context, int i) =>
                          _tile(s, items[i]),
                    );
                  },
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(FieldServiceStrings s, FsmQueueItem item) {
    final FsmWorkOrder wo = item.workOrder;
    return Card(
      child: ListTile(
        key: Key('fsm-wo-${wo.id}'),
        title: Text('${wo.number} · ${wo.title}'),
        subtitle: Text(
          <String>[
            if (item.customerName != null) item.customerName!,
            s.workType(wo.workType),
            if (item.site.address != null) item.site.address!,
          ].join('\n'),
        ),
        isThreeLine: true,
        trailing: Chip(label: Text(s.status(wo.status))),
        onTap: () => _open(item),
      ),
    );
  }
}

/// Pending-sync counter and conflict entry point.
class _SyncBanner extends StatefulWidget {
  const _SyncBanner({required this.repository, required this.onConflicts});

  final FieldServiceRepository repository;
  final VoidCallback onConflicts;

  @override
  State<_SyncBanner> createState() => _SyncBannerState();
}

class _SyncBannerState extends State<_SyncBanner> {
  late final Stream<int> _pending = widget.repository.watchPending();
  late final Stream<List<FsmOperation>> _conflicts = widget.repository
      .watchConflicts();

  @override
  Widget build(BuildContext context) {
    final FieldServiceStrings s = FieldServiceStrings.of(context);
    return Column(
      children: <Widget>[
        StreamBuilder<int>(
          stream: _pending,
          builder: (BuildContext context, AsyncSnapshot<int> snap) {
            final int pending = snap.data ?? 0;
            if (pending == 0) return const SizedBox.shrink();
            return ListTile(
              key: const Key('fsm-pending'),
              dense: true,
              leading: const Icon(Icons.cloud_upload_outlined),
              title: Text(
                fill(s.t(FsmText.pendingSync), <String, Object>{
                  'count': pending,
                }),
              ),
            );
          },
        ),
        StreamBuilder<List<FsmOperation>>(
          stream: _conflicts,
          builder:
              (BuildContext context, AsyncSnapshot<List<FsmOperation>> snap) {
                final int conflicts = snap.data?.length ?? 0;
                if (conflicts == 0) return const SizedBox.shrink();
                return ListTile(
                  key: const Key('fsm-conflicts'),
                  dense: true,
                  leading: Icon(
                    Icons.warning_amber,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(
                    fill(s.t(FsmText.syncIssues), <String, Object>{
                      'count': conflicts,
                    }),
                  ),
                  onTap: widget.onConflicts,
                );
              },
        ),
      ],
    );
  }
}

/// The conflict report: every operation the server rejected, with its field errors, to retry or discard.
class SyncConflictsDialog extends StatefulWidget {
  const SyncConflictsDialog({super.key, required this.repository});

  final FieldServiceRepository repository;

  @override
  State<SyncConflictsDialog> createState() => _SyncConflictsDialogState();
}

class _SyncConflictsDialogState extends State<SyncConflictsDialog> {
  late final Stream<List<FsmOperation>> _conflicts = widget.repository
      .watchConflicts();

  FieldServiceRepository get repository => widget.repository;

  @override
  Widget build(BuildContext context) {
    final FieldServiceStrings s = FieldServiceStrings.of(context);
    return AlertDialog(
      title: Text(s.t(FsmText.syncIssuesTitle)),
      content: SizedBox(
        width: double.maxFinite,
        child: StreamBuilder<List<FsmOperation>>(
          stream: _conflicts,
          builder:
              (BuildContext context, AsyncSnapshot<List<FsmOperation>> snap) {
                final List<FsmOperation> ops =
                    snap.data ?? const <FsmOperation>[];
                return ListView(
                  shrinkWrap: true,
                  children: <Widget>[
                    Text(s.t(FsmText.syncIssuesHint)),
                    for (final FsmOperation op in ops)
                      ListTile(
                        key: Key('fsm-conflict-${op.clientUuid}'),
                        title: Text(_label(s, op.type)),
                        subtitle: Text(
                          op.errors.isEmpty
                              ? (op.lastError ?? '')
                              : op.errors.entries
                                    .map(
                                      (MapEntry<String, List<String>> e) =>
                                          '${e.key}: ${e.value.join(', ')}',
                                    )
                                    .join('\n'),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            TextButton(
                              key: Key('fsm-conflict-retry-${op.clientUuid}'),
                              onPressed: () =>
                                  repository.retryOperation(op.clientUuid),
                              child: Text(s.t(FsmText.retry)),
                            ),
                            TextButton(
                              key: Key('fsm-conflict-discard-${op.clientUuid}'),
                              onPressed: () =>
                                  repository.discardOperation(op.clientUuid),
                              child: Text(s.t(FsmText.discard)),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(s.t(FsmText.close)),
        ),
      ],
    );
  }

  String _label(FieldServiceStrings s, FsmOperationType type) => switch (type) {
    FsmOperationType.statusTransition => s.t(FsmText.opStatusChange),
    FsmOperationType.partConsumption => s.t(FsmText.opPartConsumption),
    FsmOperationType.serviceReport => s.t(FsmText.reportTitle),
    FsmOperationType.photoUpload => s.t(FsmText.opPhotoUpload),
  };
}
