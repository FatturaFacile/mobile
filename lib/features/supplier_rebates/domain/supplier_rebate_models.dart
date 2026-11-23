import 'package:flutter/foundation.dart';

import 'rebate_decimal.dart';

/// RBAC module keys that unlock the supplier rebates workspace (`rebates` is the web-api module key).
const String supplierRebatesModule = 'supplier_rebates';
const Set<String> supplierRebatesModules = <String>{
  supplierRebatesModule,
  'rebates',
};

/// How the tiers of an agreement are applied to the volume.
enum TierMode {
  retroactive('retroactive'),
  incremental('incremental');

  const TierMode(this.wire);

  final String wire;

  static TierMode fromWire(Object? raw) => values.firstWhere(
    (TierMode m) => m.wire == '$raw',
    orElse: () => retroactive,
  );
}

enum RebateType {
  tieredVolume('tiered_volume'),
  fixedBonus('fixed_bonus'),
  marketingContribution('marketing_contribution');

  const RebateType(this.wire);

  final String wire;

  static RebateType fromWire(Object? raw) => values.firstWhere(
    (RebateType t) => t.wire == '$raw',
    orElse: () => tieredVolume,
  );
}

enum AgreementStatus {
  draft('draft'),
  active('active'),
  closed('closed'),
  cancelled('cancelled');

  const AgreementStatus(this.wire);

  final String wire;

  static AgreementStatus fromWire(Object? raw) => values.firstWhere(
    (AgreementStatus s) => s.wire == '$raw',
    orElse: () => draft,
  );
}

enum ContributionStatus {
  planned('planned'),
  accrued('accrued'),
  settled('settled');

  const ContributionStatus(this.wire);

  final String wire;

  static ContributionStatus fromWire(Object? raw) => values.firstWhere(
    (ContributionStatus s) => s.wire == '$raw',
    orElse: () => planned,
  );
}

enum RunStatus {
  posted('posted'),
  reversed('reversed');

  const RunStatus(this.wire);

  final String wire;

  static RunStatus fromWire(Object? raw) => values.firstWhere(
    (RunStatus s) => s.wire == '$raw',
    orElse: () => posted,
  );
}

enum ProposalStatus {
  draft('draft'),
  pendingApproval('pending_approval'),
  approved('approved'),
  settled('settled'),
  cancelled('cancelled');

  const ProposalStatus(this.wire);

  final String wire;

  static ProposalStatus fromWire(Object? raw) => values.firstWhere(
    (ProposalStatus s) => s.wire == '$raw',
    orElse: () => draft,
  );

  /// The workflow buttons the phone offers. Executing the set-off stays on web and desktop.
  bool get canSubmit => this == draft;
  bool get canApprove => this == pendingApproval;
  bool get canCancel => isOpen;
  bool get isOpen =>
      this == draft || this == pendingApproval || this == approved;
}

enum ExecutionMode {
  creditNoteRequest('credit_note_request'),
  chargeInvoice('charge_invoice'),
  apSetOff('ap_set_off');

  const ExecutionMode(this.wire);

  final String wire;

  static ExecutionMode fromWire(Object? raw) => values.firstWhere(
    (ExecutionMode m) => m.wire == '$raw',
    orElse: () => creditNoteRequest,
  );
}

enum ProposalLineType {
  invoice('invoice'),
  creditNote('credit_note'),
  contribution('contribution'),
  bonus('bonus');

  const ProposalLineType(this.wire);

  final String wire;

  static ProposalLineType fromWire(Object? raw) => values.firstWhere(
    (ProposalLineType t) => t.wire == '$raw',
    orElse: () => invoice,
  );
}

/// The workflow actions of a settlement proposal available on the phone.
enum ProposalAction {
  submit('submit'),
  approve('approve'),
  cancel('cancel');

  const ProposalAction(this.wire);

  /// Last segment of `/rebates/settlement-proposals/{id}/{wire}`.
  final String wire;

  static ProposalAction? fromWire(String raw) {
    for (final ProposalAction a in values) {
      if (a.wire == raw) {
        return a;
      }
    }
    return null;
  }

  bool allowedIn(ProposalStatus status) => switch (this) {
    submit => status.canSubmit,
    approve => status.canApprove,
    cancel => status.canCancel,
  };
}

Map<String, dynamic> _map(Object? v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

List<Map<String, dynamic>> _maps(Object? v) => <Map<String, dynamic>>[
  if (v is List)
    for (final dynamic raw in v)
      if (raw is Map) Map<String, dynamic>.from(raw),
];

DateTime? _date(Object? v) => v is String && v.length >= 10
    ? DateTime.tryParse(v.substring(0, 10))
    : null;

String? _dateOut(DateTime? d) => d == null
    ? null
    : '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';

String? _str(Object? v) {
  final String? s = v?.toString();
  return s == null || s.isEmpty ? null : s;
}

int _int(Object? v, [int fallback = 0]) =>
    v is num ? v.round() : int.tryParse('$v') ?? fallback;

/// One step of the rebate scale.
@immutable
class RebateTier {
  const RebateTier({
    required this.threshold,
    required this.ratePercent,
    this.flatAmount,
  });

  factory RebateTier.fromJson(Map<String, dynamic> json) => RebateTier(
    threshold: Dec.parse(json['threshold_amount']),
    ratePercent: Dec.parse(json['rate_percent']),
    flatAmount: Dec.tryParse(json['flat_amount']),
  );

  final Dec threshold;
  final Dec ratePercent;
  final Dec? flatAmount;

  Dec get flat => flatAmount ?? Dec.zero;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'threshold_amount': threshold.toPlain(),
    'rate_percent': ratePercent.toPlain(),
    'flat_amount': flatAmount?.toPlain(),
  };

  RebateTier copyWith({Dec? threshold, Dec? ratePercent, Dec? flatAmount}) =>
      RebateTier(
        threshold: threshold ?? this.threshold,
        ratePercent: ratePercent ?? this.ratePercent,
        flatAmount: flatAmount ?? this.flatAmount,
      );

  @override
  bool operator ==(Object other) =>
      other is RebateTier &&
      other.threshold == threshold &&
      other.ratePercent == ratePercent &&
      other.flatAmount == flatAmount;

  @override
  int get hashCode => Object.hash(threshold, ratePercent, flatAmount);
}

/// A tier with the threshold of the next one, as served in `progress.tiers`.
@immutable
class TierBand {
  const TierBand({
    required this.tier,
    this.maxThreshold,
  });

  factory TierBand.fromJson(Map<String, dynamic> json) => TierBand(
    tier: RebateTier.fromJson(json),
    maxThreshold: Dec.tryParse(json['max_threshold']),
  );

  final RebateTier tier;

  /// Upper bound of the band; `null` for the open-ended top tier.
  final Dec? maxThreshold;

  Map<String, dynamic> toJson() => <String, dynamic>{
    ...tier.toJson(),
    'max_threshold': maxThreshold?.toPlain(),
  };
}

@immutable
class RebateContribution {
  const RebateContribution({
    required this.id,
    required this.kind,
    required this.amount,
    required this.status,
    this.description,
    this.dueOn,
  });

  factory RebateContribution.fromJson(Map<String, dynamic> json) =>
      RebateContribution(
        id: '${json['id']}',
        kind: '${json['kind'] ?? ''}',
        description: _str(json['description']),
        amount: Dec.parse(json['amount']),
        dueOn: _date(json['due_on']),
        status: ContributionStatus.fromWire(json['status']),
      );

  final String id;

  /// `marketing`, `co_marketing` or `listing`.
  final String kind;
  final String? description;
  final Dec amount;
  final DateTime? dueOn;
  final ContributionStatus status;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'kind': kind,
    'description': description,
    'amount': amount.toPlain(),
    'due_on': _dateOut(dueOn),
    'status': status.wire,
  };
}

/// A purchase rebate agreement (premio fornitore) with its scale.
@immutable
class RebateAgreement {
  const RebateAgreement({
    required this.id,
    required this.code,
    required this.name,
    required this.tierMode,
    required this.rebateType,
    required this.status,
    required this.currency,
    this.contactId,
    this.contactName,
    this.startsOn,
    this.endsOn,
    this.supplierContractId,
    this.fixedBonusTarget,
    this.fixedBonusAmount,
    this.accrualFrequency,
    this.version = 1,
    this.openRebate,
    this.tiers = const <RebateTier>[],
    this.contributions = const <RebateContribution>[],
  });

  factory RebateAgreement.fromJson(Map<String, dynamic> json) =>
      RebateAgreement(
        id: '${json['id']}',
        code: '${json['code'] ?? ''}',
        name: '${json['name'] ?? ''}',
        contactId: _str(json['contact_id']),
        contactName: _str(json['contact_name']),
        tierMode: TierMode.fromWire(json['tier_mode']),
        rebateType: RebateType.fromWire(json['rebate_type']),
        status: AgreementStatus.fromWire(json['status']),
        currency: '${json['currency'] ?? 'CHF'}',
        startsOn: _date(json['starts_on']),
        endsOn: _date(json['ends_on']),
        supplierContractId: _str(json['supplier_contract_id']),
        fixedBonusTarget: Dec.tryParse(json['fixed_bonus_target']),
        fixedBonusAmount: Dec.tryParse(json['fixed_bonus_amount']),
        accrualFrequency: _str(json['accrual_frequency']),
        version: _int(json['version'], 1),
        openRebate: Dec.tryParse(json['open_rebate']),
        tiers: <RebateTier>[
          for (final Map<String, dynamic> t in _maps(json['tiers']))
            RebateTier.fromJson(t),
        ],
        contributions: <RebateContribution>[
          for (final Map<String, dynamic> c in _maps(json['contributions']))
            RebateContribution.fromJson(c),
        ],
      );

  final String id;
  final String code;
  final String name;
  final String? contactId;
  final String? contactName;
  final TierMode tierMode;
  final RebateType rebateType;
  final AgreementStatus status;
  final String currency;
  final DateTime? startsOn;
  final DateTime? endsOn;
  final String? supplierContractId;
  final Dec? fixedBonusTarget;
  final Dec? fixedBonusAmount;

  /// `monthly`, `quarterly` or `custom`.
  final String? accrualFrequency;
  final int version;

  /// Rebate accrued and not settled yet, when the server computed it.
  final Dec? openRebate;
  final List<RebateTier> tiers;
  final List<RebateContribution> contributions;

  bool get isTiered => rebateType == RebateType.tieredVolume;
  bool get isFixedBonus => rebateType == RebateType.fixedBonus;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'code': code,
    'name': name,
    'direction': 'purchase',
    'contact_id': contactId,
    'contact_name': contactName,
    'tier_mode': tierMode.wire,
    'rebate_type': rebateType.wire,
    'status': status.wire,
    'currency': currency,
    'starts_on': _dateOut(startsOn),
    'ends_on': _dateOut(endsOn),
    'supplier_contract_id': supplierContractId,
    'fixed_bonus_target': fixedBonusTarget?.toPlain(),
    'fixed_bonus_amount': fixedBonusAmount?.toPlain(),
    'accrual_frequency': accrualFrequency,
    'version': version,
    'open_rebate': openRebate?.toPlain(),
    'tiers': <Map<String, dynamic>>[
      for (final RebateTier t in tiers) t.toJson(),
    ],
    'contributions': <Map<String, dynamic>>[
      for (final RebateContribution c in contributions) c.toJson(),
    ],
  };

  RebateAgreement copyWith({
    String? name,
    AgreementStatus? status,
    Dec? openRebate,
    int? version,
    List<RebateTier>? tiers,
    List<RebateContribution>? contributions,
  }) => RebateAgreement(
    id: id,
    code: code,
    name: name ?? this.name,
    contactId: contactId,
    contactName: contactName,
    tierMode: tierMode,
    rebateType: rebateType,
    status: status ?? this.status,
    currency: currency,
    startsOn: startsOn,
    endsOn: endsOn,
    supplierContractId: supplierContractId,
    fixedBonusTarget: fixedBonusTarget,
    fixedBonusAmount: fixedBonusAmount,
    accrualFrequency: accrualFrequency,
    version: version ?? this.version,
    openRebate: openRebate ?? this.openRebate,
    tiers: tiers ?? this.tiers,
    contributions: contributions ?? this.contributions,
  );
}

/// Where the volume stands on the scale (the `tier` object of the progress endpoint, also the calculator output).
@immutable
class TierProgress {
  const TierProgress({
    required this.accruedRebate,
    required this.progressPercent,
    this.currentTier,
    this.nextTier,
    this.distanceToNext,
    this.projectedRebateAtNext,
    this.projectedGain,
  });

  factory TierProgress.fromJson(Map<String, dynamic> json) => TierProgress(
    currentTier: json['current_tier'] is Map
        ? RebateTier.fromJson(_map(json['current_tier']))
        : null,
    nextTier: json['next_tier'] is Map
        ? RebateTier.fromJson(_map(json['next_tier']))
        : null,
    accruedRebate: Dec.parse(json['accrued_rebate']),
    distanceToNext: Dec.tryParse(json['distance_to_next']),
    progressPercent: Dec.parse(json['progress_percent']),
    projectedRebateAtNext: Dec.tryParse(json['projected_rebate_at_next']),
    projectedGain: Dec.tryParse(json['projected_gain']),
  );

  final RebateTier? currentTier;
  final RebateTier? nextTier;
  final Dec accruedRebate;
  final Dec? distanceToNext;

  /// Share of the band between the current and the next tier already covered, 0..100.
  final Dec progressPercent;
  final Dec? projectedRebateAtNext;
  final Dec? projectedGain;

  bool get isTopTier => nextTier == null && currentTier != null;
  bool get belowFirstTier => currentTier == null;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'current_tier': currentTier?.toJson(),
    'next_tier': nextTier?.toJson(),
    'accrued_rebate': accruedRebate.toPlain(),
    'distance_to_next': distanceToNext?.toPlain(),
    'progress_percent': progressPercent.toPlain(),
    'projected_rebate_at_next': projectedRebateAtNext?.toPlain(),
    'projected_gain': projectedGain?.toPlain(),
  };
}

/// Progress of a fixed target bonus.
@immutable
class BonusProgress {
  const BonusProgress({
    required this.target,
    required this.bonus,
    required this.reached,
    required this.distanceToTarget,
    required this.progressPercent,
  });

  factory BonusProgress.fromJson(Map<String, dynamic> json) => BonusProgress(
    target: Dec.parse(json['target']),
    bonus: Dec.parse(json['bonus']),
    reached: json['reached'] == true,
    distanceToTarget: Dec.parse(json['distance_to_target']),
    progressPercent: Dec.parse(json['progress_percent']),
  );

  final Dec target;
  final Dec bonus;
  final bool reached;
  final Dec distanceToTarget;
  final Dec progressPercent;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'target': target.toPlain(),
    'bonus': bonus.toPlain(),
    'reached': reached,
    'distance_to_target': distanceToTarget.toPlain(),
    'progress_percent': progressPercent.toPlain(),
  };
}

@immutable
class ContributionSummary {
  const ContributionSummary({
    required this.planned,
    required this.accrued,
    required this.settled,
  });

  factory ContributionSummary.fromJson(Map<String, dynamic> json) =>
      ContributionSummary(
        planned: Dec.parse(json['planned']),
        accrued: Dec.parse(json['accrued']),
        settled: Dec.parse(json['settled']),
      );

  static final ContributionSummary empty = ContributionSummary(
    planned: Dec.zero,
    accrued: Dec.zero,
    settled: Dec.zero,
  );

  final Dec planned;
  final Dec accrued;
  final Dec settled;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'planned': planned.toPlain(),
    'accrued': accrued.toPlain(),
    'settled': settled.toPlain(),
  };
}

/// Live position of an agreement as of the last pull: the qualifying volume is what the offline view works from.
@immutable
class AgreementProgress {
  const AgreementProgress({
    required this.qualifyingVolume,
    required this.earnedRebate,
    required this.accruedRebate,
    required this.settledRebate,
    required this.contributions,
    this.tier,
    this.bonus,
    this.tiers = const <TierBand>[],
    this.asOf,
  });

  factory AgreementProgress.fromJson(Map<String, dynamic> json) =>
      AgreementProgress(
        qualifyingVolume: Dec.parse(json['qualifying_volume']),
        earnedRebate: Dec.parse(json['earned_rebate']),
        accruedRebate: Dec.parse(json['accrued_rebate']),
        settledRebate: Dec.parse(json['settled_rebate']),
        tier: json['tier'] is Map
            ? TierProgress.fromJson(_map(json['tier']))
            : null,
        bonus: json['bonus'] is Map
            ? BonusProgress.fromJson(_map(json['bonus']))
            : null,
        contributions: json['contributions'] is Map
            ? ContributionSummary.fromJson(_map(json['contributions']))
            : ContributionSummary.empty,
        tiers: <TierBand>[
          for (final Map<String, dynamic> t in _maps(json['tiers']))
            TierBand.fromJson(t),
        ],
        asOf: _date(json['as_of']),
      );

  final Dec qualifyingVolume;
  final Dec earnedRebate;
  final Dec accruedRebate;
  final Dec settledRebate;
  final TierProgress? tier;
  final BonusProgress? bonus;
  final ContributionSummary contributions;
  final List<TierBand> tiers;
  final DateTime? asOf;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'qualifying_volume': qualifyingVolume.toPlain(),
    'earned_rebate': earnedRebate.toPlain(),
    'accrued_rebate': accruedRebate.toPlain(),
    'settled_rebate': settledRebate.toPlain(),
    'tier': tier?.toJson(),
    'bonus': bonus?.toJson(),
    'contributions': contributions.toJson(),
    'tiers': <Map<String, dynamic>>[for (final TierBand b in tiers) b.toJson()],
    'as_of': _dateOut(asOf),
  };

  AgreementProgress copyWith({Dec? qualifyingVolume}) => AgreementProgress(
    qualifyingVolume: qualifyingVolume ?? this.qualifyingVolume,
    earnedRebate: earnedRebate,
    accruedRebate: accruedRebate,
    settledRebate: settledRebate,
    tier: tier,
    bonus: bonus,
    contributions: contributions,
    tiers: tiers,
    asOf: asOf,
  );
}

@immutable
class RunLine {
  const RunLine({
    required this.invoiceNumber,
    required this.documentType,
    required this.netAmount,
    this.invoiceDate,
  });

  factory RunLine.fromJson(Map<String, dynamic> json) => RunLine(
    invoiceNumber: '${json['invoice_number'] ?? ''}',
    documentType: '${json['document_type'] ?? ''}',
    invoiceDate: _date(json['invoice_date']),
    netAmount: Dec.parse(json['net_amount']),
  );

  final String invoiceNumber;
  final String documentType;
  final DateTime? invoiceDate;
  final Dec netAmount;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'invoice_number': invoiceNumber,
    'document_type': documentType,
    'invoice_date': _dateOut(invoiceDate),
    'net_amount': netAmount.toPlain(),
  };
}

/// One accrual run (rateo) of an agreement.
@immutable
class AccrualRun {
  const AccrualRun({
    required this.id,
    required this.status,
    required this.baseAmount,
    required this.cumulativeRebate,
    required this.deltaAmount,
    this.periodStart,
    this.periodEnd,
    this.journalEntryId,
    this.lines = const <RunLine>[],
  });

  factory AccrualRun.fromJson(Map<String, dynamic> json) => AccrualRun(
    id: '${json['id']}',
    periodStart: _date(json['period_start']),
    periodEnd: _date(json['period_end']),
    status: RunStatus.fromWire(json['status']),
    baseAmount: Dec.parse(json['base_amount']),
    cumulativeRebate: Dec.parse(json['cumulative_rebate']),
    deltaAmount: Dec.parse(json['delta_amount']),
    journalEntryId: _str(json['journal_entry_id']),
    lines: <RunLine>[
      for (final Map<String, dynamic> l in _maps(json['lines']))
        RunLine.fromJson(l),
    ],
  );

  final String id;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final RunStatus status;
  final Dec baseAmount;
  final Dec cumulativeRebate;
  final Dec deltaAmount;

  /// `null` when the ledger accounts are not configured, so nothing was posted.
  final String? journalEntryId;
  final List<RunLine> lines;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'period_start': _dateOut(periodStart),
    'period_end': _dateOut(periodEnd),
    'status': status.wire,
    'base_amount': baseAmount.toPlain(),
    'cumulative_rebate': cumulativeRebate.toPlain(),
    'delta_amount': deltaAmount.toPlain(),
    'journal_entry_id': journalEntryId,
    'lines': <Map<String, dynamic>>[for (final RunLine l in lines) l.toJson()],
  };
}

/// A row of the analytical breakdown of a settlement proposal.
@immutable
class ProposalLine {
  const ProposalLine({
    required this.type,
    required this.reference,
    required this.netAmount,
    required this.rebateAmount,
    this.referenceDate,
  });

  factory ProposalLine.fromJson(Map<String, dynamic> json) => ProposalLine(
    type: ProposalLineType.fromWire(json['line_type']),
    reference: '${json['reference'] ?? ''}',
    referenceDate: _date(json['reference_date']),
    netAmount: Dec.parse(json['net_amount']),
    rebateAmount: Dec.parse(json['rebate_amount']),
  );

  final ProposalLineType type;
  final String reference;
  final DateTime? referenceDate;
  final Dec netAmount;
  final Dec rebateAmount;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'line_type': type.wire,
    'reference': reference,
    'reference_date': _dateOut(referenceDate),
    'net_amount': netAmount.toPlain(),
    'rebate_amount': rebateAmount.toPlain(),
  };
}

/// A settlement proposal of the open accruals of an agreement.
@immutable
class SettlementProposal {
  const SettlementProposal({
    required this.id,
    required this.agreementId,
    required this.amount,
    required this.grossAmount,
    required this.taxRate,
    required this.taxAmount,
    required this.currency,
    required this.status,
    required this.executionMode,
    required this.setOffAmount,
    this.agreementCode,
    this.agreementName,
    this.version = 1,
    this.createdAt,
    this.lines = const <ProposalLine>[],
  });

  factory SettlementProposal.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> agreement = _map(json['agreement']);
    final Dec amount = Dec.parse(json['amount']);
    return SettlementProposal(
      id: '${json['id']}',
      agreementId: '${json['agreement_id'] ?? agreement['id'] ?? ''}',
      agreementCode: _str(agreement['code']),
      agreementName: _str(agreement['name']),
      amount: amount,
      grossAmount: Dec.parse(json['gross_amount'], amount),
      taxRate: Dec.parse(json['tax_rate']),
      taxAmount: Dec.parse(json['tax_amount']),
      currency: '${json['currency'] ?? 'CHF'}',
      status: ProposalStatus.fromWire(json['status']),
      executionMode: ExecutionMode.fromWire(json['execution_mode']),
      setOffAmount: Dec.parse(json['set_off_amount']),
      version: _int(json['version'], 1),
      createdAt: DateTime.tryParse('${json['created_at'] ?? ''}'),
      lines: <ProposalLine>[
        for (final Map<String, dynamic> l in _maps(json['lines']))
          ProposalLine.fromJson(l),
      ],
    );
  }

  final String id;
  final String agreementId;
  final String? agreementCode;
  final String? agreementName;

  /// Net rebate amount.
  final Dec amount;
  final Dec grossAmount;
  final Dec taxRate;
  final Dec taxAmount;
  final String currency;
  final ProposalStatus status;
  final ExecutionMode executionMode;
  final Dec setOffAmount;
  final int version;
  final DateTime? createdAt;
  final List<ProposalLine> lines;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'agreement_id': agreementId,
    'agreement': <String, dynamic>{
      'id': agreementId,
      'code': agreementCode,
      'name': agreementName,
    },
    'amount': amount.toPlain(),
    'gross_amount': grossAmount.toPlain(),
    'tax_rate': taxRate.toPlain(),
    'tax_amount': taxAmount.toPlain(),
    'currency': currency,
    'status': status.wire,
    'execution_mode': executionMode.wire,
    'set_off_amount': setOffAmount.toPlain(),
    'version': version,
    'created_at': createdAt?.toUtc().toIso8601String(),
    'lines': <Map<String, dynamic>>[
      for (final ProposalLine l in lines) l.toJson(),
    ],
  };

  SettlementProposal copyWith({ProposalStatus? status, int? version}) =>
      SettlementProposal(
        id: id,
        agreementId: agreementId,
        agreementCode: agreementCode,
        agreementName: agreementName,
        amount: amount,
        grossAmount: grossAmount,
        taxRate: taxRate,
        taxAmount: taxAmount,
        currency: currency,
        status: status ?? this.status,
        executionMode: executionMode,
        setOffAmount: setOffAmount,
        version: version ?? this.version,
        createdAt: createdAt,
        lines: lines,
      );
}

/// Newest first, open proposals before the closed ones; stable for equal dates.
List<SettlementProposal> sortProposals(List<SettlementProposal> proposals) =>
    proposals..sort((SettlementProposal a, SettlementProposal b) {
      if (a.status.isOpen != b.status.isOpen) {
        return a.status.isOpen ? -1 : 1;
      }
      final DateTime? x = a.createdAt;
      final DateTime? y = b.createdAt;
      if (x != null && y != null && x != y) {
        return y.compareTo(x);
      }
      return a.id.compareTo(b.id);
    });

/// A blanket purchase agreement (supplier contract) as listed by `/procurement/contracts`.
@immutable
class BlanketContract {
  const BlanketContract({
    required this.id,
    required this.contractNumber,
    required this.title,
    required this.currency,
    required this.status,
    required this.ceiling,
    required this.consumed,
    required this.alertThresholdPercent,
    this.minimumSpend,
    this.startsAt,
    this.endsAt,
  });

  factory BlanketContract.fromJson(Map<String, dynamic> json) =>
      BlanketContract(
        id: '${json['id']}',
        contractNumber: '${json['contract_number'] ?? ''}',
        title: '${json['title'] ?? ''}',
        currency: '${json['currency'] ?? 'CHF'}',
        status: '${json['status'] ?? ''}',
        ceiling: Dec.parse(json['total_committed_amount']),
        consumed: Dec.parse(json['consumed_amount']),
        minimumSpend: Dec.tryParse(json['minimum_spend_amount']),
        alertThresholdPercent: Dec.parse(
          json['alert_threshold_percent'],
          Dec.parse('80'),
        ),
        startsAt: _date(json['starts_at']),
        endsAt: _date(json['ends_at']),
      );

  final String id;
  final String contractNumber;
  final String title;
  final String currency;
  final String status;
  final Dec ceiling;
  final Dec consumed;
  final Dec? minimumSpend;
  final Dec alertThresholdPercent;
  final DateTime? startsAt;
  final DateTime? endsAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'contract_number': contractNumber,
    'title': title,
    'currency': currency,
    'status': status,
    'total_committed_amount': ceiling.toPlain(),
    'consumed_amount': consumed.toPlain(),
    'minimum_spend_amount': minimumSpend?.toPlain(),
    'alert_threshold_percent': alertThresholdPercent.toPlain(),
    'starts_at': _dateOut(startsAt),
    'ends_at': _dateOut(endsAt),
  };
}

enum BalanceAlertCode {
  ceilingNear('ceiling_near'),
  ceilingExceeded('ceiling_exceeded'),
  minimumAtRisk('minimum_at_risk'),
  minimumNotMet('minimum_not_met');

  const BalanceAlertCode(this.wire);

  final String wire;

  static BalanceAlertCode? fromWire(Object? raw) {
    for (final BalanceAlertCode c in values) {
      if (c.wire == '$raw') {
        return c;
      }
    }
    return null;
  }
}

@immutable
class BalanceAlert {
  const BalanceAlert({required this.code, required this.severity});

  final BalanceAlertCode code;

  /// `warning` or `critical`.
  final String severity;

  bool get isCritical => severity == 'critical';
}

@immutable
class BlanketLine {
  const BlanketLine({
    required this.description,
    required this.unitPrice,
    required this.releasedQuantity,
    required this.orderedAmount,
    this.committedQuantity,
    this.remainingQuantity,
  });

  factory BlanketLine.fromJson(Map<String, dynamic> json) => BlanketLine(
    description: '${json['description'] ?? ''}',
    unitPrice: Dec.parse(json['unit_price']),
    committedQuantity: Dec.tryParse(json['committed_quantity']),
    releasedQuantity: Dec.parse(json['released_quantity']),
    remainingQuantity: Dec.tryParse(json['remaining_quantity']),
    orderedAmount: Dec.parse(json['ordered_amount']),
  );

  final String description;
  final Dec unitPrice;
  final Dec? committedQuantity;
  final Dec releasedQuantity;
  final Dec? remainingQuantity;
  final Dec orderedAmount;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'description': description,
    'unit_price': unitPrice.toPlain(),
    'committed_quantity': committedQuantity?.toPlain(),
    'released_quantity': releasedQuantity.toPlain(),
    'remaining_quantity': remainingQuantity?.toPlain(),
    'ordered_amount': orderedAmount.toPlain(),
  };
}

/// Ceiling, minimum spend and call-off position of a blanket agreement.
@immutable
class BlanketBalance {
  const BlanketBalance({
    required this.currency,
    required this.ceiling,
    required this.orderedAmount,
    required this.receivedAmount,
    required this.invoicedAmount,
    this.minimumSpend,
    this.remainingCeiling,
    this.ceilingUsedPercent,
    this.minimumShortfall,
    this.minimumReachedPercent,
    this.lines = const <BlanketLine>[],
    this.alerts = const <BalanceAlert>[],
  });

  factory BlanketBalance.fromJson(Map<String, dynamic> json) => BlanketBalance(
    currency: '${json['currency'] ?? 'CHF'}',
    ceiling: Dec.parse(json['ceiling_amount']),
    minimumSpend: Dec.tryParse(json['minimum_spend_amount']),
    orderedAmount: Dec.parse(json['ordered_amount']),
    receivedAmount: Dec.parse(json['received_amount']),
    invoicedAmount: Dec.parse(json['invoiced_amount']),
    remainingCeiling: Dec.tryParse(json['remaining_ceiling']),
    ceilingUsedPercent: Dec.tryParse(json['ceiling_used_percent']),
    minimumShortfall: Dec.tryParse(json['minimum_shortfall']),
    minimumReachedPercent: Dec.tryParse(json['minimum_reached_percent']),
    lines: <BlanketLine>[
      for (final Map<String, dynamic> l in _maps(json['lines']))
        BlanketLine.fromJson(l),
    ],
    alerts: <BalanceAlert>[
      for (final Map<String, dynamic> a in _maps(json['alerts']))
        if (BalanceAlertCode.fromWire(a['code']) case final BalanceAlertCode c)
          BalanceAlert(code: c, severity: '${a['severity'] ?? 'warning'}'),
    ],
  );

  final String currency;

  /// Zero means the contract has no ceiling.
  final Dec ceiling;
  final Dec? minimumSpend;
  final Dec orderedAmount;
  final Dec receivedAmount;
  final Dec invoicedAmount;
  final Dec? remainingCeiling;
  final Dec? ceilingUsedPercent;
  final Dec? minimumShortfall;
  final Dec? minimumReachedPercent;
  final List<BlanketLine> lines;
  final List<BalanceAlert> alerts;

  bool get hasCeiling => ceiling.isPositive;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'currency': currency,
    'ceiling_amount': ceiling.toPlain(),
    'minimum_spend_amount': minimumSpend?.toPlain(),
    'ordered_amount': orderedAmount.toPlain(),
    'received_amount': receivedAmount.toPlain(),
    'invoiced_amount': invoicedAmount.toPlain(),
    'remaining_ceiling': remainingCeiling?.toPlain(),
    'ceiling_used_percent': ceilingUsedPercent?.toPlain(),
    'minimum_shortfall': minimumShortfall?.toPlain(),
    'minimum_reached_percent': minimumReachedPercent?.toPlain(),
    'lines': <Map<String, dynamic>>[
      for (final BlanketLine l in lines) l.toJson(),
    ],
    'alerts': <Map<String, dynamic>>[
      for (final BalanceAlert a in alerts)
        <String, dynamic>{'code': a.code.wire, 'severity': a.severity},
    ],
  };
}

/// Failure kinds of the remote calls.
enum RebateErrorKind { offline, forbidden, notFound, invalid, unknown }

class RebateException implements Exception {
  const RebateException(this.kind, {this.detail = ''});

  final RebateErrorKind kind;
  final String detail;

  @override
  String toString() => 'RebateException($kind, $detail)';
}

/// How a workflow action ended: sent and acknowledged, waiting in the outbox, or refused for good.
enum ActionStatus { sent, queued, rejected }

@immutable
class ActionOutcome {
  const ActionOutcome(this.status, {this.detail = ''});

  final ActionStatus status;
  final String detail;
}

/// A workflow action still in the outbox.
@immutable
class PendingAction {
  const PendingAction({
    required this.queueUuid,
    required this.proposalId,
    required this.action,
    required this.rejected,
    this.detail = '',
  });

  final String queueUuid;
  final String proposalId;
  final ProposalAction action;

  /// The server refused it (state conflict or validation); the user can retry or dismiss it.
  final bool rejected;
  final String detail;
}
