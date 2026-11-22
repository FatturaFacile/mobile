import 'package:fattura_facile/features/receivables/domain/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parse', () {
    test('reads decimal strings exactly, with no floating point drift', () {
      expect(Money.parse('0.10').minor, 10);
      expect(Money.parse('1234.50').minor, 123450);
      expect(Money.parse('19.99').minor, 1999);
      expect(Money.parse('-12.30').minor, -1230);
      expect(Money.parse('+7').minor, 700);
      expect(Money.parse('5.5').minor, 550);
      // 0.1 + 0.2 is 0.30000000000000004 as doubles; as money it is exact.
      expect(Money.parse('0.10') + Money.parse('0.20'), Money.parse('0.30'));
    });

    test('accepts JSON numbers', () {
      expect(Money.parse(12.5).minor, 1250);
      expect(Money.parse(3).minor, 300);
    });

    test('rounds more than two decimals half away from zero', () {
      expect(Money.parse('1.005').minor, 101);
      expect(Money.parse('1.004').minor, 100);
      expect(Money.parse('-1.005').minor, -101);
      expect(Money.parse('2.999').minor, 300);
    });

    test('rejects what is not a plain decimal', () {
      expect(() => Money.parse('abc'), throwsFormatException);
      expect(() => Money.parse('1e3'), throwsFormatException);
      expect(() => Money.parse(''), throwsFormatException);
      expect(() => Money.parse(null), throwsFormatException);
      expect(Money.tryParse(null), isNull);
      expect(Money.tryParse('1,5'), isNull);
    });

    test(
      'parseOrZero turns a missing value into zero but still rejects junk',
      () {
        expect(Money.parseOrZero(null), Money.zero);
        expect(() => Money.parseOrZero('x'), throwsFormatException);
      },
    );

    test('handles large amounts without losing cents', () {
      expect(Money.parse('999999999999.99').minor, 99999999999999);
    });
  });

  group('tryParseInput', () {
    test('reads what people type in each locale', () {
      expect(Money.tryParseInput('12,5'), Money.parse('12.50'));
      expect(Money.tryParseInput('12.5'), Money.parse('12.50'));
      expect(Money.tryParseInput("1'234.50"), Money.parse('1234.50'));
      expect(Money.tryParseInput('1.234,50'), Money.parse('1234.50'));
      expect(Money.tryParseInput('1,234.50'), Money.parse('1234.50'));
      expect(Money.tryParseInput(' 100 '), Money.parse('100'));
    });

    test('is null for blanks and text', () {
      expect(Money.tryParseInput(''), isNull);
      expect(Money.tryParseInput('abc'), isNull);
      expect(Money.tryParseInput('12,3,4'), isNull);
    });
  });

  group('arithmetic', () {
    test('adds, subtracts, compares and sums', () {
      const Money a = Money(1050);
      const Money b = Money(250);
      expect(a + b, const Money(1300));
      expect(a - b, const Money(800));
      expect(-a, const Money(-1050));
      expect(a > b, isTrue);
      expect(b < a, isTrue);
      expect(a >= const Money(1050), isTrue);
      expect(b <= a, isTrue);
      expect(a.min(b), b);
      expect(Money.sum(const <Money>[a, b, b]), const Money(1550));
      expect(Money.sum(const <Money>[]), Money.zero);
      expect((-a).abs, a);
      expect(Money.zero.isZero, isTrue);
      expect(const Money(-1).isNegative, isTrue);
      expect(const Money(1).isPositive, isTrue);
    });

    test('ratio is for display and guards the division', () {
      expect(const Money(250).ratio(const Money(1000)), 0.25);
      expect(const Money(250).ratio(Money.zero), 0);
      expect(const Money(250).ratio(const Money(-5)), 0);
    });

    test('sorts and is a value type', () {
      final List<Money> list = <Money>[
        const Money(3),
        const Money(1),
        const Money(2),
      ]..sort();
      expect(list, const <Money>[Money(1), Money(2), Money(3)]);
      expect(const Money(5) == const Money(5), isTrue);
      expect(<Money>{const Money(5), const Money(5)}.length, 1);
    });
  });

  group('wire and display', () {
    test('toWire always has two decimals and round-trips', () {
      expect(const Money(5).toWire(), '0.05');
      expect(const Money(100).toWire(), '1.00');
      expect(const Money(-1230).toWire(), '-12.30');
      expect(Money.zero.toWire(), '0.00');
      for (final String s in <String>['0.01', '10.00', '-99.99', '1234.56']) {
        expect(Money.parse(s).toWire(), s);
      }
    });

    test('formats per locale with grouping and currency', () {
      const Money m = Money(123456789);
      expect(m.format('en'), '1,234,567.89');
      expect(m.format('it-IT'), '1.234.567,89');
      expect(m.format('de-CH'), '1’234’567.89');
      expect(m.format('fr-CH'), '1’234’567.89');
      expect(m.format('it-CH'), '1’234’567.89');
      expect(m.format('en', currency: 'CHF'), 'CHF 1,234,567.89');
      expect(const Money(-5).format('en'), '-0.05');
      expect(const Money(99900).format('en'), '999.00');
      expect(const Money(100000).format('en'), '1,000.00');
      expect(const Money(100).format('en', currency: ''), '1.00');
    });
  });
}
