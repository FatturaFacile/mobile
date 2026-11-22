import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:fattura_facile/core/database/app_database.dart';
import 'package:fattura_facile/core/sync/sync_engine.dart';
import 'package:fattura_facile/features/hse/data/hse_repository.dart';
import 'package:fattura_facile/features/hse/l10n/hse_strings.dart';
import 'package:fattura_facile/features/hse/models/hse_models.dart';
import 'package:fattura_facile/features/hse/ui/near_miss_screen.dart';
import 'package:fattura_facile/features/hse/ui/ppe_delivery_screen.dart';
import 'package:fattura_facile/features/hse/ui/signature_pad.dart';
import 'package:fattura_facile/features/hse/ui/tool_box_talk_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const String productId = '019a8b7c-5555-7000-8000-000000000012';

class FakeHseRepository implements HseRepository {
  final List<PpeHandOver> handOvers = <PpeHandOver>[];
  final List<ToolBoxTalk> talks = <ToolBoxTalk>[];
  final List<NearMissReport> reports = <NearMissReport>[];

  @override
  Future<String> queuePpeHandOver(PpeHandOver handOver) async {
    handOvers.add(handOver);
    return 'q-ppe';
  }

  @override
  Future<String> queueToolBoxTalk(ToolBoxTalk talk) async {
    talks.add(talk);
    return 'q-talk';
  }

  @override
  Future<String> queueNearMiss(NearMissReport report) async {
    reports.add(report);
    return 'q-near-miss';
  }

  @override
  Stream<int> watchPending() => Stream<int>.value(0);
}

Widget host(Widget child, {Locale locale = const Locale('en')}) =>
    MaterialApp(locale: locale, home: child);

void main() {
  group('PpeScan', () {
    test('reads a PPE box label', () {
      final scan = PpeScan.parse('PPE:$productId:LOT-2027-01');

      expect(scan?.productId, productId);
      expect(scan?.lotOrSerial, 'LOT-2027-01');
    });

    test('keeps a serial number that contains a colon', () {
      expect(PpeScan.parse('ppe:$productId:SN:42:7')?.lotOrSerial, 'SN:42:7');
    });

    test('refuses a badge, a malformed product id and an empty lot', () {
      expect(PpeScan.parse('EMP-0042'), isNull);
      expect(PpeScan.parse('PPE:not-a-uuid:LOT'), isNull);
      expect(PpeScan.parse('PPE:$productId:'), isNull);
    });
  });

  group('payloads', () {
    test('a hand-over carries what the API validates', () {
      final json = PpeHandOver(
        employeeId: 'e1',
        productId: productId,
        warehouseId: 'w1',
        lotOrSerial: 'LOT-1',
        quantity: 2,
        signaturePayload: '[[[1.0,2.0]]]',
        locale: 'de-CH',
        replacementDueAt: DateTime(2028, 6, 5),
        handedOverAt: DateTime.utc(2027, 6, 15, 7, 30),
      ).toJson();

      expect(json['lot_or_serial_id'], 'LOT-1');
      expect(json['replacement_due_at'], '2028-06-05');
      expect(json['handed_over_at'], '2027-06-15T07:30:00.000Z');
      expect(json['signature_payload'], '[[[1.0,2.0]]]');
    });

    test(
      'a near miss is located by the site tag and the position of the phone',
      () {
        final report = NearMissReport(
          description: ' Oil on the floor ',
          reportedAt: DateTime.utc(2027, 5, 5),
          siteTag: 'LUG-02',
          latitude: 46.00366,
          longitude: 8.95107,
        );

        expect(report.toJson()['incident_type'], 'near_miss');
        expect(report.toJson()['description'], 'Oil on the floor');
        expect(report.location, 'LUG-02 @ 46.00366,8.95107');
        expect(
          NearMissReport(
            description: 'x',
            reportedAt: DateTime.utc(2027),
          ).toJson().containsKey('location_or_site_id'),
          isFalse,
        );
      },
    );
  });

  group('device capture', () {
    const employeeId = '019a8b7c-5555-7000-8000-000000000099';
    const pngBase64 =
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

    test('reads a worker badge and refuses anything else', () {
      expect(HseBadge.parse('EMP:$employeeId')?.employeeId, employeeId);
      expect(
        HseBadge.parse('emp: ${employeeId.toUpperCase()} ')?.employeeId,
        employeeId,
      );
      expect(HseBadge.parse('PPE:$productId:LOT-1'), isNull);
      expect(HseBadge.parse('EMP:not-a-uuid'), isNull);
      expect(HseBadge.parse('EMP:$employeeId:extra'), isNull);
    });

    test('reads the text of an NFC Forum text record', () {
      final payload = <int>[
        0x02,
        ...utf8.encode('en'),
        ...utf8.encode('EMP:$employeeId'),
      ];

      expect(ndefTextFromPayload(payload), 'EMP:$employeeId');
      expect(ndefTextFromPayload(const <int>[]), isNull);
      expect(
        ndefTextFromPayload(const <int>[0x82, 0x65, 0x6e]),
        isNull,
        reason: 'UTF-16 is not used by badges',
      );
      expect(
        ndefTextFromPayload(const <int>[0x05, 0x65]),
        isNull,
        reason: 'language code longer than the payload',
      );
    });

    test('a report carries its photos only when it has some', () {
      final without = NearMissReport(
        description: 'Oil',
        reportedAt: DateTime.utc(2027, 5, 5),
      );
      final withPhoto = NearMissReport(
        description: 'Oil',
        reportedAt: DateTime.utc(2027, 5, 5),
        photos: const [pngBase64],
      );

      expect(without.toJson().containsKey('photos'), isFalse);
      expect(withPhoto.toJson()['photos'], [pngBase64]);
    });

    testWidgets('a near miss tags the position, or says why it could not', (
      tester,
    ) async {
      final repository = FakeHseRepository();
      var answer = (
        latitude: 46.00321,
        longitude: 8.95123,
      ) as ({double latitude, double longitude})?;
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        host(
          NearMissScreen(repository: repository, locate: () async => answer),
        ),
      );

      await tester.tap(find.byKey(const Key('nm-locate')));
      await tester.pumpAndSettle();
      expect(find.text('Position saved: 46.00321, 8.95123'), findsOneWidget);

      answer = null;
      await tester.tap(find.byKey(const Key('nm-locate')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Position not available'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('nm-what')),
        'Oil on the floor',
      );
      await tester.tap(find.byKey(const Key('nm-send')));
      await tester.pumpAndSettle();
      expect(
        repository.reports.single.latitude,
        isNull,
        reason: 'a failed fix must not leave the old position behind',
      );
    });

    testWidgets(
      'a near miss takes up to three photos, lets one be removed and queues them',
      (tester) async {
        final repository = FakeHseRepository();
        await tester.binding.setSurfaceSize(const Size(800, 1600));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          host(
            NearMissScreen(
              repository: repository,
              capturePhoto: () async => pngBase64,
            ),
          ),
        );

        for (var i = 0; i < 4; i++) {
          await tester.tap(
            find.byKey(const Key('nm-photo')),
            warnIfMissed: false,
          );
          await tester.pumpAndSettle();
        }
        expect(find.text('3 of 3 photos'), findsOneWidget);
        expect(
          tester
              .widget<OutlinedButton>(find.byKey(const Key('nm-photo')))
              .onPressed,
          isNull,
        );

        await tester.tap(find.byKey(const Key('nm-photo-remove-0')));
        await tester.pumpAndSettle();
        expect(find.text('2 of 3 photos'), findsOneWidget);

        await tester.enterText(
          find.byKey(const Key('nm-what')),
          'Oil on the floor',
        );
        await tester.tap(find.byKey(const Key('nm-send')));
        await tester.pumpAndSettle();
        expect(repository.reports.single.photos, hasLength(2));
        expect(find.text('0 of 3 photos'), findsOneWidget);
      },
    );

    testWidgets('a cancelled camera adds no photo', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        host(
          NearMissScreen(
            repository: FakeHseRepository(),
            capturePhoto: () async => null,
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('nm-photo')));
      await tester.pumpAndSettle();

      expect(find.text('0 of 3 photos'), findsOneWidget);
    });

    testWidgets(
      'an NFC badge names the worker, and a wrong tag or a missing reader says so',
      (tester) async {
        String? tag = 'EMP:$employeeId';
        await tester.binding.setSurfaceSize(const Size(800, 2000));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          host(
            PpeDeliveryScreen(
              repository: FakeHseRepository(),
              warehouseId: 'wh',
              readBadge: () async => tag,
            ),
          ),
        );

        await tester.tap(find.byKey(const Key('ppe-nfc')));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<TextField>(find.byKey(const Key('ppe-worker')))
              .controller
              ?.text,
          employeeId,
        );

        tag = 'PPE:$productId:LOT-1';
        await tester.tap(find.byKey(const Key('ppe-nfc')));
        await tester.pumpAndSettle();
        expect(find.text('This is not a worker badge'), findsOneWidget);

        tag = null;
        await tester.tap(find.byKey(const Key('ppe-nfc')));
        await tester.pumpAndSettle();
        expect(find.textContaining('No badge read'), findsOneWidget);
      },
    );

    testWidgets('a worker badge scanned in the box field names the worker', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        host(
          PpeDeliveryScreen(repository: FakeHseRepository(), warehouseId: 'wh'),
        ),
      );

      await tester.enterText(
        find.byKey(const Key('scan-input')),
        'EMP:$employeeId',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<TextField>(find.byKey(const Key('ppe-worker')))
            .controller
            ?.text,
        employeeId,
      );
    });
  });

  group('HseStrings', () {
    test('every locale defines every label', () {
      for (final entry in HseStrings.tables.entries) {
        expect(
          entry.value.keys.toSet(),
          H.values.toSet(),
          reason: 'labels missing in ${entry.key}',
        );
      }
    });

    test('picks the legal notice of the jurisdiction and the language of the locale', () {
      final german = HseStrings.forLocale(const Locale('de', 'CH'));
      final italian = HseStrings.forLocale(const Locale('it', 'IT'));

      expect(
        german.legalNotice(HseJurisdiction.switzerland),
        contains('Art. 5 und 90'),
      );
      expect(italian.legalNotice(HseJurisdiction.italy), contains('75-78'));
      expect(
        HseStrings.forLocale(const Locale('es')).t(H.ppeTitle),
        'PPE hand-over',
      );
      expect(
        fill('{count} waiting', <String, Object>{'count': 3}),
        '3 waiting',
      );
    });
  });

  group('SignatureController', () {
    test('records strokes and exports them as a payload', () {
      final controller = SignatureController();
      expect(controller.isEmpty, isTrue);

      controller
        ..startStroke(const Offset(1, 2))
        ..extendStroke(const Offset(3.04, 4.06));

      expect(controller.isEmpty, isFalse);
      expect(jsonDecode(controller.toPayload()), <dynamic>[
        <dynamic>[
          <dynamic>[1.0, 2.0],
          <dynamic>[3.0, 4.1],
        ],
      ]);

      controller.clear();
      expect(controller.isEmpty, isTrue);
    });

    testWidgets('exports a PNG only when something is drawn', (tester) async {
      final controller = SignatureController();

      await tester.runAsync(() async {
        expect(await controller.toPngBase64(), isNull);
        controller
          ..startStroke(const Offset(10, 10))
          ..extendStroke(const Offset(100, 80));
        final png = await controller.toPngBase64();

        expect(png, isNotNull);
        expect(base64Decode(png!).take(4), <int>[0x89, 0x50, 0x4E, 0x47]);
      });
    });
  });

  group('SyncEngineHseRepository', () {
    late AppDatabase db;
    late SyncEngine engine;
    late HseRepository repository;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      engine = SyncEngine(db, Dio(BaseOptions(baseUrl: 'http://x/api/v1')));
      repository = SyncEngineHseRepository(engine, tenantId: 't1');
    });

    tearDown(() => db.close());

    test(
      'stores every capture in the offline queue before any network call',
      () async {
        await repository.queuePpeHandOver(
          const PpeHandOver(
            employeeId: 'e1',
            productId: productId,
            warehouseId: 'w1',
            lotOrSerial: 'LOT-1',
            quantity: 1,
            signaturePayload: '[]',
            locale: 'it-CH',
          ),
        );
        await repository.queueToolBoxTalk(
          ToolBoxTalk(
            topic: 'Ladders',
            conductedAt: DateTime.utc(2027, 6, 15),
            attendances: const <ToolBoxAttendance>[],
          ),
        );
        await repository.queueNearMiss(
          NearMissReport(
            description: 'Oil',
            reportedAt: DateTime.utc(2027, 6, 15),
          ),
        );

        final rows = await db.select(db.syncQueue).get();

        expect(rows.map((r) => r.path), <String>[
          '/hse/ppe-distributions',
          '/hse/toolbox-talks',
          '/hse/incidents',
        ]);
        expect(rows.map((r) => r.entity), <String>[
          hsePpeEntity,
          hseToolBoxEntity,
          hseNearMissEntity,
        ]);
        expect(
          rows.every((r) => r.method == 'POST' && r.tenantId == 't1'),
          isTrue,
        );
        expect(jsonDecode(rows.first.payload!)['lot_or_serial_id'], 'LOT-1');
        expect(await repository.watchPending().first, 3);
      },
    );
  });

  group('screens', () {
    testWidgets('a near miss needs a description and is queued with its site', (
      tester,
    ) async {
      final repository = FakeHseRepository();
      await tester.pumpWidget(host(NearMissScreen(repository: repository)));

      await tester.tap(find.byKey(const Key('nm-send')));
      await tester.pump();
      expect(find.text('Describe what you saw'), findsOneWidget);
      expect(repository.reports, isEmpty);

      await tester.enterText(
        find.byKey(const Key('nm-what')),
        'Oil on the floor',
      );
      await tester.enterText(find.byKey(const Key('nm-where')), 'LUG-02');
      await tester.tap(find.byKey(const Key('nm-send')));
      await tester.pumpAndSettle();

      expect(repository.reports.single.siteTag, 'LUG-02');
      expect(find.textContaining('syncs as soon as'), findsOneWidget);
    });

    testWidgets(
      'a briefing is not sent without a signed worker, and a worker needs an id and a signature',
      (tester) async {
        final repository = FakeHseRepository();
        await tester.binding.setSurfaceSize(const Size(800, 1600));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          host(
            ToolBoxTalkScreen(
              repository: repository,
              supervisorEmployeeId: 'sup-1',
            ),
          ),
        );

        await tester.tap(find.byKey(const Key('tbt-finish')));
        await tester.pump();
        expect(find.text('At least one worker must sign'), findsOneWidget);

        await tester.tap(find.byKey(const Key('tbt-next')));
        await tester.pump();
        expect(find.text('Choose the worker first'), findsOneWidget);

        await tester.enterText(find.byKey(const Key('tbt-worker')), 'EMP-1');
        await tester.tap(find.byKey(const Key('tbt-next')));
        await tester.pump();
        expect(find.text('The worker must sign first'), findsOneWidget);
        expect(find.text('Signed: 0'), findsOneWidget);
        expect(repository.talks, isEmpty);
      },
    );

    testWidgets(
      'a worker who signed is counted and the briefing is queued with the signature and the supervisor',
      (tester) async {
        final repository = FakeHseRepository();
        await tester.binding.setSurfaceSize(const Size(800, 1600));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          host(
            ToolBoxTalkScreen(
              repository: repository,
              supervisorEmployeeId: 'sup-1',
            ),
          ),
        );

        await tester.enterText(
          find.byKey(const Key('tbt-topic')),
          'Ladder safety',
        );
        await tester.enterText(find.byKey(const Key('tbt-worker')), 'EMP-1');
        final pad = tester.getRect(find.byType(SignaturePad));
        await tester.dragFrom(pad.center, const Offset(80, 30));
        await tester.runAsync(() async {
          await tester.tap(find.byKey(const Key('tbt-next')));
          await Future<void>.delayed(const Duration(milliseconds: 200));
        });
        await tester.pump();
        expect(find.text('Signed: 1'), findsOneWidget);

        await tester.tap(find.byKey(const Key('tbt-finish')));
        await tester.pumpAndSettle();

        expect(repository.talks.single.supervisorEmployeeId, 'sup-1');
        expect(repository.talks.single.attendances.single.employeeId, 'EMP-1');
        expect(
          repository.talks.single.attendances.single.signaturePayload,
          isNot('[]'),
        );
      },
    );
  });
}
