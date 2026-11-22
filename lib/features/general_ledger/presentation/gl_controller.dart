import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../app/providers.dart';
import '../../../app/session_controller.dart';
import '../data/gl_repository_impl.dart';
import '../domain/gl_amount.dart';
import '../domain/gl_models.dart';
import '../domain/gl_repository.dart';

final Provider<GlRepository> glRepositoryProvider = Provider<GlRepository>(
  (Ref ref) => GlRepositoryImpl(
    ref.watch(databaseProvider),
    ref.watch(dioProvider),
    ref.watch(syncEngineProvider),
  ),
);

/// Active tenant of the signed-in session (`null` when signed out). Tests override it.
final Provider<String?> glTenantIdProvider = Provider<String?>((Ref ref) {
  final SessionState? s = ref.watch(sessionProvider).value;
  return s is SignedIn ? s.bootstrap.tenantId : null;
});

String _today() => _day(DateTime.now());

String _day(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// `yyyy-MM-dd` of a date, as the API takes it.
String glDay(DateTime d) => _day(d);

// --- Reference data (accounts and templates) --------------------------------------------------------------------

@immutable
class GlReferenceState {
  const GlReferenceState({
    this.accounts = const <GlAccount>[],
    this.templates = const <AccountingTemplate>[],
    this.loading = false,
    this.error,
  });

  final List<GlAccount> accounts;
  final List<AccountingTemplate> templates;
  final bool loading;
  final GlException? error;

  /// Accounts open to manual posting.
  List<GlAccount> get postable => <GlAccount>[
    for (final GlAccount a in accounts)
      if (a.isActive && a.allowsManualPosting) a,
  ];

  GlAccount? accountById(String id) {
    for (final GlAccount a in accounts) {
      if (a.id == id) {
        return a;
      }
    }
    return null;
  }
}

/// The chart of accounts and the templates: the offline copy first, then the API.
class GlReferenceController extends Notifier<GlReferenceState> {
  late String? _tenantId;

  GlRepository get _repo => ref.read(glRepositoryProvider);

  @override
  GlReferenceState build() {
    _tenantId = ref.watch(glTenantIdProvider);
    return const GlReferenceState();
  }

  /// Never throws; an offline refresh keeps the cached lists.
  Future<void> load() async {
    final String? tenant = _tenantId;
    if (tenant == null) {
      return;
    }
    state = GlReferenceState(
      accounts: await _repo.cachedAccounts(tenant),
      templates: await _repo.cachedTemplates(tenant),
      loading: true,
    );
    try {
      final List<GlAccount> accounts = await _repo.refreshAccounts(tenant);
      final List<AccountingTemplate> templates = await _repo.refreshTemplates(
        tenant,
      );
      state = GlReferenceState(accounts: accounts, templates: templates);
    } on GlException catch (e) {
      state = GlReferenceState(
        accounts: state.accounts,
        templates: state.templates,
        error: e,
      );
    }
  }
}

final NotifierProvider<GlReferenceController, GlReferenceState>
glReferenceProvider = NotifierProvider<GlReferenceController, GlReferenceState>(
  GlReferenceController.new,
);

// --- Prima nota entry --------------------------------------------------------------------------------------------

/// One row of the entry form; amounts are [Amount4].
@immutable
class FormLine {
  const FormLine({
    required this.uid,
    this.accountId = '',
    this.accountCode = '',
    this.accountName = '',
    this.debit = 0,
    this.credit = 0,
    this.description = '',
  });

  final String uid;
  final String accountId;
  final String accountCode;
  final String accountName;
  final Amount4 debit;
  final Amount4 credit;
  final String description;

  FormLine copyWith({
    GlAccount? account,
    Amount4? debit,
    Amount4? credit,
    String? description,
  }) => FormLine(
    uid: uid,
    accountId: account?.id ?? accountId,
    accountCode: account?.code ?? accountCode,
    accountName: account?.name ?? accountName,
    debit: debit ?? this.debit,
    credit: credit ?? this.credit,
    description: description ?? this.description,
  );

  JournalLine toLine() => JournalLine(
    accountId: accountId,
    accountCode: accountCode,
    accountName: accountName,
    debit: debit,
    credit: credit,
    description: description,
  );
}

/// What the last save or post did; the screen shows it once and clears it.
enum GlFormOutcome { none, draftSaved, posted, queued, rejected, failed }

@immutable
class GlFormState {
  const GlFormState({
    required this.entryId,
    required this.postingDate,
    required this.lines,
    this.description = '',
    this.ledger = LedgerBook.statutory,
    this.alsoPostTo = const <LedgerBook>[],
    this.templateId,
    this.busy = false,
    this.outcome = GlFormOutcome.none,
    this.detail = '',
    this.revision = 0,
  });

  final String entryId;
  final String postingDate;
  final String description;
  final LedgerBook ledger;
  final List<LedgerBook> alsoPostTo;
  final List<FormLine> lines;
  final String? templateId;
  final bool busy;
  final GlFormOutcome outcome;
  final String detail;

  /// Bumped when the whole form is replaced (reset, template), so the text fields rebuild with the new values.
  final int revision;

  Amount4 get totalDebit =>
      lines.fold<Amount4>(0, (Amount4 s, FormLine l) => s + l.debit);
  Amount4 get totalCredit =>
      lines.fold<Amount4>(0, (Amount4 s, FormLine l) => s + l.credit);
  Amount4 get difference => totalDebit - totalCredit;

  /// The journal the form describes; its [JournalEntry.problems] decide whether saving and posting are open.
  JournalEntry toEntry(String tenantId) => JournalEntry(
    id: entryId,
    tenantId: tenantId,
    postingDate: postingDate,
    description: description,
    ledger: ledger,
    alsoPostTo: alsoPostTo,
    lines: <JournalLine>[for (final FormLine l in lines) l.toLine()],
    createdAt: DateTime.now().toUtc(),
  );

  GlFormState copyWith({
    String? entryId,
    String? postingDate,
    String? description,
    LedgerBook? ledger,
    List<LedgerBook>? alsoPostTo,
    List<FormLine>? lines,
    Object? templateId = _keep,
    bool? busy,
    GlFormOutcome? outcome,
    String? detail,
    int? revision,
  }) => GlFormState(
    entryId: entryId ?? this.entryId,
    postingDate: postingDate ?? this.postingDate,
    description: description ?? this.description,
    ledger: ledger ?? this.ledger,
    alsoPostTo: alsoPostTo ?? this.alsoPostTo,
    lines: lines ?? this.lines,
    templateId: identical(templateId, _keep)
        ? this.templateId
        : templateId as String?,
    busy: busy ?? this.busy,
    outcome: outcome ?? this.outcome,
    detail: detail ?? this.detail,
    revision: revision ?? this.revision,
  );

  static const Object _keep = Object();
}

const Uuid _uuid = Uuid();

GlFormState _freshForm(int revision) => GlFormState(
  entryId: _uuid.v7(),
  postingDate: _today(),
  lines: <FormLine>[
    FormLine(uid: _uuid.v4()),
    FormLine(uid: _uuid.v4()),
  ],
  revision: revision,
);

/// The prima nota entry: lines with live Dare, Avere and difference. Posting and saving are only possible while the
/// entry balances; when offline the entry is queued (see [GlRepository.submit]).
class GlFormController extends Notifier<GlFormState> {
  late String? _tenantId;

  GlRepository get _repo => ref.read(glRepositoryProvider);

  @override
  GlFormState build() {
    _tenantId = ref.watch(glTenantIdProvider);
    return _freshForm(0);
  }

  /// The journal of the form, or null when signed out.
  JournalEntry? get entry {
    final String? t = _tenantId;
    return t == null ? null : state.toEntry(t);
  }

  /// Empties the form (new entry id).
  void reset() => state = _freshForm(state.revision + 1);

  void setPostingDate(String value) =>
      state = state.copyWith(postingDate: value);

  void setDescription(String value) =>
      state = state.copyWith(description: value);

  void setLedger(LedgerBook book) => state = state.copyWith(
    ledger: book,
    alsoPostTo: <LedgerBook>[
      for (final LedgerBook b in state.alsoPostTo)
        if (b != book) b,
    ],
  );

  void toggleAlsoPostTo(LedgerBook book, bool on) {
    if (book == state.ledger) {
      return;
    }
    final List<LedgerBook> next = <LedgerBook>[
      for (final LedgerBook b in LedgerBook.values)
        if (b != state.ledger &&
            (b == book ? on : state.alsoPostTo.contains(b)))
          b,
    ];
    state = state.copyWith(alsoPostTo: next);
  }

  void addLine() => state = state.copyWith(
    lines: <FormLine>[
      ...state.lines,
      FormLine(uid: _uuid.v4()),
    ],
  );

  void removeLine(String uid) {
    if (state.lines.length <= 1) {
      return;
    }
    state = state.copyWith(
      lines: <FormLine>[
        for (final FormLine l in state.lines)
          if (l.uid != uid) l,
      ],
    );
  }

  void updateLine(
    String uid, {
    GlAccount? account,
    Amount4? debit,
    Amount4? credit,
    String? description,
  }) {
    state = state.copyWith(
      lines: <FormLine>[
        for (final FormLine l in state.lines)
          if (l.uid == uid)
            l.copyWith(
              account: account,
              debit: debit,
              credit: credit,
              description: description,
            )
          else
            l,
      ],
    );
  }

  /// Fills the lines from a template. Returns what is still missing (accounts the user has to choose).
  TemplateHydration applyTemplate(
    AccountingTemplate template, {
    required Amount4 amount,
    required Amount4 taxRate,
    required Map<String, GlAccount> chosen,
    required List<GlAccount> known,
    required String language,
  }) {
    final TemplateHydration h = template.hydrate(
      amount: amount,
      taxRate: taxRate,
      chosen: chosen,
      known: known,
    );
    if (h.lines.isNotEmpty) {
      state = state.copyWith(
        lines: <FormLine>[
          for (final JournalLine l in h.lines)
            FormLine(
              uid: _uuid.v4(),
              accountId: l.accountId,
              accountCode: l.accountCode,
              accountName: l.accountName,
              debit: l.debit,
              credit: l.credit,
              description: l.description,
            ),
        ],
        ledger: template.ledger,
        alsoPostTo: const <LedgerBook>[],
        templateId: template.id,
        description: state.description.trim().isEmpty
            ? template.label(language)
            : state.description,
        revision: state.revision + 1,
      );
    }
    return h;
  }

  void clearOutcome() => state = state.copyWith(outcome: GlFormOutcome.none);

  /// Stores the entry as a local draft; refused (no state change) while it does not balance.
  Future<void> saveDraft() async {
    final JournalEntry? e = entry;
    if (e == null || !e.isPostable || state.busy) {
      return;
    }
    state = state.copyWith(busy: true);
    try {
      await _repo.saveDraft(e);
      state = _freshForm(state.revision + 1)
          .copyWith(outcome: GlFormOutcome.draftSaved);
    } on UnbalancedJournalException {
      state = state.copyWith(busy: false);
    }
  }

  /// Posts the entry: sent right away online, queued offline. Blocked while it does not balance.
  Future<void> post() async {
    final JournalEntry? e = entry;
    if (e == null || !e.isPostable || state.busy) {
      return;
    }
    state = state.copyWith(busy: true);
    try {
      final SubmitOutcome o = await _repo.submit(e);
      state = switch (o.status) {
        SubmitStatus.synced => _freshForm(
          state.revision + 1,
        ).copyWith(outcome: GlFormOutcome.posted),
        SubmitStatus.queued => _freshForm(
          state.revision + 1,
        ).copyWith(outcome: GlFormOutcome.queued),
        // Refused for good: the entry stays in the journal list as editable-rejected; the form is reset.
        SubmitStatus.rejected => _freshForm(
          state.revision + 1,
        ).copyWith(outcome: GlFormOutcome.rejected, detail: o.detail),
      };
    } on UnbalancedJournalException {
      state = state.copyWith(busy: false);
    } on ImmutableJournalException {
      state = state.copyWith(busy: false, outcome: GlFormOutcome.failed);
    }
  }
}

final NotifierProvider<GlFormController, GlFormState> glFormProvider =
    NotifierProvider<GlFormController, GlFormState>(GlFormController.new);

// --- Journal list with storno ------------------------------------------------------------------------------------

/// Live journals of the tenant (local drafts and queued entries included).
final StreamProvider<List<JournalEntry>> glJournalsProvider =
    StreamProvider<List<JournalEntry>>((Ref ref) {
      final String? tenant = ref.watch(glTenantIdProvider);
      if (tenant == null) {
        return const Stream<List<JournalEntry>>.empty();
      }
      return ref.watch(glRepositoryProvider).watchJournals(tenant);
    });

@immutable
class GlJournalsState {
  const GlJournalsState({
    this.loading = false,
    this.fromCache = false,
    this.error,
  });

  final bool loading;

  /// The list shows the offline copy because the last refresh failed.
  final bool fromCache;
  final GlException? error;
}

class GlJournalsController extends Notifier<GlJournalsState> {
  late String? _tenantId;

  GlRepository get _repo => ref.read(glRepositoryProvider);

  @override
  GlJournalsState build() {
    _tenantId = ref.watch(glTenantIdProvider);
    return const GlJournalsState();
  }

  /// Sends the outbox, then reads the journals from the API. Never throws.
  Future<void> refresh() async {
    final String? tenant = _tenantId;
    if (tenant == null) {
      return;
    }
    state = const GlJournalsState(loading: true);
    await _repo.syncPending(tenant);
    try {
      await _repo.refreshJournals(tenant);
      state = const GlJournalsState();
    } on GlException catch (e) {
      state = GlJournalsState(fromCache: true, error: e);
    }
  }

  /// Creates and queues the storno of a posted journal.
  Future<SubmitOutcome?> reverse(
    JournalEntry original, {
    required String reversalDate,
    required String reason,
  }) async {
    try {
      return await _repo.reverse(
        original,
        reversalDate: reversalDate,
        reason: reason,
      );
    } on NotReversibleException {
      return null;
    }
  }

  Future<void> discard(JournalEntry entry) async {
    final String? tenant = _tenantId;
    if (tenant != null) {
      await _repo.discard(tenant, entry.id);
    }
  }
}

final NotifierProvider<GlJournalsController, GlJournalsState>
glJournalsControllerProvider =
    NotifierProvider<GlJournalsController, GlJournalsState>(
      GlJournalsController.new,
    );

// --- Trial balance and mastrino ----------------------------------------------------------------------------------

@immutable
class GlTrialState {
  const GlTrialState({
    required this.from,
    required this.to,
    this.ledger = LedgerBook.statutory,
    this.columns = 4,
    this.data,
    this.loading = false,
    this.fromCache = false,
    this.error,
  });

  final String from;
  final String to;
  final LedgerBook ledger;
  final int columns;
  final TrialBalance? data;
  final bool loading;
  final bool fromCache;
  final GlException? error;

  GlTrialState copyWith({
    String? from,
    String? to,
    LedgerBook? ledger,
    int? columns,
    Object? data = _keep,
    bool? loading,
    bool? fromCache,
    Object? error = _keep,
  }) => GlTrialState(
    from: from ?? this.from,
    to: to ?? this.to,
    ledger: ledger ?? this.ledger,
    columns: columns ?? this.columns,
    data: identical(data, _keep) ? this.data : data as TrialBalance?,
    loading: loading ?? this.loading,
    fromCache: fromCache ?? this.fromCache,
    error: identical(error, _keep) ? this.error : error as GlException?,
  );

  static const Object _keep = Object();
}

/// Trial balance of one period, ledger book and layout; the last answer per filter is readable offline.
class GlTrialController extends Notifier<GlTrialState> {
  late String? _tenantId;

  GlRepository get _repo => ref.read(glRepositoryProvider);

  @override
  GlTrialState build() {
    _tenantId = ref.watch(glTenantIdProvider);
    final DateTime now = DateTime.now();
    return GlTrialState(from: _day(DateTime(now.year)), to: _day(now));
  }

  Future<void> setFilter({
    String? from,
    String? to,
    LedgerBook? ledger,
    int? columns,
  }) {
    state = state.copyWith(
      from: from,
      to: to,
      ledger: ledger,
      columns: columns,
    );
    return load();
  }

  /// Cached answer of the filter first, then the API. Never throws.
  Future<void> load() async {
    final String? tenant = _tenantId;
    if (tenant == null) {
      return;
    }
    final GlTrialState f = state;
    state = f.copyWith(loading: true, error: null);
    final TrialBalance? cached = await _repo.cachedTrialBalance(
      tenant,
      from: f.from,
      to: f.to,
      ledger: f.ledger,
      columns: f.columns,
    );
    state = state.copyWith(data: cached, fromCache: cached != null);
    try {
      final TrialBalance fresh = await _repo.refreshTrialBalance(
        tenant,
        from: f.from,
        to: f.to,
        ledger: f.ledger,
        columns: f.columns,
      );
      // A newer filter change wins over this answer.
      if (state.from == f.from &&
          state.to == f.to &&
          state.ledger == f.ledger &&
          state.columns == f.columns) {
        state = state.copyWith(data: fresh, fromCache: false);
      }
    } on GlException catch (e) {
      state = state.copyWith(error: e);
    }
    state = state.copyWith(loading: false);
  }
}

final NotifierProvider<GlTrialController, GlTrialState> glTrialProvider =
    NotifierProvider<GlTrialController, GlTrialState>(GlTrialController.new);

@immutable
class GlLedgerState {
  const GlLedgerState({
    this.data,
    this.loading = false,
    this.fromCache = false,
    this.error,
  });

  final AccountLedger? data;
  final bool loading;
  final bool fromCache;
  final GlException? error;
}

/// Mastrino of one account for a period and ledger book.
class GlLedgerController extends Notifier<GlLedgerState> {
  GlRepository get _repo => ref.read(glRepositoryProvider);

  @override
  GlLedgerState build() => const GlLedgerState();

  Future<void> load({
    required String accountId,
    required String from,
    required String to,
    required LedgerBook ledger,
  }) async {
    final String? tenant = ref.read(glTenantIdProvider);
    if (tenant == null) {
      return;
    }
    state = const GlLedgerState(loading: true);
    final AccountLedger? cached = await _repo.cachedAccountLedger(
      tenant,
      accountId: accountId,
      from: from,
      to: to,
      ledger: ledger,
    );
    state = GlLedgerState(
      data: cached,
      fromCache: cached != null,
      loading: true,
    );
    try {
      final AccountLedger fresh = await _repo.refreshAccountLedger(
        tenant,
        accountId: accountId,
        from: from,
        to: to,
        ledger: ledger,
      );
      state = GlLedgerState(data: fresh);
    } on GlException catch (e) {
      state = GlLedgerState(data: cached, fromCache: cached != null, error: e);
    }
  }
}

final NotifierProvider<GlLedgerController, GlLedgerState> glLedgerProvider =
    NotifierProvider<GlLedgerController, GlLedgerState>(GlLedgerController.new);
