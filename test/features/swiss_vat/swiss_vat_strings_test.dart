import 'package:fattura_facile/features/swiss_vat/domain/swiss_vat_models.dart';
import 'package:fattura_facile/features/swiss_vat/presentation/swiss_vat_strings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SwissVatStrings 5-locale parity', () {
    test('defines all keys non-empty across it-CH, it-IT, de-CH, fr-CH, and en', () {
      expect(
        swissVatLocaleTables.keys,
        unorderedEquals(<String>['it-CH', 'it-IT', 'de-CH', 'fr-CH', 'en']),
      );

      for (final MapEntry<String, Map<SV, String>> entry
          in swissVatLocaleTables.entries) {
        for (final SV key in SV.values) {
          expect(
            entry.value[key],
            isNotNull,
            reason: '${entry.key} missing $key',
          );
          expect(
            entry.value[key]!.trim(),
            isNotEmpty,
            reason: '${entry.key} empty $key',
          );
        }
        expect(entry.value.length, SV.values.length);
      }
    });

    test('resolves all five target locales and adjustment labels without fallback gaps', () {
      for (final String locale in <String>[
        'it-CH',
        'it-IT',
        'de-CH',
        'fr-CH',
        'en',
      ]) {
        final SwissVatStrings s = SwissVatStrings(locale);
        expect(s.normalizedLocale, locale);
        expect(s(SV.title), isNotEmpty);
        for (final InputTaxAdjustmentType type
            in InputTaxAdjustmentType.values) {
          expect(s.adjustmentLabel(type), isNotEmpty);
        }
      }
    });
  });
}
