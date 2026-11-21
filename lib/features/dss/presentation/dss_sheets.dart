import 'package:material_ui/material_ui.dart';

import '../../../design/ff_tokens.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../domain/dss_models.dart';
import '../domain/what_if_calculator.dart';
import 'dss_format.dart';

Color dssSeverityColor(FfColors c, String severity) => switch (severity) {
  'CRITICAL' => c.danger,
  'WARNING' => c.warning,
  _ => c.info,
};

Future<void> _showSheet(BuildContext context, WidgetBuilder builder) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    constraints: BoxConstraints(
      maxWidth: MediaQuery.sizeOf(context).width >= 720 ? 640 : double.infinity,
    ),
    builder: builder,
  );
}

/// Tap-to-inspect sheet of an alert: what happened, the probable root cause and the recommended action.
Future<void> showDssAlertSheet(
  BuildContext context,
  DssAlert alert,
  String languageCode,
) {
  return _showSheet(
    context,
    (BuildContext ctx) => _AlertSheet(alert: alert, languageCode: languageCode),
  );
}

class _AlertSheet extends StatelessWidget {
  const _AlertSheet({required this.alert, required this.languageCode});

  final DssAlert alert;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final FfColors c =
        Theme.of(context).extension<FfColors>() ?? FfColors.light;
    final Color color = dssSeverityColor(c, alert.severity);
    final String? cause = DssFormat.rootCause(l, alert.code);
    final String? action = DssFormat.recommendedAction(l, alert.code);
    return SingleChildScrollView(
      key: const Key('dss-alert-sheet'),
      padding: const EdgeInsets.fromLTRB(
        FfSpace.space4,
        0,
        FfSpace.space4,
        FfSpace.space5,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.warning_amber_rounded, color: color),
              const SizedBox(width: FfSpace.space2),
              Expanded(
                child: Text(
                  DssFormat.alertTitle(l, alert.code),
                  style: const TextStyle(
                    fontSize: FfFont.lg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                DssFormat.severityLabel(l, alert.severity),
                style: TextStyle(color: color, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: FfSpace.space3),
          Text(DssFormat.alertSummary(l, alert, languageCode)),
          if (cause != null) ...<Widget>[
            const SizedBox(height: FfSpace.space4),
            _Section(title: l.dssRootCause, body: cause),
          ],
          if (action != null) ...<Widget>[
            const SizedBox(height: FfSpace.space3),
            _Section(title: l.dssRecommendedAction, body: action),
          ],
          const SizedBox(height: FfSpace.space4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l.dssClose),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final FfColors c =
        Theme.of(context).extension<FfColors>() ?? FfColors.light;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: TextStyle(
            color: c.textSecondary,
            fontSize: FfFont.xs,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: FfSpace.space1),
        Text(body),
      ],
    );
  }
}

/// What-if quick check: the price and COGS sliders re-run the simulator on the device, so it works offline.
Future<void> showDssWhatIfSheet(
  BuildContext context,
  DssSnapshot snapshot,
  String languageCode,
) {
  return _showSheet(
    context,
    (BuildContext ctx) =>
        DssWhatIfSheet(snapshot: snapshot, languageCode: languageCode),
  );
}

class DssWhatIfSheet extends StatefulWidget {
  const DssWhatIfSheet({
    super.key,
    required this.snapshot,
    required this.languageCode,
  });

  final DssSnapshot snapshot;
  final String languageCode;

  @override
  State<DssWhatIfSheet> createState() => _DssWhatIfSheetState();
}

class _DssWhatIfSheetState extends State<DssWhatIfSheet> {
  WhatIfScenario _scenario = const WhatIfScenario();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final FfColors c =
        Theme.of(context).extension<FfColors>() ?? FfColors.light;
    final String currency = widget.snapshot.overview.currency;
    final WhatIfResult result = simulateWhatIf(
      widget.snapshot.baseline,
      _scenario,
    );
    final double change = result.delta.ebitda;
    final Color changeColor = change > 0
        ? c.success
        : change < 0
        ? c.danger
        : c.textMuted;
    return SingleChildScrollView(
      key: const Key('dss-whatif-sheet'),
      padding: const EdgeInsets.fromLTRB(
        FfSpace.space4,
        0,
        FfSpace.space4,
        FfSpace.space5,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l.dssWhatIfTitle,
            style: const TextStyle(
              fontSize: FfFont.lg,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: FfSpace.space3),
          _SliderRow(
            sliderKey: const Key('dss-slider-price'),
            label: l.dssWhatIfPrice,
            value: _scenario.pricePct,
            languageCode: widget.languageCode,
            onChanged: (double v) =>
                setState(() => _scenario = _scenario.copyWith(pricePct: v)),
          ),
          _SliderRow(
            sliderKey: const Key('dss-slider-cogs'),
            label: l.dssWhatIfCogs,
            value: _scenario.cogsPct,
            languageCode: widget.languageCode,
            onChanged: (double v) =>
                setState(() => _scenario = _scenario.copyWith(cogsPct: v)),
          ),
          const SizedBox(height: FfSpace.space3),
          _Figure(
            label: l.dssWhatIfCurrent,
            value: DssFormat.amount(
              result.baseline.ebitda,
              currency,
              widget.languageCode,
            ),
          ),
          _Figure(
            valueKey: const Key('dss-whatif-ebitda'),
            label: l.dssWhatIfSimulated,
            value: DssFormat.amount(
              result.simulated.ebitda,
              currency,
              widget.languageCode,
            ),
            bold: true,
          ),
          _Figure(
            valueKey: const Key('dss-whatif-change'),
            label: l.dssWhatIfChange,
            value:
                '${change > 0 ? '+' : ''}${DssFormat.amount(change, currency, widget.languageCode)}',
            color: changeColor,
          ),
          const SizedBox(height: FfSpace.space2),
          Text(
            l.dssWhatIfOnDevice,
            style: TextStyle(color: c.textMuted, fontSize: FfFont.xs),
          ),
          const SizedBox(height: FfSpace.space2),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              TextButton(
                key: const Key('dss-whatif-reset'),
                onPressed: _scenario.isNeutral
                    ? null
                    : () => setState(() => _scenario = const WhatIfScenario()),
                child: Text(l.dssWhatIfReset),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l.dssClose),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.sliderKey,
    required this.label,
    required this.value,
    required this.languageCode,
    required this.onChanged,
  });

  final Key sliderKey;
  final String label;
  final double value;
  final String languageCode;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: Text(label)),
            Text(
              DssFormat.signedPercent(value, languageCode),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        Slider(
          key: sliderKey,
          value: value,
          min: -20,
          max: 20,
          divisions: 40,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({
    required this.label,
    required this.value,
    this.valueKey,
    this.bold = false,
    this.color,
  });

  final String label;
  final String value;
  final Key? valueKey;
  final bool bold;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label)),
          Text(
            value,
            key: valueKey,
            style: TextStyle(
              color: color,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
