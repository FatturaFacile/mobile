import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

/// Key/value vault backed by the Keychain (iOS/macOS) or the Android Keystore.
///
/// Holds secrets that must never touch the SQLite file: the database key, the audit HMAC key,
/// the device id and the session-lock settings.
abstract interface class SecureKeyStore {
  Future<String?> read(String name);
  Future<void> write(String name, String value);
  Future<void> delete(String name);
}

/// Keychain / Keystore backed implementation.
class FlutterSecureKeyStore implements SecureKeyStore {
  FlutterSecureKeyStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String name) => _storage.read(key: name);

  @override
  Future<void> write(String name, String value) =>
      _storage.write(key: name, value: value);

  @override
  Future<void> delete(String name) => _storage.delete(key: name);
}

/// In-memory vault for tests.
class MemorySecureKeyStore implements SecureKeyStore {
  final Map<String, String> values = <String, String>{};

  @override
  Future<String?> read(String name) async => values[name];

  @override
  Future<void> write(String name, String value) async => values[name] = value;

  @override
  Future<void> delete(String name) async => values.remove(name);
}

/// Names of the secrets kept in the [SecureKeyStore].
abstract final class SecureKeyNames {
  static const String databaseKey = 'ff_db_encryption_key';
  static const String auditHmacKey = 'ff_audit_hmac_key';
  static const String deviceId = 'ff_device_id';
  static const String lockEnabled = 'ff_lock_enabled';
  static const String lockTimeoutSeconds = 'ff_lock_timeout_seconds';
  static const String pinSalt = 'ff_lock_pin_salt';
  static const String pinHash = 'ff_lock_pin_hash';
}

/// Creates and returns the long-lived per-device secrets, generating them on first use.
class DeviceKeyProvider {
  DeviceKeyProvider(this._store, {Random? random})
    : _random = random ?? Random.secure();

  final SecureKeyStore _store;
  final Random _random;

  /// 256-bit key intended for the SQLCipher `PRAGMA key`.
  Future<String> databaseKey() =>
      _ensure(SecureKeyNames.databaseKey, _randomKey);

  /// 256-bit key used to HMAC-sign audit records.
  Future<List<int>> auditHmacKey() async =>
      base64Decode(await _ensure(SecureKeyNames.auditHmacKey, _randomKey));

  /// Stable pseudonymous device identifier sent as audit origin metadata.
  Future<String> deviceId() =>
      _ensure(SecureKeyNames.deviceId, () => const Uuid().v4());

  Future<bool> hasDatabaseKey() async =>
      (await _store.read(SecureKeyNames.databaseKey)) != null;

  Future<String> _ensure(String name, String Function() generate) async {
    final String? existing = await _store.read(name);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final String created = generate();
    await _store.write(name, created);
    return created;
  }

  String _randomKey() =>
      base64Encode(List<int>.generate(32, (_) => _random.nextInt(256)));
}
