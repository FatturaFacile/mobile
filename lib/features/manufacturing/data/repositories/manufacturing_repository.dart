import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/manufacturing_models.dart';
import '../local/manufacturing_dao.dart';
import '../remote/manufacturing_remote_data_source.dart';

/// Offline-first read repository for Mod 061: the UI reads SQLite only, [sync] refreshes it from the API.
class ManufacturingRepository {
  ManufacturingRepository(
    this._dao,
    this._remote, {
    DateTime Function()? clock,
    this.oeeWindowDays = 30,
  }) : _clock = clock ?? DateTime.now;

  final ManufacturingDao _dao;
  final ManufacturingRemoteDataSource _remote;
  final DateTime Function() _clock;

  /// Length of the window requested for the cached OEE summaries.
  final int oeeWindowDays;

  Stream<List<MfgWorkCenter>> watchWorkCenters(String tenantId) =>
      _dao.watchWorkCenters(tenantId);

  Stream<List<MfgMachine>> watchMachines(
    String tenantId, {
    String? workCenterId,
  }) => _dao.watchMachines(tenantId, workCenterId: workCenterId);

  Stream<List<MfgRouting>> watchRoutings(String tenantId) =>
      _dao.watchRoutings(tenantId);

  Stream<List<MfgOeeSummary>> watchOeeSummaries(String tenantId) =>
      _dao.watchOeeSummaries(tenantId);

  /// Pulls work centres, machines, routings and the OEE summary of every work centre into SQLite.
  ///
  /// Server wins. A failing OEE call of one work centre does not abort the rest; any network error leaves the cached
  /// data untouched and is returned as a [Failure].
  Future<Either<Failure, int>> sync(String tenantId) async {
    try {
      final DateTime now = _clock();
      final List<Map<String, dynamic>> workCenters = await _remote
          .fetchWorkCenters();
      final List<Map<String, dynamic>> machines = await _remote.fetchMachines();
      final List<Map<String, dynamic>> routings = await _remote.fetchRoutings();
      await _dao.replaceWorkCenters(tenantId, workCenters, now);
      await _dao.replaceMachines(tenantId, machines, now);
      await _dao.replaceRoutings(tenantId, routings, now);

      final DateTime from = now.subtract(Duration(days: oeeWindowDays));
      for (final Map<String, dynamic> wc in workCenters) {
        try {
          final Map<String, dynamic> summary = await _remote.fetchOeeSummary(
            workCenterId: wc['id'].toString(),
            from: from,
            to: now,
          );
          await _dao.upsertOeeSummary(tenantId, summary, now);
        } on DioException {
          continue;
        }
      }
      return Right<Failure, int>(
        workCenters.length + machines.length + routings.length,
      );
    } on DioException catch (e) {
      return Left<Failure, int>(mapDioError(e));
    }
  }
}
