// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gl_dao.dart';

// ignore_for_file: type=lint
mixin _$GlDaoMixin on DatabaseAccessor<AppDatabase> {
  $GlJournalEntriesTable get glJournalEntries =>
      attachedDatabase.glJournalEntries;
  $GlJournalLinesTable get glJournalLines => attachedDatabase.glJournalLines;
  $GlAccountsTable get glAccounts => attachedDatabase.glAccounts;
  $GlTemplatesTable get glTemplates => attachedDatabase.glTemplates;
  $GlReportSnapshotsTable get glReportSnapshots =>
      attachedDatabase.glReportSnapshots;
  GlDaoManager get managers => GlDaoManager(this);
}

class GlDaoManager {
  final _$GlDaoMixin _db;
  GlDaoManager(this._db);
  $$GlJournalEntriesTableTableManager get glJournalEntries =>
      $$GlJournalEntriesTableTableManager(
        _db.attachedDatabase,
        _db.glJournalEntries,
      );
  $$GlJournalLinesTableTableManager get glJournalLines =>
      $$GlJournalLinesTableTableManager(
        _db.attachedDatabase,
        _db.glJournalLines,
      );
  $$GlAccountsTableTableManager get glAccounts =>
      $$GlAccountsTableTableManager(_db.attachedDatabase, _db.glAccounts);
  $$GlTemplatesTableTableManager get glTemplates =>
      $$GlTemplatesTableTableManager(_db.attachedDatabase, _db.glTemplates);
  $$GlReportSnapshotsTableTableManager get glReportSnapshots =>
      $$GlReportSnapshotsTableTableManager(
        _db.attachedDatabase,
        _db.glReportSnapshots,
      );
}
