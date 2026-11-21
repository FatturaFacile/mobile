import 'package:flutter/foundation.dart';

/// Immutable view of one signed audit record.
@immutable
class AuditEntry {
  const AuditEntry({
    required this.tenantId,
    required this.sequenceNumber,
    required this.uuid,
    required this.entityType,
    required this.entityId,
    required this.action,
    required this.payloadJson,
    required this.metadataJson,
    required this.previousHash,
    required this.payloadHash,
    required this.recordHash,
    required this.occurredAt,
    this.syncedAt,
    this.syncAttempts = 0,
    this.lastError,
  });

  final String tenantId;
  final int sequenceNumber;
  final String uuid;
  final String entityType;
  final String entityId;
  final String action;

  /// Canonical JSON that `payloadHash` was computed over.
  final String payloadJson;

  /// Canonical JSON signed into `recordHash` (carries the offline origin).
  final String metadataJson;
  final String previousHash;
  final String payloadHash;
  final String recordHash;
  final DateTime occurredAt;
  final DateTime? syncedAt;
  final int syncAttempts;
  final String? lastError;

  bool get isSynced => syncedAt != null;
}

/// Outcome of `AuditQueue.verifyChain`.
@immutable
class AuditChainVerification {
  const AuditChainVerification({
    required this.valid,
    required this.checked,
    this.brokenAtSequence,
    this.reason,
  });

  final bool valid;
  final int checked;
  final int? brokenAtSequence;
  final String? reason;
}

/// Queue counters for the security screen.
@immutable
class AuditQueueStatus {
  const AuditQueueStatus({
    this.total = 0,
    this.pending = 0,
    this.lastSyncedAt,
    this.lastError,
  });

  final int total;
  final int pending;
  final DateTime? lastSyncedAt;
  final String? lastError;

  int get synced => total - pending;
}
