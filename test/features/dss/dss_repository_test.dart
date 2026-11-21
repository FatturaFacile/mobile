import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:fattura_facile/core/database/app_database.dart';
import 'package:fattura_facile/features/dss/data/dss_local_data_source.dart';
import 'package:fattura_facile/features/dss/data/dss_remote_data_source.dart';
import 'package:fattura_facile/features/dss/data/dss_repository_impl.dart';
import 'package:fattura_facile/features/dss/domain/dss_models.dart';
import 'package:fattura_facile/features/dss/domain/dss_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/sync_engine_test.dart' show FakeAdapter, json;
import 'dss_fixtures.dart';

void main() {
  late AppDatabase db;
  late FakeAdapter adapter;
  late DssRepositoryImpl repo;
  late DssLocalDataSource local;
  final DateTime clock = DateTime.utc(2026, 2, 1, 8);

  ResponseBody serve(RequestOptions o) {
    final String currency = '${o.queryParameters['currency'] ?? 'CHF'}';
    return switch (o.path) {
      '/analytics/dss/overview' => json(200, <String, dynamic>{
        'data': overviewJson(currency: currency),
      }),
      '/analytics/dss/profitability-matrix' => json(200, <String, dynamic>{
        'data': profitabilityJson('${o.queryParameters['dimension']}'),
      }),
      '/analytics/dss/variance-bridge' => json(200, <String, dynamic>{
        'data': varianceJson(),
      }),
      '/analytics/dss/simulate' => json(200, <String, dynamic>{
        'data': simulationJson(),
      }),
      '/analytics/dss/legal-entities' => json(200, <String, dynamic>{
        'data': <dynamic>[
          <String, dynamic>{'id': 'le-1', 'name': 'Acme SA', 'currency': 'CHF'},
        ],
      }),
      _ => json(404, <String, dynamic>{}),
    };
  }

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    adapter = FakeAdapter(serve);
    final Dio dio = Dio(BaseOptions(baseUrl: 'http://x/api/v1'))
      ..httpClientAdapter = adapter;
    local = DssLocalDataSource(db);
    repo = DssRepositoryImpl(local, DssRemoteDataSource(dio), now: () => clock);
  });

  tearDown(() => db.close());

  test('nothing is cached before the first sync', () async {
    expect(await repo.cached('t1', const DssFilter()), isNull);
  });

  test('a sync stores the whole snapshot and the cache serves it', () async {
    final DssSyncResult result = await repo.sync('t1', const DssFilter());
    expect(result.status, DssSyncStatus.synced);

    final DssSnapshot snapshot = (await repo.cached('t1', const DssFilter()))!;
    expect(snapshot.overview.kpi('revenue')!.value, 1000);
    expect(snapshot.customers.rows, hasLength(7));
    expect(snapshot.products!.rows, hasLength(7));
    expect(snapshot.variance!.actual, 100);
    expect(snapshot.baseline.cogs, 600);
    expect(snapshot.legalEntities.single.name, 'Acme SA');
    expect(snapshot.syncedAt.toUtc(), clock);
  });

  test('filters are cached independently', () async {
    await repo.sync('t1', const DssFilter());
    expect(await repo.cached('t1', const DssFilter(currency: 'EUR')), isNull);

    await repo.sync('t1', const DssFilter(currency: 'EUR'));
    final DssSnapshot eur = (await repo.cached(
      't1',
      const DssFilter(currency: 'EUR'),
    ))!;
    expect(eur.overview.currency, 'EUR');
    expect(
      (await repo.cached('t1', const DssFilter()))!.overview.currency,
      'CHF',
    );
    expect(await local.count('t1'), 2);
  });

  test('a second sync replaces the snapshot instead of adding a row', () async {
    await repo.sync('t1', const DssFilter());
    await repo.sync('t1', const DssFilter());
    expect(await local.count('t1'), 1);
  });

  test('tenants never see each other snapshots', () async {
    await repo.sync('t1', const DssFilter());
    expect(await repo.cached('t2', const DssFilter()), isNull);
    expect(await local.count('t2'), 0);

    await repo.sync('t2', const DssFilter());
    expect(await local.count('t1'), 1);
    expect(await local.count('t2'), 1);
  });

  test('offline keeps the cached snapshot and reports offline', () async {
    await repo.sync('t1', const DssFilter());
    adapter.handler = (RequestOptions o) => throw DioException.connectionError(
      requestOptions: o,
      reason: 'no network',
    );

    final DssSyncResult result = await repo.sync('t1', const DssFilter());
    expect(result.status, DssSyncStatus.offline);
    final DssSnapshot cached = (await repo.cached('t1', const DssFilter()))!;
    expect(cached.overview.kpi('revenue')!.value, 1000);
  });

  test(
    '401 and 403 map to their own statuses and leave the cache alone',
    () async {
      await repo.sync('t1', const DssFilter());
      adapter.handler = (RequestOptions o) => json(401, <String, dynamic>{});
      expect(
        (await repo.sync('t1', const DssFilter())).status,
        DssSyncStatus.unauthorized,
      );
      adapter.handler = (RequestOptions o) => json(403, <String, dynamic>{});
      expect(
        (await repo.sync('t1', const DssFilter())).status,
        DssSyncStatus.forbidden,
      );
      adapter.handler = (RequestOptions o) => json(500, <String, dynamic>{});
      expect(
        (await repo.sync('t1', const DssFilter())).status,
        DssSyncStatus.failed,
      );
      expect(await repo.cached('t1', const DssFilter()), isNotNull);
    },
  );

  test('a refused optional view does not block the sync', () async {
    adapter.handler = (RequestOptions o) =>
        o.path.endsWith('/variance-bridge') ||
            o.path.endsWith('/simulate') ||
            o.path.endsWith('/legal-entities')
        ? json(403, <String, dynamic>{})
        : serve(o);

    expect(
      (await repo.sync('t1', const DssFilter())).status,
      DssSyncStatus.synced,
    );
    final DssSnapshot snapshot = (await repo.cached('t1', const DssFilter()))!;
    expect(snapshot.variance, isNull);
    expect(snapshot.legalEntities, isEmpty);
    // Without server inputs the what-if baseline is derived from the scorecard.
    expect(snapshot.baseline.revenue, 1000);
  });

  test('an unreadable payload never replaces a good cache', () async {
    await repo.sync('t1', const DssFilter());
    adapter.handler = (RequestOptions o) =>
        json(200, <String, dynamic>{'data': 'broken'});

    final DssSyncResult result = await repo.sync('t1', const DssFilter());
    expect(result.status, DssSyncStatus.failed);
    expect(
      (await repo.cached(
        't1',
        const DssFilter(),
      ))!.overview.kpi('revenue')!.value,
      1000,
    );
  });

  test('the request carries the filter as query parameters', () async {
    await repo.sync(
      't1',
      const DssFilter(
        legalEntityId: 'le-1',
        currency: 'EUR',
        periodPreset: 'QTD',
      ),
    );
    final RequestOptions overview = adapter.calls.firstWhere(
      (RequestOptions o) => o.path == '/analytics/dss/overview',
    );
    expect(overview.queryParameters['currency'], 'EUR');
    expect(overview.queryParameters['period_preset'], 'QTD');
    expect(overview.queryParameters['legal_entity_ids[]'], <String>['le-1']);
  });
}
