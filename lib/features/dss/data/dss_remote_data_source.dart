import 'package:dio/dio.dart';

import '../domain/dss_models.dart';

/// Why a DSS request failed; the repository maps it to a [DssSyncStatus].
enum DssErrorKind { offline, unauthorized, forbidden, failed }

class DssRemoteException implements Exception {
  const DssRemoteException(this.kind, [this.detail = '']);

  final DssErrorKind kind;
  final String detail;

  @override
  String toString() => 'DssRemoteException($kind, $detail)';
}

/// REST access to `/api/v1/analytics/dss`. Every method returns the `data` object of the answer as received.
class DssRemoteDataSource {
  DssRemoteDataSource(this._dio);

  final Dio _dio;

  static const String _base = '/analytics/dss';

  Future<Map<String, dynamic>> overview(DssFilter filter) =>
      _get('$_base/overview', filter.toQuery());

  Future<Map<String, dynamic>> profitability(
    DssFilter filter,
    String dimension,
  ) => _get('$_base/profitability-matrix', <String, dynamic>{
    ...filter.toQuery(),
    'dimension': dimension,
    'limit': 100,
  });

  Future<Map<String, dynamic>> varianceBridge(DssFilter filter) =>
      _get('$_base/variance-bridge', filter.toQuery());

  /// A neutral simulation: its `inputs` are the actuals the server simulates on.
  Future<Map<String, dynamic>> simulationInputs(DssFilter filter) => _guard(
    () => _dio.post<dynamic>(
      '$_base/simulate',
      data: <String, dynamic>{
        ...filter.toBody(),
        'scenario': <String, dynamic>{
          'price_pct': 0,
          'cogs_pct': 0,
          'opex_pct': 0,
          'dso_days_delta': 0,
          'fx_shift_pct': 0,
          'fte_delta': 0,
        },
      },
    ),
  );

  Future<List<dynamic>> legalEntities() async {
    final Response<dynamic> response = await _request(
      () => _dio.get<dynamic>('$_base/legal-entities'),
    );
    final dynamic body = response.data;
    final dynamic data = body is Map ? body['data'] : null;
    return data is List ? data : <dynamic>[];
  }

  Future<Map<String, dynamic>> _get(String path, Map<String, dynamic> query) =>
      _guard(() => _dio.get<dynamic>(path, queryParameters: query));

  Future<Map<String, dynamic>> _guard(
    Future<Response<dynamic>> Function() run,
  ) async {
    final Response<dynamic> response = await _request(run);
    final dynamic body = response.data;
    final dynamic data = body is Map ? body['data'] : null;
    if (data is! Map) {
      throw const DssRemoteException(DssErrorKind.failed, 'no data');
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
      throw DssRemoteException(switch (status) {
        null => DssErrorKind.offline,
        401 => DssErrorKind.unauthorized,
        403 => DssErrorKind.forbidden,
        _ => DssErrorKind.failed,
      }, '${status ?? e.message ?? ''}');
    }
  }
}
