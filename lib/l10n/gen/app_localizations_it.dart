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
}
