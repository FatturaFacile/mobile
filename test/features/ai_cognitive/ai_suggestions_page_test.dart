import 'package:fattura_facile/design/ff_tokens.dart';
import 'package:fattura_facile/features/ai_cognitive/domain/ai_models.dart';
import 'package:fattura_facile/features/ai_cognitive/domain/ai_repository.dart';
import 'package:fattura_facile/features/ai_cognitive/presentation/ai_controller.dart';
import 'package:fattura_facile/features/ai_cognitive/presentation/ai_suggestions_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'fakes.dart';

Widget host(FakeAiRepository repo, Widget child) => ProviderScope(
  key: UniqueKey(),
  overrides: [
    aiRepositoryProvider.overrideWithValue(repo),
    aiTenantIdProvider.overrideWithValue('t1'),
  ],
  child: MaterialApp(theme: ffThemeData(), home: child),
);

void main() {
  testWidgets('lists suggestions with confidence badges per band', (
    WidgetTester tester,
  ) async {
    final FakeAiRepository repo = FakeAiRepository()
      ..remote = <Suggestion>[
        fakeSuggestion('hi', confidence: 0.95),
        fakeSuggestion('mid', confidence: 0.75, kind: 'purchase_order'),
        fakeSuggestion('lo', confidence: 0.4, kind: 'contact'),
      ];
    await tester.pumpWidget(host(repo, const AiSuggestionsPage()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('sugg-hi')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('badge-hi')),
        matching: find.text('High 95%'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('badge-mid')),
        matching: find.text('Medium 75%'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('badge-lo')),
        matching: find.text('Low 40%'),
      ),
      findsOneWidget,
    );
    expect(find.text('Sales quote'), findsWidgets);
  });

  testWidgets(
    'approve removes the card; reject asks for a reason of 3+ characters',
    (WidgetTester tester) async {
      final FakeAiRepository repo = FakeAiRepository()
        ..remote = <Suggestion>[fakeSuggestion('a'), fakeSuggestion('b')];
      await tester.pumpWidget(host(repo, const AiSuggestionsPage()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('approve-a')));
      await tester.pumpAndSettle();
      expect(repo.approved, <String>['a']);
      expect(find.byKey(const Key('sugg-a')), findsNothing);

      await tester.tap(find.byKey(const Key('reject-b')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('reject-reason')), 'ab');
      await tester.tap(find.byKey(const Key('reject-confirm')));
      await tester.pumpAndSettle();
      expect(find.text('Enter at least 3 characters.'), findsOneWidget);
      expect(repo.rejected, isEmpty);

      await tester.enterText(
        find.byKey(const Key('reject-reason')),
        'duplicate',
      );
      await tester.tap(find.byKey(const Key('reject-confirm')));
      await tester.pumpAndSettle();
      expect(repo.rejected.single.reason, 'duplicate');
      expect(find.byKey(const Key('sugg-b')), findsNothing);
      expect(find.byKey(const Key('ai-empty')), findsOneWidget);
    },
  );

  testWidgets('422 shows the problem detail and keeps the card', (
    WidgetTester tester,
  ) async {
    final FakeAiRepository repo = FakeAiRepository()
      ..remote = <Suggestion>[fakeSuggestion('a')]
      ..decisionError = const AiException(
        AiErrorKind.invalid,
        'customer missing',
      );
    await tester.pumpWidget(host(repo, const AiSuggestionsPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('approve-a')));
    await tester.pumpAndSettle();
    expect(
      find.text('The proposal is incomplete: customer missing'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('sugg-a')), findsOneWidget);
  });

  testWidgets(
    'a short capture shows the validation error, a valid one is sent',
    (WidgetTester tester) async {
      final FakeAiRepository repo = FakeAiRepository();
      await tester.pumpWidget(host(repo, const AiSuggestionsPage()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('ai-text')), 'short');
      await tester.tap(find.byKey(const Key('ai-send')));
      await tester.pumpAndSettle();
      expect(find.text('Write at least 10 characters.'), findsOneWidget);
      expect(repo.captures, isEmpty);

      await tester.enterText(
        find.byKey(const Key('ai-text')),
        'quote 2 chairs for Muster AG',
      );
      await tester.tap(find.byKey(const Key('ai-send')));
      await tester.pumpAndSettle();
      expect(repo.captures.single.text, 'quote 2 chairs for Muster AG');
      expect(
        find.text('Sent. The draft is waiting for your review.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'queued captures are announced and the microphone is hidden without a dictation service',
    (WidgetTester tester) async {
      final FakeAiRepository repo = FakeAiRepository()
        ..queue = const CaptureQueue(waiting: 2);
      await tester.pumpWidget(host(repo, const AiSuggestionsPage()));
      await tester.pumpAndSettle();
      expect(find.text('2 captures waiting to be sent'), findsOneWidget);
      expect(find.byKey(const Key('ai-dictate')), findsNothing);
    },
  );

  testWidgets('forbidden role sees a friendly state', (
    WidgetTester tester,
  ) async {
    final FakeAiRepository repo = FakeAiRepository()
      ..refreshError = const AiException(AiErrorKind.forbidden);
    await tester.pumpWidget(host(repo, const AiSuggestionsPage()));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ai-forbidden')), findsOneWidget);
    expect(find.byKey(const Key('ai-send')), findsNothing);
  });

  testWidgets('alert banner shows only for a pending high-priority anomaly', (
    WidgetTester tester,
  ) async {
    final FakeAiRepository none = FakeAiRepository()
      ..remote = <Suggestion>[
        fakeSuggestion('x', kind: 'anomaly'),
        fakeSuggestion('y', priority: 'high'),
      ];
    await tester.pumpWidget(host(none, AiAlertBanner(onOpen: () {})));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ai-alert-banner')), findsNothing);

    final FakeAiRepository one = FakeAiRepository()
      ..remote = <Suggestion>[
        fakeSuggestion(
          'z',
          kind: 'anomaly',
          priority: 'high',
          reasoning: 'Duplicate invoice detected',
        ),
      ];
    bool opened = false;
    await tester.pumpWidget(
      host(one, AiAlertBanner(onOpen: () => opened = true)),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ai-alert-banner')), findsOneWidget);
    expect(find.text('Duplicate invoice detected'), findsOneWidget);
    await tester.tap(find.byKey(const Key('ai-alert-banner')));
    expect(opened, isTrue);
  });
}
