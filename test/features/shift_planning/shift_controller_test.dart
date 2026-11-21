import 'package:fattura_facile/features/shift_planning/domain/shift_models.dart';
import 'package:fattura_facile/features/shift_planning/domain/shift_repository.dart';
import 'package:fattura_facile/features/shift_planning/presentation/shift_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  late FakeShiftRepository repo;
  late FakeCalendarExport export;
  late ProviderContainer container;

  setUp(() {
    repo = FakeShiftRepository()
      ..myRemote = <Shift>[
        fakeShift('b', date: '2026-12-08'),
        fakeShift('a', tags: <SurchargeTag>[SurchargeTag.night]),
      ]
      ..teamRemote = <Shift>[
        fakeShift(
          't',
          employeeId: 'e9',
          employeeName: 'Bruno Bianchi',
          date: '2026-12-07',
        ),
      ];
    export = FakeCalendarExport();
    container = ProviderContainer(
      overrides: [
        shiftRepositoryProvider.overrideWithValue(repo),
        shiftTenantIdProvider.overrideWithValue('t1'),
        calendarExportProvider.overrideWithValue(export),
      ],
    );
    addTearDown(container.dispose);
    container
      ..listen(shiftCalendarProvider, (_, _) {})
      ..listen(openShiftsProvider, (_, _) {})
      ..listen(swapWizardProvider, (_, _) {})
      ..listen(incomingSwapsProvider, (_, _) {});
  });

  group('calendar', () {
    ShiftCalendarController controller() =>
        container.read(shiftCalendarProvider.notifier);
    ShiftCalendarState state() => container.read(shiftCalendarProvider);

    test(
      'load shows the refreshed shifts, oldest first, and knows the employee',
      () async {
        await controller().load();

        expect(state().visible.map((Shift s) => s.id), <String>['a', 'b']);
        expect(state().loading, isFalse);
        expect(state().fromCache, isFalse);
        expect(state().myEmployeeId, 'e1');
      },
    );

    test(
      'offline load keeps the cached agenda and reports the error',
      () async {
        repo
          ..myCache = <Shift>[fakeShift('c')]
          ..refreshError = const ShiftException(ShiftErrorKind.offline);

        await controller().load();

        expect(state().mine.single.id, 'c');
        expect(state().fromCache, isTrue);
        expect(state().error?.kind, ShiftErrorKind.offline);
      },
    );

    test('forbidden empties the agenda', () async {
      repo
        ..myCache = <Shift>[fakeShift('c')]
        ..refreshError = const ShiftException(ShiftErrorKind.forbidden);

      await controller().load();

      expect(state().forbidden, isTrue);
      expect(state().mine, isEmpty);
    });

    test('the team toggle loads the colleagues once and merges them into the agenda', () async {
      await controller().load();
      expect(state().visible, hasLength(2));

      await controller().setShowTeam(true);

      expect(state().visible.map((Shift s) => s.id), <String>['a', 't', 'b']);

      await controller().setShowTeam(false);
      expect(state().visible, hasLength(2));
    });

    test(
      'exports only the shifts that have not ended as an .ics file',
      () async {
        repo.myRemote = <Shift>[
          fakeShift('old', date: '2020-01-06'),
          fakeShift('new', date: '2030-01-07'),
        ];
        await controller().load();

        await controller().exportIcs('en', now: DateTime.utc(2026, 12, 1));

        expect(export.shared.single.fileName, 'shifts.ics');
        expect(
          export.shared.single.content,
          contains('UID:new@fatturafacile.shifts'),
        );
        expect(export.shared.single.content, isNot(contains('UID:old@')));
      },
    );

    test('opens the Google Calendar page of a shift', () async {
      final bool opened = await controller().addToGoogleCalendar(
        fakeShift('a'),
        'en',
      );

      expect(opened, isTrue);
      expect(export.opened.single.host, 'calendar.google.com');
    });
  });

  group('open shifts', () {
    OpenShiftsController controller() =>
        container.read(openShiftsProvider.notifier);
    OpenShiftsState state() => container.read(openShiftsProvider);

    setUp(() {
      repo.openRemote = <Shift>[
        fakeShift('o1', employeeId: null),
        fakeShift('o2', employeeId: null),
      ];
    });

    test('load lists the shifts the employee qualifies for', () async {
      await controller().load();

      expect(state().shifts.map((Shift s) => s.id), <String>['o1', 'o2']);
    });

    test(
      'a claim accepted at once removes the shift and refreshes the own agenda',
      () async {
        await controller().load();

        final ClaimOutcome outcome = await controller().claim('o1');

        expect(outcome.status, ClaimStatus.claimed);
        expect(state().shifts.map((Shift s) => s.id), <String>['o2']);
        expect(state().busyIds, isEmpty);
        expect(container.read(shiftCalendarProvider).mine, isNotEmpty);
      },
    );

    test('an offline claim stays in the list marked as waiting', () async {
      repo
        ..claimOutcome = const ClaimOutcome(ClaimStatus.queued)
        ..queue = const ClaimQueue(waitingShiftIds: <String>{'o1'});
      await controller().load();

      final ClaimOutcome outcome = await controller().claim('o1');

      expect(outcome.status, ClaimStatus.queued);
      expect(state().shifts, hasLength(2));
      expect(state().queue.waitingShiftIds, <String>{'o1'});
    });

    test('a refused claim keeps the shift and shows the parked claim for retry and dismissal', () async {
      repo
        ..claimOutcome = const ClaimOutcome(
          ClaimStatus.rejected,
          detail: 'Rest too short',
        )
        ..queue = const ClaimQueue(
          rejected: <RejectedClaim>[
            RejectedClaim(
              queueUuid: 'q1',
              shiftId: 'o1',
              detail: 'Rest too short',
            ),
          ],
        );
      await controller().load();

      await controller().claim('o1');
      await controller().retryClaim('q1');
      await controller().dismissClaim('q1');

      expect(state().shifts, hasLength(2));
      expect(state().queue.rejected.single.detail, 'Rest too short');
      expect(repo.retried, <String>['q1']);
      expect(repo.dismissed, <String>['q1']);
    });

    test('offline keeps the cached marketplace', () async {
      repo
        ..openCache = <Shift>[fakeShift('cached', employeeId: null)]
        ..refreshError = const ShiftException(ShiftErrorKind.offline);

      await controller().load();

      expect(state().shifts.single.id, 'cached');
      expect(state().fromCache, isTrue);
    });
  });

  group('swap wizard', () {
    SwapWizardController controller() =>
        container.read(swapWizardProvider.notifier);
    SwapWizardState state() => container.read(swapWizardProvider);

    setUp(() {
      repo.peers = <SwapPeer>[
        SwapPeer(
          employeeId: 'e3',
          name: 'Bruno Bianchi',
          shifts: <PeerShift>[
            PeerShift(
              id: 'x1',
              date: '2026-12-08',
              templateCode: 'POM',
              startAt: DateTime.utc(2026, 12, 8, 13),
              endAt: DateTime.utc(2026, 12, 8, 21),
            ),
          ],
        ),
      ];
    });

    test('selecting the shift loads the eligible colleagues and unlocks the next step', () async {
      expect(state().canAdvance, isFalse);

      await controller().selectShift(fakeShift('a1'));

      expect(state().peers.single.name, 'Bruno Bianchi');
      expect(state().canAdvance, isTrue);
    });

    test('a direct swap goes shift, colleague, exchange, review and sends the colleague and the counter shift', () async {
      await controller().selectShift(fakeShift('a1'));
      controller().next();
      expect(state().step, swapStepColleague);
      expect(state().canAdvance, isFalse);

      controller()
        ..choosePeer('e3')
        ..next();
      expect(state().step, swapStepExchange);

      controller()
        ..chooseCounter('x1')
        ..next();
      expect(state().step, swapStepReview);

      final SwapRequest? sent = await controller().submit();

      expect(sent, isNotNull);
      expect(repo.swapRequests.single, (
        shiftId: 'a1',
        peer: 'e3',
        counter: 'x1',
      ));
    });

    test(
      'a broadcast skips the exchange step and sends no colleague',
      () async {
        await controller().selectShift(fakeShift('a1'));
        controller()
          ..next()
          ..chooseBroadcast()
          ..next();

        expect(state().step, swapStepReview);

        await controller().submit();
        controller().back();

        expect(repo.swapRequests.single, (
          shiftId: 'a1',
          peer: null,
          counter: null,
        ));
        expect(state().step, swapStepColleague);
      },
    );

    test('back walks the steps in reverse', () async {
      await controller().selectShift(fakeShift('a1'));
      controller()
        ..next()
        ..choosePeer('e3')
        ..next()
        ..next();
      expect(state().step, swapStepReview);

      controller().back();
      expect(state().step, swapStepExchange);
      controller().back();
      expect(state().step, swapStepColleague);
      controller().back();
      expect(state().step, swapStepShift);
    });

    test('a refusal of the server keeps the wizard on the review step with the findings', () async {
      repo.swapError = const ShiftException(
        ShiftErrorKind.invalid,
        issues: <ComplianceIssue>[
          ComplianceIssue(
            severity: IssueSeverity.blocking,
            ruleCode: 'IT.DAILY_REST_11H',
            translationKey: 'K',
          ),
        ],
      );
      await controller().selectShift(fakeShift('a1'));
      controller()
        ..next()
        ..choosePeer('e3')
        ..next()
        ..next();

      final SwapRequest? sent = await controller().submit();

      expect(sent, isNull);
      expect(state().step, swapStepReview);
      expect(state().error?.issues.single.ruleCode, 'IT.DAILY_REST_11H');
      expect(state().submitting, isFalse);
      expect(state().result, isNull);
    });

    test(
      'no colleagues, a failed lookup and a reset leave the wizard usable',
      () async {
        repo.peersError = const ShiftException(ShiftErrorKind.offline);

        await controller().selectShift(fakeShift('a1'));

        expect(state().error?.kind, ShiftErrorKind.offline);
        expect(state().peers, isEmpty);

        controller().reset();
        expect(state().shift, isNull);
        expect(state().step, swapStepShift);
      },
    );
  });

  group('swap inbox', () {
    IncomingSwapsController controller() =>
        container.read(incomingSwapsProvider.notifier);
    IncomingSwapsState state() => container.read(incomingSwapsProvider);

    setUp(() {
      repo.swapRemote = <SwapRequest>[
        fakeSwap('s1'),
        fakeSwap('s2', requester: 'e1', peer: 'e3'),
        fakeSwap('s3', status: SwapStatus.approved),
      ];
    });

    test(
      'separates the requests waiting for me from the ones I made',
      () async {
        await controller().load();

        expect(state().incoming('e1').map((SwapRequest s) => s.id), <String>[
          's1',
        ]);
        expect(state().mine('e1').map((SwapRequest s) => s.id), <String>['s2']);
      },
    );

    test('accepting answers the server and reloads the list', () async {
      await controller().load();

      final ShiftException? error = await controller().respond(
        's1',
        accept: true,
      );

      expect(error, isNull);
      expect(repo.responses.single, (id: 's1', accept: true));
      expect(state().busyIds, isEmpty);
    });

    test(
      'a blocking rule at acceptance returns the failure and keeps the request',
      () async {
        repo.respondError = const ShiftException(ShiftErrorKind.invalid);
        await controller().load();

        final ShiftException? error = await controller().respond(
          's1',
          accept: true,
        );

        expect(error?.kind, ShiftErrorKind.invalid);
        expect(state().busyIds, isEmpty);
        expect(state().swaps, isNotEmpty);
      },
    );

    test('offline keeps the cached requests', () async {
      repo
        ..swapCache = <SwapRequest>[fakeSwap('cached')]
        ..refreshError = const ShiftException(ShiftErrorKind.offline);

      await controller().load();

      expect(state().swaps.single.id, 'cached');
      expect(state().fromCache, isTrue);
    });
  });
}
