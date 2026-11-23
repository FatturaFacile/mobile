import 'package:fattura_facile/features/swiss_vat/domain/swiss_vat_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SwissVatDomain rates & UID validation', () {
    test('returns 2024+ rates (8.1/2.6/3.8) and historical 2018-2023 rates (7.7/2.5/3.7)', () {
      final SwissVatEpochRates current = SwissVatDomain.rateEpochFor(
        DateTime(2026, 3, 31),
      );
      expect(current.standardRate, 8.1);
      expect(current.reducedRate, 2.6);
      expect(current.accommodationRate, 3.8);
      expect(current.standardBox, '303');
      expect(current.bezugsteuerBox, '383');

      final SwissVatEpochRates legacy = SwissVatDomain.rateEpochFor(
        DateTime(2023, 12, 31),
      );
      expect(legacy.standardRate, 7.7);
      expect(legacy.reducedRate, 2.5);
      expect(legacy.accommodationRate, 3.7);
      expect(legacy.standardBox, '302');
      expect(legacy.bezugsteuerBox, '382');
    });

    test('validates Swiss UID-MWST via Mod-11 check digit', () {
      expect(SwissVatDomain.isValidUidMwst('CHE-116.281.710 MWST'), isTrue);
      expect(SwissVatDomain.isValidUidMwst('116281710'), isTrue);
      expect(SwissVatDomain.isValidUidMwst('CHE-116.281.711 MWST'), isFalse);
      expect(SwissVatDomain.isValidUidMwst('CHE-000.000.000 MWST'), isFalse);
      expect(
        SwissVatDomain.normalizeUid('116281710'),
        'CHE-116.281.710 MWST',
      );
    });

    test('identifies foreign suppliers subject to Bezugsteuer outside CH/LI', () {
      expect(SwissVatDomain.isForeignSupplierForBezugsteuer('de'), isTrue);
      expect(SwissVatDomain.isForeignSupplierForBezugsteuer('CH'), isFalse);
      expect(SwissVatDomain.isForeignSupplierForBezugsteuer('LI'), isFalse);
      expect(
        SwissVatDomain.isForeignSupplierForBezugsteuer(
          'DE',
          chargedSwissVat: 81.0,
        ),
        isFalse,
      );
      expect(
        SwissVatDomain.previewBezugsteuerTax(1000, DateTime(2026, 2, 1)),
        81.0,
      );
    });

    test('previews LIVA Art. 30-33 input tax adjustments accurately', () {
      final double autoMovable = SwissVatDomain.previewAdjustmentAmount(
        type: InputTaxAdjustmentType.autoconsumo,
        originalCostChf: 10000,
        originalVatRate: 8.1,
        yearsElapsed: 2,
        isRealEstate: false,
      );
      expect(autoMovable, 486.0);
      expect(InputTaxAdjustmentType.autoconsumo.afcBox, '415');

      final double degRealEstate = SwissVatDomain.previewAdjustmentAmount(
        type: InputTaxAdjustmentType.degrassazione,
        originalCostChf: 100000,
        originalVatRate: 8.1,
        yearsElapsed: 5,
        isRealEstate: true,
      );
      expect(degRealEstate, 6075.0);
      expect(InputTaxAdjustmentType.degrassazione.afcBox, '410');
    });
  });
}
