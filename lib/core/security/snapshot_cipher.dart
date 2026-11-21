import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Authenticated encryption (AES-256-GCM) of the permission snapshots kept in the local database. The key lives in the
/// platform keychain / keystore, never next to the data; a tampered or foreign payload fails to decrypt.
abstract interface class SnapshotCipher {
  Future<String> encrypt(String plain);

  /// Throws when the payload was tampered with or was written with another key.
  Future<String> decrypt(String stored);
}

class AesGcmSnapshotCipher implements SnapshotCipher {
  AesGcmSnapshotCipher(this._key);

  /// Reads the key from [storage], creating it on first use.
  static Future<AesGcmSnapshotCipher> fromSecureStorage([
    FlutterSecureStorage? storage,
  ]) async {
    const String name = 'ff_permission_cache_key';
    final FlutterSecureStorage s = storage ?? const FlutterSecureStorage();
    String? encoded = await s.read(key: name);
    if (encoded == null) {
      final SecretKey fresh = await AesGcm.with256bits().newSecretKey();
      encoded = base64Encode(await fresh.extractBytes());
      await s.write(key: name, value: encoded);
    }
    return AesGcmSnapshotCipher(SecretKey(base64Decode(encoded)));
  }

  /// A cipher with a random key that lives only as long as the object; for tests.
  static Future<AesGcmSnapshotCipher> ephemeral() async =>
      AesGcmSnapshotCipher(await AesGcm.with256bits().newSecretKey());

  static const String _prefix = 'enc:v1:';

  final SecretKey _key;
  final AesGcm _algorithm = AesGcm.with256bits();

  @override
  Future<String> encrypt(String plain) async {
    final SecretBox box = await _algorithm.encrypt(
      utf8.encode(plain),
      secretKey: _key,
    );
    return _prefix + base64Encode(box.concatenation());
  }

  @override
  Future<String> decrypt(String stored) async {
    if (!stored.startsWith(_prefix)) {
      throw const FormatException('The payload is not an encrypted snapshot.');
    }
    final SecretBox box = SecretBox.fromConcatenation(
      base64Decode(stored.substring(_prefix.length)),
      nonceLength: _algorithm.nonceLength,
      macLength: _algorithm.macAlgorithm.macLength,
    );
    return utf8.decode(await _algorithm.decrypt(box, secretKey: _key));
  }
}

/// Creates the key on first use, so the cipher can be built synchronously by a provider.
class LazySnapshotCipher implements SnapshotCipher {
  LazySnapshotCipher([this._storage]);

  final FlutterSecureStorage? _storage;
  Future<AesGcmSnapshotCipher>? _cipher;

  Future<AesGcmSnapshotCipher> get _ready =>
      _cipher ??= AesGcmSnapshotCipher.fromSecureStorage(_storage);

  @override
  Future<String> encrypt(String plain) async => (await _ready).encrypt(plain);

  @override
  Future<String> decrypt(String stored) async => (await _ready).decrypt(stored);
}
