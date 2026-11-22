import 'package:drift/native.dart';
import 'package:fattura_facile/core/database/app_database.dart';
import 'package:fattura_facile/features/general_ledger/data/local/gl_dao.dart';
import 'package:fattura_facile/features/general_ledger/domain/gl_models.dart';
import 'package:flutter_test/flutter_test.dart';

JournalEntry draft(
  String id, {
  String tenant = 't1',
  int credit = 1000000,
  String date = '2026-03-10',
}) => JournalEntry(
  id: id,
  tenantId: tenant,
  postingDate: date,
  description: 'Entry $id',
  createdAt: DateTime.utc(2026, 3, 10),
  alsoPostTo: const <LedgerBook>[LedgerBook.tax],
  lines: <JournalLine>[
    const JournalLine(accountId: 'a-bank', accountCode: '1000', debit: 1000000),
    JournalLine(accountId: 'a-cap', accountCode: '3000', credit: credit),
  ],
);

void main() {
  late AppDatabase db;
  late GlDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = db.glDao;
  });

  tearDown(() => db.close());

  group('journals', () {
    test('an unbalanced entry is never stored', () async {
      await expectLater(
        dao.saveDraft(draft('u', credit: 999999)),
        throwsA(isA<UnbalancedJournalException>()),
      );
      expect(await dao.entries('t1'), isEmpty);
    });

    test(
      'a balanced draft round-trips with its lines, books and amounts',
      () async {
        await dao.saveDraft(draft('d1'));
        final JournalEntry? stored = await dao.entry('t1', 'd1');

        expect(stored, isNotNull);
        expect(stored!.lines, hasLength(2));
        expect(stored.totalDebit, 1000000);
        expect(stored.isBalanced, isTrue);
        expect(stored.alsoPostTo, <LedgerBook>[LedgerBook.tax]);
        expect(stored.syncState, JournalSyncState.localDraft);
        expect(stored.lines.first.accountCode, '1000');
      },
    );

    test(
      'a draft can be edited until it is queued, then it is immutable',
      () async {
        await dao.saveDraft(draft('d1'));
        await dao.saveDraft(
          draft('d1', credit: 1000000).copyWith(description: 'Edited'),
        );
        expect((await dao.entry('t1', 'd1'))!.description, 'Edited');

        final JournalEntry queued = await dao.markQueued(
          't1',
          'd1',
          post: true,
        );
        expect(queued.syncState, JournalSyncState.queued);
        expect(queued.postOnSync, isTrue);

        await expectLater(
          dao.saveDraft(draft('d1')),
          throwsA(isA<ImmutableJournalException>()),
        );
        await expectLater(
          dao.discard('t1', 'd1'),
          throwsA(isA<ImmutableJournalException>()),
        );
        expect((await dao.entry('t1', 'd1'))!.description, 'Edited');
      },
    );

    test(
      'an entry that was tampered with in the database cannot be queued',
      () async {
        await dao.saveDraft(draft('d1'));
        await db.customStatement(
          "UPDATE gl_journal_lines SET credit = 5 WHERE entry_id = 'd1' AND line_number = 2",
        );
        await expectLater(
          dao.markQueued('t1', 'd1', post: true),
          throwsA(isA<UnbalancedJournalException>()),
        );
        expect(
          (await dao.entry('t1', 'd1'))!.syncState,
          JournalSyncState.localDraft,
        );
      },
    );

    test('a refused entry is editable again and can be discarded', () async {
      await dao.saveDraft(draft('d1'));
      await dao.markQueued('t1', 'd1', post: true);
      await dao.setSyncState(
        't1',
        'd1',
        JournalSyncState.rejected,
        error: 'period closed',
      );

      final JournalEntry refused = (await dao.entry('t1', 'd1'))!;
      expect(refused.isEditable, isTrue);
      expect(refused.lastError, 'period closed');

      await dao.discard('t1', 'd1');
      expect(await dao.entry('t1', 'd1'), isNull);
    });

    test(
      'a server refresh replaces the synced copies and keeps the local work',
      () async {
        await dao.saveDraft(draft('local'));
        await dao.saveDraft(draft('queued'));
        await dao.markQueued('t1', 'queued', post: true);
        await dao.replaceServerEntries('t1', <JournalEntry>[
          draft(
            'old-server',
            date: '2026-01-01',
          ).copyWith(status: JournalStatus.posted),
        ]);
        await dao.replaceServerEntries('t1', <JournalEntry>[
          draft(
            'new-server',
            date: '2026-02-01',
          ).copyWith(status: JournalStatus.posted),
        ]);

        final List<JournalEntry> all = await dao.entries('t1');
        expect(all.map((JournalEntry e) => e.id).toSet(), <String>{
          'local',
          'queued',
          'new-server',
        });
        final JournalEntry server = all.firstWhere(
          (JournalEntry e) => e.id == 'new-server',
        );
        expect(server.syncState, JournalSyncState.synced);
        expect(server.isEditable, isFalse);
      },
    );

    test('everything is scoped to the tenant', () async {
      await dao.saveDraft(draft('d1'));
      expect(await dao.entries('t2'), isEmpty);
      expect(await dao.entry('t2', 'd1'), isNull);
    });

    test('deleting an entry removes its lines', () async {
      await dao.saveDraft(draft('d1'));
      await dao.discard('t1', 'd1');
      final int lines = await db
          .customSelect('SELECT COUNT(*) AS n FROM gl_journal_lines')
          .map((row) => row.read<int>('n'))
          .getSingle();
      expect(lines, 0);
    });
  });

  group('caches', () {
    test('accounts are replaced per tenant and sorted by code', () async {
      await dao.replaceAccounts('t1', const <GlAccount>[
        GlAccount(
          id: 'b',
          code: '3000',
          name: 'Capital',
          normalBalance: 'credit',
        ),
        GlAccount(id: 'a', code: '1000', name: 'Bank'),
      ]);
      await dao.replaceAccounts('t2', const <GlAccount>[
        GlAccount(id: 'x', code: '9', name: 'Other'),
      ]);
      expect((await dao.accounts('t1')).map((GlAccount a) => a.code), <String>[
        '1000',
        '3000',
      ]);

      await dao.replaceAccounts('t1', const <GlAccount>[
        GlAccount(
          id: 'c',
          code: '2000',
          name: 'Payable',
          allowsManualPosting: false,
        ),
      ]);
      final List<GlAccount> fresh = await dao.accounts('t1');
      expect(fresh.single.id, 'c');
      expect(fresh.single.allowsManualPosting, isFalse);
      expect(await dao.accounts('t2'), hasLength(1));
    });

    test('templates keep their parameters and lines', () async {
      final AccountingTemplate t = AccountingTemplate.fromJson(
        const <String, dynamic>{
          'id': 'tpl',
          'code': 'SELF_INVOICE',
          'names': <String, String>{'en': 'Self-invoice'},
          'parameters': <Map<String, String>>[
            <String, String>{'key': 'amount', 'type': 'amount'},
            <String, String>{'key': 'expense', 'type': 'account'},
          ],
          'lines': <Map<String, String>>[
            <String, String>{
              'account': r'$expense',
              'side': 'debit',
              'amount': 'amount',
            },
          ],
          'ledger_type': 'tax',
        },
      );
      await dao.replaceTemplates('t1', <AccountingTemplate>[t]);

      final AccountingTemplate back = (await dao.templates('t1')).single;
      expect(back.code, 'SELF_INVOICE');
      expect(back.ledger, LedgerBook.tax);
      expect(back.accountKeys, <String>['expense']);
      expect(back.lines.single.isDebit, isTrue);
      expect(await dao.templates('t2'), isEmpty);
    });

    test('report snapshots are stored per filter and overwritten', () async {
      await dao.saveSnapshot('t1', trialBalanceKind, 'k1', <String, dynamic>{
        'v': 1,
      });
      await dao.saveSnapshot('t1', trialBalanceKind, 'k2', <String, dynamic>{
        'v': 2,
      });
      await dao.saveSnapshot('t1', trialBalanceKind, 'k1', <String, dynamic>{
        'v': 3,
      });

      expect((await dao.snapshot('t1', trialBalanceKind, 'k1'))!['v'], 3);
      expect((await dao.snapshot('t1', trialBalanceKind, 'k2'))!['v'], 2);
      expect(await dao.snapshot('t1', accountLedgerKind, 'k1'), isNull);
      expect(await dao.snapshot('t2', trialBalanceKind, 'k1'), isNull);
    });
  });
}
