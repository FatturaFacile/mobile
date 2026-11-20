/// Input kinds understood by the generic entity form.
enum FieldKind { text, multiline, number, date, dateTime, relation }

class FieldDef {
  const FieldDef(this.key, this.kind, {this.required = false, this.defaultValue, this.relatedEntity});

  /// API field name; also the translation key suffix (`mobile.field.<key>`).
  final String key;
  final FieldKind kind;
  final bool required;
  final Object? defaultValue;

  /// For [FieldKind.relation]: the synced entity whose records are offered.
  final String? relatedEntity;
}

typedef RecordText = String Function(Map<String, dynamic> record);
typedef BodyBuilder = Map<String, dynamic> Function(Map<String, dynamic> values);

/// Declarative description of an offline-capable resource: where it syncs, what the form edits.
class EntityDef {
  const EntityDef({
    required this.entity,
    required this.writePath,
    required this.fields,
    required this.title,
    this.subtitle,
    this.canCreate = true,
    this.canEdit = true,
    this.canDelete = true,
    this.toBody,
  });

  /// Sync entity name (`/mobile/sync/{entity}`) and translation key (`mobile.entity.<entity>`).
  final String entity;

  /// REST collection used for POST / PUT / DELETE.
  final String writePath;
  final List<FieldDef> fields;
  final RecordText title;
  final RecordText? subtitle;
  final bool canCreate;
  final bool canEdit;
  final bool canDelete;

  /// Maps flat form values to the API body when the two differ (e.g. work-order lines).
  final BodyBuilder? toBody;

  bool get readOnly => !canCreate && !canEdit && !canDelete;
}

String _s(Object? v) => v == null ? '' : '$v';

String _join(Iterable<Object?> parts) => parts.map(_s).where((String p) => p.isNotEmpty).join(' ');

Map<String, dynamic> _workOrderBody(Map<String, dynamic> values) {
  final Map<String, dynamic> body = <String, dynamic>{
    for (final MapEntry<String, dynamic> e in values.entries)
      if (!e.key.startsWith('line_')) e.key: e.value,
  };
  final String description = _s(values['line_description']);
  if (description.isNotEmpty) {
    body['lines'] = <Map<String, dynamic>>[
      <String, dynamic>{
        'type': 'labor',
        'description': description,
        'quantity': values['line_quantity'] ?? 1,
        'unit_price': values['line_unit_price'] ?? 0,
        'tax_rate': values['line_tax_rate'] ?? 0,
      },
    ];
  }
  return body;
}

/// Offline resources by sync entity.
const Map<String, EntityDef> entityDefinitions = <String, EntityDef>{
  'contacts': EntityDef(
    entity: 'contacts',
    writePath: '/crm/contacts',
    fields: <FieldDef>[
      FieldDef('company_name', FieldKind.text),
      FieldDef('first_name', FieldKind.text),
      FieldDef('last_name', FieldKind.text),
      FieldDef('email', FieldKind.text),
      FieldDef('phone', FieldKind.text),
      FieldDef('type', FieldKind.text, required: true, defaultValue: 'client'),
      FieldDef('legal_type', FieldKind.text, required: true, defaultValue: 'company'),
      FieldDef('country', FieldKind.text, required: true, defaultValue: 'CH'),
    ],
    title: _contactTitle,
    subtitle: _contactSubtitle,
  ),
  'products': EntityDef(
    entity: 'products',
    writePath: '/inventory/products',
    fields: <FieldDef>[
      FieldDef('sku', FieldKind.text, required: true),
      FieldDef('name', FieldKind.text, required: true),
      FieldDef('unit_measure', FieldKind.text, required: true, defaultValue: 'pz'),
      FieldDef('cost_price', FieldKind.number, required: true, defaultValue: 0),
      FieldDef('sale_price', FieldKind.number, required: true, defaultValue: 0),
      FieldDef('tax_rate', FieldKind.number, required: true, defaultValue: 22),
    ],
    title: _productTitle,
    subtitle: _productSubtitle,
  ),
  'work_orders': EntityDef(
    entity: 'work_orders',
    writePath: '/field-service/work-orders',
    fields: <FieldDef>[
      FieldDef('client_id', FieldKind.relation, required: true, relatedEntity: 'contacts'),
      FieldDef('date', FieldKind.date, required: true),
      FieldDef('intervention_address', FieldKind.text),
      FieldDef('notes', FieldKind.multiline),
      FieldDef('line_description', FieldKind.text),
      FieldDef('line_quantity', FieldKind.number, defaultValue: 1),
      FieldDef('line_unit_price', FieldKind.number, defaultValue: 0),
      FieldDef('line_tax_rate', FieldKind.number, defaultValue: 0),
    ],
    title: _workOrderTitle,
    subtitle: _workOrderSubtitle,
    toBody: _workOrderBody,
  ),
  'appointments': EntityDef(
    entity: 'appointments',
    writePath: '/appointments',
    fields: <FieldDef>[
      FieldDef('title', FieldKind.text, required: true),
      FieldDef('starts_at', FieldKind.dateTime, required: true),
      FieldDef('ends_at', FieldKind.dateTime, required: true),
      FieldDef('address', FieldKind.text),
      FieldDef('description', FieldKind.multiline),
    ],
    title: _appointmentTitle,
    subtitle: _appointmentSubtitle,
  ),
  'expenses': EntityDef(
    entity: 'expenses',
    writePath: '/expenses',
    fields: <FieldDef>[
      FieldDef('merchant_name', FieldKind.text),
      FieldDef('amount_gross', FieldKind.number, required: true),
      FieldDef('date', FieldKind.date),
      FieldDef('currency', FieldKind.text, defaultValue: 'CHF'),
      FieldDef('notes', FieldKind.multiline),
    ],
    title: _expenseTitle,
    subtitle: _expenseSubtitle,
  ),
  'employee_shifts': EntityDef(
    entity: 'employee_shifts',
    writePath: '/mobile/shifts',
    fields: <FieldDef>[
      FieldDef('starts_at', FieldKind.dateTime),
      FieldDef('ends_at', FieldKind.dateTime),
    ],
    title: _shiftTitle,
    canCreate: false,
    canEdit: false,
    canDelete: false,
  ),
  'payslip_documents': EntityDef(
    entity: 'payslip_documents',
    writePath: '/mobile/payslips',
    fields: <FieldDef>[
      FieldDef('title', FieldKind.text),
      FieldDef('country', FieldKind.text),
    ],
    title: _payslipTitle,
    canCreate: false,
    canEdit: false,
    canDelete: false,
  ),
};

String _contactTitle(Map<String, dynamic> r) {
  final String company = _s(r['company_name']);
  return company.isNotEmpty ? company : _join(<Object?>[r['first_name'], r['last_name']]);
}

String _contactSubtitle(Map<String, dynamic> r) => _join(<Object?>[r['email'], r['phone']]);

String _productTitle(Map<String, dynamic> r) => _s(r['name']);

String _productSubtitle(Map<String, dynamic> r) => _join(<Object?>[r['sku'], r['sale_price']]);

String _workOrderTitle(Map<String, dynamic> r) => _join(<Object?>[r['number'] ?? r['code'], r['date']]);

String _workOrderSubtitle(Map<String, dynamic> r) => _join(<Object?>[r['intervention_address'], r['status']]);

String _appointmentTitle(Map<String, dynamic> r) => _s(r['title']);

String _appointmentSubtitle(Map<String, dynamic> r) => _join(<Object?>[r['starts_at']]);

String _expenseTitle(Map<String, dynamic> r) => _join(<Object?>[r['merchant_name'], r['amount_gross']]);

String _expenseSubtitle(Map<String, dynamic> r) => _join(<Object?>[r['date'], r['status']]);

String _shiftTitle(Map<String, dynamic> r) => _join(<Object?>[r['starts_at'], r['ends_at']]);

String _payslipTitle(Map<String, dynamic> r) => _join(<Object?>[r['title'], r['period']]);

/// Which module of the bootstrap payload opens which resource.
const Map<String, String> moduleEntity = <String, String>{
  'customer_360': 'contacts',
  'inventory_counts': 'products',
  'work_orders': 'work_orders',
  'appointments': 'appointments',
  'expenses': 'expenses',
  'shifts': 'employee_shifts',
  'payslips': 'payslip_documents',
};
