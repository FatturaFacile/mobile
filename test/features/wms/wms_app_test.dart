import 'package:fattura_facile/features/wms/models/transfer.dart';
import 'package:fattura_facile/features/wms/ui/wms_app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support.dart';

void main() {
  testWidgets(
    'inbound transfer opens the receipt screen, camera scan feeds the same flow, back reloads the queue',
    (tester) async {
      useTallScreen(tester);
      final repo =
          FakeWmsRepository(
              queues: {
                TransferDirection.inbound: [buildTransfer(id: 'in-1')],
              },
            )
            ..codes = {'111': 'l1', 'SKU-2': 'l2'}
            ..receiveResult = buildTransfer(status: 'received', id: 'in-1');

      await tester.pumpWidget(
        WmsApp(
          repository: repo,
          locale: const Locale('en'),
          cameraScanner: (_) async => 'SKU-2',
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('To receive'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('transfer-in-1')));
      await tester.pumpAndSettle();

      expect(repo.calls, contains('transfer:in-1'));
      expect(find.text('Receipt TR-001'), findsOneWidget);

      await tester.tap(find.byKey(const Key('scan-camera')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('good-l2')), findsOneWidget);

      await tester.enterText(find.byKey(const Key('scan-input')), '111');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('receipt-confirm')));
      await tester.pumpAndSettle();
      expect(find.text('Receipt saved. Status: Received'), findsOneWidget);

      final queueCallsBefore = repo.calls
          .where((c) => c.startsWith('queue'))
          .length;
      await tester.tap(find.text('Back to queue'));
      await tester.pumpAndSettle();
      expect(find.text('Transfers'), findsOneWidget);
      expect(
        repo.calls.where((c) => c.startsWith('queue')).length,
        queueCallsBefore + 1,
      );
    },
  );

  testWidgets('outbound transfer opens the dispatch screen', (tester) async {
    useTallScreen(tester);
    final repo = FakeWmsRepository(
      queues: {
        TransferDirection.outbound: [
          buildTransfer(status: 'approved', id: 'out-1'),
        ],
      },
    );

    await tester.pumpWidget(
      WmsApp(repository: repo, locale: const Locale('fr')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('transfer-out-1')));
    await tester.pumpAndSettle();

    expect(find.text('Expédition TR-001'), findsOneWidget);
    expect(find.text('Confirmer l\'expédition'), findsOneWidget);
  });
}
