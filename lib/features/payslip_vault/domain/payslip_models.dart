import 'package:flutter/foundation.dart';

/// Which document of a payroll distribution is opened.
enum PayslipKind {
  cedolino('cedolino'),
  cu('cu');

  const PayslipKind(this.wire);

  final String wire;
}

/// One monthly payslip row of the employee vault (`GET /italian-payroll/my-payslips`).
@immutable
class PayslipEntry {
  const PayslipEntry({
    required this.distributionId,
    required this.year,
    required this.month,
    required this.hasCedolino,
    required this.hasCu,
    this.netAmount,
    this.firstViewedAt,
  });

  factory PayslipEntry.fromJson(Map<String, dynamic> json) => PayslipEntry(
    distributionId: '${json['distribution_id']}',
    year: _int(json['year']),
    month: _int(json['month']),
    netAmount: json['net_amount'] == null
        ? null
        : double.tryParse('${json['net_amount']}'),
    hasCedolino: json['has_cedolino'] == true,
    hasCu: json['has_cu'] == true,
    firstViewedAt: json['first_viewed_at'] is String
        ? DateTime.tryParse(json['first_viewed_at'] as String)?.toUtc()
        : null,
  );

  final String distributionId;
  final int year;
  final int month;
  final double? netAmount;
  final bool hasCedolino;
  final bool hasCu;
  final DateTime? firstViewedAt;

  bool get viewed => firstViewedAt != null;

  static int _int(Object? v) => v is int ? v : int.tryParse('$v') ?? 0;
}

enum PayslipErrorKind {
  offline,
  unauthorized,
  forbidden,
  notFound,
  biometricRequired,
  unknown,
}

class PayslipException implements Exception {
  const PayslipException(this.kind, [this.detail = '']);

  final PayslipErrorKind kind;
  final String detail;

  @override
  String toString() => 'PayslipException($kind, $detail)';
}
