import 'dart:convert';
import 'dart:typed_data';

import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_engine.dart';
import '../domain/money.dart';
import '../domain/receivables_models.dart';
import '../domain/receivables_repository.dart';
import 'receivables_local_data_source.dart';
import 'receivables_remote_data_source.dart';

/// Offline-queue entities. They are listed in [SyncEngine.defaultTerminalEntities]: a 422/403 (item already settled,
/// no permission) parks the row as rejected instead of resending it forever.
const String receivableAllocationEntity = 'receivable_allocations';
const String receivableReversalEntity = 'receivable_reversals';
const String receivableDisputeEntity = 'receivable_disputes';

const List<String> _outboxEntities = <String>[
  receivableAllocationEntity,
  receivableReversalEntity,
  receivableDisputeEntity,
];

const String _allocationsPath = '$receivablesBase/allocations';

/// Cache-first repository: the last answers are served offline, a payload that does not parse never replaces a good
/// cache, and every booking goes through the shared outbox (the queue row UUID is the `Idempotency-Key`, so a replay
/// after a lost answer never books twice).
class ReceivablesRepositoryImpl implements ReceivablesRepository {
  ReceivablesRepositoryImpl(this._local, this._remote, this._engine);

  final ReceivablesLocalDataSource _local;
  final ReceivablesRemoteDataSource _remote;
  final SyncEngine _engine;

  static String _cur(String? currency) => currency ?? '_';

  // --- Dashboard, aging, risk, DSO, provision ----------------------------------------------------------------------

  @override
  Future<ReceivablesDashboard?> cachedDashboard(
    String tenantId, {
    String? currency,
  }) => _cached(
    tenantId,
    'dashboard:${_cur(currency)}',
    ReceivablesDashboard.fromJson,
  );

  @override
  Future<ReceivablesDashboard> refreshDashboard(
    String tenantId, {
    String? currency,
  }) => _refresh(
    tenantId,
    'dashboard:${_cur(currency)}',
    () => _remote.dashboard(currency: currency),
    ReceivablesDashboard.fromJson,
  );

  @override
  Future<AgingReport?> cachedAging(
    String tenantId, {
    String? customerId,
    String? currency,
  }) => _cached(
    tenantId,
    'aging:${customerId ?? 'all'}:${_cur(currency)}',
    AgingReport.fromJson,
  );

  @override
  Future<AgingReport> refreshAging(
    String tenantId, {
    String? customerId,
    String? currency,
  }) => _refresh(
    tenantId,
    'aging:${customerId ?? 'all'}:${_cur(currency)}',
    () => _remote.aging(customerId: customerId, currency: currency),
    AgingReport.fromJson,
  );

  @override
  Future<CreditPosition?> cachedCredit(String tenantId, String customerId) =>
      _cached(tenantId, 'credit:$customerId', CreditPosition.fromJson);

  @override
  Future<CreditPosition> refreshCredit(String tenantId, String customerId) =>
      _refresh(
        tenantId,
        'credit:$customerId',
        () => _remote.credit(customerId),
        CreditPosition.fromJson,
      );

  @override
  Future<RiskScore?> cachedRisk(String tenantId, String customerId) =>
      _cached(tenantId, 'risk:$customerId', RiskScore.fromJson);

  @override
  Future<RiskScore> refreshRisk(String tenantId, String customerId) => _refresh(
    tenantId,
    'risk:$customerId',
    () => _remote.risk(customerId),
    RiskScore.fromJson,
  );

  @override
  Future<List<CreditLimit>> cachedCreditLimits(
    String tenantId,
    String customerId,
  ) async =>
      await _cached(tenantId, 'limits:$customerId', _limits) ??
      const <CreditLimit>[];

  @override
  Future<List<CreditLimit>> refreshCreditLimits(
    String tenantId,
    String customerId,
  ) => _refresh(tenantId, 'limits:$customerId', () async {
    final List<dynamic> rows = await _remote.creditLimits(customerId);
    return <String, dynamic>{'items': rows};
  }, _limits);

  @override
  Future<List<UnreconciledPayment>> cachedUnreconciled(
    String tenantId,
    String customerId,
  ) async =>
      await _cached(tenantId, 'unreconciled:$customerId', _payments) ??
      const <UnreconciledPayment>[];

  @override
  Future<List<UnreconciledPayment>> refreshUnreconciled(
    String tenantId,
    String customerId,
  ) => _refresh(tenantId, 'unreconciled:$customerId', () async {
    final List<dynamic> rows = await _remote.unreconciledPayments(customerId);
    return <String, dynamic>{'items': rows};
  }, _payments);

  @override
  Future<DsoResult?> cachedDso(
    String tenantId, {
    String? customerId,
    String? currency,
  }) => _cached(
    tenantId,
    'dso:${customerId ?? 'all'}:${_cur(currency)}',
    DsoResult.fromJson,
  );

  @override
  Future<DsoResult> refreshDso(
    String tenantId, {
    String? customerId,
    String? currency,
    int? periodDays,
  }) => _refresh(
    tenantId,
    'dso:${customerId ?? 'all'}:${_cur(currency)}',
    () => _remote.dso(
      customerId: customerId,
      periodDays: periodDays,
      currency: currency,
    ),
    DsoResult.fromJson,
  );

  @override
  Future<ProvisionReport?> cachedProvision(
    String tenantId, {
    String? customerId,
    String? currency,
  }) => _cached(
    tenantId,
    'provision:${customerId ?? 'all'}:${_cur(currency)}',
    ProvisionReport.fromJson,
  );

  @override
  Future<ProvisionReport> refreshProvision(
    String tenantId, {
    String? customerId,
    String? currency,
  }) => _refresh(
    tenantId,
    'provision:${customerId ?? 'all'}:${_cur(currency)}',
    () => _remote.provision(customerId: customerId, currency: currency),
    ProvisionReport.fromJson,
  );

  // --- Items -----------------------------------------------------------------------------------------------------

  @override
  Future<List<ReceivableItem>> cachedItems(
    String tenantId,
    String customerId,
  ) async {
    final List<ReceivableItem> items = <ReceivableItem>[];
    for (final Map<String, dynamic> raw in await _local.items(
      tenantId,
      customerId,
    )) {
      try {
        items.add(ReceivableItem.fromJson(raw));
      } on FormatException {
        // A row that no longer parses is skipped; the next refresh replaces it.
      }
    }
    return sortItems(items);
  }

  @override
  Future<List<ReceivableItem>> refreshItems(
    String tenantId,
    String customerId, {
    String? currency,
  }) async {
    final List<Map<String, dynamic>> rows = await _remote.items(
      customerId: customerId,
      currency: currency,
    );
    final List<ReceivableItem> parsed;
    try {
      parsed = <ReceivableItem>[
        for (final Map<String, dynamic> r in rows) ReceivableItem.fromJson(r),
      ];
    } on FormatException {
      throw const ReceivablesException(
        ReceivablesErrorKind.unknown,
        detail: 'format',
      );
    }
    await _local.replaceItems(tenantId, customerId, rows);
    return sortItems(parsed);
  }

  @override
  Future<ReceivableItem?> cachedItem(String tenantId, String itemId) async {
    final Map<String, dynamic>? raw = await _local.item(tenantId, itemId);
    if (raw == null) {
      return null;
    }
    try {
      return ReceivableItem.fromJson(raw);
    } on FormatException {
      return null;
    }
  }

  @override
  Future<ReceivableItem> refreshItem(String tenantId, String itemId) async {
    final Map<String, dynamic> raw = await _remote.item(itemId);
    final ReceivableItem parsed;
    try {
      parsed = ReceivableItem.fromJson(raw);
    } on FormatException {
      throw const ReceivablesException(
        ReceivablesErrorKind.unknown,
        detail: 'format',
      );
    }
    await _local.putItem(tenantId, raw);
    return parsed;
  }

  // --- Statement -------------------------------------------------------------------------------------------------

  @override
  Future<CustomerStatement?> cachedStatement(
    String tenantId,
    String customerId, {
    String? currency,
  }) => _cached(
    tenantId,
    'statement:$customerId:${_cur(currency)}',
    CustomerStatement.fromJson,
  );

  @override
  Future<CustomerStatement> refreshStatement(
    String tenantId,
    String customerId, {
    DateTime? from,
    DateTime? to,
    String? currency,
  }) => _refresh(
    tenantId,
    'statement:$customerId:${_cur(currency)}',
    () => _remote.statement(customerId, from: from, to: to, currency: currency),
    CustomerStatement.fromJson,
  );

  @override
  Future<Uint8List> downloadStatement(
    String customerId,
    StatementFormat format, {
    DateTime? from,
    DateTime? to,
    String? currency,
  }) => _remote.downloadStatement(
    customerId,
    format,
    from: from,
    to: to,
    currency: currency,
  );

  // --- Outbox ----------------------------------------------------------------------------------------------------

  @override
  Future<BookingOutcome> allocate(
    String tenantId,
    List<AllocationDraft> drafts,
  ) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'allocations': <Map<String, dynamic>>[
        for (final AllocationDraft d in drafts) d.toJson(),
      ],
    };
    if (await _alreadyQueued(tenantId, receivableAllocationEntity, (
      QueueItem r,
    ) {
      return r.path == _allocationsPath &&
          r.payload != null &&
          jsonEncode(jsonDecode(r.payload!)) == jsonEncode(body);
    })) {
      // The same booking is already waiting: a second tap must not queue a second request.
      return const BookingOutcome(BookingStatus.queued);
    }
    final BookingOutcome outcome = await _submit(
      tenantId,
      receivableAllocationEntity,
      _allocationsPath,
      body,
    );
    if (outcome.status != BookingStatus.rejected) {
      for (final AllocationDraft d in drafts) {
        await _patchItem(tenantId, d.itemId, (Map<String, dynamic> item) {
          return _applyDraft(item, d);
        });
      }
    }
    return outcome;
  }

  @override
  Future<BookingOutcome> reverseAllocation(
    String tenantId,
    String itemId,
    String allocationId,
  ) async {
    final String path = '$_allocationsPath/$allocationId/reverse';
    if (await _alreadyQueued(
      tenantId,
      receivableReversalEntity,
      (QueueItem r) => r.path == path,
    )) {
      return const BookingOutcome(BookingStatus.queued);
    }
    final BookingOutcome outcome = await _submit(
      tenantId,
      receivableReversalEntity,
      path,
      null,
    );
    if (outcome.status != BookingStatus.rejected) {
      await _patchItem(tenantId, itemId, (Map<String, dynamic> item) {
        return _applyReversal(item, allocationId);
      });
    }
    return outcome;
  }

  @override
  Future<BookingOutcome> setDispute(
    String tenantId,
    String itemId, {
    required bool disputed,
    String? reason,
  }) async {
    final String path = '$receivablesBase/items/$itemId/dispute';
    final Map<String, dynamic> body = <String, dynamic>{
      'disputed': disputed,
      if (disputed && reason != null && reason.trim().isNotEmpty)
        'reason': reason.trim(),
    };
    if (await _alreadyQueued(tenantId, receivableDisputeEntity, (QueueItem r) {
      return r.path == path &&
          r.payload != null &&
          jsonEncode(jsonDecode(r.payload!)) == jsonEncode(body);
    })) {
      return const BookingOutcome(BookingStatus.queued);
    }
    final BookingOutcome outcome = await _submit(
      tenantId,
      receivableDisputeEntity,
      path,
      body,
    );
    if (outcome.status != BookingStatus.rejected) {
      await _patchItem(tenantId, itemId, (Map<String, dynamic> item) {
        return _applyDispute(item, disputed, body['reason'] as String?);
      });
    }
    return outcome;
  }

  Future<bool> _alreadyQueued(
    String tenantId,
    String entity,
    bool Function(QueueItem row) matches,
  ) async {
    for (final QueueItem r in await _engine.queued(tenantId, entity)) {
      if (!_refused(r) && matches(r)) {
        return true;
      }
    }
    return false;
  }

  Future<BookingOutcome> _submit(
    String tenantId,
    String entity,
    String path,
    Map<String, dynamic>? data,
  ) async {
    final String entityId = await _engine.enqueueCommand(
      tenantId: tenantId,
      entity: entity,
      path: path,
      data: data,
    );
    try {
      await _engine.flush(tenantId);
    } catch (_) {
      // Whatever went wrong, the booking is safely queued and the next sync cycle resends it.
    }
    for (final QueueItem r in await _engine.queued(tenantId, entity)) {
      if (r.entityId == entityId) {
        return _refused(r)
            ? BookingOutcome(BookingStatus.rejected, detail: r.lastError ?? '')
            : const BookingOutcome(BookingStatus.queued);
      }
    }
    return const BookingOutcome(BookingStatus.sent);
  }

  bool _refused(QueueItem item) =>
      item.state == QueueState.rejected || item.state == QueueState.conflict;

  @override
  Future<List<PendingBooking>> pendingActions(
    String tenantId, {
    String? itemId,
  }) async {
    final List<PendingBooking> out = <PendingBooking>[];
    for (final String entity in _outboxEntities) {
      for (final QueueItem r in await _engine.queued(tenantId, entity)) {
        final PendingBooking? a = await _toPending(tenantId, r);
        if (a != null && (itemId == null || a.itemId == itemId)) {
          out.add(a);
        }
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

  /// `.../allocations` | `.../allocations/{id}/reverse` | `.../items/{id}/dispute`.
  Future<PendingBooking?> _toPending(String tenantId, QueueItem r) async {
    final List<String> parts = r.path.split('/');
    if (parts.length < 2) {
      return null;
    }
    final bool rejected = _refused(r);
    final String detail = r.lastError ?? '';
    if (parts.last == 'reverse' && parts.length >= 3) {
      final String allocationId = parts[parts.length - 2];
      return PendingBooking(
        queueUuid: r.uuid,
        kind: ReceivablesActionKind.reversal,
        rejected: rejected,
        allocationId: allocationId,
        itemId: await _itemOfAllocation(tenantId, allocationId),
        detail: detail,
      );
    }
    if (parts.last == 'dispute' && parts.length >= 3) {
      return PendingBooking(
        queueUuid: r.uuid,
        kind: ReceivablesActionKind.dispute,
        rejected: rejected,
        itemId: parts[parts.length - 2],
        detail: detail,
      );
    }
    if (parts.last == 'allocations' && r.payload != null) {
      final dynamic body = jsonDecode(r.payload!);
      final List<dynamic> lines = body is Map && body['allocations'] is List
          ? body['allocations'] as List<dynamic>
          : const <dynamic>[];
      String? itemId;
      Money total = Money.zero;
      for (final dynamic line in lines) {
        if (line is Map) {
          itemId ??= '${line['receivable_item_id']}';
          total += Money.tryParse(line['amount']) ?? Money.zero;
        }
      }
      return PendingBooking(
        queueUuid: r.uuid,
        kind: ReceivablesActionKind.allocation,
        rejected: rejected,
        itemId: itemId,
        amount: total,
        detail: detail,
      );
    }
    return null;
  }

  Future<String?> _itemOfAllocation(
    String tenantId,
    String allocationId,
  ) async {
    // Reversals carry no item in their path: the cached items know which one owns the allocation.
    final ReceivableItem? owner = await _findOwner(tenantId, allocationId);
    return owner?.id;
  }

  Future<ReceivableItem?> _findOwner(
    String tenantId,
    String allocationId,
  ) async {
    final List<Map<String, dynamic>> all = await _local.allItems(tenantId);
    for (final Map<String, dynamic> raw in all) {
      final dynamic allocations = raw['allocations'];
      if (allocations is List) {
        for (final dynamic a in allocations) {
          if (a is Map && '${a['id']}' == allocationId) {
            return ReceivableItem.fromJson(raw);
          }
        }
      }
    }
    return null;
  }

  // --- Optimistic local effects ----------------------------------------------------------------------------------

  Future<void> _patchItem(
    String tenantId,
    String itemId,
    Map<String, dynamic> Function(Map<String, dynamic> item) patch,
  ) async {
    final Map<String, dynamic>? item = await _local.item(tenantId, itemId);
    if (item != null) {
      await _local.putItem(tenantId, patch(item));
    }
  }

  static Map<String, dynamic> _applyDraft(
    Map<String, dynamic> item,
    AllocationDraft draft,
  ) {
    final Money open = Money.parseOrZero(item['open_amount']) - draft.amount;
    final Money settled =
        Money.parseOrZero(item['settled_amount']) + draft.amount;
    return <String, dynamic>{
      ...item,
      'open_amount': open.toWire(),
      'settled_amount': settled.toWire(),
      'status': _statusFor(
        item,
        open,
        settled,
        writtenOff: draft.type == AllocationType.writeOff,
      ),
    };
  }

  static Map<String, dynamic> _applyReversal(
    Map<String, dynamic> item,
    String allocationId,
  ) {
    final List<dynamic> allocations = item['allocations'] is List
        ? List<dynamic>.of(item['allocations'] as List<dynamic>)
        : <dynamic>[];
    Money open = Money.parseOrZero(item['open_amount']);
    Money settled = Money.parseOrZero(item['settled_amount']);
    for (int i = 0; i < allocations.length; i++) {
      final dynamic a = allocations[i];
      if (a is Map &&
          '${a['id']}' == allocationId &&
          a['reversed_at'] == null) {
        final Money amount = Money.parseOrZero(a['amount']);
        open += amount;
        settled -= amount;
        allocations[i] = <String, dynamic>{
          ...Map<String, dynamic>.from(a),
          'reversed_at': DateTime.now().toUtc().toIso8601String(),
        };
      }
    }
    return <String, dynamic>{
      ...item,
      'allocations': allocations,
      'open_amount': open.toWire(),
      'settled_amount': settled.toWire(),
      'status': _statusFor(item, open, settled),
    };
  }

  static Map<String, dynamic> _applyDispute(
    Map<String, dynamic> item,
    bool disputed,
    String? reason,
  ) {
    final Map<String, dynamic> next = <String, dynamic>{
      ...item,
      'dispute_reason': disputed ? reason : null,
    };
    next['status'] = disputed
        ? 'disputed'
        : _statusFor(
            item,
            Money.parseOrZero(item['open_amount']),
            Money.parseOrZero(item['settled_amount']),
            disputed: false,
          );
    return next;
  }

  /// Status of an item after a local change, following the server vocabulary.
  static String _statusFor(
    Map<String, dynamic> item,
    Money open,
    Money settled, {
    bool writtenOff = false,
    bool? disputed,
  }) {
    if (!open.isPositive) {
      return writtenOff || item['status'] == 'written_off'
          ? 'written_off'
          : 'paid';
    }
    if (disputed ?? item['status'] == 'disputed') {
      return 'disputed';
    }
    final Object? days = item['days_past_due'];
    if (days is num && days > 0) {
      return 'overdue';
    }
    return settled.isPositive ? 'partially_paid' : 'open';
  }

  // --- Snapshots -------------------------------------------------------------------------------------------------

  Future<T?> _cached<T>(
    String tenantId,
    String key,
    T Function(Map<String, dynamic> json) parse,
  ) async {
    final StoredSnapshot? stored = await _local.snapshot(tenantId, key);
    if (stored == null) {
      return null;
    }
    try {
      return parse(stored.json);
    } on FormatException {
      return null;
    }
  }

  /// Fetches, parses, and only then stores: a payload that does not parse never replaces a good cache.
  Future<T> _refresh<T>(
    String tenantId,
    String key,
    Future<Map<String, dynamic>> Function() fetch,
    T Function(Map<String, dynamic> json) parse,
  ) async {
    final Map<String, dynamic> json = await fetch();
    final T value;
    try {
      value = parse(json);
    } on FormatException {
      throw const ReceivablesException(
        ReceivablesErrorKind.unknown,
        detail: 'format',
      );
    }
    await _local.saveSnapshot(tenantId, key, json);
    return value;
  }

  static List<CreditLimit> _limits(Map<String, dynamic> json) => <CreditLimit>[
    for (final dynamic raw in json['items'] as List<dynamic>? ?? <dynamic>[])
      if (raw is Map) CreditLimit.fromJson(Map<String, dynamic>.from(raw)),
  ];

  static List<UnreconciledPayment> _payments(
    Map<String, dynamic> json,
  ) => <UnreconciledPayment>[
    for (final dynamic raw in json['items'] as List<dynamic>? ?? <dynamic>[])
      if (raw is Map)
        UnreconciledPayment.fromJson(Map<String, dynamic>.from(raw)),
  ];
}
