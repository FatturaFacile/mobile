import 'package:material_ui/material_ui.dart';

import '../domain/project_evm_models.dart';

/// Colour of a traffic light.
Color evmLightColor(EvmLight light) => switch (light) {
  EvmLight.green => const Color(0xFF2E7D32),
  EvmLight.amber => const Color(0xFFF9A825),
  EvmLight.red => const Color(0xFFC62828),
};

/// The S-curve: cumulative PV, EV and AC per period, and the dashed EAC projection to the planned end.
class EvmScurveChart extends StatelessWidget {
  const EvmScurveChart({
    required this.points,
    required this.forecast,
    super.key,
    this.height = 200,
  });

  final List<ScurvePoint> points;
  final List<EacPoint> forecast;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    width: double.infinity,
    child: CustomPaint(
      painter: _ScurvePainter(
        points: points,
        forecast: forecast,
        axis: Theme.of(context).colorScheme.outline,
      ),
    ),
  );
}

class _ScurvePainter extends CustomPainter {
  _ScurvePainter({
    required this.points,
    required this.forecast,
    required this.axis,
  });

  final List<ScurvePoint> points;
  final List<EacPoint> forecast;
  final Color axis;

  static const Color _pv = Color(0xFF1565C0);
  static const Color _ev = Color(0xFF2E7D32);
  static const Color _ac = Color(0xFFC62828);
  static const Color _eac = Color(0xFF6A1B9A);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) {
      return;
    }
    final List<DateTime> dates = <DateTime>[
      ...points.map((ScurvePoint p) => p.date),
      ...forecast.map((EacPoint p) => p.date),
    ]..sort();
    final int first = dates.first.millisecondsSinceEpoch;
    final int span = (dates.last.millisecondsSinceEpoch - first).clamp(
      1,
      1 << 62,
    );
    final double top = <double>[
      ...points.expand((ScurvePoint p) => <double>[p.pv, p.ev, p.ac]),
      ...forecast.map((EacPoint p) => p.eac),
    ].fold<double>(1, (double a, double b) => b > a ? b : a);

    Offset at(DateTime date, double value) => Offset(
      (date.millisecondsSinceEpoch - first) / span * size.width,
      size.height - value / top * size.height,
    );

    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      Paint()..color = axis,
    );
    canvas.drawLine(Offset.zero, Offset(0, size.height), Paint()..color = axis);

    void line(Color color, List<Offset> offsets, {bool dashed = false}) {
      final Paint paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      for (int i = 1; i < offsets.length; i++) {
        final Offset from = offsets[i - 1];
        final Offset to = offsets[i];
        if (!dashed) {
          canvas.drawLine(from, to, paint);
          continue;
        }
        // Dashes of 6 logical pixels every 12.
        final double length = (to - from).distance;
        for (double d = 0; d < length; d += 12) {
          final double end = d + 6 > length ? length : d + 6;
          canvas.drawLine(
            Offset.lerp(from, to, d / length)!,
            Offset.lerp(from, to, end / length)!,
            paint,
          );
        }
      }
    }

    line(_pv, points.map((ScurvePoint p) => at(p.date, p.pv)).toList());
    line(_ev, points.map((ScurvePoint p) => at(p.date, p.ev)).toList());
    line(_ac, points.map((ScurvePoint p) => at(p.date, p.ac)).toList());
    line(
      _eac,
      forecast.map((EacPoint p) => at(p.date, p.eac)).toList(),
      dashed: true,
    );
  }

  @override
  bool shouldRepaint(_ScurvePainter old) =>
      old.points != points || old.forecast != forecast || old.axis != axis;
}

/// Colours of the S-curve series, for the legend.
const List<Color> evmSeriesColors = <Color>[
  Color(0xFF1565C0),
  Color(0xFF2E7D32),
  Color(0xFFC62828),
  Color(0xFF6A1B9A),
];
