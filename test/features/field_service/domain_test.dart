import 'dart:convert';
import 'dart:ui' show Offset, Locale;

import 'package:fattura_facile/features/field_service/domain/coverage_policy.dart';
import 'package:fattura_facile/features/field_service/domain/scan_codes.dart';
import 'package:fattura_facile/features/field_service/domain/signature_svg.dart';
import 'package:fattura_facile/features/field_service/domain/site_navigation.dart';
import 'package:fattura_facile/features/field_service/l10n/field_service_strings.dart';
import 'package:fattura_facile/features/field_service/models/field_service_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

FsmWorkOrder order({
  String workType = 'corrective',
  CoverageType? coverage,
  bool active = true,
  bool withContract = true,
}) {
  final Map<String, dynamic> json = workOrderJson(
    workType: workType,
    contract: withContract ? contractId : null,
    extra: <String, dynamic>{
      if (withContract && coverage != null)
        'service_contract': <String, dynamic>{
          'id': contractId,
          'coverage_type': coverage.wire,
          'status': active ? 'active' : 'expired',
        },
    },
  );
  return FsmWorkOrder.fromJson(json);
}

ServiceReportDraft draft({
  String summary = 'Done',
  double labor = 1,
  String signer = 'Mario Rossi',
  String svg = drawnSvg,
  List<ChecklistEntry> checklist = const <ChecklistEntry>[],
  String locale = 'en',
}) => ServiceReportDraft(
  workPerformedSummary: summary,
  laborHours: labor,
  signerName: signer,
  signatureSvg: svg,
  signedAt: DateTime.utc(2030, 1, 1, 10),
  checklist: checklist,
  locale: locale,
);

void main() {
  group('FsmStatus', () {
    test('wire values and journey rank match the server', () {
      expect(FsmStatus.fromWire('en_route'), FsmStatus.enRoute);
      expect(FsmStatus.fromWire('on_site'), FsmStatus.onSite);
      expect(FsmStatus.fromWire('nope'), FsmStatus.unknown);
      expect(FsmStatus.fromWire(null), FsmStatus.unknown);
      expect(
        <int>[
          FsmStatus.dispatched.rank,
          FsmStatus.enRoute.rank,
          FsmStatus.onSite.rank,
          FsmStatus.inProgress.rank,
          FsmStatus.completed.rank,
          FsmStatus.invoiced.rank,
        ],
        <int>[0, 1, 2, 3, 3, 3],
      );
    });

    test('the technician journey is dispatched, en route, on site', () {
      expect(FsmStatus.dispatched.nextStep, FsmStatus.enRoute);
      expect(FsmStatus.enRoute.nextStep, FsmStatus.onSite);
      expect(FsmStatus.onSite.nextStep, isNull);
      expect(FsmStatus.dispatched.canMoveTo(FsmStatus.onSite), isTrue);
      expect(FsmStatus.enRoute.canMoveTo(FsmStatus.enRoute), isFalse);
      expect(FsmStatus.onSite.canMoveTo(FsmStatus.enRoute), isFalse);
      expect(FsmStatus.dispatched.canMoveTo(FsmStatus.completed), isFalse);
      expect(FsmStatus.completed.isOpen, isFalse);
      expect(FsmStatus.inProgress.isOpen, isTrue);
    });
  });

  group('bundle parsing', () {
    test(
      'reads the offline bundle shape of GetTechnicianOfflineWorkQueueQuery',
      () {
        final OfflineBundle b = OfflineBundle.fromJson(bundleJson());

        expect(b.serverTime, '2030-01-01T08:00:00+00:00');
        expect(b.technician.name, 'Tina Technician');
        expect(b.technician.vanWarehouseId, isNotNull);
        expect(b.openWorkOrderIds, <String>[woCorrective, woWarranty]);

        final FsmWorkOrder wo = b.workOrders.first;
        expect(wo.number, 'WO-0001');
        expect(wo.status, FsmStatus.dispatched);
        expect(wo.checklistTemplate, <String>[
          'fault_diagnosis',
          'repair_verified',
          'functional_test',
        ]);
        expect(wo.site.address, 'Via Nassa 5, Lugano');
        expect(wo.site.latitude, closeTo(46.00321, 1e-9));
        expect(wo.scheduledStart, DateTime.utc(2030, 1, 2, 7));

        final FsmEquipment eq = b.equipment.single;
        expect(eq.serialNumber, 'SN-4711');
        expect(
          eq.siteLatitude,
          closeTo(46.00321, 1e-9),
          reason: 'decimal strings are read as numbers',
        );
        expect(eq.operatingHours, 1200.5);
        expect(eq.cycleCount, 300);
        expect(eq.history.single.reportNumber, 'SR-2029-0001');
        expect(eq.history.single.meterCycles, 280);

        expect(b.vanStock.map((VanStockItem v) => v.sku), <String>[
          'FLT-1',
          'OIL-1',
        ]);
        expect(b.vanStock.first.unitPrice, 25);
        expect(b.customers.single.name, 'Rossi SA');
      },
    );

    test('a work order survives the store round trip', () {
      final FsmWorkOrder wo = order(coverage: CoverageType.fullComprehensive);
      final FsmWorkOrder again = FsmWorkOrder.fromJson(
        jsonDecode(jsonEncode(wo.toJson())) as Map<String, dynamic>,
      );

      expect(again.id, wo.id);
      expect(again.site.address, wo.site.address);
      expect(again.contract?.type, CoverageType.fullComprehensive);
      expect(again.checklistTemplate, wo.checklistTemplate);
      expect(again.scheduledStart, wo.scheduledStart);
      expect(again.copyWith(status: FsmStatus.onSite).status, FsmStatus.onSite);
    });

    test('a site without coordinates takes the equipment site', () {
      const FsmSite wo = FsmSite(address: 'Via Roma 1');
      const FsmSite eq = FsmSite(
        address: 'Other',
        latitude: 46.0,
        longitude: 8.9,
      );
      final FsmSite merged = wo.orElse(eq);

      expect(merged.address, 'Via Roma 1');
      expect(merged.hasCoordinates, isTrue);
      expect(const FsmSite().isEmpty, isTrue);
      expect(
        FsmSite.fromJson(<String, dynamic>{'address': '  '}).isEmpty,
        isTrue,
      );
    });

    test('sync results carry the status, errors and extras', () {
      final FsmSyncResult ok = FsmSyncResult.fromJson(<String, dynamic>{
        'client_uuid': 'u',
        'type': 'service_report',
        'status': 'duplicate',
        'report_number': 'SR-1',
      });
      expect(ok.duplicate, isTrue);
      expect(ok.extra, <String, dynamic>{'report_number': 'SR-1'});

      final FsmSyncResult bad = FsmSyncResult.fromJson(<String, dynamic>{
        'client_uuid': 'u',
        'status': 'rejected',
        'errors': <String, dynamic>{
          'work_order': <String>['report_exists'],
        },
      });
      expect(bad.rejected, isTrue);
      expect(bad.errors['work_order'], <String>['report_exists']);
    });
  });

  group('CoveragePolicy', () {
    const CoveragePolicy policy = CoveragePolicy();

    bool labor(FsmWorkOrder w) => policy.coversLabor(w);
    bool parts(FsmWorkOrder w) => policy.coversParts(w);
    bool travel(FsmWorkOrder w) => policy.coversTravelAndCallout(w);

    test('warranty work orders are covered in full, contract or not', () {
      final FsmWorkOrder w = order(workType: 'warranty', withContract: false);
      expect(<bool>[labor(w), parts(w), travel(w)], <bool>[true, true, true]);
    });

    test('no contract, an expired contract or none covers nothing', () {
      expect(policy.summary(order(withContract: false)).coversNothing, isTrue);
      final FsmWorkOrder expired = order(
        coverage: CoverageType.fullComprehensive,
        active: false,
      );
      expect(policy.summary(expired).coversNothing, isTrue);
    });

    test('labor_only covers labor but not parts, travel or call-out', () {
      final FsmWorkOrder w = order(coverage: CoverageType.laborOnly);
      expect(<bool>[labor(w), parts(w), travel(w)], <bool>[true, false, false]);
    });

    test(
      'parts_and_labor covers labor and parts but not travel or call-out',
      () {
        final FsmWorkOrder w = order(coverage: CoverageType.partsAndLabor);
        expect(
          <bool>[labor(w), parts(w), travel(w)],
          <bool>[true, true, false],
        );
      },
    );

    test('preventive_only covers preventive work orders like parts_and_labor and corrective ones not at all', () {
      final FsmWorkOrder preventive = order(
        workType: 'preventive',
        coverage: CoverageType.preventiveOnly,
      );
      final FsmWorkOrder corrective = order(
        coverage: CoverageType.preventiveOnly,
      );
      expect(
        <bool>[labor(preventive), parts(preventive), travel(preventive)],
        <bool>[true, true, false],
      );
      expect(
        <bool>[labor(corrective), parts(corrective), travel(corrective)],
        <bool>[false, false, false],
      );
    });

    test('full_comprehensive covers everything', () {
      final FsmWorkOrder w = order(coverage: CoverageType.fullComprehensive);
      expect(<bool>[labor(w), parts(w), travel(w)], <bool>[true, true, true]);
    });

    test('a bundle with only the contract id gets the server defaults, flagged as an estimate', () {
      final FsmWorkOrder w = order();
      expect(w.contract?.assumed, isTrue);
      expect(w.contract?.type, CoverageType.partsAndLabor);
      final CoverageSummary s = policy.summary(w);
      expect(
        <bool>[s.labor, s.parts, s.travelAndCallout],
        <bool>[true, true, false],
      );
      expect(s.estimated, isTrue);
      expect(
        policy.summary(order(coverage: CoverageType.laborOnly)).estimated,
        isFalse,
      );
    });

    test('flat contract keys are understood too', () {
      final ContractCoverage? c = ContractCoverage.fromWorkOrderJson(
        <String, dynamic>{
          'service_contract_id': contractId,
          'contract_coverage_type': 'labor_only',
          'contract_status': 'active',
        },
      );
      expect(c?.type, CoverageType.laborOnly);
      expect(c?.assumed, isFalse);
      expect(ContractCoverage.fromWorkOrderJson(<String, dynamic>{}), isNull);
    });
  });

  group('SiteNavigation', () {
    test(
      'coordinates give a geo pin with the label and a web directions link',
      () {
        const FsmSite site = FsmSite(
          address: 'Via Nassa 5',
          latitude: 46.00321,
          longitude: 8.95123,
        );

        expect(
          SiteNavigation.geoUri(site, label: 'WO 1')?.toString(),
          'geo:46.003210,8.951230?q=46.003210,8.951230(WO%201)',
        );
        final Uri web = SiteNavigation.webUri(site)!;
        expect(web.host, 'www.google.com');
        expect(web.queryParameters['destination'], '46.003210,8.951230');
        expect(web.queryParameters['api'], '1');
      },
    );

    test('an address alone is searched', () {
      const FsmSite site = FsmSite(address: 'Via Nassa 5, Lugano');

      expect(
        SiteNavigation.geoUri(site)?.toString(),
        startsWith('geo:0,0?q=Via'),
      );
      expect(
        SiteNavigation.webUri(site)?.queryParameters['destination'],
        'Via Nassa 5, Lugano',
      );
    });

    test('an empty site gives nothing; Android tries geo first, others only the web link', () {
      expect(SiteNavigation.geoUri(const FsmSite()), isNull);
      expect(SiteNavigation.webUri(const FsmSite()), isNull);
      expect(
        SiteNavigation.candidates(const FsmSite(), android: true),
        isEmpty,
      );

      const FsmSite site = FsmSite(latitude: 1, longitude: 2);
      expect(
        SiteNavigation.candidates(site, android: true).map((Uri u) => u.scheme),
        <String>['geo', 'https'],
      );
      expect(
        SiteNavigation.candidates(
          site,
          android: false,
        ).map((Uri u) => u.scheme),
        <String>['https'],
      );
    });
  });

  group('scan codes', () {
    const FsmEquipment eq = FsmEquipment(id: 'e', serialNumber: 'SN-4711');

    test('an asset label is the bare serial or SN:/ASSET: prefixed, case-insensitive', () {
      expect(AssetScan.serialOf('SN: SN-4711 '), 'SN-4711');
      expect(AssetScan.serialOf('asset:X1'), 'X1');
      expect(AssetScan.serialOf('FOO:BAR'), 'FOO:BAR');
      expect(AssetScan.matches('sn:sn-4711', eq), isTrue);
      expect(AssetScan.matches('SN-4711', eq), isTrue);
      expect(AssetScan.matches('SN-0000', eq), isFalse);
      expect(AssetScan.matches('  ', eq), isFalse);
    });

    test('a part label is PART:<product or sku>[:<lot>] or a bare product', () {
      expect(PartScan.parse('PART:FLT-1:LOT-9')?.key, 'FLT-1');
      expect(PartScan.parse('PART:FLT-1:LOT-9')?.lotNumber, 'LOT-9');
      expect(PartScan.parse('part:FLT-1:A:B')?.lotNumber, 'A:B');
      expect(PartScan.parse('FLT-1')?.lotNumber, isNull);
      expect(PartScan.parse('PART:'), isNull);
      expect(PartScan.parse(' '), isNull);
      expect(PartScan.parse('PART:X:${'L' * 80}')?.lotNumber, hasLength(60));
    });

    test('a scanned part resolves against the van by sku or product id', () {
      final List<VanStockItem> van = OfflineBundle.fromJson(bundleJson())
          .vanStock;

      expect(
        PartScan.parse('PART:flt-1')?.resolve(van)?.productId,
        productFilter,
      );
      expect(PartScan.parse(productOil)?.resolve(van)?.sku, 'OIL-1');
      expect(PartScan.parse('PART:UNKNOWN')?.resolve(van), isNull);
    });
  });

  group('signature', () {
    test('strokes become a plain vector SVG the API accepts', () {
      final String svg = SignatureSvg.fromStrokes(<List<Offset>>[
        <Offset>[const Offset(10, 10), const Offset(50.26, 40.04)],
        <Offset>[const Offset(70, 70)],
      ])!;

      expect(svg, startsWith('<svg '));
      expect(svg, endsWith('</svg>'));
      expect(svg, contains('d="M10.0 10.0 L50.3 40.0"'));
      expect(svg, contains('<circle cx="70.0" cy="70.0"'));
      expect(svg, contains('viewBox="0 0 480.0 180.0"'));
      // The server refuses scripts and event attributes: the regexes of SignServiceReportRules.
      expect(
        RegExp(r'^\s*<svg[\s>]', caseSensitive: false).hasMatch(svg),
        isTrue,
      );
      expect(
        RegExp(
          r'''<\s*script|[\s"']on[a-z]+\s*=|javascript:''',
          caseSensitive: false,
        ).hasMatch(svg),
        isFalse,
      );
      expect(draft(svg: svg).validate(), isEmpty);
    });

    test('nothing drawn gives no signature', () {
      expect(SignatureSvg.fromStrokes(const <List<Offset>>[]), isNull);
      expect(SignatureSvg.fromStrokes(<List<Offset>>[<Offset>[]]), isNull);
    });

    test('a very long signature is thinned under the server size limit', () {
      final List<Offset> points = <Offset>[
        for (var i = 0; i < 60000; i++)
          Offset((i % 480).toDouble(), (i % 180).toDouble() + 0.5),
      ];
      final String svg = SignatureSvg.fromStrokes(<List<Offset>>[points])!;

      expect(
        utf8.encode(svg).length,
        lessThanOrEqualTo(ServiceReportDraft.svgMaxBytes),
      );
      expect(svg, startsWith('<svg'));
    });

    test('the SHA-256 is the lower-case hex digest of the SVG text', () {
      // Known answer: SHA-256("abc").
      expect(
        SignatureSvgHash.sha256Hex('abc'),
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
      );
      expect(SignatureSvgHash.sha256Hex(drawnSvg), hasLength(64));
      expect(
        SignatureSvgHash.sha256Hex(drawnSvg),
        isNot(SignatureSvgHash.sha256Hex('$drawnSvg ')),
      );
      expect(
        SignatureSvgHash.sha256Hex(drawnSvg),
        SignatureSvgHash.sha256Hex(drawnSvg),
      );
    });
  });

  group('ServiceReportDraft', () {
    test('a complete report passes the local rules', () {
      expect(draft().validate(), isEmpty);
    });

    test('mirrors SignServiceReportRules', () {
      expect(
        draft(summary: '  ').validate()['work_performed_summary'],
        'required',
      );
      expect(
        draft(summary: 'x' * 5001).validate()['work_performed_summary'],
        'max',
      );
      expect(draft(labor: -1).validate()['labor_hours'], 'range');
      expect(draft(labor: 1000).validate()['labor_hours'], 'range');
      expect(draft(signer: '').validate()['customer_signer_name'], 'required');
      expect(draft(svg: 'not svg').validate()['signature_svg'], 'required');
      expect(
        draft(svg: '<svg><script>alert(1)</script></svg>')
            .validate()['signature_svg'],
        'required',
      );
      expect(
        draft(svg: '<svg onload="x()"></svg>').validate()['signature_svg'],
        'required',
      );
      expect(draft(locale: 'es-ES').validate()['locale'], 'invalid');
      expect(
        draft(checklist: const <ChecklistEntry>[ChecklistEntry(item: 'a')])
            .validate()['checklist'],
        'unanswered',
      );
      expect(
        ServiceReportDraft(
          workPerformedSummary: 's',
          laborHours: 1,
          signerName: 'n',
          signatureSvg: drawnSvg,
          signedAt: DateTime.utc(2030),
          travelKm: 100000,
          travelHours: 1000,
          latitude: 91,
          longitude: -181,
        ).validate().keys,
        containsAll(<String>[
          'travel_km',
          'travel_hours',
          'gps_latitude',
          'gps_longitude',
        ]),
      );
    });

    test('the payload has exactly the fields of the API rules', () {
      final ServiceReportDraft d = ServiceReportDraft(
        workPerformedSummary: ' Replaced capacitor ',
        laborHours: 1.5,
        travelHours: 0.5,
        travelKm: 24,
        applyCalloutFee: true,
        meterReadingHours: 1210,
        meterReadingCycles: 305,
        signerName: ' Mario Rossi ',
        signerRole: 'Manager',
        signatureSvg: drawnSvg,
        signedAt: DateTime.utc(2030, 1, 1, 10),
        latitude: 46.0,
        longitude: 8.9,
        locale: 'de-CH',
        checklist: const <ChecklistEntry>[
          ChecklistEntry(item: 'fault_diagnosis', result: ChecklistResult.pass),
          ChecklistEntry(
            item: 'functional_test',
            result: ChecklistResult.fail,
            notes: ' leak ',
          ),
        ],
        photos: <ReportPhoto>[
          ReportPhoto(
            id: 'p1',
            path: 'fsm/wo/a.jpg',
            name: 'a.jpg',
            takenAt: DateTime.utc(2030, 1, 1, 9),
          ),
        ],
      );
      final Map<String, dynamic> p = d.toPayload();

      expect(p['work_performed_summary'], 'Replaced capacitor');
      expect(p['customer_signer_name'], 'Mario Rossi');
      expect(p['signed_at'], '2030-01-01T10:00:00.000Z');
      expect(p['locale'], 'de-CH');
      expect(p['checklist'], <Map<String, dynamic>>[
        <String, dynamic>{'item': 'fault_diagnosis', 'result': 'pass'},
        <String, dynamic>{
          'item': 'functional_test',
          'result': 'fail',
          'notes': 'leak',
        },
      ]);
      expect(p['photos'], <Map<String, dynamic>>[
        <String, dynamic>{
          'path': 'fsm/wo/a.jpg',
          'name': 'a.jpg',
          'taken_at': '2030-01-01T09:00:00.000Z',
        },
      ]);
      const Set<String> allowed = <String>{
        'client_uuid',
        'work_performed_summary',
        'checklist',
        'labor_hours',
        'travel_hours',
        'travel_km',
        'apply_callout_fee',
        'meter_reading_hours',
        'meter_reading_cycles',
        'customer_signer_name',
        'customer_signer_role',
        'signature_svg',
        'signed_at',
        'gps_latitude',
        'gps_longitude',
        'photos',
        'locale',
      };
      expect(p.keys.toSet().difference(allowed), isEmpty);
      expect(
        p.keys,
        containsAll(<String>[
          'work_performed_summary',
          'labor_hours',
          'customer_signer_name',
          'signature_svg',
          'signed_at',
        ]),
      );
    });

    test('optional fields are left out when empty', () {
      final Map<String, dynamic> p = draft().toPayload();
      expect(p.containsKey('photos'), isFalse);
      expect(p.containsKey('meter_reading_hours'), isFalse);
      expect(p.containsKey('customer_signer_role'), isFalse);
      expect(p.containsKey('gps_latitude'), isFalse);
    });
  });

  group('part lines', () {
    test('covered lines are chargeable at zero, others at list price', () {
      final FsmPartLine covered = FsmPartLine(
        clientUuid: 'u',
        workOrderId: 'w',
        productId: 'p',
        sku: 'S',
        name: 'N',
        quantity: 2,
        unitPrice: 25,
        covered: true,
        createdAt: DateTime.utc(2030),
      );
      final FsmPartLine billable = FsmPartLine(
        clientUuid: 'u2',
        workOrderId: 'w',
        productId: 'p',
        sku: 'S',
        name: 'N',
        quantity: 2,
        unitPrice: 25,
        covered: false,
        createdAt: DateTime.utc(2030),
        lotNumber: 'L1',
      );

      expect(covered.chargeable, 0);
      expect(billable.chargeable, 50);
      expect(billable.toPayload(), <String, dynamic>{
        'product_id': 'p',
        'quantity': 2.0,
        'unit_price': 25.0,
        'lot_number': 'L1',
      });
      expect(FsmPartLine.fromJson(billable.toJson()).lotNumber, 'L1');
    });
  });

  group('FieldServiceStrings', () {
    test('every locale has every label', () {
      expect(FieldServiceStrings.tables.keys.toSet(), fsmReportLocales.toSet());
      for (final MapEntry<String, Map<FsmText, String>> table
          in FieldServiceStrings.tables.entries) {
        for (final FsmText key in FsmText.values) {
          expect(
            table.value[key],
            isNotNull,
            reason: '${table.key} misses $key',
          );
          expect(
            table.value[key]!.trim(),
            isNotEmpty,
            reason: '${table.key} $key is empty',
          );
        }
      }
    });

    test('placeholders are the same in every locale', () {
      final RegExp placeholder = RegExp(r'\{[a-z]+\}');
      for (final FsmText key in FsmText.values) {
        final Set<String> english = placeholder
            .allMatches(FieldServiceStrings.tables['en']![key]!)
            .map((RegExpMatch m) => m.group(0)!)
            .toSet();
        for (final MapEntry<String, Map<FsmText, String>> table
            in FieldServiceStrings.tables.entries) {
          final Set<String> found = placeholder
              .allMatches(table.value[key]!)
              .map((RegExpMatch m) => m.group(0)!)
              .toSet();
          expect(found, english, reason: '${table.key} $key');
        }
      }
    });

    test('the app language picks the locale table', () {
      expect(FieldServiceStrings.tagOf(const Locale('it')), 'it-IT');
      expect(FieldServiceStrings.tagOf(const Locale('it', 'CH')), 'it-CH');
      expect(FieldServiceStrings.tagOf(const Locale('de')), 'de-CH');
      expect(FieldServiceStrings.tagOf(const Locale('fr')), 'fr-CH');
      expect(FieldServiceStrings.tagOf(const Locale('en', 'GB')), 'en');
      expect(FieldServiceStrings.tagOf(const Locale('es')), 'en');
      for (final String tag in fsmReportLocales) {
        expect(fsmReportLocales, contains(tag));
      }
    });

    test('the field service vocabulary is the agreed one', () {
      String t(String tag, FsmText key) =>
          FieldServiceStrings.tables[tag]![key]!;

      expect(t('it-IT', FsmText.reportTitle), 'Rapportino d’Intervento');
      expect(t('de-CH', FsmText.reportTitle), 'Servicerapport');
      expect(t('fr-CH', FsmText.reportTitle), 'Rapport d’intervention');
      expect(t('en', FsmText.reportTitle), 'Service Report');

      expect(t('it-IT', FsmText.calloutFee), 'Diritto fisso di chiamata');
      expect(t('it-CH', FsmText.calloutFee), 'Diritto fisso di chiamata');
      expect(t('de-CH', FsmText.calloutFee), 'Anfahrtspauschale');
      expect(t('fr-CH', FsmText.calloutFee), 'Frais de déplacement');
      expect(t('en', FsmText.calloutFee), 'Call-out fee');

      expect(t('it-IT', FsmText.laborHours), 'Ore lavorate');
      expect(t('de-CH', FsmText.laborHours), 'Arbeitsstunden');
      expect(t('fr-CH', FsmText.laborHours), 'Heures de travail');
      expect(t('en', FsmText.laborHours), 'Labor hours');

      expect(t('it-IT', FsmText.travelHours), contains('trasferta'));
      expect(t('de-CH', FsmText.travelHours), contains('Reisezeit'));
      expect(t('fr-CH', FsmText.travelHours), contains('déplacement'));
      expect(t('en', FsmText.travelKm), 'Travel km');

      expect(t('it-IT', FsmText.covered), 'Coperto');
      expect(t('en', FsmText.chargeable), 'Chargeable');
      expect(t('it-CH', FsmText.currencyNote), contains('CHF'));
      expect(t('it-IT', FsmText.currencyNote), contains('EUR'));
    });

    test('status, type and checklist labels fall back to the sent text', () {
      final FieldServiceStrings en = FieldServiceStrings.forLocale(
        const Locale('en'),
      );

      expect(en.status(FsmStatus.enRoute), 'En route');
      expect(en.status(FsmStatus.completed), 'Completed');
      expect(en.workType('warranty'), 'Warranty');
      expect(en.workType('other'), 'other');
      expect(en.checklistItem('lubrication'), 'Lubrication');
      expect(en.checklistItem('custom_point'), 'custom_point');
      expect(
        en.error('quantity', 'insufficient_stock'),
        'Not enough on the van',
      );
      expect(en.error('labor_hours', 'required'), contains('Labor hours'));
      expect(
        fill('{count} of {max}', <String, Object>{'count': 1, 'max': 3}),
        '1 of 3',
      );
    });
  });

  group('photo upload model', () {
    test('the upload payload carries the file name, capture time, stage and trimmed caption', () {
      final ReportPhoto photo = ReportPhoto(
        id: 'p1',
        path: 'fsm/x/a.jpg',
        name: 'a.jpg',
        takenAt: DateTime.utc(2030, 1, 2, 3),
        localPath: '/data/a.jpg',
        stage: FsmPhotoStage.during,
        caption: ' belt ',
      );

      expect(photo.toUploadPayload(), <String, dynamic>{
        'local_path': '/data/a.jpg',
        'name': 'a.jpg',
        'captured_at': '2030-01-02T03:00:00.000Z',
        'stage': 'during',
        'caption': 'belt',
      });
      expect(photo.upload, FsmPhotoUpload.queued);
      expect(
        ReportPhoto(
          id: 'p2',
          path: 'x',
          name: 'b.jpg',
          takenAt: DateTime.utc(2030),
          localPath: '/b',
          caption: '  ',
        ).toUploadPayload().keys,
        <String>['local_path', 'name', 'captured_at'],
      );
    });

    test('stages and the operation type round-trip their wire values', () {
      expect(FsmPhotoStage.fromWire('after'), FsmPhotoStage.after);
      expect(FsmPhotoStage.fromWire('later'), isNull);
      expect(FsmPhotoStage.fromWire(null), isNull);
      expect(
        FsmOperationType.fromWire('photo_upload'),
        FsmOperationType.photoUpload,
      );
    });
  });
}
