/// Domain models for WMS transfer orders, mirroring the Logistics API contract.
library;

/// Parses a decimal that the API may send as a string ("2.0000"), a number or null.
double parseDecimal(Object? value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString().trim()) ?? 0;
}

/// Rounds a quantity to the 4 decimals the backend stores, removing float noise.
double roundQty(double value) => (value * 10000).round() / 10000;

enum TransferPurpose {
  interWarehouse('inter_warehouse'),
  technicianVan('technician_van'),
  interCompany('inter_company'),
  customerConsignment('customer_consignment'),
  consignmentReturn('consignment_return'),
  subcontracting('subcontracting'),
  subcontractingReturn('subcontracting_return'),
  unknown('');

  const TransferPurpose(this.wire);
  final String wire;

  static TransferPurpose parse(Object? value) => TransferPurpose.values.firstWhere(
        (p) => p.wire == value,
        orElse: () => TransferPurpose.unknown,
      );
}

enum TransferStatus {
  draft('draft'),
  approved('approved'),
  inTransit('in_transit'),
  partiallyReceived('partially_received'),
  received('received'),
  discrepancyPending('discrepancy_pending'),
  closed('closed'),
  cancelled('cancelled'),
  unknown('');

  const TransferStatus(this.wire);
  final String wire;

  static TransferStatus parse(Object? value) => TransferStatus.values.firstWhere(
        (s) => s.wire == value,
        orElse: () => TransferStatus.unknown,
      );
}

/// Direction of a transfer relative to the selected warehouse.
enum TransferDirection {
  outbound('outbound'),
  inbound('inbound');

  const TransferDirection(this.wire);
  final String wire;
}

class TransferLine {
  const TransferLine({
    required this.id,
    required this.productId,
    required this.description,
    required this.quantity,
    required this.shippedQty,
    required this.receivedQty,
    required this.damagedQty,
    required this.discrepancyQty,
  });

  factory TransferLine.fromJson(Map<String, dynamic> json) => TransferLine(
        id: json['id'].toString(),
        productId: (json['product_id'] ?? '').toString(),
        description: (json['description'] ?? '').toString(),
        quantity: parseDecimal(json['quantity']),
        shippedQty: parseDecimal(json['shipped_qty']),
        receivedQty: parseDecimal(json['received_qty']),
        damagedQty: parseDecimal(json['damaged_qty']),
        discrepancyQty: parseDecimal(json['discrepancy_qty']),
      );

  final String id;
  final String productId;
  final String description;
  final double quantity;
  final double shippedQty;
  final double receivedQty;
  final double damagedQty;
  final double discrepancyQty;

  /// Quantity still expected at the destination: shipped - received - damaged.
  double get outstandingQty => roundQty(shippedQty - receivedQty - damagedQty);
}

class TransferDiscrepancy {
  const TransferDiscrepancy({
    required this.id,
    required this.shortageQty,
    required this.damageQty,
    required this.status,
  });

  factory TransferDiscrepancy.fromJson(Map<String, dynamic> json) => TransferDiscrepancy(
        id: json['id'].toString(),
        shortageQty: parseDecimal(json['shortage_qty']),
        damageQty: parseDecimal(json['damage_qty']),
        status: (json['status'] ?? '').toString(),
      );

  final String id;
  final double shortageQty;
  final double damageQty;
  final String status;
}

class Transfer {
  const Transfer({
    required this.id,
    required this.transferNumber,
    required this.purpose,
    required this.status,
    required this.originWarehouseId,
    required this.destinationWarehouseId,
    required this.lines,
    required this.discrepancies,
  });

  factory Transfer.fromJson(Map<String, dynamic> json) => Transfer(
        id: json['id'].toString(),
        transferNumber: (json['transfer_number'] ?? '').toString(),
        purpose: TransferPurpose.parse(json['purpose']),
        status: TransferStatus.parse(json['status']),
        originWarehouseId: json['origin_warehouse_id']?.toString(),
        destinationWarehouseId: json['destination_warehouse_id']?.toString(),
        lines: _list(json['lines']).map(TransferLine.fromJson).toList(growable: false),
        discrepancies: _list(json['discrepancies']).map(TransferDiscrepancy.fromJson).toList(growable: false),
      );

  final String id;
  final String transferNumber;
  final TransferPurpose purpose;
  final TransferStatus status;
  final String? originWarehouseId;
  final String? destinationWarehouseId;
  final List<TransferLine> lines;
  final List<TransferDiscrepancy> discrepancies;

  TransferLine? lineById(String lineId) {
    for (final line in lines) {
      if (line.id == lineId) return line;
    }
    return null;
  }
}

/// Result of resolving a scanned code to a transfer line.
class ScanResult {
  const ScanResult({required this.line, required this.outstandingQty});

  factory ScanResult.fromJson(Map<String, dynamic> json) => ScanResult(
        line: TransferLine.fromJson(Map<String, dynamic>.from(json['line'] as Map)),
        outstandingQty: parseDecimal(json['outstanding_qty']),
      );

  final TransferLine line;
  final double outstandingQty;
}

/// Warehouse entry from the lookups endpoint.
class Warehouse {
  const Warehouse({required this.id, required this.code, required this.name});

  factory Warehouse.fromJson(Map<String, dynamic> json) => Warehouse(
        id: json['id'].toString(),
        code: (json['code'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
      );

  final String id;
  final String code;
  final String name;

  String get label => name.isEmpty ? code : '$code - $name';
}

List<Map<String, dynamic>> _list(Object? value) {
  if (value is! List) return const [];
  return value.map((e) => Map<String, dynamic>.from(e as Map)).toList(growable: false);
}
