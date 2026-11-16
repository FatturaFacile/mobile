import 'package:fattura_facile/l10n/ff_strings.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('en, it, de and fr define every label', () {
    for (final code in ['en', 'it', 'de', 'fr']) {
      final table = FfStrings.tables[code]!;
      for (final key in L.values) {
        expect(table[key], isNotNull, reason: '$code is missing $key');
        expect(table[key]!.trim(), isNotEmpty, reason: '$code has an empty $key');
      }
      expect(table.length, L.values.length, reason: '$code has extra keys');
    }
  });

  test('placeholders are present in every translation', () {
    for (final code in ['en', 'it', 'de', 'fr']) {
      final table = FfStrings.tables[code]!;
      expect(table[L.scannedProgress], allOf(contains('{done}'), contains('{total}')), reason: code);
      expect(table[L.dispatchTitle], contains('{number}'), reason: code);
      expect(table[L.receiptTitle], contains('{number}'), reason: code);
      expect(table[L.linesCount], contains('{n}'), reason: code);
      expect(table[L.receiptResult], contains('{status}'), reason: code);
    }
  });

  test('t() substitutes arguments and falls back to English for unknown locales', () {
    expect(const FfStrings(Locale('it')).t(L.linesCount, {'n': '3'}), '3 righe');
    expect(const FfStrings(Locale('xx')).t(L.queueTitle), 'Transfers');
  });
}
