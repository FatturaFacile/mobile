import 'package:flutter/foundation.dart';

/// RBAC module key of the physical-inventory counting (warehouse role).
const String inventoryCountModule = 'inventory_counts';

/// Parses a JSON number that Laravel may serialise as a string (decimal casts).
double? parseQuantity(Object? raw) {
  if (raw is num) {
    return raw.toDouble();
  }
  if (raw is String) {
    return double.tryParse(raw.replaceAll(',', '.'));
  }
  return null;
}

/// Renders a quantity without a trailing `.0`.
String formatQuantity(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value
      .toStringAsFixed(3)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

String? _text(Object? raw) {
  if (raw == null) {
    return null;
  }
  final String s = '$raw';
  return s.isEmpty ? null : s;
}

/// A count session assigned to the signed-in user.
///
/// Blind by construction: only the fields below are ever read from the API answer, so no system quantity, cost or
/// variance can reach the device even if a server version started sending them.
@immutable
class CountSession {
  const CountSession({
    required this.id,
    required this.sessionNumber,
    this.warehouseId,
    this.warehouseZoneId,
    this.warehouseName,
    this.zoneName,
    this.countType,
    this.status,
    this.scheduledDate,
    this.isBlind = true,
    this.freezesStock = false,
    this.frozenAt,
    this.countedLines = 0,
    this.totalLines = 0,
    this.pendingEntries = 0,
  });

  factory CountSession.fromJson(Map<String, dynamic> json) {
    final Object? warehouse = json['warehouse'];
    final Object? zone = json['warehouse_zone'] ?? json['zone'];
    return CountSession(
      id: '${json['id']}',
      sessionNumber: _text(json['session_number']) ?? '${json['id']}',
      warehouseId: _text(json['warehouse_id']),
      warehouseZoneId: _text(json['warehouse_zone_id']),
      warehouseName: warehouse is Map ? _text(warehouse['name']) : null,
      zoneName: zone is Map ? _text(zone['name']) : null,
      countType: _text(json['count_type']),
      status: _text(json['status']),
      scheduledDate: _text(json['scheduled_date']),
      isBlind: json['is_blind'] != false,
      freezesStock: json['freezes_stock'] == true,
      frozenAt: _text(json['frozen_at']),
    );
  }

  final String id;
  final String sessionNumber;
  final String? warehouseId;
  final String? warehouseZoneId;
  final String? warehouseName;
  final String? zoneName;
  final String? countType;
  final String? status;
  final String? scheduledDate;
  final bool isBlind;
  final bool freezesStock;
  final String? frozenAt;

  /// Local progress, filled in by the repository from the cached sheet and the pending entries.
  final int countedLines;
  final int totalLines;
  final int pendingEntries;

  bool get isFrozen => freezesStock && frozenAt != null;

  CountSession withProgress({
    required int counted,
    required int total,
    required int pending,
  }) => CountSession(
    id: id,
    sessionNumber: sessionNumber,
    warehouseId: warehouseId,
    warehouseZoneId: warehouseZoneId,
    warehouseName: warehouseName,
    zoneName: zoneName,
    countType: countType,
    status: status,
    scheduledDate: scheduledDate,
    isBlind: isBlind,
    freezesStock: freezesStock,
    frozenAt: frozenAt,
    countedLines: counted,
    totalLines: total,
    pendingEntries: pending,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'session_number': sessionNumber,
    'warehouse_id': warehouseId,
    'warehouse_zone_id': warehouseZoneId,
    'warehouse': warehouseName == null
        ? null
        : <String, dynamic>{'name': warehouseName},
    'warehouse_zone': zoneName == null
        ? null
        : <String, dynamic>{'name': zoneName},
    'count_type': countType,
    'status': status,
    'scheduled_date': scheduledDate,
    'is_blind': isBlind,
    'freezes_stock': freezesStock,
    'frozen_at': frozenAt,
  };
}

/// Lifecycle of a count entry typed on the device.
enum EntryStatus {
  /// Saved locally, not sent yet (or sent without an answer).
  pending,

  /// The server accepted it.
  recorded,

  /// The server accepted it but asked for another count of the line.
  recountRequired,

  /// The server refused it (for example the line was counted by someone else); the server value stands.
  rejected;

  static EntryStatus parse(String? raw) => switch (raw) {
    'recorded' => EntryStatus.recorded,
    'recount_required' => EntryStatus.recountRequired,
    'rejected' => EntryStatus.rejected,
    _ => EntryStatus.pending,
  };

  String get wire => switch (this) {
    EntryStatus.pending => 'pending',
    EntryStatus.recorded => 'recorded',
    EntryStatus.recountRequired => 'recount_required',
    EntryStatus.rejected => 'rejected',
  };
}

/// One quantity typed by the operator, kept in the local outbox until the server answers.
@immutable
class CountEntry {
  const CountEntry({
    required this.clientEntryId,
    required this.sessionId,
    required this.sessionLineId,
    required this.countedQuantity,
    required this.createdAt,
    this.notes,
    this.status = EntryStatus.pending,
    this.recountRound,
    this.message,
    this.attempts = 0,
  });

  factory CountEntry.fromJson(Map<String, dynamic> json) => CountEntry(
    clientEntryId: '${json['client_entry_id']}',
    sessionId: '${json['session_id']}',
    sessionLineId: '${json['session_line_id']}',
    countedQuantity: parseQuantity(json['counted_quantity']) ?? 0,
    createdAt:
        DateTime.tryParse('${json['created_at']}') ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    notes: _text(json['notes']),
    status: EntryStatus.parse(_text(json['status'])),
    recountRound: json['recount_round'] is num
        ? (json['recount_round'] as num).toInt()
        : null,
    message: _text(json['message']),
    attempts: json['attempts'] is num ? (json['attempts'] as num).toInt() : 0,
  );

  final String clientEntryId;
  final String sessionId;
  final String sessionLineId;
  final double countedQuantity;
  final DateTime createdAt;
  final String? notes;
  final EntryStatus status;
  final int? recountRound;
  final String? message;
  final int attempts;

  bool get isPending => status == EntryStatus.pending;

  CountEntry copyWith({
    EntryStatus? status,
    int? recountRound,
    String? message,
    int? attempts,
  }) => CountEntry(
    clientEntryId: clientEntryId,
    sessionId: sessionId,
    sessionLineId: sessionLineId,
    countedQuantity: countedQuantity,
    createdAt: createdAt,
    notes: notes,
    status: status ?? this.status,
    recountRound: recountRound ?? this.recountRound,
    message: message ?? this.message,
    attempts: attempts ?? this.attempts,
  );

  /// Body item of `POST counts/{id}/record-counts`.
  Map<String, dynamic> toWire() => <String, dynamic>{
    'client_entry_id': clientEntryId,
    'session_line_id': sessionLineId,
    'counted_quantity': countedQuantity,
    'notes': ?notes,
  };

  Map<String, dynamic> toJson() => <String, dynamic>{
    'client_entry_id': clientEntryId,
    'session_id': sessionId,
    'session_line_id': sessionLineId,
    'counted_quantity': countedQuantity,
    'created_at': createdAt.toUtc().toIso8601String(),
    'notes': notes,
    'status': status.wire,
    'recount_round': recountRound,
    'message': message,
    'attempts': attempts,
  };
}

/// A line of the blind count sheet.
///
/// There is deliberately no system quantity, unit cost, variance or expected stock here (the sheet API never returns
/// them); [firstCountedQuantity] is only set when the server policy reveals the previous count.
@immutable
class CountLine {
  const CountLine({
    required this.id,
    required this.sessionId,
    this.warehouseBinId,
    this.binBarcode,
    this.stockItemId,
    this.sku,
    this.itemName,
    this.barcode,
    this.lotId,
    this.countedQuantity,
    this.isCounted = false,
    this.recountRequired = false,
    this.recountRound = 0,
    this.recountReason,
    this.notes,
    this.countedAt,
    this.firstCountedQuantity,
    this.entry,
  });

  factory CountLine.fromJson(
    Map<String, dynamic> json, {
    required String sessionId,
  }) => CountLine(
    id: '${json['id']}',
    sessionId: sessionId,
    warehouseBinId: _text(json['warehouse_bin_id']),
    binBarcode: _text(json['bin_barcode']),
    stockItemId: _text(json['stock_item_id']),
    sku: _text(json['sku']),
    itemName: _text(json['item_name']),
    barcode: _text(json['barcode']),
    lotId: _text(json['lot_id']),
    countedQuantity: parseQuantity(json['counted_quantity']),
    isCounted: json['is_counted'] == true,
    recountRequired: json['recount_required'] == true,
    recountRound: json['recount_round'] is num
        ? (json['recount_round'] as num).toInt()
        : 0,
    recountReason: _text(json['recount_reason']),
    notes: _text(json['notes']),
    countedAt: _text(json['counted_at']),
    firstCountedQuantity: parseQuantity(json['first_counted_quantity']),
  );

  final String id;
  final String sessionId;
  final String? warehouseBinId;
  final String? binBarcode;
  final String? stockItemId;
  final String? sku;
  final String? itemName;
  final String? barcode;
  final String? lotId;
  final double? countedQuantity;
  final bool isCounted;
  final bool recountRequired;
  final int recountRound;
  final String? recountReason;
  final String? notes;
  final String? countedAt;
  final double? firstCountedQuantity;

  /// Latest entry typed on this device for the line (overlay computed by the repository, never persisted here).
  final CountEntry? entry;

  /// Waiting for the server answer.
  bool get pendingSync => entry?.isPending ?? false;

  /// The last attempt from this device was refused by the server.
  bool get rejected => entry?.status == EntryStatus.rejected;

  /// Counted from the operator's point of view (server state or an entry waiting to sync).
  bool get doneForOperator => !recountRequired && (isCounted || pendingSync);

  /// Needs a (re)count: never counted, or flagged for a recount.
  bool get toCount => !doneForOperator;

  /// Quantity the operator typed or the server holds for the own count; hidden while a recount is requested so the
  /// previous value cannot bias the new count.
  double? get shownQuantity {
    if (recountRequired) {
      return null;
    }
    return entry != null && entry!.status != EntryStatus.rejected
        ? entry!.countedQuantity
        : countedQuantity;
  }

  /// True when [query] (already lower-cased and trimmed) matches the bin, SKU, item name, barcode or bin barcode.
  bool matches(String query) {
    if (query.isEmpty) {
      return true;
    }
    for (final String? v in <String?>[
      sku,
      itemName,
      barcode,
      binBarcode,
      lotId,
    ]) {
      if (v != null && v.toLowerCase().contains(query)) {
        return true;
      }
    }
    return false;
  }

  CountLine withEntry(CountEntry? e) => CountLine(
    id: id,
    sessionId: sessionId,
    warehouseBinId: warehouseBinId,
    binBarcode: binBarcode,
    stockItemId: stockItemId,
    sku: sku,
    itemName: itemName,
    barcode: barcode,
    lotId: lotId,
    countedQuantity: countedQuantity,
    isCounted: isCounted,
    recountRequired: e?.status == EntryStatus.recountRequired
        ? true
        : recountRequired,
    recountRound: e?.status == EntryStatus.recountRequired
        ? (e?.recountRound ?? recountRound)
        : recountRound,
    recountReason: recountReason,
    notes: notes,
    countedAt: countedAt,
    firstCountedQuantity: firstCountedQuantity,
    entry: e,
  );

  /// Persisted shape: a whitelist, so nothing but the blind fields is ever stored.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'warehouse_bin_id': warehouseBinId,
    'bin_barcode': binBarcode,
    'stock_item_id': stockItemId,
    'sku': sku,
    'item_name': itemName,
    'barcode': barcode,
    'lot_id': lotId,
    'counted_quantity': countedQuantity,
    'is_counted': isCounted,
    'recount_required': recountRequired,
    'recount_round': recountRound,
    'recount_reason': recountReason,
    'notes': notes,
    'counted_at': countedAt,
    'first_counted_quantity': firstCountedQuantity,
  };
}

/// Outcome of one flush of the pending entries.
@immutable
class CountSyncReport {
  const CountSyncReport({
    this.recorded = 0,
    this.recountRequired = 0,
    this.rejected = 0,
    this.stillPending = 0,
    this.offline = false,
    this.affectedSessionIds = const <String>{},
  });

  final int recorded;
  final int recountRequired;
  final int rejected;
  final int stillPending;

  /// The network was unreachable: nothing was lost, the entries stay queued.
  final bool offline;
  final Set<String> affectedSessionIds;

  int get sent => recorded + recountRequired + rejected;
}

enum CountErrorKind { offline, forbidden, notFound, invalid, unknown }

/// Failure of a call to the counting API.
class CountException implements Exception {
  const CountException(this.kind, {this.detail = ''});

  final CountErrorKind kind;
  final String detail;

  @override
  String toString() => 'CountException($kind, $detail)';
}
