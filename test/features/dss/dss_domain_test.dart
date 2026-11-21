import 'package:fattura_facile/features/dss/domain/dss_models.dart';
import 'package:fattura_facile/features/dss/domain/dss_parser.dart';
import 'package:fattura_facile/features/dss/domain/what_if_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dss_fixtures.dart';

void main() {
  const WhatIfBaseline baseline = WhatIfBaseline(
    revenue: 1000,
    cogs: 600,
    opex: 300,
    dsoDays: 30,
    netCashFlow: 100,
    periodDays: 30,
  );

  group('what-if calculator (same cases as the web-api simulator)', () {
    test('a neutral scenario changes nothing', () {
      final WhatIfResult r = simulateWhatIf(baseline, const WhatIfScenario());
      expect(r.baseline.ebitda, 100);
      expect(r.simulated.ebitda, 100);
      expect(r.delta.ebitda, 0);
      expect(r.delta.netCashFlow, 0);
    });

    test(
      '+10% price raises EBITDA by the extra revenue and ties up receivables',
      () {
        final WhatIfResult r = simulateWhatIf(
          baseline,
          const WhatIfScenario(pricePct: 10),
        );
        expect(r.simulated.revenue, 1100);
        expect(r.simulated.ebitda, 200);
        expect(r.delta.ebitda, 100);
        // +100 EBITDA, -100 of new receivables.
        expect(r.simulated.netCashFlow, 100);
        expect(r.simulated.breakEvenRevenue, closeTo(660, 1e-9));
        expect(r.simulated.ebitdaMarginPct, closeTo(18.18, 1e-9));
      },
    );

    test('+5% COGS lowers EBITDA by 30', () {
      final WhatIfResult r = simulateWhatIf(
        baseline,
        const WhatIfScenario(cogsPct: 5),
      );
      expect(r.simulated.cogs, 630);
      expect(r.delta.ebitda, -30);
    });

    test('FX shift scales the exposed share of revenue and costs', () {
      const WhatIfBaseline exposed = WhatIfBaseline(
        revenue: 1000,
        cogs: 600,
        opex: 300,
        dsoDays: 0,
        netCashFlow: 0,
        periodDays: 30,
        revenueFxShare: 0.5,
        costFxShare: 0.2,
      );
      final WhatIfResult r = simulateWhatIf(
        exposed,
        const WhatIfScenario(fxShiftPct: 10),
      );
      expect(r.simulated.revenue, closeTo(1050, 1e-9));
      expect(r.simulated.cogs, closeTo(612, 1e-9));
      expect(r.simulated.opex, closeTo(306, 1e-9));
    });

    test('a negative contribution margin has no break-even', () {
      final WhatIfResult r = simulateWhatIf(
        baseline,
        const WhatIfScenario(pricePct: -20, cogsPct: 50),
      );
      expect(r.simulated.breakEvenRevenue, isNull);
    });
  });

  group('parser', () {
    test('reads the scorecard, alerts and working capital', () {
      final DssOverview o = DssParser.overview(overviewJson());
      expect(o.currency, 'CHF');
      expect(o.kpi('revenue')!.value, 1000);
      expect(o.kpi('revenue')!.favorable, isTrue);
      expect(o.kpi('gross_margin_pct')!.favorable, isFalse);
      expect(o.kpi('revenue')!.sparkline, <double>[1, 2, 3]);
      expect(o.alerts.map((DssAlert a) => a.code), <String>[
        'margin_erosion',
        'customer_concentration',
      ]);
      expect(o.alerts.last.label, 'Acme AG');
      expect(o.dsoDays, 30);
    });

    test('tolerates missing sections', () {
      final DssOverview o = DssParser.overview(<String, dynamic>{});
      expect(o.kpis, isEmpty);
      expect(o.alerts, isEmpty);
      expect(o.currency, 'CHF');
    });

    test('top and bottom lists are the two ends of the ranking', () {
      final DssProfitability p = DssParser.profitability(
        profitabilityJson('customer', count: 12),
      );
      final List<String> top = p.top(5).map((DssProfitRow r) => r.key).toList();
      final List<String> bottom = p
          .bottom(5)
          .map((DssProfitRow r) => r.key)
          .toList();
      expect(top.first, 'customer-1');
      expect(bottom.first, 'customer-12');
      expect(top.toSet().intersection(bottom.toSet()), isEmpty);
      expect(p.erodingCount, 1);
    });

    test('variance summary maps the bridge steps', () {
      final DssVarianceSummary v = DssParser.variance(varianceJson())!;
      expect(v.baseline, 80);
      expect(v.cogs, -15);
      expect(v.actual, 100);
      expect(DssParser.variance(<String, dynamic>{}), isNull);
    });

    test(
      'baseline uses the server inputs, else derives it from the scorecard',
      () {
        final DssOverview o = DssParser.overview(overviewJson());
        expect(DssParser.baseline(o, simulationJson()).cogs, 600);
        final WhatIfBaseline derived = DssParser.baseline(o, null);
        expect(derived.revenue, 1000);
        expect(derived.cogs, closeTo(600, 1e-9));
        expect(derived.opex, closeTo(300, 1e-9));
        expect(derived.periodDays, 30);
      },
    );
  });
}
