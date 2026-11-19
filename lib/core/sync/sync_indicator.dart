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
  static SyncUiState derive({required bool online, required int pending, required int failed}) {
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

/// Live outbox counters for the active tenant.
final syncUiProvider =StreamProvider.family<SyncUiState, String>((Ref ref, String tenantId) {
  final AppDatabase db = ref.watch(databaseProvider);
  final bool online = ref.watch(connectivityProvider).value ?? true;
  return (db.select(db.syncQueue)..where((SyncQueue q) => q.tenantId.equals(tenantId))).watch().map(
        (List<QueueItem> rows) => SyncUiState.derive(
          online: online,
          pending: rows.length,
          failed: rows.where((QueueItem r) => r.state != QueueState.pending).length,
        ),
      );
});

/// Persistent, subtle status chip: synced / offline / syncing N / error with retry.
class SyncStatusIndicator extends StatelessWidget {
  const SyncStatusIndicator({required this.state, required this.translations, this.onRetry, super.key});

  final SyncUiState state;
  final TranslationService translations;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final (IconData icon, String label) = switch (state.kind) {
      SyncUiKind.synced => (Icons.cloud_done_outlined, translations.t('mobile.sync.online')),
      SyncUiKind.offline => (Icons.cloud_off_outlined, translations.t('mobile.sync.offline')),
      SyncUiKind.syncing => (Icons.sync, translations.t('mobile.sync.syncing', params: <String, Object>{'count': state.pending})),
      SyncUiKind.error => (Icons.sync_problem_outlined, translations.t('mobile.sync.error')),
    };
    return Tooltip(
      message: label,
      child: InkWell(
        key: const Key('sync-indicator'),
        onTap: state.kind == SyncUiKind.error ? onRetry : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[Icon(icon, size: 18), const SizedBox(width: 4), Text(label)]),
        ),
      ),
    );
  }
}
