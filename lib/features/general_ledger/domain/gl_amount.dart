/// Money of the general ledger as an integer count of ten-thousandths (the 4 decimals the API uses), so sums and the
/// balance check never suffer from binary floating point drift.
typedef Amount4 = int;

const int amountScale = 10000;

/// Parses a decimal text (`1234.5`, `1234,50`, `0.0001`) into [Amount4]; null when it is not a plain non-negative number.
/// More than 4 decimals are rounded half up.
Amount4? parseAmount(String? raw) {
  if (raw == null) {
    return null;
  }
  final String text = raw.trim().replaceAll(',', '.');
  final RegExpMatch? m = RegExp(r'^(\d+)(?:\.(\d*))?$').firstMatch(text);
  if (m == null) {
    return null;
  }
  final int whole = int.parse(m.group(1)!);
  final String fractionRaw = m.group(2) ?? '';
  final String padded = fractionRaw.padRight(5, '0');
  final int fraction = int.parse(padded.substring(0, 4));
  final bool roundUp = int.parse(padded[4]) >= 5;
  return whole * amountScale + fraction + (roundUp ? 1 : 0);
}

/// Reads an API value (string `"108.1000"` or number) into [Amount4]; negative values are kept (running balances).
Amount4 amountFromJson(Object? value) {
  if (value == null) {
    return 0;
  }
  final String text = '$value'.trim();
  final bool negative = text.startsWith('-');
  final Amount4? parsed = parseAmount(negative ? text.substring(1) : text);
  if (parsed == null) {
    return 0;
  }
  return negative ? -parsed : parsed;
}

/// The API decimal string of an amount (always 4 decimals, `.` separator).
String amountToWire(Amount4 value) {
  final String sign = value < 0 ? '-' : '';
  final int abs = value.abs();
  final String fraction = (abs % amountScale).toString().padLeft(4, '0');
  return '$sign${abs ~/ amountScale}.$fraction';
}

/// Display text with two decimals and thousands grouping, localized by language code (it/de/fr use the decimal comma).
String formatAmount(Amount4 value, {String language = 'en'}) {
  final bool negative = value < 0;
  final int abs = value.abs();
  // Half-up rounding to cents.
  final int cents = (abs + 50) ~/ 100;
  final String whole = (cents ~/ 100).toString();
  final String fraction = (cents % 100).toString().padLeft(2, '0');
  final String group = switch (language) {
    'it' || 'de' => '.',
    'fr' => ' ',
    _ => ',',
  };
  final String decimal = language == 'en' ? '.' : ',';
  final StringBuffer out = StringBuffer();
  for (int i = 0; i < whole.length; i++) {
    if (i > 0 && (whole.length - i) % 3 == 0) {
      out.write(group);
    }
    out.write(whole[i]);
  }
  final bool isZero = cents == 0;
  return '${negative && !isZero ? '-' : ''}$out$decimal$fraction';
}

/// Text for an input field: empty for zero, otherwise the amount without trailing zeros (`12.5`).
String amountToInput(Amount4 value) {
  if (value == 0) {
    return '';
  }
  final String wire = amountToWire(value);
  final String trimmed = wire.replaceFirst(RegExp(r'0+$'), '');
  return trimmed.endsWith('.')
      ? trimmed.substring(0, trimmed.length - 1)
      : trimmed;
}
