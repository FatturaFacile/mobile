import 'package:material_ui/material_ui.dart';

import '../../../design/ff_tokens.dart';
import '../../general_ledger/domain/gl_amount.dart';
import 'swiss_vat_strings.dart';

FfColors swissVatColors(BuildContext context) =>
    Theme.of(context).extension<FfColors>() ?? FfColors.light;

String formatChf(Amount4 value, String localeTag) {
  final String lang = localeTag.split(RegExp('[-_]')).first.toLowerCase();
  return 'CHF ${formatAmount(value, language: lang)}';
}

class SwissVatCard extends StatelessWidget {
  const SwissVatCard({
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
    final FfColors c = swissVatColors(context);
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

class SwissVatKeyValueRow extends StatelessWidget {
  const SwissVatKeyValueRow(
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
        ? Theme.of(context).textTheme.titleSmall
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Expanded(child: Text(label, style: style)),
          Text(value, key: valueKey, style: style),
        ],
      ),
    );
  }
}

Widget swissVatOfflineBanner(SwissVatStrings s) => Padding(
  padding: const EdgeInsets.symmetric(
    horizontal: FfSpace.space3,
    vertical: FfSpace.space2,
  ),
  child: Row(
    children: <Widget>[
      const Icon(Icons.cloud_off, size: 18),
      const SizedBox(width: FfSpace.space2),
      Expanded(
        child: Text(s(SV.offlineBanner), key: const Key('chvat-offline')),
      ),
    ],
  ),
);
