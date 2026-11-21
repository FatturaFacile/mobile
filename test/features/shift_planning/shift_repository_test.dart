import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:fattura_facile/core/database/app_database.dart';
import 'package:fattura_facile/core/sync/sync_engine.dart';
import 'package:fattura_facile/features/shift_planning/data/shift_repository_impl.dart';
import 'package:fattura_facile/features/shift_planning/domain/shift_models.dart';
import 'package:fattura_facile/features/shift_planning/domain/shift_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/sync_engine_test.dart' show FakeAdapter, json;
import 'fakes.dart';

Map<String, dynamic> envelope(Object data) => <String, dynamic>{
  'success': true,
  'message': 'ok',
  'data': data,
};

Map<String, dynamic> problem(
  int status,
  String detail, {
  List<Map<String, dynamic>>? issues,
}) => <String, dynamic>{
  'title': 'Problem',
  'detail': detail,
  'status': status,
  'invalid_params': ?issues,
};

void main() {
  late AppDatabase db;
  late FakeAdapter adapter;
  late ShiftRepositoryImpl repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    adapter = FakeAdapter(
      (RequestOptions o) => json(200, envelope(<dynamic>[])),
    );
    final Dio dio = Dio(
      BaseOptions(
        baseUrl: 'http://x/api/v1',
        validateStatus: (int? s) => s != null && s < 300,
      ),
    )..httpClientAdapter = adapter;
    repo = ShiftRepositoryImpl(db, dio, SyncEngine(db, dio));
  });

  tearDown(() => db.close());

  group('own shifts, team calendar and open shifts', () {
    test('refresh stores the shifts for offline reading, oldest first, and replaces the previous copy', () async {
      adapter.handler = (RequestOptions o) => json(
        200,
        envelope(<Map<String, dynamic>>[
          fakeShift('b', date: '2026-12-08').toJson(),
          fakeShift('a', tags: <SurchargeTag>[SurchargeTag.night]).toJson(),
        ]),
      );

      final List<Shift> fresh = await repo.refreshMyShifts(
        't1',
        from: DateTime.utc(2026, 12, 1),
        to: DateTime.utc(2027, 1, 31),
      );

      expect(fresh.map((Shift s) => s.id), <String>['a', 'b']);
      expect(adapter.calls.single.path, '/shift-planning/my/shifts');
      expect(adapter.calls.single.queryParameters, <String, dynamic>{
        'from': '2026-12-01',
        'to': '2027-01-31',
      });
      expect((await repo.cachedMyShifts('t1')).map((Shift s) => s.id), <String>[
        'a',
        'b',
      ]);
      expect((await repo.cachedMyShifts('t1')).first.tags, <SurchargeTag>[
        SurchargeTag.night,
      ]);

      adapter.handler = (RequestOptions o) =>
          json(200, envelope(<Map<String, dynamic>>[fakeShift('c').toJson()]));
      await repo.refreshMyShifts('t1');
      expect((await repo.cachedMyShifts('t1')).map((Shift s) => s.id), <String>[
        'c',
      ]);
    });

    test('the cache is per tenant and per list', () async {
      adapter.handler = (RequestOptions o) =>
          json(200, envelope(<Map<String, dynamic>>[fakeShift('a').toJson()]));
      await repo.refreshMyShifts('t1');
      await repo.refreshOpenShifts('t1');
      await repo.refreshTeamShifts('t1');

      expect(await repo.cachedMyShifts('t2'), isEmpty);
      expect(adapter.calls.map((RequestOptions c) => c.path), <String>[
        '/shift-planning/my/shifts',
        '/shift-planning/my/open-shifts',
        '/shift-planning/my/team-shifts',
      ]);
      expect(await repo.cachedOpenShifts('t1'), hasLength(1));
      expect(await repo.cachedTeamShifts('t1'), hasLength(1));
    });

    test('offline refresh throws offline and keeps the cache', () async {
      adapter.handler = (RequestOptions o) =>
          json(200, envelope(<Map<String, dynamic>>[fakeShift('a').toJson()]));
      await repo.refreshMyShifts('t1');

      adapter.handler = (RequestOptions o) =>
          throw DioException.connectionError(requestOptions: o, reason: 'down');

      await expectLater(
        repo.refreshMyShifts('t1'),
        throwsA(
          isA<ShiftException>().having(
            (ShiftException e) => e.kind,
            'kind',
            ShiftErrorKind.offline,
          ),
        ),
      );
      expect(await repo.cachedMyShifts('t1'), hasLength(1));
    });

    test('maps the status codes of the API to error kinds', () async {
      Future<ShiftErrorKind> kindOf(int status) async {
        adapter.handler = (RequestOptions o) =>
            json(status, problem(status, 'x'));
        try {
          await repo.refreshMyShifts('t1');
        } on ShiftException catch (e) {
          return e.kind;
        }
        fail('no exception');
      }

      expect(await kindOf(403), ShiftErrorKind.forbidden);
      expect(await kindOf(404), ShiftErrorKind.notFound);
      expect(await kindOf(409), ShiftErrorKind.conflict);
      expect(await kindOf(422), ShiftErrorKind.invalid);
      expect(await kindOf(500), ShiftErrorKind.unknown);
    });
  });

  group('claim', () {
    test('a claim accepted by the server removes the shift from the marketplace cache', () async {
      adapter.handler = (RequestOptions o) => json(
        200,
        envelope(<Map<String, dynamic>>[
          fakeShift('open1', employeeId: null).toJson(),
        ]),
      );
      await repo.refreshOpenShifts('t1');
      adapter.handler = (RequestOptions o) => json(
        200,
        envelope(<String, dynamic>{
          'assignment': fakeShift('open1').toJson(),
          'warnings': <dynamic>[],
        }),
      );

      final ClaimOutcome outcome = await repo.claim('t1', 'open1');

      expect(outcome.status, ClaimStatus.claimed);
      expect(
        adapter.calls.last.path,
        '/shift-planning/my/open-shifts/open1/claim',
      );
      expect(adapter.calls.last.method, 'POST');
      expect(adapter.calls.last.headers['Idempotency-Key'], isNotNull);
      expect(await repo.cachedOpenShifts('t1'), isEmpty);
      expect((await repo.claimQueue('t1')).waitingShiftIds, isEmpty);
    });

    test('offline the claim waits in the outbox and is validated when it is delivered', () async {
      adapter.handler = (RequestOptions o) =>
          throw DioException.connectionError(requestOptions: o, reason: 'down');

      final ClaimOutcome outcome = await repo.claim('t1', 'open1');

      expect(outcome.status, ClaimStatus.queued);
      expect((await repo.claimQueue('t1')).waitingShiftIds, <String>{'open1'});

      adapter.handler = (RequestOptions o) =>
          json(200, envelope(<String, dynamic>{'warnings': <dynamic>[]}));
      await SyncEngine(
        db,
        Dio(BaseOptions(baseUrl: 'http://x/api/v1'))
          ..httpClientAdapter = adapter,
      ).flush('t1');

      expect((await repo.claimQueue('t1')).waitingShiftIds, isEmpty);
    });

    test('a rule violation parks the claim as rejected with the reason, and it can be retried or dismissed', () async {
      adapter.handler = (RequestOptions o) =>
          json(422, problem(422, 'Rest of 8 hours'));

      final ClaimOutcome outcome = await repo.claim('t1', 'open1');
      final ClaimQueue queue = await repo.claimQueue('t1');

      expect(outcome.status, ClaimStatus.rejected);
      expect(queue.waitingShiftIds, isEmpty);
      expect(queue.rejected.single.shiftId, 'open1');
      expect(queue.rejected.single.detail, isNotEmpty);

      await repo.dismissClaim(queue.rejected.single.queueUuid);
      expect((await repo.claimQueue('t1')).rejected, isEmpty);
    });

    test(
      'somebody faster (409) is reported as rejected too and is not resent',
      () async {
        adapter.handler = (RequestOptions o) =>
            json(409, problem(409, 'The shift has already been taken.'));

        final ClaimOutcome outcome = await repo.claim('t1', 'open1');
        final int calls = adapter.calls.length;
        await SyncEngine(
          db,
          Dio(BaseOptions(baseUrl: 'http://x/api/v1'))
            ..httpClientAdapter = adapter,
        ).flush('t1');

        expect(outcome.status, ClaimStatus.rejected);
        expect(adapter.calls, hasLength(calls));
        expect((await repo.claimQueue('t1')).rejected, hasLength(1));
      },
    );
  });

  group('swaps', () {
    test('lists the eligible colleagues', () async {
      adapter.handler = (RequestOptions o) => json(
        200,
        envelope(<Map<String, dynamic>>[
          <String, dynamic>{
            'employee_id': 'e3',
            'name': 'Bruno Bianchi',
            'warnings': <dynamic>[],
            'shifts': <dynamic>[],
          },
        ]),
      );

      final List<SwapPeer> peers = await repo.eligiblePeers('a1');

      expect(
        adapter.calls.single.path,
        '/shift-planning/my/shifts/a1/eligible-peers',
      );
      expect(peers.single.name, 'Bruno Bianchi');
    });

    test('sends a direct request with the shift in exchange, and a broadcast without colleague', () async {
      adapter.handler = (RequestOptions o) => json(
        201,
        envelope(fakeSwap('s1', requester: 'e1', peer: 'e3').toJson()),
      );

      await repo.requestSwap('a1', peerEmployeeId: 'e3', counterShiftId: 'x1');
      await repo.requestSwap('a1');

      expect(jsonDecode(jsonEncode(adapter.calls[0].data)), <String, dynamic>{
        'shift_assignment_id': 'a1',
        'target_peer_employee_id': 'e3',
        'target_shift_assignment_id': 'x1',
      });
      expect(jsonDecode(jsonEncode(adapter.calls[1].data)), <String, dynamic>{
        'shift_assignment_id': 'a1',
      });
      expect(adapter.calls.first.path, '/shift-planning/my/swaps');
    });

    test(
      'a refused swap carries the findings of the rules it breaks',
      () async {
        adapter.handler = (RequestOptions o) => json(
          422,
          problem(
            422,
            'broken',
            issues: <Map<String, dynamic>>[
              <String, dynamic>{
                'severity': 'blocking_error',
                'rule_code': 'IT.DAILY_REST_11H',
                'translation_key': 'SHIFT_PLANNING.RULE_IT_DAILY_REST_11H',
                'params': <String, dynamic>{'rest_minutes': 480},
              },
            ],
          ),
        );

        await expectLater(
          repo.requestSwap('a1', peerEmployeeId: 'e3'),
          throwsA(
            isA<ShiftException>()
                .having(
                  (ShiftException e) => e.kind,
                  'kind',
                  ShiftErrorKind.invalid,
                )
                .having(
                  (ShiftException e) => e.issues.single.ruleCode,
                  'rule',
                  'IT.DAILY_REST_11H',
                )
                .having(
                  (ShiftException e) => e.issues.single.params['rest_minutes'],
                  'rest',
                  480,
                ),
          ),
        );
      },
    );

    test('caches the swap list and answers a request', () async {
      adapter.handler = (RequestOptions o) =>
          json(200, envelope(<Map<String, dynamic>>[fakeSwap('s1').toJson()]));
      await repo.refreshSwaps('t1');
      expect((await repo.cachedSwaps('t1')).single.id, 's1');

      adapter.handler = (RequestOptions o) => json(
        200,
        envelope(
          fakeSwap('s1', status: SwapStatus.pendingManagerApproval).toJson(),
        ),
      );
      final SwapRequest accepted = await repo.respondToSwap('s1', accept: true);

      expect(accepted.status, SwapStatus.pendingManagerApproval);
      expect(adapter.calls.last.path, '/shift-planning/my/swaps/s1/respond');
      expect(jsonDecode(jsonEncode(adapter.calls.last.data)), <String, dynamic>{
        'decision': 'approve',
      });

      await repo.respondToSwap('s1', accept: false);
      expect(jsonDecode(jsonEncode(adapter.calls.last.data)), <String, dynamic>{
        'decision': 'reject',
      });
    });
  });
}
