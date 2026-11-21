import 'package:fattura_facile/features/ai_cognitive/domain/ai_models.dart';
import 'package:fattura_facile/features/ai_cognitive/domain/ai_repository.dart';
import 'package:fattura_facile/features/ai_cognitive/presentation/ai_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  late FakeAiRepository repo;
  late ProviderContainer container;

  AiSuggestionsController controller() =>
      container.read(aiSuggestionsProvider.notifier);
  AiSuggestionsState state() => container.read(aiSuggestionsProvider);

  setUp(() {
    repo = FakeAiRepository()
      ..remote = <Suggestion>[fakeSuggestion('a'), fakeSuggestion('b')];
    container = ProviderContainer(
      overrides: [
        aiRepositoryProvider.overrideWithValue(repo),
        aiTenantIdProvider.overrideWithValue('t1'),
      ],
    );
    addTearDown(container.dispose);
    container.listen(aiSuggestionsProvider, (_, _) {});
  });

  test('load shows the refreshed queue', () async {
    await controller().load();
    expect(state().suggestions.map((Suggestion s) => s.id), <String>['a', 'b']);
    expect(state().loading, isFalse);
    expect(state().fromCache, isFalse);
    expect(state().error, isNull);
  });

  test('offline load keeps the cached list and reports the error', () async {
    repo
      ..cache = <Suggestion>[fakeSuggestion('c')]
      ..refreshError = const AiException(AiErrorKind.offline);
    await controller().load();
    expect(state().suggestions.single.id, 'c');
    expect(state().fromCache, isTrue);
    expect(state().error?.kind, AiErrorKind.offline);
  });

  test('forbidden empties the list', () async {
    repo
      ..cache = <Suggestion>[fakeSuggestion('c')]
      ..refreshError = const AiException(AiErrorKind.forbidden);
    await controller().load();
    expect(state().forbidden, isTrue);
    expect(state().suggestions, isEmpty);
  });

  test('approve removes the suggestion', () async {
    await controller().load();
    expect(await controller().approve('a'), isNull);
    expect(repo.approved, <String>['a']);
    expect(state().suggestions.map((Suggestion s) => s.id), <String>['b']);
    expect(state().busyIds, isEmpty);
  });

  test('reject needs a reason of at least 3 characters', () async {
    await controller().load();
    final AiException? tooShort = await controller().reject('a', ' ab ');
    expect(tooShort?.kind, AiErrorKind.invalid);
    expect(repo.rejected, isEmpty);
    expect(state().suggestions, hasLength(2));

    expect(await controller().reject('a', 'wrong customer'), isNull);
    expect(repo.rejected.single.reason, 'wrong customer');
    expect(state().suggestions.map((Suggestion s) => s.id), <String>['b']);
  });

  test('409 drops the suggestion and reports alreadyDecided', () async {
    await controller().load();
    repo.decisionError = const AiException(AiErrorKind.alreadyDecided);
    final AiException? e = await controller().approve('a');
    expect(e?.kind, AiErrorKind.alreadyDecided);
    expect(state().suggestions.map((Suggestion s) => s.id), <String>['b']);
    expect(state().busyIds, isEmpty);
  });

  test('422 keeps the suggestion pending with the detail available', () async {
    await controller().load();
    repo.decisionError = const AiException(
      AiErrorKind.invalid,
      'customer missing',
    );
    final AiException? e = await controller().approve('a');
    expect(e?.kind, AiErrorKind.invalid);
    expect(e?.detail, 'customer missing');
    expect(state().suggestions.map((Suggestion s) => s.id), <String>['a', 'b']);
    expect(state().busyIds, isEmpty);
  });

  test(
    'alert banner is chosen only from pending high-priority anomalies',
    () async {
      repo.remote = <Suggestion>[
        fakeSuggestion('q', priority: 'high'),
        fakeSuggestion('n', kind: 'anomaly'),
      ];
      await controller().load();
      expect(state().alert, isNull);

      repo.remote = <Suggestion>[
        fakeSuggestion('n', kind: 'anomaly'),
        fakeSuggestion('h', kind: 'anomaly', priority: 'high'),
      ];
      await controller().load();
      expect(state().alert?.id, 'h');

      await controller().approve('h');
      expect(state().alert, isNull);
    },
  );

  test(
    'capture refreshes the queue when sent and reports the outcome',
    () async {
      final CaptureOutcome out = await controller().capture(
        CaptureKind.salesQuote,
        'quote 2 chairs for Muster AG',
      );
      expect(out.status, CaptureStatus.sent);
      expect(repo.captures.single.kind, CaptureKind.salesQuote);
      expect(repo.refreshCount, 1);
    },
  );

  test(
    'queued capture does not refresh and exposes the waiting count',
    () async {
      repo
        ..captureOutcome = const CaptureOutcome(CaptureStatus.queued)
        ..queue = const CaptureQueue(waiting: 1);
      final CaptureOutcome out = await controller().capture(
        CaptureKind.contact,
        'new contact Anna Rossi',
      );
      expect(out.status, CaptureStatus.queued);
      expect(repo.refreshCount, 0);
      expect(state().queue.waiting, 1);
    },
  );

  test('too short text is reported without sending', () async {
    final CaptureOutcome out = await controller().capture(
      CaptureKind.contact,
      'short',
    );
    expect(out.status, CaptureStatus.tooShort);
    expect(repo.captures, isEmpty);
  });
}
