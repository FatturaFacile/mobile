import 'dart:async';

import 'package:dio/dio.dart';

import '../../../core/error/failure.dart';
import '../../../core/network/api_client.dart';
import '../models/field_service_models.dart';
import 'field_service_store.dart';

/// Reads the bytes of a photo kept on the phone at send time; null when the file is gone.
typedef FsmPhotoReader = Future<List<int>?> Function(String path);

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

/// Running counters of one flush.
class _Tally {
  int applied = 0;
  int duplicates = 0;
  int rejected = 0;
  int failed = 0;
  int deferred = 0;
  bool offline = false;
  bool unauthorized = false;

  FsmFlushReport toReport() => FsmFlushReport(
    applied: applied,
    duplicates: duplicates,
    rejected: rejected,
    failed: failed,
    deferred: deferred,
    offline: offline,
    unauthorized: unauthorized,
  );
}

/// What to do after sending a batch or a photo.
enum _Step {
  /// Carry on with the next operation.
  next,

  /// The server is struggling: the rest waits for the next cycle.
  pause,

  /// Offline or unauthorized: stop now (the flag is set on the tally).
  stop,
}

/// Sends the queued offline operations to `POST /api/v1/fsm/mobile-sync` and the photos to
/// `POST /api/v1/fsm/work-orders/{id}/photos`.
///
/// * Operations go oldest first, in batches of at most [batchSize] (the API takes 200), so a status change never overtakes
///   the one before it and the report is always applied after the parts it bills. A photo upload is sent on its own,
///   in its place in the queue, so the photos of a work order are always stored before its report; the server ids they
///   returned travel in the report as `photo_ids`.
/// * Every operation carries its `client_uuid`, generated when it was queued and resent unchanged on every retry. The
///   server answers `duplicate` (200 for a photo) for one it already applied, so a retry after a lost answer changes nothing.
/// * `rejected` results (field errors) are kept as conflicts for the technician and never resent on their own; one rejection
///   does not stop the rest of the batch. A photo whose file is gone, or that the server refuses (413, 422), is one too.
/// * Transient failures (5xx, 429) back off exponentially; being offline neither counts as an attempt nor delays anything.
class FieldServiceOutbox {
  FieldServiceOutbox(
    this._store,
    this._dio, {
    DateTime Function()? clock,
    this._readPhoto,
    this.batchSize = 200,
    this.baseBackoff = const Duration(seconds: 5),
    this.maxBackoff = const Duration(minutes: 15),
  }) : _clock = clock ?? DateTime.now;

  final FieldServiceStore _store;
  final Dio _dio;
  final DateTime Function() _clock;
  final FsmPhotoReader? _readPhoto;
  final int batchSize;
  final Duration baseBackoff;
  final Duration maxBackoff;

  static const String syncPath = '/fsm/mobile-sync';

  /// `POST` path of the photo upload of a work order.
  static String photosPath(String workOrderId) =>
      '/fsm/work-orders/$workOrderId/photos';

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
    final _Tally tally = _Tally();

    final DateTime now = _clock().toUtc();
    final List<FsmOperation> all = await _store.activeOperations(tenantId);
    final List<FsmOperation> due = <FsmOperation>[];
    var blocked = false;
    for (final FsmOperation op in all) {
      final DateTime? next = op.nextAttemptAt;
      // An operation that waits blocks its successors: a later one must not overtake it.
      if (blocked || (next != null && next.isAfter(now))) {
        blocked = true;
        tally.deferred++;
      } else {
        due.add(op);
      }
    }

    var i = 0;
    while (i < due.length) {
      final _Step step;
      if (due[i].type == FsmOperationType.photoUpload) {
        step = await _sendPhoto(due[i], tally);
        i++;
      } else {
        var end = i;
        while (end < due.length &&
            end - i < batchSize &&
            due[end].type != FsmOperationType.photoUpload) {
          end++;
        }
        step = await _sendBatch(due.sublist(i, end), tally);
        i = end;
      }
      if (step == _Step.stop) return tally.toReport();
      if (step == _Step.pause) {
        tally.deferred += due.length - i;
        return tally.toReport();
      }
    }
    return tally.toReport();
  }

  Future<_Step> _sendBatch(List<FsmOperation> chunk, _Tally tally) async {
    try {
      final List<Map<String, dynamic>> wire = <Map<String, dynamic>>[
        for (final FsmOperation o in chunk) await _wire(o),
      ];
      final Response<dynamic> res = await _dio.post<dynamic>(
        syncPath,
        data: <String, dynamic>{'operations': wire},
        options: Options(
          headers: <String, dynamic>{'Idempotency-Key': chunk.first.clientUuid},
        ),
      );
      final Map<String, FsmSyncResult> results = _results(res.data);
      for (final FsmOperation op in chunk) {
        final FsmSyncResult? result = results[op.clientUuid];
        if (result == null) {
          // The server did not account for it: try again later.
          await _fail(op, 'missing_result');
          tally.failed++;
        } else if (result.rejected) {
          await _store.markRejected(
            op.clientUuid,
            errors: result.errors,
            message: _summary(result.errors),
          );
          tally.rejected++;
        } else {
          await _acknowledge(op, result);
          if (result.duplicate) {
            tally.duplicates++;
          } else {
            tally.applied++;
          }
        }
      }
      return _Step.next;
    } on DioException catch (e) {
      final Failure f = mapDioError(e);
      if (f is NetworkFailure) {
        tally.offline = true;
        return _Step.stop;
      }
      if (f is UnauthorizedFailure) {
        tally.unauthorized = true;
        return _Step.stop;
      }
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
          tally.rejected++;
        } else {
          await _fail(
            op,
            f.message.isEmpty ? 'HTTP ${status ?? 0}' : f.message,
          );
          tally.failed++;
        }
      }
      return permanent ? _Step.next : _Step.pause;
    }
  }

  /// One entry of the batch. The report also names the photos the server already stored.
  Future<Map<String, dynamic>> _wire(FsmOperation op) async {
    if (op.type != FsmOperationType.serviceReport) return op.toWire();
    final List<String> ids = await _store.photoServerIds(
      op.tenantId,
      op.workOrderId,
    );
    if (ids.isEmpty) return op.toWire();
    return <String, dynamic>{
      ...op.toWire(),
      'payload': <String, dynamic>{...op.payload, 'photo_ids': ids},
    };
  }

  /// Uploads one photo as multipart, reading the file now. The same `client_uuid` goes out on every retry.
  Future<_Step> _sendPhoto(FsmOperation op, _Tally tally) async {
    final Object? localPath = op.payload['local_path'];
    final FsmPhotoReader? reader = _readPhoto;
    final List<int>? bytes = localPath is String && reader != null
        ? await reader(localPath)
        : null;
    if (bytes == null) {
      await _store.markRejected(
        op.clientUuid,
        errors: const <String, List<String>>{
          'photo': <String>['file_missing'],
        },
        message: 'file_missing',
      );
      tally.rejected++;
      return _Step.next;
    }
    final Object? stage = op.payload['stage'];
    final Object? caption = op.payload['caption'];
    final Object? capturedAt = op.payload['captured_at'];
    try {
      final Response<dynamic> res = await _dio.post<dynamic>(
        photosPath(op.workOrderId),
        // A FormData can be sent once: it is rebuilt on every attempt.
        data: FormData.fromMap(<String, dynamic>{
          'photo': MultipartFile.fromBytes(
            bytes,
            filename: '${op.payload['name'] ?? 'photo.jpg'}',
          ),
          'client_uuid': op.clientUuid,
          'stage': ?stage,
          'caption': ?caption,
          'captured_at': ?capturedAt,
        }),
        options: Options(
          headers: <String, dynamic>{'Idempotency-Key': op.clientUuid},
          // The shared retry interceptor would resend an already consumed FormData: the outbox backoff retries instead.
          extra: <String, dynamic>{'retry': 99},
        ),
      );
      final dynamic body = res.data;
      final dynamic data = body is Map ? body['data'] : null;
      final Object? id = data is Map ? data['id'] : null;
      if (id == null) {
        await _fail(op, 'invalid_response');
        tally.failed++;
        return _Step.pause;
      }
      await _store.setPhotoServerId(op.tenantId, op.clientUuid, '$id');
      final bool replay = res.statusCode == 200;
      await _store.markDone(
        op.clientUuid,
        replayed: replay,
        result: <String, dynamic>{
          'id': '$id',
          if (data is Map && data['url'] != null) 'url': data['url'],
        },
        now: _clock().toUtc(),
      );
      if (replay) {
        tally.duplicates++;
      } else {
        tally.applied++;
      }
      return _Step.next;
    } on DioException catch (e) {
      final Failure f = mapDioError(e);
      if (f is NetworkFailure) {
        tally.offline = true;
        return _Step.stop;
      }
      if (f is UnauthorizedFailure) {
        tally.unauthorized = true;
        return _Step.stop;
      }
      final int? status = f is ServerFailure ? f.statusCode : null;
      final bool permanent =
          f is ForbiddenFailure ||
          f is ValidationFailure ||
          f is ConflictFailure ||
          status == 404 ||
          status == 413;
      if (permanent) {
        await _store.markRejected(
          op.clientUuid,
          errors: f is ValidationFailure && f.fieldErrors.isNotEmpty
              ? f.fieldErrors
              : <String, List<String>>{
                  'photo': <String>[
                    status == 413 ? 'too_large' : 'HTTP ${status ?? 0}',
                  ],
                },
          message: f.message.isEmpty ? 'HTTP ${status ?? 0}' : f.message,
        );
        tally.rejected++;
        return _Step.next;
      }
      await _fail(op, f.message.isEmpty ? 'HTTP ${status ?? 0}' : f.message);
      tally.failed++;
      return _Step.pause;
    }
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
