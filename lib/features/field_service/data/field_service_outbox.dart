import 'dart:async';

import 'package:dio/dio.dart';

import '../../../core/error/failure.dart';
import '../../../core/network/api_client.dart';
import '../models/field_service_models.dart';
import 'field_service_store.dart';

/// Result of one [FieldServiceOutbox.flush] run.
class FsmFlushReport {
  const FsmFlushReport({
    this.applied = 0,
    this.duplicates = 0,
    this.rejected = 0,
    this.failed = 0,
    this.deferred = 0,
    this.offline = false,
    this.unauthorized = false,
  });

  /// Acknowledged as `applied`.
  final int applied;

  /// Acknowledged as `duplicate`: an earlier attempt, whose answer was lost, had already been applied.
  final int duplicates;

  /// Refused by the server (the conflict report): kept for the technician.
  final int rejected;

  /// Transient failures scheduled for a later retry.
  final int failed;

  /// Operations skipped because their backoff has not elapsed.
  final int deferred;
  final bool offline;
  final bool unauthorized;

  int get sent => applied + duplicates;
}

/// Sends the queued offline operations to `POST /api/v1/fsm/mobile-sync`.
///
/// * Operations go oldest first, in batches of at most [batchSize] (the API takes 200), so a status change never overtakes
///   the one before it and the report is always applied after the parts it bills.
/// * Every operation carries its `client_uuid`, generated when it was queued and resent unchanged on every retry. The
///   server answers `duplicate` for one it already applied, so a retry after a lost answer changes nothing.
/// * `rejected` results (field errors) are kept as conflicts for the technician and never resent on their own; one rejection
///   does not stop the rest of the batch.
/// * Transient failures (5xx, 429) back off exponentially; being offline neither counts as an attempt nor delays anything.
class FieldServiceOutbox {
  FieldServiceOutbox(
    this._store,
    this._dio, {
    DateTime Function()? clock,
    this.batchSize = 200,
    this.baseBackoff = const Duration(seconds: 5),
    this.maxBackoff = const Duration(minutes: 15),
  }) : _clock = clock ?? DateTime.now;

  final FieldServiceStore _store;
  final Dio _dio;
  final DateTime Function() _clock;
  final int batchSize;
  final Duration baseBackoff;
  final Duration maxBackoff;

  static const String syncPath = '/fsm/mobile-sync';

  Future<FsmFlushReport>? _running;

  /// Delay before the attempt that follows [attempts] transient failures.
  Duration backoffFor(int attempts) {
    final int exp = (attempts - 1).clamp(0, 20);
    final int ms = baseBackoff.inMilliseconds * (1 << exp);
    return Duration(
      milliseconds: ms > maxBackoff.inMilliseconds
          ? maxBackoff.inMilliseconds
          : ms,
    );
  }

  /// Sends every due operation. Never throws on transport errors; a flush already running is joined, not repeated.
  Future<FsmFlushReport> flush(String tenantId) =>
      _running ??= _flush(tenantId).whenComplete(() => _running = null);

  Future<FsmFlushReport> _flush(String tenantId) async {
    var applied = 0;
    var duplicates = 0;
    var rejected = 0;
    var failed = 0;
    var deferred = 0;

    FsmFlushReport report({bool offline = false, bool unauthorized = false}) =>
        FsmFlushReport(
          applied: applied,
          duplicates: duplicates,
          rejected: rejected,
          failed: failed,
          deferred: deferred,
          offline: offline,
          unauthorized: unauthorized,
        );

    final DateTime now = _clock().toUtc();
    final List<FsmOperation> all = await _store.activeOperations(tenantId);
    final List<FsmOperation> due = <FsmOperation>[];
    var blocked = false;
    for (final FsmOperation op in all) {
      final DateTime? next = op.nextAttemptAt;
      // An operation that waits blocks its successors: a later one must not overtake it.
      if (blocked || (next != null && next.isAfter(now))) {
        blocked = true;
        deferred++;
      } else {
        due.add(op);
      }
    }

    for (var i = 0; i < due.length; i += batchSize) {
      final List<FsmOperation> chunk = due.sublist(
        i,
        i + batchSize > due.length ? due.length : i + batchSize,
      );
      try {
        final Response<dynamic> res = await _dio.post<dynamic>(
          syncPath,
          data: <String, dynamic>{
            'operations': chunk.map((FsmOperation o) => o.toWire()).toList(),
          },
          options: Options(
            headers: <String, dynamic>{
              'Idempotency-Key': chunk.first.clientUuid,
            },
          ),
        );
        final Map<String, FsmSyncResult> results = _results(res.data);
        for (final FsmOperation op in chunk) {
          final FsmSyncResult? result = results[op.clientUuid];
          if (result == null) {
            // The server did not account for it: try again later.
            await _fail(op, 'missing_result');
            failed++;
          } else if (result.rejected) {
            await _store.markRejected(
              op.clientUuid,
              errors: result.errors,
              message: _summary(result.errors),
            );
            rejected++;
          } else {
            await _acknowledge(op, result);
            if (result.duplicate) {
              duplicates++;
            } else {
              applied++;
            }
          }
        }
      } on DioException catch (e) {
        final Failure f = mapDioError(e);
        if (f is NetworkFailure) return report(offline: true);
        if (f is UnauthorizedFailure) return report(unauthorized: true);
        final int? status = f is ServerFailure ? f.statusCode : null;
        final bool permanent =
            f is ForbiddenFailure ||
            f is ValidationFailure ||
            f is ConflictFailure ||
            status == 404;
        for (final FsmOperation op in chunk) {
          if (permanent) {
            await _store.markRejected(
              op.clientUuid,
              errors: f is ValidationFailure
                  ? f.fieldErrors
                  : const <String, List<String>>{},
              message: f.message.isEmpty ? 'HTTP ${status ?? 0}' : f.message,
            );
            rejected++;
          } else {
            await _fail(
              op,
              f.message.isEmpty ? 'HTTP ${status ?? 0}' : f.message,
            );
            failed++;
          }
        }
        if (!permanent) {
          // The server is struggling: the later batches wait for the next cycle.
          deferred += due.length - (i + chunk.length);
          return report();
        }
      }
    }
    return report();
  }

  Map<String, FsmSyncResult> _results(dynamic body) {
    final dynamic data = body is Map ? body['data'] : null;
    final dynamic rows = data is Map ? data['results'] : null;
    return <String, FsmSyncResult>{
      if (rows is List)
        for (final dynamic row in rows)
          if (row is Map)
            '${row['client_uuid']}': FsmSyncResult.fromJson(
              Map<String, dynamic>.from(row),
            ),
    };
  }

  Future<void> _fail(FsmOperation op, String message) => _store.markFailed(
    op.clientUuid,
    message: message,
    nextAttemptAt: _clock().toUtc().add(backoffFor(op.attempts + 1)),
  );

  Future<void> _acknowledge(FsmOperation op, FsmSyncResult result) async {
    await _store.markDone(
      op.clientUuid,
      replayed: result.duplicate,
      result: result.extra,
      now: _clock().toUtc(),
    );
    if (op.type == FsmOperationType.serviceReport) {
      await _store.markReportAcknowledged(
        op.tenantId,
        op.clientUuid,
        reportNumber: result.extra['report_number'] as String?,
        serverSealHash: result.extra['signature_sha256_hash'] as String?,
      );
    }
  }

  String _summary(Map<String, List<String>> errors) => errors.entries
      .map(
        (MapEntry<String, List<String>> e) => '${e.key}: ${e.value.join(', ')}',
      )
      .join('; ');
}
