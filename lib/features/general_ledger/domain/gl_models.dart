import 'package:flutter/foundation.dart';

import 'gl_amount.dart';

/// The three parallel ledger books. [code] is what the API reports and filters accept (`01`, `02`, `03`),
/// [wire] the `ledger_type` of a journal.
enum LedgerBook {
  statutory('01', 'statutory'),
  tax('02', 'tax'),
  ifrs('03', 'ifrs');

  const LedgerBook(this.code, this.wire);

  final String code;
  final String wire;

  /// Reads a book from its code or its name; unknown values fall back to the statutory book.
  static LedgerBook parse(Object? value) {
    for (final LedgerBook b in LedgerBook.values) {
      if (b.code == value || b.wire == value) {
        return b;
      }
    }
    return LedgerBook.statutory;
  }
}

/// Server lifecycle of a journal.
enum JournalStatus {
  draft('draft'),
  pendingApproval('pending_approval'),
  approved('approved'),
  rejected('rejected'),
  posted('posted'),
  reversed('reversed');

  const JournalStatus(this.wire);

  final String wire;

  static JournalStatus parse(Object? value) {
    for (final JournalStatus s in JournalStatus.values) {
      if (s.wire == value) {
        return s;
      }
    }
    return JournalStatus.draft;
  }
}

/// Where a locally held journal stands against the server.
enum JournalSyncState {
  /// Only on this device, still editable.
  localDraft,

  /// Waiting in the outbox; immutable until the server answers.
  queued,

  /// Known to the server; immutable (corrections go through a reversal).
  synced,

  /// The server refused the queued write for good; editable again.
  rejected,
}

/// Why a journal cannot be saved or queued.
enum JournalProblem {
  descriptionMissing,
  tooFewLines,
  lineWithoutAccount,
  lineWithoutAmount,
  lineOnBothSides,
  unbalanced,
}

/// A save or queue was attempted on a journal that is not balanced or incomplete.
class UnbalancedJournalException implements Exception {
  const UnbalancedJournalException(this.problems);

  final List<JournalProblem> problems;

  @override
  String toString() => 'UnbalancedJournalException($problems)';
}

/// An edit was attempted on a queued, synced or posted journal.
class ImmutableJournalException implements Exception {
  const ImmutableJournalException(this.id);

  final String id;

  @override
  String toString() => 'ImmutableJournalException($id)';
}

/// A reversal was asked for a journal the server does not hold as posted.
class NotReversibleException implements Exception {
  const NotReversibleException(this.id);

  final String id;

  @override
  String toString() => 'NotReversibleException($id)';
}

@immutable
class JournalLine {
  const JournalLine({
    required this.accountId,
    this.accountCode = '',
    this.accountName = '',
    this.debit = 0,
    this.credit = 0,
    this.description = '',
  });

  factory JournalLine.fromJson(Map<String, dynamic> json) => JournalLine(
    accountId: '${json['account_id'] ?? ''}',
    accountCode: '${json['account_code'] ?? ''}',
    accountName: '${json['account_name'] ?? ''}',
    debit: amountFromJson(json['debit_amount']),
    credit: amountFromJson(json['credit_amount']),
    description: '${json['description'] ?? ''}',
  );

  final String accountId;
  final String accountCode;
  final String accountName;

  /// Dare, in [Amount4].
  final Amount4 debit;

  /// Avere, in [Amount4].
  final Amount4 credit;
  final String description;

  bool get hasAccount => accountId.isNotEmpty;

  /// A line carries exactly one positive side.
  bool get hasAmount => debit > 0 || credit > 0;
  bool get onBothSides => debit > 0 && credit > 0;

  /// The line with Dare and Avere exchanged (the storno of the line).
  JournalLine swapped() => JournalLine(
    accountId: accountId,
    accountCode: accountCode,
    accountName: accountName,
    debit: credit,
    credit: debit,
    description: description,
  );

  JournalLine copyWith({
    String? accountId,
    String? accountCode,
    String? accountName,
    Amount4? debit,
    Amount4? credit,
    String? description,
  }) => JournalLine(
    accountId: accountId ?? this.accountId,
    accountCode: accountCode ?? this.accountCode,
    accountName: accountName ?? this.accountName,
    debit: debit ?? this.debit,
    credit: credit ?? this.credit,
    description: description ?? this.description,
  );

  Map<String, dynamic> toWire() => <String, dynamic>{
    'account_id': accountId,
    'debit_amount': amountToWire(debit),
    'credit_amount': amountToWire(credit),
    if (description.isNotEmpty) 'description': description,
  };

  @override
  bool operator ==(Object other) =>
      other is JournalLine &&
      other.accountId == accountId &&
      other.debit == debit &&
      other.credit == credit &&
      other.description == description;

  @override
  int get hashCode => Object.hash(accountId, debit, credit, description);
}

/// A journal entry (prima nota). Content edits are only allowed while it is [isEditable]; saving or queuing needs
/// [problems] to be empty, so an unbalanced entry never reaches the database or the outbox.
@immutable
class JournalEntry {
  const JournalEntry({
    required this.id,
    required this.tenantId,
    required this.postingDate,
    required this.description,
    required this.createdAt,
    this.serverId,
    this.ledger = LedgerBook.statutory,
    this.alsoPostTo = const <LedgerBook>[],
    this.status = JournalStatus.draft,
    this.syncState = JournalSyncState.localDraft,
    this.postOnSync = false,
    this.lines = const <JournalLine>[],
    this.entryNumber,
    this.reversesJournalId,
    this.reversalReason,
    this.lastError,
  });

  /// Reads a journal of `GET /general-ledger/journals`; the result is a synced entry.
  factory JournalEntry.fromJson(String tenantId, Map<String, dynamic> json) {
    final Object? rawLines = json['lines'];
    final String id = '${json['id']}';
    return JournalEntry(
      id: id,
      serverId: id,
      tenantId: tenantId,
      postingDate: '${json['posting_date'] ?? ''}',
      description: '${json['description'] ?? ''}',
      ledger: LedgerBook.parse(json['ledger_type']),
      status: JournalStatus.parse(json['status']),
      syncState: JournalSyncState.synced,
      entryNumber: (json['journal_number'] ?? json['entry_number'])?.toString(),
      createdAt:
          DateTime.tryParse('${json['posted_at']}') ?? DateTime.now().toUtc(),
      lines: <JournalLine>[
        if (rawLines is List)
          for (final dynamic l in rawLines)
            if (l is Map) JournalLine.fromJson(Map<String, dynamic>.from(l)),
      ],
    );
  }

  final String id;
  final String tenantId;
  final String? serverId;

  /// `yyyy-MM-dd`.
  final String postingDate;
  final String description;
  final LedgerBook ledger;

  /// Other books the entry is posted to as well (`post_to_ledgers`).
  final List<LedgerBook> alsoPostTo;
  final JournalStatus status;
  final JournalSyncState syncState;

  /// The queued write asks the server to post the entry (otherwise it is stored there as a draft).
  final bool postOnSync;
  final List<JournalLine> lines;
  final String? entryNumber;

  /// Server id of the journal this entry reverses (storno).
  final String? reversesJournalId;
  final String? reversalReason;
  final String? lastError;
  final DateTime createdAt;

  bool get isReversal => reversesJournalId != null;

  Amount4 get totalDebit =>
      lines.fold<Amount4>(0, (Amount4 s, JournalLine l) => s + l.debit);
  Amount4 get totalCredit =>
      lines.fold<Amount4>(0, (Amount4 s, JournalLine l) => s + l.credit);

  /// Dare minus Avere; zero when the entry balances.
  Amount4 get difference => totalDebit - totalCredit;

  /// Everything that stops the entry from being saved or queued; empty means it can go.
  List<JournalProblem> get problems => <JournalProblem>[
    if (description.trim().isEmpty) JournalProblem.descriptionMissing,
    if (lines.length < 2) JournalProblem.tooFewLines,
    if (lines.any((JournalLine l) => !l.hasAccount))
      JournalProblem.lineWithoutAccount,
    if (lines.any((JournalLine l) => !l.hasAmount))
      JournalProblem.lineWithoutAmount,
    if (lines.any((JournalLine l) => l.onBothSides))
      JournalProblem.lineOnBothSides,
    if (difference != 0 || totalDebit == 0) JournalProblem.unbalanced,
  ];

  /// Dare equals Avere and is positive.
  bool get isBalanced => difference == 0 && totalDebit > 0;

  bool get isPostable => problems.isEmpty;

  /// Only a local draft (or one the server refused) can change; queued, synced and posted entries are immutable.
  bool get isEditable =>
      status == JournalStatus.draft &&
      (syncState == JournalSyncState.localDraft ||
          syncState == JournalSyncState.rejected);

  /// Throws [ImmutableJournalException] unless the entry is editable.
  void requireEditable() {
    if (!isEditable) {
      throw ImmutableJournalException(id);
    }
  }

  /// Throws [UnbalancedJournalException] unless the entry can be saved or queued.
  void requireValid() {
    final List<JournalProblem> p = problems;
    if (p.isNotEmpty) {
      throw UnbalancedJournalException(p);
    }
  }

  /// A content edit; throws [ImmutableJournalException] on a locked entry.
  JournalEntry edit({
    String? postingDate,
    String? description,
    LedgerBook? ledger,
    List<LedgerBook>? alsoPostTo,
    List<JournalLine>? lines,
  }) {
    requireEditable();
    return copyWith(
      postingDate: postingDate,
      description: description,
      ledger: ledger,
      alsoPostTo: alsoPostTo,
      lines: lines,
    );
  }

  /// The storno: a new draft with Dare and Avere swapped, dated [reversalDate], pointing at this journal with the
  /// [reason]. Only a journal the server holds as posted can be reversed.
  JournalEntry reversal({
    required String newId,
    required String reversalDate,
    required String reason,
    required DateTime now,
  }) {
    final String? original = serverId;
    if (original == null || status != JournalStatus.posted || isReversal) {
      throw NotReversibleException(id);
    }
    return JournalEntry(
      id: newId,
      tenantId: tenantId,
      postingDate: reversalDate,
      description: description,
      ledger: ledger,
      alsoPostTo: alsoPostTo,
      postOnSync: true,
      lines: <JournalLine>[for (final JournalLine l in lines) l.swapped()],
      reversesJournalId: original,
      reversalReason: reason,
      createdAt: now,
    );
  }

  JournalEntry copyWith({
    String? serverId,
    String? postingDate,
    String? description,
    LedgerBook? ledger,
    List<LedgerBook>? alsoPostTo,
    JournalStatus? status,
    JournalSyncState? syncState,
    bool? postOnSync,
    List<JournalLine>? lines,
    Object? lastError = _keep,
  }) => JournalEntry(
    id: id,
    tenantId: tenantId,
    serverId: serverId ?? this.serverId,
    postingDate: postingDate ?? this.postingDate,
    description: description ?? this.description,
    ledger: ledger ?? this.ledger,
    alsoPostTo: alsoPostTo ?? this.alsoPostTo,
    status: status ?? this.status,
    syncState: syncState ?? this.syncState,
    postOnSync: postOnSync ?? this.postOnSync,
    lines: lines ?? this.lines,
    entryNumber: entryNumber,
    reversesJournalId: reversesJournalId,
    reversalReason: reversalReason,
    lastError: identical(lastError, _keep)
        ? this.lastError
        : lastError as String?,
    createdAt: createdAt,
  );

  static const Object _keep = Object();

  /// Body of `POST /general-ledger/journals`.
  Map<String, dynamic> toCreateBody() => <String, dynamic>{
    'posting_date': postingDate,
    'description': description,
    'ledger_type': ledger.wire,
    if (alsoPostTo.isNotEmpty)
      'post_to_ledgers': <String>[
        for (final LedgerBook b in alsoPostTo) b.code,
      ],
    'status': postOnSync ? JournalStatus.posted.wire : JournalStatus.draft.wire,
    'lines': <Map<String, dynamic>>[
      for (final JournalLine l in lines) l.toWire(),
    ],
  };

  /// Body of `POST /general-ledger/journals/{id}/reverse`.
  Map<String, dynamic> toReverseBody() => <String, dynamic>{
    'reversal_date': postingDate,
    if ((reversalReason ?? '').isNotEmpty) 'reason': reversalReason,
  };

  /// The outbox path of this entry: a storno goes to the reverse endpoint of the original journal.
  String get outboxPath => isReversal
      ? '/general-ledger/journals/$reversesJournalId/reverse'
      : '/general-ledger/journals';

  Map<String, dynamic> get outboxBody =>
      isReversal ? toReverseBody() : toCreateBody();
}

/// An account of the chart of accounts.
@immutable
class GlAccount {
  const GlAccount({
    required this.id,
    required this.code,
    required this.name,
    this.accountType = '',
    this.normalBalance = 'debit',
    this.allowsManualPosting = true,
    this.isActive = true,
  });

  factory GlAccount.fromJson(Map<String, dynamic> json) => GlAccount(
    id: '${json['id']}',
    code: '${json['account_code'] ?? ''}',
    name: '${json['name'] ?? ''}',
    accountType: '${json['account_type'] ?? ''}',
    normalBalance: '${json['normal_balance'] ?? 'debit'}',
    allowsManualPosting: json['allows_manual_posting'] != false,
    isActive: json['is_active'] != false,
  );

  final String id;
  final String code;
  final String name;
  final String accountType;
  final String normalBalance;
  final bool allowsManualPosting;
  final bool isActive;

  String get label => '$code $name'.trim();

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'account_code': code,
    'name': name,
    'account_type': accountType,
    'normal_balance': normalBalance,
    'allows_manual_posting': allowsManualPosting,
    'is_active': isActive,
  };
}

/// One input of an accounting template: `amount`, `rate` (the tax rate) or `account` (an account to choose).
@immutable
class TemplateParameter {
  const TemplateParameter({required this.key, required this.type});

  final String key;
  final String type;
}

/// One line of a template: [account] is `$key` (the user picks it) or a fixed account code; [amount] is `amount`,
/// `tax` or `gross`.
@immutable
class TemplateLine {
  const TemplateLine({
    required this.account,
    required this.side,
    required this.amount,
  });

  final String account;
  final String side;
  final String amount;

  bool get isDebit => side == 'debit';
  bool get usesParameter => account.startsWith(r'$');
  String get accountKey => usesParameter ? account.substring(1) : account;
}

/// The lines a template yields for the inputs, and what is still missing.
@immutable
class TemplateHydration {
  const TemplateHydration({
    required this.lines,
    required this.missingAccountKeys,
  });

  final List<JournalLine> lines;
  final List<String> missingAccountKeys;

  Amount4 get totalDebit =>
      lines.fold<Amount4>(0, (Amount4 s, JournalLine l) => s + l.debit);
  Amount4 get totalCredit =>
      lines.fold<Amount4>(0, (Amount4 s, JournalLine l) => s + l.credit);
  bool get isBalanced =>
      missingAccountKeys.isEmpty &&
      lines.isNotEmpty &&
      totalDebit == totalCredit;
}

/// A parametric causale contabile.
@immutable
class AccountingTemplate {
  const AccountingTemplate({
    required this.id,
    required this.code,
    required this.names,
    this.category = '',
    this.journalType = 'standard',
    this.ledger = LedgerBook.statutory,
    this.parameters = const <TemplateParameter>[],
    this.lines = const <TemplateLine>[],
  });

  factory AccountingTemplate.fromJson(Map<String, dynamic> json) {
    final Object? rawNames = json['names'];
    final Object? rawParams = json['parameters'];
    final Object? rawLines = json['lines'];
    final Map<String, String> names = <String, String>{
      if (rawNames is Map)
        for (final MapEntry<dynamic, dynamic> e in rawNames.entries)
          '${e.key}': '${e.value}',
    };
    if (names.isEmpty && json['name'] != null) {
      names['en'] = '${json['name']}';
    }
    return AccountingTemplate(
      id: '${json['id']}',
      code: '${json['code'] ?? ''}',
      names: names,
      category: '${json['category'] ?? ''}',
      journalType: '${json['journal_type'] ?? 'standard'}',
      ledger: LedgerBook.parse(json['ledger_type']),
      parameters: <TemplateParameter>[
        if (rawParams is List)
          for (final dynamic p in rawParams)
            if (p is Map)
              TemplateParameter(key: '${p['key']}', type: '${p['type']}'),
      ],
      lines: <TemplateLine>[
        if (rawLines is List)
          for (final dynamic l in rawLines)
            if (l is Map)
              TemplateLine(
                account: '${l['account']}',
                side: '${l['side']}',
                amount: '${l['amount'] ?? 'amount'}',
              ),
      ],
    );
  }

  final String id;
  final String code;
  final Map<String, String> names;
  final String category;
  final String journalType;
  final LedgerBook ledger;
  final List<TemplateParameter> parameters;
  final List<TemplateLine> lines;

  /// Name in [language], falling back to English and then the code.
  String label(String language) => names[language] ?? names['en'] ?? code;

  bool get needsRate =>
      parameters.any((TemplateParameter p) => p.type == 'rate');

  /// Keys of the accounts the user has to choose.
  List<String> get accountKeys => <String>[
    for (final TemplateParameter p in parameters)
      if (p.type == 'account') p.key,
  ];

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'code': code,
    'names': names,
    'category': category,
    'journal_type': journalType,
    'ledger_type': ledger.wire,
    'parameters': <Map<String, String>>[
      for (final TemplateParameter p in parameters)
        <String, String>{'key': p.key, 'type': p.type},
    ],
    'lines': <Map<String, String>>[
      for (final TemplateLine l in lines)
        <String, String>{
          'account': l.account,
          'side': l.side,
          'amount': l.amount,
        },
    ],
  };

  /// Offline equivalent of `POST accounting-templates/{id}/preview`: [amount] is the net, [taxRate] a percent (both
  /// [Amount4]); [chosen] maps a parameter key to the picked account; fixed accounts are resolved in [known] by code or id.
  /// Lines whose amount is not positive are left out, as the server does.
  TemplateHydration hydrate({
    required Amount4 amount,
    required Map<String, GlAccount> chosen,
    required List<GlAccount> known,
    Amount4 taxRate = 0,
  }) {
    // Half-up: net x percent / 100, all in ten-thousandths.
    final Amount4 tax = needsRate ? (amount * taxRate + 500000) ~/ 1000000 : 0;
    final Map<String, Amount4> values = <String, Amount4>{
      'amount': amount,
      'tax': tax,
      'gross': amount + tax,
    };
    final List<JournalLine> out = <JournalLine>[];
    final Set<String> missing = <String>{};
    for (final TemplateLine line in lines) {
      final Amount4 value = values[line.amount] ?? 0;
      if (value <= 0) {
        continue;
      }
      GlAccount? account;
      if (line.usesParameter) {
        account = chosen[line.accountKey];
      } else {
        for (final GlAccount a in known) {
          if (a.code == line.account || a.id == line.account) {
            account = a;
            break;
          }
        }
      }
      if (account == null) {
        missing.add(line.accountKey);
        continue;
      }
      out.add(
        JournalLine(
          accountId: account.id,
          accountCode: account.code,
          accountName: account.name,
          debit: line.isDebit ? value : 0,
          credit: line.isDebit ? 0 : value,
        ),
      );
    }
    return TemplateHydration(lines: out, missingAccountKeys: missing.toList());
  }
}

/// A row of the trial balance (bilancio di verifica). The 2-column layout fills [debitBalance] and [creditBalance].
@immutable
class TrialBalanceRow {
  const TrialBalanceRow({
    required this.accountId,
    required this.code,
    required this.name,
    this.accountType = '',
    this.opening = 0,
    this.debit = 0,
    this.credit = 0,
    this.closing = 0,
    this.debitBalance = 0,
    this.creditBalance = 0,
  });

  factory TrialBalanceRow.fromJson(Map<String, dynamic> json) =>
      TrialBalanceRow(
        accountId: '${json['account_id'] ?? ''}',
        code: '${json['account_code'] ?? ''}',
        name: '${json['account_name'] ?? ''}',
        accountType: '${json['account_type'] ?? ''}',
        opening: amountFromJson(json['opening_balance']),
        debit: amountFromJson(json['debit']),
        credit: amountFromJson(json['credit']),
        closing: amountFromJson(json['closing_balance']),
        debitBalance: amountFromJson(json['debit_balance']),
        creditBalance: amountFromJson(json['credit_balance']),
      );

  final String accountId;
  final String code;
  final String name;
  final String accountType;
  final Amount4 opening;
  final Amount4 debit;
  final Amount4 credit;
  final Amount4 closing;
  final Amount4 debitBalance;
  final Amount4 creditBalance;
}

@immutable
class TrialBalance {
  const TrialBalance({
    required this.currency,
    required this.columns,
    required this.ledger,
    required this.rows,
    required this.totals,
    required this.isBalanced,
  });

  factory TrialBalance.fromJson(
    Map<String, dynamic> json, {
    required int columns,
    required LedgerBook ledger,
  }) {
    final Object? rawRows = json['accounts'];
    final Object? rawTotals = json['totals'];
    return TrialBalance(
      currency: '${json['currency'] ?? 'CHF'}',
      columns: columns,
      ledger: ledger,
      rows: <TrialBalanceRow>[
        if (rawRows is List)
          for (final dynamic r in rawRows)
            if (r is Map)
              TrialBalanceRow.fromJson(Map<String, dynamic>.from(r)),
      ],
      totals: <String, Amount4>{
        if (rawTotals is Map)
          for (final MapEntry<dynamic, dynamic> e in rawTotals.entries)
            '${e.key}': amountFromJson(e.value),
      },
      isBalanced: json['is_balanced'] == true,
    );
  }

  final String currency;
  final int columns;
  final LedgerBook ledger;
  final List<TrialBalanceRow> rows;

  /// Totals by the API key (`debit`, `credit`, `opening_balance`, `closing_balance`, `debit_balance`, `credit_balance`).
  final Map<String, Amount4> totals;
  final bool isBalanced;

  Amount4 get totalDebit =>
      totals[columns == 2 ? 'debit_balance' : 'debit'] ?? 0;
  Amount4 get totalCredit =>
      totals[columns == 2 ? 'credit_balance' : 'credit'] ?? 0;
}

@immutable
class AccountLedgerLine {
  const AccountLedgerLine({
    required this.journalEntryId,
    required this.postingDate,
    required this.description,
    required this.debit,
    required this.credit,
    required this.runningBalance,
  });

  factory AccountLedgerLine.fromJson(Map<String, dynamic> json) =>
      AccountLedgerLine(
        journalEntryId: '${json['journal_entry_id'] ?? ''}',
        postingDate: '${json['posting_date'] ?? ''}',
        description: '${json['description'] ?? ''}',
        debit: amountFromJson(json['debit']),
        credit: amountFromJson(json['credit']),
        runningBalance: amountFromJson(json['running_balance']),
      );

  final String journalEntryId;
  final String postingDate;
  final String description;
  final Amount4 debit;
  final Amount4 credit;
  final Amount4 runningBalance;
}

/// The mastrino of one account: opening balance, movements with the running balance, closing balance.
@immutable
class AccountLedger {
  const AccountLedger({
    required this.accountId,
    required this.ledger,
    required this.opening,
    required this.closing,
    required this.lines,
  });

  factory AccountLedger.fromJson(
    Map<String, dynamic> json, {
    required String accountId,
    required LedgerBook ledger,
  }) {
    final Object? rawLines = json['lines'];
    return AccountLedger(
      accountId: accountId,
      ledger: ledger,
      opening: amountFromJson(json['opening_balance']),
      closing: amountFromJson(json['closing_balance']),
      lines: <AccountLedgerLine>[
        if (rawLines is List)
          for (final dynamic l in rawLines)
            if (l is Map)
              AccountLedgerLine.fromJson(Map<String, dynamic>.from(l)),
      ],
    );
  }

  final String accountId;
  final LedgerBook ledger;
  final Amount4 opening;
  final Amount4 closing;
  final List<AccountLedgerLine> lines;
}
