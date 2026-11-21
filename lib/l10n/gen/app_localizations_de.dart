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
  String get securityTitle => 'Sicherheit';

  @override
  String get securityEncryptionSection => 'Verschlüsselter Speicher';

  @override
  String get securityDbEncrypted => 'Die lokale Datenbank ist verschlüsselt';

  @override
  String get securityDbNotEncrypted =>
      'Die lokale Datenbank ist noch nicht verschlüsselt';

  @override
  String securityKeyStored(String backend) {
    return 'Der Schlüssel liegt im $backend';
  }

  @override
  String get securityKeyMissing =>
      'Kein Schlüssel im sicheren Speicher gefunden';

  @override
  String get securityBackendKeychain => 'Keychain';

  @override
  String get securityBackendKeystore => 'Android Keystore';

  @override
  String get securityBackendSecure => 'sicheren Speicher der Plattform';

  @override
  String get securityLockSection => 'Sitzungssperre';

  @override
  String get securityLockEnabled => 'Nach Inaktivität sperren';

  @override
  String get securityLockTimeout => 'Sperr-Timeout';

  @override
  String get securityTimeout30s => '30 Sekunden';

  @override
  String get securityTimeout1m => '1 Minute';

  @override
  String get securityTimeout5m => '5 Minuten';

  @override
  String get securityTimeout15m => '15 Minuten';

  @override
  String get securitySetPin => 'PIN festlegen';

  @override
  String get securityPinHint => 'PIN (mindestens 4 Ziffern)';

  @override
  String get securityPinSaved => 'PIN gespeichert';

  @override
  String get securityPinTooShort => 'Die PIN muss mindestens 4 Ziffern haben.';

  @override
  String get securityNoLockMethod =>
      'Lege eine PIN fest oder aktiviere Biometrie, um die Sitzungssperre zu nutzen.';

  @override
  String get securityLockNow => 'Jetzt sperren';

  @override
  String get securityQueueSection => 'Audit-Warteschlange';

  @override
  String securityQueuePending(int count) {
    return '$count Einträge warten auf die Synchronisierung';
  }

  @override
  String get securityQueueAllSynced =>
      'Alle Audit-Einträge sind synchronisiert';

  @override
  String securityQueueLastSync(String time) {
    return 'Letzte Synchronisierung: $time';
  }

  @override
  String securityQueueError(String error) {
    return 'Letzter Fehler: $error';
  }

  @override
  String get securitySyncNow => 'Jetzt synchronisieren';

  @override
  String get securityVerifyChain => 'Kette prüfen';

  @override
  String securityChainValid(int count) {
    return 'Audit-Kette geprüft ($count Einträge)';
  }

  @override
  String securityChainBroken(int sequence) {
    return 'Audit-Kette bei Eintrag $sequence unterbrochen';
  }

  @override
  String get securityLockedTitle => 'Sitzung gesperrt';

  @override
  String get securityUnlockBiometric => 'Mit Biometrie entsperren';

  @override
  String get securityUnlockReason =>
      'Authentifiziere dich, um Fattura Facile zu entsperren';

  @override
  String get securityPinLabel => 'PIN';

  @override
  String get securityUnlock => 'Entsperren';

  @override
  String get securityWrongPin => 'Falsche PIN';

  @override
  String get securityTooManyAttempts =>
      'Zu viele Versuche. Versuche es gleich erneut.';

  @override
  String get piiUnmaskTitle => 'Geschützte Daten anzeigen';

  @override
  String piiUnmaskBody(String field) {
    return 'Das Anzeigen von $field wird im Audit-Protokoll festgehalten. Gib eine Begründung an.';
  }

  @override
  String get piiJustificationLabel => 'Begründung (mindestens 10 Zeichen)';

  @override
  String get piiJustificationTooShort =>
      'Die Begründung muss mindestens 10 Zeichen haben.';

  @override
  String get piiUnmaskConfirm => 'Anzeigen';

  @override
  String get piiUnmaskCancel => 'Abbrechen';

  @override
  String get piiUnmaskFailed => 'Der Wert konnte nicht angezeigt werden.';

  @override
  String get piiUnmaskForbidden => 'Du darfst dieses Feld nicht anzeigen.';

  @override
  String get piiUnmaskDemo => 'Geschütztes Feld anzeigen';

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

  @override
  String get prModuleTitle => 'Bestellanforderungen';

  @override
  String get prHubTitle => 'Bestellanforderungen (BANF)';

  @override
  String get prTabMyRequests => 'Meine Anfragen';

  @override
  String get prTabToApprove => 'Zu genehmigen';

  @override
  String get prEmptyMyRequests => 'Noch keine Bestellanforderungen vorhanden';

  @override
  String get prEmptyToApprove => 'Keine Anforderungen warten auf Ihre Freigabe';

  @override
  String get prCreateAction => 'Neue BANF';

  @override
  String get prRefreshTooltip => 'Aktualisieren';

  @override
  String get prDraftLocalNumber => 'Lokaler Entwurf';

  @override
  String get prOfflineBanner =>
      'Offlinemodus: Entwürfe und Freigaben werden bei Verbindung automatisch synchronisiert';

  @override
  String get prStatusDraft => 'Entwurf';

  @override
  String get prStatusPendingApproval => 'Freigabe ausstehend';

  @override
  String get prStatusApproved => 'Genehmigt';

  @override
  String get prStatusRejected => 'Abgelehnt';

  @override
  String get prStatusBudgetExceeded => 'Budget überschritten';

  @override
  String get prStatusConvertedToRdo => 'In Anfrage umgewandelt';

  @override
  String get prStatusConvertedToPo => 'In Bestellung umgewandelt';

  @override
  String get prStatusCancelled => 'Storniert';

  @override
  String get prSyncSynced => 'Synchronisiert';

  @override
  String get prSyncPendingUpload => 'Sync ausstehend';

  @override
  String get prSyncError => 'Sync-Fehler';

  @override
  String get prSyncRetry => 'Sync wiederholen';

  @override
  String get prQueuedForSync => 'Für automatische Synchronisation vorgemerkt';

  @override
  String get prDraftSavedOffline => 'Entwurf lokal gespeichert';

  @override
  String get prSubmittedSuccess =>
      'Bestellanforderung zur Freigabe eingereicht';

  @override
  String prSyncCompletedSubmitted(String number) {
    return 'BANF $number synchronisiert und eingereicht';
  }

  @override
  String prSyncCompletedBudgetBlocked(String number) {
    return 'BANF $number nach Sync durch Budgetprüfung blockiert';
  }

  @override
  String get prSyncCompletedApproval => 'Freigabeentscheidung synchronisiert';

  @override
  String get prUrgencyLow => 'Niedrig';

  @override
  String get prUrgencyNormal => 'Normal';

  @override
  String get prUrgencyHigh => 'Hoch';

  @override
  String get prUrgencyCritical => 'Kritisch';

  @override
  String prLinkedRdoLabel(String number) {
    return 'Anfrage $number';
  }

  @override
  String prLinkedPoLabel(String number) {
    return 'Bestellung $number';
  }

  @override
  String get prLinkedDocumentsTitle => 'Verknüpfte Einkaufsbelege';

  @override
  String get prCreateTitle => 'Neue Bestellanforderung';

  @override
  String get prEditTitle => 'Anforderung bearbeiten';

  @override
  String get prCostCenterLabel => 'Kostenstelle';

  @override
  String get prCostCenterRequired => 'Kostenstelle auswählen';

  @override
  String get prProjectLabel => 'Projekt (Optional)';

  @override
  String get prProjectNone => 'Kein Projekt';

  @override
  String get prUrgencyLabel => 'Dringlichkeit';

  @override
  String get prCurrencyLabel => 'Währung';

  @override
  String get prDeliveryDateLabel => 'Gewünschtes Lieferdatum';

  @override
  String get prDeliveryDateHint => 'Datum wählen';

  @override
  String get prJustificationLabel => 'Wirtschaftliche Begründung';

  @override
  String get prJustificationHint =>
      'Betrieblichen Bedarf oder Nutzen erläutern';

  @override
  String get prJustificationRequired =>
      'Für die Einreichung ist eine Begründung erforderlich';

  @override
  String get prLinesSectionTitle => 'Positionen';

  @override
  String get prLinesEmpty => 'Noch keine Positionen hinzugefügt';

  @override
  String get prLinesRequired =>
      'Vor der Einreichung mindestens eine Position hinzufügen';

  @override
  String get prAddLineAction => 'Position hinzufügen';

  @override
  String get prScanBarcodeAction => 'Barcode scannen';

  @override
  String get prSaveDraftOffline => 'Entwurf speichern (Offline)';

  @override
  String get prSubmitForApproval => 'Zur Freigabe einreichen';

  @override
  String get prTotalAmountLabel => 'Gesamtbetrag';

  @override
  String get prLineTypeCatalog => 'Katalogsuche';

  @override
  String get prLineTypeFreeText => 'Freitexteingabe';

  @override
  String get prCatalogSearchHint =>
      'Katalog nach SKU, Barcode oder Name durchsuchen';

  @override
  String get prCatalogEmpty => 'Keine passenden Katalogartikel gefunden';

  @override
  String prBarcodeMatched(String item) {
    return 'Artikel hinzugefügt: $item';
  }

  @override
  String prBarcodeNotFound(String code) {
    return 'Kein Katalogartikel für Code \"$code\" gefunden';
  }

  @override
  String get prLineDescriptionLabel => 'Beschreibung';

  @override
  String get prLineQuantityLabel => 'Menge';

  @override
  String get prLineUnitPriceLabel => 'Einzelpreis';

  @override
  String get prLineUomLabel => 'Mengeneinheit';

  @override
  String get prLineNotesLabel => 'Notizen (Optional)';

  @override
  String get prLineAddConfirm => 'Zur BANF hinzufügen';

  @override
  String get prFieldRequired => 'Pflichtfeld';

  @override
  String get prInvalidNumber => 'Gültige Zahl eingeben';

  @override
  String get prMustBePositive => 'Wert muss größer als null sein';

  @override
  String get prBudgetTitle => 'Kostenstellenbudget';

  @override
  String get prBudgetOfflineInfo =>
      'Offline: Echtzeit-Budgetprüfung erfolgt bei der Synchronisation.';

  @override
  String get prBudgetChecking => 'Kostenstellenbudget wird geprüft...';

  @override
  String get prBudgetStatusOk => 'Im Budget';

  @override
  String get prBudgetStatusWarning => 'Budgetwarnung';

  @override
  String get prBudgetStatusHardBlock => 'Budget überschritten (Blockiert)';

  @override
  String get prBudgetAllocated => 'Zugewiesen';

  @override
  String get prBudgetCommitted => 'Gebunden';

  @override
  String get prBudgetAvailable => 'Verfügbar';

  @override
  String get prBudgetRequested => 'Angefordert';

  @override
  String get prBudgetRemaining => 'Verbleibend';

  @override
  String prBudgetUtilization(String percent) {
    return '$percent% ausgeschöpft';
  }

  @override
  String get prBudgetWarningDialogTitle => 'Warnung Budgetschwelle';

  @override
  String get prBudgetWarningDialogBody =>
      'Diese Anforderung überschreitet die Warnschwelle der Kostenstelle. Trotzdem einreichen?';

  @override
  String get prBudgetWarningProceed => 'Trotzdem einreichen';

  @override
  String get prBudgetHardBlockSubmitBlocked =>
      'Einreichung blockiert: Kostenstellenbudget überschritten.';

  @override
  String get prDetailTitle => 'BANF-Details';

  @override
  String get prRequesterLabel => 'Anforderer';

  @override
  String get prRequestedDateLabel => 'Angefordert am';

  @override
  String get prApprovalProgressTitle => 'Genehmigungsworkflow';

  @override
  String prApprovalLevelLabel(int level) {
    return 'Stufe $level';
  }

  @override
  String get prApprovalStepApproved => 'Genehmigt';

  @override
  String get prApprovalStepPending => 'Ausstehend';

  @override
  String get prApprovalStepRejected => 'Abgelehnt';

  @override
  String get prApprovalStepWaiting => 'Wartend';

  @override
  String get prAuditTrailTitle => 'Freigabe-Audit-Protokoll';

  @override
  String get prAuditTrailEmpty => 'Noch keine Freigabeereignisse erfasst';

  @override
  String get prAuditActionSubmitted => 'Eingereicht';

  @override
  String get prAuditActionApproved => 'Genehmigt';

  @override
  String get prAuditActionRejected => 'Abgelehnt';

  @override
  String get prAuditActionBudgetWarning => 'Budgetwarnung';

  @override
  String get prAuditActionBudgetBlocked => 'Budget blockiert';

  @override
  String get prAuditActionEscalated => 'Eskaliert';

  @override
  String get prAuditActionConverted => 'Umgewandelt';

  @override
  String get prChannelWeb => 'Web';

  @override
  String get prChannelMobileApp => 'Mobile App';

  @override
  String get prChannelMobilePush => 'Push 1-Tap';

  @override
  String get prChannelEmailOneClick => 'E-Mail 1-Click';

  @override
  String get prChannelSystem => 'System';

  @override
  String get prPendingSyncTag => 'Sync ausstehend';

  @override
  String get prApproveOneTap => '1-Tap Genehmigen';

  @override
  String get prRejectAction => 'Ablehnen';

  @override
  String get prApprovedConfirmation => 'Anforderung genehmigt';

  @override
  String get prApprovedQueuedOffline =>
      'Genehmigung offline vorgemerkt; wird bei Verbindung synchronisiert';

  @override
  String get prRejectedConfirmation => 'Anforderung abgelehnt';

  @override
  String get prRejectedQueuedOffline =>
      'Ablehnung offline vorgemerkt; wird bei Verbindung synchronisiert';

  @override
  String get prRejectSheetTitle => 'Anforderung ablehnen';

  @override
  String get prRejectReasonLabel => 'Ablehnungsgrund';

  @override
  String get prRejectReasonHint =>
      'Geben Sie einen klaren Grund für die Ablehnung an';

  @override
  String get prRejectReasonRequired => 'Ein Ablehnungsgrund ist erforderlich';

  @override
  String get prRejectConfirmAction => 'Ablehnung bestätigen';

  @override
  String get prCancelAction => 'Abbrechen';

  @override
  String get prNotFound => 'Bestellanforderung nicht gefunden';

  @override
  String get prGenericError =>
      'Vorgang konnte nicht abgeschlossen werden. Bitte erneut versuchen.';

  @override
  String prLevelBadge(int current, int total) {
    return 'Stufe $current/$total';
  }
}

/// The translations for German, as used in Switzerland (`de_CH`).
class AppLocalizationsDeCh extends AppLocalizationsDe {
  AppLocalizationsDeCh() : super('de_CH');

  @override
  String get securityTitle => 'Sicherheit';

  @override
  String get securityEncryptionSection => 'Verschlüsselter Speicher';

  @override
  String get securityDbEncrypted => 'Die lokale Datenbank ist verschlüsselt';

  @override
  String get securityDbNotEncrypted =>
      'Die lokale Datenbank ist noch nicht verschlüsselt';

  @override
  String securityKeyStored(String backend) {
    return 'Der Schlüssel liegt im $backend';
  }

  @override
  String get securityKeyMissing =>
      'Kein Schlüssel im sicheren Speicher gefunden';

  @override
  String get securityBackendKeychain => 'Keychain';

  @override
  String get securityBackendKeystore => 'Android Keystore';

  @override
  String get securityBackendSecure => 'sicheren Speicher der Plattform';

  @override
  String get securityLockSection => 'Sitzungssperre';

  @override
  String get securityLockEnabled => 'Nach Inaktivität sperren';

  @override
  String get securityLockTimeout => 'Sperr-Timeout';

  @override
  String get securityTimeout30s => '30 Sekunden';

  @override
  String get securityTimeout1m => '1 Minute';

  @override
  String get securityTimeout5m => '5 Minuten';

  @override
  String get securityTimeout15m => '15 Minuten';

  @override
  String get securitySetPin => 'PIN festlegen';

  @override
  String get securityPinHint => 'PIN (mindestens 4 Ziffern)';

  @override
  String get securityPinSaved => 'PIN gespeichert';

  @override
  String get securityPinTooShort => 'Die PIN muss mindestens 4 Ziffern haben.';

  @override
  String get securityNoLockMethod =>
      'Lege eine PIN fest oder aktiviere Biometrie, um die Sitzungssperre zu nutzen.';

  @override
  String get securityLockNow => 'Jetzt sperren';

  @override
  String get securityQueueSection => 'Audit-Warteschlange';

  @override
  String securityQueuePending(int count) {
    return '$count Einträge warten auf die Synchronisierung';
  }

  @override
  String get securityQueueAllSynced =>
      'Alle Audit-Einträge sind synchronisiert';

  @override
  String securityQueueLastSync(String time) {
    return 'Letzte Synchronisierung: $time';
  }

  @override
  String securityQueueError(String error) {
    return 'Letzter Fehler: $error';
  }

  @override
  String get securitySyncNow => 'Jetzt synchronisieren';

  @override
  String get securityVerifyChain => 'Kette prüfen';

  @override
  String securityChainValid(int count) {
    return 'Audit-Kette geprüft ($count Einträge)';
  }

  @override
  String securityChainBroken(int sequence) {
    return 'Audit-Kette bei Eintrag $sequence unterbrochen';
  }

  @override
  String get securityLockedTitle => 'Sitzung gesperrt';

  @override
  String get securityUnlockBiometric => 'Mit Biometrie entsperren';

  @override
  String get securityUnlockReason =>
      'Authentifiziere dich, um Fattura Facile zu entsperren';

  @override
  String get securityPinLabel => 'PIN';

  @override
  String get securityUnlock => 'Entsperren';

  @override
  String get securityWrongPin => 'Falsche PIN';

  @override
  String get securityTooManyAttempts =>
      'Zu viele Versuche. Versuche es gleich erneut.';

  @override
  String get piiUnmaskTitle => 'Geschützte Daten anzeigen';

  @override
  String piiUnmaskBody(String field) {
    return 'Das Anzeigen von $field wird im Audit-Protokoll festgehalten. Gib eine Begründung an.';
  }

  @override
  String get piiJustificationLabel => 'Begründung (mindestens 10 Zeichen)';

  @override
  String get piiJustificationTooShort =>
      'Die Begründung muss mindestens 10 Zeichen haben.';

  @override
  String get piiUnmaskConfirm => 'Anzeigen';

  @override
  String get piiUnmaskCancel => 'Abbrechen';

  @override
  String get piiUnmaskFailed => 'Der Wert konnte nicht angezeigt werden.';

  @override
  String get piiUnmaskForbidden => 'Du darfst dieses Feld nicht anzeigen.';

  @override
  String get piiUnmaskDemo => 'Geschütztes Feld anzeigen';
}
