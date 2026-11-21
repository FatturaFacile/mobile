import 'package:drift/native.dart';
import 'package:fattura_facile/core/database/app_database.dart';
import 'package:fattura_facile/core/security/encrypted_storage.dart';
import 'package:fattura_facile/core/security/secure_key_store.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MemorySecureKeyStore vault;
  late DeviceKeyProvider keys;

  setUp(() {
    vault = MemorySecureKeyStore();
    keys = DeviceKeyProvider(vault);
  });

  test(
    'keys are generated once, 256-bit, and kept in the secure store only',
    () async {
      final String first = await keys.databaseKey();
      final String second = await keys.databaseKey();
      expect(second, first);
      expect((await keys.auditHmacKey()).length, 32);
      expect(vault.values[SecureKeyNames.databaseKey], first);
      expect(await keys.deviceId(), await keys.deviceId());
    },
  );

  test(
    'plain SQLite is reported as not encrypted while the key is provisioned',
    () async {
      final EncryptedStorageService service = EncryptedStorageService(
        probe: const StaticCipherProbe(),
        keys: keys,
        platform: TargetPlatform.android,
      );
      expect((await service.status()).keyInSecureStorage, isFalse);

      await service.provisionKey();
      final EncryptionStatus status = await service.status();
      expect(status.databaseEncrypted, isFalse);
      expect(status.keyInSecureStorage, isTrue);
      expect(status.keyBackend, KeyBackend.androidKeystore);
    },
  );

  test(
    'a SQLCipher probe marks the database as encrypted; iOS uses the Keychain',
    () async {
      final EncryptedStorageService service = EncryptedStorageService(
        probe: const StaticCipherProbe('4.5.6'),
        keys: keys,
        platform: TargetPlatform.iOS,
      );
      await service.provisionKey();
      final EncryptionStatus status = await service.status();
      expect(status.databaseEncrypted, isTrue);
      expect(status.cipherVersion, '4.5.6');
      expect(status.keyBackend, KeyBackend.keychain);
    },
  );

  test('the live probe sees plain sqlite3 as unencrypted', () async {
    final AppDatabase db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    expect(await SqlCipherProbe(db).cipherVersion(), isNull);
  });
}
