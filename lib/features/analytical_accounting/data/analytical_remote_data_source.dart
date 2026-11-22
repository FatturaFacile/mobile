import 'package:dio/dio.dart';

/// Why a request failed; the repository maps it to an [AnalyticalSyncStatus].
enum AnalyticalErrorKind { offline, unauthorized, forbidden, failed }

class AnalyticalRemoteException implements Exception {
  const AnalyticalRemoteException(this.kind, [this.detail = '']);

  final AnalyticalErrorKind kind;
  final String detail;

  @override
  String toString() => 'AnalyticalRemoteException($kind, $detail)';
}

/// The answer to a queued entry: accepted, refused for good (a 4xx the entry itself caused) or to be retried later.
enum AnalyticalPostOutcome { accepted, refused, retryLater }

class AnalyticalPostReply {
  const AnalyticalPostReply(this.outcome, [this.detail = '']);

  final AnalyticalPostOutcome outcome;
  final String detail;
}

/// REST access to `/api/v1/analytical`. Every read returns the `data` element of the answer as received.
class AnalyticalRemoteDataSource {
  AnalyticalRemoteDataSource(this._dio);

  final Dio _dio;

  Future<dynamic> centers() => _data('/analytical/centers/tree');

  Future<dynamic> runs() =>
      _data('/analytical/runs', query: <String, dynamic>{'per_page': 50});

  Future<dynamic> margin({String? from, String? to}) => _data(
    '/analytical/reports/contribution-margin',
    query: _period(from, to),
  );

  Future<dynamic> comparison({String? from, String? to}) => _data(
    '/analytical/reports/direct-vs-apportioned',
    query: <String, dynamic>{..._period(from, to), 'include_descendants': 1},
  );

  /// Posts a manual analytical entry. Authentication problems and server errors are retried later; a refusal of the entry is not.
  Future<AnalyticalPostReply> postEntry(Map<String, dynamic> body) async {
    try {
      await _dio.post<dynamic>('/analytical/entries', data: body);
      return const AnalyticalPostReply(AnalyticalPostOutcome.accepted);
    } on DioException catch (e) {
      final int? status = e.response?.statusCode;
      if (status == 400 || status == 404 || status == 409 || status == 422) {
        final dynamic data = e.response?.data;
        final dynamic message = data is Map ? data['message'] : null;
        return AnalyticalPostReply(
          AnalyticalPostOutcome.refused,
          message is String ? message : '$status',
        );
      }
      return AnalyticalPostReply(
        AnalyticalPostOutcome.retryLater,
        '${status ?? e.message ?? ''}',
      );
    }
  }

  Map<String, dynamic> _period(String? from, String? to) => <String, dynamic>{
    if (from != null && from.isNotEmpty) 'from': from,
    if (to != null && to.isNotEmpty) 'to': to,
  };

  Future<dynamic> _data(String path, {Map<String, dynamic>? query}) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        path,
        queryParameters: query,
      );
      final dynamic body = response.data;
      if (body is! Map || !body.containsKey('data')) {
        throw const AnalyticalRemoteException(
          AnalyticalErrorKind.failed,
          'no data',
        );
      }
      return body['data'];
    } on DioException catch (e) {
      final int? status = e.response?.statusCode;
      throw AnalyticalRemoteException(switch (status) {
        null => AnalyticalErrorKind.offline,
        401 => AnalyticalErrorKind.unauthorized,
        403 => AnalyticalErrorKind.forbidden,
        _ => AnalyticalErrorKind.failed,
      }, '${status ?? e.message ?? ''}');
    }
  }
}
