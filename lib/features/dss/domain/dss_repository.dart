import 'dss_models.dart';

/// How a DSS sync attempt ended.
enum DssSyncStatus {
  /// The snapshot was pulled and stored.
  synced,

  /// The server could not be reached: the cached snapshot (if any) stays in use.
  offline,

  /// There is no session or it expired: the user has to sign in.
  unauthorized,

  /// The user may not read the Executive DSS on the server.
  forbidden,

  /// The server answered with an error.
  failed,
}

/// The outcome of a sync attempt.
class DssSyncResult {
  const DssSyncResult(this.status, {this.syncedAt, this.detail = ''});

  final DssSyncStatus status;

  /// When the snapshot was pulled (only for [DssSyncStatus.synced]).
  final DateTime? syncedAt;
  final String detail;
}

/// Offline cache and sync of the Executive DSS snapshots, scoped to a tenant.
abstract interface class DssRepository {
  /// The snapshot cached for [filter], or null when nothing was pulled for it yet. Never touches the network.
  Future<DssSnapshot?> cached(String tenantId, DssFilter filter);

  /// Pulls the snapshot of [filter] and stores it in one piece. A failure leaves the cache untouched; HTTP and network failures are
  /// reported in the result, never thrown.
  Future<DssSyncResult> sync(String tenantId, DssFilter filter);
}
