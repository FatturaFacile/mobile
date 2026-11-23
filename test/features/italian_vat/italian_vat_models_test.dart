import 'package:fattura_facile/features/general_ledger/domain/gl_amount.dart';
import 'package:fattura_facile/features/italian_vat/domain/italian_vat_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

Amount4 a(String v) => amountFromJson(v);

void main() {
  group('VatRegister', () {
    test('parses lines, sectionals, lock and parameters of the answer', () {
      final VatRegister r = register(
        VatRegisterType.purchases,
        <Map<String, dynamic>>[lineJson(protocol: 7, sectional: 'D')],
        meta: <String, dynamic>{
          'currency': 'EUR',
          'pro_rata_percent': '70.00',
          'sectionals': <Map<String, dynamic>>[
            <String, dynamic>{
              'code': 'D',
              'label': 'Deferred',
              'last_protocol': 7,
            },
          ],
          'lock': <String, dynamic>{
            'locked_at': '2027-04-10T08:00:00Z',
            'stamp_duty_pages': 12,
            'last_protocol': 7,
          },
        },
      );

      expect(r.lines.single.sectional, 'D');
      expect(r.sectionals.single.label, 'Deferred');
      expect(r.lock.definitive, isTrue);
      expect(r.lock.stampDutyPages, 12);
      expect(r.proRata, a('70.00'));
      expect(r.hasProRata, isTrue);
      expect(r.lastProtocol, 7);
    });

    test('an unlocked register is provisional and counts the lines still without a protocol', () {
      final VatRegister r = register(
        VatRegisterType.sales,
        <Map<String, dynamic>>[
          lineJson(),
          lineJson(protocol: null, number: 'FA-2'),
        ],
      );

      expect(r.lock.definitive, isFalse);
      expect(r.unnumbered, 1);
      expect(r.lastProtocol, 1);
    });

    test('totals and the per-rate summary come from exact decimals', () {
      final VatRegister r = register(
        VatRegisterType.sales,
        <Map<String, dynamic>>[
          lineJson(taxable: '1000.10', vat: '220.02'),
          lineJson(
            protocol: 2,
            number: 'FA-2',
            taxable: '500.05',
            rate: '10.00',
            vat: '50.01',
          ),
          lineJson(
            protocol: 3,
            number: 'FA-3',
            taxable: '100.00',
            vat: '22.00',
          ),
        ],
      );

      expect(r.totalTaxable, a('1600.15'));
      expect(r.totalVat, a('292.03'));
      expect(r.byRate.map((RateTotal t) => t.vatRate), <Amount4>[
        a('22.00'),
        a('10.00'),
      ]);
      expect(r.byRate.first.taxable, a('1100.10'));
      expect(r.byRate.last.vat, a('50.01'));
    });

    test('filters by sectional and lists the codes sorted', () {
      final VatRegister r = register(
        VatRegisterType.sales,
        <Map<String, dynamic>>[
          lineJson(),
          lineJson(protocol: 2, number: 'FD-1', sectional: 'D'),
          lineJson(protocol: 3, number: 'AF-1', sectional: 'A'),
        ],
      );

      expect(r.sectionalCodes, <String>['A', 'D']);
      expect(r.linesOf('D').single.documentNumber, 'FD-1');
      expect(r.linesOf(null), hasLength(3));
    });

    test('the pro-rata splits the VAT of the purchases into deductible and non-deductible', () {
      final VatRegister r = register(
        VatRegisterType.purchases,
        <Map<String, dynamic>>[
          lineJson(vat: '220.00'),
          lineJson(
            protocol: 2,
            number: 'FA-2',
            rate: '10.00',
            taxable: '1100.00',
            vat: '110.00',
          ),
        ],
        meta: <String, dynamic>{'pro_rata_percent': '70.00'},
      );

      expect(r.totalDeductible, a('231.00'));
      expect(r.totalNonDeductible, a('99.00'));
    });

    test('a figure sent by the server wins over the local pro-rata split', () {
      final VatRegister r = register(
        VatRegisterType.purchases,
        <Map<String, dynamic>>[
          lineJson(deductible: '200.00', nonDeductible: '20.00'),
        ],
        meta: <String, dynamic>{'pro_rata_percent': '70.00'},
      );

      expect(r.totalDeductible, a('200.00'));
      expect(r.totalNonDeductible, a('20.00'));
    });

    test('without a pro-rata the purchases are fully deductible', () {
      final VatRegister r = register(
        VatRegisterType.purchases,
        <Map<String, dynamic>>[lineJson()],
      );

      expect(r.hasProRata, isFalse);
      expect(r.totalDeductible, a('220.00'));
      expect(r.totalNonDeductible, 0);
    });

    test('survives the round trip through the offline copy', () {
      final VatRegister r = register(
        VatRegisterType.receipts,
        <Map<String, dynamic>>[lineJson(sectional: 'Z')],
        meta: <String, dynamic>{
          'pro_rata_percent': '85.00',
          'ventilation': <String, dynamic>{
            'enabled': true,
            'purchase_basis': <Map<String, dynamic>>[
              <String, dynamic>{'vat_rate': '22.00', 'amount': '600.00'},
            ],
          },
          'lock': <String, dynamic>{'definitive': true},
        },
      );

      final VatRegister back = VatRegister.fromCache(r.toJson());

      expect(back.type, VatRegisterType.receipts);
      expect(back.from, DateTime(2027));
      expect(back.lines.single.sectional, 'Z');
      expect(back.proRata, a('85.00'));
      expect(back.ventilationEnabled, isTrue);
      expect(back.ventilation.single.purchases, a('600.00'));
      expect(back.lock.definitive, isTrue);
    });
  });

  group('ProRata', () {
    test('applies the percentage to the VAT rounded to the cent', () {
      expect(ProRata.deductible(a('220.00'), a('70.00')), a('154.00'));
      expect(ProRata.deductible(a('10.01'), a('33.00')), a('3.30'));
      expect(ProRata.deductible(a('0.05'), a('50.00')), a('0.03'));
    });

    test('keeps the sign of a credit note', () {
      expect(
        ProRata.deductible(a('220.00') * -1, a('70.00')),
        a('154.00') * -1,
      );
    });

    test('bounds the percentage between 0 and 100', () {
      expect(ProRata.deductible(a('100.00'), a('120.00')), a('100.00'));
      expect(ProRata.deductible(a('100.00'), -1), 0);
    });

    test('the yearly percentage rounds up to the next whole unit', () {
      expect(
        ProRata.percentOf(
          taxableOperations: a('7000'),
          exemptOperations: a('3000'),
        ),
        a('70'),
      );
      expect(
        ProRata.percentOf(
          taxableOperations: a('6850'),
          exemptOperations: a('3150'),
        ),
        a('69'),
      );
    });

    test(
      'has no percentage without exempt operations or without operations',
      () {
        expect(
          ProRata.percentOf(taxableOperations: a('7000'), exemptOperations: 0),
          isNull,
        );
        expect(
          ProRata.percentOf(taxableOperations: 0, exemptOperations: 0),
          isNull,
        );
      },
    );
  });

  group('Ventilation', () {
    final List<VentilationBasis> basis = <VentilationBasis>[
      VentilationBasis(vatRate: a('10.00'), purchases: a('400.00')),
      VentilationBasis(vatRate: a('22.00'), purchases: a('600.00')),
    ];

    test('splits the gross receipts in proportion to the purchases, then scorporates each rate', () {
      final List<VentilatedShare> shares = Ventilation.allocate(
        a('1000.00'),
        basis,
      );

      expect(shares.map((VentilatedShare s) => s.vatRate), <Amount4>[
        a('22.00'),
        a('10.00'),
      ]);
      expect(shares[0].gross, a('600.00'));
      expect(shares[0].taxable, a('491.80'));
      expect(shares[0].vat, a('108.20'));
      expect(shares[1].gross, a('400.00'));
      expect(shares[1].taxable, a('363.64'));
      expect(shares[1].vat, a('36.36'));
    });

    test(
      'the shares always add up to the gross receipts, whatever the rounding',
      () {
        final List<VentilatedShare> shares = Ventilation.allocate(
          a('1000.01'),
          <VentilationBasis>[
            VentilationBasis(vatRate: a('4.00'), purchases: a('100.00')),
            VentilationBasis(vatRate: a('10.00'), purchases: a('100.00')),
            VentilationBasis(vatRate: a('22.00'), purchases: a('100.00')),
          ],
        );

        expect(
          shares.fold<int>(0, (int s, VentilatedShare x) => s + x.gross),
          a('1000.01'),
        );
        for (final VentilatedShare s in shares) {
          expect(s.taxable + s.vat, s.gross);
        }
      },
    );

    test(
      'skips rates without purchases and answers nothing without any weight',
      () {
        expect(
          Ventilation.allocate(a('100.00'), <VentilationBasis>[
            VentilationBasis(vatRate: a('4.00'), purchases: 0),
            VentilationBasis(vatRate: a('22.00'), purchases: a('50.00')),
          ]).single.vatRate,
          a('22.00'),
        );
        expect(
          Ventilation.allocate(a('100.00'), const <VentilationBasis>[]),
          isEmpty,
        );
        expect(Ventilation.allocate(0, basis), isEmpty);
      },
    );

    test(
      'a ventilated receipts register exposes the split of its gross total',
      () {
        final VatRegister r = register(
          VatRegisterType.receipts,
          <Map<String, dynamic>>[lineJson(taxable: '819.67', vat: '180.33')],
          meta: <String, dynamic>{
            'ventilation': <String, dynamic>{
              'enabled': true,
              'purchase_basis': <Map<String, dynamic>>[
                <String, dynamic>{'vat_rate': '22.00', 'amount': '600.00'},
                <String, dynamic>{'vat_rate': '10.00', 'amount': '400.00'},
              ],
            },
          },
        );

        expect(r.totalGross, a('1000.00'));
        expect(
          r.ventilatedShares.map((VentilatedShare s) => s.gross),
          <Amount4>[a('600.00'), a('400.00')],
        );
      },
    );

    test('other registers and plain receipts have no ventilated split', () {
      expect(
        register(VatRegisterType.sales, <Map<String, dynamic>>[
          lineJson(),
        ]).ventilatedShares,
        isEmpty,
      );
      expect(
        register(VatRegisterType.receipts, <Map<String, dynamic>>[
          lineJson(),
        ]).ventilatedShares,
        isEmpty,
      );
    });
  });

  group('IntentLetter', () {
    test('computes the remaining plafond and the used share', () {
      final IntentLetter l = letter();

      expect(l.remaining, a('75000.00'));
      expect(l.usedRatio, closeTo(0.25, 1e-9));
      expect(l.hasProtocol, isTrue);
    });

    test('a protocol must be 17 digits, a dash and 6 digits', () {
      expect(letter(protocol: '12345678901234567-00001').hasProtocol, isFalse);
      expect(letter(protocol: '').hasProtocol, isFalse);
    });

    test('survives the round trip through the offline copy', () {
      final IntentLetter back = IntentLetter.fromJson(letter().toJson());

      expect(back.authorized, a('100000.00'));
      expect(back.validTo, DateTime(2027, 12, 31));
      expect(back.kind, IntentLetterKind.upToAmount);
    });
  });

  group('PlafondGuard (art. 8 c. 1 lett. c DPR 633/1972)', () {
    final DateTime inside = DateTime(2027, 6, 15);

    test('allows an invoice that fits comfortably', () {
      final PlafondCheck c = PlafondGuard.evaluate(
        letter(),
        a('50000.00'),
        inside,
      );

      expect(c.result, PlafondResult.ok);
      expect(c.blocked, isFalse);
      expect(c.remainingAfter, a('25000.00'));
    });

    test('warns from 90% of the plafond but does not block', () {
      final PlafondCheck c = PlafondGuard.evaluate(
        letter(),
        a('65000.00'),
        inside,
      );

      expect(c.result, PlafondResult.nearLimit);
      expect(c.warning, isTrue);
      expect(c.blocked, isFalse);
    });

    test('allows an invoice that uses the plafond exactly', () {
      final PlafondCheck c = PlafondGuard.evaluate(
        letter(),
        a('75000.00'),
        inside,
      );

      expect(c.blocked, isFalse);
      expect(c.remainingAfter, 0);
      expect(c.excess, 0);
    });

    test(
      'blocks an invoice that exceeds the plafond and reports the excess',
      () {
        final PlafondCheck c = PlafondGuard.evaluate(
          letter(),
          a('80000.00'),
          inside,
        );

        expect(c.result, PlafondResult.exceedsPlafond);
        expect(c.blocked, isTrue);
        expect(c.excess, a('5000.00'));
        expect(c.remainingAfter, a('-5000.00'));
      },
    );

    test(
      'blocks outside the validity of the letter, the boundary days included',
      () {
        expect(
          PlafondGuard.evaluate(
            letter(),
            a('1.00'),
            DateTime(2026, 12, 31),
          ).result,
          PlafondResult.notYetValid,
        );
        expect(
          PlafondGuard.evaluate(letter(), a('1.00'), DateTime(2027)).blocked,
          isFalse,
        );
        expect(
          PlafondGuard.evaluate(
            letter(),
            a('1.00'),
            DateTime(2027, 12, 31, 23, 59),
          ).blocked,
          isFalse,
        );
        expect(
          PlafondGuard.evaluate(letter(), a('1.00'), DateTime(2028)).result,
          PlafondResult.expired,
        );
      },
    );

    test(
      'blocks a revoked or expired letter and one without the AdE protocol',
      () {
        expect(
          PlafondGuard.evaluate(
            letter(status: 'revoked'),
            a('1.00'),
            inside,
          ).result,
          PlafondResult.revoked,
        );
        expect(
          PlafondGuard.evaluate(
            letter(status: 'expired'),
            a('1.00'),
            inside,
          ).result,
          PlafondResult.expired,
        );
        expect(
          PlafondGuard.evaluate(letter(protocol: ''), a('1.00'), inside).result,
          PlafondResult.missingProtocol,
        );
      },
    );
  });

  group('IntentLetterDraft', () {
    IntentLetterDraft draft({
      String customer = 'Export Srl',
      String protocol = '12345678901234567-000001',
      Amount4? amount,
      DateTime? to,
    }) => IntentLetterDraft(
      customerName: customer,
      protocol: protocol,
      authorized: amount ?? a('50000.00'),
      validFrom: DateTime(2027),
      validTo: to ?? DateTime(2027, 12, 31),
    );

    test('a complete draft has no issue', () => expect(draft().issue, isNull));

    test('reports the first problem', () {
      expect(
        draft(customer: ' ').issue,
        IntentLetterDraftIssue.customerMissing,
      );
      expect(
        draft(protocol: '123').issue,
        IntentLetterDraftIssue.protocolFormat,
      );
      expect(draft(amount: 0).issue, IntentLetterDraftIssue.amountMissing);
      expect(
        draft(to: DateTime(2026)).issue,
        IntentLetterDraftIssue.periodInverted,
      );
    });

    test('the body sent to the server and the local placeholder agree', () {
      final IntentLetterDraft d = draft();
      final Map<String, dynamic> body = d.toJson();
      final IntentLetter p = d.toPlaceholder('tmp-1');

      expect(body['authorized_amount'], '50000.0000');
      expect(body['valid_to'], '2027-12-31');
      expect(p.pending, isTrue);
      expect(p.remaining, a('50000.00'));
      expect(p.id, 'tmp-1');
    });
  });

  group('LipeSettlement and Erario c/IVA', () {
    test('computes the balance with the carry-overs and interest', () {
      final LipeSettlement s = LipeSettlement.fromJson(<String, dynamic>{
        ...settlementJson(),
        'previous_debit': '100.00',
        'previous_credit': '30.00',
        'interest_amount': '5.00',
      });

      expect(s.netVat, a('2000.00'));
      expect(s.balance, a('2075.00'));
      expect(s.periodKey, '2027-Q1');
      expect(s.paid, isFalse);
    });

    test('reconciles when the ledger balance matches, within a cent', () {
      expect(
        settlement(erario: '2000.00').reconciliation.state,
        ReconciliationState.reconciled,
      );
      expect(
        settlement(erario: '2000.01').reconciliation.state,
        ReconciliationState.reconciled,
      );
    });

    test('reports the difference with its sign', () {
      final LipeReconciliation r = settlement(erario: '1990.00').reconciliation;

      expect(r.state, ReconciliationState.difference);
      expect(r.difference, a('-10.00'));
      expect(r.expected, a('2000.00'));
    });

    test('is unknown until the server sends the ledger balance', () {
      expect(settlement().reconciliation.state, ReconciliationState.unknown);
    });

    test('reads the LIPE file status', () {
      final LipeSettlement s = settlement(
        lipe: <String, dynamic>{
          'generated_at': '2027-05-02T10:00:00Z',
          'xsd_valid': true,
          'signature_status': 'signed',
        },
      );

      expect(s.file.generated, isTrue);
      expect(s.file.xsdValid, isTrue);
      expect(s.file.signature, SignatureStatus.signed);
      expect(s.file.readyToTransmit, isTrue);
    });

    test(
      'a file with XSD errors or no signature is not ready for Entratel',
      () {
        expect(
          settlement(
            lipe: <String, dynamic>{
              'generated': true,
              'xsd_valid': false,
              'xsd_errors': <String>['Element X is missing'],
              'signature_status': 'signed',
            },
          ).file.readyToTransmit,
          isFalse,
        );
        expect(
          settlement(
            lipe: <String, dynamic>{'generated': true, 'xsd_valid': true},
          ).file.readyToTransmit,
          isFalse,
        );
        expect(LipeFileStatus.none.readyToTransmit, isFalse);
      },
    );

    test('survives the round trip through the offline copy', () {
      final LipeSettlement back = LipeSettlement.fromJson(
        settlement(
          erario: '2000.00',
          lipe: <String, dynamic>{'generated': true, 'xsd_valid': true},
        ).toJson(),
      );

      expect(back.erarioBalance, a('2000.00'));
      expect(back.file.xsdValid, isTrue);
      expect(back.payable, a('2000.00'));
    });
  });

  group('AnnualVatSummary', () {
    final List<LipeSettlement> all = <LipeSettlement>[
      settlement(
        erario: '2000.00',
        payable: '1000.00',
        paidAt: '2027-05-16T00:00:00Z',
      ),
      settlement(
        id: 's2',
        period: 2,
        output: '4000.00',
        input: '4500.00',
        erario: '-500.00',
        payable: '0.00',
      ),
      LipeSettlement.fromJson(settlementJson(id: 'old', year: 2026)),
    ];

    test('adds up the settlements of the year only', () {
      final AnnualVatSummary s = AnnualVatSummary.build(2027, all);

      expect(s.periods.map((LipeSettlement x) => x.id), <String>['s1', 's2']);
      expect(s.output, a('9000.00'));
      expect(s.input, a('7500.00'));
      expect(s.balance, a('1500.00'));
      expect(s.paid, a('1000.00'));
      expect(s.stillDue, a('500.00'));
      expect(s.fromServer, isFalse);
    });

    test('reconciles with the Erario c/IVA account when every period carries its ledger balance', () {
      final AnnualVatSummary s = AnnualVatSummary.build(2027, all);

      expect(s.erarioBalance, a('1500.00'));
      expect(s.reconciliation, ReconciliationState.reconciled);
      expect(s.erarioDifference, 0);
    });

    test('flags a difference with the ledger', () {
      final AnnualVatSummary s = AnnualVatSummary.build(2027, <LipeSettlement>[
        settlement(erario: '1900.00'),
      ]);

      expect(s.reconciliation, ReconciliationState.difference);
      expect(s.erarioDifference, a('-100.00'));
    });

    test('is unknown when a period misses its ledger balance', () {
      final AnnualVatSummary s = AnnualVatSummary.build(2027, <LipeSettlement>[
        settlement(),
      ]);

      expect(s.erarioBalance, isNull);
      expect(s.reconciliation, ReconciliationState.unknown);
    });

    test('lists the quarters without a settlement', () {
      expect(AnnualVatSummary.build(2027, all).missingQuarters, <int>[3, 4]);
    });

    test('the figures of the server win over the local sums', () {
      final AnnualVatSummary s = AnnualVatSummary.build(
        2027,
        all,
        server: <String, dynamic>{
          'balance': '1600.00',
          'paid_amount': '1600.00',
          'credit_carried_forward': '12.00',
          'erario_balance': '1600.00',
        },
      );

      expect(s.fromServer, isTrue);
      expect(s.balance, a('1600.00'));
      expect(s.stillDue, 0);
      expect(s.creditCarriedForward, a('12.00'));
      expect(s.reconciliation, ReconciliationState.reconciled);
      expect(s.output, a('9000.00'));
    });

    test('a year without settlements is empty, not an error', () {
      final AnnualVatSummary s = AnnualVatSummary.build(2030, all);

      expect(s.periods, isEmpty);
      expect(s.balance, 0);
      expect(s.reconciliation, ReconciliationState.unknown);
    });
  });

  group('WithholdingCertificate (CU)', () {
    test('tells paid, partly paid and unpaid F24', () {
      expect(certificate().f24Status, F24Status.paid);
      expect(certificate(paid: '800.00').f24Status, F24Status.partial);
      expect(certificate(paid: '0.00').f24Status, F24Status.unpaid);
      expect(
        certificate(withheld: '0.00', paid: '0.00').f24Status,
        F24Status.paid,
      );
    });

    test('the open withholding is never negative', () {
      expect(certificate(paid: '800.00').f24Open, a('1200.00'));
      expect(certificate(paid: '2500.00').f24Open, 0);
    });

    test('agents carry the commission causale and tribute code', () {
      final WithholdingCertificate c = certificate(kind: 'agent');

      expect(c.kind, RecipientKind.agent);
      expect(c.causale, 'R');
      expect(c.f24Code, '1038');
    });

    test('totals the year', () {
      final CertificateTotals t = CertificateTotals.of(<WithholdingCertificate>[
        certificate(),
        certificate(id: 'cu2', paid: '500.00'),
      ]);

      expect(t.count, 2);
      expect(t.gross, a('20000.00'));
      expect(t.withheld, a('4000.00'));
      expect(t.f24Paid, a('2500.00'));
      expect(t.f24Open, a('1500.00'));
    });

    test('survives the round trip through the offline copy', () {
      final WithholdingCertificate back = WithholdingCertificate.fromJson(
        certificate(kind: 'agent').toJson(),
      );

      expect(back.recipientName, 'Rossi Mario');
      expect(back.f24PaidOn, DateTime(2027, 2, 16));
      expect(back.kind, RecipientKind.agent);
    });
  });

  group('register wire names and module keys', () {
    test('wire names map back to the register types', () {
      expect(
        VatRegisterType.fromWire('third-party-goods'),
        VatRegisterType.thirdPartyGoods,
      );
      expect(VatRegisterType.fromWire('x'), isNull);
    });

    test('the module keys unlock the workspace', () {
      expect(
        italianVatModules,
        containsAll(<String>['italian_vat', 'vat_registers']),
      );
    });
  });
}
