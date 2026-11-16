import 'package:fattura_facile/features/wms/state/dispatch_state.dart';
import 'package:fattura_facile/features/wms/ui/dispatch_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support.dart';

void main() {
  late FakeWmsRepository repo;

  Future<void> pump(WidgetTester tester) async {
    useTallScreen(tester);
    repo = FakeWmsRepository()..codes = {'111': 'l1', 'SKU-2': 'l2'};
    final controller = DispatchController(repository: repo, transfer: buildTransfer(status: 'approved'));
    await tester.pumpWidget(testApp(DispatchScreen(controller: controller)));
    await tester.pumpAndSettle();
  }

  Future<void> scan(WidgetTester tester, String code) async {
    await tester.enterText(find.byKey(const Key('scan-input')), code);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
  }

  FilledButton confirm(WidgetTester tester) => tester.widget<FilledButton>(find.byKey(const Key('dispatch-confirm')));

  testWidgets('dispatch confirmation is enabled only once all lines are scanned', (tester) async {
    await pump(tester);
    expect(find.text('0 of 2 lines scanned'), findsOneWidget);
    expect(confirm(tester).onPressed, isNull);

    await scan(tester, '111');
    expect(find.text('1 of 2 lines scanned'), findsOneWidget);
    expect(find.text('Matched: Widget'), findsOneWidget);
    expect(confirm(tester).onPressed, isNull);

    await scan(tester, 'SKU-2');
    expect(find.text('2 of 2 lines scanned'), findsOneWidget);
    expect(confirm(tester).onPressed, isNotNull);
  });

  testWidgets('confirming posts the optional carrier data and shows the result', (tester) async {
    await pump(tester);
    await scan(tester, '111');
    await scan(tester, 'SKU-2');
    await tester.enterText(find.byKey(const Key('carrier-input')), 'DHL');
    await tester.enterText(find.byKey(const Key('packages-input')), '3');
    await tester.enterText(find.byKey(const Key('weight-input')), '12,5');

    await tester.ensureVisible(find.byKey(const Key('dispatch-confirm')));
    await tester.tap(find.byKey(const Key('dispatch-confirm')));
    await tester.pumpAndSettle();

    expect(repo.lastShipment!.carrierName, 'DHL');
    expect(repo.lastShipment!.packagesCount, 3);
    expect(repo.lastShipment!.grossWeightKg, 12.5);
    expect(find.text('Dispatch confirmed. Status: In transit'), findsOneWidget);
  });

  testWidgets('an unknown code shows the API error and leaves the checklist alone', (tester) async {
    await pump(tester);
    await scan(tester, 'nope');
    expect(find.text('Line not in transfer'), findsOneWidget);
    expect(find.text('0 of 2 lines scanned'), findsOneWidget);
  });
}
