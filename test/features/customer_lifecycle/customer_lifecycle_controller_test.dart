import 'package:dio/dio.dart';
import 'package:fattura_facile/features/customer_lifecycle/data/customer_lifecycle_remote_data_source.dart';
import 'package:fattura_facile/features/customer_lifecycle/domain/customer_lifecycle_models.dart';
import 'package:fattura_facile/features/customer_lifecycle/l10n/customer_lifecycle_strings.dart';
import 'package:fattura_facile/features/customer_lifecycle/presentation/customer_lifecycle_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/sync_engine_test.dart' show FakeAdapter, json;

Map<String, dynamic> _summary() => <String, dynamic>{
  'data': <String, dynamic>{
    'health': <String, dynamic>{'health_index': 70.5, 'churn_risk': 'low'},
    'kpis': <String, dynamic>{
      'lifetime_value': '1000.00',
      'contract_coverage': 'covered',
      'open_tickets': 2,
    },
  },
};

ProviderContainer _container(FakeAdapter adapter) {
  final Dio dio = Dio(BaseOptions(baseUrl: 'http://x/api/v1'))
    ..httpClientAdapter = adapter;
  return ProviderContainer(
    overrides: [
      customerLifecycleRemoteProvider.overrideWithValue(
        CustomerLifecycleRemoteDataSource(dio),
      ),
    ],
  );
}

void main() {
  const LifecycleContact contact = LifecycleContact(id: 'c1', label: 'Rossi SA');

  test('searches contacts and ignores an empty query', () async {
    final FakeAdapter adapter = FakeAdapter(
      (RequestOptions o) => json(200, <String, dynamic>{
        'data': <Map<String, dynamic>>[
          <String, dynamic>{'id': 'c1', 'company_name': 'Rossi SA'},
          <String, dynamic>{'id': 'c2', 'first_name': 'Anna', 'last_name': 'Verdi'},
        ],
      }),
    );
    final ProviderContainer c = _container(adapter);
    addTearDown(c.dispose);
    final CustomerLifecycleController controller = c.read(
      customerLifecycleControllerProvider.notifier,
    );

    await controller.search('  ');
    expect(adapter.calls, isEmpty);

    await controller.search('ro');
    final List<LifecycleContact> results = c
        .read(customerLifecycleControllerProvider)
        .results;
    expect(results.map((LifecycleContact r) => r.label), <String>[
      'Rossi SA',
      'Anna Verdi',
    ]);
  });

  test('selecting a customer loads its summary and timeline', () async {
    final FakeAdapter adapter = FakeAdapter((RequestOptions o) {
      if (o.path.endsWith('/crm/accounts')) {
        return json(200, <String, dynamic>{
          'data': <Map<String, dynamic>>[
            <String, dynamic>{'id': 'a1'},
          ],
        });
      }
      if (o.path.endsWith('/360')) {
        return json(200, _summary());
      }
      return json(200, <String, dynamic>{
        'data': <Map<String, dynamic>>[
          <String, dynamic>{
            'type': 'ticket',
            'id': 't1',
            'occurred_at': '2026-03-01T10:00:00+00:00',
            'title': 'Chiller offline',
          },
        ],
      });
    });
    final ProviderContainer c = _container(adapter);
    addTearDown(c.dispose);

    await c.read(customerLifecycleControllerProvider.notifier).select(contact);

    final CustomerLifecycleState state = c.read(
      customerLifecycleControllerProvider,
    );
    expect(state.loading, isFalse);
    expect(state.view!.summary.healthIndex, 70.5);
    expect(state.view!.summary.kpis.openTickets, 2);
    expect(state.view!.timeline.single.title, 'Chiller offline');
  });

  test('a customer without an account reports it', () async {
    final FakeAdapter adapter = FakeAdapter(
      (RequestOptions o) => json(200, <String, dynamic>{'data': <dynamic>[]}),
    );
    final ProviderContainer c = _container(adapter);
    addTearDown(c.dispose);

    await c.read(customerLifecycleControllerProvider.notifier).select(contact);

    final CustomerLifecycleState state = c.read(
      customerLifecycleControllerProvider,
    );
    expect(state.noAccount, isTrue);
    expect(state.view, isNull);
  });

  test('filtering reloads the timeline with the chosen types', () async {
    final FakeAdapter adapter = FakeAdapter((RequestOptions o) {
      if (o.path.endsWith('/crm/accounts')) {
        return json(200, <String, dynamic>{
          'data': <Map<String, dynamic>>[
            <String, dynamic>{'id': 'a1'},
          ],
        });
      }
      if (o.path.endsWith('/360')) {
        return json(200, _summary());
      }
      return json(200, <String, dynamic>{'data': <dynamic>[]});
    });
    final ProviderContainer c = _container(adapter);
    addTearDown(c.dispose);
    final CustomerLifecycleController controller = c.read(
      customerLifecycleControllerProvider.notifier,
    );

    await controller.select(contact);
    await controller.filter(<String>['ticket', 'invoice']);

    expect(adapter.calls.last.queryParameters['types[]'], <String>[
      'ticket',
      'invoice',
    ]);
    expect(c.read(customerLifecycleControllerProvider).types, <String>[
      'ticket',
      'invoice',
    ]);
  });

  test('a server failure is kept as a typed error', () async {
    final FakeAdapter adapter = FakeAdapter(
      (RequestOptions o) => json(403, <String, dynamic>{'message': 'no'}),
    );
    final ProviderContainer c = _container(adapter);
    addTearDown(c.dispose);

    await c.read(customerLifecycleControllerProvider.notifier).select(contact);

    expect(
      c.read(customerLifecycleControllerProvider).error,
      LifecycleErrorKind.forbidden,
    );
  });

  test('every language has every label', () {
    for (final MapEntry<String, Map<CL, String>> table
        in CustomerLifecycleStrings.tables.entries) {
      for (final CL key in CL.values) {
        expect(table.value[key], isNotNull, reason: '${table.key} misses $key');
      }
    }
    expect(CustomerLifecycleStrings.tables.keys, containsAll(<String>[
      'it',
      'en',
      'de',
      'fr',
    ]));
  });
}
