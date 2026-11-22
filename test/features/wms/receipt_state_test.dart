import 'package:fattura_facile/features/wms/data/wms_repository.dart';
import 'package:fattura_facile/features/wms/state/receipt_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

ReceiptDraft draftFor({Map<String, dynamic>? second}) =>
    ReceiptDraft.forTransfer(
      buildTransfer(
        lines: [
          lineJson('l1', shipped: '10.0000'),
          second ?? lineJson('l2', shipped: '5.0000'),
        ],
      ),
    );

void main() {
  group('ReceiptDraft', () {
    test('only lines with outstanding quantity are included', () {
      final draft = draftFor(
        second: lineJson('l2', shipped: '5.0000', received: '5.0000'),
      );
      expect(draft.lines.map((l) => l.line.id), ['l1']);
    });

    test('scan pre-fills good quantity with outstanding and marks the line scanned', () {
      final draft = draftFor().markScanned('l1');
      final line = draft.lines.first;
      expect(line.scanned, isTrue);
      expect(line.good, 10);
      expect(line.shortage, 0);
      expect(draft.lines[1].scanned, isFalse);
    });

    test('re-scanning keeps edited quantities', () {
      final draft = draftFor()
          .markScanned('l1')
          .setGood('l1', 7)
          .markScanned('l1');
      expect(draft.lines.first.good, 7);
    });

    test('scanning an unknown line leaves the draft untouched', () {
      final draft = draftFor();
      expect(identical(draft.markScanned('zzz'), draft), isTrue);
    });

    test('shortage = outstanding - good - damaged, computed live', () {
      var draft = draftFor().markScanned('l1');
      draft = draft.setGood('l1', 6).setDamaged('l1', 2);
      expect(draft.lines.first.shortage, 2);
      expect(draft.totalShortage, 2);
      expect(draft.totalDamaged, 2);
      draft = draft.setGood('l1', 8);
      expect(draft.lines.first.shortage, 0);
    });

    test('shortage never goes negative and float noise is removed', () {
      final over = draftFor().markScanned('l1').setGood('l1', 12);
      expect(over.lines.first.shortage, 0);
      final noisy = draftFor(second: lineJson('l2', shipped: '0.3000'))
          .markScanned('l2')
          .setGood('l2', 0.1)
          .setDamaged('l2', 0.1);
      expect(noisy.lines[1].shortage, 0.1);
    });

    test('validation: good + damaged must not exceed outstanding, quantities not negative', () {
      var draft = draftFor().markScanned('l1');
      draft = draft.setGood('l1', 8).setDamaged('l1', 3);
      expect(draft.lines.first.issue, LineIssue.exceedsOutstanding);
      expect(draft.allValid, isFalse);

      draft = draft.setDamaged('l1', 2);
      expect(draft.lines.first.issue, isNull);

      draft = draft.setGood('l1', -1);
      expect(draft.lines.first.issue, LineIssue.negative);
    });

    test('canSubmit requires every line scanned and valid', () {
      var draft = draftFor();
      expect(draft.canSubmit, isFalse);
      draft = draft.markScanned('l1');
      expect(draft.canSubmit, isFalse);
      draft = draft.markScanned('l2');
      expect(draft.canSubmit, isTrue);
      draft = draft.setGood('l2', 99);
      expect(draft.canSubmit, isFalse);
    });

    test('an empty draft can never be submitted', () {
      final draft = ReceiptDraft.forTransfer(
        buildTransfer(lines: [lineJson('l1', received: '10.0000')]),
      );
      expect(draft.lines, isEmpty);
      expect(draft.canSubmit, isFalse);
    });

    test(
      'partial vs final: switch drives finalReceipt and the expected outcome',
      () {
        var draft = draftFor().markScanned('l1').markScanned('l2');
        expect(draft.finalReceipt, isTrue);
        expect(draft.expectedOutcome, ReceiptOutcome.received);

        draft = draft.setGood('l1', 7);
        expect(draft.expectedOutcome, ReceiptOutcome.discrepancyPending);

        draft = draft.withPartial(true);
        expect(draft.finalReceipt, isFalse);
        expect(draft.expectedOutcome, ReceiptOutcome.partiallyReceived);
      },
    );

    test('damaged goods alone raise a discrepancy on a final receipt', () {
      final draft = draftFor()
          .markScanned('l1')
          .markScanned('l2')
          .setGood('l1', 9)
          .setDamaged('l1', 1);
      expect(draft.totalShortage, 0);
      expect(draft.expectedOutcome, ReceiptOutcome.discrepancyPending);
    });

    test('toInputs maps quantities and sends the reason only for lines with a discrepancy', () {
      final inputs = draftFor()
          .markScanned('l1')
          .markScanned('l2')
          .setGood('l1', 8)
          .setDamaged('l1', 1)
          .setReason('l1', ' broken box ')
          .setReason('l2', 'ignored')
          .toInputs();
      expect(inputs[0].toJson(), {
        'line_id': 'l1',
        'received_qty': 8.0,
        'damaged_qty': 1.0,
        'discrepancy_reason': 'broken box',
      });
      expect(inputs[1].toJson()['discrepancy_reason'], isNull);
    });
  });

  group('parseQuantityInput', () {
    test('accepts comma decimals, empty as zero, rejects text', () {
      expect(parseQuantityInput('2,5'), 2.5);
      expect(parseQuantityInput(' 4 '), 4);
      expect(parseQuantityInput(''), 0);
      expect(parseQuantityInput('x'), isNull);
    });
  });

  group('ReceiptController', () {
    late FakeWmsRepository repo;
    late ReceiptController controller;

    setUp(() {
      repo = FakeWmsRepository()..codes = {'111': 'l1', 'SKU-2': 'l2'};
      controller = ReceiptController(
        repository: repo,
        transfer: buildTransfer(),
      );
    });

    test(
      'scan matches a line by barcode or SKU and reports unknown codes',
      () async {
        expect(await controller.scan('111'), isTrue);
        expect(controller.draft.lines.first.scanned, isTrue);

        expect(await controller.scan('nope'), isFalse);
        expect(controller.error, 'Line not in transfer');

        expect(await controller.scan('  '), isFalse);
        expect(repo.calls.where((c) => c.startsWith('scan:')).length, 2);
      },
    );

    test(
      'submit is blocked until everything is scanned, then posts the receipt',
      () async {
        expect(await controller.submit(), isFalse);
        expect(repo.calls.where((c) => c.startsWith('receive')), isEmpty);

        await controller.scan('111');
        await controller.scan('SKU-2');
        controller.setGood('l1', 8);
        controller.setDamaged('l1', 2);
        controller.setReason('l1', 'crushed');
        controller.setPartial(true);

        expect(await controller.submit(), isTrue);
        expect(repo.lastFinal, isFalse);
        expect(repo.lastReceiptLines!.first.damagedQty, 2);
        expect(repo.lastReceiptLines!.first.reason, 'crushed');
        expect(controller.phase, ReceiptPhase.submitted);
        expect(controller.result, isNotNull);
        expect(controller.canSubmit, isFalse);
      },
    );

    test('API errors are exposed and the form stays editable', () async {
      repo.receiveError = const ApiException('Not in transit', statusCode: 422);
      await controller.scan('111');
      await controller.scan('SKU-2');
      expect(await controller.submit(), isFalse);
      expect(controller.error, 'Not in transit');
      expect(controller.phase, ReceiptPhase.idle);
      expect(controller.canSubmit, isTrue);
    });
  });
}
