/// Models of the project billing view (Mod 081), parsed from `/projects/{id}/billing-contract`, `/billing/unbilled-summary`,
/// `/sal-certificates`, `/retention` and `/retainer`.
///
/// Amounts reach the app as decimal strings; they are parsed to doubles for display and for the SAL calculator, never for
/// accounting: the API remains the source of truth of every certificate.
library;

double? _number(Object? value) {
  if (value == null) {
    return null;
  }
  return value is num ? value.toDouble() : double.tryParse('$value');
}

double _amount(Object? value) => _number(value) ?? 0;

String? _text(Object? value) {
  final String text = '${value ?? ''}'.trim();
  return text.isEmpty ? null : text;
}

DateTime? _date(Object? value) {
  final String? text = _text(value);
  return text == null ? null : DateTime.tryParse(text);
}

int _cents(double value) => (value * 100).round();

double _fromCents(int cents) => cents / 100;

/// Whether the work in progress is a contract asset (recognised above billed), a liability (billed above) or even.
enum WipNature { contractAsset, contractLiability, balanced }

WipNature wipNature(double difference) {
  final int cents = _cents(difference);
  if (cents > 0) {
    return WipNature.contractAsset;
  }
  return cents < 0 ? WipNature.contractLiability : WipNature.balanced;
}

/// Terms of the billing contract that the SAL calculator needs.
class BillingContractTerms {
  const BillingContractTerms({
    required this.model,
    required this.status,
    required this.jurisdiction,
    required this.currency,
    required this.contractValue,
    required this.advancePercent,
    required this.advanceAmount,
    required this.advanceRecouped,
    required this.retentionPercent,
    this.cig,
  });

  factory BillingContractTerms.fromJson(Map<String, dynamic> json) =>
      BillingContractTerms(
        model: _text(json['billing_model']) ?? 'time_and_materials',
        status: _text(json['billing_status']) ?? 'draft',
        jurisdiction: _text(json['fiscal_jurisdiction']) ?? 'IT',
        currency: _text(json['currency_code']) ?? 'EUR',
        contractValue: _amount(json['contract_total_value']),
        advancePercent: _amount(json['advance_payment_percent']),
        advanceAmount: _amount(json['advance_payment_amount']),
        advanceRecouped: _amount(json['advance_recouped_amount']),
        retentionPercent: _amount(json['retention_guarantee_percent']),
        cig: _text(json['cig']),
      );

  final String model;
  final String status;
  final String jurisdiction;
  final String currency;
  final double contractValue;
  final double advancePercent;
  final double advanceAmount;
  final double advanceRecouped;
  final double retentionPercent;
  final String? cig;

  bool get isActive => status == 'active';

  bool get billsProgress => model == 'sal_progress' || model == 'hybrid';

  /// The advance to recoup in total: the fixed amount, else the percentage of the contract value.
  double get advanceTotal => advanceAmount > 0
      ? advanceAmount
      : _fromCents(_cents(contractValue * advancePercent / 100));

  /// The retention a SAL carries: the contract's own, or the 0.50% statutory one of an Italian public contract (CIG).
  double get effectiveRetentionPercent {
    if (retentionPercent > 0) {
      return retentionPercent;
    }
    return jurisdiction == 'IT' && cig != null ? 0.5 : 0;
  }
}

/// The result of the SAL arithmetic (the same as the API): see [previewSal].
class SalPreview {
  const SalPreview({
    required this.cumulativeGross,
    required this.currentGross,
    required this.advanceDeduction,
    required this.retentionWithheld,
    required this.invoiceAmount,
    required this.netBillable,
    required this.isFinal,
  });

  final double cumulativeGross;
  final double currentGross;
  final double advanceDeduction;
  final double retentionWithheld;
  final double invoiceAmount;
  final double netBillable;
  final bool isFinal;
}

/// Live preview of a SAL certificate, the arithmetic of the API: the incremental earned value, the advance recouped in
/// proportion (all of what is left on the final certificate), the retention withheld on the gross, the invoice amount (gross
/// less advance) and what the customer pays now (invoice less retention). Null while the progress does not advance within
/// 0-100 or the contract has no value.
SalPreview? previewSal({
  required double contractValue,
  required double cumulativePercent,
  required double previousPercent,
  required double previousCumulativeGross,
  required double advanceTotal,
  required double advanceRecouped,
  required double retentionPercent,
}) {
  final int contract = _cents(contractValue);
  if (contract <= 0 ||
      cumulativePercent > 100 ||
      cumulativePercent <= previousPercent) {
    return null;
  }

  final bool isFinal = cumulativePercent == 100;
  final int cumulativeGross = (contract * cumulativePercent / 100).round();
  final int currentGross = cumulativeGross - _cents(previousCumulativeGross);
  final int total = _cents(advanceTotal);
  final int remaining = total - _cents(advanceRecouped) > 0
      ? total - _cents(advanceRecouped)
      : 0;
  final int proportional = (total * currentGross / contract).round();
  final int wanted = isFinal ? remaining : proportional;
  int deduction = wanted < remaining ? wanted : remaining;
  deduction = deduction < currentGross ? deduction : currentGross;
  deduction = deduction > 0 ? deduction : 0;
  final int retention = (currentGross * retentionPercent / 100).round();
  final int invoice = currentGross - deduction;

  return SalPreview(
    cumulativeGross: _fromCents(cumulativeGross),
    currentGross: _fromCents(currentGross),
    advanceDeduction: _fromCents(deduction),
    retentionWithheld: _fromCents(retention),
    invoiceAmount: _fromCents(invoice),
    netBillable: _fromCents(invoice - retention),
    isFinal: isFinal,
  );
}

/// The latest period-end WIP valuation of the project.
class WipFigure {
  const WipFigure({
    required this.periodEnd,
    required this.recognized,
    required this.billed,
    required this.difference,
  });

  factory WipFigure.fromJson(Map<String, dynamic> json) => WipFigure(
    periodEnd: _date(json['period_end_date']),
    recognized: _amount(json['recognized_revenue_to_date']),
    billed: _amount(json['billed_to_date']),
    difference: _amount(json['wip_asset_or_deferred_revenue_diff']),
  );

  final DateTime? periodEnd;
  final double recognized;
  final double billed;
  final double difference;

  WipNature get nature => wipNature(difference);
}

/// What a project has earned but not billed.
class BillingSummary {
  const BillingSummary({
    required this.currency,
    required this.contractValue,
    required this.billedToDate,
    required this.draftBilling,
    required this.unbilledTimeAndMaterials,
    required this.unbilledMilestones,
    required this.openSalCount,
    required this.openSalAmount,
    this.retentionHeld,
    this.latestWip,
  });

  factory BillingSummary.fromJson(Map<String, dynamic> json) {
    final Object? retention = json['retention'];
    final Object? wip = json['latest_wip_run'];
    return BillingSummary(
      currency: _text(json['currency']) ?? 'EUR',
      contractValue: _amount(json['contract_value']),
      billedToDate: _amount(json['billed_to_date']),
      draftBilling: _amount(json['draft_billing']),
      unbilledTimeAndMaterials: _amount(json['unbilled_time_and_materials']),
      unbilledMilestones: (_number(json['unbilled_milestones']) ?? 0).toInt(),
      openSalCount: (_number(json['open_sal_certificates']) ?? 0).toInt(),
      openSalAmount: _amount(json['open_sal_invoice_amount']),
      retentionHeld: retention is Map ? _amount(retention['balance']) : null,
      latestWip: wip is Map
          ? WipFigure.fromJson(Map<String, dynamic>.from(wip))
          : null,
    );
  }

  final String currency;
  final double contractValue;
  final double billedToDate;
  final double draftBilling;
  final double unbilledTimeAndMaterials;
  final int unbilledMilestones;
  final int openSalCount;
  final double openSalAmount;
  final double? retentionHeld;
  final WipFigure? latestWip;
}

/// A SAL progress certificate (Stato Avanzamento Lavori, Akontorechnung / Teilrechnung).
class SalCertificate {
  const SalCertificate({
    required this.id,
    required this.number,
    required this.previousPercent,
    required this.cumulativePercent,
    required this.cumulativeGross,
    required this.currentGross,
    required this.advanceDeduction,
    required this.retention,
    required this.invoiceAmount,
    required this.net,
    required this.isFinal,
    required this.status,
    this.periodStart,
    this.periodEnd,
  });

  factory SalCertificate.fromJson(Map<String, dynamic> json) => SalCertificate(
    id: '${json['id']}',
    number: (_number(json['sal_number']) ?? 0).toInt(),
    previousPercent: _amount(json['previous_completion_percent']),
    cumulativePercent: _amount(json['cumulative_completion_percent']),
    cumulativeGross: _amount(json['cumulative_gross_earned_value']),
    currentGross: _amount(json['current_period_gross_sal']),
    advanceDeduction: _amount(json['advance_deduction_amount']),
    retention: _amount(json['guarantee_retention_withheld']),
    invoiceAmount: _amount(json['invoice_amount']),
    net: _amount(json['net_billable_amount']),
    isFinal: json['is_final'] == true,
    status: _text(json['status']) ?? 'draft',
    periodStart: _date(json['period_start_date']),
    periodEnd: _date(json['period_end_date']),
  );

  final String id;
  final int number;
  final double previousPercent;
  final double cumulativePercent;
  final double cumulativeGross;
  final double currentGross;
  final double advanceDeduction;
  final double retention;
  final double invoiceAmount;
  final double net;
  final bool isFinal;
  final String status;
  final DateTime? periodStart;
  final DateTime? periodEnd;

  /// A certificate that still takes the next one's place: not cancelled.
  bool get isLive => status != 'cancelled';

  bool get isOpen =>
      status == 'draft' || status == 'pending_approval' || status == 'approved';
}

/// The prepaid retainer / hour bank.
class RetainerBalance {
  const RetainerBalance({
    required this.byHours,
    required this.remainingHours,
    required this.remainingAmount,
    required this.remainingPercent,
    required this.consumedHours,
    required this.thresholdPercent,
    required this.isLow,
  });

  factory RetainerBalance.fromJson(Map<String, dynamic> json) =>
      RetainerBalance(
        byHours: json['unit'] != 'amount',
        remainingHours: _amount(json['remaining_hours']),
        remainingAmount: _amount(json['remaining_amount']),
        remainingPercent: _amount(json['remaining_percent']),
        consumedHours: _amount(json['consumed_hours']),
        thresholdPercent: _amount(json['low_balance_threshold_percent']),
        isLow: json['is_low_balance'] == true,
      );

  final bool byHours;
  final double remainingHours;
  final double remainingAmount;
  final double remainingPercent;
  final double consumedHours;
  final double thresholdPercent;
  final bool isLow;

  /// Share of the bank already burned, 0 to 1, for the burn-down bar.
  double get burned => (1 - remainingPercent / 100).clamp(0, 1).toDouble();
}

/// The guarantee retention (ritenuta a garanzia, Garantierückbehalt).
class RetentionBalance {
  const RetentionBalance({
    required this.withheld,
    required this.released,
    required this.balance,
    required this.rule,
  });

  factory RetentionBalance.fromJson(Map<String, dynamic> json) =>
      RetentionBalance(
        withheld: _amount(json['withheld']),
        released: _amount(json['released']),
        balance: _amount(json['balance']),
        rule: _text(json['release_rule']) ?? 'manual',
      );

  final double withheld;
  final double released;
  final double balance;
  final String rule;
}

/// Everything the billing view shows for one project, as of the last sync.
class ProjectBillingSnapshot {
  const ProjectBillingSnapshot({
    required this.summary,
    required this.certificates,
    required this.syncedAt,
    this.contract,
    this.retainer,
    this.retention,
  });

  /// Builds the snapshot from the payloads of the endpoints; throws [FormatException] when the summary is not an object.
  factory ProjectBillingSnapshot.fromParts({
    required Map<String, dynamic> summary,
    required List<dynamic> certificates,
    required DateTime syncedAt,
    Map<String, dynamic>? contract,
    Map<String, dynamic>? retainer,
    Map<String, dynamic>? retention,
  }) {
    if (summary.isEmpty) {
      throw const FormatException('empty billing summary');
    }
    final Object? balance = retainer?['balance'];
    return ProjectBillingSnapshot(
      summary: BillingSummary.fromJson(summary),
      certificates: certificates
          .whereType<Map<dynamic, dynamic>>()
          .map(
            (Map<dynamic, dynamic> item) =>
                SalCertificate.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      syncedAt: syncedAt,
      contract: contract == null || contract.isEmpty
          ? null
          : BillingContractTerms.fromJson(contract),
      retainer: balance is Map
          ? RetainerBalance.fromJson(Map<String, dynamic>.from(balance))
          : null,
      retention: retention == null || retention.isEmpty
          ? null
          : RetentionBalance.fromJson(retention),
    );
  }

  final BillingSummary summary;
  final List<SalCertificate> certificates;
  final BillingContractTerms? contract;
  final RetainerBalance? retainer;
  final RetentionBalance? retention;
  final DateTime syncedAt;

  /// The last certificate that is not cancelled: the base of the next one.
  SalCertificate? get lastLive {
    final List<SalCertificate> live = certificates
        .where((SalCertificate sal) => sal.isLive)
        .toList();
    if (live.isEmpty) {
      return null;
    }
    return live.reduce(
      (SalCertificate a, SalCertificate b) => a.number >= b.number ? a : b,
    );
  }

  /// Previews the next certificate at [cumulativePercent] with the terms of the contract; null when there is no contract
  /// billing by progress, or the percentage is not valid.
  SalPreview? previewNext(double cumulativePercent) {
    final BillingContractTerms? terms = contract;
    if (terms == null || !terms.billsProgress) {
      return null;
    }
    final SalCertificate? last = lastLive;
    return previewSal(
      contractValue: terms.contractValue,
      cumulativePercent: cumulativePercent,
      previousPercent: last?.cumulativePercent ?? 0,
      previousCumulativeGross: last?.cumulativeGross ?? 0,
      advanceTotal: terms.advanceTotal,
      advanceRecouped: certificates
          .where((SalCertificate sal) => sal.isLive)
          .fold<double>(
            0,
            (double sum, SalCertificate sal) => sum + sal.advanceDeduction,
          ),
      retentionPercent: terms.effectiveRetentionPercent,
    );
  }
}

/// Why a sync ended the way it did.
enum BillingSyncStatus { synced, offline, unauthorized, forbidden, failed }

class BillingSyncResult {
  const BillingSyncResult(this.status, {this.detail = ''});

  final BillingSyncStatus status;
  final String detail;
}
