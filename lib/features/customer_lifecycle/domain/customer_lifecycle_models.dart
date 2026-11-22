/// Touchpoint types of the customer timeline, as sent by the web-api.
const List<String> kTimelineTypes = <String>[
  'activity',
  'opportunity',
  'invoice',
  'ticket',
  'work_order',
  'contract',
  'lead',
];

/// Cross-module KPIs of a customer (`GET /crm/customers/{id}/360`). Money amounts stay decimal strings.
class CustomerLifecycleKpis {
  const CustomerLifecycleKpis({
    required this.lifetimeValue,
    required this.openPipelineValue,
    required this.overdueReceivableAmount,
    required this.openTickets,
    required this.slaBreachRate,
    required this.mttrHours,
    required this.activeContracts,
    required this.contractCoverage,
    required this.contractHoursRemaining,
    required this.interventionsScheduled,
    required this.interventionsCompleted,
  });

  factory CustomerLifecycleKpis.fromJson(Map<String, dynamic> json) =>
      CustomerLifecycleKpis(
        lifetimeValue: '${json['lifetime_value'] ?? '0.00'}',
        openPipelineValue: '${json['open_pipeline_value'] ?? '0.00'}',
        overdueReceivableAmount: '${json['overdue_receivable_amount'] ?? '0.00'}',
        openTickets: (json['open_tickets'] as num?)?.toInt() ?? 0,
        slaBreachRate: (json['sla_breach_rate'] as num?)?.toDouble() ?? 0,
        mttrHours: (json['mttr_hours'] as num?)?.toDouble(),
        activeContracts: (json['active_contracts'] as num?)?.toInt() ?? 0,
        contractCoverage: '${json['contract_coverage'] ?? 'none'}',
        contractHoursRemaining: '${json['contract_hours_remaining'] ?? '0.00'}',
        interventionsScheduled:
            (json['interventions_scheduled'] as num?)?.toInt() ?? 0,
        interventionsCompleted:
            (json['interventions_completed'] as num?)?.toInt() ?? 0,
      );

  final String lifetimeValue;
  final String openPipelineValue;
  final String overdueReceivableAmount;
  final int openTickets;
  final double slaBreachRate;
  final double? mttrHours;
  final int activeContracts;

  /// `none`, `covered` or `exhausted`.
  final String contractCoverage;
  final String contractHoursRemaining;
  final int interventionsScheduled;
  final int interventionsCompleted;
}

/// Health and KPIs of a customer.
class CustomerLifecycleSummary {
  const CustomerLifecycleSummary({
    required this.healthIndex,
    required this.churnRisk,
    required this.kpis,
  });

  factory CustomerLifecycleSummary.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> health = Map<String, dynamic>.from(
      (json['health'] as Map<dynamic, dynamic>?) ?? <String, dynamic>{},
    );
    final Map<String, dynamic> kpis = Map<String, dynamic>.from(
      (json['kpis'] as Map<dynamic, dynamic>?) ?? <String, dynamic>{},
    );
    return CustomerLifecycleSummary(
      healthIndex: (health['health_index'] as num?)?.toDouble() ?? 0,
      churnRisk: health['churn_risk'] as String?,
      kpis: CustomerLifecycleKpis.fromJson(kpis),
    );
  }

  final double healthIndex;
  final String? churnRisk;
  final CustomerLifecycleKpis kpis;
}

/// One touchpoint of the customer timeline.
class CustomerTimelineEvent {
  const CustomerTimelineEvent({
    required this.type,
    required this.id,
    required this.occurredAt,
    required this.title,
    this.status,
    this.amount,
    this.reference,
  });

  factory CustomerTimelineEvent.fromJson(Map<String, dynamic> json) =>
      CustomerTimelineEvent(
        type: '${json['type']}',
        id: '${json['id']}',
        occurredAt: DateTime.parse('${json['occurred_at']}'),
        title: '${json['title'] ?? ''}',
        status: json['status'] as String?,
        amount: json['amount'] as String?,
        reference: json['reference'] as String?,
      );

  final String type;
  final String id;
  final DateTime occurredAt;
  final String title;
  final String? status;
  final String? amount;
  final String? reference;
}
