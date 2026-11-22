import 'package:dio/dio.dart';

import '../domain/customer_lifecycle_models.dart';

/// Why a request failed.
enum LifecycleErrorKind {
  offline,
  unauthorized,
  forbidden,
  notFound,
  validation,
  failed,
}

class LifecycleRemoteException implements Exception {
  const LifecycleRemoteException(this.kind, [this.detail = '']);

  final LifecycleErrorKind kind;
  final String detail;

  @override
  String toString() => 'LifecycleRemoteException($kind, $detail)';
}

/// REST access to the customer 360 endpoints of the web-api (online only: no offline cache or write queue yet).
class CustomerLifecycleRemoteDataSource {
  CustomerLifecycleRemoteDataSource(this._dio);

  final Dio _dio;

  /// The CRM account behind a contact (party master), or null when the contact has none.
  Future<String?> findAccountId(String contactId) async {
    final Response<dynamic> response = await _request(
      () => _dio.get<dynamic>(
        '/crm/accounts',
        queryParameters: <String, dynamic>{'contact_id': contactId},
      ),
    );
    final dynamic body = response.data;
    dynamic rows = body is Map ? body['data'] : null;
    if (rows is Map) {
      rows = rows['data'];
    }
    if (rows is List && rows.isNotEmpty && rows.first is Map) {
      return (rows.first as Map<dynamic, dynamic>)['id'] as String?;
    }
    return null;
  }

  /// Customers whose name matches [query] (the contact list of the CRM).
  Future<List<LifecycleContact>> searchContacts(String query) async {
    final Response<dynamic> response = await _request(
      () => _dio.get<dynamic>(
        '/crm/contacts',
        queryParameters: <String, dynamic>{'search': query, 'per_page': 20},
      ),
    );
    final dynamic body = response.data;
    dynamic rows = body is Map ? body['data'] : null;
    if (rows is Map) {
      rows = rows['data'];
    }
    if (rows is! List) {
      return <LifecycleContact>[];
    }
    return rows
        .whereType<Map<dynamic, dynamic>>()
        .map(
          (Map<dynamic, dynamic> row) =>
              LifecycleContact.fromJson(Map<String, dynamic>.from(row)),
        )
        .toList();
  }

  Future<CustomerLifecycleSummary> summary(String accountId) async {
    final Response<dynamic> response = await _request(
      () => _dio.get<dynamic>('/crm/customers/$accountId/360'),
    );
    final dynamic body = response.data;
    final dynamic data = body is Map ? body['data'] : null;
    if (data is! Map) {
      throw const LifecycleRemoteException(
        LifecycleErrorKind.failed,
        'no data',
      );
    }
    return CustomerLifecycleSummary.fromJson(Map<String, dynamic>.from(data));
  }

  Future<List<CustomerTimelineEvent>> timeline(
    String accountId, {
    List<String> types = const <String>[],
    int limit = 50,
  }) async {
    final Response<dynamic> response = await _request(
      () => _dio.get<dynamic>(
        '/crm/customers/$accountId/timeline',
        queryParameters: <String, dynamic>{
          'limit': limit,
          if (types.isNotEmpty) 'types[]': types,
        },
      ),
    );
    final dynamic body = response.data;
    final dynamic data = body is Map ? body['data'] : null;
    if (data is! List) {
      return <CustomerTimelineEvent>[];
    }
    return data
        .whereType<Map<dynamic, dynamic>>()
        .map(
          (Map<dynamic, dynamic> row) =>
              CustomerTimelineEvent.fromJson(Map<String, dynamic>.from(row)),
        )
        .toList();
  }

  static const String activitiesPath = '/crm/activities';

  /// The `crm/activities` request body of a quick action.
  static Map<String, dynamic> activityBody({
    required String accountId,
    required String type,
    required String subject,
    String? dueDate,
  }) => <String, dynamic>{
    'type': type,
    'subject': subject,
    'due_date': dueDate,
    'related_type': 'account',
    'related_id': accountId,
  };

  /// Logs a CRM activity (`meeting` for a visit, `follow_up`) on [accountId]. Throws [LifecycleRemoteException]:
  /// kind `offline` when the network is unreachable, `validation` on a 4xx validation error.
  Future<void> createActivity({
    required String accountId,
    required String type,
    required String subject,
    String? dueDate,
  }) async {
    await _request(
      () => _dio.post<dynamic>(
        activitiesPath,
        data: activityBody(
          accountId: accountId,
          type: type,
          subject: subject,
          dueDate: dueDate,
        ),
      ),
    );
  }

  Future<Response<dynamic>> _request(
    Future<Response<dynamic>> Function() run,
  ) async {
    try {
      return await run();
    } on DioException catch (e) {
      final int? status = e.response?.statusCode;
      throw LifecycleRemoteException(switch (status) {
        null => LifecycleErrorKind.offline,
        401 => LifecycleErrorKind.unauthorized,
        403 => LifecycleErrorKind.forbidden,
        404 => LifecycleErrorKind.notFound,
        400 || 422 => LifecycleErrorKind.validation,
        _ => LifecycleErrorKind.failed,
      }, '${status ?? e.message ?? ''}');
    }
  }
}
