import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:fattura_facile/core/database/app_database.dart';
import 'package:fattura_facile/core/sync/sync_engine.dart';
import 'package:fattura_facile/features/customer_lifecycle/data/customer_lifecycle_remote_data_source.dart';
import 'package:fattura_facile/features/customer_lifecycle/domain/customer_lifecycle_models.dart';
import 'package:fattura_facile/features/customer_lifecycle/presentation/customer_lifecycle_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/sync_engine_test.dart' show FakeAdapter, json;

const String _tenant = 't1';

void main() {
  late AppDatabase db;
  late FakeAdapter adapter;
  late bool online;
  late int activityStatus;
  late ProviderContainer container;
  late SyncEngine engine;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    online = true;
    activityStatus = 201;
    adapter = FakeAdapter((RequestOptions o) {
      if (o.path.endsWith('/crm/activities')) {
        if (!online) {
          throw DioException.connectionError(
            requestOptions: o,
            reason: 'unreachable',
          );
        }
        return json(
          activityStatus,
          activityStatus == 422
              ? <String, dynamic>{'message': 'invalid'}
              : <String, dynamic>{
                  'data': <String, dynamic>{'id': 'act1'},
                },
        );
      }
      if (o.path.endsWith('/crm/accounts')) {
        return json(200, <String, dynamic>{
          'data': <Map<String, dynamic>>[
            <String, dynamic>{'id': 'a1'},
          ],
        });
      }
      if (o.path.endsWith('/360')) {
        return json(200, <String, dynamic>{
          'data': <String, dynamic>{
            'health': <String, dynamic>{'health_index': 70.5},
            'kpis': <String, dynamic>{'contract_coverage': 'none'},
          },
        });
      }
      return json(200, <String, dynamic>{'data': <dynamic>[]});
    });
    final Dio dio = Dio(BaseOptions(baseUrl: 'http://x/api/v1'))
      ..httpClientAdapter = adapter;
    engine = SyncEngine(db, dio);
    container = ProviderContainer(
      overrides: [
        customerLifecycleRemoteProvider.overrideWithValue(
          CustomerLifecycleRemoteDataSource(dio),
        ),
        lifecycleSyncEngineProvider.overrideWithValue(engine),
        lifecycleTenantIdProvider.overrideWithValue(_tenant),
      ],
    );
    await container
        .read(customerLifecycleControllerProvider.notifier)
        .select(const LifecycleContact(id: 'c1', label: 'Rossi SA'));
    adapter.calls.clear();
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  CustomerLifecycleController controller() =>
      container.read(customerLifecycleControllerProvider.notifier);

  Iterable<RequestOptions> activityCalls() => adapter.calls.where(
    (RequestOptions o) => o.path.endsWith('/crm/activities'),
  );

  test('log visit posts a meeting activity on the account', () async {
    final QuickActionOutcome outcome = await controller().quickAction(
      LifecycleQuickAction.logVisit,
      '  Site visit  ',
    );

    expect(outcome, QuickActionOutcome.sent);
    final RequestOptions call = activityCalls().single;
    expect(call.method, 'POST');
    expect(call.data, <String, dynamic>{
      'type': 'meeting',
      'subject': 'Site visit',
      'due_date': null,
      'related_type': 'account',
      'related_id': 'a1',
    });
    expect(await engine.queued(_tenant, lifecycleActivityEntity), isEmpty);
  });

  test('create follow-up posts follow_up with the due date', () async {
    final QuickActionOutcome outcome = await controller().quickAction(
      LifecycleQuickAction.createFollowUp,
      'Call back',
      dueDate: DateTime(2026, 12, 5),
    );

    expect(outcome, QuickActionOutcome.sent);
    final Map<String, dynamic> body =
        activityCalls().single.data as Map<String, dynamic>;
    expect(body['type'], 'follow_up');
    expect(body['due_date'], '2026-12-05');
  });

  test('an empty or over-long subject is rejected without a request', () async {
    expect(
      await controller().quickAction(LifecycleQuickAction.logVisit, '   '),
      QuickActionOutcome.invalid,
    );
    expect(
      await controller().quickAction(
        LifecycleQuickAction.logVisit,
        List<String>.filled(kActivitySubjectMax + 1, 'x').join(),
      ),
      QuickActionOutcome.invalid,
    );
    expect(adapter.calls, isEmpty);
  });

  test('an unreachable network saves the action in the outbox', () async {
    online = false;

    final QuickActionOutcome outcome = await controller().quickAction(
      LifecycleQuickAction.createFollowUp,
      'Call back',
      dueDate: DateTime(2026, 12, 5),
    );

    expect(outcome, QuickActionOutcome.queued);
    final List<QueueItem> rows = await engine.queued(
      _tenant,
      lifecycleActivityEntity,
    );
    expect(rows, hasLength(1));
    expect(rows.single.method, 'POST');
    expect(rows.single.path, '/crm/activities');
    final Map<String, dynamic> body =
        jsonDecode(rows.single.payload!) as Map<String, dynamic>;
    expect(body['type'], 'follow_up');
    expect(body['related_id'], 'a1');
    expect(await controller().pendingCount(), 1);
  });

  test('replay sends the queued action once the network is back', () async {
    online = false;
    await controller().quickAction(LifecycleQuickAction.logVisit, 'Visit');
    adapter.calls.clear();

    expect(await controller().replayPending(), 0);

    online = true;
    expect(await controller().replayPending(), 1);
    final RequestOptions call = activityCalls().first;
    expect(call.headers['Idempotency-Key'], isNotNull);
    expect((call.data as Map<String, dynamic>)['type'], 'meeting');
    expect(await engine.queued(_tenant, lifecycleActivityEntity), isEmpty);
    expect(await controller().replayPending(), 0);
  });

  test('a 422 validation error is never queued', () async {
    activityStatus = 422;

    final QuickActionOutcome outcome = await controller().quickAction(
      LifecycleQuickAction.logVisit,
      'Visit',
    );

    expect(outcome, QuickActionOutcome.invalid);
    expect(await engine.queued(_tenant, lifecycleActivityEntity), isEmpty);
  });

  test('a replayed action refused with 422 is parked, not resent', () async {
    online = false;
    await controller().quickAction(LifecycleQuickAction.logVisit, 'Visit');
    online = true;
    activityStatus = 422;
    await controller().replayPending();
    adapter.calls.clear();

    await controller().replayPending();

    expect(activityCalls(), isEmpty);
    final List<QueueItem> rows = await engine.queued(
      _tenant,
      lifecycleActivityEntity,
    );
    expect(rows.single.state, QueueState.rejected);
  });
}
