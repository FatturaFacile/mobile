import 'dart:convert';

import 'package:fattura_facile/features/wms/data/wms_repository.dart';
import 'package:fattura_facile/features/wms/models/transfer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'support.dart';

const _config = ApiConfig(
  baseUrl: 'https://api.test/',
  token: 'tok-123',
  tenantId: 'tenant-9',
  locale: 'it',
);

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

void main() {
  late List<http.Request> requests;

  HttpWmsRepository build(http.Response Function(http.Request) handler) {
    requests = [];
    return HttpWmsRepository(
      config: _config,
      client: MockClient((request) async {
        requests.add(request);
        return handler(request);
      }),
    );
  }

  test('queue: outbound asks for approved transfers of the warehouse with auth + tenant headers', () async {
    final repo = build(
      (_) => _json({
        'success': true,
        'message': '',
        'data': [transferJson(status: 'approved')],
        'meta': {'total': 1},
      }),
    );

    final result = await repo.queue(
      warehouseId: 'w-main',
      direction: TransferDirection.outbound,
    );

    final request = requests.single;
    expect(request.method, 'GET');
    expect(request.url.path, '/api/v1/wms/transfers');
    expect(request.url.queryParameters, {
      'status': 'approved',
      'warehouse_id': 'w-main',
      'direction': 'outbound',
    });
    expect(request.headers['Authorization'], 'Bearer tok-123');
    expect(request.headers['X-Tenant-Id'], 'tenant-9');
    expect(request.headers['Accept-Language'], 'it');
    expect(result.single.status, TransferStatus.approved);
  });

  test('queue: inbound asks for in_transit and partially_received', () async {
    final repo = build(
      (_) => _json({'success': true, 'message': '', 'data': []}),
    );
    await repo.queue(
      warehouseId: 'w-branch',
      direction: TransferDirection.inbound,
    );
    expect(
      requests.single.url.queryParameters['status'],
      'in_transit,partially_received',
    );
    expect(requests.single.url.queryParameters['direction'], 'inbound');
  });

  test('warehouses and transfer detail use their endpoints', () async {
    final repo = build(
      (r) => r.url.path.endsWith('warehouses')
          ? _json({
              'success': true,
              'data': [
                {'id': 'w1', 'code': 'MAIN', 'name': 'Main'},
              ],
            })
          : _json({'success': true, 'data': transferJson(id: 'abc')}),
    );

    expect((await repo.warehouses()).single.code, 'MAIN');
    expect((await repo.transfer('abc')).id, 'abc');
    expect(requests[0].url.path, '/api/v1/logistics/lookups/warehouses');
    expect(requests[1].url.path, '/api/v1/wms/transfers/abc');
  });

  test(
    'scan posts the code and parses the line with numeric outstanding',
    () async {
      final repo = build(
        (_) => _json({
          'success': true,
          'data': {'line': lineJson('l1'), 'outstanding_qty': 12},
        }),
      );

      final result = await repo.scan('t1', '8001234567890');

      expect(requests.single.method, 'POST');
      expect(requests.single.url.path, '/api/v1/wms/transfers/t1/scan');
      expect(jsonDecode(requests.single.body), {'code': '8001234567890'});
      expect(
        requests.single.headers['Content-Type'],
        contains('application/json'),
      );
      expect(result.line.id, 'l1');
      expect(result.outstandingQty, 12);
    },
  );

  test('ship sends only the provided optional fields', () async {
    final repo = build(
      (_) =>
          _json({'success': true, 'data': transferJson(status: 'in_transit')}),
    );

    await repo.ship(
      't1',
      const ShipmentInput(
        carrierName: ' Van ',
        packagesCount: 2,
        grossWeightKg: 4.5,
      ),
    );
    expect(requests.last.url.path, '/api/v1/wms/transfers/t1/ship');
    expect(jsonDecode(requests.last.body), {
      'carrier_name': 'Van',
      'packages_count': 2,
      'gross_weight_kg': 4.5,
    });

    final shipped = await repo.ship('t1', const ShipmentInput());
    expect(jsonDecode(requests.last.body), isEmpty);
    expect(shipped.status, TransferStatus.inTransit);
  });

  test('receive posts final flag and per-line quantities', () async {
    final repo = build(
      (_) => _json({
        'success': true,
        'data': transferJson(
          status: 'discrepancy_pending',
          discrepancies: [
            {
              'id': 'd1',
              'shortage_qty': '2.0000',
              'damage_qty': '2.0000',
              'status': 'pending',
            },
          ],
        ),
      }),
    );

    final result = await repo.receive(
      't1',
      finalReceipt: false,
      lines: const [
        ReceiptLineInput(
          lineId: 'l1',
          receivedQty: 8,
          damagedQty: 2,
          reason: 'wet',
        ),
      ],
    );

    expect(requests.single.url.path, '/api/v1/wms/transfers/t1/receive');
    expect(jsonDecode(requests.single.body), {
      'final': false,
      'lines': [
        {
          'line_id': 'l1',
          'received_qty': 8.0,
          'damaged_qty': 2.0,
          'discrepancy_reason': 'wet',
        },
      ],
    });
    expect(result.status, TransferStatus.discrepancyPending);
    expect(result.discrepancies.single.shortageQty, 2);
  });

  group('error mapping', () {
    test('422 envelope becomes ApiException with the server message', () async {
      final repo = build(
        (_) =>
            _json({'success': false, 'message': 'Line not in transfer'}, 422),
      );
      await expectLater(
        repo.scan('t1', 'x'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.message, 'message', 'Line not in transfer')
              .having((e) => e.statusCode, 'statusCode', 422)
              .having((e) => e.isNetwork, 'isNetwork', false),
        ),
      );
    });

    test('401 and 403 are flagged', () async {
      final repo = build(
        (_) => _json({'success': false, 'message': 'Forbidden'}, 403),
      );
      await expectLater(
        repo.queue(warehouseId: 'w', direction: TransferDirection.inbound),
        throwsA(
          isA<ApiException>().having((e) => e.isForbidden, 'forbidden', true),
        ),
      );
      final repo401 = build((_) => _json({'message': 'Unauthenticated.'}, 401));
      await expectLater(
        repo401.transfer('t'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.isUnauthorized,
            'unauthorized',
            true,
          ),
        ),
      );
    });

    test('non-JSON error bodies fall back to the HTTP status', () async {
      final repo = build((_) => http.Response('<html>boom</html>', 500));
      await expectLater(
        repo.transfer('t'),
        throwsA(
          isA<ApiException>().having((e) => e.message, 'message', 'HTTP 500'),
        ),
      );
    });

    test('transport failures are mapped to network errors', () async {
      final repo = HttpWmsRepository(
        config: _config,
        client: MockClient((_) async => throw http.ClientException('offline')),
      );
      await expectLater(
        repo.transfer('t'),
        throwsA(
          isA<ApiException>().having((e) => e.isNetwork, 'isNetwork', true),
        ),
      );
    });

    test(
      'an unexpected payload shape is reported instead of crashing',
      () async {
        final repo = build((_) => _json({'success': true, 'data': 'oops'}));
        await expectLater(repo.transfer('t'), throwsA(isA<ApiException>()));
      },
    );
  });
}
