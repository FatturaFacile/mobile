import 'package:fattura_facile/features/supplier_rebates/domain/supplier_rebate_models.dart';
import 'package:fattura_facile/features/supplier_rebates/presentation/supplier_rebates_format.dart';
import 'package:fattura_facile/features/supplier_rebates/presentation/supplier_rebates_strings.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

void main() {
  group('locale tables', () {
    test('every language defines every label, none of them empty', () {
      expect(supplierRebatesLocaleTables.keys, unorderedEquals(<String>['it', 'en', 'de', 'fr']));
      for (final MapEntry<String, Map<RB, String>> table in supplierRebatesLocaleTables.entries) {
        for (final RB key in RB.values) {
          expect(table.value[key], isNotNull, reason: '${table.key} misses $key');
          expect(table.value[key]!.trim(), isNotEmpty, reason: '${table.key} empty $key');
        }
        expect(table.value.length, RB.values.length, reason: '${table.key} has extra keys');
      }
    });

    test('the translations of a label differ between the languages that must differ', () {
      for (final RB key in <RB>[RB.title, RB.approve, RB.blanketBalance, RB.errorOffline]) {
        final Set<String> texts = <String>{
          for (final Map<RB, String> t in supplierRebatesLocaleTables.values) t[key]!,
        };
        expect(texts.length, greaterThan(1), reason: '$key is not translated');
      }
    });

    test('keeps the agreed terminology', () {
      const SupplierRebatesStrings it = SupplierRebatesStrings('it');
      const SupplierRebatesStrings de = SupplierRebatesStrings('de');
      const SupplierRebatesStrings fr = SupplierRebatesStrings('fr');
      const SupplierRebatesStrings en = SupplierRebatesStrings('en');

      expect(it(RB.tabBlankets), 'Contratti quadro');
      expect(de(RB.tabBlankets), 'Rahmenverträge');
      expect(fr(RB.tabBlankets), 'Accords-cadres');
      expect(en(RB.tabBlankets), 'Blanket agreements');
      expect(it(RB.title), 'Premi fornitori');
      expect(de(RB.title), 'Lieferantenrückvergütungen');
      expect(fr(RB.title), 'Ristournes fournisseurs');
      expect(it(RB.accrualRuns), 'Calcolo ratei');
      expect(it(RB.lineCreditNote), 'Nota di credito');
      expect(de(RB.lineCreditNote), 'Gutschrift');
      expect(it(RB.execApSetOff), 'Compensazione nello scadenzario passivo');
    });
  });

  group('language selection', () {
    test('regional tags pick their language: it-CH, it-IT, de-CH, fr-CH, en', () {
      expect(const SupplierRebatesStrings('it-CH')(RB.approve), 'Approva');
      expect(const SupplierRebatesStrings('it_IT')(RB.approve), 'Approva');
      expect(const SupplierRebatesStrings('de-CH')(RB.approve), 'Genehmigen');
      expect(const SupplierRebatesStrings('fr-CH')(RB.approve), 'Approuver');
      expect(const SupplierRebatesStrings('en')(RB.approve), 'Approve');
      expect(const SupplierRebatesStrings('DE')(RB.approve), 'Genehmigen');
    });

    test('an unknown language falls back to English', () {
      expect(const SupplierRebatesStrings('rm')(RB.approve), 'Approve');
      expect(const SupplierRebatesStrings('')(RB.approve), 'Approve');
    });
  });

  group('enum labels', () {
    const SupplierRebatesStrings s = SupplierRebatesStrings('en');

    test('every status, type, mode and alert has a label', () {
      for (final RebateType t in RebateType.values) {
        expect(s.rebateType(t), isNotEmpty);
      }
      for (final TierMode m in TierMode.values) {
        expect(s.tierMode(m), isNotEmpty);
      }
      for (final AgreementStatus v in AgreementStatus.values) {
        expect(s.agreementStatus(v), isNotEmpty);
      }
      for (final ProposalStatus v in ProposalStatus.values) {
        expect(s.proposalStatus(v), isNotEmpty);
      }
      for (final ExecutionMode m in ExecutionMode.values) {
        expect(s.executionMode(m), isNotEmpty);
      }
      for (final ProposalLineType t in ProposalLineType.values) {
        expect(s.lineType(t), isNotEmpty);
      }
      for (final ContributionStatus v in ContributionStatus.values) {
        expect(s.contributionStatus(v), isNotEmpty);
      }
      for (final RunStatus v in RunStatus.values) {
        expect(s.runStatus(v), isNotEmpty);
      }
      for (final BalanceAlertCode c in BalanceAlertCode.values) {
        expect(s.alert(c), isNotEmpty);
      }
      for (final ProposalAction a in ProposalAction.values) {
        expect(s.action(a), isNotEmpty);
        expect(s.confirm(a), isNotEmpty);
      }
    });

    test('wire values of the contributions and frequencies are mapped', () {
      expect(s.contributionKind('co_marketing'), 'Co-marketing');
      expect(s.contributionKind('other'), 'other');
      expect(s.frequencyName('quarterly'), 'Quarterly');
      expect(s.frequencyName(null), '');
    });

    test('error messages use the problem detail when the server sent one', () {
      expect(s.error(const RebateException(RebateErrorKind.offline)), 'No connection');
      expect(s.error(const RebateException(RebateErrorKind.invalid)), 'Not allowed in the current state');
      expect(
        s.error(const RebateException(RebateErrorKind.invalid, detail: 'Version conflict')),
        'Version conflict',
      );
      expect(s.error(const RebateException(RebateErrorKind.forbidden)), isNotEmpty);
      expect(s.error(const RebateException(RebateErrorKind.notFound)), isNotEmpty);
      expect(s.error(const RebateException(RebateErrorKind.unknown)), isNotEmpty);
    });
  });

  group('RebateFormat', () {
    test('money follows the Swiss separators of it, de and fr and the plain ones of English', () {
      expect(RebateFormat.money(d('1234567.5'), 'CHF', 'en'), 'CHF 1,234,567.50');
      expect(RebateFormat.money(d('1234567.5'), 'CHF', 'de-CH'), 'CHF 1’234’567.50');
      expect(RebateFormat.money(d('1234.5'), 'CHF', 'it-CH'), 'CHF 1’234.50');
      // Italy keeps the Italian conventions.
      expect(RebateFormat.money(d('1234.5'), 'EUR', 'it_IT'), 'EUR 1.234,50');
    });

    test('money is rounded half away from zero to the cent', () {
      expect(RebateFormat.money(d('10.005'), 'CHF', 'en'), 'CHF 10.01');
      expect(RebateFormat.money(d('-10.005'), 'CHF', 'en'), 'CHF -10.01');
      expect(RebateFormat.money(d('0'), 'CHF', 'en'), 'CHF 0.00');
    });

    test('percent shows at most two decimals', () {
      expect(RebateFormat.percent(d('2'), 'en'), '2%');
      expect(RebateFormat.percent(d('13.333'), 'en'), '13.33%');
      expect(RebateFormat.percent(d('8.1'), 'en'), '8.1%');
    });

    test('dates are dd.MM.yyyy in it, de and fr and ISO in English', () {
      expect(RebateFormat.date(DateTime(2027, 12, 31), 'de-CH'), '31.12.2027');
      expect(RebateFormat.date(DateTime(2027, 12, 31), 'en'), '2027-12-31');
      expect(RebateFormat.date(null, 'en'), '');
      expect(
        RebateFormat.range(DateTime(2027), DateTime(2027, 12, 31), 'fr'),
        '01.01.2027 – 31.12.2027',
      );
    });

    test('quantities keep up to three decimals', () {
      expect(RebateFormat.quantity(d('1200'), 'en'), '1,200');
      expect(RebateFormat.quantity(d('12.3456'), 'en'), '12.346');
    });
  });
}
