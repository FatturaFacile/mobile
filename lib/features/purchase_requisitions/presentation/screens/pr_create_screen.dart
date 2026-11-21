import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../design/ff_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../wms/ui/scan_field.dart' show CameraScanner;
import '../../domain/entities/budget_check.dart';
import '../../domain/entities/pr_reference_models.dart';
import '../../domain/entities/purchase_requisition.dart';
import '../providers/pr_form_controller.dart';
import '../providers/pr_providers.dart';
import '../widgets/pr_budget_banner.dart';
import '../widgets/pr_labels.dart';
import '../widgets/pr_line_item_sheet.dart';

/// Quick mobile Purchase Requisition creation / draft editing screen.
class PrCreateScreen extends ConsumerStatefulWidget {
  const PrCreateScreen({
    required this.tenantId,
    required this.userId,
    required this.userName,
    this.defaultCurrency = 'CHF',
    this.existing,
    this.cameraScanner,
    super.key,
  });

  final String tenantId;
  final String userId;
  final String userName;
  final String defaultCurrency;
  final PurchaseRequisition? existing;
  final CameraScanner? cameraScanner;

  @override
  ConsumerState<PrCreateScreen> createState() => _PrCreateScreenState();
}

class _PrCreateScreenState extends ConsumerState<PrCreateScreen> {
  final TextEditingController _justificationController =
      TextEditingController();
  late final PrFormArgs _args;
  String? _validationBanner;

  @override
  void initState() {
    super.initState();
    _args = PrFormArgs(
      tenantId: widget.tenantId,
      userId: widget.userId,
      userName: widget.userName,
      defaultCurrency: widget.defaultCurrency,
      existing: widget.existing,
    );
    _justificationController.text = widget.existing?.justification ?? '';
  }

  @override
  void dispose() {
    _justificationController.dispose();
    super.dispose();
  }

  Future<void> _pickDeliveryDate(PrFormState state) async {
    final DateTime now = DateTime.now();
    final DateTime initial =
        state.requestedDeliveryDate ?? now.add(const Duration(days: 7));
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null && mounted) {
      ref
          .read(prFormControllerProvider(_args).notifier)
          .setDeliveryDate(picked);
    }
  }

  Future<void> _openLineSheet({
    PrItemType initialType = PrItemType.catalogItem,
    PurchaseRequisitionLine? existingLine,
    int? editIndex,
  }) async {
    final PrFormController controller = ref.read(
      prFormControllerProvider(_args).notifier,
    );
    final PrFormState current = ref.read(prFormControllerProvider(_args));

    final PurchaseRequisitionLine? result = await PrLineItemSheet.show(
      context,
      currency: current.currency,
      onSearchCatalog: controller.searchCatalog,
      onLookupBarcode: controller.lookupBarcode,
      cameraScanner: widget.cameraScanner,
      initialType: initialType,
      existingLine: existingLine,
    );
    if (result == null || !mounted) {
      return;
    }
    setState(() => _validationBanner = null);
    if (editIndex != null) {
      await controller.updateLine(editIndex, result);
    } else {
      await controller.addLine(result);
    }
  }

  Future<void> _scanBarcodeAction() async {
    if (widget.cameraScanner == null) {
      await _openLineSheet(initialType: PrItemType.catalogItem);
      return;
    }
    final String? code = await widget.cameraScanner!(context);
    if (code == null || code.trim().isEmpty || !mounted) {
      return;
    }
    final CatalogItemOption? matched = await ref
        .read(prFormControllerProvider(_args).notifier)
        .scanAndAddBarcode(code);
    if (!mounted) {
      return;
    }
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    if (matched == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.prBarcodeNotFound(code))),
      );
    } else {
      setState(() => _validationBanner = null);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.prBarcodeMatched(matched.name))),
      );
    }
  }

  Future<void> _saveDraft() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final PrFormState current = ref.read(prFormControllerProvider(_args));
    if (current.costCenterId.isEmpty) {
      setState(() => _validationBanner = l10n.prCostCenterRequired);
      return;
    }
    setState(() => _validationBanner = null);

    final result = await ref
        .read(prFormControllerProvider(_args).notifier)
        .saveDraftOffline();
    if (!mounted) {
      return;
    }
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    result.match(
      (failure) => messenger.showSnackBar(
        SnackBar(
          content: Text(
            failure.message.isNotEmpty ? failure.message : l10n.prGenericError,
          ),
        ),
      ),
      (_) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.prDraftSavedOffline)),
        );
        Navigator.of(context).maybePop(true);
      },
    );
  }

  Future<void> _submit({bool acknowledgeBudgetWarning = false}) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final PrFormState current = ref.read(prFormControllerProvider(_args));
    if (current.costCenterId.isEmpty) {
      setState(() => _validationBanner = l10n.prCostCenterRequired);
      return;
    }
    if (current.justification.trim().isEmpty) {
      setState(() => _validationBanner = l10n.prJustificationRequired);
      return;
    }
    if (current.lines.isEmpty) {
      setState(() => _validationBanner = l10n.prLinesRequired);
      return;
    }
    setState(() => _validationBanner = null);

    final PrSubmitOutcome outcome = await ref
        .read(prFormControllerProvider(_args).notifier)
        .submit(acknowledgeBudgetWarning: acknowledgeBudgetWarning);
    if (!mounted) {
      return;
    }

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    switch (outcome.kind) {
      case PrSubmitOutcomeKind.submittedOnline:
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.prSubmittedSuccess)),
        );
        Navigator.of(context).maybePop(true);
      case PrSubmitOutcomeKind.queuedOffline:
        messenger.showSnackBar(SnackBar(content: Text(l10n.prQueuedForSync)));
        Navigator.of(context).maybePop(true);
      case PrSubmitOutcomeKind.budgetWarningConfirmationNeeded:
        final bool proceed = await _showBudgetWarningDialog(
          outcome.budgetCheck,
        );
        if (proceed && mounted) {
          await _submit(acknowledgeBudgetWarning: true);
        }
      case PrSubmitOutcomeKind.budgetHardBlock:
        final String msg = outcome.message?.isNotEmpty == true
            ? outcome.message!
            : l10n.prBudgetHardBlockSubmitBlocked;
        setState(() => _validationBanner = msg);
        messenger.showSnackBar(SnackBar(content: Text(msg)));
      case PrSubmitOutcomeKind.validationError:
        setState(
          () => _validationBanner = _localizedValidationError(
            l10n,
            outcome.validationFields,
          ),
        );
      case PrSubmitOutcomeKind.failure:
        final String msg = outcome.message?.isNotEmpty == true
            ? outcome.message!
            : l10n.prGenericError;
        messenger.showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<bool> _showBudgetWarningDialog(BudgetCheckResult? check) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        key: const Key('pr-budget-warning-dialog'),
        title: Text(l10n.prBudgetWarningDialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(l10n.prBudgetWarningDialogBody),
            if (check != null && check.message.trim().isNotEmpty) ...<Widget>[
              const SizedBox(height: FfSpace.space2),
              Text(check.message),
            ],
          ],
        ),
        actions: <Widget>[
          TextButton(
            key: const Key('pr-budget-warning-cancel'),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.prCancelAction),
          ),
          FilledButton(
            key: const Key('pr-budget-warning-proceed'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.prBudgetWarningProceed),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  String _localizedValidationError(
    AppLocalizations l10n,
    Map<String, List<String>> fields,
  ) {
    if (fields.containsKey('cost_center_id')) {
      return l10n.prCostCenterRequired;
    }
    if (fields.containsKey('justification')) {
      return l10n.prJustificationRequired;
    }
    if (fields.containsKey('lines')) {
      return l10n.prLinesRequired;
    }
    return l10n.prGenericError;
  }

  @override
  Widget build(BuildContext context) {
    final FfColors colors =
        Theme.of(context).extension<FfColors>() ?? FfColors.light;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final PrFormState state = ref.watch(prFormControllerProvider(_args));
    final PrFormController controller = ref.read(
      prFormControllerProvider(_args).notifier,
    );
    final bool isOnline = ref.watch(prIsOnlineProvider);

    final List<CostCenterOption> costCenters =
        ref.watch(prCostCentersProvider(widget.tenantId)).value ??
        const <CostCenterOption>[];
    final List<CostCenterOption> resolvedCostCenters = <CostCenterOption>[
      ...costCenters,
      if (state.costCenterId.isNotEmpty &&
          !costCenters.any((CostCenterOption c) => c.id == state.costCenterId))
        CostCenterOption(
          id: state.costCenterId,
          code: state.costCenterCode,
          name: state.costCenterName,
          currency: state.currency.wireValue,
        ),
    ];

    final List<ProjectOption> projects =
        ref.watch(prProjectsProvider(widget.tenantId)).value ??
        const <ProjectOption>[];
    final List<ProjectOption> resolvedProjects = <ProjectOption>[
      ...projects,
      if (state.projectId != null &&
          state.projectId!.isNotEmpty &&
          !projects.any((ProjectOption p) => p.id == state.projectId))
        ProjectOption(
          id: state.projectId!,
          code: state.projectCode ?? '',
          name: state.projectName ?? state.projectId!,
        ),
    ];

    final bool submitBlocked = isOnline && state.isBudgetBlocked;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existing == null ? l10n.prCreateTitle : l10n.prEditTitle,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(FfSpace.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (!isOnline) ...<Widget>[
              Container(
                key: const Key('pr-create-offline-banner'),
                padding: const EdgeInsets.all(FfSpace.space3),
                decoration: BoxDecoration(
                  color: colors.infoBg,
                  borderRadius: BorderRadius.circular(FfRadius.md),
                ),
                child: Row(
                  children: <Widget>[
                    Icon(
                      Icons.cloud_off_outlined,
                      color: colors.info,
                      size: FfFont.lg,
                    ),
                    const SizedBox(width: FfSpace.space2),
                    Expanded(
                      child: Text(
                        l10n.prOfflineBanner,
                        style: TextStyle(
                          color: colors.info,
                          fontSize: FfFont.xs,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: FfSpace.space3),
            ],
            if (_validationBanner != null) ...<Widget>[
              Container(
                key: const Key('pr-form-validation-banner'),
                padding: const EdgeInsets.all(FfSpace.space3),
                decoration: BoxDecoration(
                  color: colors.dangerBg,
                  borderRadius: BorderRadius.circular(FfRadius.md),
                  border: Border.all(
                    color: colors.danger.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  _validationBanner!,
                  style: TextStyle(
                    color: colors.danger,
                    fontSize: FfFont.sm,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: FfSpace.space3),
            ],
            DropdownButtonFormField<String>(
              key: const Key('pr-cost-center-picker'),
              initialValue:
                  resolvedCostCenters.any(
                    (CostCenterOption c) => c.id == state.costCenterId,
                  )
                  ? state.costCenterId
                  : null,
              decoration: InputDecoration(
                labelText: l10n.prCostCenterLabel,
                border: const OutlineInputBorder(),
              ),
              items: <DropdownMenuItem<String>>[
                for (final CostCenterOption cc in resolvedCostCenters)
                  DropdownMenuItem<String>(
                    value: cc.id,
                    child: Text(
                      cc.displayLabel,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (String? id) {
                if (id == null) {
                  return;
                }
                final CostCenterOption selected = resolvedCostCenters
                    .firstWhere((CostCenterOption c) => c.id == id);
                setState(() => _validationBanner = null);
                controller.selectCostCenter(selected);
              },
            ),
            const SizedBox(height: FfSpace.space3),
            DropdownButtonFormField<String>(
              key: const Key('pr-project-picker'),
              initialValue:
                  (state.projectId != null &&
                      resolvedProjects.any(
                        (ProjectOption p) => p.id == state.projectId,
                      ))
                  ? state.projectId
                  : '',
              decoration: InputDecoration(
                labelText: l10n.prProjectLabel,
                border: const OutlineInputBorder(),
              ),
              items: <DropdownMenuItem<String>>[
                DropdownMenuItem<String>(
                  value: '',
                  child: Text(l10n.prProjectNone),
                ),
                for (final ProjectOption project in resolvedProjects)
                  DropdownMenuItem<String>(
                    value: project.id,
                    child: Text(
                      project.displayLabel,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (String? id) {
                if (id == null || id.isEmpty) {
                  controller.selectProject(null);
                  return;
                }
                final ProjectOption selected = resolvedProjects.firstWhere(
                  (ProjectOption p) => p.id == id,
                );
                controller.selectProject(selected);
              },
            ),
            const SizedBox(height: FfSpace.space3),
            Text(
              l10n.prUrgencyLabel,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: FfFont.xs,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: FfSpace.space1),
            Wrap(
              spacing: FfSpace.space2,
              runSpacing: FfSpace.space1,
              children: <Widget>[
                for (final PrUrgency urgency in PrUrgency.values)
                  ChoiceChip(
                    key: Key('pr-urgency-${urgency.wireValue}'),
                    label: Text(PrLabels.urgency(l10n, urgency)),
                    selected: state.urgency == urgency,
                    onSelected: (_) => controller.setUrgency(urgency),
                  ),
              ],
            ),
            const SizedBox(height: FfSpace.space3),
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        l10n.prCurrencyLabel,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: FfFont.xs,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: FfSpace.space1),
                      SegmentedButton<PrCurrency>(
                        key: const Key('pr-currency-segment'),
                        segments: <ButtonSegment<PrCurrency>>[
                          ButtonSegment<PrCurrency>(
                            value: PrCurrency.chf,
                            label: Text(PrCurrency.chf.wireValue),
                          ),
                          ButtonSegment<PrCurrency>(
                            value: PrCurrency.eur,
                            label: Text(PrCurrency.eur.wireValue),
                          ),
                        ],
                        selected: <PrCurrency>{state.currency},
                        onSelectionChanged: (Set<PrCurrency> s) =>
                            controller.setCurrency(s.first),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: FfSpace.space3),
                Expanded(
                  child: InkWell(
                    key: const Key('pr-delivery-date-picker'),
                    onTap: () => _pickDeliveryDate(state),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: l10n.prDeliveryDateLabel,
                        border: const OutlineInputBorder(),
                        suffixIcon: const Icon(Icons.event_outlined),
                      ),
                      child: Text(
                        state.requestedDeliveryDate != null
                            ? PrLabels.formatDate(
                                context,
                                state.requestedDeliveryDate!,
                              )
                            : l10n.prDeliveryDateHint,
                        style: TextStyle(
                          color: state.requestedDeliveryDate != null
                              ? colors.text
                              : colors.textMuted,
                          fontSize: FfFont.sm,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: FfSpace.space3),
            TextField(
              key: const Key('pr-justification-input'),
              controller: _justificationController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l10n.prJustificationLabel,
                hintText: l10n.prJustificationHint,
                border: const OutlineInputBorder(),
              ),
              onChanged: (String value) {
                setState(() => _validationBanner = null);
                controller.setJustification(value);
              },
            ),
            const SizedBox(height: FfSpace.space3),
            PrBudgetBanner(
              isOnline: isOnline,
              budgetCheck: state.budgetCheck,
              isLoading: state.isCheckingBudget,
              currency: state.currency,
            ),
            const SizedBox(height: FfSpace.space4),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    l10n.prLinesSectionTitle,
                    style: TextStyle(
                      color: colors.text,
                      fontSize: FfFont.md,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  PrLabels.formatAmount(
                    context,
                    state.totalAmount,
                    state.currency,
                  ),
                  key: const Key('pr-form-total-amount'),
                  style: TextStyle(
                    color: colors.primary,
                    fontSize: FfFont.md,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: FfSpace.space2),
            Wrap(
              spacing: FfSpace.space2,
              runSpacing: FfSpace.space2,
              children: <Widget>[
                OutlinedButton.icon(
                  key: const Key('pr-add-line-button'),
                  icon: const Icon(Icons.add),
                  onPressed: () =>
                      _openLineSheet(initialType: PrItemType.catalogItem),
                  label: Text(l10n.prAddLineAction),
                ),
                OutlinedButton.icon(
                  key: const Key('pr-scan-barcode-button'),
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: _scanBarcodeAction,
                  label: Text(l10n.prScanBarcodeAction),
                ),
              ],
            ),
            const SizedBox(height: FfSpace.space2),
            if (state.lines.isEmpty)
              Card(
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(FfRadius.lg),
                  side: BorderSide(color: colors.borderSubtle),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(FfSpace.space4),
                  child: Center(
                    child: Text(
                      l10n.prLinesEmpty,
                      key: const Key('pr-form-lines-empty'),
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: FfFont.sm,
                      ),
                    ),
                  ),
                ),
              )
            else
              for (int i = 0; i < state.lines.length; i++) ...<Widget>[
                Card(
                  key: Key('pr-form-line-${state.lines[i].localId}'),
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(FfRadius.lg),
                    side: BorderSide(color: colors.border),
                  ),
                  child: ListTile(
                    onTap: () => _openLineSheet(
                      initialType: state.lines[i].itemType,
                      existingLine: state.lines[i],
                      editIndex: i,
                    ),
                    title: Text(
                      state.lines[i].description,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${state.lines[i].quantity} ${state.lines[i].uom} × '
                      '${PrLabels.formatAmount(context, state.lines[i].unitPrice, state.currency)}',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: FfFont.xs,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          PrLabels.formatAmount(
                            context,
                            state.lines[i].lineTotal,
                            state.currency,
                          ),
                          style: TextStyle(
                            color: colors.text,
                            fontWeight: FontWeight.w600,
                            fontSize: FfFont.sm,
                          ),
                        ),
                        IconButton(
                          key: Key('pr-remove-line-${state.lines[i].localId}'),
                          icon: Icon(
                            Icons.delete_outline,
                            color: colors.danger,
                          ),
                          onPressed: () => controller.removeLine(i),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: FfSpace.space2),
              ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(FfSpace.space3),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(top: BorderSide(color: colors.border)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (submitBlocked)
                Padding(
                  padding: const EdgeInsets.only(bottom: FfSpace.space2),
                  child: Text(
                    l10n.prBudgetHardBlockSubmitBlocked,
                    key: const Key('pr-hard-block-submit-note'),
                    style: TextStyle(
                      color: colors.danger,
                      fontSize: FfFont.xs,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      key: const Key('pr-save-draft-button'),
                      onPressed: state.isSubmitting ? null : _saveDraft,
                      child: Text(l10n.prSaveDraftOffline),
                    ),
                  ),
                  const SizedBox(width: FfSpace.space2),
                  Expanded(
                    child: FilledButton(
                      key: const Key('pr-submit-button'),
                      onPressed: (state.isSubmitting || submitBlocked)
                          ? null
                          : _submit,
                      child: state.isSubmitting
                          ? SizedBox(
                              width: FfSpace.space4,
                              height: FfSpace.space4,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colors.onPrimary,
                              ),
                            )
                          : Text(l10n.prSubmitForApproval),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
