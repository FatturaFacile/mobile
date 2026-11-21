// ignore_for_file: prefer_const_literals_to_create_immutables
import 'package:fattura_facile/features/shift_planning/domain/ical_exporter.dart';
import 'package:fattura_facile/features/shift_planning/domain/shift_models.dart';
import 'package:fattura_facile/features/shift_planning/presentation/shift_strings.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  group('Shift', () {
    test(
      'parses the API resource with template, surcharge tags and warnings',
      () {
        final Shift shift = Shift.fromJson(<String, dynamic>{
          'id': 'a1',
          'roster_schedule_period_id': 'p1',
          'employee_id': 'e1',
          'is_open': false,
          'shift_date': '2026-12-07',
          'template': <String, dynamic>{
            'code': 'NOT',
            'name': <String, dynamic>{'it': 'Notte', 'en': 'Night'},
            'color_hex': '#722ED1',
          },
          'start_at': '2026-12-07T21:00:00+00:00',
          'end_at': '2026-12-08T05:00:00+00:00',
          'surcharge_breakdown': <String, dynamic>{
            'tags': <String>['night', 'sunday', 'unknown'],
          },
          'compliance_warnings': <Map<String, dynamic>>[
            <String, dynamic>{
              'severity': 'warning',
              'rule_code': 'CONTRACT.WEEKLY_HOURS_EXCEEDED',
              'translation_key':
                  'SHIFT_PLANNING.RULE_CONTRACT_WEEKLY_HOURS_EXCEEDED',
              'params': <String, dynamic>{'scheduled_hours': 48, 'skip': null},
            },
          ],
        });

        expect(shift.templateCode, 'NOT');
        expect(shift.label('it'), 'Notte');
        expect(shift.label('de'), 'Night');
        expect(shift.tags, <SurchargeTag>[
          SurchargeTag.night,
          SurchargeTag.sunday,
        ]);
        expect(shift.length, const Duration(hours: 8));
        expect(shift.isOpen, isFalse);
        expect(shift.warnings.single.isBlocking, isFalse);
        expect(shift.warnings.single.params, <String, Object>{
          'scheduled_hours': 48,
        });
      },
    );

    test('keeps tags and warnings through the offline cache round trip', () {
      final Shift original = fakeShift(
        'a1',
        tags: <SurchargeTag>[SurchargeTag.holiday],
        warnings: const <ComplianceIssue>[
          ComplianceIssue(
            severity: IssueSeverity.blocking,
            ruleCode: 'IT.DAILY_REST_11H',
            translationKey: 'K',
          ),
        ],
      );

      final Shift copy = Shift.fromJson(original.toJson());

      expect(copy.tags, original.tags);
      expect(copy.warnings.single.isBlocking, isTrue);
      expect(copy.startAt, original.startAt);
      expect(copy.templateName['it'], 'Mattina');
    });

    test('an open shift has no employee; the cost of a shift never reaches the model', () {
      final Shift open = Shift.fromJson(<String, dynamic>{
        'id': 'a2',
        'employee_id': null,
        'shift_date': '2026-12-08',
        'start_at': '2026-12-08T05:00:00Z',
        'end_at': '2026-12-08T13:00:00Z',
        'estimated_labor_cost': '160.00',
      });

      expect(open.isOpen, isTrue);
      expect(open.toJson().containsKey('estimated_labor_cost'), isFalse);
    });
  });

  group('SwapRequest and SwapPeer', () {
    test('parses a broadcast request and its two shifts', () {
      final SwapRequest swap = SwapRequest.fromJson(<String, dynamic>{
        'id': 's1',
        'requester_employee_id': 'e2',
        'target_peer_employee_id': null,
        'shift_assignment_id': 'a1',
        'target_shift_assignment_id': null,
        'status': 'pending_manager_approval',
        'rejection_reason': null,
        'assignment': fakeShift('a1').toJson(),
      });

      expect(swap.isBroadcast, isTrue);
      expect(swap.status, SwapStatus.pendingManagerApproval);
      expect(swap.assignment?.id, 'a1');
      expect(
        SwapRequest.fromJson(swap.toJson()).status,
        SwapStatus.pendingManagerApproval,
      );
    });

    test(
      'parses an eligible colleague with the shifts to take in exchange',
      () {
        final SwapPeer peer = SwapPeer.fromJson(<String, dynamic>{
          'employee_id': 'e3',
          'name': 'Bruno Bianchi',
          'warnings': <Map<String, dynamic>>[],
          'shifts': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'x1',
              'shift_date': '2026-12-08',
              'template_code': 'POM',
              'start_at': '2026-12-08T13:00:00Z',
              'end_at': '2026-12-08T21:00:00Z',
            },
          ],
        });

        expect(peer.name, 'Bruno Bianchi');
        expect(peer.shifts.single.templateCode, 'POM');
      },
    );
  });

  group('IcalExporter', () {
    final DateTime now = DateTime.utc(2026, 12, 1, 8, 30);

    test('writes a UTC calendar with one event per shift, CRLF lines and the surcharge categories', () {
      final String ics = const IcalExporter().build(
        <Shift>[
          fakeShift(
            'a1',
            tags: <SurchargeTag>[SurchargeTag.night, SurchargeTag.onCall],
          ),
          fakeShift('a2', date: '2026-12-08', code: 'POM'),
        ],
        languageCode: 'it',
        now: now,
      );

      expect(ics, startsWith('BEGIN:VCALENDAR\r\nVERSION:2.0\r\n'));
      expect(ics, endsWith('END:VCALENDAR\r\n'));
      expect('BEGIN:VEVENT'.allMatches(ics), hasLength(2));
      expect(ics, contains('UID:a1@fatturafacile.shifts'));
      expect(ics, contains('DTSTAMP:20261201T083000Z'));
      expect(ics, contains('DTSTART:20261207T050000Z'));
      expect(ics, contains('DTEND:20261207T130000Z'));
      expect(ics, contains('SUMMARY:Mattina'));
      expect(ics, contains('CATEGORIES:NIGHT,ON_CALL'));
      expect(ics.replaceAll('\r\n', '').contains('\n'), isFalse);
    });

    test('escapes text and folds lines longer than 75 characters', () {
      final Shift odd = Shift(
        id: 'a3',
        date: '2026-12-07',
        startAt: DateTime.utc(2026, 12, 7, 5),
        endAt: DateTime.utc(2026, 12, 7, 13),
        templateCode: 'X',
        templateName: <String, String>{
          'en': 'Early; late, mixed\\ ${'long ' * 30}',
        },
      );

      final String ics = const IcalExporter().build(
        <Shift>[odd],
        languageCode: 'en',
        now: now,
      );

      expect(ics, contains(r'SUMMARY:Early\; late\, mixed\\ long'));
      for (final String line in ics.split('\r\n')) {
        expect(line.length, lessThanOrEqualTo(75));
      }
      expect(ics, contains('\r\n '));
    });

    test('builds the Google Calendar link of a shift', () {
      final Uri uri = const IcalExporter().googleCalendarUri(
        fakeShift('a1'),
        languageCode: 'en',
      );

      expect(uri.host, 'calendar.google.com');
      expect(uri.queryParameters['action'], 'TEMPLATE');
      expect(uri.queryParameters['text'], 'Morning');
      expect(uri.queryParameters['dates'], '20261207T050000Z/20261207T130000Z');
    });
  });

  group('ShiftStrings', () {
    test('every locale defines every label', () {
      for (final MapEntry<String, Map<SL, String>> table
          in shiftLocaleTables.entries) {
        for (final SL key in SL.values) {
          expect(
            table.value[key],
            isNotNull,
            reason: '${table.key} lacks $key',
          );
          expect(
            table.value[key]!.trim(),
            isNotEmpty,
            reason: '${table.key} has an empty $key',
          );
        }
      }
      expect(
        shiftLocaleTables.keys,
        containsAll(<String>['it', 'en', 'de', 'fr']),
      );
    });

    test('falls back to English and names the surcharge tags', () {
      const ShiftStrings s = ShiftStrings('xx');

      expect(s(SL.tabOpen), 'Open shifts');
      expect(const ShiftStrings('it').tag('night'), 'Notte');
      expect(const ShiftStrings('de').tag('on_call'), 'Pikett');
      expect(s.tag('other'), 'other');
    });
  });
}
