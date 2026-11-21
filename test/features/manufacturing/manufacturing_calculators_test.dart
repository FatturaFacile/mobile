import 'package:fattura_facile/features/manufacturing/domain/calculators/oee_calculator.dart';
import 'package:fattura_facile/features/manufacturing/domain/calculators/routing_lead_time_cost_calculator.dart';
import 'package:fattura_facile/features/manufacturing/domain/entities/manufacturing_models.dart';
import 'package:flutter_test/flutter_test.dart';

const MfgWorkCenter _wc = MfgWorkCenter(
  id: 'wc-1',
  code: 'WC-1',
  name: 'Milling',
  hourlySetupCostRate: 60,
  hourlyMachineRunCostRate: 120,
  hourlyCostRate: 30,
  hourlyOverheadRate: 12,
);

MfgRouting _routing(List<MfgRoutingStep> steps) => MfgRouting(
  id: 'r-1',
  routingNumber: 'RT-1',
  name: 'Shaft',
  revision: 'A',
  status: 'active',
  steps: steps,
);

void main() {
  group('RoutingLeadTimeCostCalculator', () {
    test('computes lead time and cost split of a single machined step', () {
      final RoutingLeadTimeCostResult r =
          RoutingLeadTimeCostCalculator.calculate(
            _routing(const <MfgRoutingStep>[
              MfgRoutingStep(
                id: 's1',
                sequence: 10,
                operationCode: 'OP10',
                name: 'Mill',
                workCenterId: 'wc-1',
                setupTimeMinutes: 30,
                runTimeMinutesPerUnit: 2,
                queueTimeMinutes: 5,
              ),
            ]),
            workCenters: <String, MfgWorkCenter>{'wc-1': _wc},
            quantity: 10,
          );
      expect(r.totalMinutes, 55);
      expect(r.serialMinutes, 55);
      expect(r.overlapSavingMinutes, 0);
      expect(r.steps.single.runMinutes, 20);
      expect(r.cost.setup, 30);
      expect(r.cost.machineRun, 40);
      expect(r.cost.directLabor, 10);
      expect(r.cost.overhead, 10);
      expect(r.cost.total, 90);
      expect(r.unitCost, 9);
    });

    test('overlap lets the next step start after the first transfer batch', () {
      final MfgRouting routing = _routing(const <MfgRoutingStep>[
        MfgRoutingStep(
          id: 's1',
          sequence: 10,
          operationCode: 'OP10',
          name: 'A',
          workCenterId: 'wc-1',
          runTimeMinutesPerUnit: 1,
          overlapTransferBatchQty: 10,
        ),
        MfgRoutingStep(
          id: 's2',
          sequence: 20,
          operationCode: 'OP20',
          name: 'B',
          workCenterId: 'wc-1',
          runTimeMinutesPerUnit: 1,
        ),
      ]);
      final Map<String, MfgWorkCenter> wcs = <String, MfgWorkCenter>{
        'wc-1': _wc,
      };
      final RoutingLeadTimeCostResult on =
          RoutingLeadTimeCostCalculator.calculate(
            routing,
            workCenters: wcs,
            quantity: 100,
          );
      expect(on.serialMinutes, 200);
      expect(on.totalMinutes, 110);
      expect(on.overlapSavingMinutes, 90);
      expect(on.steps.first.overlapApplied, isTrue);
      expect(on.steps.last.startOffsetMinutes, 10);

      final RoutingLeadTimeCostResult off =
          RoutingLeadTimeCostCalculator.calculate(
            routing,
            workCenters: wcs,
            quantity: 100,
            includeOverlap: false,
          );
      expect(off.totalMinutes, 200);
      expect(off.steps.first.overlapApplied, isFalse);
    });

    test('machine parallel units and efficiency scale run time; subcontracting is priced per unit', () {
      final RoutingLeadTimeCostResult r =
          RoutingLeadTimeCostCalculator.calculate(
            _routing(const <MfgRoutingStep>[
              MfgRoutingStep(
                id: 's1',
                sequence: 10,
                operationCode: 'OP10',
                name: 'Mill',
                workCenterId: 'wc-1',
                machineCenterId: 'm-1',
                runTimeMinutesPerUnit: 3,
              ),
              MfgRoutingStep(
                id: 's2',
                sequence: 20,
                operationCode: 'OP20',
                name: 'Paint',
                workCenterId: 'wc-1',
                operationType: 'external_subcontracting',
                subcontractUnitCost: 2.5,
              ),
            ]),
            workCenters: <String, MfgWorkCenter>{'wc-1': _wc},
            machines: <String, MfgMachine>{
              'm-1': const MfgMachine(
                id: 'm-1',
                code: 'M1',
                name: 'Mill 1',
                workCenterId: 'wc-1',
                parallelCapacityUnits: 2,
                efficiencyFactorPercent: 50,
              ),
            },
            quantity: 4,
          );
      // divisor = 2 * 0.5 = 1 -> run = 3 * 4
      expect(r.steps.first.runMinutes, 12);
      expect(r.steps.last.cost.subcontracting, 10);
      expect(r.cost.subcontracting, 10);
      expect(r.cost.material, 0);
    });

    test(
      'rejects non-positive quantity, empty routing and unknown work centre',
      () {
        expect(
          () => RoutingLeadTimeCostCalculator.calculate(
            _routing(const <MfgRoutingStep>[]),
            workCenters: const <String, MfgWorkCenter>{},
          ),
          throwsA(isA<RoutingCalculationException>()),
        );
        expect(
          () => RoutingLeadTimeCostCalculator.calculate(
            _routing(const <MfgRoutingStep>[
              MfgRoutingStep(
                id: 's',
                sequence: 1,
                operationCode: 'X',
                name: 'X',
                workCenterId: 'missing',
              ),
            ]),
            workCenters: const <String, MfgWorkCenter>{},
          ),
          throwsA(
            isA<RoutingCalculationException>().having(
              (RoutingCalculationException e) => e.field,
              'field',
              'work_center_id',
            ),
          ),
        );
        expect(
          () => RoutingLeadTimeCostCalculator.calculate(
            _routing(const <MfgRoutingStep>[]),
            workCenters: const <String, MfgWorkCenter>{},
            quantity: 0,
          ),
          throwsA(
            isA<RoutingCalculationException>().having(
              (RoutingCalculationException e) => e.field,
              'field',
              'quantity',
            ),
          ),
        );
      },
    );
  });

  group('OeeCalculator', () {
    test('combines availability, performance and quality', () {
      final OeeResult r = OeeCalculator.calculate(
        scheduledMinutes: 480,
        idealCycleMinutesPerUnit: 1,
        logs: const <OeeLogInput>[
          OeeLogInput(
            plannedDowntimeMinutes: 30,
            unplannedDowntimeMinutes: 60,
            goodUnits: 300,
            scrapUnits: 10,
            reworkUnits: 10,
          ),
        ],
      );
      expect(r.plannedProductionMinutes, 450);
      expect(r.operatingMinutes, 390);
      expect(r.availabilityPercent, 86.67);
      expect(r.performancePercent, 82.05);
      expect(r.qualityPercent, 93.75);
      expect(r.oeePercent, 66.67);
    });

    test('clamps performance to 100 percent and defaults quality to 1 without units', () {
      final OeeResult fast = OeeCalculator.calculate(
        scheduledMinutes: 100,
        idealCycleMinutesPerUnit: 1,
        logs: const <OeeLogInput>[OeeLogInput(goodUnits: 500)],
      );
      expect(fast.performance, 1);
      expect(fast.oeePercent, 100);

      final OeeResult idle = OeeCalculator.calculate(
        scheduledMinutes: 100,
        idealCycleMinutesPerUnit: 1,
        logs: const <OeeLogInput>[],
      );
      expect(idle.quality, 1);
      expect(idle.performance, 0);
      expect(idle.oee, 0);
    });

    test('zero planned time yields zero availability', () {
      final OeeResult r = OeeCalculator.calculate(
        scheduledMinutes: 60,
        idealCycleMinutesPerUnit: 1,
        logs: const <OeeLogInput>[OeeLogInput(plannedDowntimeMinutes: 90)],
      );
      expect(r.plannedProductionMinutes, 0);
      expect(r.availability, 0);
    });

    test(
      'ideal cycle falls back machine -> work-centre mean -> routing mean',
      () {
        expect(OeeCalculator.idealCycleMinutes(machineCycleSeconds: 90), 1.5);
        expect(
          OeeCalculator.idealCycleMinutes(
            workCenterMachineCycleSeconds: <double>[60, 120, 0],
          ),
          1.5,
        );
        expect(
          OeeCalculator.idealCycleMinutes(
            workCenterMachineCycleSeconds: <double>[60],
            machineScope: true,
            routingRunMinutesPerUnit: <double>[2, 4],
          ),
          3,
        );
        expect(OeeCalculator.idealCycleMinutes(), 0);
      },
    );
  });

  group('API models', () {
    test(
      'MfgRouting sorts operations by sequence and parses decimal strings',
      () {
        final MfgRouting r = MfgRouting.fromJson(<String, dynamic>{
          'id': 'r-1',
          'routing_number': 'RT-1',
          'name': 'Shaft',
          'revision': 'B',
          'status': 'active',
          'is_default': true,
          'item_code': 'IT-9',
          'operations': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'o2',
              'sequence': 20,
              'operation_code': 'OP20',
              'name': 'B',
              'work_center_id': 'wc-1',
              'run_time_minutes_per_unit': '1.500',
            },
            <String, dynamic>{
              'id': 'o1',
              'sequence': 10,
              'operation_code': 'OP10',
              'name': 'A',
              'work_center_id': 'wc-1',
              'setup_time_minutes': '12.250',
              'overlap_transfer_batch_qty': '5.0000',
              'required_operators': 2,
            },
          ],
        });
        expect(r.isDefault, isTrue);
        expect(r.steps.map((MfgRoutingStep s) => s.id), <String>['o1', 'o2']);
        expect(r.steps.first.setupTimeMinutes, 12.25);
        expect(r.steps.first.overlapTransferBatchQty, 5);
        expect(r.steps.first.requiredOperators, 2);
        expect(r.steps.last.runTimeMinutesPerUnit, 1.5);
      },
    );

    test('MfgOeeSummary parses the /oee/summary payload', () {
      final MfgOeeSummary s = MfgOeeSummary.fromJson(<String, dynamic>{
        'work_center_id': 'wc-1',
        'machine_center_id': null,
        'from': '2026-11-01T00:00:00+00:00',
        'to': '2026-11-21T00:00:00+00:00',
        'summary': <String, dynamic>{
          'oee_percent': 66.67,
          'availability_percent': 86.67,
          'good_units': 300,
        },
        'targets_percent': <String, dynamic>{'oee': 85.0},
        'meets_target': false,
        'gap_to_target_percent': -18.33,
        'six_big_losses': <String, dynamic>{
          'equipment_failure': <String, dynamic>{
            'minutes': 60.0,
            'factor': 'availability',
          },
        },
      });
      expect(s.machineCenterId, isNull);
      expect(s.metrics.oeePercent, 66.67);
      expect(s.targetOeePercent, 85);
      expect(s.meetsTarget, isFalse);
      expect(s.losses['equipment_failure'], 60);
    });

    test('MfgMachine and MfgWorkCenter map API aliases', () {
      final MfgWorkCenter wc = MfgWorkCenter.fromJson(<String, dynamic>{
        'id': 'wc-1',
        'work_center_code': 'WC-1',
        'name': 'Milling',
        'efficiency_factor_percent': '90.00',
        'hourly_labor_cost_rate': '31.5',
        'parallel_capacity_units': 2,
      });
      expect(wc.efficiencyPercent, 90);
      expect(wc.hourlyCostRate, 31.5);
      final MfgMachine m = MfgMachine.fromJson(<String, dynamic>{
        'id': 'm-1',
        'machine_code': 'M1',
        'name': 'Mill 1',
        'work_center_id': 'wc-1',
        'is_industria_40_enabled': true,
        'telemetry_last_seen_at': '2026-11-21T10:00:00+00:00',
        'ideal_cycle_time_seconds_per_unit': '45',
      });
      expect(m.industria40, isTrue);
      expect(m.telemetryLastSeenAt, isNotNull);
      expect(m.idealCycleTimeSecondsPerUnit, 45);
    });
  });
}
