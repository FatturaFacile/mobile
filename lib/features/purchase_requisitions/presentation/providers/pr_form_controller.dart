import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/approval_models.dart';
import '../../domain/entities/budget_check.dart';
import '../../domain/entities/pr_reference_models.dart';
import '../../domain/entities/purchase_requisition.dart';
import 'pr_providers.dart';

/// Immutable family key for initializing [PrFormController].
class PrFormArgs {
  const PrFormArgs({
    required this.tenantId,
    required this.userId,
    required this.userName,
    this.defaultCurrency = 'CHF',
    this.existing,
  });

  final String tenantId;
  final String userId;
  final String userName;
  final String defaultCurrency;
  final PurchaseRequisition? existing;

  @override
  bool operator ==(Object other) {
    return other is PrFormArgs &&
        other.tenantId == tenantId &&
        other.userId == userId &&
        other.defaultCurrency == defaultCurrency &&
        other.existing?.localId == existing?.localId;
  }

  @override
  int get hashCode =>
      Object.hash(tenantId, userId, defaultCurrency, existing?.localId);
}

/// Outcome returned by [PrFormController.submit] for clear UI handling.
enum PrSubmitOutcomeKind {
  submittedOnline,
  queuedOffline,
  budgetWarningConfirmationNeeded,
  budgetHardBlock,
  validationError,
  failure,
}

/// Result of attempting to submit a Purchase Requisition from the form screen.
class PrSubmitOutcome {
  const PrSubmitOutcome({
    required this.kind,
    this.requisition,
    this.budgetCheck,
    this.message,
    this.validationFields = const <String, List<String>>{},
  });

  final PrSubmitOutcomeKind kind;
  final PurchaseRequisition? requisition;
  final BudgetCheckResult? budgetCheck;
  final String? message;
  final Map<String, List<String>> validationFields;
}

/// Editable state of the Quick Mobile PR Creation / Edit screen.
class PrFormState {
  const PrFormState({
    required this.localId,
    required this.costCenterId,
    required this.costCenterCode,
    required this.costCenterName,
    required this.urgency,
    required this.currency,
    required this.justification,
    required this.lines,
    required this.createdAt,
    this.remoteId,
    this.requisitionNumber,
    this.projectId,
    this.projectCode,
    this.projectName,
    this.requestedDeliveryDate,
    this.budgetCheck,
    this.isCheckingBudget = false,
    this.isSubmitting = false,
    this.errorMessage,
  });

  final String localId;
  final String? remoteId;
  final String? requisitionNumber;
  final String costCenterId;
  final String costCenterCode;
  final String costCenterName;
  final String? projectId;
  final String? projectCode;
  final String? projectName;
  final PrUrgency urgency;
  final PrCurrency currency;
  final DateTime? requestedDeliveryDate;
  final String justification;
  final List<PurchaseRequisitionLine> lines;
  final BudgetCheckResult? budgetCheck;
  final bool isCheckingBudget;
  final bool isSubmitting;
  final String? errorMessage;
  final DateTime createdAt;

  /// Sum of line totals.
  double get totalAmount => lines.fold<double>(
    0,
    (double sum, PurchaseRequisitionLine l) => sum + l.lineTotal,
  );

  /// Whether live budget check returned a Hard-Block.
  bool get isBudgetBlocked =>
      budgetCheck?.status == BudgetCheckStatus.hardBlock;

  /// Returns a modified copy of [PrFormState].
  PrFormState copyWith({
    String? costCenterId,
    String? costCenterCode,
    String? costCenterName,
    String? projectId,
    String? projectCode,
    String? projectName,
    bool clearProject = false,
    PrUrgency? urgency,
    PrCurrency? currency,
    DateTime? requestedDeliveryDate,
    bool clearDeliveryDate = false,
    String? justification,
    List<PurchaseRequisitionLine>? lines,
    BudgetCheckResult? budgetCheck,
    bool clearBudgetCheck = false,
    bool? isCheckingBudget,
    bool? isSubmitting,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return PrFormState(
      localId: localId,
      remoteId: remoteId,
      requisitionNumber: requisitionNumber,
      costCenterId: costCenterId ?? this.costCenterId,
      costCenterCode: costCenterCode ?? this.costCenterCode,
      costCenterName: costCenterName ?? this.costCenterName,
      projectId: clearProject ? null : (projectId ?? this.projectId),
      projectCode: clearProject ? null : (projectCode ?? this.projectCode),
      projectName: clearProject ? null : (projectName ?? this.projectName),
      urgency: urgency ?? this.urgency,
      currency: currency ?? this.currency,
      requestedDeliveryDate: clearDeliveryDate
          ? null
          : (requestedDeliveryDate ?? this.requestedDeliveryDate),
      justification: justification ?? this.justification,
      lines: lines ?? this.lines,
      budgetCheck: clearBudgetCheck ? null : (budgetCheck ?? this.budgetCheck),
      isCheckingBudget: isCheckingBudget ?? this.isCheckingBudget,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      createdAt: createdAt,
    );
  }
}

/// Manages form inputs, catalog/barcode additions, live Cost Center budget preview, offline drafts, and submission.
class PrFormController extends Notifier<PrFormState> {
  PrFormController(this.arg);

  final PrFormArgs arg;
  final Uuid _uuid = const Uuid();
  bool _disposed = false;

  @override
  PrFormState build() {
    ref.onDispose(() => _disposed = true);
    final PurchaseRequisition? existing = arg.existing;
    if (existing != null) {
      return PrFormState(
        localId: existing.localId,
        remoteId: existing.remoteId,
        requisitionNumber: existing.requisitionNumber,
        costCenterId: existing.costCenterId,
        costCenterCode: existing.costCenterCode,
        costCenterName: existing.costCenterName,
        projectId: existing.projectId,
        projectCode: existing.projectCode,
        projectName: existing.projectName,
        urgency: existing.urgency,
        currency: existing.currency,
        requestedDeliveryDate: existing.requestedDeliveryDate,
        justification: existing.justification,
        lines: existing.lines,
        budgetCheck: existing.budgetCheck,
        createdAt: existing.createdAt,
      );
    }

    return PrFormState(
      localId: _uuid.v7(),
      costCenterId: '',
      costCenterCode: '',
      costCenterName: '',
      urgency: PrUrgency.normal,
      currency: PrCurrency.fromWire(arg.defaultCurrency),
      justification: '',
      lines: const <PurchaseRequisitionLine>[],
      createdAt: DateTime.now().toUtc(),
    );
  }

  /// Selects the target Cost Center (`Mod 019`) and refreshes live budget availability if online.
  Future<void> selectCostCenter(CostCenterOption cc) async {
    state = state.copyWith(
      costCenterId: cc.id,
      costCenterCode: cc.code,
      costCenterName: cc.name,
      currency: PrCurrency.fromWire(cc.currency),
      clearBudgetCheck: true,
      clearErrorMessage: true,
    );
    await refreshBudgetPreview();
  }

  /// Selects or clears the optional Project (`Domain 09`).
  Future<void> selectProject(ProjectOption? project) async {
    if (project == null) {
      state = state.copyWith(clearProject: true);
    } else {
      state = state.copyWith(
        projectId: project.id,
        projectCode: project.code,
        projectName: project.name,
      );
    }
    await refreshBudgetPreview();
  }

  /// Updates urgency level.
  void setUrgency(PrUrgency urgency) {
    state = state.copyWith(urgency: urgency);
  }

  /// Updates currency (`CHF` / `EUR`) and refreshes budget preview.
  Future<void> setCurrency(PrCurrency currency) async {
    state = state.copyWith(currency: currency, clearBudgetCheck: true);
    await refreshBudgetPreview();
  }

  /// Updates requested delivery date.
  void setDeliveryDate(DateTime? date) {
    if (date == null) {
      state = state.copyWith(clearDeliveryDate: true);
    } else {
      state = state.copyWith(requestedDeliveryDate: date);
    }
  }

  /// Updates economic justification text.
  void setJustification(String justification) {
    state = state.copyWith(
      justification: justification,
      clearErrorMessage: true,
    );
  }

  /// Appends a new line item and refreshes live budget preview.
  Future<void> addLine(PurchaseRequisitionLine line) async {
    final List<PurchaseRequisitionLine> next = <PurchaseRequisitionLine>[
      ...state.lines,
      line.copyWith(lineNumber: state.lines.length + 1),
    ];
    state = state.copyWith(lines: next, clearErrorMessage: true);
    await refreshBudgetPreview();
  }

  /// Updates an existing line item at [index] and refreshes live budget preview.
  Future<void> updateLine(int index, PurchaseRequisitionLine line) async {
    if (index < 0 || index >= state.lines.length) {
      return;
    }
    final List<PurchaseRequisitionLine> next =
        List<PurchaseRequisitionLine>.from(state.lines);
    next[index] = line.copyWith(lineNumber: index + 1);
    state = state.copyWith(lines: next, clearErrorMessage: true);
    await refreshBudgetPreview();
  }

  /// Removes a line item at [index] and renumbers remaining lines.
  Future<void> removeLine(int index) async {
    if (index < 0 || index >= state.lines.length) {
      return;
    }
    final List<PurchaseRequisitionLine> next = <PurchaseRequisitionLine>[];
    for (int i = 0; i < state.lines.length; i++) {
      if (i == index) {
        continue;
      }
      next.add(state.lines[i].copyWith(lineNumber: next.length + 1));
    }
    state = state.copyWith(lines: next);
    await refreshBudgetPreview();
  }

  /// Searches catalog items locally and remotely for the bottom sheet picker.
  Future<List<CatalogItemOption>> searchCatalog(String query) {
    return ref
        .read(prRepositoryProvider)
        .searchCatalogItems(arg.tenantId, query);
  }

  /// Looks up a catalog item by barcode or SKU.
  Future<CatalogItemOption?> lookupBarcode(String code) {
    return ref
        .read(prRepositoryProvider)
        .findCatalogItemByBarcode(arg.tenantId, code);
  }

  /// Scans a barcode or SKU and immediately adds a catalog line item if found.
  Future<CatalogItemOption?> scanAndAddBarcode(String code) async {
    final CatalogItemOption? match = await lookupBarcode(code);
    if (match == null) {
      return null;
    }
    await addLine(
      PurchaseRequisitionLine(
        localId: _uuid.v7(),
        lineNumber: state.lines.length + 1,
        itemType: PrItemType.catalogItem,
        catalogItemId: match.id,
        catalogSku: match.sku,
        description: match.name,
        quantity: 1,
        unitPrice: match.unitPrice,
        uom: match.uom,
      ),
    );
    return match;
  }

  /// Runs real-time Cost Center budget check (`POST /budget-preview`) when online and inputs are ready.
  Future<void> refreshBudgetPreview() async {
    final bool isOnline = ref.read(prIsOnlineProvider);
    if (!isOnline ||
        state.costCenterId.isEmpty ||
        state.lines.isEmpty ||
        state.totalAmount <= 0) {
      if (!_disposed) {
        state = state.copyWith(isCheckingBudget: false, clearBudgetCheck: true);
      }
      return;
    }

    final String checkedCostCenterId = state.costCenterId;
    final double checkedTotal = state.totalAmount;
    state = state.copyWith(isCheckingBudget: true);

    final Either<Failure, BudgetCheckResult> res = await ref
        .read(checkBudgetPreviewUseCaseProvider)
        .call(
          costCenterId: checkedCostCenterId,
          projectId: state.projectId,
          currency: state.currency.wireValue,
          lines: state.lines,
        );

    if (_disposed ||
        state.costCenterId != checkedCostCenterId ||
        state.totalAmount != checkedTotal) {
      return;
    }

    res.match(
      (Failure _) {
        state = state.copyWith(isCheckingBudget: false);
      },
      (BudgetCheckResult result) {
        state = state.copyWith(isCheckingBudget: false, budgetCheck: result);
      },
    );
  }

  /// Saves the current form as an offline-first draft in SQLite (`sync_status = pending_upload` if offline).
  Future<Either<Failure, PurchaseRequisition>> saveDraftOffline() async {
    state = state.copyWith(isSubmitting: true, clearErrorMessage: true);
    final Either<Failure, PurchaseRequisition> result = await ref
        .read(saveDraftPrUseCaseProvider)
        .call(
          _toDomain(status: PrStatus.draft),
          isOnline: ref.read(prIsOnlineProvider),
        );
    if (!_disposed) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: result.fold((Failure f) => f.message, (_) => null),
      );
    }
    return result;
  }

  /// Submits the requisition for approval, returning structured budget/offline/validation outcomes.
  Future<PrSubmitOutcome> submit({
    bool acknowledgeBudgetWarning = false,
  }) async {
    state = state.copyWith(isSubmitting: true, clearErrorMessage: true);
    final bool isOnline = ref.read(prIsOnlineProvider);
    final Either<Failure, PurchaseRequisition> result = await ref
        .read(submitPrUseCaseProvider)
        .call(
          _toDomain(status: arg.existing?.status ?? PrStatus.draft),
          isOnline: isOnline,
          acknowledgeBudgetWarning: acknowledgeBudgetWarning,
        );

    if (_disposed) {
      return const PrSubmitOutcome(kind: PrSubmitOutcomeKind.failure);
    }

    return result.match(
      (Failure failure) {
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: failure.message,
        );
        if (failure is ValidationFailure) {
          return PrSubmitOutcome(
            kind: PrSubmitOutcomeKind.validationError,
            message: failure.message,
            validationFields: failure.fieldErrors,
          );
        }
        return PrSubmitOutcome(
          kind: PrSubmitOutcomeKind.failure,
          message: failure.message,
        );
      },
      (PurchaseRequisition pr) {
        state = state.copyWith(
          isSubmitting: false,
          budgetCheck: pr.budgetCheck ?? state.budgetCheck,
        );
        if (!isOnline || pr.pendingSubmit) {
          return PrSubmitOutcome(
            kind: PrSubmitOutcomeKind.queuedOffline,
            requisition: pr,
          );
        }
        if (pr.status == PrStatus.budgetExceeded ||
            pr.budgetCheck?.status == BudgetCheckStatus.hardBlock) {
          return PrSubmitOutcome(
            kind: PrSubmitOutcomeKind.budgetHardBlock,
            requisition: pr,
            budgetCheck: pr.budgetCheck,
            message: pr.syncError ?? pr.budgetCheck?.message,
          );
        }
        if (pr.status == PrStatus.draft &&
            pr.budgetCheck?.status == BudgetCheckStatus.warning) {
          return PrSubmitOutcome(
            kind: PrSubmitOutcomeKind.budgetWarningConfirmationNeeded,
            requisition: pr,
            budgetCheck: pr.budgetCheck,
          );
        }
        return PrSubmitOutcome(
          kind: PrSubmitOutcomeKind.submittedOnline,
          requisition: pr,
        );
      },
    );
  }

  PurchaseRequisition _toDomain({required PrStatus status}) {
    final PurchaseRequisition? existing = arg.existing;
    return PurchaseRequisition(
      localId: state.localId,
      remoteId: state.remoteId,
      tenantId: arg.tenantId,
      requisitionNumber: state.requisitionNumber,
      requesterId: existing?.requesterId ?? arg.userId,
      requesterName: existing?.requesterName ?? arg.userName,
      costCenterId: state.costCenterId,
      costCenterCode: state.costCenterCode,
      costCenterName: state.costCenterName,
      projectId: state.projectId,
      projectCode: state.projectCode,
      projectName: state.projectName,
      urgency: state.urgency,
      requestedDeliveryDate: state.requestedDeliveryDate,
      justification: state.justification.trim(),
      currency: state.currency,
      totalAmount: state.totalAmount,
      status: status,
      syncStatus: existing?.syncStatus ?? PrSyncStatus.pendingUpload,
      pendingSubmit: existing?.pendingSubmit ?? false,
      lines: state.lines,
      budgetCheck: state.budgetCheck,
      approvalSteps: existing?.approvalSteps ?? const <ApprovalLevelStep>[],
      linkedRdo: existing?.linkedRdo,
      linkedPo: existing?.linkedPo,
      createdAt: state.createdAt,
      updatedAt: DateTime.now().toUtc(),
      serverUpdatedAt: existing?.serverUpdatedAt,
    );
  }
}

/// Provider for [PrFormController], parameterized by [PrFormArgs].
final prFormControllerProvider = NotifierProvider.autoDispose
    .family<PrFormController, PrFormState, PrFormArgs>(PrFormController.new);
