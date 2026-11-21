import 'package:drift/drift.dart' show Value;
import 'package:fattura_facile/app/providers.dart';
import 'package:fattura_facile/core/database/app_database.dart';
import 'package:fattura_facile/features/shop_floor/data/local/shop_floor_tables.dart';
import 'package:fattura_facile/features/shop_floor/data/shop_floor_outbox.dart';
import 'package:fattura_facile/features/shop_floor/data/shop_floor_sync_worker.dart';
import 'package:fattura_facile/features/shop_floor/presentation/operation_terminal_page.dart';
import 'package:fattura_facile/features/shop_floor/presentation/order_page.dart';
import 'package:fattura_facile/features/shop_floor/presentation/qc_checklist_page.dart';
import 'package:fattura_facile/features/shop_floor/presentation/shop_floor_home_page.dart';
import 'package:fattura_facile/features/shop_floor/presentation/shop_floor_providers.dart';
import 'package:fattura_facile/l10n/gen/app_localizations.dart';
import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support.dart';

/// The five locales of the product.
const List<Locale> locales = <Locale>[
  Locale('it', 'CH'),
  Locale('de', 'CH'),
  Locale('fr', 'CH'),
  Locale('en'),
  Locale('it', 'IT'),
];

Future<void> settle(WidgetTester t) async {
  await t.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 80)),
  );
  await t.pump();
  await t.pump(const Duration(milliseconds: 400));
}

Future<void> tapKey(WidgetTester t, String key) async {
  final Finder f = find.byKey(Key(key));
  await t.ensureVisible(f);
  await t.tap(f);
  await settle(t);
}

Widget app(
  Harness h,
  Widget home, {
  Locale locale = const Locale('en'),
  String? scanned,
}) {
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(h.db),
      shopFloorOutboxProvider.overrideWithValue(h.outbox),
      shopFloorRepositoryProvider.overrideWithValue(h.repo),
      shopFloorCameraScannerProvider.overrideWithValue(
        (BuildContext c) async => scanned,
      ),
      shopFloorSyncProvider.overrideWith((Ref ref) {
        final ShopFloorSyncCoordinator c = ShopFloorSyncCoordinator(
          runner: (String t) async => const OutboxFlushReport(),
          onCycleDone: (String t, OutboxFlushReport r) async {},
          interval: const Duration(days: 1),
        );
        ref.onDispose(c.stop);
        return c;
      }),
    ],
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    ),
  );
}

void main() {
  late Harness h;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    h = Harness();
    await h.seed();
  });

  tearDown(() => h.close());

  void tall(WidgetTester t) {
    t.view.physicalSize = const Size(900, 3000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
  }

  Future<void> unmount(WidgetTester t) async {
    await t.pumpWidget(const SizedBox.shrink());
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await t.pump(const Duration(seconds: 1));
  }

  group('localization rendering', () {
    test('the app locale list contains the five product locales', () {
      for (final Locale l in locales) {
        expect(AppLocalizations.supportedLocales, contains(l), reason: '$l');
      }
    });

    testWidgets(
      'the order list renders translated text in it-CH, de-CH, fr-CH, en and it-IT',
      (WidgetTester tester) async {
        tall(tester);
        final Map<Locale, (String title, String status, String progress)>
        expected = <Locale, (String, String, String)>{
          const Locale('it', 'CH'): (
            'Produzione',
            'Rilasciato',
            '10 di 100 pcs',
          ),
          const Locale('de', 'CH'): (
            'Fertigung',
            'Freigegeben',
            '10 von 100 pcs',
          ),
          const Locale('fr', 'CH'): ('Atelier', 'Lancé', '10 sur 100 pcs'),
          const Locale('en'): ('Shop floor', 'Released', '10 of 100 pcs'),
          const Locale('it', 'IT'): (
            'Produzione',
            'Rilasciato',
            '10 di 100 pcs',
          ),
        };
        for (final Locale locale in locales) {
          await tester.pumpWidget(
            app(h, const ShopFloorHomePage(tenantId: tenant), locale: locale),
          );
          await settle(tester);
          final (String title, String status, String progress) =
              expected[locale]!;
          expect(find.text(title), findsOneWidget, reason: '$locale title');
          expect(find.text('PO-0001'), findsOneWidget);
          expect(find.text(status), findsOneWidget, reason: '$locale status');
          expect(
            find.text(progress),
            findsOneWidget,
            reason: '$locale progress',
          );
          await unmount(tester);
        }
      },
    );

    testWidgets(
      'the operator terminal renders in every locale with no raw keys and the Swiss spelling in de-CH',
      (WidgetTester tester) async {
        tall(tester);
        final Map<Locale, (String good, String scrap, String confirm)>
        expected = <Locale, (String, String, String)>{
          const Locale('it', 'CH'): ('Buoni', 'Scarti', 'Conferma operazione'),
          const Locale('de', 'CH'): (
            'Gutteile',
            'Ausschuss',
            'Arbeitsgang rückmelden',
          ),
          const Locale('fr', 'CH'): ('Bons', 'Rebuts', "Confirmer l'opération"),
          const Locale('en'): ('Good', 'Scrap', 'Confirm operation'),
          const Locale('it', 'IT'): ('Buoni', 'Scarti', 'Conferma operazione'),
        };
        for (final Locale locale in locales) {
          await tester.pumpWidget(
            app(
              h,
              const OperationTerminalPage(
                tenantId: tenant,
                orderId: orderId,
                operationId: opId,
              ),
              locale: locale,
            ),
          );
          await settle(tester);
          final (String good, String scrap, String confirm) = expected[locale]!;
          expect(find.text(good), findsOneWidget, reason: '$locale');
          expect(find.text(scrap), findsOneWidget, reason: '$locale');
          expect(find.text(confirm), findsOneWidget, reason: '$locale');
          expect(
            find.textContaining('mfg'),
            findsNothing,
            reason: '$locale shows no raw key',
          );
          await unmount(tester);
        }
        final AppLocalizations de = await AppLocalizations.delegate.load(
          const Locale('de'),
        );
        final AppLocalizations deCh = await AppLocalizations.delegate.load(
          const Locale('de', 'CH'),
        );
        expect(de.mfgErrQuantity, contains('größer'));
        expect(deCh.mfgErrQuantity, contains('grösser'));
      },
    );

    test(
      'every language has every shop-floor string, with placeholders filled',
      () async {
        for (final Locale l in locales) {
          final AppLocalizations s = await AppLocalizations.delegate.load(l);
          for (final String text in <String>[
            s.mfgTitle,
            s.mfgScanPrompt,
            s.mfgStartSetup,
            s.mfgStartRun,
            s.mfgPause,
            s.mfgResume,
            s.mfgGood,
            s.mfgScrap,
            s.mfgBackflush,
            s.mfgCheckIn,
            s.mfgQcSignOff,
            s.mfgQueueTitle,
            s.mfgKindConfirm,
            s.mfgErrScrapReason,
          ]) {
            expect(text.trim(), isNotEmpty, reason: '$l');
          }
          expect(s.mfgScanUnknown('X-1'), contains('X-1'), reason: '$l');
          expect(s.mfgSyncPending(3), contains('3'), reason: '$l');
          expect(
            s.mfgQcTolerance('9', '11'),
            allOf(contains('9'), contains('11')),
            reason: '$l',
          );
        }
      },
    );
  });

  group('operator terminal', () {
    testWidgets(
      'start run, count good and scrap, confirm: the posting lands in the offline queue',
      (WidgetTester tester) async {
        tall(tester);
        await tester.pumpWidget(
          app(
            h,
            const OperationTerminalPage(
              tenantId: tenant,
              orderId: orderId,
              operationId: opId,
            ),
          ),
        );
        await settle(tester);

        await tapKey(tester, 'mfg-start-run');
        expect(find.text('Running'), findsOneWidget);
        await tapKey(tester, 'mfg-good-p10');
        await tapKey(tester, 'mfg-good-p1');
        await tapKey(tester, 'mfg-scrap-p1');
        expect(find.text('11'), findsOneWidget);

        // Scrap needs a reason: refused, nothing queued.
        await tapKey(tester, 'mfg-confirm');
        expect(find.text('Enter a reason for the scrap.'), findsOneWidget);
        expect(await tester.runAsync(() => h.outbox.all(tenant)), isEmpty);

        await tester.enterText(
          find.byKey(const Key('mfg-scrap-reason')),
          'burr',
        );
        await tapKey(tester, 'mfg-confirm');
        final List<MfgOutboxRow> rows = (await tester.runAsync(
          () => h.outbox.all(tenant),
        ))!;
        expect(rows, hasLength(1));
        expect(rows.single.kind, OutboxKind.confirm);
        expect(
          rows.single.payload,
          allOf(
            contains('"good_quantity":"11.0000"'),
            contains('"scrap_quantity":"1.0000"'),
            contains('"scrap_reason":"burr"'),
          ),
        );
        expect(
          find.text('Saved. It will be sent as soon as you are online.'),
          findsOneWidget,
        );
        await unmount(tester);
      },
    );

    testWidgets(
      'pause switches to resume and the screen shows the paused phase',
      (WidgetTester tester) async {
        tall(tester);
        await tester.pumpWidget(
          app(
            h,
            const OperationTerminalPage(
              tenantId: tenant,
              orderId: orderId,
              operationId: opId,
            ),
          ),
        );
        await settle(tester);
        await tapKey(tester, 'mfg-start-setup');
        expect(find.text('Setup in progress'), findsOneWidget);
        await tapKey(tester, 'mfg-pause');
        expect(find.text('Paused'), findsOneWidget);
        expect(find.byKey(const Key('mfg-resume')), findsOneWidget);
        await tapKey(tester, 'mfg-resume');
        expect(find.text('Setup in progress'), findsOneWidget);
        await unmount(tester);
      },
    );

    testWidgets(
      'operator buttons are at least 64 logical pixels tall (glove friendly)',
      (WidgetTester tester) async {
        tall(tester);
        await tester.pumpWidget(
          app(
            h,
            const OperationTerminalPage(
              tenantId: tenant,
              orderId: orderId,
              operationId: opId,
            ),
          ),
        );
        await settle(tester);
        for (final String k in <String>[
          'mfg-start-setup',
          'mfg-start-run',
          'mfg-good-p1',
          'mfg-confirm',
        ]) {
          await tester.ensureVisible(find.byKey(Key(k)));
          expect(
            tester.getSize(find.byKey(Key(k))).height,
            greaterThanOrEqualTo(64),
            reason: k,
          );
        }
        await unmount(tester);
      },
    );
  });

  group('scanner flows', () {
    testWidgets(
      'typing a bare order number on the home screen opens the order; an unknown code is refused',
      (WidgetTester tester) async {
        tall(tester);
        await tester.pumpWidget(
          app(h, const ShopFloorHomePage(tenantId: tenant)),
        );
        await settle(tester);

        await tester.enterText(find.byType(TextField), 'nothing');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await settle(tester);
        expect(find.text('Code not recognised: nothing'), findsOneWidget);

        await tester.enterText(find.byType(TextField), 'po-0001');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await settle(tester);
        await tester.pumpAndSettle(const Duration(milliseconds: 100));
        expect(
          find.text('Operations'),
          findsOneWidget,
          reason: 'order page is open',
        );
        await unmount(tester);
      },
    );

    testWidgets(
      'camera scan of a lot label stages it, backflush queues the issue',
      (WidgetTester tester) async {
        tall(tester);
        await tester.pumpWidget(
          app(
            h,
            const OrderPage(tenantId: tenant, orderId: orderId),
            scanned: '(01)09506000134352(10)LOT-9(30)4',
          ),
        );
        await settle(tester);

        await tapKey(tester, 'mfg-camera');
        await settle(tester);
        expect(
          find.text('Which material does lot LOT-9 belong to?'),
          findsOneWidget,
        );
        await tapKey(tester, 'mfg-stage-confirm');
        expect(find.text('Lot LOT-9 staged'), findsOneWidget);

        await tester.tap(find.text('Materials'));
        await tester.pumpAndSettle(const Duration(milliseconds: 100));
        await settle(tester);
        expect(find.byKey(const Key('mfg-staged-LOT-9')), findsOneWidget);
        await tapKey(tester, 'mfg-backflush');
        final List<MfgOutboxRow> rows = (await tester.runAsync(
          () => h.outbox.all(tenant),
        ))!;
        expect(rows.single.kind, OutboxKind.issue);
        expect(
          rows.single.payload,
          allOf(contains(lineA), contains('"quantity":"4.0000"')),
        );
        expect(find.text('1 issues queued'), findsOneWidget);
        await unmount(tester);
      },
    );

    testWidgets('scanning a machine plate checks the operator in', (
      WidgetTester tester,
    ) async {
      tall(tester);
      await tester.pumpWidget(
        app(
          h,
          const OrderPage(tenantId: tenant, orderId: orderId),
          scanned: 'FF:WC:WC-10',
        ),
      );
      await settle(tester);
      await tapKey(tester, 'mfg-camera');
      await settle(tester);
      final List<MfgOutboxRow> rows = (await tester.runAsync(
        () => h.outbox.all(tenant),
      ))!;
      expect(rows.single.kind, OutboxKind.checkIn);
      expect(find.text('Checked in: Press 10'), findsOneWidget);
      await unmount(tester);
    });
  });

  group('QC checklist', () {
    testWidgets(
      'judges each measurement against its tolerance and signs the inspection off into the queue',
      (WidgetTester tester) async {
        tall(tester);
        final order = (await tester.runAsync(() => h.repo.orders(tenant)))!
            .single;
        await tester.pumpWidget(
          app(
            h,
            QcChecklistPage(
              tenantId: tenant,
              order: order,
              operation: order.operations.single,
            ),
          ),
        );
        await settle(tester);

        await tester.enterText(find.byKey(const Key('mfg-qc-$charId')), '10.5');
        await tester.pump();
        expect(find.text('Out of tolerance'), findsOneWidget);
        await tester.enterText(find.byKey(const Key('mfg-qc-$charId')), '10.0');
        await tester.pump();
        expect(find.text('In tolerance'), findsOneWidget);

        await tapKey(tester, 'mfg-qc-signoff');
        final List<MfgOutboxRow> rows = (await tester.runAsync(
          () => h.outbox.all(tenant),
        ))!;
        expect(rows.single.kind, OutboxKind.inspection);
        expect(rows.single.payload, contains('"defect_count":0'));
        await unmount(tester);
      },
    );
  });

  group('send queue', () {
    testWidgets('lists refused postings and lets the supervisor retry them', (
      WidgetTester tester,
    ) async {
      tall(tester);
      await tester.runAsync(() async {
        final String key = await h.outbox.enqueue(
          tenantId: tenant,
          kind: OutboxKind.confirm,
          orderId: orderId,
          path: '/x',
          payload: <String, dynamic>{},
        );
        await (h.db.update(
          h.db.mfgOutbox,
        )..where((t) => t.uuid.equals(key))).write(
          const MfgOutboxCompanion(
            state: Value(OutboxState.rejected),
            lastError: Value('invalid'),
          ),
        );
      });
      await tester.pumpWidget(app(h, const SendQueuePage(tenantId: tenant)));
      await settle(tester);
      expect(find.text('Operation confirmation'), findsOneWidget);
      expect(find.textContaining('Refused by the server'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await settle(tester);
      expect(
        (await tester.runAsync(() => h.outbox.all(tenant)))!.single.state,
        OutboxState.pending,
      );
      await unmount(tester);
    });
  });
}
