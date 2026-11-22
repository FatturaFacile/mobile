import 'package:fattura_facile/features/field_service/data/field_service_outbox.dart';
import 'package:fattura_facile/features/field_service/data/field_service_repository.dart';
import 'package:fattura_facile/features/field_service/device/field_service_device_services.dart';
import 'package:fattura_facile/features/field_service/models/field_service_models.dart';
import 'package:fattura_facile/features/field_service/presentation/service_report_page.dart';
import 'package:fattura_facile/features/field_service/presentation/work_order_detail_page.dart';
import 'package:fattura_facile/features/field_service/presentation/work_queue_page.dart';
import 'package:fattura_facile/features/hse/ui/signature_pad.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'fakes.dart';
import 'support.dart';

Finder keyed(String key) => find.byKey(Key(key));

Finder inKey(String key, String text) =>
    find.descendant(of: keyed(key), matching: find.text(text));

Future<void> pump(
  WidgetTester tester,
  Widget child, {
  Locale locale = const Locale('en'),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: testDelegates,
      locale: locale,
      home: child,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> openPage(
  WidgetTester tester,
  Widget page, {
  Locale locale = const Locale('en'),
}) async {
  await tester.pumpWidget(hostApp(page, locale: locale));
  await tester.tap(keyed('open-page'));
  await tester.pumpAndSettle();
}

void main() {
  group('work queue', () {
    testWidgets('lists the open work orders from the phone', (
      WidgetTester tester,
    ) async {
      final FakeFsmRepository repo = FakeFsmRepository(
        queue: <FsmQueueItem>[
          queueItem(),
          queueItem(
            id: woWarranty,
            workType: 'warranty',
            status: FsmStatus.onSite,
          ),
        ],
      );

      await pump(tester, WorkQueuePage(repository: repo, refreshOnOpen: false));

      expect(find.text('My work orders'), findsOneWidget);
      expect(
        find.textContaining('WO-0001 · Compressor does not start'),
        findsNWidgets(2),
      );
      expect(find.textContaining('Rossi SA'), findsNWidgets(2));
      expect(find.textContaining('Corrective maintenance'), findsOneWidget);
      expect(find.text('Dispatched'), findsOneWidget);
      expect(find.text('On site'), findsOneWidget);
      expect(repo.calls, isNot(contains('refresh')));
    });

    testWidgets('shows an empty state', (WidgetTester tester) async {
      final FakeFsmRepository repo = FakeFsmRepository(queue: <FsmQueueItem>[]);

      await pump(tester, WorkQueuePage(repository: repo, refreshOnOpen: false));

      expect(keyed('fsm-empty'), findsOneWidget);
      expect(find.textContaining('No open work orders'), findsOneWidget);
    });

    testWidgets('refreshes when it opens and says when it is offline', (
      WidgetTester tester,
    ) async {
      final FakeFsmRepository repo = FakeFsmRepository()
        ..refreshResult = const FsmRefreshResult(offline: true);

      await pump(tester, WorkQueuePage(repository: repo));

      expect(repo.calls, contains('refresh'));
      expect(keyed('fsm-offline'), findsOneWidget);
      expect(find.textContaining('Offline'), findsOneWidget);
    });

    testWidgets('a failed refresh keeps the list and says so', (
      WidgetTester tester,
    ) async {
      final FakeFsmRepository repo = FakeFsmRepository()
        ..refreshResult = const FsmRefreshResult(error: 'boom');

      await pump(tester, WorkQueuePage(repository: repo));

      expect(find.text('Could not refresh the work orders'), findsOneWidget);
      expect(find.textContaining('WO-0001'), findsOneWidget);
    });

    testWidgets('opens the work order that was tapped', (
      WidgetTester tester,
    ) async {
      final FakeFsmRepository repo = FakeFsmRepository();

      await pump(tester, WorkQueuePage(repository: repo, refreshOnOpen: false));
      await tester.tap(keyed('fsm-wo-$woCorrective'));
      await tester.pumpAndSettle();

      expect(
        find.text('WO-0001'),
        findsOneWidget,
        reason: 'the detail app bar',
      );
      expect(keyed('fsm-next-step'), findsOneWidget);
    });

    testWidgets('shows what waits to sync and sends it on demand', (
      WidgetTester tester,
    ) async {
      final FakeFsmRepository repo = FakeFsmRepository()..pending = 3;

      await pump(tester, WorkQueuePage(repository: repo, refreshOnOpen: false));
      expect(find.text('3 waiting to sync'), findsOneWidget);

      await tester.tap(keyed('fsm-sync'));
      await tester.pumpAndSettle();

      expect(repo.calls, contains('sync'));
      expect(find.text('Synchronised: 1 sent'), findsOneWidget);
    });

    testWidgets('sync says when the phone is offline', (
      WidgetTester tester,
    ) async {
      final FakeFsmRepository repo = FakeFsmRepository()
        ..syncReport = const FsmFlushReport(offline: true);

      await pump(tester, WorkQueuePage(repository: repo, refreshOnOpen: false));
      await tester.tap(keyed('fsm-sync'));
      await tester.pumpAndSettle();

      expect(
        find.text('No connection: changes stay on the device'),
        findsOneWidget,
      );
      expect(keyed('fsm-offline'), findsOneWidget);
    });

    testWidgets('sync says when the session expired', (
      WidgetTester tester,
    ) async {
      final FakeFsmRepository repo = FakeFsmRepository()
        ..syncReport = const FsmFlushReport(unauthorized: true);

      await pump(tester, WorkQueuePage(repository: repo, refreshOnOpen: false));
      await tester.tap(keyed('fsm-sync'));
      await tester.pumpAndSettle();

      expect(find.text('Session expired: sign in again'), findsOneWidget);
    });

    testWidgets(
      'the conflict report lists the rejected operations and lets the technician retry or discard',
      (WidgetTester tester) async {
        final FakeFsmRepository repo = FakeFsmRepository()
          ..conflicts = <FsmOperation>[
            conflict(),
            conflict(uuid: 'c2', type: FsmOperationType.partConsumption),
          ];

        await pump(
          tester,
          WorkQueuePage(repository: repo, refreshOnOpen: false),
        );
        expect(find.text('Sync conflicts (2)'), findsOneWidget);

        await tester.tap(keyed('fsm-conflicts'));
        await tester.pumpAndSettle();

        expect(find.text('Sync conflicts'), findsOneWidget);
        expect(find.text('Service Report'), findsOneWidget);
        expect(find.text('Part consumption'), findsOneWidget);
        expect(
          find.textContaining('work_order: report_exists'),
          findsNWidgets(2),
        );

        await tester.tap(keyed('fsm-conflict-retry-c1'));
        await tester.tap(keyed('fsm-conflict-discard-c2'));
        await tester.pumpAndSettle();
        expect(repo.calls, containsAll(<String>['retry:c1', 'discard:c2']));

        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();
        expect(find.text('Sync conflicts'), findsNothing);
      },
    );

    testWidgets('speaks German and French', (WidgetTester tester) async {
      final FakeFsmRepository repo = FakeFsmRepository();

      await pump(
        tester,
        WorkQueuePage(repository: repo, refreshOnOpen: false),
        locale: const Locale('de'),
      );
      expect(find.text('Meine Einsätze'), findsOneWidget);
      expect(find.text('Disponiert'), findsOneWidget);
      expect(find.textContaining('Vorbeugende Wartung'), findsNothing);
      expect(find.textContaining('Reparatur'), findsOneWidget);

      await pump(
        tester,
        WorkQueuePage(repository: repo, refreshOnOpen: false),
        locale: const Locale('fr'),
      );
      expect(find.text('Mes interventions'), findsOneWidget);
      expect(find.text('Assignée'), findsOneWidget);
    });
  });

  group('work order detail', () {
    Future<void> openDetail(
      WidgetTester tester,
      FakeFsmRepository repo, {
      FieldServiceDeviceHooks device = const FieldServiceDeviceHooks(),
      Locale locale = const Locale('en'),
    }) async {
      tallScreen(tester);
      await pump(
        tester,
        WorkOrderDetailPage(
          repository: repo,
          workOrderId: woCorrective,
          device: device,
        ),
        locale: locale,
      );
    }

    testWidgets(
      'shows the work order, customer, problem, site, asset and history',
      (WidgetTester tester) async {
        await openDetail(tester, FakeFsmRepository());

        expect(find.text('Compressor does not start'), findsOneWidget);
        expect(inKey('fsm-status', 'Dispatched'), findsOneWidget);
        expect(
          find.textContaining('Rossi SA · +41 91 000 00 00'),
          findsOneWidget,
        );
        expect(find.text('Trips the breaker'), findsOneWidget);
        expect(
          find.textContaining('Via Nassa 5, Lugano · 46.00321, 8.95123'),
          findsOneWidget,
        );
        expect(find.text('Serial number SN-4711'), findsOneWidget);
        expect(find.textContaining('SR-2029-0001'), findsOneWidget);
        expect(find.text('Replaced belt'), findsOneWidget);
        expect(keyed('fsm-waiting-sync'), findsNothing);
      },
    );

    testWidgets('flags the work order that still has changes waiting to sync', (
      WidgetTester tester,
    ) async {
      await openDetail(
        tester,
        FakeFsmRepository(detail: detailFixture(pending: 2)),
      );

      expect(inKey('fsm-waiting-sync', 'Waiting to sync'), findsOneWidget);
    });

    testWidgets('the next journey step is queued offline', (
      WidgetTester tester,
    ) async {
      final FakeFsmRepository repo = FakeFsmRepository();
      await openDetail(tester, repo);

      expect(find.text('Start travel'), findsOneWidget);
      await tester.tap(keyed('fsm-next-step'));
      await tester.pumpAndSettle();

      expect(repo.calls, <String>['advance:en_route']);
      expect(keyed('fsm-message'), findsOneWidget);
      expect(
        find.text('Saved on the device, it syncs when online'),
        findsOneWidget,
      );
    });

    testWidgets('en route offers the arrival step, on site offers none', (
      WidgetTester tester,
    ) async {
      final FakeFsmRepository repo = FakeFsmRepository(
        detail: detailFixture(status: FsmStatus.enRoute),
      );
      await openDetail(tester, repo);

      expect(find.text('Arrived on site'), findsOneWidget);
      await tester.tap(keyed('fsm-next-step'));
      await tester.pumpAndSettle();
      expect(repo.calls, <String>['advance:on_site']);

      await openDetail(
        tester,
        FakeFsmRepository(detail: detailFixture(status: FsmStatus.onSite)),
      );
      expect(keyed('fsm-next-step'), findsNothing);
      expect(keyed('fsm-open-report'), findsOneWidget);
    });

    testWidgets('a refused step shows why', (WidgetTester tester) async {
      final FakeFsmRepository repo = FakeFsmRepository()
        ..failWith = const FsmException(<String, String>{
          'status': 'transition_invalid',
        });
      await openDetail(tester, repo);

      await tester.tap(keyed('fsm-next-step'));
      await tester.pumpAndSettle();

      expect(find.text('This work order is no longer open'), findsOneWidget);
    });

    testWidgets(
      'launches the navigator with the site coordinates and the work order as label',
      (WidgetTester tester) async {
        FsmSite? opened;
        String? label;
        await openDetail(
          tester,
          FakeFsmRepository(),
          device: FieldServiceDeviceHooks(
            openNavigation: (FsmSite site, String? l) async {
              opened = site;
              label = l;
              return true;
            },
          ),
        );

        await tester.tap(keyed('fsm-navigate'));
        await tester.pumpAndSettle();

        expect(opened?.latitude, closeTo(46.00321, 1e-9));
        expect(opened?.longitude, closeTo(8.95123, 1e-9));
        expect(opened?.address, 'Via Nassa 5, Lugano');
        expect(label, 'Compressor does not start');
        expect(keyed('fsm-message'), findsNothing);
      },
    );

    testWidgets(
      'says when no navigation app opened and hides the button without a hook',
      (WidgetTester tester) async {
        await openDetail(
          tester,
          FakeFsmRepository(),
          device: FieldServiceDeviceHooks(
            openNavigation: (FsmSite s, String? l) async => false,
          ),
        );
        await tester.tap(keyed('fsm-navigate'));
        await tester.pumpAndSettle();
        expect(find.text('No navigation app could be opened'), findsOneWidget);

        await openDetail(tester, FakeFsmRepository());
        expect(keyed('fsm-navigate'), findsNothing);
      },
    );

    testWidgets('scanning the asset serial confirms or warns', (
      WidgetTester tester,
    ) async {
      String code = 'SN:SN-4711';
      final FieldServiceDeviceHooks device = FieldServiceDeviceHooks(
        scanCode: (BuildContext c) async => code,
      );
      await openDetail(tester, FakeFsmRepository(), device: device);

      await tester.tap(keyed('fsm-scan-asset'));
      await tester.pumpAndSettle();
      expect(find.text('Serial number matches: SN-4711'), findsOneWidget);

      code = 'SN-0000';
      await tester.tap(keyed('fsm-scan-asset'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'The scanned serial SN-0000 is not the one of this work order (SN-4711)',
        ),
        findsOneWidget,
      );
    });

    testWidgets('the checklist is answered with one tap per point', (
      WidgetTester tester,
    ) async {
      final FakeFsmRepository repo = FakeFsmRepository();
      await openDetail(tester, repo);

      expect(find.text('Fault diagnosis'), findsOneWidget);
      await tester.tap(keyed('fsm-check-fault_diagnosis-pass'));
      await tester.tap(keyed('fsm-check-repair_verified-fail'));
      await tester.tap(keyed('fsm-check-functional_test-na'));
      await tester.pumpAndSettle();

      expect(repo.calls, <String>[
        'check:fault_diagnosis:pass',
        'check:repair_verified:fail',
        'check:functional_test:na',
      ]);
    });

    testWidgets(
      'shows what the contract covers and says when it is an estimate',
      (WidgetTester tester) async {
        await openDetail(tester, FakeFsmRepository());

        expect(inKey('fsm-coverage-labor', 'Covered'), findsOneWidget);
        expect(inKey('fsm-coverage-parts', 'Covered'), findsOneWidget);
        expect(inKey('fsm-coverage-travel', 'Chargeable'), findsOneWidget);
        expect(keyed('fsm-coverage-estimated'), findsOneWidget);
      },
    );

    testWidgets(
      'a work order without contract is all chargeable, a warranty one all covered',
      (WidgetTester tester) async {
        await openDetail(
          tester,
          FakeFsmRepository(detail: detailFixture(withContract: false)),
        );
        expect(inKey('fsm-coverage-labor', 'Chargeable'), findsOneWidget);
        expect(inKey('fsm-coverage-parts', 'Chargeable'), findsOneWidget);
        expect(keyed('fsm-coverage-estimated'), findsNothing);

        await openDetail(
          tester,
          FakeFsmRepository(
            detail: detailFixture(workType: 'warranty', withContract: false),
          ),
        );
        expect(inKey('fsm-coverage-travel', 'Covered'), findsOneWidget);
      },
    );

    testWidgets(
      'lists the consumed parts with covered or chargeable and the chargeable total',
      (WidgetTester tester) async {
        final FakeFsmRepository repo = FakeFsmRepository(
          detail: detailFixture(
            parts: <FsmPartLine>[
              partLine(),
              partLine(covered: false, uuid: 'p-2', quantity: 3),
            ],
          ),
        );
        await openDetail(tester, repo);

        expect(inKey('fsm-part-flag-p-1', 'Covered'), findsOneWidget);
        expect(inKey('fsm-part-flag-p-2', 'Chargeable'), findsOneWidget);
        expect(find.textContaining('2 × FLT-1 · Air filter'), findsOneWidget);
        expect(find.text('Chargeable parts: 75.00'), findsOneWidget);

        await tester.tap(keyed('fsm-part-remove-p-2'));
        await tester.pumpAndSettle();
        expect(repo.calls, <String>['remove-part:p-2']);
      },
    );

    testWidgets('says when no part was used', (WidgetTester tester) async {
      await openDetail(tester, FakeFsmRepository());
      expect(keyed('fsm-no-parts'), findsOneWidget);
      expect(keyed('fsm-chargeable-total'), findsNothing);
    });

    testWidgets(
      'a van part is picked, shown as covered, and consumed with quantity and lot',
      (WidgetTester tester) async {
        final FakeFsmRepository repo = FakeFsmRepository();
        await openDetail(tester, repo);

        await tester.tap(keyed('fsm-add-part'));
        await tester.pumpAndSettle();
        expect(find.text('FLT-1 · Air filter'), findsOneWidget);
        expect(find.text('On the van: 5'), findsOneWidget);
        expect(keyed('fsm-part-coverage'), findsNothing);

        await tester.tap(keyed('fsm-van-$productFilter'));
        await tester.pumpAndSettle();
        expect(inKey('fsm-part-coverage', 'Covered'), findsOneWidget);

        await tester.enterText(keyed('fsm-part-qty'), '2');
        await tester.enterText(keyed('fsm-part-lot'), 'LOT-7');
        await tester.tap(keyed('fsm-part-confirm'));
        await tester.pumpAndSettle();

        expect(repo.consumed?.item.productId, productFilter);
        expect(repo.consumed?.quantity, 2);
        expect(repo.consumed?.lot, 'LOT-7');
        expect(
          keyed('fsm-part-confirm'),
          findsNothing,
          reason: 'the sheet closed',
        );
      },
    );

    testWidgets('a chargeable part is flagged before it is added', (
      WidgetTester tester,
    ) async {
      await openDetail(
        tester,
        FakeFsmRepository(detail: detailFixture(withContract: false)),
      );

      await tester.tap(keyed('fsm-add-part'));
      await tester.pumpAndSettle();
      await tester.tap(keyed('fsm-van-$productOil'));
      await tester.pumpAndSettle();

      expect(inKey('fsm-part-coverage', 'Chargeable'), findsOneWidget);
    });

    testWidgets('a part is added by scanning its label, lot included', (
      WidgetTester tester,
    ) async {
      final FakeFsmRepository repo = FakeFsmRepository();
      String code = 'PART:FLT-1:LOT-7';
      await openDetail(
        tester,
        repo,
        device: FieldServiceDeviceHooks(
          scanCode: (BuildContext c) async => code,
        ),
      );

      await tester.tap(keyed('fsm-add-part'));
      await tester.pumpAndSettle();
      await tester.tap(keyed('fsm-scan-part'));
      await tester.pumpAndSettle();

      expect(inKey('fsm-part-coverage', 'Covered'), findsOneWidget);
      expect(
        tester.widget<TextField>(keyed('fsm-part-lot')).controller?.text,
        'LOT-7',
      );

      await tester.tap(keyed('fsm-part-confirm'));
      await tester.pumpAndSettle();
      expect(repo.consumed?.item.sku, 'FLT-1');
      expect(repo.consumed?.quantity, 1);

      // A label the van does not carry.
      code = 'PART:UNKNOWN';
      await tester.tap(keyed('fsm-add-part'));
      await tester.pumpAndSettle();
      await tester.tap(keyed('fsm-scan-part'));
      await tester.pumpAndSettle();
      expect(find.text('This part is not on the van'), findsOneWidget);
    });

    testWidgets('the picker refuses a bad quantity and shows the stock error', (
      WidgetTester tester,
    ) async {
      final FakeFsmRepository repo = FakeFsmRepository();
      await openDetail(tester, repo);
      await tester.tap(keyed('fsm-add-part'));
      await tester.pumpAndSettle();

      await tester.tap(keyed('fsm-part-confirm'));
      await tester.pumpAndSettle();
      expect(
        find.text('This part is not on the van'),
        findsOneWidget,
        reason: 'nothing picked yet',
      );

      await tester.tap(keyed('fsm-van-$productFilter'));
      await tester.enterText(keyed('fsm-part-qty'), '0');
      await tester.tap(keyed('fsm-part-confirm'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a quantity greater than zero'), findsOneWidget);

      repo.failWith = const FsmException(<String, String>{
        'quantity': 'insufficient_stock',
      });
      await tester.enterText(keyed('fsm-part-qty'), '9');
      await tester.tap(keyed('fsm-part-confirm'));
      await tester.pumpAndSettle();
      expect(
        inKey('fsm-part-message', 'Not enough on the van'),
        findsOneWidget,
      );
      expect(repo.consumed, isNull);
    });

    testWidgets(
      'a signed work order shows the seal and takes no more changes',
      (WidgetTester tester) async {
        final StoredReport report = StoredReport(
          workOrderId: woCorrective,
          clientUuid: 'rep-1',
          signatureSha256: 'abc123',
          signedAt: DateTime.utc(2030, 1, 1, 10),
          payload: const <String, dynamic>{},
          reportNumber: 'SR-2030-0007',
        );
        await openDetail(
          tester,
          FakeFsmRepository(
            detail: detailFixture(
              status: FsmStatus.completed,
              report: report,
              parts: <FsmPartLine>[partLine()],
            ),
          ),
        );

        expect(keyed('fsm-signed'), findsOneWidget);
        expect(find.text('Signature SHA-256: abc123'), findsOneWidget);
        expect(find.text('Report no. SR-2030-0007'), findsOneWidget);
        expect(keyed('fsm-open-report'), findsNothing);
        expect(keyed('fsm-next-step'), findsNothing);
        expect(keyed('fsm-add-part'), findsNothing);
        expect(keyed('fsm-part-remove-p-1'), findsNothing);
      },
    );

    testWidgets('the report button opens the service report', (
      WidgetTester tester,
    ) async {
      await openDetail(
        tester,
        FakeFsmRepository(detail: detailFixture(status: FsmStatus.onSite)),
      );

      await tester.tap(keyed('fsm-open-report'));
      await tester.pumpAndSettle();

      expect(keyed('fsm-sign'), findsOneWidget);
      expect(find.text('Service Report'), findsOneWidget);
    });

    testWidgets('speaks Italian', (WidgetTester tester) async {
      await openDetail(tester, FakeFsmRepository(), locale: const Locale('it'));

      expect(find.text('Assegnato'), findsOneWidget);
      expect(find.text('Parti per l’intervento'), findsOneWidget);
      expect(find.text('Rapportino d’Intervento'), findsOneWidget);
      expect(find.text('Diagnosi del guasto'), findsOneWidget);
    });
  });

  group('service report', () {
    FakeFsmRepository onSiteRepo({
      List<FsmPartLine> parts = const <FsmPartLine>[],
    }) => FakeFsmRepository(
      detail: detailFixture(status: FsmStatus.onSite, parts: parts),
    );

    Future<void> open(
      WidgetTester tester,
      FakeFsmRepository repo, {
      FieldServiceDeviceHooks device = const FieldServiceDeviceHooks(),
      Locale locale = const Locale('en'),
    }) async {
      tallScreen(tester);
      await openPage(
        tester,
        ServiceReportPage(
          repository: repo,
          workOrderId: woCorrective,
          device: device,
          clock: () => DateTime.utc(2030, 1, 1, 10),
        ),
        locale: locale,
      );
    }

    Future<void> fillForm(WidgetTester tester) async {
      await tester.enterText(
        keyed('fsm-summary'),
        'Replaced the start capacitor',
      );
      await tester.enterText(keyed('fsm-labor'), '1,5');
      await tester.enterText(keyed('fsm-travel-hours'), '0.5');
      await tester.enterText(keyed('fsm-travel-km'), '24');
      await tester.enterText(keyed('fsm-meter-hours'), '1210');
      await tester.enterText(keyed('fsm-meter-cycles'), '305');
      await tester.enterText(keyed('fsm-signer'), 'Mario Rossi');
      await tester.enterText(keyed('fsm-signer-role'), 'Facility manager');
      await tester.tap(keyed('fsm-callout'));
      await tester.pump();
    }

    Future<void> drawSignature(WidgetTester tester) async {
      await tester.drag(find.byType(SignaturePad), const Offset(120, 0));
      await tester.pump();
    }

    testWidgets(
      'shows the fields of the service report with the coverage of each cost',
      (WidgetTester tester) async {
        await open(tester, onSiteRepo());

        expect(find.text('Service Report'), findsOneWidget);
        for (final String label in <String>[
          'Work performed',
          'Labor hours',
          'Travel hours',
          'Travel km',
          'Meter reading (hours)',
          'Meter reading (cycles)',
          'Customer name',
          'Customer signature',
        ]) {
          expect(find.text(label), findsOneWidget, reason: label);
        }
        expect(find.text('Apply the call-out fee'), findsOneWidget);
        expect(find.text('Call-out fee · Chargeable'), findsOneWidget);
        expect(find.text('0 of 20 photos'), findsOneWidget);
        expect(find.byType(SignaturePad), findsOneWidget);
      },
    );

    testWidgets('does not send an incomplete report and says what is missing', (
      WidgetTester tester,
    ) async {
      final FakeFsmRepository repo = onSiteRepo();
      await open(tester, repo);

      await tester.tap(keyed('fsm-sign'));
      await tester.pumpAndSettle();

      expect(repo.signedDraft, isNull);
      expect(
        find.text('Labor hours must be between 0 and 999'),
        findsOneWidget,
      );
      expect(find.text('The customer must sign first'), findsOneWidget);
    });

    testWidgets('a labor value that is not a number is refused', (
      WidgetTester tester,
    ) async {
      final FakeFsmRepository repo = onSiteRepo();
      await open(tester, repo);
      await tester.enterText(keyed('fsm-labor'), 'abc');
      await drawSignature(tester);

      await tester.tap(keyed('fsm-sign'));
      await tester.pumpAndSettle();

      expect(repo.signedDraft, isNull);
      expect(
        find.text('Labor hours must be between 0 and 999'),
        findsOneWidget,
      );
    });

    testWidgets(
      'signs with a vector signature and queues the report through the repository',
      (WidgetTester tester) async {
        final FakeFsmRepository repo = onSiteRepo();
        await open(
          tester,
          repo,
          device: FieldServiceDeviceHooks(
            locate: () async => (latitude: 46.00321, longitude: 8.95123),
          ),
        );
        await fillForm(tester);
        await tester.tap(keyed('fsm-locate'));
        await tester.pumpAndSettle();
        expect(find.text('Position saved: 46.00321, 8.95123'), findsOneWidget);
        await drawSignature(tester);

        await tester.tap(keyed('fsm-sign'));
        await tester.pumpAndSettle();

        final ServiceReportDraft? draft = repo.signedDraft;
        expect(draft, isNotNull);
        expect(draft!.workPerformedSummary, 'Replaced the start capacitor');
        expect(draft.laborHours, 1.5);
        expect(draft.travelHours, 0.5);
        expect(draft.travelKm, 24);
        expect(draft.applyCalloutFee, isTrue);
        expect(draft.meterReadingHours, 1210);
        expect(draft.meterReadingCycles, 305);
        expect(draft.signerName, 'Mario Rossi');
        expect(draft.signerRole, 'Facility manager');
        expect(draft.signedAt, DateTime.utc(2030, 1, 1, 10));
        expect(draft.latitude, 46.00321);
        expect(draft.longitude, 8.95123);
        expect(draft.locale, 'en');
        expect(draft.signatureSvg, startsWith('<svg '));
        expect(draft.signatureSvg, contains('<path d="M'));
        expect(draft.checklist.map((ChecklistEntry c) => c.item), <String>[
          'fault_diagnosis',
          'repair_verified',
          'functional_test',
        ]);

        // The page closed and the technician is told it was saved offline.
        expect(keyed('fsm-sign'), findsNothing);
        expect(
          find.text(
            'Service report signed and saved. It syncs as soon as the device is online.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('the report is sent in the language of the tenant locale', (
      WidgetTester tester,
    ) async {
      final FakeFsmRepository repo = onSiteRepo();
      await open(tester, repo, locale: const Locale('it', 'CH'));
      expect(find.text('Rapportino d’Intervento'), findsOneWidget);
      expect(find.text('Ore lavorate'), findsOneWidget);
      expect(
        find.text('Diritto fisso di chiamata · A pagamento'),
        findsOneWidget,
      );
      await fillForm(tester);
      await drawSignature(tester);

      await tester.tap(keyed('fsm-sign'));
      await tester.pumpAndSettle();

      expect(repo.signedDraft?.locale, 'it-CH');
    });

    testWidgets(
      'German uses Servicerapport, Arbeitsstunden and Anfahrtspauschale',
      (WidgetTester tester) async {
        await open(tester, onSiteRepo(), locale: const Locale('de'));

        expect(find.text('Servicerapport'), findsOneWidget);
        expect(find.text('Arbeitsstunden'), findsOneWidget);
        expect(find.text('Reisezeit (Stunden)'), findsOneWidget);
        expect(find.text('Anfahrtspauschale · Verrechenbar'), findsOneWidget);
      },
    );

    testWidgets(
      'French uses Rapport d’intervention, Heures de travail and Frais de déplacement',
      (WidgetTester tester) async {
        await open(tester, onSiteRepo(), locale: const Locale('fr'));

        expect(find.text('Rapport d’intervention'), findsOneWidget);
        expect(find.text('Heures de travail'), findsOneWidget);
        expect(find.text('Frais de déplacement · Facturable'), findsOneWidget);
      },
    );

    testWidgets('the repository refusal is shown and the page stays open', (
      WidgetTester tester,
    ) async {
      final FakeFsmRepository repo = onSiteRepo()
        ..failWith = const FsmException(<String, String>{
          'checklist': 'unanswered',
          'meter_reading': 'regression',
          'customer_signer_name': 'required',
        });
      await open(tester, repo);
      await fillForm(tester);
      await drawSignature(tester);

      await tester.tap(keyed('fsm-sign'));
      await tester.pumpAndSettle();

      expect(find.text('Answer every checklist point'), findsOneWidget);
      expect(
        find.text('The reading cannot be lower than the current meter'),
        findsOneWidget,
      );
      expect(find.text('Enter the name of the person signing'), findsOneWidget);
      expect(keyed('fsm-sign'), findsOneWidget);
    });

    testWidgets('clearing the pad removes the signature', (
      WidgetTester tester,
    ) async {
      final FakeFsmRepository repo = onSiteRepo();
      await open(tester, repo);
      await fillForm(tester);
      await drawSignature(tester);
      await tester.tap(keyed('fsm-clear-signature'));
      await tester.pump();

      await tester.tap(keyed('fsm-sign'));
      await tester.pumpAndSettle();

      expect(repo.signedDraft, isNull);
      expect(find.text('The customer must sign first'), findsOneWidget);
    });

    testWidgets(
      'photos are taken through the hook and attached to the report',
      (WidgetTester tester) async {
        final FakeFsmRepository repo = onSiteRepo();
        await open(
          tester,
          repo,
          device: FieldServiceDeviceHooks(
            takePhoto: () async => (localPath: '/data/a.jpg', name: 'a.jpg'),
          ),
        );

        await tester.tap(keyed('fsm-add-photo'));
        await tester.pumpAndSettle();

        expect(repo.calls, <String>['photo:a.jpg:/data/a.jpg']);
      },
    );

    testWidgets('lists the attached photos and removes one', (
      WidgetTester tester,
    ) async {
      final FakeFsmRepository repo = onSiteRepo();
      repo.detailValue = FsmWorkOrderDetail(
        workOrder: repo.detailValue!.workOrder,
        coverage: repo.detailValue!.coverage,
        site: repo.detailValue!.site,
        checklist: repo.detailValue!.checklist,
        photos: <ReportPhoto>[
          ReportPhoto(
            id: 'ph-9',
            path: 'fsm/x/b.jpg',
            name: 'b.jpg',
            takenAt: DateTime.utc(2030),
          ),
        ],
      );
      await open(tester, repo);

      expect(find.text('b.jpg'), findsOneWidget);
      expect(find.text('1 of 20 photos'), findsOneWidget);
      await tester.tap(keyed('fsm-photo-remove-ph-9'));
      await tester.pumpAndSettle();
      expect(repo.calls, <String>['remove-photo:ph-9']);
    });

    testWidgets('the chosen stage and caption go with the next photo', (
      WidgetTester tester,
    ) async {
      final FakeFsmRepository repo = onSiteRepo();
      await open(
        tester,
        repo,
        device: FieldServiceDeviceHooks(
          takePhoto: () async => (localPath: '/data/a.jpg', name: 'a.jpg'),
        ),
      );

      await tester.tap(keyed('fsm-photo-stage-before'));
      await tester.pump();
      await tester.enterText(keyed('fsm-photo-caption'), 'worn belt');
      await tester.tap(keyed('fsm-add-photo'));
      await tester.pumpAndSettle();

      expect(repo.calls, <String>['photo:a.jpg:/data/a.jpg:before:worn belt']);
    });

    testWidgets(
      'each photo shows queued, uploaded or failed; only the failed one can be retried and an uploaded one cannot be removed',
      (WidgetTester tester) async {
        final FakeFsmRepository repo = onSiteRepo();
        ReportPhoto photo(String id, FsmPhotoUpload upload) => ReportPhoto(
          id: id,
          path: 'fsm/x/$id.jpg',
          name: '$id.jpg',
          takenAt: DateTime.utc(2030),
          upload: upload,
          stage: id == 'q' ? FsmPhotoStage.after : null,
          caption: id == 'q' ? 'cleaned' : null,
        );
        repo.detailValue = FsmWorkOrderDetail(
          workOrder: repo.detailValue!.workOrder,
          coverage: repo.detailValue!.coverage,
          site: repo.detailValue!.site,
          checklist: repo.detailValue!.checklist,
          photos: <ReportPhoto>[
            photo('q', FsmPhotoUpload.queued),
            photo('u', FsmPhotoUpload.uploaded),
            photo('f', FsmPhotoUpload.failed),
          ],
        );
        await open(tester, repo);

        expect(
          find.descendant(
            of: keyed('fsm-photo-q'),
            matching: find.text('Waiting to upload'),
          ),
          findsOneWidget,
        );
        expect(find.text('After · cleaned'), findsOneWidget);
        expect(
          find.descendant(
            of: keyed('fsm-photo-u'),
            matching: find.text('Uploaded'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: keyed('fsm-photo-f'),
            matching: find.text('Upload failed'),
          ),
          findsOneWidget,
        );
        expect(keyed('fsm-photo-remove-u'), findsNothing);
        expect(keyed('fsm-photo-retry-q'), findsNothing);
        expect(keyed('fsm-photo-retry-u'), findsNothing);

        await tester.tap(keyed('fsm-photo-retry-f'));
        await tester.pumpAndSettle();
        expect(repo.calls, <String>['retry:f']);
      },
    );

    testWidgets(
      'GPS that is unavailable is reported and the report is still signed',
      (WidgetTester tester) async {
        final FakeFsmRepository repo = onSiteRepo();
        await open(
          tester,
          repo,
          device: FieldServiceDeviceHooks(locate: () async => null),
        );
        await tester.tap(keyed('fsm-locate'));
        await tester.pumpAndSettle();
        expect(find.textContaining('Position not available'), findsOneWidget);
        await fillForm(tester);
        await drawSignature(tester);

        await tester.tap(keyed('fsm-sign'));
        await tester.pumpAndSettle();

        expect(repo.signedDraft?.latitude, isNull);
      },
    );

    testWidgets(
      'shows the chargeable parts total and hides meters without an asset',
      (WidgetTester tester) async {
        final FakeFsmRepository repo = FakeFsmRepository(
          detail: detailFixture(
            status: FsmStatus.onSite,
            withEquipment: false,
            parts: <FsmPartLine>[partLine(covered: false, quantity: 2)],
          ),
        );
        await open(tester, repo);

        expect(find.text('Chargeable parts: 50.00'), findsOneWidget);
        expect(keyed('fsm-meter-hours'), findsNothing);
        expect(keyed('fsm-meter-cycles'), findsNothing);
      },
    );

    testWidgets(
      'the form is kept when the page is left and restored when it is opened again',
      (WidgetTester tester) async {
        final FakeFsmRepository repo = onSiteRepo();
        repo.drafts[woCorrective] = <String, dynamic>{
          'summary': 'Half done',
          'labor': '2',
          'callout': true,
        };
        await open(tester, repo);

        expect(
          tester.widget<TextField>(keyed('fsm-summary')).controller?.text,
          'Half done',
        );
        expect(
          tester.widget<SwitchListTile>(keyed('fsm-callout')).value,
          isTrue,
        );

        await tester.enterText(keyed('fsm-signer'), 'Anna');
        await tester.pageBack();
        await tester.pumpAndSettle();

        expect(repo.drafts[woCorrective]?['signer'], 'Anna');
        expect(repo.drafts[woCorrective]?['summary'], 'Half done');
      },
    );

    testWidgets('an already signed work order cannot be signed twice', (
      WidgetTester tester,
    ) async {
      final StoredReport report = StoredReport(
        workOrderId: woCorrective,
        clientUuid: 'rep-1',
        signatureSha256: 'h',
        signedAt: DateTime.utc(2030),
        payload: const <String, dynamic>{},
      );
      await open(
        tester,
        FakeFsmRepository(
          detail: detailFixture(status: FsmStatus.completed, report: report),
        ),
      );

      expect(keyed('fsm-report-signed'), findsOneWidget);
      expect(keyed('fsm-sign'), findsNothing);
    });
  });
}
