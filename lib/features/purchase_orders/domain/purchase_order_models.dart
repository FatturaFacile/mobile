import 'package:flutter/foundation.dart';

import '../../supplier_rebates/domain/rebate_decimal.dart';

/// RBAC module keys that unlock the purchase order workspace (Mod 046).
const String purchaseOrdersModule = 'purchase_orders';
const Set<String> purchaseOrdersModules = <String>{
  purchaseOrdersModule,
  'procurement_orders',
};

final Dec _one = Dec.parse(1);

String _str(Object? v) => v == null ? '' : '$v';

String? _strOrNull(Object? v) {
  final String s = _str(v).trim();
  return s.isEmpty ? null : s;
}

Dec _dec(Object? v) => Dec.parse(v);

Dec? _decOrNull(Object? v) => Dec.tryParse(v);

bool _bool(Object? v) => v == true || v == 1 || v == '1' || v == 'true';

int _int(Object? v) => v is int ? v : int.tryParse('$v') ?? 0;

DateTime? _date(Object? v) {
  final String s = _str(v);
  return s.isEmpty ? null : DateTime.tryParse(s);
}

Map<String, dynamic> _map(Object? v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

List<Map<String, dynamic>> _maps(Object? v) => <Map<String, dynamic>>[
  if (v is List)
    for (final dynamic e in v)
      if (e is Map) Map<String, dynamic>.from(e),
];

List<Dec> _decs(Object? v) => <Dec>[
  if (v is List)
    for (final dynamic d in v)
      if (Dec.tryParse(d) != null) Dec.parse(d),
];

/// `2026-11-23` for a date-only wire field.
String? _wireDate(DateTime? d) => d == null
    ? null
    : '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Lifecycle of a purchase order. Unknown server values keep the raw text in [PurchaseOrder.rawStatus].
enum PoStatus {
  draft('draft'),
  pendingApproval('pending_approval'),
  approved('approved'),
  sent('sent'),
  confirmed('confirmed'),
  partiallyReceived('partially_received'),
  received('received'),
  closed('closed'),
  cancelled('cancelled'),
  unknown('');

  const PoStatus(this.wire);

  final String wire;

  static PoStatus fromWire(Object? raw) => values.firstWhere(
    (PoStatus s) => s.wire == '$raw' && s != unknown,
    orElse: () => unknown,
  );

  /// Orders the supplier still owes goods for: the ones the overdue radar watches (backend `OpenStatuses`).
  bool get isOpenForDelivery =>
      this == sent || this == confirmed || this == partiallyReceived;

  /// A transmitted order can be confirmed by the supplier (and re-confirmed with a revised date).
  bool get canConfirm => this == sent || this == confirmed;
}

/// One order line with the dual unit of measure of Mod 046.
@immutable
class PoLine {
  const PoLine({
    required this.id,
    this.lineNumber = 0,
    this.description = '',
    this.quantityOrdered,
    this.quantityReceived,
    this.uom = '',
    this.baseUom = '',
    this.uomConversionFactor,
    this.quantityBaseOrdered,
    this.quantityBaseReceived,
    this.quantityConfirmed,
    this.discountCascade = const <Dec>[],
    this.discountPercentEffective,
    this.confirmedDeliveryDate,
    this.promisedDeliveryDate,
    this.unitPrice,
    this.taxRate,
    this.lineNetAmount,
    this.isClosed = false,
  });

  factory PoLine.fromJson(Map<String, dynamic> j) => PoLine(
    id: _str(j['id']),
    lineNumber: _int(j['line_number']),
    description: _str(j['description']),
    quantityOrdered: _decOrNull(j['quantity_ordered']),
    quantityReceived: _decOrNull(j['quantity_received']),
    uom: _str(j['uom']),
    baseUom: _str(j['base_uom']),
    uomConversionFactor: _decOrNull(j['uom_conversion_factor']),
    quantityBaseOrdered: _decOrNull(j['quantity_base_ordered']),
    quantityBaseReceived: _decOrNull(j['quantity_base_received']),
    quantityConfirmed: _decOrNull(j['quantity_confirmed']),
    discountCascade: _decs(j['discount_cascade']),
    discountPercentEffective: _decOrNull(j['discount_percent_effective']),
    confirmedDeliveryDate: _date(j['confirmed_delivery_date']),
    promisedDeliveryDate: _date(j['promised_delivery_date']),
    unitPrice: _decOrNull(j['unit_price']),
    taxRate: _decOrNull(j['tax_rate']),
    lineNetAmount: _decOrNull(j['line_net_amount']),
    isClosed: _bool(j['is_closed']),
  );

  final String id;
  final int lineNumber;
  final String description;
  final Dec? quantityOrdered;
  final Dec? quantityReceived;

  /// Purchase unit of measure (`BOX`).
  final String uom;

  /// Stock unit of measure (`PCS`) and how many of it one [uom] holds.
  final String baseUom;
  final Dec? uomConversionFactor;
  final Dec? quantityBaseOrdered;
  final Dec? quantityBaseReceived;
  final Dec? quantityConfirmed;

  /// Successive discounts in percent (`[10, 5]` = 10% then 5% on the remainder).
  final List<Dec> discountCascade;
  final Dec? discountPercentEffective;
  final DateTime? confirmedDeliveryDate;
  final DateTime? promisedDeliveryDate;
  final Dec? unitPrice;
  final Dec? taxRate;
  final Dec? lineNetAmount;
  final bool isClosed;

  /// The line is bought in a unit that differs from the stock unit, so both quantities are shown.
  bool get isDualUom =>
      baseUom.isNotEmpty &&
      uom.isNotEmpty &&
      baseUom != uom &&
      (uomConversionFactor ?? _one) != _one;

  /// Ordered quantity in the stock unit; derived from the factor when the server did not send it.
  Dec? get orderedBase {
    if (quantityBaseOrdered != null) {
      return quantityBaseOrdered;
    }
    final Dec? q = quantityOrdered;
    final Dec? f = uomConversionFactor;
    return q == null || f == null ? q : q * f;
  }

  /// The date the supplier is due to deliver: the line promise, then its confirmation.
  DateTime? get dueDate => promisedDeliveryDate ?? confirmedDeliveryDate;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'line_number': lineNumber,
    'description': description,
    'quantity_ordered': quantityOrdered?.toPlain(),
    'quantity_received': quantityReceived?.toPlain(),
    'uom': uom,
    'base_uom': baseUom,
    'uom_conversion_factor': uomConversionFactor?.toPlain(),
    'quantity_base_ordered': quantityBaseOrdered?.toPlain(),
    'quantity_base_received': quantityBaseReceived?.toPlain(),
    'quantity_confirmed': quantityConfirmed?.toPlain(),
    'discount_cascade': <String>[
      for (final Dec d in discountCascade) d.toPlain(),
    ],
    'discount_percent_effective': discountPercentEffective?.toPlain(),
    'confirmed_delivery_date': _wireDate(confirmedDeliveryDate),
    'promised_delivery_date': _wireDate(promisedDeliveryDate),
    'unit_price': unitPrice?.toPlain(),
    'tax_rate': taxRate?.toPlain(),
    'line_net_amount': lineNetAmount?.toPlain(),
    'is_closed': isClosed,
  };

  PoLine copyWith({
    Dec? quantityConfirmed,
    Dec? unitPrice,
    DateTime? confirmedDeliveryDate,
    DateTime? promisedDeliveryDate,
  }) => PoLine(
    id: id,
    lineNumber: lineNumber,
    description: description,
    quantityOrdered: quantityOrdered,
    quantityReceived: quantityReceived,
    uom: uom,
    baseUom: baseUom,
    uomConversionFactor: uomConversionFactor,
    quantityBaseOrdered: quantityBaseOrdered,
    quantityBaseReceived: quantityBaseReceived,
    quantityConfirmed: quantityConfirmed ?? this.quantityConfirmed,
    discountCascade: discountCascade,
    discountPercentEffective: discountPercentEffective,
    confirmedDeliveryDate: confirmedDeliveryDate ?? this.confirmedDeliveryDate,
    promisedDeliveryDate: promisedDeliveryDate ?? this.promisedDeliveryDate,
    unitPrice: unitPrice ?? this.unitPrice,
    taxRate: taxRate,
    lineNetAmount: lineNetAmount,
    isClosed: isClosed,
  );
}

@immutable
class PurchaseOrder {
  const PurchaseOrder({
    required this.id,
    this.poNumber = '',
    this.supplierId = '',
    this.supplierName = '',
    this.rawStatus = '',
    this.status = PoStatus.unknown,
    this.orderDate,
    this.expectedDeliveryDate,
    this.promisedDeliveryDate,
    this.currency = 'CHF',
    this.netAmount,
    this.totalAmount,
    this.isDropship = false,
    this.salesOrderId,
    this.supplierConfirmationNumber,
    this.confirmedAt,
    this.reminderCount = 0,
    this.lastReminderAt,
    this.notes = '',
    this.lines = const <PoLine>[],
  });

  factory PurchaseOrder.fromJson(Map<String, dynamic> j) {
    final String raw = _str(j['status']);
    return PurchaseOrder(
      id: _str(j['id']),
      poNumber: _str(j['po_number']),
      supplierId: _str(j['supplier_id']),
      supplierName: _str(_map(j['supplier'])['name'] ?? j['supplier_name']),
      rawStatus: raw,
      status: PoStatus.fromWire(raw),
      orderDate: _date(j['order_date']),
      expectedDeliveryDate: _date(j['expected_delivery_date']),
      promisedDeliveryDate: _date(j['promised_delivery_date']),
      currency: _strOrNull(j['currency']) ?? 'CHF',
      netAmount: _decOrNull(j['net_amount']),
      totalAmount: _decOrNull(j['total_amount']),
      isDropship: _bool(j['is_dropship']),
      salesOrderId: _strOrNull(j['sales_order_id']),
      supplierConfirmationNumber: _strOrNull(j['supplier_confirmation_number']),
      confirmedAt: _date(j['confirmed_at']),
      reminderCount: _int(j['reminder_count']),
      lastReminderAt: _date(j['last_reminder_at']),
      notes: _str(j['notes']),
      lines: <PoLine>[
        for (final Map<String, dynamic> l in _maps(j['lines']))
          PoLine.fromJson(l),
      ],
    );
  }

  final String id;
  final String poNumber;
  final String supplierId;
  final String supplierName;
  final String rawStatus;
  final PoStatus status;
  final DateTime? orderDate;
  final DateTime? expectedDeliveryDate;

  /// Delivery date the supplier committed to when confirming.
  final DateTime? promisedDeliveryDate;
  final String currency;
  final Dec? netAmount;
  final Dec? totalAmount;
  final bool isDropship;
  final String? salesOrderId;
  final String? supplierConfirmationNumber;
  final DateTime? confirmedAt;
  final int reminderCount;
  final DateTime? lastReminderAt;
  final String notes;
  final List<PoLine> lines;

  /// Date an open line is due: its own promise, then the order promise, then the requested date.
  DateTime? dueDateOf(PoLine line) =>
      line.dueDate ?? promisedDeliveryDate ?? expectedDeliveryDate;

  /// Open lines whose due date is before [today]; empty unless the order is waiting for goods.
  List<PoLine> overdueLines(DateTime today) {
    if (!status.isOpenForDelivery) {
      return const <PoLine>[];
    }
    final DateTime t = _dayOnly(today);
    return <PoLine>[
      for (final PoLine l in lines)
        if (!l.isClosed &&
            dueDateOf(l) != null &&
            _dayOnly(dueDateOf(l)!).isBefore(t))
          l,
    ];
  }

  /// Days the latest line is overdue (0 when none is).
  int daysOverdue(DateTime today) {
    int worst = 0;
    for (final PoLine l in overdueLines(today)) {
      final int d = _dayOnly(today).difference(_dayOnly(dueDateOf(l)!)).inDays;
      if (d > worst) {
        worst = d;
      }
    }
    return worst;
  }

  bool isOverdue(DateTime today) => overdueLines(today).isNotEmpty;

  /// Any line is bought in a unit other than the stock unit.
  bool get hasDualUom => lines.any((PoLine l) => l.isDualUom);

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'po_number': poNumber,
    'supplier_id': supplierId,
    'supplier': <String, dynamic>{'name': supplierName},
    'status': rawStatus,
    'order_date': _wireDate(orderDate),
    'expected_delivery_date': _wireDate(expectedDeliveryDate),
    'promised_delivery_date': _wireDate(promisedDeliveryDate),
    'currency': currency,
    'net_amount': netAmount?.toPlain(),
    'total_amount': totalAmount?.toPlain(),
    'is_dropship': isDropship,
    'sales_order_id': salesOrderId,
    'supplier_confirmation_number': supplierConfirmationNumber,
    'confirmed_at': confirmedAt?.toIso8601String(),
    'reminder_count': reminderCount,
    'last_reminder_at': lastReminderAt?.toIso8601String(),
    'notes': notes,
    'lines': <Map<String, dynamic>>[for (final PoLine l in lines) l.toJson()],
  };

  PurchaseOrder copyWith({
    String? rawStatus,
    PoStatus? status,
    DateTime? promisedDeliveryDate,
    String? supplierConfirmationNumber,
    DateTime? confirmedAt,
    int? reminderCount,
    DateTime? lastReminderAt,
    List<PoLine>? lines,
  }) => PurchaseOrder(
    id: id,
    poNumber: poNumber,
    supplierId: supplierId,
    supplierName: supplierName,
    rawStatus: rawStatus ?? this.rawStatus,
    status: status ?? this.status,
    orderDate: orderDate,
    expectedDeliveryDate: expectedDeliveryDate,
    promisedDeliveryDate: promisedDeliveryDate ?? this.promisedDeliveryDate,
    currency: currency,
    netAmount: netAmount,
    totalAmount: totalAmount,
    isDropship: isDropship,
    salesOrderId: salesOrderId,
    supplierConfirmationNumber:
        supplierConfirmationNumber ?? this.supplierConfirmationNumber,
    confirmedAt: confirmedAt ?? this.confirmedAt,
    reminderCount: reminderCount ?? this.reminderCount,
    lastReminderAt: lastReminderAt ?? this.lastReminderAt,
    notes: notes,
    lines: lines ?? this.lines,
  );
}

/// Row of `GET purchase-orders/overdue`.
@immutable
class OverdueOrder {
  const OverdueOrder({
    required this.order,
    this.daysOverdue = 0,
    this.overdueLineIds = const <String>[],
    this.reminderCount = 0,
    this.lastReminderAt,
    this.nextReminderDue = false,
  });

  factory OverdueOrder.fromJson(Map<String, dynamic> j) => OverdueOrder(
    order: PurchaseOrder.fromJson(_map(j['order'])),
    daysOverdue: _int(j['days_overdue']),
    overdueLineIds: <String>[
      if (j['overdue_line_ids'] is List)
        for (final dynamic id in j['overdue_line_ids'] as List<dynamic>) '$id',
    ],
    reminderCount: _int(j['reminder_count']),
    lastReminderAt: _date(j['last_reminder_at']),
    nextReminderDue: _bool(j['next_reminder_due']),
  );

  final PurchaseOrder order;
  final int daysOverdue;
  final List<String> overdueLineIds;
  final int reminderCount;
  final DateTime? lastReminderAt;

  /// The reminder interval elapsed: the buyer may send the next level now.
  final bool nextReminderDue;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'order': order.toJson(),
    'days_overdue': daysOverdue,
    'overdue_line_ids': overdueLineIds,
    'reminder_count': reminderCount,
    'last_reminder_at': lastReminderAt?.toIso8601String(),
    'next_reminder_due': nextReminderDue,
  };
}

/// What the supplier confirmed for one line, as entered on the phone.
@immutable
class ConfirmationLineInput {
  const ConfirmationLineInput({
    required this.purchaseOrderLineId,
    this.confirmedQuantity,
    this.confirmedUnitPrice,
    this.confirmedDeliveryDate,
    this.varianceReason = '',
  });

  final String purchaseOrderLineId;
  final Dec? confirmedQuantity;
  final Dec? confirmedUnitPrice;
  final DateTime? confirmedDeliveryDate;
  final String varianceReason;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'purchase_order_line_id': purchaseOrderLineId,
    if (confirmedQuantity != null)
      'confirmed_quantity': confirmedQuantity!.toPlain(),
    if (confirmedUnitPrice != null)
      'confirmed_unit_price': confirmedUnitPrice!.toPlain(),
    if (confirmedDeliveryDate != null)
      'confirmed_delivery_date': _wireDate(confirmedDeliveryDate),
    if (varianceReason.trim().isNotEmpty)
      'variance_reason': varianceReason.trim(),
  };
}

/// Body of `POST purchase-orders/{id}/confirmations`.
@immutable
class ConfirmationInput {
  const ConfirmationInput({
    required this.confirmationNumber,
    this.confirmedAt,
    this.confirmedDeliveryDate,
    this.notes = '',
    this.lines = const <ConfirmationLineInput>[],
  });

  final String confirmationNumber;
  final DateTime? confirmedAt;
  final DateTime? confirmedDeliveryDate;
  final String notes;
  final List<ConfirmationLineInput> lines;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'confirmation_number': confirmationNumber.trim(),
    if (confirmedAt != null) 'confirmed_at': _wireDate(confirmedAt),
    if (confirmedDeliveryDate != null)
      'confirmed_delivery_date': _wireDate(confirmedDeliveryDate),
    if (notes.trim().isNotEmpty) 'notes': notes.trim(),
    if (lines.isNotEmpty)
      'lines': <Map<String, dynamic>>[
        for (final ConfirmationLineInput l in lines) l.toJson(),
      ],
  };
}

@immutable
class ConfirmationLine {
  const ConfirmationLine({
    required this.purchaseOrderLineId,
    this.orderedQuantity,
    this.confirmedQuantity,
    this.orderedUnitPrice,
    this.confirmedUnitPrice,
    this.confirmedDeliveryDate,
    this.quantityVariance,
    this.priceVariance,
    this.priceVariancePercent,
    this.deliveryDelayDays = 0,
    this.varianceReason,
  });

  factory ConfirmationLine.fromJson(Map<String, dynamic> j) => ConfirmationLine(
    purchaseOrderLineId: _str(j['purchase_order_line_id']),
    orderedQuantity: _decOrNull(j['ordered_quantity']),
    confirmedQuantity: _decOrNull(j['confirmed_quantity']),
    orderedUnitPrice: _decOrNull(j['ordered_unit_price']),
    confirmedUnitPrice: _decOrNull(j['confirmed_unit_price']),
    confirmedDeliveryDate: _date(j['confirmed_delivery_date']),
    quantityVariance: _decOrNull(j['quantity_variance']),
    priceVariance: _decOrNull(j['price_variance']),
    priceVariancePercent: _decOrNull(j['price_variance_percent']),
    deliveryDelayDays: _int(j['delivery_delay_days']),
    varianceReason: _strOrNull(j['variance_reason']),
  );

  final String purchaseOrderLineId;
  final Dec? orderedQuantity;
  final Dec? confirmedQuantity;
  final Dec? orderedUnitPrice;
  final Dec? confirmedUnitPrice;
  final DateTime? confirmedDeliveryDate;
  final Dec? quantityVariance;
  final Dec? priceVariance;
  final Dec? priceVariancePercent;
  final int deliveryDelayDays;
  final String? varianceReason;

  bool get hasVariance =>
      !(quantityVariance ?? Dec.zero).isZero ||
      !(priceVariance ?? Dec.zero).isZero ||
      deliveryDelayDays != 0;
}

/// A recorded supplier confirmation with its variances against the order.
@immutable
class PoConfirmation {
  const PoConfirmation({
    required this.id,
    required this.purchaseOrderId,
    this.confirmationNumber = '',
    this.hasVariance = false,
    this.requiresReview = false,
    this.notes = '',
    this.confirmedAt,
    this.priceVarianceTotal,
    this.quantityVarianceTotal,
    this.lines = const <ConfirmationLine>[],
  });

  factory PoConfirmation.fromJson(Map<String, dynamic> j) => PoConfirmation(
    id: _str(j['id']),
    purchaseOrderId: _str(j['purchase_order_id']),
    confirmationNumber: _str(j['confirmation_number']),
    hasVariance: _bool(j['has_variance']),
    requiresReview: _bool(j['requires_review']),
    notes: _str(j['notes']),
    confirmedAt: _date(j['confirmed_at']),
    priceVarianceTotal: _decOrNull(j['price_variance_total']),
    quantityVarianceTotal: _decOrNull(j['quantity_variance_total']),
    lines: <ConfirmationLine>[
      for (final Map<String, dynamic> l in _maps(j['lines']))
        ConfirmationLine.fromJson(l),
    ],
  );

  final String id;
  final String purchaseOrderId;
  final String confirmationNumber;
  final bool hasVariance;

  /// The variance exceeds the tolerance: the buyer must review it before the order proceeds.
  final bool requiresReview;
  final String notes;
  final DateTime? confirmedAt;
  final Dec? priceVarianceTotal;
  final Dec? quantityVarianceTotal;
  final List<ConfirmationLine> lines;
}

/// Reminder sent to a supplier about an overdue order.
@immutable
class PoReminder {
  const PoReminder({
    required this.id,
    required this.purchaseOrderId,
    this.level = 1,
    this.channel = '',
    this.trigger = '',
    this.daysOverdue = 0,
    this.sentAt,
  });

  factory PoReminder.fromJson(Map<String, dynamic> j) => PoReminder(
    id: _str(j['id']),
    purchaseOrderId: _str(j['purchase_order_id']),
    level: _int(j['level']),
    channel: _str(j['channel']),
    trigger: _str(j['trigger']),
    daysOverdue: _int(j['days_overdue']),
    sentAt: _date(j['sent_at']),
  );

  final String id;
  final String purchaseOrderId;
  final int level;
  final String channel;
  final String trigger;
  final int daysOverdue;
  final DateTime? sentAt;
}

enum DropshipStatus {
  pending('pending'),
  ddtIssued('ddt_issued'),
  partiallyDelivered('partially_delivered'),
  delivered('delivered'),
  unknown('');

  const DropshipStatus(this.wire);

  final String wire;

  static DropshipStatus fromWire(Object? raw) => values.firstWhere(
    (DropshipStatus s) => s.wire == '$raw' && s != unknown,
    orElse: () => unknown,
  );

  /// The delivery notice of the supplier can still be recorded.
  bool get canRecordDelivery => this != delivered;
}

/// Virtual stock movement of a dropshipment (the goods pass through no warehouse).
@immutable
class DropshipMovement {
  const DropshipMovement({
    required this.purchaseOrderLineId,
    this.direction = '',
    this.quantityBase,
    this.baseUom = '',
    this.valuedAmount,
    this.movedAt,
  });

  factory DropshipMovement.fromJson(Map<String, dynamic> j) => DropshipMovement(
    purchaseOrderLineId: _str(j['purchase_order_line_id']),
    direction: _str(j['direction']),
    quantityBase: _decOrNull(j['quantity_base']),
    baseUom: _str(j['base_uom']),
    valuedAmount: _decOrNull(j['valued_amount']),
    movedAt: _date(j['moved_at']),
  );

  final String purchaseOrderLineId;
  final String direction;
  final Dec? quantityBase;
  final String baseUom;
  final Dec? valuedAmount;
  final DateTime? movedAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'purchase_order_line_id': purchaseOrderLineId,
    'direction': direction,
    'quantity_base': quantityBase?.toPlain(),
    'base_uom': baseUom,
    'valued_amount': valuedAmount?.toPlain(),
    'moved_at': movedAt?.toIso8601String(),
  };
}

/// A supplier-to-customer shipment tracked from the purchase order.
@immutable
class Dropship {
  const Dropship({
    required this.id,
    required this.purchaseOrderId,
    this.salesOrderId = '',
    this.rawStatus = '',
    this.status = DropshipStatus.unknown,
    this.recipientName = '',
    this.recipientAddress = '',
    this.recipientPhone,
    this.deliveryNotes = '',
    this.ddtNumber,
    this.supplierShipmentReference,
    this.deliveryProofReference,
    this.billingAuthorized = false,
    this.ddtIssuedAt,
    this.deliveredAt,
    this.movements = const <DropshipMovement>[],
  });

  factory Dropship.fromJson(Map<String, dynamic> j) {
    final String raw = _str(j['status']);
    String joined(List<Object?> parts) =>
        parts.map(_str).where((String p) => p.isNotEmpty).join(' ');
    final String address =
        _strOrNull(j['recipient_address']) ??
        <String>[
          joined(<Object?>[j['recipient_street'], j['recipient_house_number']]),
          joined(<Object?>[j['recipient_postal_code'], j['recipient_city']]),
          _str(j['recipient_country_code']),
        ].where((String p) => p.isNotEmpty).join(', ');
    return Dropship(
      id: _str(j['id']),
      purchaseOrderId: _str(j['purchase_order_id']),
      salesOrderId: _str(j['sales_order_id']),
      rawStatus: raw,
      status: DropshipStatus.fromWire(raw),
      recipientName: _str(j['recipient_name']),
      recipientAddress: address,
      recipientPhone: _strOrNull(j['recipient_phone']),
      deliveryNotes: _str(j['delivery_notes']),
      ddtNumber: _strOrNull(j['ddt_number']),
      supplierShipmentReference: _strOrNull(j['supplier_shipment_reference']),
      deliveryProofReference: _strOrNull(j['delivery_proof_reference']),
      billingAuthorized: _bool(j['billing_authorized']),
      ddtIssuedAt: _date(j['ddt_issued_at']),
      deliveredAt: _date(j['delivered_at']),
      movements: <DropshipMovement>[
        for (final Map<String, dynamic> m in _maps(
          j['virtual_stock_movements'],
        ))
          DropshipMovement.fromJson(m),
      ],
    );
  }

  final String id;
  final String purchaseOrderId;
  final String salesOrderId;
  final String rawStatus;
  final DropshipStatus status;
  final String recipientName;

  /// One-line address assembled from the recipient fields.
  final String recipientAddress;
  final String? recipientPhone;
  final String deliveryNotes;
  final String? ddtNumber;
  final String? supplierShipmentReference;
  final String? deliveryProofReference;
  final bool billingAuthorized;
  final DateTime? ddtIssuedAt;
  final DateTime? deliveredAt;
  final List<DropshipMovement> movements;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'purchase_order_id': purchaseOrderId,
    'sales_order_id': salesOrderId,
    'status': rawStatus,
    'recipient_name': recipientName,
    'recipient_address': recipientAddress,
    'recipient_phone': recipientPhone,
    'delivery_notes': deliveryNotes,
    'ddt_number': ddtNumber,
    'supplier_shipment_reference': supplierShipmentReference,
    'delivery_proof_reference': deliveryProofReference,
    'billing_authorized': billingAuthorized,
    'ddt_issued_at': ddtIssuedAt?.toIso8601String(),
    'delivered_at': deliveredAt?.toIso8601String(),
    'virtual_stock_movements': <Map<String, dynamic>>[
      for (final DropshipMovement m in movements) m.toJson(),
    ],
  };

  Dropship copyWith({
    String? rawStatus,
    DropshipStatus? status,
    DateTime? deliveredAt,
    String? deliveryProofReference,
    String? supplierShipmentReference,
  }) => Dropship(
    id: id,
    purchaseOrderId: purchaseOrderId,
    salesOrderId: salesOrderId,
    rawStatus: rawStatus ?? this.rawStatus,
    status: status ?? this.status,
    recipientName: recipientName,
    recipientAddress: recipientAddress,
    recipientPhone: recipientPhone,
    deliveryNotes: deliveryNotes,
    ddtNumber: ddtNumber,
    supplierShipmentReference:
        supplierShipmentReference ?? this.supplierShipmentReference,
    deliveryProofReference:
        deliveryProofReference ?? this.deliveryProofReference,
    billingAuthorized: billingAuthorized,
    ddtIssuedAt: ddtIssuedAt,
    deliveredAt: deliveredAt ?? this.deliveredAt,
    movements: movements,
  );
}

@immutable
class DeliveryLineInput {
  const DeliveryLineInput({
    required this.purchaseOrderLineId,
    required this.quantityDelivered,
  });

  final String purchaseOrderLineId;
  final Dec quantityDelivered;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'purchase_order_line_id': purchaseOrderLineId,
    'quantity_delivered': quantityDelivered.toPlain(),
  };
}

/// Body of `POST dropshipments/{id}/deliveries`: the supplier's delivery notice with the proof reference.
@immutable
class DeliveryInput {
  const DeliveryInput({
    this.deliveredAt,
    this.deliveryProofReference = '',
    this.supplierShipmentReference = '',
    this.lines = const <DeliveryLineInput>[],
  });

  final DateTime? deliveredAt;
  final String deliveryProofReference;
  final String supplierShipmentReference;
  final List<DeliveryLineInput> lines;

  Map<String, dynamic> toJson() => <String, dynamic>{
    if (deliveredAt != null) 'delivered_at': _wireDate(deliveredAt),
    if (deliveryProofReference.trim().isNotEmpty)
      'delivery_proof_reference': deliveryProofReference.trim(),
    if (supplierShipmentReference.trim().isNotEmpty)
      'supplier_shipment_reference': supplierShipmentReference.trim(),
    if (lines.isNotEmpty)
      'lines': <Map<String, dynamic>>[
        for (final DeliveryLineInput l in lines) l.toJson(),
      ],
  };
}

/// Inputs of a pricing preview.
@immutable
class PricingInput {
  const PricingInput({
    required this.quantity,
    required this.unitPrice,
    this.discountCascade = const <Dec>[],
    this.uomConversionFactor,
    this.exchangeRate,
    this.taxRate,
  });

  final Dec quantity;
  final Dec unitPrice;
  final List<Dec> discountCascade;
  final Dec? uomConversionFactor;
  final Dec? exchangeRate;
  final Dec? taxRate;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'quantity': quantity.toPlain(),
    'unit_price': unitPrice.toPlain(),
    if (discountCascade.isNotEmpty)
      'discount_cascade': <String>[
        for (final Dec d in discountCascade) d.toPlain(),
      ],
    if (uomConversionFactor != null)
      'uom_conversion_factor': uomConversionFactor!.toPlain(),
    if (exchangeRate != null) 'exchange_rate': exchangeRate!.toPlain(),
    if (taxRate != null) 'tax_rate': taxRate!.toPlain(),
  };
}

/// Result of `POST purchase-orders/pricing-preview` (or its offline estimate).
@immutable
class PricingPreview {
  const PricingPreview({
    required this.discountCascade,
    required this.effectiveDiscountPercent,
    required this.netUnitPrice,
    required this.lineNetAmount,
    required this.lineTaxAmount,
    required this.lineTotalAmount,
    required this.quantityBase,
    required this.netPricePerBaseUnit,
    this.lineNetAmountCompanyCurrency,
    this.estimated = false,
  });

  factory PricingPreview.fromJson(Map<String, dynamic> j) => PricingPreview(
    discountCascade: _decs(j['discount_cascade']),
    effectiveDiscountPercent: _dec(j['effective_discount_percent']),
    netUnitPrice: _dec(j['net_unit_price']),
    lineNetAmount: _dec(j['line_net_amount']),
    lineTaxAmount: _dec(j['line_tax_amount']),
    lineTotalAmount: _dec(j['line_total_amount']),
    quantityBase: _dec(j['quantity_base']),
    netPricePerBaseUnit: _dec(j['net_price_per_base_unit']),
    lineNetAmountCompanyCurrency: _decOrNull(
      j['line_net_amount_company_currency'],
    ),
  );

  final List<Dec> discountCascade;
  final Dec effectiveDiscountPercent;
  final Dec netUnitPrice;
  final Dec lineNetAmount;
  final Dec lineTaxAmount;
  final Dec lineTotalAmount;

  /// Quantity in the stock unit.
  final Dec quantityBase;
  final Dec netPricePerBaseUnit;
  final Dec? lineNetAmountCompanyCurrency;

  /// Computed on the phone because the server was unreachable.
  final bool estimated;
}

/// Offline twin of the server pricing preview: cascading discounts, dual unit of measure and exchange rate, with the
/// same truncation (scale 10) and two-decimal rounding as the backend `Decimal` helper.
abstract final class PoPricing {
  /// Net unit price after the successive discounts: `price * (1 - d1/100) * (1 - d2/100)...`.
  static Dec netUnitPrice(Dec price, List<Dec> cascade) {
    Dec net = price;
    for (final Dec d in cascade) {
      net = net * (Dec.hundred - d) / Dec.hundred;
    }
    return net;
  }

  /// Combined discount in percent of the whole cascade.
  static Dec effectivePercent(List<Dec> cascade) {
    Dec factor = _one;
    for (final Dec d in cascade) {
      factor = factor * (Dec.hundred - d) / Dec.hundred;
    }
    return ((_one - factor) * Dec.hundred).round2();
  }

  static PricingPreview preview(PricingInput input) {
    final Dec factor = (input.uomConversionFactor ?? _one).isPositive
        ? (input.uomConversionFactor ?? _one)
        : _one;
    final Dec netUnit = netUnitPrice(input.unitPrice, input.discountCascade);
    final Dec net = (input.quantity * netUnit).round2();
    final Dec tax = (net * (input.taxRate ?? Dec.zero) / Dec.hundred).round2();
    return PricingPreview(
      discountCascade: input.discountCascade,
      effectiveDiscountPercent: effectivePercent(input.discountCascade),
      netUnitPrice: netUnit,
      lineNetAmount: net,
      lineTaxAmount: tax,
      lineTotalAmount: net + tax,
      quantityBase: input.quantity * factor,
      netPricePerBaseUnit: netUnit / factor,
      lineNetAmountCompanyCurrency: (net * (input.exchangeRate ?? _one))
          .round2(),
      estimated: true,
    );
  }
}

/// Failure kinds of the remote calls.
enum PoErrorKind { offline, forbidden, notFound, invalid, unknown }

class PoException implements Exception {
  const PoException(this.kind, {this.detail = ''});

  final PoErrorKind kind;
  final String detail;

  @override
  String toString() => 'PoException($kind, $detail)';
}

/// How a write ended: sent and acknowledged, waiting in the outbox, or refused for good.
enum PoActionStatus { sent, queued, rejected }

@immutable
class PoActionOutcome {
  const PoActionOutcome(this.status, {this.detail = ''});

  final PoActionStatus status;
  final String detail;
}

/// Kinds of write the phone queues.
enum PoActionKind { confirmation, reminder, delivery }

/// A write still in the outbox.
@immutable
class PoPendingAction {
  const PoPendingAction({
    required this.queueUuid,
    required this.targetId,
    required this.kind,
    this.rejected = false,
    this.detail = '',
  });

  final String queueUuid;

  /// Purchase order id (confirmation, reminder) or dropshipment id (delivery).
  final String targetId;
  final PoActionKind kind;
  final bool rejected;
  final String detail;
}
