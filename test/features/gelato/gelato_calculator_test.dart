import 'package:fattura_facile/features/gelato/domain/gelato_calculator.dart';
import 'package:fattura_facile/features/gelato/presentation/gelato_strings.dart';
import 'package:flutter_test/flutter_test.dart';

GelatoIngredient ingredient(
  String id, {
  double pod = 0,
  double pac = 0,
  double milkFat = 0,
  double slng = 0,
  double solids = 0,
  double water = 100,
  double cost = 0,
}) => GelatoIngredient(
  id: id,
  code: id,
  names: <String, String>{'en': id},
  pod: pod,
  pac: pac,
  milkFat: milkFat,
  otherFat: 0,
  slng: slng,
  totalSolids: solids,
  waterPercent: water,
  costPerKg: cost,
);

List<GelatoLine> creamLines() => <GelatoLine>[
  GelatoLine(
    ingredient('sucrose', pod: 100, pac: 100, solids: 100, water: 0, cost: 1.1),
    160,
  ),
  GelatoLine(
    ingredient(
      'milk',
      pod: 0.8,
      milkFat: 3.6,
      slng: 8.6,
      solids: 12.2,
      water: 87.8,
      cost: 1.3,
    ),
    600,
  ),
  GelatoLine(
    ingredient(
      'cream',
      pod: 0.5,
      milkFat: 35,
      slng: 5.6,
      solids: 40.6,
      water: 59.4,
      cost: 4.2,
    ),
    100,
  ),
  GelatoLine(ingredient('water'), 140),
];

void main() {
  const GelatoCalculator calculator = GelatoCalculator();

  test(
    'computes POD, PAC, SLNG, solids and the lactose ceiling per 1000 g',
    () {
      final GelatoMetrics m = calculator.analyze(creamLines());

      expect(m.pod, closeTo(165.3, 0.001));
      expect(m.pac, closeTo(190.888, 0.001));
      expect(m.slng, closeTo(5.72, 0.001));
      expect(m.milkFat, closeTo(5.66, 0.001));
      expect(m.totalSolids, closeTo(27.38, 0.001));
      expect(m.slngMax, closeTo(10.525, 0.001));
      expect(m.lactoseRisk, isFalse);
    },
  );

  test('does not depend on the batch weight', () {
    final List<GelatoLine> doubled = <GelatoLine>[
      for (final GelatoLine l in creamLines())
        GelatoLine(l.ingredient, l.grams * 3.5),
    ];

    expect(
      calculator.analyze(doubled).pac,
      closeTo(calculator.analyze(creamLines()).pac, 1e-9),
    );
  });

  test('flags the lactose crystallization risk', () {
    final GelatoMetrics m = calculator.analyze(<GelatoLine>[
      GelatoLine(ingredient('smp', slng: 95, solids: 96, water: 4), 300),
      GelatoLine(ingredient('water'), 700),
    ]);

    expect(m.lactoseRisk, isTrue);
  });

  test('costs the batch, the litre of gelato and the portion', () {
    final GelatoMetrics m = calculator.analyze(
      creamLines(),
      overrunPercent: 30,
      portionGrams: 100,
    );

    expect(m.costPerKg, closeTo(1.376, 1e-9));
    expect(m.batchCost, closeTo(1.376, 1e-9));
    expect(m.costPerPortion, closeTo(0.1376, 1e-9));
    expect(m.costPerLitreGelato, lessThan(m.batchCost / (1 / 1.09)));
  });

  test('overrun from the measured volumes', () {
    expect(calculator.overrun(1.5, 1.0), closeTo(50, 1e-9));
    expect(() => calculator.overrun(1, 0), throwsArgumentError);
  });

  test('rejects an empty recipe and scales the weighing targets', () {
    expect(() => calculator.analyze(<GelatoLine>[]), throwsArgumentError);
    expect(
      calculator.scale(<GelatoLine>[
        GelatoLine(ingredient('a'), 600),
        GelatoLine(ingredient('b'), 400),
      ], 3500),
      <double>[2100, 1400],
    );
  });

  test('parses an ingredient of the API and falls back to English labels', () {
    final GelatoIngredient i = GelatoIngredient.fromJson(<String, dynamic>{
      'id': 'i-1',
      'code': 'MILK',
      'name': <String, dynamic>{'en': 'Milk', 'de': 'Milch'},
      'pod': 0.8,
      'total_solids_percent': 12.2,
    });

    expect(i.label('de'), 'Milch');
    expect(i.label('fr'), 'Milk');
    expect(i.waterPercent, closeTo(87.8, 1e-9));
  });

  test('every locale table defines every label', () {
    for (final String locale in <String>['it', 'en', 'de', 'fr']) {
      for (final GL key in GL.values) {
        expect(
          gelatoStrings[locale]![key],
          isNotNull,
          reason: '$locale is missing ${key.name}',
        );
        expect(gelatoStrings[locale]![key], isNotEmpty);
      }
    }
    expect(gelatoLabel('xx', GL.title), 'Gelato');
  });
}
