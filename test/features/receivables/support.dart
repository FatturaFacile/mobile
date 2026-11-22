import 'dart:typed_data';

import 'package:fattura_facile/features/receivables/data/statement_exporter.dart';
import 'package:fattura_facile/features/receivables/domain/money.dart';
import 'package:fattura_facile/features/receivables/domain/receivables_models.dart';
import 'package:fattura_facile/features/receivables/domain/receivables_repository.dart';

// --- JSON fixtures, shaped like the API contract (docs/receivables-api.md) ------------------------------------------------

Map<String, dynamic> itemJson(
  String id, {
  String customerId = 'c1',
  String open = '100.00',
  String original = '100.00',
  String settled = '0.00',
  int days = 0,
  String status = 'open',
  String number = 'FT-1',
  String due = '2030-02-01',
  String currency = 'CHF',
  String? disputeReason,
  List<Map<String, dynamic>>? allocations,
}) => <String, dynamic>{
  'id': id,
  'customer_id': customerId,
  'invoice_id': 'inv-$id',
  'sequence': 1,
  'document_type': 'invoice',
  'document_number': number,
  'currency': currency,
  'original_amount': original,
  'open_amount': open,
  'settled_amount': settled,
  'issue_date': '2030-01-01',
  'due_date': due,
  'value_date': '2030-01-01',
  'status': status,
  'stored_status': 'open',
  'days_past_due': days,
  'dispute_reason': disputeReason,
  'allocations': ?allocations,
};

Map<String, dynamic> allocationJson(
  String id,
  String itemId, {
  String type = 'payment',
  String amount = '40.00',
  String? reversedAt,
}) => <String, dynamic>{
  'id': id,
  'receivable_item_id': itemId,
  'source_type': type,
  'origin': 'manual',
  'source_id': null,
  'source_reference': 'PAY-1',
  'amount': amount,
  'value_date': '2030-01-10',
  'notes': '',
  'allocated_by': 'u1',
  'reversed_at': reversedAt,
};

/// Buckets that differ from the server defaults on purpose: the UI must follow the response, not hardcode.
const List<Map<String, dynamic>> customBuckets = <Map<String, dynamic>>[
  <String, dynamic>{'key': 'current', 'from': 0, 'to': 0},
  <String, dynamic>{'key': '1_15', 'from': 1, 'to': 15},
  <String, dynamic>{'key': '16_45', 'from': 16, 'to': 45},
  <String, dynamic>{'key': '46_plus', 'from': 46, 'to': null},
];

Map<String, dynamic> agingJson({
  String currency = 'CHF',
  List<String> currencies = const <String>['CHF'],
}) => <String, dynamic>{
  'as_of': '2030-02-10',
  'currency': currency,
  'available_currencies': currencies,
  'buckets': customBuckets,
  'totals': <String, dynamic>{
    'current': '500.00',
    '1_15': '300.00',
    '16_45': '150.00',
    '46_plus': '50.00',
  },
  'total_open': '1000.00',
  'total_overdue': '500.00',
  'over_90': '0.00',
  'customers': <Map<String, dynamic>>[
    <String, dynamic>{
      'customer_id': 'c1',
      'customer_name': 'Rossi SA',
      'buckets': <String, dynamic>{
        'current': '400.00',
        '1_15': '300.00',
        '16_45': '0.00',
        '46_plus': '0.00',
      },
      'total_open': '700.00',
      'total_overdue': '300.00',
      'items': 3,
    },
    <String, dynamic>{
      'customer_id': 'c2',
      'customer_name': 'Bianchi Sagl',
      'buckets': <String, dynamic>{
        'current': '100.00',
        '1_15': '0.00',
        '16_45': '150.00',
        '46_plus': '50.00',
      },
      'total_open': '300.00',
      'total_overdue': '200.00',
      'items': 2,
    },
  ],
};

Map<String, dynamic> dashboardJson() => <String, dynamic>{
  'as_of': '2030-02-10',
  'currency': 'CHF',
  'kpis': <String, dynamic>{
    'total_exposure': '1500.00',
    'total_open': '1000.00',
    'overdue_amount': '500.00',
    'over_90': '0.00',
    'dso': 42.5,
    'bad_debt_provision': '12.50',
    'net_realizable_value': '987.50',
    'blocked_customers': 1,
    'active_overrides': 0,
  },
  'aging': agingJson(),
  'blocked': <Map<String, dynamic>>[
    <String, dynamic>{
      'customer_id': 'c2',
      'reason': 'limit_exceeded',
      'exposure': '1500.00',
      'limit': '1000.00',
    },
  ],
};

Map<String, dynamic> limitJson({String granted = '1000.00'}) =>
    <String, dynamic>{
      'id': 'l1',
      'customer_id': 'c1',
      'currency': 'CHF',
      'granted_limit': granted,
      'insured_limit': null,
      'insured_cover': '0.00',
      'insurer_name': null,
      'policy_number': null,
      'coverage_percentage': null,
      'max_overdue_days': 30,
      'overdue_tolerance_amount': '0.00',
      'reaction_policy': 'block_order',
      'valid_from': '2030-01-01',
      'valid_to': null,
      'is_active': true,
      'notes': null,
    };

Map<String, dynamic> overrideJson({
  String id = 'o1',
  String? expiresAt = '2031-01-01T00:00:00Z',
  String? revokedAt,
}) => <String, dynamic>{
  'id': id,
  'customer_id': 'c1',
  'scope': 'order',
  'reason': 'Key customer',
  'authorized_by': 'Anna',
  'expires_at': expiresAt,
  'revoked_at': revokedAt,
  'revoke_reason': null,
  'created_at': '2030-01-05T10:00:00Z',
};

Map<String, dynamic> creditJson({
  bool blocked = false,
  bool hold = false,
  String outcome = 'ok',
  double? utilization = 50,
  bool withLimit = true,
  List<Map<String, dynamic>> overrides = const <Map<String, dynamic>>[],
}) => <String, dynamic>{
  'customer_id': 'c1',
  'as_of': '2030-02-10',
  'limit': withLimit ? limitJson() : null,
  'exposure': <String, dynamic>{
    'open_invoices': '600.00',
    'unbilled_delivery_notes': '100.00',
    'confirmed_orders': '50.00',
    'unreconciled_payments': '50.00',
    'total_exposure': '700.00',
    'overdue_amount': '300.00',
    'overdue_items': 1,
    'max_days_past_due': 12,
  },
  'utilization_percent': withLimit ? utilization : null,
  'available_credit': withLimit ? '300.00' : null,
  'insured_cover': '0.00',
  'uninsured_exposure': '700.00',
  'is_credit_hold': hold,
  'is_blocked': blocked,
  'decision': <String, dynamic>{
    'outcome': outcome,
    'reason': blocked ? 'Limit exceeded' : '',
    'breaches': blocked ? <String>['limit'] : <String>[],
    'overridden': false,
  },
  'overrides': overrides,
};

Map<String, dynamic> riskJson() => <String, dynamic>{
  'customer_id': 'c1',
  'score': 62.4,
  'rating': 'high',
  'factors': <Map<String, dynamic>>[
    <String, dynamic>{'key': 'overdue_ratio', 'value': 0.4, 'points': 20},
  ],
  'blocked': false,
};

Map<String, dynamic> paymentJson({String id = 'le1', String left = '60.00'}) =>
    <String, dynamic>{
      'ledger_entry_id': id,
      'reference': 'BANK-9',
      'date': '2030-02-01',
      'currency': 'CHF',
      'amount': '80.00',
      'unallocated': left,
    };

Map<String, dynamic> statementJson() => <String, dynamic>{
  'tenant': <String, dynamic>{'name': 'Acme'},
  'customer': <String, dynamic>{'id': 'c1', 'name': 'Rossi SA'},
  'currency': 'CHF',
  'period': <String, dynamic>{'from': '2030-01-01', 'to': '2030-02-10'},
  'as_of': '2030-02-10',
  'opening_balance': '100.00',
  'movements': <Map<String, dynamic>>[
    <String, dynamic>{
      'date': '2030-01-05',
      'value_date': '2030-01-05',
      'kind': 'invoice',
      'document_type': 'invoice',
      'reference': 'FT-1',
      'receivable_item_id': 'i1',
      'allocation_id': null,
      'currency': 'CHF',
      'debit': '300.00',
      'credit': '0.00',
      'due_date': '2030-02-05',
      'status': 'open',
      'balance': '400.00',
    },
    <String, dynamic>{
      'date': '2030-01-20',
      'value_date': '2030-01-20',
      'kind': 'payment',
      'document_type': 'payment',
      'reference': 'PAY-1',
      'receivable_item_id': 'i1',
      'allocation_id': 'a1',
      'currency': 'CHF',
      'debit': '0.00',
      'credit': '120.00',
      'due_date': null,
      'status': 'open',
      'balance': '280.00',
    },
  ],
  'closing_balance': '280.00',
  'open_items': <Map<String, dynamic>>[itemJson('i1', open: '180.00')],
  'total_open': '280.00',
  'total_overdue': '100.00',
  'aging': <String, dynamic>{'current': '180.00', '1_15': '100.00'},
  'credit': <String, dynamic>{},
};

Map<String, dynamic> envelope(Object data) => <String, dynamic>{'data': data};

// --- Models ----------------------------------------------------------------------------------------------------------

ReceivableItem item(
  String id, {
  String customerId = 'c1',
  String open = '100.00',
  int days = 0,
  String status = 'open',
  String number = 'FT-1',
  List<Map<String, dynamic>>? allocations,
}) => ReceivableItem.fromJson(
  itemJson(
    id,
    customerId: customerId,
    open: open,
    days: days,
    status: status,
    number: number,
    allocations: allocations,
  ),
);

// --- Fakes -----------------------------------------------------------------------------------------------------------

class FakeStatementExporter implements StatementExporter {
  final List<({String fileName, int length, String mimeType})> shared =
      <({String fileName, int length, String mimeType})>[];
  Object? failWith;

  @override
  Future<void> share({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final Object? e = failWith;
    if (e != null) {
      throw e;
    }
    shared.add((fileName: fileName, length: bytes.length, mimeType: mimeType));
  }
}

/// In-memory [ReceivablesRepository] with scriptable outcomes.
class FakeReceivablesRepository implements ReceivablesRepository {
  ReceivablesDashboard? dashboardCache;
  ReceivablesDashboard? dashboardRemote;
  ReceivablesException? refreshError;
  final List<String?> dashboardCurrencies = <String?>[];

  AgingReport? agingCache;
  AgingReport? agingRemote;
  CreditPosition? credit;
  RiskScore? risk;
  List<UnreconciledPayment> unreconciled = <UnreconciledPayment>[];
  List<ReceivableItem> items = <ReceivableItem>[];
  CustomerStatement? statementCache;
  CustomerStatement? statementRemote;
  ReceivablesException? downloadError;
  Uint8List downloadBytes = Uint8List.fromList(<int>[1, 2, 3]);
  final List<({StatementFormat format, DateTime? from, DateTime? to})>
  downloads = <({StatementFormat format, DateTime? from, DateTime? to})>[];

  /// What the next allocate/reverse/dispute answers.
  BookingStatus nextStatus = BookingStatus.sent;
  String nextDetail = '';
  List<PendingBooking> pending = <PendingBooking>[];

  final List<List<AllocationDraft>> allocations = <List<AllocationDraft>>[];
  final List<({String itemId, String allocationId})> reversals =
      <({String itemId, String allocationId})>[];
  final List<({String itemId, bool disputed, String? reason})> disputes =
      <({String itemId, bool disputed, String? reason})>[];
  final List<String> dismissed = <String>[];
  final List<String> retried = <String>[];
  int flushes = 0;

  void _failIfScripted() {
    final ReceivablesException? e = refreshError;
    if (e != null) {
      throw e;
    }
  }

  @override
  Future<ReceivablesDashboard?> cachedDashboard(
    String tenantId, {
    String? currency,
  }) async => dashboardCache;

  @override
  Future<ReceivablesDashboard> refreshDashboard(
    String tenantId, {
    String? currency,
  }) async {
    dashboardCurrencies.add(currency);
    _failIfScripted();
    final ReceivablesDashboard fresh = dashboardRemote!;
    dashboardCache = fresh;
    return fresh;
  }

  @override
  Future<AgingReport?> cachedAging(
    String tenantId, {
    String? customerId,
    String? currency,
  }) async => agingCache;

  @override
  Future<AgingReport> refreshAging(
    String tenantId, {
    String? customerId,
    String? currency,
  }) async {
    _failIfScripted();
    return agingCache = agingRemote ?? agingCache!;
  }

  @override
  Future<CreditPosition?> cachedCredit(String t, String id) async => credit;

  @override
  Future<CreditPosition> refreshCredit(String t, String id) async {
    _failIfScripted();
    return credit!;
  }

  @override
  Future<RiskScore?> cachedRisk(String t, String id) async => risk;

  @override
  Future<RiskScore> refreshRisk(String t, String id) async {
    _failIfScripted();
    return risk!;
  }

  @override
  Future<List<CreditLimit>> cachedCreditLimits(String t, String id) async =>
      const <CreditLimit>[];

  @override
  Future<List<CreditLimit>> refreshCreditLimits(String t, String id) async =>
      const <CreditLimit>[];

  @override
  Future<List<UnreconciledPayment>> cachedUnreconciled(
    String t,
    String id,
  ) async => unreconciled;

  @override
  Future<List<UnreconciledPayment>> refreshUnreconciled(
    String t,
    String id,
  ) async {
    _failIfScripted();
    return unreconciled;
  }

  @override
  Future<DsoResult?> cachedDso(
    String tenantId, {
    String? customerId,
    String? currency,
  }) async => null;

  @override
  Future<DsoResult> refreshDso(
    String tenantId, {
    String? customerId,
    String? currency,
    int? periodDays,
  }) async => throw const ReceivablesException(ReceivablesErrorKind.unknown);

  @override
  Future<ProvisionReport?> cachedProvision(
    String tenantId, {
    String? customerId,
    String? currency,
  }) async => null;

  @override
  Future<ProvisionReport> refreshProvision(
    String tenantId, {
    String? customerId,
    String? currency,
  }) async => throw const ReceivablesException(ReceivablesErrorKind.unknown);

  @override
  Future<List<ReceivableItem>> cachedItems(String t, String customerId) async =>
      sortItems(items.where((ReceivableItem i) => i.customerId == customerId));

  @override
  Future<List<ReceivableItem>> refreshItems(
    String t,
    String customerId, {
    String? currency,
  }) async {
    _failIfScripted();
    return cachedItems(t, customerId);
  }

  @override
  Future<ReceivableItem?> cachedItem(String t, String itemId) async {
    for (final ReceivableItem i in items) {
      if (i.id == itemId) {
        return i;
      }
    }
    return null;
  }

  @override
  Future<ReceivableItem> refreshItem(String t, String itemId) async {
    _failIfScripted();
    return (await cachedItem(t, itemId))!;
  }

  @override
  Future<CustomerStatement?> cachedStatement(
    String t,
    String customerId, {
    String? currency,
  }) async => statementCache;

  @override
  Future<CustomerStatement> refreshStatement(
    String t,
    String customerId, {
    DateTime? from,
    DateTime? to,
    String? currency,
  }) async {
    _failIfScripted();
    return statementCache = statementRemote!;
  }

  @override
  Future<Uint8List> downloadStatement(
    String customerId,
    StatementFormat format, {
    DateTime? from,
    DateTime? to,
    String? currency,
  }) async {
    final ReceivablesException? e = downloadError;
    if (e != null) {
      throw e;
    }
    downloads.add((format: format, from: from, to: to));
    return downloadBytes;
  }

  BookingOutcome _outcome() => BookingOutcome(nextStatus, detail: nextDetail);

  @override
  Future<BookingOutcome> allocate(
    String tenantId,
    List<AllocationDraft> drafts,
  ) async {
    allocations.add(drafts);
    if (nextStatus != BookingStatus.rejected) {
      for (final AllocationDraft d in drafts) {
        final int at = items.indexWhere((ReceivableItem i) => i.id == d.itemId);
        if (at >= 0) {
          final ReceivableItem old = items[at];
          final Money open = old.openAmount - d.amount;
          items[at] = ReceivableItem.fromJson(
            itemJson(
              old.id,
              customerId: old.customerId,
              open: open.toWire(),
              number: old.documentNumber,
              status: open.isPositive ? 'partially_paid' : 'paid',
            ),
          );
        }
      }
    }
    return _outcome();
  }

  @override
  Future<BookingOutcome> reverseAllocation(
    String tenantId,
    String itemId,
    String allocationId,
  ) async {
    reversals.add((itemId: itemId, allocationId: allocationId));
    return _outcome();
  }

  @override
  Future<BookingOutcome> setDispute(
    String tenantId,
    String itemId, {
    required bool disputed,
    String? reason,
  }) async {
    disputes.add((itemId: itemId, disputed: disputed, reason: reason));
    return _outcome();
  }

  @override
  Future<List<PendingBooking>> pendingActions(
    String tenantId, {
    String? itemId,
  }) async => itemId == null
      ? pending
      : pending.where((PendingBooking a) => a.itemId == itemId).toList();

  @override
  Future<void> retryAction(String tenantId, String queueUuid) async =>
      retried.add(queueUuid);

  @override
  Future<void> dismissAction(String queueUuid) async =>
      dismissed.add(queueUuid);

  @override
  Future<int> flush(String tenantId) async {
    flushes++;
    return 0;
  }
}
