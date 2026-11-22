import 'package:fattura_facile/features/supplier_rebates/domain/rebate_decimal.dart';
import 'package:fattura_facile/features/supplier_rebates/domain/supplier_rebate_models.dart';

/// Scale used across the tests: 2% from 100k, 3% + 500 flat from 250k, 4% + 1000 flat from 500k.
Map<String, dynamic> tierJson(String threshold, String rate, [String? flat]) =>
    <String, dynamic>{
      'threshold_amount': threshold,
      'rate_percent': rate,
      'flat_amount': flat,
    };

List<Map<String, dynamic>> scaleJson() => <Map<String, dynamic>>[
  tierJson('100000.00', '2.00'),
  tierJson('250000.00', '3.00', '500.00'),
  tierJson('500000.00', '4.00', '1000.00'),
];

List<RebateTier> scale() => <RebateTier>[
  for (final Map<String, dynamic> t in scaleJson()) RebateTier.fromJson(t),
];

Map<String, dynamic> agreementJson({
  String id = 'a1',
  String code = 'PFA-2027',
  String mode = 'retroactive',
  String type = 'tiered_volume',
  String status = 'active',
  String currency = 'CHF',
  List<Map<String, dynamic>>? tiers,
  List<Map<String, dynamic>>? contributions,
  String? supplierContractId,
}) => <String, dynamic>{
  'id': id,
  'code': code,
  'name': 'Rappel $code',
  'direction': 'purchase',
  'contact_id': 'c1',
  'contact_name': 'Alpina AG',
  'tier_mode': mode,
  'rebate_type': type,
  'status': status,
  'currency': currency,
  'starts_on': '2027-01-01',
  'ends_on': '2027-12-31',
  'supplier_contract_id': supplierContractId,
  'fixed_bonus_target': type == 'fixed_bonus' ? '50000.00' : null,
  'fixed_bonus_amount': type == 'fixed_bonus' ? '2500.00' : null,
  'accrual_frequency': 'quarterly',
  'version': 3,
  'open_rebate': '1200.00',
  'tiers': tiers ?? scaleJson(),
  'contributions': contributions ?? <Map<String, dynamic>>[],
};

Map<String, dynamic> contributionJson() => <String, dynamic>{
  'id': 'k1',
  'kind': 'marketing',
  'description': 'Flyer',
  'amount': '800.00',
  'due_on': '2027-06-30',
  'status': 'planned',
};

/// The `progress` payload the backend serves for a retroactive agreement at 120000 of volume.
Map<String, dynamic> progressJson({String volume = '120000.00'}) =>
    <String, dynamic>{
      'agreement_id': 'a1',
      'rebate_type': 'tiered_volume',
      'tier_mode': 'retroactive',
      'currency': 'CHF',
      'as_of': '2027-03-31',
      'qualifying_volume': volume,
      'earned_rebate': '2400.00',
      'accrued_rebate': '1200.00',
      'settled_rebate': '0.00',
      'tier': <String, dynamic>{
        'current_tier': tierJson('100000.00', '2.00'),
        'next_tier': tierJson('250000.00', '3.00', '500.00'),
        'accrued_rebate': '2400.00',
        'distance_to_next': '130000.00',
        'progress_percent': '13.33',
        'projected_rebate_at_next': '8000.00',
        'projected_gain': '5600.00',
      },
      'bonus': null,
      'contributions': <String, dynamic>{
        'planned': '800.00',
        'accrued': '0.00',
        'settled': '0.00',
      },
      'tiers': <Map<String, dynamic>>[
        <String, dynamic>{...tierJson('100000.00', '2.00'), 'max_threshold': '250000.00'},
        <String, dynamic>{
          ...tierJson('250000.00', '3.00', '500.00'),
          'max_threshold': '500000.00',
        },
        <String, dynamic>{
          ...tierJson('500000.00', '4.00', '1000.00'),
          'max_threshold': null,
        },
      ],
    };

Map<String, dynamic> runJson({String id = 'r1'}) => <String, dynamic>{
  'id': id,
  'period_start': '2027-01-01',
  'period_end': '2027-03-31',
  'status': 'posted',
  'base_amount': '120000.00',
  'cumulative_rebate': '2400.00',
  'delta_amount': '2400.00',
  'journal_entry_id': null,
  'lines': <Map<String, dynamic>>[
    <String, dynamic>{
      'invoice_number': 'INV-1',
      'document_type': 'invoice',
      'invoice_date': '2027-02-10',
      'net_amount': '120000.00',
    },
  ],
};

Map<String, dynamic> proposalJson({
  String id = 'p1',
  String status = 'draft',
  String agreementId = 'a1',
  int version = 2,
  String createdAt = '2027-04-01T08:00:00Z',
}) => <String, dynamic>{
  'id': id,
  'agreement_id': agreementId,
  'agreement': <String, dynamic>{
    'id': agreementId,
    'code': 'PFA-2027',
    'name': 'Rappel PFA-2027',
    'direction': 'purchase',
  },
  'amount': '2400.00',
  'gross_amount': '2594.40',
  'tax_rate': '8.10',
  'tax_amount': '194.40',
  'currency': 'CHF',
  'status': status,
  'execution_mode': 'ap_set_off',
  'set_off_amount': '0.00',
  'version': version,
  'created_at': createdAt,
  'lines': <Map<String, dynamic>>[
    <String, dynamic>{
      'line_type': 'invoice',
      'reference': 'INV-1',
      'reference_date': '2027-02-10',
      'net_amount': '120000.00',
      'rebate_amount': '2400.00',
    },
    <String, dynamic>{
      'line_type': 'credit_note',
      'reference': 'CN-1',
      'reference_date': '2027-02-20',
      'net_amount': '-1000.00',
      'rebate_amount': '-20.00',
    },
  ],
};

Map<String, dynamic> contractJson({String id = 'sc1'}) => <String, dynamic>{
  'id': id,
  'contract_number': 'RV-2027-1',
  'title': 'Rahmenvertrag Stahl',
  'contract_type': 'framework',
  'total_committed_amount': 100000.0,
  'consumed_amount': 20000.0,
  'minimum_spend_amount': 60000.0,
  'alert_threshold_percent': 80.0,
  'currency': 'CHF',
  'starts_at': '2027-01-01',
  'ends_at': '2027-12-31',
  'status': 'active',
};

Map<String, dynamic> balanceJson({bool exceeded = false}) => <String, dynamic>{
  'contract_id': 'sc1',
  'currency': 'CHF',
  'status': 'active',
  'ceiling_amount': '100000.00',
  'minimum_spend_amount': '60000.00',
  'ordered_amount': exceeded ? '105000.00' : '85000.00',
  'received_amount': '40000.00',
  'invoiced_amount': '30000.00',
  'remaining_ceiling': exceeded ? '-5000.00' : '15000.00',
  'ceiling_used_percent': exceeded ? '105.00' : '85.00',
  'minimum_shortfall': '0.00',
  'minimum_reached_percent': '141.67',
  'alert_threshold_percent': '80.00',
  'lines': <Map<String, dynamic>>[
    <String, dynamic>{
      'line_id': 'l1',
      'description': 'Steel plate 10mm',
      'unit_price': '12.50',
      'committed_quantity': '8000.000',
      'released_quantity': '6800.000',
      'remaining_quantity': '1200.000',
      'ordered_amount': '85000.00',
    },
  ],
  'alerts': <Map<String, dynamic>>[
    <String, dynamic>{
      'code': exceeded ? 'ceiling_exceeded' : 'ceiling_near',
      'severity': exceeded ? 'critical' : 'warning',
    },
  ],
};

Map<String, dynamic> envelope(Object data) => <String, dynamic>{
  'success': true,
  'message': 'ok',
  'data': data,
};

Dec d(String value) => Dec.parse(value);

RebateAgreement agreement({
  String mode = 'retroactive',
  String type = 'tiered_volume',
}) => RebateAgreement.fromJson(agreementJson(mode: mode, type: type));

SettlementProposal proposal({String status = 'draft', int version = 2}) =>
    SettlementProposal.fromJson(proposalJson(status: status, version: version));
