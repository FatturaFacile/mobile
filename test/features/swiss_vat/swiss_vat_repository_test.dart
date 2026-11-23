import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:fattura_facile/core/database/app_database.dart';
import 'package:fattura_facile/core/sync/sync_engine.dart';
import 'package:fattura_facile/features/swiss_vat/data/swiss_vat_repository_impl.dart';
import 'package:fattura_facile/features/swiss_vat/domain/swiss_vat_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/sync_engine_test.dart' show FakeAdapter, json;
import 'fixtures.dart';

Never _offline(RequestOptions o) =>
    throw DioException.connectionError(requestOptions: o, reason: 'down');

void main() {
  late AppDatabase db;
  late FakeAdapter adapter;
  late Dio dio;
  late SwissVatRepositoryImpl repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    adapter = FakeAdapter(
      (RequestOptions o) => json(200, swissEnvelope(<dynamic>[])),
    );
    dio = Dio(
      BaseOptions(
        baseUrl: 'http://x/api/v1',
        validateStatus: (int? s) => s != null && s < 300,
      ),
    )..httpClientAdapter = adapter;
    repo = SwissVatRepositoryImpl(db, dio, SyncEngine(db, dio));
  });

  tearDown(() => db.close());

  test('refreshes returns + reconciliation and falls back to Drift cache offline', () async {
    adapter.handler = (RequestOptions o) {
      if (o.path == '/swiss-vat/returns') {
        return json(200, swissEnvelope(<dynamic>[returnJson()]));
      }
      if (o.path == '/swiss-vat/returns/ret-1/reconciliation') {
        return json(200, swissEnvelope(returnJson()));
      }
      return json(200, swissEnvelope(<dynamic>[]));
    };

    final List<SwissVatReturn> rets = await repo.refreshReturns('t1', 2026);
    expect(rets.single.periodLabel, '2026-Q1');

    final SwissVatReturn detailed = await repo.refreshReconciliation(
      't1',
      'ret-1',
    );
    expect(detailed.boxSchedule.length, 2);

    adapter.handler = _offline;
    final List<SwissVatReturn> cached = await repo.cachedReturns('t1', 2026);
    expect(cached.single.boxSchedule.length, 2);
  });

  test('queues Bezugsteuer creation offline and rejects domestic CH/LI', () async {
    final SwissVatActionOutcome domestic = await repo.createBezugsteuer(
      't1',
      BezugsteuerDraft(
        supplierName: 'Zurich AG',
        supplierCountry: 'CH',
        invoiceDate: DateTime(2026, 2, 15),
        description: 'Domestic service',
        netAmountChf: 500,
      ),
    );
    expect(domestic.status, SwissVatActionStatus.rejected);

    adapter.handler = _offline;
    final SwissVatActionOutcome queued = await repo.createBezugsteuer(
      't1',
      BezugsteuerDraft(
        supplierName: 'AWS EMEA',
        supplierCountry: 'LU',
        invoiceDate: DateTime(2026, 2, 15),
        description: 'Cloud SaaS',
        netAmountChf: 1000,
      ),
    );
    expect(queued.status, SwissVatActionStatus.queued);

    final List<BezugsteuerEntry> cached = await repo.cachedBezugsteuer('t1');
    expect(cached.single.supplierCountry, 'LU');
    expect(cached.single.afcBox, '383');
    expect(cached.single.pending, isTrue);
  });
}
