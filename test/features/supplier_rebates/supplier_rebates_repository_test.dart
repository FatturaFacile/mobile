import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:fattura_facile/core/database/app_database.dart';
import 'package:fattura_facile/core/sync/sync_engine.dart';
import 'package:fattura_facile/features/supplier_rebates/data/supplier_rebates_repository_impl.dart';
import 'package:fattura_facile/features/supplier_rebates/domain/supplier_rebate_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/sync_engine_test.dart' show FakeAdapter, json;
import 'fixtures.dart';

Never offline(RequestOptions o) =>
    throw DioException.connectionError(requestOptions: o, reason: 'down');

void main() {
  late AppDatabase db;
  late FakeAdapter adapter;
  late Dio dio;
  late SupplierRebatesRepositoryImpl repo;

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
    repo = SupplierRebatesRepositoryImpl(db, dio, SyncEngine(db, dio));
  });

  tearDown(() => db.close());

  group('agreements', () {
    test('refresh asks for purchase agreements and stores an offline copy, newest first', () async {
      adapter.handler = (RequestOptions o) => json(
        200,
        envelope(<Map<String, dynamic>>[
          agreementJson(id: 'a1', code: 'PFA-A'),
          agreementJson(id: 'a2', code: 'PFA-B')..['starts_on'] = '2027-06-01',
        ]),
      );

      final List<RebateAgreement> fresh = await repo.refreshAgreements('t1');

      expect(adapter.calls.single.path, '/rebates/agreements');
      expect(adapter.calls.single.queryParameters, containsPair('direction', 'purchase'));
      expect(fresh.map((RebateAgreement a) => a.id), <String>['a2', 'a1']);

      adapter.handler = offline;
      final List<RebateAgreement> cached = await repo.cachedAgreements('t1');
      expect(cached.map((RebateAgreement a) => a.id), <String>['a2', 'a1']);
      expect(cached.first.tiers, hasLength(3));
    });

    test('a paginator body {data: {data: [...]}} is read as well', () async {
      adapter.handler = (RequestOptions o) => json(
        200,
        envelope(<String, dynamic>{
          'data': <Map<String, dynamic>>[agreementJson()],
        }),
      );

      expect(await repo.refreshAgreements('t1'), hasLength(1));
    });

    test('the list refresh keeps the contributions a detail pull stored', () async {
      adapter.handler = (RequestOptions o) => json(
        200,
        envelope(agreementJson(contributions: <Map<String, dynamic>>[contributionJson()])),
      );
      final RebateAgreement detail = await repo.refreshAgreement('t1', 'a1');
      expect(detail.contributions, hasLength(1));

      adapter.handler = (RequestOptions o) =>
          json(200, envelope(<Map<String, dynamic>>[agreementJson()]));
      await repo.refreshAgreements('t1');

      final RebateAgreement? cached = await repo.cachedAgreement('t1', 'a1');
      expect(cached!.contributions.single.id, 'k1');
    });

    test('agreements that left the list are dropped from the copy', () async {
      adapter.handler = (RequestOptions o) => json(
        200,
        envelope(<Map<String, dynamic>>[agreementJson(id: 'a1'), agreementJson(id: 'a2', code: 'B')]),
      );
      await repo.refreshAgreements('t1');

      adapter.handler = (RequestOptions o) =>
          json(200, envelope(<Map<String, dynamic>>[agreementJson(id: 'a2', code: 'B')]));
      await repo.refreshAgreements('t1');

      expect((await repo.cachedAgreements('t1')).map((RebateAgreement a) => a.id), <String>['a2']);
    });

    test('the copy is tenant scoped', () async {
      adapter.handler = (RequestOptions o) =>
          json(200, envelope(<Map<String, dynamic>>[agreementJson()]));
      await repo.refreshAgreements('t1');

      expect(await repo.cachedAgreements('t2'), isEmpty);
      expect(await repo.cachedAgreement('t2', 'a1'), isNull);
    });
  });

  group('progress and runs', () {
    test('progress is pulled from the endpoint and readable offline', () async {
      adapter.handler = (RequestOptions o) => json(200, envelope(progressJson()));

      final AgreementProgress p = await repo.refreshProgress('t1', 'a1');

      expect(adapter.calls.single.path, '/rebates/agreements/a1/progress');
      expect(p.qualifyingVolume.toFixed2(), '120000.00');
      adapter.handler = offline;
      final AgreementProgress? cached = await repo.cachedProgress('t1', 'a1');
      expect(cached!.tier!.distanceToNext!.toFixed2(), '130000.00');
      expect(cached.tiers, hasLength(3));
    });

    test('offline refresh throws an offline exception and keeps the copy', () async {
      adapter.handler = (RequestOptions o) => json(200, envelope(progressJson()));
      await repo.refreshProgress('t1', 'a1');

      adapter.handler = offline;
      await expectLater(
        repo.refreshProgress('t1', 'a1'),
        throwsA(
          isA<RebateException>().having((RebateException e) => e.kind, 'kind', RebateErrorKind.offline),
        ),
      );
      expect(await repo.cachedProgress('t1', 'a1'), isNotNull);
    });

    test('accrual runs are stored per agreement', () async {
      adapter.handler = (RequestOptions o) =>
          json(200, envelope(<Map<String, dynamic>>[runJson(id: 'r1'), runJson(id: 'r2')]));

      final List<AccrualRun> runs = await repo.refreshRuns('t1', 'a1');

      expect(adapter.calls.single.path, '/rebates/agreements/a1/accrual-runs');
      expect(runs, hasLength(2));
      expect((await repo.cachedRuns('t1', 'a1')).map((AccrualRun r) => r.id), <String>['r1', 'r2']);
      expect(await repo.cachedRuns('t1', 'other'), isEmpty);
    });
  });

  group('proposals', () {
    test('refresh stores the proposals, open ones first', () async {
      adapter.handler = (RequestOptions o) => json(
        200,
        envelope(<Map<String, dynamic>>[
          proposalJson(id: 'done', status: 'settled', createdAt: '2027-09-01T00:00:00Z'),
          proposalJson(id: 'open'),
        ]),
      );

      final List<SettlementProposal> fresh = await repo.refreshProposals('t1');

      expect(fresh.map((SettlementProposal p) => p.id), <String>['open', 'done']);
      expect((await repo.cachedProposals('t1')).map((SettlementProposal p) => p.id), <String>['open', 'done']);
    });

    test('a scoped refresh sends agreement_id and only replaces that agreement', () async {
      adapter.handler = (RequestOptions o) => json(
        200,
        envelope(<Map<String, dynamic>>[
          proposalJson(id: 'p1'),
          proposalJson(id: 'q1', agreementId: 'a2'),
        ]),
      );
      await repo.refreshProposals('t1');

      adapter.handler = (RequestOptions o) =>
          json(200, envelope(<Map<String, dynamic>>[proposalJson(id: 'p2')]));
      await repo.refreshProposals('t1', agreementId: 'a1');

      expect(adapter.calls.last.queryParameters, containsPair('agreement_id', 'a1'));
      final List<String> ids = (await repo.cachedProposals('t1')).map((SettlementProposal p) => p.id).toList()
        ..sort();
      expect(ids, <String>['p2', 'q1']);
      expect(
        (await repo.cachedProposals('t1', agreementId: 'a1')).map((SettlementProposal p) => p.id),
        <String>['p2'],
      );
    });

    test('a single proposal is pulled and cached', () async {
      adapter.handler = (RequestOptions o) =>
          json(200, envelope(proposalJson(status: 'pending_approval')));

      final SettlementProposal p = await repo.refreshProposal('t1', 'p1');

      expect(adapter.calls.single.path, '/rebates/settlement-proposals/p1');
      expect(p.status, ProposalStatus.pendingApproval);
      expect((await repo.cachedProposal('t1', 'p1'))!.lines, hasLength(2));
    });
  });

  group('blanket agreements', () {
    test('contracts and balance are cached for offline reading', () async {
      adapter.handler = (RequestOptions o) =>
          json(200, envelope(<Map<String, dynamic>>[contractJson()]));
      expect(await repo.refreshContracts('t1'), hasLength(1));
      expect(adapter.calls.single.path, '/procurement/contracts');

      adapter.handler = (RequestOptions o) => json(200, envelope(balanceJson()));
      final BlanketBalance b = await repo.refreshBalance('t1', 'sc1');
      expect(adapter.calls.last.path, '/procurement/contracts/sc1/balance');
      expect(b.alerts.single.code, BalanceAlertCode.ceilingNear);

      adapter.handler = offline;
      expect((await repo.cachedContracts('t1')).single.id, 'sc1');
      expect((await repo.cachedBalance('t1', 'sc1'))!.ceilingUsedPercent!.toFixed2(), '85.00');
      expect(await repo.cachedBalance('t1', 'nope'), isNull);
    });
  });

  group('errors', () {
    test('HTTP failures map to exception kinds and keep the problem detail', () async {
      adapter.handler = (RequestOptions o) => json(403, <String, dynamic>{'detail': 'No access'});
      await expectLater(
        repo.refreshAgreements('t1'),
        throwsA(isA<RebateException>().having((RebateException e) => e.kind, 'kind', RebateErrorKind.forbidden)),
      );

      adapter.handler = (RequestOptions o) => json(404, <String, dynamic>{});
      await expectLater(
        repo.refreshProposal('t1', 'x'),
        throwsA(isA<RebateException>().having((RebateException e) => e.kind, 'kind', RebateErrorKind.notFound)),
      );

      adapter.handler = (RequestOptions o) => json(422, <String, dynamic>{'detail': 'Version conflict'});
      await expectLater(
        repo.refreshProposal('t1', 'x'),
        throwsA(
          isA<RebateException>()
              .having((RebateException e) => e.kind, 'kind', RebateErrorKind.invalid)
              .having((RebateException e) => e.detail, 'detail', 'Version conflict'),
        ),
      );

      adapter.handler = (RequestOptions o) => json(500, <String, dynamic>{});
      await expectLater(
        repo.refreshProposal('t1', 'x'),
        throwsA(isA<RebateException>().having((RebateException e) => e.kind, 'kind', RebateErrorKind.unknown)),
      );
    });
  });

  group('outbox', () {
    test('online, an action is sent at once with the version the user saw', () async {
      adapter.handler = (RequestOptions o) => json(200, envelope(proposalJson(status: 'approved')));

      final ActionOutcome outcome = await repo.act('t1', 'p1', ProposalAction.approve, version: 2);

      expect(outcome.status, ActionStatus.sent);
      expect(adapter.calls.single.path, '/rebates/settlement-proposals/p1/approve');
      expect(adapter.calls.single.method, 'POST');
      expect(adapter.calls.single.data, containsPair('version', 2));
      expect(await repo.pendingActions('t1'), isEmpty);
    });

    test('offline, the action is queued and replayed with its queue uuid as idempotency key', () async {
      adapter.handler = offline;

      final ActionOutcome submit = await repo.act('t1', 'p1', ProposalAction.submit, version: 1);
      final ActionOutcome cancel = await repo.act('t1', 'p2', ProposalAction.cancel);

      expect(submit.status, ActionStatus.queued);
      expect(cancel.status, ActionStatus.queued);
      final List<PendingAction> pending = await repo.pendingActions('t1');
      expect(pending.map((PendingAction a) => (a.proposalId, a.action)), <(String, ProposalAction)>[
        ('p1', ProposalAction.submit),
        ('p2', ProposalAction.cancel),
      ]);
      expect(await repo.pendingActions('t1', proposalId: 'p2'), hasLength(1));
      expect(await repo.pendingActions('t1', proposalId: 'other'), isEmpty);

      final List<String> keys = <String>[];
      adapter.calls.clear();
      adapter.handler = (RequestOptions o) {
        keys.add('${o.headers['Idempotency-Key']}');
        return json(200, envelope(proposalJson()));
      };
      expect(await repo.flush('t1'), 2);

      expect(adapter.calls.map((RequestOptions c) => c.path), <String>[
        '/rebates/settlement-proposals/p1/submit',
        '/rebates/settlement-proposals/p2/cancel',
      ]);
      expect(keys, <String>[for (final PendingAction a in pending) a.queueUuid]);
      expect(await repo.pendingActions('t1'), isEmpty);
    });

    test('a second tap on the same action while it is queued adds nothing', () async {
      adapter.handler = offline;

      await repo.act('t1', 'p1', ProposalAction.approve, version: 2);
      final ActionOutcome again = await repo.act('t1', 'p1', ProposalAction.approve, version: 2);

      expect(again.status, ActionStatus.queued);
      expect(await repo.pendingActions('t1'), hasLength(1));
      // Another action of the same proposal is a different request.
      await repo.act('t1', 'p1', ProposalAction.cancel, version: 2);
      expect(await repo.pendingActions('t1'), hasLength(2));
    });

    test('the queued body carries the version', () async {
      adapter.handler = offline;

      await repo.act('t1', 'p1', ProposalAction.approve, version: 7);

      final List<QueueItem> rows = await db.select(db.syncQueue).get();
      expect(jsonDecode(rows.single.payload!), containsPair('version', 7));
      expect(rows.single.entity, rebateActionEntity);
    });

    test('a 422 (wrong state or version conflict) parks the action as rejected, it is not resent and can be dismissed', () async {
      adapter.handler = (RequestOptions o) =>
          json(422, <String, dynamic>{'detail': 'Version conflict'});

      final ActionOutcome outcome = await repo.act('t1', 'p1', ProposalAction.approve, version: 1);

      expect(outcome.status, ActionStatus.rejected);
      expect(outcome.detail, isNotEmpty);
      final PendingAction rejected = (await repo.pendingActions('t1')).single;
      expect(rejected.rejected, isTrue);

      adapter.calls.clear();
      expect(await repo.flush('t1'), 0);
      expect(adapter.calls, isEmpty);

      await repo.dismissAction(rejected.queueUuid);
      expect(await repo.pendingActions('t1'), isEmpty);
      adapter.handler = offline;
      expect((await repo.act('t1', 'p1', ProposalAction.approve, version: 3)).status, ActionStatus.queued);
    });

    test('a rejected action can be retried', () async {
      adapter.handler = (RequestOptions o) => json(403, <String, dynamic>{'detail': 'No right'});
      await repo.act('t1', 'p1', ProposalAction.approve, version: 1);
      final PendingAction rejected = (await repo.pendingActions('t1')).single;

      adapter.handler = (RequestOptions o) => json(200, envelope(proposalJson(status: 'approved')));
      await repo.retryAction('t1', rejected.queueUuid);

      expect(await repo.pendingActions('t1'), isEmpty);
    });

    test('outbox rows are tenant scoped', () async {
      adapter.handler = offline;
      await repo.act('t1', 'p1', ProposalAction.submit, version: 1);

      expect(await repo.pendingActions('t2'), isEmpty);
      adapter.calls.clear();
      expect(await repo.flush('t2'), 0);
      expect(adapter.calls, isEmpty);
      expect(await repo.pendingActions('t1'), hasLength(1));
    });

    test('the rebate action entity is terminal in the sync engine', () {
      expect(SyncEngine.defaultTerminalEntities, contains(rebateActionEntity));
    });
  });
}
