import 'package:dio/dio.dart';

import '../../domain/entities/budget_check.dart';

/// Typed exception thrown when `POST /{id}/submit` is blocked by the Cost Center budget check (`Mod 019`).
class BudgetHardBlockException implements Exception {
  const BudgetHardBlockException({
    required this.budgetCheck,
    required this.message,
  });

  final BudgetCheckResult budgetCheck;
  final String message;

  @override
  String toString() => 'BudgetHardBlockException($message)';
}

/// REST client aligned to `/api/v1/procurement/purchase-requisitions`.
class PurchaseRequisitionRemoteDataSource {
  const PurchaseRequisitionRemoteDataSource(this._dio);

  static const String _basePath = '/procurement/purchase-requisitions';

  final Dio _dio;

  /// `GET /procurement/purchase-requisitions`
  Future<List<Map<String, dynamic>>> fetchRequisitions() async {
    final Response<dynamic> res = await _dio.get<dynamic>(_basePath);
    return _extractList(res.data);
  }

  /// `GET /procurement/purchase-requisitions/{id}`
  Future<Map<String, dynamic>> fetchRequisitionDetail(String id) async {
    final Response<dynamic> res = await _dio.get<dynamic>('$_basePath/$id');
    return _extractMap(res.data);
  }

  /// `GET /procurement/purchase-requisitions/pending-approvals`
  Future<List<Map<String, dynamic>>> fetchPendingApprovals() async {
    final Response<dynamic> res = await _dio.get<dynamic>(
      '$_basePath/pending-approvals',
    );
    return _extractList(res.data);
  }

  /// `POST /procurement/purchase-requisitions`
  Future<Map<String, dynamic>> createRequisition(
    Map<String, dynamic> body, {
    required String idempotencyKey,
  }) async {
    final Response<dynamic> res = await _dio.post<dynamic>(
      _basePath,
      data: body,
      options: Options(
        headers: <String, dynamic>{'Idempotency-Key': idempotencyKey},
      ),
    );
    return _extractMap(res.data);
  }

  /// `PUT /procurement/purchase-requisitions/{id}`
  Future<Map<String, dynamic>> updateRequisition(
    String remoteId,
    Map<String, dynamic> body, {
    required String idempotencyKey,
  }) async {
    final Response<dynamic> res = await _dio.put<dynamic>(
      '$_basePath/$remoteId',
      data: body,
      options: Options(
        headers: <String, dynamic>{'Idempotency-Key': idempotencyKey},
      ),
    );
    return _extractMap(res.data);
  }

  /// `POST /procurement/purchase-requisitions/{id}/submit`
  Future<Map<String, dynamic>> submitRequisition(
    String remoteId, {
    required String idempotencyKey,
    bool acknowledgeBudgetWarning = false,
  }) async {
    try {
      final Response<dynamic> res = await _dio.post<dynamic>(
        '$_basePath/$remoteId/submit',
        data: <String, dynamic>{
          'acknowledge_budget_warning': acknowledgeBudgetWarning,
        },
        options: Options(
          headers: <String, dynamic>{'Idempotency-Key': idempotencyKey},
        ),
      );
      return _extractMap(res.data);
    } on DioException catch (e) {
      final BudgetHardBlockException? hardBlock = _tryExtractBudgetHardBlock(e);
      if (hardBlock != null) {
        throw hardBlock;
      }
      rethrow;
    }
  }

  /// `POST /procurement/purchase-requisitions/budget-preview`
  Future<BudgetCheckResult> previewBudget(Map<String, dynamic> body) async {
    final Response<dynamic> res = await _dio.post<dynamic>(
      '$_basePath/budget-preview',
      data: body,
    );
    final Map<String, dynamic> map = _extractMap(res.data);
    final Object? nested = map['budget_check'];
    return BudgetCheckResult.fromJson(
      nested is Map<String, dynamic> ? nested : map,
    );
  }

  /// `POST /procurement/purchase-requisitions/{id}/approve`
  Future<Map<String, dynamic>> approveRequisition(
    String remoteId, {
    String? comment,
    String channel = 'mobile_app',
    required String idempotencyKey,
  }) async {
    final Response<dynamic> res = await _dio.post<dynamic>(
      '$_basePath/$remoteId/approve',
      data: <String, dynamic>{
        'channel': channel,
        if (comment != null && comment.trim().isNotEmpty)
          'comment': comment.trim(),
      },
      options: Options(
        headers: <String, dynamic>{'Idempotency-Key': idempotencyKey},
      ),
    );
    return _extractMap(res.data);
  }

  /// `POST /procurement/purchase-requisitions/{id}/reject`
  Future<Map<String, dynamic>> rejectRequisition(
    String remoteId, {
    required String reason,
    String channel = 'mobile_app',
    required String idempotencyKey,
  }) async {
    final Response<dynamic> res = await _dio.post<dynamic>(
      '$_basePath/$remoteId/reject',
      data: <String, dynamic>{'reason': reason, 'channel': channel},
      options: Options(
        headers: <String, dynamic>{'Idempotency-Key': idempotencyKey},
      ),
    );
    return _extractMap(res.data);
  }

  /// `POST /procurement/purchase-requisitions/one-click-action`
  Future<Map<String, dynamic>> oneClickAction({
    required String requisitionId,
    String? approvalId,
    required String action,
    String? token,
    String? reason,
    String channel = 'mobile_push',
    required String idempotencyKey,
  }) async {
    final Response<dynamic> res = await _dio.post<dynamic>(
      '$_basePath/one-click-action',
      data: <String, dynamic>{
        'requisition_id': requisitionId,
        if (approvalId != null && approvalId.isNotEmpty)
          'approval_id': approvalId,
        'action': action,
        if (token != null && token.isNotEmpty) 'token': token,
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
        'channel': channel,
      },
      options: Options(
        headers: <String, dynamic>{'Idempotency-Key': idempotencyKey},
      ),
    );
    return _extractMap(res.data);
  }

  /// Best-effort fetch of Cost Centers for online picker hydration.
  Future<List<Map<String, dynamic>>> fetchCostCenters() async {
    try {
      final Response<dynamic> res = await _dio.get<dynamic>(
        '/procurement/cost-centers',
      );
      return _extractList(res.data);
    } on DioException {
      return <Map<String, dynamic>>[];
    }
  }

  /// Best-effort fetch of Projects for online picker hydration.
  Future<List<Map<String, dynamic>>> fetchProjects() async {
    try {
      final Response<dynamic> res = await _dio.get<dynamic>('/projects');
      return _extractList(res.data);
    } on DioException {
      return <Map<String, dynamic>>[];
    }
  }

  /// Best-effort catalog search against `/inventory/products`.
  Future<List<Map<String, dynamic>>> searchCatalog(String query) async {
    try {
      final Response<dynamic> res = await _dio.get<dynamic>(
        '/inventory/products',
        queryParameters: <String, dynamic>{
          if (query.trim().isNotEmpty) 'search': query.trim(),
        },
      );
      return _extractList(res.data);
    } on DioException {
      return <Map<String, dynamic>>[];
    }
  }

  BudgetHardBlockException? _tryExtractBudgetHardBlock(DioException e) {
    final Response<dynamic>? r = e.response;
    if (r == null || (r.statusCode != 422 && r.statusCode != 409)) {
      return null;
    }
    final dynamic body = r.data;
    if (body is! Map) {
      return null;
    }
    final Map<String, dynamic> map = body.map(
      (dynamic k, dynamic v) => MapEntry<String, dynamic>('$k', v),
    );
    final Object? data = map['data'];
    final Map<String, dynamic>? nestedData = data is Map
        ? data.map((dynamic k, dynamic v) => MapEntry<String, dynamic>('$k', v))
        : null;

    final Object? rawBudget =
        map['budget_check'] ?? nestedData?['budget_check'];
    final String code = '${map['code'] ?? nestedData?['code'] ?? ''}';
    final String message = '${map['message'] ?? ''}';

    if (rawBudget is Map) {
      final Map<String, dynamic> budgetMap = rawBudget.map(
        (dynamic k, dynamic v) => MapEntry<String, dynamic>('$k', v),
      );
      budgetMap.putIfAbsent(
        'status',
        () => BudgetCheckStatus.hardBlock.wireValue,
      );
      final BudgetCheckResult parsed = BudgetCheckResult.fromJson(budgetMap);
      if (parsed.status == BudgetCheckStatus.hardBlock ||
          code.contains('budget')) {
        return BudgetHardBlockException(
          budgetCheck: parsed,
          message: message.isNotEmpty ? message : parsed.message,
        );
      }
    } else if (code == 'budget_hard_block' || code == 'budget_exceeded') {
      return BudgetHardBlockException(
        budgetCheck: BudgetCheckResult.fromJson(<String, dynamic>{
          'status': BudgetCheckStatus.hardBlock.wireValue,
          'message': message,
        }),
        message: message,
      );
    }
    return null;
  }

  Map<String, dynamic> _extractMap(dynamic raw) {
    if (raw is! Map) {
      return <String, dynamic>{};
    }
    final Map<String, dynamic> map = raw.map(
      (dynamic k, dynamic v) => MapEntry<String, dynamic>('$k', v),
    );
    final dynamic data = map['data'];
    if (data is Map) {
      return data.map(
        (dynamic k, dynamic v) => MapEntry<String, dynamic>('$k', v),
      );
    }
    return map;
  }

  List<Map<String, dynamic>> _extractList(dynamic raw) {
    if (raw is List) {
      return raw.whereType<Map<dynamic, dynamic>>().map(_stringKeyMap).toList();
    }
    if (raw is! Map) {
      return <Map<String, dynamic>>[];
    }
    final dynamic data = raw['data'];
    if (data is List) {
      return data
          .whereType<Map<dynamic, dynamic>>()
          .map(_stringKeyMap)
          .toList();
    }
    if (data is Map && data['data'] is List) {
      return (data['data'] as List<dynamic>)
          .whereType<Map<dynamic, dynamic>>()
          .map(_stringKeyMap)
          .toList();
    }
    final dynamic items = raw['items'];
    if (items is List) {
      return items
          .whereType<Map<dynamic, dynamic>>()
          .map(_stringKeyMap)
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  Map<String, dynamic> _stringKeyMap(Map<dynamic, dynamic> raw) {
    return raw.map(
      (dynamic k, dynamic v) => MapEntry<String, dynamic>('$k', v),
    );
  }
}
