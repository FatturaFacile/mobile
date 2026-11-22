import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/gl_models.dart';
import 'gl_tables.dart';

part 'gl_dao.g.dart';

const String trialBalanceKind = 'trial_balance';
const String accountLedgerKind = 'account_ledger';

/// Tenant scoped store of the general ledger: journals with their lines, the account and template caches and the
/// report snapshots. The guards live here as well as in the domain model, so nothing bypasses them:
/// an unbalanced journal is never stored, and a queued/synced/posted one is never rewritten by a user edit.
@DriftAccessor(
  tables: <Type>[
    GlJournalEntries,
    GlJournalLines,
    GlAccounts,
    GlTemplates,
    GlReportSnapshots,
  ],
)
class GlDao extends DatabaseAccessor<AppDatabase> with _$GlDaoMixin {
  GlDao(super.db);

  // --- Journals ---------------------------------------------------------------------------------------------------

  /// Live journals of the tenant, newest posting date first.
  Stream<List<JournalEntry>> watchEntries(String tenantId) {
    final SimpleSelectStatement<$GlJournalEntriesTable, GlJournalEntryRow> q =
        select(glJournalEntries)
          ..where(($GlJournalEntriesTable t) => t.tenantId.equals(tenantId))
          ..orderBy(<OrderingTerm Function($GlJournalEntriesTable)>[
            ($GlJournalEntriesTable t) => OrderingTerm.desc(t.postingDate),
            ($GlJournalEntriesTable t) => OrderingTerm.desc(t.createdAt),
          ]);
    return q.watch().asyncMap(_withLines);
  }

  Future<List<JournalEntry>> entries(String tenantId) =>
      watchEntries(tenantId).first;

  Future<JournalEntry?> entry(String tenantId, String id) async {
    final GlJournalEntryRow? row =
        await (select(glJournalEntries)..where(
              ($GlJournalEntriesTable t) =>
                  t.tenantId.equals(tenantId) & t.id.equals(id),
            ))
            .getSingleOrNull();
    if (row == null) {
      return null;
    }
    return (await _withLines(<GlJournalEntryRow>[row])).first;
  }

  /// Stores a local draft. Throws [UnbalancedJournalException] when it is not balanced and complete, and
  /// [ImmutableJournalException] when the stored journal is queued, synced or posted.
  Future<void> saveDraft(JournalEntry entry) async {
    entry.requireValid();
    await transaction(() async {
      final JournalEntry? stored = await this.entry(entry.tenantId, entry.id);
      if (stored != null && !stored.isEditable) {
        throw ImmutableJournalException(entry.id);
      }
      await _write(
        entry.copyWith(syncState: JournalSyncState.localDraft, lastError: null),
      );
    });
  }

  /// Moves a local draft into the outbox state. The persisted lines are checked again, so an entry that was
  /// tampered with after saving still cannot be queued unbalanced.
  Future<JournalEntry> markQueued(
    String tenantId,
    String id, {
    required bool post,
  }) async {
    return transaction(() async {
      final JournalEntry? stored = await entry(tenantId, id);
      if (stored == null) {
        throw StateError('Unknown journal $id');
      }
      stored.requireEditable();
      stored.requireValid();
      final JournalEntry queued = stored.copyWith(
        syncState: JournalSyncState.queued,
        postOnSync: post || stored.postOnSync,
        lastError: null,
      );
      await _write(queued);
      return queued;
    });
  }

  /// Bookkeeping of the sync: the outbox acknowledged it ([JournalSyncState.synced]) or refused it
  /// ([JournalSyncState.rejected], with the reason).
  Future<void> setSyncState(
    String tenantId,
    String id,
    JournalSyncState state, {
    String? error,
  }) async {
    await (update(glJournalEntries)..where(
          ($GlJournalEntriesTable t) =>
              t.tenantId.equals(tenantId) & t.id.equals(id),
        ))
        .write(
          GlJournalEntriesCompanion(
            syncState: Value<int>(state.index),
            lastError: Value<String?>(error),
            updatedAt: Value<DateTime>(DateTime.now().toUtc()),
          ),
        );
  }

  /// Removes a local draft or a refused entry; queued, synced and posted journals cannot be deleted.
  Future<void> discard(String tenantId, String id) async {
    final JournalEntry? stored = await entry(tenantId, id);
    if (stored == null) {
      return;
    }
    stored.requireEditable();
    await (delete(glJournalEntries)..where(
          ($GlJournalEntriesTable t) =>
              t.tenantId.equals(tenantId) & t.id.equals(id),
        ))
        .go();
  }

  /// Replaces the server copies with a fresh read; local drafts, queued and refused entries are kept.
  Future<void> replaceServerEntries(
    String tenantId,
    List<JournalEntry> fresh,
  ) async {
    await transaction(() async {
      await (delete(glJournalEntries)..where(
            ($GlJournalEntriesTable t) =>
                t.tenantId.equals(tenantId) &
                t.syncState.equals(JournalSyncState.synced.index),
          ))
          .go();
      for (final JournalEntry e in fresh) {
        await _write(e.copyWith(syncState: JournalSyncState.synced));
      }
    });
  }

  Future<List<JournalEntry>> _withLines(List<GlJournalEntryRow> rows) async {
    if (rows.isEmpty) {
      return <JournalEntry>[];
    }
    final List<GlJournalLineRow> all =
        await (select(glJournalLines)
              ..where(
                ($GlJournalLinesTable l) => l.entryId.isIn(<String>[
                  for (final GlJournalEntryRow r in rows) r.id,
                ]),
              )
              ..orderBy(<OrderingTerm Function($GlJournalLinesTable)>[
                ($GlJournalLinesTable l) => OrderingTerm.asc(l.lineNumber),
              ]))
            .get();
    final Map<String, List<JournalLine>> byEntry =
        <String, List<JournalLine>>{};
    for (final GlJournalLineRow l in all) {
      byEntry
          .putIfAbsent(l.entryId, () => <JournalLine>[])
          .add(
            JournalLine(
              accountId: l.accountId,
              accountCode: l.accountCode,
              accountName: l.accountName,
              debit: l.debit,
              credit: l.credit,
              description: l.description,
            ),
          );
    }
    return <JournalEntry>[
      for (final GlJournalEntryRow r in rows)
        JournalEntry(
          id: r.id,
          tenantId: r.tenantId,
          serverId: r.serverId,
          postingDate: r.postingDate,
          description: r.description,
          ledger: LedgerBook.parse(r.ledgerType),
          alsoPostTo: <LedgerBook>[
            for (final String c in r.alsoPostTo.split(','))
              if (c.isNotEmpty) LedgerBook.parse(c),
          ],
          status: JournalStatus.parse(r.status),
          syncState: JournalSyncState
              .values[r.syncState.clamp(0, JournalSyncState.values.length - 1)],
          postOnSync: r.postOnSync,
          lines: byEntry[r.id] ?? const <JournalLine>[],
          entryNumber: r.entryNumber,
          reversesJournalId: r.reversesJournalId,
          reversalReason: r.reversalReason,
          lastError: r.lastError,
          createdAt: r.createdAt,
        ),
    ];
  }

  Future<void> _write(JournalEntry e) async {
    await into(glJournalEntries).insertOnConflictUpdate(
      GlJournalEntriesCompanion.insert(
        id: e.id,
        tenantId: e.tenantId,
        serverId: Value<String?>(e.serverId),
        postingDate: e.postingDate,
        description: e.description,
        ledgerType: Value<String>(e.ledger.wire),
        alsoPostTo: Value<String>(
          e.alsoPostTo.map((LedgerBook b) => b.code).join(','),
        ),
        status: Value<String>(e.status.wire),
        syncState: Value<int>(e.syncState.index),
        postOnSync: Value<bool>(e.postOnSync),
        entryNumber: Value<String?>(e.entryNumber),
        reversesJournalId: Value<String?>(e.reversesJournalId),
        reversalReason: Value<String?>(e.reversalReason),
        lastError: Value<String?>(e.lastError),
        createdAt: e.createdAt,
        updatedAt: DateTime.now().toUtc(),
      ),
    );
    await (delete(
      glJournalLines,
    )..where(($GlJournalLinesTable l) => l.entryId.equals(e.id))).go();
    int n = 0;
    for (final JournalLine l in e.lines) {
      n++;
      await into(glJournalLines).insert(
        GlJournalLinesCompanion.insert(
          entryId: e.id,
          lineNumber: n,
          accountId: l.accountId,
          accountCode: Value<String>(l.accountCode),
          accountName: Value<String>(l.accountName),
          debit: Value<int>(l.debit),
          credit: Value<int>(l.credit),
          description: Value<String>(l.description),
        ),
      );
    }
  }

  // --- Accounts and templates -------------------------------------------------------------------------------------

  Future<List<GlAccount>> accounts(String tenantId) async {
    final List<GlAccountRow> rows =
        await (select(glAccounts)
              ..where(($GlAccountsTable t) => t.tenantId.equals(tenantId))
              ..orderBy(<OrderingTerm Function($GlAccountsTable)>[
                ($GlAccountsTable t) => OrderingTerm.asc(t.code),
              ]))
            .get();
    return <GlAccount>[
      for (final GlAccountRow r in rows)
        GlAccount(
          id: r.id,
          code: r.code,
          name: r.name,
          accountType: r.accountType,
          normalBalance: r.normalBalance,
          allowsManualPosting: r.allowsManualPosting,
          isActive: r.isActive,
        ),
    ];
  }

  Future<void> replaceAccounts(String tenantId, List<GlAccount> fresh) async {
    await transaction(() async {
      await (delete(
        glAccounts,
      )..where(($GlAccountsTable t) => t.tenantId.equals(tenantId))).go();
      for (final GlAccount a in fresh) {
        await into(glAccounts).insertOnConflictUpdate(
          GlAccountsCompanion.insert(
            tenantId: tenantId,
            id: a.id,
            code: a.code,
            name: a.name,
            accountType: Value<String>(a.accountType),
            normalBalance: Value<String>(a.normalBalance),
            allowsManualPosting: Value<bool>(a.allowsManualPosting),
            isActive: Value<bool>(a.isActive),
          ),
        );
      }
    });
  }

  Future<List<AccountingTemplate>> templates(String tenantId) async {
    final List<GlTemplateRow> rows =
        await (select(glTemplates)
              ..where(($GlTemplatesTable t) => t.tenantId.equals(tenantId))
              ..orderBy(<OrderingTerm Function($GlTemplatesTable)>[
                ($GlTemplatesTable t) => OrderingTerm.asc(t.code),
              ]))
            .get();
    return <AccountingTemplate>[
      for (final GlTemplateRow r in rows)
        AccountingTemplate.fromJson(
          jsonDecode(r.payload) as Map<String, dynamic>,
        ),
    ];
  }

  Future<void> replaceTemplates(
    String tenantId,
    List<AccountingTemplate> fresh,
  ) async {
    await transaction(() async {
      await (delete(
        glTemplates,
      )..where(($GlTemplatesTable t) => t.tenantId.equals(tenantId))).go();
      for (final AccountingTemplate t in fresh) {
        await into(glTemplates).insertOnConflictUpdate(
          GlTemplatesCompanion.insert(
            tenantId: tenantId,
            id: t.id,
            code: t.code,
            payload: jsonEncode(t.toJson()),
          ),
        );
      }
    });
  }

  // --- Report snapshots -------------------------------------------------------------------------------------------

  Future<void> saveSnapshot(
    String tenantId,
    String kind,
    String filterKey,
    Map<String, dynamic> payload,
  ) async {
    await into(glReportSnapshots).insertOnConflictUpdate(
      GlReportSnapshotsCompanion.insert(
        tenantId: tenantId,
        kind: kind,
        filterKey: filterKey,
        payload: jsonEncode(payload),
        syncedAt: DateTime.now().toUtc(),
      ),
    );
  }

  Future<Map<String, dynamic>?> snapshot(
    String tenantId,
    String kind,
    String filterKey,
  ) async {
    final GlReportSnapshotRow? row =
        await (select(glReportSnapshots)..where(
              ($GlReportSnapshotsTable t) =>
                  t.tenantId.equals(tenantId) &
                  t.kind.equals(kind) &
                  t.filterKey.equals(filterKey),
            ))
            .getSingleOrNull();
    return row == null ? null : jsonDecode(row.payload) as Map<String, dynamic>;
  }
}
