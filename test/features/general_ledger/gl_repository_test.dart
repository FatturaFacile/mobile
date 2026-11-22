import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:fattura_facile/core/database/app_database.dart';
import 'package:fattura_facile/core/sync/sync_engine.dart';
import 'package:fattura_facile/features/general_ledger/data/gl_repository_impl.dart';
import 'package:fattura_facile/features/general_ledger/domain/gl_models.dart';
import 'package:fattura_facile/features/general_ledger/domain/gl_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/sync_engine_test.dart' show FakeAdapter, json;

Map<String, dynamic> envelope(Object data) => <String, dynamic>{
  'success': true,
  'message': 'ok',
  'data': data,
};

JournalEntry entry({int credit = 1000000}) => JournalEntry(
  id: 'j1',
  tenantId: 't1',
  postingDate: '2026-03-10',
  description: 'Capital',
  createdAt: DateTime.utc(2026, 3, 10),
  lines: <JournalLine>[
    const JournalLine(accountId: 'a-bank', debit: 1000000),
    JournalLine(accountId: 'a-cap', credit: credit),
  ],
);

Map<String, dynamic> serverJournal(String id, {String status = 'posted'}) =>
    <String, dynamic>{
      'id': id,
      'posting_date': '2026-03-10',
      'description': 'Capital',
      'ledger_type': 'statutory',
      'status': status,
      'journal_number': 'JE-1',
      'lines': <Map<String, dynamic>>[
        <String, dynamic>{
          'account_id': 'a-bank',
          'debit_amount': 1000.0,
          'credit_amount': 0.0,
        },
        <String, dynamic>{
          'account_id': 'a-cap',
          'debit_amount': 0.0,
          'credit_amount': 1000.0,
        },
      ],
    };

void main() {
  late AppDatabase db;
  late FakeAdapter adapter;
  late GlRepositoryImpl repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    adapter = FakeAdapter(
      (RequestOptions o) =>
          json(201, envelope(<String, dynamic>{'id': 'srv-1'})),
    );
    final Dio dio = Dio(
      BaseOptions(
        baseUrl: 'http://x/api/v1',
        validateStatus: (int? s) => s != null && s < 300,
      ),
    )..httpClientAdapter = adapter;
    repo = GlRepositoryImpl(
      db,
      dio,
      SyncEngine(db, dio),
      clock: () => DateTime.utc(2026, 4, 1),
    );
  });

  tearDown(() => db.close());

  group('submit', () {
    test('online: posts to /general-ledger/journals with an idempotency key and settles as synced', () async {
      final SubmitOutcome o = await repo.submit(entry());

      expect(o.status, SubmitStatus.synced);
      final RequestOptions call = adapter.calls.single;
      expect(call.method, 'POST');
      expect(call.path, '/general-ledger/journals');
      expect(call.headers['Idempotency-Key'], isNotEmpty);
      final Map<String, dynamic> body = call.data as Map<String, dynamic>;
      expect(body['status'], 'posted');
      expect(body['lines'], hasLength(2));
      final JournalEntry stored = (await db.glDao.entry('t1', 'j1'))!;
      expect(stored.syncState, JournalSyncState.synced);
      expect(stored.isEditable, isFalse);
      expect(await db.select(db.syncQueue).get(), isEmpty);
    });

    test('offline: the entry stays queued, immutable, and the outbox keeps the write', () async {
      adapter.handler = (RequestOptions o) =>
          throw DioException.connectionError(requestOptions: o, reason: 'down');

      final SubmitOutcome o = await repo.submit(entry());

      expect(o.status, SubmitStatus.queued);
      final JournalEntry stored = (await db.glDao.entry('t1', 'j1'))!;
      expect(stored.syncState, JournalSyncState.queued);
      expect(stored.isEditable, isFalse);
      final List<QueueItem> queue = await db.select(db.syncQueue).get();
      expect(queue, hasLength(1));
      expect(queue.single.entity, glJournalEntity);
      expect(queue.single.entityId, 'j1');
      expect(jsonDecode(queue.single.payload!)['description'], 'Capital');

      // The device comes back online: the next sync cycle sends it and settles the entry.
      adapter.handler = (RequestOptions o) =>
          json(201, envelope(<String, dynamic>{'id': 'srv-1'}));
      await repo.syncPending('t1');
      expect(
        (await db.glDao.entry('t1', 'j1'))!.syncState,
        JournalSyncState.synced,
      );
      expect(await db.select(db.syncQueue).get(), isEmpty);
    });

    test(
      'an unbalanced entry reaches neither the database nor the outbox',
      () async {
        await expectLater(
          repo.submit(entry(credit: 999999)),
          throwsA(isA<UnbalancedJournalException>()),
        );
        expect(await db.glDao.entries('t1'), isEmpty);
        expect(await db.select(db.syncQueue).get(), isEmpty);
        expect(adapter.calls, isEmpty);
      },
    );

    test('a 422 refuses the entry for good: editable again with the reason, not resent', () async {
      adapter.handler = (RequestOptions o) => json(422, <String, dynamic>{
        'detail': 'Fiscal period closed',
        'status': 422,
      });

      final SubmitOutcome o = await repo.submit(entry());

      expect(o.status, SubmitStatus.rejected);
      final JournalEntry stored = (await db.glDao.entry('t1', 'j1'))!;
      expect(stored.syncState, JournalSyncState.rejected);
      expect(stored.isEditable, isTrue);
      expect(stored.lastError, isNotEmpty);
      expect(await db.select(db.syncQueue).get(), isEmpty);

      await repo.syncPending('t1');
      expect(adapter.calls, hasLength(1));
    });

    test('a queued entry cannot be queued twice', () async {
      adapter.handler = (RequestOptions o) =>
          throw DioException.connectionError(requestOptions: o, reason: 'down');
      await repo.submit(entry());
      await expectLater(
        repo.submit(entry()),
        throwsA(isA<ImmutableJournalException>()),
      );
      expect(await db.select(db.syncQueue).get(), hasLength(1));
    });
  });

  group('storno', () {
    test('queues a reversal draft that points at the original and calls the reverse endpoint', () async {
      adapter.handler = (RequestOptions o) =>
          json(200, envelope(<Map<String, dynamic>>[serverJournal('srv-9')]));
      await repo.refreshJournals('t1');
      final JournalEntry original = (await db.glDao.entries('t1')).single;
      expect(original.status, JournalStatus.posted);
      expect(original.totalDebit, 10000000);

      adapter.calls.clear();
      adapter.handler = (RequestOptions o) =>
          json(200, envelope(<String, dynamic>{'id': 'srv-10'}));
      final SubmitOutcome o = await repo.reverse(
        original,
        reversalDate: '2026-04-01',
        reason: 'typo',
      );

      expect(o.status, SubmitStatus.synced);
      final RequestOptions call = adapter.calls.single;
      expect(call.path, '/general-ledger/journals/srv-9/reverse');
      expect(call.data, <String, dynamic>{
        'reversal_date': '2026-04-01',
        'reason': 'typo',
      });
      final JournalEntry storno = (await db.glDao.entries('t1'))
          .firstWhere((JournalEntry e) => e.isReversal);
      expect(storno.reversesJournalId, 'srv-9');
      expect(storno.lines.first.credit, 10000000);
      expect(storno.lines.first.debit, 0);
    });

    test('a draft cannot be reversed', () async {
      await expectLater(
        repo.reverse(entry(), reversalDate: '2026-04-01', reason: ''),
        throwsA(isA<NotReversibleException>()),
      );
    });
  });

  group('reads', () {
    test('accounts are read page by page into the cache', () async {
      adapter.handler = (RequestOptions o) {
        final int page = o.queryParameters['page'] as int;
        return json(200, <String, dynamic>{
          'data': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'a$page',
              'account_code': '${1000 * page}',
              'name': 'Account $page',
            },
          ],
          'meta': <String, dynamic>{
            'current_page': page,
            'last_page': 2,
            'total': 2,
          },
        });
      };
      final List<GlAccount> accounts = await repo.refreshAccounts('t1');

      expect(accounts.map((GlAccount a) => a.id), <String>['a1', 'a2']);
      expect(
        adapter.calls.map((RequestOptions c) => c.queryParameters['page']),
        <int>[1, 2],
      );
      expect((await repo.cachedAccounts('t1')), hasLength(2));
    });

    test(
      'trial balance uses the filter on the wire and is cached per filter',
      () async {
        adapter.handler = (RequestOptions o) => json(
          200,
          envelope(<String, dynamic>{
            'currency': 'CHF',
            'accounts': <Map<String, dynamic>>[
              <String, dynamic>{
                'account_id': 'a',
                'account_code': '1000',
                'account_name': 'Bank',
                'opening_balance': '0.0000',
                'debit': '400.0000',
                'credit': '0.0000',
                'closing_balance': '400.0000',
              },
            ],
            'totals': <String, dynamic>{
              'debit': '400.0000',
              'credit': '400.0000',
            },
            'is_balanced': true,
          }),
        );

        final TrialBalance t = await repo.refreshTrialBalance(
          't1',
          from: '2026-01-01',
          to: '2026-12-31',
          ledger: LedgerBook.tax,
          columns: 4,
        );

        expect(
          adapter.calls.single.path,
          '/general-ledger/reports/trial-balance',
        );
        expect(adapter.calls.single.queryParameters, <String, dynamic>{
          'from': '2026-01-01',
          'to': '2026-12-31',
          'ledger': '02',
          'columns': 4,
        });
        expect(t.rows.single.debit, 4000000);
        expect(
          (await repo.cachedTrialBalance(
            't1',
            from: '2026-01-01',
            to: '2026-12-31',
            ledger: LedgerBook.tax,
            columns: 4,
          ))!.isBalanced,
          isTrue,
        );
        expect(
          await repo.cachedTrialBalance(
            't1',
            from: '2026-01-01',
            to: '2026-12-31',
            ledger: LedgerBook.statutory,
            columns: 4,
          ),
          isNull,
        );
        expect(
          await repo.cachedTrialBalance(
            't1',
            from: '2026-01-01',
            to: '2026-12-31',
            ledger: LedgerBook.tax,
            columns: 2,
          ),
          isNull,
        );
      },
    );

    test('account ledger keeps the running balance and works offline from the cache', () async {
      adapter.handler = (RequestOptions o) => json(
        200,
        envelope(<String, dynamic>{
          'opening_balance': '0.0000',
          'closing_balance': '450.0000',
          'lines': <Map<String, dynamic>>[
            <String, dynamic>{
              'journal_entry_id': 'j',
              'posting_date': '2026-02-11',
              'description': 'Deposit',
              'debit': '400.0000',
              'credit': '0.0000',
              'running_balance': '400.0000',
            },
          ],
        }),
      );
      await repo.refreshAccountLedger(
        't1',
        accountId: 'a',
        from: '2026-01-01',
        to: '2026-12-31',
        ledger: LedgerBook.tax,
      );

      expect(adapter.calls.single.queryParameters['account_id'], 'a');
      expect(adapter.calls.single.queryParameters['ledger'], '02');
      final AccountLedger? cached = await repo.cachedAccountLedger(
        't1',
        accountId: 'a',
        from: '2026-01-01',
        to: '2026-12-31',
        ledger: LedgerBook.tax,
      );
      expect(cached!.closing, 4500000);
      expect(cached.lines.single.runningBalance, 4000000);
    });

    test('a failed read maps to a GlException', () async {
      adapter.handler = (RequestOptions o) =>
          json(403, <String, dynamic>{'detail': 'no'});
      await expectLater(
        repo.refreshJournals('t1'),
        throwsA(
          isA<GlException>().having(
            (GlException e) => e.kind,
            'kind',
            GlErrorKind.forbidden,
          ),
        ),
      );
    });
  });
}
