import 'package:material_ui/material_ui.dart';

import '../domain/project_portfolio_models.dart';
import '../domain/project_portfolio_repository.dart';
import '../l10n/project_portfolio_strings.dart';

/// Localized names of the enums and of the refusal reasons, and the number/date formats of the screens.
extension ProjectPortfolioLabels on ProjectPortfolioStrings {
  String status(ProjectStatus value) => t(switch (value) {
    ProjectStatus.planning => PP.statusPlanning,
    ProjectStatus.active => PP.statusActive,
    ProjectStatus.onHold => PP.statusOnHold,
    ProjectStatus.completed => PP.statusCompleted,
    ProjectStatus.cancelled => PP.statusCancelled,
  });

  String projectType(ProjectType value) => t(switch (value) {
    ProjectType.clientBillable => PP.typeClientBillable,
    ProjectType.internalRAndD => PP.typeInternalRd,
    ProjectType.capexInvestment => PP.typeCapex,
  });

  String billing(BillingModel value) => t(switch (value) {
    BillingModel.timeAndMaterials => PP.billingTimeAndMaterials,
    BillingModel.fixedPrice => PP.billingFixedPrice,
    BillingModel.salProgress => PP.billingSalProgress,
    BillingModel.retainer => PP.billingRetainer,
  });

  String nodeType(WbsNodeType value) => t(switch (value) {
    WbsNodeType.phase => PP.nodeTypePhase,
    WbsNodeType.deliverable => PP.nodeTypeDeliverable,
    WbsNodeType.workPackage => PP.nodeTypeWorkPackage,
    WbsNodeType.milestone => PP.nodeTypeMilestone,
  });

  String dependency(DependencyType value) => t(switch (value) {
    DependencyType.fs => PP.dependencyFs,
    DependencyType.ss => PP.dependencySs,
    DependencyType.ff => PP.dependencyFf,
    DependencyType.sf => PP.dependencySf,
  });

  String progressState(WbsProgressState value) => t(switch (value) {
    WbsProgressState.notStarted => PP.boardNotStarted,
    WbsProgressState.inProgress => PP.boardInProgress,
    WbsProgressState.done => PP.boardDone,
  });

  String error(PortfolioErrorKind kind) => t(switch (kind) {
    PortfolioErrorKind.notFound => PP.errNotFound,
    PortfolioErrorKind.invalidTitle => PP.errTitle,
    PortfolioErrorKind.invalidDates => PP.errDates,
    PortfolioErrorKind.invalidProgress => PP.errProgress,
    PortfolioErrorKind.invalidAmount => PP.errAmount,
    PortfolioErrorKind.invalidCup => PP.invalidCup,
    PortfolioErrorKind.invalidCig => PP.invalidCig,
    PortfolioErrorKind.dependencyCycle => PP.errCycle,
    PortfolioErrorKind.duplicateDependency => PP.errDuplicate,
    PortfolioErrorKind.crossProject => PP.errCrossProject,
  });

  /// `5 d late`, `2 d early` or "on plan"; empty when the baseline had no date to compare.
  String slip(int? days) {
    if (days == null) {
      return '';
    }
    if (days == 0) {
      return t(PP.onPlan);
    }
    return days > 0
        ? f(PP.slipLate, <String, Object>{'count': days})
        : f(PP.slipEarly, <String, Object>{'count': -days});
  }
}

/// Hours or amounts without trailing zeros: `120`, `12.5`.
String formatQuantity(double value) {
  final String text = value.toStringAsFixed(2);
  return text.contains('.')
      ? text.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '')
      : text;
}

String formatPercent(double value) => '${value.round()}%';

String formatDate(BuildContext context, DateTime? date) => date == null
    ? '—'
    : MaterialLocalizations.of(context).formatShortDate(date);
