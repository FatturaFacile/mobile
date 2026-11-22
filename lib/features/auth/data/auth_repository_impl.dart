import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/error/failure.dart';
import '../../../core/network/api_client.dart';
import '../../../core/security/pkce.dart';
import '../../../core/security/token_store.dart';
import '../domain/auth_models.dart';
import '../domain/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._dio, this._context, this._store);

  final Dio _dio;
  final RequestContext _context;
  final TokenStore _store;

  @override
  Future<Either<Failure, LoginOutcome>> signIn({
    required String email,
    required String password,
    required String deviceId,
    required String platform,
    String? deviceName,
    String? appVersion,
  }) async {
    final PkcePair pkce = PkcePair.generate();
    try {
      final Response<dynamic> authorize = await _dio.post<dynamic>(
        '/mobile/auth/pkce/authorize',
        data: <String, dynamic>{
          'email': email,
          'password': password,
          'code_challenge': pkce.challenge,
          'code_challenge_method': 'S256',
        },
      );
      final Map<String, dynamic> data = _data(authorize);
      final Object? code = data['code'];
      if (code is! String) {
        return const Right<Failure, LoginOutcome>(LoginTwoFactorRequired());
      }
      final Response<dynamic> token = await _dio.post<dynamic>(
        '/mobile/auth/pkce/token',
        data: <String, dynamic>{
          'code': code,
          'code_verifier': pkce.verifier,
          'device_id': deviceId,
          'device_name': ?deviceName,
          'platform': platform,
          'app_version': ?appVersion,
        },
      );
      final Map<String, dynamic> t = _data(token);
      final AuthSession session = AuthSession(
        accessToken: '${t['access_token']}',
        tenantId: '${t['tenant_id']}',
        deviceSessionId: t['device_session_id']?.toString(),
      );
      await _store.save(token: session.accessToken, tenantId: session.tenantId);
      _context
        ..accessToken = session.accessToken
        ..tenantId = session.tenantId;
      return Right<Failure, LoginOutcome>(LoginAuthorized(session));
    } on DioException catch (e) {
      return Left<Failure, LoginOutcome>(mapDioError(e));
    }
  }

  @override
  Future<AuthSession?> restore() async {
    final String? token = await _store.readToken();
    final String? tenant = await _store.readTenantId();
    if (token == null || tenant == null) {
      return null;
    }
    _context
      ..accessToken = token
      ..tenantId = tenant;
    return AuthSession(accessToken: token, tenantId: tenant);
  }

  @override
  Future<void> switchTenant(String tenantId) async {
    await _store.saveTenantId(tenantId);
    _context.tenantId = tenantId;
  }

  @override
  Future<Either<Failure, Bootstrap>> bootstrap() async {
    try {
      final Response<dynamic> res = await _dio.get<dynamic>(
        '/mobile/bootstrap',
      );
      return Right<Failure, Bootstrap>(Bootstrap.fromJson(_data(res)));
    } on DioException catch (e) {
      return Left<Failure, Bootstrap>(mapDioError(e));
    }
  }

  @override
  Future<void> signOut() async {
    await _store.clear();
    _context
      ..accessToken = null
      ..tenantId = null;
  }

  Map<String, dynamic> _data(Response<dynamic> r) =>
      ((r.data as Map<String, dynamic>)['data'] as Map<String, dynamic>?) ??
      <String, dynamic>{};
}
