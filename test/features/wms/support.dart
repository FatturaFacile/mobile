import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:fattura_facile/design/ff_tokens.dart';
import 'package:fattura_facile/features/wms/data/wms_repository.dart';
import 'package:fattura_facile/features/wms/models/transfer.dart';
import 'package:fattura_facile/l10n/ff_strings.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_test/flutter_test.dart' show WidgetTester, addTearDown;
import 'package:material_ui/material_ui.dart';

Map<String, dynamic> lineJson(
  String id, {
  String description = 'Widget',
  Object quantity = '10.0000',
  Object shipped = '10.0000',
  Object received = '0.0000',
  Object damaged = '0.0000',
}) => {
  'id': id,
  'product_id': 'p-$id',
  'description': description,
  'quantity': quantity,
  'shipped_qty': shipped,
  'received_qty': received,
  'damaged_qty': damaged,
  'discrepancy_qty': '0.0000',
};

Map<String, dynamic> transferJson({
  String id = 't1',
  String number = 'TR-001',
  String status = 'in_transit',
  String purpose = 'inter_warehouse',
  List<Map<String, dynamic>>? lines,
  List<Map<String, dynamic>> discrepancies = const [],
}) => {
  'id': id,
  'transfer_number': number,
  'purpose': purpose,
  'status': status,
  'origin_warehouse_id': 'w-main',
  'destination_warehouse_id': 'w-branch',
  'lines':
      lines ??
      [
        lineJson('l1', description: 'Widget'),
        lineJson('l2', description: 'Gadget', shipped: '5.0000'),
      ],
  'discrepancies': discrepancies,
};

Transfer buildTransfer({
  String status = 'in_transit',
  List<Map<String, dynamic>>? lines,
  String id = 't1',
}) => Transfer.fromJson(transferJson(status: status, lines: lines, id: id));

/// In-memory repository recording its calls.
class FakeWmsRepository implements WmsRepository {
  FakeWmsRepository({
    this.warehouseList = const [
      Warehouse(id: 'w-main', code: 'MAIN', name: 'Main'),
      Warehouse(id: 'w-branch', code: 'BR', name: 'Branch'),
    ],
    this.queues = const {},
  });

  final List<Warehouse> warehouseList;
  final Map<TransferDirection, List<Transfer>> queues;
  final List<String> calls = [];

  /// Code -> line id used by [scan]; unknown codes raise a 422.
  Map<String, String> codes = {};
  Transfer? transferResult;
  Transfer? shipResult;
  Transfer? receiveResult;
  ApiException? queueError;
  ApiException? shipError;
  ApiException? receiveError;
  List<ReceiptLineInput>? lastReceiptLines;
  bool? lastFinal;
  ShipmentInput? lastShipment;

  @override
  Future<List<Warehouse>> warehouses() async => warehouseList;

  @override
  Future<List<Transfer>> queue({
    required String warehouseId,
    required TransferDirection direction,
  }) async {
    calls.add('queue:$warehouseId:${direction.wire}');
    if (queueError != null) throw queueError!;
    return queues[direction] ?? const [];
  }

  @override
  Future<Transfer> transfer(String id) async {
    calls.add('transfer:$id');
    return transferResult ?? buildTransfer(id: id);
  }

  @override
  Future<ScanResult> scan(String transferId, String code) async {
    calls.add('scan:$code');
    final lineId = codes[code];
    if (lineId == null)
      throw const ApiException('Line not in transfer', statusCode: 422);
    final line = (transferResult ?? buildTransfer(id: transferId)).lineById(
      lineId,
    )!;
    return ScanResult(line: line, outstandingQty: line.outstandingQty);
  }

  @override
  Future<Transfer> ship(String transferId, ShipmentInput shipment) async {
    calls.add('ship:$transferId');
    lastShipment = shipment;
    if (shipError != null) throw shipError!;
    return shipResult ?? buildTransfer(status: 'in_transit', id: transferId);
  }

  @override
  Future<Transfer> receive(
    String transferId, {
    required bool finalReceipt,
    required List<ReceiptLineInput> lines,
  }) async {
    calls.add('receive:$transferId');
    lastFinal = finalReceipt;
    lastReceiptLines = lines;
    if (receiveError != null) throw receiveError!;
    return receiveResult ?? buildTransfer(status: 'received', id: transferId);
  }
}

/// Wraps [child] with theme and localizations like the real app does.
Widget testApp(Widget child, {Locale locale = const Locale('en')}) =>
    MaterialApp(
      theme: ffThemeData(),
      locale: locale,
      supportedLocales: FfStrings.supportedLocales,
      localizationsDelegates: const [
        FfStrings.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: child,
    );

/// Gives the test surface enough height for the whole (lazily built) list.
void useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}
