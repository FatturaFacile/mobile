import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/error/failure.dart';
import '../../../core/network/api_client.dart';
import 'audit_queue.dart';

/// Minimum length of the justification the API (and this client) accepts.
const int piiJustificationMinLength = 10;

/// Server path relative to the Dio base URL (`<host>/api/v1`).
const String piiUnmaskPath = '/security/pii/unmask';

/// Full server endpoint of the unmask call.
const String piiUnmaskEndpoint = '/api/v1/security/pii/unmask';

/// Whether [justification] is long enough once trimmed.
bool isValidJustification(String justification) =>
    justification.trim().length >= piiJustificationMinLength;

abstract interface class PiiUnmaskRepository {
  /// Asks the API to reveal a masked [field]. The call is audited server-side with [justification].
  Future<Either<Failure, String>> unmask({
    required String entityType,
    required String entityId,
    required String field,
    required String justification,
  });
}

class HttpPiiUnmaskRepository implements PiiUnmaskRepository {
  HttpPiiUnmaskRepository(this._dio, this._context, [this._audit]);

  final Dio _dio;
  final RequestContext _context;
  final AuditQueue? _audit;

  @override
  Future<Either<Failure, String>> unmask({
    required String entityType,
    required String entityId,
    required String field,
    required String justification,
  }) async {
    final String reason = justification.trim();
    if (reason.length < piiJustificationMinLength) {
      return const Left<Failure, String>(
        ValidationFailure('justification_too_short'),
      );
    }
    try {
      final Response<dynamic> r = await _dio.post<dynamic>(
        piiUnmaskPath,
        data: <String, Object?>{
          'entity_type': entityType,
          'entity_id': entityId,
          'field': field,
          'justification': reason,
        },
      );
      final String value = _extract(r.data);
      await _recordLocally(entityType, entityId, field, reason);
      return Right<Failure, String>(value);
    } on DioException catch (e) {
      return Left<Failure, String>(mapDioError(e));
    }
  }

  String _extract(Object? body) {
    if (body is Map) {
      final Object? data = body['data'];
      final Object? value = data is Map ? data['value'] : body['value'];
      return value == null ? '' : '$value';
    }
    return '';
  }

  /// Local trail of the reveal; never blocks the result when the tenant is unknown.
  Future<void> _recordLocally(
    String entityType,
    String entityId,
    String field,
    String reason,
  ) async {
    final String? tenant = _context.tenantId;
    final AuditQueue? audit = _audit;
    if (audit == null || tenant == null || tenant.isEmpty) {
      return;
    }
    await audit.record(
      tenantId: tenant,
      entityType: entityType,
      entityId: entityId,
      action: 'pii_unmask',
      payload: <String, Object?>{'field': field, 'justification': reason},
    );
  }
}
