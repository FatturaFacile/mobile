// ignore_for_file: deprecated_member_use

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get prModuleTitle => 'Richieste di Acquisto';

  @override
  String get prHubTitle => 'Richieste di Acquisto (RDA)';

  @override
  String get prTabMyRequests => 'Le mie RDA';

  @override
  String get prTabToApprove => 'Da approvare';

  @override
  String get prEmptyMyRequests => 'Nessuna richiesta di acquisto presente';

  @override
  String get prEmptyToApprove => 'Nessuna richiesta in attesa di approvazione';

  @override
  String get prCreateAction => 'Nuova RDA';

  @override
  String get prRefreshTooltip => 'Aggiorna';

  @override
  String get prDraftLocalNumber => 'Bozza locale';

  @override
  String get prOfflineBanner =>
      'Modalità offline: bozze e approvazioni si sincronizzeranno al ripristino della rete';

  @override
  String get prStatusDraft => 'Bozza';

  @override
  String get prStatusPendingApproval => 'In approvazione';

  @override
  String get prStatusApproved => 'Approvata';

  @override
  String get prStatusRejected => 'Rifiutata';

  @override
  String get prStatusBudgetExceeded => 'Budget superato';

  @override
  String get prStatusConvertedToRdo => 'Convertita in RDO';

  @override
  String get prStatusConvertedToPo => 'Convertita in OdA';

  @override
  String get prStatusCancelled => 'Annullata';

  @override
  String get prSyncSynced => 'Sincronizzata';

  @override
  String get prSyncPendingUpload => 'In attesa di sync';

  @override
  String get prSyncError => 'Errore di sync';

  @override
  String get prSyncRetry => 'Riprova sync';

  @override
  String get prQueuedForSync => 'In coda per la sincronizzazione automatica';

  @override
  String get prDraftSavedOffline => 'Bozza salvata localmente';

  @override
  String get prSubmittedSuccess =>
      'Richiesta di acquisto inviata in approvazione';

  @override
  String prSyncCompletedSubmitted(String number) {
    return 'RDA $number sincronizzata e inviata';
  }

  @override
  String prSyncCompletedBudgetBlocked(String number) {
    return 'RDA $number bloccata dal controllo budget dopo la sync';
  }

  @override
  String get prSyncCompletedApproval =>
      'Decisione di approvazione sincronizzata';

  @override
  String get prUrgencyLow => 'Bassa';

  @override
  String get prUrgencyNormal => 'Normale';

  @override
  String get prUrgencyHigh => 'Alta';

  @override
  String get prUrgencyCritical => 'Critica';

  @override
  String prLinkedRdoLabel(String number) {
    return 'RDO $number';
  }

  @override
  String prLinkedPoLabel(String number) {
    return 'OdA $number';
  }

  @override
  String get prLinkedDocumentsTitle => 'Documenti di acquisto collegati';

  @override
  String get prCreateTitle => 'Nuova Richiesta di Acquisto';

  @override
  String get prEditTitle => 'Modifica Richiesta';

  @override
  String get prCostCenterLabel => 'Centro di Costo';

  @override
  String get prCostCenterRequired => 'Seleziona un Centro di Costo';

  @override
  String get prProjectLabel => 'Progetto (Facoltativo)';

  @override
  String get prProjectNone => 'Nessun progetto';

  @override
  String get prUrgencyLabel => 'Urgenza';

  @override
  String get prCurrencyLabel => 'Valuta';

  @override
  String get prDeliveryDateLabel => 'Data consegna richiesta';

  @override
  String get prDeliveryDateHint => 'Seleziona data';

  @override
  String get prJustificationLabel => 'Motivazione economica';

  @override
  String get prJustificationHint =>
      'Descrivi la necessità operativa o aziendale';

  @override
  String get prJustificationRequired =>
      'La motivazione economica è obbligatoria per l\'invio';

  @override
  String get prLinesSectionTitle => 'Righe richiesta';

  @override
  String get prLinesEmpty => 'Nessuna riga aggiunta';

  @override
  String get prLinesRequired => 'Aggiungi almeno una riga prima di inviare';

  @override
  String get prAddLineAction => 'Aggiungi riga';

  @override
  String get prScanBarcodeAction => 'Scansiona codice';

  @override
  String get prSaveDraftOffline => 'Salva bozza (Offline)';

  @override
  String get prSubmitForApproval => 'Invia per approvazione';

  @override
  String get prTotalAmountLabel => 'Importo totale';

  @override
  String get prLineTypeCatalog => 'Ricerca catalogo';

  @override
  String get prLineTypeFreeText => 'Testo libero';

  @override
  String get prCatalogSearchHint =>
      'Cerca nel catalogo per SKU, barcode o nome';

  @override
  String get prCatalogEmpty => 'Nessun articolo trovato nel catalogo';

  @override
  String prBarcodeMatched(String item) {
    return 'Articolo aggiunto: $item';
  }

  @override
  String prBarcodeNotFound(String code) {
    return 'Nessun articolo trovato per il codice \"$code\"';
  }

  @override
  String get prLineDescriptionLabel => 'Descrizione';

  @override
  String get prLineQuantityLabel => 'Quantità';

  @override
  String get prLineUnitPriceLabel => 'Prezzo unitario';

  @override
  String get prLineUomLabel => 'Unità di misura';

  @override
  String get prLineNotesLabel => 'Note (Facoltative)';

  @override
  String get prLineAddConfirm => 'Aggiungi alla RDA';

  @override
  String get prFieldRequired => 'Campo obbligatorio';

  @override
  String get prInvalidNumber => 'Inserisci un numero valido';

  @override
  String get prMustBePositive => 'Il valore deve essere maggiore di zero';

  @override
  String get prBudgetTitle => 'Budget Centro di Costo';

  @override
  String get prBudgetOfflineInfo =>
      'Offline: il controllo budget in tempo reale verrà eseguito alla sincronizzazione.';

  @override
  String get prBudgetChecking => 'Verifica budget Centro di Costo...';

  @override
  String get prBudgetStatusOk => 'Entro il budget';

  @override
  String get prBudgetStatusWarning => 'Avviso budget';

  @override
  String get prBudgetStatusHardBlock => 'Budget superato (Bloccato)';

  @override
  String get prBudgetAllocated => 'Assegnato';

  @override
  String get prBudgetCommitted => 'Impegnato';

  @override
  String get prBudgetAvailable => 'Disponibile';

  @override
  String get prBudgetRequested => 'Richiesto';

  @override
  String get prBudgetRemaining => 'Residuo';

  @override
  String prBudgetUtilization(String percent) {
    return '$percent% utilizzato';
  }

  @override
  String get prBudgetWarningDialogTitle => 'Avviso soglia budget';

  @override
  String get prBudgetWarningDialogBody =>
      'Questa richiesta supera la soglia di avviso del Centro di Costo. Vuoi inviarla comunque?';

  @override
  String get prBudgetWarningProceed => 'Invia comunque';

  @override
  String get prBudgetHardBlockSubmitBlocked =>
      'Invio bloccato: budget del Centro di Costo superato.';

  @override
  String get prDetailTitle => 'Dettaglio RDA';

  @override
  String get prRequesterLabel => 'Richiedente';

  @override
  String get prRequestedDateLabel => 'Data richiesta';

  @override
  String get prApprovalProgressTitle => 'Flusso di approvazione';

  @override
  String prApprovalLevelLabel(int level) {
    return 'Livello $level';
  }

  @override
  String get prApprovalStepApproved => 'Approvato';

  @override
  String get prApprovalStepPending => 'In attesa';

  @override
  String get prApprovalStepRejected => 'Rifiutato';

  @override
  String get prApprovalStepWaiting => 'In coda';

  @override
  String get prAuditTrailTitle => 'Storico approvazioni';

  @override
  String get prAuditTrailEmpty => 'Nessun evento di approvazione registrato';

  @override
  String get prAuditActionSubmitted => 'Inviata';

  @override
  String get prAuditActionApproved => 'Approvata';

  @override
  String get prAuditActionRejected => 'Rifiutata';

  @override
  String get prAuditActionBudgetWarning => 'Avviso budget';

  @override
  String get prAuditActionBudgetBlocked => 'Blocco budget';

  @override
  String get prAuditActionEscalated => 'Escalation';

  @override
  String get prAuditActionConverted => 'Convertita';

  @override
  String get prChannelWeb => 'Web';

  @override
  String get prChannelMobileApp => 'App Mobile';

  @override
  String get prChannelMobilePush => 'Notifica 1-Tap';

  @override
  String get prChannelEmailOneClick => 'Email 1-Click';

  @override
  String get prChannelSystem => 'Sistema';

  @override
  String get prPendingSyncTag => 'In attesa di sync';

  @override
  String get prApproveOneTap => 'Approva 1-Tap';

  @override
  String get prRejectAction => 'Rifiuta';

  @override
  String get prApprovedConfirmation => 'Richiesta approvata';

  @override
  String get prApprovedQueuedOffline =>
      'Approvazione accodata offline; verrà inviata alla riconnessione';

  @override
  String get prRejectedConfirmation => 'Richiesta rifiutata';

  @override
  String get prRejectedQueuedOffline =>
      'Rifiuto accodato offline; verrà inviato alla riconnessione';

  @override
  String get prRejectSheetTitle => 'Rifiuta richiesta';

  @override
  String get prRejectReasonLabel => 'Motivazione del rifiuto';

  @override
  String get prRejectReasonHint =>
      'Inserisci una motivazione chiara per il rifiuto';

  @override
  String get prRejectReasonRequired =>
      'La motivazione del rifiuto è obbligatoria';

  @override
  String get prRejectConfirmAction => 'Conferma rifiuto';

  @override
  String get prCancelAction => 'Annulla';

  @override
  String get prNotFound => 'Richiesta di acquisto non trovata';

  @override
  String get prGenericError => 'Impossibile completare l\'operazione. Riprova.';

  @override
  String prLevelBadge(int current, int total) {
    return 'Livello $current/$total';
  }

  @override
  String get mfgModuleTitle => 'Ingegneria di produzione';

  @override
  String get mfgHubTitle => 'Ingegneria di produzione';

  @override
  String get mfgTabRoutings => 'Cicli';

  @override
  String get mfgTabMachines => 'Macchine';

  @override
  String get mfgTabOee => 'OEE';

  @override
  String get mfgSyncAction => 'Sincronizza ora';

  @override
  String get mfgSyncFailed => 'Sincronizzazione fallita, dati offline';

  @override
  String get mfgEmptyRoutings => 'Nessun ciclo disponibile offline';

  @override
  String get mfgEmptyMachines => 'Nessuna macchina disponibile offline';

  @override
  String get mfgEmptyOee => 'Nessun dato OEE disponibile offline';

  @override
  String mfgRevisionLabel(String revision) {
    return 'Rev. $revision';
  }

  @override
  String mfgStepsCount(int count) {
    return '$count fasi';
  }

  @override
  String mfgStepTitle(int sequence, String code) {
    return '$sequence · $code';
  }

  @override
  String mfgWorkCenterLabel(String code) {
    return 'Centro di lavoro $code';
  }

  @override
  String mfgMinutesValue(String value) {
    return '$value min';
  }

  @override
  String get mfgSetupTime => 'Attrezzaggio';

  @override
  String get mfgRunTime => 'Lavorazione / unità';

  @override
  String get mfgQueueTime => 'Attesa';

  @override
  String get mfgMoveTime => 'Trasporto';

  @override
  String get mfgSubcontracted => 'Conto lavoro';

  @override
  String get mfgCalculatorTitle => 'Lead time e costo';

  @override
  String get mfgLotQuantity => 'Quantità lotto';

  @override
  String get mfgIncludeOverlap => 'Sovrapposizione lotti di trasferimento';

  @override
  String get mfgCalculate => 'Calcola';

  @override
  String get mfgCalcInvalid => 'Inserisci una quantità maggiore di zero';

  @override
  String get mfgCalcMissingWorkCenter =>
      'Un centro di lavoro del ciclo non è disponibile offline';

  @override
  String get mfgTotalLeadTime => 'Lead time totale';

  @override
  String get mfgSerialLeadTime => 'Senza sovrapposizione';

  @override
  String get mfgOverlapSaving => 'Risparmio da sovrapposizione';

  @override
  String get mfgTotalCost => 'Costo totale';

  @override
  String get mfgUnitCost => 'Costo per unità';

  @override
  String get mfgCostSetup => 'Attrezzaggio';

  @override
  String get mfgCostMachine => 'Macchina';

  @override
  String get mfgCostLabor => 'Manodopera diretta';

  @override
  String get mfgCostOverhead => 'Spese generali';

  @override
  String get mfgCostSubcontracting => 'Conto lavoro';

  @override
  String get mfgCostMaterialNote =>
      'Il costo dei materiali non è incluso offline';

  @override
  String mfgMachineStatus(String status) {
    return 'Stato: $status';
  }

  @override
  String get mfgIndustria40 => 'Industria 4.0';

  @override
  String get mfgTransizione50 => 'Transizione 5.0';

  @override
  String mfgIdealCycle(String seconds) {
    return 'Ciclo ideale: $seconds s/unità';
  }

  @override
  String get mfgTelemetryNever => 'Nessuna telemetria';

  @override
  String get mfgTelemetryStale => 'Telemetria non aggiornata';

  @override
  String get mfgTelemetryOnline => 'Telemetria online';

  @override
  String mfgOeeValue(String percent) {
    return 'OEE $percent%';
  }

  @override
  String get mfgAvailability => 'Disponibilità';

  @override
  String get mfgPerformance => 'Prestazione';

  @override
  String get mfgQuality => 'Qualità';

  @override
  String mfgOeeTarget(String percent) {
    return 'Obiettivo $percent%';
  }

  @override
  String get mfgOeeMeetsTarget => 'Obiettivo raggiunto';

  @override
  String mfgOeeBelowTarget(String gap) {
    return 'Sotto obiettivo di $gap pt';
  }

  @override
  String mfgOeePeriod(String from, String to) {
    return '$from – $to';
  }

  @override
  String get mfgGoodUnits => 'Unità buone';

  @override
  String get mfgScrapUnits => 'Scarti';

  @override
  String get mfgReworkUnits => 'Rilavorazioni';

  @override
  String get mfgOperatingMinutes => 'Tempo operativo';

  @override
  String get mfgLossesTitle => 'Sei grandi perdite (minuti)';

  @override
  String get mfgLossEquipmentFailure => 'Guasti';

  @override
  String get mfgLossSetupAdjustment => 'Attrezzaggio e regolazioni';

  @override
  String get mfgLossMinorStops => 'Micro-fermate';

  @override
  String get mfgLossReducedSpeed => 'Velocità ridotta';

  @override
  String get mfgLossProcessDefects => 'Difetti di processo';

  @override
  String get mfgLossStartupRejects => 'Scarti di avviamento';
}
