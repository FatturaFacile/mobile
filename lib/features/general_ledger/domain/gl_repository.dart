import 'package:flutter/foundation.dart';

import 'gl_models.dart';

/// Why a call of the general ledger API failed; the UI maps it to a localized message.
enum GlErrorKind { forbidden, notFound, conflict, invalid, offline, unknown }

class GlException implements Exception {
  const GlException(this.kind, {this.detail = ''});

  final GlErrorKind kind;

  /// `detail` of the RFC 7807 problem.
  final String detail;

  @override
  String toString() => 'GlException($kind, $detail)';
}

/// What happened to a journal handed to the outbox.
enum SubmitStatus {
  /// The server accepted it.
  synced,

  /// Stored in the outbox; it is sent as soon as the device is online.
  queued,

  /// The server refused it for good; [SubmitOutcome.detail] says why and the entry is editable again.
  rejected,
}

@immutable
class SubmitOutcome {
  const SubmitOutcome(this.status, {this.detail = ''});

  final SubmitStatus status;
  final String detail;
}

abstract class GlRepository {
  /// Live journals of the tenant: local drafts, queued writes and the server copies.
  Stream<List<JournalEntry>> watchJournals(String tenantId);

  /// Reads the journals of the API into the local store; throws [GlException] when it cannot.
  Future<void> refreshJournals(String tenantId);

  Future<List<GlAccount>> cachedAccounts(String tenantId);
  Future<List<GlAccount>> refreshAccounts(String tenantId);

  Future<List<AccountingTemplate>> cachedTemplates(String tenantId);
  Future<List<AccountingTemplate>> refreshTemplates(String tenantId);

  /// Stores a local draft; throws [UnbalancedJournalException] or [ImmutableJournalException].
  Future<void> saveDraft(JournalEntry entry);

  /// Saves (when still a draft) and queues the entry, then tries to send the outbox. Throws
  /// [UnbalancedJournalException] when the entry does not balance.
  Future<SubmitOutcome> submit(JournalEntry entry, {bool post = true});

  /// Creates the storno of a synced, posted journal (a draft with Dare and Avere swapped, pointing at the original
  /// with the [reason]) and queues it.
  Future<SubmitOutcome> reverse(
    JournalEntry original, {
    required String reversalDate,
    required String reason,
  });

  /// Removes a local draft or refused entry.
  Future<void> discard(String tenantId, String id);

  /// Sends the outbox and settles the entries that were queued; never throws.
  Future<void> syncPending(String tenantId);

  Future<TrialBalance?> cachedTrialBalance(
    String tenantId, {
    required String from,
    required String to,
    required LedgerBook ledger,
    required int columns,
  });

  Future<TrialBalance> refreshTrialBalance(
    String tenantId, {
    required String from,
    required String to,
    required LedgerBook ledger,
    required int columns,
  });

  Future<AccountLedger?> cachedAccountLedger(
    String tenantId, {
    required String accountId,
    required String from,
    required String to,
    required LedgerBook ledger,
  });

  Future<AccountLedger> refreshAccountLedger(
    String tenantId, {
    required String accountId,
    required String from,
    required String to,
    required LedgerBook ledger,
  });
}
