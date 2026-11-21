// ignore_for_file: deprecated_member_use

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

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

  @override
  String get mfgModuleTitle => 'Produktionstechnik';

  @override
  String get mfgHubTitle => 'Produktionstechnik';

  @override
  String get mfgTabRoutings => 'Arbeitspläne';

  @override
  String get mfgTabMachines => 'Maschinen';

  @override
  String get mfgTabOee => 'OEE';

  @override
  String get mfgSyncAction => 'Jetzt synchronisieren';

  @override
  String get mfgSyncFailed => 'Synchronisierung fehlgeschlagen, Offline-Daten';

  @override
  String get mfgEmptyRoutings => 'Keine Arbeitspläne offline verfügbar';

  @override
  String get mfgEmptyMachines => 'Keine Maschinen offline verfügbar';

  @override
  String get mfgEmptyOee => 'Keine OEE-Daten offline verfügbar';

  @override
  String mfgRevisionLabel(String revision) {
    return 'Rev. $revision';
  }

  @override
  String mfgStepsCount(int count) {
    return '$count Arbeitsgänge';
  }

  @override
  String mfgStepTitle(int sequence, String code) {
    return '$sequence · $code';
  }

  @override
  String mfgWorkCenterLabel(String code) {
    return 'Arbeitsplatz $code';
  }

  @override
  String mfgMinutesValue(String value) {
    return '$value Min.';
  }

  @override
  String get mfgSetupTime => 'Rüsten';

  @override
  String get mfgRunTime => 'Bearbeitung / Einheit';

  @override
  String get mfgQueueTime => 'Wartezeit';

  @override
  String get mfgMoveTime => 'Transport';

  @override
  String get mfgSubcontracted => 'Fremdfertigung';

  @override
  String get mfgCalculatorTitle => 'Durchlaufzeit und Kosten';

  @override
  String get mfgLotQuantity => 'Losgröße';

  @override
  String get mfgIncludeOverlap => 'Überlappung der Transferlose';

  @override
  String get mfgCalculate => 'Berechnen';

  @override
  String get mfgCalcInvalid => 'Menge größer als null eingeben';

  @override
  String get mfgCalcMissingWorkCenter =>
      'Ein Arbeitsplatz dieses Arbeitsplans ist offline nicht verfügbar';

  @override
  String get mfgTotalLeadTime => 'Gesamtdurchlaufzeit';

  @override
  String get mfgSerialLeadTime => 'Ohne Überlappung';

  @override
  String get mfgOverlapSaving => 'Überlappungsersparnis';

  @override
  String get mfgTotalCost => 'Gesamtkosten';

  @override
  String get mfgUnitCost => 'Kosten pro Einheit';

  @override
  String get mfgCostSetup => 'Rüsten';

  @override
  String get mfgCostMachine => 'Maschinenlauf';

  @override
  String get mfgCostLabor => 'Direkte Arbeit';

  @override
  String get mfgCostOverhead => 'Gemeinkosten';

  @override
  String get mfgCostSubcontracting => 'Fremdfertigung';

  @override
  String get mfgCostMaterialNote =>
      'Materialkosten sind offline nicht enthalten';

  @override
  String mfgMachineStatus(String status) {
    return 'Status: $status';
  }

  @override
  String get mfgIndustria40 => 'Industrie 4.0';

  @override
  String get mfgTransizione50 => 'Transizione 5.0';

  @override
  String mfgIdealCycle(String seconds) {
    return 'Idealzyklus: $seconds s/Einheit';
  }

  @override
  String get mfgTelemetryNever => 'Keine Telemetrie';

  @override
  String get mfgTelemetryStale => 'Telemetrie veraltet';

  @override
  String get mfgTelemetryOnline => 'Telemetrie online';

  @override
  String mfgOeeValue(String percent) {
    return 'OEE $percent%';
  }

  @override
  String get mfgAvailability => 'Verfügbarkeit';

  @override
  String get mfgPerformance => 'Leistung';

  @override
  String get mfgQuality => 'Qualität';

  @override
  String mfgOeeTarget(String percent) {
    return 'Ziel $percent%';
  }

  @override
  String get mfgOeeMeetsTarget => 'Ziel erreicht';

  @override
  String mfgOeeBelowTarget(String gap) {
    return '$gap Pkt. unter Ziel';
  }

  @override
  String mfgOeePeriod(String from, String to) {
    return '$from – $to';
  }

  @override
  String get mfgGoodUnits => 'Gutstücke';

  @override
  String get mfgScrapUnits => 'Ausschuss';

  @override
  String get mfgReworkUnits => 'Nacharbeit';

  @override
  String get mfgOperatingMinutes => 'Betriebszeit';

  @override
  String get mfgLossesTitle => 'Sechs große Verluste (Minuten)';

  @override
  String get mfgLossEquipmentFailure => 'Anlagenausfall';

  @override
  String get mfgLossSetupAdjustment => 'Rüsten und Einstellen';

  @override
  String get mfgLossMinorStops => 'Kleinstillstände';

  @override
  String get mfgLossReducedSpeed => 'Reduzierte Geschwindigkeit';

  @override
  String get mfgLossProcessDefects => 'Prozessfehler';

  @override
  String get mfgLossStartupRejects => 'Anlaufausschuss';
}
