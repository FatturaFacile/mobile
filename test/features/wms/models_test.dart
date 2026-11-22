import 'package:fattura_facile/features/wms/models/transfer.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

void main() {
  group('parseDecimal', () {
    test('parses decimal strings, numbers and garbage safely', () {
      expect(parseDecimal('2.0000'), 2.0);
      expect(parseDecimal(' 3.5 '), 3.5);
      expect(parseDecimal(7), 7.0);
      expect(parseDecimal(1.25), 1.25);
      expect(parseDecimal(null), 0);
      expect(parseDecimal('abc'), 0);
    });
  });

  group('Transfer.fromJson', () {
    test('parses transfer, lines and discrepancies', () {
      final transfer = Transfer.fromJson(
        transferJson(
          status: 'discrepancy_pending',
          purpose: 'customer_consignment',
          lines: [
            lineJson(
              'l1',
              shipped: '10.0000',
              received: '8.0000',
              damaged: '1.0000',
            ),
          ],
          discrepancies: [
            {
              'id': 'd1',
              'shortage_qty': '1.0000',
              'damage_qty': '1.0000',
              'status': 'pending',
            },
          ],
        ),
      );

      expect(transfer.id, 't1');
      expect(transfer.transferNumber, 'TR-001');
      expect(transfer.purpose, TransferPurpose.customerConsignment);
      expect(transfer.status, TransferStatus.discrepancyPending);
      expect(transfer.originWarehouseId, 'w-main');
      expect(transfer.lines.single.shippedQty, 10);
      expect(transfer.lines.single.outstandingQty, 1);
      expect(transfer.discrepancies.single.shortageQty, 1);
      expect(transfer.discrepancies.single.status, 'pending');
      expect(transfer.lineById('l1'), isNotNull);
      expect(transfer.lineById('nope'), isNull);
    });

    test('maps every wire status and purpose, unknown values fall back', () {
      for (final s in TransferStatus.values.where(
        (s) => s != TransferStatus.unknown,
      )) {
        expect(TransferStatus.parse(s.wire), s);
      }
      for (final p in TransferPurpose.values.where(
        (p) => p != TransferPurpose.unknown,
      )) {
        expect(TransferPurpose.parse(p.wire), p);
      }
      expect(TransferStatus.parse('weird'), TransferStatus.unknown);
      expect(TransferPurpose.parse(null), TransferPurpose.unknown);
    });

    test('tolerates missing lines and discrepancies (list payload)', () {
      final transfer = Transfer.fromJson({'id': 'x', 'status': 'approved'});
      expect(transfer.lines, isEmpty);
      expect(transfer.discrepancies, isEmpty);
      expect(transfer.originWarehouseId, isNull);
    });

    test('outstanding is shipped - received - damaged without float noise', () {
      final line = TransferLine.fromJson(
        lineJson('l', shipped: '0.3000', received: '0.1000', damaged: '0.1000'),
      );
      expect(line.outstandingQty, 0.1);
    });
  });

  test('ScanResult parses numeric outstanding_qty', () {
    final result = ScanResult.fromJson({
      'line': lineJson('l1'),
      'outstanding_qty': 12,
    });
    expect(result.line.id, 'l1');
    expect(result.outstandingQty, 12);
  });

  test('Warehouse label combines code and name', () {
    expect(
      Warehouse.fromJson({'id': 1, 'code': 'MAIN', 'name': 'Central'}).label,
      'MAIN - Central',
    );
    expect(Warehouse.fromJson({'id': 2, 'code': 'BR'}).label, 'BR');
  });
}
