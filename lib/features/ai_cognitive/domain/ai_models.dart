import 'package:flutter/foundation.dart';

/// How much the AI trusts a proposal: `>= 0.90` high, `>= 0.70` medium, otherwise low.
enum ConfidenceBand {
  high,
  medium,
  low;

  static const double highThreshold = 0.90;
  static const double mediumThreshold = 0.70;

  static ConfidenceBand of(double confidence) {
    if (confidence >= highThreshold) {
      return ConfidenceBand.high;
    }
    if (confidence >= mediumThreshold) {
      return ConfidenceBand.medium;
    }
    return ConfidenceBand.low;
  }
}

/// What a text capture should become (`kind` of `POST /ai/suggestions/extract`).
enum CaptureKind {
  salesQuote('sales_quote', 'document'),
  purchaseOrder('purchase_order', 'document'),
  supportTicket('support_ticket', 'support_ticket'),
  contact('contact', 'document');

  const CaptureKind(this.wire, this.sourceType);

  final String wire;

  /// Matching `source_type` accepted by the backend.
  final String sourceType;
}

/// Suggestion kinds and statuses the app knows; the backend may add more, so models keep the raw string.
abstract final class SuggestionKinds {
  static const String anomaly = 'anomaly';
}

abstract final class SuggestionStatus {
  static const String pending = 'pending';
  static const String failed = 'failed';
}

abstract final class SuggestionPriority {
  static const String high = 'high';
}

/// One AI proposal waiting in (or decided from) the human-in-the-loop queue.
@immutable
class Suggestion {
  const Suggestion({
    required this.id,
    required this.kind,
    required this.status,
    required this.priority,
    required this.confidence,
    this.workflow,
    this.sourceType,
    this.sourceReference,
    this.sourceText,
    this.proposedPayload = const <String, dynamic>{},
    this.fieldConfidences = const <String, double>{},
    this.amount,
    this.reasoning,
    this.decisionFeedback,
    this.resultingEntityType,
    this.resultingEntityId,
    this.expiresAt,
    this.createdAt,
  });

  factory Suggestion.fromJson(Map<String, dynamic> json) {
    final Object? payload = json['proposed_payload'];
    final Object? fields = json['field_confidences'];
    return Suggestion(
      id: '${json['id']}',
      kind: '${json['kind'] ?? ''}',
      status: '${json['status'] ?? SuggestionStatus.pending}',
      priority: '${json['priority'] ?? 'normal'}',
      confidence: _double(json['confidence']) ?? 0,
      workflow: json['workflow'] as String?,
      sourceType: json['source_type'] as String?,
      sourceReference: json['source_reference'] as String?,
      sourceText: json['source_text'] as String?,
      proposedPayload: payload is Map
          ? Map<String, dynamic>.from(payload)
          : const <String, dynamic>{},
      fieldConfidences: fields is Map
          ? <String, double>{
              for (final MapEntry<dynamic, dynamic> e in fields.entries)
                if (_double(e.value) != null) '${e.key}': _double(e.value)!,
            }
          : const <String, double>{},
      amount: _double(json['amount']),
      reasoning: json['reasoning'] as String?,
      decisionFeedback: json['decision_feedback'] as String?,
      resultingEntityType: json['resulting_entity_type'] as String?,
      resultingEntityId: json['resulting_entity_id'] as String?,
      expiresAt: DateTime.tryParse('${json['expires_at']}'),
      createdAt: DateTime.tryParse('${json['created_at']}'),
    );
  }

  final String id;
  final String kind;
  final String status;
  final String priority;
  final double confidence;
  final String? workflow;
  final String? sourceType;
  final String? sourceReference;
  final String? sourceText;
  final Map<String, dynamic> proposedPayload;
  final Map<String, double> fieldConfidences;
  final double? amount;
  final String? reasoning;
  final String? decisionFeedback;
  final String? resultingEntityType;
  final String? resultingEntityId;
  final DateTime? expiresAt;
  final DateTime? createdAt;

  ConfidenceBand get band => ConfidenceBand.of(confidence);

  bool get isPending => status == SuggestionStatus.pending;

  /// Only high-priority anomaly/fraud suggestions that still wait for a human raise the app-shell alert.
  bool get isHighPriorityAnomaly =>
      kind == SuggestionKinds.anomaly &&
      priority == SuggestionPriority.high &&
      isPending;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'kind': kind,
    'status': status,
    'priority': priority,
    'confidence': confidence,
    'workflow': workflow,
    'source_type': sourceType,
    'source_reference': sourceReference,
    'source_text': sourceText,
    'proposed_payload': proposedPayload,
    'field_confidences': fieldConfidences,
    'amount': amount,
    'reasoning': reasoning,
    'decision_feedback': decisionFeedback,
    'resulting_entity_type': resultingEntityType,
    'resulting_entity_id': resultingEntityId,
    'expires_at': expiresAt?.toIso8601String(),
    'created_at': createdAt?.toIso8601String(),
  };

  static double? _double(Object? v) =>
      v is num ? v.toDouble() : (v is String ? double.tryParse(v) : null);
}

/// The alert to surface in the app shell: the newest pending high-priority anomaly, or `null`.
Suggestion? selectAlertBanner(Iterable<Suggestion> suggestions) {
  Suggestion? best;
  for (final Suggestion s in suggestions) {
    if (!s.isHighPriorityAnomaly) {
      continue;
    }
    final DateTime? at = s.createdAt;
    final DateTime? bestAt = best?.createdAt;
    if (best == null ||
        (at != null && (bestAt == null || at.isAfter(bestAt)))) {
      best = s;
    }
  }
  return best;
}

/// A page of the open queue plus the per-kind counters of `meta.open_by_kind`.
@immutable
class SuggestionsPage {
  const SuggestionsPage(
    this.items, {
    this.total = 0,
    this.openByKind = const <String, int>{},
  });

  final List<Suggestion> items;
  final int total;
  final Map<String, int> openByKind;
}
