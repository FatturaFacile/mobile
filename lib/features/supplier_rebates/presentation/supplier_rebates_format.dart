import 'package:intl/intl.dart';

import '../domain/rebate_decimal.dart';

/// Number and date formatting of the supplier rebates screens: Swiss separators for the Swiss locales, the agreement
/// currency (CHF/EUR) printed before the amount.
abstract final class RebateFormat {
  /// The `intl` locale of a language code (`de`, `de-CH`, `it_IT`...); Swiss conventions for it/de/fr.
  static String intlLocale(String languageCode) =>
      switch (languageCode.split(RegExp('[-_]')).first.toLowerCase()) {
        'it' => 'it_CH',
        'de' => 'de_CH',
        'fr' => 'fr_CH',
        _ => 'en',
      };

  /// `CHF 1’234.50`, rounded half away from zero to two decimals.
  static String money(Dec value, String currency, String languageCode) {
    final NumberFormat f = NumberFormat.decimalPatternDigits(
      locale: intlLocale(languageCode),
      decimalDigits: 2,
    );
    return '$currency ${f.format(value.round2().toDouble())}';
  }

  /// A quantity with up to three decimals.
  static String quantity(Dec value, String languageCode) =>
      NumberFormat('#,##0.###', intlLocale(languageCode)).format(value.toDouble());

  /// `12.5%`, two decimals at most.
  static String percent(Dec value, String languageCode) =>
      '${NumberFormat('0.##', intlLocale(languageCode)).format(value.round2().toDouble())}%';

  /// `31.12.2027` (`2027-12-31` in English).
  static String date(DateTime? date, String languageCode) {
    if (date == null) {
      return '';
    }
    final String y = date.year.toString().padLeft(4, '0');
    final String m = date.month.toString().padLeft(2, '0');
    final String d = date.day.toString().padLeft(2, '0');
    return languageCode.toLowerCase().startsWith('en') ? '$y-$m-$d' : '$d.$m.$y';
  }

  /// `01.01.2027 – 31.12.2027`.
  static String range(DateTime? from, DateTime? to, String languageCode) =>
      '${date(from, languageCode)} – ${date(to, languageCode)}';
}
