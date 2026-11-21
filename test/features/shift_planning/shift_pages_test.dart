import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:fattura_facile/app/providers.dart';
import 'package:fattura_facile/core/database/app_database.dart';
import 'package:fattura_facile/core/localization/translation_service.dart';
import 'package:fattura_facile/design/ff_tokens.dart';
import 'package:fattura_facile/features/shift_planning/domain/shift_models.dart';
import 'package:fattura_facile/features/shift_planning/domain/shift_repository.dart';
import 'package:fattura_facile/features/shift_planning/presentation/shift_controller.dart';
import 'package:fattura_facile/features/shift_planning/presentation/shift_pages.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'fakes.dart';

void main() {
  late AppDatabase db;
  late FakeShiftRepository repo;
  late FakeCalendarExport export;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = FakeShiftRepository()
      ..myRemote = <Shift>[
        fakeShift(
          'a1',
          date: '2030-03-04',
          tags: <SurchargeTag>[SurchargeTag.night, SurchargeTag.sunday],
        ),
        fakeShift(
          'a2',
          date: '2030-03-05',
          code: 'POM',
          warnings: const <ComplianceIssue>[
            ComplianceIssue(
              severity: IssueSeverity.warning,
              ruleCode: 'CONTRACT.WEEKLY_HOURS_EXCEEDED',
              translationKey:
                  'SHIFT_PLANNING.RULE_CONTRACT_WEEKLY_HOURS_EXCEEDED',
            ),
          ],
        ),
      ]
      ..teamRemote = <Shift>[
        fakeShift(
          't1',
          employeeId: 'e9',
          employeeName: 'Bruno Bianchi',
          date: '2030-03-04',
        ),
      ]
      ..openRemote = <Shift>[
        fakeShift('o1', employeeId: null, date: '2030-03-06'),
      ]
      ..peers = <SwapPeer>[
        SwapPeer(
          employeeId: 'e3',
          name: 'Carla Verdi',
          shifts: <PeerShift>[
            PeerShift(
              id: 'x1',
              date: '2030-03-07',
              templateCode: 'NOT',
              startAt: DateTime.utc(2030, 3, 7, 21),
              endAt: DateTime.utc(2030, 3, 8, 5),
            ),
          ],
        ),
      ];
    export = FakeCalendarExport();
  });

  tearDown(() => db.close());

  Widget host(Widget child) => ProviderScope(
    key: UniqueKey(),
    overrides: [
      shiftRepositoryProvider.overrideWithValue(repo),
      shiftTenantIdProvider.overrideWithValue('t1'),
      calendarExportProvider.overrideWithValue(export),
      translationProvider.overrideWithValue(TranslationService(db, Dio())),
    ],
    child: MaterialApp(theme: ffThemeData(), home: child),
  );

  testWidgets(
    'the calendar lists the shifts by day with the surcharge tags and the warnings',
    (WidgetTester tester) async {
      await tester.pumpWidget(host(const ShiftHomePage()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('shift-day-2030-03-04')), findsOneWidget);
      expect(find.byKey(const Key('shift-card-a1')), findsOneWidget);
      expect(find.byKey(const Key('shift-tag-a1-night')), findsOneWidget);
      expect(find.byKey(const Key('shift-tag-a1-sunday')), findsOneWidget);
      expect(find.text('Night'), findsOneWidget);
      expect(
        find.textContaining('CONTRACT.WEEKLY_HOURS_EXCEEDED'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('shift-card-t1')), findsNothing);
    },
  );

  testWidgets('the team switch adds the colleagues with their names', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(host(const ShiftHomePage()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Team'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('shift-card-t1')), findsOneWidget);
    expect(find.byKey(const Key('shift-who-t1')), findsOneWidget);
    expect(find.text('Bruno Bianchi'), findsOneWidget);
  });

  testWidgets('the export button shares the shifts as an .ics file', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(host(const ShiftHomePage()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('shift-export')));
    await tester.pumpAndSettle();

    expect(export.shared.single.content, contains('BEGIN:VCALENDAR'));
    expect(
      export.shared.single.content,
      contains('UID:a1@fatturafacile.shifts'),
    );
    expect(find.text('Calendar ready'), findsOneWidget);
  });

  testWidgets('an offline agenda is flagged as a copy', (
    WidgetTester tester,
  ) async {
    repo
      ..myCache = <Shift>[fakeShift('c1', date: '2030-03-04')]
      ..refreshError = const ShiftException(ShiftErrorKind.offline);

    await tester.pumpWidget(host(const ShiftHomePage()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('shift-cached')), findsOneWidget);
    expect(find.byKey(const Key('shift-card-c1')), findsOneWidget);
  });

  testWidgets('a role without self-service sees only the message', (
    WidgetTester tester,
  ) async {
    repo.refreshError = const ShiftException(ShiftErrorKind.forbidden);

    await tester.pumpWidget(host(const ShiftHomePage()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('shift-forbidden')), findsOneWidget);
  });

  testWidgets('one tap claims an open shift', (WidgetTester tester) async {
    await tester.pumpWidget(host(const ShiftHomePage()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tab-open')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('claim-o1')), findsOneWidget);
    await tester.tap(find.byKey(const Key('claim-o1')));
    await tester.pumpAndSettle();

    expect(repo.claimed, <String>['o1']);
    expect(find.text('The shift is yours'), findsOneWidget);
    expect(find.byKey(const Key('claim-o1')), findsNothing);
  });

  testWidgets(
    'an offline claim says it is queued and shows the waiting badge',
    (WidgetTester tester) async {
      repo
        ..claimOutcome = const ClaimOutcome(ClaimStatus.queued)
        ..queue = const ClaimQueue(waitingShiftIds: <String>{'o1'});
      await tester.pumpWidget(host(const ShiftHomePage()));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tab-open')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('claim-waiting-o1')), findsOneWidget);
      expect(find.byKey(const Key('claim-o1')), findsNothing);
    },
  );

  testWidgets('a claim parked by the server can be retried or dismissed', (
    WidgetTester tester,
  ) async {
    repo.queue = const ClaimQueue(
      rejected: <RejectedClaim>[
        RejectedClaim(queueUuid: 'q1', shiftId: 'o1', detail: 'Rest too short'),
      ],
    );
    await tester.pumpWidget(host(const ShiftHomePage()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tab-open')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Rest too short'), findsOneWidget);
    await tester.tap(find.byKey(const Key('claim-retry-q1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('claim-dismiss-q1')));
    await tester.pumpAndSettle();

    expect(repo.retried, <String>['q1']);
    expect(repo.dismissed, <String>['q1']);
  });

  testWidgets(
    'a colleague accepts an incoming swap and sees the status of the own requests',
    (WidgetTester tester) async {
      repo.swapRemote = <SwapRequest>[
        fakeSwap(
          's1',
          requester: 'e2',
          peer: 'e1',
          assignment: fakeShift('a-s1', employeeId: 'e2', date: '2030-03-09'),
        ),
        fakeSwap(
          's2',
          requester: 'e1',
          peer: 'e3',
          status: SwapStatus.pendingManagerApproval,
        ),
      ];
      await tester.pumpWidget(host(const ShiftHomePage()));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tab-swaps')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('swap-incoming-s1')), findsOneWidget);
      expect(find.byKey(const Key('swap-mine-s2')), findsOneWidget);
      expect(find.text('Waiting for the manager'), findsOneWidget);

      await tester.tap(find.byKey(const Key('swap-accept-s1')));
      await tester.pumpAndSettle();

      expect(repo.responses.single, (id: 's1', accept: true));
      expect(find.text('Accepted: the manager decides now'), findsOneWidget);
    },
  );

  testWidgets(
    'the wizard walks the four steps and sends a direct swap with a shift in exchange',
    (WidgetTester tester) async {
      await tester.pumpWidget(host(const ShiftHomePage()));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tab-swaps')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('swap-start')));
      await tester.pumpAndSettle();

      expect(find.text('1/4 · Shift'), findsOneWidget);
      await tester.tap(find.byKey(const Key('swap-shift-a1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('swap-next')));
      await tester.pumpAndSettle();

      expect(find.text('2/4 · Colleague'), findsOneWidget);
      await tester.tap(find.byKey(const Key('swap-peer-e3')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('swap-next')));
      await tester.pumpAndSettle();

      expect(find.text('3/4 · Exchange'), findsOneWidget);
      await tester.tap(find.byKey(const Key('swap-counter-x1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('swap-next')));
      await tester.pumpAndSettle();

      expect(find.text('4/4 · Review'), findsOneWidget);
      expect(find.text('Carla Verdi'), findsOneWidget);
      await tester.tap(find.byKey(const Key('swap-send')));
      await tester.pumpAndSettle();

      expect(repo.swapRequests.single, (
        shiftId: 'a1',
        peer: 'e3',
        counter: 'x1',
      ));
      expect(find.byKey(const Key('swap-done')), findsOneWidget);
    },
  );

  testWidgets(
    'the wizard shows the rules a refused swap breaks and stays on the review step',
    (WidgetTester tester) async {
      repo.swapError = const ShiftException(
        ShiftErrorKind.invalid,
        issues: <ComplianceIssue>[
          ComplianceIssue(
            severity: IssueSeverity.blocking,
            ruleCode: 'IT.DAILY_REST_11H',
            translationKey: 'SHIFT_PLANNING.RULE_IT_DAILY_REST_11H',
          ),
        ],
      );
      await tester.pumpWidget(host(const ShiftHomePage()));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tab-swaps')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('swap-start')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('swap-shift-a1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('swap-next')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('swap-broadcast')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('swap-next')));
      await tester.pumpAndSettle();

      expect(find.text('3/4 · Review'), findsNothing);
      expect(find.text('4/4 · Review'), findsOneWidget);
      await tester.tap(find.byKey(const Key('swap-send')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('swap-issue-IT.DAILY_REST_11H')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('swap-done')), findsNothing);
      expect(repo.swapRequests.single, (
        shiftId: 'a1',
        peer: null,
        counter: null,
      ));
    },
  );

  testWidgets('a shift menu starts the wizard with that shift already chosen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(host(const ShiftHomePage()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('shift-menu-a1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Swap shift'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('swap-step')), findsOneWidget);
    await tester.tap(find.byKey(const Key('swap-next')));
    await tester.pumpAndSettle();
    expect(find.text('2/4 · Colleague'), findsOneWidget);
    expect(find.byKey(const Key('swap-peer-e3')), findsOneWidget);
  });
}
