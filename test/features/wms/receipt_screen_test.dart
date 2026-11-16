import 'package:fattura_facile/features/wms/state/receipt_state.dart';
import 'package:fattura_facile/features/wms/ui/receipt_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support.dart';

void main() {
  late FakeWmsRepository repo;
  late ReceiptController controller;

  Future<void> pump(WidgetTester tester, {Locale locale = const Locale('en')}) async {
    useTallScreen(tester);
    repo = FakeWmsRepository()..codes = {'111': 'l1', 'SKU-2': 'l2'};
    controller = ReceiptController(repository: repo, transfer: buildTransfer());
    await tester.pumpWidget(testApp(ReceiptScreen(controller: controller), locale: locale));
    await tester.pumpAndSettle();
  }

  Future<void> scan(WidgetTester tester, String code) async {
    await tester.enterText(find.byKey(const Key('scan-input')), code);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
  }

  FilledButton confirmButton(WidgetTester tester) => tester.widget<FilledButton>(find.byKey(const Key('receipt-confirm')));

  testWidgets('quantities are locked until the line is scanned and confirm is disabled', (tester) async {
    await pump(tester);

    expect(find.byKey(const Key('good-l1')), findsNothing);
    expect(find.text('Scan the line to enter quantities'), findsNWidgets(2));
    expect(confirmButton(tester).onPressed, isNull);
  });

  testWidgets('scanning pre-fills the outstanding quantity; confirm needs every line scanned', (tester) async {
    await pump(tester);

    await scan(tester, '111');
    expect(find.byKey(const Key('good-l1')), findsOneWidget);
    expect(tester.widget<TextField>(find.byKey(const Key('good-l1'))).controller!.text, '10');
    expect(find.text('Shortage: 0'), findsOneWidget);
    expect(confirmButton(tester).onPressed, isNull);

    await scan(tester, 'SKU-2');
    expect(confirmButton(tester).onPressed, isNotNull);
  });

  testWidgets('an unknown code shows the API error', (tester) async {
    await pump(tester);
    await scan(tester, 'nope');
    expect(find.text('Line not in transfer'), findsOneWidget);
  });

  testWidgets('shortage updates live and the reason field appears with a discrepancy', (tester) async {
    await pump(tester);
    await scan(tester, '111');

    await tester.enterText(find.byKey(const Key('good-l1')), '6');
    await tester.enterText(find.byKey(const Key('damaged-l1')), '2');
    await tester.pump();

    expect(find.byKey(const Key('shortage-l1')), findsOneWidget);
    expect(find.text('Shortage: 2'), findsOneWidget);
    expect(find.byKey(const Key('reason-l1')), findsOneWidget);
    expect(find.text('Expected result: discrepancy pending manager approval'), findsOneWidget);
  });

  testWidgets('exceeding the outstanding quantity is flagged and blocks the confirmation', (tester) async {
    await pump(tester);
    await scan(tester, '111');
    await scan(tester, 'SKU-2');

    await tester.enterText(find.byKey(const Key('good-l1')), '9');
    await tester.enterText(find.byKey(const Key('damaged-l1')), '2');
    await tester.pump();

    expect(find.byKey(const Key('issue-l1')), findsOneWidget);
    expect(find.text('Received plus damaged exceeds the outstanding quantity'), findsOneWidget);
    expect(confirmButton(tester).onPressed, isNull);
  });

  testWidgets('non numeric input is flagged and blocks the confirmation', (tester) async {
    await pump(tester);
    await scan(tester, '111');
    await scan(tester, 'SKU-2');

    await tester.enterText(find.byKey(const Key('good-l1')), 'abc');
    await tester.pump();

    expect(find.text('Enter a valid number'), findsOneWidget);
    expect(confirmButton(tester).onPressed, isNull);
  });

  testWidgets('the partial switch sends final=false and shows the partially received preview', (tester) async {
    await pump(tester);
    await scan(tester, '111');
    await scan(tester, 'SKU-2');
    await tester.enterText(find.byKey(const Key('good-l1')), '4');
    await tester.pump();

    await tester.tap(find.byKey(const Key('partial-switch')));
    await tester.pump();
    expect(find.text('Expected result: partially received'), findsOneWidget);

    await tester.tap(find.byKey(const Key('receipt-confirm')));
    await tester.pumpAndSettle();

    expect(repo.lastFinal, isFalse);
    expect(repo.lastReceiptLines!.first.receivedQty, 4);
  });

  testWidgets('a final receipt with a discrepancy tells the operator a manager must approve', (tester) async {
    await pump(tester);
    repo.receiveResult = buildTransfer(status: 'discrepancy_pending');
    await scan(tester, '111');
    await scan(tester, 'SKU-2');
    await tester.enterText(find.byKey(const Key('good-l1')), '8');
    await tester.enterText(find.byKey(const Key('damaged-l1')), '1');
    await tester.pump();

    await tester.tap(find.byKey(const Key('receipt-confirm')));
    await tester.pumpAndSettle();

    expect(repo.lastFinal, isTrue);
    expect(find.text('Receipt saved. Status: Discrepancy pending'), findsOneWidget);
    expect(find.byKey(const Key('manager-approval')), findsOneWidget);
    expect(find.text('Discrepancies need manager approval'), findsOneWidget);
    // No approve action exists for operators.
    expect(find.textContaining('Approve'), findsNothing);
  });

  testWidgets('a clean final receipt shows received without the approval notice', (tester) async {
    await pump(tester);
    await scan(tester, '111');
    await scan(tester, 'SKU-2');

    await tester.tap(find.byKey(const Key('receipt-confirm')));
    await tester.pumpAndSettle();

    expect(find.text('Receipt saved. Status: Received'), findsOneWidget);
    expect(find.byKey(const Key('manager-approval')), findsNothing);
  });

  testWidgets('labels are translated (German)', (tester) async {
    await pump(tester, locale: const Locale('de'));
    await scan(tester, '111');
    expect(find.text('Wareneingang TR-001'), findsOneWidget);
    expect(find.text('Beschädigt'), findsOneWidget);
    expect(find.text('Teilwareneingang'), findsOneWidget);
  });
}
