import 'dart:async';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:fattura_facile/app/providers.dart';
import 'package:fattura_facile/core/database/app_database.dart';
import 'package:fattura_facile/core/localization/translation_service.dart';
import 'package:fattura_facile/design/ff_tokens.dart';
import 'package:fattura_facile/features/general_ledger/domain/gl_models.dart';
import 'package:fattura_facile/features/general_ledger/domain/gl_repository.dart';
import 'package:fattura_facile/features/general_ledger/presentation/gl_controller.dart';
import 'package:fattura_facile/features/general_ledger/presentation/gl_pages.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class FakeGlRepository implements GlRepository {
  List<GlAccount> accounts = const <GlAccount>[
    GlAccount(id: 'a-bank', code: '1000', name: 'Bank'),
    GlAccount(
      id: 'a-cap',
      code: '3000',
      name: 'Capital',
      normalBalance: 'credit',
    ),
  ];
  final List<JournalEntry> submitted = <JournalEntry>[];
  final List<JournalEntry> drafts = <JournalEntry>[];
  final StreamController<List<JournalEntry>> journals =
      StreamController<List<JournalEntry>>.broadcast();
  List<JournalEntry> current = <JournalEntry>[];
  TrialBalance? trial;

  @override
  Stream<List<JournalEntry>> watchJournals(String tenantId) async* {
    yield current;
    yield* journals.stream;
  }

  @override
  Future<void> refreshJournals(String tenantId) async {}

  @override
  Future<List<GlAccount>> cachedAccounts(String tenantId) async => accounts;

  @override
  Future<List<GlAccount>> refreshAccounts(String tenantId) async => accounts;

  @override
  Future<List<AccountingTemplate>> cachedTemplates(String tenantId) async =>
      const <AccountingTemplate>[];

  @override
  Future<List<AccountingTemplate>> refreshTemplates(String tenantId) async =>
      const <AccountingTemplate>[];

  @override
  Future<void> saveDraft(JournalEntry entry) async {
    entry.requireValid();
    drafts.add(entry);
  }

  @override
  Future<SubmitOutcome> submit(JournalEntry entry, {bool post = true}) async {
    entry.requireValid();
    submitted.add(entry);
    return const SubmitOutcome(SubmitStatus.queued);
  }

  @override
  Future<SubmitOutcome> reverse(
    JournalEntry original, {
    required String reversalDate,
    required String reason,
  }) async => const SubmitOutcome(SubmitStatus.queued);

  @override
  Future<void> discard(String tenantId, String id) async {}

  @override
  Future<void> syncPending(String tenantId) async {}

  @override
  Future<TrialBalance?> cachedTrialBalance(
    String tenantId, {
    required String from,
    required String to,
    required LedgerBook ledger,
    required int columns,
  }) async => null;

  @override
  Future<TrialBalance> refreshTrialBalance(
    String tenantId, {
    required String from,
    required String to,
    required LedgerBook ledger,
    required int columns,
  }) async =>
      trial ??
      TrialBalance(
        currency: 'CHF',
        columns: columns,
        ledger: ledger,
        rows: const <TrialBalanceRow>[],
        totals: const <String, int>{},
        isBalanced: true,
      );

  @override
  Future<AccountLedger?> cachedAccountLedger(
    String tenantId, {
    required String accountId,
    required String from,
    required String to,
    required LedgerBook ledger,
  }) async => null;

  @override
  Future<AccountLedger> refreshAccountLedger(
    String tenantId, {
    required String accountId,
    required String from,
    required String to,
    required LedgerBook ledger,
  }) async => AccountLedger(
    accountId: accountId,
    ledger: ledger,
    opening: 0,
    closing: 0,
    lines: const <AccountLedgerLine>[],
  );
}

void main() {
  late AppDatabase db;
  late FakeGlRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = FakeGlRepository();
  });

  tearDown(() async {
    await repo.journals.close();
    await db.close();
  });

  Widget host(Widget child) => ProviderScope(
    key: UniqueKey(),
    overrides: [
      glRepositoryProvider.overrideWithValue(repo),
      glTenantIdProvider.overrideWithValue('t1'),
      translationProvider.overrideWithValue(TranslationService(db, Dio())),
    ],
    child: MaterialApp(theme: ffThemeData(), home: child),
  );

  testWidgets(
    'posting is blocked until Dare and Avere match, and the difference is live',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(900, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(host(const GlHomePage()));
      await tester.pumpAndSettle();

      FilledButton post() =>
          tester.widget<FilledButton>(find.byKey(const Key('gl-post')));
      expect(post().onPressed, isNull);

      final ProviderContainer container = ProviderScope.containerOf(
        tester.element(find.byType(GlHomePage)),
      );
      final GlFormController form = container.read(glFormProvider.notifier);
      final List<FormLine> lines = container.read(glFormProvider).lines;
      form.setDescription('Capital');
      form.updateLine(lines[0].uid, account: repo.accounts[0], debit: 1000000);
      form.updateLine(lines[1].uid, account: repo.accounts[1], credit: 900000);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('gl-difference')), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('gl-difference'))).data,
        '10.00',
      );
      expect(post().onPressed, isNull);
      expect(
        tester
            .widget<OutlinedButton>(find.byKey(const Key('gl-save-draft')))
            .onPressed,
        isNull,
      );

      form.updateLine(lines[1].uid, credit: 1000000);
      await tester.pumpAndSettle();

      expect(
        tester.widget<Text>(find.byKey(const Key('gl-difference'))).data,
        '0.00',
      );
      expect(post().onPressed, isNotNull);

      await tester.tap(find.byKey(const Key('gl-post')));
      await tester.pumpAndSettle();
      expect(repo.submitted, hasLength(1));
      expect(repo.submitted.single.isBalanced, isTrue);
      // The form is cleared after a queued post.
      expect(container.read(glFormProvider).totalDebit, 0);
    },
  );

  testWidgets('typing amounts updates the totals', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(host(const GlHomePage()));
    await tester.pumpAndSettle();

    final ProviderContainer container = ProviderScope.containerOf(
      tester.element(find.byType(GlHomePage)),
    );
    final List<FormLine> lines = container.read(glFormProvider).lines;
    await tester.enterText(
      find.byKey(Key('gl-debit-${lines[0].uid}-0')),
      '25,5',
    );
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(const Key('gl-total-debit'))).data,
      '25.50',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('gl-difference'))).data,
      '25.50',
    );
  });

  testWidgets(
    'the journal list offers storno only for synced posted entries and drafts can be discarded',
    (WidgetTester tester) async {
      final JournalEntry posted = JournalEntry(
        id: 'p1',
        serverId: 'p1',
        tenantId: 't1',
        postingDate: '2026-03-10',
        description: 'Posted',
        status: JournalStatus.posted,
        syncState: JournalSyncState.synced,
        createdAt: DateTime.utc(2026, 3, 10),
        lines: const <JournalLine>[
          JournalLine(accountId: 'a', debit: 1000000),
          JournalLine(accountId: 'b', credit: 1000000),
        ],
      );
      final JournalEntry local = JournalEntry(
        id: 'l1',
        tenantId: 't1',
        postingDate: '2026-03-11',
        description: 'Local',
        createdAt: DateTime.utc(2026, 3, 11),
        lines: posted.lines,
      );
      repo.current = <JournalEntry>[local, posted];
      await tester.pumpWidget(host(const JournalsTab()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('gl-reverse-p1')), findsOneWidget);
      expect(find.byKey(const Key('gl-discard-p1')), findsNothing);
      expect(find.byKey(const Key('gl-reverse-l1')), findsNothing);
      expect(find.byKey(const Key('gl-discard-l1')), findsOneWidget);
    },
  );

  testWidgets(
    'the trial balance shows 4 columns by default and the ledger book filter',
    (WidgetTester tester) async {
      repo.trial = const TrialBalance(
        currency: 'CHF',
        columns: 4,
        ledger: LedgerBook.statutory,
        rows: <TrialBalanceRow>[
          TrialBalanceRow(
            accountId: 'a',
            code: '1000',
            name: 'Bank',
            opening: 0,
            debit: 4000000,
            credit: 0,
            closing: 4000000,
          ),
        ],
        totals: <String, int>{'debit': 4000000, 'credit': 4000000},
        isBalanced: true,
      );
      await tester.pumpWidget(host(const TrialBalanceTab()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('gl-trial-row-1000')), findsOneWidget);
      expect(find.text('Closing balance'), findsOneWidget);
      expect(find.byKey(const Key('gl-trial-book-02')), findsOneWidget);
      expect(find.byKey(const Key('gl-trial-balanced')), findsOneWidget);
      expect(find.byType(SegmentedButton<int>), findsOneWidget);
      expect(find.text('400.00'), findsWidgets);
    },
  );
}
