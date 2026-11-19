import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the credentials of the signed-in user.
abstract interface class TokenStore {
  Future<String?> readToken();
  Future<String?> readTenantId();
  Future<void> save({required String token, required String tenantId});
  Future<void> saveTenantId(String tenantId);
  Future<void> clear();
}

/// Keychain / Keystore backed implementation.
class SecureTokenStore implements TokenStore {
  SecureTokenStore([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();

  static const String _tokenKey = 'ff_access_token';
  static const String _tenantKey = 'ff_active_tenant_id';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> readToken() => _storage.read(key: _tokenKey);

  @override
  Future<String?> readTenantId() => _storage.read(key: _tenantKey);

  @override
  Future<void> save({required String token, required String tenantId}) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _tenantKey, value: tenantId);
  }

  @override
  Future<void> saveTenantId(String tenantId) => _storage.write(key: _tenantKey, value: tenantId);

  @override
  Future<void> clear() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _tenantKey);
  }
}

/// In-memory store for tests.
class MemoryTokenStore implements TokenStore {
  String? _token;
  String? _tenant;

  @override
  Future<String?> readToken() async => _token;

  @override
  Future<String?> readTenantId() async => _tenant;

  @override
  Future<void> save({required String token, required String tenantId}) async {
    _token = token;
    _tenant = tenantId;
  }

  @override
  Future<void> saveTenantId(String tenantId) async => _tenant = tenantId;

  @override
  Future<void> clear() async {
    _token = null;
    _tenant = null;
  }
}
