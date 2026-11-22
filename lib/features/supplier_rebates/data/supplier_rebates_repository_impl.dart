import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_engine.dart';
import '../domain/supplier_rebate_models.dart';
import '../domain/supplier_rebates_repository.dart';

/// Offline-queue entity of the settlement workflow actions. It is listed in [SyncEngine.defaultTerminalEntities]: a
/// 422/403 (wrong state, version conflict, missing right) parks the row as rejected instead of resending it forever.
const String rebateActionEntity = 'rebate_proposal_actions';

/// Entities of the cached reads in the generic entity store (no schema of their own, so no Drift migration).
const String rebateAgreementEntity = 'rebate_agreements';
const String rebateProgressEntity = 'rebate_progress';
const String rebateRunsEntity = 'rebate_runs';
const String rebateProposalEntity = 'rebate_proposals';
const String rebateContractEntity = 'rebate_contracts';
const String rebateBalanceEntity = 'rebate_balances';

const String _rebates = '/rebates';

/// Maps a transport error to a [RebateException]; the RFC 7807 `detail` is kept.
RebateException mapRebateError(DioException e) {
  final Response<dynamic>? r = e.response;
  if (r == null) {
    return const RebateException(RebateErrorKind.offline);
  }
  final dynamic body = r.data;
  String detail = '';
  if (body is Map) {
    final dynamic d = body['detail'] ?? body['message'] ?? body['title'];
    detail = d is String ? d : '';
  }
  return switch (r.statusCode) {
    403 => RebateException(RebateErrorKind.forbidden, detail: detail),
    404 => RebateException(RebateErrorKind.notFound, detail: detail),
    409 || 422 => RebateException(RebateErrorKind.invalid, detail: detail),
    _ => RebateException(RebateErrorKind.unknown, detail: detail),
  };
}

class SupplierRebatesRepositoryImpl implements SupplierRebatesRepository {
  SupplierRebatesRepositoryImpl(this._db, this._dio, this._engine);

  final AppDatabase _db;
  final Dio _dio;
  final SyncEngine _engine;

  // --- Agreements ------------------------------------------------------------------------------------------------

  @override
  Future<List<RebateAgreement>> cachedAgreements(String tenantId) async =>
      _byStart(<RebateAgreement>[
        for (final EntityRecord r in await _rows(
          tenantId,
          rebateAgreementEntity,
        ))
          RebateAgreement.fromJson(_decode(r.payload)),
      ]);

  @override
  Future<List<RebateAgreement>> refreshAgreements(String tenantId) async {
    final Response<dynamic> res = await _guard(
      () => _dio.get<dynamic>(
        '$_rebates/agreements',
        queryParameters: <String, dynamic>{
          'direction': 'purchase',
          'per_page': 100,
        },
      ),
    );
    final List<RebateAgreement> fresh = <RebateAgreement>[
      for (final Map<String, dynamic> j in _list(res.data))
        RebateAgreement.fromJson(j),
    ];
    // The list does not carry the contributions: keep the ones a detail pull stored.
    final Map<String, RebateAgreement> old = <String, RebateAgreement>{
      for (final RebateAgreement a in await cachedAgreements(tenantId)) a.id: a,
    };
    final List<RebateAgreement> merged = <RebateAgreement>[
      for (final RebateAgreement a in fresh)
        if (a.contributions.isEmpty && (old[a.id]?.contributions.isNotEmpty ?? false))
          a.copyWith(contributions: old[a.id]!.contributions)
        else
          a,
    ];
    await _replace(tenantId, rebateAgreementEntity, <String, Map<String, dynamic>>{
      for (final RebateAgreement a in merged) a.id: a.toJson(),
    });
    return _byStart(merged);
  }

  @override
  Future<RebateAgreement?> cachedAgreement(String tenantId, String id) async {
    final EntityRecord? r = await _row(tenantId, rebateAgreementEntity, id);
    return r == null ? null : RebateAgreement.fromJson(_decode(r.payload));
  }

  @override
  Future<RebateAgreement> refreshAgreement(String tenantId, String id) async {
    final Response<dynamic> res = await _guard(
      () => _dio.get<dynamic>('$_rebates/agreements/$id'),
    );
    final RebateAgreement agreement = RebateAgreement.fromJson(
      _map(_map(res.data)['data']),
    );
    await _put(tenantId, rebateAgreementEntity, agreement.id, agreement.toJson());
    return agreement;
  }

  @override
  Future<AgreementProgress?> cachedProgress(
    String tenantId,
    String agreementId,
  ) async {
    final EntityRecord? r = await _row(
      tenantId,
      rebateProgressEntity,
      agreementId,
    );
    return r == null ? null : AgreementProgress.fromJson(_decode(r.payload));
  }

  @override
  Future<AgreementProgress> refreshProgress(
    String tenantId,
    String agreementId,
  ) async {
    final Response<dynamic> res = await _guard(
      () => _dio.get<dynamic>('$_rebates/agreements/$agreementId/progress'),
    );
    final AgreementProgress progress = AgreementProgress.fromJson(
      _map(_map(res.data)['data']),
    );
    await _put(tenantId, rebateProgressEntity, agreementId, progress.toJson());
    return progress;
  }

  @override
  Future<List<AccrualRun>> cachedRuns(String tenantId, String agreementId) async {
    final EntityRecord? r = await _row(tenantId, rebateRunsEntity, agreementId);
    return r == null ? const <AccrualRun>[] : _runs(_decode(r.payload)['items']);
  }

  @override
  Future<List<AccrualRun>> refreshRuns(
    String tenantId,
    String agreementId,
  ) async {
    final Response<dynamic> res = await _guard(
      () => _dio.get<dynamic>('$_rebates/agreements/$agreementId/accrual-runs'),
    );
    final List<AccrualRun> runs = _runs(_list(res.data));
    await _put(tenantId, rebateRunsEntity, agreementId, <String, dynamic>{
      'items': <Map<String, dynamic>>[for (final AccrualRun r in runs) r.toJson()],
    });
    return runs;
  }

  // --- Settlement proposals --------------------------------------------------------------------------------------

  @override
  Future<List<SettlementProposal>> cachedProposals(
    String tenantId, {
    String? agreementId,
  }) async {
    final List<SettlementProposal> proposals = <SettlementProposal>[
      for (final EntityRecord r in await _rows(tenantId, rebateProposalEntity))
        SettlementProposal.fromJson(_decode(r.payload)),
    ];
    return sortProposals(<SettlementProposal>[
      for (final SettlementProposal p in proposals)
        if (agreementId == null || p.agreementId == agreementId) p,
    ]);
  }

  @override
  Future<List<SettlementProposal>> refreshProposals(
    String tenantId, {
    String? agreementId,
  }) async {
    final Response<dynamic> res = await _guard(
      () => _dio.get<dynamic>(
        '$_rebates/settlement-proposals',
        queryParameters: <String, dynamic>{
          'agreement_id': ?agreementId,
          'per_page': 100,
        },
      ),
    );
    final List<SettlementProposal> proposals = <SettlementProposal>[
      for (final Map<String, dynamic> j in _list(res.data))
        SettlementProposal.fromJson(j),
    ];
    await _db.transaction(() async {
      // A scoped pull only replaces the proposals of that agreement.
      final List<SettlementProposal> old = await cachedProposals(
        tenantId,
        agreementId: agreementId,
      );
      final Set<String> fresh = <String>{
        for (final SettlementProposal p in proposals) p.id,
      };
      for (final SettlementProposal p in old) {
        if (!fresh.contains(p.id)) {
          await _delete(tenantId, rebateProposalEntity, p.id);
        }
      }
      for (final SettlementProposal p in proposals) {
        await _put(tenantId, rebateProposalEntity, p.id, p.toJson());
      }
    });
    return sortProposals(proposals);
  }

  @override
  Future<SettlementProposal?> cachedProposal(String tenantId, String id) async {
    final EntityRecord? r = await _row(tenantId, rebateProposalEntity, id);
    return r == null ? null : SettlementProposal.fromJson(_decode(r.payload));
  }

  @override
  Future<SettlementProposal> refreshProposal(String tenantId, String id) async {
    final Response<dynamic> res = await _guard(
      () => _dio.get<dynamic>('$_rebates/settlement-proposals/$id'),
    );
    final SettlementProposal proposal = SettlementProposal.fromJson(
      _map(_map(res.data)['data']),
    );
    await _put(tenantId, rebateProposalEntity, proposal.id, proposal.toJson());
    return proposal;
  }

  // --- Blanket agreements ----------------------------------------------------------------------------------------

  @override
  Future<List<BlanketContract>> cachedContracts(String tenantId) async =>
      <BlanketContract>[
        for (final EntityRecord r in await _rows(tenantId, rebateContractEntity))
          BlanketContract.fromJson(_decode(r.payload)),
      ];

  @override
  Future<List<BlanketContract>> refreshContracts(String tenantId) async {
    final Response<dynamic> res = await _guard(
      () => _dio.get<dynamic>(
        '/procurement/contracts',
        queryParameters: <String, dynamic>{'per_page': 100},
      ),
    );
    final List<BlanketContract> contracts = <BlanketContract>[
      for (final Map<String, dynamic> j in _list(res.data))
        BlanketContract.fromJson(j),
    ];
    await _replace(tenantId, rebateContractEntity, <String, Map<String, dynamic>>{
      for (final BlanketContract c in contracts) c.id: c.toJson(),
    });
    return contracts;
  }

  @override
  Future<BlanketBalance?> cachedBalance(
    String tenantId,
    String contractId,
  ) async {
    final EntityRecord? r = await _row(
      tenantId,
      rebateBalanceEntity,
      contractId,
    );
    return r == null ? null : BlanketBalance.fromJson(_decode(r.payload));
  }

  @override
  Future<BlanketBalance> refreshBalance(
    String tenantId,
    String contractId,
  ) async {
    final Response<dynamic> res = await _guard(
      () => _dio.get<dynamic>('/procurement/contracts/$contractId/balance'),
    );
    final BlanketBalance balance = BlanketBalance.fromJson(
      _map(_map(res.data)['data']),
    );
    await _put(tenantId, rebateBalanceEntity, contractId, balance.toJson());
    return balance;
  }

  // --- Outbox ----------------------------------------------------------------------------------------------------

  @override
  Future<ActionOutcome> act(
    String tenantId,
    String proposalId,
    ProposalAction action, {
    int? version,
  }) async {
    final String path =
        '$_rebates/settlement-proposals/$proposalId/${action.wire}';
    for (final QueueItem r in await _engine.queued(tenantId, rebateActionEntity)) {
      if (r.path == path && !_refused(r)) {
        // Already waiting: a second tap must not queue a second request.
        return const ActionOutcome(ActionStatus.queued);
      }
    }
    final String entityId = await _engine.enqueueCommand(
      tenantId: tenantId,
      entity: rebateActionEntity,
      path: path,
      data: <String, dynamic>{'version': ?version},
    );
    try {
      await _engine.flush(tenantId);
    } catch (_) {
      // Whatever went wrong, the action is safely queued and the next sync cycle resends it.
    }
    for (final QueueItem r in await _engine.queued(tenantId, rebateActionEntity)) {
      if (r.entityId == entityId) {
        return _refused(r)
            ? ActionOutcome(ActionStatus.rejected, detail: r.lastError ?? '')
            : const ActionOutcome(ActionStatus.queued);
      }
    }
    return const ActionOutcome(ActionStatus.sent);
  }

  @override
  Future<List<PendingAction>> pendingActions(
    String tenantId, {
    String? proposalId,
  }) async {
    final List<PendingAction> out = <PendingAction>[];
    for (final QueueItem r in await _engine.queued(tenantId, rebateActionEntity)) {
      final PendingAction? a = _toPending(r);
      if (a != null && (proposalId == null || a.proposalId == proposalId)) {
        out.add(a);
      }
    }
    return out;
  }

  @override
  Future<void> retryAction(String tenantId, String queueUuid) async {
    await _engine.retry(queueUuid);
    await _engine.flush(tenantId);
  }

  @override
  Future<void> dismissAction(String queueUuid) => _engine.discard(queueUuid);

  @override
  Future<int> flush(String tenantId) async =>
      (await _engine.flush(tenantId)).sent;

  bool _refused(QueueItem item) =>
      item.state == QueueState.rejected || item.state == QueueState.conflict;

  /// `/rebates/settlement-proposals/{id}/submit|approve|cancel`.
  PendingAction? _toPending(QueueItem r) {
    final List<String> parts = r.path.split('/');
    final int at = parts.indexOf('settlement-proposals');
    if (at < 0 || at + 2 >= parts.length) {
      return null;
    }
    final ProposalAction? action = ProposalAction.fromWire(parts[at + 2]);
    if (action == null) {
      return null;
    }
    return PendingAction(
      queueUuid: r.uuid,
      proposalId: parts[at + 1],
      action: action,
      rejected: _refused(r),
      detail: r.lastError ?? '',
    );
  }

  // --- Parsing ---------------------------------------------------------------------------------------------------

  static List<RebateAgreement> _byStart(List<RebateAgreement> agreements) =>
      agreements..sort((RebateAgreement a, RebateAgreement b) {
        final DateTime? x = a.startsOn;
        final DateTime? y = b.startsOn;
        if (x != null && y != null && x != y) {
          return y.compareTo(x);
        }
        return a.code.compareTo(b.code);
      });

  /// `data` is either the list itself or a paginator `{data: [...]}`.
  static List<Map<String, dynamic>> _list(Object? body) {
    Object? data = _map(body)['data'];
    if (data is Map) {
      data = data['data'];
    }
    return <Map<String, dynamic>>[
      if (data is List)
        for (final dynamic raw in data)
          if (raw is Map) Map<String, dynamic>.from(raw),
    ];
  }

  static List<AccrualRun> _runs(Object? items) => <AccrualRun>[
    if (items is List)
      for (final dynamic raw in items)
        if (raw is Map) AccrualRun.fromJson(Map<String, dynamic>.from(raw)),
  ];

  static Map<String, dynamic> _decode(String payload) =>
      Map<String, dynamic>.from(jsonDecode(payload) as Map<dynamic, dynamic>);

  static Map<String, dynamic> _map(Object? v) =>
      v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

  // --- Local store -----------------------------------------------------------------------------------------------

  Future<List<EntityRecord>> _rows(String tenantId, String entity) {
    return (_db.select(_db.entityRecords)..where(
          (EntityRecords t) =>
              t.tenantId.equals(tenantId) & t.entity.equals(entity),
        ))
        .get();
  }

  Future<EntityRecord?> _row(String tenantId, String entity, String id) {
    return (_db.select(_db.entityRecords)..where(
          (EntityRecords t) =>
              t.tenantId.equals(tenantId) &
              t.entity.equals(entity) &
              t.id.equals(id),
        ))
        .getSingleOrNull();
  }

  Future<void> _put(
    String tenantId,
    String entity,
    String id,
    Map<String, dynamic> payload,
  ) async {
    final DateTime now = DateTime.now().toUtc();
    await _db
        .into(_db.entityRecords)
        .insertOnConflictUpdate(
          EntityRecordsCompanion.insert(
            entity: entity,
            id: id,
            tenantId: tenantId,
            payload: jsonEncode(payload),
            syncStatus: SyncStatus.synced,
            localUpdatedAt: now,
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<void> _delete(String tenantId, String entity, String id) {
    return (_db.delete(_db.entityRecords)..where(
          (EntityRecords t) =>
              t.tenantId.equals(tenantId) &
              t.entity.equals(entity) &
              t.id.equals(id),
        ))
        .go();
  }

  Future<void> _replace(
    String tenantId,
    String entity,
    Map<String, Map<String, dynamic>> items,
  ) async {
    await _db.transaction(() async {
      await (_db.delete(_db.entityRecords)..where(
            (EntityRecords t) =>
                t.tenantId.equals(tenantId) & t.entity.equals(entity),
          ))
          .go();
      for (final MapEntry<String, Map<String, dynamic>> e in items.entries) {
        await _put(tenantId, entity, e.key, e.value);
      }
    });
  }

  Future<Response<dynamic>> _guard(
    Future<Response<dynamic>> Function() call,
  ) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw mapRebateError(e);
    }
  }
}
