import 'package:fattura_facile/features/resource_planning/domain/resource_planning_models.dart';
import 'package:fattura_facile/features/resource_planning/domain/resource_planning_repository.dart';
import 'package:fattura_facile/features/resource_planning/presentation/resource_planning_strings.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  group('SaturationBand.fromLoad', () {
    SaturationBand band(double load, {double net = 40, double booked = 10}) =>
        SaturationBand.fromLoad(
          loadPercent: load,
          netHours: net,
          bookedHours: booked,
        );

    test('is none without net capacity and without bookings', () {
      expect(band(0, net: 0, booked: 0), SaturationBand.none);
    });

    test('is green below 80 percent', () {
      expect(band(79.99), SaturationBand.green);
      expect(band(0), SaturationBand.green);
    });

    test('is yellow from 80 up to and including 100 percent', () {
      expect(band(80), SaturationBand.yellow);
      expect(band(100), SaturationBand.yellow);
    });

    test('is red above 100 percent, including the capped load of a booked resource without capacity', () {
      expect(band(100.01), SaturationBand.red);
      expect(band(overloadLoadCap, net: 0, booked: 8), SaturationBand.red);
    });

    test('honours the thresholds sent by the server', () {
      expect(
        SaturationBand.fromLoad(
          loadPercent: 90,
          netHours: 40,
          bookedHours: 36,
          yellowAt: 95,
          redAt: 110,
        ),
        SaturationBand.green,
      );
    });
  });

  group('wire parsing', () {
    test('booking type, band, certification and utilization status read the wire names', () {
      expect(BookingType.fromWire('HardCommitted'), BookingType.hardCommitted);
      expect(BookingType.fromWire('SoftTentative').isSoft, isTrue);
      expect(BookingType.fromWire('weird'), BookingType.softTentative);
      expect(SaturationBand.fromWire('red'), SaturationBand.red);
      expect(SaturationBand.fromWire(null), SaturationBand.none);
      expect(
        CertificationStatus.fromWire('expired'),
        CertificationStatus.expired,
      );
      expect(CertificationStatus.expired.isBlocking, isTrue);
      expect(CertificationStatus.valid.isBlocking, isFalse);
      expect(
        UtilizationStatus.fromWire('below_target'),
        UtilizationStatus.belowTarget,
      );
      expect(UtilizationGroup.costCenter.wire, 'cost_center');
      expect(UtilizationGroup.resource.wire, 'resource');
    });

    test('a skill keeps the certificate requirement', () {
      final Skill s = Skill.fromJson(<String, dynamic>{
        'id': 's1',
        'category': 'Safety',
        'skill_name': 'Forklift',
        'requires_certification': true,
        'certification_code': 'FORKLIFT',
      });

      expect(s.skillName, 'Forklift');
      expect(s.requiresCertification, isTrue);
      expect(s.certificationCode, 'FORKLIFT');
    });

    test('an employee skill profile carries the proficiency and the certificate verdict', () {
      final EmployeeSkillProfile p = EmployeeSkillProfile.fromJson(
        <String, dynamic>{
          'id': 'p1',
          'employee_id': 'e1',
          'employee_name': 'Anna Rossi',
          'skill_id': 's1',
          'skill_name': 'Forklift',
          'category': 'Safety',
          'proficiency_level': 4,
          'valid_until_date': '2031-01-01',
          'is_valid': true,
          'requires_certification': true,
          'certification_code': 'FORKLIFT',
          'certification_status': 'missing',
          'certification_valid_until': null,
        },
      );

      expect(p.proficiencyLevel, 4);
      expect(p.validUntilDate, '2031-01-01');
      expect(p.certificationStatus, CertificationStatus.missing);
      expect(p.certificationValidUntil, isNull);
    });

    test('an allocation parses decimals sent as numbers or strings, and exposes the soft helpers', () {
      final Map<String, dynamic> json = allocationJson(
        'a1',
        projectId: null,
        overloaded: true,
        peak: 130,
      )..['allocated_hours_per_day'] = '3.50';

      final ResourceAllocation a = ResourceAllocation.fromJson(json);

      expect(a.allocatedHoursPerDay, 3.5);
      expect(a.totalAllocatedHours, 20);
      expect(a.isSoft, isTrue);
      expect(a.projectId, isNull);
      expect(a.referenceName, 'Big deal');
      expect(a.canConvertWithoutProject, isFalse);
      expect(a.isOverloaded, isTrue);
      expect(a.peakLoadPercent, 130);
      expect(fakeAllocation('a2').canConvertWithoutProject, isTrue);
      expect(
        fakeAllocation('a3', type: 'HardCommitted').canConvertWithoutProject,
        isFalse,
      );
    });

    test('a mutation result lists every affected row and the overload weeks', () {
      final AllocationMutationResult r = AllocationMutationResult.fromJson(
        mutationJson(
          <Map<String, dynamic>>[
            allocationJson('a1'),
            allocationJson('a2', start: '2030-03-06'),
          ],
          overloaded: true,
          peak: 115,
          warnings: <Map<String, dynamic>>[
            <String, dynamic>{
              'code': 'skill_certificate_invalid',
              'params': <String, dynamic>{'skill_id': 's1'},
            },
          ],
        ),
      );

      expect(r.allocations.map((ResourceAllocation a) => a.id), <String>[
        'a1',
        'a2',
      ]);
      expect(r.overload.isOverloaded, isTrue);
      expect(r.overload.weeks.single.loadPercent, 115);
      expect(r.warnings.single.code, 'skill_certificate_invalid');
      expect(r.warnings.single.params['skill_id'], 's1');
    });

    test('a mutation result without the allocations list falls back to the main allocation', () {
      final AllocationMutationResult r = AllocationMutationResult.fromJson(
        <String, dynamic>{'allocation': allocationJson('a1')},
      );

      expect(r.allocations.single.id, 'a1');
      expect(r.overload.isOverloaded, isFalse);
      expect(r.warnings, isEmpty);
    });

    test('a capacity snapshot parses the weekly figures', () {
      final ResourceCapacitySnapshot s = ResourceCapacitySnapshot.fromJson(
        <String, dynamic>{
          'id': 'n1',
          'employee_id': 'e1',
          'week_start_date': '2030-03-04',
          'contractual_hours': '40.00',
          'leave_and_holiday_hours': 8,
          'net_available_hours': 32,
          'billable_booked_hours': 20,
          'internal_booked_hours': 4,
          'utilization_rate_percent': 62.5,
          'department_id': null,
          'cost_center_id': 'c1',
        },
      );

      expect(s.contractualHours, 40);
      expect(s.utilizationRatePercent, 62.5);
      expect(s.departmentId, isNull);
      expect(s.costCenterId, 'c1');
    });
  });

  group('capacity heatmap', () {
    final CapacityHeatmap map = CapacityHeatmap.fromJson(heatmapJson());

    test('parses thresholds, periods, rows and cells', () {
      expect(map.yellowThreshold, 80);
      expect(map.redThreshold, 100);
      expect(map.periods, <String>['2030-03-04', '2030-03-11']);
      expect(map.rows, hasLength(2));
      expect(map.rows.first.cells.last.band, SaturationBand.yellow);
      expect(map.rows.first.departmentName, 'Engineering');
    });

    test('missing thresholds fall back to 80 and 100', () {
      final CapacityHeatmap m = CapacityHeatmap.fromJson(<String, dynamic>{
        'from': '2030-03-04',
        'to': '2030-03-10',
        'granularity': 'day',
      });

      expect(m.yellowThreshold, defaultYellowThreshold);
      expect(m.redThreshold, defaultRedThreshold);
      expect(m.rows, isEmpty);
    });

    test('a row reports its peak load, its worst band and its overload', () {
      final HeatmapRow anna = map.rows.first;
      final HeatmapRow bruno = map.rows.last;

      expect(anna.peakLoadPercent, 90);
      expect(anna.worstBand, SaturationBand.yellow);
      expect(anna.isOverloaded, isFalse);
      expect(bruno.peakLoadPercent, 120);
      expect(bruno.worstBand, SaturationBand.red);
      expect(bruno.isOverloaded, isTrue);
    });

    test('overloaded rows are listed most loaded first', () {
      final CapacityHeatmap m = CapacityHeatmap.fromJson(<String, dynamic>{
        ...heatmapJson(),
        'rows': <Map<String, dynamic>>[
          rowJson('e1', 'A', <Map<String, dynamic>>[
            cellJson('2030-03-04', load: 110, band: 'red', overloaded: true),
          ]),
          rowJson('e2', 'B', <Map<String, dynamic>>[
            cellJson('2030-03-04', load: 160, band: 'red', overloaded: true),
          ]),
          rowJson('e3', 'C', <Map<String, dynamic>>[
            cellJson('2030-03-04', load: 40),
          ]),
        ],
      });

      expect(m.overloadedRows.map((HeatmapRow r) => r.employeeId), <String>[
        'e2',
        'e1',
      ]);
    });

    test('a cell computes its booked and free hours, never negative', () {
      final HeatmapCell free = HeatmapCell.fromJson(
        cellJson('2030-03-04', net: 40, hard: 10, soft: 6),
      );
      final HeatmapCell over = HeatmapCell.fromJson(
        cellJson('2030-03-04', net: 40, hard: 40, soft: 8),
      );

      expect(free.bookedHours, 16);
      expect(free.freeHours, 24);
      expect(over.freeHours, 0);
    });
  });

  group('candidates and utilization', () {
    test('a candidate parses matched skills, blockers and the overload flag', () {
      final Candidate c = Candidate.fromJson(
        candidateJson(
          'e1',
          'Anna',
          eligible: false,
          peakAfter: 125,
          blockers: <Map<String, dynamic>>[
            <String, dynamic>{
              'code': 'certificate_expired',
              'skill_id': 's1',
              'params': <String, dynamic>{},
            },
          ],
        ),
      );

      expect(c.eligible, isFalse);
      expect(c.matchedSkills.single.level, 4);
      expect(c.blockers.single.code, 'certificate_expired');
      expect(c.blockers.single.skillId, 's1');
      expect(c.wouldOverload, isTrue);
      expect(c.hourlyCost, 55);
    });

    test('a candidate query serializes the requirements and omits the empty optionals', () {
      const CandidateQuery q = CandidateQuery(
        startDate: '2030-03-04',
        endDate: '2030-03-29',
        allocatedHoursPerDay: 4,
        requirements: <SkillRequirement>[
          SkillRequirement(skillId: 's1', minLevel: 3),
        ],
      );

      final Map<String, dynamic> json = q.toJson();

      expect(json['requirements'], <Map<String, dynamic>>[
        <String, dynamic>{'skill_id': 's1', 'min_level': 3},
      ]);
      expect(json['require_valid_certificates'], isTrue);
      expect(json['include_ineligible'], isFalse);
      expect(json['limit'], 10);
      expect(json.containsKey('project_id'), isFalse);
      expect(json.containsKey('department_id'), isFalse);
    });

    test('a utilization report parses rows, totals and the status', () {
      final UtilizationReport r = UtilizationReport.fromJson(
        utilizationJson(),
      );

      expect(r.defaultTargetPercent, 70);
      expect(r.rows, hasLength(2));
      expect(r.rows.first.status, UtilizationStatus.belowTarget);
      expect(r.rows.last.status, UtilizationStatus.onTarget);
      expect(r.rows.first.gapPercent, -10);
      expect(r.totals.keyName, 'Total');
      expect(r.totals.billableCommittedHours, 96);
    });
  });

  group('rebalance request', () {
    test('a shift serializes the strategy and the days only', () {
      expect(const RebalanceRequest.shiftBy(7).toJson(), <String, dynamic>{
        'strategy': 'shift',
        'shift_days': 7,
      });
    });

    test('a reassignment names the colleague', () {
      expect(
        const RebalanceRequest.reassignTo('e9').toJson(),
        <String, dynamic>{'strategy': 'reassign', 'employee_id': 'e9'},
      );
    });

    test('a split carries the cut date', () {
      expect(
        const RebalanceRequest(
          strategy: RebalanceStrategy.split,
          splitDate: '2030-03-06',
          shiftDays: 7,
        ).toJson(),
        <String, dynamic>{
          'strategy': 'split',
          'split_date': '2030-03-06',
          'shift_days': 7,
        },
      );
    });
  });

  group('strings', () {
    test('every locale table defines every label', () {
      for (final MapEntry<String, Map<RS, String>> table
          in resourcePlanningLocaleTables.entries) {
        for (final RS key in RS.values) {
          expect(
            table.value[key],
            isNotNull,
            reason: '${table.key} misses ${key.name}',
          );
          expect(table.value[key], isNotEmpty);
        }
      }
      expect(resourcePlanningLocaleTables.keys.toSet(), <String>{
        'it',
        'en',
        'de',
        'fr',
      });
    });

    test('the parameterized labels keep their placeholder in every locale', () {
      for (final Map<RS, String> table in resourcePlanningLocaleTables.values) {
        expect(table[RS.overloadAlert], contains('{n}'));
        expect(table[RS.overloadedBooking], contains('{n}'));
      }
    });

    test('regional variants resolve to their language and unknown languages to English', () {
      expect(
        const ResourcePlanningStrings('de-CH')(RS.tabCapacity),
        'Kapazität',
      );
      expect(
        const ResourcePlanningStrings('fr_CH')(RS.tabCapacity),
        'Capacité',
      );
      expect(
        const ResourcePlanningStrings('it-IT')(RS.tabCapacity),
        'Capacità',
      );
      expect(const ResourcePlanningStrings('it-CH')(RS.softBadge), 'Provvisoria');
      expect(const ResourcePlanningStrings('pt')(RS.tabCapacity), 'Capacity');
    });

    test('placeholders are replaced and unknown codes are shown as received', () {
      const ResourcePlanningStrings s = ResourcePlanningStrings('en');

      expect(
        s(RS.overloadAlert, params: <String, Object>{'n': 3}),
        '3 resources above 100% of capacity',
      );
      expect(s.blocker('certificate_missing'), 'Certificate missing');
      expect(s.blocker('mystery'), 'mystery');
      expect(s.violation('already_hard_committed'), contains('already'));
      expect(s.violation('mystery'), 'mystery');
    });
  });
}
