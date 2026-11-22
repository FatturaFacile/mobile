import 'package:dio/dio.dart';

import '../domain/project_evm_models.dart';

/// Why a request failed; the repository maps it to an [EvmSyncStatus].
enum EvmErrorKind { offline, unauthorized, forbidden, failed }

class EvmRemoteException implements Exception {
  const EvmRemoteException(this.kind, [this.detail = '']);

  final EvmErrorKind kind;
  final String detail;

  @override
  String toString() => 'EvmRemoteException($kind, $detail)';
}

/// REST access to `/api/v1/projects/{id}/evm`. Every method returns the `data` object of the answer as received.
class ProjectEvmRemoteDataSource {
  ProjectEvmRemoteDataSource(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> breakdown(String projectId) =>
      _object('/projects/$projectId/evm/wbs-breakdown');

  Future<Map<String, dynamic>> waterfall(String projectId) =>
      _object('/projects/$projectId/evm/waterfall');

  Future<Map<String, dynamic>> scurve(String projectId) => _object(
    '/projects/evm/scurve',
    query: <String, dynamic>{
      'granularity': 'month',
      'project_ids[]': <String>[projectId],
    },
  );

  Future<List<dynamic>> projects() async {
    final Response<dynamic> response = await _request(
      () => _dio.get<dynamic>(
        '/projects',
        queryParameters: <String, dynamic>{'per_page': 100},
      ),
    );
    final dynamic body = response.data;
    final dynamic data = body is Map ? body['data'] : null;
    return data is List ? data : <dynamic>[];
  }

  Future<Map<String, dynamic>> _object(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final Response<dynamic> response = await _request(
      () => _dio.get<dynamic>(path, queryParameters: query),
    );
    final dynamic body = response.data;
    final dynamic data = body is Map ? body['data'] : null;
    if (data is! Map) {
      throw const EvmRemoteException(EvmErrorKind.failed, 'no data');
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
      throw EvmRemoteException(switch (status) {
        null => EvmErrorKind.offline,
        401 => EvmErrorKind.unauthorized,
        403 => EvmErrorKind.forbidden,
        _ => EvmErrorKind.failed,
      }, '${status ?? e.message ?? ''}');
    }
  }
}
