import 'package:fattura_facile/design/ff_tokens.dart';
import 'package:fattura_facile/features/copilot/domain/copilot_models.dart';
import 'package:fattura_facile/features/copilot/presentation/copilot_controller.dart';
import 'package:fattura_facile/features/copilot/presentation/copilot_sheet.dart';
import 'package:fattura_facile/features/copilot/presentation/compact_markdown.dart';
import 'package:fattura_facile/features/copilot/presentation/visualization_view.dart';
import 'package:fattura_facile/l10n/gen/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget host(Widget child) => MaterialApp(
  theme: ffThemeData(),
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

CopilotMessage action({ActionStatus status = ActionStatus.pending}) =>
    CopilotMessage(
      id: 'm1',
      conversationId: 'c1',
      role: MessageRole.assistant,
      content: 'Create it?',
      createdAt: DateTime(2026),
      actionStatus: status,
      proposedAction: const ProposedAction(
        tool: 'create_order',
        module: 'sales',
        summary: 'Create order',
        arguments: <String, dynamic>{
          'customer': 'X',
          'items': <dynamic>[
            <String, dynamic>{'quantity': 2, 'sku': 'A'},
          ],
        },
        editableFields: <String>['items.0.quantity'],
      ),
    );

void main() {
  final AppLocalizations en = lookupAppLocalizations(const Locale('en'));

  testWidgets(
    'action card edits only editable fields and sends only changed overrides',
    (WidgetTester tester) async {
      Map<String, Object?>? sent;
      await tester.pumpWidget(
        host(
          MessageBubble(
            message: action(),
            strings: en,
            onCitation: (_) {},
            onConfirm: (Map<String, Object?> o) async => sent = o,
            onReject: () async {},
          ),
        ),
      );
      expect(find.byKey(const Key('edit-items.0.quantity')), findsOneWidget);
      expect(find.byKey(const Key('edit-customer')), findsNothing);
      expect(find.text('Confirm & Execute'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('edit-items.0.quantity')),
        '3',
      );
      await tester.tap(find.byKey(const Key('action-confirm')));
      await tester.pump();
      expect(sent, <String, Object?>{'items.0.quantity': 3});
    },
  );

  testWidgets(
    'unchanged confirm sends no overrides; resolved actions hide the buttons',
    (WidgetTester tester) async {
      Map<String, Object?>? sent;
      await tester.pumpWidget(
        host(
          MessageBubble(
            message: action(),
            strings: en,
            onCitation: (_) {},
            onConfirm: (Map<String, Object?> o) async => sent = o,
            onReject: () async {},
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('action-confirm')));
      await tester.pump();
      expect(sent, isEmpty);

      await tester.pumpWidget(
        host(
          MessageBubble(
            message: action(status: ActionStatus.executed),
            strings: en,
            onCitation: (_) {},
            onConfirm: (_) async {},
            onReject: () async {},
          ),
        ),
      );
      expect(find.byKey(const Key('action-confirm')), findsNothing);
      expect(find.text('Executed'), findsOneWidget);
    },
  );

  testWidgets('cancel triggers reject', (WidgetTester tester) async {
    bool rejected = false;
    await tester.pumpWidget(
      host(
        MessageBubble(
          message: action(),
          strings: en,
          onCitation: (_) {},
          onConfirm: (_) async {},
          onReject: () async => rejected = true,
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('action-cancel')));
    await tester.pump();
    expect(rejected, isTrue);
  });

  testWidgets('entity citation chips are tappable and report the citation', (
    WidgetTester tester,
  ) async {
    Citation? tapped;
    await tester.pumpWidget(
      host(
        MessageBubble(
          message: CopilotMessage(
            id: 'm2',
            conversationId: 'c1',
            role: MessageRole.assistant,
            content: 'See **Rossi**',
            createdAt: DateTime(2026),
            citations: const <Citation>[
              Citation(
                type: 'entity',
                label: 'Rossi Srl',
                entityType: 'contacts',
                entityId: '7',
                route: '/contacts/7',
              ),
            ],
          ),
          strings: en,
          onCitation: (Citation c) => tapped = c,
          onConfirm: (_) async {},
          onReject: () async {},
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('entity-chip-7')));
    expect(tapped?.entityType, 'contacts');
    expect(tapped?.route, '/contacts/7');
  });

  testWidgets(
    'markdown renders bold, lists and tables inside a horizontal scroller',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        host(
          const CompactMarkdown(
            '# Title\n\n- one **bold**\n- two\n\n| A | B |\n|---|---|\n| 1 | 2 |',
          ),
        ),
      );
      expect(find.text('Title'), findsOneWidget);
      expect(find.text('two'), findsOneWidget);
      expect(find.byType(Table), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    },
  );

  testWidgets('visualization renders every type', (WidgetTester tester) async {
    const List<ChartDataset> ds = <ChartDataset>[
      ChartDataset(label: 'S', data: <double>[1, 3, 2]),
    ];
    for (final String type in <String>['bar', 'line', 'pie']) {
      await tester.pumpWidget(
        host(
          VisualizationView(
            Visualization(
              type: type,
              title: 'T',
              labels: const <String>['a', 'b', 'c'],
              datasets: ds,
            ),
          ),
        ),
      );
      expect(find.byKey(Key('viz-$type')), findsOneWidget, reason: type);
    }
    await tester.pumpWidget(
      host(
        const VisualizationView(
          Visualization(type: 'kpi_card', metric: 'Revenue', value: 1250.5),
        ),
      ),
    );
    expect(find.byKey(const Key('viz-kpi')), findsOneWidget);
    expect(find.text('1250.50'), findsOneWidget);
    await tester.pumpWidget(
      host(
        const VisualizationView(
          Visualization(
            type: 'table',
            columns: <String>['A', 'B'],
            rows: <List<Object?>>[
              <Object?>[1, 'x'],
            ],
          ),
        ),
      ),
    );
    expect(find.byKey(const Key('viz-table-scroll')), findsOneWidget);
    expect(find.text('x'), findsOneWidget);
  });

  testWidgets(
    'route observer captures page routes with entity arguments and ignores overlays',
    (WidgetTester tester) async {
      final CopilotContextTracker tracker = CopilotContextTracker();
      final CopilotRouteObserver observer = CopilotRouteObserver(tracker);
      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: <NavigatorObserver>[observer],
          home: const Scaffold(),
        ),
      );
      final NavigatorState nav = tester.state(find.byType(Navigator));
      nav.push(
        MaterialPageRoute<void>(
          settings: const RouteSettings(
            name: '/contacts/7',
            arguments: CopilotContext(
              route: '/contacts',
              entityType: 'contacts',
              entityId: '7',
            ),
          ),
          builder: (_) => const Scaffold(),
        ),
      );
      await tester.pumpAndSettle();
      expect(tracker.current.entityType, 'contacts');
      expect(tracker.current.entityId, '7');
      expect(tracker.current.route, '/contacts');

      showModalBottomSheet<void>(
        context: nav.context,
        builder: (_) => const SizedBox(height: 50),
      );
      await tester.pumpAndSettle();
      expect(tracker.current.entityId, '7');

      nav.pop();
      await tester.pumpAndSettle();
      nav.pop();
      await tester.pumpAndSettle();
      expect(tracker.current.entityId, isNull);
    },
  );

  test('every Copilot string exists in all four locales', () {
    for (final String code in <String>['it', 'en', 'de', 'fr']) {
      final AppLocalizations l = lookupAppLocalizations(Locale(code));
      expect(l.copilotConfirm, isNotEmpty, reason: code);
      expect(l.copilotErrRateLimited, isNotEmpty);
      expect(l.copilotToolRunning('x'), contains('x'));
    }
    expect(lookupAppLocalizations(const Locale('it')).copilotCancel, 'Annulla');
  });
}
