import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:fattura_facile/core/database/app_database.dart';
import 'package:fattura_facile/features/analytical_accounting/data/analytical_local_data_source.dart';
import 'package:fattura_facile/features/analytical_accounting/data/analytical_remote_data_source.dart';
import 'package:fattura_facile/features/analytical_accounting/data/analytical_repository.dart';
import 'package:fattura_facile/features/analytical_accounting/domain/analytical_models.dart';
import 'package:fattura_facile/features/analytical_accounting/l10n/analytical_strings.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/sync_engine_test.dart' show FakeAdapter, json;

final List<dynamic> _centers = <dynamic>[
  <String, dynamic>{
    'id': 'root',
    'parent_id': null,
    'code': 'ROOT',
    'name': 'Company',
    'center_type': 'COST_CENTER',
    'category': 'STRUCTURAL',
    'depth': 0,
    'manager_name': 'Rita Rossi',
    'is_active': true,
    'children': <dynamic>[
      <String, dynamic>{
        'id': 'it',
        'parent_id': 'root',
        'code': 'IT',
        'name': 'Information systems',
        'center_type': 'COST_CENTER',
        'category': 'AUXILIARY',
        'depth': 1,
        'manager_name': null,
        'is_active': true,
        'children': <dynamic>[],
      },
      <String, dynamic>{
        'id': 'pc',
        'parent_id': 'root',
        'code': 'PC',
        'name': 'Ticino',
        'center_type': 'PROFIT_CENTER',
        'category': 'PROFIT',
        'depth': 1,
        'manager_name': null,
        'is_active': false,
        'children': <dynamic>[],
      },
    ],
  },
];

final List<dynamic> _runs = <dynamic>[
  <String, dynamic>{
    'id': 'r1',
    'period_key': '2027-03',
    'status': 'CONSOLIDATED',
    'total_pool': '1000.0000',
    'total_allocated': '1000.0000',
    'total_unallocated': '0.0000',
  },
];

final Map<String, dynamic> _margin = <String, dynamic>{
  'statement': <String, dynamic>{
    'operating_revenues': '5000.00',
    'direct_variable_costs': '400.00',
    'contribution_margin_1': '4600.00',
    'contribution_margin_1_pct': '92.00',
    'direct_fixed_costs': '1000.00',
    'contribution_margin_2': '3600.00',
    'contribution_margin_2_pct': '72.00',
    'indirect_costs': '0.00',
    'apportioned_costs': '250.00',
    'operating_result': '3350.00',
    'operating_result_pct': '67.00',
    'non_operating': '0.00',
  },
  'breakdown': <dynamic>[],
};

final Map<String, dynamic> _comparison = <String, dynamic>{
  'rows': <dynamic>[
    <String, dynamic>{
      'center_id': 'it',
      'code': 'IT',
      'name': 'Information systems',
      'depth': 1,
      'direct_cost': '1000.00',
      'apportioned_in': '0.00',
      'apportioned_out': '1000.00',
      'net_cost': '0.00',
      'variance': '-1000.00',
      'share_pct': '0.00',
    },
  ],
  'totals': <String, dynamic>{},
};

void main() {
  group('cents and the largest remainder method', () {
    test('rounds half away from zero and formats back', () {
      expect(cents(10.005), 1001);
      expect(cents(-10.005), -1001);
      expect(centsText(-1234), '-12.34');
      expect(centsText(5), '0.05');
    });

    test('splits with the leftover going to the earliest weight', () {
      expect(allocateCents(100, <int>[10000, 10000, 10000]), <int>[34, 33, 33]);
      expect(allocateCents(-100, <int>[10000, 10000, 10000]), <int>[-34, -33, -33]);
      expect(allocateCents(100, <int>[0, 0]), <int>[0, 0]);
    });

    test('always adds up to the total', () {
      for (final int total in <int>[1, 7, 99, 12345, 999999]) {
        final List<int> shares = allocateCents(total, <int>[173333, 1, 999000, 31416, 420000]);
        expect(shares.fold<int>(0, (int a, int b) => a + b), total);
      }
    });
  });

  group('allocation vectors', () {
    test('split by percentage with exact rounding', () {
      final SplitResult result = splitVectors(100.01, const <AllocationVector>[
        AllocationVector(costCenterId: 'a', percentage: 50),
        AllocationVector(costCenterId: 'b', percentage: 25),
        AllocationVector(profitCenterId: 'c', percentage: 25),
      ]);
      expect(result.isValid, isTrue);
      expect(result.amounts, <int>[5001, 2500, 2500]);
    });

    test('split by exact amount must add up to the line', () {
      expect(
        splitVectors(100, const <AllocationVector>[
          AllocationVector(costCenterId: 'a', amount: 60),
          AllocationVector(projectId: 'p', amount: 40),
        ]).amounts,
        <int>[6000, 4000],
      );
      expect(
        splitVectors(100, const <AllocationVector>[
          AllocationVector(costCenterId: 'a', amount: 60),
          AllocationVector(projectId: 'p', amount: 30),
        ]).errors,
        <String>['vectorAmountSum'],
      );
    });

    test('every broken rule is reported', () {
      expect(splitVectors(10, const <AllocationVector>[]).errors, <String>['vectorRequired']);
      expect(
        splitVectors(10, const <AllocationVector>[
          AllocationVector(costCenterId: 'a', percentage: 60),
          AllocationVector(costCenterId: 'b', percentage: 30),
        ]).errors,
        <String>['vectorPercentSum'],
      );
      expect(
        splitVectors(10, const <AllocationVector>[
          AllocationVector(costCenterId: 'a', amount: 6),
          AllocationVector(costCenterId: 'b', percentage: 40),
        ]).errors,
        contains('vectorMixedModes'),
      );
      expect(
        splitVectors(10, const <AllocationVector>[AllocationVector(percentage: 100)]).errors,
        contains('vectorTargetRequired'),
      );
      expect(
        splitVectors(10, const <AllocationVector>[AllocationVector(costCenterId: 'a')]).errors,
        contains('vectorValueRequired'),
      );
    });
  });

  group('entry draft', () {
    test('builds the API payload with its vectors', () {
      const EntryDraft draft = EntryDraft(
        postingDate: '2027-03-15',
        description: 'Rent',
        lines: <EntryLineDraft>[
          EntryLineDraft(
            amount: 100,
            costElementType: 'FIXED_DIRECT',
            vectors: <AllocationVector>[
              AllocationVector(costCenterId: 'a', percentage: 60),
              AllocationVector(profitCenterId: 'b', percentage: 40),
            ],
          ),
        ],
      );

      final Map<String, dynamic> body = draft.toJson();
      final Map<String, dynamic> line = (body['lines'] as List<dynamic>).first as Map<String, dynamic>;
      expect(draft.validate(), isEmpty);
      expect(body['posting_date'], '2027-03-15');
      expect(line['amount'], '100.00');
      expect(line['vectors'] as List<dynamic>, hasLength(2));
      expect(jsonDecode(draft.toJsonText()), body);
    });

    test('is refused when incomplete', () {
      expect(const EntryDraft(postingDate: '2027-03-15', lines: <EntryLineDraft>[]).validate(), <String>['entryNeedsLines']);
      expect(
        const EntryDraft(
          postingDate: '2027-03-15',
          lines: <EntryLineDraft>[EntryLineDraft(amount: 1, costElementType: 'BOGUS', costCenterId: 'a')],
        ).validate(),
        <String>['invalidCostElement'],
      );
      expect(
        const EntryDraft(
          postingDate: '2027-03-15',
          lines: <EntryLineDraft>[EntryLineDraft(amount: 1, costElementType: 'REVENUE')],
        ).validate(),
        <String>['vectorTargetRequired'],
      );
    });
  });

  group('parsing', () {
    test('reads the tree and flattens it depth first', () {
      final List<AnalyticalCenter> roots = parseCenters(_centers);
      final List<AnalyticalCenter> flat = flattenCenters(roots);
      expect(flat.map((AnalyticalCenter c) => c.code), <String>['ROOT', 'IT', 'PC']);
      expect(roots.single.managerName, 'Rita Rossi');
      expect(flat.last.isActive, isFalse);
      expect(flat.last.isCostCenter, isFalse);
    });

    test('reads the margin levels and checks they add up', () {
      final ContributionMargin margin = ContributionMargin.fromJson(_margin);
      expect(margin.margin2, 3600);
      expect(margin.operatingResultPercent, 67);
      expect(margin.isConsistent, isTrue);
      final Map<String, dynamic> broken = <String, dynamic>{
        'statement': <String, dynamic>{
          ...(_margin['statement'] as Map<String, dynamic>),
          'operating_result': '1.00',
        },
      };
      expect(ContributionMargin.fromJson(broken).isConsistent, isFalse);
    });

    test('reads the comparison and the runs, and refuses a wrong shape', () {
      expect(parseComparison(_comparison).single.variance, -1000);
      expect(parseRuns(_runs).single.status, 'CONSOLIDATED');
      expect(() => parseCenters(<String, dynamic>{}), throwsA(isA<AnalyticalFormatException>()));
      expect(() => parseRuns('x'), throwsA(isA<AnalyticalFormatException>()));
      expect(() => parseComparison(<String, dynamic>{}), throwsA(isA<AnalyticalFormatException>()));
      expect(() => ContributionMargin.fromJson(<String, dynamic>{}), throwsA(isA<AnalyticalFormatException>()));
    });

    test('the enum values are the ones of the web-api contract', () {
      expect(analyticalCenterCategories, <String>['STRUCTURAL', 'AUXILIARY', 'PRODUCTION', 'LOGISTICS', 'COMMERCIAL', 'PROFIT']);
      expect(analyticalDriverTypes, <String>['AREA_SQM', 'HEADCOUNT_FTE', 'MACHINE_HOURS', 'REVENUE_VOLUME', 'FIXED_PERCENTAGE', 'CUSTOM']);
      expect(analyticalCostElementTypes, <String>['VARIABLE_DIRECT', 'FIXED_DIRECT', 'INDIRECT_AUXILIARY', 'REVENUE', 'NON_OPERATING']);
      expect(analyticalRunStatuses, <String>['PREVIEW', 'CONSOLIDATED', 'REVERSED']);
      expect(analyticalCenterTypes, <String>['COST_CENTER', 'PROFIT_CENTER']);
    });
  });

  group('strings', () {
    test('every language has every label', () {
      for (final MapEntry<String, Map<A, String>> table in AnalyticalStrings.tables.entries) {
        final List<A> missing = A.values.where((A key) => (table.value[key] ?? '').trim().isEmpty).toList();
        expect(missing, isEmpty, reason: '${table.key} misses $missing');
      }
    });

    test('placeholders match across languages', () {
      final RegExp placeholder = RegExp(r'\{(\w+)\}');
      for (final A key in A.values) {
        final Set<String> variants = AnalyticalStrings.tables.values
            .map(
              (Map<A, String> table) =>
                  (placeholder.allMatches(table[key]!).map((RegExpMatch m) => m.group(1)!).toList()..sort()).join(','),
            )
            .toSet();
        expect(variants, hasLength(1), reason: '$key has different placeholders');
      }
    });

    test('an unknown language falls back to English and contract values are labelled', () {
      final AnalyticalStrings s = AnalyticalStrings.forLanguage('xx');
      expect(s.t(A.title), 'Cost accounting');
      expect(s.element('FIXED_DIRECT'), 'Direct fixed costs');
      expect(s.centerCategory('PROFIT'), 'Profit');
      expect(s.runStatus('REVERSED'), 'Reversed');
      expect(s.error('vectorPercentSum'), 'The percentages must add up to 100');
      expect(s.error('other'), 'other');
      expect(fillAnalytical('Entries waiting to be sent: {count}', <String, Object>{'count': 2}), 'Entries waiting to be sent: 2');
      expect(AnalyticalStrings.forLanguage('de').centerType('PROFIT_CENTER'), 'Profitcenter');
    });
  });

  group('repository', () {
    late AppDatabase db;
    late FakeAdapter adapter;
    late AnalyticalRepositoryImpl repo;
    late DateTime clock;
    int postStatus = 201;
    bool reachable = true;

    ResponseBody serve(RequestOptions o) {
      if (!reachable) {
        throw DioException.connectionError(requestOptions: o, reason: 'down');
      }
      if (o.method == 'POST' && o.path == '/analytical/entries') {
        return json(postStatus, <String, dynamic>{'message': postStatus == 422 ? 'Period consolidated' : 'ok'});
      }
      return switch (o.path) {
        '/analytical/centers/tree' => json(200, <String, dynamic>{'data': _centers}),
        '/analytical/runs' => json(200, <String, dynamic>{'data': _runs}),
        '/analytical/reports/contribution-margin' => json(200, <String, dynamic>{'data': _margin}),
        '/analytical/reports/direct-vs-apportioned' => json(200, <String, dynamic>{'data': _comparison}),
        _ => json(404, <String, dynamic>{}),
      };
    }

    const EntryDraft draft = EntryDraft(
      postingDate: '2027-03-15',
      lines: <EntryLineDraft>[EntryLineDraft(amount: 50, costElementType: 'FIXED_DIRECT', costCenterId: 'it')],
    );

    setUp(() {
      postStatus = 201;
      reachable = true;
      clock = DateTime.utc(2027, 3, 1, 8);
      db = AppDatabase(NativeDatabase.memory());
      adapter = FakeAdapter(serve);
      final Dio dio = Dio(BaseOptions(baseUrl: 'http://x/api/v1'))..httpClientAdapter = adapter;
      repo = AnalyticalRepositoryImpl(
        AnalyticalLocalDataSource(db),
        AnalyticalRemoteDataSource(dio),
        now: () => clock,
      );
    });

    tearDown(() => db.close());

    test('nothing is cached before the first sync', () async {
      final AnalyticalOverview overview = await repo.overview('t1');
      expect(overview.centers, isEmpty);
      expect(overview.margin, isNull);
      expect(overview.syncedAt, isNull);
      expect(overview.pending, 0);
    });

    test('a sync stores the four read models and the cache serves them', () async {
      expect((await repo.sync('t1')).status, AnalyticalSyncStatus.synced);

      final AnalyticalOverview overview = await repo.overview('t1');
      expect(flattenCenters(overview.centers), hasLength(3));
      expect(overview.runs.single.totalAllocated, 1000);
      expect(overview.margin!.operatingResult, 3350);
      expect(overview.comparison.single.code, 'IT');
      expect(overview.syncedAt!.toUtc(), clock);
    });

    test('the cache is tenant scoped', () async {
      await repo.sync('t1');

      expect((await repo.overview('t2')).margin, isNull);
    });

    test('an unreachable server is offline and keeps the cache', () async {
      await repo.sync('t1');
      reachable = false;

      final AnalyticalSyncResult result = await repo.sync('t1');

      expect(result.status, AnalyticalSyncStatus.offline);
      expect((await repo.overview('t1')).margin, isNotNull);
    });

    test('a payload that does not parse never replaces a good cache', () async {
      await repo.sync('t1');
      final Dio bad = Dio(BaseOptions(baseUrl: 'http://x/api/v1'))
        ..httpClientAdapter = FakeAdapter(
          (RequestOptions o) => o.path == '/analytical/reports/contribution-margin'
              ? json(200, <String, dynamic>{'data': <String, dynamic>{}})
              : serve(o),
        );
      final AnalyticalRepositoryImpl broken = AnalyticalRepositoryImpl(
        AnalyticalLocalDataSource(db),
        AnalyticalRemoteDataSource(bad),
        now: () => clock.add(const Duration(hours: 1)),
      );

      expect((await broken.sync('t1')).status, AnalyticalSyncStatus.failed);
      expect((await repo.overview('t1')).syncedAt!.toUtc(), clock);
    });

    test('an entry is queued offline and sent by the next sync', () async {
      expect(await repo.queueEntry('t1', draft), isEmpty);
      expect((await repo.overview('t1')).pending, 1);

      final AnalyticalSyncResult result = await repo.sync('t1');

      expect(result.sent, 1);
      expect(result.failed, 0);
      expect((await repo.overview('t1')).pending, 0);
      expect(adapter.calls.first.method, 'POST');
    });

    test('an invalid entry is refused and never queued', () async {
      final List<String> errors = await repo.queueEntry(
        't1',
        const EntryDraft(postingDate: '2027-03-15', lines: <EntryLineDraft>[]),
      );

      expect(errors, <String>['entryNeedsLines']);
      expect((await repo.overview('t1')).pending, 0);
    });

    test('a refused entry is parked, an unreachable server leaves it pending', () async {
      await repo.queueEntry('t1', draft);

      postStatus = 422;
      final AnalyticalSyncResult refused = await repo.sync('t1');
      expect(refused.failed, 1);
      expect((await repo.overview('t1')).pending, 0);

      await repo.queueEntry('t1', draft);
      postStatus = 503;
      final AnalyticalSyncResult retry = await repo.sync('t1');
      expect(retry.sent, 0);
      expect(retry.failed, 0);
      expect((await repo.overview('t1')).pending, 1);
    });
  });
}
