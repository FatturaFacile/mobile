import 'package:fattura_facile/features/wms/data/wms_repository.dart';
import 'package:fattura_facile/features/wms/models/transfer.dart';
import 'package:fattura_facile/features/wms/state/queue_state.dart';
import 'package:fattura_facile/features/wms/ui/queue_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support.dart';

void main() {
  late FakeWmsRepository repo;

  setUp(() {
    repo = FakeWmsRepository(
      queues: {
        TransferDirection.outbound: [
          buildTransfer(status: 'approved', id: 'out-1'),
        ],
        TransferDirection.inbound: [
          buildTransfer(id: 'in-1'),
          Transfer.fromJson(
            transferJson(
              id: 'in-2',
              number: 'TR-002',
              status: 'partially_received',
            ),
          ),
        ],
      },
    );
  });

  Future<(TransferQueueController, List<(Transfer, TransferDirection)>)> pump(
    WidgetTester tester,
  ) async {
    final controller = TransferQueueController(repository: repo);
    final opened = <(Transfer, TransferDirection)>[];
    await tester.pumpWidget(
      testApp(
        QueueScreen(
          controller: controller,
          onOpen: (t, d) => opened.add((t, d)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (controller, opened);
  }

  testWidgets(
    'loads the first warehouse and lists outbound transfers to dispatch',
    (tester) async {
      await pump(tester);

      expect(repo.calls, contains('queue:w-main:outbound'));
      expect(find.text('TR-001'), findsOneWidget);
      expect(find.text('Approved'), findsOneWidget);
      expect(find.text('Inter-warehouse - 2 lines'), findsOneWidget);
      expect(find.byKey(const Key('transfer-out-1')), findsOneWidget);
    },
  );

  testWidgets(
    'switching to inbound lists transfers to receive with their status chips',
    (tester) async {
      await pump(tester);

      await tester.tap(find.text('To receive'));
      await tester.pumpAndSettle();

      expect(repo.calls, contains('queue:w-main:inbound'));
      expect(find.byKey(const Key('transfer-in-1')), findsOneWidget);
      expect(find.text('In transit'), findsOneWidget);
      expect(find.text('Partially received'), findsOneWidget);
    },
  );

  testWidgets('changing the warehouse reloads the queue for it', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.byKey(const Key('warehouse-select')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('BR - Branch').last);
    await tester.pumpAndSettle();

    expect(repo.calls, contains('queue:w-branch:outbound'));
  });

  testWidgets('tapping a transfer reports it with the active direction', (
    tester,
  ) async {
    final (_, opened) = await pump(tester);

    await tester.tap(find.byKey(const Key('transfer-out-1')));
    expect(opened.single.$1.id, 'out-1');
    expect(opened.single.$2, TransferDirection.outbound);
  });

  testWidgets('shows an empty state when nothing is waiting', (tester) async {
    repo = FakeWmsRepository();
    await pump(tester);
    expect(find.byKey(const Key('queue-empty')), findsOneWidget);
  });

  testWidgets('shows the API error and retries', (tester) async {
    repo.queueError = const ApiException('Forbidden', statusCode: 403);
    await pump(tester);
    expect(find.text('Forbidden'), findsOneWidget);

    repo.queueError = null;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('TR-001'), findsOneWidget);
  });

  testWidgets('labels are translated (Italian)', (tester) async {
    final controller = TransferQueueController(repository: repo);
    await tester.pumpWidget(
      testApp(
        QueueScreen(controller: controller, onOpen: (_, _) {}),
        locale: const Locale('it'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Trasferimenti'), findsOneWidget);
    expect(find.text('Da spedire'), findsOneWidget);
    expect(find.text('Approvato'), findsOneWidget);
  });
}
