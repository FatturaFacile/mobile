import '../domain/project_evm_models.dart';
import 'project_evm_local_data_source.dart';
import 'project_evm_remote_data_source.dart';

/// Contract of the profitability view (fakeable in tests): the cache is read at once, the sync refreshes it.
abstract class ProjectEvmRepository {
  /// The projects the picker offers, from the cache.
  Future<List<EvmProjectRef>> cachedProjects(String tenantId);

  /// Pulls the project list into the cache.
  Future<EvmSyncResult> syncProjects(String tenantId);

  Future<ProjectEvmSnapshot?> cached(String tenantId, String projectId);

  Future<EvmSyncResult> sync(String tenantId, String projectId);
}

/// Cache-first repository: the figures of the last sync are served offline, and a payload that does not parse never
/// replaces a good cache.
class ProjectEvmRepositoryImpl implements ProjectEvmRepository {
  ProjectEvmRepositoryImpl(
    this._local,
    this._remote, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final ProjectEvmLocalDataSource _local;
  final ProjectEvmRemoteDataSource _remote;
  final DateTime Function() _now;

  @override
  Future<List<EvmProjectRef>> cachedProjects(String tenantId) async {
    final EvmStoredPayload? stored = await _local.projectIndex(tenantId);
    return stored == null
        ? <EvmProjectRef>[]
        : _projects(stored.json['projects']);
  }

  @override
  Future<EvmSyncResult> syncProjects(String tenantId) async {
    try {
      final List<dynamic> projects = await _remote.projects();
      await _local.saveProjectIndex(tenantId, projects, _now().toUtc());
      return const EvmSyncResult(EvmSyncStatus.synced);
    } on EvmRemoteException catch (e) {
      return EvmSyncResult(_status(e.kind), detail: e.detail);
    }
  }

  @override
  Future<ProjectEvmSnapshot?> cached(String tenantId, String projectId) async {
    final EvmStoredPayload? stored = await _local.snapshot(tenantId, projectId);
    if (stored == null) {
      return null;
    }
    return ProjectEvmSnapshot.fromParts(
      breakdown: _part(stored.json, 'breakdown'),
      waterfall: _part(stored.json, 'waterfall'),
      scurve: _part(stored.json, 'scurve'),
      syncedAt: stored.syncedAt,
    );
  }

  @override
  Future<EvmSyncResult> sync(String tenantId, String projectId) async {
    try {
      final Map<String, dynamic> breakdown = await _remote.breakdown(projectId);
      final Map<String, dynamic> waterfall = await _remote.waterfall(projectId);
      final Map<String, dynamic> scurve = await _remote.scurve(projectId);
      final DateTime now = _now().toUtc();

      // Parse before saving: a payload that does not parse must never replace a good cache.
      ProjectEvmSnapshot.fromParts(
        breakdown: breakdown,
        waterfall: waterfall,
        scurve: scurve,
        syncedAt: now,
      );

      await _local.saveSnapshot(tenantId, projectId, <String, dynamic>{
        'breakdown': breakdown,
        'waterfall': waterfall,
        'scurve': scurve,
      }, now);
      return const EvmSyncResult(EvmSyncStatus.synced);
    } on EvmRemoteException catch (e) {
      return EvmSyncResult(_status(e.kind), detail: e.detail);
    } on FormatException catch (e) {
      return EvmSyncResult(EvmSyncStatus.failed, detail: e.message);
    }
  }

  static EvmSyncStatus _status(EvmErrorKind kind) => switch (kind) {
    EvmErrorKind.offline => EvmSyncStatus.offline,
    EvmErrorKind.unauthorized => EvmSyncStatus.unauthorized,
    EvmErrorKind.forbidden => EvmSyncStatus.forbidden,
    EvmErrorKind.failed => EvmSyncStatus.failed,
  };

  static Map<String, dynamic> _part(Map<String, dynamic> json, String key) {
    final Object? part = json[key];
    return part is Map ? Map<String, dynamic>.from(part) : <String, dynamic>{};
  }

  static List<EvmProjectRef> _projects(Object? value) => value is List
      ? value
            .whereType<Map<dynamic, dynamic>>()
            .map(
              (Map<dynamic, dynamic> item) =>
                  EvmProjectRef.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList()
      : <EvmProjectRef>[];
}
