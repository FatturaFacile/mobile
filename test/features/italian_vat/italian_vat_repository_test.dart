import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:fattura_facile/core/database/app_database.dart';
import 'package:fattura_facile/core/sync/sync_engine.dart';
import 'package:fattura_facile/features/general_ledger/domain/gl_amount.dart';
import 'package:fattura_facile/features/italian_vat/data/italian_vat_repository_impl.dart';
import 'package:fattura_facile/features/italian_vat/domain/italian_vat_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/sync_engine_test.dart' show FakeAdapter, json;
import 'fixtures.dart';

Never offline(RequestOptions o) =>
    throw DioException.connectionError(requestOptions: o, reason: 'down');

ResponseBody problem(int status, String detail) =>
    json(status, <String, dynamic>{'detail': detail});

IntentLetterDraft draft({
  String customer = 'Export Srl',
  String protocol = '12345678901234567-000001',
}) => IntentLetterDraft(
  customerName: customer,
  protocol: protocol,
  authorized: amountFromJson('50000.00'),
  validFrom: DateTime(2027),
  validTo: DateTime(2027, 12, 31),
);

void main() {
  late AppDatabase db;
  late FakeAdapter adapter;
  late Dio dio;
  late ItalianVatRepositoryImpl repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    adapter = FakeAdapter(
      (RequestOptions o) => json(200, envelope(<dynamic>[])),
    );
    dio = Dio(
      BaseOptions(
        baseUrl: 'http://x/api/v1',
        validateStatus: (int? s) => s != null && s < 300,
      ),
    )..httpClientAdapter = adapter;
    repo = ItalianVatRepositoryImpl(db, dio, SyncEngine(db, dio));
  });

  tearDown(() => db.close());

  final DateTime from = DateTime(2027);
  final DateTime to = DateTime(2027, 3, 31);

  group('registers', () {
    test(
      'refresh asks for the register of the period and keeps an offline copy',
      () async {
        adapter.handler = (RequestOptions o) => json(
          200,
          registerBody(
            <Map<String, dynamic>>[lineJson(protocol: 4, sectional: 'D')],
            meta: <String, dynamic>{
              'pro_rata_percent': '70.00',
              'lock': <String, dynamic>{'definitive': true},
            },
          ),
        );

        final VatRegister fresh = await repo.refreshRegister(
          't1',
          VatRegisterType.purchases,
          from,
          to,
        );

        expect(
          adapter.calls.single.path,
          '/general-ledger/vat-registers/purchases',
        );
        expect(adapter.calls.single.queryParameters, <String, dynamic>{
          'from': '2027-01-01',
          'to': '2027-03-31',
        });
        expect(fresh.lines.single.protocolNumber, 4);

        adapter.handler = offline;
        final VatRegister? cached = await repo.cachedRegister(
          't1',
          VatRegisterType.purchases,
          from,
          to,
        );
        expect(cached, isNotNull);
        expect(cached!.proRata, amountFromJson('70.00'));
        expect(cached.lock.definitive, isTrue);
        expect(cached.lines.single.sectional, 'D');
      },
    );

    test(
      'every register type and period has its own copy, scoped to the tenant',
      () async {
        adapter.handler = (RequestOptions o) =>
            json(200, registerBody(<Map<String, dynamic>>[lineJson()]));
        await repo.refreshRegister('t1', VatRegisterType.sales, from, to);

        expect(
          await repo.cachedRegister('t1', VatRegisterType.purchases, from, to),
          isNull,
        );
        expect(
          await repo.cachedRegister(
            't1',
            VatRegisterType.sales,
            from,
            DateTime(2027, 12, 31),
          ),
          isNull,
        );
        expect(
          await repo.cachedRegister('t2', VatRegisterType.sales, from, to),
          isNull,
        );
        expect(
          await repo.cachedRegister('t1', VatRegisterType.sales, from, to),
          isNotNull,
        );
      },
    );

    test('the new register types use their own path segment', () async {
      adapter.handler = (RequestOptions o) =>
          json(200, registerBody(const <Map<String, dynamic>>[]));
      await repo.refreshRegister(
        't1',
        VatRegisterType.thirdPartyGoods,
        from,
        to,
      );
      await repo.refreshRegister('t1', VatRegisterType.receipts, from, to);

      expect(adapter.calls.map((RequestOptions c) => c.path), <String>[
        '/general-ledger/vat-registers/third-party-goods',
        '/general-ledger/vat-registers/receipts',
      ]);
    });

    test(
      'a dead network is reported as offline and leaves the copy untouched',
      () async {
        adapter.handler = (RequestOptions o) =>
            json(200, registerBody(<Map<String, dynamic>>[lineJson()]));
        await repo.refreshRegister('t1', VatRegisterType.sales, from, to);

        adapter.handler = offline;
        await expectLater(
          repo.refreshRegister('t1', VatRegisterType.sales, from, to),
          throwsA(
            isA<ItalianVatException>().having(
              (ItalianVatException e) => e.kind,
              'kind',
              ItalianVatErrorKind.offline,
            ),
          ),
        );
        expect(
          (await repo.cachedRegister(
            't1',
            VatRegisterType.sales,
            from,
            to,
          ))!.lines,
          hasLength(1),
        );
      },
    );

    test(
      'maps the status codes to error kinds and keeps the problem detail',
      () async {
        adapter.handler = (RequestOptions o) => problem(403, 'No ledger right');
        await expectLater(
          repo.refreshRegister('t1', VatRegisterType.sales, from, to),
          throwsA(
            isA<ItalianVatException>()
                .having(
                  (ItalianVatException e) => e.kind,
                  'kind',
                  ItalianVatErrorKind.forbidden,
                )
                .having(
                  (ItalianVatException e) => e.detail,
                  'detail',
                  'No ledger right',
                ),
          ),
        );
        adapter.handler = (RequestOptions o) => problem(422, 'Bad period');
        await expectLater(
          repo.refreshRegister('t1', VatRegisterType.sales, from, to),
          throwsA(
            isA<ItalianVatException>().having(
              (ItalianVatException e) => e.kind,
              'kind',
              ItalianVatErrorKind.invalid,
            ),
          ),
        );
        adapter.handler = (RequestOptions o) => problem(500, 'boom');
        await expectLater(
          repo.refreshRegister('t1', VatRegisterType.sales, from, to),
          throwsA(
            isA<ItalianVatException>().having(
              (ItalianVatException e) => e.kind,
              'kind',
              ItalianVatErrorKind.unknown,
            ),
          ),
        );
      },
    );
  });

  group('letters of intent', () {
    test('refresh stores the letters, the one valid longest first', () async {
      adapter.handler = (RequestOptions o) => json(
        200,
        envelope(<Map<String, dynamic>>[
          letterJson(id: 'a', validTo: '2027-06-30'),
          letterJson(id: 'b', validTo: '2027-12-31'),
        ]),
      );

      final List<IntentLetter> fresh = await repo.refreshLetters('t1');

      expect(adapter.calls.single.path, '/vat/intent-letters');
      expect(fresh.map((IntentLetter l) => l.id), <String>['b', 'a']);
      adapter.handler = offline;
      expect(
        (await repo.cachedLetters('t1')).map((IntentLetter l) => l.id),
        <String>['b', 'a'],
      );
    });

    test('a paginated answer is read too', () async {
      adapter.handler = (RequestOptions o) => json(
        200,
        envelope(<String, dynamic>{
          'data': <Map<String, dynamic>>[letterJson()],
        }),
      );

      expect(await repo.refreshLetters('t1'), hasLength(1));
    });

    test(
      'an online create posts the letter and leaves nothing waiting',
      () async {
        adapter.handler = (RequestOptions o) =>
            json(201, envelope(letterJson(id: 'srv-1')));

        final ActionOutcome outcome = await repo.createLetter('t1', draft());

        expect(outcome.status, ActionStatus.sent);
        final RequestOptions call = adapter.calls.single;
        expect(call.method, 'POST');
        expect(call.path, '/vat/intent-letters');
        expect(call.headers['Idempotency-Key'], isNotNull);
        final Map<String, dynamic> body = Map<String, dynamic>.from(
          call.data as Map<dynamic, dynamic>,
        );
        expect(body['protocol'], '12345678901234567-000001');
        expect(body['authorized_amount'], '50000.0000');
        expect(await repo.pendingActions('t1'), isEmpty);
      },
    );

    test(
      'once the server lists the letter the local placeholder disappears',
      () async {
        adapter.handler = (RequestOptions o) =>
            json(201, envelope(letterJson(id: 'srv-1')));
        await repo.createLetter('t1', draft());
        expect((await repo.cachedLetters('t1')).single.pending, isTrue);

        adapter.handler = (RequestOptions o) => json(
          200,
          envelope(<Map<String, dynamic>>[letterJson(id: 'srv-1')]),
        );
        final List<IntentLetter> fresh = await repo.refreshLetters('t1');

        expect(fresh.single.id, 'srv-1');
        expect(fresh.single.pending, isFalse);
      },
    );

    test(
      'offline the letter is kept locally as pending and queued once',
      () async {
        adapter.handler = offline;

        final ActionOutcome outcome = await repo.createLetter('t1', draft());

        expect(outcome.status, ActionStatus.queued);
        final List<IntentLetter> local = await repo.cachedLetters('t1');
        expect(local.single.pending, isTrue);
        expect(local.single.remaining, amountFromJson('50000.00'));
        final List<PendingVatAction> pending = await repo.pendingActions('t1');
        expect(pending.single.kind, VatActionKind.intentLetter);
        expect(pending.single.targetId, 'Export Srl');
        expect(pending.single.rejected, isFalse);
      },
    );

    test(
      'a refresh while the letter is still queued keeps its placeholder',
      () async {
        adapter.handler = offline;
        await repo.createLetter('t1', draft());

        adapter.handler = (RequestOptions o) =>
            json(200, envelope(<Map<String, dynamic>>[letterJson(id: 'old')]));
        final List<IntentLetter> fresh = await repo.refreshLetters('t1');

        expect(fresh.map((IntentLetter l) => l.id), contains('old'));
        expect(fresh.where((IntentLetter l) => l.pending), hasLength(1));
      },
    );

    test('an invalid draft is refused locally and nothing is queued', () async {
      final ActionOutcome outcome = await repo.createLetter(
        't1',
        draft(protocol: '123'),
      );

      expect(outcome.status, ActionStatus.rejected);
      expect(adapter.calls, isEmpty);
      expect(await repo.pendingActions('t1'), isEmpty);
      expect(await repo.cachedLetters('t1'), isEmpty);
    });

    test('a letter the server refuses is parked as rejected; dismissing it removes the placeholder', () async {
      adapter.handler = (RequestOptions o) =>
          problem(422, 'Protocol unknown to the Agenzia');

      final ActionOutcome outcome = await repo.createLetter('t1', draft());

      expect(outcome.status, ActionStatus.rejected);
      final PendingVatAction action = (await repo.pendingActions('t1')).single;
      expect(action.rejected, isTrue);

      await repo.dismissAction(action.queueUuid);
      expect(await repo.pendingActions('t1'), isEmpty);
      expect(await repo.cachedLetters('t1'), isEmpty);
    });
  });

  group('periodic settlements and LIPE', () {
    test('refresh stores the settlements, newest period first', () async {
      adapter.handler = (RequestOptions o) => json(
        200,
        envelope(<Map<String, dynamic>>[
          settlementJson(),
          settlementJson(id: 's2', period: 2),
          settlementJson(id: 's0', year: 2026, period: 4),
        ]),
      );

      final List<LipeSettlement> fresh = await repo.refreshSettlements('t1');

      expect(adapter.calls.single.path, '/vat/settlements');
      expect(fresh.map((LipeSettlement s) => s.id), <String>['s2', 's1', 's0']);
    });

    test('the detail adds the LIPE file and the ledger balance, and a later list refresh keeps them', () async {
      adapter.handler = (RequestOptions o) => json(
        200,
        envelope(
          settlementJson(
            erario: '2000.00',
            lipe: <String, dynamic>{
              'generated': true,
              'xsd_valid': true,
              'signature_status': 'signed',
            },
          ),
        ),
      );
      final LipeSettlement detail = await repo.refreshSettlement('t1', 's1');
      expect(adapter.calls.single.path, '/vat/settlements/s1');
      expect(detail.file.readyToTransmit, isTrue);

      adapter.handler = (RequestOptions o) =>
          json(200, envelope(<Map<String, dynamic>>[settlementJson()]));
      final LipeSettlement listed = (await repo.refreshSettlements('t1'))
          .single;

      expect(listed.erarioBalance, amountFromJson('2000.00'));
      expect(listed.file.readyToTransmit, isTrue);
      expect(listed.reconciliation.state, ReconciliationState.reconciled);
    });

    test(
      'a list entry that carries its own detail replaces the stored one',
      () async {
        adapter.handler = (RequestOptions o) =>
            json(200, envelope(settlementJson(erario: '2000.00')));
        await repo.refreshSettlement('t1', 's1');

        adapter.handler = (RequestOptions o) => json(
          200,
          envelope(<Map<String, dynamic>>[settlementJson(erario: '1500.00')]),
        );
        final LipeSettlement listed = (await repo.refreshSettlements('t1'))
            .single;

        expect(listed.erarioBalance, amountFromJson('1500.00'));
      },
    );

    test('requesting the LIPE file queues one command per settlement, a second tap adds nothing', () async {
      adapter.handler = offline;

      expect((await repo.requestLipe('t1', 's1')).status, ActionStatus.queued);
      expect((await repo.requestLipe('t1', 's1')).status, ActionStatus.queued);

      final List<PendingVatAction> pending = await repo.pendingActions('t1');
      expect(pending, hasLength(1));
      expect(pending.single.kind, VatActionKind.lipeGeneration);
      expect(pending.single.targetId, 's1');
      expect((await repo.requestLipe('t1', 's2')).status, ActionStatus.queued);
      expect(await repo.pendingActions('t1'), hasLength(2));
    });

    test(
      'online the request goes to the settlement and is acknowledged',
      () async {
        adapter.handler = (RequestOptions o) =>
            json(202, envelope(<String, dynamic>{}));

        final ActionOutcome outcome = await repo.requestLipe('t1', 's1');

        expect(outcome.status, ActionStatus.sent);
        expect(adapter.calls.single.method, 'POST');
        expect(adapter.calls.single.path, '/vat/settlements/s1/lipe');
      },
    );

    test(
      'a refused request is parked with the server detail and can be retried',
      () async {
        adapter.handler = (RequestOptions o) =>
            problem(422, 'Settlement not posted');

        final ActionOutcome outcome = await repo.requestLipe('t1', 's1');
        expect(outcome.status, ActionStatus.rejected);

        final PendingVatAction action = (await repo.pendingActions('t1'))
            .single;
        expect(action.rejected, isTrue);

        adapter.handler = (RequestOptions o) =>
            json(202, envelope(<String, dynamic>{}));
        await repo.retryAction('t1', action.queueUuid);
        expect(await repo.pendingActions('t1'), isEmpty);
      },
    );

    test('downloads the LIPE XML and the settlement PDF as bytes', () async {
      adapter.handler = (RequestOptions o) => ResponseBody.fromBytes(
        utf8.encode('<xml/>'),
        200,
        headers: <String, List<String>>{
          'content-type': <String>['application/xml; charset=utf-8'],
          'content-disposition': <String>[
            'attachment; filename="IT01234567890_LI_00001.xml"',
          ],
        },
      );
      final LipeSettlement s = settlement();

      final VatFile xml = await repo.downloadLipeXml(s);

      expect(adapter.calls.single.path, '/vat/settlements/s1/export-xml');
      expect(adapter.calls.single.responseType, ResponseType.bytes);
      expect(xml.fileName, 'IT01234567890_LI_00001.xml');
      expect(xml.mimeType, 'application/xml');
      expect(utf8.decode(xml.bytes), '<xml/>');

      adapter.handler = (RequestOptions o) => ResponseBody.fromBytes(
        Uint8List.fromList(<int>[37, 80, 68, 70]),
        200,
      );
      final VatFile pdf = await repo.downloadSettlementPdf(s);
      expect(adapter.calls.last.path, '/vat/settlements/s1/export-pdf');
      expect(pdf.fileName, 'vat-settlement-2027-Q1.pdf');
      expect(pdf.mimeType, 'application/pdf');
    });

    test('a download that fails raises the mapped error', () async {
      adapter.handler = offline;

      await expectLater(
        repo.downloadLipeXml(settlement()),
        throwsA(
          isA<ItalianVatException>().having(
            (ItalianVatException e) => e.kind,
            'kind',
            ItalianVatErrorKind.offline,
          ),
        ),
      );
    });
  });

  group('annual VAT', () {
    test('without a server summary the year is added up from the cached settlements', () async {
      adapter.handler = (RequestOptions o) => json(
        200,
        envelope(<Map<String, dynamic>>[
          settlementJson(),
          settlementJson(id: 's2', period: 2, output: '1000.00', input: '0.00'),
        ]),
      );
      await repo.refreshSettlements('t1');

      adapter.handler = offline;
      final AnnualVatSummary s = await repo.cachedAnnual('t1', 2027);

      expect(s.output, amountFromJson('6000.00'));
      expect(s.fromServer, isFalse);
    });

    test(
      'refresh pulls the settlements and the server summary, which wins',
      () async {
        adapter.handler = (RequestOptions o) {
          if (o.path == '/vat/settlements') {
            return json(
              200,
              envelope(<Map<String, dynamic>>[settlementJson()]),
            );
          }
          return json(
            200,
            envelope(<String, dynamic>{
              'balance': '2100.00',
              'erario_balance': '2100.00',
            }),
          );
        };

        final AnnualVatSummary s = await repo.refreshAnnual('t1', 2027);

        expect(adapter.calls.map((RequestOptions c) => c.path), <String>[
          '/vat/settlements',
          '/vat/annual-returns/2027',
        ]);
        expect(s.fromServer, isTrue);
        expect(s.balance, amountFromJson('2100.00'));
        expect(s.reconciliation, ReconciliationState.reconciled);
      },
    );

    test(
      'a year the server has no summary for falls back to the settlements',
      () async {
        adapter.handler = (RequestOptions o) => o.path == '/vat/settlements'
            ? json(200, envelope(<Map<String, dynamic>>[settlementJson()]))
            : problem(404, 'No annual return');

        final AnnualVatSummary s = await repo.refreshAnnual('t1', 2027);

        expect(s.fromServer, isFalse);
        expect(s.balance, amountFromJson('2000.00'));
      },
    );

    test('any other failure of the summary is raised', () async {
      adapter.handler = (RequestOptions o) => o.path == '/vat/settlements'
          ? json(200, envelope(<dynamic>[]))
          : problem(403, 'no');

      await expectLater(
        repo.refreshAnnual('t1', 2027),
        throwsA(
          isA<ItalianVatException>().having(
            (ItalianVatException e) => e.kind,
            'kind',
            ItalianVatErrorKind.forbidden,
          ),
        ),
      );
    });
  });

  group('certificazioni uniche', () {
    test('refresh replaces the certificates of the year and leaves the other years alone', () async {
      adapter.handler = (RequestOptions o) => json(
        200,
        envelope(<Map<String, dynamic>>[
          certificateJson(name: 'Verdi Anna'),
          certificateJson(
            id: 'cu2',
            name: 'Bianchi Luca',
            kind: 'agent',
            paid: '0.00',
          ),
        ]),
      );
      final List<WithholdingCertificate> fresh = await repo.refreshCertificates(
        't1',
        2027,
      );

      expect(
        adapter.calls.single.path,
        '/general-ledger/withholding-certificates',
      );
      expect(adapter.calls.single.queryParameters, containsPair('year', 2027));
      expect(fresh.map((WithholdingCertificate c) => c.recipientName), <String>[
        'Bianchi Luca',
        'Verdi Anna',
      ]);

      adapter.handler = (RequestOptions o) => json(
        200,
        envelope(<Map<String, dynamic>>[certificateJson(id: 'cu9')]),
      );
      await repo.refreshCertificates('t1', 2027);

      expect(
        (await repo.cachedCertificates(
          't1',
          2027,
        )).map((WithholdingCertificate c) => c.id),
        <String>['cu9'],
      );
      expect(await repo.cachedCertificates('t1', 2026), isEmpty);
    });

    test(
      'downloads the PDF of one certificate and the telematic file of the year',
      () async {
        adapter.handler = (RequestOptions o) =>
            ResponseBody.fromBytes(Uint8List.fromList(<int>[1, 2, 3]), 200);

        final VatFile pdf = await repo.downloadCertificatePdf(
          certificate(name: 'Rossi Mario'),
        );
        expect(
          adapter.calls.single.path,
          '/general-ledger/withholding-certificates/cu1/pdf',
        );
        expect(pdf.fileName, 'cu-2027-Rossi_Mario.pdf');
        expect(pdf.bytes, <int>[1, 2, 3]);

        final VatFile telematic = await repo.downloadTelematicFile(2027);
        expect(
          adapter.calls.last.path,
          '/general-ledger/withholding-certificates/telematic-file',
        );
        expect(adapter.calls.last.queryParameters, containsPair('year', 2027));
        expect(telematic.fileName, 'cu-2027.txt');
      },
    );

    test('requesting the certificates of a year queues it once with the year as body', () async {
      adapter.handler = offline;

      expect(
        (await repo.requestCertificates('t1', 2027)).status,
        ActionStatus.queued,
      );
      expect(
        (await repo.requestCertificates('t1', 2027)).status,
        ActionStatus.queued,
      );
      expect(
        (await repo.requestCertificates('t1', 2026)).status,
        ActionStatus.queued,
      );

      final List<PendingVatAction> pending = await repo.pendingActions('t1');
      expect(pending.map((PendingVatAction p) => p.targetId), <String>[
        '2027',
        '2026',
      ]);
      expect(
        pending.every(
          (PendingVatAction p) => p.kind == VatActionKind.certificateGeneration,
        ),
        isTrue,
      );
    });
  });

  group('register export', () {
    test(
      'asks for the CSV of the period and names the file after the register',
      () async {
        adapter.handler = (RequestOptions o) => ResponseBody.fromString(
          'a;b',
          200,
          headers: <String, List<String>>{
            'content-type': <String>['text/csv; charset=utf-8'],
          },
        );

        final VatFile file = await repo.downloadRegisterCsv(
          VatRegisterType.sales,
          from,
          to,
        );

        expect(
          adapter.calls.single.queryParameters,
          containsPair('format', 'csv'),
        );
        expect(file.fileName, 'vat-register-sales-2027-01-01-2027-03-31.csv');
        expect(file.mimeType, 'text/csv');
      },
    );
  });

  test('the outbox entities are terminal, so a refusal is parked instead of resent forever', () {
    expect(
      SyncEngine.defaultTerminalEntities,
      containsAll(<String>[
        vatLetterEntity,
        vatLipeRequestEntity,
        vatCertificateRequestEntity,
      ]),
    );
  });
}
