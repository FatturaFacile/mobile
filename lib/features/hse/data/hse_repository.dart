import '../../../core/sync/sync_engine.dart';
import '../models/hse_models.dart';

/// Entities of the HSE outbox rows.
const String hsePpeEntity = 'hse_ppe_distribution';
const String hseToolBoxEntity = 'hse_toolbox_talk';
const String hseNearMissEntity = 'hse_near_miss';

/// Contract of the HSE capture screens (fakeable in tests). Every method returns as soon as the record is safe on the device.
abstract class HseRepository {
  /// Queues a signed PPE hand-over; the server decrements the stock, hashes the signature and files the PDF.
  Future<String> queuePpeHandOver(PpeHandOver handOver);

  /// Queues a tool-box talk with all its signatures as one batch.
  Future<String> queueToolBoxTalk(ToolBoxTalk talk);

  /// Queues a near-miss report.
  Future<String> queueNearMiss(NearMissReport report);

  /// Writes not yet acknowledged by the server (offline queue size).
  Stream<int> watchPending();
}

/// Outbox implementation on the generic [SyncEngine]: the write is stored in the local SQLite queue first and the engine
/// sends it, in order, whenever the device is online (the orchestrator flushes in the background).
class SyncEngineHseRepository implements HseRepository {
  SyncEngineHseRepository(this._engine, {required this.tenantId});

  final SyncEngine _engine;
  final String tenantId;

  @override
  Future<String> queuePpeHandOver(PpeHandOver handOver) => _engine.enqueueCommand(
        tenantId: tenantId,
        entity: hsePpeEntity,
        path: '/hse/ppe-distributions',
        data: handOver.toJson(),
      );

  @override
  Future<String> queueToolBoxTalk(ToolBoxTalk talk) => _engine.enqueueCommand(
        tenantId: tenantId,
        entity: hseToolBoxEntity,
        path: '/hse/toolbox-talks',
        data: talk.toJson(),
      );

  @override
  Future<String> queueNearMiss(NearMissReport report) => _engine.enqueueCommand(
        tenantId: tenantId,
        entity: hseNearMissEntity,
        path: '/hse/incidents',
        data: report.toJson(),
      );

  @override
  Stream<int> watchPending() => _engine.watchPending(tenantId);
}
