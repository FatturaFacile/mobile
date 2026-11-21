import 'dart:async';

import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import 'purchase_requisition_tables.dart';

part 'purchase_requisition_dao.g.dart';

/// Joined representation of a local PR header and its ordered line items.
class LocalPurchaseRequisitionWithLines {
  const LocalPurchaseRequisitionWithLines({
    required this.header,
    required this.lines,
  });

  final LocalPurchaseRequisitionRow header;
  final List<LocalPurchaseRequisitionLineRow> lines;
}

/// Server-derived requisition payload ready for local upsert.
class ServerRequisitionWrite {
  const ServerRequisitionWrite({required this.header, required this.lines});

  final LocalPurchaseRequisitionsCompanion header;
  final List<LocalPurchaseRequisitionLinesCompanion> lines;
}

/// Tenant-scoped Drift DAO for Mod 044 Purchase Requisitions, Pending Approvals, and Audit Logs.
@DriftAccessor(
  tables: <Type>[
    LocalPurchaseRequisitions,
    LocalPurchaseRequisitionLines,
    LocalPendingApprovals,
    LocalApprovalAuditLogs,
  ],
)
class PurchaseRequisitionDao extends DatabaseAccessor<AppDatabase>
    with _$PurchaseRequisitionDaoMixin {
  PurchaseRequisitionDao(super.db);

  /// Streams all non-deleted purchase requisitions and their lines for [tenantId].
  Stream<List<LocalPurchaseRequisitionWithLines>> watchMyRequisitions(
    String tenantId,
  ) {
    final SimpleSelectStatement<
      $LocalPurchaseRequisitionsTable,
      LocalPurchaseRequisitionRow
    >
    query = select(localPurchaseRequisitions)
      ..where(
        ($LocalPurchaseRequisitionsTable t) =>
            t.tenantId.equals(tenantId) & t.deletedAt.isNull(),
      )
      ..orderBy(<OrderingTerm Function($LocalPurchaseRequisitionsTable)>[
        ($LocalPurchaseRequisitionsTable t) => OrderingTerm.desc(t.updatedAt),
      ]);

    return query.watch().asyncMap((
      List<LocalPurchaseRequisitionRow> headers,
    ) async {
      if (headers.isEmpty) {
        return <LocalPurchaseRequisitionWithLines>[];
      }
      final List<String> ids = headers
          .map((LocalPurchaseRequisitionRow h) => h.localId)
          .toList();
      final List<LocalPurchaseRequisitionLineRow> allLines =
          await (select(localPurchaseRequisitionLines)
                ..where(
                  ($LocalPurchaseRequisitionLinesTable l) =>
                      l.requisitionLocalId.isIn(ids),
                )
                ..orderBy(
                  <OrderingTerm Function($LocalPurchaseRequisitionLinesTable)>[
                    ($LocalPurchaseRequisitionLinesTable l) =>
                        OrderingTerm.asc(l.lineNumber),
                  ],
                ))
              .get();

      final Map<String, List<LocalPurchaseRequisitionLineRow>> grouped =
          <String, List<LocalPurchaseRequisitionLineRow>>{};
      for (final LocalPurchaseRequisitionLineRow line in allLines) {
        grouped
            .putIfAbsent(
              line.requisitionLocalId,
              () => <LocalPurchaseRequisitionLineRow>[],
            )
            .add(line);
      }

      return headers
          .map(
            (LocalPurchaseRequisitionRow h) =>
                LocalPurchaseRequisitionWithLines(
                  header: h,
                  lines:
                      grouped[h.localId] ?? <LocalPurchaseRequisitionLineRow>[],
                ),
          )
          .toList();
    });
  }

  /// Streams a single purchase requisition by either [localId] or [remoteId].
  Stream<LocalPurchaseRequisitionWithLines?> watchRequisitionById(
    String tenantId,
    String id,
  ) {
    final SimpleSelectStatement<
      $LocalPurchaseRequisitionsTable,
      LocalPurchaseRequisitionRow
    >
    query = select(localPurchaseRequisitions)
      ..where(
        ($LocalPurchaseRequisitionsTable t) =>
            t.tenantId.equals(tenantId) &
            t.deletedAt.isNull() &
            (t.localId.equals(id) | t.remoteId.equals(id)),
      )
      ..limit(1);

    return query.watchSingleOrNull().asyncMap((
      LocalPurchaseRequisitionRow? header,
    ) async {
      if (header == null) {
        return null;
      }
      final List<LocalPurchaseRequisitionLineRow> lines = await _linesForHeader(
        header.localId,
      );
      return LocalPurchaseRequisitionWithLines(header: header, lines: lines);
    });
  }

  /// Fetches a single purchase requisition by either `localId` or `remoteId`.
  Future<LocalPurchaseRequisitionWithLines?> getRequisitionById(
    String tenantId,
    String id,
  ) async {
    final LocalPurchaseRequisitionRow? header =
        await (select(localPurchaseRequisitions)
              ..where(
                ($LocalPurchaseRequisitionsTable t) =>
                    t.tenantId.equals(tenantId) &
                    t.deletedAt.isNull() &
                    (t.localId.equals(id) | t.remoteId.equals(id)),
              )
              ..limit(1))
            .getSingleOrNull();
    if (header == null) {
      return null;
    }
    return LocalPurchaseRequisitionWithLines(
      header: header,
      lines: await _linesForHeader(header.localId),
    );
  }

  /// Inserts or replaces a requisition header and its lines inside a single transaction.
  Future<void> upsertRequisitionWithLines(
    LocalPurchaseRequisitionsCompanion header,
    List<LocalPurchaseRequisitionLinesCompanion> lines,
  ) async {
    final String requisitionLocalId = header.localId.value;
    await transaction(() async {
      await into(localPurchaseRequisitions).insertOnConflictUpdate(header);
      await (delete(localPurchaseRequisitionLines)..where(
            ($LocalPurchaseRequisitionLinesTable l) =>
                l.requisitionLocalId.equals(requisitionLocalId),
          ))
          .go();
      if (lines.isNotEmpty) {
        await batch((Batch b) {
          b.insertAll(
            localPurchaseRequisitionLines,
            lines,
            mode: InsertMode.insertOrReplace,
          );
        });
      }
    });
  }

  /// Updates synchronization state and optional server-derived fields for [localId].
  Future<void> updateSyncState({
    required String tenantId,
    required String localId,
    required String syncStatus,
    String? remoteId,
    String? requisitionNumber,
    String? status,
    String? syncError,
    bool clearSyncError = false,
    bool? pendingSubmit,
    String? budgetCheckSnapshotJson,
    String? approvalProgressJson,
    DateTime? serverUpdatedAt,
  }) async {
    await (update(localPurchaseRequisitions)..where(
          ($LocalPurchaseRequisitionsTable t) =>
              t.tenantId.equals(tenantId) & t.localId.equals(localId),
        ))
        .write(
          LocalPurchaseRequisitionsCompanion(
            remoteId: remoteId != null
                ? Value<String?>(remoteId)
                : const Value<String?>.absent(),
            requisitionNumber: requisitionNumber != null
                ? Value<String?>(requisitionNumber)
                : const Value<String?>.absent(),
            status: status != null
                ? Value<String>(status)
                : const Value<String>.absent(),
            syncStatus: Value<String>(syncStatus),
            syncError: clearSyncError
                ? const Value<String?>(null)
                : (syncError != null
                      ? Value<String?>(syncError)
                      : const Value<String?>.absent()),
            pendingSubmit: pendingSubmit != null
                ? Value<bool>(pendingSubmit)
                : const Value<bool>.absent(),
            budgetCheckSnapshotJson: budgetCheckSnapshotJson != null
                ? Value<String?>(budgetCheckSnapshotJson)
                : const Value<String?>.absent(),
            approvalProgressJson: approvalProgressJson != null
                ? Value<String?>(approvalProgressJson)
                : const Value<String?>.absent(),
            serverUpdatedAt: serverUpdatedAt != null
                ? Value<DateTime?>(serverUpdatedAt)
                : const Value<DateTime?>.absent(),
            updatedAt: Value<DateTime>(DateTime.now().toUtc()),
          ),
        );
  }

  /// Returns all local requisitions waiting for upload or submission (`pending_upload` or `sync_error`).
  Future<List<LocalPurchaseRequisitionWithLines>> getPendingUploadRequisitions(
    String tenantId,
  ) async {
    final List<LocalPurchaseRequisitionRow> headers =
        await (select(localPurchaseRequisitions)
              ..where(
                ($LocalPurchaseRequisitionsTable t) =>
                    t.tenantId.equals(tenantId) &
                    t.deletedAt.isNull() &
                    (t.syncStatus.equals('pending_upload') |
                        t.syncStatus.equals('sync_error') |
                        t.pendingSubmit.equals(true)),
              )
              ..orderBy(
                <OrderingTerm Function($LocalPurchaseRequisitionsTable)>[
                  ($LocalPurchaseRequisitionsTable t) =>
                      OrderingTerm.asc(t.createdAt),
                ],
              ))
            .get();

    final List<LocalPurchaseRequisitionWithLines> result =
        <LocalPurchaseRequisitionWithLines>[];
    for (final LocalPurchaseRequisitionRow header in headers) {
      result.add(
        LocalPurchaseRequisitionWithLines(
          header: header,
          lines: await _linesForHeader(header.localId),
        ),
      );
    }
    return result;
  }

  /// Merges server requisitions into SQLite while preserving unsynced local drafts (`pending_upload`).
  Future<void> upsertServerRequisitions(
    String tenantId,
    List<ServerRequisitionWrite> items,
  ) async {
    await transaction(() async {
      for (final ServerRequisitionWrite item in items) {
        final String? remoteId = item.header.remoteId.present
            ? item.header.remoteId.value
            : null;
        final String incomingLocalId = item.header.localId.value;
        final LocalPurchaseRequisitionRow? existing =
            await (select(localPurchaseRequisitions)
                  ..where(
                    ($LocalPurchaseRequisitionsTable t) =>
                        t.tenantId.equals(tenantId) &
                        (t.localId.equals(incomingLocalId) |
                            (remoteId != null
                                ? t.remoteId.equals(remoteId)
                                : const Constant<bool>(false))),
                  )
                  ..limit(1))
                .getSingleOrNull();

        if (existing != null &&
            (existing.syncStatus == 'pending_upload' ||
                existing.pendingSubmit)) {
          continue;
        }

        final String targetLocalId = existing?.localId ?? incomingLocalId;
        final LocalPurchaseRequisitionsCompanion headerToWrite = item.header
            .copyWith(
              localId: Value<String>(targetLocalId),
              syncStatus: const Value<String>('synced'),
              syncError: const Value<String?>(null),
              pendingSubmit: const Value<bool>(false),
            );
        final List<LocalPurchaseRequisitionLinesCompanion> linesToWrite = item
            .lines
            .map(
              (LocalPurchaseRequisitionLinesCompanion l) =>
                  l.copyWith(requisitionLocalId: Value<String>(targetLocalId)),
            )
            .toList();

        await into(localPurchaseRequisitions)
            .insertOnConflictUpdate(headerToWrite);
        await (delete(localPurchaseRequisitionLines)..where(
              ($LocalPurchaseRequisitionLinesTable l) =>
                  l.requisitionLocalId.equals(targetLocalId),
            ))
            .go();
        if (linesToWrite.isNotEmpty) {
          await batch((Batch b) {
            b.insertAll(
              localPurchaseRequisitionLines,
              linesToWrite,
              mode: InsertMode.insertOrReplace,
            );
          });
        }
      }
    });
  }

  /// Soft-deletes a local requisition record.
  Future<void> softDeleteRequisition(String tenantId, String localId) async {
    await (update(localPurchaseRequisitions)..where(
          ($LocalPurchaseRequisitionsTable t) =>
              t.tenantId.equals(tenantId) & t.localId.equals(localId),
        ))
        .write(
          LocalPurchaseRequisitionsCompanion(
            deletedAt: Value<DateTime?>(DateTime.now().toUtc()),
          ),
        );
  }

  /// Streams pending manager approvals awaiting decision or still syncing.
  Stream<List<LocalPendingApprovalRow>> watchPendingApprovals(String tenantId) {
    return (select(localPendingApprovals)
          ..where(
            ($LocalPendingApprovalsTable t) =>
                t.tenantId.equals(tenantId) &
                (t.pendingDecision.isNull() |
                    t.syncStatus.equals('sync_error')),
          )
          ..orderBy(<OrderingTerm Function($LocalPendingApprovalsTable)>[
            ($LocalPendingApprovalsTable t) => OrderingTerm.desc(t.requestedAt),
          ]))
        .watch();
  }

  /// Streams the live unread/pending approval badge count for [tenantId].
  Stream<int> watchPendingApprovalCount(String tenantId) {
    return (select(localPendingApprovals)..where(
          ($LocalPendingApprovalsTable t) =>
              t.tenantId.equals(tenantId) & t.pendingDecision.isNull(),
        ))
        .watch()
        .map((List<LocalPendingApprovalRow> rows) => rows.length);
  }

  /// Replaces synced server pending approvals while preserving any queued offline decisions.
  Future<void> replacePendingApprovals(
    String tenantId,
    List<LocalPendingApprovalsCompanion> serverItems,
  ) async {
    await transaction(() async {
      final List<LocalPendingApprovalRow> unsyncedRows =
          await (select(localPendingApprovals)..where(
                ($LocalPendingApprovalsTable t) =>
                    t.tenantId.equals(tenantId) & t.pendingDecision.isNotNull(),
              ))
              .get();
      final Set<String> preservedIds = unsyncedRows
          .map((LocalPendingApprovalRow r) => r.approvalId)
          .toSet();
      final Set<String> preservedRequisitionIds = unsyncedRows
          .map((LocalPendingApprovalRow r) => r.requisitionRemoteId)
          .toSet();

      await (delete(localPendingApprovals)..where(
            ($LocalPendingApprovalsTable t) =>
                t.tenantId.equals(tenantId) & t.pendingDecision.isNull(),
          ))
          .go();

      final List<LocalPendingApprovalsCompanion> toInsert = serverItems
          .where(
            (LocalPendingApprovalsCompanion item) =>
                !preservedIds.contains(item.approvalId.value) &&
                !preservedRequisitionIds.contains(
                  item.requisitionRemoteId.value,
                ),
          )
          .toList();

      if (toInsert.isNotEmpty) {
        await batch((Batch b) {
          b.insertAll(
            localPendingApprovals,
            toInsert,
            mode: InsertMode.insertOrReplace,
          );
        });
      }
    });
  }

  /// Records a queued offline 1-tap approval/rejection decision (creating a stub row if needed).
  Future<void> markLocalApprovalDecision({
    required String tenantId,
    required String requisitionRemoteId,
    String? approvalId,
    required String decision,
    String? rejectionReason,
    String? oneClickToken,
    String syncStatus = 'pending_upload',
    String? syncError,
  }) async {
    final DateTime now = DateTime.now().toUtc();
    await transaction(() async {
      final LocalPendingApprovalRow? existing =
          await (select(localPendingApprovals)
                ..where(
                  ($LocalPendingApprovalsTable t) =>
                      t.tenantId.equals(tenantId) &
                      ((approvalId != null && approvalId.isNotEmpty
                              ? t.approvalId.equals(approvalId)
                              : const Constant<bool>(false)) |
                          t.requisitionRemoteId.equals(requisitionRemoteId)),
                )
                ..limit(1))
              .getSingleOrNull();

      if (existing != null) {
        await (update(localPendingApprovals)..where(
              ($LocalPendingApprovalsTable t) =>
                  t.approvalId.equals(existing.approvalId),
            ))
            .write(
              LocalPendingApprovalsCompanion(
                pendingDecision: Value<String?>(decision),
                pendingRejectionReason: Value<String?>(rejectionReason),
                oneClickToken: oneClickToken != null
                    ? Value<String?>(oneClickToken)
                    : const Value<String?>.absent(),
                syncStatus: Value<String>(syncStatus),
                syncError: Value<String?>(syncError),
                updatedAt: Value<DateTime>(now),
              ),
            );
        return;
      }

      final LocalPurchaseRequisitionRow? cachedPr =
          await (select(localPurchaseRequisitions)
                ..where(
                  ($LocalPurchaseRequisitionsTable t) =>
                      t.tenantId.equals(tenantId) &
                      (t.remoteId.equals(requisitionRemoteId) |
                          t.localId.equals(requisitionRemoteId)),
                )
                ..limit(1))
              .getSingleOrNull();

      final String resolvedApprovalId =
          (approvalId != null && approvalId.isNotEmpty)
          ? approvalId
          : 'offline-$requisitionRemoteId';

      await into(localPendingApprovals).insertOnConflictUpdate(
        LocalPendingApprovalsCompanion.insert(
          approvalId: resolvedApprovalId,
          tenantId: tenantId,
          requisitionRemoteId: requisitionRemoteId,
          requisitionNumber: cachedPr?.requisitionNumber ?? requisitionRemoteId,
          requesterName: cachedPr?.requesterName ?? '',
          costCenterCode: cachedPr?.costCenterCode ?? '',
          costCenterName: cachedPr?.costCenterName ?? '',
          projectName: Value<String?>(cachedPr?.projectName),
          urgency: Value<String>(cachedPr?.urgency ?? 'normal'),
          totalAmount: cachedPr?.totalAmount ?? 0,
          currency: Value<String>(cachedPr?.currency ?? 'CHF'),
          status: Value<String>(cachedPr?.status ?? 'pending_approval'),
          oneClickToken: Value<String?>(oneClickToken),
          pendingDecision: Value<String?>(decision),
          pendingRejectionReason: Value<String?>(rejectionReason),
          syncStatus: Value<String>(syncStatus),
          syncError: Value<String?>(syncError),
          requestedAt: cachedPr?.createdAt ?? now,
          updatedAt: now,
        ),
      );
    });
  }

  /// Fetches queued offline manager decisions waiting to be sent to the API.
  Future<List<LocalPendingApprovalRow>> getPendingOfflineDecisions(
    String tenantId,
  ) {
    return (select(localPendingApprovals)
          ..where(
            ($LocalPendingApprovalsTable t) =>
                t.tenantId.equals(tenantId) & t.pendingDecision.isNotNull(),
          )
          ..orderBy(<OrderingTerm Function($LocalPendingApprovalsTable)>[
            ($LocalPendingApprovalsTable t) => OrderingTerm.asc(t.updatedAt),
          ]))
        .get();
  }

  /// Removes a pending approval after server confirmation.
  Future<void> removePendingApproval(
    String tenantId,
    String approvalIdOrRequisitionId,
  ) async {
    await (delete(localPendingApprovals)..where(
          ($LocalPendingApprovalsTable t) =>
              t.tenantId.equals(tenantId) &
              (t.approvalId.equals(approvalIdOrRequisitionId) |
                  t.requisitionRemoteId.equals(approvalIdOrRequisitionId)),
        ))
        .go();
  }

  /// Streams audit logs matching any of [requisitionIds] (local and/or remote ID), newest first.
  Stream<List<LocalApprovalAuditLogRow>> watchAuditLogs(
    String tenantId,
    List<String> requisitionIds,
  ) {
    final List<String> cleanIds = requisitionIds
        .where((String id) => id.isNotEmpty)
        .toSet()
        .toList();
    if (cleanIds.isEmpty) {
      return Stream<List<LocalApprovalAuditLogRow>>.value(
        <LocalApprovalAuditLogRow>[],
      );
    }
    return (select(localApprovalAuditLogs)
          ..where(
            ($LocalApprovalAuditLogsTable t) =>
                t.tenantId.equals(tenantId) & t.requisitionId.isIn(cleanIds),
          )
          ..orderBy(<OrderingTerm Function($LocalApprovalAuditLogsTable)>[
            ($LocalApprovalAuditLogsTable t) => OrderingTerm.desc(t.occurredAt),
          ]))
        .watch();
  }

  /// Replaces synced server audit logs for [requisitionId] while preserving pending local entries.
  Future<void> replaceAuditLogs(
    String tenantId,
    String requisitionId,
    List<LocalApprovalAuditLogsCompanion> serverEntries,
  ) async {
    await transaction(() async {
      await (delete(localApprovalAuditLogs)..where(
            ($LocalApprovalAuditLogsTable t) =>
                t.tenantId.equals(tenantId) &
                t.requisitionId.equals(requisitionId) &
                t.isLocalPending.equals(false),
          ))
          .go();

      if (serverEntries.isNotEmpty) {
        await batch((Batch b) {
          b.insertAll(
            localApprovalAuditLogs,
            serverEntries,
            mode: InsertMode.insertOrReplace,
          );
        });
      }
    });
  }

  /// Appends a single audit log entry (typically an optimistic offline submission/decision).
  Future<void> appendAuditLog(LocalApprovalAuditLogsCompanion entry) async {
    await into(localApprovalAuditLogs).insertOnConflictUpdate(entry);
  }

  /// Reassigns local optimistic audit log entries from [fromRequisitionId] to [toRequisitionId].
  Future<void> reassignAuditLogRequisitionId(
    String tenantId, {
    required String fromRequisitionId,
    required String toRequisitionId,
  }) async {
    if (fromRequisitionId == toRequisitionId) {
      return;
    }
    await (update(localApprovalAuditLogs)..where(
          ($LocalApprovalAuditLogsTable t) =>
              t.tenantId.equals(tenantId) &
              t.requisitionId.equals(fromRequisitionId),
        ))
        .write(
          LocalApprovalAuditLogsCompanion(
            requisitionId: Value<String>(toRequisitionId),
          ),
        );
  }

  /// Clears optimistic local pending audit log entries once acknowledged by server sync.
  Future<void> clearPendingAuditLogs(
    String tenantId,
    List<String> requisitionIds,
  ) async {
    final List<String> cleanIds = requisitionIds
        .where((String id) => id.isNotEmpty)
        .toSet()
        .toList();
    if (cleanIds.isEmpty) {
      return;
    }
    await (delete(localApprovalAuditLogs)..where(
          ($LocalApprovalAuditLogsTable t) =>
              t.tenantId.equals(tenantId) &
              t.requisitionId.isIn(cleanIds) &
              t.isLocalPending.equals(true),
        ))
        .go();
  }

  /// Streams counts of pending and failed PR uploads/decisions for [tenantId].
  Stream<({int pending, int failed})> watchPendingSyncCounts(String tenantId) {
    final Stream<List<LocalPurchaseRequisitionRow>> prStream =
        (select(localPurchaseRequisitions)..where(
              ($LocalPurchaseRequisitionsTable t) =>
                  t.tenantId.equals(tenantId) &
                  t.deletedAt.isNull() &
                  (t.syncStatus.equals('pending_upload') |
                      t.syncStatus.equals('sync_error')),
            ))
            .watch();

    final Stream<List<LocalPendingApprovalRow>> approvalStream =
        (select(localPendingApprovals)..where(
              ($LocalPendingApprovalsTable t) =>
                  t.tenantId.equals(tenantId) & t.pendingDecision.isNotNull(),
            ))
            .watch();

    late final StreamController<({int pending, int failed})> controller;
    StreamSubscription<List<LocalPurchaseRequisitionRow>>? prSub;
    StreamSubscription<List<LocalPendingApprovalRow>>? approvalSub;
    int prPending = 0;
    int prFailed = 0;
    int appPending = 0;
    int appFailed = 0;
    bool prReady = false;
    bool approvalReady = false;

    void emit() {
      if (prReady && approvalReady && !controller.isClosed) {
        controller.add((
          pending: prPending + appPending,
          failed: prFailed + appFailed,
        ));
      }
    }

    controller = StreamController<({int pending, int failed})>(
      onListen: () {
        prSub = prStream.listen((List<LocalPurchaseRequisitionRow> rows) {
          prPending = rows.length;
          prFailed = rows
              .where(
                (LocalPurchaseRequisitionRow r) => r.syncStatus == 'sync_error',
              )
              .length;
          prReady = true;
          emit();
        });
        approvalSub = approvalStream.listen((
          List<LocalPendingApprovalRow> rows,
        ) {
          appPending = rows.length;
          appFailed = rows
              .where(
                (LocalPendingApprovalRow r) => r.syncStatus == 'sync_error',
              )
              .length;
          approvalReady = true;
          emit();
        });
      },
      onCancel: () async {
        await prSub?.cancel();
        await approvalSub?.cancel();
      },
    );
    return controller.stream;
  }

  Future<List<LocalPurchaseRequisitionLineRow>> _linesForHeader(
    String requisitionLocalId,
  ) {
    return (select(localPurchaseRequisitionLines)
          ..where(
            ($LocalPurchaseRequisitionLinesTable l) =>
                l.requisitionLocalId.equals(requisitionLocalId),
          )
          ..orderBy(
            <OrderingTerm Function($LocalPurchaseRequisitionLinesTable)>[
              ($LocalPurchaseRequisitionLinesTable l) =>
                  OrderingTerm.asc(l.lineNumber),
            ],
          ))
        .get();
  }
}
