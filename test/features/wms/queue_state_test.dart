import 'dart:async';

import 'package:fattura_facile/features/wms/data/wms_repository.dart';
import 'package:fattura_facile/features/wms/models/transfer.dart';
import 'package:fattura_facile/features/wms/state/queue_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

class _SlowRepository extends FakeWmsRepository {
  final Map<String, Completer<List<Transfer>>> pending = {};

  @override
  Future<List<Transfer>> queue({
    required String warehouseId,
    required TransferDirection direction,
  }) => (pending[warehouseId] = Completer<List<Transfer>>()).future;
}

void main() {
  test('init loads warehouses and selects the first one', () async {
    final repo = FakeWmsRepository(
      queues: {
        TransferDirection.outbound: [buildTransfer(status: 'approved')],
      },
    );
    final controller = TransferQueueController(repository: repo);
    await controller.init();

    expect(controller.warehouseId, 'w-main');
    expect(controller.phase, QueuePhase.loaded);
    expect(controller.transfers, hasLength(1));
  });

  test(
    'an initial warehouse is respected and direction changes reload',
    () async {
      final repo = FakeWmsRepository();
      final controller = TransferQueueController(
        repository: repo,
        initialWarehouseId: 'w-branch',
      );
      await controller.init();
      await controller.setDirection(TransferDirection.inbound);
      await controller.setDirection(TransferDirection.inbound); // no-op

      expect(repo.calls, ['queue:w-branch:outbound', 'queue:w-branch:inbound']);
    },
  );

  test('failures are exposed', () async {
    final repo = FakeWmsRepository()
      ..queueError = const ApiException('Boom', statusCode: 500);
    final controller = TransferQueueController(repository: repo);
    await controller.init();
    expect(controller.phase, QueuePhase.failed);
    expect(controller.error, 'Boom');
  });

  test(
    'a stale response is ignored when a newer request was started',
    () async {
      final repo = _SlowRepository();
      final controller = TransferQueueController(
        repository: repo,
        initialWarehouseId: 'w-main',
      );
      final first = controller.refresh();
      final second = controller.selectWarehouse('w-branch');

      repo.pending['w-branch']!.complete([buildTransfer(id: 'new')]);
      await second;
      repo.pending['w-main']!.complete([buildTransfer(id: 'old')]);
      await first;

      expect(controller.transfers.single.id, 'new');
    },
  );
}
