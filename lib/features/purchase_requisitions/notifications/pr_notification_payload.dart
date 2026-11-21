/// Action requested by an incoming push notification or deep link.
enum PrNotificationAction { open, approve, reject }

/// Parsed push notification or deep link payload targeting a Purchase Requisition approval.
class PrNotificationPayload {
  const PrNotificationPayload({
    required this.requisitionId,
    required this.action,
    this.approvalId,
    this.requisitionNumber,
    this.tenantId,
    this.oneClickToken,
    this.rejectionReason,
    this.deepLink,
  });

  final String requisitionId;
  final String? approvalId;
  final String? requisitionNumber;
  final String? tenantId;
  final String? oneClickToken;
  final PrNotificationAction action;
  final String? rejectionReason;
  final String? deepLink;

  /// Attempts to parse an FCM/APNs push notification data map.
  ///
  /// Expected keys: `type` (`purchase_requisition_approval` | `pr_approval` | `purchase_requisition`),
  /// `requisition_id` (or `purchase_requisition_id`), optional `approval_id`, `requisition_number`,
  /// `tenant_id`, `one_click_token` / `token`, `action` (`open` | `approve` | `reject`),
  /// `reason` / `rejection_reason`, and optional `deep_link`.
  static PrNotificationPayload? tryParse(Map<String, dynamic> raw) {
    final String? type = _str(raw['type']) ?? _str(raw['event_type']);
    final String? deepLink = _str(raw['deep_link']) ?? _str(raw['url']);
    String? requisitionId =
        _str(raw['requisition_id']) ?? _str(raw['purchase_requisition_id']);

    PrNotificationPayload? uriParsed;
    if (deepLink != null) {
      final Uri? parsedUri = Uri.tryParse(deepLink);
      if (parsedUri != null) {
        uriParsed = tryParseUri(parsedUri);
      }
    }

    requisitionId ??= uriParsed?.requisitionId;
    if (requisitionId == null || requisitionId.isEmpty) {
      return null;
    }

    const Set<String> acceptedTypes = <String>{
      'purchase_requisition_approval',
      'pr_approval',
      'purchase_requisition',
      'pr_one_click_approval',
    };
    if (type != null && !acceptedTypes.contains(type) && uriParsed == null) {
      return null;
    }

    final PrNotificationAction action = _parseAction(
      _str(raw['action']) ?? _str(raw['action_id']) ?? _str(raw['decision']),
      fallback: uriParsed?.action ?? PrNotificationAction.open,
    );

    return PrNotificationPayload(
      requisitionId: requisitionId,
      approvalId: _str(raw['approval_id']) ?? uriParsed?.approvalId,
      requisitionNumber:
          _str(raw['requisition_number']) ?? uriParsed?.requisitionNumber,
      tenantId: _str(raw['tenant_id']) ?? uriParsed?.tenantId,
      oneClickToken:
          _str(raw['one_click_token']) ??
          _str(raw['token']) ??
          uriParsed?.oneClickToken,
      action: action,
      rejectionReason:
          _str(raw['rejection_reason']) ??
          _str(raw['reason']) ??
          uriParsed?.rejectionReason,
      deepLink: deepLink,
    );
  }

  /// Parses deep links such as:
  /// - `fatturafacile://procurement/purchase-requisitions/{id}?approval_id=...&token=...&action=approve`
  /// - `https://app.fatturafacile.eu/procurement/purchase-requisitions/{id}?...`
  /// - `/procurement/purchase-requisitions/{id}?...`
  static PrNotificationPayload? tryParseUri(Uri uri) {
    final List<String> segments = <String>[
      if (uri.scheme == 'fatturafacile' && uri.host.isNotEmpty) uri.host,
      ...uri.pathSegments.where((String s) => s.isNotEmpty),
    ];

    final int idx = segments.indexOf('purchase-requisitions');
    if (idx == -1 || idx + 1 >= segments.length) {
      return null;
    }
    final String requisitionId = segments[idx + 1].trim();
    if (requisitionId.isEmpty) {
      return null;
    }

    final Map<String, String> q = uri.queryParameters;
    return PrNotificationPayload(
      requisitionId: requisitionId,
      approvalId: _str(q['approval_id']),
      requisitionNumber: _str(q['requisition_number']),
      tenantId: _str(q['tenant_id']),
      oneClickToken: _str(q['one_click_token']) ?? _str(q['token']),
      action: _parseAction(_str(q['action']) ?? _str(q['decision'])),
      rejectionReason: _str(q['rejection_reason']) ?? _str(q['reason']),
      deepLink: uri.toString(),
    );
  }

  static PrNotificationAction _parseAction(
    String? raw, {
    PrNotificationAction fallback = PrNotificationAction.open,
  }) {
    switch (raw?.toLowerCase()) {
      case 'approve':
      case 'approved':
      case 'one_tap_approve':
        return PrNotificationAction.approve;
      case 'reject':
      case 'rejected':
      case 'one_tap_reject':
        return PrNotificationAction.reject;
      case 'open':
      case 'view':
        return PrNotificationAction.open;
      default:
        return fallback;
    }
  }

  static String? _str(Object? raw) {
    if (raw == null) {
      return null;
    }
    final String s = '$raw'.trim();
    return s.isEmpty ? null : s;
  }
}
