import 'package:dio/dio.dart';

/// Why the API refuses the session or a request, from the status and the stable `code` of a 403 problem.
enum ApiProblem {
  /// 401: the token was revoked or expired remotely; the session is over.
  sessionRevoked,

  /// 403 `permission_denied`: the cached permissions are stale.
  permissionDenied,

  /// 403 `mfa_required`: a second factor must be set up or presented.
  mfaRequired,

  /// 403 `company_access_revoked`: the member lost access to the company.
  companyAccessRevoked,
}

/// Reacts to what the server withdraws: a 401 (remote revocation) and the structured 403 codes are reported to
/// [onProblem], which clears the local credentials and permissions. The error itself always continues to the caller.
class AuthProblemInterceptor extends Interceptor {
  AuthProblemInterceptor({required this.onProblem});

  /// Endpoints where a 401 is a wrong credential, not a revoked session.
  static const List<String> anonymousPaths = <String>[
    '/auth/login',
    '/auth/two-factor-challenge',
    '/auth/passkeys/login',
    '/auth/sso',
  ];

  final Future<void> Function(ApiProblem problem) onProblem;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final ApiProblem? problem = classify(err);
    if (problem != null) {
      await onProblem(problem);
    }
    handler.next(err);
  }

  /// The problem a failed request stands for, or `null` for any other error.
  static ApiProblem? classify(DioException err) {
    final Response<dynamic>? response = err.response;
    final int status = response?.statusCode ?? 0;
    final String path = err.requestOptions.path;

    if (status == 401) {
      return anonymousPaths.any(path.contains)
          ? null
          : ApiProblem.sessionRevoked;
    }
    if (status == 403) {
      final dynamic body = response?.data;
      final dynamic code = body is Map ? body['code'] : null;
      return switch (code) {
        'permission_denied' => ApiProblem.permissionDenied,
        'mfa_required' => ApiProblem.mfaRequired,
        'company_access_revoked' => ApiProblem.companyAccessRevoked,
        _ => null,
      };
    }
    return null;
  }
}
