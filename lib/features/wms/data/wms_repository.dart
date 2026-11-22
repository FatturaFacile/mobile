import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/transfer.dart';

/// Connection settings shared by every request.
class ApiConfig {
  const ApiConfig({
    required this.baseUrl,
    required this.token,
    required this.tenantId,
    this.locale = 'en',
  });

  final String baseUrl;
  final String token;
  final String tenantId;
  final String locale;
}

/// Failure reported by the backend (e.g. 422 business rule) or by the transport.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.isNetwork = false});

  final String message;
  final int? statusCode;
  final bool isNetwork;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// One line of a receipt as sent to the API.
class ReceiptLineInput {
  const ReceiptLineInput({
    required this.lineId,
    required this.receivedQty,
    required this.damagedQty,
    this.reason,
  });

  final String lineId;
  final double receivedQty;
  final double damagedQty;
  final String? reason;

  Map<String, dynamic> toJson() {
    final trimmed = reason?.trim();
    return {
      'line_id': lineId,
      'received_qty': receivedQty,
      'damaged_qty': damagedQty,
      'discrepancy_reason': (trimmed == null || trimmed.isEmpty)
          ? null
          : trimmed,
    };
  }
}

/// Optional transport data of the dispatch confirmation.
class ShipmentInput {
  const ShipmentInput({
    this.carrierName,
    this.packagesCount,
    this.grossWeightKg,
  });

  final String? carrierName;
  final int? packagesCount;
  final double? grossWeightKg;

  Map<String, dynamic> toJson() {
    final name = carrierName?.trim();
    return {
      if (name != null && name.isNotEmpty) 'carrier_name': name,
      if (packagesCount != null) 'packages_count': packagesCount,
      if (grossWeightKg != null) 'gross_weight_kg': grossWeightKg,
    };
  }
}

/// Contract of the WMS API used by the operator screens (fakeable in tests).
abstract class WmsRepository {
  Future<List<Warehouse>> warehouses();
  Future<List<Transfer>> queue({
    required String warehouseId,
    required TransferDirection direction,
  });
  Future<Transfer> transfer(String id);
  Future<ScanResult> scan(String transferId, String code);
  Future<Transfer> ship(String transferId, ShipmentInput shipment);
  Future<Transfer> receive(
    String transferId, {
    required bool finalReceipt,
    required List<ReceiptLineInput> lines,
  });
}

/// HTTP implementation. The [http.Client] is injected so tests can swap it.
class HttpWmsRepository implements WmsRepository {
  HttpWmsRepository({required this.config, http.Client? client})
    : _client = client ?? http.Client();

  final ApiConfig config;
  final http.Client _client;

  Map<String, String> get _headers => {
    'Authorization': 'Bearer ${config.token}',
    'X-Tenant-Id': config.tenantId,
    'Accept': 'application/json',
    'Accept-Language': config.locale,
    'Content-Type': 'application/json',
  };

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = config.baseUrl.endsWith('/')
        ? config.baseUrl.substring(0, config.baseUrl.length - 1)
        : config.baseUrl;
    return Uri.parse('$base$path').replace(queryParameters: query);
  }

  @override
  Future<List<Warehouse>> warehouses() async {
    final data = await _send(
      'GET',
      _uri('/api/v1/logistics/lookups/warehouses'),
    );
    return _rows(data).map(Warehouse.fromJson).toList(growable: false);
  }

  @override
  Future<List<Transfer>> queue({
    required String warehouseId,
    required TransferDirection direction,
  }) async {
    // Outbound transfers wait for dispatch once approved; inbound ones wait for receipt once on the road.
    final statuses = direction == TransferDirection.outbound
        ? [TransferStatus.approved]
        : [TransferStatus.inTransit, TransferStatus.partiallyReceived];
    final data = await _send(
      'GET',
      _uri('/api/v1/wms/transfers', {
        'status': statuses.map((s) => s.wire).join(','),
        'warehouse_id': warehouseId,
        'direction': direction.wire,
      }),
    );
    return _rows(data).map(Transfer.fromJson).toList(growable: false);
  }

  @override
  Future<Transfer> transfer(String id) async {
    final data = await _send('GET', _uri('/api/v1/wms/transfers/$id'));
    return Transfer.fromJson(_row(data));
  }

  @override
  Future<ScanResult> scan(String transferId, String code) async {
    final data = await _send(
      'POST',
      _uri('/api/v1/wms/transfers/$transferId/scan'),
      body: {'code': code},
    );
    return ScanResult.fromJson(_row(data));
  }

  @override
  Future<Transfer> ship(String transferId, ShipmentInput shipment) async {
    final data = await _send(
      'POST',
      _uri('/api/v1/wms/transfers/$transferId/ship'),
      body: shipment.toJson(),
    );
    return Transfer.fromJson(_row(data));
  }

  @override
  Future<Transfer> receive(
    String transferId, {
    required bool finalReceipt,
    required List<ReceiptLineInput> lines,
  }) async {
    final data = await _send(
      'POST',
      _uri('/api/v1/wms/transfers/$transferId/receive'),
      body: {
        'final': finalReceipt,
        'lines': lines.map((l) => l.toJson()).toList(),
      },
    );
    return Transfer.fromJson(_row(data));
  }

  Future<Object?> _send(
    String method,
    Uri uri, {
    Map<String, dynamic>? body,
  }) async {
    final request = http.Request(method, uri)..headers.addAll(_headers);
    if (method != 'GET') request.body = jsonEncode(body ?? const {});
    final http.Response response;
    try {
      response = await http.Response.fromStream(await _client.send(request));
    } on Exception catch (e) {
      throw ApiException(e.toString(), isNetwork: true);
    }
    Object? decoded;
    try {
      decoded = response.body.isEmpty
          ? null
          : jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      decoded = null;
    }
    final map = decoded is Map ? decoded : const <String, dynamic>{};
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        map['success'] == false) {
      throw ApiException(
        (map['message'] ?? 'HTTP ${response.statusCode}').toString(),
        statusCode: response.statusCode,
      );
    }
    return map['data'];
  }

  Map<String, dynamic> _row(Object? data) {
    if (data is! Map) throw const ApiException('Unexpected response shape');
    return Map<String, dynamic>.from(data);
  }

  List<Map<String, dynamic>> _rows(Object? data) {
    if (data is! List) throw const ApiException('Unexpected response shape');
    return data
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList(growable: false);
  }

  void close() => _client.close();
}
