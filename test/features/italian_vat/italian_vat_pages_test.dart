import 'package:fattura_facile/app/providers.dart';
import 'package:fattura_facile/core/network/api_client.dart';
import 'package:fattura_facile/design/ff_tokens.dart';
import 'package:fattura_facile/features/italian_vat/domain/italian_vat_models.dart';
import 'package:fattura_facile/features/italian_vat/presentation/italian_vat_controller.dart';
import 'package:fattura_facile/features/italian_vat/presentation/italian_vat_pages.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'fakes.dart';
import 'fixtures.dart';

void main() {
  late FakeItalianVatRepository repo;
  late FakeExporter exporter;

  final DateTime q2From = DateTime(2027, 4);
  final DateTime q2To = DateTime(2027, 6, 30);

  VatRegister reg(
    VatRegisterType type,
    List<Map<String, dynamic>> lines, {
    Map<String, dynamic>? meta,
  }) => VatRegister.fromJson(
    registerBody(lines, meta: meta),
    type: type,
    from: q2From,
    to: q2To,
  );

  void serve(VatRegister r) =>
      repo.remoteRegisters[FakeItalianVatRepository.key(r.type, q2From, q2To)] =
          r;

  setUp(() {
    repo = FakeItalianVatRepository();
    exporter = FakeExporter();
    serve(reg(VatRegisterType.sales, <Map<String, dynamic>>[lineJson()]));
  });

  Widget host({String language = 'en'}) => ProviderScope(
    key: UniqueKey(),
    overrides: [
      italianVatRepositoryProvider.overrideWithValue(repo),
      italianVatTenantIdProvider.overrideWithValue('t1'),
      italianVatNowProvider.overrideWithValue(DateTime(2027, 5, 10)),
      italianVatExporterProvider.overrideWithValue(exporter),
      requestContextProvider.overrideWithValue(
        RequestContext()..languageCode = language,
      ),
    ],
    child: MaterialApp(theme: ffThemeData(), home: const ItalianVatHomePage()),
  );

  /// Pumps the workspace on a tall surface, so the lazily built lists are built whole.
  Future<void> open(WidgetTester tester, {String language = 'en'}) async {
    tester.view.physicalSize = const Size(800, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(host(language: language));
    await tester.pumpAndSettle();
  }

  Future<void> tapTab(WidgetTester tester, String key) async {
    await tester.tap(find.byKey(Key(key)));
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String key) async {
    final Finder f = find.byKey(Key(key));
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  /// Text of the widget with [key], or of the label inside it (the chips carry the key on their container).
  String textOf(WidgetTester tester, String key) {
    final Finder f = find.byKey(Key(key));
    final Finder inner = find.descendant(of: f, matching: find.byType(Text));
    return tester.widgetList(inner).isNotEmpty
        ? tester.widget<Text>(inner.first).data!
        : tester.widget<Text>(f).data!;
  }

  group('registers', () {
    testWidgets(
      'lists the lines of the register with its totals and a provisional print state',
      (WidgetTester tester) async {
        await open(tester);

        expect(find.text('VAT registers and filings'), findsOneWidget);
        expect(find.byKey(const Key('ivat-line-1')), findsOneWidget);
        expect(find.textContaining('FA-1 · Alpina SA'), findsOneWidget);
        expect(textOf(tester, 'ivat-total-taxable'), 'EUR 1,000.00');
        expect(textOf(tester, 'ivat-total-vat'), 'EUR 220.00');
        expect(find.text('Provisional print'), findsOneWidget);
      },
    );

    testWidgets(
      'shows the definitive lock, the last protocol and the stamp duty pages',
      (WidgetTester tester) async {
        serve(
          reg(
            VatRegisterType.sales,
            <Map<String, dynamic>>[lineJson(protocol: 9)],
            meta: <String, dynamic>{
              'lock': <String, dynamic>{
                'locked_at': '2027-07-10T08:00:00Z',
                'stamp_duty_pages': 3,
              },
            },
          ),
        );
        await open(tester);

        expect(find.text('Definitive print'), findsOneWidget);
        expect(find.text('Last protocol'), findsOneWidget);
        expect(find.text('Pages with virtual stamp duty'), findsOneWidget);
      },
    );

    testWidgets('warns about the entries still without a protocol number', (
      WidgetTester tester,
    ) async {
      serve(
        reg(VatRegisterType.sales, <Map<String, dynamic>>[
          lineJson(),
          lineJson(protocol: null, number: 'FA-2'),
        ]),
      );
      await open(tester);

      expect(textOf(tester, 'ivat-unnumbered'), '1');
    });

    testWidgets(
      'the purchases register shows the pro-rata with deductible and non-deductible VAT',
      (WidgetTester tester) async {
        serve(
          reg(
            VatRegisterType.purchases,
            <Map<String, dynamic>>[lineJson()],
            meta: <String, dynamic>{'pro_rata_percent': '70.00'},
          ),
        );
        await open(tester);
        await tap(tester, 'ivat-reg-purchases');

        expect(textOf(tester, 'ivat-prorata'), '70.00%');
        expect(textOf(tester, 'ivat-deductible'), 'EUR 154.00');
        expect(textOf(tester, 'ivat-non-deductible'), 'EUR 66.00');
        expect(
          find.textContaining('Non-deductible VAT EUR 66.00'),
          findsOneWidget,
        );
      },
    );

    testWidgets('a purchases register without pro-rata has no pro-rata card', (
      WidgetTester tester,
    ) async {
      serve(reg(VatRegisterType.purchases, <Map<String, dynamic>>[lineJson()]));
      await open(tester);
      await tap(tester, 'ivat-reg-purchases');

      expect(find.byKey(const Key('ivat-prorata')), findsNothing);
    });

    testWidgets(
      'the corrispettivi register shows the ventilated split of the gross receipts',
      (WidgetTester tester) async {
        serve(
          reg(
            VatRegisterType.receipts,
            <Map<String, dynamic>>[lineJson(taxable: '819.67', vat: '180.33')],
            meta: <String, dynamic>{
              'ventilation': <String, dynamic>{
                'enabled': true,
                'purchase_basis': <Map<String, dynamic>>[
                  <String, dynamic>{'vat_rate': '22.00', 'amount': '600.00'},
                  <String, dynamic>{'vat_rate': '10.00', 'amount': '400.00'},
                ],
              },
            },
          ),
        );
        await open(tester);
        await tap(tester, 'ivat-reg-receipts');

        expect(find.text('Ventilation of retail receipts'), findsOneWidget);
        expect(
          find.byKey(Key('ivat-vent-gross-${amt('22.00')}')),
          findsOneWidget,
        );
        expect(find.text('EUR 600.00'), findsWidgets);
        expect(find.text('EUR 400.00'), findsWidgets);
      },
    );

    testWidgets('the goods on commission register can be opened', (
      WidgetTester tester,
    ) async {
      serve(
        reg(VatRegisterType.thirdPartyGoods, <Map<String, dynamic>>[
          lineJson(number: 'DDT-7'),
        ]),
      );
      await open(tester);
      await tap(tester, 'ivat-reg-third-party-goods');

      expect(find.textContaining('DDT-7'), findsOneWidget);
    });

    testWidgets('filters the lines by sectional', (WidgetTester tester) async {
      serve(
        reg(VatRegisterType.sales, <Map<String, dynamic>>[
          lineJson(),
          lineJson(protocol: 2, number: 'FD-1', sectional: 'D'),
        ]),
      );
      await open(tester);
      expect(find.byKey(const Key('ivat-line-1')), findsOneWidget);
      expect(find.byKey(const Key('ivat-line-2')), findsOneWidget);

      await tap(tester, 'ivat-sectional-D');

      expect(find.byKey(const Key('ivat-line-1')), findsNothing);
      expect(find.byKey(const Key('ivat-line-2')), findsOneWidget);
      expect(textOf(tester, 'ivat-total-taxable'), 'EUR 1,000.00');

      await tap(tester, 'ivat-sectional-all');
      expect(find.byKey(const Key('ivat-line-1')), findsOneWidget);
    });

    testWidgets('an empty period says so', (WidgetTester tester) async {
      serve(reg(VatRegisterType.sales, const <Map<String, dynamic>>[]));
      await open(tester);

      expect(find.byKey(const Key('ivat-no-lines')), findsOneWidget);
    });

    testWidgets('changing the period or the year loads that register', (
      WidgetTester tester,
    ) async {
      await open(tester);

      await tap(tester, 'ivat-period-month');
      expect(find.byKey(const Key('ivat-period-index')), findsOneWidget);

      await tap(tester, 'ivat-period-year');
      expect(find.byKey(const Key('ivat-period-index')), findsNothing);

      await tap(tester, 'ivat-year-prev');
      expect(textOf(tester, 'ivat-year'), '2026');
    });

    testWidgets('exports the register as CSV through the share sheet', (
      WidgetTester tester,
    ) async {
      await open(tester);
      await tap(tester, 'ivat-export-csv');

      expect(repo.downloads, <String>['register-sales.csv']);
      expect(exporter.shared.single, startsWith('register-sales.csv|text/csv'));
      expect(find.text('File shared'), findsOneWidget);
    });

    testWidgets('a failed export says so', (WidgetTester tester) async {
      repo.downloadError = const ItalianVatException(
        ItalianVatErrorKind.offline,
      );
      await open(tester);
      await tap(tester, 'ivat-export-csv');

      expect(
        find.text('You are offline: operation not available'),
        findsOneWidget,
      );
    });
  });

  group('plafond and letters of intent', () {
    setUp(() => repo.remoteLetters = <IntentLetter>[letter()]);

    testWidgets('shows the plafond used and left of each letter', (
      WidgetTester tester,
    ) async {
      await open(tester);
      await tapTab(tester, 'ivat-tab-plafond');

      expect(find.text('Export Srl'), findsOneWidget);
      expect(find.text('12345678901234567-000001'), findsOneWidget);
      expect(textOf(tester, 'ivat-remaining-l1'), 'EUR 75,000.00');
      expect(find.byKey(const Key('ivat-plafond-bar-l1')), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('an empty list says so', (WidgetTester tester) async {
      repo.remoteLetters = <IntentLetter>[];
      await open(tester);
      await tapTab(tester, 'ivat-tab-plafond');

      expect(find.byKey(const Key('ivat-no-letters')), findsOneWidget);
    });

    testWidgets(
      'an invoice that fits is allowed, with the plafond left after it',
      (WidgetTester tester) async {
        await open(tester);
        await tapTab(tester, 'ivat-tab-plafond');
        await tap(tester, 'ivat-check-l1');
        await tester.enterText(
          find.byKey(const Key('ivat-check-amount')),
          '10000',
        );
        await tap(tester, 'ivat-check-run');

        expect(
          textOf(tester, 'ivat-check-result'),
          'The invoice fits within the plafond',
        );
        expect(find.text('EUR 65,000.00'), findsOneWidget);
      },
    );

    testWidgets(
      'an invoice that exceeds the plafond is blocked, citing art. 8 and showing the excess',
      (WidgetTester tester) async {
        await open(tester);
        await tapTab(tester, 'ivat-tab-plafond');
        await tap(tester, 'ivat-check-l1');
        await tester.enterText(
          find.byKey(const Key('ivat-check-amount')),
          '80000',
        );
        await tap(tester, 'ivat-check-run');

        expect(
          textOf(tester, 'ivat-check-result'),
          'Plafond exceeded: an invoice without VAT is not allowed',
        );
        expect(find.text('Art. 8 par. 1 lett. c DPR 633/1972'), findsOneWidget);
        expect(find.text('Excess'), findsOneWidget);
        expect(find.text('EUR 5,000.00'), findsOneWidget);
      },
    );

    testWidgets('an invoice that nearly uses it up is only a warning', (
      WidgetTester tester,
    ) async {
      await open(tester);
      await tapTab(tester, 'ivat-tab-plafond');
      await tap(tester, 'ivat-check-l1');
      await tester.enterText(
        find.byKey(const Key('ivat-check-amount')),
        '70000',
      );
      await tap(tester, 'ivat-check-run');

      expect(
        textOf(tester, 'ivat-check-result'),
        'Warning: the plafond is running out',
      );
    });

    testWidgets(
      'registers a new letter: validates it, then saves it through the outbox',
      (WidgetTester tester) async {
        await open(tester);
        await tapTab(tester, 'ivat-tab-plafond');
        await tap(tester, 'ivat-add-letter');
        await tester.enterText(
          find.byKey(const Key('ivat-letter-customer')),
          'Nuovo Srl',
        );
        await tester.enterText(
          find.byKey(const Key('ivat-letter-protocol')),
          '123',
        );
        await tester.enterText(
          find.byKey(const Key('ivat-letter-amount')),
          '20000',
        );
        await tap(tester, 'ivat-letter-save');

        expect(
          textOf(tester, 'ivat-letter-issue'),
          'The protocol needs 17 digits, a dash and 6 digits',
        );
        expect(repo.drafts, isEmpty);

        await tester.enterText(
          find.byKey(const Key('ivat-letter-protocol')),
          '12345678901234567-000002',
        );
        await tap(tester, 'ivat-letter-save');

        expect(repo.drafts.single.customerName, 'Nuovo Srl');
        expect(repo.drafts.single.authorized, amt('20000.00'));
        expect(repo.drafts.single.validFrom, DateTime(2027));
        expect(repo.drafts.single.validTo, DateTime(2027, 12, 31));
        expect(find.text('Letter registered'), findsOneWidget);
        expect(find.byKey(const Key('ivat-letter-save')), findsNothing);
      },
    );

    testWidgets('a letter saved offline is listed as waiting to be sent', (
      WidgetTester tester,
    ) async {
      repo.nextStatus = ActionStatus.queued;
      await open(tester);
      await tapTab(tester, 'ivat-tab-plafond');
      await tap(tester, 'ivat-add-letter');
      await tester.enterText(
        find.byKey(const Key('ivat-letter-customer')),
        'Nuovo Srl',
      );
      await tester.enterText(
        find.byKey(const Key('ivat-letter-protocol')),
        '12345678901234567-000002',
      );
      await tester.enterText(
        find.byKey(const Key('ivat-letter-amount')),
        '20000',
      );
      await tap(tester, 'ivat-letter-save');

      expect(
        find.text('Letter saved: it will be sent at the next sync'),
        findsOneWidget,
      );
      expect(find.text('Waiting to be sent'), findsOneWidget);
      expect(find.text('Nuovo Srl'), findsOneWidget);
    });
  });

  group('LIPE and Erario c/IVA', () {
    setUp(
      () => repo.remoteSettlements = <LipeSettlement>[
        settlement(
          erario: '1990.00',
          lipe: <String, dynamic>{
            'generated': true,
            'xsd_valid': true,
            'signature_status': 'signed',
          },
        ),
      ],
    );

    testWidgets('lists the settlements with their balance', (
      WidgetTester tester,
    ) async {
      await open(tester);
      await tapTab(tester, 'ivat-tab-lipe');

      expect(find.text('2027-Q1'), findsOneWidget);
      expect(
        find.textContaining('VAT balance of the period: EUR 2,000.00'),
        findsOneWidget,
      );
      expect(find.text('Posted'), findsOneWidget);
    });

    testWidgets(
      'an opened settlement shows the Erario c/IVA difference and the validated, signed file',
      (WidgetTester tester) async {
        await open(tester);
        await tapTab(tester, 'ivat-tab-lipe');
        await tap(tester, 'ivat-settlement-s1');

        expect(find.text('Difference to investigate'), findsOneWidget);
        expect(textOf(tester, 'ivat-recon-diff-s1'), 'EUR -10.00');
        expect(textOf(tester, 'ivat-lipe-xsd-s1'), 'XSD validation passed');
        expect(textOf(tester, 'ivat-lipe-sig-s1'), 'Valid digital signature');
        expect(find.byKey(const Key('ivat-lipe-ready-s1')), findsOneWidget);
      },
    );

    testWidgets('a settlement without a file or ledger balance says so', (
      WidgetTester tester,
    ) async {
      repo.remoteSettlements = <LipeSettlement>[settlement()];
      await open(tester);
      await tapTab(tester, 'ivat-tab-lipe');
      await tap(tester, 'ivat-settlement-s1');

      expect(find.byKey(const Key('ivat-lipe-none-s1')), findsOneWidget);
      expect(find.text('Reconciliation not available yet'), findsOneWidget);
      expect(find.byKey(const Key('ivat-lipe-ready-s1')), findsNothing);
    });

    testWidgets('shows the XSD errors of an invalid file', (
      WidgetTester tester,
    ) async {
      repo.remoteSettlements = <LipeSettlement>[
        settlement(
          lipe: <String, dynamic>{
            'generated': true,
            'xsd_valid': false,
            'xsd_errors': <String>['Missing Modulo'],
          },
        ),
      ];
      await open(tester);
      await tapTab(tester, 'ivat-tab-lipe');
      await tap(tester, 'ivat-settlement-s1');

      expect(textOf(tester, 'ivat-lipe-xsd-s1'), 'XSD validation failed');
      expect(find.text('Missing Modulo'), findsOneWidget);
      expect(find.byKey(const Key('ivat-lipe-ready-s1')), findsNothing);
    });

    testWidgets('generates the LIPE XML and shares the XML and the PDF', (
      WidgetTester tester,
    ) async {
      await open(tester);
      await tapTab(tester, 'ivat-tab-lipe');
      await tap(tester, 'ivat-settlement-s1');

      await tap(tester, 'ivat-lipe-generate-s1');
      expect(repo.lipeRequests, <String>['s1']);
      expect(find.text('Request sent'), findsOneWidget);

      await tap(tester, 'ivat-lipe-xml-s1');
      await tap(tester, 'ivat-settlement-pdf-s1');
      expect(exporter.shared.map((String s) => s.split('|').first), <String>[
        'lipe-2027-Q1.xml',
        'settlement-2027-Q1.pdf',
      ]);
    });

    testWidgets('a LIPE request made offline is told to be queued', (
      WidgetTester tester,
    ) async {
      repo.nextStatus = ActionStatus.queued;
      await open(tester);
      await tapTab(tester, 'ivat-tab-lipe');
      await tap(tester, 'ivat-settlement-s1');
      await tap(tester, 'ivat-lipe-generate-s1');

      expect(
        find.text('Request queued: it will be sent at the next sync'),
        findsOneWidget,
      );
    });

    testWidgets('an empty list says so', (WidgetTester tester) async {
      repo.remoteSettlements = <LipeSettlement>[];
      await open(tester);
      await tapTab(tester, 'ivat-tab-lipe');

      expect(find.byKey(const Key('ivat-no-settlements')), findsOneWidget);
    });
  });

  group('annual VAT and CU', () {
    setUp(() {
      repo.remoteSettlements = <LipeSettlement>[
        settlement(
          erario: '2000.00',
          payable: '1000.00',
          paidAt: '2027-05-16T00:00:00Z',
        ),
        settlement(
          id: 's2',
          period: 2,
          output: '4000.00',
          input: '4500.00',
          erario: '-500.00',
          payable: '0.00',
        ),
      ];
      repo.remoteCertificates = <WithholdingCertificate>[
        certificate(),
        certificate(
          id: 'cu2',
          name: 'Bianchi Luca',
          kind: 'agent',
          paid: '0.00',
        ),
      ];
    });

    testWidgets('reconciles the year with the Erario c/IVA account', (
      WidgetTester tester,
    ) async {
      await open(tester);
      await tapTab(tester, 'ivat-tab-annual');

      expect(textOf(tester, 'ivat-annual-balance'), 'EUR 1,500.00');
      expect(textOf(tester, 'ivat-annual-due'), 'EUR 500.00');
      expect(textOf(tester, 'ivat-annual-missing'), 'Q3, Q4');
      expect(textOf(tester, 'ivat-annual-recon'), 'Reconciled');
      expect(
        find.text('Computed on the phone from the known settlements'),
        findsOneWidget,
      );
    });

    testWidgets('a credit year shows the credit label', (
      WidgetTester tester,
    ) async {
      repo.remoteSettlements = <LipeSettlement>[
        settlement(output: '1000.00', input: '3000.00', payable: '0.00'),
      ];
      await open(tester);
      await tapTab(tester, 'ivat-tab-annual');

      expect(find.text('VAT credit of the year'), findsOneWidget);
      expect(textOf(tester, 'ivat-annual-balance'), 'EUR 2,000.00');
    });

    testWidgets(
      'lists the certificates with their F24 payment status and the withholding still to pay',
      (WidgetTester tester) async {
        await open(tester);
        await tapTab(tester, 'ivat-tab-annual');

        expect(find.byKey(const Key('ivat-cu-cu1')), findsOneWidget);
        expect(find.text('F24 paid'), findsOneWidget);
        expect(find.text('F24 to be paid'), findsOneWidget);
        expect(find.text('Agent'), findsOneWidget);
        expect(find.text('1038'), findsOneWidget);
        expect(textOf(tester, 'ivat-cu-withheld'), 'EUR 4,000.00');
        expect(textOf(tester, 'ivat-cu-open'), 'EUR 2,000.00');
      },
    );

    testWidgets('shares the PDF of a certificate and the telematic file', (
      WidgetTester tester,
    ) async {
      await open(tester);
      await tapTab(tester, 'ivat-tab-annual');

      await tap(tester, 'ivat-cu-pdf-cu1');
      await tap(tester, 'ivat-cu-telematic');

      expect(exporter.shared.map((String s) => s.split('|').first), <String>[
        'cu-cu1.pdf',
        'cu-2027.txt',
      ]);
    });

    testWidgets('generates the certificates of the selected year', (
      WidgetTester tester,
    ) async {
      await open(tester);
      await tapTab(tester, 'ivat-tab-annual');
      await tap(tester, 'ivat-cu-generate');

      expect(repo.certificateRequests, <int>[2027]);
      expect(find.text('Request sent'), findsOneWidget);
    });

    testWidgets('a year without certificates has no telematic file to share', (
      WidgetTester tester,
    ) async {
      repo.remoteCertificates = <WithholdingCertificate>[];
      await open(tester);
      await tapTab(tester, 'ivat-tab-annual');

      expect(find.byKey(const Key('ivat-no-certificates')), findsOneWidget);
      expect(
        tester
            .widget<OutlinedButton>(find.byKey(const Key('ivat-cu-telematic')))
            .onPressed,
        isNull,
      );
    });

    testWidgets('moving to another year loads its summary', (
      WidgetTester tester,
    ) async {
      await open(tester);
      await tapTab(tester, 'ivat-tab-annual');
      await tap(tester, 'ivat-annual-prev');

      expect(textOf(tester, 'ivat-annual-year'), 'Year 2026');
      expect(find.byKey(const Key('ivat-no-certificates')), findsOneWidget);
    });
  });

  group('offline, errors and the outbox', () {
    testWidgets(
      'shows the offline copy banner when the refresh cannot reach the server',
      (WidgetTester tester) async {
        repo.refreshError = const ItalianVatException(
          ItalianVatErrorKind.offline,
        );
        await open(tester);

        expect(find.byKey(const Key('ivat-offline')), findsOneWidget);
        expect(find.byKey(const Key('ivat-error')), findsNothing);
      },
    );

    testWidgets('a missing right is reported in words', (
      WidgetTester tester,
    ) async {
      repo.refreshError = const ItalianVatException(
        ItalianVatErrorKind.forbidden,
      );
      await open(tester);

      expect(
        textOf(tester, 'ivat-error'),
        'You do not have the rights for this function',
      );
    });

    testWidgets('another failure shows the generic refresh error', (
      WidgetTester tester,
    ) async {
      repo.refreshError = const ItalianVatException(
        ItalianVatErrorKind.unknown,
      );
      await open(tester);

      expect(textOf(tester, 'ivat-error'), 'The data could not be refreshed');
    });

    testWidgets(
      'lists the queued writes, with retry and dismiss for a refused one',
      (WidgetTester tester) async {
        repo.pending = <PendingVatAction>[
          const PendingVatAction(
            queueUuid: 'q1',
            kind: VatActionKind.lipeGeneration,
            rejected: true,
            targetId: 's1',
            detail: 'Settlement not posted',
          ),
          const PendingVatAction(
            queueUuid: 'q2',
            kind: VatActionKind.certificateGeneration,
            rejected: false,
            targetId: '2027',
          ),
        ];
        await open(tester);

        expect(
          find.textContaining('LIPE generation · s1 — Settlement not posted'),
          findsOneWidget,
        );
        expect(
          find.textContaining('CU generation · 2027 — Waiting'),
          findsOneWidget,
        );
        expect(find.byKey(const Key('ivat-retry-q2')), findsNothing);

        await tap(tester, 'ivat-retry-q1');
        expect(repo.retried, <String>['q1']);
        expect(find.byKey(const Key('ivat-pending-q1')), findsNothing);
      },
    );

    testWidgets('dismisses a refused write', (WidgetTester tester) async {
      repo.pending = <PendingVatAction>[
        const PendingVatAction(
          queueUuid: 'q1',
          kind: VatActionKind.intentLetter,
          rejected: true,
          targetId: 'Export Srl',
        ),
      ];
      await open(tester);
      await tap(tester, 'ivat-dismiss-q1');

      expect(repo.dismissed, <String>['q1']);
      expect(find.byKey(const Key('ivat-pending-q1')), findsNothing);
    });

    testWidgets('the refresh button reloads everything', (
      WidgetTester tester,
    ) async {
      await open(tester);
      repo.remoteLetters = <IntentLetter>[letter()];

      await tap(tester, 'ivat-refresh');
      await tapTab(tester, 'ivat-tab-plafond');

      expect(find.text('Export Srl'), findsOneWidget);
    });
  });

  group('languages', () {
    testWidgets('speaks German for de-CH', (WidgetTester tester) async {
      await open(tester, language: 'de-CH');

      expect(find.text('MWST-Register und Meldungen'), findsOneWidget);
      expect(find.text('Verkäufe'), findsOneWidget);
      expect(textOf(tester, 'ivat-total-taxable'), 'EUR 1.000,00');
    });

    testWidgets('speaks French for fr-CH', (WidgetTester tester) async {
      await open(tester, language: 'fr-CH');

      expect(find.text('Registres TVA et déclarations'), findsOneWidget);
      expect(find.text('Impression provisoire'), findsOneWidget);
    });

    testWidgets('speaks Italian for it-IT and it-CH, with the decimal comma', (
      WidgetTester tester,
    ) async {
      await open(tester, language: 'it-IT');

      expect(find.text('Registri IVA e adempimenti'), findsOneWidget);
      expect(find.text('Stampa provvisoria'), findsOneWidget);
      expect(textOf(tester, 'ivat-total-taxable'), 'EUR 1.000,00');

      await open(tester, language: 'it-CH');
      expect(find.text('Registri IVA e adempimenti'), findsOneWidget);
    });
  });
}
