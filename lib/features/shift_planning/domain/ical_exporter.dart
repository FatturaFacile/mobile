import 'shift_models.dart';

/// Builds an RFC 5545 iCalendar document from published shifts, importable by every calendar app (Apple, Google,
/// Outlook). Times are written in UTC, so the daylight-saving shift of the establishment never moves an event.
class IcalExporter {
  const IcalExporter({this.productId = '-//FatturaFacile//ShiftPlanning//EN'});

  final String productId;

  /// The document for [shifts]; [now] stamps every event (a fixed value makes the output reproducible in tests).
  String build(
    List<Shift> shifts, {
    required String languageCode,
    DateTime? now,
  }) {
    final String stamp = _utc(now ?? DateTime.now().toUtc());
    final List<String> lines = <String>[
      'BEGIN:VCALENDAR',
      'VERSION:2.0',
      'PRODID:$productId',
      'CALSCALE:GREGORIAN',
      'METHOD:PUBLISH',
      for (final Shift s in shifts) ..._event(s, languageCode, stamp),
      'END:VCALENDAR',
    ];
    return '${lines.map(_fold).join('\r\n')}\r\n';
  }

  List<String> _event(Shift s, String languageCode, String stamp) {
    final String summary = s.label(languageCode);
    return <String>[
      'BEGIN:VEVENT',
      'UID:${s.id}@fatturafacile.shifts',
      'DTSTAMP:$stamp',
      'DTSTART:${_utc(s.startAt)}',
      'DTEND:${_utc(s.endAt)}',
      'SUMMARY:${_escape(summary)}',
      if (s.tags.isNotEmpty)
        'CATEGORIES:${s.tags.map((SurchargeTag t) => t.wire.toUpperCase()).join(',')}',
      'DESCRIPTION:${_escape('${s.templateCode} · $summary')}',
      'TRANSP:OPAQUE',
      'END:VEVENT',
    ];
  }

  /// Link that opens the "add event" page of Google Calendar for one shift.
  Uri googleCalendarUri(Shift s, {required String languageCode}) {
    return Uri.https(
      'calendar.google.com',
      '/calendar/render',
      <String, String>{
        'action': 'TEMPLATE',
        'text': s.label(languageCode),
        'dates': '${_utc(s.startAt)}/${_utc(s.endAt)}',
        'details': s.templateCode,
      },
    );
  }

  static String _utc(DateTime value) {
    final DateTime u = value.toUtc();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${u.year.toString().padLeft(4, '0')}${two(u.month)}${two(u.day)}'
        'T${two(u.hour)}${two(u.minute)}${two(u.second)}Z';
  }

  /// Text values escape backslash, semicolon, comma and line breaks (RFC 5545 §3.3.11).
  static String _escape(String value) => value
      .replaceAll('\\', r'\\')
      .replaceAll(';', r'\;')
      .replaceAll(',', r'\,')
      .replaceAll('\r\n', r'\n')
      .replaceAll('\n', r'\n');

  /// Content lines are folded at 75 octets with a CRLF and a space (RFC 5545 §3.1).
  static String _fold(String line) {
    final List<int> bytes = line.codeUnits;
    if (bytes.length <= 75) {
      return line;
    }
    final StringBuffer out = StringBuffer();
    int start = 0;
    bool first = true;
    while (start < line.length) {
      final int limit = first ? 75 : 74;
      final int end = start + limit < line.length ? start + limit : line.length;
      if (!first) {
        out.write('\r\n ');
      }
      out.write(line.substring(start, end));
      start = end;
      first = false;
    }
    return out.toString();
  }
}
