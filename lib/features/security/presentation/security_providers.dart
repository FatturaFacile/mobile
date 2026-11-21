import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/security/encrypted_storage.dart';
import '../../../core/security/secure_key_store.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../data/audit_queue.dart';
import '../data/audit_sync_adapter.dart';
import '../data/pii_unmask_repository.dart';
import '../data/session_lock_controller.dart';

final Provider<DeviceKeyProvider> deviceKeyProvider =
    Provider<DeviceKeyProvider>(
      (Ref ref) => DeviceKeyProvider(ref.watch(secureKeyStoreProvider)),
    );

final Provider<DatabaseCipherProbe> databaseCipherProbeProvider =
    Provider<DatabaseCipherProbe>(
      (Ref ref) => SqlCipherProbe(ref.watch(databaseProvider)),
    );

final Provider<EncryptedStorageService> encryptedStorageProvider =
    Provider<EncryptedStorageService>(
      (Ref ref) => EncryptedStorageService(
        probe: ref.watch(databaseCipherProbeProvider),
        keys: ref.watch(deviceKeyProvider),
      ),
    );

final Provider<AuditQueue> auditQueueProvider = Provider<AuditQueue>(
  (Ref ref) => AuditQueue(
    ref.watch(databaseProvider),
    ref.watch(deviceKeyProvider),
    now: ref.watch(securityClockProvider),
  ),
);

final Provider<AuditSyncAdapter> auditSyncAdapterProvider =
    Provider<AuditSyncAdapter>(
      (Ref ref) => AuditSyncAdapter(
        ref.watch(auditQueueProvider),
        ref.watch(dioProvider),
        ref.watch(deviceKeyProvider),
      ),
    );

final Provider<PiiUnmaskRepository> piiUnmaskRepositoryProvider =
    Provider<PiiUnmaskRepository>(
      (Ref ref) => HttpPiiUnmaskRepository(
        ref.watch(dioProvider),
        ref.watch(requestContextProvider),
        ref.watch(auditQueueProvider),
      ),
    );

/// Region of the device (e.g. `CH`), used to pick it-CH / de-CH / fr-CH wording.
final Provider<String?> securityCountryProvider = Provider<String?>(
  (Ref ref) => PlatformDispatcher.instance.locale.countryCode,
);

/// Localized security strings for the active app language.
final Provider<AppLocalizations> securityStringsProvider =
    Provider<AppLocalizations>(
      (Ref ref) => securityStrings(
        ref.watch(requestContextProvider).languageCode,
        countryCode: ref.watch(securityCountryProvider),
      ),
    );

/// Resolves the best ARB for [languageCode] / [countryCode]: it-CH, de-CH, fr-CH, it-IT, then the
/// plain language, then English.
AppLocalizations securityStrings(String languageCode, {String? countryCode}) {
  final List<Locale> supported = AppLocalizations.supportedLocales;
  final Locale exact = Locale(languageCode, countryCode);
  if (countryCode != null && supported.contains(exact)) {
    return lookupAppLocalizations(exact);
  }
  final Locale base = Locale(languageCode);
  return lookupAppLocalizations(
    supported.contains(base) ? base : const Locale('en'),
  );
}

final FutureProvider<EncryptionStatus> encryptionStatusProvider =
    FutureProvider.autoDispose<EncryptionStatus>((Ref ref) async {
      final EncryptedStorageService service = ref.watch(
        encryptedStorageProvider,
      );
      await service.provisionKey();
      return service.status();
    });
