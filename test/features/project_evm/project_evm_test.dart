import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:fattura_facile/core/database/app_database.dart';
import 'package:fattura_facile/features/project_evm/data/project_evm_local_data_source.dart';
import 'package:fattura_facile/features/project_evm/data/project_evm_remote_data_source.dart';
import 'package:fattura_facile/features/project_evm/data/project_evm_repository.dart';
import 'package:fattura_facile/features/project_evm/domain/project_evm_models.dart';
import 'package:fattura_facile/features/project_evm/l10n/project_evm_strings.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/sync_engine_test.dart' show FakeAdapter, json;

Map<String, dynamic> _figures({
  String cpi = '0.8333',
  String spi = '0.5000',
  String absorption = '85.00',
}) => <String, dynamic>{
  'has_snapshot': true,
  'bac': '100000.00',
  'committed': '1000.00',
  'actual': '30000.00',
  'total_exposure': '31000.00',
  'pv': '50000.00',
  'ev': '25000.00',
  'cv': '-5000.00',
  'sv': '-25000.00',
  'cpi': cpi,
  'spi': spi,
  'eac': '120000.00',
  'etc': '90000.00',
  'vac': '-20000.00',
  'budget_absorption_percent': absorption,
  'recognized_revenue': '50000.00',
  'gross_margin_amount': '20000.00',
  'gross_margin_percent': '40.00',
  'manual_etc_override': null,
};

Map<String, dynamic> _breakdown() => <String, dynamic>{
  'project_id': 'p1',
  'currency': 'CHF',
  'snapshot_date': '2027-03-01',
  'project': _figures(),
  'reconciliation': <String, dynamic>{
    'standard': 'Swiss GAAP FER 22',
    'managerial_actual_cost': '30000.0000',
    'statutory_cumulative_cost': '29000.0000',
    'cost_difference': '1000.0000',
    'cost_center_overhead': '500.0000',
    'last_recognition_date': '2027-02-28',
    'is_reconciled': false,
  },
  'nodes': <dynamic>[
    <String, dynamic>{
      'wbs_node_id': 'n1',
      'wbs_code': '1',
      'title': 'Phase one',
      ..._figures(),
      'children': <dynamic>[
        <String, dynamic>{
          'wbs_node_id': 'n11',
          'wbs_code': '1.1',
          'title': 'Package',
          ..._figures(cpi: '1.0500'),
          'children': <dynamic>[],
        },
        <String, dynamic>{
          'wbs_node_id': 'n12',
          'wbs_code': '1.2',
          'title': 'Not started',
          'has_snapshot': false,
          'children': <dynamic>[],
        },
      ],
    },
  ],
};

Map<String, dynamic> _waterfall() => <String, dynamic>{
  'steps': <dynamic>[
    <String, dynamic>{
      'key': 'revenue',
      'amount': '50000.00',
      'running_total': '50000.00',
      'kind': 'total',
    },
    <String, dynamic>{
      'key': 'TimesheetLabor',
      'amount': '-30000.00',
      'running_total': '20000.00',
      'kind': 'delta',
    },
    <String, dynamic>{
      'key': 'gross_margin',
      'amount': '20000.00',
      'running_total': '20000.00',
      'kind': 'total',
    },
  ],
};

Map<String, dynamic> _scurve() => <String, dynamic>{
  'points': <dynamic>[
    <String, dynamic>{
      'date': '2027-01-31',
      'pv': '100.00',
      'ev': '80.00',
      'ac': '90.00',
    },
    <String, dynamic>{
      'date': '2027-02-28',
      'pv': '200.00',
      'ev': '150.00',
      'ac': '170.00',
    },
  ],
  'forecast': <dynamic>[
    <String, dynamic>{'date': '2027-02-28', 'eac': '170.00'},
    <String, dynamic>{'date': '2027-06-30', 'eac': '600.00'},
  ],
};

void main() {
  group('traffic lights', () {
    test('green from 1.00, amber from 0.90, red below, undefined is green', () {
      expect(indexLight(1), EvmLight.green);
      expect(indexLight(0.95), EvmLight.amber);
      expect(indexLight(0.9), EvmLight.amber);
      expect(indexLight(0.8999), EvmLight.red);
      expect(indexLight(null), EvmLight.green);
    });

    test('absorption warns above 80% only', () {
      expect(absorptionWarning(80), isFalse);
      expect(absorptionWarning(80.01), isTrue);
      expect(absorptionWarning(null), isFalse);
    });
  });

  group('parsing', () {
    final ProjectEvmSnapshot snapshot = ProjectEvmSnapshot.fromParts(
      breakdown: _breakdown(),
      waterfall: _waterfall(),
      scurve: _scurve(),
      syncedAt: DateTime.utc(2027, 3, 1),
    );

    test('reads the project figures and counts the breached thresholds', () {
      final EvmFigures p = snapshot.project!;
      expect(p.bac, 100000);
      expect(p.cpi, 0.8333);
      expect(p.cpiLight, EvmLight.red);
      expect(p.spiLight, EvmLight.red);
      expect(p.exposure, 31000);
      expect(p.marginPercent, 40);
      expect(p.breaches, 3);
      expect(snapshot.currency, 'CHF');
    });

    test('reads the WBS tree, a node without snapshot has no figures', () {
      final WbsNode phase = snapshot.nodes.single;
      expect(phase.children, hasLength(2));
      expect(phase.children.first.figures!.cpiLight, EvmLight.green);
      expect(phase.children.last.figures, isNull);
    });

    test('reads the waterfall, the S-curve and the reconciliation', () {
      expect(snapshot.waterfall.map((WaterfallStep s) => s.isTotal), <bool>[
        true,
        false,
        true,
      ]);
      expect(snapshot.points, hasLength(2));
      expect(snapshot.forecast.last.eac, 600);
      expect(snapshot.reconciliation!.standard, 'Swiss GAAP FER 22');
      expect(snapshot.reconciliation!.hasValuation, isTrue);
    });

    test('a project without snapshot has no figures', () {
      final ProjectEvmSnapshot empty = ProjectEvmSnapshot.fromParts(
        breakdown: <String, dynamic>{
          'project_id': 'p2',
          'currency': null,
          'snapshot_date': null,
          'project': <String, dynamic>{'has_snapshot': false},
          'reconciliation': null,
          'nodes': <dynamic>[],
        },
        waterfall: <String, dynamic>{'steps': <dynamic>[]},
        scurve: <String, dynamic>{
          'points': <dynamic>[],
          'forecast': <dynamic>[],
        },
        syncedAt: DateTime.utc(2027, 3, 1),
      );
      expect(empty.project, isNull);
      expect(empty.currency, 'EUR');
      expect(empty.snapshotDate, isNull);
    });
  });

  group('strings', () {
    test('every language has every label', () {
      for (final MapEntry<String, Map<P, String>> table
          in ProjectEvmStrings.tables.entries) {
        final List<P> missing = P.values
            .where((P key) => (table.value[key] ?? '').trim().isEmpty)
            .toList();
        expect(missing, isEmpty, reason: '${table.key} misses $missing');
      }
    });

    test('placeholders match across languages', () {
      final RegExp placeholder = RegExp(r'\{(\w+)\}');
      for (final P key in P.values) {
        final Set<String> variants = ProjectEvmStrings.tables.values
            .map(
              (Map<P, String> table) =>
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
      'an unknown language falls back to English and sources are labelled',
      () {
        final ProjectEvmStrings s = ProjectEvmStrings.forLanguage('xx');
        expect(s.t(P.title), 'Project profitability');
        expect(s.source('TimesheetLabor'), 'Labour (timesheets)');
        expect(s.source('gross_margin'), 'Gross margin');
        expect(s.source('Other'), 'Other');
        expect(
          fillEvm('Thresholds breached: {count}', <String, Object>{'count': 2}),
          'Thresholds breached: 2',
        );
      },
    );
  });

  group('repository', () {
    late AppDatabase db;
    late FakeAdapter adapter;
    late ProjectEvmRepositoryImpl repo;
    final DateTime clock = DateTime.utc(2027, 3, 1, 8);

    ResponseBody serve(RequestOptions o) => switch (o.path) {
      '/projects/p1/evm/wbs-breakdown' => json(200, <String, dynamic>{
        'data': _breakdown(),
      }),
      '/projects/p1/evm/waterfall' => json(200, <String, dynamic>{
        'data': _waterfall(),
      }),
      '/projects/evm/scurve' => json(200, <String, dynamic>{'data': _scurve()}),
      '/projects' => json(200, <String, dynamic>{
        'data': <dynamic>[
          <String, dynamic>{
            'id': 'p1',
            'project_number': 'PRJ-1',
            'name': 'Microgrid',
          },
        ],
      }),
      _ => json(404, <String, dynamic>{}),
    };

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      adapter = FakeAdapter(serve);
      final Dio dio = Dio(BaseOptions(baseUrl: 'http://x/api/v1'))
        ..httpClientAdapter = adapter;
      repo = ProjectEvmRepositoryImpl(
        ProjectEvmLocalDataSource(db),
        ProjectEvmRemoteDataSource(dio),
        now: () => clock,
      );
    });

    tearDown(() => db.close());

    test('nothing is cached before the first sync', () async {
      expect(await repo.cached('t1', 'p1'), isNull);
      expect(await repo.cachedProjects('t1'), isEmpty);
    });

    test('a sync stores the snapshot and the cache serves it', () async {
      expect((await repo.sync('t1', 'p1')).status, EvmSyncStatus.synced);

      final ProjectEvmSnapshot snapshot = (await repo.cached('t1', 'p1'))!;
      expect(snapshot.project!.eac, 120000);
      expect(snapshot.nodes.single.children, hasLength(2));
      expect(snapshot.waterfall, hasLength(3));
      expect(snapshot.syncedAt.toUtc(), clock);
      expect(adapter.calls.map((RequestOptions o) => o.path), <String>[
        '/projects/p1/evm/wbs-breakdown',
        '/projects/p1/evm/waterfall',
        '/projects/evm/scurve',
      ]);
    });

    test('the project picker is cached', () async {
      expect((await repo.syncProjects('t1')).status, EvmSyncStatus.synced);
      final List<EvmProjectRef> projects = await repo.cachedProjects('t1');
      expect(projects.single.label, 'PRJ-1 · Microgrid');
    });

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

      expect((await repo.sync('t1', 'p1')).status, EvmSyncStatus.offline);
      expect((await repo.cached('t1', 'p1'))!.project!.bac, 100000);
    });

    test(
      'refusals and failures map to their status and leave the cache alone',
      () async {
        await repo.sync('t1', 'p1');
        for (final (int status, EvmSyncStatus expected)
            in <(int, EvmSyncStatus)>[
              (401, EvmSyncStatus.unauthorized),
              (403, EvmSyncStatus.forbidden),
              (500, EvmSyncStatus.failed),
            ]) {
          adapter.handler = (RequestOptions o) =>
              json(status, <String, dynamic>{});
          expect((await repo.sync('t1', 'p1')).status, expected);
        }
        expect((await repo.cached('t1', 'p1'))!.project!.bac, 100000);
      },
    );

    test(
      'a payload without data fails and never replaces a good cache',
      () async {
        await repo.sync('t1', 'p1');
        adapter.handler = (RequestOptions o) =>
            json(200, <String, dynamic>{'data': 'broken'});

        expect((await repo.sync('t1', 'p1')).status, EvmSyncStatus.failed);
        expect((await repo.cached('t1', 'p1'))!.project!.bac, 100000);
      },
    );
  });
}
