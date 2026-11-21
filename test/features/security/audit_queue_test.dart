import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:fattura_facile/core/database/app_database.dart';
import 'package:fattura_facile/core/security/secure_key_store.dart';
import 'package:fattura_facile/features/security/data/audit_queue.dart';
import 'package:fattura_facile/features/security/data/audit_sync_adapter.dart';
import 'package:fattura_facile/features/security/domain/audit_entry.dart';
import 'package:fattura_facile/features/security/domain/audit_hasher.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/sync_engine_test.dart' show FakeAdapter, json;

const String tenant = 't1';

void main() {
  late Directory dir;
  late File file;
  late MemorySecureKeyStore vault;
  late DateTime clock;

  AppDatabase open() => AppDatabase(NativeDatabase(file));
  AuditQueue queueOn(AppDatabase db) => AuditQueue(
    db,
    DeviceKeyProvider(vault),
    now: () => clock = clock.add(const Duration(seconds: 1)),
  );

  setUp(() {
    dir = Directory.systemTemp.createTempSync('ff_audit_test');
    file = File('${dir.path}/audit.sqlite');
    vault = MemorySecureKeyStore();
    clock = DateTime.utc(2026, 1, 1);
  });

  tearDown(() => dir.deleteSync(recursive: true));

  test('canonical JSON sorts keys recursively', () {
    expect(
      canonicalJson(<String, Object?>{
        'b': 1,
        'a': <String, Object?>{
          'z': 1,
          'y': <Object?>[2, 1],
        },
      }),
      '{"a":{"y":[2,1],"z":1},"b":1}',
    );
  });

  test('entries are chained, hashed as specified and verify cleanly', () async {
    final AppDatabase db = open();
    final AuditQueue q = queueOn(db);
    final AuditEntry a = await q.record(
      tenantId: tenant,
      entityType: 'invoice',
      entityId: '1',
      action: 'view',
      payload: <String, Object?>{'b': 2, 'a': 1},
    );
    final AuditEntry b = await q.record(
      tenantId: tenant,
      entityType: 'invoice',
      entityId: '1',
      action: 'update',
    );

    expect(a.sequenceNumber, 1);
    expect(a.previousHash, auditGenesisHash);
    expect(a.payloadJson, '{"a":1,"b":2}');
    expect(a.payloadHash, AuditHasher.payloadHashOfJson('{"a":1,"b":2}'));
    expect(a.occurredAt.isUtc, isTrue);
    expect(a.metadataJson, contains('"origin":"offline"'));
    final AuditHasher hasher = AuditHasher(
      await DeviceKeyProvider(vault).auditHmacKey(),
    );
    expect(
      a.recordHash,
      hasher.recordHash(
        previousHash: a.previousHash,
        payloadHash: a.payloadHash,
        metadataJson: a.metadataJson,
      ),
    );
    expect(b.sequenceNumber, 2);
    expect(b.previousHash, a.recordHash);

    final AuditChainVerification v = await q.verifyChain(tenant);
    expect(v.valid, isTrue);
    expect(v.checked, 2);
    await db.close();
  });

  test('the queue and chain survive a restart and keep extending', () async {
    AppDatabase db = open();
    await queueOn(db).record(
      tenantId: tenant,
      entityType: 'invoice',
      entityId: '1',
      action: 'view',
    );
    await db.close();

    db = open();
    final AuditQueue q = queueOn(db);
    expect((await q.status(tenant)).pending, 1);
    final AuditEntry next = await q.record(
      tenantId: tenant,
      entityType: 'invoice',
      entityId: '2',
      action: 'view',
    );
    expect(next.sequenceNumber, 2);
    expect((await q.verifyChain(tenant)).valid, isTrue);
    await db.close();
  });

  test(
    'tampering with any signed field breaks verification at that entry',
    () async {
      final AppDatabase db = open();
      final AuditQueue q = queueOn(db);
      for (int i = 0; i < 3; i++) {
        await q.record(
          tenantId: tenant,
          entityType: 'invoice',
          entityId: '$i',
          action: 'view',
          payload: <String, Object?>{'i': i},
        );
      }
      await (db.update(
        db.auditQueueEntries,
      )..where((AuditQueueEntries t) => t.sequenceNumber.equals(2))).write(
        const AuditQueueEntriesCompanion(
          payloadJson: Value<String>('{"i":99}'),
        ),
      );
      final AuditChainVerification v = await q.verifyChain(tenant);
      expect(v.valid, isFalse);
      expect(v.brokenAtSequence, 2);
      expect(v.reason, 'payload_hash_mismatch');
      await db.close();
    },
  );

  test('a forged record hash (wrong device key) is rejected', () async {
    final AppDatabase db = open();
    final AuditQueue q = queueOn(db);
    await q.record(
      tenantId: tenant,
      entityType: 'invoice',
      entityId: '1',
      action: 'view',
    );
    vault.values[SecureKeyNames.auditHmacKey] =
        'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=';
    final AuditChainVerification v = await q.verifyChain(tenant);
    expect(v.valid, isFalse);
    expect(v.reason, 'record_hash_mismatch');
    await db.close();
  });

  group('sync adapter', () {
    late AppDatabase db;
    late AuditQueue q;
    late FakeAdapter adapter;
    late AuditSyncAdapter sync;

    setUp(() async {
      db = open();
      q = queueOn(db);
      adapter = FakeAdapter(
        (RequestOptions o) => json(201, <String, dynamic>{
          'data': <String, dynamic>{'batch_id': 'b1'},
        }),
      );
      final Dio dio = Dio(BaseOptions(baseUrl: 'https://x.test/api/v1'))
        ..httpClientAdapter = adapter;
      sync = AuditSyncAdapter(q, dio, DeviceKeyProvider(vault), batchSize: 2);
      for (int i = 0; i < 3; i++) {
        await q.record(
          tenantId: tenant,
          entityType: 'invoice',
          entityId: '$i',
          action: 'view',
        );
      }
    });

    tearDown(() => db.close());

    test('endpoint constant targets the versioned API', () {
      expect(auditOfflineBatchesEndpoint, '/api/v1/audit/offline-batches');
    });

    test('uploads in order, in batches, and marks synced only after success without touching signed fields', () async {
      final List<AuditEntry> before = await q.entries(tenant);
      final AuditSyncResult r = await sync.sync(tenant);

      expect(r.ok, isTrue);
      expect(r.uploaded, 3);
      expect(adapter.calls.length, 2);
      final List<dynamic> first =
          (adapter.calls[0].data as Map<String, dynamic>)['entries']
              as List<dynamic>;
      expect(
        first.map(
          (dynamic e) => (e as Map<String, dynamic>)['sequence_number'],
        ),
        <int>[1, 2],
      );
      expect((first.first as Map<String, dynamic>)['origin'], 'offline');
      expect(
        (first.first as Map<String, dynamic>)['record_hash'],
        before.first.recordHash,
      );
      expect(adapter.calls[0].headers['Idempotency-Key'], 'audit-t1-1-2');

      final List<AuditEntry> after = await q.entries(tenant);
      expect(after.every((AuditEntry e) => e.isSynced), isTrue);
      for (int i = 0; i < 3; i++) {
        expect(after[i].recordHash, before[i].recordHash);
        expect(after[i].payloadJson, before[i].payloadJson);
        expect(after[i].metadataJson, before[i].metadataJson);
      }
      expect((await q.verifyChain(tenant)).valid, isTrue);
      expect((await q.status(tenant)).pending, 0);
    });

    test(
      'a failed upload leaves the batch pending and records the error',
      () async {
        adapter.handler = (RequestOptions o) =>
            json(500, <String, dynamic>{'message': 'boom'});
        final AuditSyncResult r = await sync.sync(tenant);
        expect(r.ok, isFalse);
        final AuditQueueStatus s = await q.status(tenant);
        expect(s.pending, 3);
        expect(s.lastError, isNotNull);
        expect((await q.pending(tenant)).first.syncAttempts, 1);
      },
    );

    test('a later batch failing keeps the earlier batch synced and the rest pending in order', () async {
      int n = 0;
      adapter.handler = (RequestOptions o) => ++n == 1
          ? json(201, <String, dynamic>{})
          : json(503, <String, dynamic>{});
      final AuditSyncResult r = await sync.sync(tenant);
      expect(r.uploaded, 2);
      expect(
        (await q.pending(tenant)).map((AuditEntry e) => e.sequenceNumber),
        <int>[3],
      );
    });
  });
}
