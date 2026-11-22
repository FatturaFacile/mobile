import 'dart:async';

import 'package:flutter/widgets.dart';

import 'helpdesk_push_payload.dart';

/// What [HelpdeskPushHandler.handle] did with a push.
enum HelpdeskPushOutcome {
  /// Not a helpdesk push (the caller can offer it to another handler).
  ignored,

  /// Opened the ticket and the operator is alerted ([HelpdeskPushResult.alert]).
  navigatedUrgent,

  /// Opened the ticket, no alert needed.
  navigated,
}

class HelpdeskPushResult {
  const HelpdeskPushResult(this.outcome, [this.payload]);

  final HelpdeskPushOutcome outcome;
  final HelpdeskPushPayload? payload;

  bool get alert => outcome == HelpdeskPushOutcome.navigatedUrgent;
}

/// Turns an incoming push action into navigation to the ticket (deep link) and tells the caller whether to alert.
class HelpdeskPushHandler {
  const HelpdeskPushHandler();

  HelpdeskPushResult handle(
    Map<String, dynamic> data, {
    required GlobalKey<NavigatorState> navigatorKey,
    String? activeTicketId,
  }) {
    final HelpdeskPushPayload? payload = HelpdeskPushPayload.tryParse(data);
    if (payload == null) {
      return const HelpdeskPushResult(HelpdeskPushOutcome.ignored);
    }
    final NavigatorState? nav = navigatorKey.currentState;
    // The ticket already on screen is not pushed again.
    if (nav != null && activeTicketId != payload.ticketId) {
      unawaited(nav.pushNamed<void>(payload.routeName));
    }
    return HelpdeskPushResult(
      payload.isUrgent
          ? HelpdeskPushOutcome.navigatedUrgent
          : HelpdeskPushOutcome.navigated,
      payload,
    );
  }
}
