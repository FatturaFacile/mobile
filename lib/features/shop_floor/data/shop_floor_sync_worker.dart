import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';

import '../../../core/database/app_database.dart';
import 'shop_floor_outbox.dart';

/// Everything the worker isolate needs to talk to the API and the same SQLite file (all plain, sendable values).
class ShopFloorSyncJob {
  const ShopFloorSyncJob({
    required this.databasePath,
    required this.apiRoot,
    required this.token,
    required this.tenantId,
    required this.languageCode,
  });

  final String databasePath;
  final String apiRoot;
  final String token;
  final String tenantId;
  final String languageCode;
}

/// Flushes the outbox in a short-lived background isolate with its own SQLite connection, so a slow network never
/// blocks a frame on the operator terminal. The uuid of every row travels with it, so a retry after a lost response is
/// recognised by the server as a replay.
Future<OutboxFlushReport> flushOutboxInIsolate(ShopFloorSyncJob job) {
  return Isolate.run<OutboxFlushReport>(() async {
    final AppDatabase db = AppDatabase(NativeDatabase(File(job.databasePath)));
    final Dio dio = Dio(
      BaseOptions(
        baseUrl: job.apiRoot,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        headers: <String, dynamic>{
          'Accept': 'application/json',
          'Authorization': 'Bearer ${job.token}',
          'X-Tenant-Id': job.tenantId,
          'X-Language-Code': job.languageCode,
          'Accept-Language': job.languageCode,
        },
      ),
    );
    try {
      return await ShopFloorOutbox(db, dio).flush(job.tenantId);
    } finally {
      dio.close();
      await db.close();
    }
  });
}

/// Runs one background cycle for a tenant.
typedef OutboxRunner = Future<OutboxFlushReport> Function(String tenantId);

/// Periodic and event-driven trigger of the outbox worker. At most one cycle runs at a time; [syncNow] never throws.
class ShopFloorSyncCoordinator {
  ShopFloorSyncCoordinator({
    required this._runner,
    required this.onCycleDone,
    this.interval = const Duration(seconds: 30),
  });

  final OutboxRunner _runner;

  /// Called after every cycle on the main isolate (refresh read models, notify UI streams).
  final Future<void> Function(String tenantId, OutboxFlushReport report)
  onCycleDone;
  final Duration interval;
  Timer? _timer;
  bool _running = false;

  void start(String tenantId) {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => syncNow(tenantId));
    unawaited(syncNow(tenantId));
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<OutboxFlushReport?> syncNow(String tenantId) async {
    if (_running) {
      return null;
    }
    _running = true;
    try {
      final OutboxFlushReport report = await _runner(tenantId);
      await onCycleDone(tenantId, report);
      return report;
    } catch (_) {
      // Best effort: the queue is persistent, so the next cycle resumes where this one stopped.
      return null;
    } finally {
      _running = false;
    }
  }
}
