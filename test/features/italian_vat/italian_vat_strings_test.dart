import 'package:fattura_facile/features/italian_vat/domain/italian_vat_models.dart';
import 'package:fattura_facile/features/italian_vat/presentation/italian_vat_strings.dart';
import 'package:flutter_test/flutter_test.dart';

String t(String language, IV key) => ItalianVatStrings(language)(key);

void main() {
  group('locale tables', () {
    test('every language defines every label, none of them empty', () {
      expect(
        italianVatLocaleTables.keys,
        unorderedEquals(<String>['it', 'en', 'de', 'fr']),
      );
      for (final MapEntry<String, Map<IV, String>> table
          in italianVatLocaleTables.entries) {
        for (final IV key in IV.values) {
          expect(
            table.value[key],
            isNotNull,
            reason: '${table.key} misses $key',
          );
          expect(
            table.value[key]!.trim(),
            isNotEmpty,
            reason: '${table.key} empty $key',
          );
        }
        expect(
          table.value.length,
          IV.values.length,
          reason: '${table.key} has extra keys',
        );
      }
    });

    test('the translations of the labels differ between the languages that must differ', () {
      for (final IV key in <IV>[
        IV.title,
        IV.regSales,
        IV.addLetter,
        IV.plafondExceeded,
        IV.differenceFound,
        IV.f24Unpaid,
      ]) {
        final Set<String> texts = <String>{
          for (final Map<IV, String> t in italianVatLocaleTables.values)
            t[key]!,
        };
        expect(texts.length, greaterThan(1), reason: '$key is not translated');
      }
    });

    test('the legal acronyms stay untranslated in every language', () {
      for (final Map<IV, String> t in italianVatLocaleTables.values) {
        expect(t[IV.tabLipe], 'LIPE');
        expect(t[IV.tabPlafond], 'Plafond');
        expect(t[IV.erario], contains('Erario c/IVA'));
        expect(t[IV.certificates], contains('CU'));
        expect(t[IV.plafondLaw], contains('633/1972'));
      }
    });
  });

  group('language selection', () {
    test('a region tag selects its language: the Swiss and Italian variants of all five locales', () {
      expect(t('it-CH', IV.regSales), 'Vendite');
      expect(t('it-IT', IV.regSales), 'Vendite');
      expect(t('de-CH', IV.regSales), 'Verkäufe');
      expect(t('fr-CH', IV.regSales), 'Ventes');
      expect(t('en', IV.regSales), 'Sales');
      expect(const ItalianVatStrings('it_IT').language, 'it');
      expect(const ItalianVatStrings('FR').language, 'fr');
    });

    test('an unknown language falls back to English', () {
      expect(t('es', IV.regPurchases), 'Purchases');
      expect(t('', IV.regPurchases), 'Purchases');
    });

    test('keeps the agreed terminology', () {
      expect(t('it', IV.regReceipts), 'Corrispettivi');
      expect(t('it', IV.regThirdParty), 'Merci c/terzi');
      expect(t('it', IV.letters), "Lettere d'intento");
      expect(t('it', IV.proRata), 'Pro-rata di detraibilità');
      expect(t('it', IV.ventilation), 'Ventilazione dei corrispettivi');
      expect(t('de', IV.letters), 'Absichtserklärungen');
      expect(t('fr', IV.letters), "Lettres d'intention");
    });
  });

  group('enum helpers', () {
    const ItalianVatStrings en = ItalianVatStrings('en');

    test('name every register, letter kind and letter status', () {
      for (final VatRegisterType t in VatRegisterType.values) {
        expect(en.register(t), isNotEmpty);
      }
      for (final IntentLetterKind k in IntentLetterKind.values) {
        expect(en.kind(k), isNotEmpty);
      }
      for (final IntentLetterStatus s in IntentLetterStatus.values) {
        expect(en.letterStatus(s), isNotEmpty);
      }
    });

    test('word every plafond result, blocked ones as not allowed', () {
      for (final PlafondResult r in PlafondResult.values) {
        expect(en.plafond(r), isNotEmpty);
      }
      expect(en.plafond(PlafondResult.exceedsPlafond), contains('not allowed'));
      expect(en.plafond(PlafondResult.ok), isNot(contains('not allowed')));
    });

    test('word every draft issue', () {
      for (final IntentLetterDraftIssue i in IntentLetterDraftIssue.values) {
        expect(en.draftIssue(i), isNotEmpty);
      }
    });

    test('word the LIPE states, reconciliation, recipients, F24 and queued actions', () {
      for (final SignatureStatus s in SignatureStatus.values) {
        expect(en.signature(s), isNotEmpty);
      }
      expect(en.xsd(true), 'XSD validation passed');
      expect(en.xsd(false), 'XSD validation failed');
      expect(en.xsd(null), 'XSD validation not run');
      for (final ReconciliationState s in ReconciliationState.values) {
        expect(en.reconciliation(s), isNotEmpty);
      }
      for (final RecipientKind k in RecipientKind.values) {
        expect(en.recipientKind(k), isNotEmpty);
      }
      for (final F24Status f in F24Status.values) {
        expect(en.f24(f), isNotEmpty);
      }
      for (final VatActionKind k in VatActionKind.values) {
        expect(en.action(k), isNotEmpty);
      }
    });

    test('names the status of a settlement, paid first', () {
      expect(
        en.settlementStatus(
          LipeSettlement.fromJson(<String, dynamic>{
            'id': 'x',
            'status': 'draft',
          }),
        ),
        'Draft',
      );
      expect(
        en.settlementStatus(
          LipeSettlement.fromJson(<String, dynamic>{
            'id': 'x',
            'status': 'posted',
          }),
        ),
        'Posted',
      );
      expect(
        en.settlementStatus(
          LipeSettlement.fromJson(<String, dynamic>{
            'id': 'x',
            'status': 'posted',
            'paid_at': '2027-05-16',
          }),
        ),
        'Paid',
      );
    });

    test('an outcome shows the server detail when the request was refused', () {
      expect(
        en.outcome(
          const ActionOutcome(ActionStatus.queued),
          queued: IV.requestQueued,
          sent: IV.requestSent,
          rejected: IV.requestRejected,
        ),
        en(IV.requestQueued),
      );
      expect(
        en.outcome(
          const ActionOutcome(ActionStatus.rejected, detail: 'Not posted'),
          queued: IV.requestQueued,
          sent: IV.requestSent,
          rejected: IV.requestRejected,
        ),
        'Not posted',
      );
      expect(
        en.outcome(
          const ActionOutcome(ActionStatus.rejected),
          queued: IV.requestQueued,
          sent: IV.requestSent,
          rejected: IV.requestRejected,
        ),
        en(IV.requestRejected),
      );
    });

    test('maps every error kind, preferring the server detail for a refused request', () {
      for (final ItalianVatErrorKind k in ItalianVatErrorKind.values) {
        expect(en.error(ItalianVatException(k)), isNotEmpty);
      }
      expect(
        en.error(
          const ItalianVatException(
            ItalianVatErrorKind.invalid,
            detail: 'Bad year',
          ),
        ),
        'Bad year',
      );
      expect(
        en.error(const ItalianVatException(ItalianVatErrorKind.invalid)),
        en(IV.errorInvalid),
      );
    });
  });
}
