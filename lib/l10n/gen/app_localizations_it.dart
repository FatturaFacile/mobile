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
