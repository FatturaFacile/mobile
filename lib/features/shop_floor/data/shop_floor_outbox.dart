import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/error/failure.dart';
import '../../../core/network/api_client.dart';
import 'local/shop_floor_tables.dart';

/// Result of one [ShopFloorOutbox.flush] run.
class OutboxFlushReport {
  const OutboxFlushReport({
    this.sent = 0,
    this.replayed = 0,
    this.failed = 0,
    this.rejected = 0,
    this.deferred = 0,
    this.offline = false,
    this.unauthorized = false,
  });

  /// Acknowledged with 200/201 (includes [replayed]).
  final int sent;

  /// Acknowledged with 200: the posting had already been applied by an earlier, unacknowledged attempt.
  final int replayed;

  /// Transient failures scheduled for a later retry.
  final int failed;

  /// Refused for good (needs a supervisor).
  final int rejected;

  /// Rows skipped because their backoff has not elapsed, a predecessor of the same order is blocked, or a parent is open.
  final int deferred;
  final bool offline;
  final bool unauthorized;
}

/// Persistent, ordered, idempotent mutation queue of the shop floor.
///
/// * Rows are sent oldest first. If a row of a production order fails transiently, every later row of the **same order**
///   waits (an issue must never overtake the one before it), while other orders keep flowing.
/// * The row `uuid` is generated once at enqueue time and is resent unchanged on every retry as `Idempotency-Key`; for
///   confirmations it is also the `operation_posting_uuid`, so HTTP 200 means "already applied".
/// * Transient failures back off exponentially ([baseBackoff] * 2^(attempts-1), capped at [maxBackoff]); being offline
///   neither counts as an attempt nor delays the row.
class ShopFloorOutbox {
  ShopFloorOutbox(
    this._db,
    this._dio, {
    Uuid? uuid,
    DateTime Function()? clock,
    this.baseBackoff = const Duration(seconds: 5),
    this.maxBackoff = const Duration(minutes: 15),
  }) : _uuid = uuid ?? const Uuid(),
       _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final Dio _dio;
  final Uuid _uuid;
  final DateTime Function() _clock;
  final Duration baseBackoff;
  final Duration maxBackoff;

  static const String _root = '/manufacturing';

  /// Delay before attempt number [attempts]+1 after [attempts] transient failures.
  Duration backoffFor(int attempts) {
    final int exp = (attempts - 1).clamp(0, 20);
    final int ms = baseBackoff.inMilliseconds * (1 << exp);
    return Duration(
      milliseconds: ms > maxBackoff.inMilliseconds
          ? maxBackoff.inMilliseconds
          : ms,
    );
  }

  /// Number of mutations not yet acknowledged.
  Stream<int> watchPending(String tenantId) {
    return (_db.select(_db.mfgOutbox)..where(
          (MfgOutbox t) =>
              t.tenantId.equals(tenantId) &
              t.state.isIn(<int>[OutboxState.pending, OutboxState.failed]),
        ))
        .watch()
        .map((List<MfgOutboxRow> r) => r.length);
  }

  /// Rows of one tenant, oldest first (any state).
  Stream<List<MfgOutboxRow>> watchAll(String tenantId) {
    return (_db.select(_db.mfgOutbox)
          ..where((MfgOutbox t) => t.tenantId.equals(tenantId))
          ..orderBy(<OrderingTerm Function(MfgOutbox)>[
            (MfgOutbox t) => OrderingTerm.asc(t.sequence),
          ]))
        .watch();
  }

  Future<List<MfgOutboxRow>> all(String tenantId) {
    return (_db.select(_db.mfgOutbox)
          ..where((MfgOutbox t) => t.tenantId.equals(tenantId))
          ..orderBy(<OrderingTerm Function(MfgOutbox)>[
            (MfgOutbox t) => OrderingTerm.asc(t.sequence),
          ]))
        .get();
  }

  /// Queues one mutation. Pass [uuid] to use a key generated earlier (confirmations); a new UUID v4 otherwise.
  /// Safe to call inside a transaction.
  Future<String> enqueue({
    required String tenantId,
    required String kind,
    required String orderId,
    required String path,
    required Map<String, dynamic> payload,
    String? uuid,
    String? dependsOn,
  }) async {
    final String key = uuid ?? _uuid.v4();
    await _db
        .into(_db.mfgOutbox)
        .insert(
          MfgOutboxCompanion.insert(
            uuid: key,
            tenantId: tenantId,
            kind: kind,
            orderId: orderId,
            path: path,
            payload: jsonEncode(payload),
            dependsOn: Value<String?>(dependsOn),
            createdAt: _clock().toUtc(),
          ),
        );
    return key;
  }

  /// Puts a rejected or failed row back in line (the supervisor fixed the cause). The uuid is kept.
  Future<void> retry(String uuid) async {
    await (_db.update(_db.mfgOutbox)..where(
          (MfgOutbox t) =>
              t.uuid.equals(uuid) & t.state.isNotValue(OutboxState.done),
        ))
        .write(
          const MfgOutboxCompanion(
            state: Value<int>(OutboxState.pending),
            nextAttemptAt: Value<DateTime?>(null),
            lastError: Value<String?>(null),
          ),
        );
  }

  /// Drops an unsent row (never an acknowledged one).
  Future<void> discard(String uuid) async {
    await (_db.delete(_db.mfgOutbox)..where(
          (MfgOutbox t) =>
              t.uuid.equals(uuid) & t.state.isNotValue(OutboxState.done),
        ))
        .go();
  }

  /// Sends every due row. Never throws on transport errors.
  Future<OutboxFlushReport> flush(String tenantId) async {
    int sent = 0;
    int replayed = 0;
    int failed = 0;
    int rejected = 0;
    int deferred = 0;
    final Set<String> blockedOrders = <String>{};
    final DateTime now = _clock().toUtc();
    final List<MfgOutboxRow> rows =
        await (_db.select(_db.mfgOutbox)
              ..where(
                (MfgOutbox t) =>
                    t.tenantId.equals(tenantId) &
                    t.state.isIn(<int>[
                      OutboxState.pending,
                      OutboxState.failed,
                    ]),
              )
              ..orderBy(<OrderingTerm Function(MfgOutbox)>[
                (MfgOutbox t) => OrderingTerm.asc(t.sequence),
              ]))
            .get();

    OutboxFlushReport report({
      bool offline = false,
      bool unauthorized = false,
    }) => OutboxFlushReport(
      sent: sent,
      replayed: replayed,
      failed: failed,
      rejected: rejected,
      deferred: deferred,
      offline: offline,
      unauthorized: unauthorized,
    );

    for (final MfgOutboxRow row in rows) {
      final DateTime? due = row.nextAttemptAt;
      final bool notDue = due != null && due.isAfter(now);
      if (blockedOrders.contains(row.orderId) ||
          notDue ||
          (row.dependsOn != null && !await _isDone(row.dependsOn!))) {
        // A row that waits also blocks its successors of the same order, otherwise they would overtake it.
        blockedOrders.add(row.orderId);
        deferred++;
        continue;
      }
      try {
        final Response<dynamic> res = await _dio.request<dynamic>(
          '$_root${row.path}',
          data: jsonDecode(row.payload),
          options: Options(
            method: row.method,
            headers: <String, dynamic>{'Idempotency-Key': row.uuid},
          ),
        );
        final bool replay =
            res.statusCode == 200 && row.kind == OutboxKind.confirm;
        await (_db.update(
          _db.mfgOutbox,
        )..where((MfgOutbox t) => t.uuid.equals(row.uuid))).write(
          MfgOutboxCompanion(
            state: const Value<int>(OutboxState.done),
            replayed: Value<bool>(replay),
            completedAt: Value<DateTime?>(_clock().toUtc()),
            lastError: const Value<String?>(null),
            nextAttemptAt: const Value<DateTime?>(null),
          ),
        );
        sent++;
        if (replay) {
          replayed++;
        }
      } on DioException catch (e) {
        final Failure f = mapDioError(e);
        if (f is NetworkFailure) {
          return report(offline: true);
        }
        if (f is UnauthorizedFailure) {
          return report(unauthorized: true);
        }
        final int? status = f is ServerFailure ? f.statusCode : null;
        final bool permanent =
            f is ForbiddenFailure ||
            f is ValidationFailure ||
            f is ConflictFailure ||
            status == 404;
        if (permanent) {
          await _mark(row, OutboxState.rejected, f.message, null);
          rejected++;
        } else {
          final int attempts = row.attempts + 1;
          await _mark(
            row,
            OutboxState.failed,
            f.message.isEmpty ? 'HTTP ${status ?? 0}' : f.message,
            now.add(backoffFor(attempts)),
            attempts: attempts,
          );
          blockedOrders.add(row.orderId);
          failed++;
        }
      }
    }
    return report();
  }

  Future<bool> _isDone(String uuid) async {
    final MfgOutboxRow? parent = await (_db.select(
      _db.mfgOutbox,
    )..where((MfgOutbox t) => t.uuid.equals(uuid))).getSingleOrNull();
    return parent == null || parent.state == OutboxState.done;
  }

  Future<void> _mark(
    MfgOutboxRow row,
    int state,
    String message,
    DateTime? next, {
    int? attempts,
  }) async {
    await (_db.update(
      _db.mfgOutbox,
    )..where((MfgOutbox t) => t.uuid.equals(row.uuid))).write(
      MfgOutboxCompanion(
        state: Value<int>(state),
        attempts: Value<int>(attempts ?? row.attempts + 1),
        lastError: Value<String?>(message),
        nextAttemptAt: Value<DateTime?>(next),
      ),
    );
  }
}
