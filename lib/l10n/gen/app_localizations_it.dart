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
}
