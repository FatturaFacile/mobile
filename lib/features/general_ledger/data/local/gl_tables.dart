import 'package:drift/drift.dart';

/// Journal entries (prima nota) held on the device: local drafts, queued writes and the server copies read back.
/// Amounts of the lines are integer ten-thousandths. [id] is the client UUID, the outbox `entityId`.
@DataClassName('GlJournalEntryRow')
class GlJournalEntries extends Table {
  TextColumn get id => text()();
  TextColumn get tenantId => text()();
  TextColumn get serverId => text().nullable()();
  TextColumn get postingDate => text()();
  TextColumn get description => text()();
  TextColumn get ledgerType =>
      text().withDefault(const Constant('statutory'))();

  /// Comma separated codes of the other books (`02,03`).
  TextColumn get alsoPostTo => text().withDefault(const Constant(''))();
  TextColumn get status => text().withDefault(const Constant('draft'))();

  /// Index of `JournalSyncState`.
  IntColumn get syncState => integer().withDefault(const Constant(0))();
  BoolColumn get postOnSync => boolean().withDefault(const Constant(false))();
  TextColumn get entryNumber => text().nullable()();
  TextColumn get reversesJournalId => text().nullable()();
  TextColumn get reversalReason => text().nullable()();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DataClassName('GlJournalLineRow')
class GlJournalLines extends Table {
  TextColumn get entryId =>
      text().references(GlJournalEntries, #id, onDelete: KeyAction.cascade)();
  IntColumn get lineNumber => integer()();
  TextColumn get accountId => text()();
  TextColumn get accountCode => text().withDefault(const Constant(''))();
  TextColumn get accountName => text().withDefault(const Constant(''))();
  IntColumn get debit => integer().withDefault(const Constant(0))();
  IntColumn get credit => integer().withDefault(const Constant(0))();
  TextColumn get description => text().withDefault(const Constant(''))();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{entryId, lineNumber};
}

/// Chart of accounts cache (tenant scoped).
@DataClassName('GlAccountRow')
class GlAccounts extends Table {
  TextColumn get tenantId => text()();
  TextColumn get id => text()();
  TextColumn get code => text()();
  TextColumn get name => text()();
  TextColumn get accountType => text().withDefault(const Constant(''))();
  TextColumn get normalBalance => text().withDefault(const Constant('debit'))();
  BoolColumn get allowsManualPosting =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{tenantId, id};
}

/// Accounting template (causale) cache; `payload` is the API resource as received.
@DataClassName('GlTemplateRow')
class GlTemplates extends Table {
  TextColumn get tenantId => text()();
  TextColumn get id => text()();
  TextColumn get code => text()();
  TextColumn get payload => text()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{tenantId, id};
}

/// Last trial balance or account ledger read for one filter, kept for offline reading. `kind` is `trial_balance`
/// or `account_ledger`; `filterKey` encodes the filter; `payload` is the API `data` object as received.
@DataClassName('GlReportSnapshotRow')
class GlReportSnapshots extends Table {
  TextColumn get tenantId => text()();
  TextColumn get kind => text()();
  TextColumn get filterKey => text()();
  TextColumn get payload => text()();
  DateTimeColumn get syncedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{
    tenantId,
    kind,
    filterKey,
  };
}
