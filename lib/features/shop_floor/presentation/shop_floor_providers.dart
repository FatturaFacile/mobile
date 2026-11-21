import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show TableUpdate;
import 'package:material_ui/material_ui.dart'
    show BuildContext, MaterialPageRoute, Navigator;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/database/app_database.dart';
import '../../wms/ui/scan_field.dart' show CameraScanner;
import '../data/shop_floor_outbox.dart';
import '../data/shop_floor_repository.dart';
import '../data/shop_floor_sync_worker.dart';
import '../domain/shop_floor_models.dart';
import 'camera_scanner_page.dart';

/// Absolute path of the SQLite file, set by `main`. When null (tests, in-memory databases) the outbox is flushed on the
/// main isolate instead of a background isolate.
final Provider<String?> shopFloorDatabasePathProvider = Provider<String?>(
  (Ref ref) => null,
);

final Provider<ShopFloorOutbox> shopFloorOutboxProvider =
    Provider<ShopFloorOutbox>(
      (Ref ref) =>
          ShopFloorOutbox(ref.watch(databaseProvider), ref.watch(dioProvider)),
    );

final Provider<ShopFloorRepository> shopFloorRepositoryProvider =
    Provider<ShopFloorRepository>(
      (Ref ref) => ShopFloorRepository(
        ref.watch(databaseProvider),
        ref.watch(dioProvider),
        ref.watch(shopFloorOutboxProvider),
      ),
    );

/// Opens the camera and returns the decoded code; tests override it with a fake.
final Provider<CameraScanner> shopFloorCameraScannerProvider =
    Provider<CameraScanner>(
      (Ref ref) =>
          (BuildContext context) => Navigator.of(context).push<String>(
            MaterialPageRoute<String>(
              builder: (_) => const CameraScannerPage(),
            ),
          ),
    );

final Provider<ShopFloorSyncCoordinator> shopFloorSyncProvider =
    Provider<ShopFloorSyncCoordinator>((Ref ref) {
      final ShopFloorOutbox outbox = ref.watch(shopFloorOutboxProvider);
      final ShopFloorRepository repo = ref.watch(shopFloorRepositoryProvider);
      final AppDatabase db = ref.watch(databaseProvider);
      final String? path = ref.watch(shopFloorDatabasePathProvider);
      final ShopFloorSyncCoordinator coordinator = ShopFloorSyncCoordinator(
        runner: (String tenantId) {
          final String token =
              ref.read(requestContextProvider).accessToken ?? '';
          if (path == null || token.isEmpty) {
            return outbox.flush(tenantId);
          }
          return flushOutboxInIsolate(
            ShopFloorSyncJob(
              databasePath: path,
              apiRoot: ref.read(appConfigProvider).apiRoot,
              token: token,
              tenantId: tenantId,
              languageCode: ref.read(requestContextProvider).languageCode,
            ),
          );
        },
        onCycleDone: (String tenantId, OutboxFlushReport report) async {
          // The isolate wrote through its own connection: tell this connection's streams.
          db.notifyUpdates(<TableUpdate>{TableUpdate.onTable(db.mfgOutbox)});
          if (report.offline || report.unauthorized) {
            return;
          }
          try {
            await repo.refresh(tenantId);
          } on DioException {
            // Offline or server error: the cached orders stay as they are.
          }
        },
      );
      ref.onDispose(coordinator.stop);
      return coordinator;
    });

final shopFloorOrdersProvider =
    StreamProvider.family<List<ProductionOrder>, String>(
      (Ref ref, String tenantId) =>
          ref.watch(shopFloorRepositoryProvider).watchOrders(tenantId),
    );

final shopFloorPendingProvider = StreamProvider.family<int, String>(
  (Ref ref, String tenantId) =>
      ref.watch(shopFloorOutboxProvider).watchPending(tenantId),
);

final shopFloorQueueProvider =
    StreamProvider.family<List<MfgOutboxRow>, String>(
      (Ref ref, String tenantId) =>
          ref.watch(shopFloorOutboxProvider).watchAll(tenantId),
    );
