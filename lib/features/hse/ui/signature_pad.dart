import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

/// The strokes drawn on glass. A stroke is a list of points; lifting the finger ends it.
class SignatureController extends ChangeNotifier {
  final List<List<Offset>> _strokes = <List<Offset>>[];

  /// Strokes drawn so far (read-only copy).
  List<List<Offset>> get strokes => <List<Offset>>[
    for (final s in _strokes) List<Offset>.unmodifiable(s),
  ];

  bool get isEmpty => _strokes.isEmpty;

  void startStroke(Offset point) {
    _strokes.add(<Offset>[point]);
    notifyListeners();
  }

  void extendStroke(Offset point) {
    if (_strokes.isEmpty) return;
    _strokes.last.add(point);
    notifyListeners();
  }

  void clear() {
    _strokes.clear();
    notifyListeners();
  }

  /// The strokes as compact JSON (`[[[x,y],[x,y]], ...]`): the evidence the server hashes with the hand-over data.
  String toPayload() => jsonEncode(<List<List<double>>>[
    for (final stroke in _strokes)
      <List<double>>[
        for (final p in stroke)
          <double>[
            double.parse(p.dx.toStringAsFixed(1)),
            double.parse(p.dy.toStringAsFixed(1)),
          ],
      ],
  ]);

  /// The signature as a base64 PNG on a transparent background, or null while nothing is drawn.
  Future<String?> toPngBase64({
    Size size = const Size(480, 180),
    Color ink = const Color(0xFF111111),
  }) async {
    if (isEmpty) return null;
    final recorder = ui.PictureRecorder();
    SignaturePainter(strokes: strokes, ink: ink).paint(Canvas(recorder), size);
    final image = await recorder.endRecording().toImage(
      size.width.round(),
      size.height.round(),
    );
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data == null ? null : base64Encode(data.buffer.asUint8List());
  }
}

/// Paints the strokes with round joins.
class SignaturePainter extends CustomPainter {
  const SignaturePainter({required this.strokes, required this.ink});

  final List<List<Offset>> strokes;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ink
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final stroke in strokes) {
      if (stroke.length == 1) {
        canvas.drawCircle(
          stroke.first,
          1.25,
          paint..style = PaintingStyle.fill,
        );
        paint.style = PaintingStyle.stroke;
        continue;
      }
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (final p in stroke.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(SignaturePainter oldDelegate) => true;
}

/// Signature surface: a light "paper" so the ink reads in the dark theme too.
class SignaturePad extends StatelessWidget {
  const SignaturePad({super.key, required this.controller, this.height = 180});

  final SignatureController controller;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        border: Border.all(color: const Color(0xFF9E9E9E)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (d) => controller.startStroke(d.localPosition),
        onPanUpdate: (d) => controller.extendStroke(d.localPosition),
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) => CustomPaint(
            size: Size.infinite,
            painter: SignaturePainter(
              strokes: controller.strokes,
              ink: const Color(0xFF111111),
            ),
          ),
        ),
      ),
    );
  }
}
