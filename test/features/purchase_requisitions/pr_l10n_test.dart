import 'package:fattura_facile/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all 4 locales (en, it, de, fr) load AppLocalizations with populated strings and placeholders', () async {
    for (final String code in <String>['en', 'it', 'de', 'fr']) {
      final AppLocalizations l10n = await AppLocalizations.delegate.load(
        Locale(code),
      );
      expect(l10n.prHubTitle.trim(), isNotEmpty, reason: '$code prHubTitle');
      expect(
        l10n.prTabMyRequests.trim(),
        isNotEmpty,
        reason: '$code prTabMyRequests',
      );
      expect(
        l10n.prTabToApprove.trim(),
        isNotEmpty,
        reason: '$code prTabToApprove',
      );
      expect(
        l10n.prApproveOneTap.trim(),
        isNotEmpty,
        reason: '$code prApproveOneTap',
      );
      expect(
        l10n.prRejectReasonRequired.trim(),
        isNotEmpty,
        reason: '$code prRejectReasonRequired',
      );
      expect(
        l10n.prStatusBudgetExceeded.trim(),
        isNotEmpty,
        reason: '$code prStatusBudgetExceeded',
      );

      expect(l10n.prLinkedRdoLabel('RDO-42'), contains('RDO-42'), reason: code);
      expect(l10n.prLinkedPoLabel('PO-99'), contains('PO-99'), reason: code);
      expect(
        l10n.prLevelBadge(1, 3),
        allOf(contains('1'), contains('3')),
        reason: code,
      );
      expect(l10n.prBudgetUtilization('88'), contains('88'), reason: code);
      expect(
        l10n.prSyncCompletedSubmitted('RDA-01'),
        contains('RDA-01'),
        reason: code,
      );
      expect(
        l10n.prSyncCompletedBudgetBlocked('RDA-02'),
        contains('RDA-02'),
        reason: code,
      );
    }
  });
}
