import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../app/session_controller.dart';
import '../../core/database/app_database.dart';
import '../../core/localization/translation_service.dart';
import '../../core/sync/sync_engine.dart';
import '../../core/sync/sync_orchestrator.dart';

/// Clock in / out: the punch is queued locally with its timestamp and sent when online.
class ClockPage extends ConsumerWidget {
  const ClockPage({required this.tenantId, super.key});

  final String tenantId;

  Future<void> _punch(BuildContext context, WidgetRef ref, String path) async {
    final TranslationService t = ref.read(translationProvider);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    await ref
        .read(syncEngineProvider)
        .enqueueCommand(
          tenantId: tenantId,
          entity: 'time_entries',
          path: path,
          data: <String, dynamic>{
            'recorded_at': DateTime.now().toUtc().toIso8601String(),
          },
        );
    messenger.showSnackBar(SnackBar(content: Text(t.t('mobile.clock.queued'))));
    ref.read(syncOrchestratorProvider).run(tenantId, const <String>[
      'time_entries',
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TranslationService t = ref.watch(translationProvider);
    return Scaffold(
      appBar: AppBar(title: Text(t.t('mobile.module.clock'))),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            FilledButton.icon(
              key: const Key('clock-in'),
              icon: const Icon(Icons.login),
              onPressed: () =>
                  _punch(context, ref, '/time-attendance/clock-in'),
              label: Text(t.t('mobile.clock.in')),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              key: const Key('clock-out'),
              icon: const Icon(Icons.logout),
              onPressed: () =>
                  _punch(context, ref, '/time-attendance/clock-out'),
              label: Text(t.t('mobile.clock.out')),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pending approval steps for the signed-in user; decisions are queued so they work offline.
class ApprovalsPage extends ConsumerStatefulWidget {
  const ApprovalsPage({required this.tenantId, super.key});

  final String tenantId;

  @override
  ConsumerState<ApprovalsPage> createState() => _ApprovalsPageState();
}

class _ApprovalsPageState extends ConsumerState<ApprovalsPage> {
  late Future<List<Map<String, dynamic>>> _inbox = _load();
  final Set<String> _decided = <String>{};

  Future<List<Map<String, dynamic>>> _load() async {
    final Response<dynamic> res = await ref
        .read(dioProvider)
        .get<dynamic>('/mobile/approvals');
    final List<dynamic> data =
        (res.data as Map<String, dynamic>)['data'] as List<dynamic>? ??
        <dynamic>[];
    return data.cast<Map<String, dynamic>>();
  }

  Future<void> _decide(String stepId, String decision) async {
    setState(() => _decided.add(stepId));
    await ref
        .read(syncEngineProvider)
        .enqueueCommand(
          tenantId: widget.tenantId,
          entity: 'approval_decisions',
          path: '/mobile/approvals/$stepId/decision',
          data: <String, dynamic>{'decision': decision},
        );
    ref.read(syncOrchestratorProvider).run(widget.tenantId, const <String>[]);
  }

  @override
  Widget build(BuildContext context) {
    final TranslationService t = ref.watch(translationProvider);
    return Scaffold(
      appBar: AppBar(title: Text(t.t('mobile.module.approvals_inbox'))),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _inbox,
        builder:
            (
              BuildContext context,
              AsyncSnapshot<List<Map<String, dynamic>>> snap,
            ) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        t.t('mobile.approvals.offline'),
                        key: const Key('approvals-offline'),
                      ),
                      TextButton(
                        onPressed: () => setState(() => _inbox = _load()),
                        child: Text(t.t('mobile.sync.retry')),
                      ),
                    ],
                  ),
                );
              }
              final List<Map<String, dynamic>> steps = snap.data!
                  .where(
                    (Map<String, dynamic> s) =>
                        !_decided.contains('${s['id']}'),
                  )
                  .toList();
              if (steps.isEmpty) {
                return Center(
                  child: Text(
                    t.t('mobile.approvals.empty'),
                    key: const Key('approvals-empty'),
                  ),
                );
              }
              return ListView(
                children: <Widget>[
                  for (final Map<String, dynamic> s in steps)
                    ListTile(
                      key: Key('approval-${s['id']}'),
                      title: Text(
                        '${(s['node'] as Map<String, dynamic>?)?['name'] ?? (s['instance'] as Map<String, dynamic>?)?['name'] ?? s['id']}',
                      ),
                      subtitle: s['due_at'] == null
                          ? null
                          : Text('${s['due_at']}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          IconButton(
                            key: Key('approve-${s['id']}'),
                            tooltip: t.t('mobile.approvals.approve'),
                            icon: const Icon(Icons.check_circle_outline),
                            onPressed: () => _decide('${s['id']}', 'approved'),
                          ),
                          IconButton(
                            key: Key('reject-${s['id']}'),
                            tooltip: t.t('mobile.approvals.reject'),
                            icon: const Icon(Icons.cancel_outlined),
                            onPressed: () => _decide('${s['id']}', 'rejected'),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
      ),
    );
  }
}

/// Failed and conflicting writes with the two ways out: resend the local edit or take the server version.
class ConflictsPage extends ConsumerWidget {
  const ConflictsPage({
    required this.tenantId,
    required this.syncEntities,
    super.key,
  });

  final String tenantId;
  final List<String> syncEntities;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TranslationService t = ref.watch(translationProvider);
    final SyncEngine engine = ref.watch(syncEngineProvider);
    return Scaffold(
      appBar: AppBar(title: Text(t.t('mobile.conflicts.title'))),
      body: StreamBuilder<List<QueueItem>>(
        stream: engine.watchIssues(tenantId),
        builder: (BuildContext context, AsyncSnapshot<List<QueueItem>> snap) {
          final List<QueueItem> items = snap.data ?? <QueueItem>[];
          if (items.isEmpty) {
            return Center(
              child: Text(
                t.t('mobile.conflicts.none'),
                key: const Key('conflicts-empty'),
              ),
            );
          }
          return ListView(
            children: <Widget>[
              for (final QueueItem i in items)
                ListTile(
                  key: Key('issue-${i.uuid}'),
                  leading: Icon(
                    i.state == QueueState.conflict
                        ? Icons.warning_amber_outlined
                        : Icons.error_outline,
                  ),
                  title: Text(
                    '${t.t('mobile.entity.${i.entity}')} · ${i.method}',
                  ),
                  subtitle: Text(i.lastError ?? ''),
                  trailing: Wrap(
                    children: <Widget>[
                      TextButton(
                        key: Key('keep-mine-${i.uuid}'),
                        onPressed: () async {
                          await engine.retry(i.uuid);
                          ref
                              .read(syncOrchestratorProvider)
                              .run(tenantId, syncEntities);
                        },
                        child: Text(t.t('mobile.conflicts.keepMine')),
                      ),
                      TextButton(
                        key: Key('use-server-${i.uuid}'),
                        onPressed: () async {
                          await engine.discard(i.uuid);
                          ref
                              .read(syncOrchestratorProvider)
                              .run(tenantId, syncEntities);
                        },
                        child: Text(t.t('mobile.conflicts.useServer')),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// The companies of the signed-in user (from `GET /mobile/tenants`).
final FutureProvider<List<({String id, String name})>> userTenantsProvider =
    FutureProvider<List<({String id, String name})>>((Ref ref) async {
      final Response<dynamic> res = await ref
          .watch(dioProvider)
          .get<dynamic>('/mobile/tenants');
      final List<dynamic> data =
          (res.data as Map<String, dynamic>)['data'] as List<dynamic>? ??
          <dynamic>[];
      return data
          .cast<Map<String, dynamic>>()
          .map(
            (Map<String, dynamic> m) =>
                (id: '${m['tenant_id']}', name: '${m['tenant_name']}'),
          )
          .toList();
    });

/// Bottom sheet to switch company; data stays separated per tenant in SQLite.
class TenantSwitcher extends ConsumerWidget {
  const TenantSwitcher({required this.activeTenantId, super.key});

  final String activeTenantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TranslationService t = ref.watch(translationProvider);
    final AsyncValue<List<({String id, String name})>> tenants = ref.watch(
      userTenantsProvider,
    );
    return SafeArea(
      child: tenants.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (Object e, StackTrace _) => Padding(
          padding: const EdgeInsets.all(24),
          child: Text(t.t('mobile.tenant.none')),
        ),
        data: (List<({String id, String name})> list) => ListView(
          shrinkWrap: true,
          children: <Widget>[
            ListTile(title: Text(t.t('mobile.tenant.switch'))),
            for (final ({String id, String name}) c in list)
              ListTile(
                key: Key('tenant-${c.id}'),
                title: Text(c.name),
                trailing: c.id == activeTenantId
                    ? const Icon(Icons.check)
                    : null,
                onTap: () {
                  Navigator.of(context).pop();
                  if (c.id != activeTenantId) {
                    ref.read(sessionProvider.notifier).switchTenant(c.id);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// Shown for modules that exist in the permission model but have no mobile screen yet.
class ModuleUnavailablePage extends ConsumerWidget {
  const ModuleUnavailablePage({required this.module, super.key});

  final String module;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TranslationService t = ref.watch(translationProvider);
    return Scaffold(
      appBar: AppBar(title: Text(t.t('mobile.module.$module'))),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            t.t('mobile.common.unavailable'),
            key: const Key('module-unavailable'),
          ),
        ),
      ),
    );
  }
}
