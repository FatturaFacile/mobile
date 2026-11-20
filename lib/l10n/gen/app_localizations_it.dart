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
}
