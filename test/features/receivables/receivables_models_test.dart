import 'package:fattura_facile/features/receivables/domain/money.dart';
import 'package:fattura_facile/features/receivables/domain/receivables_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

void main() {
  group('items', () {
    test('parse the wire shape with money as exact decimals', () {
      final ReceivableItem i = ReceivableItem.fromJson(
        itemJson(
          'i1',
          open: '60.10',
          original: '100.10',
          settled: '40.00',
          days: 12,
          status: 'overdue',
          disputeReason: 'wrong price',
          allocations: <Map<String, dynamic>>[allocationJson('a1', 'i1')],
        ),
      );
      expect(i.id, 'i1');
      expect(i.customerId, 'c1');
      expect(i.openAmount, Money.parse('60.10'));
      expect(i.originalAmount - i.settledAmount, i.openAmount);
      expect(i.status, ItemStatus.overdue);
      expect(i.isOverdue, isTrue);
      expect(i.daysPastDue, 12);
      expect(i.dueDate, DateTime(2030, 2, 1));
      expect(i.disputeReason, 'wrong price');
      expect(i.allocations.single.type, AllocationType.payment);
      expect(i.allocations.single.amount, Money.parse('40.00'));
      expect(i.canAllocate, isTrue);
    });

    test(
      'an unknown status never throws and settled items cannot be booked',
      () {
        expect(ItemStatus.fromWire('weird'), ItemStatus.unknown);
        expect(item('a', status: 'paid', open: '0.00').canAllocate, isFalse);
        expect(
          item('a', status: 'written_off', open: '0.00').canAllocate,
          isFalse,
        );
        expect(item('a', status: 'disputed').canAllocate, isTrue);
        expect(item('a', status: 'disputed').isDisputed, isTrue);
      },
    );

    test('a malformed amount is a format error, not a silent zero', () {
      expect(
        () => ReceivableItem.fromJson(itemJson('i1', open: 'twelve')),
        throwsFormatException,
      );
    });

    test('reversed allocations are not offered for reversal', () {
      final ReceivableItem i = item(
        'i1',
        allocations: <Map<String, dynamic>>[
          allocationJson('a1', 'i1'),
          allocationJson('a2', 'i1', reversedAt: '2030-01-11T10:00:00Z'),
        ],
      );
      expect(i.allocations.length, 2);
      expect(i.allocations.last.isReversed, isTrue);
      expect(i.reversible.map((ReceivableAllocation a) => a.id), <String>[
        'a1',
      ]);
    });

    test('allocation types read both source_type and type', () {
      expect(
        ReceivableAllocation.fromJson(<String, dynamic>{
          'id': '1',
          'type': 'discount',
          'amount': '1.00',
        }).type,
        AllocationType.discount,
      );
      expect(
        ReceivableAllocation.fromJson(<String, dynamic>{
          'id': '1',
          'source_type': 'debit_adjustment',
          'amount': '-5.00',
        }).amount,
        Money.parse('-5.00'),
      );
    });

    test('sortItems puts the most overdue first, then the larger amount', () {
      final List<ReceivableItem> sorted = sortItems(<ReceivableItem>[
        item('a', days: 0, open: '500.00'),
        item('b', days: 30, open: '10.00'),
        item('c', days: 30, open: '90.00'),
        item('d', days: 5, open: '1.00'),
      ]);
      expect(sorted.map((ReceivableItem i) => i.id), <String>[
        'c',
        'b',
        'd',
        'a',
      ]);
    });
  });

  group('aging buckets', () {
    final List<AgingBucketDef> buckets = <AgingBucketDef>[
      for (final Map<String, dynamic> b in customBuckets)
        AgingBucketDef.fromJson(b),
    ];

    test('are read from the response, not hardcoded', () {
      final AgingReport r = AgingReport.fromJson(agingJson());
      expect(r.buckets.map((AgingBucketDef b) => b.key), <String>[
        'current',
        '1_15',
        '16_45',
        '46_plus',
      ]);
      expect(r.buckets[1].to, 15);
      expect(r.buckets.last.isOpenEnded, isTrue);
      expect(r.buckets.first.isCurrent, isTrue);
    });

    test('bucketKeyOf places days past due in the server buckets', () {
      expect(bucketKeyOf(-3, buckets), 'current');
      expect(bucketKeyOf(0, buckets), 'current');
      expect(bucketKeyOf(1, buckets), '1_15');
      expect(bucketKeyOf(15, buckets), '1_15');
      expect(bucketKeyOf(16, buckets), '16_45');
      expect(bucketKeyOf(45, buckets), '16_45');
      expect(bucketKeyOf(46, buckets), '46_plus');
      expect(bucketKeyOf(9999, buckets), '46_plus');
      expect(bucketKeyOf(5, const <AgingBucketDef>[]), isNull);
    });

    test('work with the default 30/60/90/120 definition as well', () {
      final AgingReport r = AgingReport.fromJson(<String, dynamic>{
        'buckets': <Map<String, dynamic>>[
          <String, dynamic>{'key': 'current', 'from': 0, 'to': 0},
          <String, dynamic>{'key': '1_30', 'from': 1, 'to': 30},
          <String, dynamic>{'key': '31_60', 'from': 31, 'to': 60},
          <String, dynamic>{'key': '61_90', 'from': 61, 'to': 90},
          <String, dynamic>{'key': '91_120', 'from': 91, 'to': 120},
          <String, dynamic>{'key': '121_plus', 'from': 121, 'to': null},
        ],
        'totals': <String, dynamic>{},
      });
      expect(bucketKeyOf(31, r.buckets), '31_60');
      expect(bucketKeyOf(121, r.buckets), '121_plus');
      expect(bucketKeyOf(120, r.buckets), '91_120');
    });

    test(
      'derive bounds from the keys when the response has no definitions',
      () {
        final AgingReport r = AgingReport.fromJson(<String, dynamic>{
          'totals': <String, dynamic>{
            'current': '1.00',
            '1_30': '2.00',
            '121_plus': '3.00',
          },
        });
        expect(r.buckets.map((AgingBucketDef b) => b.key), <String>[
          'current',
          '1_30',
          '121_plus',
        ]);
        expect(
          r.buckets[1],
          const AgingBucketDef(key: '1_30', from: 1, to: 30),
        );
        expect(r.buckets[2].to, isNull);
        expect(r.buckets[2].from, 121);
      },
    );

    test('totals, shares and the customers behind a bucket', () {
      final AgingReport r = AgingReport.fromJson(agingJson());
      expect(r.totalOf('1_15'), Money.parse('300.00'));
      expect(r.totalOf('nope'), Money.zero);
      expect(r.bucketSum, r.totalOpen);
      expect(r.shareOf('current'), 0.5);
      expect(r.shareOf('46_plus'), 0.05);
      expect(
        r.customersIn('16_45').map((AgingCustomer c) => c.customerId),
        <String>['c2'],
      );
      expect(
        r.customersIn('current').map((AgingCustomer c) => c.customerId),
        <String>['c1', 'c2'],
      );
      expect(r.customersIn('46_plus').single.customerName, 'Bianchi Sagl');
      expect(r.availableCurrencies, <String>['CHF']);
    });

    test('itemsInBucket drills down by days past due', () {
      final List<ReceivableItem> items = <ReceivableItem>[
        item('a', days: 0),
        item('b', days: 7),
        item('c', days: 20),
        item('d', days: 90),
      ];
      expect(
        itemsInBucket(items, '1_15', buckets).map((ReceivableItem i) => i.id),
        <String>['b'],
      );
      expect(
        itemsInBucket(
          items,
          '46_plus',
          buckets,
        ).map((ReceivableItem i) => i.id),
        <String>['d'],
      );
      expect(itemsInBucket(items, null, buckets), items);
    });
  });

  group('credit position', () {
    test('parses limit, exposure components, utilisation and overrides', () {
      final CreditPosition p = CreditPosition.fromJson(
        creditJson(overrides: <Map<String, dynamic>>[overrideJson()]),
      );
      expect(p.limit!.grantedLimit, Money.parse('1000.00'));
      expect(p.limit!.reactionPolicy, ReactionPolicy.blockOrder);
      expect(p.limit!.maxOverdueDays, 30);
      expect(p.limit!.isActive, isTrue);
      expect(p.exposure.openInvoices, Money.parse('600.00'));
      expect(p.exposure.maxDaysPastDue, 12);
      expect(p.utilizationPercent, 50);
      expect(p.availableCredit, Money.parse('300.00'));
      expect(p.overrides.single.scope, OverrideScope.order);
      expect(p.overrides.single.authorizedBy, 'Anna');
    });

    test(
      'exposure = invoices + delivery notes + orders - unreconciled payments',
      () {
        final CreditExposure e = CreditPosition.fromJson(creditJson()).exposure;
        expect(e.computedTotal, Money.parse('700.00'));
        expect(e.isConsistent, isTrue);
        const CreditExposure off = CreditExposure(
          openInvoices: Money(1000),
          totalExposure: Money(999),
        );
        expect(off.isConsistent, isFalse);
      },
    );

    test(
      'a customer without a limit has no utilisation or available credit',
      () {
        final CreditPosition p = CreditPosition.fromJson(
          creditJson(withLimit: false),
        );
        expect(p.limit, isNull);
        expect(p.utilizationPercent, isNull);
        expect(p.availableCredit, isNull);
        expect(p.level, UtilisationLevel.ok);
      },
    );

    test('utilisation levels switch at 80 and 100 percent', () {
      expect(utilisationLevel(null), UtilisationLevel.ok);
      expect(utilisationLevel(79.9), UtilisationLevel.ok);
      expect(utilisationLevel(80), UtilisationLevel.warning);
      expect(utilisationLevel(99.9), UtilisationLevel.warning);
      expect(utilisationLevel(100), UtilisationLevel.exceeded);
      expect(utilisationLevel(250), UtilisationLevel.exceeded);
    });

    test('utilisation and available credit can be recomputed offline', () {
      expect(
        computeUtilisationPercent(
          Money.parse('700.00'),
          Money.parse('1000.00'),
        ),
        70,
      );
      expect(
        computeUtilisationPercent(
          Money.parse('333.33'),
          Money.parse('1000.00'),
        ),
        33.3,
      );
      expect(computeUtilisationPercent(Money.parse('1.00'), null), isNull);
      expect(
        computeUtilisationPercent(Money.parse('1.00'), Money.zero),
        isNull,
      );
      expect(
        computeAvailableCredit(Money.parse('700.00'), Money.parse('1000.00')),
        Money.parse('300.00'),
      );
      expect(
        computeAvailableCredit(Money.parse('1200.00'), Money.parse('1000.00')),
        Money.zero,
      );
      expect(computeAvailableCredit(Money.parse('1.00'), null), isNull);
    });

    test('the alert is blocked, warning or none', () {
      expect(
        CreditPosition.fromJson(creditJson(blocked: true, outcome: 'block'))
            .alert,
        CreditAlert.blocked,
      );
      expect(
        CreditPosition.fromJson(creditJson(hold: true)).alert,
        CreditAlert.blocked,
      );
      expect(
        CreditPosition.fromJson(creditJson(outcome: 'block')).alert,
        CreditAlert.blocked,
      );
      expect(
        CreditPosition.fromJson(creditJson(outcome: 'warning')).alert,
        CreditAlert.warning,
      );
      expect(
        CreditPosition.fromJson(creditJson(utilization: 85)).alert,
        CreditAlert.warning,
      );
      // Overdue items with a limit set are a warning even below the thresholds.
      expect(CreditPosition.fromJson(creditJson()).alert, CreditAlert.warning);
      final CreditPosition clean = CreditPosition.fromJson(<String, dynamic>{
        ...creditJson(),
        'exposure': <String, dynamic>{},
      });
      expect(clean.alert, CreditAlert.none);
    });

    test('decision is read as an object or as a plain outcome string', () {
      final CreditDecision d = CreditDecision.fromJson(<String, dynamic>{
        'outcome': 'block',
        'reason': 'Limit exceeded',
        'breaches': <dynamic>[
          'limit',
          <String, dynamic>{'code': 'overdue'},
        ],
        'overridden': true,
      });
      expect(d.outcome, DecisionOutcome.block);
      expect(d.reason, 'Limit exceeded');
      expect(d.breaches, <String>['limit', 'overdue']);
      expect(d.overridden, isTrue);
      expect(
        CreditDecision.fromJson('warning').outcome,
        DecisionOutcome.warning,
      );
      expect(CreditDecision.fromJson(null).outcome, DecisionOutcome.ok);
    });

    test('overrides are active until revoked or expired', () {
      final DateTime now = DateTime.utc(2030, 6, 1);
      expect(CreditOverride.fromJson(overrideJson()).isActiveAt(now), isTrue);
      expect(
        CreditOverride.fromJson(overrideJson(expiresAt: '2030-05-31T00:00:00Z'))
            .isActiveAt(now),
        isFalse,
      );
      expect(
        CreditOverride.fromJson(overrideJson(revokedAt: '2030-05-01T00:00:00Z'))
            .isActiveAt(now),
        isFalse,
      );
      expect(
        CreditOverride.fromJson(overrideJson(expiresAt: null)).isActiveAt(now),
        isTrue,
      );
      final CreditPosition p = CreditPosition.fromJson(
        creditJson(
          overrides: <Map<String, dynamic>>[
            overrideJson(),
            overrideJson(id: 'o2', revokedAt: '2030-05-01T00:00:00Z'),
          ],
        ),
      );
      expect(p.activeOverrides(now).map((CreditOverride o) => o.id), <String>[
        'o1',
      ]);
    });
  });

  group('risk, dso and provision', () {
    test('risk reads the rating and derives it from the score when absent', () {
      final RiskScore r = RiskScore.fromJson(riskJson());
      expect(r.rating, RiskRating.high);
      expect(r.score, 62.4);
      expect(r.factors.single.key, 'overdue_ratio');
      expect(r.factors.single.value, '0.4');
      expect(r.factors.single.points, 20);
      expect(
        RiskScore.fromJson(<String, dynamic>{'score': 80}).rating,
        RiskRating.critical,
      );
      expect(RiskRating.fromScore(24.9), RiskRating.low);
      expect(RiskRating.fromScore(25), RiskRating.medium);
      expect(RiskRating.fromScore(50), RiskRating.high);
      expect(RiskRating.fromScore(75), RiskRating.critical);
    });

    test(
      'dso is null without sales and matches receivables / sales x days',
      () {
        final DsoResult d = DsoResult.fromJson(<String, dynamic>{
          'as_of': '2030-02-10',
          'period_days': 90,
          'currency': 'CHF',
          'receivables': '1000.00',
          'credit_sales': '4000.00',
          'dso': 22.5,
        });
        expect(d.dso, 22.5);
        expect(
          DsoResult.compute(d.receivables, d.creditSales, d.periodDays),
          22.5,
        );
        expect(
          DsoResult.fromJson(<String, dynamic>{
            'receivables': '10.00',
            'credit_sales': '0.00',
            'dso': null,
          }).dso,
          isNull,
        );
        expect(DsoResult.compute(Money.parse('10.00'), Money.zero, 90), isNull);
      },
    );

    test('provision lines multiply the open amount by the rate', () {
      final ProvisionReport p = ProvisionReport.fromJson(<String, dynamic>{
        'currency': 'CHF',
        'lines': <Map<String, dynamic>>[
          <String, dynamic>{
            'key': '1_30',
            'from': 1,
            'to': 30,
            'open_amount': '200.00',
            'rate_percent': 1,
            'provision': '2.00',
            'is_default_rate': true,
          },
          <String, dynamic>{
            'key': '121_plus',
            'from': 121,
            'to': null,
            'open_amount': '100.00',
            'rate_percent': 50,
            'provision': '50.00',
            'is_default_rate': false,
          },
        ],
        'total_open': '300.00',
        'total_provision': '52.00',
        'net_realizable_value': '248.00',
      });
      expect(p.lines.length, 2);
      expect(p.lines.last.bucket.isOpenEnded, isTrue);
      expect(p.lines.last.isDefaultRate, isFalse);
      expect(
        Money.sum(p.lines.map((ProvisionLine l) => l.provision)),
        p.totalProvision,
      );
      expect(p.totalOpen - p.totalProvision, p.netRealizableValue);
    });
  });

  group('dashboard and statement', () {
    test('dashboard carries KPIs, aging and blocked customers', () {
      final ReceivablesDashboard d = ReceivablesDashboard.fromJson(
        dashboardJson(),
      );
      expect(d.kpis.totalExposure, Money.parse('1500.00'));
      expect(d.kpis.dso, 42.5);
      expect(d.kpis.blockedCustomers, 1);
      expect(d.aging.customers.length, 2);
      expect(d.blocked.single.customerId, 'c2');
      expect(d.blocked.single.limit, Money.parse('1000.00'));
      expect(d.currency, 'CHF');
    });

    test('statement balances reconcile with the movements', () {
      final CustomerStatement s = CustomerStatement.fromJson(statementJson());
      expect(s.customerName, 'Rossi SA');
      expect(s.from, DateTime(2030, 1, 1));
      expect(s.movements.length, 2);
      expect(s.movements.last.credit, Money.parse('120.00'));
      expect(s.computedClosing, s.closingBalance);
      expect(s.openItems.single.openAmount, Money.parse('180.00'));
      expect(s.aging['1_15'], Money.parse('100.00'));
    });

    test('statement aging also accepts the /aging shape with totals', () {
      final CustomerStatement s = CustomerStatement.fromJson(<String, dynamic>{
        ...statementJson(),
        'aging': <String, dynamic>{
          'buckets': customBuckets,
          'totals': <String, dynamic>{'current': '5.00', '1_15': '6.00'},
        },
      });
      expect(s.aging['current'], Money.parse('5.00'));
      expect(s.aging.length, 2);
    });
  });

  group('allocation drafts', () {
    AllocationDraft draft(
      AllocationType type,
      String amount, {
      String? sourceId,
    }) => AllocationDraft(
      itemId: 'i1',
      type: type,
      amount: Money.parse(amount),
      valueDate: DateTime(2030, 3, 4),
      sourceId: sourceId,
    );

    test('serialise to the POST /allocations line shape', () {
      final Map<String, dynamic> json = AllocationDraft(
        itemId: 'i1',
        type: AllocationType.creditNote,
        amount: Money.parse('12.5'),
        valueDate: DateTime(2030, 3, 4),
        sourceId: 'cn-1',
        reference: '  REF  ',
        notes: ' ',
      ).toJson();
      expect(json, <String, dynamic>{
        'receivable_item_id': 'i1',
        'type': 'credit_note',
        'amount': '12.50',
        'value_date': '2030-03-04',
        'source_id': 'cn-1',
        'reference': 'REF',
      });
      expect(
        draft(AllocationType.payment, '1').toJson().containsKey('source_id'),
        isFalse,
      );
    });

    test('are checked against the open amount and the source', () {
      const Money open = Money(10000);
      expect(
        validateDraft(
          draft(AllocationType.payment, '100.00'),
          openAmount: open,
        ),
        isEmpty,
      );
      expect(
        validateDraft(draft(AllocationType.payment, '0'), openAmount: open),
        <DraftIssue>[DraftIssue.amountInvalid],
      );
      expect(
        validateDraft(draft(AllocationType.discount, '-5'), openAmount: open),
        <DraftIssue>[DraftIssue.amountInvalid],
      );
      expect(
        validateDraft(
          draft(AllocationType.writeOff, '100.01'),
          openAmount: open,
        ),
        <DraftIssue>[DraftIssue.exceedsOpen],
      );
      expect(
        validateDraft(
          draft(AllocationType.creditNote, '10.00'),
          openAmount: open,
        ),
        <DraftIssue>[DraftIssue.sourceRequired],
      );
      expect(
        validateDraft(
          draft(AllocationType.creditNote, '10.00', sourceId: 'cn-1'),
          openAmount: open,
        ),
        isEmpty,
      );
      expect(
        validateDraft(
          draft(AllocationType.payment, '70.00', sourceId: 'le1'),
          openAmount: open,
          sourceAvailable: Money.parse('60.00'),
        ),
        <DraftIssue>[DraftIssue.exceedsSource],
      );
      // A debit adjustment raises the open amount, so it is not capped by it.
      expect(
        validateDraft(
          draft(AllocationType.debitAdjustment, '500.00'),
          openAmount: open,
        ),
        isEmpty,
      );
    });

    test('only four types can be booked from the phone', () {
      expect(AllocationType.bookable, <AllocationType>[
        AllocationType.payment,
        AllocationType.creditNote,
        AllocationType.writeOff,
        AllocationType.discount,
      ]);
    });

    test('formatApiDate pads', () {
      expect(formatApiDate(DateTime(2030, 1, 5)), '2030-01-05');
    });
  });
}
