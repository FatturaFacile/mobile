import 'package:dio/dio.dart';

/// REST client aligned to `/api/v1/manufacturing` (read side of Mod 061).
class ManufacturingRemoteDataSource {
  const ManufacturingRemoteDataSource(this._dio);

  static const String _basePath = '/manufacturing';
  static const int _pageSize = 100;

  final Dio _dio;

  /// `GET /manufacturing/work-centers`
  Future<List<Map<String, dynamic>>> fetchWorkCenters() =>
      _fetchAll('$_basePath/work-centers');

  /// `GET /manufacturing/machines`
  Future<List<Map<String, dynamic>>> fetchMachines() =>
      _fetchAll('$_basePath/machines');

  /// `GET /manufacturing/routings` (operations are embedded).
  Future<List<Map<String, dynamic>>> fetchRoutings() =>
      _fetchAll('$_basePath/routings');

  /// `GET /manufacturing/oee/summary` for one work centre (optionally one machine).
  Future<Map<String, dynamic>> fetchOeeSummary({
    required String workCenterId,
    String? machineCenterId,
    required DateTime from,
    required DateTime to,
  }) async {
    final Response<dynamic> res = await _dio.get<dynamic>(
      '$_basePath/oee/summary',
      queryParameters: <String, dynamic>{
        'work_center_id': workCenterId,
        // ignore: use_null_aware_elements
        if (machineCenterId != null) 'machine_center_id': machineCenterId,
        'from_datetime': from.toUtc().toIso8601String(),
        'to_datetime': to.toUtc().toIso8601String(),
      },
    );
    final Object? body = res.data;
    if (body is Map && body['data'] is Map) {
      return Map<String, dynamic>.from(body['data'] as Map);
    }
    return Map<String, dynamic>.from(body! as Map);
  }

  Future<List<Map<String, dynamic>>> _fetchAll(String path) async {
    final List<Map<String, dynamic>> all = <Map<String, dynamic>>[];
    int page = 1;
    while (true) {
      final Response<dynamic> res = await _dio.get<dynamic>(
        path,
        queryParameters: <String, dynamic>{'per_page': _pageSize, 'page': page},
      );
      final Object? body = res.data;
      final Object? rows = body is Map ? body['data'] : body;
      if (rows is List) {
        all.addAll(
          rows.whereType<Map<dynamic, dynamic>>().map(
            (Map<dynamic, dynamic> m) => Map<String, dynamic>.from(m),
          ),
        );
      }
      final Object? meta = body is Map ? body['meta'] : null;
      final int last = meta is Map
          ? (int.tryParse('${meta['last_page'] ?? 1}') ?? 1)
          : 1;
      if (page >= last || rows is! List || rows.isEmpty) {
        return all;
      }
      page++;
    }
  }
}
