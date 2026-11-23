import 'package:fattura_facile/features/purchase_orders/domain/purchase_order_models.dart';
import 'package:fattura_facile/features/supplier_rebates/domain/rebate_decimal.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

void main() {
  final DateTime today = DateTime(2026, 11, 23);

  List<Map<String, dynamic>> oneLine({String? promised, bool closed = false}) =>
      <Map<String, dynamic>>[lineJson(promised: promised, closed: closed)];

  group('PurchaseOrder', () {
    test('parses the resource with its dual unit of measure lines', () {
      final PurchaseOrder o = order(
        status: 'confirmed',
        promised: '2026-11-25',
        dropship: true,
      );

      expect(o.status, PoStatus.confirmed);
      expect(o.isDropship, isTrue);
      expect(o.supplierName, 'Alpina AG');
      expect(o.promisedDeliveryDate, DateTime(2026, 11, 25));
      final PoLine l = o.lines.single;
      expect(l.uom, 'BOX');
      expect(l.baseUom, 'PCS');
      expect(l.isDualUom, isTrue);
      expect(l.orderedBase, Dec.parse('120'));
      expect(l.discountCascade, <Dec>[Dec.parse('10'), Dec.parse('5')]);
    });

    test('an unknown status keeps its raw text', () {
      final PurchaseOrder o = order(status: 'on_hold');

      expect(o.status, PoStatus.unknown);
      expect(o.rawStatus, 'on_hold');
    });

    test('a line in its stock unit, or with factor 1, is not dual', () {
      expect(PoLine.fromJson(lineJson(uom: 'PCS')).isDualUom, isFalse);
      expect(PoLine.fromJson(lineJson(factor: '1.0000')).isDualUom, isFalse);
    });

    test(
      'derives the stock quantity from the factor when the server omits it',
      () {
        final Map<String, dynamic> j = lineJson()
          ..remove('quantity_base_ordered');

        expect(PoLine.fromJson(j).orderedBase, Dec.parse('120'));
      },
    );

    test('survives a toJson/fromJson round trip (the offline copy)', () {
      final PurchaseOrder o = order(
        status: 'confirmed',
        promised: '2026-11-25',
      );

      final PurchaseOrder back = PurchaseOrder.fromJson(o.toJson());

      expect(back.poNumber, o.poNumber);
      expect(back.status, PoStatus.confirmed);
      expect(back.promisedDeliveryDate, o.promisedDeliveryDate);
      expect(back.lines.single.discountCascade, o.lines.single.discountCascade);
      expect(back.lines.single.uomConversionFactor, Dec.parse('12'));
    });
  });

  group('overdue detection', () {
    test('an open order whose promised date has passed is overdue by the days elapsed', () {
      final PurchaseOrder o = order(
        status: 'confirmed',
        promised: '2026-11-10',
        lines: oneLine(),
      );

      expect(o.isOverdue(today), isTrue);
      expect(o.daysOverdue(today), 13);
      expect(o.overdueLines(today), hasLength(1));
    });

    test('a line promise wins over the order date', () {
      final PurchaseOrder o = order(
        promised: '2026-11-01',
        lines: oneLine(promised: '2026-12-01'),
      );

      expect(o.isOverdue(today), isFalse);
    });

    test('falls back to the requested date when nothing was promised', () {
      final PurchaseOrder future = order(lines: oneLine());
      final PurchaseOrder late = PurchaseOrder.fromJson(
        orderJson(expected: '2026-11-01', lines: oneLine()),
      );

      expect(future.isOverdue(today), isFalse);
      expect(late.isOverdue(today), isTrue);
    });

    test(
      'closed lines, a due date of today and non-open statuses never count',
      () {
        expect(
          order(promised: '2026-11-23', lines: oneLine()).isOverdue(today),
          isFalse,
        );
        expect(
          order(lines: oneLine(promised: '2026-11-01', closed: true))
              .isOverdue(today),
          isFalse,
        );
        expect(
          order(
            status: 'received',
            lines: oneLine(promised: '2026-11-01'),
          ).isOverdue(today),
          isFalse,
        );
        expect(
          order(
            status: 'draft',
            lines: oneLine(promised: '2026-11-01'),
          ).isOverdue(today),
          isFalse,
        );
      },
    );

    test('the radar row parses with the reminder state', () {
      final OverdueOrder r = OverdueOrder.fromJson(overdueJson());

      expect(r.daysOverdue, 12);
      expect(r.overdueLineIds, <String>['l1']);
      expect(r.reminderCount, 1);
      expect(r.nextReminderDue, isTrue);
      expect(OverdueOrder.fromJson(r.toJson()).order.id, 'o1');
    });
  });

  group('status rules', () {
    test(
      'only transmitted orders can be confirmed and only open ones are watched',
      () {
        expect(PoStatus.sent.canConfirm, isTrue);
        expect(PoStatus.confirmed.canConfirm, isTrue);
        expect(PoStatus.draft.canConfirm, isFalse);
        expect(PoStatus.received.canConfirm, isFalse);
        expect(PoStatus.partiallyReceived.isOpenForDelivery, isTrue);
        expect(PoStatus.closed.isOpenForDelivery, isFalse);
      },
    );

    test('a delivered dropshipment accepts no further delivery notice', () {
      expect(DropshipStatus.delivered.canRecordDelivery, isFalse);
      expect(DropshipStatus.partiallyDelivered.canRecordDelivery, isTrue);
      expect(DropshipStatus.pending.canRecordDelivery, isTrue);
    });
  });

  group('requests', () {
    test('a confirmation body carries only what was entered', () {
      final ConfirmationInput i = ConfirmationInput(
        confirmationNumber: ' AB-1 ',
        confirmedAt: DateTime(2026, 11, 14),
        lines: <ConfirmationLineInput>[
          ConfirmationLineInput(
            purchaseOrderLineId: 'l1',
            confirmedQuantity: Dec.parse('8'),
            confirmedUnitPrice: Dec.parse('105.5'),
            confirmedDeliveryDate: DateTime(2026, 11, 20),
            varianceReason: ' shortage ',
          ),
          const ConfirmationLineInput(purchaseOrderLineId: 'l2'),
        ],
      );

      final Map<String, dynamic> j = i.toJson();

      expect(j['confirmation_number'], 'AB-1');
      expect(j['confirmed_at'], '2026-11-14');
      expect(j.containsKey('notes'), isFalse);
      final List<dynamic> lines = j['lines'] as List<dynamic>;
      final Map<String, dynamic> first = lines[0] as Map<String, dynamic>;
      expect(first['confirmed_quantity'], '8.00');
      expect(first['confirmed_unit_price'], '105.50');
      expect(first['confirmed_delivery_date'], '2026-11-20');
      expect(first['variance_reason'], 'shortage');
      expect(lines[1], <String, dynamic>{'purchase_order_line_id': 'l2'});
    });

    test('a delivery body carries the proof reference and the delivered quantities', () {
      final DeliveryInput i = DeliveryInput(
        deliveredAt: DateTime(2026, 11, 22),
        deliveryProofReference: ' POD-9 ',
        lines: <DeliveryLineInput>[
          DeliveryLineInput(
            purchaseOrderLineId: 'l1',
            quantityDelivered: Dec.parse('6'),
          ),
        ],
      );

      expect(i.toJson(), <String, dynamic>{
        'delivered_at': '2026-11-22',
        'delivery_proof_reference': 'POD-9',
        'lines': <Map<String, dynamic>>[
          <String, dynamic>{
            'purchase_order_line_id': 'l1',
            'quantity_delivered': '6.00',
          },
        ],
      });
    });
  });

  group('dropship', () {
    test('assembles the address and reads the virtual stock movements', () {
      final Dropship d = Dropship.fromJson(dropshipJson());

      expect(d.status, DropshipStatus.ddtIssued);
      expect(d.recipientAddress, 'Via Roma 12, 6900 Lugano, CH');
      expect(d.movements.single.quantityBase, Dec.parse('120'));
      expect(
        Dropship.fromJson(d.toJson()).recipientAddress,
        d.recipientAddress,
      );
    });
  });

  group('confirmation', () {
    test('exposes the variances and the review flag', () {
      final PoConfirmation c = PoConfirmation.fromJson(confirmationJson());

      expect(c.requiresReview, isTrue);
      expect(c.priceVarianceTotal, Dec.parse('50'));
      expect(c.lines.single.hasVariance, isTrue);
      expect(c.lines.single.deliveryDelayDays, 10);
      expect(c.lines.single.varianceReason, 'Raw material shortage');
    });
  });

  group('PoPricing (offline estimate)', () {
    test('matches the server for a 10% + 5% cascade on a BOX of 12', () {
      final PricingPreview p = PoPricing.preview(
        PricingInput(
          quantity: Dec.parse('10'),
          unitPrice: Dec.parse('100'),
          discountCascade: <Dec>[Dec.parse('10'), Dec.parse('5')],
          uomConversionFactor: Dec.parse('12'),
          taxRate: Dec.parse('8.1'),
        ),
      );
      final PricingPreview server = PricingPreview.fromJson(previewJson());

      expect(p.netUnitPrice, server.netUnitPrice);
      expect(p.effectiveDiscountPercent, server.effectiveDiscountPercent);
      expect(p.lineNetAmount, server.lineNetAmount);
      expect(p.lineTaxAmount, server.lineTaxAmount);
      expect(p.lineTotalAmount, server.lineTotalAmount);
      expect(p.quantityBase, server.quantityBase);
      expect(p.netPricePerBaseUnit, server.netPricePerBaseUnit);
      expect(p.estimated, isTrue);
      expect(server.estimated, isFalse);
    });

    test(
      'without discounts, factor or rate it is plain quantity times price',
      () {
        final PricingPreview p = PoPricing.preview(
          PricingInput(quantity: Dec.parse('3'), unitPrice: Dec.parse('2.5')),
        );

        expect(p.effectiveDiscountPercent, Dec.zero);
        expect(p.lineNetAmount, Dec.parse('7.5'));
        expect(p.quantityBase, Dec.parse('3'));
        expect(p.lineNetAmountCompanyCurrency, Dec.parse('7.5'));
      },
    );

    test('applies the exchange rate to the company-currency amount', () {
      final PricingPreview p = PoPricing.preview(
        PricingInput(
          quantity: Dec.parse('1'),
          unitPrice: Dec.parse('100'),
          exchangeRate: Dec.parse('0.95'),
        ),
      );

      expect(p.lineNetAmountCompanyCurrency, Dec.parse('95'));
    });

    test(
      'a zero conversion factor is treated as 1 instead of dividing by zero',
      () {
        final PricingPreview p = PoPricing.preview(
          PricingInput(
            quantity: Dec.parse('2'),
            unitPrice: Dec.parse('10'),
            uomConversionFactor: Dec.zero,
          ),
        );

        expect(p.quantityBase, Dec.parse('2'));
        expect(p.netPricePerBaseUnit, Dec.parse('10'));
      },
    );
  });
}
