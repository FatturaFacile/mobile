import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:fattura_facile/core/database/app_database.dart';
import 'package:fattura_facile/features/shop_floor/data/shop_floor_outbox.dart';
import 'package:fattura_facile/features/shop_floor/data/shop_floor_repository.dart';

const String tenant = 'tenant-1';
const String orderId = '11111111-1111-4111-8111-111111111111';
const String otherOrderId = '22222222-2222-4222-8222-222222222222';
const String lineA = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const String lineB = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
const String opId = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';
const String wcId = 'dddddddd-dddd-4ddd-8ddd-dddddddddddd';
const String planId = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee';
const String charId = 'ffffffff-ffff-4fff-8fff-ffffffffffff';

typedef Responder = ResponseBody Function(RequestOptions options);

ResponseBody jsonBody(int status, Object body) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: <String, List<String>>{
    Headers.contentTypeHeader: <String>[Headers.jsonContentType],
  },
);

/// Scriptable fake of the manufacturing API; every request is recorded.
class FakeApi implements HttpClientAdapter {
  FakeApi();

  final List<RequestOptions> calls = <RequestOptions>[];

  /// Overrides the answer of POSTs; the default is 201 `{data: {}}`.
  Responder? onPost;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls.add(options);
    if (options.method == 'POST') {
      return (onPost ??
          (RequestOptions o) => jsonBody(201, <String, dynamic>{
            'data': <String, dynamic>{},
          }))(options);
    }
    final String path = options.path;
    if (path.endsWith('/production-orders')) {
      return options.queryParameters['status'] == 'released'
          ? jsonBody(200, <String, dynamic>{
              'data': <Map<String, dynamic>>[
                <String, dynamic>{'id': orderId},
              ],
              'meta': <String, dynamic>{'last_page': 1},
            })
          : jsonBody(200, <String, dynamic>{'data': <dynamic>[]});
    }
    if (path.endsWith('/production-orders/$orderId')) {
      return jsonBody(200, <String, dynamic>{'data': orderJson()});
    }
    if (path.endsWith('/work-centers')) {
      return jsonBody(200, <String, dynamic>{
        'data': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': wcId,
            'work_center_code': 'WC-10',
            'name': 'Press 10',
          },
        ],
      });
    }
    if (path.endsWith('/quality/plans')) {
      return jsonBody(200, <String, dynamic>{
        'data': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': planId,
            'plan_code': 'QP-1',
            'name': 'Final check',
            'characteristics': <Map<String, dynamic>>[
              <String, dynamic>{
                'id': charId,
                'characteristic_name': 'Diameter',
                'target_value': '10',
                'min_tolerance': '9.9',
                'max_tolerance': '10.1',
                'uom': 'mm',
              },
            ],
          },
        ],
      });
    }
    if (path.endsWith('/genealogy')) {
      return jsonBody(200, <String, dynamic>{
        'data': <String, dynamic>{'lots': <dynamic>[]},
      });
    }
    return jsonBody(404, <String, dynamic>{'message': 'nope'});
  }

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> orderJson({
  String id = orderId,
  String number = 'PO-0001',
}) => <String, dynamic>{
  'id': id,
  'order_number': number,
  'status': 'released',
  'item_code': 'FG-1',
  'item_name': 'Widget',
  'target_quantity': '100.0000',
  'completed_quantity': '10.0000',
  'scrapped_quantity': '0.0000',
  'uom': 'pcs',
  'lines': <Map<String, dynamic>>[
    <String, dynamic>{
      'id': lineA,
      'mfg_item_id': 'i1',
      'item_code': 'RM-A',
      'issue_method': 'backflush',
      'required_quantity': '200',
      'issued_quantity': '20',
      'uom': 'kg',
    },
    <String, dynamic>{
      'id': lineB,
      'mfg_item_id': 'i2',
      'item_code': 'RM-B',
      'issue_method': 'manual',
      'required_quantity': '50',
      'issued_quantity': '0',
      'uom': 'kg',
    },
  ],
  'operations': <Map<String, dynamic>>[
    <String, dynamic>{
      'id': opId,
      'sequence': 10,
      'operation_code': 'OP10',
      'name': 'Pressing',
      'work_center_id': wcId,
      'status': 'pending',
      'completed_quantity': '0',
      'scrapped_quantity': '0',
    },
  ],
};

/// Mutable clock for backoff tests.
class TestClock {
  TestClock(this.now);

  DateTime now;

  DateTime call() => now;

  void advance(Duration d) => now = now.add(d);
}

class Harness {
  Harness._(this.db, this.api, this.clock, this.outbox, this.repo);

  factory Harness() {
    final AppDatabase db = AppDatabase(NativeDatabase.memory());
    final FakeApi api = FakeApi();
    final Dio dio = Dio(BaseOptions(baseUrl: 'http://x/api/v1'))
      ..httpClientAdapter = api;
    final TestClock clock = TestClock(DateTime.utc(2030, 1, 1, 8));
    final ShopFloorOutbox outbox = ShopFloorOutbox(db, dio, clock: clock.call);
    final ShopFloorRepository repo = ShopFloorRepository(
      db,
      dio,
      outbox,
      clock: clock.call,
    );
    return Harness._(db, api, clock, outbox, repo);
  }

  final AppDatabase db;
  final FakeApi api;
  final TestClock clock;
  final ShopFloorOutbox outbox;
  final ShopFloorRepository repo;

  /// Loads the fake server's orders, work centres and quality plans into the local cache.
  Future<void> seed() => repo.refresh(tenant);

  List<RequestOptions> posts() =>
      api.calls.where((RequestOptions c) => c.method == 'POST').toList();

  Future<void> close() => db.close();
}
