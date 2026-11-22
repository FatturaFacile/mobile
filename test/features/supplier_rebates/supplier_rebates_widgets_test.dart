import 'package:fattura_facile/design/ff_tokens.dart';
import 'package:fattura_facile/features/supplier_rebates/domain/rebate_decimal.dart';
import 'package:fattura_facile/features/supplier_rebates/domain/supplier_rebate_models.dart';
import 'package:fattura_facile/features/supplier_rebates/domain/tier_progress_calculator.dart';
import 'package:fattura_facile/features/supplier_rebates/presentation/supplier_rebates_widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'fixtures.dart';

Widget host(Widget child) => MaterialApp(
  theme: ffThemeData(),
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

String textOf(WidgetTester tester, String key) =>
    tester.widget<Text>(find.byKey(Key(key))).data!;

double barValue(WidgetTester tester) => tester
    .widget<LinearProgressIndicator>(
      find.descendant(
        of: find.byKey(const Key('rebate-progress-bar')),
        matching: find.byType(LinearProgressIndicator),
      ),
    )
    .value!;

TierProgressCard card(
  String volume, {
  TierMode mode = TierMode.retroactive,
  bool offline = false,
}) => TierProgressCard(
  progress: TierProgressCalculator.progress(scale(), d(volume), mode),
  volume: d(volume),
  currency: 'CHF',
  languageCode: 'en',
  recomputedOffline: offline,
);

void main() {
  group('TierProgressCard', () {
    testWidgets('shows the tier, the bar inside the band, the distance and the projected gain', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(host(card('120000')));

      expect(textOf(tester, 'rebate-volume'), 'CHF 120,000.00');
      expect(textOf(tester, 'rebate-accrued'), 'CHF 2,400.00');
      expect(textOf(tester, 'rebate-current-tier'), '2%');
      expect(textOf(tester, 'rebate-progress-percent'), '13.33%');
      expect(textOf(tester, 'rebate-next-tier'), 'CHF 250,000.00 · 3%');
      expect(textOf(tester, 'rebate-distance'), 'CHF 130,000.00');
      expect(textOf(tester, 'rebate-projected'), 'CHF 8,000.00');
      expect(textOf(tester, 'rebate-projected-gain'), '+CHF 5,600.00');
      expect(barValue(tester), closeTo(0.1333, 0.001));
      expect(find.byKey(const Key('rebate-top-tier')), findsNothing);
    });

    testWidgets('below the first tier it says so and counts down to tier one', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(host(card('50000')));

      expect(textOf(tester, 'rebate-current-tier'), 'No tier reached yet');
      expect(textOf(tester, 'rebate-distance'), 'CHF 50,000.00');
      expect(textOf(tester, 'rebate-projected-gain'), '+CHF 2,000.00');
      expect(textOf(tester, 'rebate-accrued'), 'CHF 0.00');
      expect(barValue(tester), closeTo(0.5, 0.001));
    });

    testWidgets('on the top tier there is no distance, only the congratulation', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(host(card('600000')));

      expect(textOf(tester, 'rebate-top-tier'), 'Top tier reached');
      expect(find.byKey(const Key('rebate-distance')), findsNothing);
      expect(find.byKey(const Key('rebate-next-tier')), findsNothing);
      expect(find.byKey(const Key('rebate-projected-gain')), findsNothing);
      expect(textOf(tester, 'rebate-accrued'), 'CHF 25,000.00');
      expect(barValue(tester), 1.0);
    });

    testWidgets('the incremental mode changes the accrued rebate and the gain', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(host(card('120000', mode: TierMode.incremental)));

      expect(textOf(tester, 'rebate-accrued'), 'CHF 400.00');
      expect(textOf(tester, 'rebate-projected-gain'), '+CHF 3,100.00');
    });

    testWidgets('notes when the figures were computed on the phone', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(host(card('120000', offline: true)));

      expect(find.byKey(const Key('rebate-recomputed')), findsOneWidget);
    });

    testWidgets('formats money with the Swiss separators of the locale', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(
          TierProgressCard(
            progress: TierProgressCalculator.progress(scale(), d('120000'), TierMode.retroactive),
            volume: d('120000'),
            currency: 'CHF',
            languageCode: 'de-CH',
          ),
        ),
      );

      expect(textOf(tester, 'rebate-volume'), 'CHF 120’000.00');
    });
  });

  group('TierLadder', () {
    testWidgets('marks the reached tiers and highlights the current one', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(TierLadder(tiers: scale(), volume: d('260000'), currency: 'CHF', languageCode: 'en')),
      );

      expect(find.byKey(const Key('rebate-tier-0')), findsOneWidget);
      expect(find.byKey(const Key('rebate-tier-2')), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsNWidgets(2));
      expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
      expect(find.textContaining('3% + CHF 500.00'), findsOneWidget);
      expect(find.textContaining('no upper limit'), findsOneWidget);
    });
  });

  group('BonusProgressCard', () {
    BonusProgressCard bonusCard(String volume) => BonusProgressCard(
      bonus: TierProgressCalculator.bonusProgress(d('50000'), d('2500'), d(volume)),
      volume: d(volume),
      currency: 'CHF',
      languageCode: 'en',
    );

    testWidgets('below the target it shows the distance', (WidgetTester tester) async {
      await tester.pumpWidget(host(bonusCard('30000')));

      expect(textOf(tester, 'rebate-distance'), 'CHF 20,000.00');
      expect(find.byKey(const Key('rebate-target-reached')), findsNothing);
      expect(barValue(tester), closeTo(0.6, 0.001));
    });

    testWidgets('at the target it shows the bonus as reached', (WidgetTester tester) async {
      await tester.pumpWidget(host(bonusCard('50000')));

      expect(textOf(tester, 'rebate-target-reached'), 'Target reached');
      expect(find.byKey(const Key('rebate-distance')), findsNothing);
      expect(barValue(tester), 1.0);
    });
  });

  group('ProposalActionButtons', () {
    Future<List<ProposalAction>> pumpAndTap(
      WidgetTester tester,
      ProposalStatus status, {
      Set<ProposalAction> pending = const <ProposalAction>{},
      bool busy = false,
    }) async {
      final List<ProposalAction> tapped = <ProposalAction>[];
      await tester.pumpWidget(
        host(
          ProposalActionButtons(
            status: status,
            languageCode: 'en',
            pending: pending,
            busy: busy,
            onAction: tapped.add,
          ),
        ),
      );
      return tapped;
    }

    Finder button(ProposalAction a) => find.byKey(Key('proposal-action-${a.wire}'));

    testWidgets('a draft offers submit and cancel', (WidgetTester tester) async {
      final List<ProposalAction> tapped = await pumpAndTap(tester, ProposalStatus.draft);

      expect(button(ProposalAction.submit), findsOneWidget);
      expect(button(ProposalAction.cancel), findsOneWidget);
      expect(button(ProposalAction.approve), findsNothing);
      expect(find.text('Submit for approval'), findsOneWidget);

      await tester.tap(button(ProposalAction.submit));
      await tester.tap(button(ProposalAction.cancel));
      expect(tapped, <ProposalAction>[ProposalAction.submit, ProposalAction.cancel]);
    });

    testWidgets('pending approval offers approve and cancel', (WidgetTester tester) async {
      final List<ProposalAction> tapped = await pumpAndTap(tester, ProposalStatus.pendingApproval);

      expect(button(ProposalAction.approve), findsOneWidget);
      expect(button(ProposalAction.cancel), findsOneWidget);
      expect(button(ProposalAction.submit), findsNothing);

      await tester.tap(button(ProposalAction.approve));
      expect(tapped, <ProposalAction>[ProposalAction.approve]);
    });

    testWidgets('approved offers only cancel and points to the web for the execution', (
      WidgetTester tester,
    ) async {
      await pumpAndTap(tester, ProposalStatus.approved);

      expect(button(ProposalAction.cancel), findsOneWidget);
      expect(button(ProposalAction.approve), findsNothing);
      expect(button(ProposalAction.submit), findsNothing);
      expect(find.byKey(const Key('proposal-execute-on-web')), findsOneWidget);
      expect(find.textContaining('xecute'), findsOneWidget);
    });

    testWidgets('settled and cancelled offer no button at all', (WidgetTester tester) async {
      for (final ProposalStatus s in <ProposalStatus>[ProposalStatus.settled, ProposalStatus.cancelled]) {
        await pumpAndTap(tester, s);

        expect(find.byType(FilledButton), findsNothing);
        expect(find.byType(OutlinedButton), findsNothing);
        expect(find.byKey(const Key('proposal-execute-on-web')), findsNothing);
      }
    });

    testWidgets('an action waiting in the outbox disables the buttons', (WidgetTester tester) async {
      final List<ProposalAction> tapped = await pumpAndTap(
        tester,
        ProposalStatus.pendingApproval,
        pending: <ProposalAction>{ProposalAction.approve},
      );

      expect(tester.widget<FilledButton>(button(ProposalAction.approve)).onPressed, isNull);
      expect(tester.widget<OutlinedButton>(button(ProposalAction.cancel)).onPressed, isNull);

      await tester.tap(button(ProposalAction.approve), warnIfMissed: false);
      expect(tapped, isEmpty);
    });

    testWidgets('a running request disables the buttons', (WidgetTester tester) async {
      await pumpAndTap(tester, ProposalStatus.draft, busy: true);

      expect(tester.widget<FilledButton>(button(ProposalAction.submit)).onPressed, isNull);
    });
  });

  group('BalanceMeters', () {
    testWidgets('a near ceiling shows a warning and the remaining amount', (WidgetTester tester) async {
      await tester.pumpWidget(
        host(BalanceMeters(balance: BlanketBalance.fromJson(balanceJson()), languageCode: 'en')),
      );

      expect(find.byKey(const Key('balance-alert-ceiling_near')), findsOneWidget);
      expect(find.text('The ceiling is almost used up'), findsOneWidget);
      expect(textOf(tester, 'balance-remaining'), 'CHF 15,000.00');
      expect(find.byKey(const Key('balance-ceiling-bar')), findsOneWidget);
      expect(textOf(tester, 'balance-shortfall'), 'CHF 0.00');
    });

    testWidgets('an exceeded ceiling shows the critical alert', (WidgetTester tester) async {
      await tester.pumpWidget(
        host(
          BalanceMeters(balance: BlanketBalance.fromJson(balanceJson(exceeded: true)), languageCode: 'en'),
        ),
      );

      expect(find.byKey(const Key('balance-alert-ceiling_exceeded')), findsOneWidget);
      expect(find.text('Ceiling exceeded'), findsOneWidget);
      expect(textOf(tester, 'balance-remaining'), 'CHF -5,000.00');
    });

    testWidgets('a contract without ceiling says so', (WidgetTester tester) async {
      final Map<String, dynamic> json = balanceJson()
        ..['ceiling_amount'] = '0.00'
        ..['alerts'] = <dynamic>[];

      await tester.pumpWidget(
        host(BalanceMeters(balance: BlanketBalance.fromJson(json), languageCode: 'en')),
      );

      expect(find.byKey(const Key('balance-no-ceiling')), findsOneWidget);
      expect(find.byKey(const Key('balance-ceiling-bar')), findsNothing);
    });
  });

  testWidgets('RebateBar clamps the percentage to the bar', (WidgetTester tester) async {
    const Color blue = Color(0xFF2196F3);
    await tester.pumpWidget(
      host(RebateBar(key: const Key('rebate-progress-bar'), percent: Dec.zero, color: blue)),
    );
    expect(barValue(tester), 0.0);

    await tester.pumpWidget(
      host(RebateBar(key: const Key('rebate-progress-bar'), percent: d('250'), color: blue)),
    );
    expect(barValue(tester), 1.0);
  });
}
