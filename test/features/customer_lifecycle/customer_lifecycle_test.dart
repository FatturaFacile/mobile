import 'package:dio/dio.dart';
import 'package:fattura_facile/features/customer_lifecycle/data/customer_lifecycle_remote_data_source.dart';
import 'package:fattura_facile/features/customer_lifecycle/domain/customer_lifecycle_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/sync_engine_test.dart' show FakeAdapter, json;

void main() {
  late FakeAdapter adapter;
  late CustomerLifecycleRemoteDataSource remote;

  void serve(ResponseBody Function(RequestOptions o) handler) {
    adapter = FakeAdapter(handler);
    final Dio dio = Dio(BaseOptions(baseUrl: 'http://x/api/v1'))
      ..httpClientAdapter = adapter;
    remote = CustomerLifecycleRemoteDataSource(dio);
  }

  test('finds the account of a contact in a plain or paginated list', () async {
    serve(
      (RequestOptions o) => json(200, <String, dynamic>{
        'data': <String, dynamic>{
          'data': <Map<String, dynamic>>[
            <String, dynamic>{'id': 'a1'},
          ],
        },
      }),
    );

    expect(await remote.findAccountId('c1'), 'a1');
    expect(adapter.calls.single.queryParameters['contact_id'], 'c1');

    serve(
      (RequestOptions o) => json(200, <String, dynamic>{
        'data': <Map<String, dynamic>>[
          <String, dynamic>{'id': 'a2'},
        ],
      }),
    );
    expect(await remote.findAccountId('c1'), 'a2');
  });

  test('returns null when the contact has no CRM account', () async {
    serve(
      (RequestOptions o) => json(200, <String, dynamic>{'data': <dynamic>[]}),
    );

    expect(await remote.findAccountId('c1'), isNull);
  });

  test('parses the 360 summary with health and KPIs', () async {
    serve(
      (RequestOptions o) => json(200, <String, dynamic>{
        'data': <String, dynamic>{
          'health': <String, dynamic>{
            'health_index': 70.5,
            'churn_risk': 'medium',
          },
          'kpis': <String, dynamic>{
            'lifetime_value': '1000.00',
            'open_pipeline_value': '500.00',
            'overdue_receivable_amount': '0.00',
            'open_tickets': 2,
            'sla_breach_rate': 10.0,
            'mttr_hours': 4.5,
            'active_contracts': 1,
            'contract_coverage': 'covered',
            'contract_hours_remaining': '8.00',
            'interventions_scheduled': 1,
            'interventions_completed': 3,
          },
        },
      }),
    );

    final CustomerLifecycleSummary summary = await remote.summary('a1');

    expect(summary.healthIndex, 70.5);
    expect(summary.churnRisk, 'medium');
    expect(summary.kpis.contractCoverage, 'covered');
    expect(summary.kpis.mttrHours, 4.5);
    expect(summary.kpis.interventionsCompleted, 3);
    expect(adapter.calls.single.path, endsWith('/crm/customers/a1/360'));
  });

  test('sends the type filters and parses the timeline', () async {
    serve(
      (RequestOptions o) => json(200, <String, dynamic>{
        'data': <Map<String, dynamic>>[
          <String, dynamic>{
            'type': 'ticket',
            'id': 't1',
            'occurred_at': '2026-03-01T10:00:00+00:00',
            'title': 'Chiller offline',
            'status': 'open',
            'amount': null,
            'reference': 'T-1',
          },
        ],
      }),
    );

    final List<CustomerTimelineEvent> events = await remote.timeline(
      'a1',
      types: <String>['ticket', 'invoice'],
    );

    expect(events.single.title, 'Chiller offline');
    expect(events.single.reference, 'T-1');
    expect(adapter.calls.single.queryParameters['types[]'], <String>[
      'ticket',
      'invoice',
    ]);
    expect(kTimelineTypes, contains('work_order'));
  });

  test('maps HTTP failures to a typed error', () async {
    serve((RequestOptions o) => json(404, <String, dynamic>{'message': 'no'}));

    await expectLater(
      remote.summary('a1'),
      throwsA(
        isA<LifecycleRemoteException>().having(
          (LifecycleRemoteException e) => e.kind,
          'kind',
          LifecycleErrorKind.notFound,
        ),
      ),
    );
  });
}
