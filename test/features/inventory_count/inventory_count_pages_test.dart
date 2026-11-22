import 'package:dio/dio.dart';
import 'package:fattura_facile/app/providers.dart';
import 'package:fattura_facile/core/localization/translation_service.dart';
import 'package:fattura_facile/design/ff_tokens.dart';
import 'package:fattura_facile/features/inventory_count/domain/inventory_count_models.dart';
import 'package:fattura_facile/features/inventory_count/presentation/inventory_count_controller.dart';
import 'package:fattura_facile/features/inventory_count/presentation/inventory_count_pages.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support.dart';

void main() {
  late CountFixture f;
  late TranslationService t;
  String? scanned;

  setUp(() async {
    f = CountFixture();
    t = await f.translations();
    scanned = null;
    f.route(
      sessions: <Map<String, dynamic>>[sessionJson('s1')],
      sheet: <Map<String, dynamic>>[
        lineJson('l1', sku: 'SKU-1', name: 'Widget'),
        lineJson(
          'l2',
          sku: 'SKU-2',
          name: 'Gadget',
          counted: true,
          quantity: 3,
        ),
        lineJson('l3', sku: 'SKU-3', name: 'Gizmo', recount: true, round: 2),
      ],
      record: CountFixture.answer('recorded'),
    );
  });

  tearDown(() => f.dispose());

  Widget host(Widget child) => ProviderScope(
    key: UniqueKey(),
    overrides: [
      databaseProvider.overrideWithValue(f.db),
      dioProvider.overrideWithValue(f.dio),
      translationProvider.overrideWithValue(t),
      inventoryCountTenantProvider.overrideWithValue(tenant),
      inventoryCountCameraScannerProvider.overrideWithValue(
        (BuildContext context) async => scanned,
      ),
    ],
    child: MaterialApp(theme: ffThemeData(), home: child),
  );

  CountSession session() => CountSession.fromJson(sessionJson('s1'));

  testWidgets(
    'my counts lists the assigned session with the frozen badge and progress',
    (WidgetTester tester) async {
      await tester.pumpWidget(host(const InventoryCountListPage()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('count-session-s1')), findsOneWidget);
      expect(find.text('INV-s1'), findsOneWidget);
      expect(find.textContaining('Main warehouse'), findsOneWidget);
      expect(find.byKey(const Key('count-frozen-s1')), findsOneWidget);
      expect(find.byKey(const Key('count-progress-s1')), findsOneWidget);
    },
  );

  testWidgets('my counts shows the empty state', (WidgetTester tester) async {
    f.route(sessions: <Map<String, dynamic>>[]);
    await tester.pumpWidget(host(const InventoryCountListPage()));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('count-empty')), findsOneWidget);
  });

  testWidgets(
    'the sheet is blind: notice shown, no system quantity, recount hint without previous value',
    (WidgetTester tester) async {
      await tester.pumpWidget(host(CountSheetPage(session: session())));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('count-blind-notice')), findsOneWidget);
      expect(
        find.text('Blind count: the system stock is not shown'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('count-line-l1')), findsOneWidget);
      // Counted lines are hidden by the default "to count" filter.
      expect(find.byKey(const Key('count-line-l2')), findsNothing);
      expect(find.byKey(const Key('count-recount-l3')), findsOneWidget);
      expect(find.byKey(const Key('count-recount-hint-l3')), findsOneWidget);
      expect(find.byKey(const Key('count-first-l3')), findsNothing);
      expect(find.textContaining('Round 2'), findsOneWidget);
    },
  );

  testWidgets('the counted filter shows the own quantity', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(host(CountSheetPage(session: session())));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Counted'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('count-line-l2')), findsOneWidget);
    expect(find.byKey(const Key('count-qty-l2')), findsOneWidget);
    expect(find.byKey(const Key('count-line-l1')), findsNothing);
  });

  testWidgets('searching narrows the list', (WidgetTester tester) async {
    await tester.pumpWidget(host(CountSheetPage(session: session())));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('count-search')), 'sku-3');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('count-line-l3')), findsOneWidget);
    expect(find.byKey(const Key('count-line-l1')), findsNothing);
  });

  testWidgets('the camera scan opens the quantity entry of the matching line', (
    WidgetTester tester,
  ) async {
    scanned = 'EAN-l1';
    await tester.pumpWidget(host(CountSheetPage(session: session())));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('count-camera')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('count-qty')), findsOneWidget);
    expect(find.text('Counted quantity'), findsOneWidget);
  });

  testWidgets(
    'entering a quantity offline queues it and shows the pending counter and badge',
    (WidgetTester tester) async {
      await tester.pumpWidget(host(CountSheetPage(session: session())));
      await tester.pumpAndSettle();
      f.adapter.handler = (RequestOptions o) => throw DioException(
        requestOptions: o,
        type: DioExceptionType.connectionError,
      );

      await tester.tap(find.byKey(const Key('count-line-l1')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('count-qty')), '12,5');
      await tester.enterText(
        find.byKey(const Key('count-notes')),
        'two pallets',
      );
      await tester.tap(find.byKey(const Key('count-save')));
      await tester.pumpAndSettle();

      expect(find.text('Saved on the device: it will sync'), findsOneWidget);
      expect(find.byKey(const Key('count-pending-l1')), findsOneWidget);
      expect(find.text('1 counts to sync'), findsOneWidget);
      expect(find.byKey(const Key('count-sync-now')), findsOneWidget);
      expect(await f.repo.pendingCount(tenant), 1);
    },
  );

  testWidgets('an invalid quantity is refused without saving', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(host(CountSheetPage(session: session())));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('count-line-l1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('count-save')));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid quantity'), findsOneWidget);
    expect(await f.repo.pendingCount(tenant), 0);
  });

  testWidgets('sync now sends the pending entry and the counter disappears', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(host(CountSheetPage(session: session())));
    await tester.pumpAndSettle();
    await f.repo.recordCount(
      tenant,
      sessionId: 's1',
      lineId: 'l1',
      quantity: 4,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('count-pending-bar')), findsOneWidget);

    await tester.tap(find.byKey(const Key('count-sync-now')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('count-pending-bar')), findsNothing);
    expect(await f.repo.pendingCount(tenant), 0);
  });

  testWidgets('a line refused by the server is surfaced and can be dismissed', (
    WidgetTester tester,
  ) async {
    f.route(
      sessions: <Map<String, dynamic>>[sessionJson('s1')],
      sheet: <Map<String, dynamic>>[lineJson('l1')],
      record: CountFixture.answer('rejected'),
    );
    await tester.pumpWidget(host(CountSheetPage(session: session())));
    await tester.pumpAndSettle();
    await f.repo.recordCount(
      tenant,
      sessionId: 's1',
      lineId: 'l1',
      quantity: 4,
    );

    await tester.tap(find.byKey(const Key('count-sync-now')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('count-rejected-l1')), findsOneWidget);
    expect(find.textContaining('the server value stands'), findsOneWidget);

    await tester.tap(find.byKey(const Key('count-dismiss-l1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('count-rejected-l1')), findsNothing);
  });
}
