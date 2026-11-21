import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/approval_models.dart';
import '../../domain/entities/budget_check.dart';
import '../../domain/entities/pr_reference_models.dart';
import '../../domain/entities/purchase_requisition.dart';
import '../../domain/repositories/purchase_requisition_repository.dart';
import '../local/purchase_requisition_dao.dart';
import '../mappers/purchase_requisition_mapper.dart';
import '../remote/purchase_requisition_remote_data_source.dart';

/// Offline-first implementation of [PurchaseRequisitionRepository] backed by Drift SQLite and REST APIs.
class PurchaseRequisitionRepositoryImpl
    implements PurchaseRequisitionRepository {
  PurchaseRequisitionRepositoryImpl(
    this._db,
    this._dao,
    this._remote, {
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final PurchaseRequisitionDao _dao;
  final PurchaseRequisitionRemoteDataSource _remote;
  final Uuid _uuid;

  final StreamController<PrSyncEvent> _syncEventsController =
      StreamController<PrSyncEvent>.broadcast();

  /// Releases internal stream resources.
  void dispose() {
    _syncEventsController.close();
  }

  @override
  Stream<PrSyncEvent> get syncEvents => _syncEventsController.stream;

  @override
  Stream<List<PurchaseRequisition>> watchMyRequisitions(String tenantId) {
    return _dao
        .watchMyRequisitions(tenantId)
        .map(
          (List<LocalPurchaseRequisitionWithLines> rows) =>
              rows.map(PurchaseRequisitionMapper.fromRow).toList(),
        );
  }

  @override
  Stream<PurchaseRequisition?> watchRequisition(String tenantId, String id) {
    return _dao
        .watchRequisitionById(tenantId, id)
        .map(
          (LocalPurchaseRequisitionWithLines? row) =>
              row == null ? null : PurchaseRequisitionMapper.fromRow(row),
        );
  }

  @override
  Stream<List<PendingApprovalItem>> watchPendingApprovals(String tenantId) {
    return _dao
        .watchPendingApprovals(tenantId)
        .map(
          (List<LocalPendingApprovalRow> rows) => rows
              .map(PurchaseRequisitionMapper.pendingApprovalFromRow)
              .toList(),
        );
  }

  @override
  Stream<int> watchPendingApprovalCount(String tenantId) {
    return _dao.watchPendingApprovalCount(tenantId);
  }

  @override
  Stream<List<ApprovalAuditEntry>> watchAuditLogs(
    String tenantId,
    String requisitionId,
  ) {
    return _dao.watchRequisitionById(tenantId, requisitionId).asyncExpand((
      LocalPurchaseRequisitionWithLines? pr,
    ) {
      final List<String> ids = <String>[
        requisitionId,
        if (pr != null) pr.header.localId,
        if (pr?.header.remoteId != null && pr!.header.remoteId!.isNotEmpty)
          pr.header.remoteId!,
      ];
      return _dao
          .watchAuditLogs(tenantId, ids)
          .map(
            (List<LocalApprovalAuditLogRow> rows) =>
                rows.map(PurchaseRequisitionMapper.auditLogFromRow).toList(),
          );
    });
  }

  @override
  Future<Either<Failure, PurchaseRequisition>> saveDraft(
    PurchaseRequisition draft, {
    required bool isOnline,
  }) async {
    final PurchaseRequisition localDraft = draft.copyWith(
      syncStatus: PrSyncStatus.pendingUpload,
      pendingSubmit: false,
      clearSyncError: true,
    );
    await _persistLocal(localDraft);

    if (!isOnline) {
      return Right<Failure, PurchaseRequisition>(localDraft);
    }

    try {
      final PurchaseRequisition uploaded = await _uploadHeaderAndLines(
        localDraft,
      );
      _emitEvent(
        PrSyncEvent(
          kind: PrSyncEventKind.draftSynced,
          requisitionId: uploaded.effectiveId,
          requisitionNumber: uploaded.requisitionNumber,
        ),
      );
      return Right<Failure, PurchaseRequisition>(uploaded);
    } on DioException catch (e) {
      final Failure failure = mapDioError(e);
      if (failure is NetworkFailure || failure is UnauthorizedFailure) {
        return Right<Failure, PurchaseRequisition>(localDraft);
      }
      await _dao.updateSyncState(
        tenantId: localDraft.tenantId,
        localId: localDraft.localId,
        syncStatus: PrSyncStatus.syncError.wireValue,
        syncError: failure.message,
      );
      return Left<Failure, PurchaseRequisition>(failure);
    }
  }

  @override
  Future<Either<Failure, BudgetCheckResult>> previewBudget(
    BudgetPreviewRequest request,
  ) async {
    try {
      final BudgetCheckResult result = await _remote.previewBudget(
        request.toJson(),
      );
      return Right<Failure, BudgetCheckResult>(result);
    } on DioException catch (e) {
      return Left<Failure, BudgetCheckResult>(mapDioError(e));
    }
  }

  @override
  Future<Either<Failure, PurchaseRequisition>> submitRequisition(
    PurchaseRequisition requisition, {
    required bool isOnline,
    bool acknowledgeBudgetWarning = false,
  }) async {
    final PurchaseRequisition staged = requisition.copyWith(
      syncStatus: PrSyncStatus.pendingUpload,
      clearSyncError: true,
    );
    await _persistLocal(staged);

    if (!isOnline) {
      final PurchaseRequisition queued = await _queueOfflineSubmit(staged);
      return Right<Failure, PurchaseRequisition>(queued);
    }

    if (!acknowledgeBudgetWarning) {
      try {
        final BudgetCheckResult preview = await _remote.previewBudget(
          BudgetPreviewRequest(
            costCenterId: staged.costCenterId,
            projectId: staged.projectId,
            currency: staged.currency.wireValue,
            totalAmount: staged.totalAmount,
            lines: staged.lines
                .map(
                  (PurchaseRequisitionLine l) => BudgetPreviewLineInput(
                    catalogItemId: l.catalogItemId,
                    description: l.description,
                    quantity: l.quantity,
                    unitPrice: l.unitPrice,
                  ),
                )
                .toList(),
          ).toJson(),
        );
        if (preview.status == BudgetCheckStatus.hardBlock) {
          final PurchaseRequisition blocked = await _markBudgetBlocked(
            staged,
            budgetCheck: preview,
            message: preview.message,
          );
          return Right<Failure, PurchaseRequisition>(blocked);
        }
        if (preview.status == BudgetCheckStatus.warning) {
          final PurchaseRequisition warned = staged.copyWith(
            budgetCheck: preview,
            status: PrStatus.draft,
            pendingSubmit: false,
            syncStatus: PrSyncStatus.pendingUpload,
          );
          await _persistLocal(warned);
          return Right<Failure, PurchaseRequisition>(warned);
        }
      } on DioException catch (e) {
        final Failure failure = mapDioError(e);
        if (failure is NetworkFailure) {
          final PurchaseRequisition queued = await _queueOfflineSubmit(staged);
          return Right<Failure, PurchaseRequisition>(queued);
        }
        // Non-network preview errors do not block attempting real server submit if supported.
      }
    }

    PurchaseRequisition current = staged;
    try {
      current = await _uploadHeaderAndLines(staged);
      final String remoteId = current.remoteId ?? current.localId;
      final Map<String, dynamic> submittedJson = await _remote
          .submitRequisition(
            remoteId,
            idempotencyKey: _uuid.v4(),
            acknowledgeBudgetWarning: acknowledgeBudgetWarning,
          );
      final PurchaseRequisition synced = await _saveServerRequisitionResponse(
        submittedJson,
        tenantId: staged.tenantId,
        fallbackLocalId: current.localId,
        fallbackPr: current,
      );
      await _dao.clearPendingAuditLogs(staged.tenantId, <String>[
        staged.localId,
        remoteId,
      ]);
      _emitEvent(
        PrSyncEvent(
          kind: PrSyncEventKind.submitted,
          requisitionId: synced.effectiveId,
          requisitionNumber: synced.requisitionNumber,
        ),
      );
      return Right<Failure, PurchaseRequisition>(synced);
    } on BudgetHardBlockException catch (e) {
      final PurchaseRequisition blocked = await _markBudgetBlocked(
        current,
        budgetCheck: e.budgetCheck,
        message: e.message,
      );
      return Right<Failure, PurchaseRequisition>(blocked);
    } on DioException catch (e) {
      final Failure failure = mapDioError(e);
      if (failure is NetworkFailure) {
        final PurchaseRequisition queued = await _queueOfflineSubmit(current);
        return Right<Failure, PurchaseRequisition>(queued);
      }
      await _dao.updateSyncState(
        tenantId: current.tenantId,
        localId: current.localId,
        syncStatus: PrSyncStatus.syncError.wireValue,
        syncError: failure.message,
        pendingSubmit: false,
      );
      return Left<Failure, PurchaseRequisition>(failure);
    }
  }

  @override
  Future<Either<Failure, PurchaseRequisition>> refreshRequisitionDetail(
    String tenantId,
    String id,
  ) async {
    try {
      final Map<String, dynamic> json = await _remote.fetchRequisitionDetail(
        id,
      );
      final LocalPurchaseRequisitionWithLines? existing = await _dao
          .getRequisitionById(tenantId, id);
      final PurchaseRequisition synced = await _saveServerRequisitionResponse(
        json,
        tenantId: tenantId,
        fallbackLocalId: existing?.header.localId,
      );
      return Right<Failure, PurchaseRequisition>(synced);
    } on DioException catch (e) {
      final Failure failure = mapDioError(e);
      final LocalPurchaseRequisitionWithLines? cached = await _dao
          .getRequisitionById(tenantId, id);
      if (cached != null && failure is NetworkFailure) {
        return Right<Failure, PurchaseRequisition>(
          PurchaseRequisitionMapper.fromRow(cached),
        );
      }
      return Left<Failure, PurchaseRequisition>(failure);
    }
  }

  @override
  Future<Either<Failure, void>> approveRequisition({
    required String tenantId,
    required String requisitionId,
    String? approvalId,
    required String actorId,
    required String actorName,
    String? comment,
    required bool isOnline,
  }) {
    return _performDecision(
      tenantId: tenantId,
      requisitionId: requisitionId,
      approvalId: approvalId,
      decision: 'approve',
      actorId: actorId,
      actorName: actorName,
      channel: ApprovalChannel.mobileApp,
      commentOrReason: comment,
      useOneClickEndpoint: false,
      isOnline: isOnline,
    );
  }

  @override
  Future<Either<Failure, void>> rejectRequisition({
    required String tenantId,
    required String requisitionId,
    String? approvalId,
    required String actorId,
    required String actorName,
    required String reason,
    required bool isOnline,
  }) {
    return _performDecision(
      tenantId: tenantId,
      requisitionId: requisitionId,
      approvalId: approvalId,
      decision: 'reject',
      actorId: actorId,
      actorName: actorName,
      channel: ApprovalChannel.mobileApp,
      commentOrReason: reason,
      useOneClickEndpoint: false,
      isOnline: isOnline,
    );
  }

  @override
  Future<Either<Failure, void>> executeOneClickAction({
    required String tenantId,
    required String requisitionId,
    String? approvalId,
    required String action,
    String? token,
    String? reason,
    required String actorId,
    required String actorName,
    required bool isOnline,
  }) {
    return _performDecision(
      tenantId: tenantId,
      requisitionId: requisitionId,
      approvalId: approvalId,
      decision: action.trim().toLowerCase(),
      actorId: actorId,
      actorName: actorName,
      channel: ApprovalChannel.mobilePush,
      commentOrReason: reason,
      token: token,
      useOneClickEndpoint: true,
      isOnline: isOnline,
    );
  }

  @override
  Future<PrSyncSummary> syncAll(String tenantId) async {
    int uploaded = 0;
    int submitted = 0;
    int approvalsSynced = 0;
    int budgetBlocked = 0;
    int failed = 0;

    // 1. Flush pending local drafts & queued submissions.
    final List<LocalPurchaseRequisitionWithLines> pendingPrs = await _dao
        .getPendingUploadRequisitions(tenantId);
    for (final LocalPurchaseRequisitionWithLines row in pendingPrs) {
      final PurchaseRequisition pr = PurchaseRequisitionMapper.fromRow(row);
      if (pr.syncStatus == PrSyncStatus.syncError &&
          !pr.pendingSubmit &&
          pr.status == PrStatus.budgetExceeded) {
        continue;
      }
      PurchaseRequisition syncedHeader = pr;
      try {
        syncedHeader = await _uploadHeaderAndLines(pr);
        uploaded++;
        if (pr.pendingSubmit) {
          final String remoteId = syncedHeader.remoteId ?? syncedHeader.localId;
          final Map<String, dynamic> submittedJson = await _remote
              .submitRequisition(remoteId, idempotencyKey: _uuid.v4());
          final PurchaseRequisition submittedPr =
              await _saveServerRequisitionResponse(
                submittedJson,
                tenantId: tenantId,
                fallbackLocalId: syncedHeader.localId,
                fallbackPr: syncedHeader,
              );
          await _dao.clearPendingAuditLogs(tenantId, <String>[
            pr.localId,
            remoteId,
          ]);
          submitted++;
          _emitEvent(
            PrSyncEvent(
              kind: PrSyncEventKind.submitted,
              requisitionId: submittedPr.effectiveId,
              requisitionNumber: submittedPr.requisitionNumber,
            ),
          );
        }
      } on BudgetHardBlockException catch (e) {
        await _markBudgetBlocked(
          syncedHeader,
          budgetCheck: e.budgetCheck,
          message: e.message,
        );
        budgetBlocked++;
      } on DioException catch (e) {
        final Failure failure = mapDioError(e);
        if (failure is NetworkFailure) {
          return PrSyncSummary(
            uploaded: uploaded,
            submitted: submitted,
            approvalsSynced: approvalsSynced,
            budgetBlocked: budgetBlocked,
            failed: failed,
            offline: true,
          );
        }
        await _dao.updateSyncState(
          tenantId: tenantId,
          localId: syncedHeader.localId,
          syncStatus: PrSyncStatus.syncError.wireValue,
          syncError: failure.message,
        );
        failed++;
        _emitEvent(
          PrSyncEvent(
            kind: PrSyncEventKind.syncFailed,
            requisitionId: syncedHeader.effectiveId,
            requisitionNumber: syncedHeader.requisitionNumber,
            message: failure.message,
          ),
        );
      }
    }

    // 2. Flush queued offline manager 1-tap approval/rejection decisions.
    final List<LocalPendingApprovalRow> pendingDecisions = await _dao
        .getPendingOfflineDecisions(tenantId);
    for (final LocalPendingApprovalRow row in pendingDecisions) {
      final String? decision = row.pendingDecision;
      if (decision == null) {
        continue;
      }
      try {
        final bool isOneClick = row.oneClickToken != null;
        final String? token = row.oneClickToken == '__one_click__'
            ? null
            : row.oneClickToken;
        final Map<String, dynamic> response = isOneClick
            ? await _remote.oneClickAction(
                requisitionId: row.requisitionRemoteId,
                approvalId: row.approvalId.startsWith('offline-')
                    ? null
                    : row.approvalId,
                action: decision,
                token: token,
                reason: row.pendingRejectionReason,
                channel: ApprovalChannel.mobilePush.wireValue,
                idempotencyKey: _uuid.v4(),
              )
            : decision == 'approve'
            ? await _remote.approveRequisition(
                row.requisitionRemoteId,
                channel: ApprovalChannel.mobileApp.wireValue,
                idempotencyKey: _uuid.v4(),
              )
            : await _remote.rejectRequisition(
                row.requisitionRemoteId,
                reason: row.pendingRejectionReason ?? '',
                channel: ApprovalChannel.mobileApp.wireValue,
                idempotencyKey: _uuid.v4(),
              );

        await _dao.removePendingApproval(tenantId, row.approvalId);
        await _dao.clearPendingAuditLogs(tenantId, <String>[
          row.requisitionRemoteId,
        ]);
        await _reconcileDecisionResponse(
          tenantId,
          row.requisitionRemoteId,
          decision,
          response,
        );
        approvalsSynced++;
        _emitEvent(
          PrSyncEvent(
            kind: PrSyncEventKind.approvalSynced,
            requisitionId: row.requisitionRemoteId,
            requisitionNumber: row.requisitionNumber,
          ),
        );
      } on DioException catch (e) {
        final Failure failure = mapDioError(e);
        if (failure is NetworkFailure) {
          return PrSyncSummary(
            uploaded: uploaded,
            submitted: submitted,
            approvalsSynced: approvalsSynced,
            budgetBlocked: budgetBlocked,
            failed: failed,
            offline: true,
          );
        }
        await _dao.markLocalApprovalDecision(
          tenantId: tenantId,
          requisitionRemoteId: row.requisitionRemoteId,
          approvalId: row.approvalId,
          decision: decision,
          rejectionReason: row.pendingRejectionReason,
          oneClickToken: row.oneClickToken,
          syncStatus: PrSyncStatus.syncError.wireValue,
          syncError: failure.message,
        );
        failed++;
      }
    }

    // 3. Pull fresh server state for "My Requests" and "To Approve".
    try {
      final List<Map<String, dynamic>> rawPrs = await _remote
          .fetchRequisitions();
      final List<ServerRequisitionWrite> writes = <ServerRequisitionWrite>[];
      for (final Map<String, dynamic> item in rawPrs) {
        final parsed = PurchaseRequisitionMapper.fromApiJson(
          item,
          tenantId: tenantId,
        );
        writes.add(parsed.write);
        if (parsed.auditLogs.isNotEmpty) {
          await _dao.replaceAuditLogs(
            tenantId,
            parsed.domain.effectiveId,
            parsed.auditLogs,
          );
        }
      }
      await _dao.upsertServerRequisitions(tenantId, writes);

      final List<Map<String, dynamic>> rawApprovals = await _remote
          .fetchPendingApprovals();
      final List<LocalPendingApprovalsCompanion> approvals = rawApprovals
          .map(
            (Map<String, dynamic> json) =>
                PurchaseRequisitionMapper.pendingApprovalFromApiJson(
                  json,
                  tenantId: tenantId,
                ),
          )
          .toList();
      await _dao.replacePendingApprovals(tenantId, approvals);
    } on DioException catch (e) {
      if (mapDioError(e) is NetworkFailure) {
        return PrSyncSummary(
          uploaded: uploaded,
          submitted: submitted,
          approvalsSynced: approvalsSynced,
          budgetBlocked: budgetBlocked,
          failed: failed,
          offline: true,
        );
      }
      failed++;
    }

    return PrSyncSummary(
      uploaded: uploaded,
      submitted: submitted,
      approvalsSynced: approvalsSynced,
      budgetBlocked: budgetBlocked,
      failed: failed,
    );
  }

  @override
  Future<List<CostCenterOption>> loadCostCenters(String tenantId) async {
    final List<CostCenterOption> cached = await _readEntityRecords(
      tenantId,
      'cost_centers',
      PurchaseRequisitionMapper.costCenterFromJson,
    );
    final List<Map<String, dynamic>> remote = await _remote.fetchCostCenters();
    if (remote.isEmpty) {
      return cached;
    }
    return _mergeById<CostCenterOption>(
      remote.map(PurchaseRequisitionMapper.costCenterFromJson),
      cached,
      (CostCenterOption c) => c.id,
    );
  }

  @override
  Future<List<ProjectOption>> loadProjects(String tenantId) async {
    final List<ProjectOption> cached = await _readEntityRecords(
      tenantId,
      'projects',
      PurchaseRequisitionMapper.projectFromJson,
    );
    final List<Map<String, dynamic>> remote = await _remote.fetchProjects();
    if (remote.isEmpty) {
      return cached;
    }
    return _mergeById<ProjectOption>(
      remote.map(PurchaseRequisitionMapper.projectFromJson),
      cached,
      (ProjectOption p) => p.id,
    );
  }

  @override
  Future<List<CatalogItemOption>> searchCatalogItems(
    String tenantId,
    String query,
  ) async {
    final String normalized = query.trim().toLowerCase();
    final List<CatalogItemOption> cached = await _readEntityRecords(
      tenantId,
      'products',
      PurchaseRequisitionMapper.catalogItemFromJson,
    );
    final List<CatalogItemOption> filteredCached = normalized.isEmpty
        ? cached
        : cached.where((CatalogItemOption item) {
            return item.name.toLowerCase().contains(normalized) ||
                item.sku.toLowerCase().contains(normalized) ||
                (item.barcode?.toLowerCase().contains(normalized) ?? false);
          }).toList();

    final List<Map<String, dynamic>> remote = await _remote.searchCatalog(
      query,
    );
    if (remote.isEmpty) {
      return filteredCached;
    }
    return _mergeById<CatalogItemOption>(
      remote.map(PurchaseRequisitionMapper.catalogItemFromJson),
      filteredCached,
      (CatalogItemOption item) => item.id,
    );
  }

  @override
  Future<CatalogItemOption?> findCatalogItemByBarcode(
    String tenantId,
    String code,
  ) async {
    final String normalized = code.trim().toLowerCase();
    if (normalized.isEmpty) {
      return null;
    }
    final List<CatalogItemOption> candidates = await searchCatalogItems(
      tenantId,
      code,
    );
    for (final CatalogItemOption item in candidates) {
      if ((item.barcode?.trim().toLowerCase() == normalized) ||
          item.sku.trim().toLowerCase() == normalized) {
        return item;
      }
    }
    return null;
  }

  Future<void> _persistLocal(PurchaseRequisition pr) async {
    final companions = PurchaseRequisitionMapper.toCompanions(pr);
    await _dao.upsertRequisitionWithLines(companions.header, companions.lines);
  }

  Future<PurchaseRequisition> _uploadHeaderAndLines(
    PurchaseRequisition pr,
  ) async {
    final Map<String, dynamic> body =
        PurchaseRequisitionMapper.toApiRequestBody(pr);
    final String idempotencyKey = _uuid.v4();
    final Map<String, dynamic> response =
        (pr.remoteId == null || pr.remoteId!.isEmpty)
        ? await _remote.createRequisition(body, idempotencyKey: idempotencyKey)
        : await _remote.updateRequisition(
            pr.remoteId!,
            body,
            idempotencyKey: idempotencyKey,
          );

    return _saveServerRequisitionResponse(
      response,
      tenantId: pr.tenantId,
      fallbackLocalId: pr.localId,
      fallbackPr: pr,
      preservePendingSubmit: pr.pendingSubmit,
    );
  }

  Future<PurchaseRequisition> _saveServerRequisitionResponse(
    Map<String, dynamic> json, {
    required String tenantId,
    String? fallbackLocalId,
    PurchaseRequisition? fallbackPr,
    bool preservePendingSubmit = false,
  }) async {
    final parsed = PurchaseRequisitionMapper.fromApiJson(
      json,
      tenantId: tenantId,
      fallbackLocalId: fallbackLocalId,
      fallbackLines: fallbackPr?.lines,
    );
    final PurchaseRequisition updatedDomain = preservePendingSubmit
        ? parsed.domain.copyWith(
            pendingSubmit: true,
            syncStatus: PrSyncStatus.pendingUpload,
          )
        : parsed.domain;
    await _persistLocal(updatedDomain);

    final String? remoteId = updatedDomain.remoteId;
    if (fallbackLocalId != null && remoteId != null && remoteId.isNotEmpty) {
      await _dao.reassignAuditLogRequisitionId(
        tenantId,
        fromRequisitionId: fallbackLocalId,
        toRequisitionId: remoteId,
      );
    }
    if (parsed.auditLogs.isNotEmpty) {
      await _dao.replaceAuditLogs(
        tenantId,
        updatedDomain.effectiveId,
        parsed.auditLogs,
      );
    }
    return updatedDomain;
  }

  Future<PurchaseRequisition> _queueOfflineSubmit(
    PurchaseRequisition pr,
  ) async {
    final DateTime now = DateTime.now().toUtc();
    final PurchaseRequisition queued = pr.copyWith(
      status: PrStatus.pendingApproval,
      syncStatus: PrSyncStatus.pendingUpload,
      pendingSubmit: true,
      clearSyncError: true,
      updatedAt: now,
    );
    await _persistLocal(queued);
    await _dao.appendAuditLog(
      LocalApprovalAuditLogsCompanion.insert(
        id: 'local-submit-${queued.localId}',
        tenantId: queued.tenantId,
        requisitionId: queued.effectiveId,
        level: const Value<int>(1),
        action: ApprovalActionType.submitted.wireValue,
        actorId: Value<String?>(queued.requesterId),
        actorName: queued.requesterName,
        channel: Value<String>(ApprovalChannel.mobileApp.wireValue),
        occurredAt: now,
        isLocalPending: const Value<bool>(true),
      ),
    );
    return queued;
  }

  Future<PurchaseRequisition> _markBudgetBlocked(
    PurchaseRequisition pr, {
    required BudgetCheckResult budgetCheck,
    required String message,
  }) async {
    final DateTime now = DateTime.now().toUtc();
    final String resolvedMsg = message.trim().isNotEmpty
        ? message.trim()
        : budgetCheck.message;
    final PurchaseRequisition blocked = pr.copyWith(
      status: PrStatus.budgetExceeded,
      syncStatus: PrSyncStatus.syncError,
      syncError: resolvedMsg,
      pendingSubmit: false,
      budgetCheck: budgetCheck,
      updatedAt: now,
    );
    await _persistLocal(blocked);
    await _dao.appendAuditLog(
      LocalApprovalAuditLogsCompanion.insert(
        id: 'local-budget-block-${_uuid.v4()}',
        tenantId: blocked.tenantId,
        requisitionId: blocked.effectiveId,
        level: const Value<int>(1),
        action: ApprovalActionType.budgetBlocked.wireValue,
        actorName: 'Mod 019 Budget',
        channel: Value<String>(ApprovalChannel.system.wireValue),
        comment: Value<String?>(resolvedMsg),
        occurredAt: now,
        isLocalPending: const Value<bool>(false),
      ),
    );
    _emitEvent(
      PrSyncEvent(
        kind: PrSyncEventKind.budgetBlocked,
        requisitionId: blocked.effectiveId,
        requisitionNumber: blocked.requisitionNumber,
        message: resolvedMsg,
        budgetCheck: budgetCheck,
      ),
    );
    return blocked;
  }

  Future<Either<Failure, void>> _performDecision({
    required String tenantId,
    required String requisitionId,
    String? approvalId,
    required String decision,
    required String actorId,
    required String actorName,
    required ApprovalChannel channel,
    String? commentOrReason,
    String? token,
    required bool useOneClickEndpoint,
    required bool isOnline,
  }) async {
    if (decision == 'reject' &&
        (commentOrReason == null || commentOrReason.trim().isEmpty)) {
      return const Left<Failure, void>(
        ValidationFailure(
          'Rejection reason is required',
          fieldErrors: <String, List<String>>{
            'reason': <String>['required'],
          },
        ),
      );
    }

    if (!isOnline) {
      await _queueOfflineDecision(
        tenantId: tenantId,
        requisitionId: requisitionId,
        approvalId: approvalId,
        decision: decision,
        actorId: actorId,
        actorName: actorName,
        channel: channel,
        commentOrReason: commentOrReason,
        token: useOneClickEndpoint ? (token ?? '__one_click__') : null,
      );
      return const Right<Failure, void>(null);
    }

    final String idempotencyKey = _uuid.v4();
    try {
      final Map<String, dynamic> response = useOneClickEndpoint
          ? await _remote.oneClickAction(
              requisitionId: requisitionId,
              approvalId: approvalId,
              action: decision,
              token: token,
              reason: decision == 'reject' ? commentOrReason?.trim() : null,
              channel: channel.wireValue,
              idempotencyKey: idempotencyKey,
            )
          : decision == 'approve'
          ? await _remote.approveRequisition(
              requisitionId,
              comment: commentOrReason,
              channel: channel.wireValue,
              idempotencyKey: idempotencyKey,
            )
          : await _remote.rejectRequisition(
              requisitionId,
              reason: commentOrReason!.trim(),
              channel: channel.wireValue,
              idempotencyKey: idempotencyKey,
            );

      await _dao.removePendingApproval(tenantId, approvalId ?? requisitionId);
      await _reconcileDecisionResponse(
        tenantId,
        requisitionId,
        decision,
        response,
        actorId: actorId,
        actorName: actorName,
        channel: channel,
        commentOrReason: commentOrReason,
      );
      _emitEvent(
        PrSyncEvent(
          kind: PrSyncEventKind.approvalSynced,
          requisitionId: requisitionId,
        ),
      );
      return const Right<Failure, void>(null);
    } on DioException catch (e) {
      final Failure failure = mapDioError(e);
      if (failure is NetworkFailure) {
        await _queueOfflineDecision(
          tenantId: tenantId,
          requisitionId: requisitionId,
          approvalId: approvalId,
          decision: decision,
          actorId: actorId,
          actorName: actorName,
          channel: channel,
          commentOrReason: commentOrReason,
          token: useOneClickEndpoint ? (token ?? '__one_click__') : null,
        );
        return const Right<Failure, void>(null);
      }
      return Left<Failure, void>(failure);
    }
  }

  Future<void> _queueOfflineDecision({
    required String tenantId,
    required String requisitionId,
    String? approvalId,
    required String decision,
    required String actorId,
    required String actorName,
    required ApprovalChannel channel,
    String? commentOrReason,
    String? token,
  }) async {
    final DateTime now = DateTime.now().toUtc();
    await _dao.markLocalApprovalDecision(
      tenantId: tenantId,
      requisitionRemoteId: requisitionId,
      approvalId: approvalId,
      decision: decision,
      rejectionReason: decision == 'reject' ? commentOrReason?.trim() : null,
      oneClickToken: token,
      syncStatus: PrSyncStatus.pendingUpload.wireValue,
    );

    final LocalPurchaseRequisitionWithLines? cachedPr = await _dao
        .getRequisitionById(tenantId, requisitionId);
    if (cachedPr != null) {
      await _dao.updateSyncState(
        tenantId: tenantId,
        localId: cachedPr.header.localId,
        syncStatus: cachedPr.header.syncStatus,
        status: decision == 'approve'
            ? PrStatus.approved.wireValue
            : PrStatus.rejected.wireValue,
      );
    }

    await _dao.appendAuditLog(
      LocalApprovalAuditLogsCompanion.insert(
        id: 'local-decision-${_uuid.v4()}',
        tenantId: tenantId,
        requisitionId: cachedPr?.header.remoteId ?? requisitionId,
        level: const Value<int>(1),
        action: decision == 'approve'
            ? ApprovalActionType.approved.wireValue
            : ApprovalActionType.rejected.wireValue,
        actorId: Value<String?>(actorId),
        actorName: actorName,
        channel: Value<String>(channel.wireValue),
        comment: Value<String?>(commentOrReason?.trim()),
        occurredAt: now,
        isLocalPending: const Value<bool>(true),
      ),
    );
  }

  Future<void> _reconcileDecisionResponse(
    String tenantId,
    String requisitionId,
    String decision,
    Map<String, dynamic> response, {
    String? actorId,
    String? actorName,
    ApprovalChannel channel = ApprovalChannel.mobileApp,
    String? commentOrReason,
  }) async {
    final Object? nestedPr =
        response['purchase_requisition'] ?? response['requisition'];
    final Map<String, dynamic>? prMap = nestedPr is Map
        ? nestedPr.map(
            (dynamic k, dynamic v) => MapEntry<String, dynamic>('$k', v),
          )
        : (response.containsKey('lines') ||
                  response.containsKey('cost_center_id')
              ? response
              : null);

    if (prMap != null) {
      final LocalPurchaseRequisitionWithLines? existing = await _dao
          .getRequisitionById(tenantId, requisitionId);
      await _saveServerRequisitionResponse(
        prMap,
        tenantId: tenantId,
        fallbackLocalId: existing?.header.localId,
      );
      return;
    }

    final LocalPurchaseRequisitionWithLines? existing = await _dao
        .getRequisitionById(tenantId, requisitionId);
    final String? statusFromApi = response['status']?.toString();
    final String resolvedStatus =
        statusFromApi != null && statusFromApi.isNotEmpty
        ? statusFromApi
        : (decision == 'approve'
              ? PrStatus.approved.wireValue
              : PrStatus.rejected.wireValue);

    if (existing != null) {
      await _dao.updateSyncState(
        tenantId: tenantId,
        localId: existing.header.localId,
        syncStatus: PrSyncStatus.synced.wireValue,
        status: resolvedStatus,
        clearSyncError: true,
      );
    }

    if (actorName != null && actorName.isNotEmpty) {
      await _dao.appendAuditLog(
        LocalApprovalAuditLogsCompanion.insert(
          id: 'srv-decision-${_uuid.v4()}',
          tenantId: tenantId,
          requisitionId: existing?.header.remoteId ?? requisitionId,
          level: Value<int>((response['level'] as num?)?.toInt() ?? 1),
          action: decision == 'approve'
              ? ApprovalActionType.approved.wireValue
              : ApprovalActionType.rejected.wireValue,
          actorId: Value<String?>(actorId),
          actorName: actorName,
          channel: Value<String>(channel.wireValue),
          comment: Value<String?>(commentOrReason?.trim()),
          occurredAt: DateTime.now().toUtc(),
          isLocalPending: const Value<bool>(false),
        ),
      );
    }
  }

  Future<List<T>> _readEntityRecords<T>(
    String tenantId,
    String entity,
    T Function(Map<String, dynamic> json) mapper,
  ) async {
    final List<EntityRecord> rows =
        await (_db.select(_db.entityRecords)..where(
              (EntityRecords t) =>
                  t.tenantId.equals(tenantId) &
                  t.entity.equals(entity) &
                  t.deletedAt.isNull(),
            ))
            .get();
    final List<T> result = <T>[];
    for (final EntityRecord row in rows) {
      try {
        final dynamic decoded = jsonDecode(row.payload);
        if (decoded is Map) {
          result.add(
            mapper(
              decoded.map(
                (dynamic k, dynamic v) => MapEntry<String, dynamic>('$k', v),
              ),
            ),
          );
        }
      } on FormatException {
        continue;
      }
    }
    return result;
  }

  List<T> _mergeById<T>(
    Iterable<T> primary,
    Iterable<T> secondary,
    String Function(T) idOf,
  ) {
    final Map<String, T> map = <String, T>{};
    for (final T item in secondary) {
      final String id = idOf(item);
      if (id.isNotEmpty) {
        map[id] = item;
      }
    }
    for (final T item in primary) {
      final String id = idOf(item);
      if (id.isNotEmpty) {
        map[id] = item;
      }
    }
    return map.values.toList();
  }

  void _emitEvent(PrSyncEvent event) {
    if (!_syncEventsController.isClosed) {
      _syncEventsController.add(event);
    }
  }
}
