import 'package:drift/drift.dart';

/// Offline mirror of `GET /manufacturing/work-centers` (Mod 061). `payload` is the API resource JSON.
@DataClassName('MfgWorkCenterRow')
class MfgLocalWorkCenters extends Table {
  @override
  String get tableName => 'mfg_work_centers';

  TextColumn get tenantId => text().named('tenant_id')();
  TextColumn get id => text()();
  TextColumn get code => text()();
  TextColumn get name => text()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  TextColumn get payload => text()();
  DateTimeColumn get syncedAt => dateTime().named('synced_at')();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{tenantId, id};
}

/// Offline mirror of `GET /manufacturing/machines`.
@DataClassName('MfgMachineRow')
class MfgLocalMachines extends Table {
  @override
  String get tableName => 'mfg_machines';

  TextColumn get tenantId => text().named('tenant_id')();
  TextColumn get id => text()();
  TextColumn get code => text()();
  TextColumn get name => text()();
  TextColumn get workCenterId => text().named('work_center_id')();
  TextColumn get status => text().withDefault(const Constant('active'))();
  TextColumn get payload => text()();
  DateTimeColumn get syncedAt => dateTime().named('synced_at')();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{tenantId, id};
}

/// Offline mirror of `GET /manufacturing/routings` (header only; steps live in [MfgLocalRoutingSteps]).
@DataClassName('MfgRoutingRow')
class MfgLocalRoutings extends Table {
  @override
  String get tableName => 'mfg_routings';

  TextColumn get tenantId => text().named('tenant_id')();
  TextColumn get id => text()();
  TextColumn get routingNumber => text().named('routing_number')();
  TextColumn get name => text()();
  TextColumn get revision => text()();
  TextColumn get status => text()();
  BoolColumn get isDefault =>
      boolean().named('is_default').withDefault(const Constant(false))();
  TextColumn get payload => text()();
  DateTimeColumn get syncedAt => dateTime().named('synced_at')();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{tenantId, id};
}

/// Routing operation steps (`operations[]` of a routing resource).
@DataClassName('MfgRoutingStepRow')
class MfgLocalRoutingSteps extends Table {
  @override
  String get tableName => 'mfg_routing_steps';

  TextColumn get tenantId => text().named('tenant_id')();
  TextColumn get id => text()();
  TextColumn get routingId => text().named('routing_id')();
  IntColumn get sequence => integer()();
  TextColumn get workCenterId => text().named('work_center_id')();
  TextColumn get machineCenterId =>
      text().named('machine_center_id').nullable()();
  TextColumn get payload => text()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{tenantId, id};
}

/// Latest `GET /manufacturing/oee/summary` per work centre (and optionally machine).
@DataClassName('MfgOeeSummaryRow')
class MfgLocalOeeSummaries extends Table {
  @override
  String get tableName => 'mfg_oee_summaries';

  TextColumn get tenantId => text().named('tenant_id')();

  /// `<workCenterId>:<machineId|all>`.
  TextColumn get scopeKey => text().named('scope_key')();
  TextColumn get workCenterId => text().named('work_center_id')();
  TextColumn get machineCenterId =>
      text().named('machine_center_id').nullable()();
  DateTimeColumn get fromAt => dateTime().named('from_at')();
  DateTimeColumn get toAt => dateTime().named('to_at')();
  TextColumn get payload => text()();
  DateTimeColumn get syncedAt => dateTime().named('synced_at')();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{tenantId, scopeKey};
}
