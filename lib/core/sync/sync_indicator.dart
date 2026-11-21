import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../database/app_database.dart';
import '../localization/translation_service.dart';
import 'sync_engine.dart';

/// What the app bar indicator shows.
enum SyncUiKind { synced, offline, syncing, error }

class SyncUiState {
  const SyncUiState(this.kind, {this.pending = 0});

  final SyncUiKind kind;
  final int pending;

  /// Offline wins, then failed items, then in-flight items.
  static SyncUiState derive({
    required bool online,
    required int pending,
    required int failed,
  }) {
    if (!online) {
      return SyncUiState(SyncUiKind.offline, pending: pending);
    }
    if (failed > 0) {
      return SyncUiState(SyncUiKind.error, pending: pending);
    }
    if (pending > 0) {
      return SyncUiState(SyncUiKind.syncing, pending: pending);
    }
    return const SyncUiState(SyncUiKind.synced);
  }
}

/// Live outbox counters for the active tenant (core outbox + Mod 044 purchase requisitions/approvals).
final syncUiProvider = StreamProvider.family<SyncUiState, String>((
  Ref ref,
  String tenantId,
) {
  final AppDatabase db = ref.watch(databaseProvider);
  final bool online = ref.watch(connectivityProvider).value ?? true;
  final Stream<List<QueueItem>> coreStream = (db.select(
    db.syncQueue,
  )..where((SyncQueue q) => q.tenantId.equals(tenantId))).watch();
  final Stream<({int pending, int failed})> prStream = db.purchaseRequisitionDao
      .watchPendingSyncCounts(tenantId);

  late final StreamController<SyncUiState> controller;
  StreamSubscription<List<QueueItem>>? coreSub;
  StreamSubscription<({int pending, int failed})>? prSub;

  int corePending = 0;
  int coreFailed = 0;
  int prPending = 0;
  int prFailed = 0;
  bool coreReady = false;
  bool prReady = false;

  void emit() {
    if (coreReady && prReady && !controller.isClosed) {
      controller.add(
        SyncUiState.derive(
          online: online,
          pending: corePending + prPending,
          failed: coreFailed + prFailed,
        ),
      );
    }
  }

  controller = StreamController<SyncUiState>(
    onListen: () {
      coreSub = coreStream.listen((List<QueueItem> rows) {
        corePending = rows.length;
        coreFailed = rows
            .where((QueueItem r) => r.state != QueueState.pending)
            .length;
        coreReady = true;
        emit();
      });
      prSub = prStream.listen((({int pending, int failed}) counts) {
        prPending = counts.pending;
        prFailed = counts.failed;
        prReady = true;
        emit();
      });
    },
    onCancel: () async {
      await coreSub?.cancel();
      await prSub?.cancel();
    },
  );
  return controller.stream;
});

/// Persistent, subtle status chip: synced / offline / syncing N / error with retry.
class SyncStatusIndicator extends StatelessWidget {
  const SyncStatusIndicator({
    required this.state,
    required this.translations,
    this.onRetry,
    super.key,
  });

  final SyncUiState state;
  final TranslationService translations;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final (IconData icon, String label) = switch (state.kind) {
      SyncUiKind.synced => (
        Icons.cloud_done_outlined,
        translations.t('mobile.sync.online'),
      ),
      SyncUiKind.offline => (
        Icons.cloud_off_outlined,
        translations.t('mobile.sync.offline'),
      ),
      SyncUiKind.syncing => (
        Icons.sync,
        translations.t(
          'mobile.sync.syncing',
          params: <String, Object>{'count': state.pending},
        ),
      ),
      SyncUiKind.error => (
        Icons.sync_problem_outlined,
        translations.t('mobile.sync.error'),
      ),
    };
    return Tooltip(
      message: label,
      child: InkWell(
        key: const Key('sync-indicator'),
        onTap: state.kind == SyncUiKind.error ? onRetry : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 18),
              const SizedBox(width: 4),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}
