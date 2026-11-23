import 'package:material_ui/material_ui.dart';

import '../../../design/ff_tokens.dart';
import '../../general_ledger/domain/gl_amount.dart';
import '../domain/italian_vat_models.dart';
import 'italian_vat_strings.dart';

FfColors vatColors(BuildContext context) =>
    Theme.of(context).extension<FfColors>() ?? FfColors.light;

/// Number and date formatting of the Italian VAT screens.
abstract final class VatFormat {
  /// `EUR 1.234,50` (decimal comma for it/de/fr, point for English).
  static String money(Amount4 value, String currency, String languageCode) =>
      '$currency ${formatAmount(value, language: _language(languageCode))}';

  /// `22,00%`.
  static String percent(Amount4 value, String languageCode) =>
      '${formatAmount(value, language: _language(languageCode))}%';

  /// `31.12.2027` (`2027-12-31` in English).
  static String date(DateTime? date, String languageCode) {
    if (date == null) {
      return '';
    }
    final String y = date.year.toString().padLeft(4, '0');
    final String m = date.month.toString().padLeft(2, '0');
    final String d = date.day.toString().padLeft(2, '0');
    return _language(languageCode) == 'en' ? '$y-$m-$d' : '$d.$m.$y';
  }

  static String _language(String code) =>
      code.split(RegExp('[-_]')).first.toLowerCase();
}

/// Card with a title and rows of label / value pairs.
class VatCard extends StatelessWidget {
  const VatCard({
    required this.title,
    required this.children,
    this.trailing,
    super.key,
  });

  final String title;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final FfColors c = vatColors(context);
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: FfSpace.space3,
        vertical: FfSpace.space2,
      ),
      color: c.surface,
      child: Padding(
        padding: const EdgeInsets.all(FfSpace.space3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: FfSpace.space2),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// One label / value row.
class VatRow extends StatelessWidget {
  const VatRow(
    this.label,
    this.value, {
    this.emphasis = false,
    this.valueKey,
    super.key,
  });

  final String label;
  final String value;
  final bool emphasis;
  final Key? valueKey;

  @override
  Widget build(BuildContext context) {
    final TextStyle? style = emphasis
        ? Theme.of(context).textTheme.bodyMedium
              ?.copyWith(fontWeight: FontWeight.w700)
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(child: Text(label, style: style)),
          const SizedBox(width: FfSpace.space2),
          Flexible(
            child: Text(
              value,
              key: valueKey,
              textAlign: TextAlign.end,
              style: style,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small coloured status pill.
class VatChip extends StatelessWidget {
  const VatChip(this.label, this.tone, {super.key});

  final String label;
  final VatTone tone;

  @override
  Widget build(BuildContext context) {
    final FfColors c = vatColors(context);
    final (Color bg, Color fg) = switch (tone) {
      VatTone.good => (c.successBg, c.success),
      VatTone.warn => (c.warningBg, c.warning),
      VatTone.bad => (c.dangerBg, c.danger),
      VatTone.neutral => (c.surfaceAlt, c.textSecondary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: FfSpace.space2,
        vertical: FfSpace.space1,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(FfRadius.sm),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

enum VatTone { good, warn, bad, neutral }

VatTone plafondTone(PlafondResult r) => switch (r) {
  PlafondResult.ok => VatTone.good,
  PlafondResult.nearLimit => VatTone.warn,
  _ => VatTone.bad,
};

VatTone reconciliationTone(ReconciliationState s) => switch (s) {
  ReconciliationState.reconciled => VatTone.good,
  ReconciliationState.difference => VatTone.bad,
  ReconciliationState.unknown => VatTone.neutral,
};

VatTone f24Tone(F24Status s) => switch (s) {
  F24Status.paid => VatTone.good,
  F24Status.partial => VatTone.warn,
  F24Status.unpaid => VatTone.bad,
};

/// Plafond usage bar: green, amber from 90%, red once exceeded.
class PlafondBar extends StatelessWidget {
  const PlafondBar({required this.letter, super.key});

  final IntentLetter letter;

  @override
  Widget build(BuildContext context) {
    final FfColors c = vatColors(context);
    final double ratio = letter.usedRatio;
    final Color color = ratio > 1
        ? c.danger
        : (ratio >= PlafondGuard.warnAtPercent / 100 ? c.warning : c.success);
    return ClipRRect(
      borderRadius: BorderRadius.circular(FfRadius.sm),
      child: LinearProgressIndicator(
        key: Key('ivat-plafond-bar-${letter.id}'),
        value: ratio.clamp(0, 1).toDouble(),
        minHeight: 8,
        color: color,
        backgroundColor: c.surfaceAlt,
      ),
    );
  }
}

/// Banner shown while the screen runs on the offline copy.
Widget vatOfflineBanner(ItalianVatStrings s) => MaterialBanner(
  key: const Key('ivat-offline'),
  content: Text(s(IV.offlineCopy)),
  actions: const <Widget>[SizedBox.shrink()],
);

const String vatNoValue = '—';
