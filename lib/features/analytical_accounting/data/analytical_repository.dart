import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../domain/analytical_models.dart';
import 'analytical_local_data_source.dart';
import 'analytical_remote_data_source.dart';

/// Contract of the analytical accounting page (fakeable in tests): the cache is read at once, the sync flushes the offline queue
/// and refreshes the cache.
abstract class AnalyticalRepository {
  Future<AnalyticalOverview> overview(String tenantId);

  /// Captures a manual entry offline: validated, then queued for the next sync. Returns the error codes, empty when queued.
  Future<List<String>> queueEntry(String tenantId, EntryDraft draft);

  Future<AnalyticalSyncResult> sync(
    String tenantId, {
    String? from,
    String? to,
  });
}

/// Cache-first repository: the figures of the last sync are served offline, queued entries go first, and a payload that does not
/// parse never replaces a good cache.
class AnalyticalRepositoryImpl implements AnalyticalRepository {
  AnalyticalRepositoryImpl(
    this._local,
    this._remote, {
    DateTime Function()? now,
    Uuid? uuid,
  }) : _now = now ?? DateTime.now,
       _uuid = uuid ?? const Uuid();

  final AnalyticalLocalDataSource _local;
  final AnalyticalRemoteDataSource _remote;
  final DateTime Function() _now;
  final Uuid _uuid;

  @override
  Future<AnalyticalOverview> overview(String tenantId) async {
    final AnalyticalStoredPayload? centers = await _local.snapshot(
      tenantId,
      analyticalCentersId,
    );
    final AnalyticalStoredPayload? runs = await _local.snapshot(
      tenantId,
      analyticalRunsId,
    );
    final AnalyticalStoredPayload? margin = await _local.snapshot(
      tenantId,
      analyticalMarginId,
    );
    final AnalyticalStoredPayload? comparison = await _local.snapshot(
      tenantId,
      analyticalComparisonId,
    );
    return AnalyticalOverview(
      centers: centers == null
          ? <AnalyticalCenter>[]
          : parseCenters(centers.data),
      runs: runs == null ? <ApportionmentRun>[] : parseRuns(runs.data),
      margin: margin == null
          ? null
          : ContributionMargin.fromJson(margin.data as Map<dynamic, dynamic>),
      comparison: comparison == null
          ? <ComparisonRow>[]
          : parseComparison(comparison.data),
      syncedAt: margin?.syncedAt ?? centers?.syncedAt,
      pending: await _local.pendingCount(tenantId),
    );
  }

  @override
  Future<List<String>> queueEntry(String tenantId, EntryDraft draft) async {
    final List<String> errors = draft.validate();
    if (errors.isNotEmpty) {
      return errors;
    }
    await _local.enqueue(
      tenantId,
      _uuid.v4(),
      draft.toJsonText(),
      _now().toUtc(),
    );
    return <String>[];
  }

  @override
  Future<AnalyticalSyncResult> sync(
    String tenantId, {
    String? from,
    String? to,
  }) async {
    try {
      final List<int> flushed = await _flush(tenantId);
      final dynamic centers = await _remote.centers();
      final dynamic runs = await _remote.runs();
      final dynamic margin = await _remote.margin(from: from, to: to);
      final dynamic comparison = await _remote.comparison(from: from, to: to);

      // Parse before saving: a payload that does not parse must never replace a good cache.
      parseCenters(centers);
      parseRuns(runs);
      ContributionMargin.fromJson(margin as Map<dynamic, dynamic>);
      parseComparison(comparison);

      final DateTime now = _now().toUtc();
      await _local.saveSnapshot(tenantId, analyticalCentersId, centers, now);
      await _local.saveSnapshot(tenantId, analyticalRunsId, runs, now);
      await _local.saveSnapshot(tenantId, analyticalMarginId, margin, now);
      await _local.saveSnapshot(
        tenantId,
        analyticalComparisonId,
        comparison,
        now,
      );
      return AnalyticalSyncResult(
        AnalyticalSyncStatus.synced,
        sent: flushed[0],
        failed: flushed[1],
      );
    } on AnalyticalRemoteException catch (e) {
      return AnalyticalSyncResult(_status(e.kind), detail: e.detail);
    } on AnalyticalFormatException catch (e) {
      return AnalyticalSyncResult(
        AnalyticalSyncStatus.failed,
        detail: e.message,
      );
    } on TypeError catch (e) {
      return AnalyticalSyncResult(
        AnalyticalSyncStatus.failed,
        detail: e.toString(),
      );
    }
  }

  /// Sends the queued entries oldest first: an accepted one is marked sent, a refused one parked, and an unreachable server
  /// leaves it pending. Returns `[sent, failed]`.
  Future<List<int>> _flush(String tenantId) async {
    int sent = 0;
    int failed = 0;
    for (final PendingOperation operation in await _local.pending(tenantId)) {
      final AnalyticalPostReply reply = await _remote.postEntry(
        _decode(operation.body),
      );
      switch (reply.outcome) {
        case AnalyticalPostOutcome.accepted:
          await _local.markSent(tenantId, operation.id, _now().toUtc());
          sent++;
        case AnalyticalPostOutcome.refused:
          await _local.markFailed(
            tenantId,
            operation.id,
            reply.detail,
            _now().toUtc(),
          );
          failed++;
        case AnalyticalPostOutcome.retryLater:
          break;
      }
    }
    return <int>[sent, failed];
  }

  Map<String, dynamic> _decode(String body) =>
      Map<String, dynamic>.from(jsonDecode(body) as Map<dynamic, dynamic>);

  AnalyticalSyncStatus _status(AnalyticalErrorKind kind) => switch (kind) {
    AnalyticalErrorKind.offline => AnalyticalSyncStatus.offline,
    AnalyticalErrorKind.unauthorized => AnalyticalSyncStatus.unauthorized,
    AnalyticalErrorKind.forbidden => AnalyticalSyncStatus.forbidden,
    AnalyticalErrorKind.failed => AnalyticalSyncStatus.failed,
  };
}
