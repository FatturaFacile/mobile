import 'package:dio/dio.dart';
import 'package:fattura_facile/features/field_service/data/field_service_outbox.dart';
import 'package:fattura_facile/features/field_service/data/field_service_repository.dart';
import 'package:fattura_facile/features/field_service/domain/signature_svg.dart';
import 'package:fattura_facile/features/field_service/models/field_service_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

void main() {
  late FsmHarness h;

  setUp(() async {
    h = FsmHarness();
    await h.seed();
  });

  tearDown(() => h.close());

  Future<FsmWorkOrderDetail> detail([String id = woCorrective]) async =>
      (await h.repo.watchDetail(id).first)!;

  Future<VanStockItem> van(String productId) async =>
      (await h.repo.watchVanStock().first).firstWhere(
        (VanStockItem v) => v.productId == productId,
      );

  List<RequestOptions> gets() =>
      h.api.calls.where((RequestOptions c) => c.method == 'GET').toList();

  group('offline bundle', () {
    test('is stored and read back with the names the list shows', () async {
      final List<FsmQueueItem> queue = await h.repo.watchWorkQueue().first;

      expect(queue.map((FsmQueueItem q) => q.workOrder.number), <String>[
        'WO-0001',
        'WO-0002',
      ]);
      expect(queue.first.customerName, 'Rossi SA');
      expect(queue.first.equipmentSerial, 'SN-4711');
      expect(queue.first.site.address, 'Via Nassa 5, Lugano');

      final FsmWorkOrderDetail d = await detail();
      expect(d.customer?.phone, '+41 91 000 00 00');
      expect(d.equipment?.history.single.summary, 'Replaced belt');
      expect(d.checklist.map((ChecklistEntry c) => c.item), <String>[
        'fault_diagnosis',
        'repair_verified',
        'functional_test',
      ]);
      expect(d.checklist.every((ChecklistEntry c) => !c.answered), isTrue);
      expect(
        (await h.repo.watchVanStock().first).map((VanStockItem v) => v.sku),
        <String>['FLT-1', 'OIL-1'],
      );
      expect(await h.store.technician(tenant), isNotNull);
    });

    test('a refresh asks for the delta since the last server time and drops the work orders that left the queue', () async {
      expect(gets().first.queryParameters.containsKey('since'), isFalse);
      expect(
        gets().first.path,
        '/fsm/technicians/$technicianId/offline-bundle',
      );

      h.api.bundle = bundleJson(
        serverTime: '2030-01-01T09:30:00+00:00',
        workOrders: <Map<String, dynamic>>[],
        openIds: <String>[woCorrective],
      );
      final FsmRefreshResult result = await h.repo.refresh();

      expect(gets().last.queryParameters['since'], '2030-01-01T08:00:00+00:00');
      expect(result.ok, isTrue);
      expect(result.merge.removed, 1);
      final List<FsmQueueItem> queue = await h.repo.watchWorkQueue().first;
      expect(queue.map((FsmQueueItem q) => q.workOrder.id), <String>[
        woCorrective,
      ]);
      expect(await h.store.serverTime(tenant), '2030-01-01T09:30:00+00:00');
    });

    test('data is scoped to the tenant', () async {
      expect(await h.store.workOrders('someone-else'), isEmpty);
      expect(await h.store.vanStock('someone-else'), isEmpty);
    });

    test('offline or refused refreshes are reported, not thrown', () async {
      h.api.offline = true;
      expect((await h.repo.refresh()).offline, isTrue);
      h.api.offline = false;
      h.api.bundleFailStatus = 500;
      final FsmRefreshResult refused = await h.repo.refresh();
      expect(refused.ok, isFalse);
      expect(refused.error, 'boom');
      expect(
        await h.repo.watchWorkQueue().first,
        hasLength(2),
        reason: 'the cache stays',
      );
      h.api.bundleFailStatus = 401;
      expect((await h.repo.refresh()).unauthorized, isTrue);
    });
  });

  group('status transitions queued offline', () {
    test('dispatched, en route, on site: each step moves the work order now and queues one operation', () async {
      await h.repo.advanceStatus(
        woCorrective,
        FsmStatus.enRoute,
        at: DateTime.utc(2030, 1, 2, 6, 30),
      );
      expect((await detail()).workOrder.status, FsmStatus.enRoute);
      await h.repo.advanceStatus(
        woCorrective,
        FsmStatus.onSite,
        at: DateTime.utc(2030, 1, 2, 7),
      );
      expect((await detail()).workOrder.status, FsmStatus.onSite);

      final List<FsmOperation> ops = await h.store.operations(tenant);
      expect(ops.map((FsmOperation o) => o.type), <FsmOperationType>[
        FsmOperationType.statusTransition,
        FsmOperationType.statusTransition,
      ]);
      expect(ops.first.payload, <String, dynamic>{
        'status': 'en_route',
        'at': '2030-01-02T06:30:00.000Z',
      });
      expect(ops.last.payload['status'], 'on_site');
      expect(
        ops.every((FsmOperation o) => o.state == FsmOutboxState.pending),
        isTrue,
      );
      expect(
        h.api.syncs,
        isEmpty,
        reason: 'nothing talks to the server until a sync',
      );
      expect((await detail()).pendingOperations, 2);
    });

    test('a repeated tap is a no-op, a step back is refused', () async {
      await h.repo.advanceStatus(woCorrective, FsmStatus.enRoute);
      await h.repo.advanceStatus(woCorrective, FsmStatus.enRoute);
      expect(await h.store.operations(tenant), hasLength(1));

      await h.repo.advanceStatus(woCorrective, FsmStatus.onSite);
      await expectLater(
        h.repo.advanceStatus(woCorrective, FsmStatus.enRoute),
        throwsA(
          isA<FsmException>().having(
            (FsmException e) => e.errors['status'],
            'status',
            'transition_invalid',
          ),
        ),
      );
      await expectLater(
        h.repo.advanceStatus(woCorrective, FsmStatus.completed),
        throwsA(isA<FsmException>()),
      );
    });

    test(
      'dispatched may jump straight to on site, like the server allows',
      () async {
        await h.repo.advanceStatus(woWarranty, FsmStatus.onSite);
        expect((await detail(woWarranty)).workOrder.status, FsmStatus.onSite);
      },
    );

    test('an unknown work order is refused', () async {
      await expectLater(
        h.repo.advanceStatus('missing', FsmStatus.enRoute),
        throwsA(
          isA<FsmException>().having(
            (FsmException e) => e.errors['work_order_id'],
            'code',
            'not_found',
          ),
        ),
      );
    });
  });

  group('van parts and coverage', () {
    test('a covered part is flagged offline, drops the van stock and is queued with the sync payload', () async {
      final VanStockItem filter = await van(productFilter);

      final FsmPartLine line = await h.repo.consumePart(
        woCorrective,
        filter,
        2,
        lotNumber: ' LOT-9 ',
      );

      expect(line.covered, isTrue, reason: 'parts_and_labor contract');
      expect(line.chargeable, 0);
      expect(line.lotNumber, 'LOT-9');
      expect((await van(productFilter)).available, 3);
      expect((await detail()).parts.single.clientUuid, line.clientUuid);

      final FsmOperation op = (await h.store.operations(tenant)).single;
      expect(op.type, FsmOperationType.partConsumption);
      expect(op.clientUuid, line.clientUuid);
      expect(op.workOrderId, woCorrective);
      expect(op.payload, <String, dynamic>{
        'product_id': productFilter,
        'quantity': 2.0,
        'unit_price': 25.0,
        'lot_number': 'LOT-9',
      });
    });

    test('a part with no contract is chargeable at the list price', () async {
      h.api.bundle = bundleJson(
        workOrders: <Map<String, dynamic>>[workOrderJson(contract: null)],
      );
      await h.repo.refresh();

      final FsmPartLine line = await h.repo.consumePart(
        woCorrective,
        await van(productOil),
        3,
      );

      expect(line.covered, isFalse);
      expect(line.chargeable, 37.5);
      expect((await detail()).coverage.coversNothing, isTrue);
    });

    test('warranty work covers parts even without a contract', () async {
      final FsmPartLine line = await h.repo.consumePart(
        woWarranty,
        await van(productOil),
        1,
      );
      expect(line.covered, isTrue);
      expect((await detail(woWarranty)).coverage.travelAndCallout, isTrue);
    });

    test(
      'more than the van holds, or no quantity, is refused and changes nothing',
      () async {
        final VanStockItem filter = await van(productFilter);

        await expectLater(
          h.repo.consumePart(woCorrective, filter, 6),
          throwsA(
            isA<FsmException>().having(
              (FsmException e) => e.errors['quantity'],
              'q',
              'insufficient_stock',
            ),
          ),
        );
        await expectLater(
          h.repo.consumePart(woCorrective, filter, 0),
          throwsA(
            isA<FsmException>().having(
              (FsmException e) => e.errors['quantity'],
              'q',
              'positive',
            ),
          ),
        );
        await expectLater(
          h.repo.consumePart(woCorrective, filter, 1, lotNumber: 'x' * 61),
          throwsA(isA<FsmException>()),
        );
        expect((await van(productFilter)).available, 5);
        expect(await h.store.operations(tenant), isEmpty);
      },
    );

    test(
      'removing a part that has not synced puts it back on the van',
      () async {
        final FsmPartLine line = await h.repo.consumePart(
          woCorrective,
          await van(productFilter),
          2,
        );

        await h.repo.removePart(woCorrective, line.clientUuid);

        expect((await van(productFilter)).available, 5);
        expect((await detail()).parts, isEmpty);
        expect(await h.store.operations(tenant), isEmpty);
      },
    );

    test('a part the server already applied cannot be removed', () async {
      final FsmPartLine line = await h.repo.consumePart(
        woCorrective,
        await van(productFilter),
        2,
      );
      await h.repo.sync();

      await expectLater(
        h.repo.removePart(woCorrective, line.clientUuid),
        throwsA(
          isA<FsmException>().having(
            (FsmException e) => e.errors['part'],
            'part',
            'already_synced',
          ),
        ),
      );
    });

    test('a refresh does not hand back the quantity of parts still waiting to sync', () async {
      await h.repo.consumePart(woCorrective, await van(productFilter), 2);

      await h.repo.refresh(); // the server still says 5

      expect((await van(productFilter)).available, 3);
    });
  });

  group('checklist, photos and draft', () {
    test('checklist answers are kept per point with their notes', () async {
      await h.repo.setChecklistResult(
        woCorrective,
        'fault_diagnosis',
        ChecklistResult.fail,
        notes: 'worn bearing',
      );
      await h.repo.setChecklistResult(
        woCorrective,
        'repair_verified',
        ChecklistResult.na,
      );

      final List<ChecklistEntry> list = (await detail()).checklist;
      expect(list[0].result, ChecklistResult.fail);
      expect(list[0].notes, 'worn bearing');
      expect(list[1].result, ChecklistResult.na);
      expect(list[2].answered, isFalse);
    });

    test(
      'photos keep the file on the phone and send a path reference',
      () async {
        final ReportPhoto photo = await h.repo.addPhoto(
          woCorrective,
          localPath: '/data/p1.jpg',
          name: 'p1.jpg',
        );

        expect(photo.path, 'fsm/$woCorrective/p1.jpg');
        expect((await detail()).photos.single.localPath, '/data/p1.jpg');
        await h.repo.removePhoto(woCorrective, photo.id);
        expect((await detail()).photos, isEmpty);
      },
    );

    test('at most 20 photos', () async {
      for (var i = 0; i < 20; i++) {
        await h.repo.addPhoto(
          woCorrective,
          localPath: '/d/$i.jpg',
          name: '$i.jpg',
        );
      }
      await expectLater(
        h.repo.addPhoto(woCorrective, localPath: '/d/x.jpg', name: 'x.jpg'),
        throwsA(
          isA<FsmException>().having(
            (FsmException e) => e.errors['photos'],
            'photos',
            'max',
          ),
        ),
      );
    });

    test('the report form draft survives', () async {
      expect(await h.repo.loadDraft(woCorrective), isEmpty);
      await h.repo.saveDraft(woCorrective, <String, dynamic>{
        'summary': 'half done',
        'callout': true,
      });
      expect(await h.repo.loadDraft(woCorrective), <String, dynamic>{
        'summary': 'half done',
        'callout': true,
      });
    });
  });

  group('signing the service report', () {
    test('seals the signature, completes the work order locally and queues the report', () async {
      final ServiceReportDraft draft = await h.validDraft();

      final StoredReport report = await h.repo.signAndClose(
        woCorrective,
        draft,
      );

      expect(report.signatureSha256, SignatureSvgHash.sha256Hex(drawnSvg));
      expect(report.signatureSha256, hasLength(64));
      expect(
        report.reportNumber,
        isNull,
        reason: 'the number comes from the server',
      );
      final FsmWorkOrderDetail d = await detail();
      expect(d.workOrder.status, FsmStatus.completed);
      expect(d.signed, isTrue);
      expect(d.report?.signedAt, DateTime.utc(2030, 1, 1, 10));

      final FsmOperation op = (await h.store.operations(tenant)).single;
      expect(op.type, FsmOperationType.serviceReport);
      expect(op.clientUuid, report.clientUuid);
      expect(op.payload, draft.toPayload());
      expect(op.payload['locale'], 'it-CH');
      expect(op.payload['signature_svg'], drawnSvg);
    });

    test('is refused until it is complete, naming the API fields', () async {
      final ServiceReportDraft ok = await h.validDraft();
      final ServiceReportDraft bad = ServiceReportDraft(
        workPerformedSummary: ' ',
        laborHours: 1,
        signerName: '',
        signatureSvg: 'nope',
        signedAt: ok.signedAt,
        checklist: ok.checklist,
      );

      await expectLater(
        h.repo.signAndClose(woCorrective, bad),
        throwsA(
          isA<FsmException>().having(
            (FsmException e) => e.errors.keys,
            'fields',
            containsAll(<String>[
              'work_performed_summary',
              'customer_signer_name',
              'signature_svg',
            ]),
          ),
        ),
      );
      expect(await h.store.operations(tenant), isEmpty);
      expect((await detail()).workOrder.status, FsmStatus.dispatched);
    });

    test('the checklist must be answered', () async {
      final FsmWorkOrderDetail d = await detail();
      final ServiceReportDraft unanswered = ServiceReportDraft(
        workPerformedSummary: 'x',
        laborHours: 1,
        signerName: 'Mario',
        signatureSvg: drawnSvg,
        signedAt: DateTime.utc(2030),
        checklist: d.checklist,
      );

      await expectLater(
        h.repo.signAndClose(woCorrective, unanswered),
        throwsA(
          isA<FsmException>().having(
            (FsmException e) => e.errors['checklist'],
            'c',
            'unanswered',
          ),
        ),
      );
    });

    test('a meter reading below the asset counters is refused like the server does', () async {
      final ServiceReportDraft ok = await h.validDraft();
      final ServiceReportDraft low = ServiceReportDraft(
        workPerformedSummary: ok.workPerformedSummary,
        laborHours: ok.laborHours,
        signerName: ok.signerName,
        signatureSvg: ok.signatureSvg,
        signedAt: ok.signedAt,
        checklist: ok.checklist,
        meterReadingHours: 1000,
      );

      await expectLater(
        h.repo.signAndClose(woCorrective, low),
        throwsA(
          isA<FsmException>().having(
            (FsmException e) => e.errors['meter_reading'],
            'm',
            'regression',
          ),
        ),
      );
    });

    test('a signed work order accepts nothing more', () async {
      await h.repo.signAndClose(woCorrective, await h.validDraft());

      await expectLater(
        h.repo.signAndClose(woCorrective, await h.validDraft()),
        throwsA(isA<FsmException>()),
      );
      await expectLater(
        h.repo.consumePart(woCorrective, await van(productOil), 1),
        throwsA(isA<FsmException>()),
      );
      await expectLater(
        h.repo.advanceStatus(woCorrective, FsmStatus.onSite),
        throwsA(isA<FsmException>()),
      );
    });
  });

  group('sync outbox', () {
    /// Queues a full visit: two status steps, a part and the signed report.
    Future<List<FsmOperation>> fullVisit() async {
      await h.repo.advanceStatus(woCorrective, FsmStatus.enRoute);
      await h.repo.advanceStatus(woCorrective, FsmStatus.onSite);
      await h.repo.consumePart(woCorrective, await van(productFilter), 1);
      await h.repo.signAndClose(woCorrective, await h.validDraft());
      return h.store.operations(tenant);
    }

    test(
      'sends one batch in queue order with the client_uuid of every operation',
      () async {
        final List<FsmOperation> queued = await fullVisit();

        final FsmFlushReport report = await h.outbox.flush(tenant);

        expect(report.applied, 4);
        expect(h.api.syncs, hasLength(1));
        expect(h.api.syncs.single.path, '/fsm/mobile-sync');
        final List<Map<String, dynamic>> sent = h.api.opsOf(0);
        expect(sent.map((Map<String, dynamic> o) => o['type']), <String>[
          'status_transition',
          'status_transition',
          'part_consumption',
          'service_report',
        ]);
        expect(
          sent.map((Map<String, dynamic> o) => o['client_uuid']),
          queued.map((FsmOperation o) => o.clientUuid),
        );
        expect(
          sent.every(
            (Map<String, dynamic> o) => o['work_order_id'] == woCorrective,
          ),
          isTrue,
        );
        expect(
          sent.last['payload']['work_performed_summary'],
          'Replaced the start capacitor',
        );
        expect(
          h.api.syncs.single.headers['Idempotency-Key'],
          queued.first.clientUuid,
        );

        final List<FsmOperation> after = await h.store.operations(tenant);
        expect(
          after.every((FsmOperation o) => o.state == FsmOutboxState.done),
          isTrue,
        );
        expect(await h.repo.watchPending().first, 0);
      },
    );

    test('the server report number and seal are kept next to the device signature hash', () async {
      await fullVisit();

      await h.outbox.flush(tenant);

      final StoredReport report = (await detail()).report!;
      expect(report.reportNumber, 'SR-2030-0001');
      expect(report.serverSealHash, startsWith('seal-'));
      expect(report.signatureSha256, SignatureSvgHash.sha256Hex(drawnSvg));
      final FsmOperation reportOp = (await h.store.operations(tenant)).last;
      expect(reportOp.result['report_number'], 'SR-2030-0001');
    });

    test('a lost answer is replayed with the same client_uuids and the server says duplicate', () async {
      await fullVisit();
      h.api.dropNextAnswer = true;

      final FsmFlushReport first = await h.outbox.flush(tenant);

      expect(first.offline, isTrue);
      expect(
        (await h.store.operations(tenant))
            .every((FsmOperation o) => o.state == FsmOutboxState.pending),
        isTrue,
      );
      expect(h.api.applied, hasLength(4), reason: 'the server did apply them');

      final FsmFlushReport second = await h.outbox.flush(tenant);

      expect(second.duplicates, 4);
      expect(second.applied, 0);
      expect(
        h.api.opsOf(1).map((Map<String, dynamic> o) => o['client_uuid']),
        h.api.opsOf(0).map((Map<String, dynamic> o) => o['client_uuid']),
      );
      final List<FsmOperation> ops = await h.store.operations(tenant);
      expect(
        ops.every(
          (FsmOperation o) => o.state == FsmOutboxState.done && o.replayed,
        ),
        isTrue,
      );
    });

    test(
      'being offline neither counts as an attempt nor delays the queue',
      () async {
        await fullVisit();
        h.api.offline = true;

        final FsmFlushReport report = await h.outbox.flush(tenant);

        expect(report.offline, isTrue);
        final List<FsmOperation> ops = await h.store.operations(tenant);
        expect(
          ops.every(
            (FsmOperation o) => o.attempts == 0 && o.nextAttemptAt == null,
          ),
          isTrue,
        );

        h.api.offline = false;
        expect((await h.outbox.flush(tenant)).applied, 4);
      },
    );

    test('a rejection is reported as a conflict and does not stop the rest of the batch', () async {
      final List<FsmOperation> queued = await fullVisit();
      final FsmOperation reportOp = queued.last;
      h.api.rejections[reportOp.clientUuid] = <String, List<String>>{
        'work_order': <String>['report_exists'],
      };

      final FsmFlushReport report = await h.outbox.flush(tenant);

      expect(report.applied, 3);
      expect(report.rejected, 1);
      final List<FsmOperation> conflicts = await h.repo.watchConflicts().first;
      expect(conflicts.single.clientUuid, reportOp.clientUuid);
      expect(conflicts.single.errors, <String, List<String>>{
        'work_order': <String>['report_exists'],
      });
      expect(conflicts.single.lastError, 'work_order: report_exists');
      expect(
        await h.repo.watchPending().first,
        0,
        reason: 'a conflict is not pending',
      );

      // It is never resent on its own.
      await h.outbox.flush(tenant);
      expect(h.api.syncs, hasLength(1));
    });

    test('retrying a conflict resends it with the same client_uuid', () async {
      final FsmOperation reportOp = (await fullVisit()).last;
      h.api.rejections[reportOp.clientUuid] = <String, List<String>>{
        'work_order': <String>['report_not_open'],
      };
      await h.outbox.flush(tenant);

      h.api.rejections.clear();
      await h.repo.retryOperation(reportOp.clientUuid);
      expect(
        (await h.store.operation(reportOp.clientUuid))?.state,
        FsmOutboxState.pending,
      );
      final FsmFlushReport report = await h.outbox.flush(tenant);

      expect(report.applied, 1);
      expect(h.api.opsOf(1).single['client_uuid'], reportOp.clientUuid);
      expect(await h.repo.watchConflicts().first, isEmpty);
    });

    test('discarding a rejected report undoes its local effects so the technician can sign again', () async {
      final FsmOperation reportOp = (await fullVisit()).last;
      h.api.rejections[reportOp.clientUuid] = <String, List<String>>{
        'signature_svg': <String>['invalid'],
      };
      await h.outbox.flush(tenant);

      await h.repo.discardOperation(reportOp.clientUuid);

      final FsmWorkOrderDetail d = await detail();
      expect(d.signed, isFalse);
      expect(d.workOrder.status, FsmStatus.onSite);
      expect(await h.store.operation(reportOp.clientUuid), isNull);
      await h.repo.signAndClose(woCorrective, await h.validDraft());
      expect((await detail()).signed, isTrue);
    });

    test('discarding a pending part puts it back on the van', () async {
      final FsmPartLine line = await h.repo.consumePart(
        woCorrective,
        await van(productFilter),
        2,
      );

      await h.repo.discardOperation(line.clientUuid);

      expect((await van(productFilter)).available, 5);
      expect((await detail()).parts, isEmpty);
    });

    test(
      'a server error backs off exponentially and the queue waits',
      () async {
        await fullVisit();
        h.api.failStatus = 503;

        final FsmFlushReport first = await h.outbox.flush(tenant);

        expect(first.failed, 4);
        final List<FsmOperation> failed = await h.store.operations(tenant);
        expect(
          failed.every(
            (FsmOperation o) =>
                o.state == FsmOutboxState.failed && o.attempts == 1,
          ),
          isTrue,
        );
        expect(failed.first.nextAttemptAt, DateTime.utc(2030, 1, 1, 8, 0, 5));
        expect(failed.first.lastError, 'status 503');
        expect(await h.repo.watchPending().first, 4);

        // Not due yet: nothing is sent.
        final FsmFlushReport early = await h.outbox.flush(tenant);
        expect(early.deferred, 4);
        expect(h.api.syncs, hasLength(1));

        // Still failing: the delay doubles.
        h.clock.advance(const Duration(seconds: 6));
        await h.outbox.flush(tenant);
        final List<FsmOperation> second = await h.store.operations(tenant);
        expect(second.first.attempts, 2);
        expect(
          second.first.nextAttemptAt,
          DateTime.utc(2030, 1, 1, 8, 0, 6).add(const Duration(seconds: 10)),
        );

        h.api.failStatus = null;
        h.clock.advance(const Duration(seconds: 11));
        expect((await h.outbox.flush(tenant)).applied, 4);
      },
    );

    test('backoff is capped', () {
      expect(h.outbox.backoffFor(1), const Duration(seconds: 5));
      expect(h.outbox.backoffFor(3), const Duration(seconds: 20));
      expect(h.outbox.backoffFor(30), const Duration(minutes: 15));
    });

    test('an expired session stops the flush and keeps the queue', () async {
      await fullVisit();
      h.api.failStatus = 401;

      final FsmFlushReport report = await h.outbox.flush(tenant);

      expect(report.unauthorized, isTrue);
      expect(
        (await h.store.operations(tenant))
            .every((FsmOperation o) => o.attempts == 0),
        isTrue,
      );
    });

    test(
      'a refused batch (422) becomes conflicts instead of retrying for ever',
      () async {
        await h.repo.advanceStatus(woCorrective, FsmStatus.enRoute);
        h.api.failStatus = 422;

        final FsmFlushReport report = await h.outbox.flush(tenant);

        expect(report.rejected, 1);
        expect(await h.repo.watchConflicts().first, hasLength(1));
      },
    );

    test('batches never exceed the size the API accepts', () async {
      final FieldServiceOutbox small = FieldServiceOutbox(
        h.store,
        _dioOf(h),
        clock: h.clock.call,
        batchSize: 2,
      );
      await fullVisit();

      final FsmFlushReport report = await small.flush(tenant);

      expect(report.applied, 4);
      expect(h.api.syncs, hasLength(2));
      expect(h.api.opsOf(0), hasLength(2));
      expect(h.api.opsOf(1), hasLength(2));
    });

    test(
      'sync sends the queue, then refreshes; offline it skips the refresh',
      () async {
        await h.repo.advanceStatus(woCorrective, FsmStatus.enRoute);
        final int getsBefore = gets().length;

        h.api.offline = true;
        final FsmFlushReport offline = await h.repo.sync();
        expect(offline.offline, isTrue);
        expect(gets().length, getsBefore + 0);

        h.api.offline = false;
        final FsmFlushReport online = await h.repo.sync();
        expect(online.applied, 1);
        final List<RequestOptions> order = h.api.calls.sublist(
          h.api.calls.length - 2,
        );
        expect(
          <String>[order.first.method, order.last.method],
          <String>['POST', 'GET'],
        );
      },
    );
  });

  group('refresh while changes are waiting', () {
    test('a work order with queued steps keeps its local status', () async {
      await h.repo.advanceStatus(woCorrective, FsmStatus.onSite);

      await h.repo.refresh(); // the server still says dispatched

      expect((await detail()).workOrder.status, FsmStatus.onSite);
    });

    test(
      'once the steps are acknowledged the server status wins again',
      () async {
        await h.repo.advanceStatus(woCorrective, FsmStatus.onSite);
        await h.repo.sync();

        h.api.bundle = bundleJson(
          workOrders: <Map<String, dynamic>>[
            workOrderJson(status: 'in_progress'),
          ],
          openIds: <String>[woCorrective, woWarranty],
        );
        await h.repo.refresh();

        expect((await detail()).workOrder.status, FsmStatus.inProgress);
      },
    );

    test('a work order that left the queue is kept while its changes wait, dropped afterwards', () async {
      await h.repo.advanceStatus(woCorrective, FsmStatus.enRoute);
      h.api.bundle = bundleJson(
        workOrders: <Map<String, dynamic>>[],
        openIds: <String>[woWarranty],
      );

      await h.repo.refresh();
      expect(await h.store.workOrder(tenant, woCorrective), isNotNull);

      await h.repo.sync();
      await h.repo.refresh();
      expect(await h.store.workOrder(tenant, woCorrective), isNull);
    });
  });

  group('photo upload', () {
    Future<ReportPhoto> shoot(
      String name, {
      FsmPhotoStage? stage,
      String? caption,
      bool onPhone = true,
    }) {
      if (onPhone) h.files['/data/$name'] = <int>[1, 2, 3, 4];
      return h.repo.addPhoto(
        woCorrective,
        localPath: '/data/$name',
        name: name,
        stage: stage,
        caption: caption,
      );
    }

    List<String> paths() =>
        h.api.calls.map((RequestOptions c) => c.path).toList();

    test(
      'a photo is queued as an upload operation keyed by its own id',
      () async {
        final ReportPhoto photo = await shoot(
          'a.jpg',
          stage: FsmPhotoStage.before,
          caption: '  worn belt ',
        );

        final FsmOperation op = (await h.store.operations(tenant)).single;
        expect(op.type, FsmOperationType.photoUpload);
        expect(op.clientUuid, photo.id);
        expect(op.payload['local_path'], '/data/a.jpg');
        expect(op.payload['stage'], 'before');
        expect(op.payload['caption'], 'worn belt');
        final ReportPhoto stored = (await detail()).photos.single;
        expect(stored.upload, FsmPhotoUpload.queued);
        expect(stored.stage, FsmPhotoStage.before);
        expect(stored.caption, 'worn belt');
        expect(
          h.api.photoUploads,
          isEmpty,
          reason: 'nothing is sent before a sync',
        );
        await expectLater(
          shoot('b.jpg', caption: 'x' * 256),
          throwsA(
            isA<FsmException>().having(
              (FsmException e) => e.errors['caption'],
              'caption',
              'max',
            ),
          ),
        );
      },
    );

    test(
      'photos upload before the report and their server ids go into photo_ids',
      () async {
        await h.repo.advanceStatus(woCorrective, FsmStatus.enRoute);
        await h.repo.advanceStatus(woCorrective, FsmStatus.onSite);
        final ReportPhoto first = await shoot(
          'a.jpg',
          stage: FsmPhotoStage.after,
        );
        await shoot('b.jpg');
        await h.repo.signAndClose(woCorrective, await h.validDraft());
        h.api.calls.clear();

        final FsmFlushReport report = await h.outbox.flush(tenant);

        expect(report.applied, 5);
        expect(paths(), <String>[
          '/fsm/mobile-sync',
          '/fsm/work-orders/$woCorrective/photos',
          '/fsm/work-orders/$woCorrective/photos',
          '/fsm/mobile-sync',
        ], reason: 'the statuses, then each photo alone, then the report');
        final Map<String, dynamic> upload = h.api.photoUploads.first;
        expect(upload['client_uuid'], first.id);
        expect(upload['idempotency_key'], first.id);
        expect(upload['file_field'], 'photo');
        expect(upload['filename'], 'a.jpg');
        expect(upload['size'], 4);
        expect(upload['stage'], 'after');
        expect(upload['captured_at'], isNotNull);
        expect(h.api.photoUploads.last.containsKey('stage'), isFalse);

        final List<Map<String, dynamic>> reportOps = h.api.opsOf(1);
        expect(reportOps.single['type'], 'service_report');
        expect(reportOps.single['payload']['photo_ids'], <String>[
          'srv-1',
          'srv-2',
        ]);
        final List<ReportPhoto> photos = (await detail()).photos;
        expect(
          photos.map((ReportPhoto p) => p.upload),
          everyElement(FsmPhotoUpload.uploaded),
        );
        expect(photos.map((ReportPhoto p) => p.serverId), <String?>[
          'srv-1',
          'srv-2',
        ]);
      },
    );

    test('a report without photos carries no photo_ids', () async {
      await h.repo.advanceStatus(woCorrective, FsmStatus.onSite);
      await h.repo.signAndClose(woCorrective, await h.validDraft());

      await h.outbox.flush(tenant);

      final Map<String, dynamic> payload =
          h.api.opsOf(0).last['payload'] as Map<String, dynamic>;
      expect(payload.containsKey('photo_ids'), isFalse);
    });

    test(
      'a lost answer is retried with the same client_uuid and not duplicated',
      () async {
        final ReportPhoto photo = await shoot('a.jpg');
        h.api.dropNextPhotoAnswer = true;

        final FsmFlushReport lost = await h.outbox.flush(tenant);
        expect(lost.offline, isTrue);
        final FsmOperation waiting = (await h.store.operations(tenant)).single;
        expect(waiting.state, FsmOutboxState.pending);
        expect(waiting.attempts, 0, reason: 'offline is not an attempt');

        final FsmFlushReport retry = await h.outbox.flush(tenant);

        expect(
          retry.duplicates,
          1,
          reason: 'the server answered 200: already stored',
        );
        expect(h.api.photoUploads, hasLength(2));
        expect(
          h.api.photoUploads.map((Map<String, dynamic> u) => u['client_uuid']),
          <String>[photo.id, photo.id],
        );
        expect(h.api.photoIds, hasLength(1));
        final ReportPhoto stored = (await detail()).photos.single;
        expect(stored.upload, FsmPhotoUpload.uploaded);
        expect(stored.serverId, 'srv-1');
        expect((await h.store.operation(photo.id))!.replayed, isTrue);
      },
    );

    test('a file gone from the phone is a conflict: the rest goes on and the report omits it', () async {
      await h.repo.advanceStatus(woCorrective, FsmStatus.onSite);
      final ReportPhoto gone = await shoot('gone.jpg', onPhone: false);
      await shoot('ok.jpg');
      await h.repo.signAndClose(woCorrective, await h.validDraft());

      final FsmFlushReport report = await h.outbox.flush(tenant);

      expect(report.rejected, 1);
      expect(
        h.api.photoUploads,
        hasLength(1),
        reason: 'the missing file never reached the server',
      );
      expect(h.api.opsOf(1).single['type'], 'service_report');
      expect(h.api.opsOf(1).single['payload']['photo_ids'], <String>['srv-1']);
      final FsmOperation op = (await h.store.conflicts(tenant)).single;
      expect(op.clientUuid, gone.id);
      expect(op.errors['photo'], <String>['file_missing']);
      expect(
        (await detail()).photos
            .firstWhere((ReportPhoto p) => p.id == gone.id)
            .upload,
        FsmPhotoUpload.failed,
      );

      await h.repo.discardOperation(gone.id);
      expect(
        (await detail()).photos.map((ReportPhoto p) => p.id),
        isNot(contains(gone.id)),
      );
      expect(await h.store.conflicts(tenant), isEmpty);
    });

    test('a retried conflict uploads once the file is back, with its original client_uuid', () async {
      final ReportPhoto photo = await shoot('late.jpg', onPhone: false);
      await h.outbox.flush(tenant);
      expect((await detail()).photos.single.upload, FsmPhotoUpload.failed);

      h.files['/data/late.jpg'] = <int>[9];
      await h.repo.retryOperation(photo.id);
      final FsmFlushReport report = await h.outbox.flush(tenant);

      expect(report.applied, 1);
      expect(h.api.photoUploads.single['client_uuid'], photo.id);
      expect((await detail()).photos.single.upload, FsmPhotoUpload.uploaded);
    });

    for (final ({int status, String error}) c in <({int status, String error})>[
      (status: 413, error: 'too_large'),
      (status: 422, error: 'HTTP 0'),
    ]) {
      test(
        '${c.status} from the photo endpoint is a conflict, the next operation still goes',
        () async {
          await h.repo.advanceStatus(woCorrective, FsmStatus.enRoute);
          final ReportPhoto photo = await shoot('big.jpg');
          await h.repo.advanceStatus(woCorrective, FsmStatus.onSite);
          h.api.photoFailStatus = c.status;

          final FsmFlushReport report = await h.outbox.flush(tenant);

          expect(report.rejected, 1);
          expect(report.applied, 2, reason: 'both status steps');
          final FsmOperation op = (await h.store.conflicts(tenant)).single;
          expect(op.clientUuid, photo.id);
          expect(op.errors.keys, <String>['photo']);
          if (c.status == 413) expect(op.errors['photo'], <String>[c.error]);
          expect((await detail()).photos.single.upload, FsmPhotoUpload.failed);
        },
      );
    }

    test(
      'offline and 401 stop the flush without touching what follows',
      () async {
        await shoot('a.jpg');
        await h.repo.advanceStatus(woCorrective, FsmStatus.enRoute);

        h.api.offline = true;
        expect((await h.outbox.flush(tenant)).offline, isTrue);
        h.api.offline = false;
        h.api.photoFailStatus = 401;
        final FsmFlushReport unauthorized = await h.outbox.flush(tenant);

        expect(unauthorized.unauthorized, isTrue);
        expect(
          h.api.syncs,
          isEmpty,
          reason: 'the status step waited behind the photo',
        );
        expect(
          (await h.store.operations(tenant))
              .every((FsmOperation o) => o.state == FsmOutboxState.pending),
          isTrue,
        );
      },
    );

    test(
      'a server error backs the photo off and holds back the report',
      () async {
        await h.repo.advanceStatus(woCorrective, FsmStatus.onSite);
        await shoot('a.jpg');
        await h.repo.signAndClose(woCorrective, await h.validDraft());
        h.api.photoFailStatus = 503;
        h.api.calls.clear();

        final FsmFlushReport first = await h.outbox.flush(tenant);

        expect(first.failed, 1);
        expect(
          first.deferred,
          1,
          reason: 'the report must not overtake the photo',
        );
        expect(h.api.syncs, hasLength(1), reason: 'only the status step');
        final FsmOperation photoOp = (await h.store.operations(tenant))
            .firstWhere(
              (FsmOperation o) => o.type == FsmOperationType.photoUpload,
            );
        expect(photoOp.state, FsmOutboxState.failed);

        h.api.photoFailStatus = null;
        h.clock.advance(const Duration(minutes: 1));
        final FsmFlushReport second = await h.outbox.flush(tenant);

        expect(second.applied, 2);
        expect(h.api.opsOf(1).single['payload']['photo_ids'], <String>[
          'srv-1',
        ]);
      },
    );

    test('a photo can be removed until the server has it', () async {
      final ReportPhoto queued = await shoot('a.jpg');
      await h.repo.removePhoto(woCorrective, queued.id);
      expect((await detail()).photos, isEmpty);
      expect(await h.store.operations(tenant), isEmpty);

      final ReportPhoto sent = await shoot('b.jpg');
      await h.outbox.flush(tenant);
      await expectLater(
        h.repo.removePhoto(woCorrective, sent.id),
        throwsA(
          isA<FsmException>().having(
            (FsmException e) => e.errors['photo'],
            'photo',
            'already_synced',
          ),
        ),
      );
      expect((await detail()).photos, hasLength(1));
    });

    test(
      'a photo kept before the upload existed shows as failed, not as queued',
      () async {
        await h.store.insertPhoto(
          tenant,
          woCorrective,
          ReportPhoto(
            id: 'legacy',
            path: 'fsm/x/legacy.jpg',
            name: 'legacy.jpg',
            takenAt: DateTime.utc(2030),
            localPath: '/data/legacy.jpg',
          ),
        );

        expect((await detail()).photos.single.upload, FsmPhotoUpload.failed);
      },
    );
  });
}

Dio _dioOf(FsmHarness h) =>
    Dio(BaseOptions(baseUrl: 'http://x/api/v1'))..httpClientAdapter = h.api;
