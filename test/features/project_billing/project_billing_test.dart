import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:fattura_facile/core/database/app_database.dart';
import 'package:fattura_facile/features/project_billing/data/project_billing_local_data_source.dart';
import 'package:fattura_facile/features/project_billing/data/project_billing_remote_data_source.dart';
import 'package:fattura_facile/features/project_billing/data/project_billing_repository.dart';
import 'package:fattura_facile/features/project_billing/domain/project_billing_models.dart';
import 'package:fattura_facile/features/project_billing/l10n/project_billing_strings.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/sync_engine_test.dart' show FakeAdapter, json;

Map<String, dynamic> _summary() => <String, dynamic>{
  'project_id': 'p1',
  'currency': 'CHF',
  'billing_model': 'hybrid',
  'contract_value': '100000.00',
  'billed_to_date': '27000.00',
  'draft_billing': '0.00',
  'unbilled_time_and_materials': '240.00',
  'unbilled_milestones': 1,
  'open_sal_certificates': 0,
  'open_sal_invoice_amount': '0.00',
  'retention': <String, dynamic>{
    'withheld': '1500.00',
    'released': '0.00',
    'balance': '1500.00',
    'release_rule': 'on_acceptance',
    'release_date': null,
  },
  'latest_wip_run': <String, dynamic>{
    'period_end_date': '2027-03-31',
    'recognized_revenue_to_date': '20000.00',
    'billed_to_date': '50000.00',
    'wip_asset_or_deferred_revenue_diff': '-30000.00',
    'nature': 'contract_liability',
  },
};

Map<String, dynamic> _contract({String? cig}) => <String, dynamic>{
  'billing_model': 'sal_progress',
  'billing_status': 'active',
  'fiscal_jurisdiction': 'IT',
  'currency_code': 'CHF',
  'contract_total_value': '100000.0000',
  'advance_payment_percent': '10.0000',
  'advance_payment_amount': '0.0000',
  'advance_recouped_amount': '3000.0000',
  'retention_guarantee_percent': cig == null ? '5.0000' : '0.0000',
  'cig': cig,
};

List<dynamic> _certificates() => <dynamic>[
  <String, dynamic>{
    'id': 's1',
    'sal_number': 1,
    'previous_completion_percent': '0.0000',
    'cumulative_completion_percent': '30.0000',
    'cumulative_gross_earned_value': '30000.0000',
    'current_period_gross_sal': '30000.0000',
    'advance_deduction_amount': '3000.0000',
    'guarantee_retention_withheld': '1500.0000',
    'invoice_amount': '27000.0000',
    'net_billable_amount': '25500.0000',
    'is_final': false,
    'status': 'invoiced',
    'period_start_date': '2027-01-01',
    'period_end_date': '2027-01-31',
  },
  <String, dynamic>{
    'id': 's2',
    'sal_number': 2,
    'previous_completion_percent': '30.0000',
    'cumulative_completion_percent': '60.0000',
    'cumulative_gross_earned_value': '60000.0000',
    'current_period_gross_sal': '30000.0000',
    'advance_deduction_amount': '3000.0000',
    'guarantee_retention_withheld': '1500.0000',
    'invoice_amount': '27000.0000',
    'net_billable_amount': '25500.0000',
    'is_final': false,
    'status': 'cancelled',
  },
];

Map<String, dynamic> _retainer() => <String, dynamic>{
  'balance': <String, dynamic>{
    'unit': 'hours',
    'remaining_hours': '4.00',
    'remaining_amount': '0.00',
    'remaining_percent': '10.00',
    'consumed_hours': '36.00',
    'low_balance_threshold_percent': '25.00',
    'is_low_balance': true,
  },
  'entries': <dynamic>[],
};

Map<String, dynamic> _retention() => <String, dynamic>{
  'withheld': '1500.00',
  'released': '500.00',
  'balance': '1000.00',
  'release_rule': 'on_acceptance',
};

void main() {
  group('SAL arithmetic', () {
    test('the first SAL recoups the advance in proportion and withholds the retention', () {
      final SalPreview p = previewSal(
        contractValue: 100000,
        cumulativePercent: 30,
        previousPercent: 0,
        previousCumulativeGross: 0,
        advanceTotal: 10000,
        advanceRecouped: 0,
        retentionPercent: 5,
      )!;
      expect(p.currentGross, 30000);
      expect(p.advanceDeduction, 3000);
      expect(p.retentionWithheld, 1500);
      expect(p.invoiceAmount, 27000);
      expect(p.netBillable, 25500);
      expect(p.isFinal, isFalse);
    });

    test(
      'a later SAL bills the delta against the previous cumulative value',
      () {
        final SalPreview p = previewSal(
          contractValue: 100000,
          cumulativePercent: 55,
          previousPercent: 30,
          previousCumulativeGross: 30000,
          advanceTotal: 10000,
          advanceRecouped: 3000,
          retentionPercent: 5,
        )!;
        expect(p.currentGross, 25000);
        expect(p.advanceDeduction, 2500);
        expect(p.retentionWithheld, 1250);
        expect(p.netBillable, 21250);
      },
    );

    test('the final SAL recoups the whole remaining advance', () {
      final SalPreview p = previewSal(
        contractValue: 100000,
        cumulativePercent: 100,
        previousPercent: 90,
        previousCumulativeGross: 90000,
        advanceTotal: 10000,
        advanceRecouped: 8000,
        retentionPercent: 0,
      )!;
      expect(p.isFinal, isTrue);
      expect(p.advanceDeduction, 2000);
    });

    test('the advance never exceeds the gross of the certificate', () {
      final SalPreview p = previewSal(
        contractValue: 100000,
        cumulativePercent: 10,
        previousPercent: 0,
        previousCumulativeGross: 0,
        advanceTotal: 1000000,
        advanceRecouped: 0,
        retentionPercent: 0,
      )!;
      expect(p.advanceDeduction, 10000);
      expect(p.invoiceAmount, 0);
    });

    test('a progress that does not advance, exceeds 100% or has no value is refused', () {
      SalPreview? preview(
        double cumulative,
        double previous, [
        double value = 100000,
      ]) => previewSal(
        contractValue: value,
        cumulativePercent: cumulative,
        previousPercent: previous,
        previousCumulativeGross: 0,
        advanceTotal: 0,
        advanceRecouped: 0,
        retentionPercent: 0,
      );
      expect(preview(30, 30), isNull);
      expect(preview(101, 0), isNull);
      expect(preview(10, 0, 0), isNull);
    });

    test('a work in progress is an asset, a liability or balanced', () {
      expect(wipNature(10), WipNature.contractAsset);
      expect(wipNature(-0.5), WipNature.contractLiability);
      expect(wipNature(0), WipNature.balanced);
    });
  });

  group('parsing', () {
    final ProjectBillingSnapshot snapshot = ProjectBillingSnapshot.fromParts(
      summary: _summary(),
      contract: _contract(),
      certificates: _certificates(),
      retainer: _retainer(),
      retention: _retention(),
      syncedAt: DateTime.utc(2027, 3, 1),
    );

    test(
      'reads the billing position, the WIP nature and the retention held',
      () {
        expect(snapshot.summary.currency, 'CHF');
        expect(snapshot.summary.unbilledTimeAndMaterials, 240);
        expect(snapshot.summary.unbilledMilestones, 1);
        expect(snapshot.summary.retentionHeld, 1500);
        expect(snapshot.summary.latestWip!.nature, WipNature.contractLiability);
      },
    );

    test('reads the certificates and keeps the last live one as the base of the next', () {
      expect(snapshot.certificates, hasLength(2));
      expect(snapshot.certificates.last.isLive, isFalse);
      expect(snapshot.certificates.first.isOpen, isFalse);
      expect(snapshot.lastLive!.number, 1);
    });

    test('reads the retainer burn-down and the retention', () {
      expect(snapshot.retainer!.isLow, isTrue);
      expect(snapshot.retainer!.burned, closeTo(0.9, 0.0001));
      expect(snapshot.retainer!.byHours, isTrue);
      expect(snapshot.retention!.balance, 1000);
    });

    test('previews the next SAL against the live certificates and the contract terms', () {
      final SalPreview p = snapshot.previewNext(55)!;
      expect(p.currentGross, 25000);
      expect(p.advanceDeduction, 2500);
      expect(snapshot.previewNext(30), isNull);
    });

    test(
      'an Italian public contract withholds 0.50% when it states no retention',
      () {
        final ProjectBillingSnapshot publicContract =
            ProjectBillingSnapshot.fromParts(
              summary: _summary(),
              contract: _contract(cig: 'Z1234567AB'),
              certificates: <dynamic>[],
              syncedAt: DateTime.utc(2027, 3, 1),
            );
        expect(publicContract.contract!.effectiveRetentionPercent, 0.5);
        expect(publicContract.previewNext(40)!.retentionWithheld, 200);
      },
    );

    test('a project billed by time and materials has no SAL calculator', () {
      final ProjectBillingSnapshot tm = ProjectBillingSnapshot.fromParts(
        summary: _summary(),
        contract: <String, dynamic>{
          ..._contract(),
          'billing_model': 'time_and_materials',
        },
        certificates: <dynamic>[],
        syncedAt: DateTime.utc(2027, 3, 1),
      );
      expect(tm.previewNext(50), isNull);
    });

    test('an empty summary is a format error', () {
      expect(
        () => ProjectBillingSnapshot.fromParts(
          summary: <String, dynamic>{},
          certificates: <dynamic>[],
          syncedAt: DateTime.utc(2027, 3, 1),
        ),
        throwsFormatException,
      );
    });
  });

  group('strings', () {
    test('every language has every label', () {
      for (final MapEntry<String, Map<PB, String>> table
          in ProjectBillingStrings.tables.entries) {
        final List<PB> missing = PB.values
            .where((PB key) => (table.value[key] ?? '').trim().isEmpty)
            .toList();
        expect(missing, isEmpty, reason: '${table.key} misses $missing');
      }
    });

    test('placeholders match across languages', () {
      final RegExp placeholder = RegExp(r'\{(\w+)\}');
      for (final PB key in PB.values) {
        final Set<String> variants = ProjectBillingStrings.tables.values
            .map(
              (Map<PB, String> table) =>
                  (placeholder
                          .allMatches(table[key]!)
                          .map((RegExpMatch m) => m.group(1)!)
                          .toList()
                        ..sort())
                      .join(','),
            )
            .toSet();
        expect(
          variants,
          hasLength(1),
          reason: '$key has different placeholders',
        );
      }
    });

    test(
      'an unknown language falls back to English and statuses are labelled',
      () {
        final ProjectBillingStrings s = ProjectBillingStrings.forLanguage('xx');
        expect(s.t(PB.title), 'Project billing');
        expect(s.status('pending_approval'), 'Pending approval');
        expect(s.status('other'), 'other');
        expect(
          fillBilling('Milestones to bill: {count}', <String, Object>{
            'count': 2,
          }),
          'Milestones to bill: 2',
        );
      },
    );
  });

  group('repository', () {
    late AppDatabase db;
    late FakeAdapter adapter;
    late ProjectBillingRepositoryImpl repo;
    final DateTime clock = DateTime.utc(2027, 3, 1, 8);

    ResponseBody serve(RequestOptions o) => switch (o.path) {
      '/projects/p1/billing/unbilled-summary' => json(200, <String, dynamic>{
        'data': _summary(),
      }),
      '/projects/p1/billing-contract' => json(200, <String, dynamic>{
        'data': _contract(),
      }),
      '/projects/p1/sal-certificates' => json(200, <String, dynamic>{
        'data': _certificates(),
      }),
      '/projects/p1/retention' => json(200, <String, dynamic>{
        'data': _retention(),
      }),
      '/projects/p1/retainer' => json(200, <String, dynamic>{
        'data': _retainer(),
      }),
      _ => json(404, <String, dynamic>{}),
    };

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      adapter = FakeAdapter(serve);
      final Dio dio = Dio(BaseOptions(baseUrl: 'http://x/api/v1'))
        ..httpClientAdapter = adapter;
      repo = ProjectBillingRepositoryImpl(
        ProjectBillingLocalDataSource(db),
        ProjectBillingRemoteDataSource(dio),
        now: () => clock,
      );
    });

    tearDown(() => db.close());

    test('nothing is cached before the first sync', () async {
      expect(await repo.cached('t1', 'p1'), isNull);
    });

    test('a sync stores the snapshot and the cache serves it', () async {
      expect((await repo.sync('t1', 'p1')).status, BillingSyncStatus.synced);

      final ProjectBillingSnapshot snapshot = (await repo.cached('t1', 'p1'))!;
      expect(snapshot.summary.contractValue, 100000);
      expect(snapshot.certificates, hasLength(2));
      expect(snapshot.retainer!.remainingHours, 4);
      expect(snapshot.retention!.released, 500);
      expect(snapshot.syncedAt.toUtc(), clock);
      expect(
        adapter.calls.map((RequestOptions o) => o.path),
        containsAll(<String>[
          '/projects/p1/billing/unbilled-summary',
          '/projects/p1/billing-contract',
          '/projects/p1/sal-certificates',
          '/projects/p1/retention',
          '/projects/p1/retainer',
        ]),
      );
    });

    test(
      'a project without a contract syncs without retention and retainer',
      () async {
        adapter.handler = (RequestOptions o) => switch (o.path) {
          '/projects/p1/billing/unbilled-summary' => json(
            200,
            <String, dynamic>{'data': _summary()},
          ),
          '/projects/p1/billing-contract' => json(200, <String, dynamic>{
            'data': null,
          }),
          '/projects/p1/sal-certificates' => json(200, <String, dynamic>{
            'data': <dynamic>[],
          }),
          _ => json(404, <String, dynamic>{}),
        };

        expect((await repo.sync('t1', 'p1')).status, BillingSyncStatus.synced);
        final ProjectBillingSnapshot snapshot = (await repo.cached(
          't1',
          'p1',
        ))!;
        expect(snapshot.contract, isNull);
        expect(snapshot.retainer, isNull);
        expect(snapshot.retention, isNull);
        expect(
          adapter.calls.map((RequestOptions o) => o.path),
          isNot(contains('/projects/p1/retention')),
        );
      },
    );

    test(
      'a contract without retainer or retention (404) still syncs',
      () async {
        adapter.handler = (RequestOptions o) => switch (o.path) {
          '/projects/p1/billing/unbilled-summary' => json(
            200,
            <String, dynamic>{'data': _summary()},
          ),
          '/projects/p1/billing-contract' => json(200, <String, dynamic>{
            'data': _contract(),
          }),
          '/projects/p1/sal-certificates' => json(200, <String, dynamic>{
            'data': _certificates(),
          }),
          _ => json(404, <String, dynamic>{}),
        };

        expect((await repo.sync('t1', 'p1')).status, BillingSyncStatus.synced);
        expect((await repo.cached('t1', 'p1'))!.retainer, isNull);
      },
    );

    test('tenants never see each other snapshots', () async {
      await repo.sync('t1', 'p1');
      expect(await repo.cached('t2', 'p1'), isNull);
    });

    test('offline keeps the cached snapshot and reports offline', () async {
      await repo.sync('t1', 'p1');
      adapter.handler = (RequestOptions o) =>
          throw DioException.connectionError(
            requestOptions: o,
            reason: 'offline',
          );

      expect((await repo.sync('t1', 'p1')).status, BillingSyncStatus.offline);
      expect((await repo.cached('t1', 'p1'))!.summary.contractValue, 100000);
    });

    test(
      'refusals and failures map to their status and leave the cache alone',
      () async {
        await repo.sync('t1', 'p1');
        for (final (int status, BillingSyncStatus expected)
            in <(int, BillingSyncStatus)>[
              (401, BillingSyncStatus.unauthorized),
              (403, BillingSyncStatus.forbidden),
              (500, BillingSyncStatus.failed),
            ]) {
          adapter.handler = (RequestOptions o) =>
              json(status, <String, dynamic>{});
          expect((await repo.sync('t1', 'p1')).status, expected);
        }
        expect((await repo.cached('t1', 'p1'))!.summary.contractValue, 100000);
      },
    );

    test(
      'a payload without data fails and never replaces a good cache',
      () async {
        await repo.sync('t1', 'p1');
        adapter.handler = (RequestOptions o) =>
            json(200, <String, dynamic>{'data': 'broken'});

        expect((await repo.sync('t1', 'p1')).status, BillingSyncStatus.failed);
        expect((await repo.cached('t1', 'p1'))!.summary.contractValue, 100000);
      },
    );
  });
}
