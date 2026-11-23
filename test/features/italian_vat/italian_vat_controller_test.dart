import 'package:fattura_facile/features/italian_vat/domain/italian_vat_models.dart';
import 'package:fattura_facile/features/italian_vat/presentation/italian_vat_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';
import 'fixtures.dart';

void main() {
  late FakeItalianVatRepository repo;
  late FakeExporter exporter;
  late ProviderContainer container;

  // Q2 2027: 2027-04-01 .. 2027-06-30.
  final DateTime q2From = DateTime(2027, 4);
  final DateTime q2To = DateTime(2027, 6, 30);

  ItalianVatController ctrl() => container.read(italianVatProvider.notifier);
  ItalianVatState state() => container.read(italianVatProvider);

  setUp(() {
    repo = FakeItalianVatRepository()
      ..remoteRegisters[FakeItalianVatRepository.key(
        VatRegisterType.sales,
        q2From,
        q2To,
      )] = VatRegister.fromJson(
        registerBody(<Map<String, dynamic>>[lineJson()]),
        type: VatRegisterType.sales,
        from: q2From,
        to: q2To,
      )
      ..remoteLetters = <IntentLetter>[letter()]
      ..remoteSettlements = <LipeSettlement>[settlement(erario: '2000.00')]
      ..remoteCertificates = <WithholdingCertificate>[certificate()];
    exporter = FakeExporter();
    container = ProviderContainer(
      overrides: [
        italianVatRepositoryProvider.overrideWithValue(repo),
        italianVatTenantIdProvider.overrideWithValue('t1'),
        italianVatNowProvider.overrideWithValue(DateTime(2027, 5, 10)),
        italianVatExporterProvider.overrideWithValue(exporter),
      ],
    );
    addTearDown(container.dispose);
  });

  group('periods', () {
    test(
      'the default selection is the current quarter of the sales register',
      () {
        expect(state().year, 2027);
        expect(state().registerType, VatRegisterType.sales);
        expect(state().periodKind, RegisterPeriodKind.quarter);
        expect(state().periodIndex, 2);
        expect(state().range.from, q2From);
        expect(state().range.to, q2To);
      },
    );

    test('computes the first and last day of months, quarters and years', () {
      expect(
        VatPeriods.range(RegisterPeriodKind.month, 2028, 2).to,
        DateTime(2028, 2, 29),
      );
      expect(
        VatPeriods.range(RegisterPeriodKind.month, 2027, 12).to,
        DateTime(2027, 12, 31),
      );
      expect(
        VatPeriods.range(RegisterPeriodKind.quarter, 2027, 4).from,
        DateTime(2027, 10),
      );
      expect(
        VatPeriods.range(RegisterPeriodKind.quarter, 2027, 1).to,
        DateTime(2027, 3, 31),
      );
      expect(
        VatPeriods.range(RegisterPeriodKind.year, 2027, 1).from,
        DateTime(2027),
      );
      expect(
        VatPeriods.range(RegisterPeriodKind.year, 2027, 1).to,
        DateTime(2027, 12, 31),
      );
    });

    test('picks the current index of each period kind', () {
      final DateTime now = DateTime(2027, 11, 3);
      expect(VatPeriods.currentIndex(RegisterPeriodKind.month, now), 11);
      expect(VatPeriods.currentIndex(RegisterPeriodKind.quarter, now), 4);
      expect(VatPeriods.currentIndex(RegisterPeriodKind.year, now), 1);
    });
  });

  group('load', () {
    test(
      'fills every part from the server and keeps the copy for offline use',
      () async {
        await ctrl().load();

        final ItalianVatState s = state();
        expect(s.loading, isFalse);
        expect(s.fromCache, isFalse);
        expect(s.error, isNull);
        expect(s.register!.lines, hasLength(1));
        expect(s.letters.single.customerName, 'Export Srl');
        expect(s.settlements.single.id, 's1');
        expect(s.annual!.output, amt('5000.00'));
        expect(s.certificates.single.recipientName, 'Rossi Mario');
      },
    );

    test('offline it shows the cached copy and flags it', () async {
      await ctrl().load();
      repo.refreshError = const ItalianVatException(
        ItalianVatErrorKind.offline,
      );

      await ctrl().load();

      expect(state().fromCache, isTrue);
      expect(state().error!.kind, ItalianVatErrorKind.offline);
      expect(state().register!.lines, hasLength(1));
      expect(state().letters, hasLength(1));
      expect(state().certificates, hasLength(1));
    });

    test(
      'a refused refresh is reported, not mistaken for being offline',
      () async {
        repo.refreshError = const ItalianVatException(
          ItalianVatErrorKind.forbidden,
        );

        await ctrl().load();

        expect(state().forbidden, isTrue);
        expect(state().fromCache, isFalse);
      },
    );

    test('shows the pending outbox rows', () async {
      repo.pending = <PendingVatAction>[
        const PendingVatAction(
          queueUuid: 'q1',
          kind: VatActionKind.lipeGeneration,
          rejected: false,
          targetId: 's1',
        ),
      ];

      await ctrl().load();

      expect(state().pending.single.queueUuid, 'q1');
      expect(state().pendingOf(VatActionKind.lipeGeneration), hasLength(1));
      expect(state().pendingOf(VatActionKind.intentLetter), isEmpty);
    });

    test('does nothing without a tenant', () async {
      final ProviderContainer signedOut = ProviderContainer(
        overrides: [
          italianVatRepositoryProvider.overrideWithValue(repo),
          italianVatTenantIdProvider.overrideWithValue(null),
          italianVatNowProvider.overrideWithValue(DateTime(2027, 5, 10)),
        ],
      );
      addTearDown(signedOut.dispose);

      await signedOut.read(italianVatProvider.notifier).load();

      expect(signedOut.read(italianVatProvider).register, isNull);
      expect(signedOut.read(italianVatProvider).letters, isEmpty);
    });
  });

  group('registers', () {
    test(
      'switching the register reloads it and clears the sectional filter',
      () async {
        await ctrl().load();
        ctrl().selectSectional('D');
        expect(state().sectional, 'D');

        await ctrl().selectRegister(VatRegisterType.purchases);

        expect(state().registerType, VatRegisterType.purchases);
        expect(state().sectional, isNull);
        expect(state().register!.type, VatRegisterType.purchases);
      },
    );

    test(
      'switching the period reloads the register of the new range',
      () async {
        await ctrl().selectPeriod(RegisterPeriodKind.month, 3);

        expect(state().range.from, DateTime(2027, 3));
        expect(state().range.to, DateTime(2027, 3, 31));
        expect(state().register!.from, DateTime(2027, 3));
      },
    );

    test('keeps the period index inside the kind', () async {
      await ctrl().selectPeriod(RegisterPeriodKind.month, 99);
      expect(state().periodIndex, 12);
      await ctrl().selectPeriod(RegisterPeriodKind.year, 5);
      expect(state().periodIndex, 1);
      await ctrl().selectPeriod(RegisterPeriodKind.quarter, 0);
      expect(state().periodIndex, 1);
    });

    test('shows the cached register at once while the refresh runs, and keeps it offline', () async {
      await ctrl().load();
      repo.refreshError = const ItalianVatException(
        ItalianVatErrorKind.offline,
      );

      await ctrl().reloadRegister();

      expect(state().register!.lines, hasLength(1));
      expect(state().fromCache, isTrue);
      expect(state().loading, isFalse);
    });

    test('changing the year refreshes the annual summary and the certificates of that year', () async {
      await ctrl().load();

      await ctrl().selectYear(2026);

      expect(state().year, 2026);
      expect(state().annual!.year, 2026);
      expect(state().annual!.periods, isEmpty);
      expect(state().certificates, isEmpty);
    });
  });

  group('letters of intent', () {
    final IntentLetterDraft draft = IntentLetterDraft(
      customerName: 'Nuovo Srl',
      protocol: '12345678901234567-000002',
      authorized: amt('20000.00'),
      validFrom: DateTime(2027),
      validTo: DateTime(2027, 12, 31),
    );

    test('a letter created offline shows at once as pending', () async {
      repo.nextStatus = ActionStatus.queued;
      repo.pending = <PendingVatAction>[
        const PendingVatAction(
          queueUuid: 'q9',
          kind: VatActionKind.intentLetter,
          rejected: false,
          targetId: 'Nuovo Srl',
        ),
      ];

      final ActionOutcome o = await ctrl().createLetter(draft);

      expect(o.status, ActionStatus.queued);
      expect(state().letters.single.pending, isTrue);
      expect(state().letters.single.customerName, 'Nuovo Srl');
      expect(state().pending, hasLength(1));
      expect(repo.drafts.single.protocol, '12345678901234567-000002');
    });

    test('a letter sent at once leaves nothing waiting', () async {
      final ActionOutcome o = await ctrl().createLetter(draft);

      expect(o.status, ActionStatus.sent);
      expect(state().pending, isEmpty);
    });
  });

  group('LIPE and certificates', () {
    test('a LIPE request sent at once refreshes the settlement with its new file status', () async {
      repo.cacheSettlements = <LipeSettlement>[settlement()];
      repo.remoteSettlements = <LipeSettlement>[
        settlement(
          lipe: <String, dynamic>{
            'generated': true,
            'xsd_valid': true,
            'signature_status': 'signed',
          },
        ),
      ];

      final ActionOutcome o = await ctrl().requestLipe('s1');

      expect(o.status, ActionStatus.sent);
      expect(repo.lipeRequests, <String>['s1']);
      expect(state().settlements.single.file.readyToTransmit, isTrue);
    });

    test('a queued LIPE request stays pending and does not pretend the file exists', () async {
      await ctrl().load();
      repo.nextStatus = ActionStatus.queued;
      repo.pending = <PendingVatAction>[
        const PendingVatAction(
          queueUuid: 'q1',
          kind: VatActionKind.lipeGeneration,
          rejected: false,
          targetId: 's1',
        ),
      ];

      final ActionOutcome o = await ctrl().requestLipe('s1');

      expect(o.status, ActionStatus.queued);
      expect(state().pending.single.targetId, 's1');
      expect(state().settlements.single.file.generated, isFalse);
    });

    test('requesting the certificates targets the selected year and refreshes them when sent', () async {
      await ctrl().load();
      repo.remoteCertificates = <WithholdingCertificate>[
        certificate(),
        certificate(id: 'cu2', name: 'Bianchi'),
      ];

      await ctrl().requestCertificates();

      expect(repo.certificateRequests, <int>[2027]);
      expect(state().certificates, hasLength(2));
    });

    test('a queued certificate request does not refresh', () async {
      await ctrl().load();
      repo.nextStatus = ActionStatus.queued;
      repo.remoteCertificates = <WithholdingCertificate>[];

      await ctrl().requestCertificates();

      expect(state().certificates, hasLength(1));
    });
  });

  group('outbox', () {
    test('retry and dismiss drop the row from the list', () async {
      repo.pending = <PendingVatAction>[
        const PendingVatAction(
          queueUuid: 'q1',
          kind: VatActionKind.intentLetter,
          rejected: true,
          detail: 'no',
        ),
        const PendingVatAction(
          queueUuid: 'q2',
          kind: VatActionKind.certificateGeneration,
          rejected: true,
        ),
      ];
      await ctrl().load();

      await ctrl().retry('q1');
      expect(repo.retried, <String>['q1']);
      expect(state().pending.map((PendingVatAction a) => a.queueUuid), <String>[
        'q2',
      ]);

      await ctrl().dismiss('q2');
      expect(repo.dismissed, <String>['q2']);
      expect(state().pending, isEmpty);
    });
  });

  group('sharing files', () {
    test('downloads the LIPE XML and hands it to the share sheet', () async {
      final ExportResult r = await ctrl().shareLipeXml(settlement());

      expect(r.failed, isFalse);
      expect(r.fileName, 'lipe-2027-Q1.xml');
      expect(exporter.shared, <String>['lipe-2027-Q1.xml|application/xml|3']);
    });

    test('shares the register CSV, the settlement PDF, the certificate PDF and the telematic file', () async {
      await ctrl().exportRegisterCsv();
      await ctrl().shareSettlementPdf(settlement());
      await ctrl().shareCertificatePdf(certificate());
      await ctrl().shareTelematicFile();

      expect(repo.downloads, <String>[
        'register-sales.csv',
        'settlement-2027-Q1.pdf',
        'cu-cu1.pdf',
        'cu-2027.txt',
      ]);
      expect(exporter.shared, hasLength(4));
    });

    test(
      'a failed download reports the server error and shares nothing',
      () async {
        repo.downloadError = const ItalianVatException(
          ItalianVatErrorKind.offline,
        );

        final ExportResult r = await ctrl().shareTelematicFile();

        expect(r.failed, isTrue);
        expect(r.error!.kind, ItalianVatErrorKind.offline);
        expect(exporter.shared, isEmpty);
      },
    );

    test(
      'a share sheet that fails is a failure without a server error',
      () async {
        exporter.fail = true;

        final ExportResult r = await ctrl().shareLipeXml(settlement());

        expect(r.failed, isTrue);
        expect(r.error, isNull);
      },
    );
  });
}
