import '../domain/project_billing_models.dart';
import 'project_billing_local_data_source.dart';
import 'project_billing_remote_data_source.dart';

/// Contract of the billing view (fakeable in tests): the cache is read at once, the sync refreshes it.
abstract class ProjectBillingRepository {
  Future<ProjectBillingSnapshot?> cached(String tenantId, String projectId);

  Future<BillingSyncResult> sync(String tenantId, String projectId);
}

/// Cache-first repository: the figures of the last sync are served offline, and a payload that does not parse never
/// replaces a good cache.
class ProjectBillingRepositoryImpl implements ProjectBillingRepository {
  ProjectBillingRepositoryImpl(
    this._local,
    this._remote, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final ProjectBillingLocalDataSource _local;
  final ProjectBillingRemoteDataSource _remote;
  final DateTime Function() _now;

  @override
  Future<ProjectBillingSnapshot?> cached(
    String tenantId,
    String projectId,
  ) async {
    final BillingStoredPayload? stored = await _local.snapshot(
      tenantId,
      projectId,
    );
    if (stored == null) {
      return null;
    }
    try {
      return _parse(stored.json, stored.syncedAt);
    } on FormatException {
      return null;
    }
  }

  @override
  Future<BillingSyncResult> sync(String tenantId, String projectId) async {
    try {
      final Map<String, dynamic> summary = await _remote.summary(projectId);
      final Map<String, dynamic>? contract = await _remote.contract(projectId);
      final List<dynamic> certificates = await _remote.certificates(projectId);
      final Map<String, dynamic>? retention = contract == null
          ? null
          : await _remote.retention(projectId);
      final Map<String, dynamic>? retainer = contract == null
          ? null
          : await _remote.retainer(projectId);
      final DateTime now = _now().toUtc();

      final Map<String, dynamic> payload = <String, dynamic>{
        'summary': summary,
        'contract': contract,
        'certificates': certificates,
        'retention': retention,
        'retainer': retainer,
      };

      // Parse before saving: a payload that does not parse must never replace a good cache.
      _parse(payload, now);

      await _local.saveSnapshot(tenantId, projectId, payload, now);
      return const BillingSyncResult(BillingSyncStatus.synced);
    } on BillingRemoteException catch (e) {
      return BillingSyncResult(_status(e.kind), detail: e.detail);
    } on FormatException catch (e) {
      return BillingSyncResult(BillingSyncStatus.failed, detail: e.message);
    }
  }

  static ProjectBillingSnapshot _parse(
    Map<String, dynamic> json,
    DateTime syncedAt,
  ) => ProjectBillingSnapshot.fromParts(
    summary: _map(json['summary']) ?? <String, dynamic>{},
    certificates: json['certificates'] is List
        ? json['certificates'] as List<dynamic>
        : <dynamic>[],
    syncedAt: syncedAt,
    contract: _map(json['contract']),
    retainer: _map(json['retainer']),
    retention: _map(json['retention']),
  );

  static Map<String, dynamic>? _map(Object? value) =>
      value is Map ? Map<String, dynamic>.from(value) : null;

  static BillingSyncStatus _status(BillingErrorKind kind) => switch (kind) {
    BillingErrorKind.offline => BillingSyncStatus.offline,
    BillingErrorKind.unauthorized => BillingSyncStatus.unauthorized,
    BillingErrorKind.forbidden => BillingSyncStatus.forbidden,
    BillingErrorKind.notFound => BillingSyncStatus.failed,
    BillingErrorKind.failed => BillingSyncStatus.failed,
  };
}
