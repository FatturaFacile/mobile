import 'package:material_ui/material_ui.dart';

import '../../../../design/ff_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/approval_models.dart';
import 'pr_labels.dart';

/// Multi-level approval workflow progress timeline (Mod 006).
class PrApprovalProgress extends StatelessWidget {
  const PrApprovalProgress({required this.steps, super.key});

  final List<ApprovalLevelStep> steps;

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) {
      return const SizedBox.shrink();
    }
    final FfColors colors =
        Theme.of(context).extension<FfColors>() ?? FfColors.light;
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(FfRadius.lg),
        side: BorderSide(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(FfSpace.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              l10n.prApprovalProgressTitle,
              style: TextStyle(
                color: colors.text,
                fontSize: FfFont.md,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: FfSpace.space3),
            for (int i = 0; i < steps.length; i++) ...<Widget>[
              _StepRow(step: steps[i], colors: colors, l10n: l10n),
              if (i < steps.length - 1) const SizedBox(height: FfSpace.space2),
            ],
          ],
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.step,
    required this.colors,
    required this.l10n,
  });

  final ApprovalLevelStep step;
  final FfColors colors;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final ({IconData icon, Color color}) visual = switch (step.status) {
      ApprovalStepStatus.approved => (
        icon: Icons.check_circle,
        color: colors.success,
      ),
      ApprovalStepStatus.pending => (
        icon: Icons.pending_actions,
        color: colors.info,
      ),
      ApprovalStepStatus.rejected => (icon: Icons.cancel, color: colors.danger),
      ApprovalStepStatus.waiting => (
        icon: Icons.radio_button_unchecked,
        color: colors.textMuted,
      ),
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(visual.icon, color: visual.color, size: FfFont.xl),
        const SizedBox(width: FfSpace.space3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      '${l10n.prApprovalLevelLabel(step.level)} · ${step.roleName}',
                      style: TextStyle(
                        color: colors.text,
                        fontSize: FfFont.sm,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    PrLabels.stepStatus(l10n, step.status),
                    style: TextStyle(
                      color: visual.color,
                      fontSize: FfFont.xs,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (step.approverName != null && step.approverName!.isNotEmpty)
                Text(
                  step.decidedAt != null
                      ? '${step.approverName} · ${PrLabels.formatDateTime(context, step.decidedAt!)}'
                      : step.approverName!,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: FfFont.xs,
                  ),
                ),
              if (step.comment != null && step.comment!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: FfSpace.space1),
                  child: Text(
                    step.comment!,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: FfFont.xs,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
