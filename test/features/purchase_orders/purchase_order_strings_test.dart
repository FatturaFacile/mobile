import 'package:fattura_facile/features/purchase_orders/domain/purchase_order_models.dart';
import 'package:fattura_facile/features/purchase_orders/presentation/purchase_order_strings.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

void main() {
  test('every locale defines every label', () {
    for (final MapEntry<String, Map<PO, String>> t
        in purchaseOrderLocaleTables.entries) {
      for (final PO key in PO.values) {
        expect(t.value[key], isNotNull, reason: '${t.key} misses $key');
        expect(t.value[key], isNotEmpty, reason: '${t.key} has empty $key');
      }
    }
  });

  test('the four supported locales are present', () {
    expect(purchaseOrderLocaleTables.keys.toSet(), <String>{
      'it',
      'de',
      'fr',
      'en',
    });
  });

  test('placeholders are kept in every translation', () {
    for (final Map<PO, String> t in purchaseOrderLocaleTables.values) {
      for (final PO key in <PO>[
        PO.overdueBadge,
        PO.overdueAlert,
        PO.remindersSent,
      ]) {
        expect(t[key], contains('{n}'));
      }
    }
  });

  test('regional language codes resolve to their language, unknown ones to English', () {
    expect(
      const PurchaseOrderStrings('de-CH')(PO.statusConfirmed),
      'Bestätigt',
    );
    expect(
      const PurchaseOrderStrings('it_IT')(PO.statusConfirmed),
      'Confermato',
    );
    expect(const PurchaseOrderStrings('FR')(PO.statusConfirmed), 'Confirmée');
    expect(const PurchaseOrderStrings('xx')(PO.statusConfirmed), 'Confirmed');
  });

  test('count fills the placeholder', () {
    expect(
      const PurchaseOrderStrings('en').count(PO.overdueBadge, 4),
      'Overdue 4 d',
    );
  });

  test('an unknown status prints the raw server text', () {
    expect(
      const PurchaseOrderStrings('en').status(order(status: 'on_hold')),
      'on_hold',
    );
  });

  test('a server detail replaces the generic invalid message', () {
    const PurchaseOrderStrings s = PurchaseOrderStrings('en');

    expect(
      s.error(
        const PoException(PoErrorKind.invalid, detail: 'Order is closed'),
      ),
      'Order is closed',
    );
    expect(
      s.error(const PoException(PoErrorKind.invalid)),
      'The server rejected the data.',
    );
  });
}
