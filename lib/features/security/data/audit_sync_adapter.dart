import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/security/secure_key_store.dart';
import '../domain/audit_entry.dart';
import '../domain/audit_hasher.dart';
import 'audit_queue.dart';

/// Versioned API prefix the [Dio] base URL already ends with.
const String auditApiPrefix = '/api/v1';

/// Full server endpoint for offline audit batches.
const String auditOfflineBatchesEndpoint =
    '$auditApiPrefix/audit/offline-batches';

/// Same endpoint relative to the Dio `baseUrl` (`<host>/api/v1`).
const String auditOfflineBatchesPath = '/audit/offline-batches';

@immutable
class AuditSyncResult {
  const AuditSyncResult({this.uploaded = 0, this.error});

  final int uploaded;
  final String? error;

  bool get ok => error == null;
}

/// Uploads pending audit entries in chain order, as one atomic batch per request.
///
/// Entries are marked synced only after the server acknowledged the whole batch; a failed
/// request leaves every entry pending so the next attempt re-sends the same contiguous prefix
/// (the idempotency key is derived from tenant and sequence range so retries are safe).
class AuditSyncAdapter {
  AuditSyncAdapter(this._queue, this._dio, this._keys, {this.batchSize = 100});

  final AuditQueue _queue;
  final Dio _dio;
  final DeviceKeyProvider _keys;
  final int batchSize;

  Future<AuditSyncResult> sync(String tenantId) async {
    int uploaded = 0;
    while (true) {
      final List<AuditEntry> batch = await _queue.pending(
        tenantId,
        limit: batchSize,
      );
      if (batch.isEmpty) {
        return AuditSyncResult(uploaded: uploaded);
      }
      final List<int> sequences = batch
          .map((AuditEntry e) => e.sequenceNumber)
          .toList();
      try {
        final Response<dynamic> response = await _dio.post<dynamic>(
          auditOfflineBatchesPath,
          data: <String, Object?>{
            'device_id': await _keys.deviceId(),
            'origin': auditOriginOffline,
            'entries': batch.map(toWire).toList(),
          },
          options: Options(
            headers: <String, Object?>{
              'Idempotency-Key':
                  'audit-$tenantId-${sequences.first}-${sequences.last}',
            },
          ),
        );
        final int status = response.statusCode ?? 0;
        if (status < 200 || status >= 300) {
          throw DioException(
            requestOptions: response.requestOptions,
            response: response,
            message: 'HTTP $status',
          );
        }
        await _queue.markSynced(
          tenantId,
          sequences,
          receipt: _receipt(response.data),
        );
        uploaded += batch.length;
      } on DioException catch (e) {
        final String message = e.message ?? e.type.name;
        await _queue.markFailed(tenantId, sequences, message);
        return AuditSyncResult(uploaded: uploaded, error: message);
      }
    }
  }

  /// Wire form of an entry. Signed fields are sent byte-for-byte as stored.
  @visibleForTesting
  static Map<String, Object?> toWire(AuditEntry e) => <String, Object?>{
    'sequence_number': e.sequenceNumber,
    'uuid': e.uuid,
    'entity_type': e.entityType,
    'entity_id': e.entityId,
    'action': e.action,
    'occurred_at': e.occurredAt.toUtc().toIso8601String(),
    'previous_hash': e.previousHash,
    'payload_hash': e.payloadHash,
    'record_hash': e.recordHash,
    'payload_json': e.payloadJson,
    'metadata_json': e.metadataJson,
    'origin': auditOriginOffline,
  };

  String? _receipt(Object? body) {
    if (body is Map) {
      final Object? data = body['data'];
      return canonicalJson(data is Map ? data : body);
    }
    return null;
  }
}
