import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:fattura_facile/core/database/app_database.dart';
import 'package:fattura_facile/core/error/failure.dart';
import 'package:fattura_facile/features/manufacturing/data/remote/manufacturing_remote_data_source.dart';
import 'package:fattura_facile/features/manufacturing/data/repositories/manufacturing_repository.dart';
import 'package:fattura_facile/features/manufacturing/domain/entities/manufacturing_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

class FakeManufacturingRemote implements ManufacturingRemoteDataSource {
  bool fail = false;
  final Set<String> failingOee = <String>{};
  int oeeCalls = 0;

  @override
  Future<List<Map<String, dynamic>>> fetchWorkCenters() async {
    _maybeFail();
    return <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 'wc-1',
        'work_center_code': 'WC-1',
        'name': 'Milling',
        'status': 'active',
      },
      <String, dynamic>{
        'id': 'wc-2',
        'work_center_code': 'WC-2',
        'name': 'Assembly',
        'status': 'active',
      },
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchMachines() async {
    _maybeFail();
    return <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 'm-1',
        'machine_code': 'M1',
        'name': 'Mill 1',
        'work_center_id': 'wc-1',
      },
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchRoutings() async {
    _maybeFail();
    return <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 'r-1',
        'routing_number': 'RT-1',
        'name': 'Shaft',
        'revision': 'A',
        'status': 'active',
        'operations': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'o2',
            'sequence': 20,
            'operation_code': 'OP20',
            'name': 'Assemble',
            'work_center_id': 'wc-2',
          },
          <String, dynamic>{
            'id': 'o1',
            'sequence': 10,
            'operation_code': 'OP10',
            'name': 'Mill',
            'work_center_id': 'wc-1',
            'machine_center_id': 'm-1',
          },
        ],
      },
    ];
  }

  @override
  Future<Map<String, dynamic>> fetchOeeSummary({
    required String workCenterId,
    String? machineCenterId,
    required DateTime from,
    required DateTime to,
  }) async {
    oeeCalls++;
    if (failingOee.contains(workCenterId)) {
      throw DioException(requestOptions: RequestOptions(path: '/oee/summary'));
    }
    return <String, dynamic>{
      'work_center_id': workCenterId,
      'machine_center_id': null,
      'from': from.toUtc().toIso8601String(),
      'to': to.toUtc().toIso8601String(),
      'summary': <String, dynamic>{'oee_percent': 70.5},
      'targets_percent': <String, dynamic>{'oee': 85.0},
      'meets_target': false,
      'gap_to_target_percent': -14.5,
    };
  }

  void _maybeFail() {
    if (fail) {
      throw DioException(requestOptions: RequestOptions(path: '/x'));
    }
  }
}

void main() {
  late AppDatabase db;
  late FakeManufacturingRemote remote;
  late ManufacturingRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    remote = FakeManufacturingRemote();
    repo = ManufacturingRepository(
      db.manufacturingDao,
      remote,
      clock: () => DateTime.utc(2026, 11, 21, 12),
    );
  });

  tearDown(() => db.close());

  test(
    'sync fills SQLite and the repository streams tenant-scoped, ordered data',
    () async {
      final Either<Failure, int> result = await repo.sync('t1');
      expect(result.isRight(), isTrue);

      final List<MfgRouting> routings = await repo.watchRoutings('t1').first;
      expect(routings, hasLength(1));
      expect(
        routings.single.steps.map((MfgRoutingStep s) => s.operationCode),
        <String>['OP10', 'OP20'],
      );
      expect(routings.single.steps.first.machineCenterId, 'm-1');

      expect(
        (await repo.watchWorkCenters('t1').first).map(
          (MfgWorkCenter w) => w.code,
        ),
        <String>['WC-1', 'WC-2'],
      );
      expect(
        await repo.watchMachines('t1', workCenterId: 'wc-1').first,
        hasLength(1),
      );
      expect(
        await repo.watchMachines('t1', workCenterId: 'wc-2').first,
        isEmpty,
      );

      final List<MfgOeeSummary> oee = await repo.watchOeeSummaries('t1').first;
      expect(oee, hasLength(2));
      expect(oee.first.metrics.oeePercent, 70.5);
      expect(oee.first.from, DateTime.utc(2026, 10, 22, 12));

      expect(await repo.watchRoutings('other').first, isEmpty);
      expect(await repo.watchOeeSummaries('other').first, isEmpty);
    },
  );

  test('re-sync replaces rows instead of duplicating them', () async {
    await repo.sync('t1');
    await repo.sync('t1');
    expect(await repo.watchRoutings('t1').first, hasLength(1));
    expect((await repo.watchRoutings('t1').first).single.steps, hasLength(2));
    expect(await repo.watchOeeSummaries('t1').first, hasLength(2));
  });

  test('one failing OEE call does not abort the sync', () async {
    remote.failingOee.add('wc-1');
    final Either<Failure, int> result = await repo.sync('t1');
    expect(result.isRight(), isTrue);
    expect(remote.oeeCalls, 2);
    final List<MfgOeeSummary> oee = await repo.watchOeeSummaries('t1').first;
    expect(oee.map((MfgOeeSummary s) => s.workCenterId), <String>['wc-2']);
  });

  test(
    'network failure returns a Failure and keeps the offline cache',
    () async {
      await repo.sync('t1');
      remote.fail = true;
      final Either<Failure, int> result = await repo.sync('t1');
      expect(result.isLeft(), isTrue);
      expect(await repo.watchRoutings('t1').first, hasLength(1));
      expect(await repo.watchWorkCenters('t1').first, hasLength(2));
    },
  );
}
