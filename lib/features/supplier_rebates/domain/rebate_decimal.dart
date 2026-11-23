import 'package:flutter/foundation.dart';

/// Exact decimal for rebate arithmetic: a [BigInt] count of 10^-10 units, the scale of the backend `Decimal` helper
/// (bcmath, scale 10). Products and quotients truncate toward zero exactly like `bcmul`/`bcdiv`, and [round2] rounds half
/// away from zero, so the offline figures of the phone match the ones the server computes. Floats never enter the
/// arithmetic; [toDouble] exists only to size progress bars.
@immutable
class Dec implements Comparable<Dec> {
  const Dec._(this.units);

  /// Digits after the decimal point kept by every operation.
  static const int scale = 10;

  static final BigInt _one = BigInt.from(10).pow(scale);

  static final Dec zero = Dec._(BigInt.zero);
  static final Dec hundred = Dec._(BigInt.from(100) * _one);

  /// The value times 10^[scale].
  final BigInt units;

  static final RegExp _pattern = RegExp(r'^([+-]?)(\d*)(?:\.(\d*))?$');

  /// Parses a decimal string (`"1250.50"`, `"-3"`, `".5"`), an int or a double. Anything else is `null`.
  static Dec? tryParse(Object? raw) {
    if (raw == null) {
      return null;
    }
    final String text = switch (raw) {
      final int i => '$i',
      final double d => d.isFinite ? d.toStringAsFixed(scale) : '',
      _ => '$raw'.trim(),
    };
    final RegExpMatch? m = _pattern.firstMatch(text);
    if (m == null) {
      return null;
    }
    final String whole = m.group(2) ?? '';
    final String fraction = m.group(3) ?? '';
    if (whole.isEmpty && fraction.isEmpty) {
      return null;
    }
    final String padded = fraction.length >= scale
        ? fraction.substring(0, scale)
        : fraction.padRight(scale, '0');
    final BigInt value = BigInt.parse('${whole.isEmpty ? '0' : whole}$padded');
    return Dec._(m.group(1) == '-' ? -value : value);
  }

  /// Like [tryParse] but a missing or malformed value is [fallback] (zero by default).
  static Dec parse(Object? raw, [Dec? fallback]) =>
      tryParse(raw) ?? fallback ?? zero;

  Dec operator +(Dec other) => Dec._(units + other.units);

  Dec operator -(Dec other) => Dec._(units - other.units);

  Dec operator -() => Dec._(-units);

  /// Truncates toward zero at 10 decimals.
  Dec operator *(Dec other) => Dec._((units * other.units) ~/ _one);

  /// Truncates toward zero at 10 decimals; dividing by zero yields zero (the callers guard it anyway).
  Dec operator /(Dec other) =>
      other.units == BigInt.zero ? zero : Dec._((units * _one) ~/ other.units);

  bool operator <(Dec other) => units < other.units;
  bool operator <=(Dec other) => units <= other.units;
  bool operator >(Dec other) => units > other.units;
  bool operator >=(Dec other) => units >= other.units;

  bool get isPositive => units > BigInt.zero;
  bool get isNegative => units < BigInt.zero;
  bool get isZero => units == BigInt.zero;

  Dec get abs => isNegative ? -this : this;

  static Dec max(Dec a, Dec b) => a >= b ? a : b;
  static Dec min(Dec a, Dec b) => a <= b ? a : b;

  /// Rounded to two decimals, half away from zero.
  Dec round2() {
    final BigInt step = BigInt.from(10).pow(scale - 2);
    final BigInt magnitude = units.abs();
    BigInt cents = magnitude ~/ step;
    if ((magnitude % step) * BigInt.two >= step) {
      cents += BigInt.one;
    }
    final BigInt rounded = cents * step;
    return Dec._(isNegative ? -rounded : rounded);
  }

  /// Plain `1234.50` string, two decimals, after [round2].
  String toFixed2() {
    final Dec r = round2();
    final String digits = r.units.abs().toString().padLeft(scale + 1, '0');
    final String whole = digits.substring(0, digits.length - scale);
    final String cents = digits.substring(digits.length - scale).substring(0, 2);
    return '${r.isNegative ? '-' : ''}$whole.$cents';
  }

  /// Exact plain string with at least two decimals and no trailing zeros beyond them (`4.5000` for a rate).
  String toPlain() {
    final String digits = units.abs().toString().padLeft(scale + 1, '0');
    final String whole = digits.substring(0, digits.length - scale);
    String fraction = digits.substring(digits.length - scale);
    while (fraction.length > 2 && fraction.endsWith('0')) {
      fraction = fraction.substring(0, fraction.length - 1);
    }
    return '${isNegative ? '-' : ''}$whole.$fraction';
  }

  /// Lossy conversion for layout only (progress bars, chart extents).
  double toDouble() => units.toDouble() / _one.toDouble();

  @override
  int compareTo(Dec other) => units.compareTo(other.units);

  @override
  bool operator ==(Object other) => other is Dec && other.units == units;

  @override
  int get hashCode => units.hashCode;

  @override
  String toString() => toPlain();
}
