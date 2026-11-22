import 'package:fattura_facile/features/project_portfolio/l10n/project_portfolio_strings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every language has every label, none empty', () {
    for (final MapEntry<String, Map<PP, String>> table
        in ProjectPortfolioStrings.tables.entries) {
      for (final PP key in PP.values) {
        expect(table.value[key], isNotNull, reason: '${table.key} misses $key');
        expect(table.value[key]!.trim(), isNotEmpty, reason: '${table.key} $key');
      }
      expect(table.value.length, PP.values.length, reason: '${table.key} has extras');
    }
    expect(
      ProjectPortfolioStrings.tables.keys,
      containsAll(<String>['en', 'it', 'de', 'fr']),
    );
  });

  test('placeholders are the same in every language', () {
    final RegExp placeholder = RegExp(r'\{(\w+)\}');
    final Map<PP, String> english = ProjectPortfolioStrings.tables['en']!;
    for (final MapEntry<String, Map<PP, String>> table
        in ProjectPortfolioStrings.tables.entries) {
      for (final PP key in PP.values) {
        final Set<String> expected = placeholder
            .allMatches(english[key]!)
            .map((RegExpMatch m) => m.group(1)!)
            .toSet();
        final Set<String> actual = placeholder
            .allMatches(table.value[key]!)
            .map((RegExpMatch m) => m.group(1)!)
            .toSet();
        expect(actual, expected, reason: '${table.key} $key');
      }
    }
  });

  test('regional locales resolve to their language, unknown ones to English', () {
    expect(ProjectPortfolioStrings.forLanguage('it-CH').t(PP.statusActive), 'Attiva');
    expect(ProjectPortfolioStrings.forLanguage('de_CH').t(PP.statusActive), 'Aktiv');
    expect(ProjectPortfolioStrings.forLanguage('fr-CH').t(PP.statusActive), 'Actif');
    expect(ProjectPortfolioStrings.forLanguage('it-IT').t(PP.statusActive), 'Attiva');
    expect(ProjectPortfolioStrings.forLanguage('xx').t(PP.statusActive), 'Active');
  });

  test('placeholders are replaced', () {
    final ProjectPortfolioStrings s = ProjectPortfolioStrings.forLanguage('en');
    expect(s.f(PP.slipLate, <String, Object>{'count': 3}), '3 d late');
    expect(
      s.f(PP.deleteNodeMessage, <String, Object>{'title': 'Design'}),
      contains('"Design"'),
    );
  });
}
