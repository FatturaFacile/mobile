import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_engine.dart';
import '../domain/gl_models.dart';
import '../domain/gl_repository.dart';
import 'local/gl_dao.dart';

/// Offline-queue entity of the journals and stornos. Listed in [SyncEngine.defaultTerminalEntities], so a 422 (closed
/// period, unbalanced for the server) parks the write instead of resending it on every cycle.
const String glJournalEntity = 'gl_journals';

const String _base = '/general-ledger';

/// Maps a transport error to a [GlException]; the RFC 7807 `detail` is kept.
GlException mapGlError(DioException e) {
  final Response<dynamic>? r = e.response;
  if (r == null) {
    return const GlException(GlErrorKind.offline);
  }
  final dynamic body = r.data;
  String detail = '';
  if (body is Map) {
    final dynamic d = body['detail'] ?? body['message'] ?? body['title'];
    detail = d is String ? d : '';
  }
  return switch (r.statusCode) {
    403 => GlException(GlErrorKind.forbidden, detail: detail),
    404 => GlException(GlErrorKind.notFound, detail: detail),
    409 => GlException(GlErrorKind.conflict, detail: detail),
    422 => GlException(GlErrorKind.invalid, detail: detail),
    _ => GlException(GlErrorKind.unknown, detail: detail),
  };
}

class GlRepositoryImpl implements GlRepository {
  GlRepositoryImpl(
    this._db,
    this._dio,
    this._engine, {
    Uuid? uuid,
    DateTime Function()? clock,
  }) : _uuid = uuid ?? const Uuid(),
       _clock = clock ?? _utcNow;

  final AppDatabase _db;
  final Dio _dio;
  final SyncEngine _engine;
  final Uuid _uuid;
  final DateTime Function() _clock;

  static DateTime _utcNow() => DateTime.now().toUtc();

  GlDao get _dao => _db.glDao;

  // --- Reference data ---------------------------------------------------------------------------------------------

  @override
  Future<List<GlAccount>> cachedAccounts(String tenantId) =>
      _dao.accounts(tenantId);

  @override
  Future<List<GlAccount>> refreshAccounts(String tenantId) async {
    final List<GlAccount> fresh = <GlAccount>[
      for (final Map<String, dynamic> raw in await _pages(
        '$_base/accounts',
        const <String, dynamic>{},
        perPage: 200,
      ))
        GlAccount.fromJson(raw),
    ];
    await _dao.replaceAccounts(tenantId, fresh);
    return _dao.accounts(tenantId);
  }

  @override
  Future<List<AccountingTemplate>> cachedTemplates(String tenantId) =>
      _dao.templates(tenantId);

  @override
  Future<List<AccountingTemplate>> refreshTemplates(String tenantId) async {
    final Response<dynamic> res = await _guard(
      () => _dio.get<dynamic>('$_base/accounting-templates'),
    );
    final List<AccountingTemplate> fresh = <AccountingTemplate>[
      for (final dynamic raw in _list(_map(res.data)['data']))
        if (raw is Map)
          AccountingTemplate.fromJson(Map<String, dynamic>.from(raw)),
    ];
    await _dao.replaceTemplates(tenantId, fresh);
    return _dao.templates(tenantId);
  }

  // --- Journals ---------------------------------------------------------------------------------------------------

  @override
  Stream<List<JournalEntry>> watchJournals(String tenantId) =>
      _dao.watchEntries(tenantId);

  @override
  Future<void> refreshJournals(String tenantId) async {
    final List<JournalEntry> fresh = <JournalEntry>[
      for (final Map<String, dynamic> raw in await _pages(
        '$_base/journals',
        const <String, dynamic>{},
        perPage: 100,
        maxPages: 3,
      ))
        JournalEntry.fromJson(tenantId, raw),
    ];
    await _dao.replaceServerEntries(tenantId, fresh);
  }

  @override
  Future<void> saveDraft(JournalEntry entry) => _dao.saveDraft(entry);

  @override
  Future<SubmitOutcome> submit(JournalEntry entry, {bool post = true}) async {
    entry.requireValid();
    final JournalEntry stored =
        await _dao.entry(entry.tenantId, entry.id) ?? entry;
    if (stored.isEditable) {
      // Persist the latest content first (guards: balanced, not yet locked), then lock it into the outbox.
      await _dao.saveDraft(entry);
    }
    final JournalEntry queued = await _dao.markQueued(
      entry.tenantId,
      entry.id,
      post: post,
    );
    await _engine.enqueueCommand(
      tenantId: queued.tenantId,
      entity: glJournalEntity,
      path: queued.outboxPath,
      data: queued.outboxBody,
      entityId: queued.id,
    );
    await syncPending(queued.tenantId);
    final JournalEntry? after = await _dao.entry(queued.tenantId, queued.id);
    return switch (after?.syncState) {
      JournalSyncState.synced => const SubmitOutcome(SubmitStatus.synced),
      JournalSyncState.rejected => SubmitOutcome(
        SubmitStatus.rejected,
        detail: after?.lastError ?? '',
      ),
      _ => const SubmitOutcome(SubmitStatus.queued),
    };
  }

  @override
  Future<SubmitOutcome> reverse(
    JournalEntry original, {
    required String reversalDate,
    required String reason,
  }) async {
    final JournalEntry storno = original.reversal(
      newId: _uuid.v7(),
      reversalDate: reversalDate,
      reason: reason,
      now: _clock(),
    );
    await _dao.saveDraft(storno);
    return submit(storno);
  }

  @override
  Future<void> discard(String tenantId, String id) =>
      _dao.discard(tenantId, id);

  @override
  Future<void> syncPending(String tenantId) async {
    try {
      await _engine.flush(tenantId);
    } catch (_) {
      // Offline or server trouble: the writes stay queued and the next sync cycle resends them.
    }
    await _settle(tenantId);
  }

  /// Entries whose outbox row is gone were accepted; the ones the server refused for good become editable again.
  Future<void> _settle(String tenantId) async {
    final List<QueueItem> rows = await _engine.queued(
      tenantId,
      glJournalEntity,
    );
    final Map<String, QueueItem> byEntry = <String, QueueItem>{
      for (final QueueItem r in rows) r.entityId: r,
    };
    for (final JournalEntry e in await _dao.entries(tenantId)) {
      if (e.syncState != JournalSyncState.queued) {
        continue;
      }
      final QueueItem? item = byEntry[e.id];
      if (item == null) {
        await _dao.setSyncState(tenantId, e.id, JournalSyncState.synced);
      } else if (item.state == QueueState.rejected ||
          item.state == QueueState.conflict) {
        await _dao.setSyncState(
          tenantId,
          e.id,
          JournalSyncState.rejected,
          error: item.lastError ?? '',
        );
        await _engine.discard(item.uuid);
      }
    }
  }

  // --- Reports ----------------------------------------------------------------------------------------------------

  static String _trialKey(
    String from,
    String to,
    LedgerBook ledger,
    int columns,
  ) => '$from|$to|${ledger.code}|$columns';

  static String _ledgerKey(
    String accountId,
    String from,
    String to,
    LedgerBook ledger,
  ) => '$accountId|$from|$to|${ledger.code}';

  @override
  Future<TrialBalance?> cachedTrialBalance(
    String tenantId, {
    required String from,
    required String to,
    required LedgerBook ledger,
    required int columns,
  }) async {
    final Map<String, dynamic>? data = await _dao.snapshot(
      tenantId,
      trialBalanceKind,
      _trialKey(from, to, ledger, columns),
    );
    return data == null
        ? null
        : TrialBalance.fromJson(data, columns: columns, ledger: ledger);
  }

  @override
  Future<TrialBalance> refreshTrialBalance(
    String tenantId, {
    required String from,
    required String to,
    required LedgerBook ledger,
    required int columns,
  }) async {
    final Response<dynamic> res = await _guard(
      () => _dio.get<dynamic>(
        '$_base/reports/trial-balance',
        queryParameters: <String, dynamic>{
          'from': from,
          'to': to,
          'ledger': ledger.code,
          'columns': columns,
        },
      ),
    );
    final Map<String, dynamic> data = _map(_map(res.data)['data']);
    await _dao.saveSnapshot(
      tenantId,
      trialBalanceKind,
      _trialKey(from, to, ledger, columns),
      data,
    );
    return TrialBalance.fromJson(data, columns: columns, ledger: ledger);
  }

  @override
  Future<AccountLedger?> cachedAccountLedger(
    String tenantId, {
    required String accountId,
    required String from,
    required String to,
    required LedgerBook ledger,
  }) async {
    final Map<String, dynamic>? data = await _dao.snapshot(
      tenantId,
      accountLedgerKind,
      _ledgerKey(accountId, from, to, ledger),
    );
    return data == null
        ? null
        : AccountLedger.fromJson(data, accountId: accountId, ledger: ledger);
  }

  @override
  Future<AccountLedger> refreshAccountLedger(
    String tenantId, {
    required String accountId,
    required String from,
    required String to,
    required LedgerBook ledger,
  }) async {
    final Response<dynamic> res = await _guard(
      () => _dio.get<dynamic>(
        '$_base/reports/account-ledger',
        queryParameters: <String, dynamic>{
          'account_id': accountId,
          'from': from,
          'to': to,
          'ledger': ledger.code,
          'page': 1,
          'per_page': 500,
        },
      ),
    );
    final Map<String, dynamic> data = _map(_map(res.data)['data']);
    await _dao.saveSnapshot(
      tenantId,
      accountLedgerKind,
      _ledgerKey(accountId, from, to, ledger),
      data,
    );
    return AccountLedger.fromJson(data, accountId: accountId, ledger: ledger);
  }

  // --- Transport helpers ------------------------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> _pages(
    String path,
    Map<String, dynamic> query, {
    required int perPage,
    int maxPages = 20,
  }) async {
    final List<Map<String, dynamic>> out = <Map<String, dynamic>>[];
    int page = 1;
    int last = 1;
    do {
      final Response<dynamic> res = await _guard(
        () => _dio.get<dynamic>(
          path,
          queryParameters: <String, dynamic>{
            ...query,
            'page': page,
            'per_page': perPage,
          },
        ),
      );
      final Map<String, dynamic> body = _map(res.data);
      for (final dynamic raw in _list(body['data'])) {
        if (raw is Map) {
          out.add(Map<String, dynamic>.from(raw));
        }
      }
      final Object? meta = body['meta'];
      last = meta is Map && meta['last_page'] is int
          ? meta['last_page'] as int
          : 1;
      page++;
    } while (page <= last && page <= maxPages);
    return out;
  }

  Future<Response<dynamic>> _guard(
    Future<Response<dynamic>> Function() call,
  ) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw mapGlError(e);
    }
  }

  static Map<String, dynamic> _map(Object? v) =>
      v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

  static List<dynamic> _list(Object? v) => v is List ? v : const <dynamic>[];
}
