import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/database/app_database.dart';
import '../core/localization/translation_service.dart';
import '../core/network/api_client.dart';
import '../core/security/token_store.dart';
import '../core/sync/sync_engine.dart';
import '../features/auth/data/auth_repository_impl.dart';
import '../features/auth/domain/auth_repository.dart';

/// Infrastructure providers. Tests and `main` override [databaseProvider] and [tokenStoreProvider].
final Provider<AppConfig> appConfigProvider = Provider<AppConfig>((Ref ref) => AppConfig.fromEnvironment());

final Provider<RequestContext> requestContextProvider = Provider<RequestContext>((Ref ref) => RequestContext());

final Provider<AppDatabase> databaseProvider = Provider<AppDatabase>((Ref ref) => throw UnimplementedError('override databaseProvider'));

final Provider<TokenStore> tokenStoreProvider = Provider<TokenStore>((Ref ref) => SecureTokenStore());

final Provider<Dio> dioProvider = Provider<Dio>((Ref ref) => buildDio(ref.watch(appConfigProvider), ref.watch(requestContextProvider)));

final Provider<AuthRepository> authRepositoryProvider = Provider<AuthRepository>(
  (Ref ref) => AuthRepositoryImpl(ref.watch(dioProvider), ref.watch(requestContextProvider), ref.watch(tokenStoreProvider)),
);

final Provider<SyncEngine> syncEngineProvider = Provider<SyncEngine>((Ref ref) => SyncEngine(ref.watch(databaseProvider), ref.watch(dioProvider)));

final Provider<TranslationService> translationProvider =
    Provider<TranslationService>((Ref ref) => TranslationService(ref.watch(databaseProvider), ref.watch(dioProvider)));

/// `true` while the device has a network interface up.
final StreamProvider<bool> connectivityProvider = StreamProvider<bool>((Ref ref) {
  return Connectivity().onConnectivityChanged.map((List<ConnectivityResult> r) => !r.contains(ConnectivityResult.none));
});
