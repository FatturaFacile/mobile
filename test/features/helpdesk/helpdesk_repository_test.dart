import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:fattura_facile/core/database/app_database.dart';
import 'package:fattura_facile/core/sync/sync_engine.dart';
import 'package:fattura_facile/features/helpdesk/data/helpdesk_repository_impl.dart';
import 'package:fattura_facile/features/helpdesk/domain/helpdesk_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/sync_engine_test.dart' show FakeAdapter, json;

Map<String, dynamic> envelope(Object data) => <String, dynamic>{
  'success': true,
  'message': 'ok',
  'data': data,
};

Map<String, dynamic> risk(
  String id,
  double pct, {
  String priority = 'medium',
}) => <String, dynamic>{
  'ticket_id': id,
  'ticket_number': 'TK-$id',
  'subject': 'S$id',
  'priority': priority,
  'status': 'open',
  'risk_percent': pct,
  'targets': <Map<String, dynamic>>[
    <String, dynamic>{
      'target': 'resolution',
      'due_at': '2030-01-01T12:00:00Z',
      'elapsed_percent': pct,
      'state': pct >= 100 ? 'breached' : 'at_risk',
    },
  ],
};

Never offline(RequestOptions o) =>
    throw DioException.connectionError(requestOptions: o, reason: 'down');

void main() {
  late AppDatabase db;
  late FakeAdapter adapter;
  late Dio dio;
  late HelpdeskRepositoryImpl repo;

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
    repo = HelpdeskRepositoryImpl(db, dio, SyncEngine(db, dio));
  });

  tearDown(() => db.close());

  group('queue', () {
    test('refresh merges /tickets with breach-risk, sorts by risk and stores an offline copy', () async {
      adapter.handler = (RequestOptions o) {
        if (o.path.endsWith('/helpdesk/breach-risk')) {
          return json(
            200,
            envelope(<Map<String, dynamic>>[
              risk('2', 90),
              risk('3', 110, priority: 'high'),
            ]),
          );
        }
        return json(
          200,
          envelope(<Map<String, dynamic>>[
            <String, dynamic>{
              'id': '1',
              'ticket_number': 'TK-1',
              'subject': 'S1',
              'priority': 'critical',
              'status': 'open',
            },
            <String, dynamic>{
              'id': '2',
              'ticket_number': 'TK-2',
              'subject': 'S2',
              'priority': 'medium',
              'status': 'open',
            },
            <String, dynamic>{
              'id': '9',
              'ticket_number': 'TK-9',
              'subject': 'S9',
              'priority': 'high',
              'status': 'closed',
            },
          ]),
        );
      };

      final List<QueueTicket> fresh = await repo.refreshQueue('t1');

      expect(fresh.map((QueueTicket t) => t.id), <String>['3', '2', '1']);
      final RequestOptions riskCall = adapter.calls.firstWhere(
        (RequestOptions c) => c.path.endsWith('/breach-risk'),
      );
      expect(riskCall.path, '/esm/helpdesk/breach-risk');
      expect(riskCall.queryParameters, <String, dynamic>{
        'risk_percent': 75,
        'limit': 100,
      });
      expect(
        (await repo.cachedQueue('t1')).map((QueueTicket t) => t.id),
        <String>['3', '2', '1'],
      );
      expect((await repo.cachedTicket('t1', '1'))!.priority.badge, 'P1');
      expect(await repo.cachedQueue('other-tenant'), isEmpty);
    });

    test(
      'offline refresh throws offline and keeps the previous copy',
      () async {
        adapter.handler = (RequestOptions o) =>
            json(200, envelope(<Map<String, dynamic>>[risk('1', 80)]));
        await repo.refreshQueue('t1');

        adapter.handler = offline;

        await expectLater(
          repo.refreshQueue('t1'),
          throwsA(
            isA<HelpdeskException>().having(
              (HelpdeskException e) => e.kind,
              'kind',
              HelpdeskErrorKind.offline,
            ),
          ),
        );
        expect(await repo.cachedQueue('t1'), hasLength(1));
      },
    );

    test('403 maps to forbidden', () async {
      adapter.handler = (RequestOptions o) =>
          json(403, <String, dynamic>{'detail': 'no'});

      await expectLater(
        repo.refreshQueue('t1'),
        throwsA(
          isA<HelpdeskException>().having(
            (HelpdeskException e) => e.kind,
            'kind',
            HelpdeskErrorKind.forbidden,
          ),
        ),
      );
    });
  });

  group('ticket detail', () {
    test(
      'customer context and time entries are cached for offline reading',
      () async {
        adapter.handler = (RequestOptions o) {
          if (o.path.endsWith('/customer-context')) {
            return json(
              200,
              envelope(<String, dynamic>{
                'contracts': <Map<String, dynamic>>[
                  <String, dynamic>{'name': 'Gold', 'remaining_hours': 12.5},
                ],
                'assets': <dynamic>[],
                'open_invoices': <Map<String, dynamic>>[
                  <String, dynamic>{'number': 'F-1', 'total': '100.00'},
                ],
                'recent_tickets': <dynamic>[],
              }),
            );
          }
          return json(
            200,
            envelope(<Map<String, dynamic>>[
              <String, dynamic>{
                'id': 'e1',
                'minutes': 30,
                'billing_status': 'contract_deducted',
              },
            ]),
          );
        };

        final CustomerContext ctx = await repo.refreshContext('t1', '7');
        final List<TimeEntry> entries = await repo.refreshTimeEntries(
          't1',
          '7',
        );

        expect(adapter.calls.map((RequestOptions c) => c.path), <String>[
          '/esm/tickets/7/customer-context',
          '/esm/tickets/7/time-entries',
        ]);
        expect(ctx.contracts.single.detail, '12.5');
        expect(entries.single.billingStatus, BillingStatus.contractDeducted);

        adapter.handler = offline;
        final CustomerContext? cachedCtx = await repo.cachedContext('t1', '7');
        expect(cachedCtx!.openInvoices.single.title, 'F-1');
        expect((await repo.cachedTimeEntries('t1', '7')).single.minutes, 30);
        expect(await repo.cachedContext('t1', 'unknown'), isNull);
      },
    );
  });

  group('outbox', () {
    test('online time logging posts the entry with an Idempotency-Key and leaves nothing queued', () async {
      adapter.handler = (RequestOptions o) =>
          json(200, envelope(<String, dynamic>{'id': 'e1'}));

      final ActionOutcome outcome = await repo.logTime(
        't1',
        '7',
        minutes: 45,
        technicianId: 'u1',
        description: ' fixed ',
      );

      expect(outcome.status, ActionStatus.sent);
      final RequestOptions call = adapter.calls.single;
      expect(call.method, 'POST');
      expect(call.path, '/esm/tickets/7/time-entries');
      expect(call.headers['Idempotency-Key'], isNotEmpty);
      expect(call.data, <String, dynamic>{
        'minutes': 45,
        'technician_id': 'u1',
        'description': 'fixed',
        'is_billable': true,
      });
      expect(await repo.pendingActions('t1'), isEmpty);
    });

    test('offline time logging and escalation wait in the outbox, then replay with the same idempotency keys', () async {
      adapter.handler = offline;

      final ActionOutcome time = await repo.logTime('t1', '7', minutes: 15);
      final ActionOutcome esc = await repo.escalate(
        't1',
        '7',
        EscalationTarget.fieldService,
      );

      expect(time.status, ActionStatus.queued);
      expect(esc.status, ActionStatus.queued);
      final List<PendingAction> pending = await repo.pendingActions('t1');
      expect(pending.map((PendingAction a) => a.kind), <PendingActionKind>[
        PendingActionKind.timeEntry,
        PendingActionKind.fieldService,
      ]);
      expect(pending.first.minutes, 15);
      expect(await repo.pendingActions('t1', ticketId: 'other'), isEmpty);

      final List<String> keys = <String>[];
      adapter.calls.clear();
      adapter.handler = (RequestOptions o) {
        keys.add('${o.headers['Idempotency-Key']}');
        return json(200, envelope(<String, dynamic>{'id': 'x'}));
      };
      expect(await repo.flush('t1'), 2);

      expect(adapter.calls.map((RequestOptions c) => c.path), <String>[
        '/esm/tickets/7/time-entries',
        '/esm/tickets/7/escalate/field-service',
      ]);
      expect(keys, <String>[
        for (final PendingAction a in pending) a.queueUuid,
      ]);
      expect(await repo.pendingActions('t1'), isEmpty);
      // A second flush has nothing to replay: the rows were acknowledged.
      adapter.calls.clear();
      expect(await repo.flush('t1'), 0);
      expect(adapter.calls, isEmpty);
    });

    test('a replay after an unacknowledged send reuses the same key (the server answers 200 with the existing record)', () async {
      adapter.handler = offline;
      await repo.escalate('t1', '7', EscalationTarget.rma);
      final String key = (await repo.pendingActions('t1')).single.queueUuid;

      // The server stored it but the response was lost: the row is still queued and goes out again unchanged.
      final List<String> sent = <String>[];
      adapter.handler = (RequestOptions o) {
        sent.add('${o.headers['Idempotency-Key']}');
        return json(200, envelope(<String, dynamic>{'id': 'rma1'}));
      };
      await repo.flush('t1');

      expect(sent, <String>[key]);
    });

    test('a second tap on escalate while one is queued adds nothing', () async {
      adapter.handler = offline;

      await repo.escalate('t1', '7', EscalationTarget.rma);
      final ActionOutcome again = await repo.escalate(
        't1',
        '7',
        EscalationTarget.rma,
      );

      expect(again.status, ActionStatus.queued);
      expect(await repo.pendingActions('t1'), hasLength(1));
      // The other target is a different escalation.
      await repo.escalate('t1', '7', EscalationTarget.fieldService);
      expect(await repo.pendingActions('t1'), hasLength(2));
    });

    test('422 on a closed ticket parks the escalation as rejected, it is not resent and can be dismissed', () async {
      adapter.handler = (RequestOptions o) =>
          json(422, <String, dynamic>{'detail': 'Ticket is closed'});

      final ActionOutcome outcome = await repo.escalate(
        't1',
        '7',
        EscalationTarget.fieldService,
      );

      expect(outcome.status, ActionStatus.rejected);
      expect(outcome.detail, isNotEmpty);
      final PendingAction rejected = (await repo.pendingActions('t1')).single;
      expect(rejected.rejected, isTrue);

      adapter.calls.clear();
      expect(await repo.flush('t1'), 0);
      expect(adapter.calls, isEmpty);

      await repo.dismissAction(rejected.queueUuid);
      expect(await repo.pendingActions('t1'), isEmpty);
      // After dismissing, a new tap is accepted again.
      adapter.handler = offline;
      expect(
        (await repo.escalate('t1', '7', EscalationTarget.fieldService)).status,
        ActionStatus.queued,
      );
    });

    test('outbox rows are tenant scoped', () async {
      adapter.handler = offline;
      await repo.logTime('t1', '7', minutes: 5);

      expect(await repo.pendingActions('t2'), isEmpty);
      adapter.calls.clear();
      expect(await repo.flush('t2'), 0);
      expect(adapter.calls, isEmpty);
      expect(await repo.pendingActions('t1'), hasLength(1));
      expect(
        jsonDecode((await _queueRows(db)).single.payload!),
        containsPair('minutes', 5),
      );
    });
  });
}

Future<List<QueueItem>> _queueRows(AppDatabase db) =>
    db.select(db.syncQueue).get();
