import 'package:fattura_facile/features/italian_vat/domain/italian_vat_models.dart';

Map<String, dynamic> envelope(Object? data, {Map<String, dynamic>? meta}) =>
    <String, dynamic>{
      'success': true,
      'message': '',
      'data': data,
      'meta': ?meta,
    };

Map<String, dynamic> lineJson({
  int? protocol = 1,
  String number = 'FA-1',
  String taxable = '1000.00',
  String rate = '22.00',
  String vat = '220.00',
  String? sectional,
  String? deductible,
  String? nonDeductible,
  String partner = 'Alpina SA',
}) => <String, dynamic>{
  'protocol_number': protocol,
  'posting_date': '2027-02-10',
  'document_date': '2027-02-09',
  'document_number': number,
  'document_type': 'invoice',
  'partner_name': partner,
  'taxable_amount': taxable,
  'vat_rate': rate,
  'vat_amount': vat,
  'vat_treatment': 'standard',
  'sectional': sectional,
  'deductible_vat': deductible,
  'non_deductible_vat': nonDeductible,
};

/// A register answer: `{data: [...], totals: {...}, meta: {...}}`.
Map<String, dynamic> registerBody(
  List<Map<String, dynamic>> lines, {
  Map<String, dynamic>? meta,
}) => <String, dynamic>{
  'data': lines,
  'totals': <String, dynamic>{'taxable': '0', 'tax': '0'},
  'meta': meta ?? <String, dynamic>{'currency': 'EUR'},
};

VatRegister register(
  VatRegisterType type,
  List<Map<String, dynamic>> lines, {
  Map<String, dynamic>? meta,
}) => VatRegister.fromJson(
  registerBody(lines, meta: meta),
  type: type,
  from: DateTime(2027),
  to: DateTime(2027, 3, 31),
);

Map<String, dynamic> letterJson({
  String id = 'l1',
  String customer = 'Export Srl',
  String protocol = '12345678901234567-000001',
  String authorized = '100000.00',
  String consumed = '25000.00',
  String status = 'active',
  String validFrom = '2027-01-01',
  String validTo = '2027-12-31',
}) => <String, dynamic>{
  'id': id,
  'customer_id': 'c1',
  'customer_name': customer,
  'protocol': protocol,
  'kind': 'up_to_amount',
  'status': status,
  'received_on': '2027-01-05',
  'valid_from': validFrom,
  'valid_to': validTo,
  'authorized_amount': authorized,
  'consumed_amount': consumed,
  'currency': 'EUR',
};

IntentLetter letter({
  String authorized = '100000.00',
  String consumed = '25000.00',
  String status = 'active',
  String protocol = '12345678901234567-000001',
  String validFrom = '2027-01-01',
  String validTo = '2027-12-31',
}) => IntentLetter.fromJson(
  letterJson(
    authorized: authorized,
    consumed: consumed,
    status: status,
    protocol: protocol,
    validFrom: validFrom,
    validTo: validTo,
  ),
);

Map<String, dynamic> settlementJson({
  String id = 's1',
  int year = 2027,
  int period = 1,
  String output = '5000.00',
  String input = '3000.00',
  String status = 'posted',
  Map<String, dynamic>? lipe,
  String? erario,
  String? paidAt,
  String payable = '2000.00',
}) => <String, dynamic>{
  'id': id,
  'year': year,
  'period': period,
  'period_type': 'quarterly',
  'output_vat_amount': output,
  'input_vat_amount': input,
  'previous_debit': '0.00',
  'previous_credit': '0.00',
  'interest_amount': '0.00',
  'payable_amount': payable,
  'status': status,
  'currency': 'EUR',
  'paid_at': paidAt,
  'lipe': ?lipe,
  if (erario != null)
    'reconciliation': <String, dynamic>{'erario_balance': erario},
};

LipeSettlement settlement({
  String id = 's1',
  int period = 1,
  String output = '5000.00',
  String input = '3000.00',
  String? erario,
  Map<String, dynamic>? lipe,
  String? paidAt,
  String payable = '2000.00',
}) => LipeSettlement.fromJson(
  settlementJson(
    id: id,
    period: period,
    output: output,
    input: input,
    erario: erario,
    lipe: lipe,
    paidAt: paidAt,
    payable: payable,
  ),
);

Map<String, dynamic> certificateJson({
  String id = 'cu1',
  String name = 'Rossi Mario',
  String kind = 'professional',
  String gross = '10000.00',
  String withheld = '2000.00',
  String paid = '2000.00',
}) => <String, dynamic>{
  'id': id,
  'year': 2027,
  'recipient_name': name,
  'recipient_kind': kind,
  'tax_code': 'RSSMRA80A01H501U',
  'causale': kind == 'agent' ? 'R' : 'A',
  'gross_amount': gross,
  'taxable_amount': gross,
  'withheld_amount': withheld,
  'f24_paid_amount': paid,
  'f24_paid_on': paid == '0.00' ? null : '2027-02-16',
  'f24_tribute_code': kind == 'agent' ? '1038' : '1040',
  'currency': 'EUR',
};

WithholdingCertificate certificate({
  String id = 'cu1',
  String name = 'Rossi Mario',
  String kind = 'professional',
  String gross = '10000.00',
  String withheld = '2000.00',
  String paid = '2000.00',
}) => WithholdingCertificate.fromJson(
  certificateJson(
    id: id,
    name: name,
    kind: kind,
    gross: gross,
    withheld: withheld,
    paid: paid,
  ),
);
