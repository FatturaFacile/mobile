import 'package:material_ui/material_ui.dart';

import '../../../design/ff_tokens.dart';

/// Minimal Markdown renderer for chat bubbles: headings, lists, quotes, code, pipe tables and
/// inline bold / italic / code. Links render as styled text (no navigation).
class CompactMarkdown extends StatelessWidget {
  const CompactMarkdown(this.source, {this.color, super.key});

  final String source;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle base = (theme.textTheme.bodyMedium ?? const TextStyle())
        .copyWith(fontSize: FfFont.md, height: 1.35, color: color);
    final List<Widget> blocks = <Widget>[];
    final List<String> lines = source.replaceAll('\r\n', '\n').split('\n');
    int i = 0;
    while (i < lines.length) {
      final String line = lines[i];
      final String trimmed = line.trim();
      if (trimmed.isEmpty) {
        i++;
      } else if (trimmed.startsWith('```')) {
        final StringBuffer code = StringBuffer();
        i++;
        while (i < lines.length && !lines[i].trim().startsWith('```')) {
          code.writeln(lines[i]);
          i++;
        }
        i++;
        blocks.add(_CodeBlock(code.toString().trimRight(), base));
      } else if (_isTableRow(trimmed) &&
          i + 1 < lines.length &&
          _isSeparator(lines[i + 1].trim())) {
        final List<List<String>> rows = <List<String>>[_cells(trimmed)];
        i += 2;
        while (i < lines.length && _isTableRow(lines[i].trim())) {
          rows.add(_cells(lines[i].trim()));
          i++;
        }
        blocks.add(_MarkdownTable(rows, base));
      } else if (trimmed.startsWith('#')) {
        final int level =
            trimmed.length - trimmed.replaceFirst(RegExp(r'^#+'), '').length;
        final String text = trimmed.substring(level).trim();
        blocks.add(
          Text.rich(
            _inline(
              text,
              base.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: level <= 1 ? FfFont.lg : FfFont.md,
              ),
              context,
            ),
          ),
        );
        i++;
      } else if (RegExp(r'^([-*•]|\d+[.)])\s+').hasMatch(trimmed)) {
        final RegExpMatch m = RegExp(r'^([-*•]|\d+[.)])\s+')
            .firstMatch(trimmed)!;
        final bool numbered = RegExp(r'\d').hasMatch(m.group(1)!);
        blocks.add(
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                width: 22,
                child: Text(numbered ? m.group(1)! : '•', style: base),
              ),
              Expanded(
                child: Text.rich(
                  _inline(trimmed.substring(m.end), base, context),
                ),
              ),
            ],
          ),
        );
        i++;
      } else if (trimmed.startsWith('>')) {
        blocks.add(
          Container(
            padding: const EdgeInsets.only(left: FfSpace.space2),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: theme.dividerColor, width: 3),
              ),
            ),
            child: Text.rich(
              _inline(trimmed.substring(1).trim(), base, context),
            ),
          ),
        );
        i++;
      } else {
        final StringBuffer para = StringBuffer(trimmed);
        i++;
        while (i < lines.length &&
            lines[i].trim().isNotEmpty &&
            !_startsBlock(lines[i].trim())) {
          para.write(' ${lines[i].trim()}');
          i++;
        }
        blocks.add(Text.rich(_inline(para.toString(), base, context)));
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int k = 0; k < blocks.length; k++) ...<Widget>[
          if (k > 0) const SizedBox(height: FfSpace.space1 + 2),
          blocks[k],
        ],
      ],
    );
  }

  static bool _startsBlock(String l) =>
      l.startsWith('#') ||
      l.startsWith('```') ||
      l.startsWith('>') ||
      RegExp(r'^([-*•]|\d+[.)])\s+').hasMatch(l) ||
      _isTableRow(l);

  static bool _isTableRow(String l) => l.startsWith('|') && l.contains('|', 1);

  static bool _isSeparator(String l) =>
      _isTableRow(l) &&
      RegExp(r'^\|[\s:|-]+\|?$').hasMatch(l) &&
      l.contains('-');

  static List<String> _cells(String l) {
    String s = l;
    if (s.startsWith('|')) s = s.substring(1);
    if (s.endsWith('|')) s = s.substring(0, s.length - 1);
    return s.split('|').map((String c) => c.trim()).toList();
  }

  static final RegExp _tokens = RegExp(
    r'\*\*(.+?)\*\*|__(.+?)__|`([^`]+)`|\*(.+?)\*|\[([^\]]+)\]\(([^)]+)\)',
  );

  static TextSpan _inline(String text, TextStyle style, BuildContext context) {
    final List<InlineSpan> spans = <InlineSpan>[];
    int last = 0;
    for (final RegExpMatch m in _tokens.allMatches(text)) {
      if (m.start > last)
        spans.add(TextSpan(text: text.substring(last, m.start)));
      if (m.group(1) != null || m.group(2) != null) {
        spans.add(
          TextSpan(
            text: m.group(1) ?? m.group(2),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        );
      } else if (m.group(3) != null) {
        spans.add(
          TextSpan(
            text: m.group(3),
            style: TextStyle(
              fontFamily: FfFont.mono,
              backgroundColor: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest,
            ),
          ),
        );
      } else if (m.group(4) != null) {
        spans.add(
          TextSpan(
            text: m.group(4),
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: m.group(5),
            style: TextStyle(
              decoration: TextDecoration.underline,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        );
      }
      last = m.end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
    return TextSpan(style: style, children: spans);
  }
}

class _CodeBlock extends StatelessWidget {
  const _CodeBlock(this.code, this.base);

  final String code;
  final TextStyle base;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(FfSpace.space2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(FfRadius.md),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Text(
          code,
          style: base.copyWith(fontFamily: FfFont.mono, fontSize: FfFont.sm),
        ),
      ),
    );
  }
}

class _MarkdownTable extends StatelessWidget {
  const _MarkdownTable(this.rows, this.base);

  final List<List<String>> rows;
  final TextStyle base;

  @override
  Widget build(BuildContext context) {
    final Color border = Theme.of(context).dividerColor;
    final int cols = rows.first.length;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        defaultColumnWidth: const IntrinsicColumnWidth(),
        border: TableBorder.all(color: border),
        children: <TableRow>[
          for (int r = 0; r < rows.length; r++)
            TableRow(
              children: <Widget>[
                for (int c = 0; c < cols; c++)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: FfSpace.space2,
                      vertical: FfSpace.space1,
                    ),
                    child: Text(
                      c < rows[r].length ? rows[r][c] : '',
                      style: base.copyWith(
                        fontSize: FfFont.sm,
                        fontWeight: r == 0 ? FontWeight.w700 : null,
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
