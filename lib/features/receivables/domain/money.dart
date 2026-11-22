import 'package:flutter/foundation.dart';

/// A money amount in integer minor units (cents), so receivables are never added, compared or split with doubles.
///
/// The API sends decimal strings with two decimals (`"1234.50"`); [Money.parse] reads them exactly and [toWire] writes
/// them back in the same shape.
@immutable
class Money implements Comparable<Money> {
  const Money(this.minor);

  static const Money zero = Money(0);

  /// Amount in cents.
  final int minor;

  static final RegExp _wire = RegExp(r'^([+-])?(\d+)(?:\.(\d+))?$');

  /// Parses a wire value (decimal string or JSON number). More than two decimals are rounded half away from zero.
  /// Throws [FormatException] when [value] is not a plain decimal.
  factory Money.parse(Object? value) {
    final Money? parsed = tryParse(value);
    if (parsed == null) {
      throw FormatException('Not a decimal amount: $value');
    }
    return parsed;
  }

  /// `null` when [value] is null or malformed.
  static Money? tryParse(Object? value) {
    if (value == null) {
      return null;
    }
    final RegExpMatch? m = _wire.firstMatch('$value'.trim());
    if (m == null) {
      return null;
    }
    final String whole = m.group(2)!;
    final String fraction = m.group(3) ?? '';
    final String padded = fraction.padRight(2, '0');
    int minor = int.parse(whole) * 100 + int.parse(padded.substring(0, 2));
    if (padded.length > 2 && padded.codeUnitAt(2) >= 0x35) {
      minor += 1;
    }
    return Money(m.group(1) == '-' ? -minor : minor);
  }

  /// A missing value is zero; a malformed one is a [FormatException].
  factory Money.parseOrZero(Object? value) =>
      value == null ? zero : Money.parse(value);

  /// Reads what a person typed (`1'234.50`, `1.234,50`, `12,5`); `null` when it is not an amount.
  static Money? tryParseInput(String text) {
    String t = text.trim().replaceAll(RegExp("[\\s'’]"), '');
    if (t.isEmpty) {
      return null;
    }
    final int comma = t.lastIndexOf(',');
    final int dot = t.lastIndexOf('.');
    if (comma >= 0 && dot >= 0) {
      // The last separator is the decimal one; the other groups thousands.
      t = comma > dot
          ? t.replaceAll('.', '').replaceAll(',', '.')
          : t.replaceAll(',', '');
    } else if (comma >= 0) {
      t = t.replaceAll(',', '.');
    }
    return tryParse(t);
  }

  bool get isZero => minor == 0;
  bool get isNegative => minor < 0;
  bool get isPositive => minor > 0;

  Money get abs => Money(minor.abs());

  Money operator +(Money other) => Money(minor + other.minor);
  Money operator -(Money other) => Money(minor - other.minor);
  Money operator -() => Money(-minor);
  bool operator <(Money other) => minor < other.minor;
  bool operator <=(Money other) => minor <= other.minor;
  bool operator >(Money other) => minor > other.minor;
  bool operator >=(Money other) => minor >= other.minor;

  /// The smaller of the two.
  Money min(Money other) => minor <= other.minor ? this : other;

  /// Sum of [values].
  static Money sum(Iterable<Money> values) =>
      values.fold<Money>(zero, (Money a, Money b) => a + b);

  /// `this / total` for display (bars, gauges) only; `0` when [total] is not positive.
  double ratio(Money total) => total.minor <= 0 ? 0 : minor / total.minor;

  /// Two decimals decimal string, as the API expects (`"-12.30"`).
  String toWire() {
    final String sign = minor < 0 ? '-' : '';
    final int a = minor.abs();
    return '$sign${a ~/ 100}.${(a % 100).toString().padLeft(2, '0')}';
  }

  /// Display text for a locale tag (`it-IT` uses `1.234,50`, the Swiss tags `1’234.50`, anything else `1,234.50`),
  /// prefixed with [currency] when given.
  String format(String tag, {String? currency}) {
    final String sign = minor < 0 ? '-' : '';
    final int a = minor.abs();
    final String group = switch (tag) {
      'it-IT' => '.',
      'it-CH' || 'de-CH' || 'fr-CH' => '’',
      _ => ',',
    };
    final String decimal = tag == 'it-IT' ? ',' : '.';
    final String digits = '${a ~/ 100}';
    final StringBuffer whole = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        whole.write(group);
      }
      whole.write(digits[i]);
    }
    final String text =
        '$sign$whole$decimal${(a % 100).toString().padLeft(2, '0')}';
    return currency == null || currency.isEmpty ? text : '$currency $text';
  }

  @override
  int compareTo(Money other) => minor.compareTo(other.minor);

  @override
  bool operator ==(Object other) => other is Money && other.minor == minor;

  @override
  int get hashCode => minor.hashCode;

  @override
  String toString() => toWire();
}
