import 'package:fattura_facile/features/ai_cognitive/domain/ai_models.dart';
import 'package:flutter_test/flutter_test.dart';

Suggestion make({
  String id = 's',
  String kind = 'anomaly',
  String priority = 'high',
  String status = 'pending',
  double confidence = 0.5,
  DateTime? createdAt,
}) => Suggestion(
  id: id,
  kind: kind,
  status: status,
  priority: priority,
  confidence: confidence,
  createdAt: createdAt,
);

void main() {
  group('Suggestion.fromJson', () {
    test('parses the full backend resource', () {
      final Suggestion s = Suggestion.fromJson(const <String, dynamic>{
        'id': 'a1',
        'kind': 'sales_quote',
        'workflow': 'quote',
        'source_type': 'document',
        'source_reference': 'mobile-1',
        'source_text': 'quote 2 chairs',
        'proposed_payload': <String, dynamic>{
          'customer': 'Muster AG',
          'qty': 2,
        },
        'field_confidences': <String, dynamic>{'customer': 0.95, 'qty': 1},
        'confidence': 0.82,
        'amount': 240,
        'reasoning': 'Matched customer',
        'citations': <dynamic>[],
        'status': 'pending',
        'priority': 'normal',
        'decided_by': null,
        'expires_at': '2026-12-01T10:00:00Z',
        'created_at': '2026-11-20T10:00:00Z',
      });
      expect(s.id, 'a1');
      expect(s.kind, 'sales_quote');
      expect(s.proposedPayload['customer'], 'Muster AG');
      expect(s.fieldConfidences, <String, double>{
        'customer': 0.95,
        'qty': 1.0,
      });
      expect(s.confidence, 0.82);
      expect(s.amount, 240.0);
      expect(s.band, ConfidenceBand.medium);
      expect(s.createdAt, DateTime.utc(2026, 11, 20, 10));
      expect(s.isPending, isTrue);
    });

    test('tolerates missing optional fields and numeric strings', () {
      final Suggestion s = Suggestion.fromJson(const <String, dynamic>{
        'id': 'a2',
        'kind': 'contact',
        'confidence': '0.9',
        'amount': null,
        'proposed_payload': null,
      });
      expect(s.confidence, 0.9);
      expect(s.amount, isNull);
      expect(s.proposedPayload, isEmpty);
      expect(s.priority, 'normal');
      expect(s.createdAt, isNull);
    });

    test('toJson round trips', () {
      final Suggestion s = Suggestion.fromJson(const <String, dynamic>{
        'id': 'a3',
        'kind': 'anomaly',
        'confidence': 0.4,
        'priority': 'high',
        'status': 'pending',
        'created_at': '2026-11-20T10:00:00Z',
        'proposed_payload': <String, dynamic>{'x': 1},
      });
      final Suggestion again = Suggestion.fromJson(s.toJson());
      expect(again.toJson(), s.toJson());
    });
  });

  group('ConfidenceBand', () {
    test('thresholds are inclusive at 0.90 and 0.70', () {
      expect(ConfidenceBand.of(1), ConfidenceBand.high);
      expect(ConfidenceBand.of(0.90), ConfidenceBand.high);
      expect(ConfidenceBand.of(0.8999), ConfidenceBand.medium);
      expect(ConfidenceBand.of(0.70), ConfidenceBand.medium);
      expect(ConfidenceBand.of(0.6999), ConfidenceBand.low);
      expect(ConfidenceBand.of(0), ConfidenceBand.low);
    });
  });

  group('selectAlertBanner', () {
    test('only pending high-priority anomalies qualify', () {
      expect(
        selectAlertBanner(<Suggestion>[
          make(id: 'normal', priority: 'normal'),
          make(id: 'quote', kind: 'sales_quote'),
          make(id: 'done', status: 'approved'),
          make(id: 'failed', status: 'failed'),
          make(id: 'low', priority: 'low'),
        ]),
        isNull,
      );
    });

    test('picks the newest qualifying anomaly', () {
      final Suggestion? alert = selectAlertBanner(<Suggestion>[
        make(id: 'old', createdAt: DateTime.utc(2026, 11, 1)),
        make(id: 'quote', kind: 'sales_quote'),
        make(id: 'new', createdAt: DateTime.utc(2026, 11, 20)),
      ]);
      expect(alert?.id, 'new');
    });

    test('empty list yields no banner', () {
      expect(selectAlertBanner(const <Suggestion>[]), isNull);
    });
  });
}
