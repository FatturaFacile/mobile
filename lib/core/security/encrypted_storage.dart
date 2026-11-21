import 'package:flutter/foundation.dart';

import '../database/app_database.dart';
import 'secure_key_store.dart';

/// Whether the on-disk SQLite file is encrypted.
enum DatabaseEncryption {
  /// SQLCipher is active (`PRAGMA cipher_version` answers).
  encrypted,

  /// Plain SQLite: the key is provisioned in secure storage but the engine does not use it yet.
  notEncrypted,
}

/// Where the key material lives.
enum KeyBackend { keychain, androidKeystore, platformSecureStorage }

/// Snapshot shown on the security screen.
@immutable
class EncryptionStatus {
  const EncryptionStatus({
    required this.database,
    required this.keyInSecureStorage,
    required this.keyBackend,
    this.cipherVersion,
  });

  final DatabaseEncryption database;
  final bool keyInSecureStorage;
  final KeyBackend keyBackend;
  final String? cipherVersion;

  bool get databaseEncrypted => database == DatabaseEncryption.encrypted;
}

/// Reports the cipher state of the open database. Abstracted so the engine can be swapped
/// (SQLCipher / SQLite3 Multiple Ciphers) and so tests can simulate an encrypted database.
abstract interface class DatabaseCipherProbe {
  /// SQLCipher version string, or `null` when the engine is plain SQLite.
  Future<String?> cipherVersion();
}

/// Asks the live connection through `PRAGMA cipher_version`, which only SQLCipher answers.
class SqlCipherProbe implements DatabaseCipherProbe {
  const SqlCipherProbe(this._db);

  final AppDatabase _db;

  @override
  Future<String?> cipherVersion() async {
    try {
      final rows = await _db.customSelect('PRAGMA cipher_version').get();
      if (rows.isEmpty) {
        return null;
      }
      final Object? value = rows.first.data.values.firstOrNull;
      return value is String && value.isNotEmpty ? value : null;
    } catch (_) {
      return null;
    }
  }
}

/// Probe for tests and for builds that know their cipher state up front.
class StaticCipherProbe implements DatabaseCipherProbe {
  const StaticCipherProbe([this.version]);

  final String? version;

  @override
  Future<String?> cipherVersion() async => version;
}

/// Computes the [EncryptionStatus] and provisions the database key in secure storage.
class EncryptedStorageService {
  const EncryptedStorageService({
    required this.probe,
    required this.keys,
    this.platform,
  });

  final DatabaseCipherProbe probe;
  final DeviceKeyProvider keys;
  final TargetPlatform? platform;

  /// Makes sure the database key exists in the Keychain / Keystore (idempotent).
  Future<void> provisionKey() => keys.databaseKey();

  Future<EncryptionStatus> status() async {
    final String? version = await probe.cipherVersion();
    final bool hasKey = await keys.hasDatabaseKey();
    return EncryptionStatus(
      database: version == null
          ? DatabaseEncryption.notEncrypted
          : DatabaseEncryption.encrypted,
      keyInSecureStorage: hasKey,
      keyBackend: switch (platform ?? defaultTargetPlatform) {
        TargetPlatform.iOS || TargetPlatform.macOS => KeyBackend.keychain,
        TargetPlatform.android => KeyBackend.androidKeystore,
        _ => KeyBackend.platformSecureStorage,
      },
      cipherVersion: version,
    );
  }
}
