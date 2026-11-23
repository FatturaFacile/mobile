import '../../general_ledger/domain/gl_amount.dart';

/// RBAC module keys that unlock the Italian VAT workspace (`ledger` is the web-api module key of the routes).
const String italianVatModule = 'italian_vat';
const Set<String> italianVatModules = <String>{
  italianVatModule,
  'vat_registers',
  'vat_compliance',
};

/// A difference below this many ten-thousandths (one cent) counts as reconciled.
const int reconciliationTolerance = 100;

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

int? _intOrNull(Object? raw) {
  if (raw is num) {
    return raw.toInt();
  }
  return raw is String ? int.tryParse(raw) : null;
}

Amount4? _amountOrNull(Object? raw) => raw == null ? null : amountFromJson(raw);

Map<String, dynamic> _map(Object? raw) =>
    raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};

List<Map<String, dynamic>> _maps(Object? raw) => <Map<String, dynamic>>[
  if (raw is List)
    for (final dynamic i in raw)
      if (i is Map) Map<String, dynamic>.from(i),
];

// --- Errors --------------------------------------------------------------------------------------------------------

enum ItalianVatErrorKind { offline, forbidden, notFound, invalid, unknown }

class ItalianVatException implements Exception {
  const ItalianVatException(this.kind, {this.detail = ''});

  final ItalianVatErrorKind kind;

  /// RFC 7807 `detail` of the answer, when the server gave one.
  final String detail;

  @override
  String toString() => 'ItalianVatException($kind, $detail)';
}

// --- VAT registers -------------------------------------------------------------------------------------------------

/// The four registers of DPR 633/1972 art. 23-25 and 39.
enum VatRegisterType {
  sales('sales'),
  purchases('purchases'),
  receipts('receipts'),
  thirdPartyGoods('third-party-goods');

  const VatRegisterType(this.wire);

  final String wire;

  static VatRegisterType? fromWire(String? wire) {
    for (final VatRegisterType t in values) {
      if (t.wire == wire) {
        return t;
      }
    }
    return null;
  }
}

/// One VAT rate of one document of a register.
class VatRegisterLine {
  const VatRegisterLine({
    required this.documentNumber,
    required this.taxable,
    required this.vatRate,
    required this.vat,
    this.protocolNumber,
    this.postingDate,
    this.documentDate,
    this.documentType,
    this.partnerName,
    this.vatTreatment,
    this.sectional,
    this.deductibleVat,
    this.nonDeductibleVat,
  });

  factory VatRegisterLine.fromJson(Map<String, dynamic> j) => VatRegisterLine(
    protocolNumber: _intOrNull(j['protocol_number']),
    postingDate: _date(j['posting_date']),
    documentDate: _date(j['document_date']),
    documentNumber: _str(j['document_number']),
    documentType: _strOrNull(j['document_type']),
    partnerName: _strOrNull(j['partner_name']),
    taxable: amountFromJson(j['taxable_amount']),
    vatRate: amountFromJson(j['vat_rate']),
    vat: amountFromJson(j['vat_amount']),
    vatTreatment: _strOrNull(j['vat_treatment']),
    sectional: _strOrNull(j['sectional']),
    deductibleVat: _amountOrNull(j['deductible_vat']),
    nonDeductibleVat: _amountOrNull(j['non_deductible_vat']),
  );

  final int? protocolNumber;
  final DateTime? postingDate;
  final DateTime? documentDate;
  final String documentNumber;
  final String? documentType;
  final String? partnerName;
  final Amount4 taxable;

  /// Percentage with four decimals (`22.0000` is `220000`).
  final Amount4 vatRate;
  final Amount4 vat;
  final String? vatTreatment;

  /// Sectional (numbering series) code: ordinary, deferred (`D`), self-invoice (`A`)...
  final String? sectional;
  final Amount4? deductibleVat;
  final Amount4? nonDeductibleVat;

  /// Deductible VAT: the server figure, else the VAT times [proRata] (a percentage, `100.0000` when fully deductible).
  Amount4 deductibleWith(Amount4 proRata) =>
      deductibleVat ?? ProRata.deductible(vat, proRata);

  /// Non-deductible VAT, the complement of [deductibleWith].
  Amount4 nonDeductibleWith(Amount4 proRata) =>
      nonDeductibleVat ?? vat - deductibleWith(proRata);

  Map<String, dynamic> toJson() => <String, dynamic>{
    'protocol_number': protocolNumber,
    'posting_date': _dateWire(postingDate),
    'document_date': _dateWire(documentDate),
    'document_number': documentNumber,
    'document_type': documentType,
    'partner_name': partnerName,
    'taxable_amount': amountToWire(taxable),
    'vat_rate': amountToWire(vatRate),
    'vat_amount': amountToWire(vat),
    'vat_treatment': vatTreatment,
    'sectional': sectional,
    'deductible_vat': deductibleVat == null
        ? null
        : amountToWire(deductibleVat!),
    'non_deductible_vat': nonDeductibleVat == null
        ? null
        : amountToWire(nonDeductibleVat!),
  };
}

/// A numbering series of the register (`sezionale`).
class VatSectional {
  const VatSectional({required this.code, this.label = '', this.lastProtocol});

  factory VatSectional.fromJson(Map<String, dynamic> j) => VatSectional(
    code: _str(j['code']),
    label: _str(j['label'] ?? j['name']),
    lastProtocol: _intOrNull(j['last_protocol']),
  );

  final String code;
  final String label;
  final int? lastProtocol;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'code': code,
    'label': label,
    'last_protocol': lastProtocol,
  };
}

/// Definitive-print state of a register period (`stampa definitiva` and virtual stamp duty).
class RegisterLock {
  const RegisterLock({
    this.definitive = false,
    this.lockedAt,
    this.lastProtocol,
    this.stampDutyPages,
  });

  factory RegisterLock.fromJson(Map<String, dynamic> j) => RegisterLock(
    definitive: j['definitive'] == true || j['locked_at'] != null,
    lockedAt: _date(j['locked_at']),
    lastProtocol: _intOrNull(j['last_protocol']),
    stampDutyPages: _intOrNull(j['stamp_duty_pages']),
  );

  static const RegisterLock open = RegisterLock();

  final bool definitive;
  final DateTime? lockedAt;
  final int? lastProtocol;
  final int? stampDutyPages;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'definitive': definitive,
    'locked_at': lockedAt?.toIso8601String(),
    'last_protocol': lastProtocol,
    'stamp_duty_pages': stampDutyPages,
  };
}

/// Gross purchases of one VAT rate, the weight of the `ventilazione` of the retail receipts (DPR 633/72 art. 24).
class VentilationBasis {
  const VentilationBasis({required this.vatRate, required this.purchases});

  factory VentilationBasis.fromJson(Map<String, dynamic> j) => VentilationBasis(
    vatRate: amountFromJson(j['vat_rate']),
    purchases: amountFromJson(j['amount'] ?? j['purchases']),
  );

  final Amount4 vatRate;
  final Amount4 purchases;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'vat_rate': amountToWire(vatRate),
    'amount': amountToWire(purchases),
  };
}

/// One VAT-rate row of a register summary.
class RateTotal {
  const RateTotal({
    required this.vatRate,
    required this.taxable,
    required this.vat,
  });

  final Amount4 vatRate;
  final Amount4 taxable;
  final Amount4 vat;
}

/// A register of one period with its lines, sectionals, lock state and the pro-rata / ventilation parameters.
class VatRegister {
  const VatRegister({
    required this.type,
    required this.from,
    required this.to,
    required this.lines,
    this.sectionals = const <VatSectional>[],
    this.lock = RegisterLock.open,
    this.proRata,
    this.ventilation = const <VentilationBasis>[],
    this.ventilationEnabled = false,
    this.currency = 'EUR',
    this.fetchedAt,
  });

  factory VatRegister.fromJson(
    Map<String, dynamic> body, {
    required VatRegisterType type,
    required DateTime from,
    required DateTime to,
    DateTime? fetchedAt,
  }) {
    final Map<String, dynamic> meta = _map(body['meta']);
    final Map<String, dynamic> vent = _map(meta['ventilation']);
    return VatRegister(
      type: type,
      from: from,
      to: to,
      lines: <VatRegisterLine>[
        for (final Map<String, dynamic> l in _maps(body['data']))
          VatRegisterLine.fromJson(l),
      ],
      sectionals: <VatSectional>[
        for (final Map<String, dynamic> s in _maps(meta['sectionals']))
          VatSectional.fromJson(s),
      ],
      lock: meta['lock'] is Map
          ? RegisterLock.fromJson(_map(meta['lock']))
          : RegisterLock.open,
      proRata: _amountOrNull(meta['pro_rata_percent']),
      ventilationEnabled: vent['enabled'] == true,
      ventilation: <VentilationBasis>[
        for (final Map<String, dynamic> b in _maps(vent['purchase_basis']))
          VentilationBasis.fromJson(b),
      ],
      currency: _str(meta['currency'], 'EUR'),
      fetchedAt: fetchedAt,
    );
  }

  final VatRegisterType type;
  final DateTime from;
  final DateTime to;
  final List<VatRegisterLine> lines;
  final List<VatSectional> sectionals;
  final RegisterLock lock;

  /// Pro-rata deductible percentage of the year (`null` when the company has no exempt operations).
  final Amount4? proRata;
  final List<VentilationBasis> ventilation;
  final bool ventilationEnabled;
  final String currency;
  final DateTime? fetchedAt;

  /// Percentage applied to the purchases: 100 when no pro-rata applies.
  Amount4 get effectiveProRata => proRata ?? 100 * amountScale;

  Amount4 get totalTaxable =>
      lines.fold(0, (Amount4 a, VatRegisterLine l) => a + l.taxable);

  Amount4 get totalVat =>
      lines.fold(0, (Amount4 a, VatRegisterLine l) => a + l.vat);

  /// Total deductible VAT (purchases register), honouring the pro-rata.
  Amount4 get totalDeductible => lines.fold(
    0,
    (Amount4 a, VatRegisterLine l) => a + l.deductibleWith(effectiveProRata),
  );

  Amount4 get totalNonDeductible => totalVat - totalDeductible;

  /// Gross amount of the lines (taxable plus VAT).
  Amount4 get totalGross => totalTaxable + totalVat;

  bool get hasProRata => type == VatRegisterType.purchases && proRata != null;

  /// Lines of one sectional (`null` is every line).
  List<VatRegisterLine> linesOf(String? sectional) => <VatRegisterLine>[
    for (final VatRegisterLine l in lines)
      if (sectional == null || (l.sectional ?? '') == sectional) l,
  ];

  /// Sectional codes present in the lines or declared by the server, sorted.
  List<String> get sectionalCodes {
    final Set<String> codes = <String>{
      for (final VatSectional s in sectionals) s.code,
      for (final VatRegisterLine l in lines)
        if ((l.sectional ?? '').isNotEmpty) l.sectional!,
    };
    return codes.toList()..sort();
  }

  /// Totals per VAT rate, highest rate first.
  List<RateTotal> get byRate {
    final Map<Amount4, List<Amount4>> acc = <Amount4, List<Amount4>>{};
    for (final VatRegisterLine l in lines) {
      final List<Amount4> a = acc.putIfAbsent(l.vatRate, () => <Amount4>[0, 0]);
      a[0] += l.taxable;
      a[1] += l.vat;
    }
    return <RateTotal>[
      for (final MapEntry<Amount4, List<Amount4>> e in acc.entries)
        RateTotal(vatRate: e.key, taxable: e.value[0], vat: e.value[1]),
    ]..sort((RateTotal a, RateTotal b) => b.vatRate.compareTo(a.vatRate));
  }

  /// The ventilated split of the gross receipts of the period, empty unless the register is a ventilated one.
  List<VentilatedShare> get ventilatedShares =>
      type == VatRegisterType.receipts && ventilationEnabled
      ? Ventilation.allocate(totalGross, ventilation)
      : const <VentilatedShare>[];

  /// Highest protocol number of the lines.
  int? get lastProtocol {
    int? max;
    for (final VatRegisterLine l in lines) {
      final int? p = l.protocolNumber;
      if (p != null && (max == null || p > max)) {
        max = p;
      }
    }
    return max ?? lock.lastProtocol;
  }

  /// Lines still without a protocol number: the period is not posted yet, so the print cannot be definitive.
  int get unnumbered =>
      lines.where((VatRegisterLine l) => l.protocolNumber == null).length;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'type': type.wire,
    'from': _dateWire(from),
    'to': _dateWire(to),
    'data': <Map<String, dynamic>>[
      for (final VatRegisterLine l in lines) l.toJson(),
    ],
    'meta': <String, dynamic>{
      'sectionals': <Map<String, dynamic>>[
        for (final VatSectional s in sectionals) s.toJson(),
      ],
      'lock': lock.toJson(),
      'pro_rata_percent': proRata == null ? null : amountToWire(proRata!),
      'currency': currency,
      'ventilation': <String, dynamic>{
        'enabled': ventilationEnabled,
        'purchase_basis': <Map<String, dynamic>>[
          for (final VentilationBasis b in ventilation) b.toJson(),
        ],
      },
    },
    'fetched_at': fetchedAt?.toIso8601String(),
  };

  /// Reads back what [toJson] stored.
  factory VatRegister.fromCache(Map<String, dynamic> j) => VatRegister.fromJson(
    j,
    type: VatRegisterType.fromWire(_str(j['type'])) ?? VatRegisterType.sales,
    from: _date(j['from']) ?? DateTime(1970),
    to: _date(j['to']) ?? DateTime(1970),
    fetchedAt: _date(j['fetched_at']),
  );
}

// --- Pro-rata and ventilation --------------------------------------------------------------------------------------

/// `Pro-rata di detraibilità` (DPR 633/72 art. 19 c. 5): the deductible share of the input VAT.
abstract final class ProRata {
  /// Deductible part of [vat] at [percent] (four decimals), rounded half up to the cent.
  static Amount4 deductible(Amount4 vat, Amount4 percent) {
    final int bounded = percent < 0
        ? 0
        : (percent > 100 * amountScale ? 100 * amountScale : percent);
    return _mulDivCent(vat, bounded, 100 * amountScale);
  }

  /// The percentage of the year: taxable operations over all operations, rounded UP to the next whole unit as the law
  /// requires. `null` when there are no exempt operations (the VAT is fully deductible) or no operations at all.
  static Amount4? percentOf({
    required Amount4 taxableOperations,
    required Amount4 exemptOperations,
  }) {
    final Amount4 total = taxableOperations + exemptOperations;
    if (total <= 0 || exemptOperations <= 0) {
      return null;
    }
    final int whole = (taxableOperations * 100 + total - 1) ~/ total;
    return (whole > 100 ? 100 : whole) * amountScale;
  }
}

/// `a * b / divisor` rounded half away from zero to a whole cent (100 ten-thousandths); sign-safe.
Amount4 _mulDivCent(int a, int b, int divisor) {
  final bool negative = (a < 0) != (b < 0);
  final int product = a.abs() * b.abs();
  final int exact =
      product ~/ divisor + (product % divisor * 2 >= divisor ? 1 : 0);
  final int cents = (exact + 50) ~/ 100 * 100;
  return negative ? -cents : cents;
}

/// One VAT rate of a ventilated split.
class VentilatedShare {
  const VentilatedShare({
    required this.vatRate,
    required this.gross,
    required this.taxable,
    required this.vat,
  });

  final Amount4 vatRate;
  final Amount4 gross;
  final Amount4 taxable;
  final Amount4 vat;
}

/// `Ventilazione dei corrispettivi` (DPR 633/72 art. 24): the gross receipts are split between the VAT rates in
/// proportion to the goods purchased at each rate, then each share is scorporated.
abstract final class Ventilation {
  static List<VentilatedShare> allocate(
    Amount4 gross,
    List<VentilationBasis> basis,
  ) {
    final List<VentilationBasis> weights = <VentilationBasis>[
      for (final VentilationBasis b in basis)
        if (b.purchases > 0) b,
    ];
    final Amount4 total = weights.fold(
      0,
      (Amount4 a, VentilationBasis b) => a + b.purchases,
    );
    if (gross <= 0 || total <= 0) {
      return const <VentilatedShare>[];
    }
    final List<VentilatedShare> out = <VentilatedShare>[];
    Amount4 assigned = 0;
    for (int i = 0; i < weights.length; i++) {
      final VentilationBasis b = weights[i];
      final bool last = i == weights.length - 1;
      final Amount4 share = last
          ? gross - assigned
          : _mulDivCent(gross, b.purchases, total);
      assigned += share;
      final Amount4 divisor = 100 * amountScale + b.vatRate;
      final Amount4 taxable = _mulDivCent(share, 100 * amountScale, divisor);
      out.add(
        VentilatedShare(
          vatRate: b.vatRate,
          gross: share,
          taxable: taxable,
          vat: share - taxable,
        ),
      );
    }
    return out..sort(
      (VentilatedShare a, VentilatedShare b) => b.vatRate.compareTo(a.vatRate),
    );
  }
}

// --- Letters of intent ---------------------------------------------------------------------------------------------

enum IntentLetterKind {
  singleOperation('single_operation'),
  upToAmount('up_to_amount'),
  period('period');

  const IntentLetterKind(this.wire);

  final String wire;

  static IntentLetterKind fromWire(String? wire) => values.firstWhere(
    (IntentLetterKind k) => k.wire == wire,
    orElse: () => IntentLetterKind.upToAmount,
  );
}

enum IntentLetterStatus {
  active('active'),
  exhausted('exhausted'),
  expired('expired'),
  revoked('revoked');

  const IntentLetterStatus(this.wire);

  final String wire;

  static IntentLetterStatus fromWire(String? wire) => values.firstWhere(
    (IntentLetterStatus s) => s.wire == wire,
    orElse: () => IntentLetterStatus.active,
  );
}

/// `Lettera d'intento` received from a habitual exporter's customer: it authorises invoices without VAT (art. 8 c. 1
/// lett. c DPR 633/72) up to the declared plafond.
class IntentLetter {
  const IntentLetter({
    required this.id,
    required this.customerName,
    required this.authorized,
    required this.consumed,
    this.protocol = '',
    this.customerId,
    this.kind = IntentLetterKind.upToAmount,
    this.status = IntentLetterStatus.active,
    this.receivedOn,
    this.validFrom,
    this.validTo,
    this.currency = 'EUR',
    this.pending = false,
  });

  factory IntentLetter.fromJson(Map<String, dynamic> j) => IntentLetter(
    id: _str(j['id']),
    customerId: _strOrNull(j['customer_id'] ?? j['contact_id']),
    customerName: _str(j['customer_name'] ?? j['contact_name']),
    protocol: _str(j['protocol'] ?? j['protocol_number']),
    kind: IntentLetterKind.fromWire(_strOrNull(j['kind'])),
    status: IntentLetterStatus.fromWire(_strOrNull(j['status'])),
    receivedOn: _date(j['received_on']),
    validFrom: _date(j['valid_from']),
    validTo: _date(j['valid_to']),
    authorized: amountFromJson(j['authorized_amount']),
    consumed: amountFromJson(j['consumed_amount']),
    currency: _str(j['currency'], 'EUR'),
    pending: j['pending'] == true,
  );

  final String id;
  final String? customerId;
  final String customerName;

  /// Protocol of the Agenzia delle Entrate receipt (17 digits, a dash and 6 digits). Empty until acquired.
  final String protocol;
  final IntentLetterKind kind;
  final IntentLetterStatus status;
  final DateTime? receivedOn;
  final DateTime? validFrom;
  final DateTime? validTo;
  final Amount4 authorized;
  final Amount4 consumed;
  final String currency;

  /// Created on the phone and still waiting in the outbox.
  final bool pending;

  Amount4 get remaining => authorized - consumed;

  /// Share of the plafond used, `0..1` (more than 1 when the plafond is exceeded).
  double get usedRatio => authorized <= 0 ? 0 : consumed / authorized;

  bool get hasProtocol => RegExp(r'^\d{17}-\d{6}$').hasMatch(protocol.trim());

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'customer_id': customerId,
    'customer_name': customerName,
    'protocol': protocol,
    'kind': kind.wire,
    'status': status.wire,
    'received_on': _dateWire(receivedOn),
    'valid_from': _dateWire(validFrom),
    'valid_to': _dateWire(validTo),
    'authorized_amount': amountToWire(authorized),
    'consumed_amount': amountToWire(consumed),
    'currency': currency,
    'pending': pending,
  };

  IntentLetter copyWith({
    Amount4? consumed,
    IntentLetterStatus? status,
    bool? pending,
  }) => IntentLetter(
    id: id,
    customerId: customerId,
    customerName: customerName,
    protocol: protocol,
    kind: kind,
    status: status ?? this.status,
    receivedOn: receivedOn,
    validFrom: validFrom,
    validTo: validTo,
    authorized: authorized,
    consumed: consumed ?? this.consumed,
    currency: currency,
    pending: pending ?? this.pending,
  );
}

/// The fields of a letter registered on the phone; the server assigns the id and checks the protocol.
class IntentLetterDraft {
  const IntentLetterDraft({
    required this.customerName,
    required this.protocol,
    required this.authorized,
    required this.validFrom,
    required this.validTo,
    this.customerId,
    this.kind = IntentLetterKind.upToAmount,
    this.receivedOn,
    this.currency = 'EUR',
  });

  final String? customerId;
  final String customerName;
  final String protocol;
  final IntentLetterKind kind;
  final Amount4 authorized;
  final DateTime validFrom;
  final DateTime validTo;
  final DateTime? receivedOn;
  final String currency;

  /// Why the draft cannot be saved, or `null`; the server stays the authority.
  IntentLetterDraftIssue? get issue {
    if (customerName.trim().isEmpty) {
      return IntentLetterDraftIssue.customerMissing;
    }
    if (!RegExp(r'^\d{17}-\d{6}$').hasMatch(protocol.trim())) {
      return IntentLetterDraftIssue.protocolFormat;
    }
    if (authorized <= 0) {
      return IntentLetterDraftIssue.amountMissing;
    }
    if (validTo.isBefore(validFrom)) {
      return IntentLetterDraftIssue.periodInverted;
    }
    return null;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'customer_id': customerId,
    'customer_name': customerName.trim(),
    'protocol': protocol.trim(),
    'kind': kind.wire,
    'authorized_amount': amountToWire(authorized),
    'valid_from': _dateWire(validFrom),
    'valid_to': _dateWire(validTo),
    'received_on': _dateWire(receivedOn),
    'currency': currency,
  };

  IntentLetter toPlaceholder(String id) => IntentLetter(
    id: id,
    customerId: customerId,
    customerName: customerName.trim(),
    protocol: protocol.trim(),
    kind: kind,
    authorized: authorized,
    consumed: 0,
    validFrom: validFrom,
    validTo: validTo,
    receivedOn: receivedOn,
    currency: currency,
    pending: true,
  );
}

enum IntentLetterDraftIssue {
  customerMissing,
  protocolFormat,
  amountMissing,
  periodInverted,
}

enum PlafondResult {
  ok,
  nearLimit,
  exceedsPlafond,
  expired,
  notYetValid,
  revoked,
  missingProtocol,
}

/// Outcome of checking an invoice without VAT against a letter of intent.
class PlafondCheck {
  const PlafondCheck({
    required this.result,
    required this.remainingAfter,
    required this.excess,
  });

  final PlafondResult result;

  /// Plafond left once the invoice is booked (negative when exceeded).
  final Amount4 remainingAfter;

  /// How much of the invoice does not fit in the plafond.
  final Amount4 excess;

  /// Art. 8 c. 1 lett. c: the invoice may NOT be issued without VAT.
  bool get blocked => switch (result) {
    PlafondResult.ok || PlafondResult.nearLimit => false,
    _ => true,
  };

  bool get warning => result == PlafondResult.nearLimit;
}

/// Local mirror of the plafond control the server runs when an invoice without VAT is issued, so a salesperson sees
/// the erosion of the plafond before the order is placed, offline as well.
abstract final class PlafondGuard {
  /// Share of the plafond (percent) from which a warning shows.
  static const int warnAtPercent = 90;

  static PlafondCheck evaluate(
    IntentLetter letter,
    Amount4 invoiceTaxable,
    DateTime on,
  ) {
    final Amount4 after = letter.remaining - invoiceTaxable;
    final Amount4 excess = after < 0 ? -after : 0;
    final DateTime day = DateTime(on.year, on.month, on.day);
    PlafondResult result;
    if (letter.status == IntentLetterStatus.revoked) {
      result = PlafondResult.revoked;
    } else if (!letter.hasProtocol) {
      result = PlafondResult.missingProtocol;
    } else if (letter.validFrom != null &&
        day.isBefore(_dayOf(letter.validFrom!))) {
      result = PlafondResult.notYetValid;
    } else if (letter.status == IntentLetterStatus.expired ||
        (letter.validTo != null && day.isAfter(_dayOf(letter.validTo!)))) {
      result = PlafondResult.expired;
    } else if (after < 0) {
      result = PlafondResult.exceedsPlafond;
    } else if (letter.authorized > 0 &&
        (letter.consumed + invoiceTaxable) * 100 >=
            letter.authorized * warnAtPercent) {
      result = PlafondResult.nearLimit;
    } else {
      result = PlafondResult.ok;
    }
    return PlafondCheck(result: result, remainingAfter: after, excess: excess);
  }

  static DateTime _dayOf(DateTime d) => DateTime(d.year, d.month, d.day);
}

// --- LIPE and Erario c/IVA -----------------------------------------------------------------------------------------

enum SignatureStatus {
  unsigned('unsigned'),
  signed('signed'),
  invalid('invalid');

  const SignatureStatus(this.wire);

  final String wire;

  static SignatureStatus fromWire(String? wire) => values.firstWhere(
    (SignatureStatus s) => s.wire == wire,
    orElse: () => SignatureStatus.unsigned,
  );
}

/// XSD validation and signature state of the generated `LiquidazioniPeriodicheIVA` file.
class LipeFileStatus {
  const LipeFileStatus({
    this.generated = false,
    this.xsdValid,
    this.xsdErrors = const <String>[],
    this.signature = SignatureStatus.unsigned,
    this.generatedAt,
    this.protocol,
  });

  factory LipeFileStatus.fromJson(Map<String, dynamic> j) => LipeFileStatus(
    generated: j['generated'] == true || j['generated_at'] != null,
    xsdValid: j['xsd_valid'] is bool ? j['xsd_valid'] as bool : null,
    xsdErrors: <String>[
      if (j['xsd_errors'] is List)
        for (final dynamic e in j['xsd_errors'] as List<dynamic>) '$e',
    ],
    signature: SignatureStatus.fromWire(_strOrNull(j['signature_status'])),
    generatedAt: _date(j['generated_at']),
    protocol: _strOrNull(j['protocol']),
  );

  static const LipeFileStatus none = LipeFileStatus();

  final bool generated;

  /// `null` when the file was not validated yet.
  final bool? xsdValid;
  final List<String> xsdErrors;
  final SignatureStatus signature;
  final DateTime? generatedAt;

  /// Entratel receipt protocol once the file was transmitted.
  final String? protocol;

  /// Valid against the schema and signed: ready for Entratel / Desktop Telematico.
  bool get readyToTransmit =>
      generated && xsdValid == true && signature == SignatureStatus.signed;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'generated': generated,
    'xsd_valid': xsdValid,
    'xsd_errors': xsdErrors,
    'signature_status': signature.wire,
    'generated_at': generatedAt?.toIso8601String(),
    'protocol': protocol,
  };
}

enum ReconciliationState { unknown, reconciled, difference }

/// Periodic settlement against the `Erario c/IVA` ledger account.
class LipeReconciliation {
  const LipeReconciliation({
    required this.state,
    this.erarioBalance,
    this.expected,
    this.difference = 0,
  });

  /// Reconciles the VAT balance of [settlement] (output minus input VAT) with the movement of the ledger account the
  /// server reports; `unknown` while the server has not sent it.
  factory LipeReconciliation.of(LipeSettlement settlement) {
    final Amount4? erario = settlement.erarioBalance;
    final Amount4 expected = settlement.netVat;
    if (erario == null) {
      return LipeReconciliation(
        state: ReconciliationState.unknown,
        expected: expected,
      );
    }
    final Amount4 diff = erario - expected;
    return LipeReconciliation(
      state: diff.abs() <= reconciliationTolerance
          ? ReconciliationState.reconciled
          : ReconciliationState.difference,
      erarioBalance: erario,
      expected: expected,
      difference: diff,
    );
  }

  final ReconciliationState state;
  final Amount4? erarioBalance;
  final Amount4? expected;
  final Amount4 difference;
}

/// A periodic VAT settlement (`liquidazione periodica`), monthly or quarterly.
class LipeSettlement {
  const LipeSettlement({
    required this.id,
    required this.year,
    required this.period,
    required this.output,
    required this.input,
    this.periodType = 'quarterly',
    this.previousDebit = 0,
    this.previousCredit = 0,
    this.interest = 0,
    this.payable = 0,
    this.status = 'draft',
    this.periodFrom,
    this.periodTo,
    this.paidAt,
    this.currency = 'EUR',
    this.file = LipeFileStatus.none,
    this.erarioBalance,
  });

  factory LipeSettlement.fromJson(Map<String, dynamic> j) {
    final Map<String, dynamic> recon = _map(j['reconciliation']);
    return LipeSettlement(
      id: _str(j['id']),
      year: _intOrNull(j['year']) ?? 0,
      period: _intOrNull(j['period']) ?? 0,
      periodType: _str(j['period_type'], 'quarterly'),
      output: amountFromJson(j['output_vat_amount']),
      input: amountFromJson(j['input_vat_amount']),
      previousDebit: amountFromJson(j['previous_debit']),
      previousCredit: amountFromJson(j['previous_credit']),
      interest: amountFromJson(j['interest_amount']),
      payable: amountFromJson(j['payable_amount']),
      status: _str(j['status'], 'draft'),
      periodFrom: _date(j['period_from']),
      periodTo: _date(j['period_to']),
      paidAt: _date(j['paid_at']),
      currency: _str(j['currency'], 'EUR'),
      file: j['lipe'] is Map
          ? LipeFileStatus.fromJson(_map(j['lipe']))
          : LipeFileStatus.none,
      erarioBalance: _amountOrNull(recon['erario_balance']),
    );
  }

  final String id;
  final int year;
  final int period;
  final String periodType;
  final Amount4 output;
  final Amount4 input;
  final Amount4 previousDebit;
  final Amount4 previousCredit;
  final Amount4 interest;
  final Amount4 payable;
  final String status;
  final DateTime? periodFrom;
  final DateTime? periodTo;
  final DateTime? paidAt;
  final String currency;
  final LipeFileStatus file;
  final Amount4? erarioBalance;

  bool get quarterly => periodType == 'quarterly';

  bool get paid => paidAt != null || status == 'paid';

  /// Output VAT minus input VAT: positive is a debit towards the Erario, negative a credit.
  Amount4 get netVat => output - input;

  /// Balance after the carry-overs of the previous period, plus interest: what is due (positive) or credited.
  Amount4 get balance => netVat + previousDebit - previousCredit + interest;

  LipeReconciliation get reconciliation => LipeReconciliation.of(this);

  /// `2027-Q2` / `2027-03`, the key the periods are sorted and shown by.
  String get periodKey =>
      '$year-${quarterly ? 'Q' : ''}${period.toString().padLeft(quarterly ? 1 : 2, '0')}';

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'year': year,
    'period': period,
    'period_type': periodType,
    'output_vat_amount': amountToWire(output),
    'input_vat_amount': amountToWire(input),
    'previous_debit': amountToWire(previousDebit),
    'previous_credit': amountToWire(previousCredit),
    'interest_amount': amountToWire(interest),
    'payable_amount': amountToWire(payable),
    'status': status,
    'period_from': _dateWire(periodFrom),
    'period_to': _dateWire(periodTo),
    'paid_at': paidAt?.toIso8601String(),
    'currency': currency,
    'lipe': file.toJson(),
    'reconciliation': <String, dynamic>{
      'erario_balance': erarioBalance == null
          ? null
          : amountToWire(erarioBalance!),
    },
  };
}

// --- Annual VAT ----------------------------------------------------------------------------------------------------

/// Annual VAT reconciliation of one year: the sum of its periodic settlements, replaced figure by figure by the
/// server's own summary when it sent one.
class AnnualVatSummary {
  const AnnualVatSummary({
    required this.year,
    required this.periods,
    required this.output,
    required this.input,
    required this.balance,
    required this.paid,
    this.erarioBalance,
    this.creditCarriedForward,
    this.currency = 'EUR',
    this.fromServer = false,
  });

  /// Totals of the settlements of [year]; the figures of [server] (`GET /vat/annual-returns/{year}`) win when present.
  factory AnnualVatSummary.build(
    int year,
    List<LipeSettlement> settlements, {
    Map<String, dynamic>? server,
  }) {
    final List<LipeSettlement> periods =
        <LipeSettlement>[
          for (final LipeSettlement s in settlements)
            if (s.year == year) s,
        ]..sort(
          (LipeSettlement a, LipeSettlement b) => a.period.compareTo(b.period),
        );
    final Amount4 output = periods.fold(
      0,
      (Amount4 a, LipeSettlement s) => a + s.output,
    );
    final Amount4 input = periods.fold(
      0,
      (Amount4 a, LipeSettlement s) => a + s.input,
    );
    final Amount4 paid = periods
        .where((LipeSettlement s) => s.paid)
        .fold(
          0,
          (Amount4 a, LipeSettlement s) => a + (s.payable > 0 ? s.payable : 0),
        );
    final int? erarioParts =
        periods.every((LipeSettlement s) => s.erarioBalance != null) &&
            periods.isNotEmpty
        ? periods.fold<int>(
            0,
            (int a, LipeSettlement s) => a + s.erarioBalance!,
          )
        : null;
    final Map<String, dynamic> s = server ?? const <String, dynamic>{};
    return AnnualVatSummary(
      year: year,
      periods: periods,
      output: _amountOrNull(s['output_vat_amount']) ?? output,
      input: _amountOrNull(s['input_vat_amount']) ?? input,
      balance: _amountOrNull(s['balance']) ?? output - input,
      paid: _amountOrNull(s['paid_amount']) ?? paid,
      erarioBalance: _amountOrNull(s['erario_balance']) ?? erarioParts,
      creditCarriedForward: _amountOrNull(s['credit_carried_forward']),
      currency: _str(
        s['currency'],
        periods.isEmpty ? 'EUR' : periods.first.currency,
      ),
      fromServer: server != null && server.isNotEmpty,
    );
  }

  final int year;
  final List<LipeSettlement> periods;
  final Amount4 output;
  final Amount4 input;

  /// Annual debit (positive) or credit (negative).
  final Amount4 balance;
  final Amount4 paid;
  final Amount4? erarioBalance;
  final Amount4? creditCarriedForward;
  final String currency;
  final bool fromServer;

  /// Debit still to pay for the year.
  Amount4 get stillDue => balance > paid ? balance - paid : 0;

  /// Periods 1-4 of a quarterly company without a settlement.
  List<int> get missingQuarters => <int>[
    for (int q = 1; q <= 4; q++)
      if (!periods.any((LipeSettlement s) => s.quarterly && s.period == q)) q,
  ];

  /// Erario c/IVA against the annual balance.
  ReconciliationState get reconciliation {
    final Amount4? erario = erarioBalance;
    if (erario == null) {
      return ReconciliationState.unknown;
    }
    return (erario - balance).abs() <= reconciliationTolerance
        ? ReconciliationState.reconciled
        : ReconciliationState.difference;
  }

  Amount4 get erarioDifference => (erarioBalance ?? balance) - balance;
}

// --- Certificazione Unica ------------------------------------------------------------------------------------------

enum RecipientKind {
  professional('professional'),
  agent('agent');

  const RecipientKind(this.wire);

  final String wire;

  static RecipientKind fromWire(String? wire) => values.firstWhere(
    (RecipientKind k) => k.wire == wire,
    orElse: () => RecipientKind.professional,
  );
}

enum F24Status { unpaid, partial, paid }

/// `Certificazione Unica` of one self-employed person or agent: compensation, withholding and its F24 payment.
class WithholdingCertificate {
  const WithholdingCertificate({
    required this.id,
    required this.year,
    required this.recipientName,
    required this.gross,
    required this.taxable,
    required this.withheld,
    required this.f24Paid,
    this.kind = RecipientKind.professional,
    this.taxCode,
    this.vatNumber,
    this.causale = 'A',
    this.f24PaidOn,
    this.f24Code = '1040',
    this.currency = 'EUR',
    this.pdfAvailable = false,
  });

  factory WithholdingCertificate.fromJson(Map<String, dynamic> j) =>
      WithholdingCertificate(
        id: _str(j['id']),
        year: _intOrNull(j['year']) ?? 0,
        recipientName: _str(j['recipient_name']),
        kind: RecipientKind.fromWire(_strOrNull(j['recipient_kind'])),
        taxCode: _strOrNull(j['tax_code']),
        vatNumber: _strOrNull(j['vat_number']),
        causale: _str(j['causale'], 'A'),
        gross: amountFromJson(j['gross_amount']),
        taxable: amountFromJson(j['taxable_amount']),
        withheld: amountFromJson(j['withheld_amount']),
        f24Paid: amountFromJson(j['f24_paid_amount']),
        f24PaidOn: _date(j['f24_paid_on']),
        f24Code: _str(j['f24_tribute_code'], '1040'),
        currency: _str(j['currency'], 'EUR'),
        pdfAvailable: j['pdf_available'] != false,
      );

  final String id;
  final int year;
  final String recipientName;
  final RecipientKind kind;
  final String? taxCode;
  final String? vatNumber;

  /// `Causale` of the compensation (`A` self-employed, `R` agents' commission...).
  final String causale;
  final Amount4 gross;
  final Amount4 taxable;
  final Amount4 withheld;
  final Amount4 f24Paid;
  final DateTime? f24PaidOn;

  /// F24 tribute code of the withholding: 1040 for self-employed, 1038 for commission agents.
  final String f24Code;
  final String currency;
  final bool pdfAvailable;

  Amount4 get f24Open => withheld > f24Paid ? withheld - f24Paid : 0;

  F24Status get f24Status {
    if (withheld <= 0 || f24Paid >= withheld) {
      return F24Status.paid;
    }
    return f24Paid > 0 ? F24Status.partial : F24Status.unpaid;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'year': year,
    'recipient_name': recipientName,
    'recipient_kind': kind.wire,
    'tax_code': taxCode,
    'vat_number': vatNumber,
    'causale': causale,
    'gross_amount': amountToWire(gross),
    'taxable_amount': amountToWire(taxable),
    'withheld_amount': amountToWire(withheld),
    'f24_paid_amount': amountToWire(f24Paid),
    'f24_paid_on': _dateWire(f24PaidOn),
    'f24_tribute_code': f24Code,
    'currency': currency,
    'pdf_available': pdfAvailable,
  };
}

/// Totals of the certificates of a year.
class CertificateTotals {
  const CertificateTotals({
    required this.gross,
    required this.withheld,
    required this.f24Paid,
    required this.count,
  });

  factory CertificateTotals.of(List<WithholdingCertificate> certificates) =>
      CertificateTotals(
        gross: certificates.fold(
          0,
          (Amount4 a, WithholdingCertificate c) => a + c.gross,
        ),
        withheld: certificates.fold(
          0,
          (Amount4 a, WithholdingCertificate c) => a + c.withheld,
        ),
        f24Paid: certificates.fold(
          0,
          (Amount4 a, WithholdingCertificate c) => a + c.f24Paid,
        ),
        count: certificates.length,
      );

  final Amount4 gross;
  final Amount4 withheld;
  final Amount4 f24Paid;
  final int count;

  Amount4 get f24Open => withheld > f24Paid ? withheld - f24Paid : 0;
}

// --- Files and outbox ----------------------------------------------------------------------------------------------

/// A file downloaded from the server (LIPE XML, PDF, CU telematic file, register CSV).
class VatFile {
  const VatFile({
    required this.fileName,
    required this.bytes,
    required this.mimeType,
  });

  final String fileName;
  final List<int> bytes;
  final String mimeType;
}

enum ActionStatus { sent, queued, rejected }

class ActionOutcome {
  const ActionOutcome(this.status, {this.detail = ''});

  final ActionStatus status;
  final String detail;
}

/// What the outbox can hold for the module.
enum VatActionKind { intentLetter, lipeGeneration, certificateGeneration }

/// A write waiting in the outbox (or refused by the server).
class PendingVatAction {
  const PendingVatAction({
    required this.queueUuid,
    required this.kind,
    required this.rejected,
    this.targetId = '',
    this.detail = '',
  });

  final String queueUuid;
  final VatActionKind kind;
  final bool rejected;

  /// Settlement id or certificate year the action refers to.
  final String targetId;
  final String detail;
}
