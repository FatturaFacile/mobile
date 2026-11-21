import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../error/failure.dart';
import 'auth_problem_interceptor.dart';

/// Mutable request context (token, tenant, locale) read by the interceptor.
class RequestContext {
  String? accessToken;
  String? tenantId;
  String languageCode = 'en';
}

/// Adds the headers the Laravel API expects on every request.
class ContextInterceptor extends Interceptor {
  ContextInterceptor(this._context);

  final RequestContext _context;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final Map<String, dynamic> h = options.headers;
    h.putIfAbsent('Accept', () => 'application/json');
    h['X-Language-Code'] = _context.languageCode;
    h['Accept-Language'] = _context.languageCode;
    final String? token = _context.accessToken;
    if (token != null && token.isNotEmpty) {
      h['Authorization'] = 'Bearer $token';
    }
    final String? tenant = _context.tenantId;
    if (tenant != null && tenant.isNotEmpty) {
      h['X-Tenant-Id'] = tenant;
    }
    handler.next(options);
  }
}

/// Retries transient failures with exponential backoff (idempotent requests only).
class RetryInterceptor extends Interceptor {
  RetryInterceptor(
    this._dio, {
    this.maxRetries = 3,
    this.baseDelay = const Duration(milliseconds: 400),
  });

  final Dio _dio;
  final int maxRetries;
  final Duration baseDelay;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final int attempt = (err.requestOptions.extra['retry'] as int?) ?? 0;
    final int status = err.response?.statusCode ?? 0;
    final bool transient =
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError ||
        (status >= 502 && status <= 504);
    final bool safe =
        err.requestOptions.method == 'GET' ||
        err.requestOptions.headers.containsKey('Idempotency-Key');
    if (!transient || !safe || attempt >= maxRetries) {
      return handler.next(err);
    }
    await Future<void>.delayed(baseDelay * (1 << attempt));
    final RequestOptions opts = err.requestOptions
      ..extra['retry'] = attempt + 1;
    try {
      handler.resolve(await _dio.fetch<dynamic>(opts));
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}

/// Reads the human message of a Laravel envelope (`message`) or an RFC 7807 problem (`detail`, then `title`).
String _errorMessage(dynamic body) {
  if (body is Map) {
    for (final String k in <String>['message', 'detail', 'title']) {
      final dynamic v = body[k];
      if (v is String && v.isNotEmpty) {
        return v;
      }
    }
  }
  return '';
}

/// Maps transport errors to domain [Failure]s.
Failure mapDioError(DioException e) {
  final Response<dynamic>? r = e.response;
  if (r == null) {
    return NetworkFailure(e.message ?? '');
  }
  final dynamic body = r.data;
  final String message = _errorMessage(body);
  switch (r.statusCode) {
    case 401:
      return UnauthorizedFailure(message);
    case 403:
      return ForbiddenFailure(message);
    case 409:
    case 412:
      return ConflictFailure(message);
    case 422:
      final Map<String, List<String>> fields = <String, List<String>>{};
      final dynamic errors = body is Map ? body['errors'] : null;
      if (errors is Map) {
        errors.forEach((dynamic k, dynamic v) {
          fields['$k'] = (v as List<dynamic>).map((dynamic x) => '$x').toList();
        });
      }
      return ValidationFailure(message, fieldErrors: fields);
    default:
      return ServerFailure(message, statusCode: r.statusCode);
  }
}

/// Builds the configured [Dio] instance.
Dio buildDio(
  AppConfig config,
  RequestContext context, {
  AuthProblemInterceptor? problems,
}) {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: config.apiRoot,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );
  dio.interceptors
    ..add(ContextInterceptor(context))
    ..add(RetryInterceptor(dio));
  if (problems != null) {
    dio.interceptors.add(problems);
  }
  return dio;
}
