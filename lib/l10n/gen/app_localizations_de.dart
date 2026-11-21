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
  String get dssTitle => 'Executive-DSS';

  @override
  String dssSyncedAt(String time) {
    return 'Synchronisiert $time';
  }

  @override
  String dssOfflineSince(String time) {
    return 'Offline · synchronisiert $time';
  }

  @override
  String get dssNeverSynced => 'Noch nicht synchronisiert';

  @override
  String get dssSyncing => 'Synchronisierung…';

  @override
  String get dssAllEntities => 'Alle Gesellschaften';

  @override
  String get dssLegalEntity => 'Gesellschaft';

  @override
  String get dssCurrency => 'Währung';

  @override
  String get dssPeriodMtd => 'MTD';

  @override
  String get dssPeriodQtd => 'QTD';

  @override
  String get dssPeriodYtd => 'YTD';

  @override
  String get dssPeriodL12m => 'L12M';

  @override
  String get dssKpiRevenue => 'Umsatz';

  @override
  String get dssKpiGrossMargin => 'Bruttomarge %';

  @override
  String get dssKpiEbitda => 'EBITDA';

  @override
  String get dssKpiNetCash => 'Netto-Cashflow';

  @override
  String get dssKpiCcc => 'Cash-Conversion-Cycle';

  @override
  String get dssKpiDso => 'DSO';

  @override
  String dssDays(String value) {
    return '$value T';
  }

  @override
  String get dssKpiUnavailable => 'Keine Datenquelle';

  @override
  String get dssNoData => 'Noch keine Daten';

  @override
  String get dssNoDataBody =>
      'Verbinden Sie sich mit dem Internet und ziehen Sie nach unten, um die Kennzahlen zu laden.';

  @override
  String get dssVsBaseline => 'ggü. Basis';

  @override
  String get dssAlertsTitle => 'Strategische Alarme';

  @override
  String get dssNoAlerts => 'Keine aktiven Alarme.';

  @override
  String get dssSeverityCritical => 'Kritisch';

  @override
  String get dssSeverityWarning => 'Warnung';

  @override
  String get dssSeverityInfo => 'Info';

  @override
  String get dssAlertMarginErosion => 'Erosion der Bruttomarge';

  @override
  String get dssAlertDsoSpike => 'DSO-Anstieg';

  @override
  String get dssAlertCustomerConcentration => 'Kundenkonzentration';

  @override
  String get dssAlertBudgetOverrun => 'Budgetüberschreitung';

  @override
  String get dssAlertOutlier => 'Ausreisser gegenüber der Historie';

  @override
  String dssAlertSummaryMarginErosion(String value, String threshold) {
    return 'Die Bruttomarge sank um $value Pkt. (Grenze $threshold Pkt.).';
  }

  @override
  String dssAlertSummaryDsoSpike(String value, String threshold) {
    return 'Das DSO stieg um $value Tage (Grenze $threshold).';
  }

  @override
  String dssAlertSummaryCustomerConcentration(
    String label,
    String value,
    String threshold,
  ) {
    return '$label macht $value% des Umsatzes aus (Grenze $threshold%).';
  }

  @override
  String dssAlertSummaryBudgetOverrun(String value, String threshold) {
    return 'Budget um $value% überschritten (Grenze $threshold%).';
  }

  @override
  String dssAlertSummaryOutlier(String value, String threshold) {
    return 'Abweichung von $value σ (Schwelle $threshold σ).';
  }

  @override
  String get dssRootCause => 'Hauptursache';

  @override
  String get dssRecommendedAction => 'Empfohlene Massnahme';

  @override
  String get dssCauseMarginErosion =>
      'Die Warenkosten steigen schneller als die Preise, oder das Sortiment verschiebt sich zu margenschwachen Produkten.';

  @override
  String get dssActionMarginErosion =>
      'Preislisten und Lieferantenkosten prüfen; mit dem What-if-Check eine Preiserhöhung berechnen.';

  @override
  String get dssCauseDsoSpike =>
      'Kunden zahlen später, oder grosse Rechnungen sind überfällig.';

  @override
  String get dssActionDsoSpike =>
      'Mahnwesen für die ältesten Rechnungen starten und Zahlungspläne mit den grössten Schuldnern vereinbaren.';

  @override
  String get dssCauseCustomerConcentration =>
      'Ein einzelner Kunde erzeugt einen überproportionalen Umsatzanteil.';

  @override
  String get dssActionCustomerConcentration =>
      'Kundenbasis diversifizieren und einen langfristigen Vertrag mit diesem Kunden sichern.';

  @override
  String get dssCauseBudgetOverrun =>
      'Die tatsächlichen Ausgaben dieser Budgetposition übersteigen den genehmigten Betrag.';

  @override
  String get dssActionBudgetOverrun =>
      'Ermessensausgaben der Position stoppen und beim Kostenstellenverantwortlichen einen Massnahmenplan anfordern.';

  @override
  String get dssCauseOutlier =>
      'Der letzte Wert liegt weit von seinem historischen Durchschnitt entfernt.';

  @override
  String get dssActionOutlier =>
      'Quelldaten auf Fehler prüfen und klären, ob die Veränderung ein echter Trend ist.';

  @override
  String get dssTopCustomers => 'Top-5-Kunden';

  @override
  String get dssBottomCustomers => 'Letzte 5 Kunden';

  @override
  String get dssTopProducts => 'Top-5-Produkte';

  @override
  String get dssBottomProducts => 'Letzte 5 Produkte';

  @override
  String get dssNetMargin => 'Nettomarge';

  @override
  String get dssParetoCore => 'Kern';

  @override
  String get dssValueDestroying => 'Wertvernichtend';

  @override
  String get dssVarianceTitle => 'EBITDA-Brücke';

  @override
  String get dssVarBaseline => 'Basis';

  @override
  String get dssVarVolume => 'Menge';

  @override
  String get dssVarPrice => 'Preis';

  @override
  String get dssVarCogs => 'Warenkosten';

  @override
  String get dssVarOpex => 'OPEX';

  @override
  String get dssVarFx => 'Währung';

  @override
  String get dssVarActual => 'Ist';

  @override
  String get dssWhatIfTitle => 'What-if-Schnellcheck';

  @override
  String get dssWhatIfPrice => 'Preisänderung';

  @override
  String get dssWhatIfCogs => 'Änderung der Warenkosten';

  @override
  String get dssWhatIfCurrent => 'Aktuell';

  @override
  String get dssWhatIfSimulated => 'Simuliertes EBITDA';

  @override
  String get dssWhatIfChange => 'Veränderung';

  @override
  String get dssWhatIfReset => 'Zurücksetzen';

  @override
  String get dssWhatIfOnDevice =>
      'Auf diesem Gerät mit den zuletzt synchronisierten Zahlen berechnet.';

  @override
  String get dssErrUnauthorized =>
      'Ihre Sitzung ist abgelaufen. Bitte erneut anmelden.';

  @override
  String get dssErrForbidden =>
      'Sie haben keinen Zugriff auf das Executive-DSS.';

  @override
  String get dssErrFailed =>
      'Der Server konnte die Zahlen nicht liefern. Es werden die zuletzt synchronisierten Daten angezeigt.';

  @override
  String get dssClose => 'Schliessen';
}
