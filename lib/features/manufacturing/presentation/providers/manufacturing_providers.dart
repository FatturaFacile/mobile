import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../data/local/manufacturing_dao.dart';
import '../../data/remote/manufacturing_remote_data_source.dart';
import '../../data/repositories/manufacturing_repository.dart';
import '../../domain/entities/manufacturing_models.dart';

/// Drift DAO for the Mod 061 local mirror.
final Provider<ManufacturingDao> manufacturingDaoProvider =
    Provider<ManufacturingDao>((Ref ref) {
      return ref.watch(databaseProvider).manufacturingDao;
    });

/// REST data source aligned to `/api/v1/manufacturing`.
final Provider<ManufacturingRemoteDataSource> manufacturingRemoteProvider =
    Provider<ManufacturingRemoteDataSource>((Ref ref) {
      return ManufacturingRemoteDataSource(ref.watch(dioProvider));
    });

/// Offline-first repository for work centres, machines, routings and OEE.
final Provider<ManufacturingRepository> manufacturingRepositoryProvider =
    Provider<ManufacturingRepository>((Ref ref) {
      return ManufacturingRepository(
        ref.watch(manufacturingDaoProvider),
        ref.watch(manufacturingRemoteProvider),
      );
    });

final mfgRoutingsProvider = StreamProvider.family<List<MfgRouting>, String>((
  Ref ref,
  String tenantId,
) {
  return ref.watch(manufacturingRepositoryProvider).watchRoutings(tenantId);
});

final mfgMachinesProvider = StreamProvider.family<List<MfgMachine>, String>((
  Ref ref,
  String tenantId,
) {
  return ref.watch(manufacturingRepositoryProvider).watchMachines(tenantId);
});

final mfgWorkCentersProvider =
    StreamProvider.family<List<MfgWorkCenter>, String>((
      Ref ref,
      String tenantId,
    ) {
      return ref
          .watch(manufacturingRepositoryProvider)
          .watchWorkCenters(tenantId);
    });

final mfgOeeProvider = StreamProvider.family<List<MfgOeeSummary>, String>((
  Ref ref,
  String tenantId,
) {
  return ref.watch(manufacturingRepositoryProvider).watchOeeSummaries(tenantId);
});
