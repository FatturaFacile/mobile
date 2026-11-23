import 'package:fattura_facile/app/providers.dart';
import 'package:fattura_facile/core/network/api_client.dart';
import 'package:fattura_facile/design/ff_tokens.dart';
import 'package:fattura_facile/features/swiss_vat/domain/swiss_vat_models.dart';
import 'package:fattura_facile/features/swiss_vat/presentation/swiss_vat_controller.dart';
import 'package:fattura_facile/features/swiss_vat/presentation/swiss_vat_pages.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'fakes.dart';
import 'fixtures.dart';

void main() {
  late FakeSwissVatRepository repo;
  late FakeSwissVatExporter exporter;

  setUp(() {
    repo = FakeSwissVatRepository();
    exporter = FakeSwissVatExporter();
    final SwissVatReturn r = SwissVatReturn.fromJson(returnJson());
    repo.remoteReturns = <SwissVatReturn>[r];
    repo.detailedReturns[r.id] = r;
    repo.remoteBez = <BezugsteuerEntry>[
      BezugsteuerEntry.fromJson(bezugsteuerJson()),
    ];
    repo.remoteAdj = <InputTaxAdjustment>[
      InputTaxAdjustment.fromJson(adjustmentJson()),
    ];
  });

  Widget host({String language = 'en'}) => ProviderScope(
    key: UniqueKey(),
    overrides: [
      swissVatRepositoryProvider.overrideWithValue(repo),
      swissVatTenantIdProvider.overrideWithValue('t1'),
      swissVatNowProvider.overrideWithValue(DateTime(2026, 3, 15)),
      swissVatExporterProvider.overrideWithValue(exporter),
      requestContextProvider.overrideWithValue(
        RequestContext()..languageCode = language,
      ),
    ],
    child: MaterialApp(theme: ffThemeData(), home: const SwissVatHomePage()),
  );

  Future<void> open(WidgetTester tester, {String language = 'en'}) async {
    tester.view.physicalSize = const Size(800, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(host(language: language));
    await tester.pumpAndSettle();
  }

  testWidgets('renders AFC boxes, quadratura badge, and exports SuisseTax XML', (
    WidgetTester tester,
  ) async {
    await open(tester, language: 'en');

    expect(find.text('Swiss VAT (MWST / IVA / TVA)'), findsOneWidget);
    expect(find.byKey(const Key('chvat-box-200')), findsOneWidget);
    expect(find.byKey(const Key('chvat-quad-badge')), findsOneWidget);
    expect(find.text('PASS'), findsOneWidget);

    await tester.tap(find.byKey(const Key('chvat-export-xml')));
    await tester.pumpAndSettle();

    expect(exporter.shared.single.fileName, 'suissetax-2026-Q1.xml');
    expect(exporter.shared.single.mimeType, 'application/xml');
  });

  testWidgets('displays Bezugsteuer entries and supports confirming one', (
    WidgetTester tester,
  ) async {
    await open(tester, language: 'de-CH');

    await tester.tap(find.byKey(const Key('chvat-tab-bezugsteuer')));
    await tester.pumpAndSettle();

    expect(find.text('CloudTech GmbH (DE)'), findsOneWidget);
    await tester.tap(find.byKey(const Key('chvat-bez-confirm-bez-1')));
    await tester.pumpAndSettle();

    expect(repo.confirmedBez, <String>['bez-1']);
  });
}
