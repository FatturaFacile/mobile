import 'package:fattura_facile/features/receivables/domain/money.dart';
import 'package:fattura_facile/features/receivables/domain/receivables_models.dart';
import 'package:fattura_facile/features/receivables/presentation/receivables_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

void main() {
  late FakeReceivablesRepository repo;
  late FakeStatementExporter exporter;
  late ProviderContainer container;

  ProviderContainer make({String? tenant = 't1'}) {
    final ProviderContainer c = ProviderContainer(
      overrides: [
        receivablesRepositoryProvider.overrideWithValue(repo),
        receivablesTenantIdProvider.overrideWithValue(tenant),
        receivablesClockProvider.overrideWithValue(() => DateTime(2030, 3, 4)),
        statementExporterProvider.overrideWithValue(exporter),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  setUp(() {
    repo = FakeReceivablesRepository()
      ..dashboardRemote = ReceivablesDashboard.fromJson(dashboardJson())
      ..agingRemote = AgingReport.fromJson(agingJson())
      ..agingCache = AgingReport.fromJson(agingJson())
      ..credit = CreditPosition.fromJson(creditJson())
      ..risk = RiskScore.fromJson(riskJson())
      ..unreconciled = <UnreconciledPayment>[
        UnreconciledPayment.fromJson(paymentJson()),
      ]
      ..items = <ReceivableItem>[
        item('i1', days: 0, open: '100.00'),
        item('i2', days: 7, open: '200.00'),
        item('i3', days: 30, open: '50.00'),
        item('x1', customerId: 'c9'),
      ]
      ..statementRemote = CustomerStatement.fromJson(statementJson());
    exporter = FakeStatementExporter();
    container = make();
  });

  group('dashboard', () {
    test('shows the offline copy first, then the fresh figures', () async {
      repo.dashboardCache = ReceivablesDashboard.fromJson(<String, dynamic>{
        ...dashboardJson(),
        'kpis': <String, dynamic>{
          ...(dashboardJson()['kpis'] as Map<String, dynamic>),
          'total_open': '1.00',
        },
      });
      final ReceivablesDashboardController ctrl = container.read(
        receivablesDashboardProvider.notifier,
      );
      final List<ReceivablesDashboardState> seen =
          <ReceivablesDashboardState>[];
      container.listen(
        receivablesDashboardProvider,
        (ReceivablesDashboardState? _, ReceivablesDashboardState next) =>
            seen.add(next),
      );

      await ctrl.load();

      expect(
        seen.any(
          (ReceivablesDashboardState s) =>
              s.fromCache && s.dashboard?.kpis.totalOpen == Money.parse('1.00'),
        ),
        isTrue,
      );
      final ReceivablesDashboardState done = container.read(
        receivablesDashboardProvider,
      );
      expect(done.dashboard!.kpis.totalOpen, Money.parse('1000.00'));
      expect(done.fromCache, isFalse);
      expect(done.loading, isFalse);
      expect(done.error, isNull);
      expect(repo.flushes, 1);
    });

    test('the outbox is flushed once per load, before the refresh', () async {
      await container.read(receivablesDashboardProvider.notifier).load();
      expect(repo.flushes, 1);
      expect(repo.dashboardCurrencies, hasLength(1));
    });

    test(
      'offline keeps the cached figures and flags them as an offline copy',
      () async {
        repo
          ..dashboardCache = ReceivablesDashboard.fromJson(dashboardJson())
          ..refreshError = const ReceivablesException(
            ReceivablesErrorKind.offline,
          );
        await container.read(receivablesDashboardProvider.notifier).load();
        final ReceivablesDashboardState s = container.read(
          receivablesDashboardProvider,
        );
        expect(s.dashboard, isNotNull);
        expect(s.fromCache, isTrue);
        expect(s.error!.kind, ReceivablesErrorKind.offline);
        expect(s.loading, isFalse);
      },
    );

    test('forbidden clears the figures', () async {
      repo
        ..dashboardCache = ReceivablesDashboard.fromJson(dashboardJson())
        ..refreshError = const ReceivablesException(
          ReceivablesErrorKind.forbidden,
        );
      await container.read(receivablesDashboardProvider.notifier).load();
      final ReceivablesDashboardState s = container.read(
        receivablesDashboardProvider,
      );
      expect(s.dashboard, isNull);
      expect(s.forbidden, isTrue);
    });

    test('changing the currency reloads with it', () async {
      final ReceivablesDashboardController ctrl = container.read(
        receivablesDashboardProvider.notifier,
      );
      await ctrl.load();
      await ctrl.setCurrency('EUR');
      expect(repo.dashboardCurrencies, <String?>[null, 'EUR']);
      expect(container.read(receivablesDashboardProvider).currency, 'EUR');
    });

    test('pending bookings are counted', () async {
      repo.pending = const <PendingBooking>[
        PendingBooking(
          queueUuid: 'q1',
          kind: ReceivablesActionKind.allocation,
          rejected: false,
          itemId: 'i1',
        ),
      ];
      await container.read(receivablesDashboardProvider.notifier).load();
      expect(
        container.read(receivablesDashboardProvider).pending,
        hasLength(1),
      );
    });

    test('without a session nothing happens', () async {
      container = make(tenant: null);
      await container.read(receivablesDashboardProvider.notifier).load();
      expect(container.read(receivablesDashboardProvider).dashboard, isNull);
      expect(repo.dashboardCurrencies, isEmpty);
    });
  });

  group('customer credit', () {
    test(
      'loads the position, risk, aging and only that customer\'s items',
      () async {
        final CustomerCreditController ctrl = container.read(
          customerCreditProvider.notifier,
        );
        await ctrl.load('c1', customerName: 'Rossi SA');
        final CustomerCreditState s = container.read(customerCreditProvider);
        expect(s.customerName, 'Rossi SA');
        expect(s.credit!.exposure.totalExposure, Money.parse('700.00'));
        expect(s.risk!.rating, RiskRating.high);
        expect(s.aging!.buckets.length, 4);
        expect(s.unreconciled.single.ledgerEntryId, 'le1');
        // Most overdue first, the other customer's item is not here.
        expect(s.items.map((ReceivableItem i) => i.id), <String>[
          'i3',
          'i2',
          'i1',
        ]);
        expect(s.loading, isFalse);
        expect(s.fromCache, isFalse);
      },
    );

    test('offline: the cached copy stays and an error is kept', () async {
      repo.refreshError = const ReceivablesException(
        ReceivablesErrorKind.offline,
      );
      await container.read(customerCreditProvider.notifier).load('c1');
      final CustomerCreditState s = container.read(customerCreditProvider);
      expect(s.credit, isNotNull);
      expect(s.items, hasLength(3));
      expect(s.fromCache, isTrue);
      expect(s.error!.kind, ReceivablesErrorKind.offline);
    });

    test('an aging bucket filters the items and totals them', () async {
      final CustomerCreditController ctrl = container.read(
        customerCreditProvider.notifier,
      );
      await ctrl.load('c1', bucket: '1_15');
      CustomerCreditState s = container.read(customerCreditProvider);
      expect(s.bucket, '1_15');
      expect(s.visibleItems.map((ReceivableItem i) => i.id), <String>['i2']);
      expect(s.visibleTotal, Money.parse('200.00'));

      ctrl.setBucket('16_45');
      s = container.read(customerCreditProvider);
      expect(s.visibleItems.map((ReceivableItem i) => i.id), <String>['i3']);

      ctrl.setBucket(null);
      s = container.read(customerCreditProvider);
      expect(s.visibleItems, hasLength(3));
      expect(s.visibleTotal, Money.parse('350.00'));
    });

    test('select opens an item', () async {
      final CustomerCreditController ctrl = container.read(
        customerCreditProvider.notifier,
      );
      await ctrl.load('c1');
      await ctrl.select('i2');
      expect(container.read(customerCreditProvider).selected!.id, 'i2');
    });

    group('allocate', () {
      late CustomerCreditController ctrl;

      setUp(() async {
        ctrl = container.read(customerCreditProvider.notifier);
        await ctrl.load('c1');
      });

      ReceivableItem open(String id) => container
          .read(customerCreditProvider)
          .items
          .firstWhere((ReceivableItem i) => i.id == id);

      test(
        'an invalid amount is refused locally and nothing is sent',
        () async {
          final List<DraftIssue> over = await ctrl.allocate(
            open('i1'),
            type: AllocationType.payment,
            amount: Money.parse('100.01'),
          );
          expect(over, <DraftIssue>[DraftIssue.exceedsOpen]);
          final List<DraftIssue> zero = await ctrl.allocate(
            open('i1'),
            type: AllocationType.payment,
            amount: Money.zero,
          );
          expect(zero, <DraftIssue>[DraftIssue.amountInvalid]);
          final List<DraftIssue> noSource = await ctrl.allocate(
            open('i1'),
            type: AllocationType.creditNote,
            amount: Money.parse('5'),
          );
          expect(noSource, <DraftIssue>[DraftIssue.sourceRequired]);
          expect(repo.allocations, isEmpty);
          expect(container.read(customerCreditProvider).busy, isFalse);
        },
      );

      test(
        'a payment against an unreconciled one is capped by what is left',
        () async {
          final List<DraftIssue> issues = await ctrl.allocate(
            open('i2'),
            type: AllocationType.payment,
            amount: Money.parse('70.00'),
            payment: repo.unreconciled.single,
          );
          expect(issues, <DraftIssue>[DraftIssue.exceedsSource]);
          expect(repo.allocations, isEmpty);
        },
      );

      test('a valid booking is sent with today as value date and the payment as source', () async {
        final List<DraftIssue> issues = await ctrl.allocate(
          open('i2'),
          type: AllocationType.payment,
          amount: Money.parse('60.00'),
          payment: repo.unreconciled.single,
          reference: 'BANK-9',
        );
        expect(issues, isEmpty);
        final AllocationDraft sent = repo.allocations.single.single;
        expect(sent.itemId, 'i2');
        expect(sent.amount, Money.parse('60.00'));
        expect(sent.sourceId, 'le1');
        expect(sent.valueDate, DateTime(2030, 3, 4));
        expect(sent.reference, 'BANK-9');

        final CustomerCreditState s = container.read(customerCreditProvider);
        expect(s.notice, ReceivablesNotice.allocated);
        expect(s.busy, isFalse);
        expect(open('i2').openAmount, Money.parse('140.00'));
      });

      test(
        'offline the booking is queued and the list already shows it',
        () async {
          repo
            ..nextStatus = BookingStatus.queued
            ..pending = const <PendingBooking>[
              PendingBooking(
                queueUuid: 'q1',
                kind: ReceivablesActionKind.allocation,
                rejected: false,
                itemId: 'i1',
              ),
            ];
          await ctrl.allocate(
            open('i1'),
            type: AllocationType.discount,
            amount: Money.parse('100.00'),
          );
          final CustomerCreditState s = container.read(customerCreditProvider);
          expect(s.notice, ReceivablesNotice.allocationQueued);
          expect(s.pendingFor('i1'), 1);
          expect(s.pendingFor('i2'), 0);
          expect(open('i1').status, ItemStatus.paid);
        },
      );

      test('a refusal is reported with the server detail', () async {
        repo
          ..nextStatus = BookingStatus.rejected
          ..nextDetail = 'Already settled';
        await ctrl.allocate(
          open('i1'),
          type: AllocationType.payment,
          amount: Money.parse('10.00'),
        );
        final CustomerCreditState s = container.read(customerCreditProvider);
        expect(s.notice, ReceivablesNotice.rejected);
        expect(s.noticeDetail, 'Already settled');
        expect(s.busy, isFalse);
        ctrl.clearNotice();
        expect(container.read(customerCreditProvider).notice, isNull);
      });
    });

    group('reverse and dispute', () {
      late CustomerCreditController ctrl;

      setUp(() async {
        ctrl = container.read(customerCreditProvider.notifier);
        await ctrl.load('c1');
      });

      test(
        'reverse sends the item and allocation and reports the outcome',
        () async {
          await ctrl.reverse('i1', 'a1');
          expect(repo.reversals.single, (itemId: 'i1', allocationId: 'a1'));
          expect(
            container.read(customerCreditProvider).notice,
            ReceivablesNotice.reversed,
          );
        },
      );

      test('reverse queued offline', () async {
        repo.nextStatus = BookingStatus.queued;
        await ctrl.reverse('i1', 'a1');
        expect(
          container.read(customerCreditProvider).notice,
          ReceivablesNotice.reverseQueued,
        );
      });

      test('a reversal that is already waiting is not sent again', () async {
        repo.pending = const <PendingBooking>[
          PendingBooking(
            queueUuid: 'q1',
            kind: ReceivablesActionKind.reversal,
            rejected: false,
            itemId: 'i1',
            allocationId: 'a1',
          ),
        ];
        await ctrl.load('c1');
        expect(
          container.read(customerCreditProvider).reversalPending('a1'),
          isTrue,
        );
        await ctrl.reverse('i1', 'a1');
        expect(repo.reversals, isEmpty);
      });

      test('a refused reversal does not block a retry', () async {
        repo.pending = const <PendingBooking>[
          PendingBooking(
            queueUuid: 'q1',
            kind: ReceivablesActionKind.reversal,
            rejected: true,
            itemId: 'i1',
            allocationId: 'a1',
          ),
        ];
        await ctrl.load('c1');
        expect(
          container.read(customerCreditProvider).reversalPending('a1'),
          isFalse,
        );
      });

      test('a dispute needs a reason', () async {
        expect(await ctrl.setDispute('i1', disputed: true), isFalse);
        expect(
          await ctrl.setDispute('i1', disputed: true, reason: '  '),
          isFalse,
        );
        expect(repo.disputes, isEmpty);

        expect(
          await ctrl.setDispute('i1', disputed: true, reason: 'wrong price'),
          isTrue,
        );
        expect(repo.disputes.single, (
          itemId: 'i1',
          disputed: true,
          reason: 'wrong price',
        ));
        expect(
          container.read(customerCreditProvider).notice,
          ReceivablesNotice.disputed,
        );
      });

      test('lifting a dispute needs no reason, online or queued', () async {
        await ctrl.setDispute('i1', disputed: false);
        expect(
          container.read(customerCreditProvider).notice,
          ReceivablesNotice.disputeLifted,
        );
        repo.nextStatus = BookingStatus.queued;
        await ctrl.setDispute('i1', disputed: false);
        expect(
          container.read(customerCreditProvider).notice,
          ReceivablesNotice.disputeLiftQueued,
        );
        await ctrl.setDispute('i1', disputed: true, reason: 'x');
        expect(
          container.read(customerCreditProvider).notice,
          ReceivablesNotice.disputeQueued,
        );
      });

      test(
        'retry and dismiss go to the repository and refresh the pending list',
        () async {
          repo.pending = const <PendingBooking>[
            PendingBooking(
              queueUuid: 'q1',
              kind: ReceivablesActionKind.dispute,
              rejected: true,
              itemId: 'i1',
            ),
          ];
          await ctrl.retry('q1');
          expect(repo.retried, <String>['q1']);
          repo.pending = const <PendingBooking>[];
          await ctrl.dismiss('q1');
          expect(repo.dismissed, <String>['q1']);
          expect(container.read(customerCreditProvider).pending, isEmpty);
        },
      );
    });
  });

  group('statement', () {
    test('loads the period from the start of the year until today', () async {
      final StatementController ctrl = container.read(
        statementProvider.notifier,
      );
      await ctrl.load('c1');
      final StatementState s = container.read(statementProvider);
      expect(s.from, DateTime(2030, 1, 1));
      expect(s.to, DateTime(2030, 3, 4));
      expect(s.statement!.closingBalance, Money.parse('280.00'));
      expect(s.loading, isFalse);
      expect(s.fromCache, isFalse);
    });

    test('offline keeps the cached statement', () async {
      repo
        ..statementCache = CustomerStatement.fromJson(statementJson())
        ..refreshError = const ReceivablesException(
          ReceivablesErrorKind.offline,
        );
      await container.read(statementProvider.notifier).load('c1');
      final StatementState s = container.read(statementProvider);
      expect(s.statement, isNotNull);
      expect(s.fromCache, isTrue);
      expect(s.error!.kind, ReceivablesErrorKind.offline);
    });

    test('export downloads the file and hands it to the share sheet', () async {
      final StatementController ctrl = container.read(
        statementProvider.notifier,
      );
      await ctrl.load(
        'c1',
        from: DateTime(2030, 1, 1),
        to: DateTime(2030, 2, 10),
      );
      await ctrl.export(StatementFormat.pdf);
      await ctrl.export(StatementFormat.xlsx);

      expect(repo.downloads.map((d) => d.format), <StatementFormat>[
        StatementFormat.pdf,
        StatementFormat.xlsx,
      ]);
      expect(repo.downloads.first.to, DateTime(2030, 2, 10));
      expect(exporter.shared.first.fileName, 'statement-c1-20300210.pdf');
      expect(exporter.shared.first.mimeType, 'application/pdf');
      expect(exporter.shared.first.length, 3);
      expect(exporter.shared.last.fileName, 'statement-c1-20300210.xlsx');
      expect(exporter.shared.last.mimeType, contains('spreadsheetml.sheet'));
      final StatementState s = container.read(statementProvider);
      expect(s.export, ExportResult.shared);
      expect(s.exporting, isFalse);
      ctrl.clearExport();
      expect(container.read(statementProvider).export, isNull);
    });

    test(
      'export offline and export failures are reported, never thrown',
      () async {
        final StatementController ctrl = container.read(
          statementProvider.notifier,
        );
        await ctrl.load('c1');

        repo.downloadError = const ReceivablesException(
          ReceivablesErrorKind.offline,
        );
        await ctrl.export(StatementFormat.pdf);
        expect(container.read(statementProvider).export, ExportResult.offline);

        repo.downloadError = const ReceivablesException(
          ReceivablesErrorKind.forbidden,
        );
        await ctrl.export(StatementFormat.pdf);
        expect(container.read(statementProvider).export, ExportResult.failed);

        repo.downloadError = null;
        exporter.failWith = StateError('share sheet closed');
        await ctrl.export(StatementFormat.pdf);
        expect(container.read(statementProvider).export, ExportResult.failed);
        expect(container.read(statementProvider).exporting, isFalse);
        expect(exporter.shared, isEmpty);
      },
    );

    test('export without a loaded customer does nothing', () async {
      await container
          .read(statementProvider.notifier)
          .export(StatementFormat.pdf);
      expect(repo.downloads, isEmpty);
    });
  });
}
