import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/manufacturing_models.dart';
import 'manufacturing_tables.dart';

part 'manufacturing_dao.g.dart';

Map<String, dynamic> _decode(String payload) =>
    Map<String, dynamic>.from(jsonDecode(payload) as Map<dynamic, dynamic>);

/// Tenant-scoped Drift DAO for the Mod 061 production-engineering mirror.
@DriftAccessor(
  tables: <Type>[
    MfgLocalWorkCenters,
    MfgLocalMachines,
    MfgLocalRoutings,
    MfgLocalRoutingSteps,
    MfgLocalOeeSummaries,
  ],
)
class ManufacturingDao extends DatabaseAccessor<AppDatabase>
    with _$ManufacturingDaoMixin {
  ManufacturingDao(super.db);

  Stream<List<MfgWorkCenter>> watchWorkCenters(String tenantId) {
    final SimpleSelectStatement<$MfgLocalWorkCentersTable, MfgWorkCenterRow> q =
        select(mfgLocalWorkCenters)
          ..where(($MfgLocalWorkCentersTable t) => t.tenantId.equals(tenantId))
          ..orderBy(<OrderingTerm Function($MfgLocalWorkCentersTable)>[
            ($MfgLocalWorkCentersTable t) => OrderingTerm.asc(t.code),
          ]);
    return q.watch().map(
      (List<MfgWorkCenterRow> rows) => rows
          .map(
            (MfgWorkCenterRow r) => MfgWorkCenter.fromJson(_decode(r.payload)),
          )
          .toList(),
    );
  }

  Stream<List<MfgMachine>> watchMachines(
    String tenantId, {
    String? workCenterId,
  }) {
    final SimpleSelectStatement<$MfgLocalMachinesTable, MfgMachineRow> q =
        select(mfgLocalMachines)
          ..where(
            ($MfgLocalMachinesTable t) =>
                t.tenantId.equals(tenantId) &
                (workCenterId == null
                    ? const Constant<bool>(true)
                    : t.workCenterId.equals(workCenterId)),
          )
          ..orderBy(<OrderingTerm Function($MfgLocalMachinesTable)>[
            ($MfgLocalMachinesTable t) => OrderingTerm.asc(t.code),
          ]);
    return q.watch().map(
      (List<MfgMachineRow> rows) => rows
          .map((MfgMachineRow r) => MfgMachine.fromJson(_decode(r.payload)))
          .toList(),
    );
  }

  /// Routing headers with their ordered steps.
  Stream<List<MfgRouting>> watchRoutings(String tenantId) {
    final SimpleSelectStatement<$MfgLocalRoutingsTable, MfgRoutingRow> q =
        select(mfgLocalRoutings)
          ..where(($MfgLocalRoutingsTable t) => t.tenantId.equals(tenantId))
          ..orderBy(<OrderingTerm Function($MfgLocalRoutingsTable)>[
            ($MfgLocalRoutingsTable t) => OrderingTerm.asc(t.routingNumber),
            ($MfgLocalRoutingsTable t) => OrderingTerm.asc(t.revision),
          ]);
    return q.watch().asyncMap((List<MfgRoutingRow> headers) async {
      final List<MfgRoutingStepRow> steps =
          await (select(mfgLocalRoutingSteps)
                ..where(
                  ($MfgLocalRoutingStepsTable t) => t.tenantId.equals(tenantId),
                )
                ..orderBy(<OrderingTerm Function($MfgLocalRoutingStepsTable)>[
                  ($MfgLocalRoutingStepsTable t) =>
                      OrderingTerm.asc(t.sequence),
                ]))
              .get();
      return headers.map((MfgRoutingRow h) {
        final Map<String, dynamic> json = _decode(h.payload);
        json['operations'] = steps
            .where((MfgRoutingStepRow s) => s.routingId == h.id)
            .map((MfgRoutingStepRow s) => _decode(s.payload))
            .toList();
        return MfgRouting.fromJson(json);
      }).toList();
    });
  }

  Stream<MfgOeeSummary?> watchOeeSummary(
    String tenantId,
    String workCenterId, {
    String? machineId,
  }) {
    final String key = '$workCenterId:${machineId ?? 'all'}';
    return (select(mfgLocalOeeSummaries)..where(
          ($MfgLocalOeeSummariesTable t) =>
              t.tenantId.equals(tenantId) & t.scopeKey.equals(key),
        ))
        .watchSingleOrNull()
        .map(
          (MfgOeeSummaryRow? r) =>
              r == null ? null : MfgOeeSummary.fromJson(_decode(r.payload)),
        );
  }

  Stream<List<MfgOeeSummary>> watchOeeSummaries(String tenantId) {
    return (select(mfgLocalOeeSummaries)
          ..where(($MfgLocalOeeSummariesTable t) => t.tenantId.equals(tenantId))
          ..orderBy(<OrderingTerm Function($MfgLocalOeeSummariesTable)>[
            ($MfgLocalOeeSummariesTable t) => OrderingTerm.asc(t.scopeKey),
          ]))
        .watch()
        .map(
          (List<MfgOeeSummaryRow> rows) => rows
              .map(
                (MfgOeeSummaryRow r) =>
                    MfgOeeSummary.fromJson(_decode(r.payload)),
              )
              .toList(),
        );
  }

  /// Replaces the tenant's work centres with the server snapshot.
  Future<void> replaceWorkCenters(
    String tenantId,
    List<Map<String, dynamic>> resources,
    DateTime now,
  ) {
    return transaction(() async {
      await (delete(mfgLocalWorkCenters)..where(
            ($MfgLocalWorkCentersTable t) => t.tenantId.equals(tenantId),
          ))
          .go();
      await batch((Batch b) {
        b.insertAll(mfgLocalWorkCenters, <MfgLocalWorkCentersCompanion>[
          for (final Map<String, dynamic> r in resources)
            MfgLocalWorkCentersCompanion.insert(
              tenantId: tenantId,
              id: r['id'].toString(),
              code: (r['work_center_code'] ?? '').toString(),
              name: (r['name'] ?? '').toString(),
              status: Value<String>((r['status'] ?? 'active').toString()),
              payload: jsonEncode(r),
              syncedAt: now,
            ),
        ]);
      });
    });
  }

  Future<void> replaceMachines(
    String tenantId,
    List<Map<String, dynamic>> resources,
    DateTime now,
  ) {
    return transaction(() async {
      await (delete(
        mfgLocalMachines,
      )..where(($MfgLocalMachinesTable t) => t.tenantId.equals(tenantId))).go();
      await batch((Batch b) {
        b.insertAll(mfgLocalMachines, <MfgLocalMachinesCompanion>[
          for (final Map<String, dynamic> r in resources)
            MfgLocalMachinesCompanion.insert(
              tenantId: tenantId,
              id: r['id'].toString(),
              code: (r['machine_code'] ?? '').toString(),
              name: (r['name'] ?? '').toString(),
              workCenterId: (r['work_center_id'] ?? '').toString(),
              status: Value<String>((r['status'] ?? 'active').toString()),
              payload: jsonEncode(r),
              syncedAt: now,
            ),
        ]);
      });
    });
  }

  /// Replaces routing headers and their steps (the `operations` array is split into [mfgLocalRoutingSteps]).
  Future<void> replaceRoutings(
    String tenantId,
    List<Map<String, dynamic>> resources,
    DateTime now,
  ) {
    return transaction(() async {
      await (delete(mfgLocalRoutingSteps)..where(
            ($MfgLocalRoutingStepsTable t) => t.tenantId.equals(tenantId),
          ))
          .go();
      await (delete(
        mfgLocalRoutings,
      )..where(($MfgLocalRoutingsTable t) => t.tenantId.equals(tenantId))).go();
      for (final Map<String, dynamic> r in resources) {
        final Map<String, dynamic> header = Map<String, dynamic>.of(r)
          ..remove('operations');
        final String routingId = r['id'].toString();
        await into(mfgLocalRoutings).insert(
          MfgLocalRoutingsCompanion.insert(
            tenantId: tenantId,
            id: routingId,
            routingNumber: (r['routing_number'] ?? '').toString(),
            name: (r['name'] ?? '').toString(),
            revision: (r['revision'] ?? '').toString(),
            status: (r['status'] ?? '').toString(),
            isDefault: Value<bool>(r['is_default'] == true),
            payload: jsonEncode(header),
            syncedAt: now,
          ),
        );
        final Object? ops = r['operations'];
        if (ops is List) {
          for (final Map<dynamic, dynamic> raw
              in ops.whereType<Map<dynamic, dynamic>>()) {
            final Map<String, dynamic> op = Map<String, dynamic>.from(raw);
            await into(mfgLocalRoutingSteps).insert(
              MfgLocalRoutingStepsCompanion.insert(
                tenantId: tenantId,
                id: op['id'].toString(),
                routingId: routingId,
                sequence: mfgInt(op['sequence']),
                workCenterId: (op['work_center_id'] ?? '').toString(),
                machineCenterId: Value<String?>(
                  mfgStr(op['machine_center_id']),
                ),
                payload: jsonEncode(op),
              ),
            );
          }
        }
      }
    });
  }

  Future<void> upsertOeeSummary(
    String tenantId,
    Map<String, dynamic> data,
    DateTime now,
  ) {
    final String workCenterId = data['work_center_id'].toString();
    final String? machineId = mfgStr(data['machine_center_id']);
    return into(mfgLocalOeeSummaries).insertOnConflictUpdate(
      MfgLocalOeeSummariesCompanion.insert(
        tenantId: tenantId,
        scopeKey: '$workCenterId:${machineId ?? 'all'}',
        workCenterId: workCenterId,
        machineCenterId: Value<String?>(machineId),
        fromAt: DateTime.parse(data['from'].toString()),
        toAt: DateTime.parse(data['to'].toString()),
        payload: jsonEncode(data),
        syncedAt: now,
      ),
    );
  }
}
