import 'package:dio/dio.dart';

/// Why a request failed; the repository maps it to a `BillingSyncStatus`.
enum BillingErrorKind { offline, unauthorized, forbidden, notFound, failed }

class BillingRemoteException implements Exception {
  const BillingRemoteException(this.kind, [this.detail = '']);

  final BillingErrorKind kind;
  final String detail;

  @override
  String toString() => 'BillingRemoteException($kind, $detail)';
}

/// REST access to the project billing endpoints of `/api/v1/projects/{id}`. Every method returns the `data` of the answer
/// as received; the optional ones answer null when the project has no billing contract yet (404).
class ProjectBillingRemoteDataSource {
  ProjectBillingRemoteDataSource(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> summary(String projectId) =>
      _object('/projects/$projectId/billing/unbilled-summary');

  Future<Map<String, dynamic>?> contract(String projectId) async {
    final Response<dynamic> response = await _request(
      () => _dio.get<dynamic>('/projects/$projectId/billing-contract'),
    );
    final dynamic body = response.data;
    final dynamic data = body is Map ? body['data'] : null;
    return data is Map ? Map<String, dynamic>.from(data) : null;
  }

  Future<List<dynamic>> certificates(String projectId) async {
    final Response<dynamic> response = await _request(
      () => _dio.get<dynamic>('/projects/$projectId/sal-certificates'),
    );
    final dynamic body = response.data;
    final dynamic data = body is Map ? body['data'] : null;
    return data is List ? data : <dynamic>[];
  }

  Future<Map<String, dynamic>?> retention(String projectId) =>
      _optional('/projects/$projectId/retention');

  Future<Map<String, dynamic>?> retainer(String projectId) =>
      _optional('/projects/$projectId/retainer');

  Future<Map<String, dynamic>?> _optional(String path) async {
    try {
      return await _object(path);
    } on BillingRemoteException catch (e) {
      if (e.kind == BillingErrorKind.notFound) {
        return null;
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _object(String path) async {
    final Response<dynamic> response = await _request(
      () => _dio.get<dynamic>(path),
    );
    final dynamic body = response.data;
    final dynamic data = body is Map ? body['data'] : null;
    if (data is! Map) {
      throw const BillingRemoteException(BillingErrorKind.failed, 'no data');
    }
    return Map<String, dynamic>.from(data);
  }

  Future<Response<dynamic>> _request(
    Future<Response<dynamic>> Function() run,
  ) async {
    try {
      return await run();
    } on DioException catch (e) {
      final int? status = e.response?.statusCode;
      throw BillingRemoteException(switch (status) {
        null => BillingErrorKind.offline,
        401 => BillingErrorKind.unauthorized,
        403 => BillingErrorKind.forbidden,
        404 => BillingErrorKind.notFound,
        _ => BillingErrorKind.failed,
      }, '${status ?? e.message ?? ''}');
    }
  }
}
