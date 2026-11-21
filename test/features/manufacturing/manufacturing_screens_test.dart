import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:fattura_facile/design/ff_tokens.dart';
import 'package:fattura_facile/features/manufacturing/data/repositories/manufacturing_repository.dart';
import 'package:fattura_facile/features/manufacturing/domain/entities/manufacturing_models.dart';
import 'package:fattura_facile/features/manufacturing/presentation/providers/manufacturing_providers.dart';
import 'package:fattura_facile/features/manufacturing/presentation/screens/manufacturing_hub_screen.dart';
import 'package:fattura_facile/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _FakeRepo implements ManufacturingRepository {
  _FakeRepo({this.seeded = false});

  final bool seeded;

  @override
  Stream<List<MfgWorkCenter>> watchWorkCenters(String tenantId) =>
      Stream<List<MfgWorkCenter>>.value(
        seeded
            ? const <MfgWorkCenter>[
                MfgWorkCenter(
                  id: 'wc-1',
                  code: 'WC-1',
                  name: 'Milling',
                  hourlySetupCostRate: 60,
                  hourlyMachineRunCostRate: 120,
                  hourlyCostRate: 30,
                  hourlyOverheadRate: 12,
                ),
              ]
            : const <MfgWorkCenter>[],
      );

  @override
  Stream<List<MfgMachine>> watchMachines(
    String tenantId, {
    String? workCenterId,
  }) => Stream<List<MfgMachine>>.value(
    seeded
        ? const <MfgMachine>[
            MfgMachine(
              id: 'm-1',
              code: 'M1',
              name: 'Mill 1',
              workCenterId: 'wc-1',
              industria40: true,
              telemetryStatus: 'online',
            ),
          ]
        : const <MfgMachine>[],
  );

  @override
  Stream<List<MfgRouting>> watchRoutings(String tenantId) =>
      Stream<List<MfgRouting>>.value(
        seeded
            ? const <MfgRouting>[
                MfgRouting(
                  id: 'r-1',
                  routingNumber: 'RT-1',
                  name: 'Shaft',
                  revision: 'A',
                  status: 'active',
                  steps: <MfgRoutingStep>[
                    MfgRoutingStep(
                      id: 'o1',
                      sequence: 10,
                      operationCode: 'OP10',
                      name: 'Mill',
                      workCenterId: 'wc-1',
                      setupTimeMinutes: 30,
                      runTimeMinutesPerUnit: 2,
                      queueTimeMinutes: 5,
                    ),
                  ],
                ),
              ]
            : const <MfgRouting>[],
      );

  @override
  Stream<List<MfgOeeSummary>> watchOeeSummaries(String tenantId) =>
      Stream<List<MfgOeeSummary>>.value(
        seeded
            ? <MfgOeeSummary>[
                MfgOeeSummary(
                  workCenterId: 'wc-1',
                  from: DateTime.utc(2026, 10, 22),
                  to: DateTime.utc(2026, 11, 21),
                  metrics: const MfgOeeMetrics(
                    availabilityPercent: 86.67,
                    performancePercent: 82.05,
                    qualityPercent: 93.75,
                    oeePercent: 66.67,
                  ),
                  targetOeePercent: 85,
                  meetsTarget: false,
                  gapToTargetPercent: -18.33,
                  losses: const <String, double>{'equipment_failure': 60},
                ),
              ]
            : const <MfgOeeSummary>[],
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _app(_FakeRepo repo, {Locale locale = const Locale('en')}) {
  return ProviderScope(
    overrides: <Override>[
      manufacturingRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp(
      theme: ffThemeData(),
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const ManufacturingHubScreen(tenantId: 't1', autoSync: false),
    ),
  );
}

void main() {
  testWidgets('shows localized empty states offline when nothing is cached', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_app(_FakeRepo()));
    await tester.pumpAndSettle();
    expect(find.text('No routings available offline'), findsOneWidget);
    await tester.tap(find.byKey(const Key('mfg-tab-machines')));
    await tester.pumpAndSettle();
    expect(find.text('No machines available offline'), findsOneWidget);
    await tester.tap(find.byKey(const Key('mfg-tab-oee')));
    await tester.pumpAndSettle();
    expect(find.text('No OEE data available offline'), findsOneWidget);
  });

  testWidgets('inspects routing steps, machines and OEE and calculates a lot', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(_FakeRepo(seeded: true)));
    await tester.pumpAndSettle();

    expect(find.text('RT-1 · Shaft'), findsOneWidget);
    await tester.tap(find.byKey(const Key('mfg-routing-r-1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('mfg-step-o1')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('mfg-qty')), '10');
    await tester.tap(find.byKey(const Key('mfg-calculate')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(const Key('mfg-total-minutes'))).data,
      '55 min',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('mfg-total-cost'))).data,
      '90',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('mfg-unit-cost'))).data,
      '9',
    );

    await tester.enterText(find.byKey(const Key('mfg-qty')), '0');
    await tester.tap(find.byKey(const Key('mfg-calculate')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('mfg-calc-error')), findsOneWidget);
    expect(find.byKey(const Key('mfg-total-minutes')), findsNothing);

    Navigator.of(tester.element(find.byKey(const Key('mfg-qty')))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('mfg-tab-machines')));
    await tester.pumpAndSettle();
    expect(find.text('M1 · Mill 1'), findsOneWidget);
    expect(find.text('Telemetry online'), findsOneWidget);

    await tester.tap(find.byKey(const Key('mfg-tab-oee')));
    await tester.pumpAndSettle();
    expect(find.text('OEE 66.67%'), findsOneWidget);
    expect(find.text('Below target by 18.33 pts'), findsOneWidget);
    expect(find.textContaining('Equipment failure'), findsOneWidget);
  });

  testWidgets('renders Italian strings', (WidgetTester tester) async {
    await tester.pumpWidget(
      _app(_FakeRepo(seeded: true), locale: const Locale('it')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Cicli'), findsOneWidget);
    expect(find.text('Macchine'), findsOneWidget);
  });

  test('all 4 locales provide Mod 061 strings with placeholders', () async {
    for (final String code in <String>['en', 'it', 'de', 'fr']) {
      final AppLocalizations l10n = await AppLocalizations.delegate.load(
        Locale(code),
      );
      expect(l10n.mfgHubTitle.trim(), isNotEmpty, reason: code);
      expect(l10n.mfgTabRoutings.trim(), isNotEmpty, reason: code);
      expect(l10n.mfgTabOee.trim(), isNotEmpty, reason: code);
      expect(l10n.mfgRevisionLabel('B'), contains('B'), reason: code);
      expect(l10n.mfgStepsCount(3), contains('3'), reason: code);
      expect(l10n.mfgOeeValue('66'), contains('66'), reason: code);
      expect(l10n.mfgLossStartupRejects.trim(), isNotEmpty, reason: code);
    }
  });
}
