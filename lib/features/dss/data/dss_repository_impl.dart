import 'dart:convert';

import '../domain/dss_models.dart';
import '../domain/dss_parser.dart';
import '../domain/dss_repository.dart';
import 'dss_local_data_source.dart';
import 'dss_remote_data_source.dart';

/// Sync repository of the Executive DSS: pulls the views of a filter and saves them together, serves the cache offline.
class DssRepositoryImpl implements DssRepository {
  DssRepositoryImpl(this._local, this._remote, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final DssLocalDataSource _local;
  final DssRemoteDataSource _remote;
  final DateTime Function() _now;

  @override
  Future<DssSnapshot?> cached(String tenantId, DssFilter filter) async {
    final DssStoredPayload? stored = await _local.find(tenantId, filter);
    if (stored == null) {
      return null;
    }
    final DssOverview overview = DssParser.overview(
      _object(stored.overviewJson),
    );
    final String? inputs = stored.inputsJson;
    final String? products = stored.productsJson;
    final String? variance = stored.varianceJson;
    final String? entities = stored.legalEntitiesJson;
    return DssSnapshot(
      filter: filter,
      overview: overview,
      customers: DssParser.profitability(_object(stored.customersJson)),
      products: products == null
          ? null
          : DssParser.profitability(_object(products)),
      variance: variance == null ? null : DssParser.variance(_object(variance)),
      baseline: DssParser.baseline(
        overview,
        inputs == null ? null : _object(inputs),
      ),
      legalEntities: entities == null
          ? const <DssLegalEntity>[]
          : DssParser.legalEntities(jsonDecode(entities)),
      syncedAt: stored.syncedAt,
    );
  }

  @override
  Future<DssSyncResult> sync(String tenantId, DssFilter filter) async {
    try {
      // The overview and the customers are what the page cannot work without: any failure here leaves the cache untouched.
      final Map<String, dynamic> overview = await _remote.overview(filter);
      final Map<String, dynamic> customers = await _remote.profitability(
        filter,
        'customer',
      );
      final Map<String, dynamic>? products = await _optional(
        () => _remote.profitability(filter, 'product'),
      );
      final Map<String, dynamic>? variance = await _optional(
        () => _remote.varianceBridge(filter),
      );
      final Map<String, dynamic>? inputs = await _optional(
        () => _remote.simulationInputs(filter),
      );
      final List<dynamic>? entities = await _optionalList(
        _remote.legalEntities,
      );

      // A payload that does not parse must never replace a good cache.
      DssParser.overview(overview);
      DssParser.profitability(customers);

      final DateTime now = _now().toUtc();
      await _local.save(
        tenantId,
        filter,
        DssStoredPayload(
          overviewJson: jsonEncode(overview),
          customersJson: jsonEncode(customers),
          productsJson: products == null ? null : jsonEncode(products),
          varianceJson: variance == null ? null : jsonEncode(variance),
          inputsJson: inputs == null ? null : jsonEncode(inputs),
          legalEntitiesJson: entities == null ? null : jsonEncode(entities),
          syncedAt: now,
        ),
      );
      return DssSyncResult(DssSyncStatus.synced, syncedAt: now);
    } on DssRemoteException catch (e) {
      return DssSyncResult(_status(e.kind), detail: e.detail);
    } on FormatException catch (e) {
      return DssSyncResult(DssSyncStatus.failed, detail: e.message);
    }
  }

  static DssSyncStatus _status(DssErrorKind kind) => switch (kind) {
    DssErrorKind.offline => DssSyncStatus.offline,
    DssErrorKind.unauthorized => DssSyncStatus.unauthorized,
    DssErrorKind.forbidden => DssSyncStatus.forbidden,
    DssErrorKind.failed => DssSyncStatus.failed,
  };

  /// The extras (products, bridge, what-if inputs) are skipped when the server refuses them, but a lost connection still fails the sync.
  static Future<Map<String, dynamic>?> _optional(
    Future<Map<String, dynamic>> Function() fetch,
  ) async {
    try {
      return await fetch();
    } on DssRemoteException catch (e) {
      if (e.kind == DssErrorKind.forbidden || e.kind == DssErrorKind.failed) {
        return null;
      }
      rethrow;
    }
  }

  static Future<List<dynamic>?> _optionalList(
    Future<List<dynamic>> Function() fetch,
  ) async {
    try {
      return await fetch();
    } on DssRemoteException catch (e) {
      if (e.kind == DssErrorKind.forbidden || e.kind == DssErrorKind.failed) {
        return null;
      }
      rethrow;
    }
  }

  static Map<String, dynamic> _object(String json) =>
      Map<String, dynamic>.from(jsonDecode(json) as Map<dynamic, dynamic>);
}
