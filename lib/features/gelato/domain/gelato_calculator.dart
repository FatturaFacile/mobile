import 'dart:math' as math;

/// Technical ingredient as the API returns it (values per 100 g).
class GelatoIngredient {
  const GelatoIngredient({
    required this.id,
    required this.code,
    required this.names,
    required this.pod,
    required this.pac,
    required this.milkFat,
    required this.otherFat,
    required this.slng,
    required this.totalSolids,
    required this.waterPercent,
    required this.costPerKg,
  });

  factory GelatoIngredient.fromJson(Map<String, dynamic> json) {
    double n(String key) => (json[key] as num?)?.toDouble() ?? 0;
    final Map<String, dynamic> names =
        (json['name'] as Map<dynamic, dynamic>?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    return GelatoIngredient(
      id: json['id'] as String,
      code: json['code'] as String? ?? '',
      names: names.map(
        (String k, dynamic v) => MapEntry<String, String>(k, '$v'),
      ),
      pod: n('pod'),
      pac: n('pac'),
      milkFat: n('milk_fat_percent'),
      otherFat: n('other_fat_percent'),
      slng: n('slng_percent'),
      totalSolids: n('total_solids_percent'),
      waterPercent: json['water_percent'] == null
          ? 100 - n('total_solids_percent')
          : n('water_percent'),
      costPerKg: n('cost_per_kg'),
    );
  }

  final String id;
  final String code;
  final Map<String, String> names;
  final double pod;
  final double pac;
  final double milkFat;
  final double otherFat;
  final double slng;
  final double totalSolids;
  final double waterPercent;
  final double costPerKg;

  String label(String locale) => names[locale] ?? names['en'] ?? code;
}

/// Grams of an ingredient in the recipe on screen.
class GelatoLine {
  const GelatoLine(this.ingredient, this.grams);
  final GelatoIngredient ingredient;
  final double grams;
}

/// Indexes of a mix per 1,000 g, the same formulas as the API engine:
/// POD = 10 * sum(x_i POD_i), PAC = 10 * sum(x_i PAC_i) + SLNG% * 10 * 0.54, SLNG max = (100 - TS%) / 6.9.
class GelatoMetrics {
  const GelatoMetrics({
    required this.totalGrams,
    required this.pod,
    required this.pac,
    required this.milkFat,
    required this.otherFat,
    required this.slng,
    required this.slngMax,
    required this.totalSolids,
    required this.costPerKg,
    required this.batchCost,
    required this.costPerLitreGelato,
    required this.costPerPortion,
  });

  final double totalGrams;
  final double pod;
  final double pac;
  final double milkFat;
  final double otherFat;
  final double slng;
  final double slngMax;
  final double totalSolids;
  final double costPerKg;
  final double batchCost;
  final double costPerLitreGelato;
  final double costPerPortion;

  double get totalFat => milkFat + otherFat;

  /// Lactose sandiness guardrail: SLNG above the ceiling.
  bool get lactoseRisk => slng > slngMax;
}

class GelatoCalculator {
  const GelatoCalculator();

  static const double milkSaltsFactor = 0.54;
  static const double lactoseDivisor = 6.9;
  static const double defaultDensity = 1.09;

  GelatoMetrics analyze(
    List<GelatoLine> lines, {
    double overrunPercent = 0,
    double portionGrams = 80,
    double density = defaultDensity,
  }) {
    final double total = lines.fold(0, (double s, GelatoLine l) => s + l.grams);
    if (total <= 0) {
      throw ArgumentError(
        'A recipe needs at least one ingredient with a positive weight.',
      );
    }
    double weighted(double Function(GelatoIngredient) v) =>
        lines.fold(
          0.0,
          (double s, GelatoLine l) => s + l.grams * v(l.ingredient),
        ) /
        total;

    final double slng = weighted((GelatoIngredient i) => i.slng);
    final double solids = math.min(
      100,
      weighted((GelatoIngredient i) => i.totalSolids),
    );
    final double costPerKg = weighted((GelatoIngredient i) => i.costPerKg);
    final double batchCost = costPerKg * total / 1000;
    final double mixLitres = total / 1000 / density;
    final double gelatoLitres = mixLitres * (1 + overrunPercent / 100);

    return GelatoMetrics(
      totalGrams: total,
      pod: weighted((GelatoIngredient i) => i.pod) * 10,
      pac:
          weighted((GelatoIngredient i) => i.pac) * 10 +
          slng * 10 * milkSaltsFactor,
      milkFat: weighted((GelatoIngredient i) => i.milkFat),
      otherFat: weighted((GelatoIngredient i) => i.otherFat),
      slng: slng,
      slngMax: math.max(0, (100 - solids) / lactoseDivisor),
      totalSolids: solids,
      costPerKg: costPerKg,
      batchCost: batchCost,
      costPerLitreGelato: batchCost / gelatoLitres,
      costPerPortion: costPerKg * portionGrams / 1000,
    );
  }

  /// Overrun % from the measured volumes in litres.
  double overrun(double gelatoLitres, double mixLitres) {
    if (mixLitres <= 0) {
      throw ArgumentError('The liquid mix volume must be positive.');
    }
    return (gelatoLitres - mixLitres) / mixLitres * 100;
  }

  /// The grams of every line for another batch weight (guided weighing at a different size).
  List<double> scale(List<GelatoLine> lines, double batchWeight) {
    final double total = lines.fold(0, (double s, GelatoLine l) => s + l.grams);
    if (total <= 0 || batchWeight <= 0) {
      return <double>[for (final GelatoLine l in lines) l.grams];
    }
    return <double>[
      for (final GelatoLine l in lines)
        (l.grams * batchWeight / total * 100).roundToDouble() / 100,
    ];
  }
}
