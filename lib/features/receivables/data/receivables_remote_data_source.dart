import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../domain/receivables_models.dart';

/// Base of the receivables API under the Dio base URL (`/api/v1`).
const String receivablesBase = '/invoicing/receivables';

/// Maps a transport error to a [ReceivablesException]; the `message` of the answer is kept as detail.
ReceivablesException mapReceivablesError(DioException e) {
  final Response<dynamic>? r = e.response;
  if (r == null) {
    return const ReceivablesException(ReceivablesErrorKind.offline);
  }
  final dynamic body = r.data;
  String detail = '';
  if (body is Map) {
    final dynamic d = body['message'] ?? body['detail'] ?? body['title'];
    detail = d is String ? d : '';
  }
  return switch (r.statusCode) {
    403 => ReceivablesException(ReceivablesErrorKind.forbidden, detail: detail),
    404 => ReceivablesException(ReceivablesErrorKind.notFound, detail: detail),
    422 => ReceivablesException(ReceivablesErrorKind.invalid, detail: detail),
    _ => ReceivablesException(ReceivablesErrorKind.unknown, detail: detail),
  };
}

/// REST access to `/api/v1/invoicing/receivables`. Every read returns the `data` of the envelope as received.
class ReceivablesRemoteDataSource {
  ReceivablesRemoteDataSource(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> dashboard({String? currency}) =>
      _object('/dashboard', <String, dynamic>{'currency': ?currency});

  Future<Map<String, dynamic>> aging({String? customerId, String? currency}) =>
      _object('/aging', <String, dynamic>{
        'customer_id': ?customerId,
        'currency': ?currency,
      });

  /// Every page of `/items` of one customer (the list is paginated, 100 per page, at most 20 pages).
  Future<List<Map<String, dynamic>>> items({
    required String customerId,
    String? currency,
    bool openOnly = true,
  }) async {
    final List<Map<String, dynamic>> rows = <Map<String, dynamic>>[];
    int page = 1;
    int last = 1;
    do {
      final Response<dynamic> res = await _guard(
        () => _dio.get<dynamic>(
          '$receivablesBase/items',
          queryParameters: <String, dynamic>{
            'customer_id': customerId,
            'currency': ?currency,
            if (openOnly) 'open_only': 1,
            'per_page': 100,
            'page': page,
          },
        ),
      );
      final Map<String, dynamic> body = _asMap(res.data);
      final dynamic data = body['data'];
      if (data is List) {
        for (final dynamic raw in data) {
          if (raw is Map) {
            rows.add(Map<String, dynamic>.from(raw));
          }
        }
      }
      final dynamic meta = body['meta'];
      last = meta is Map && meta['last_page'] is num
          ? (meta['last_page'] as num).toInt()
          : 1;
      page++;
    } while (page <= last && page <= 20);
    return rows;
  }

  Future<Map<String, dynamic>> item(String id) => _object('/items/$id');

  Future<Map<String, dynamic>> credit(String customerId) =>
      _object('/customers/$customerId/credit');

  Future<Map<String, dynamic>> risk(String customerId) =>
      _object('/customers/$customerId/risk');

  Future<List<dynamic>> creditLimits(String customerId) =>
      _list('/customers/$customerId/credit-limits');

  Future<List<dynamic>> unreconciledPayments(String customerId) =>
      _list('/customers/$customerId/unreconciled-payments');

  Future<Map<String, dynamic>> dso({
    String? customerId,
    int? periodDays,
    String? currency,
  }) => _object('/dso', <String, dynamic>{
    'customer_id': ?customerId,
    'period_days': ?periodDays,
    'currency': ?currency,
  });

  Future<Map<String, dynamic>> provision({
    String? customerId,
    String? currency,
  }) => _object('/provision', <String, dynamic>{
    'customer_id': ?customerId,
    'currency': ?currency,
  });

  Future<Map<String, dynamic>> statement(
    String customerId, {
    DateTime? from,
    DateTime? to,
    String? currency,
  }) => _object(
    '/customers/$customerId/statement',
    _statementQuery(from, to, currency),
  );

  /// The statement as a file (PDF or XLSX); the bytes are not cached, the share sheet takes them straight away.
  Future<Uint8List> downloadStatement(
    String customerId,
    StatementFormat format, {
    DateTime? from,
    DateTime? to,
    String? currency,
  }) async {
    final Response<List<int>> res = await _guardBytes(
      () => _dio.get<List<int>>(
        '$receivablesBase/customers/$customerId/statement/${format.extension}',
        queryParameters: _statementQuery(from, to, currency),
        options: Options(responseType: ResponseType.bytes),
      ),
    );
    return Uint8List.fromList(res.data ?? const <int>[]);
  }

  static Map<String, dynamic> _statementQuery(
    DateTime? from,
    DateTime? to,
    String? currency,
  ) => <String, dynamic>{
    if (from != null) 'from': formatApiDate(from),
    if (to != null) 'to': formatApiDate(to),
    'currency': ?currency,
  };

  Future<Map<String, dynamic>> _object(
    String path, [
    Map<String, dynamic>? query,
  ]) async {
    final Response<dynamic> res = await _guard(
      () => _dio.get<dynamic>(
        '$receivablesBase$path',
        queryParameters: query == null || query.isEmpty ? null : query,
      ),
    );
    final dynamic data = _asMap(res.data)['data'];
    if (data is! Map) {
      throw const ReceivablesException(ReceivablesErrorKind.unknown);
    }
    return Map<String, dynamic>.from(data);
  }

  Future<List<dynamic>> _list(String path) async {
    final Response<dynamic> res = await _guard(
      () => _dio.get<dynamic>('$receivablesBase$path'),
    );
    final dynamic data = _asMap(res.data)['data'];
    return data is List ? data : <dynamic>[];
  }

  Future<Response<dynamic>> _guard(
    Future<Response<dynamic>> Function() call,
  ) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw mapReceivablesError(e);
    }
  }

  Future<Response<List<int>>> _guardBytes(
    Future<Response<List<int>>> Function() call,
  ) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw mapReceivablesError(e);
    }
  }

  static Map<String, dynamic> _asMap(Object? v) =>
      v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
}
