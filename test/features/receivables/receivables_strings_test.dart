import 'dart:ui';

import 'package:fattura_facile/features/receivables/domain/money.dart';
import 'package:fattura_facile/features/receivables/domain/receivables_models.dart';
import 'package:fattura_facile/features/receivables/presentation/receivables_strings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('locale tables', () {
    test('cover exactly the five locales', () {
      expect(
        ReceivablesStrings.tables.keys.toSet(),
        receivablesLocales.toSet(),
      );
      expect(receivablesLocales, <String>[
        'it-IT',
        'it-CH',
        'de-CH',
        'fr-CH',
        'en',
      ]);
    });

    test('every locale defines every key with a non-empty text', () {
      for (final MapEntry<String, Map<RC, String>> table
          in ReceivablesStrings.tables.entries) {
        for (final RC key in RC.values) {
          expect(
            table.value[key],
            isNotNull,
            reason: '${table.key} misses ${key.name}',
          );
          expect(
            table.value[key]!.trim(),
            isNotEmpty,
            reason: '${table.key} has an empty ${key.name}',
          );
        }
        expect(
          table.value.length,
          RC.values.length,
          reason: '${table.key} has keys that are not in RC',
        );
      }
    });

    test('placeholders are the same in every locale', () {
      final RegExp ph = RegExp(r'\{(\w+)\}');
      for (final RC key in RC.values) {
        final Set<String?> expected = ph
            .allMatches(ReceivablesStrings.tables['en']![key]!)
            .map((RegExpMatch m) => m.group(1))
            .toSet();
        for (final MapEntry<String, Map<RC, String>> table
            in ReceivablesStrings.tables.entries) {
          final Set<String?> found = ph
              .allMatches(table.value[key]!)
              .map((RegExpMatch m) => m.group(1))
              .toSet();
          expect(found, expected, reason: '${table.key} ${key.name}');
        }
      }
    });

    test('the languages are really translated, not copied from English', () {
      for (final String tag in <String>['it-IT', 'de-CH', 'fr-CH']) {
        final Map<RC, String> table = ReceivablesStrings.tables[tag]!;
        final int same = RC.values
            .where((RC k) => table[k] == ReceivablesStrings.tables['en']![k])
            .length;
        // Only acronyms and borrowed words (DSO, XLSX...) may match.
        expect(same, lessThan(12), reason: tag);
      }
    });

    test('it-CH is Italian with the Swiss vocabulary', () {
      expect(ReceivablesStrings.forTag('it-CH').t(RC.title), 'Debitori');
      expect(ReceivablesStrings.forTag('it-IT').t(RC.title), 'Crediti clienti');
      expect(
        ReceivablesStrings.forTag('it-CH').t(RC.refresh),
        ReceivablesStrings.forTag('it-IT').t(RC.refresh),
      );
    });
  });

  group('locale resolution', () {
    test('Italian goes to it-CH only for Switzerland', () {
      expect(ReceivablesStrings.tagOf(const Locale('it')), 'it-IT');
      expect(ReceivablesStrings.tagOf(const Locale('it', 'IT')), 'it-IT');
      expect(ReceivablesStrings.tagOf(const Locale('it', 'CH')), 'it-CH');
    });

    test('German and French use their Swiss tables, anything else English', () {
      expect(ReceivablesStrings.tagOf(const Locale('de')), 'de-CH');
      expect(ReceivablesStrings.tagOf(const Locale('de', 'DE')), 'de-CH');
      expect(ReceivablesStrings.tagOf(const Locale('fr', 'CH')), 'fr-CH');
      expect(ReceivablesStrings.tagOf(const Locale('en', 'US')), 'en');
      expect(ReceivablesStrings.tagOf(const Locale('pt')), 'en');
    });

    test('an unknown tag falls back to English', () {
      expect(ReceivablesStrings.forTag('xx').t(RC.title), 'Receivables');
    });
  });

  group('formatting', () {
    final ReceivablesStrings en = ReceivablesStrings.forTag('en');
    final ReceivablesStrings itIt = ReceivablesStrings.forTag('it-IT');
    final ReceivablesStrings deCh = ReceivablesStrings.forTag('de-CH');

    test('money follows the locale', () {
      expect(en.money(Money.parse('1234.5'), 'CHF'), 'CHF 1,234.50');
      expect(itIt.money(Money.parse('1234.5'), 'EUR'), 'EUR 1.234,50');
      expect(deCh.money(Money.parse('1234.5')), '1’234.50');
    });

    test('dates and percentages follow the locale', () {
      final DateTime d = DateTime(2030, 3, 4);
      expect(en.date(d), '2030-03-04');
      expect(itIt.date(d), '04/03/2030');
      expect(deCh.date(d), '04.03.2030');
      expect(en.date(null), '');
      expect(en.percent(85.26), '85.3%');
      expect(itIt.percent(85.2), '85,2%');
    });

    test('placeholders are filled', () {
      expect(en.f(RC.daysValue, <String, Object>{'n': 5}), '5 days');
      expect(
        itIt.f(RC.customerOpenOverdue, <String, Object>{
          'open': '1',
          'overdue': '2',
        }),
        'Aperto 1 · scaduto 2',
      );
    });

    test('buckets are labelled from the server definition', () {
      expect(
        en.bucket(const AgingBucketDef(key: 'current', from: 0, to: 0)),
        'Not yet due',
      );
      expect(
        en.bucket(const AgingBucketDef(key: '1_15', from: 1, to: 15)),
        '1-15 days',
      );
      expect(
        en.bucket(const AgingBucketDef(key: '121_plus', from: 121)),
        '121+ days',
      );
      expect(
        itIt.bucket(const AgingBucketDef(key: '16_45', from: 16, to: 45)),
        '16-45 giorni',
      );
    });

    test('enum labels and errors resolve in every locale', () {
      for (final String tag in receivablesLocales) {
        final ReceivablesStrings s = ReceivablesStrings.forTag(tag);
        for (final ItemStatus v in ItemStatus.values) {
          expect(s.status(v), isNotEmpty);
        }
        for (final AllocationType v in AllocationType.values) {
          expect(s.allocationType(v), isNotEmpty);
        }
        for (final OverrideScope v in OverrideScope.values) {
          expect(s.overrideScope(v), isNotEmpty);
        }
        for (final RiskRating v in RiskRating.values) {
          expect(s.rating(v), isNotEmpty);
        }
        for (final DraftIssue v in DraftIssue.values) {
          expect(s.draftIssue(v), isNotEmpty);
        }
        for (final ReceivablesErrorKind k in ReceivablesErrorKind.values) {
          expect(s.error(ReceivablesException(k)), isNotEmpty);
        }
        expect(s.policy(ReactionPolicy.blockOrder), isNotEmpty);
        expect(s.policy(ReactionPolicy.unknown), isEmpty);
      }
    });

    test('a server message wins over the generic invalid text', () {
      expect(
        en.error(
          const ReceivablesException(
            ReceivablesErrorKind.invalid,
            detail: 'Credit hold',
          ),
        ),
        'Credit hold',
      );
      expect(
        en.error(const ReceivablesException(ReceivablesErrorKind.invalid)),
        'Action not allowed',
      );
    });
  });
}
