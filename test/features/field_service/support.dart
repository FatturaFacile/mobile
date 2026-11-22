import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:fattura_facile/core/database/app_database.dart';
import 'package:fattura_facile/features/field_service/data/field_service_outbox.dart';
import 'package:fattura_facile/features/field_service/data/field_service_repository.dart';
import 'package:fattura_facile/features/field_service/data/field_service_store.dart';
import 'package:fattura_facile/features/field_service/models/field_service_models.dart';

const String tenant = 'tenant-1';
const String technicianId = '11111111-1111-4111-8111-111111111111';
const String woCorrective = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1';
const String woWarranty = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa2';
const String customerId = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';
const String equipmentId = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee';
const String contractId = 'dddddddd-dddd-4ddd-8ddd-dddddddddddd';
const String productFilter = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1';
const String productOil = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2';

const String drawnSvg =
    '<svg xmlns="http://www.w3.org/2000/svg" width="480.0" height="180.0" '
    'viewBox="0 0 480.0 180.0"><path d="M10.0 10.0 L50.0 40.0" fill="none" '
    'stroke="#111111" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>';

typedef Responder = ResponseBody Function(RequestOptions options);

ResponseBody jsonBody(int status, Object body) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: <String, List<String>>{
    Headers.contentTypeHeader: <String>[Headers.jsonContentType],
  },
);

/// The offline bundle of the fake server: a corrective work order under a `parts_and_labor` contract and a warranty one.
Map<String, dynamic> bundleJson({
  String serverTime = '2030-01-01T08:00:00+00:00',
  List<String>? openIds,
  List<Map<String, dynamic>>? workOrders,
  double filters = 5,
}) {
  final List<Map<String, dynamic>> orders =
      workOrders ?? <Map<String, dynamic>>[workOrderJson(), warrantyJson()];
  return <String, dynamic>{
    'server_time': serverTime,
    'technician': <String, dynamic>{
      'id': technicianId,
      'name': 'Tina Technician',
      'skills': <String>['hvac'],
      'van_warehouse_id': 'vvvvvvvv-vvvv-4vvv-8vvv-vvvvvvvvvvvv',
    },
    'open_work_order_ids':
        openIds ??
        orders.map((Map<String, dynamic> w) => '${w['id']}').toList(),
    'work_orders': orders,
    'customers': <Map<String, dynamic>>[
      <String, dynamic>{
        'id': customerId,
        'name': 'Rossi SA',
        'email': 'info@rossi.example',
        'phone': '+41 91 000 00 00',
      },
    ],
    'equipment': <Map<String, dynamic>>[
      <String, dynamic>{
        'id': equipmentId,
        'serial_number': 'SN-4711',
        'product_id': productFilter,
        'site_address': 'Via Nassa 5, Lugano',
        'site_latitude': '46.003210',
        'site_longitude': '8.951230',
        'current_operating_hours': '1200.50',
        'current_cycle_count': 300,
        'last_service_date': '2029-06-01',
        'history': <Map<String, dynamic>>[
          <String, dynamic>{
            'report_number': 'SR-2029-0001',
            'signed_at': '2029-06-01T10:00:00+00:00',
            'summary': 'Replaced belt',
            'meter_reading_hours': '1100.00',
            'meter_reading_cycles': 280,
          },
        ],
      },
    ],
    'van_stock': <Map<String, dynamic>>[
      <String, dynamic>{
        'product_id': productFilter,
        'sku': 'FLT-1',
        'name': 'Air filter',
        'available': filters,
        'unit_price': '25.00',
      },
      <String, dynamic>{
        'product_id': productOil,
        'sku': 'OIL-1',
        'name': 'Oil 1 l',
        'available': 10,
        'unit_price': '12.50',
      },
    ],
  };
}

Map<String, dynamic> workOrderJson({
  String id = woCorrective,
  String status = 'dispatched',
  String workType = 'corrective',
  String? contract = contractId,
  Map<String, dynamic>? extra,
}) => <String, dynamic>{
  'id': id,
  'work_order_number': 'WO-0001',
  'work_type': workType,
  'priority': 'high',
  'status': status,
  'title': 'Compressor does not start',
  'problem_description': 'Trips the breaker',
  'customer_id': customerId,
  'equipment_passport_id': equipmentId,
  'service_contract_id': contract,
  'scheduled_start': '2030-01-02T07:00:00+00:00',
  'scheduled_end': '2030-01-02T09:00:00+00:00',
  'site': <String, dynamic>{
    'address': 'Via Nassa 5, Lugano',
    'lat': 46.00321,
    'lng': 8.95123,
  },
  'required_skills': <String>['hvac'],
  'checklist_template': <Map<String, String>>[
    <String, String>{'item': 'fault_diagnosis'},
    <String, String>{'item': 'repair_verified'},
    <String, String>{'item': 'functional_test'},
  ],
  'updated_at': '2030-01-01T07:30:00+00:00',
  ...?extra,
};

Map<String, dynamic> warrantyJson() => workOrderJson(
  id: woWarranty,
  workType: 'warranty',
  contract: null,
  extra: <String, dynamic>{
    'work_order_number': 'WO-0002',
    'title': 'Warranty swap',
  },
);

/// Scriptable fake of the `/fsm` API. It behaves like the server: it remembers the `client_uuid`s it applied and answers
/// `duplicate` for a replay.
class FakeFsmApi implements HttpClientAdapter {
  FakeFsmApi();

  final List<RequestOptions> calls = <RequestOptions>[];
  final Set<String> applied = <String>{};

  /// What `GET offline-bundle` returns as `data`.
  Map<String, dynamic> bundle = bundleJson();

  /// `client_uuid` -> field errors: answered `rejected`.
  final Map<String, Map<String, List<String>>> rejections =
      <String, Map<String, List<String>>>{};

  /// Answers every sync with this HTTP status (5xx, 401, 422...) when set.
  int? failStatus;

  /// Answers `GET offline-bundle` with this HTTP status when set.
  int? bundleFailStatus;

  /// The connection is down.
  bool offline = false;

  /// Applies the batch but loses the answer once (the response never reaches the phone).
  bool dropNextAnswer = false;

  List<RequestOptions> get syncs => calls
      .where(
        (RequestOptions c) =>
            c.method == 'POST' && c.path.endsWith('/fsm/mobile-sync'),
      )
      .toList();

  /// The operations sent in call number [i] of the sync endpoint.
  List<Map<String, dynamic>> opsOf(int i) {
    final Map<String, dynamic> body = syncs[i].data as Map<String, dynamic>;
    return (body['operations'] as List<dynamic>)
        .map(
          (dynamic o) => Map<String, dynamic>.from(o as Map<dynamic, dynamic>),
        )
        .toList();
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls.add(options);
    if (offline) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'down',
      );
    }
    if (options.method == 'GET' && options.path.contains('/offline-bundle')) {
      if (bundleFailStatus != null) {
        return jsonBody(bundleFailStatus!, <String, dynamic>{
          'message': 'boom',
        });
      }
      return jsonBody(200, <String, dynamic>{'data': bundle});
    }
    if (options.method == 'POST' && options.path.endsWith('/fsm/mobile-sync')) {
      if (failStatus != null) {
        return jsonBody(failStatus!, <String, dynamic>{
          'message': 'status $failStatus',
        });
      }
      final List<Map<String, dynamic>> results = <Map<String, dynamic>>[];
      final Map<String, dynamic> body = options.data as Map<String, dynamic>;
      for (final dynamic raw in body['operations'] as List<dynamic>) {
        final Map<String, dynamic> op = Map<String, dynamic>.from(
          raw as Map<dynamic, dynamic>,
        );
        final String uuid = '${op['client_uuid']}';
        final String type = '${op['type']}';
        if (rejections.containsKey(uuid)) {
          results.add(<String, dynamic>{
            'client_uuid': uuid,
            'type': type,
            'status': 'rejected',
            'errors': rejections[uuid],
          });
          continue;
        }
        final bool replay = applied.contains(uuid);
        applied.add(uuid);
        results.add(<String, dynamic>{
          'client_uuid': uuid,
          'type': type,
          'status': replay ? 'duplicate' : 'applied',
          if (type == 'service_report') ...<String, dynamic>{
            'report_id': 'r-$uuid',
            'report_number': 'SR-2030-0001',
            'signature_sha256_hash': 'seal-$uuid',
          },
          if (type == 'part_consumption') 'consumption_id': 'c-$uuid',
          if (type == 'status_transition')
            'work_order_status':
                '${(op['payload'] as Map<dynamic, dynamic>)['status']}',
        });
      }
      if (dropNextAnswer) {
        dropNextAnswer = false;
        throw DioException.connectionError(
          requestOptions: options,
          reason: 'lost answer',
        );
      }
      return jsonBody(200, <String, dynamic>{
        'data': <String, dynamic>{
          'results': results,
          'server_time': '2030-01-01T09:00:00+00:00',
        },
      });
    }
    return jsonBody(404, <String, dynamic>{'message': 'nope'});
  }

  @override
  void close({bool force = false}) {}
}

/// Mutable clock for backoff tests.
class TestClock {
  TestClock(this.now);

  DateTime now;

  DateTime call() => now;

  void advance(Duration d) => now = now.add(d);
}

/// Real store, outbox and repository on an in-memory SQLite, talking to [FakeFsmApi]. UUIDs are `u-1`, `u-2`, ...
class FsmHarness {
  FsmHarness._(
    this.db,
    this.api,
    this.clock,
    this.store,
    this.outbox,
    this.repo,
  );

  factory FsmHarness() {
    final AppDatabase db = AppDatabase(NativeDatabase.memory());
    final FakeFsmApi api = FakeFsmApi();
    final Dio dio = Dio(BaseOptions(baseUrl: 'http://x/api/v1'))
      ..httpClientAdapter = api;
    final TestClock clock = TestClock(DateTime.utc(2030, 1, 1, 8));
    final FieldServiceStore store = FieldServiceStore(db);
    final FieldServiceOutbox outbox = FieldServiceOutbox(
      store,
      dio,
      clock: clock.call,
    );
    var n = 0;
    final LocalFieldServiceRepository repo = LocalFieldServiceRepository(
      store: store,
      dio: dio,
      outbox: outbox,
      tenantId: tenant,
      technicianId: technicianId,
      newUuid: () => 'u-${++n}',
      clock: clock.call,
    );
    return FsmHarness._(db, api, clock, store, outbox, repo);
  }

  final AppDatabase db;
  final FakeFsmApi api;
  final TestClock clock;
  final FieldServiceStore store;
  final FieldServiceOutbox outbox;
  final LocalFieldServiceRepository repo;

  Future<void> seed() => repo.refresh();

  /// A report that passes the local validation for the corrective work order (every checklist point answered).
  Future<ServiceReportDraft> validDraft({String id = woCorrective}) async {
    for (final String item in <String>[
      'fault_diagnosis',
      'repair_verified',
      'functional_test',
    ]) {
      await repo.setChecklistResult(id, item, ChecklistResult.pass);
    }
    final FsmWorkOrderDetail detail = (await repo.watchDetail(id).first)!;
    return ServiceReportDraft(
      workPerformedSummary: 'Replaced the start capacitor',
      checklist: detail.checklist,
      laborHours: 1.5,
      travelHours: 0.5,
      travelKm: 24,
      applyCalloutFee: true,
      meterReadingHours: 1210,
      meterReadingCycles: 305,
      signerName: 'Mario Rossi',
      signerRole: 'Facility manager',
      signatureSvg: drawnSvg,
      signedAt: DateTime.utc(2030, 1, 1, 10),
      latitude: 46.0032,
      longitude: 8.9512,
      photos: detail.photos,
      locale: 'it-CH',
    );
  }

  Future<void> close() async {
    await store.dispose();
    await db.close();
  }
}
