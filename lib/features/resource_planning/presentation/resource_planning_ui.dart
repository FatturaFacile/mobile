import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/providers.dart';
import '../../../design/ff_tokens.dart';
import '../domain/resource_planning_models.dart';
import '../domain/resource_planning_repository.dart';
import 'resource_planning_strings.dart';

/// User-facing message of a failed call. A rule violation names the first violation code, then the server detail.
String resourcePlanningErrorMessage(
  ResourcePlanningStrings s,
  ResourcePlanningException e,
) {
  switch (e.kind) {
    case ResourcePlanningErrorKind.invalid:
      if (e.violations.isNotEmpty) {
        return s.violation(e.violations.first.code);
      }
      return e.detail.isEmpty ? s(RS.errorInvalid) : e.detail;
    case ResourcePlanningErrorKind.forbidden:
      return s(RS.errorForbidden);
    case ResourcePlanningErrorKind.notFound:
      return s(RS.errorNotFound);
    case ResourcePlanningErrorKind.conflict:
      return s(RS.errorConflict);
    case ResourcePlanningErrorKind.offline:
      return s(RS.errorOffline);
    case ResourcePlanningErrorKind.unknown:
      return s(RS.errorUnknown);
  }
}

/// Localized labels in the language of the current request context.
ResourcePlanningStrings rpStrings(WidgetRef ref) => ResourcePlanningStrings(
  ref.watch(requestContextProvider).languageCode,
);

FfColors rpColors(BuildContext context) =>
    Theme.of(context).extension<FfColors>() ?? FfColors.light;

/// Hours without a trailing `.0`.
String rpHours(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

/// Percentage rounded to a whole number.
String rpPercent(double v) => '${v.round()}%';

/// Message of a failed load with a retry button.
Widget rpErrorBox(
  ResourcePlanningStrings s,
  ResourcePlanningException error,
  VoidCallback onRetry, {
  Key? key,
}) => Padding(
  padding: const EdgeInsets.all(FfSpace.space4),
  child: Column(
    key: key,
    children: <Widget>[
      Text(resourcePlanningErrorMessage(s, error)),
      TextButton(onPressed: onRetry, child: Text(s(RS.retry))),
    ],
  ),
);

/// Shows [message] in a snack bar; [messageKey] lets a test find it.
void rpSnack(BuildContext context, String message, {Key? messageKey}) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message, key: messageKey)));
}

/// Asks the user to confirm a destructive action; true when the confirm button was pressed.
Future<bool> rpConfirm(
  BuildContext context,
  ResourcePlanningStrings s, {
  required String title,
  required String body,
}) async {
  final bool? result = await showDialog<bool>(
    context: context,
    builder: (BuildContext ctx) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: <Widget>[
        TextButton(
          key: const Key('rp-confirm-cancel'),
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(s(RS.cancelAction)),
        ),
        FilledButton(
          key: const Key('rp-confirm-ok'),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(s(RS.deleteAction)),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Parses a decimal typed with a dot or a comma; null when it is not a number.
double? parseDecimal(String text) =>
    double.tryParse(text.trim().replaceAll(',', '.'));

String allocationIssueLabel(
  ResourcePlanningStrings s,
  AllocationDraftIssue issue,
) => switch (issue) {
  AllocationDraftIssue.employeeRequired => s(RS.issueEmployeeRequired),
  AllocationDraftIssue.invalidPeriod => s(RS.violationInvalidPeriod),
  AllocationDraftIssue.invalidHours => s(RS.issueInvalidHours),
  AllocationDraftIssue.projectRequired => s(RS.issueProjectRequired),
  AllocationDraftIssue.referenceRequired => s(RS.issueReferenceRequired),
  AllocationDraftIssue.invalidOpportunityId => s(RS.issueInvalidOpportunity),
};

String skillIssueLabel(ResourcePlanningStrings s, SkillDraftIssue issue) =>
    switch (issue) {
      SkillDraftIssue.categoryRequired => s(RS.issueCategoryRequired),
      SkillDraftIssue.nameRequired => s(RS.issueSkillNameRequired),
      SkillDraftIssue.certificationCodeRequired => s(RS.issueCertificationCode),
    };

String profileIssueLabel(
  ResourcePlanningStrings s,
  SkillProfileDraftIssue issue,
) => switch (issue) {
  SkillProfileDraftIssue.employeeRequired => s(RS.issueEmployeeRequired),
  SkillProfileDraftIssue.skillRequired => s(RS.issueSkillRequired),
  SkillProfileDraftIssue.invalidLevel => s(RS.proficiencyField),
};

String holidayIssueLabel(
  ResourcePlanningStrings s,
  LocalHolidayDraftIssue issue,
) => switch (issue) {
  LocalHolidayDraftIssue.nameRequired => s(RS.issueHolidayName),
  LocalHolidayDraftIssue.invalidCountry => s(RS.countryField),
  LocalHolidayDraftIssue.invalidDate => s(RS.issueHolidayDate),
  LocalHolidayDraftIssue.invalidFraction => s(RS.issueHolidayFraction),
};

String certificationStatusLabel(
  ResourcePlanningStrings s,
  CertificationStatus status,
) => switch (status) {
  CertificationStatus.notRequired => s(RS.certNotRequired),
  CertificationStatus.valid => s(RS.certValid),
  CertificationStatus.missing => s(RS.certMissing),
  CertificationStatus.expired => s(RS.certExpired),
};
