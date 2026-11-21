import 'package:material_ui/material_ui.dart';

import '../../../design/ff_tokens.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../domain/dss_models.dart';
import 'dss_format.dart';

/// The six indicators of the Executive Pulse, in display order.
const List<String> dssPulseKeys = <String>[
  'revenue',
  'gross_margin_pct',
  'ebitda',
  'net_cash_flow',
  'ccc_days',
  'dso_days',
];

/// A grid of pulse cards: two columns on a phone, three on a tablet.
class DssPulseGrid extends StatelessWidget {
  const DssPulseGrid({
    super.key,
    required this.overview,
    required this.languageCode,
  });

  final DssOverview overview;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final List<DssKpi> kpis = <DssKpi>[
      for (final String key in dssPulseKeys)
        if (overview.kpi(key) case final DssKpi kpi) kpi,
    ];
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int columns = constraints.maxWidth >= 720 ? 3 : 2;
        final double width =
            (constraints.maxWidth - FfSpace.space2 * (columns - 1)) / columns;
        return Wrap(
          spacing: FfSpace.space2,
          runSpacing: FfSpace.space2,
          children: <Widget>[
            for (final DssKpi kpi in kpis)
              SizedBox(
                width: width,
                child: DssPulseCard(
                  kpi: kpi,
                  currency: overview.currency,
                  languageCode: languageCode,
                ),
              ),
          ],
        );
      },
    );
  }
}

class DssPulseCard extends StatelessWidget {
  const DssPulseCard({
    super.key,
    required this.kpi,
    required this.currency,
    required this.languageCode,
  });

  final DssKpi kpi;
  final String currency;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final FfColors c =
        Theme.of(context).extension<FfColors>() ?? FfColors.light;
    final double? deltaPct = kpi.deltaPct;
    final Color trend = switch (kpi.favorable) {
      true => c.success,
      false => c.danger,
      null => c.textMuted,
    };
    return Container(
      key: Key('dss-kpi-${kpi.key}'),
      padding: const EdgeInsets.all(FfSpace.space3),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(FfRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            DssFormat.kpiLabel(l, kpi.key),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: c.textSecondary, fontSize: FfFont.xs),
          ),
          const SizedBox(height: FfSpace.space1),
          Text(
            DssFormat.kpiValue(l, kpi, currency, languageCode),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: c.text,
              fontSize: FfFont.xl,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: FfSpace.space1),
          Row(
            children: <Widget>[
              if (deltaPct != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: FfSpace.space2,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: trend.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(FfRadius.sm),
                  ),
                  child: Text(
                    DssFormat.signedPercent(deltaPct, languageCode),
                    key: Key('dss-delta-${kpi.key}'),
                    style: TextStyle(
                      color: trend,
                      fontSize: FfFont.xs,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                Text(
                  kpi.available ? '' : l.dssKpiUnavailable,
                  style: TextStyle(color: c.textMuted, fontSize: FfFont.xs),
                ),
              const Spacer(),
              SizedBox(
                width: 56,
                height: 22,
                child: CustomPaint(
                  painter: DssSparklinePainter(kpi.sparkline, trend),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A minimal line chart without axes; draws nothing for fewer than two points.
class DssSparklinePainter extends CustomPainter {
  const DssSparklinePainter(this.points, this.color);

  final List<double> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) {
      return;
    }
    double min = points.first;
    double max = points.first;
    for (final double p in points) {
      min = p < min ? p : min;
      max = p > max ? p : max;
    }
    final double span = max - min;
    final Path path = Path();
    for (int i = 0; i < points.length; i++) {
      final double x = size.width * i / (points.length - 1);
      final double y = span == 0
          ? size.height / 2
          : size.height - (points[i] - min) / span * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(DssSparklinePainter old) =>
      old.color != color || old.points != points;
}
