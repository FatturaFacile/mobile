import 'package:fattura_facile/features/entities/entity_definition.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every launcher module maps to a defined resource', () {
    for (final String entity in moduleEntity.values) {
      expect(entityDefinitions.containsKey(entity), isTrue, reason: entity);
    }
  });

  test('read-only resources expose no write actions', () {
    expect(entityDefinitions['payslip_documents']!.readOnly, isTrue);
    expect(entityDefinitions['employee_shifts']!.readOnly, isTrue);
    expect(entityDefinitions['contacts']!.readOnly, isFalse);
  });

  test('titles fall back sensibly', () {
    final EntityDef contacts = entityDefinitions['contacts']!;
    expect(contacts.title(<String, dynamic>{'company_name': 'Acme'}), 'Acme');
    expect(
      contacts.title(<String, dynamic>{
        'first_name': 'Anna',
        'last_name': 'Rossi',
      }),
      'Anna Rossi',
    );
    expect(
      entityDefinitions['expenses']!.title(<String, dynamic>{
        'merchant_name': 'Bar',
        'amount_gross': 3,
      }),
      'Bar 3',
    );
  });

  test('a work order form flattens its line into the API shape', () {
    final Map<String, dynamic> body = entityDefinitions['work_orders']!.toBody!(
      <String, dynamic>{
        'client_id': 'c1',
        'date': '2026-05-01',
        'line_description': 'Repair',
        'line_quantity': 2,
        'line_unit_price': 50,
        'line_tax_rate': 8.1,
      },
    );
    expect(body.containsKey('line_description'), isFalse);
    expect(body['client_id'], 'c1');
    final Map<String, dynamic> line =
        (body['lines'] as List<dynamic>).single as Map<String, dynamic>;
    expect(line, <String, dynamic>{
      'type': 'labor',
      'description': 'Repair',
      'quantity': 2,
      'unit_price': 50,
      'tax_rate': 8.1,
    });

    final Map<String, dynamic> noLine = entityDefinitions['work_orders']!
        .toBody!(<String, dynamic>{'client_id': 'c1', 'date': '2026-05-01'});
    expect(noLine.containsKey('lines'), isFalse);
  });

  test('required API fields are marked required in the forms', () {
    List<String> required(String e) => entityDefinitions[e]!.fields
        .where((FieldDef f) => f.required)
        .map((FieldDef f) => f.key)
        .toList();
    expect(
      required('products'),
      containsAll(<String>[
        'sku',
        'name',
        'unit_measure',
        'cost_price',
        'sale_price',
        'tax_rate',
      ]),
    );
    expect(
      required('appointments'),
      containsAll(<String>['title', 'starts_at', 'ends_at']),
    );
    expect(required('work_orders'), containsAll(<String>['client_id', 'date']));
  });
}
