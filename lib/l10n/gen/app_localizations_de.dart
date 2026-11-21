// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get copilotTitle => 'Copilot';

  @override
  String get copilotTooltip => 'Copilot öffnen';

  @override
  String get copilotInputHint => 'Frag etwas zu deinem ERP …';

  @override
  String get copilotSend => 'Senden';

  @override
  String get copilotEmptyTitle => 'Wie kann ich helfen?';

  @override
  String get copilotEmptyBody =>
      'Frag nach Rechnungen, Lagerbestand, Fristen oder Schweizer und italienischen Vorschriften.';

  @override
  String get copilotNewChat => 'Neue Unterhaltung';

  @override
  String get copilotHistory => 'Verlauf';

  @override
  String get copilotNoHistory => 'Keine letzten Unterhaltungen';

  @override
  String get copilotUntitled => 'Unterhaltung ohne Titel';

  @override
  String get copilotDeleteConversation => 'Unterhaltung löschen';

  @override
  String get copilotOfflineBanner =>
      'Du bist offline: gespeicherte Unterhaltungen sind schreibgeschützt.';

  @override
  String get copilotThinking => 'Ich denke nach …';

  @override
  String copilotToolRunning(String tool) {
    return '$tool wird ausgeführt …';
  }

  @override
  String get copilotConfirm => 'Bestätigen und ausführen';

  @override
  String get copilotCancel => 'Abbrechen';

  @override
  String get copilotActionTitle => 'Vorgeschlagene Aktion';

  @override
  String get copilotEditableFields => 'Werte vor dem Bestätigen anpassen';

  @override
  String get copilotActionPending => 'Wartet auf Bestätigung';

  @override
  String get copilotActionConfirmed => 'Bestätigt';

  @override
  String get copilotActionRejected => 'Abgebrochen';

  @override
  String get copilotActionExecuted => 'Ausgeführt';

  @override
  String get copilotActionFailed => 'Fehlgeschlagen';

  @override
  String get copilotSources => 'Quellen';

  @override
  String get copilotRouteUnavailable =>
      'Dieser Bildschirm ist in der App nicht verfügbar.';

  @override
  String get copilotRetry => 'Erneut versuchen';

  @override
  String get copilotErrForbidden =>
      'Du hast keine Berechtigung für Copilot oder diese Aktion.';

  @override
  String get copilotErrNotFound => 'Element nicht gefunden.';

  @override
  String get copilotErrConflict =>
      'Die Aktion wurde bereits abgebrochen oder ist fehlgeschlagen.';

  @override
  String get copilotErrInvalid => 'Ungültige Werte oder Aktion fehlgeschlagen.';

  @override
  String get copilotErrRateLimited =>
      'Zu viele Anfragen oder Kontingent erschöpft. Versuche es später erneut.';

  @override
  String get copilotErrProvider =>
      'Das KI-Modell ist derzeit nicht erreichbar.';

  @override
  String get copilotErrOffline =>
      'Du bist offline. Versuche es erneut, wenn du wieder online bist.';

  @override
  String get copilotErrUnknown => 'Etwas ist schiefgelaufen.';

  @override
  String get copilotClose => 'Schließen';

  @override
  String get cogTitle => 'KI-Vorschläge';

  @override
  String get cogModule => 'KI-Prüfung';

  @override
  String get cogCaptureHint =>
      'Anfrage diktieren oder tippen, z. B. \"Offerte 2 Stühle für Muster AG\"';

  @override
  String get cogKindLabel => 'Erstellen';

  @override
  String get cogKindSalesQuote => 'Verkaufsofferte';

  @override
  String get cogKindPurchaseOrder => 'Bestellung';

  @override
  String get cogKindSupportTicket => 'Support-Ticket';

  @override
  String get cogKindContact => 'Kontakt';

  @override
  String get cogKindAccountingCoding => 'Kontierung';

  @override
  String get cogKindReconciliationMatch => 'Abstimmung';

  @override
  String get cogKindAnomaly => 'Anomalie';

  @override
  String get cogKindLatePaymentRisk => 'Zahlungsverzugsrisiko';

  @override
  String get cogKindChurnRisk => 'Abwanderungsrisiko';

  @override
  String get cogKindReorder => 'Nachbestellung';

  @override
  String get cogKindCashFlowAlert => 'Liquiditätswarnung';

  @override
  String get cogKindOther => 'Vorschlag';

  @override
  String get cogSend => 'Senden';

  @override
  String get cogDictate => 'Diktieren';

  @override
  String get cogTextTooShort => 'Mindestens 10 Zeichen eingeben.';

  @override
  String get cogCaptureSent => 'Gesendet. Der Entwurf wartet auf Ihre Prüfung.';

  @override
  String get cogCaptureQueued =>
      'Offline gespeichert. Wird bei Verbindung gesendet.';

  @override
  String cogCaptureRejected(String detail) {
    return 'Die Anfrage wurde nicht akzeptiert: $detail';
  }

  @override
  String cogQueuedCount(int count) {
    return '$count Anfragen warten auf den Versand';
  }

  @override
  String get cogDismiss => 'Verwerfen';

  @override
  String get cogConfidenceHigh => 'Hoch';

  @override
  String get cogConfidenceMedium => 'Mittel';

  @override
  String get cogConfidenceLow => 'Niedrig';

  @override
  String cogConfidence(int percent) {
    return 'Vertrauen $percent %';
  }

  @override
  String get cogEmpty => 'Keine Vorschläge zur Prüfung';

  @override
  String get cogApprove => 'Genehmigen';

  @override
  String get cogReject => 'Ablehnen';

  @override
  String get cogRejectTitle => 'Vorschlag ablehnen';

  @override
  String get cogRejectReason => 'Grund (mindestens 3 Zeichen)';

  @override
  String get cogReasonTooShort => 'Mindestens 3 Zeichen eingeben.';

  @override
  String get cogCancel => 'Abbrechen';

  @override
  String get cogApproved => 'Vorschlag genehmigt.';

  @override
  String get cogRejected => 'Vorschlag abgelehnt.';

  @override
  String get cogErrForbidden => 'Ihre Rolle darf KI-Vorschläge nicht nutzen.';

  @override
  String get cogErrAlreadyDecided =>
      'Bereits von jemand anderem entschieden. Liste aktualisiert.';

  @override
  String cogErrInvalid(String detail) {
    return 'Der Vorschlag ist unvollständig: $detail';
  }

  @override
  String get cogErrOffline =>
      'Sie sind offline. Versuchen Sie es später erneut.';

  @override
  String get cogErrRateLimited => 'Zu viele Anfragen. Später erneut versuchen.';

  @override
  String get cogErrProvider => 'Der KI-Dienst ist derzeit nicht verfügbar.';

  @override
  String get cogErrNotFound => 'Dieser Vorschlag existiert nicht mehr.';

  @override
  String get cogErrUnknown => 'Etwas ist schiefgelaufen.';

  @override
  String get cogAlertTitle => 'Warnung mit hoher Priorität';

  @override
  String get cogAlertReview => 'Prüfen';

  @override
  String get cogPriorityHigh => 'Hohe Priorität';

  @override
  String get cogRetry => 'Erneut versuchen';

  @override
  String get cogOfflineCached => 'Gespeicherte Vorschläge (offline)';
}
