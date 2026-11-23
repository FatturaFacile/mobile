import 'dart:convert';

import '../../general_ledger/domain/gl_amount.dart';

/// RBAC module keys that unlock the Swiss VAT (MWST / IVA / TVA) workspace.
const String swissVatModule = 'swiss_vat';
const Set<String> swissVatModules = <String>{
  swissVatModule,
  'swiss_mwst',
};

// --- Parsing helpers -----------------------------------------------------------------------------------------------

DateTime? _date(Object? raw) {
  if (raw is! String || raw.isEmpty) {
    return null;
  }
  return DateTime.tryParse(raw);
}

String? _dateWire(DateTime? d) {
  if (d == null) {
    return null;
  }
  final String y = d.year.toString().padLeft(4, '0');
  final String m = d.month.toString().padLeft(2, '0');
  final String day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

String _str(Object? raw, [String fallback = '']) =>
    raw == null ? fallback : '$raw';

String? _strOrNull(Object? raw) =>
    raw == null || '$raw'.isEmpty ? null : '$raw';

int _int(Object? raw, [int fallback = 0]) {
  if (raw is num) {
    return raw.toInt();
  }
  return raw is String ? (int.tryParse(raw) ?? fallback) : fallback;
}

double _dbl(Object? raw, [double fallback = 0]) {
  if (raw is num) {
    return raw.toDouble();
  }
  return raw is String ? (double.tryParse(raw) ?? fallback) : fallback;
}

Map<String, dynamic> _map(Object? raw) =>
    raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};

List<Map<String, dynamic>> _maps(Object? raw) => <Map<String, dynamic>>[
  if (raw is List)
    for (final dynamic item in raw)
      if (item is Map) Map<String, dynamic>.from(item),
];

List<String> _stringsList(Object? raw) => <String>[
  if (raw is List)
    for (final dynamic item in raw)
      if (item != null) '$item',
];

// --- Errors --------------------------------------------------------------------------------------------------------

enum SwissVatErrorKind { offline, forbidden, notFound, invalid, unknown }

class SwissVatException implements Exception {
  const SwissVatException(this.kind, {this.detail = ''});

  final SwissVatErrorKind kind;
  final String detail;

  @override
  String toString() => 'SwissVatException($kind, $detail)';
}

// --- Enums ---------------------------------------------------------------------------------------------------------

enum SwissVatMethod {
  effective('effective'),
  saldosteuersatz('saldosteuersatz');

  const SwissVatMethod(this.wire);
  final String wire;

  static SwissVatMethod fromWire(String? wire) =>
      wire == 'saldosteuersatz' ? saldosteuersatz : effective;
}

enum SwissVatConsiderationBasis {
  agreed('agreed'),
  received('received');

  const SwissVatConsiderationBasis(this.wire);
  final String wire;

  static SwissVatConsiderationBasis fromWire(String? wire) =>
      wire == 'received' ? received : agreed;
}

enum SwissVatFrequency {
  quarterly('quarterly'),
  semiannual('semiannual'),
  monthly('monthly');

  const SwissVatFrequency(this.wire);
  final String wire;

  static SwissVatFrequency fromWire(String? wire) => switch (wire) {
    'semiannual' => semiannual,
    'monthly' => monthly,
    _ => quarterly,
  };
}

enum SwissVatReturnStatus {
  draft('draft'),
  calculated('calculated'),
  validated('validated'),
  finalized('finalized'),
  submitted('submitted');

  const SwissVatReturnStatus(this.wire);
  final String wire;

  static SwissVatReturnStatus fromWire(String? wire) => switch (wire) {
    'calculated' => calculated,
    'validated' => validated,
    'finalized' => finalized,
    'submitted' => submitted,
    _ => draft,
  };
}

enum BezugsteuerCategory {
  softwareCloud('software_cloud'),
  consulting('consulting'),
  itServices('it_services'),
  telecom('telecom'),
  royalties('royalties'),
  marketing('marketing'),
  otherCrossBorderService('other_cross_border_service'),
  importService('import_service');

  const BezugsteuerCategory(this.wire);
  final String wire;

  static BezugsteuerCategory fromWire(String? wire) {
    for (final BezugsteuerCategory c in values) {
      if (c.wire == wire) {
        return c;
      }
    }
    return otherCrossBorderService;
  }
}

enum BezugsteuerStatus {
  detected('detected'),
  confirmed('confirmed'),
  excluded('excluded'),
  declared('declared');

  const BezugsteuerStatus(this.wire);
  final String wire;

  static BezugsteuerStatus fromWire(String? wire) {
    for (final BezugsteuerStatus s in values) {
      if (s.wire == wire) {
        return s;
      }
    }
    return detected;
  }
}

enum InputTaxAdjustmentType {
  autoconsumo('autoconsumo'),
  degrassazione('degrassazione'),
  mixedUseReduction('mixed_use_reduction'),
  subsidyReduction('subsidy_reduction');

  const InputTaxAdjustmentType(this.wire);
  final String wire;

  String get afcBox => switch (this) {
    degrassazione => '410',
    autoconsumo || mixedUseReduction => '415',
    subsidyReduction => '420',
  };

  String get legalBasis => switch (this) {
    autoconsumo => 'Art. 31 LIVA',
    degrassazione => 'Art. 32 LIVA',
    mixedUseReduction => 'Art. 30 LIVA',
    subsidyReduction => 'Art. 33(2) LIVA',
  };

  static InputTaxAdjustmentType fromWire(String? wire) {
    for (final InputTaxAdjustmentType t in values) {
      if (t.wire == wire) {
        return t;
      }
    }
    return autoconsumo;
  }
}

enum SwissVatActionKind {
  configSave,
  bezugsteuerCreate,
  bezugsteuerConfirm,
  bezugsteuerExclude,
  adjustmentCreate,
  adjustmentApprove,
  returnCalculate,
}

// --- Domain Rules & Calculators ------------------------------------------------------------------------------------

class SwissVatEpochRates {
  const SwissVatEpochRates({
    required this.standardRate,
    required this.reducedRate,
    required this.accommodationRate,
    required this.standardBox,
    required this.reducedBox,
    required this.accommodationBox,
    required this.bezugsteuerBox,
  });

  final double standardRate;
  final double reducedRate;
  final double accommodationRate;
  final String standardBox;
  final String reducedBox;
  final String accommodationBox;
  final String bezugsteuerBox;
}

abstract final class SwissVatDomain {
  static final DateTime currentEpochStart = DateTime(2024, 1, 1);

  static const List<double> saldosteuersatzBands = <double>[
    0.1,
    0.6,
    1.3,
    2.1,
    3.0,
    3.7,
    4.5,
    5.3,
    6.2,
    6.8,
  ];

  static SwissVatEpochRates rateEpochFor(DateTime date) {
    if (!date.isBefore(currentEpochStart)) {
      return const SwissVatEpochRates(
        standardRate: 8.1,
        reducedRate: 2.6,
        accommodationRate: 3.8,
        standardBox: '303',
        reducedBox: '313',
        accommodationBox: '343',
        bezugsteuerBox: '383',
      );
    }
    return const SwissVatEpochRates(
      standardRate: 7.7,
      reducedRate: 2.5,
      accommodationRate: 3.7,
      standardBox: '302',
      reducedBox: '312',
      accommodationBox: '342',
      bezugsteuerBox: '382',
    );
  }

  /// Validates a Swiss UID-MWST identifier (`CHE-XXX.XXX.XXX MWST`) via its Mod-11 check digit.
  static bool isValidUidMwst(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return false;
    }
    final String digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 9 || digits == '000000000') {
      return false;
    }
    const List<int> weights = <int>[5, 4, 3, 2, 7, 6, 5, 4];
    int sum = 0;
    for (int i = 0; i < 8; i++) {
      sum += int.parse(digits[i]) * weights[i];
    }
    final int expected = (11 - (sum % 11)) % 11;
    return expected != 10 && expected == int.parse(digits[8]);
  }

  static String normalizeUid(String? raw) {
    if (raw == null) {
      return 'CHE-000.000.000 MWST';
    }
    final String d = raw.replaceAll(RegExp(r'\D'), '');
    if (d.length != 9) {
      return 'CHE-000.000.000 MWST';
    }
    return 'CHE-${d.substring(0, 3)}.${d.substring(3, 6)}.${d.substring(6, 9)} MWST';
  }

  /// Commercial 0.05 CHF rounding used for Swiss tax amounts.
  static double roundSwiss005(double value) => (value * 20).round() / 20.0;

  static bool isForeignSupplierForBezugsteuer(
    String countryCode, {
    double chargedSwissVat = 0,
  }) {
    if (chargedSwissVat > 0) {
      return false;
    }
    final String norm = countryCode.trim().toUpperCase();
    return norm.length == 2 && norm != 'CH' && norm != 'LI';
  }

  static double previewBezugsteuerTax(double netChf, DateTime invoiceDate) {
    if (netChf <= 0) {
      return 0;
    }
    final SwissVatEpochRates epoch = rateEpochFor(invoiceDate);
    return roundSwiss005(netChf * epoch.standardRate / 100.0);
  }

  /// Preview LIVA Art. 30-33 input tax adjustment amount (5y movable / 20y real estate).
  static double previewAdjustmentAmount({
    required InputTaxAdjustmentType type,
    required double originalCostChf,
    required double originalVatRate,
    required int yearsElapsed,
    required bool isRealEstate,
    double ratioPercent = 100,
  }) {
    if (originalCostChf <= 0 || originalVatRate <= 0) {
      return 0;
    }
    final double originalVat = originalCostChf * originalVatRate / 100.0;
    final double ratio = ratioPercent.clamp(0, 100) / 100.0;
    if (type == InputTaxAdjustmentType.mixedUseReduction ||
        type == InputTaxAdjustmentType.subsidyReduction) {
      return double.parse((originalVat * ratio).toStringAsFixed(2));
    }
    final int life = isRealEstate ? 20 : 5;
    final int remaining = (life - yearsElapsed.clamp(0, life)).clamp(0, life);
    if (remaining == 0) {
      return 0;
    }
    final double factor = ratioPercent > 0 ? ratio : 1.0;
    return double.parse(
      (originalVat * (remaining / life) * factor).toStringAsFixed(2),
    );
  }
}

// --- Entities & DTOs -----------------------------------------------------------------------------------------------

class SwissVatConfig {
  const SwissVatConfig({
    this.id = '',
    this.uidMwst,
    this.accountingMethod = SwissVatMethod.effective,
    this.considerationBasis = SwissVatConsiderationBasis.agreed,
    this.reportingFrequency = SwissVatFrequency.quarterly,
    this.sssRatePrimary,
    this.sssRateSecondary,
    this.sssSectorPrimary,
    this.sssSectorSecondary,
    this.roundingMode = 'chf_005',
    this.autoDetectBezugsteuer = true,
    this.bezugsteuerThresholdChf = '0.00',
    this.defaultCurrency = 'CHF',
    this.canton,
  });

  factory SwissVatConfig.fromJson(Map<String, dynamic> j) => SwissVatConfig(
    id: _str(j['id']),
    uidMwst: _strOrNull(j['uid_mwst']),
    accountingMethod: SwissVatMethod.fromWire(_strOrNull(j['accounting_method'])),
    considerationBasis: SwissVatConsiderationBasis.fromWire(
      _strOrNull(j['consideration_basis']),
    ),
    reportingFrequency: SwissVatFrequency.fromWire(
      _strOrNull(j['reporting_frequency']),
    ),
    sssRatePrimary: _strOrNull(j['sss_rate_primary']),
    sssRateSecondary: _strOrNull(j['sss_rate_secondary']),
    sssSectorPrimary: _strOrNull(j['sss_sector_primary']),
    sssSectorSecondary: _strOrNull(j['sss_sector_secondary']),
    roundingMode: _str(j['rounding_mode'], 'chf_005'),
    autoDetectBezugsteuer: j['auto_detect_bezugsteuer'] != false,
    bezugsteuerThresholdChf: _str(j['bezugsteuer_threshold_chf'], '0.00'),
    defaultCurrency: _str(j['default_currency'], 'CHF'),
    canton: _strOrNull(j['canton']),
  );

  final String id;
  final String? uidMwst;
  final SwissVatMethod accountingMethod;
  final SwissVatConsiderationBasis considerationBasis;
  final SwissVatFrequency reportingFrequency;
  final String? sssRatePrimary;
  final String? sssRateSecondary;
  final String? sssSectorPrimary;
  final String? sssSectorSecondary;
  final String roundingMode;
  final bool autoDetectBezugsteuer;
  final String bezugsteuerThresholdChf;
  final String defaultCurrency;
  final String? canton;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'uid_mwst': uidMwst,
    'accounting_method': accountingMethod.wire,
    'consideration_basis': considerationBasis.wire,
    'reporting_frequency': reportingFrequency.wire,
    'sss_rate_primary': sssRatePrimary,
    'sss_rate_secondary': sssRateSecondary,
    'sss_sector_primary': sssSectorPrimary,
    'sss_sector_secondary': sssSectorSecondary,
    'rounding_mode': roundingMode,
    'auto_detect_bezugsteuer': autoDetectBezugsteuer,
    'bezugsteuer_threshold_chf': bezugsteuerThresholdChf,
    'default_currency': defaultCurrency,
    'canton': canton,
  };
}

class SwissVatTaxCode {
  const SwissVatTaxCode({
    required this.id,
    required this.code,
    required this.name,
    required this.rateType,
    required this.exemptionType,
    required this.ratePercent,
    required this.afcBox,
    this.isBezugsteuer = false,
    this.isInputTaxDeductible = true,
    this.effectiveFrom,
    this.effectiveTo,
    this.isActive = true,
  });

  factory SwissVatTaxCode.fromJson(Map<String, dynamic> j) => SwissVatTaxCode(
    id: _str(j['id']),
    code: _str(j['code']),
    name: _str(j['name']),
    rateType: _str(j['rate_type']),
    exemptionType: _str(j['exemption_type'], 'none'),
    ratePercent: _str(j['rate_percent'], '0.00'),
    afcBox: _str(j['afc_box']),
    isBezugsteuer: j['is_bezugsteuer'] == true,
    isInputTaxDeductible: j['is_input_tax_deductible'] != false,
    effectiveFrom: _date(j['effective_from']),
    effectiveTo: _date(j['effective_to']),
    isActive: j['is_active'] != false,
  );

  final String id;
  final String code;
  final String name;
  final String rateType;
  final String exemptionType;
  final String ratePercent;
  final String afcBox;
  final bool isBezugsteuer;
  final bool isInputTaxDeductible;
  final DateTime? effectiveFrom;
  final DateTime? effectiveTo;
  final bool isActive;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'code': code,
    'name': name,
    'rate_type': rateType,
    'exemption_type': exemptionType,
    'rate_percent': ratePercent,
    'afc_box': afcBox,
    'is_bezugsteuer': isBezugsteuer,
    'is_input_tax_deductible': isInputTaxDeductible,
    'effective_from': _dateWire(effectiveFrom),
    'effective_to': _dateWire(effectiveTo),
    'is_active': isActive,
  };
}

class AfcBoxLine {
  const AfcBoxLine({
    required this.code,
    required this.section,
    required this.amount,
    this.labelKey = '',
    this.label = '',
    this.baseAmount,
    this.ratePercent,
    this.taxAmount,
    this.epochBoxAlias,
  });

  factory AfcBoxLine.fromJson(Map<String, dynamic> j) => AfcBoxLine(
    code: _str(j['code']),
    section: _str(j['section']),
    labelKey: _str(j['label_key']),
    label: _str(j['label']),
    amount: amountFromJson(j['amount']),
    baseAmount: j['base_amount'] == null ? null : amountFromJson(j['base_amount']),
    ratePercent: _strOrNull(j['rate_percent']),
    taxAmount: j['tax_amount'] == null ? null : amountFromJson(j['tax_amount']),
    epochBoxAlias: _strOrNull(j['epoch_box_alias']),
  );

  final String code;
  final String section;
  final String labelKey;
  final String label;
  final Amount4 amount;
  final Amount4? baseAmount;
  final String? ratePercent;
  final Amount4? taxAmount;
  final String? epochBoxAlias;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'code': code,
    'section': section,
    'label_key': labelKey,
    'label': label,
    'amount': amountToWire(amount),
    'base_amount': baseAmount == null ? null : amountToWire(baseAmount!),
    'rate_percent': ratePercent,
    'tax_amount': taxAmount == null ? null : amountToWire(taxAmount!),
    'epoch_box_alias': epochBoxAlias,
  };
}

class QuadraturaCheck {
  const QuadraturaCheck({
    required this.code,
    required this.severity,
    required this.passed,
    required this.expected,
    required this.actual,
    required this.difference,
    this.messageKey = '',
    this.message = '',
  });

  factory QuadraturaCheck.fromJson(Map<String, dynamic> j) => QuadraturaCheck(
    code: _str(j['code']),
    severity: _str(j['severity'], 'blocker'),
    passed: j['passed'] == true,
    expected: _str(j['expected'], '0.00'),
    actual: _str(j['actual'], '0.00'),
    difference: _str(j['difference'], '0.00'),
    messageKey: _str(j['message_key']),
    message: _str(j['message']),
  );

  final String code;
  final String severity;
  final bool passed;
  final String expected;
  final String actual;
  final String difference;
  final String messageKey;
  final String message;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'code': code,
    'severity': severity,
    'passed': passed,
    'expected': expected,
    'actual': actual,
    'difference': difference,
    'message_key': messageKey,
    'message': message,
  };
}

class QuadraturaReport {
  const QuadraturaReport({
    required this.passed,
    required this.checks,
    this.blockersCount = 0,
    this.warningsCount = 0,
  });

  factory QuadraturaReport.fromJson(Map<String, dynamic> j) {
    final List<QuadraturaCheck> list = <QuadraturaCheck>[
      for (final Map<String, dynamic> c in _maps(j['checks']))
        QuadraturaCheck.fromJson(c),
    ];
    return QuadraturaReport(
      passed: j['passed'] == true,
      checks: list,
      blockersCount: _int(
        j['blockers_count'],
        list.where((QuadraturaCheck c) => !c.passed && c.severity == 'blocker').length,
      ),
      warningsCount: _int(
        j['warnings_count'],
        list.where((QuadraturaCheck c) => !c.passed && c.severity == 'warning').length,
      ),
    );
  }

  static const QuadraturaReport empty = QuadraturaReport(
    passed: false,
    checks: <QuadraturaCheck>[],
  );

  final bool passed;
  final List<QuadraturaCheck> checks;
  final int blockersCount;
  final int warningsCount;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'passed': passed,
    'blockers_count': blockersCount,
    'warnings_count': warningsCount,
    'checks': <Map<String, dynamic>>[
      for (final QuadraturaCheck c in checks) c.toJson(),
    ],
  };
}

class SwissVatReturn {
  const SwissVatReturn({
    required this.id,
    required this.fiscalYear,
    required this.periodType,
    required this.periodNumber,
    required this.periodLabel,
    required this.accountingMethod,
    required this.considerationBasis,
    required this.status,
    required this.box200TotalTurnover,
    required this.box289TotalDeductions,
    required this.box299TaxableTurnover,
    required this.box399TotalOutputTax,
    required this.box479TotalInputTax,
    required this.box500PayableAmount,
    required this.box510CreditAmount,
    required this.grossTurnover,
    required this.invoicedVatTotal,
    required this.forfeitedInputVat,
    required this.sssRevenueAdjustment,
    required this.bezugsteuerBase,
    required this.bezugsteuerTax,
    required this.adjustmentsBox410,
    required this.adjustmentsBox415,
    required this.adjustmentsBox420,
    required this.quadraturaPassed,
    required this.quadraturaReport,
    this.periodFrom,
    this.periodTo,
    this.currency = 'CHF',
    this.boxSchedule = const <AfcBoxLine>[],
    this.finalizedAt,
    this.suissetaxReference,
  });

  factory SwissVatReturn.fromJson(Map<String, dynamic> j) => SwissVatReturn(
    id: _str(j['id']),
    fiscalYear: _int(j['fiscal_year']),
    periodType: SwissVatFrequency.fromWire(_strOrNull(j['period_type'])),
    periodNumber: _int(j['period_number'], 1),
    periodLabel: _str(j['period_label']),
    periodFrom: _date(j['period_from']),
    periodTo: _date(j['period_to']),
    accountingMethod: SwissVatMethod.fromWire(_strOrNull(j['accounting_method'])),
    considerationBasis: SwissVatConsiderationBasis.fromWire(
      _strOrNull(j['consideration_basis']),
    ),
    currency: _str(j['currency'], 'CHF'),
    status: SwissVatReturnStatus.fromWire(_strOrNull(j['status'])),
    box200TotalTurnover: amountFromJson(j['box_200_total_turnover']),
    box289TotalDeductions: amountFromJson(j['box_289_total_deductions']),
    box299TaxableTurnover: amountFromJson(j['box_299_taxable_turnover']),
    box399TotalOutputTax: amountFromJson(j['box_399_total_output_tax']),
    box479TotalInputTax: amountFromJson(j['box_479_total_input_tax']),
    box500PayableAmount: amountFromJson(j['box_500_payable_amount']),
    box510CreditAmount: amountFromJson(j['box_510_credit_amount']),
    grossTurnover: amountFromJson(j['gross_turnover']),
    invoicedVatTotal: amountFromJson(j['invoiced_vat_total']),
    forfeitedInputVat: amountFromJson(j['forfeited_input_vat']),
    sssRevenueAdjustment: amountFromJson(j['sss_revenue_adjustment']),
    bezugsteuerBase: amountFromJson(j['bezugsteuer_base']),
    bezugsteuerTax: amountFromJson(j['bezugsteuer_tax']),
    adjustmentsBox410: amountFromJson(j['adjustments_box_410']),
    adjustmentsBox415: amountFromJson(j['adjustments_box_415']),
    adjustmentsBox420: amountFromJson(j['adjustments_box_420']),
    quadraturaPassed: j['quadratura_passed'] == true,
    quadraturaReport: j['quadratura_report'] is Map
        ? QuadraturaReport.fromJson(_map(j['quadratura_report']))
        : QuadraturaReport.empty,
    boxSchedule: <AfcBoxLine>[
      for (final Map<String, dynamic> b in _maps(
        j['box_schedule'] ??
            (j['afc_boxes'] is Map ? (j['afc_boxes'] as Map)['boxes'] : null),
      ))
        AfcBoxLine.fromJson(b),
    ],
    finalizedAt: _date(j['finalized_at']),
    suissetaxReference: _strOrNull(j['suissetax_reference']),
  );

  final String id;
  final int fiscalYear;
  final SwissVatFrequency periodType;
  final int periodNumber;
  final String periodLabel;
  final DateTime? periodFrom;
  final DateTime? periodTo;
  final SwissVatMethod accountingMethod;
  final SwissVatConsiderationBasis considerationBasis;
  final String currency;
  final SwissVatReturnStatus status;
  final Amount4 box200TotalTurnover;
  final Amount4 box289TotalDeductions;
  final Amount4 box299TaxableTurnover;
  final Amount4 box399TotalOutputTax;
  final Amount4 box479TotalInputTax;
  final Amount4 box500PayableAmount;
  final Amount4 box510CreditAmount;
  final Amount4 grossTurnover;
  final Amount4 invoicedVatTotal;
  final Amount4 forfeitedInputVat;
  final Amount4 sssRevenueAdjustment;
  final Amount4 bezugsteuerBase;
  final Amount4 bezugsteuerTax;
  final Amount4 adjustmentsBox410;
  final Amount4 adjustmentsBox415;
  final Amount4 adjustmentsBox420;
  final bool quadraturaPassed;
  final QuadraturaReport quadraturaReport;
  final List<AfcBoxLine> boxSchedule;
  final DateTime? finalizedAt;
  final String? suissetaxReference;

  Amount4 get netBalance => box500PayableAmount > 0
      ? box500PayableAmount
      : -box510CreditAmount;

  SwissVatReturn withReconciliation(
    QuadraturaReport report,
    List<AfcBoxLine> schedule,
  ) => SwissVatReturn(
    id: id,
    fiscalYear: fiscalYear,
    periodType: periodType,
    periodNumber: periodNumber,
    periodLabel: periodLabel,
    periodFrom: periodFrom,
    periodTo: periodTo,
    accountingMethod: accountingMethod,
    considerationBasis: considerationBasis,
    currency: currency,
    status: status,
    box200TotalTurnover: box200TotalTurnover,
    box289TotalDeductions: box289TotalDeductions,
    box299TaxableTurnover: box299TaxableTurnover,
    box399TotalOutputTax: box399TotalOutputTax,
    box479TotalInputTax: box479TotalInputTax,
    box500PayableAmount: box500PayableAmount,
    box510CreditAmount: box510CreditAmount,
    grossTurnover: grossTurnover,
    invoicedVatTotal: invoicedVatTotal,
    forfeitedInputVat: forfeitedInputVat,
    sssRevenueAdjustment: sssRevenueAdjustment,
    bezugsteuerBase: bezugsteuerBase,
    bezugsteuerTax: bezugsteuerTax,
    adjustmentsBox410: adjustmentsBox410,
    adjustmentsBox415: adjustmentsBox415,
    adjustmentsBox420: adjustmentsBox420,
    quadraturaPassed: report.passed,
    quadraturaReport: report,
    boxSchedule: schedule,
    finalizedAt: finalizedAt,
    suissetaxReference: suissetaxReference,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'fiscal_year': fiscalYear,
    'period_type': periodType.wire,
    'period_number': periodNumber,
    'period_label': periodLabel,
    'period_from': _dateWire(periodFrom),
    'period_to': _dateWire(periodTo),
    'accounting_method': accountingMethod.wire,
    'consideration_basis': considerationBasis.wire,
    'currency': currency,
    'status': status.wire,
    'box_200_total_turnover': amountToWire(box200TotalTurnover),
    'box_289_total_deductions': amountToWire(box289TotalDeductions),
    'box_299_taxable_turnover': amountToWire(box299TaxableTurnover),
    'box_399_total_output_tax': amountToWire(box399TotalOutputTax),
    'box_479_total_input_tax': amountToWire(box479TotalInputTax),
    'box_500_payable_amount': amountToWire(box500PayableAmount),
    'box_510_credit_amount': amountToWire(box510CreditAmount),
    'gross_turnover': amountToWire(grossTurnover),
    'invoiced_vat_total': amountToWire(invoicedVatTotal),
    'forfeited_input_vat': amountToWire(forfeitedInputVat),
    'sss_revenue_adjustment': amountToWire(sssRevenueAdjustment),
    'bezugsteuer_base': amountToWire(bezugsteuerBase),
    'bezugsteuer_tax': amountToWire(bezugsteuerTax),
    'adjustments_box_410': amountToWire(adjustmentsBox410),
    'adjustments_box_415': amountToWire(adjustmentsBox415),
    'adjustments_box_420': amountToWire(adjustmentsBox420),
    'quadratura_passed': quadraturaPassed,
    'quadratura_report': quadraturaReport.toJson(),
    'box_schedule': <Map<String, dynamic>>[
      for (final AfcBoxLine b in boxSchedule) b.toJson(),
    ],
    'finalized_at': finalizedAt?.toIso8601String(),
    'suissetax_reference': suissetaxReference,
  };
}

class BezugsteuerEntry {
  const BezugsteuerEntry({
    required this.id,
    required this.supplierName,
    required this.supplierCountry,
    required this.description,
    required this.serviceCategory,
    required this.netAmountChf,
    required this.vatRatePercent,
    required this.taxAmountChf,
    required this.deductibleInputTaxChf,
    required this.afcBox,
    required this.status,
    this.invoiceNumber,
    this.invoiceDate,
    this.pending = false,
  });

  factory BezugsteuerEntry.fromJson(Map<String, dynamic> j) => BezugsteuerEntry(
    id: _str(j['id']),
    supplierName: _str(j['supplier_name']),
    supplierCountry: _str(j['supplier_country'], 'XX'),
    invoiceNumber: _strOrNull(j['invoice_number']),
    invoiceDate: _date(j['invoice_date']),
    serviceCategory: BezugsteuerCategory.fromWire(_strOrNull(j['service_category'])),
    description: _str(j['description']),
    netAmountChf: amountFromJson(j['net_amount_chf']),
    vatRatePercent: _str(j['vat_rate_percent'], '8.10'),
    taxAmountChf: amountFromJson(j['tax_amount_chf']),
    deductibleInputTaxChf: amountFromJson(j['deductible_input_tax_chf']),
    afcBox: _str(j['afc_box'], '383'),
    status: BezugsteuerStatus.fromWire(_strOrNull(j['status'])),
    pending: j['_pending'] == true,
  );

  final String id;
  final String supplierName;
  final String supplierCountry;
  final String? invoiceNumber;
  final DateTime? invoiceDate;
  final BezugsteuerCategory serviceCategory;
  final String description;
  final Amount4 netAmountChf;
  final String vatRatePercent;
  final Amount4 taxAmountChf;
  final Amount4 deductibleInputTaxChf;
  final String afcBox;
  final BezugsteuerStatus status;
  final bool pending;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'supplier_name': supplierName,
    'supplier_country': supplierCountry,
    'invoice_number': invoiceNumber,
    'invoice_date': _dateWire(invoiceDate),
    'service_category': serviceCategory.wire,
    'description': description,
    'net_amount_chf': amountToWire(netAmountChf),
    'vat_rate_percent': vatRatePercent,
    'tax_amount_chf': amountToWire(taxAmountChf),
    'deductible_input_tax_chf': amountToWire(deductibleInputTaxChf),
    'afc_box': afcBox,
    'status': status.wire,
    if (pending) '_pending': true,
  };
}

class BezugsteuerDraft {
  const BezugsteuerDraft({
    required this.supplierName,
    required this.supplierCountry,
    required this.invoiceDate,
    required this.description,
    required this.netAmountChf,
    this.serviceCategory = BezugsteuerCategory.softwareCloud,
    this.invoiceNumber,
    this.currency = 'CHF',
  });

  final String supplierName;
  final String supplierCountry;
  final DateTime invoiceDate;
  final String description;
  final double netAmountChf;
  final BezugsteuerCategory serviceCategory;
  final String? invoiceNumber;
  final String currency;

  String? validate() {
    if (supplierName.trim().isEmpty || description.trim().isEmpty) {
      return 'required';
    }
    if (!SwissVatDomain.isForeignSupplierForBezugsteuer(supplierCountry)) {
      return 'domestic_forbidden';
    }
    if (netAmountChf <= 0) {
      return 'invalid_amount';
    }
    return null;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'supplier_name': supplierName.trim(),
    'supplier_country': supplierCountry.trim().toUpperCase(),
    'invoice_number': invoiceNumber,
    'invoice_date': _dateWire(invoiceDate),
    'service_category': serviceCategory.wire,
    'description': description.trim(),
    'currency': currency,
    'original_net_amount': netAmountChf,
  };

  BezugsteuerEntry toPlaceholder(String id) {
    final double tax = SwissVatDomain.previewBezugsteuerTax(
      netAmountChf,
      invoiceDate,
    );
    final SwissVatEpochRates epoch = SwissVatDomain.rateEpochFor(invoiceDate);
    return BezugsteuerEntry(
      id: id,
      supplierName: supplierName.trim(),
      supplierCountry: supplierCountry.trim().toUpperCase(),
      invoiceNumber: invoiceNumber,
      invoiceDate: invoiceDate,
      serviceCategory: serviceCategory,
      description: description.trim(),
      netAmountChf: (netAmountChf * 10000).round(),
      vatRatePercent: epoch.standardRate.toStringAsFixed(2),
      taxAmountChf: (tax * 10000).round(),
      deductibleInputTaxChf: (tax * 10000).round(),
      afcBox: epoch.bezugsteuerBox,
      status: BezugsteuerStatus.detected,
      pending: true,
    );
  }
}

class InputTaxAdjustment {
  const InputTaxAdjustment({
    required this.id,
    required this.adjustmentType,
    required this.afcBox,
    required this.description,
    required this.adjustmentAmountChf,
    required this.legalBasis,
    required this.status,
    this.effectiveDate,
    this.fiscalYear = 2026,
    this.assetCategory = 'movable',
    this.originalCostChf,
    this.originalVatRate,
    this.yearsElapsed,
    this.pending = false,
  });

  factory InputTaxAdjustment.fromJson(Map<String, dynamic> j) =>
      InputTaxAdjustment(
        id: _str(j['id']),
        adjustmentType: InputTaxAdjustmentType.fromWire(
          _strOrNull(j['adjustment_type']),
        ),
        afcBox: _str(j['afc_box'], '415'),
        effectiveDate: _date(j['effective_date']),
        fiscalYear: _int(j['fiscal_year'], DateTime.now().year),
        assetCategory: _str(j['asset_category'], 'movable'),
        description: _str(j['description']),
        originalCostChf: _strOrNull(j['original_cost_chf']),
        originalVatRate: _strOrNull(j['original_vat_rate']),
        yearsElapsed: j['years_elapsed'] is int ? j['years_elapsed'] as int : null,
        adjustmentAmountChf: amountFromJson(j['adjustment_amount_chf']),
        legalBasis: _str(j['legal_basis'], 'Art. 31 LIVA'),
        status: _str(j['status'], 'draft'),
        pending: j['_pending'] == true,
      );

  final String id;
  final InputTaxAdjustmentType adjustmentType;
  final String afcBox;
  final DateTime? effectiveDate;
  final int fiscalYear;
  final String assetCategory;
  final String description;
  final String? originalCostChf;
  final String? originalVatRate;
  final int? yearsElapsed;
  final Amount4 adjustmentAmountChf;
  final String legalBasis;
  final String status;
  final bool pending;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'adjustment_type': adjustmentType.wire,
    'afc_box': afcBox,
    'effective_date': _dateWire(effectiveDate),
    'fiscal_year': fiscalYear,
    'asset_category': assetCategory,
    'description': description,
    'original_cost_chf': originalCostChf,
    'original_vat_rate': originalVatRate,
    'years_elapsed': yearsElapsed,
    'adjustment_amount_chf': amountToWire(adjustmentAmountChf),
    'legal_basis': legalBasis,
    'status': status,
    if (pending) '_pending': true,
  };
}

class InputTaxAdjustmentDraft {
  const InputTaxAdjustmentDraft({
    required this.adjustmentType,
    required this.effectiveDate,
    required this.description,
    required this.originalCostChf,
    this.originalVatRate = 8.1,
    this.yearsElapsed = 0,
    this.isRealEstate = false,
    this.ratioPercent = 100,
  });

  final InputTaxAdjustmentType adjustmentType;
  final DateTime effectiveDate;
  final String description;
  final double originalCostChf;
  final double originalVatRate;
  final int yearsElapsed;
  final bool isRealEstate;
  final double ratioPercent;

  String? validate() {
    if (description.trim().isEmpty || originalCostChf <= 0) {
      return 'invalid_adjustment';
    }
    return null;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'adjustment_type': adjustmentType.wire,
    'effective_date': _dateWire(effectiveDate),
    'asset_category': isRealEstate ? 'real_estate' : 'movable',
    'description': description.trim(),
    'original_cost_chf': originalCostChf,
    'original_vat_rate': originalVatRate,
    'years_elapsed': yearsElapsed,
    'private_or_exempt_ratio': ratioPercent,
  };

  InputTaxAdjustment toPlaceholder(String id) {
    final double preview = SwissVatDomain.previewAdjustmentAmount(
      type: adjustmentType,
      originalCostChf: originalCostChf,
      originalVatRate: originalVatRate,
      yearsElapsed: yearsElapsed,
      isRealEstate: isRealEstate,
      ratioPercent: ratioPercent,
    );
    return InputTaxAdjustment(
      id: id,
      adjustmentType: adjustmentType,
      afcBox: adjustmentType.afcBox,
      effectiveDate: effectiveDate,
      fiscalYear: effectiveDate.year,
      assetCategory: isRealEstate ? 'real_estate' : 'movable',
      description: description.trim(),
      originalCostChf: originalCostChf.toStringAsFixed(2),
      originalVatRate: originalVatRate.toStringAsFixed(2),
      yearsElapsed: yearsElapsed,
      adjustmentAmountChf: (preview * 10000).round(),
      legalBasis: adjustmentType.legalBasis,
      status: 'draft',
      pending: true,
    );
  }
}

class SuisseTaxValidationResult {
  const SuisseTaxValidationResult({
    required this.valid,
    required this.xsdValid,
    required this.quadraturaPassed,
    required this.schemaVersion,
    required this.errors,
  });

  factory SuisseTaxValidationResult.fromJson(Map<String, dynamic> j) =>
      SuisseTaxValidationResult(
        valid: j['valid'] == true,
        xsdValid: j['xsd_valid'] == true,
        quadraturaPassed: j['quadratura_passed'] == true,
        schemaVersion: _str(j['schema_version'], 'eCH-0217-v2.0'),
        errors: _stringsList(j['errors']),
      );

  final bool valid;
  final bool xsdValid;
  final bool quadraturaPassed;
  final String schemaVersion;
  final List<String> errors;
}

class SuisseTaxXmlExport {
  const SuisseTaxXmlExport({
    required this.id,
    required this.returnId,
    required this.fileName,
    required this.sha256Checksum,
    required this.xsdValid,
    required this.quadraturaPassed,
    required this.schemaVersion,
    this.periodLabel = '',
    this.exportedAt,
    this.validationErrors = const <String>[],
  });

  factory SuisseTaxXmlExport.fromJson(Map<String, dynamic> j) =>
      SuisseTaxXmlExport(
        id: _str(j['id']),
        returnId: _str(j['swiss_vat_return_id']),
        fileName: _str(j['file_name']),
        sha256Checksum: _str(j['sha256_checksum']),
        xsdValid: j['xsd_valid'] == true,
        quadraturaPassed: j['quadratura_passed'] == true,
        schemaVersion: _str(j['schema_version'], 'eCH-0217-v2.0'),
        periodLabel: _str(j['period_label']),
        exportedAt: _date(j['exported_at']),
        validationErrors: _stringsList(j['validation_errors']),
      );

  final String id;
  final String returnId;
  final String fileName;
  final String sha256Checksum;
  final bool xsdValid;
  final bool quadraturaPassed;
  final String schemaVersion;
  final String periodLabel;
  final DateTime? exportedAt;
  final List<String> validationErrors;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'swiss_vat_return_id': returnId,
    'file_name': fileName,
    'sha256_checksum': sha256Checksum,
    'xsd_valid': xsdValid,
    'quadratura_passed': quadraturaPassed,
    'schema_version': schemaVersion,
    'period_label': periodLabel,
    'exported_at': exportedAt?.toIso8601String(),
    'validation_errors': validationErrors,
  };
}

class SwissVatFile {
  const SwissVatFile({
    required this.fileName,
    required this.bytes,
    required this.mimeType,
  });

  final String fileName;
  final List<int> bytes;
  final String mimeType;

  String get utf8Preview => utf8.decode(bytes, allowMalformed: true);
}

enum SwissVatActionStatus { sent, queued, rejected }

class SwissVatActionOutcome {
  const SwissVatActionOutcome(this.status, {this.detail = ''});
  final SwissVatActionStatus status;
  final String detail;
}

class PendingSwissVatAction {
  const PendingSwissVatAction({
    required this.queueUuid,
    required this.kind,
    required this.rejected,
    required this.targetLabel,
    this.detail = '',
  });

  final String queueUuid;
  final SwissVatActionKind kind;
  final bool rejected;
  final String targetLabel;
  final String detail;
}

double parseAmount4ToDouble(Amount4 value) => _dbl(amountToWire(value));
