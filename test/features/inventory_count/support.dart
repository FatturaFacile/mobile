import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:fattura_facile/core/database/app_database.dart';
import 'package:fattura_facile/core/localization/translation_service.dart';
import 'package:fattura_facile/features/inventory_count/data/inventory_count_repository.dart';

import '../../core/sync_engine_test.dart' show FakeAdapter, json;

/// Dictionary entries the screens read (the real ones are served by the API seeders).
const Map<String, String> inventoryCountDictionary = <String, String>{
  'mobile.inventory_count.my_counts': 'My counts',
  'mobile.inventory_count.no_counts': 'No counts assigned',
  'mobile.inventory_count.blind_notice':
      'Blind count: the system stock is not shown',
  'mobile.inventory_count.scan_or_search': 'Scan or search item / location',
  'mobile.inventory_count.counted_quantity': 'Counted quantity',
  'mobile.inventory_count.notes': 'Notes',
  'mobile.inventory_count.save_count': 'Save count',
  'mobile.inventory_count.recount_required': 'Recount required',
  'mobile.inventory_count.recount_hint':
      'Count again without looking at the previous value',
  'mobile.inventory_count.recount_round': 'Round {round}',
  'mobile.inventory_count.counted': 'Counted',
  'mobile.inventory_count.to_count': 'To count',
  'mobile.inventory_count.filter_all': 'All',
  'mobile.inventory_count.queued_offline': 'Saved on the device: it will sync',
  'mobile.inventory_count.sync_pending': '{count} counts to sync',
  'mobile.inventory_count.sync_now': 'Sync now',
  'mobile.inventory_count.sync_done': 'Sync completed',
  'mobile.inventory_count.sync_error': 'Sync failed: try again',
  'mobile.inventory_count.rejected': 'Count rejected by the server',
  'mobile.inventory_count.conflict_server_wins':
      'Line already counted by someone else: the server value stands',
  'mobile.inventory_count.frozen': 'Stock frozen',
  'mobile.inventory_count.progress': '{counted} / {total}',
  'mobile.inventory_count.pending_sync': 'Waiting to sync',
  'mobile.inventory_count.count_saved': 'Count saved',
  'mobile.inventory_count.dismiss': 'Dismiss',
  'mobile.inventory_count.no_lines': 'No lines to count',
  'mobile.inventory_count.no_match': 'No line matches the search',
  'mobile.inventory_count.quantity_invalid': 'Enter a valid quantity',
  'mobile.inventory_count.first_count': 'First count',
  'mobile.inventory_count.warehouse': 'Warehouse',
};

const String tenant = 't1';

Map<String, dynamic> sessionJson(String id, {bool frozen = true}) =>
    <String, dynamic>{
      'id': id,
      'session_number': 'INV-$id',
      'warehouse_id': 'w1',
      'warehouse_zone_id': null,
      'count_type': 'full',
      'status': 'in_progress',
      'scheduled_date': '2030-01-10',
      'is_blind': true,
      'freezes_stock': frozen,
      'frozen_at': frozen ? '2030-01-10T08:00:00Z' : null,
      'assigned_to': 'u1',
      'warehouse': <String, dynamic>{'id': 'w1', 'name': 'Main warehouse'},
    };

/// A sheet line as the API returns it. The `extra` map lets a test smuggle in forbidden fields.
Map<String, dynamic> lineJson(
  String id, {
  String sku = 'SKU-1',
  String name = 'Widget',
  String bin = 'BIN-A1',
  bool counted = false,
  double? quantity,
  bool recount = false,
  int round = 0,
  double? first,
  Map<String, dynamic> extra = const <String, dynamic>{},
}) => <String, dynamic>{
  'id': id,
  'warehouse_bin_id': 'b-$id',
  'bin_barcode': bin,
  'stock_item_id': 'i-$id',
  'sku': sku,
  'item_name': name,
  'barcode': 'EAN-$id',
  'lot_id': null,
  'counted_quantity': quantity,
  'is_counted': counted,
  'recount_required': recount,
  'recount_round': round,
  'recount_reason': recount ? 'variance' : null,
  'notes': null,
  'counted_at': null,
  'first_counted_quantity': ?first,
  ...extra,
};

class CountFixture {
  CountFixture() {
    db = AppDatabase(NativeDatabase.memory());
    adapter = FakeAdapter(
      (RequestOptions o) => json(200, <String, dynamic>{'data': <dynamic>[]}),
    );
    dio = Dio(
      BaseOptions(
        baseUrl: 'http://x/api/v1',
        validateStatus: (int? s) => s != null && s < 300,
      ),
    )..httpClientAdapter = adapter;
    repo = InventoryCountRepository(db, dio);
  }

  late final AppDatabase db;
  late final FakeAdapter adapter;
  late final Dio dio;
  late final InventoryCountRepository repo;

  Future<TranslationService> translations() async {
    await db.batch((b) {
      b.insertAll(
        db.translations,
        inventoryCountDictionary.entries.map(
          (e) => TranslationsCompanion.insert(
            locale: 'en',
            key: e.key,
            value: e.value,
            tenantId: const Value<String>(''),
          ),
        ),
      );
    });
    final TranslationService service = TranslationService(db, Dio());
    await service.load('en');
    return service;
  }

  /// Routes by path; `sheet` and `assigned` answer the GETs, `record` answers the batch POST.
  void route({
    List<Map<String, dynamic>> sessions = const <Map<String, dynamic>>[],
    List<Map<String, dynamic>> sheet = const <Map<String, dynamic>>[],
    ResponseBody Function(RequestOptions o)? record,
  }) {
    adapter.handler = (RequestOptions o) {
      if (o.path.endsWith('/assigned')) {
        return json(200, <String, dynamic>{'data': sessions});
      }
      if (o.path.endsWith('/sheet')) {
        return json(200, <String, dynamic>{
          'session': sessions.isEmpty ? null : sessions.first,
          'data': sheet,
        });
      }
      if (o.path.endsWith('/record-counts')) {
        return record!(o);
      }
      return json(404, <String, dynamic>{'message': 'not found'});
    };
  }

  /// Answers every entry of the batch with [status].
  static ResponseBody Function(RequestOptions) answer(
    String status, {
    int? round,
    String? message,
  }) =>
      (RequestOptions o) => json(200, <String, dynamic>{
        'data': <Map<String, dynamic>>[
          for (final dynamic e
              in (o.data as Map<String, dynamic>)['entries'] as List<dynamic>)
            <String, dynamic>{
              'client_entry_id': (e as Map<String, dynamic>)['client_entry_id'],
              'session_line_id': e['session_line_id'],
              'status': status,
              'recount_round': ?round,
              'message': ?message,
            },
        ],
      });

  Future<void> dispose() => db.close();
}
