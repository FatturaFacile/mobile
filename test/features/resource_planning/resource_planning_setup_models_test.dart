import 'package:fattura_facile/features/resource_planning/domain/resource_planning_models.dart';
import 'package:fattura_facile/features/resource_planning/domain/resource_planning_repository.dart';
import 'package:fattura_facile/features/resource_planning/presentation/resource_planning_strings.dart';
import 'package:fattura_facile/features/resource_planning/presentation/resource_planning_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

AllocationDraft draft({
  String employeeId = 'e1',
  BookingType type = BookingType.hardCommitted,
  String start = '2030-03-04',
  String end = '2030-03-08',
  double hours = 4,
  String? projectId = 'p1',
  String? opportunityId,
}) => AllocationDraft(
  employeeId: employeeId,
  bookingType: type,
  startDate: start,
  endDate: end,
  allocatedHoursPerDay: hours,
  projectId: projectId,
  opportunityId: opportunityId,
);

void main() {
  group('isUuid', () {
    test('accepts a uuid with surrounding spaces and rejects anything else', () {
      expect(isUuid(uuidA), isTrue);
      expect(isUuid('  $uuidA '), isTrue);
      expect(isUuid('p1'), isFalse);
      expect(isUuid(''), isFalse);
      expect(isUuid('${uuidA}x'), isFalse);
    });
  });

  group('ResourceLookup and ProjectRef', () {
    test('a resource is parsed with its department and cost center', () {
      final ResourceLookup r = ResourceLookup.fromJson(resourceJson('e1', 'Anna Rossi'));

      expect(r.employeeId, 'e1');
      expect(r.fullName, 'Anna Rossi');
      expect(r.departmentName, 'Engineering');
      expect(r.costCenterId, 'c-d1');
      expect(r.weeklyContractHours, 40);
      expect(r.country, 'CH');
      expect(r.region, isNull);
    });

    test('a project label joins number and name, or is the name alone', () {
      expect(
        ProjectRef.fromJson(<String, dynamic>{'id': 'p1', 'name': 'Relaunch', 'project_number': 'P-001'}).label,
        'P-001 - Relaunch',
      );
      expect(
        ProjectRef.fromJson(<String, dynamic>{'id': 'p1', 'name': 'Relaunch'}).label,
        'Relaunch',
      );
    });
  });

  group('AllocationDraft', () {
    test('a complete hard draft has no issue', () {
      expect(draft().validate(), isEmpty);
    });

    test('a hard booking needs a project, also when an opportunity is given', () {
      final List<AllocationDraftIssue> issues = draft(projectId: null, opportunityId: uuidA).validate();

      expect(issues, <AllocationDraftIssue>[AllocationDraftIssue.projectRequired]);
    });

    test('a soft booking needs a project or an opportunity', () {
      expect(
        draft(type: BookingType.softTentative, projectId: null).validate(),
        <AllocationDraftIssue>[AllocationDraftIssue.referenceRequired],
      );
      expect(
        draft(type: BookingType.softTentative, projectId: null, opportunityId: uuidA).validate(),
        isEmpty,
      );
      expect(draft(type: BookingType.softTentative).validate(), isEmpty);
    });

    test('a blank project id counts as missing', () {
      expect(
        draft(projectId: '  ').validate(),
        <AllocationDraftIssue>[AllocationDraftIssue.projectRequired],
      );
    });

    test('the opportunity id must be a uuid', () {
      expect(
        draft(type: BookingType.softTentative, projectId: null, opportunityId: 'o1').validate(),
        contains(AllocationDraftIssue.invalidOpportunityId),
      );
    });

    test('the employee, the period and the hours are checked', () {
      expect(draft(employeeId: ' ').validate(), contains(AllocationDraftIssue.employeeRequired));
      expect(draft(start: '2030-03-08', end: '2030-03-04').validate(), contains(AllocationDraftIssue.invalidPeriod));
      expect(draft(start: '', end: '').validate(), contains(AllocationDraftIssue.invalidPeriod));
      expect(draft(hours: 0).validate(), contains(AllocationDraftIssue.invalidHours));
      expect(draft(hours: 24.5).validate(), contains(AllocationDraftIssue.invalidHours));
      expect(draft(hours: 24).validate(), isEmpty);
      expect(draft(start: '2030-03-04', end: '2030-03-04').validate(), isEmpty);
    });

    test('toJson sends only what is set and trims the free text', () {
      final Map<String, dynamic> json = const AllocationDraft(
        employeeId: 'e1',
        bookingType: BookingType.softTentative,
        startDate: '2030-03-04',
        endDate: '2030-03-08',
        allocatedHoursPerDay: 4.5,
        opportunityId: ' $uuidA ',
        notes: '  call the client  ',
        isBillable: false,
        allowOverload: false,
        requiredSkillIds: <String>['s1', 's2'],
      ).toJson();

      expect(json, <String, dynamic>{
        'employee_id': 'e1',
        'booking_type': 'SoftTentative',
        'start_date': '2030-03-04',
        'end_date': '2030-03-08',
        'allocated_hours_per_day': 4.5,
        'is_billable': false,
        'crm_opportunity_id': uuidA,
        'notes': 'call the client',
        'allow_overload': false,
        'required_skill_ids': <String>['s1', 's2'],
      });
    });

    test('toJson leaves out empty notes, blank references and an empty skill list', () {
      final Map<String, dynamic> json = const AllocationDraft(
        employeeId: 'e1',
        bookingType: BookingType.hardCommitted,
        startDate: '2030-03-04',
        endDate: '2030-03-08',
        allocatedHoursPerDay: 8,
        projectId: 'p1',
        opportunityId: ' ',
        notes: ' ',
      ).toJson();

      expect(json.containsKey('crm_opportunity_id'), isFalse);
      expect(json.containsKey('notes'), isFalse);
      expect(json.containsKey('required_skill_ids'), isFalse);
      expect(json['project_id'], 'p1');
      expect(json['booking_type'], 'HardCommitted');
      expect(json['is_billable'], isTrue);
      expect(json['allow_overload'], isTrue);
    });
  });

  group('SkillDraft', () {
    test('category and name are required', () {
      expect(
        const SkillDraft(category: ' ', skillName: '').validate(),
        <SkillDraftIssue>[SkillDraftIssue.categoryRequired, SkillDraftIssue.nameRequired],
      );
    });

    test('a skill that requires a certificate needs its code', () {
      expect(
        const SkillDraft(category: 'HSE', skillName: 'Forklift', requiresCertification: true).validate(),
        <SkillDraftIssue>[SkillDraftIssue.certificationCodeRequired],
      );
      expect(
        const SkillDraft(
          category: 'HSE',
          skillName: 'Forklift',
          requiresCertification: true,
          certificationCode: 'FORK',
        ).validate(),
        isEmpty,
      );
    });

    test('the certification code is only sent with a certificate requirement', () {
      expect(
        const SkillDraft(category: 'Eng', skillName: 'Flutter', certificationCode: 'X').toJson(),
        <String, dynamic>{'category': 'Eng', 'skill_name': 'Flutter', 'requires_certification': false},
      );
      expect(
        const SkillDraft(
          category: ' HSE ',
          skillName: ' Forklift ',
          requiresCertification: true,
          certificationCode: ' FORK ',
        ).toJson(),
        <String, dynamic>{
          'category': 'HSE',
          'skill_name': 'Forklift',
          'requires_certification': true,
          'certification_code': 'FORK',
        },
      );
    });

    test('a draft can be started from an existing skill', () {
      final SkillDraft d = SkillDraft.fromSkill(
        Skill.fromJson(skillJson('s1', 'Forklift', category: 'HSE', cert: true, code: 'FORK')),
      );

      expect(d.category, 'HSE');
      expect(d.requiresCertification, isTrue);
      expect(d.certificationCode, 'FORK');
    });
  });

  group('SkillProfileDraft', () {
    test('employee, skill and a level from 1 to 5 are required', () {
      expect(
        const SkillProfileDraft(employeeId: '', skillId: '', proficiencyLevel: 0).validate(),
        <SkillProfileDraftIssue>[
          SkillProfileDraftIssue.employeeRequired,
          SkillProfileDraftIssue.skillRequired,
          SkillProfileDraftIssue.invalidLevel,
        ],
      );
      expect(const SkillProfileDraft(employeeId: 'e', skillId: 's', proficiencyLevel: 6).validate(), isNotEmpty);
      expect(const SkillProfileDraft(employeeId: 'e', skillId: 's', proficiencyLevel: 5).validate(), isEmpty);
    });

    test('the expiry date is sent only when set', () {
      expect(
        const SkillProfileDraft(employeeId: 'e', skillId: 's', proficiencyLevel: 3).toJson(),
        <String, dynamic>{'employee_id': 'e', 'skill_id': 's', 'proficiency_level': 3},
      );
      expect(
        const SkillProfileDraft(
          employeeId: 'e',
          skillId: 's',
          proficiencyLevel: 3,
          validUntilDate: '2031-01-31',
        ).toJson()['valid_until_date'],
        '2031-01-31',
      );
    });
  });

  group('utilization targets', () {
    test('a target without department and cost center is the tenant default', () {
      expect(
        UtilizationTarget.fromJson(<String, dynamic>{'id': 't1', 'department_id': null, 'cost_center_id': null, 'target_percent': 70}).isDefault,
        isTrue,
      );
      final UtilizationTarget dept = UtilizationTarget.fromJson(<String, dynamic>{
        'id': 't2',
        'department_id': 'd1',
        'target_percent': '65.5',
      });
      expect(dept.isDefault, isFalse);
      expect(dept.targetPercent, 65.5);
    });

    test('a draft is valid between 0 and 100 and for one scope only', () {
      expect(const UtilizationTargetDraft(targetPercent: 0).isValid, isTrue);
      expect(const UtilizationTargetDraft(targetPercent: 100).isValid, isTrue);
      expect(const UtilizationTargetDraft(targetPercent: 100.5).isValid, isFalse);
      expect(const UtilizationTargetDraft(targetPercent: -1).isValid, isFalse);
      expect(
        const UtilizationTargetDraft(targetPercent: 50, departmentId: 'd', costCenterId: 'c').isValid,
        isFalse,
      );
    });

    test('toJson sends the scope ids that are set', () {
      expect(const UtilizationTargetDraft(targetPercent: 70).toJson(), <String, dynamic>{'target_percent': 70.0});
      expect(
        const UtilizationTargetDraft(targetPercent: 70, departmentId: 'd1').toJson(),
        <String, dynamic>{'department_id': 'd1', 'target_percent': 70.0},
      );
    });
  });

  group('local holidays', () {
    test('a holiday is parsed and shows MM-DD, or the full date for a one-off', () {
      final LocalHoliday yearly = LocalHoliday.fromJson(<String, dynamic>{
        'id': 'h1',
        'country': 'CH',
        'region_code': 'TI',
        'month': 3,
        'day': 19,
        'year': null,
        'name': 'San Giuseppe',
        'day_fraction': 1,
      });
      final LocalHoliday oneOff = LocalHoliday.fromJson(<String, dynamic>{
        'id': 'h2',
        'country': 'IT',
        'month': 12,
        'day': 24,
        'year': 2030,
        'name': 'Closing',
        'day_fraction': 0.5,
      });

      expect(yearly.dateLabel, '03-19');
      expect(yearly.regionCode, 'TI');
      expect(oneOff.dateLabel, '2030-12-24');
      expect(oneOff.dayFraction, 0.5);
    });

    LocalHolidayDraft holiday({
      String country = 'CH',
      int month = 3,
      int day = 19,
      int? year,
      String name = 'San Giuseppe',
      double fraction = 1,
    }) => LocalHolidayDraft(country: country, month: month, day: day, year: year, name: name, dayFraction: fraction);

    test('a valid draft has no issue', () {
      expect(holiday().validate(), isEmpty);
    });

    test('name, country, date and fraction are checked', () {
      expect(holiday(name: ' ').validate(), <LocalHolidayDraftIssue>[LocalHolidayDraftIssue.nameRequired]);
      expect(holiday(country: 'DE').validate(), <LocalHolidayDraftIssue>[LocalHolidayDraftIssue.invalidCountry]);
      expect(holiday(month: 13).validate(), <LocalHolidayDraftIssue>[LocalHolidayDraftIssue.invalidDate]);
      expect(holiday(day: 0).validate(), <LocalHolidayDraftIssue>[LocalHolidayDraftIssue.invalidDate]);
      expect(holiday(month: 4, day: 31).validate(), <LocalHolidayDraftIssue>[LocalHolidayDraftIssue.invalidDate]);
      expect(holiday(fraction: 0).validate(), <LocalHolidayDraftIssue>[LocalHolidayDraftIssue.invalidFraction]);
      expect(holiday(fraction: 1.5).validate(), <LocalHolidayDraftIssue>[LocalHolidayDraftIssue.invalidFraction]);
    });

    test('29 February is valid every year, but only in a leap year when the year is given', () {
      expect(holiday(month: 2, day: 29).validate(), isEmpty);
      expect(holiday(month: 2, day: 29, year: 2028).validate(), isEmpty);
      expect(holiday(month: 2, day: 29, year: 2030).validate(), <LocalHolidayDraftIssue>[LocalHolidayDraftIssue.invalidDate]);
    });

    test('toJson trims the text and leaves out the empty region and municipality', () {
      expect(
        const LocalHolidayDraft(
          country: 'CH',
          regionCode: ' ',
          municipality: ' Lugano ',
          month: 3,
          day: 19,
          name: ' San Giuseppe ',
          dayFraction: 0.5,
        ).toJson(),
        <String, dynamic>{
          'country': 'CH',
          'municipality': 'Lugano',
          'month': 3,
          'day': 19,
          'name': 'San Giuseppe',
          'day_fraction': 0.5,
        },
      );
    });
  });

  group('strings of the setup screens', () {
    test('the new violation and warning codes have a label', () {
      const ResourcePlanningStrings s = ResourcePlanningStrings('en');

      expect(s.violation('employee_not_found'), isNot('employee_not_found'));
      expect(s.violation('wbs_node_not_in_project'), isNot('wbs_node_not_in_project'));
      expect(s.violation('opportunity_not_open'), isNot('opportunity_not_open'));
      expect(s.violation('soft_booking_requires_reference'), isNot('soft_booking_requires_reference'));
      expect(s.violation('certification_code_required'), isNot('certification_code_required'));
      expect(s.violation('skill_missing'), 'Skill missing');
      expect(s.violation('certificate_expired'), 'Certificate expired');
    });

    test('the parameterized setup labels keep their placeholder in every locale', () {
      for (final MapEntry<String, Map<RS, String>> table in resourcePlanningLocaleTables.entries) {
        for (final RS key in <RS>[
          RS.deleteAllocationBody,
          RS.deleteSkillBody,
          RS.deleteProfileBody,
          RS.deleteHolidayBody,
        ]) {
          expect(table.value[key], contains('{name}'), reason: '${table.key} ${key.name}');
        }
      }
    });

    test('the setup labels are translated in German', () {
      const ResourcePlanningStrings de = ResourcePlanningStrings('de-CH');

      expect(de(RS.tabSetup), 'Einstellungen');
      expect(de(RS.addAllocation), 'Neue Zuweisung');
      expect(de(RS.strategySplit), 'Teilen');
    });
  });

  group('error message', () {
    test('a rule violation names the violation, an empty one falls back to the detail', () {
      const ResourcePlanningStrings s = ResourcePlanningStrings('en');

      expect(
        resourcePlanningErrorMessage(
          s,
          const ResourcePlanningException(
            ResourcePlanningErrorKind.invalid,
            violations: <ApiCode>[ApiCode('employee_not_found')],
          ),
        ),
        'Employee not found or without an active contract',
      );
      expect(
        resourcePlanningErrorMessage(
          s,
          const ResourcePlanningException(ResourcePlanningErrorKind.invalid, detail: 'server says no'),
        ),
        'server says no',
      );
    });
  });
}
