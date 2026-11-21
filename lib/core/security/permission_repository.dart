import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../database/app_database.dart';
import 'permission_models.dart';
import 'permission_service.dart';
import 'snapshot_cipher.dart';

/// Syncs the effective permissions and field policies (`GET /profile/permissions`) into the local SQLite database and
/// enforces them offline. Snapshots are encrypted at rest and isolated per tenant, user and company; a revoked snapshot is
/// never read back.
class PermissionRepository {
  PermissionRepository(this._db, this._dio, this._service, this._cipher);

  final AppDatabase _db;
  final Dio _dio;
  final PermissionService _service;
  final SnapshotCipher _cipher;

  static const String _noCompany = '';

  /// Reads the snapshot from the API and stores it; offline it falls back to the cached one. Without either, nothing is
  /// granted (deny by default). Returns the snapshot now in force.
  Future<PermissionSnapshot?> sync({
    required String tenantId,
    required String userId,
    String? companyId,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/profile/permissions',
        options: Options(
          headers: <String, dynamic>{'X-Company-Id': ?companyId},
        ),
      );
      final dynamic body = response.data;
      final Object? data = body is Map<String, dynamic> ? body['data'] : null;
      final PermissionSnapshot snapshot = PermissionSnapshot.fromApi(
        data is Map<String, dynamic> ? data : <String, dynamic>{},
        tenantId: tenantId,
        userId: userId,
        companyId: companyId,
      );
      await _save(snapshot);
      _service.apply(snapshot);
      return snapshot;
    } on DioException catch (e) {
      final int status = e.response?.statusCode ?? 0;
      if (status == 401 || status == 403) {
        // The server refused: never fall back to cached rights it may have withdrawn.
        _service.apply(null);
        return null;
      }
      final PermissionSnapshot? cached = await loadCached(
        tenantId: tenantId,
        userId: userId,
        companyId: companyId,
      );
      _service.apply(cached);
      return cached;
    }
  }

  /// The cached snapshot of the tenant, user and company, or `null` when there is none, it was revoked or unreadable.
  Future<PermissionSnapshot?> loadCached({
    required String tenantId,
    required String userId,
    String? companyId,
  }) async {
    final PermissionSnapshotRow? row =
        await (_db.select(_db.permissionSnapshots)..where(
              ($PermissionSnapshotsTable t) =>
                  t.tenantId.equals(tenantId) &
                  t.userId.equals(userId) &
                  t.companyId.equals(companyId ?? _noCompany) &
                  t.revokedAt.isNull(),
            ))
            .getSingleOrNull();
    if (row == null) {
      return null;
    }
    try {
      return PermissionSnapshot.fromStored(
        await _cipher.decrypt(row.payload),
        tenantId: tenantId,
        userId: userId,
        companyId: companyId,
        fetchedAt: row.fetchedAt,
      );
    } on Object {
      return null;
    }
  }

  /// Marks every snapshot of the user as revoked (the server answered 401 or took the company access away).
  Future<void> revokeUser(String userId) async {
    await (_db.update(_db.permissionSnapshots)..where(
          ($PermissionSnapshotsTable t) =>
              t.userId.equals(userId) & t.revokedAt.isNull(),
        ))
        .write(
          PermissionSnapshotsCompanion(
            revokedAt: Value<DateTime>(DateTime.now().toUtc()),
          ),
        );
    _service.apply(null);
  }

  /// Deletes every snapshot (sign-out).
  Future<void> purge() async {
    await _db.delete(_db.permissionSnapshots).go();
    _service.apply(null);
  }

  Future<void> _save(PermissionSnapshot snapshot) async {
    final String payload = await _cipher.encrypt(snapshot.payload());
    await _db
        .into(_db.permissionSnapshots)
        .insertOnConflictUpdate(
          PermissionSnapshotsCompanion.insert(
            tenantId: snapshot.tenantId,
            userId: snapshot.userId,
            companyId: Value<String>(snapshot.companyId ?? _noCompany),
            payload: payload,
            fetchedAt: snapshot.fetchedAt,
            revokedAt: const Value<DateTime?>(null),
          ),
        );
  }
}
