import 'package:fattura_facile/app/providers.dart';
import 'package:fattura_facile/core/network/api_client.dart';
import 'package:fattura_facile/design/ff_tokens.dart';
import 'package:fattura_facile/features/supplier_rebates/domain/supplier_rebate_models.dart';
import 'package:fattura_facile/features/supplier_rebates/presentation/supplier_rebates_controller.dart';
import 'package:fattura_facile/features/supplier_rebates/presentation/supplier_rebates_pages.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'fakes.dart';
import 'fixtures.dart';

void main() {
  late FakeSupplierRebatesRepository repo;

  setUp(() {
    repo = FakeSupplierRebatesRepository()
      ..remoteAgreements = <RebateAgreement>[
        RebateAgreement.fromJson(
          agreementJson(
            contributions: <Map<String, dynamic>>[contributionJson()],
            supplierContractId: 'sc1',
          ),
        ),
      ]
      ..remoteProgress = AgreementProgress.fromJson(progressJson())
      ..remoteProposals = <SettlementProposal>[proposal(status: 'pending_approval')]
      ..contracts = <BlanketContract>[BlanketContract.fromJson(contractJson())]
      ..remoteBalance = BlanketBalance.fromJson(balanceJson())
      ..runs = <AccrualRun>[AccrualRun.fromJson(runJson())];
  });

  Widget host(Widget child, {String language = 'en'}) => ProviderScope(
    key: UniqueKey(),
    overrides: [
      supplierRebatesRepositoryProvider.overrideWithValue(repo),
      supplierRebatesTenantIdProvider.overrideWithValue('t1'),
      requestContextProvider.overrideWithValue(
        RequestContext()..languageCode = language,
      ),
    ],
    child: MaterialApp(theme: ffThemeData(), home: child),
  );

  Finder action(ProposalAction a) => find.byKey(Key('proposal-action-${a.wire}'));

  /// Pumps [page] on a tall surface, so the lazily built lists of the detail pages are built whole.
  Future<void> pumpPage(WidgetTester tester, Widget page) {
    tester.view.physicalSize = const Size(800, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    return tester.pumpWidget(page);
  }

  group('workspace', () {
    testWidgets('lists the agreements with supplier, type and the rebate still to settle', (
      WidgetTester tester,
    ) async {
      await pumpPage(tester, host(const SupplierRebatesHomePage()));
      await tester.pumpAndSettle();

      expect(find.text('Supplier rebates'), findsOneWidget);
      expect(find.byKey(const Key('agreement-card-a1')), findsOneWidget);
      expect(find.textContaining('PFA-2027'), findsWidgets);
      expect(find.textContaining('Alpina AG'), findsOneWidget);
      expect(find.textContaining('Rebate to settle: CHF 1,200.00'), findsOneWidget);
      expect(find.byKey(const Key('rebates-offline')), findsNothing);
    });

    testWidgets('offline it shows the cached copy under an offline banner', (
      WidgetTester tester,
    ) async {
      repo
        ..cacheAgreements = <RebateAgreement>[agreement()]
        ..refreshError = const RebateException(RebateErrorKind.offline);

      await pumpPage(tester, host(const SupplierRebatesHomePage()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('rebates-offline')), findsOneWidget);
      expect(find.byKey(const Key('agreement-card-a1')), findsOneWidget);
    });

    testWidgets('an empty workspace says so', (WidgetTester tester) async {
      repo.remoteAgreements = <RebateAgreement>[];

      await pumpPage(tester, host(const SupplierRebatesHomePage()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('rebates-empty')), findsOneWidget);
    });

    testWidgets('the tabs show the proposals and the blanket agreements', (
      WidgetTester tester,
    ) async {
      await pumpPage(tester, host(const SupplierRebatesHomePage()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('rebates-tab-proposals')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('proposal-card-p1')), findsOneWidget);
      expect(find.text('Pending approval'), findsOneWidget);

      await tester.tap(find.byKey(const Key('rebates-tab-blankets')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('contract-card-sc1')), findsOneWidget);
      expect(find.textContaining('RV-2027-1'), findsOneWidget);
    });

    testWidgets('speaks the language of the session, with Swiss separators', (
      WidgetTester tester,
    ) async {
      await pumpPage(tester, host(const SupplierRebatesHomePage(), language: 'de-CH'));
      await tester.pumpAndSettle();

      expect(find.text('Lieferantenrückvergütungen'), findsOneWidget);
      expect(find.textContaining('Rückvergütung zur Abrechnung: CHF 1’200.00'), findsOneWidget);
    });
  });

  group('agreement detail', () {
    testWidgets('shows the tier progress, the ladder, contributions and accrual runs', (
      WidgetTester tester,
    ) async {
      await pumpPage(tester, host(const AgreementDetailPage(agreementId: 'a1')));
      await tester.pumpAndSettle();

      expect(find.text('PFA-2027'), findsOneWidget);
      expect(find.byKey(const Key('rebate-progress-card')), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('rebate-distance'))).data,
        'CHF 130,000.00',
      );
      expect(find.byKey(const Key('rebate-tier-2')), findsOneWidget);
      expect(find.byKey(const Key('contribution-k1')), findsOneWidget);
      expect(find.byKey(const Key('run-r1')), findsOneWidget);
      expect(find.byKey(const Key('agreement-proposal-p1')), findsOneWidget);
      expect(find.byKey(const Key('rebate-recomputed')), findsNothing);
    });

    testWidgets('offline it recomputes from the last known volume and says so', (
      WidgetTester tester,
    ) async {
      repo
        ..cacheAgreements = <RebateAgreement>[agreement()]
        ..cacheProgress = AgreementProgress.fromJson(progressJson(volume: '260000.00'))
        ..refreshError = const RebateException(RebateErrorKind.offline);

      await pumpPage(tester, host(const AgreementDetailPage(agreementId: 'a1')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('rebates-offline')), findsOneWidget);
      expect(find.byKey(const Key('rebate-recomputed')), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('rebate-distance'))).data,
        'CHF 240,000.00',
      );
    });

    testWidgets('a fixed bonus agreement shows the bonus card instead of the ladder', (
      WidgetTester tester,
    ) async {
      repo
        ..remoteAgreements = <RebateAgreement>[agreement(type: 'fixed_bonus')]
        ..remoteProgress = AgreementProgress.fromJson(progressJson(volume: '30000.00'));

      await pumpPage(tester, host(const AgreementDetailPage(agreementId: 'a1')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('rebate-bonus-card')), findsOneWidget);
      expect(find.byKey(const Key('rebate-progress-card')), findsNothing);
      expect(find.byKey(const Key('rebate-tier-0')), findsNothing);
      expect(
        tester.widget<Text>(find.byKey(const Key('rebate-distance'))).data,
        'CHF 20,000.00',
      );
    });
  });

  group('proposal detail', () {
    testWidgets('shows the totals and the analytical breakdown', (WidgetTester tester) async {
      await pumpPage(tester, host(const ProposalDetailPage(proposalId: 'p1')));
      await tester.pumpAndSettle();

      expect(tester.widget<Text>(find.byKey(const Key('proposal-net'))).data, 'CHF 2,400.00');
      expect(tester.widget<Text>(find.byKey(const Key('proposal-gross'))).data, 'CHF 2,594.40');
      expect(find.byKey(const Key('proposal-line-0')), findsOneWidget);
      expect(find.byKey(const Key('proposal-line-1')), findsOneWidget);
      expect(find.textContaining('Credit note · CN-1'), findsOneWidget);
      expect(find.text('Set-off in the payables schedule'), findsOneWidget);
    });

    testWidgets('approving asks for a confirmation, then sends the action and confirms', (
      WidgetTester tester,
    ) async {
      repo.statusAfterAction = ProposalStatus.approved;
      await pumpPage(tester, host(const ProposalDetailPage(proposalId: 'p1')));
      await tester.pumpAndSettle();
      expect(action(ProposalAction.approve), findsOneWidget);
      expect(action(ProposalAction.submit), findsNothing);

      await tester.tap(action(ProposalAction.approve));
      await tester.pumpAndSettle();
      expect(find.text('Approve the settlement proposal?'), findsOneWidget);
      expect(repo.acted, isEmpty);

      await tester.tap(find.byKey(const Key('rebate-confirm')));
      await tester.pumpAndSettle();

      expect(repo.acted.single.action, ProposalAction.approve);
      expect(repo.acted.single.version, 2);
      expect(find.text('Done'), findsOneWidget);
      // The proposal is now approved: only cancel is left, with the hint about the web.
      expect(action(ProposalAction.approve), findsNothing);
      expect(action(ProposalAction.cancel), findsOneWidget);
      expect(find.byKey(const Key('proposal-execute-on-web')), findsOneWidget);
    });

    testWidgets('dismissing the confirmation sends nothing', (WidgetTester tester) async {
      await pumpPage(tester, host(const ProposalDetailPage(proposalId: 'p1')));
      await tester.pumpAndSettle();

      await tester.tap(action(ProposalAction.cancel));
      await tester.pumpAndSettle();
      expect(find.textContaining('accruals become open again'), findsOneWidget);
      await tester.tap(find.byKey(const Key('rebate-dialog-dismiss')));
      await tester.pumpAndSettle();

      expect(repo.acted, isEmpty);
    });

    testWidgets('offline the action is queued: notice, waiting row and locked buttons', (
      WidgetTester tester,
    ) async {
      repo.nextStatus = ActionStatus.queued;
      await pumpPage(tester, host(const ProposalDetailPage(proposalId: 'p1')));
      await tester.pumpAndSettle();

      await tester.tap(action(ProposalAction.approve));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('rebate-confirm')));
      await tester.pumpAndSettle();

      expect(find.textContaining('No connection: it is sent as soon as you are online'), findsOneWidget);
      expect(find.text('Waiting to be sent'), findsOneWidget);
      expect(tester.widget<FilledButton>(action(ProposalAction.approve)).onPressed, isNull);
    });

    testWidgets('a rejected queued action can be retried or dismissed', (WidgetTester tester) async {
      repo.pending = <PendingAction>[
        const PendingAction(
          queueUuid: 'q9',
          proposalId: 'p1',
          action: ProposalAction.approve,
          rejected: true,
          detail: 'Version conflict',
        ),
      ];
      await pumpPage(tester, host(const ProposalDetailPage(proposalId: 'p1')));
      await tester.pumpAndSettle();

      expect(find.text('Version conflict'), findsOneWidget);
      expect(find.byKey(const Key('pending-retry-q9')), findsOneWidget);

      await tester.tap(find.byKey(const Key('pending-dismiss-q9')));
      await tester.pumpAndSettle();

      expect(repo.dismissed, <String>['q9']);
      expect(find.text('Version conflict'), findsNothing);
    });

    for (final (String status, List<String> expected) in <(String, List<String>)>[
      ('draft', <String>['submit', 'cancel']),
      ('pending_approval', <String>['approve', 'cancel']),
      ('approved', <String>['cancel']),
      ('settled', <String>[]),
      ('cancelled', <String>[]),
    ]) {
      testWidgets('status $status offers $expected', (WidgetTester tester) async {
        repo.remoteProposals = <SettlementProposal>[proposal(status: status)];
        await pumpPage(tester, host(const ProposalDetailPage(proposalId: 'p1')));
        await tester.pumpAndSettle();

        for (final ProposalAction a in ProposalAction.values) {
          expect(
            action(a),
            expected.contains(a.wire) ? findsOneWidget : findsNothing,
            reason: '$status / ${a.wire}',
          );
        }
      });
    }
  });

  group('blanket balance', () {
    testWidgets('shows the alerts, the meters and the call-off lines', (WidgetTester tester) async {
      await pumpPage(tester, host(const BlanketBalancePage(contractId: 'sc1')));
      await tester.pumpAndSettle();

      expect(find.textContaining('RV-2027-1'), findsOneWidget);
      expect(find.byKey(const Key('balance-alert-ceiling_near')), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(const Key('balance-remaining'))).data, 'CHF 15,000.00');
      expect(find.byKey(const Key('balance-line-0')), findsOneWidget);
      expect(find.text('Steel plate 10mm'), findsOneWidget);
    });

    testWidgets('offline it shows the cached balance under the offline banner', (
      WidgetTester tester,
    ) async {
      repo
        ..cacheBalance = BlanketBalance.fromJson(balanceJson(exceeded: true))
        ..refreshError = const RebateException(RebateErrorKind.offline);

      await pumpPage(tester, host(const BlanketBalancePage(contractId: 'sc1')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('rebates-offline')), findsOneWidget);
      expect(find.byKey(const Key('balance-alert-ceiling_exceeded')), findsOneWidget);
    });
  });
}
