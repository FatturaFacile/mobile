import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../../design/ff_tokens.dart';
import '../domain/copilot_models.dart';

/// Renders the `visualization` payload: `bar`, `line`, `pie`, `kpi_card` or `table` (the default).
class VisualizationView extends StatelessWidget {
  const VisualizationView(this.viz, {super.key});

  final Visualization viz;

  @override
  Widget build(BuildContext context) {
    final Widget body = switch (viz.type) {
      'kpi_card' => _KpiCard(viz),
      'bar' => _ChartBox(
        painter: _BarPainter(
          viz,
          _palette(context),
          Theme.of(context).dividerColor,
        ),
        viz: viz,
      ),
      'line' => _ChartBox(
        painter: _LinePainter(
          viz,
          _palette(context),
          Theme.of(context).dividerColor,
        ),
        viz: viz,
      ),
      'pie' => _PieChart(viz, _palette(context)),
      _ => _DataTableView(viz),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (viz.title != null &&
            viz.title!.isNotEmpty &&
            viz.type != 'kpi_card')
          Padding(
            padding: const EdgeInsets.only(bottom: FfSpace.space2),
            child: Text(
              viz.title!,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: FfFont.md,
              ),
            ),
          ),
        body,
      ],
    );
  }
}

List<Color> _palette(BuildContext context) {
  final FfColors c = Theme.of(context).extension<FfColors>() ?? FfColors.light;
  return <Color>[
    c.chart1,
    c.chart2,
    c.chart3,
    c.chart4,
    c.chart5,
    c.chart6,
    c.chart7,
    c.chart8,
  ];
}

String formatNumber(num v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

String _cell(Object? v) => v is num ? formatNumber(v) : (v?.toString() ?? '');

class _DataTableView extends StatelessWidget {
  const _DataTableView(this.viz);

  final Visualization viz;

  @override
  Widget build(BuildContext context) {
    if (viz.columns.isEmpty) return const SizedBox.shrink();
    return SingleChildScrollView(
      key: const Key('viz-table-scroll'),
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: FfSpace.space4,
        headingRowHeight: 36,
        dataRowMinHeight: 36,
        dataRowMaxHeight: 44,
        columns: <DataColumn>[
          for (final String c in viz.columns)
            DataColumn(
              label: Text(
                c,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: FfFont.sm,
                ),
              ),
            ),
        ],
        rows: <DataRow>[
          for (final List<Object?> r in viz.rows)
            DataRow(
              cells: <DataCell>[
                for (int i = 0; i < viz.columns.length; i++)
                  DataCell(
                    Text(
                      i < r.length ? _cell(r[i]) : '',
                      style: const TextStyle(fontSize: FfFont.sm),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard(this.viz);

  final Visualization viz;

  @override
  Widget build(BuildContext context) {
    final Object? v = viz.value;
    return Container(
      key: const Key('viz-kpi'),
      width: double.infinity,
      padding: const EdgeInsets.all(FfSpace.space4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(FfRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            viz.metric ?? viz.title ?? '',
            style: const TextStyle(fontSize: FfFont.sm),
          ),
          const SizedBox(height: FfSpace.space1),
          Text(
            v is num ? formatNumber(v) : (v?.toString() ?? ''),
            style: const TextStyle(
              fontSize: FfFont.size2xl,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartBox extends StatelessWidget {
  const _ChartBox({required this.painter, required this.viz});

  final CustomPainter painter;
  final Visualization viz;

  @override
  Widget build(BuildContext context) {
    final List<Color> colors = _palette(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          height: 160,
          width: double.infinity,
          child: CustomPaint(key: Key('viz-${viz.type}'), painter: painter),
        ),
        const SizedBox(height: FfSpace.space1),
        if (viz.labels.isNotEmpty)
          Text(
            viz.labels.join(' · '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: FfFont.xs),
          ),
        Wrap(
          spacing: FfSpace.space3,
          children: <Widget>[
            for (int i = 0; i < viz.datasets.length; i++)
              _LegendDot(colors[i % colors.length], viz.datasets[i].label),
          ],
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot(this.color, this.label);

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: FfSpace.space1),
        Text(label, style: const TextStyle(fontSize: FfFont.xs)),
      ],
    );
  }
}

double _maxOf(Visualization v) {
  double m = 0;
  for (final ChartDataset d in v.datasets) {
    for (final double x in d.data) {
      m = math.max(m, x);
    }
  }
  return m <= 0 ? 1 : m;
}

class _BarPainter extends CustomPainter {
  _BarPainter(this.viz, this.colors, this.axis);

  final Visualization viz;
  final List<Color> colors;
  final Color axis;

  @override
  void paint(Canvas canvas, Size size) {
    final double max = _maxOf(viz);
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      Paint()..color = axis,
    );
    final int groups = viz.datasets.isEmpty
        ? 0
        : viz.datasets.map((ChartDataset d) => d.data.length).reduce(math.max);
    if (groups == 0) return;
    final double groupW = size.width / groups;
    final double barW = groupW * 0.7 / viz.datasets.length;
    for (int g = 0; g < groups; g++) {
      for (int s = 0; s < viz.datasets.length; s++) {
        final List<double> data = viz.datasets[s].data;
        if (g >= data.length) continue;
        final double h = size.height * (data[g] / max);
        final double x = g * groupW + groupW * 0.15 + s * barW;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, size.height - h, barW, h),
            const Radius.circular(FfRadius.sm),
          ),
          Paint()..color = colors[s % colors.length],
        );
      }
    }
  }

  @override
  bool shouldRepaint(_BarPainter old) => old.viz != viz;
}

class _LinePainter extends CustomPainter {
  _LinePainter(this.viz, this.colors, this.axis);

  final Visualization viz;
  final List<Color> colors;
  final Color axis;

  @override
  void paint(Canvas canvas, Size size) {
    final double max = _maxOf(viz);
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      Paint()..color = axis,
    );
    for (int s = 0; s < viz.datasets.length; s++) {
      final List<double> data = viz.datasets[s].data;
      if (data.isEmpty) continue;
      final Paint line = Paint()
        ..color = colors[s % colors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      final Path path = Path();
      for (int i = 0; i < data.length; i++) {
        final double x = data.length == 1
            ? size.width / 2
            : size.width * i / (data.length - 1);
        final double y = size.height - size.height * (data[i] / max);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
        canvas.drawCircle(
          Offset(x, y),
          3,
          Paint()..color = colors[s % colors.length],
        );
      }
      canvas.drawPath(path, line);
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) => old.viz != viz;
}

class _PieChart extends StatelessWidget {
  const _PieChart(this.viz, this.colors);

  final Visualization viz;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final List<double> data = viz.datasets.isEmpty
        ? <double>[]
        : viz.datasets.first.data;
    return Row(
      children: <Widget>[
        SizedBox(
          width: 120,
          height: 120,
          child: CustomPaint(
            key: const Key('viz-pie'),
            painter: _PiePainter(data, colors),
          ),
        ),
        const SizedBox(width: FfSpace.space4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (int i = 0; i < data.length; i++)
                _LegendDot(
                  colors[i % colors.length],
                  '${i < viz.labels.length ? viz.labels[i] : ''} ${formatNumber(data[i])}'
                      .trim(),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PiePainter extends CustomPainter {
  _PiePainter(this.data, this.colors);

  final List<double> data;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final double total = data.fold<double>(
      0,
      (double a, double b) => a + math.max(0, b),
    );
    if (total <= 0) return;
    final Rect rect = Offset.zero & size;
    double start = -math.pi / 2;
    for (int i = 0; i < data.length; i++) {
      final double sweep = 2 * math.pi * math.max(0, data[i]) / total;
      canvas.drawArc(
        rect,
        start,
        sweep,
        true,
        Paint()..color = colors[i % colors.length],
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_PiePainter old) => old.data != data;
}
