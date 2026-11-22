import 'package:material_ui/material_ui.dart';

import '../../../l10n/gen/app_localizations.dart';

/// Structured rendering of the production-order genealogy payload
/// (`output_lots`, `operations`, `machine_events`).
class GenealogyView extends StatelessWidget {
  const GenealogyView({required this.data, super.key});

  final Map<String, dynamic> data;

  List<Map<String, dynamic>> _list(String key) {
    final dynamic raw = data[key];
    if (raw is! List) {
      return const <Map<String, dynamic>>[];
    }
    return raw
        .whereType<Map<dynamic, dynamic>>()
        .map((Map<dynamic, dynamic> e) => Map<String, dynamic>.from(e))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final TextTheme text = Theme.of(context).textTheme;
    final List<Map<String, dynamic>> lots = _list('output_lots');
    final List<Map<String, dynamic>> ops = _list('operations');
    final List<Map<String, dynamic>> events = _list('machine_events');
    if (lots.isEmpty && ops.isEmpty && events.isEmpty) {
      return Text(l10n.mfgGenealogyEmpty);
    }
    Widget section(String title, List<String> lines) {
      if (lines.isEmpty) {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: text.titleSmall),
            for (final String line in lines) Text(line),
          ],
        ),
      );
    }

    String t(dynamic v) => v == null ? '-' : v.toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (data['order_number'] != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(t(data['order_number']), style: text.titleMedium),
          ),
        section(
          l10n.mfgGenealogyOutputLots,
          lots.map((Map<String, dynamic> e) => t(e['lot_number'])).toList(),
        ),
        section(
          l10n.mfgGenealogyOperations,
          ops
              .map(
                (Map<String, dynamic> e) =>
                    '${t(e['started_at'])} → ${t(e['completed_at'])}',
              )
              .toList(),
        ),
        section(
          l10n.mfgGenealogyMachineEvents,
          events
              .map(
                (Map<String, dynamic> e) =>
                    '${t(e['occurred_at'])}  ${t(e['state'])}',
              )
              .toList(),
        ),
      ],
    );
  }
}
