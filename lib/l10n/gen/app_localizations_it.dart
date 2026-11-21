// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get copilotTitle => 'Copilot';

  @override
  String get copilotTooltip => 'Apri Copilot';

  @override
  String get copilotInputHint => 'Chiedi qualcosa sul tuo ERP…';

  @override
  String get copilotSend => 'Invia';

  @override
  String get copilotEmptyTitle => 'Come posso aiutarti?';

  @override
  String get copilotEmptyBody =>
      'Chiedi di fatture, scorte, scadenze o normative svizzere e italiane.';

  @override
  String get copilotNewChat => 'Nuova conversazione';

  @override
  String get copilotHistory => 'Cronologia';

  @override
  String get copilotNoHistory => 'Nessuna conversazione recente';

  @override
  String get copilotUntitled => 'Conversazione senza titolo';

  @override
  String get copilotDeleteConversation => 'Elimina conversazione';

  @override
  String get copilotOfflineBanner =>
      'Sei offline: puoi solo leggere le conversazioni salvate.';

  @override
  String get copilotThinking => 'Sto pensando…';

  @override
  String copilotToolRunning(String tool) {
    return 'Eseguo $tool…';
  }

  @override
  String get copilotConfirm => 'Conferma ed esegui';

  @override
  String get copilotCancel => 'Annulla';

  @override
  String get copilotActionTitle => 'Azione proposta';

  @override
  String get copilotEditableFields => 'Modifica i valori prima di confermare';

  @override
  String get copilotActionPending => 'In attesa di conferma';

  @override
  String get copilotActionConfirmed => 'Confermata';

  @override
  String get copilotActionRejected => 'Annullata';

  @override
  String get copilotActionExecuted => 'Eseguita';

  @override
  String get copilotActionFailed => 'Non riuscita';

  @override
  String get copilotSources => 'Fonti';

  @override
  String get copilotRouteUnavailable =>
      'Questa schermata non è disponibile nell\'app.';

  @override
  String get copilotRetry => 'Riprova';

  @override
  String get copilotErrForbidden =>
      'Non hai i permessi per usare Copilot o questa azione.';

  @override
  String get copilotErrNotFound => 'Elemento non trovato.';

  @override
  String get copilotErrConflict =>
      'L\'azione è già stata annullata o è fallita.';

  @override
  String get copilotErrInvalid => 'Valori non validi o azione non riuscita.';

  @override
  String get copilotErrRateLimited =>
      'Troppe richieste o quota esaurita. Riprova più tardi.';

  @override
  String get copilotErrProvider =>
      'Il modello AI non è al momento raggiungibile.';

  @override
  String get copilotErrOffline => 'Sei offline. Riprova quando torni online.';

  @override
  String get copilotErrUnknown => 'Qualcosa è andato storto.';

  @override
  String get copilotClose => 'Chiudi';

  @override
  String get securityTitle => 'Sicurezza';

  @override
  String get securityEncryptionSection => 'Archiviazione cifrata';

  @override
  String get securityDbEncrypted => 'Il database locale è cifrato';

  @override
  String get securityDbNotEncrypted =>
      'Il database locale non è ancora cifrato';

  @override
  String securityKeyStored(String backend) {
    return 'La chiave di cifratura è custodita in $backend';
  }

  @override
  String get securityKeyMissing =>
      'Nessuna chiave di cifratura nell\'archivio sicuro';

  @override
  String get securityBackendKeychain => 'Keychain';

  @override
  String get securityBackendKeystore => 'Android Keystore';

  @override
  String get securityBackendSecure => 'archivio sicuro della piattaforma';

  @override
  String get securityLockSection => 'Blocco sessione';

  @override
  String get securityLockEnabled => 'Blocca dopo inattività';

  @override
  String get securityLockTimeout => 'Timeout di blocco';

  @override
  String get securityTimeout30s => '30 secondi';

  @override
  String get securityTimeout1m => '1 minuto';

  @override
  String get securityTimeout5m => '5 minuti';

  @override
  String get securityTimeout15m => '15 minuti';

  @override
  String get securitySetPin => 'Imposta PIN';

  @override
  String get securityPinHint => 'PIN (almeno 4 cifre)';

  @override
  String get securityPinSaved => 'PIN salvato';

  @override
  String get securityPinTooShort => 'Il PIN deve avere almeno 4 cifre.';

  @override
  String get securityNoLockMethod =>
      'Imposta un PIN o attiva la biometria per usare il blocco sessione.';

  @override
  String get securityLockNow => 'Blocca ora';

  @override
  String get securityQueueSection => 'Coda di audit';

  @override
  String securityQueuePending(int count) {
    return '$count voci in attesa di sincronizzazione';
  }

  @override
  String get securityQueueAllSynced =>
      'Tutte le voci di audit sono sincronizzate';

  @override
  String securityQueueLastSync(String time) {
    return 'Ultima sincronizzazione: $time';
  }

  @override
  String securityQueueError(String error) {
    return 'Ultimo errore: $error';
  }

  @override
  String get securitySyncNow => 'Sincronizza ora';

  @override
  String get securityVerifyChain => 'Verifica catena';

  @override
  String securityChainValid(int count) {
    return 'Catena di audit verificata ($count voci)';
  }

  @override
  String securityChainBroken(int sequence) {
    return 'Catena di audit interrotta alla voce $sequence';
  }

  @override
  String get securityLockedTitle => 'Sessione bloccata';

  @override
  String get securityUnlockBiometric => 'Sblocca con la biometria';

  @override
  String get securityUnlockReason => 'Autenticati per sbloccare Fattura Facile';

  @override
  String get securityPinLabel => 'PIN';

  @override
  String get securityUnlock => 'Sblocca';

  @override
  String get securityWrongPin => 'PIN errato';

  @override
  String get securityTooManyAttempts => 'Troppi tentativi. Riprova tra poco.';

  @override
  String get piiUnmaskTitle => 'Mostra dati protetti';

  @override
  String piiUnmaskBody(String field) {
    return 'La visualizzazione di $field viene registrata nel registro di audit. Inserisci una motivazione.';
  }

  @override
  String get piiJustificationLabel => 'Motivazione (almeno 10 caratteri)';

  @override
  String get piiJustificationTooShort =>
      'La motivazione deve avere almeno 10 caratteri.';

  @override
  String get piiUnmaskConfirm => 'Mostra';

  @override
  String get piiUnmaskCancel => 'Annulla';

  @override
  String get piiUnmaskFailed => 'Impossibile mostrare il valore.';

  @override
  String get piiUnmaskForbidden =>
      'Non sei autorizzato a mostrare questo campo.';

  @override
  String get piiUnmaskDemo => 'Mostra campo protetto';

  @override
  String get cogTitle => 'Suggerimenti AI';

  @override
  String get cogModule => 'Revisione AI';

  @override
  String get cogCaptureHint =>
      'Detta o scrivi una richiesta, es. \"preventivo 2 sedie per Muster AG\"';

  @override
  String get cogKindLabel => 'Crea';

  @override
  String get cogKindSalesQuote => 'Preventivo';

  @override
  String get cogKindPurchaseOrder => 'Ordine di acquisto';

  @override
  String get cogKindSupportTicket => 'Ticket di supporto';

  @override
  String get cogKindContact => 'Contatto';

  @override
  String get cogKindAccountingCoding => 'Codifica contabile';

  @override
  String get cogKindReconciliationMatch => 'Riconciliazione';

  @override
  String get cogKindAnomaly => 'Anomalia';

  @override
  String get cogKindLatePaymentRisk => 'Rischio di ritardo pagamento';

  @override
  String get cogKindChurnRisk => 'Rischio di abbandono';

  @override
  String get cogKindReorder => 'Riordino';

  @override
  String get cogKindCashFlowAlert => 'Allerta di cassa';

  @override
  String get cogKindOther => 'Suggerimento';

  @override
  String get cogSend => 'Invia';

  @override
  String get cogDictate => 'Detta';

  @override
  String get cogTextTooShort => 'Scrivi almeno 10 caratteri.';

  @override
  String get cogCaptureSent => 'Inviato. La bozza attende la tua revisione.';

  @override
  String get cogCaptureQueued =>
      'Salvato offline. Sarà inviato al ritorno della connessione.';

  @override
  String cogCaptureRejected(String detail) {
    return 'La richiesta non è stata accettata: $detail';
  }

  @override
  String cogQueuedCount(int count) {
    return '$count richieste in attesa di invio';
  }

  @override
  String get cogDismiss => 'Ignora';

  @override
  String get cogConfidenceHigh => 'Alta';

  @override
  String get cogConfidenceMedium => 'Media';

  @override
  String get cogConfidenceLow => 'Bassa';

  @override
  String cogConfidence(int percent) {
    return 'Affidabilità $percent%';
  }

  @override
  String get cogEmpty => 'Nessun suggerimento da rivedere';

  @override
  String get cogApprove => 'Approva';

  @override
  String get cogReject => 'Rifiuta';

  @override
  String get cogRejectTitle => 'Rifiuta suggerimento';

  @override
  String get cogRejectReason => 'Motivo (almeno 3 caratteri)';

  @override
  String get cogReasonTooShort => 'Inserisci almeno 3 caratteri.';

  @override
  String get cogCancel => 'Annulla';

  @override
  String get cogApproved => 'Suggerimento approvato.';

  @override
  String get cogRejected => 'Suggerimento rifiutato.';

  @override
  String get cogErrForbidden => 'Il tuo ruolo non può usare i suggerimenti AI.';

  @override
  String get cogErrAlreadyDecided =>
      'Già deciso da un altro utente. Elenco aggiornato.';

  @override
  String cogErrInvalid(String detail) {
    return 'La proposta è incompleta: $detail';
  }

  @override
  String get cogErrOffline => 'Sei offline. Riprova quando torni online.';

  @override
  String get cogErrRateLimited => 'Troppe richieste. Riprova più tardi.';

  @override
  String get cogErrProvider => 'Il servizio AI non è al momento disponibile.';

  @override
  String get cogErrNotFound => 'Questo suggerimento non esiste più.';

  @override
  String get cogErrUnknown => 'Qualcosa è andato storto.';

  @override
  String get cogAlertTitle => 'Allerta ad alta priorità';

  @override
  String get cogAlertReview => 'Rivedi';

  @override
  String get cogPriorityHigh => 'Alta priorità';

  @override
  String get cogRetry => 'Riprova';

  @override
  String get cogOfflineCached => 'Suggerimenti salvati (offline)';

  @override
  String get dssTitle => 'DSS direzionale';

  @override
  String dssSyncedAt(String time) {
    return 'Sincronizzato $time';
  }

  @override
  String dssOfflineSince(String time) {
    return 'Offline · sincronizzato $time';
  }

  @override
  String get dssNeverSynced => 'Non ancora sincronizzato';

  @override
  String get dssSyncing => 'Sincronizzazione…';

  @override
  String get dssAllEntities => 'Tutte le entità';

  @override
  String get dssLegalEntity => 'Entità legale';

  @override
  String get dssCurrency => 'Valuta';

  @override
  String get dssPeriodMtd => 'MTD';

  @override
  String get dssPeriodQtd => 'QTD';

  @override
  String get dssPeriodYtd => 'YTD';

  @override
  String get dssPeriodL12m => 'L12M';

  @override
  String get dssKpiRevenue => 'Ricavi';

  @override
  String get dssKpiGrossMargin => 'Margine lordo %';

  @override
  String get dssKpiEbitda => 'EBITDA';

  @override
  String get dssKpiNetCash => 'Flusso di cassa netto';

  @override
  String get dssKpiCcc => 'Ciclo di conversione di cassa';

  @override
  String get dssKpiDso => 'DSO';

  @override
  String dssDays(String value) {
    return '$value gg';
  }

  @override
  String get dssKpiUnavailable => 'Nessuna fonte dati';

  @override
  String get dssNoData => 'Ancora nessun dato';

  @override
  String get dssNoDataBody =>
      'Connettiti a internet e trascina verso il basso per caricare i dati direzionali.';

  @override
  String get dssVsBaseline => 'vs riferimento';

  @override
  String get dssAlertsTitle => 'Alert strategici';

  @override
  String get dssNoAlerts => 'Nessun alert attivo.';

  @override
  String get dssSeverityCritical => 'Critico';

  @override
  String get dssSeverityWarning => 'Attenzione';

  @override
  String get dssSeverityInfo => 'Info';

  @override
  String get dssAlertMarginErosion => 'Erosione del margine lordo';

  @override
  String get dssAlertDsoSpike => 'Picco del DSO';

  @override
  String get dssAlertCustomerConcentration => 'Concentrazione su un cliente';

  @override
  String get dssAlertBudgetOverrun => 'Sforamento di budget';

  @override
  String get dssAlertOutlier => 'Anomalia rispetto allo storico';

  @override
  String dssAlertSummaryMarginErosion(String value, String threshold) {
    return 'Il margine lordo è sceso di $value pt (limite $threshold pt).';
  }

  @override
  String dssAlertSummaryDsoSpike(String value, String threshold) {
    return 'Il DSO è salito di $value giorni (limite $threshold).';
  }

  @override
  String dssAlertSummaryCustomerConcentration(
    String label,
    String value,
    String threshold,
  ) {
    return '$label pesa il $value% dei ricavi (limite $threshold%).';
  }

  @override
  String dssAlertSummaryBudgetOverrun(String value, String threshold) {
    return 'Oltre il budget del $value% (limite $threshold%).';
  }

  @override
  String dssAlertSummaryOutlier(String value, String threshold) {
    return 'Scostamento di $value σ (soglia $threshold σ).';
  }

  @override
  String get dssRootCause => 'Causa principale';

  @override
  String get dssRecommendedAction => 'Azione consigliata';

  @override
  String get dssCauseMarginErosion =>
      'Il costo del venduto cresce più dei prezzi, oppure il mix si sposta su prodotti a basso margine.';

  @override
  String get dssActionMarginErosion =>
      'Rivedi listini e costi dei fornitori; usa la verifica what-if per dimensionare un aumento di prezzo.';

  @override
  String get dssCauseDsoSpike =>
      'I clienti pagano più tardi oppure ci sono fatture di importo elevato scadute.';

  @override
  String get dssActionDsoSpike =>
      'Avvia i solleciti sulle fatture più vecchie e concorda piani di pagamento con i maggiori debitori.';

  @override
  String get dssCauseCustomerConcentration =>
      'Un solo cliente genera una quota sproporzionata dei ricavi.';

  @override
  String get dssActionCustomerConcentration =>
      'Diversifica il portafoglio clienti e assicura un contratto a lungo termine con questo cliente.';

  @override
  String get dssCauseBudgetOverrun =>
      'La spesa effettiva su questa voce di budget supera l\'importo approvato.';

  @override
  String get dssActionBudgetOverrun =>
      'Blocca le spese discrezionali sulla voce e chiedi un piano di rientro al responsabile del centro di costo.';

  @override
  String get dssCauseOutlier =>
      'L\'ultimo valore è molto lontano dalla media storica.';

  @override
  String get dssActionOutlier =>
      'Verifica i dati di origine alla ricerca di errori, poi conferma se la variazione è un trend reale.';

  @override
  String get dssTopCustomers => 'Primi 5 clienti';

  @override
  String get dssBottomCustomers => 'Ultimi 5 clienti';

  @override
  String get dssTopProducts => 'Primi 5 prodotti';

  @override
  String get dssBottomProducts => 'Ultimi 5 prodotti';

  @override
  String get dssNetMargin => 'Margine netto';

  @override
  String get dssParetoCore => 'Nucleo';

  @override
  String get dssValueDestroying => 'Distrugge valore';

  @override
  String get dssVarianceTitle => 'Ponte EBITDA';

  @override
  String get dssVarBaseline => 'Riferimento';

  @override
  String get dssVarVolume => 'Volume';

  @override
  String get dssVarPrice => 'Prezzo';

  @override
  String get dssVarCogs => 'Costo del venduto';

  @override
  String get dssVarOpex => 'OPEX';

  @override
  String get dssVarFx => 'Cambio';

  @override
  String get dssVarActual => 'Consuntivo';

  @override
  String get dssWhatIfTitle => 'Verifica what-if';

  @override
  String get dssWhatIfPrice => 'Variazione prezzi';

  @override
  String get dssWhatIfCogs => 'Variazione costo del venduto';

  @override
  String get dssWhatIfCurrent => 'Attuale';

  @override
  String get dssWhatIfSimulated => 'EBITDA simulato';

  @override
  String get dssWhatIfChange => 'Variazione';

  @override
  String get dssWhatIfReset => 'Azzera';

  @override
  String get dssWhatIfOnDevice =>
      'Calcolato su questo dispositivo con gli ultimi dati sincronizzati.';

  @override
  String get dssErrUnauthorized => 'La sessione è scaduta. Accedi di nuovo.';

  @override
  String get dssErrForbidden => 'Non hai accesso al DSS direzionale.';

  @override
  String get dssErrFailed =>
      'Il server non ha fornito i dati. Vengono mostrati gli ultimi dati sincronizzati.';

  @override
  String get dssClose => 'Chiudi';

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
}

/// The translations for Italian, as used in Switzerland (`it_CH`).
class AppLocalizationsItCh extends AppLocalizationsIt {
  AppLocalizationsItCh() : super('it_CH');

  @override
  String get securityTitle => 'Sicurezza';

  @override
  String get securityEncryptionSection => 'Archiviazione cifrata';

  @override
  String get securityDbEncrypted => 'Il database locale è cifrato';

  @override
  String get securityDbNotEncrypted =>
      'Il database locale non è ancora cifrato';

  @override
  String securityKeyStored(String backend) {
    return 'La chiave di cifratura è custodita in $backend';
  }

  @override
  String get securityKeyMissing =>
      'Nessuna chiave di cifratura nell\'archivio sicuro';

  @override
  String get securityBackendKeychain => 'Keychain';

  @override
  String get securityBackendKeystore => 'Android Keystore';

  @override
  String get securityBackendSecure => 'archivio sicuro della piattaforma';

  @override
  String get securityLockSection => 'Blocco sessione';

  @override
  String get securityLockEnabled => 'Blocca dopo inattività';

  @override
  String get securityLockTimeout => 'Timeout di blocco';

  @override
  String get securityTimeout30s => '30 secondi';

  @override
  String get securityTimeout1m => '1 minuto';

  @override
  String get securityTimeout5m => '5 minuti';

  @override
  String get securityTimeout15m => '15 minuti';

  @override
  String get securitySetPin => 'Imposta PIN';

  @override
  String get securityPinHint => 'PIN (almeno 4 cifre)';

  @override
  String get securityPinSaved => 'PIN salvato';

  @override
  String get securityPinTooShort => 'Il PIN deve avere almeno 4 cifre.';

  @override
  String get securityNoLockMethod =>
      'Imposta un PIN o attiva la biometria per usare il blocco sessione.';

  @override
  String get securityLockNow => 'Blocca ora';

  @override
  String get securityQueueSection => 'Coda di audit';

  @override
  String securityQueuePending(int count) {
    return '$count voci in attesa di sincronizzazione';
  }

  @override
  String get securityQueueAllSynced =>
      'Tutte le voci di audit sono sincronizzate';

  @override
  String securityQueueLastSync(String time) {
    return 'Ultima sincronizzazione: $time';
  }

  @override
  String securityQueueError(String error) {
    return 'Ultimo errore: $error';
  }

  @override
  String get securitySyncNow => 'Sincronizza ora';

  @override
  String get securityVerifyChain => 'Verifica catena';

  @override
  String securityChainValid(int count) {
    return 'Catena di audit verificata ($count voci)';
  }

  @override
  String securityChainBroken(int sequence) {
    return 'Catena di audit interrotta alla voce $sequence';
  }

  @override
  String get securityLockedTitle => 'Sessione bloccata';

  @override
  String get securityUnlockBiometric => 'Sblocca con la biometria';

  @override
  String get securityUnlockReason => 'Autenticati per sbloccare Fattura Facile';

  @override
  String get securityPinLabel => 'PIN';

  @override
  String get securityUnlock => 'Sblocca';

  @override
  String get securityWrongPin => 'PIN errato';

  @override
  String get securityTooManyAttempts => 'Troppi tentativi. Riprova tra poco.';

  @override
  String get piiUnmaskTitle => 'Mostra dati protetti';

  @override
  String piiUnmaskBody(String field) {
    return 'La visualizzazione di $field viene registrata nel registro di audit. Inserisci una motivazione.';
  }

  @override
  String get piiJustificationLabel => 'Motivazione (almeno 10 caratteri)';

  @override
  String get piiJustificationTooShort =>
      'La motivazione deve avere almeno 10 caratteri.';

  @override
  String get piiUnmaskConfirm => 'Mostra';

  @override
  String get piiUnmaskCancel => 'Annulla';

  @override
  String get piiUnmaskFailed => 'Impossibile mostrare il valore.';

  @override
  String get piiUnmaskForbidden =>
      'Non sei autorizzato a mostrare questo campo.';

  @override
  String get piiUnmaskDemo => 'Mostra campo protetto';
}

/// The translations for Italian, as used in Italy (`it_IT`).
class AppLocalizationsItIt extends AppLocalizationsIt {
  AppLocalizationsItIt() : super('it_IT');

  @override
  String get securityTitle => 'Sicurezza';

  @override
  String get securityEncryptionSection => 'Archiviazione cifrata';

  @override
  String get securityDbEncrypted => 'Il database locale è cifrato';

  @override
  String get securityDbNotEncrypted =>
      'Il database locale non è ancora cifrato';

  @override
  String securityKeyStored(String backend) {
    return 'La chiave di cifratura è custodita in $backend';
  }

  @override
  String get securityKeyMissing =>
      'Nessuna chiave di cifratura nell\'archivio sicuro';

  @override
  String get securityBackendKeychain => 'Keychain';

  @override
  String get securityBackendKeystore => 'Android Keystore';

  @override
  String get securityBackendSecure => 'archivio sicuro della piattaforma';

  @override
  String get securityLockSection => 'Blocco sessione';

  @override
  String get securityLockEnabled => 'Blocca dopo inattività';

  @override
  String get securityLockTimeout => 'Timeout di blocco';

  @override
  String get securityTimeout30s => '30 secondi';

  @override
  String get securityTimeout1m => '1 minuto';

  @override
  String get securityTimeout5m => '5 minuti';

  @override
  String get securityTimeout15m => '15 minuti';

  @override
  String get securitySetPin => 'Imposta PIN';

  @override
  String get securityPinHint => 'PIN (almeno 4 cifre)';

  @override
  String get securityPinSaved => 'PIN salvato';

  @override
  String get securityPinTooShort => 'Il PIN deve avere almeno 4 cifre.';

  @override
  String get securityNoLockMethod =>
      'Imposta un PIN o attiva la biometria per usare il blocco sessione.';

  @override
  String get securityLockNow => 'Blocca ora';

  @override
  String get securityQueueSection => 'Coda di audit';

  @override
  String securityQueuePending(int count) {
    return '$count voci in attesa di sincronizzazione';
  }

  @override
  String get securityQueueAllSynced =>
      'Tutte le voci di audit sono sincronizzate';

  @override
  String securityQueueLastSync(String time) {
    return 'Ultima sincronizzazione: $time';
  }

  @override
  String securityQueueError(String error) {
    return 'Ultimo errore: $error';
  }

  @override
  String get securitySyncNow => 'Sincronizza ora';

  @override
  String get securityVerifyChain => 'Verifica catena';

  @override
  String securityChainValid(int count) {
    return 'Catena di audit verificata ($count voci)';
  }

  @override
  String securityChainBroken(int sequence) {
    return 'Catena di audit interrotta alla voce $sequence';
  }

  @override
  String get securityLockedTitle => 'Sessione bloccata';

  @override
  String get securityUnlockBiometric => 'Sblocca con la biometria';

  @override
  String get securityUnlockReason => 'Autenticati per sbloccare Fattura Facile';

  @override
  String get securityPinLabel => 'PIN';

  @override
  String get securityUnlock => 'Sblocca';

  @override
  String get securityWrongPin => 'PIN errato';

  @override
  String get securityTooManyAttempts => 'Troppi tentativi. Riprova tra poco.';

  @override
  String get piiUnmaskTitle => 'Mostra dati protetti';

  @override
  String piiUnmaskBody(String field) {
    return 'La visualizzazione di $field viene registrata nel registro di audit. Inserisci una motivazione.';
  }

  @override
  String get piiJustificationLabel => 'Motivazione (almeno 10 caratteri)';

  @override
  String get piiJustificationTooShort =>
      'La motivazione deve avere almeno 10 caratteri.';

  @override
  String get piiUnmaskConfirm => 'Mostra';

  @override
  String get piiUnmaskCancel => 'Annulla';

  @override
  String get piiUnmaskFailed => 'Impossibile mostrare il valore.';

  @override
  String get piiUnmaskForbidden =>
      'Non sei autorizzato a mostrare questo campo.';

  @override
  String get piiUnmaskDemo => 'Mostra campo protetto';
}
