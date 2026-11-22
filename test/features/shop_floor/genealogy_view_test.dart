import 'package:fattura_facile/features/shop_floor/presentation/genealogy_view.dart';
import 'package:fattura_facile/l10n/gen/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(Map<String, dynamic> data) => MaterialApp(
  locale: const Locale('en'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: GenealogyView(data: data)),
);

void main() {
  testWidgets('renders lots, operations and machine events', (t) async {
    await t.pumpWidget(
      _host(<String, dynamic>{
        'order_number': 'PO-1',
        'output_lots': <dynamic>[
          <String, dynamic>{'lot_id': 'a', 'lot_number': 'L-42'},
        ],
        'operations': <dynamic>[
          <String, dynamic>{'started_at': 'S1', 'completed_at': null},
        ],
        'machine_events': <dynamic>[
          <String, dynamic>{'occurred_at': 'T1', 'state': 'running'},
        ],
      }),
    );
    expect(find.text('PO-1'), findsOneWidget);
    expect(find.text('L-42'), findsOneWidget);
    expect(find.text('S1 → -'), findsOneWidget);
    expect(find.textContaining('running'), findsOneWidget);
  });

  testWidgets('shows empty message', (t) async {
    await t.pumpWidget(_host(<String, dynamic>{}));
    expect(find.text('No genealogy data yet.'), findsOneWidget);
  });
}
