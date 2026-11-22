import 'dart:convert';
import 'dart:ui' show Offset;

import 'package:crypto/crypto.dart';

import '../models/field_service_models.dart';

/// Turns the strokes drawn on glass into the vector signature the service report carries (`signature_svg`).
///
/// The SVG is plain paths: it starts with `<svg`, holds no script or event attribute (the API refuses both) and is kept
/// under [ServiceReportDraft.svgMaxBytes] by thinning the points of long signatures.
abstract final class SignatureSvg {
  static const String ink = '#111111';
  static const double strokeWidth = 2.5;

  /// The SVG of [strokes] on a [width] x [height] canvas, or null while nothing is drawn.
  static String? fromStrokes(
    List<List<Offset>> strokes, {
    double width = 480,
    double height = 180,
  }) {
    var current = <List<Offset>>[
      for (final List<Offset> s in strokes)
        if (s.isNotEmpty) s,
    ];
    if (current.isEmpty) return null;

    var svg = _render(current, width, height);
    // Drop every second point (keeping the ends of each stroke) until the signature fits the server limit.
    while (utf8.encode(svg).length > ServiceReportDraft.svgMaxBytes) {
      final List<List<Offset>> thinned = <List<Offset>>[
        for (final List<Offset> s in current) _thin(s),
      ];
      if (thinned.every((List<Offset> s) => s.length <= 2)) break;
      current = thinned;
      svg = _render(current, width, height);
    }
    return svg;
  }

  static List<Offset> _thin(List<Offset> stroke) {
    if (stroke.length <= 2) return stroke;
    return <Offset>[
      for (var i = 0; i < stroke.length; i++)
        if (i.isEven || i == stroke.length - 1) stroke[i],
    ];
  }

  static String _n(double v) => v.toStringAsFixed(1);

  static String _render(
    List<List<Offset>> strokes,
    double width,
    double height,
  ) {
    final StringBuffer out = StringBuffer()
      ..write(
        '<svg xmlns="http://www.w3.org/2000/svg" '
        'width="${_n(width)}" height="${_n(height)}" '
        'viewBox="0 0 ${_n(width)} ${_n(height)}">',
      );
    for (final List<Offset> stroke in strokes) {
      if (stroke.length == 1) {
        out.write(
          '<circle cx="${_n(stroke.first.dx)}" cy="${_n(stroke.first.dy)}" '
          'r="${_n(strokeWidth / 2)}" fill="$ink"/>',
        );
        continue;
      }
      final StringBuffer d = StringBuffer(
        'M${_n(stroke.first.dx)} ${_n(stroke.first.dy)}',
      );
      for (final Offset p in stroke.skip(1)) {
        d.write(' L${_n(p.dx)} ${_n(p.dy)}');
      }
      out.write(
        '<path d="$d" fill="none" stroke="$ink" stroke-width="$strokeWidth" '
        'stroke-linecap="round" stroke-linejoin="round"/>',
      );
    }
    out.write('</svg>');
    return out.toString();
  }
}

/// SHA-256 of the signature SVG, lower-case hex: the device-side fingerprint of what the customer drew. The server seals the
/// report with its own hash (`signature_sha256_hash`, which also covers the report number it assigns), so this one is kept
/// next to the queued report as evidence of the signature that left the phone.
abstract final class SignatureSvgHash {
  static String sha256Hex(String svg) =>
      sha256.convert(utf8.encode(svg)).toString();
}
