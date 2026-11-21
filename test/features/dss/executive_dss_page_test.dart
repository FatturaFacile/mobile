import 'package:fattura_facile/design/ff_tokens.dart';
import 'package:fattura_facile/features/dss/domain/dss_models.dart';
import 'package:fattura_facile/features/dss/domain/dss_repository.dart';
import 'package:fattura_facile/features/dss/presentation/dss_controller.dart';
import 'package:fattura_facile/features/dss/presentation/executive_dss_page.dart';
import 'package:fattura_facile/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'dss_fixtures.dart';

class FakeDssRepository implements DssRepository {
  FakeDssRepository({
    this.syncStatus = DssSyncStatus.synced,
    this.cache = true,
  });

  DssSyncStatus syncStatus;
  bool cache;
  final List<DssFilter> synced = <DssFilter>[];
  final Set<DssFilter> pulled = <DssFilter>{};

  @override
  Future<DssSnapshot?> cached(String tenantId, DssFilter filter) async {
    if (!cache && !pulled.contains(filter)) {
      return null;
    }
    return snapshotFor(
      filter,
      entities: const <DssLegalEntity>[
        DssLegalEntity(id: 'le-1', name: 'Acme SA', currency: 'CHF'),
      ],
    );
  }

  @override
  Future<DssSyncResult> sync(String tenantId, DssFilter filter) async {
    synced.add(filter);
    if (syncStatus == DssSyncStatus.synced) {
      pulled.add(filter);
    }
    return DssSyncResult(syncStatus, syncedAt: DateTime.utc(2026, 1, 30, 10));
  }
}

Future<void> pumpPage(WidgetTester tester, FakeDssRepository repo) async {
  tester.view.physicalSize = const Size(900, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [dssRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        theme: ffThemeData(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const ExecutiveDssPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders the pulse cards, alerts and the profitability lists', (
    WidgetTester tester,
  ) async {
    await pumpPage(tester, FakeDssRepository());

    for (final String key in <String>[
      'revenue',
      'gross_margin_pct',
      'ebitda',
      'net_cash_flow',
      'ccc_days',
      'dso_days',
    ]) {
      expect(find.byKey(Key('dss-kpi-$key')), findsOneWidget, reason: key);
    }
    expect(find.text('CHF 1.0K'), findsOneWidget);
    expect(find.text('+12.5%'), findsOneWidget);
    expect(find.text('40.0%'), findsOneWidget);
    expect(find.text('Gross margin erosion'), findsOneWidget);
    expect(
      find.text('Acme AG is 38.0% of revenue (limit 25.0%).'),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('dss-top-customer-customer-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('dss-bottom-customer-customer-7')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('dss-top-product-product-1')), findsOneWidget);
    expect(find.byKey(const Key('dss-variance')), findsOneWidget);
    expect(find.text('Eroding value'), findsWidgets);
  });

  testWidgets('shows the empty state when nothing was ever synced', (
    WidgetTester tester,
  ) async {
    await pumpPage(
      tester,
      FakeDssRepository(syncStatus: DssSyncStatus.offline, cache: false),
    );
    expect(find.byKey(const Key('dss-empty')), findsOneWidget);
    expect(find.byKey(const Key('dss-whatif-open')), findsNothing);
  });

  testWidgets('offline shows the cached figures and the offline pill', (
    WidgetTester tester,
  ) async {
    await pumpPage(
      tester,
      FakeDssRepository(syncStatus: DssSyncStatus.offline),
    );
    expect(find.byKey(const Key('dss-kpi-revenue')), findsOneWidget);
    expect(find.textContaining('Offline · synced'), findsOneWidget);
  });

  testWidgets('a forbidden answer is announced', (WidgetTester tester) async {
    await pumpPage(
      tester,
      FakeDssRepository(syncStatus: DssSyncStatus.forbidden),
    );
    expect(find.byKey(const Key('dss-notice')), findsOneWidget);
    expect(
      find.text('You do not have access to the Executive DSS.'),
      findsOneWidget,
    );
  });

  testWidgets('switching currency and period reloads for the new filter', (
    WidgetTester tester,
  ) async {
    final FakeDssRepository repo = FakeDssRepository();
    await pumpPage(tester, repo);
    expect(repo.synced.single, const DssFilter());

    await tester.tap(find.byKey(const Key('dss-currency-EUR')));
    await tester.pumpAndSettle();
    expect(repo.synced.last, const DssFilter(currency: 'EUR'));
    expect(find.text('EUR 1.0K'), findsOneWidget);

    await tester.tap(find.byKey(const Key('dss-period-QTD')));
    await tester.pumpAndSettle();
    expect(
      repo.synced.last,
      const DssFilter(currency: 'EUR', periodPreset: 'QTD'),
    );
  });

  testWidgets('pull to refresh syncs again', (WidgetTester tester) async {
    final FakeDssRepository repo = FakeDssRepository();
    await pumpPage(tester, repo);
    await tester.drag(find.byType(ListView), const Offset(0, 1800));
    await tester.pumpAndSettle();
    expect(repo.synced.length, 2);
  });

  testWidgets('tapping an alert opens root cause and recommended action', (
    WidgetTester tester,
  ) async {
    await pumpPage(tester, FakeDssRepository());
    await tester.tap(
      find.byKey(const Key('dss-alert-margin_erosion-gross_margin_pct')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dss-alert-sheet')), findsOneWidget);
    expect(find.text('Root cause'), findsOneWidget);
    expect(find.text('Recommended action'), findsOneWidget);
    expect(
      find.textContaining('Cost of goods is growing faster'),
      findsOneWidget,
    );
    expect(find.text('Critical'), findsWidgets);
  });

  testWidgets('the what-if sliders preview EBITDA on the device', (
    WidgetTester tester,
  ) async {
    await pumpPage(tester, FakeDssRepository());
    await tester.tap(find.byKey(const Key('dss-whatif-open')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dss-whatif-sheet')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('dss-whatif-ebitda'))).data,
      'CHF 100',
    );

    // Moving the price slider to its right end (+20%) adds 20% of the revenue to EBITDA.
    await tester.drag(
      find.byKey(const Key('dss-slider-price')),
      const Offset(2000, 0),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(const Key('dss-whatif-ebitda'))).data,
      'CHF 300',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('dss-whatif-change'))).data,
      '+CHF 200',
    );

    await tester.tap(find.byKey(const Key('dss-whatif-reset')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(const Key('dss-whatif-ebitda'))).data,
      'CHF 100',
    );
  });
}
