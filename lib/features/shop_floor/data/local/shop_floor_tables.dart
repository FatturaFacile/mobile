import 'package:drift/drift.dart';

/// Outbox row states.
abstract final class OutboxState {
  /// Waiting for its first or next attempt.
  static const int pending = 0;

  /// A transient failure (5xx, 429): retried once `nextAttemptAt` has passed.
  static const int failed = 1;

  /// The server refused it for good (403/404/409/422): needs the supervisor, never resent automatically.
  static const int rejected = 2;

  /// Acknowledged by the server (kept for the audit trail and replay detection).
  static const int done = 3;
}

/// Kinds of queued shop-floor mutations.
abstract final class OutboxKind {
  static const String issue = 'issue';
  static const String confirm = 'confirm';
  static const String receipt = 'receipt';
  static const String checkIn = 'check_in';
  static const String inspection = 'inspection';
}

/// Cached production orders (header columns for lookups, the API resource as JSON).
@DataClassName('MfgOrderRow')
class MfgOrders extends Table {
  TextColumn get tenantId => text()();
  TextColumn get id => text()();
  TextColumn get orderNumber => text()();
  TextColumn get status => text()();
  TextColumn get payload => text()();
  DateTimeColumn get syncedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{tenantId, id};
}

@DataClassName('MfgWorkCenterRow')
class MfgWorkCenters extends Table {
  TextColumn get tenantId => text()();
  TextColumn get id => text()();
  TextColumn get code => text()();
  TextColumn get payload => text()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{tenantId, id};
}

@DataClassName('MfgQualityPlanRow')
class MfgQualityPlans extends Table {
  TextColumn get tenantId => text()();
  TextColumn get id => text()();
  TextColumn get payload => text()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{tenantId, id};
}

/// Raw-material lots scanned and held until the operator backflushes them.
@DataClassName('MfgStagedLotRow')
class MfgStagedLots extends Table {
  TextColumn get id => text()();
  TextColumn get tenantId => text()();
  TextColumn get orderId => text()();
  TextColumn get lineId => text()();
  TextColumn get lotNumber => text()();
  TextColumn get lotId => text().nullable()();
  TextColumn get gtin => text().nullable()();
  RealColumn get quantity => real()();

  /// Outbox uuid of the issue that posted it; null while still staged.
  TextColumn get outboxUuid => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

/// Operator stopwatch and counters of one operation, persisted across app restarts.
@DataClassName('MfgOperationTimerRow')
class MfgOperationTimers extends Table {
  TextColumn get tenantId => text()();
  TextColumn get operationId => text()();
  TextColumn get orderId => text()();
  IntColumn get phase => integer().withDefault(const Constant(0))();
  IntColumn get resumePhase => integer().withDefault(const Constant(2))();
  IntColumn get setupSeconds => integer().withDefault(const Constant(0))();
  IntColumn get runSeconds => integer().withDefault(const Constant(0))();
  IntColumn get downtimeSeconds => integer().withDefault(const Constant(0))();
  DateTimeColumn get phaseStartedAt => dateTime().nullable()();
  RealColumn get goodQuantity => real().withDefault(const Constant(0))();
  RealColumn get scrapQuantity => real().withDefault(const Constant(0))();
  TextColumn get scrapReason => text().nullable()();
  TextColumn get machineWorkCenterId => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{tenantId, operationId};
}

/// Persistent mutation queue of the shop floor. Rows are sent in `sequence` order per production order; `uuid` is the
/// idempotency key (and the `operation_posting_uuid` of a confirmation) and never changes across retries.
@DataClassName('MfgOutboxRow')
class MfgOutbox extends Table {
  IntColumn get sequence => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  TextColumn get tenantId => text()();
  TextColumn get kind => text()();
  TextColumn get orderId => text()();
  TextColumn get method => text().withDefault(const Constant('POST'))();
  TextColumn get path => text()();
  TextColumn get payload => text()();

  /// Queue uuid that must be acknowledged first (explicit dependency across orders).
  TextColumn get dependsOn => text().nullable()();
  IntColumn get state => integer().withDefault(const Constant(0))();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextAttemptAt => dateTime().nullable()();
  TextColumn get lastError => text().nullable()();

  /// The server answered 200 instead of 201: the posting had already been applied (idempotent replay).
  BoolColumn get replayed => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
}
