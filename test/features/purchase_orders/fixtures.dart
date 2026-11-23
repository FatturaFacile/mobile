import 'package:fattura_facile/features/purchase_orders/domain/purchase_order_models.dart';
import 'package:fattura_facile/features/supplier_rebates/domain/rebate_decimal.dart';

/// Wire-shape of a purchase order line (`PurchaseOrderResource`); a BOX of 12 PCS by default.
Map<String, dynamic> lineJson({
  String id = 'l1',
  int number = 1,
  String uom = 'BOX',
  String baseUom = 'PCS',
  String factor = '12.0000',
  String quantity = '10.0000',
  String? promised = '2026-11-10',
  List<String> cascade = const <String>['10', '5'],
  bool closed = false,
}) => <String, dynamic>{
  'id': id,
  'line_number': number,
  'description': 'Widget $number',
  'quantity_ordered': quantity,
  'quantity_received': '0.0000',
  'uom': uom,
  'base_uom': baseUom,
  'uom_conversion_factor': factor,
  'quantity_base_ordered': '120.0000',
  'quantity_base_received': '0.0000',
  'quantity_confirmed': null,
  'discount_cascade': cascade,
  'discount_percent_effective': '14.5000',
  'promised_delivery_date': promised,
  'confirmed_delivery_date': null,
  'unit_price': '100.0000',
  'tax_rate': '8.10',
  'line_net_amount': '855.00',
  'is_closed': closed,
};

Map<String, dynamic> orderJson({
  String id = 'o1',
  String number = 'PO-0001',
  String status = 'sent',
  String? promised,
  String expected = '2026-11-30',
  bool dropship = false,
  List<Map<String, dynamic>>? lines,
  int reminders = 0,
}) => <String, dynamic>{
  'id': id,
  'po_number': number,
  'supplier_id': 's1',
  'supplier': <String, dynamic>{'name': 'Alpina AG'},
  'status': status,
  'order_date': '2026-10-20',
  'expected_delivery_date': expected,
  'promised_delivery_date': promised,
  'currency': 'CHF',
  'net_amount': '855.00',
  'total_amount': '924.26',
  'is_dropship': dropship,
  'sales_order_id': dropship ? 'so1' : null,
  'supplier_confirmation_number': null,
  'confirmed_at': null,
  'reminder_count': reminders,
  'last_reminder_at': null,
  'notes': '',
  'lines': lines ?? <Map<String, dynamic>>[lineJson()],
};

PurchaseOrder order({
  String id = 'o1',
  String number = 'PO-0001',
  String status = 'sent',
  String? promised,
  bool dropship = false,
  List<Map<String, dynamic>>? lines,
  int reminders = 0,
}) => PurchaseOrder.fromJson(
  orderJson(
    id: id,
    number: number,
    status: status,
    promised: promised,
    dropship: dropship,
    lines: lines,
    reminders: reminders,
  ),
);

Map<String, dynamic> overdueJson({
  String id = 'o1',
  int days = 12,
  bool due = true,
}) => <String, dynamic>{
  'order': orderJson(id: id, status: 'confirmed', promised: '2026-11-10'),
  'days_overdue': days,
  'overdue_line_ids': <String>['l1'],
  'reminder_count': 1,
  'last_reminder_at': '2026-11-15T08:00:00+00:00',
  'next_reminder_due': due,
};

Map<String, dynamic> dropshipJson({
  String id = 'd1',
  String status = 'ddt_issued',
  String orderId = 'o1',
}) => <String, dynamic>{
  'id': id,
  'purchase_order_id': orderId,
  'sales_order_id': 'so1',
  'status': status,
  'recipient_name': 'Rossi SA',
  'recipient_street': 'Via Roma',
  'recipient_house_number': '12',
  'recipient_postal_code': '6900',
  'recipient_city': 'Lugano',
  'recipient_country_code': 'CH',
  'recipient_phone': '+41 91 000 00 00',
  'delivery_notes': 'Ring twice',
  'ddt_number': 'DDT-77',
  'supplier_shipment_reference': null,
  'delivery_proof_reference': null,
  'billing_authorized': false,
  'ddt_issued_at': '2026-11-12T09:00:00+00:00',
  'delivered_at': null,
  'virtual_stock_movements': <Map<String, dynamic>>[
    <String, dynamic>{
      'purchase_order_line_id': 'l1',
      'direction': 'in',
      'quantity_base': '120.0000',
      'base_uom': 'PCS',
      'unit_cost_base': '7.1250',
      'valued_amount': '855.00',
      'moved_at': '2026-11-12T09:00:00+00:00',
    },
  ],
};

Map<String, dynamic> confirmationJson({String id = 'c1', bool review = true}) =>
    <String, dynamic>{
      'id': id,
      'purchase_order_id': 'o1',
      'confirmation_number': 'AB-991',
      'has_variance': true,
      'requires_review': review,
      'notes': '',
      'confirmed_at': '2026-11-14',
      'price_variance_total': '50.00',
      'quantity_variance_total': '-2.0000',
      'lines': <Map<String, dynamic>>[
        <String, dynamic>{
          'purchase_order_line_id': 'l1',
          'ordered_quantity': '10.0000',
          'confirmed_quantity': '8.0000',
          'ordered_unit_price': '100.0000',
          'confirmed_unit_price': '105.0000',
          'confirmed_delivery_date': '2026-11-20',
          'quantity_variance': '-2.0000',
          'quantity_variance_base': '-24.0000',
          'price_variance': '5.0000',
          'price_variance_percent': '5.0000',
          'line_total_variance': '50.00',
          'delivery_delay_days': 10,
          'variance_reason': 'Raw material shortage',
        },
      ],
    };

Map<String, dynamic> previewJson() => <String, dynamic>{
  'discount_cascade': <String>['10', '5'],
  'effective_discount_percent': '14.50',
  'net_unit_price': '85.5000',
  'line_net_amount': '855.00',
  'line_tax_amount': '69.26',
  'line_total_amount': '924.26',
  'quantity_base': '120.0000',
  'net_price_per_base_unit': '7.1250',
  'line_net_amount_company_currency': '855.00',
};

/// A BOX of 12 PCS, 10 boxes at 100 with a 10% + 5% cascade and 8.1% tax.
abstract final class PricingInputFixture {
  static final PricingInput box = PricingInput(
    quantity: Dec.parse('10'),
    unitPrice: Dec.parse('100'),
    discountCascade: <Dec>[Dec.parse('10'), Dec.parse('5')],
    uomConversionFactor: Dec.parse('12'),
    taxRate: Dec.parse('8.1'),
  );
}
