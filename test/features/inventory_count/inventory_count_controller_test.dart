import 'package:dio/dio.dart';
import 'package:fattura_facile/app/providers.dart';
import 'package:fattura_facile/features/inventory_count/domain/inventory_count_models.dart';
import 'package:fattura_facile/features/inventory_count/presentation/inventory_count_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

void main() {
  late CountFixture f;
  late ProviderContainer container;

  setUp(() {
    f = CountFixture();
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(f.db),
        dioProvider.overrideWithValue(f.dio),
        inventoryCountTenantProvider.overrideWithValue(tenant),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await f.dispose();
  });

  CountSheetController sheet() =>
      container.read(countSheetProvider('s1').notifier);
  CountSheetState state() => container.read(countSheetProvider('s1'));

  void online() => f.route(
    sessions: <Map<String, dynamic>>[sessionJson('s1')],
    sheet: <Map<String, dynamic>>[
      lineJson('l1', sku: 'SKU-1', bin: 'BIN-A1'),
      lineJson('l2', sku: 'SKU-2', name: 'Gadget', bin: 'BIN-A1'),
      lineJson(
        'l3',
        sku: 'SKU-3',
        name: 'Gizmo',
        bin: 'BIN-B2',
        counted: true,
        quantity: 2,
      ),
      lineJson(
        'l4',
        sku: 'SKU-4',
        name: 'Doohickey',
        bin: 'BIN-C3',
        recount: true,
        round: 1,
      ),
    ],
    record: CountFixture.answer('recorded'),
  );

  test('load shows the sheet, recounts first, and the to-count filter hides counted lines', () async {
    online();
    await sheet().load();

    expect(state().fromCache, isFalse);
    expect(state().visible.map((CountLine l) => l.id), <String>[
      'l4',
      'l1',
      'l2',
    ]);
    sheet().setFilter(CountFilter.counted);
    expect(state().visible.map((CountLine l) => l.id), <String>['l3']);
    sheet().setFilter(CountFilter.all);
    expect(state().visible, hasLength(4));
    expect(state().recountLines, 1);
  });

  test('search matches item, SKU, bin and barcode', () async {
    online();
    await sheet().load();
    sheet().setFilter(CountFilter.all);
    for (final MapEntry<String, String> c in <String, String>{
      'gadget': 'l2',
      'sku-1': 'l1',
      'bin-b2': 'l3',
      'ean-l4': 'l4',
    }.entries) {
      sheet().setQuery(c.key);
      expect(state().visible.single.id, c.value, reason: c.key);
    }
  });

  test('a scan resolving to one open line focuses it, a bin scan lists its lines, an unknown code warns', () async {
    online();
    await sheet().load();

    sheet().scan('SKU-2');
    expect(state().focusLineId, 'l2');

    sheet().scan('BIN-A1');
    expect(state().focusLineId, isNull);
    expect(state().visible.map((CountLine l) => l.id), <String>['l1', 'l2']);

    sheet().scan('NOPE');
    expect(state().notice, CountNotice.scanNoMatch);
    expect(state().visible, isEmpty);
  });

  test('saving online sends the entry and reports it saved', () async {
    online();
    await sheet().load();
    final CountLine line = state().lines.firstWhere(
      (CountLine l) => l.id == 'l1',
    );

    expect(await sheet().save(line, 12, notes: 'two pallets'), isTrue);

    expect(state().notice, CountNotice.saved);
    expect(await f.repo.pendingCount(tenant), 0);
  });

  test(
    'saving offline keeps the count on the device and marks the line pending',
    () async {
      online();
      await sheet().load();
      f.adapter.handler = (RequestOptions o) => throw DioException(
        requestOptions: o,
        type: DioExceptionType.connectionError,
      );
      final CountLine line = state().lines.firstWhere(
        (CountLine l) => l.id == 'l1',
      );

      await sheet().save(line, 12);

      expect(state().notice, CountNotice.queuedOffline);
      final CountLine now = state().lines.firstWhere(
        (CountLine l) => l.id == 'l1',
      );
      expect(now.pendingSync, isTrue);
      expect(now.shownQuantity, 12);
      expect(now.toCount, isFalse);
      expect(await f.repo.pendingCount(tenant), 1);
    },
  );

  test(
    'a recount answer flags the line for a new count and hides the typed value',
    () async {
      online();
      await sheet().load();
      final CountLine line = state().lines.firstWhere(
        (CountLine l) => l.id == 'l1',
      );
      f.route(
        sessions: <Map<String, dynamic>>[sessionJson('s1')],
        sheet: <Map<String, dynamic>>[lineJson('l1', recount: true, round: 1)],
        record: CountFixture.answer('recount_required', round: 1),
      );

      await sheet().save(line, 9);

      expect(state().notice, CountNotice.recountRequested);
      final CountLine now = state().lines.single;
      expect(now.recountRequired, isTrue);
      expect(now.shownQuantity, isNull);
      expect(now.toCount, isTrue);
    },
  );

  test(
    'syncNow reports an error while offline and success once reachable',
    () async {
      online();
      await sheet().load();
      final CountLine line = state().lines.firstWhere(
        (CountLine l) => l.id == 'l1',
      );
      f.adapter.handler = (RequestOptions o) => throw DioException(
        requestOptions: o,
        type: DioExceptionType.connectionError,
      );
      await sheet().save(line, 1);

      await sheet().syncNow();
      expect(state().notice, CountNotice.syncError);

      online();
      await sheet().syncNow();
      expect(state().notice, CountNotice.syncDone);
      expect(await f.repo.pendingCount(tenant), 0);
    },
  );

  test(
    'my counts lists the sessions from the cache when the refresh fails',
    () async {
      online();
      final CountListController list = container.read(
        countListProvider.notifier,
      );
      await list.load();
      expect(container.read(countListProvider).sessions.single.id, 's1');

      f.adapter.handler = (RequestOptions o) => throw DioException(
        requestOptions: o,
        type: DioExceptionType.connectionError,
      );
      container.invalidate(countListProvider);
      await container.read(countListProvider.notifier).load();
      final CountListState s = container.read(countListProvider);
      expect(s.sessions.single.id, 's1');
      expect(s.fromCache, isTrue);
      expect(s.error?.kind, CountErrorKind.offline);
    },
  );
}
