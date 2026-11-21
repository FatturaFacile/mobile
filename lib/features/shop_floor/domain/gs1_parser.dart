/// Parsed GS1-128 / GS1 DataMatrix element strings (the application identifiers a shop floor label carries).
class Gs1Data {
  const Gs1Data(this.elements);

  /// Application identifier -> raw value.
  final Map<String, String> elements;

  String? get sscc => elements['00'];
  String? get gtin => elements['01'] ?? elements['02'];
  String? get lot => elements['10'];
  String? get serial => elements['21'];

  /// Expiry date (AI 17); day `00` (end of month) is read as the first of the month.
  DateTime? get expiry => _date(elements['17']);

  /// Count of items (AI 30, 37) or a net weight in kg (AI 310n).
  double? get quantity {
    final String? count = elements['30'] ?? elements['37'];
    if (count != null) {
      return double.tryParse(count);
    }
    for (final MapEntry<String, String> e in elements.entries) {
      if (e.key.length == 4 && e.key.startsWith('310')) {
        final int? raw = int.tryParse(e.value);
        final int? decimals = int.tryParse(e.key.substring(3));
        if (raw != null && decimals != null) {
          return raw / _pow10(decimals);
        }
      }
    }
    return null;
  }

  bool get isEmpty => elements.isEmpty;

  static double _pow10(int n) {
    double r = 1;
    for (int i = 0; i < n; i++) {
      r *= 10;
    }
    return r;
  }

  static DateTime? _date(String? v) {
    if (v == null || v.length != 6) {
      return null;
    }
    final int? yy = int.tryParse(v.substring(0, 2));
    final int? mm = int.tryParse(v.substring(2, 4));
    final int? dd = int.tryParse(v.substring(4, 6));
    if (yy == null || mm == null || dd == null || mm < 1 || mm > 12) {
      return null;
    }
    return DateTime.utc(2000 + yy, mm, dd == 0 ? 1 : dd);
  }
}

/// GS1 element string parser. Accepts the human readable form `(01)0123...(10)LOT` and the raw form with the
/// FNC1 / GS separator (`\x1d`) after variable length fields. Returns an empty [Gs1Data] when the text is not GS1.
abstract final class Gs1Parser {
  static const String _gs = '\u001d';

  /// Fixed length AIs: AI -> value length. Everything else is variable (terminated by GS or end).
  static const Map<String, int> _fixed = <String, int>{
    '00': 18,
    '01': 14,
    '02': 14,
    '11': 6,
    '12': 6,
    '13': 6,
    '15': 6,
    '16': 6,
    '17': 6,
    '20': 2,
  };

  static const Set<String> _variable = <String>{
    '10',
    '21',
    '22',
    '30',
    '37',
    '240',
    '241',
    '242',
    '250',
    '251',
    '400',
    '401',
    '420',
    '421',
  };

  static Gs1Data parse(String input) {
    String text = input.trim();
    if (text.startsWith(']C1') ||
        text.startsWith(']d2') ||
        text.startsWith(']Q3')) {
      text = text.substring(3);
    }
    if (text.isEmpty) {
      return const Gs1Data(<String, String>{});
    }
    return Gs1Data(
      text.startsWith('(') ? _parseBracketed(text) : _parseRaw(text),
    );
  }

  static Map<String, String> _parseBracketed(String text) {
    final Map<String, String> out = <String, String>{};
    final RegExp re = RegExp(r'\((\d{2,4})\)([^()]*)');
    for (final RegExpMatch m in re.allMatches(text)) {
      final String value = m.group(2)!.replaceAll(_gs, '');
      if (value.isNotEmpty) {
        out[m.group(1)!] = value;
      }
    }
    return text.replaceAll(re, '').trim().isEmpty ? out : <String, String>{};
  }

  static Map<String, String> _parseRaw(String text) {
    final Map<String, String> out = <String, String>{};
    int i = 0;
    while (i < text.length) {
      if (text[i] == _gs) {
        i++;
        continue;
      }
      final _Ai? ai = _readAi(text, i);
      if (ai == null) {
        return <String, String>{};
      }
      i += ai.code.length;
      int end;
      final int? fixedLength = ai.length;
      if (fixedLength != null) {
        end = i + fixedLength;
        if (end > text.length) {
          return <String, String>{};
        }
      } else {
        end = text.indexOf(_gs, i);
        if (end < 0) {
          end = text.length;
        }
      }
      final String value = text.substring(i, end);
      if (value.isEmpty) {
        return <String, String>{};
      }
      out[ai.code] = value;
      i = end;
    }
    return out;
  }

  static _Ai? _readAi(String text, int i) {
    if (i + 2 > text.length) {
      return null;
    }
    final String two = text.substring(i, i + 2);
    final int? fixed = _fixed[two];
    if (fixed != null) {
      return _Ai(two, fixed);
    }
    if (_variable.contains(two)) {
      return _Ai(two, null);
    }
    if (i + 4 <= text.length) {
      final String four = text.substring(i, i + 4);
      // 310n..369n measures are 6 digits long.
      if (RegExp(r'^3[1-6]\d\d$').hasMatch(four)) {
        return _Ai(four, 6);
      }
    }
    if (i + 3 <= text.length && _variable.contains(text.substring(i, i + 3))) {
      return _Ai(text.substring(i, i + 3), null);
    }
    // 90-99 are company internal variable fields.
    if (RegExp(r'^9\d$').hasMatch(two)) {
      return _Ai(two, null);
    }
    return null;
  }
}

class _Ai {
  const _Ai(this.code, this.length);

  final String code;
  final int? length;
}
