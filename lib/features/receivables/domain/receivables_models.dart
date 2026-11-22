/// Models of Accounts Receivable and Credit Management (Mod 013), parsed from `/invoicing/receivables/*`.
///
/// Amounts reach the app as decimal strings and are held as [Money] (integer cents); aging buckets are always taken
/// from the `buckets` array of the response, never hardcoded.
library;

import 'package:flutter/foundation.dart';

import 'money.dart';

// --- JSON helpers ------------------------------------------------------------------------------------------------

Map<String, dynamic> _map(Object? v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

List<Map<String, dynamic>> _maps(Object? v) => <Map<String, dynamic>>[
  if (v is List)
    for (final dynamic e in v)
      if (e is Map) Map<String, dynamic>.from(e),
];

String _s(Object? v, [String fallback = '']) => v == null ? fallback : '$v';

String? _sn(Object? v) => v == null || '$v'.isEmpty ? null : '$v';

int _i(Object? v, [int fallback = 0]) =>
    v is num ? v.round() : int.tryParse('$v') ?? fallback;

double? _d(Object? v) =>
    v is num ? v.toDouble() : (v == null ? null : double.tryParse('$v'));

bool _b(Object? v) => v == true || v == 1 || v == '1' || v == 'true';

DateTime? _date(Object? v) => v == null ? null : DateTime.tryParse('$v');

Money _m(Object? v) => Money.parseOrZero(v);

Money? _mn(Object? v) => v == null ? null : Money.parse(v);

/// `YYYY-MM-DD`, the date format of the API.
String formatApiDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

// --- Vocabulary --------------------------------------------------------------------------------------------------

enum ItemStatus {
  open('open'),
  partiallyPaid('partially_paid'),
  paid('paid'),
  overdue('overdue'),
  disputed('disputed'),
  writtenOff('written_off'),
  unknown('');

  const ItemStatus(this.wire);

  final String wire;

  static ItemStatus fromWire(Object? value) {
    for (final ItemStatus s in values) {
      if (s.wire == value) {
        return s;
      }
    }
    return ItemStatus.unknown;
  }
}

enum AllocationType {
  payment('payment'),
  creditNote('credit_note'),
  debitAdjustment('debit_adjustment'),
  writeOff('write_off'),
  discount('discount');

  const AllocationType(this.wire);

  final String wire;

  /// The types a person can book from the phone (a debit adjustment is raised by the back office).
  static const List<AllocationType> bookable = <AllocationType>[
    payment,
    creditNote,
    writeOff,
    discount,
  ];

  static AllocationType fromWire(Object? value) {
    for (final AllocationType t in values) {
      if (t.wire == value) {
        return t;
      }
    }
    return AllocationType.payment;
  }
}

enum ReactionPolicy {
  warning('warning'),
  blockOrder('block_order'),
  blockDeliveryNote('block_delivery_note'),
  creditHold('credit_hold'),
  unknown('');

  const ReactionPolicy(this.wire);

  final String wire;

  static ReactionPolicy fromWire(Object? value) {
    for (final ReactionPolicy p in values) {
      if (p.wire == value) {
        return p;
      }
    }
    return ReactionPolicy.unknown;
  }
}

enum OverrideScope {
  all('all'),
  order('order'),
  deliveryNote('delivery_note'),
  unknown('');

  const OverrideScope(this.wire);

  final String wire;

  static OverrideScope fromWire(Object? value) {
    for (final OverrideScope s in values) {
      if (s.wire == value) {
        return s;
      }
    }
    return OverrideScope.unknown;
  }
}

enum DecisionOutcome {
  ok('ok'),
  warning('warning'),
  block('block');

  const DecisionOutcome(this.wire);

  final String wire;

  static DecisionOutcome fromWire(Object? value) {
    for (final DecisionOutcome d in values) {
      if (d.wire == value) {
        return d;
      }
    }
    return DecisionOutcome.ok;
  }
}

enum RiskRating {
  low('low'),
  medium('medium'),
  high('high'),
  critical('critical');

  const RiskRating(this.wire);

  final String wire;

  static RiskRating fromWire(Object? value) {
    for (final RiskRating r in values) {
      if (r.wire == value) {
        return r;
      }
    }
    return RiskRating.low;
  }

  /// Rating of a score the way the server derives it: below 25 low, below 50 medium, below 75 high.
  static RiskRating fromScore(double score) {
    if (score < 25) {
      return RiskRating.low;
    }
    if (score < 50) {
      return RiskRating.medium;
    }
    return score < 75 ? RiskRating.high : RiskRating.critical;
  }
}

// --- Aging -------------------------------------------------------------------------------------------------------

/// One aging bucket as the server defines it: `key` (`current`, `1_30`, `121_plus`...), `from` and `to` days past due
/// (`to` is `null` for the open-ended bucket).
@immutable
class AgingBucketDef {
  const AgingBucketDef({required this.key, required this.from, this.to});

  factory AgingBucketDef.fromJson(Map<String, dynamic> json) {
    final String key = _s(json['key']);
    final AgingBucketDef derived = AgingBucketDef.fromKey(key);
    return AgingBucketDef(
      key: key,
      from: json.containsKey('from') ? _i(json['from']) : derived.from,
      to: json.containsKey('to')
          ? (json['to'] == null ? null : _i(json['to']))
          : derived.to,
    );
  }

  /// Best-effort bounds of a key when the response carries no `buckets` array (`1_30`, `121_plus`, `current`).
  factory AgingBucketDef.fromKey(String key) {
    if (key == 'current') {
      return const AgingBucketDef(key: 'current', from: 0, to: 0);
    }
    final List<String> parts = key.split('_');
    final int from = int.tryParse(parts.first) ?? 0;
    final int? to = parts.length > 1 ? int.tryParse(parts[1]) : null;
    return AgingBucketDef(key: key, from: from, to: to);
  }

  final String key;
  final int from;
  final int? to;

  bool get isCurrent => key == 'current';
  bool get isOpenEnded => !isCurrent && to == null;

  bool containsDays(int daysPastDue) {
    if (isCurrent) {
      return daysPastDue <= 0;
    }
    return daysPastDue >= from && (to == null || daysPastDue <= to!);
  }

  @override
  bool operator ==(Object other) =>
      other is AgingBucketDef &&
      other.key == key &&
      other.from == from &&
      other.to == to;

  @override
  int get hashCode => Object.hash(key, from, to);
}

/// Key of the bucket an item with [daysPastDue] belongs to, or `null` when [buckets] has none for it.
String? bucketKeyOf(int daysPastDue, List<AgingBucketDef> buckets) {
  for (final AgingBucketDef b in buckets) {
    if (b.containsDays(daysPastDue)) {
      return b.key;
    }
  }
  return null;
}

/// The outstanding amounts of one customer per bucket.
@immutable
class AgingCustomer {
  const AgingCustomer({
    required this.customerId,
    required this.customerName,
    required this.buckets,
    required this.totalOpen,
    required this.totalOverdue,
    this.items = 0,
  });

  factory AgingCustomer.fromJson(Map<String, dynamic> json) => AgingCustomer(
    customerId: _s(json['customer_id']),
    customerName: _s(json['customer_name']),
    buckets: <String, Money>{
      for (final MapEntry<String, dynamic> e in _map(json['buckets']).entries)
        e.key: _m(e.value),
    },
    totalOpen: _m(json['total_open']),
    totalOverdue: _m(json['total_overdue']),
    items: _i(json['items']),
  );

  final String customerId;
  final String customerName;
  final Map<String, Money> buckets;
  final Money totalOpen;
  final Money totalOverdue;
  final int items;

  Money amountIn(String bucketKey) => buckets[bucketKey] ?? Money.zero;
}

/// `GET /aging`: totals per bucket (in the order of [buckets]) and the customers behind them.
@immutable
class AgingReport {
  const AgingReport({
    required this.buckets,
    required this.totals,
    required this.totalOpen,
    required this.totalOverdue,
    required this.over90,
    this.asOf,
    this.currency = '',
    this.availableCurrencies = const <String>[],
    this.customers = const <AgingCustomer>[],
  });

  factory AgingReport.fromJson(Map<String, dynamic> json) {
    final Map<String, Money> totals = <String, Money>{
      for (final MapEntry<String, dynamic> e in _map(json['totals']).entries)
        e.key: _m(e.value),
    };
    List<AgingBucketDef> buckets = <AgingBucketDef>[
      for (final Map<String, dynamic> b in _maps(json['buckets']))
        AgingBucketDef.fromJson(b),
    ];
    if (buckets.isEmpty) {
      // Defensive: no definitions sent, fall back to the keys of the totals in the order received.
      buckets = <AgingBucketDef>[
        for (final String key in totals.keys) AgingBucketDef.fromKey(key),
      ];
    }
    return AgingReport(
      asOf: _date(json['as_of']),
      currency: _s(json['currency']),
      availableCurrencies: <String>[
        if (json['available_currencies'] is List)
          for (final dynamic c in json['available_currencies'] as List) '$c',
      ],
      buckets: buckets,
      totals: totals,
      totalOpen: _m(json['total_open']),
      totalOverdue: _m(json['total_overdue']),
      over90: _m(json['over_90']),
      customers: <AgingCustomer>[
        for (final Map<String, dynamic> c in _maps(json['customers']))
          AgingCustomer.fromJson(c),
      ],
    );
  }

  final DateTime? asOf;
  final String currency;
  final List<String> availableCurrencies;
  final List<AgingBucketDef> buckets;
  final Map<String, Money> totals;
  final Money totalOpen;
  final Money totalOverdue;
  final Money over90;
  final List<AgingCustomer> customers;

  Money totalOf(String bucketKey) => totals[bucketKey] ?? Money.zero;

  /// Sum of the bucket totals; equals [totalOpen] on a consistent response.
  Money get bucketSum => Money.sum(totals.values);

  /// Share of [bucketKey] in the open total, `0..1`, for the bars.
  double shareOf(String bucketKey) => totalOf(bucketKey).ratio(totalOpen);

  /// Customers with something in [bucketKey], largest amount first.
  List<AgingCustomer> customersIn(String bucketKey) {
    final List<AgingCustomer> rows = customers
        .where((AgingCustomer c) => c.amountIn(bucketKey).isPositive)
        .toList();
    rows.sort(
      (AgingCustomer a, AgingCustomer b) =>
          b.amountIn(bucketKey).compareTo(a.amountIn(bucketKey)),
    );
    return rows;
  }
}

// --- Items and allocations ---------------------------------------------------------------------------------------

@immutable
class ReceivableAllocation {
  const ReceivableAllocation({
    required this.id,
    required this.receivableItemId,
    required this.type,
    required this.amount,
    this.origin = '',
    this.sourceId,
    this.sourceReference = '',
    this.valueDate,
    this.notes = '',
    this.reversedAt,
  });

  factory ReceivableAllocation.fromJson(Map<String, dynamic> json) =>
      ReceivableAllocation(
        id: _s(json['id']),
        receivableItemId: _s(json['receivable_item_id']),
        type: AllocationType.fromWire(json['source_type'] ?? json['type']),
        amount: _m(json['amount']),
        origin: _s(json['origin']),
        sourceId: _sn(json['source_id']),
        sourceReference: _s(json['source_reference']),
        valueDate: _date(json['value_date']),
        notes: _s(json['notes']),
        reversedAt: _date(json['reversed_at']),
      );

  final String id;
  final String receivableItemId;
  final AllocationType type;
  final Money amount;
  final String origin;
  final String? sourceId;
  final String sourceReference;
  final DateTime? valueDate;
  final String notes;
  final DateTime? reversedAt;

  bool get isReversed => reversedAt != null;
}

@immutable
class ReceivableItem {
  const ReceivableItem({
    required this.id,
    required this.customerId,
    required this.documentNumber,
    required this.currency,
    required this.originalAmount,
    required this.openAmount,
    required this.settledAmount,
    required this.status,
    this.invoiceId,
    this.sequence = 1,
    this.documentType = '',
    this.issueDate,
    this.dueDate,
    this.valueDate,
    this.storedStatus = ItemStatus.unknown,
    this.daysPastDue = 0,
    this.disputeReason,
    this.allocations = const <ReceivableAllocation>[],
  });

  factory ReceivableItem.fromJson(Map<String, dynamic> json) => ReceivableItem(
    id: _s(json['id']),
    customerId: _s(json['customer_id']),
    invoiceId: _sn(json['invoice_id']),
    sequence: _i(json['sequence'], 1),
    documentType: _s(json['document_type']),
    documentNumber: _s(json['document_number']),
    currency: _s(json['currency']),
    originalAmount: _m(json['original_amount']),
    openAmount: _m(json['open_amount']),
    settledAmount: _m(json['settled_amount']),
    issueDate: _date(json['issue_date']),
    dueDate: _date(json['due_date']),
    valueDate: _date(json['value_date']),
    status: ItemStatus.fromWire(json['status']),
    storedStatus: ItemStatus.fromWire(json['stored_status']),
    daysPastDue: _i(json['days_past_due']),
    disputeReason: _sn(json['dispute_reason']),
    allocations: <ReceivableAllocation>[
      for (final Map<String, dynamic> a in _maps(json['allocations']))
        ReceivableAllocation.fromJson(a),
    ],
  );

  final String id;
  final String customerId;
  final String? invoiceId;
  final int sequence;
  final String documentType;
  final String documentNumber;
  final String currency;
  final Money originalAmount;
  final Money openAmount;
  final Money settledAmount;
  final DateTime? issueDate;
  final DateTime? dueDate;
  final DateTime? valueDate;
  final ItemStatus status;
  final ItemStatus storedStatus;
  final int daysPastDue;
  final String? disputeReason;
  final List<ReceivableAllocation> allocations;

  bool get isDisputed => status == ItemStatus.disputed;
  bool get isOverdue => status == ItemStatus.overdue || daysPastDue > 0;

  /// Money can still be booked against it.
  bool get canAllocate =>
      openAmount.isPositive &&
      status != ItemStatus.paid &&
      status != ItemStatus.writtenOff;

  /// Allocations that can still be reversed.
  List<ReceivableAllocation> get reversible =>
      allocations.where((ReceivableAllocation a) => !a.isReversed).toList();
}

/// An item sorted for the list: most days past due first, then the larger open amount.
List<ReceivableItem> sortItems(Iterable<ReceivableItem> items) {
  final List<ReceivableItem> rows = items.toList();
  rows.sort((ReceivableItem a, ReceivableItem b) {
    final int byDays = b.daysPastDue.compareTo(a.daysPastDue);
    return byDays != 0 ? byDays : b.openAmount.compareTo(a.openAmount);
  });
  return rows;
}

/// Items of [bucketKey] (all of them when `null`).
List<ReceivableItem> itemsInBucket(
  List<ReceivableItem> items,
  String? bucketKey,
  List<AgingBucketDef> buckets,
) {
  if (bucketKey == null) {
    return items;
  }
  return items
      .where(
        (ReceivableItem i) => bucketKeyOf(i.daysPastDue, buckets) == bucketKey,
      )
      .toList();
}

/// A payment on the books that is not yet matched to an invoice.
@immutable
class UnreconciledPayment {
  const UnreconciledPayment({
    required this.ledgerEntryId,
    required this.reference,
    required this.currency,
    required this.amount,
    required this.unallocated,
    this.date,
  });

  factory UnreconciledPayment.fromJson(Map<String, dynamic> json) =>
      UnreconciledPayment(
        ledgerEntryId: _s(json['ledger_entry_id']),
        reference: _s(json['reference']),
        date: _date(json['date']),
        currency: _s(json['currency']),
        amount: _m(json['amount']),
        unallocated: _m(json['unallocated']),
      );

  final String ledgerEntryId;
  final String reference;
  final DateTime? date;
  final String currency;
  final Money amount;
  final Money unallocated;
}

// --- Credit ------------------------------------------------------------------------------------------------------

@immutable
class CreditLimit {
  const CreditLimit({
    required this.id,
    required this.customerId,
    required this.currency,
    required this.grantedLimit,
    required this.reactionPolicy,
    this.insuredLimit,
    this.insuredCover,
    this.insurerName,
    this.policyNumber,
    this.coveragePercentage,
    this.maxOverdueDays,
    this.overdueToleranceAmount,
    this.validFrom,
    this.validTo,
    this.isActive = true,
    this.notes,
  });

  factory CreditLimit.fromJson(Map<String, dynamic> json) => CreditLimit(
    id: _s(json['id']),
    customerId: _s(json['customer_id']),
    currency: _s(json['currency']),
    grantedLimit: _m(json['granted_limit']),
    insuredLimit: _mn(json['insured_limit']),
    insuredCover: _mn(json['insured_cover']),
    insurerName: _sn(json['insurer_name']),
    policyNumber: _sn(json['policy_number']),
    coveragePercentage: _d(json['coverage_percentage']),
    maxOverdueDays: json['max_overdue_days'] == null
        ? null
        : _i(json['max_overdue_days']),
    overdueToleranceAmount: _mn(json['overdue_tolerance_amount']),
    reactionPolicy: ReactionPolicy.fromWire(json['reaction_policy']),
    validFrom: _date(json['valid_from']),
    validTo: _date(json['valid_to']),
    isActive: json.containsKey('is_active') ? _b(json['is_active']) : true,
    notes: _sn(json['notes']),
  );

  final String id;
  final String customerId;
  final String currency;
  final Money grantedLimit;
  final Money? insuredLimit;
  final Money? insuredCover;
  final String? insurerName;
  final String? policyNumber;
  final double? coveragePercentage;
  final int? maxOverdueDays;
  final Money? overdueToleranceAmount;
  final ReactionPolicy reactionPolicy;
  final DateTime? validFrom;
  final DateTime? validTo;
  final bool isActive;
  final String? notes;

  bool get isInsured =>
      insurerName != null || (insuredLimit?.isPositive ?? false);
}

@immutable
class CreditOverride {
  const CreditOverride({
    required this.id,
    required this.customerId,
    required this.scope,
    required this.reason,
    this.authorizedBy,
    this.expiresAt,
    this.revokedAt,
    this.revokeReason,
    this.createdAt,
  });

  factory CreditOverride.fromJson(Map<String, dynamic> json) => CreditOverride(
    id: _s(json['id']),
    customerId: _s(json['customer_id']),
    scope: OverrideScope.fromWire(json['scope']),
    reason: _s(json['reason']),
    authorizedBy: _sn(json['authorized_by']),
    expiresAt: _date(json['expires_at']),
    revokedAt: _date(json['revoked_at']),
    revokeReason: _sn(json['revoke_reason']),
    createdAt: _date(json['created_at']),
  );

  final String id;
  final String customerId;
  final OverrideScope scope;
  final String reason;
  final String? authorizedBy;
  final DateTime? expiresAt;
  final DateTime? revokedAt;
  final String? revokeReason;
  final DateTime? createdAt;

  /// In force at [now]: not revoked and not expired.
  bool isActiveAt(DateTime now) =>
      revokedAt == null && (expiresAt == null || expiresAt!.isAfter(now));
}

/// The components of a customer's credit exposure.
@immutable
class CreditExposure {
  const CreditExposure({
    this.openInvoices = Money.zero,
    this.unbilledDeliveryNotes = Money.zero,
    this.confirmedOrders = Money.zero,
    this.unreconciledPayments = Money.zero,
    this.totalExposure = Money.zero,
    this.overdueAmount = Money.zero,
    this.overdueItems = 0,
    this.maxDaysPastDue = 0,
  });

  factory CreditExposure.fromJson(Map<String, dynamic> json) => CreditExposure(
    openInvoices: _m(json['open_invoices']),
    unbilledDeliveryNotes: _m(json['unbilled_delivery_notes']),
    confirmedOrders: _m(json['confirmed_orders']),
    unreconciledPayments: _m(json['unreconciled_payments']),
    totalExposure: _m(json['total_exposure']),
    overdueAmount: _m(json['overdue_amount']),
    overdueItems: _i(json['overdue_items']),
    maxDaysPastDue: _i(json['max_days_past_due']),
  );

  final Money openInvoices;
  final Money unbilledDeliveryNotes;
  final Money confirmedOrders;
  final Money unreconciledPayments;
  final Money totalExposure;
  final Money overdueAmount;
  final int overdueItems;
  final int maxDaysPastDue;

  /// Open invoices + unbilled delivery notes + confirmed orders - unreconciled payments, the way the server defines
  /// the exposure.
  Money get computedTotal =>
      openInvoices +
      unbilledDeliveryNotes +
      confirmedOrders -
      unreconciledPayments;

  bool get isConsistent => computedTotal == totalExposure;
}

/// How full the credit line is.
enum UtilisationLevel { ok, warning, exceeded }

/// Share of the limit used, from the server percentage; below 80 is fine, from 80 a warning, from 100 exceeded.
UtilisationLevel utilisationLevel(double? percent) {
  if (percent == null || percent < 80) {
    return UtilisationLevel.ok;
  }
  return percent < 100 ? UtilisationLevel.warning : UtilisationLevel.exceeded;
}

/// Percent of [limit] taken by [exposure], one decimal, `null` without a positive limit. Used when a cached position
/// has to be re-evaluated offline.
double? computeUtilisationPercent(Money exposure, Money? limit) {
  if (limit == null || !limit.isPositive) {
    return null;
  }
  return (exposure.minor * 1000 / limit.minor).round() / 10;
}

/// Credit still available: the limit minus the exposure, never negative; `null` without a limit.
Money? computeAvailableCredit(Money exposure, Money? limit) {
  if (limit == null) {
    return null;
  }
  final Money left = limit - exposure;
  return left.isNegative ? Money.zero : left;
}

@immutable
class CreditDecision {
  const CreditDecision({
    this.outcome = DecisionOutcome.ok,
    this.reason = '',
    this.breaches = const <String>[],
    this.overridden = false,
  });

  /// The `decision` of `/customers/{id}/credit`: an outcome string, or an object shaped like the `/credit-check`
  /// answer (`outcome`, `reason`, `breaches`, `overridden`).
  factory CreditDecision.fromJson(Object? json) {
    if (json is Map) {
      final Map<String, dynamic> m = Map<String, dynamic>.from(json);
      return CreditDecision(
        outcome: DecisionOutcome.fromWire(m['outcome']),
        reason: _s(m['reason']),
        breaches: <String>[
          if (m['breaches'] is List)
            for (final dynamic b in m['breaches'] as List)
              if (b is Map)
                _s(b['reason'] ?? b['code'] ?? b['type'] ?? b['key'])
              else
                '$b',
        ],
        overridden: _b(m['overridden']),
      );
    }
    if (json is String) {
      return CreditDecision(outcome: DecisionOutcome.fromWire(json));
    }
    return const CreditDecision();
  }

  final DecisionOutcome outcome;
  final String reason;
  final List<String> breaches;
  final bool overridden;
}

/// `GET /customers/{id}/credit`.
@immutable
class CreditPosition {
  const CreditPosition({
    required this.customerId,
    required this.exposure,
    required this.decision,
    this.asOf,
    this.limit,
    this.utilizationPercent,
    this.availableCredit,
    this.insuredCover = Money.zero,
    this.uninsuredExposure = Money.zero,
    this.isCreditHold = false,
    this.isBlocked = false,
    this.overrides = const <CreditOverride>[],
  });

  factory CreditPosition.fromJson(Map<String, dynamic> json) => CreditPosition(
    customerId: _s(json['customer_id']),
    asOf: _date(json['as_of']),
    limit: json['limit'] is Map
        ? CreditLimit.fromJson(_map(json['limit']))
        : null,
    exposure: CreditExposure.fromJson(_map(json['exposure'])),
    utilizationPercent: _d(json['utilization_percent']),
    availableCredit: _mn(json['available_credit']),
    insuredCover: _m(json['insured_cover']),
    uninsuredExposure: _m(json['uninsured_exposure']),
    isCreditHold: _b(json['is_credit_hold']),
    isBlocked: _b(json['is_blocked']),
    decision: CreditDecision.fromJson(json['decision']),
    overrides: <CreditOverride>[
      for (final Map<String, dynamic> o in _maps(json['overrides']))
        CreditOverride.fromJson(o),
    ],
  );

  final String customerId;
  final DateTime? asOf;
  final CreditLimit? limit;
  final CreditExposure exposure;
  final double? utilizationPercent;
  final Money? availableCredit;
  final Money insuredCover;
  final Money uninsuredExposure;
  final bool isCreditHold;
  final bool isBlocked;
  final CreditDecision decision;
  final List<CreditOverride> overrides;

  UtilisationLevel get level => utilisationLevel(utilizationPercent);

  /// Overrides in force at [now].
  List<CreditOverride> activeOverrides(DateTime now) =>
      overrides.where((CreditOverride o) => o.isActiveAt(now)).toList();

  /// The banner to show: a block (or credit hold), a warning, or nothing.
  CreditAlert get alert {
    if (isBlocked ||
        isCreditHold ||
        decision.outcome == DecisionOutcome.block) {
      return CreditAlert.blocked;
    }
    if (decision.outcome == DecisionOutcome.warning ||
        level != UtilisationLevel.ok ||
        exposure.overdueItems > 0 && limit != null) {
      return CreditAlert.warning;
    }
    return CreditAlert.none;
  }
}

enum CreditAlert { none, warning, blocked }

@immutable
class RiskFactor {
  const RiskFactor({
    required this.key,
    required this.value,
    required this.points,
  });

  factory RiskFactor.fromJson(Map<String, dynamic> json) => RiskFactor(
    key: _s(json['key']),
    value: _s(json['value']),
    points: _d(json['points']) ?? 0,
  );

  final String key;
  final String value;
  final double points;
}

@immutable
class RiskScore {
  const RiskScore({
    required this.customerId,
    required this.score,
    required this.rating,
    this.factors = const <RiskFactor>[],
    this.blocked = false,
  });

  factory RiskScore.fromJson(Map<String, dynamic> json) {
    final double score = _d(json['score']) ?? 0;
    return RiskScore(
      customerId: _s(json['customer_id']),
      score: score,
      rating: json['rating'] == null
          ? RiskRating.fromScore(score)
          : RiskRating.fromWire(json['rating']),
      factors: <RiskFactor>[
        for (final Map<String, dynamic> f in _maps(json['factors']))
          RiskFactor.fromJson(f),
      ],
      blocked: _b(json['blocked']),
    );
  }

  final String customerId;
  final double score;
  final RiskRating rating;
  final List<RiskFactor> factors;
  final bool blocked;
}

// --- DSO and provision -------------------------------------------------------------------------------------------

@immutable
class DsoResult {
  const DsoResult({
    required this.periodDays,
    required this.receivables,
    required this.creditSales,
    this.asOf,
    this.currency = '',
    this.dso,
  });

  factory DsoResult.fromJson(Map<String, dynamic> json) => DsoResult(
    asOf: _date(json['as_of']),
    periodDays: _i(json['period_days'], 90),
    currency: _s(json['currency']),
    receivables: _m(json['receivables']),
    creditSales: _m(json['credit_sales']),
    dso: _d(json['dso']),
  );

  final DateTime? asOf;
  final int periodDays;
  final String currency;
  final Money receivables;
  final Money creditSales;

  /// `null` when there are receivables but no sales in the period.
  final double? dso;

  /// Receivables / credit sales x period days, one decimal; `null` without sales (the server's definition).
  static double? compute(Money receivables, Money creditSales, int periodDays) {
    if (!creditSales.isPositive) {
      return null;
    }
    return (receivables.minor * periodDays * 10 / creditSales.minor).round() /
        10;
  }
}

@immutable
class ProvisionLine {
  const ProvisionLine({
    required this.bucket,
    required this.openAmount,
    required this.ratePercent,
    required this.provision,
    this.isDefaultRate = true,
  });

  factory ProvisionLine.fromJson(Map<String, dynamic> json) => ProvisionLine(
    bucket: AgingBucketDef.fromJson(json),
    openAmount: _m(json['open_amount']),
    ratePercent: _d(json['rate_percent']) ?? 0,
    provision: _m(json['provision']),
    isDefaultRate: json.containsKey('is_default_rate')
        ? _b(json['is_default_rate'])
        : true,
  );

  final AgingBucketDef bucket;
  final Money openAmount;
  final double ratePercent;
  final Money provision;
  final bool isDefaultRate;
}

@immutable
class ProvisionReport {
  const ProvisionReport({
    required this.lines,
    required this.totalOpen,
    required this.totalProvision,
    required this.netRealizableValue,
    this.currency = '',
  });

  factory ProvisionReport.fromJson(Map<String, dynamic> json) =>
      ProvisionReport(
        currency: _s(json['currency']),
        lines: <ProvisionLine>[
          for (final Map<String, dynamic> l in _maps(json['lines']))
            ProvisionLine.fromJson(l),
        ],
        totalOpen: _m(json['total_open']),
        totalProvision: _m(json['total_provision']),
        netRealizableValue: _m(json['net_realizable_value']),
      );

  final String currency;
  final List<ProvisionLine> lines;
  final Money totalOpen;
  final Money totalProvision;
  final Money netRealizableValue;
}

// --- Dashboard and statement -------------------------------------------------------------------------------------

@immutable
class BlockedCustomer {
  const BlockedCustomer({
    required this.customerId,
    required this.reason,
    required this.exposure,
    this.limit,
    this.customerName = '',
  });

  factory BlockedCustomer.fromJson(Map<String, dynamic> json) =>
      BlockedCustomer(
        customerId: _s(json['customer_id']),
        customerName: _s(json['customer_name'] ?? json['name']),
        reason: _s(json['reason']),
        exposure: _m(json['exposure']),
        limit: _mn(json['limit']),
      );

  final String customerId;
  final String customerName;
  final String reason;
  final Money exposure;
  final Money? limit;
}

@immutable
class ReceivablesKpis {
  const ReceivablesKpis({
    this.totalExposure = Money.zero,
    this.totalOpen = Money.zero,
    this.overdueAmount = Money.zero,
    this.over90 = Money.zero,
    this.dso,
    this.badDebtProvision = Money.zero,
    this.netRealizableValue = Money.zero,
    this.blockedCustomers = 0,
    this.activeOverrides = 0,
  });

  factory ReceivablesKpis.fromJson(Map<String, dynamic> json) =>
      ReceivablesKpis(
        totalExposure: _m(json['total_exposure']),
        totalOpen: _m(json['total_open']),
        overdueAmount: _m(json['overdue_amount']),
        over90: _m(json['over_90']),
        dso: _d(json['dso']),
        badDebtProvision: _m(json['bad_debt_provision']),
        netRealizableValue: _m(json['net_realizable_value']),
        blockedCustomers: _i(json['blocked_customers']),
        activeOverrides: _i(json['active_overrides']),
      );

  final Money totalExposure;
  final Money totalOpen;
  final Money overdueAmount;
  final Money over90;
  final double? dso;
  final Money badDebtProvision;
  final Money netRealizableValue;
  final int blockedCustomers;
  final int activeOverrides;
}

@immutable
class ReceivablesDashboard {
  const ReceivablesDashboard({
    required this.kpis,
    required this.aging,
    required this.blocked,
    this.asOf,
    this.currency = '',
  });

  factory ReceivablesDashboard.fromJson(Map<String, dynamic> json) =>
      ReceivablesDashboard(
        asOf: _date(json['as_of']),
        currency: _s(json['currency']),
        kpis: ReceivablesKpis.fromJson(_map(json['kpis'])),
        aging: AgingReport.fromJson(_map(json['aging'])),
        blocked: <BlockedCustomer>[
          for (final Map<String, dynamic> b in _maps(json['blocked']))
            BlockedCustomer.fromJson(b),
        ],
      );

  final DateTime? asOf;
  final String currency;
  final ReceivablesKpis kpis;
  final AgingReport aging;
  final List<BlockedCustomer> blocked;
}

@immutable
class LedgerMovement {
  const LedgerMovement({
    required this.kind,
    required this.reference,
    required this.debit,
    required this.credit,
    required this.balance,
    this.date,
    this.valueDate,
    this.documentType = '',
    this.receivableItemId,
    this.allocationId,
    this.currency = '',
    this.dueDate,
    this.status = '',
  });

  factory LedgerMovement.fromJson(Map<String, dynamic> json) => LedgerMovement(
    date: _date(json['date']),
    valueDate: _date(json['value_date']),
    kind: _s(json['kind']),
    documentType: _s(json['document_type']),
    reference: _s(json['reference']),
    receivableItemId: _sn(json['receivable_item_id']),
    allocationId: _sn(json['allocation_id']),
    currency: _s(json['currency']),
    debit: _m(json['debit']),
    credit: _m(json['credit']),
    dueDate: _date(json['due_date']),
    status: _s(json['status']),
    balance: _m(json['balance']),
  );

  final DateTime? date;
  final DateTime? valueDate;
  final String kind;
  final String documentType;
  final String reference;
  final String? receivableItemId;
  final String? allocationId;
  final String currency;
  final Money debit;
  final Money credit;
  final DateTime? dueDate;
  final String status;
  final Money balance;
}

/// `GET /customers/{id}/statement`.
@immutable
class CustomerStatement {
  const CustomerStatement({
    required this.customerId,
    required this.customerName,
    required this.currency,
    required this.openingBalance,
    required this.closingBalance,
    required this.totalOpen,
    required this.totalOverdue,
    this.from,
    this.to,
    this.asOf,
    this.movements = const <LedgerMovement>[],
    this.openItems = const <ReceivableItem>[],
    this.aging = const <String, Money>{},
  });

  factory CustomerStatement.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> customer = _map(json['customer']);
    final Map<String, dynamic> period = _map(json['period']);
    final Map<String, dynamic> agingJson = _map(json['aging']);
    // The aging block is either `{bucketKey: amount}` or the `/aging` shape with a `totals` map.
    final Map<String, dynamic> agingTotals = agingJson['totals'] is Map
        ? _map(agingJson['totals'])
        : agingJson;
    return CustomerStatement(
      customerId: _s(customer['id'] ?? customer['customer_id']),
      customerName: _s(
        customer['name'] ??
            customer['customer_name'] ??
            customer['company_name'],
      ),
      currency: _s(json['currency']),
      from: _date(period['from']),
      to: _date(period['to']),
      asOf: _date(json['as_of']),
      openingBalance: _m(json['opening_balance']),
      movements: <LedgerMovement>[
        for (final Map<String, dynamic> m in _maps(json['movements']))
          LedgerMovement.fromJson(m),
      ],
      closingBalance: _m(json['closing_balance']),
      openItems: <ReceivableItem>[
        for (final Map<String, dynamic> i in _maps(json['open_items']))
          ReceivableItem.fromJson(i),
      ],
      totalOpen: _m(json['total_open']),
      totalOverdue: _m(json['total_overdue']),
      aging: <String, Money>{
        for (final MapEntry<String, dynamic> e in agingTotals.entries)
          if (e.value is String || e.value is num) e.key: _m(e.value),
      },
    );
  }

  final String customerId;
  final String customerName;
  final String currency;
  final DateTime? from;
  final DateTime? to;
  final DateTime? asOf;
  final Money openingBalance;
  final List<LedgerMovement> movements;
  final Money closingBalance;
  final List<ReceivableItem> openItems;
  final Money totalOpen;
  final Money totalOverdue;
  final Map<String, Money> aging;

  /// Opening balance + debits - credits; equals [closingBalance] on a consistent statement.
  Money get computedClosing =>
      openingBalance +
      Money.sum(movements.map((LedgerMovement m) => m.debit)) -
      Money.sum(movements.map((LedgerMovement m) => m.credit));
}

// --- Writes ------------------------------------------------------------------------------------------------------

/// One line of `POST /allocations`.
@immutable
class AllocationDraft {
  const AllocationDraft({
    required this.itemId,
    required this.type,
    required this.amount,
    required this.valueDate,
    this.sourceId,
    this.reference,
    this.notes,
  });

  final String itemId;
  final AllocationType type;
  final Money amount;
  final DateTime valueDate;

  /// Ledger entry of an unreconciled payment, or the credit note invoice id.
  final String? sourceId;
  final String? reference;
  final String? notes;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'receivable_item_id': itemId,
    'type': type.wire,
    'amount': amount.toWire(),
    'value_date': formatApiDate(valueDate),
    'source_id': ?sourceId,
    if (reference != null && reference!.trim().isNotEmpty)
      'reference': reference!.trim(),
    if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
  };
}

/// What is wrong with a draft, checked before it goes in the outbox.
enum DraftIssue { amountInvalid, exceedsOpen, sourceRequired, exceedsSource }

/// Local checks of an allocation against the item it settles ([openAmount]) and, for a payment taken from an
/// unreconciled one, what is left on it ([sourceAvailable]).
List<DraftIssue> validateDraft(
  AllocationDraft draft, {
  required Money openAmount,
  Money? sourceAvailable,
}) {
  final List<DraftIssue> issues = <DraftIssue>[];
  if (!draft.amount.isPositive) {
    issues.add(DraftIssue.amountInvalid);
    return issues;
  }
  if (draft.type != AllocationType.debitAdjustment &&
      draft.amount > openAmount) {
    issues.add(DraftIssue.exceedsOpen);
  }
  if (draft.type == AllocationType.creditNote &&
      (draft.sourceId == null || draft.sourceId!.trim().isEmpty)) {
    issues.add(DraftIssue.sourceRequired);
  }
  if (draft.type == AllocationType.payment &&
      draft.sourceId != null &&
      sourceAvailable != null &&
      draft.amount > sourceAvailable) {
    issues.add(DraftIssue.exceedsSource);
  }
  return issues;
}

enum ReceivablesActionKind { allocation, reversal, dispute }

/// A write waiting in (or refused by) the outbox.
@immutable
class PendingBooking {
  const PendingBooking({
    required this.queueUuid,
    required this.kind,
    required this.rejected,
    this.itemId,
    this.allocationId,
    this.amount,
    this.detail = '',
  });

  final String queueUuid;
  final ReceivablesActionKind kind;
  final bool rejected;
  final String? itemId;
  final String? allocationId;
  final Money? amount;
  final String detail;
}

enum BookingStatus { sent, queued, rejected }

class BookingOutcome {
  const BookingOutcome(this.status, {this.detail = ''});

  final BookingStatus status;
  final String detail;
}

enum ReceivablesErrorKind { offline, forbidden, notFound, invalid, unknown }

class ReceivablesException implements Exception {
  const ReceivablesException(this.kind, {this.detail = ''});

  final ReceivablesErrorKind kind;

  /// The `message` of the server answer, when there was one.
  final String detail;

  @override
  String toString() => 'ReceivablesException($kind, $detail)';
}

/// Format of a customer statement download.
enum StatementFormat {
  pdf('pdf', 'application/pdf'),
  xlsx(
    'xlsx',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  );

  const StatementFormat(this.extension, this.mimeType);

  final String extension;
  final String mimeType;
}
