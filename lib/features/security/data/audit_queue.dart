import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/security/secure_key_store.dart';
import '../domain/audit_entry.dart';
import '../domain/audit_hasher.dart';

/// Origin marker signed into every entry created while the device is the source of truth.
const String auditOriginOffline = 'offline';

/// Offline hash-chained audit log persisted in the local SQLite database (one chain per tenant).
class AuditQueue {
  AuditQueue(this._db, this._keys, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final AppDatabase _db;
  final DeviceKeyProvider _keys;
  final DateTime Function() _now;

  /// Appends a signed entry. The read of the chain tip and the insert share one transaction so
  /// concurrent writers cannot fork the chain.
  Future<AuditEntry> record({
    required String tenantId,
    required String entityType,
    required String entityId,
    required String action,
    Map<String, Object?> payload = const <String, Object?>{},
  }) async {
    final AuditHasher hasher = AuditHasher(await _keys.auditHmacKey());
    final String deviceId = await _keys.deviceId();
    final DateTime occurredAt = _now().toUtc();
    final String payloadJson = canonicalJson(payload);
    final String payloadHash = AuditHasher.payloadHashOfJson(payloadJson);

    return _db.transaction(() async {
      final AuditQueueRow? tip =
          await (_db.select(_db.auditQueueEntries)
                ..where((AuditQueueEntries t) => t.tenantId.equals(tenantId))
                ..orderBy(<OrderClauseGenerator<AuditQueueEntries>>[
                  (AuditQueueEntries t) => OrderingTerm.desc(t.sequenceNumber),
                ])
                ..limit(1))
              .getSingleOrNull();
      final int sequence = (tip?.sequenceNumber ?? 0) + 1;
      final String previousHash = tip?.recordHash ?? auditGenesisHash;
      final String metadataJson = canonicalJson(<String, Object?>{
        'action': action,
        'device_id': deviceId,
        'entity_id': entityId,
        'entity_type': entityType,
        'occurred_at': occurredAt.toIso8601String(),
        'origin': auditOriginOffline,
        'sequence_number': sequence,
        'tenant_id': tenantId,
      });
      final String recordHash = hasher.recordHash(
        previousHash: previousHash,
        payloadHash: payloadHash,
        metadataJson: metadataJson,
      );
      final String uuid = const Uuid().v4();
      await _db
          .into(_db.auditQueueEntries)
          .insert(
            AuditQueueEntriesCompanion.insert(
              tenantId: tenantId,
              sequenceNumber: sequence,
              uuid: uuid,
              entityType: entityType,
              entityId: entityId,
              action: action,
              payloadJson: payloadJson,
              metadataJson: metadataJson,
              previousHash: previousHash,
              payloadHash: payloadHash,
              recordHash: recordHash,
              occurredAt: occurredAt,
            ),
          );
      return AuditEntry(
        tenantId: tenantId,
        sequenceNumber: sequence,
        uuid: uuid,
        entityType: entityType,
        entityId: entityId,
        action: action,
        payloadJson: payloadJson,
        metadataJson: metadataJson,
        previousHash: previousHash,
        payloadHash: payloadHash,
        recordHash: recordHash,
        occurredAt: occurredAt,
      );
    });
  }

  /// Every entry of the tenant chain in sequence order.
  Future<List<AuditEntry>> entries(String tenantId) async =>
      (await _rows(tenantId)).map(_toEntry).toList();

  /// Unsynced entries in chain order, oldest first.
  Future<List<AuditEntry>> pending(String tenantId, {int limit = 100}) async {
    final List<AuditQueueRow> rows =
        await (_db.select(_db.auditQueueEntries)
              ..where(
                (AuditQueueEntries t) =>
                    t.tenantId.equals(tenantId) & t.syncedAt.isNull(),
              )
              ..orderBy(<OrderClauseGenerator<AuditQueueEntries>>[
                (AuditQueueEntries t) => OrderingTerm.asc(t.sequenceNumber),
              ])
              ..limit(limit))
            .get();
    return rows.map(_toEntry).toList();
  }

  Future<AuditQueueStatus> status(String tenantId) async {
    final List<AuditQueueRow> rows = await _rows(tenantId);
    DateTime? lastSynced;
    String? lastError;
    for (final AuditQueueRow r in rows) {
      final DateTime? s = r.syncedAt;
      if (s != null && (lastSynced == null || s.isAfter(lastSynced))) {
        lastSynced = s;
      }
      if (r.syncedAt == null && r.lastError != null) {
        lastError = r.lastError;
      }
    }
    return AuditQueueStatus(
      total: rows.length,
      pending: rows.where((AuditQueueRow r) => r.syncedAt == null).length,
      lastSyncedAt: lastSynced?.toUtc(),
      lastError: lastError,
    );
  }

  /// Marks [sequences] as uploaded in one statement. Signed columns are never touched.
  Future<void> markSynced(
    String tenantId,
    List<int> sequences, {
    String? receipt,
  }) async {
    await (_db.update(_db.auditQueueEntries)..where(
          (AuditQueueEntries t) =>
              t.tenantId.equals(tenantId) & t.sequenceNumber.isIn(sequences),
        ))
        .write(
          AuditQueueEntriesCompanion(
            syncedAt: Value<DateTime?>(_now().toUtc()),
            lastError: const Value<String?>(null),
            serverReceipt: Value<String?>(receipt),
          ),
        );
  }

  Future<void> markFailed(
    String tenantId,
    List<int> sequences,
    String error,
  ) async {
    await _db.transaction(() async {
      for (final int s in sequences) {
        final AuditQueueRow? row =
            await (_db.select(_db.auditQueueEntries)..where(
                  (AuditQueueEntries t) =>
                      t.tenantId.equals(tenantId) & t.sequenceNumber.equals(s),
                ))
                .getSingleOrNull();
        if (row == null) {
          continue;
        }
        await (_db.update(_db.auditQueueEntries)..where(
              (AuditQueueEntries t) =>
                  t.tenantId.equals(tenantId) & t.sequenceNumber.equals(s),
            ))
            .write(
              AuditQueueEntriesCompanion(
                syncAttempts: Value<int>(row.syncAttempts + 1),
                lastError: Value<String?>(error),
              ),
            );
      }
    });
  }

  /// Recomputes every hash and checks sequence continuity and linkage.
  Future<AuditChainVerification> verifyChain(String tenantId) async {
    final AuditHasher hasher = AuditHasher(await _keys.auditHmacKey());
    final List<AuditQueueRow> rows = await _rows(tenantId);
    String previous = auditGenesisHash;
    int expected = 1;
    int checked = 0;
    for (final AuditQueueRow r in rows) {
      AuditChainVerification broken(String reason) => AuditChainVerification(
        valid: false,
        checked: checked,
        brokenAtSequence: r.sequenceNumber,
        reason: reason,
      );
      if (r.sequenceNumber != expected) {
        return broken('sequence_gap');
      }
      if (r.previousHash != previous) {
        return broken('previous_hash_mismatch');
      }
      if (AuditHasher.payloadHashOfJson(r.payloadJson) != r.payloadHash) {
        return broken('payload_hash_mismatch');
      }
      final Object? meta = jsonDecode(r.metadataJson);
      if (meta is! Map ||
          meta['sequence_number'] != r.sequenceNumber ||
          meta['tenant_id'] != tenantId) {
        return broken('metadata_mismatch');
      }
      final String expectedRecord = hasher.recordHash(
        previousHash: r.previousHash,
        payloadHash: r.payloadHash,
        metadataJson: r.metadataJson,
      );
      if (expectedRecord != r.recordHash) {
        return broken('record_hash_mismatch');
      }
      previous = r.recordHash;
      expected++;
      checked++;
    }
    return AuditChainVerification(valid: true, checked: checked);
  }

  Future<List<AuditQueueRow>> _rows(String tenantId) =>
      (_db.select(_db.auditQueueEntries)
            ..where((AuditQueueEntries t) => t.tenantId.equals(tenantId))
            ..orderBy(<OrderClauseGenerator<AuditQueueEntries>>[
              (AuditQueueEntries t) => OrderingTerm.asc(t.sequenceNumber),
            ]))
          .get();

  AuditEntry _toEntry(AuditQueueRow r) => AuditEntry(
    tenantId: r.tenantId,
    sequenceNumber: r.sequenceNumber,
    uuid: r.uuid,
    entityType: r.entityType,
    entityId: r.entityId,
    action: r.action,
    payloadJson: r.payloadJson,
    metadataJson: r.metadataJson,
    previousHash: r.previousHash,
    payloadHash: r.payloadHash,
    recordHash: r.recordHash,
    occurredAt: r.occurredAt.toUtc(),
    syncedAt: r.syncedAt?.toUtc(),
    syncAttempts: r.syncAttempts,
    lastError: r.lastError,
  );
}
