import 'package:fattura_facile/features/general_ledger/domain/gl_amount.dart';
import 'package:fattura_facile/features/general_ledger/domain/gl_models.dart';
import 'package:fattura_facile/features/general_ledger/presentation/gl_strings.dart';
import 'package:flutter_test/flutter_test.dart';

JournalEntry entry({
  List<JournalLine>? lines,
  String description = 'Rent',
  JournalStatus status = JournalStatus.draft,
  JournalSyncState sync = JournalSyncState.localDraft,
  String? serverId,
}) => JournalEntry(
  id: 'j1',
  tenantId: 't1',
  postingDate: '2026-03-10',
  description: description,
  status: status,
  syncState: sync,
  serverId: serverId,
  createdAt: DateTime.utc(2026, 3, 10),
  lines:
      lines ??
      const <JournalLine>[
        JournalLine(accountId: 'a-rent', debit: 3000000),
        JournalLine(accountId: 'a-bank', credit: 3000000),
      ],
);

void main() {
  group('amounts', () {
    test('parse accepts dot and comma and rounds half up at 4 decimals', () {
      expect(parseAmount('12.5'), 125000);
      expect(parseAmount('12,50'), 125000);
      expect(parseAmount('0.00005'), 1);
      expect(parseAmount('0.00004'), 0);
      expect(parseAmount('-1'), isNull);
      expect(parseAmount('abc'), isNull);
      expect(parseAmount(''), isNull);
    });

    test('wire and display formats', () {
      expect(amountToWire(1081000), '108.1000');
      expect(amountToWire(-5), '-0.0005');
      expect(amountFromJson('-12.3400'), -123400);
      expect(amountFromJson(10.5), 105000);
      expect(formatAmount(12345678900, language: 'it'), '1.234.567,89');
      expect(formatAmount(12345678900, language: 'en'), '1,234,567.89');
      expect(amountToInput(125000), '12.5');
      expect(amountToInput(0), '');
    });

    test('0.1 + 0.2 style sums stay exact', () {
      expect(parseAmount('0.1')! + parseAmount('0.2')!, parseAmount('0.3'));
    });
  });

  group('balance invariant', () {
    test('a balanced entry is postable', () {
      final JournalEntry e = entry();
      expect(e.isBalanced, isTrue);
      expect(e.difference, 0);
      expect(e.problems, isEmpty);
      expect(e.isPostable, isTrue);
      e.requireValid();
    });

    test('an unbalanced entry reports the difference and cannot be queued', () {
      final JournalEntry e = entry(
        lines: const <JournalLine>[
          JournalLine(accountId: 'a-rent', debit: 3000000),
          JournalLine(accountId: 'a-bank', credit: 2999999),
        ],
      );
      expect(e.isBalanced, isFalse);
      expect(e.difference, 1);
      expect(e.problems, contains(JournalProblem.unbalanced));
      expect(e.requireValid, throwsA(isA<UnbalancedJournalException>()));
    });

    test('incomplete lines are reported one by one', () {
      final JournalEntry e = entry(
        description: ' ',
        lines: const <JournalLine>[
          JournalLine(accountId: '', debit: 100),
          JournalLine(accountId: 'a', debit: 100, credit: 100),
          JournalLine(accountId: 'b'),
        ],
      );
      expect(
        e.problems,
        containsAll(<JournalProblem>[
          JournalProblem.descriptionMissing,
          JournalProblem.lineWithoutAccount,
          JournalProblem.lineWithoutAmount,
          JournalProblem.lineOnBothSides,
        ]),
      );
    });

    test('a single line or an empty entry never balances', () {
      expect(entry(lines: const <JournalLine>[]).isBalanced, isFalse);
      expect(
        entry(lines: const <JournalLine>[JournalLine(accountId: 'a', debit: 5)])
            .problems,
        contains(JournalProblem.tooFewLines),
      );
    });
  });

  group('immutability', () {
    test('local drafts and refused entries can be edited', () {
      expect(entry().isEditable, isTrue);
      expect(entry(sync: JournalSyncState.rejected).isEditable, isTrue);
      expect(entry().edit(description: 'Rent March').description, 'Rent March');
    });

    test('queued, synced and posted entries refuse content edits', () {
      for (final JournalEntry e in <JournalEntry>[
        entry(sync: JournalSyncState.queued),
        entry(sync: JournalSyncState.synced, serverId: 's1'),
        entry(status: JournalStatus.posted, sync: JournalSyncState.synced),
        entry(status: JournalStatus.posted),
      ]) {
        expect(e.isEditable, isFalse);
        expect(
          () => e.edit(description: 'x'),
          throwsA(isA<ImmutableJournalException>()),
        );
      }
    });
  });

  group('storno', () {
    final JournalEntry posted = entry(
      status: JournalStatus.posted,
      sync: JournalSyncState.synced,
      serverId: 'srv-1',
    );

    test(
      'swaps Dare and Avere, points at the original and keeps the reason',
      () {
        final JournalEntry r = posted.reversal(
          newId: 'j2',
          reversalDate: '2026-04-01',
          reason: 'wrong period',
          now: DateTime.utc(2026, 4, 1),
        );
        expect(r.reversesJournalId, 'srv-1');
        expect(r.reversalReason, 'wrong period');
        expect(r.isReversal, isTrue);
        expect(r.postingDate, '2026-04-01');
        expect(r.lines[0].credit, 3000000);
        expect(r.lines[0].debit, 0);
        expect(r.lines[1].debit, 3000000);
        expect(r.isBalanced, isTrue);
        expect(r.syncState, JournalSyncState.localDraft);
        expect(r.status, JournalStatus.draft);
        expect(r.outboxPath, '/general-ledger/journals/srv-1/reverse');
        expect(r.outboxBody, <String, dynamic>{
          'reversal_date': '2026-04-01',
          'reason': 'wrong period',
        });
      },
    );

    test('only a synced, posted, not yet reversed journal can be reversed', () {
      JournalEntry reverse(JournalEntry e) => e.reversal(
        newId: 'x',
        reversalDate: '2026-04-01',
        reason: '',
        now: DateTime.utc(2026, 4, 1),
      );
      expect(() => reverse(entry()), throwsA(isA<NotReversibleException>()));
      expect(
        () => reverse(posted.copyWith(status: JournalStatus.reversed)),
        throwsA(isA<NotReversibleException>()),
      );
      expect(
        () => reverse(entry(status: JournalStatus.posted)),
        throwsA(isA<NotReversibleException>()),
      );
      final JournalEntry storno = reverse(posted);
      expect(
        () => reverse(
          storno.copyWith(serverId: 's2', status: JournalStatus.posted),
        ),
        throwsA(isA<NotReversibleException>()),
      );
    });
  });

  group('API contract', () {
    test('create body carries the ledger book, the extra books and the post intent', () {
      final JournalEntry e = entry().copyWith(
        ledger: LedgerBook.tax,
        alsoPostTo: <LedgerBook>[LedgerBook.statutory, LedgerBook.ifrs],
        postOnSync: true,
      );
      final Map<String, dynamic> body = e.toCreateBody();
      expect(body['ledger_type'], 'tax');
      expect(body['post_to_ledgers'], <String>['01', '03']);
      expect(body['status'], 'posted');
      expect(body['posting_date'], '2026-03-10');
      expect(body['lines'], <Map<String, dynamic>>[
        <String, dynamic>{
          'account_id': 'a-rent',
          'debit_amount': '300.0000',
          'credit_amount': '0.0000',
        },
        <String, dynamic>{
          'account_id': 'a-bank',
          'debit_amount': '0.0000',
          'credit_amount': '300.0000',
        },
      ]);
      expect(e.outboxPath, '/general-ledger/journals');
    });

    test('ledger books map codes and names', () {
      expect(LedgerBook.parse('02'), LedgerBook.tax);
      expect(LedgerBook.parse('ifrs'), LedgerBook.ifrs);
      expect(LedgerBook.parse('zzz'), LedgerBook.statutory);
    });

    test('trial balance parses the 2-column layout', () {
      final TrialBalance t = TrialBalance.fromJson(
        const <String, dynamic>{
          'currency': 'CHF',
          'accounts': <Map<String, dynamic>>[
            <String, dynamic>{
              'account_id': 'a',
              'account_code': '3000',
              'account_name': 'Capital',
              'debit_balance': '0.0000',
              'credit_balance': '1000.0000',
            },
          ],
          'totals': <String, dynamic>{
            'debit_balance': '1000.0000',
            'credit_balance': '1000.0000',
          },
          'is_balanced': true,
        },
        columns: 2,
        ledger: LedgerBook.statutory,
      );
      expect(t.rows.single.creditBalance, 10000000);
      expect(t.totalDebit, t.totalCredit);
      expect(t.isBalanced, isTrue);
    });
  });

  group('templates', () {
    final AccountingTemplate expense = AccountingTemplate.fromJson(
      const <String, dynamic>{
        'id': 'tpl',
        'code': 'EXPENSE_WITH_VAT',
        'names': <String, String>{
          'en': 'Expense with VAT',
          'it': 'Costo con IVA',
        },
        'ledger_type': 'statutory',
        'parameters': <Map<String, String>>[
          <String, String>{'key': 'amount', 'type': 'amount'},
          <String, String>{'key': 'tax_rate', 'type': 'rate'},
          <String, String>{'key': 'expense', 'type': 'account'},
          <String, String>{'key': 'input_vat', 'type': 'account'},
          <String, String>{'key': 'payable', 'type': 'account'},
        ],
        'lines': <Map<String, String>>[
          <String, String>{
            'account': r'$expense',
            'side': 'debit',
            'amount': 'amount',
          },
          <String, String>{
            'account': r'$input_vat',
            'side': 'debit',
            'amount': 'tax',
          },
          <String, String>{
            'account': r'$payable',
            'side': 'credit',
            'amount': 'gross',
          },
        ],
      },
    );
    const GlAccount a1 = GlAccount(id: 'e', code: '6000', name: 'Expense');
    const GlAccount a2 = GlAccount(id: 'v', code: '1170', name: 'Input VAT');
    const GlAccount a3 = GlAccount(id: 'p', code: '2000', name: 'Payable');

    test(
      'hydration matches the server preview (100.00 at 8.1% gives 108.10)',
      () {
        final TemplateHydration h = expense.hydrate(
          amount: parseAmount('100.00')!,
          taxRate: parseAmount('8.1')!,
          chosen: <String, GlAccount>{
            'expense': a1,
            'input_vat': a2,
            'payable': a3,
          },
          known: const <GlAccount>[],
        );
        expect(h.lines, hasLength(3));
        expect(h.totalDebit, parseAmount('108.10'));
        expect(h.totalCredit, parseAmount('108.10'));
        expect(h.isBalanced, isTrue);
        expect(h.lines[2].credit, parseAmount('108.10'));
        expect(expense.label('it'), 'Costo con IVA');
        expect(expense.label('fr'), 'Expense with VAT');
        expect(expense.needsRate, isTrue);
        expect(expense.accountKeys, <String>[
          'expense',
          'input_vat',
          'payable',
        ]);
      },
    );

    test('a missing account is reported and the template is not balanced', () {
      final TemplateHydration h = expense.hydrate(
        amount: parseAmount('100')!,
        taxRate: parseAmount('8.1')!,
        chosen: <String, GlAccount>{'expense': a1},
        known: const <GlAccount>[],
      );
      expect(
        h.missingAccountKeys,
        containsAll(<String>['input_vat', 'payable']),
      );
      expect(h.isBalanced, isFalse);
    });

    test('a zero tax rate leaves the tax line out', () {
      final TemplateHydration h = expense.hydrate(
        amount: parseAmount('50')!,
        chosen: <String, GlAccount>{
          'expense': a1,
          'input_vat': a2,
          'payable': a3,
        },
        known: const <GlAccount>[],
      );
      expect(h.lines, hasLength(2));
      expect(h.isBalanced, isTrue);
    });
  });

  test('every locale defines every label', () {
    for (final MapEntry<String, Map<GL, String>> table
        in glLocaleTables.entries) {
      for (final GL key in GL.values) {
        expect(table.value[key], isNotNull, reason: '${table.key} lacks $key');
        expect(table.value[key], isNotEmpty, reason: '${table.key} empty $key');
      }
    }
    expect(glLocaleTables.keys, containsAll(<String>['it', 'de', 'fr', 'en']));
    expect(const GlStrings('xx')(GL.debit), 'Debit');
    expect(const GlStrings('it')(GL.debit), 'Dare');
  });
}
