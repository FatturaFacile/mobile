import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../features/inventory_count/presentation/inventory_count_controller.dart';
import '../../features/purchase_requisitions/presentation/providers/pr_providers.dart';
import 'sync_engine.dart';

/// Feature-level background sync callback invoked by [SyncOrchestrator] after core entity sync.
typedef SyncHook = Future<void> Function(String tenantId);

/// Runs one full cycle: flush the outbox, delta-pull every allowed entity, and execute feature sync hooks. Never throws.
class SyncOrchestrator {
  SyncOrchestrator(this._engine, {this.hooks = const <SyncHook>[]});

  final SyncEngine _engine;
  final List<SyncHook> hooks;
  bool _running = false;

  Future<void> run(String tenantId, List<String> entities) async {
    if (_running) {
      return;
    }
    _running = true;
    try {
      final FlushReport first = await _engine.flush(tenantId);
      if (first.offline) {
        return;
      }
      for (final String entity in entities) {
        try {
          await _engine.pull(tenantId, entity);
        } catch (_) {
          // One feed failing must not stop the others; the next cycle retries from the same watermark.
        }
      }
      await _engine.flush(tenantId);
      for (final SyncHook hook in hooks) {
        try {
          await hook(tenantId);
        } catch (_) {
          // One feature sync hook failing must not stop core sync or other hooks.
        }
      }
    } catch (_) {
      // Sync is best effort: the UI shows the outcome through the indicator.
    } finally {
      _running = false;
    }
  }
}

final Provider<SyncOrchestrator> syncOrchestratorProvider =
    Provider<SyncOrchestrator>(
      (Ref ref) => SyncOrchestrator(
        ref.watch(syncEngineProvider),
        hooks: <SyncHook>[
          (String tenantId) =>
              ref.read(syncPurchaseRequisitionsUseCaseProvider).call(tenantId),
          (String tenantId) => syncInventoryCounts(ref, tenantId),
        ],
      ),
    );

/// Triggers a sync on start, when connectivity returns and when the app comes back to the foreground.
class SyncLifecycle extends ConsumerStatefulWidget {
  const SyncLifecycle({
    required this.tenantId,
    required this.entities,
    required this.child,
    super.key,
  });

  final String tenantId;
  final List<String> entities;
  final Widget child;

  @override
  ConsumerState<SyncLifecycle> createState() => _SyncLifecycleState();
}

class _SyncLifecycleState extends ConsumerState<SyncLifecycle>
    with WidgetsBindingObserver {
  void _sync() =>
      ref.read(syncOrchestratorProvider).run(widget.tenantId, widget.entities);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  @override
  void didUpdateWidget(SyncLifecycle old) {
    super.didUpdateWidget(old);
    if (old.tenantId != widget.tenantId) {
      _sync();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _sync();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<bool>>(connectivityProvider, (
      AsyncValue<bool>? prev,
      AsyncValue<bool> next,
    ) {
      if (next.value == true && prev?.value != true) {
        _sync();
      }
    });
    return widget.child;
  }
}
