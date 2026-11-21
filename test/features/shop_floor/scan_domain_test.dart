import 'package:fattura_facile/features/shop_floor/domain/gs1_parser.dart';
import 'package:fattura_facile/features/shop_floor/domain/scan_resolver.dart';
import 'package:fattura_facile/features/shop_floor/domain/shop_floor_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GS1-128', () {
    test('parses the human readable form', () {
      final Gs1Data d = Gs1Parser.parse(
        '(01)09506000134352(17)271231(10)LOT-42(30)12',
      );
      expect(d.gtin, '09506000134352');
      expect(d.expiry, DateTime.utc(2027, 12, 31));
      expect(d.lot, 'LOT-42');
      expect(d.quantity, 12);
    });

    test(
      'parses the raw form with FNC1 separators and the symbology identifier',
      () {
        final Gs1Data d = Gs1Parser.parse(
          ']C101095060001343521727123110LOT-42\u001d3102001250',
        );
        expect(d.lot, 'LOT-42');
        expect(d.quantity, 12.5, reason: 'AI 3102 is kg with two decimals');
        expect(d.gtin, '09506000134352');
      },
    );

    test(
      'a variable field at the end needs no separator; fixed fields need none',
      () {
        final Gs1Data d = Gs1Parser.parse(
          '0109506000134352'
          '10ABC',
        );
        expect(d.elements, <String, String>{
          '01': '09506000134352',
          '10': 'ABC',
        });
      },
    );

    test('non GS1 text and truncated fixed fields yield nothing', () {
      expect(Gs1Parser.parse('PO-0001').isEmpty, isTrue);
      expect(Gs1Parser.parse('0109506').isEmpty, isTrue);
      expect(Gs1Parser.parse('(10)').isEmpty, isTrue);
      expect(Gs1Parser.parse('').isEmpty, isTrue);
    });
  });

  group('ScanResolver', () {
    test('prefixed order, work centre and lot codes', () {
      expect(
        ScanResolver.resolve('FF:PO:PO-0001'),
        isA<OrderScan>().having((OrderScan s) => s.reference, 'ref', 'PO-0001'),
      );
      expect(
        ScanResolver.resolve('ff:wc:WC-10'),
        isA<WorkCenterScan>().having(
          (WorkCenterScan s) => s.code,
          'code',
          'WC-10',
        ),
      );
      final ScanResult lot = ScanResolver.resolve(
        'FF:LOT:99999999-9999-4999-8999-999999999999|L-77',
      );
      expect(
        lot,
        isA<LotScan>()
            .having(
              (LotScan s) => s.lotId,
              'id',
              '99999999-9999-4999-8999-999999999999',
            )
            .having((LotScan s) => s.lotNumber, 'lot', 'L-77'),
      );
    });

    test('a bare order number is recognised only against the known orders', () {
      expect(
        ScanResolver.resolve('po-0001', knownOrderNumbers: <String>['PO-0001']),
        isA<OrderScan>(),
      );
      expect(ScanResolver.resolve('po-0001'), isA<UnknownScan>());
    });

    test('a GS1 label with a lot is a lot scan; garbage and empty prefixes are unknown', () {
      final ScanResult r = ScanResolver.resolve(
        '(01)09506000134352(10)LOT-9(37)40',
      );
      expect(
        r,
        isA<LotScan>()
            .having((LotScan s) => s.lotNumber, 'lot', 'LOT-9')
            .having((LotScan s) => s.quantity, 'qty', 40)
            .having((LotScan s) => s.gtin, 'gtin', '09506000134352'),
      );
      expect(ScanResolver.resolve('FF:PO:'), isA<UnknownScan>());
      expect(ScanResolver.resolve('FF:LOT:not-a-uuid'), isA<UnknownScan>());
      expect(ScanResolver.resolve('   '), isA<UnknownScan>());
    });
  });

  group('OperationTimer', () {
    final DateTime t0 = DateTime.utc(2030, 1, 1, 8);

    test('setup, run, pause and resume accumulate into the right buckets', () {
      OperationTimer t = const OperationTimer().startSetup(t0);
      t = t.startRun(t0.add(const Duration(minutes: 5)));
      t = t.pause(t0.add(const Duration(minutes: 15)));
      expect(t.phase, TerminalPhase.paused);
      t = t.resume(t0.add(const Duration(minutes: 18)));
      expect(
        t.phase,
        TerminalPhase.run,
        reason: 'resume returns to the interrupted phase',
      );
      final OperationTimer end = t.stop(t0.add(const Duration(minutes: 28)));
      expect(end.setupSeconds, 300);
      expect(end.runSeconds, 600 + 600);
      expect(end.downtimeSeconds, 180);
      expect(end.phase, TerminalPhase.idle);
    });

    test(
      'pause is ignored when nothing is running and resume when not paused',
      () {
        const OperationTimer idle = OperationTimer();
        expect(idle.pause(t0).phase, TerminalPhase.idle);
        expect(idle.startRun(t0).resume(t0).phase, TerminalPhase.run);
      },
    );

    test('snapshot includes the running phase without stopping it', () {
      final OperationTimer t = const OperationTimer().startRun(t0);
      expect(t.snapshot(t0.add(const Duration(seconds: 90))).runSeconds, 90);
      expect(t.runSeconds, 0);
      expect(OperationTimer.minutes(90), 1.5);
    });
  });

  group('models', () {
    test('quality tolerance and order parsing', () {
      const QualityCharacteristic c = QualityCharacteristic(
        id: 'c',
        name: 'd',
        min: 9.9,
        max: 10.1,
      );
      expect(c.accepts(10), isTrue);
      expect(c.accepts(10.2), isFalse);
      expect(
        const QualityCharacteristic(id: 'c', name: 'd', min: 1).accepts(1000),
        isTrue,
        reason: 'an open side is unbounded',
      );
      final ProductionOrder o = ProductionOrder.fromJson(<String, dynamic>{
        'id': 'x',
        'order_number': 'PO-1',
        'status': 'in_progress',
        'target_quantity': '5.5',
        'uom': 'pcs',
        'operations': <dynamic>[
          <String, dynamic>{'id': 'b', 'sequence': 20},
          <String, dynamic>{'id': 'a', 'sequence': 10},
        ],
      });
      expect(o.isExecutable, isTrue);
      expect(o.targetQuantity, 5.5);
      expect(o.operations.map((OrderOperation e) => e.id), <String>['a', 'b']);
    });
  });
}
