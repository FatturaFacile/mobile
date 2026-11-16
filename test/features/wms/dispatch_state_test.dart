import 'package:fattura_facile/features/wms/data/wms_repository.dart';
import 'package:fattura_facile/features/wms/state/dispatch_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

void main() {
  group('DispatchChecklist', () {
    test('is ready only when every line has been scanned', () {
      var checklist = DispatchChecklist(lines: buildTransfer(status: 'approved').lines);
      expect(checklist.isReady, isFalse);
      checklist = checklist.markScanned('l1');
      expect(checklist.scannedCount, 1);
      expect(checklist.isReady, isFalse);
      checklist = checklist.markScanned('l2').markScanned('l2');
      expect(checklist.scannedCount, 2);
      expect(checklist.isReady, isTrue);
    });

    test('ignores lines that are not part of the transfer and never is ready when empty', () {
      final checklist = DispatchChecklist(lines: buildTransfer().lines);
      expect(identical(checklist.markScanned('zzz'), checklist), isTrue);
      expect(const DispatchChecklist(lines: []).isReady, isFalse);
    });
  });

  group('DispatchController', () {
    late FakeWmsRepository repo;
    late DispatchController controller;

    setUp(() {
      repo = FakeWmsRepository()..codes = {'111': 'l1', 'SKU-2': 'l2'};
      controller = DispatchController(repository: repo, transfer: buildTransfer(status: 'approved'));
    });

    test('confirm is refused until all lines are scanned', () async {
      expect(controller.canConfirm, isFalse);
      expect(await controller.confirm(), isFalse);
      await controller.scan('111');
      expect(controller.canConfirm, isFalse);
      expect(repo.calls.where((c) => c.startsWith('ship')), isEmpty);
    });

    test('scanning every line enables the dispatch which then posts the shipment data', () async {
      expect(await controller.scan('111'), isTrue);
      expect(controller.lastScanned!.id, 'l1');
      await controller.scan('SKU-2');
      expect(controller.canConfirm, isTrue);

      const shipment = ShipmentInput(carrierName: 'DHL', packagesCount: 3, grossWeightKg: 12.5);
      expect(await controller.confirm(shipment), isTrue);
      expect(repo.lastShipment!.carrierName, 'DHL');
      expect(controller.phase, DispatchPhase.shipped);
      expect(controller.canConfirm, isFalse);
      expect(await controller.scan('111'), isFalse);
    });

    test('unknown code keeps the checklist and surfaces the API message', () async {
      expect(await controller.scan('nope'), isFalse);
      expect(controller.error, 'Line not in transfer');
      expect(controller.checklist.scannedCount, 0);
    });

    test('ship failure is reported and dispatch can be retried', () async {
      await controller.scan('111');
      await controller.scan('SKU-2');
      repo.shipError = const ApiException('Not approved', statusCode: 422);
      expect(await controller.confirm(), isFalse);
      expect(controller.error, 'Not approved');
      expect(controller.canConfirm, isTrue);
    });
  });
}
