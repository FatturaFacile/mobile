// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get copilotTitle => 'Copilot';

  @override
  String get copilotTooltip => 'Ouvrir Copilot';

  @override
  String get copilotInputHint => 'Posez une question sur votre ERP…';

  @override
  String get copilotSend => 'Envoyer';

  @override
  String get copilotEmptyTitle => 'Comment puis-je aider ?';

  @override
  String get copilotEmptyBody =>
      'Posez des questions sur les factures, les stocks, les échéances ou les réglementations suisses et italiennes.';

  @override
  String get copilotNewChat => 'Nouvelle conversation';

  @override
  String get copilotHistory => 'Historique';

  @override
  String get copilotNoHistory => 'Aucune conversation récente';

  @override
  String get copilotUntitled => 'Conversation sans titre';

  @override
  String get copilotDeleteConversation => 'Supprimer la conversation';

  @override
  String get copilotOfflineBanner =>
      'Vous êtes hors ligne : les conversations enregistrées sont en lecture seule.';

  @override
  String get copilotThinking => 'Je réfléchis…';

  @override
  String copilotToolRunning(String tool) {
    return 'Exécution de $tool…';
  }

  @override
  String get copilotConfirm => 'Confirmer et exécuter';

  @override
  String get copilotCancel => 'Annuler';

  @override
  String get copilotActionTitle => 'Action proposée';

  @override
  String get copilotEditableFields => 'Modifiez les valeurs avant de confirmer';

  @override
  String get copilotActionPending => 'En attente de confirmation';

  @override
  String get copilotActionConfirmed => 'Confirmée';

  @override
  String get copilotActionRejected => 'Annulée';

  @override
  String get copilotActionExecuted => 'Exécutée';

  @override
  String get copilotActionFailed => 'Échec';

  @override
  String get copilotSources => 'Sources';

  @override
  String get copilotRouteUnavailable =>
      'Cet écran n\'est pas disponible dans l\'application.';

  @override
  String get copilotRetry => 'Réessayer';

  @override
  String get copilotErrForbidden =>
      'Vous n\'avez pas l\'autorisation d\'utiliser Copilot ou cette action.';

  @override
  String get copilotErrNotFound => 'Élément introuvable.';

  @override
  String get copilotErrConflict => 'L\'action a déjà été annulée ou a échoué.';

  @override
  String get copilotErrInvalid => 'Valeurs invalides ou échec de l\'action.';

  @override
  String get copilotErrRateLimited =>
      'Trop de requêtes ou quota épuisé. Réessayez plus tard.';

  @override
  String get copilotErrProvider =>
      'Le modèle d\'IA est actuellement indisponible.';

  @override
  String get copilotErrOffline =>
      'Vous êtes hors ligne. Réessayez une fois reconnecté.';

  @override
  String get copilotErrUnknown => 'Une erreur s\'est produite.';

  @override
  String get copilotClose => 'Fermer';

  @override
  String get securityTitle => 'Sécurité';

  @override
  String get securityEncryptionSection => 'Stockage chiffré';

  @override
  String get securityDbEncrypted => 'La base de données locale est chiffrée';

  @override
  String get securityDbNotEncrypted =>
      'La base de données locale n\'est pas encore chiffrée';

  @override
  String securityKeyStored(String backend) {
    return 'La clé de chiffrement est conservée dans $backend';
  }

  @override
  String get securityKeyMissing =>
      'Aucune clé de chiffrement dans le stockage sécurisé';

  @override
  String get securityBackendKeychain => 'Keychain';

  @override
  String get securityBackendKeystore => 'Android Keystore';

  @override
  String get securityBackendSecure => 'le stockage sécurisé de la plateforme';

  @override
  String get securityLockSection => 'Verrouillage de session';

  @override
  String get securityLockEnabled => 'Verrouiller après inactivité';

  @override
  String get securityLockTimeout => 'Délai de verrouillage';

  @override
  String get securityTimeout30s => '30 secondes';

  @override
  String get securityTimeout1m => '1 minute';

  @override
  String get securityTimeout5m => '5 minutes';

  @override
  String get securityTimeout15m => '15 minutes';

  @override
  String get securitySetPin => 'Définir un code PIN';

  @override
  String get securityPinHint => 'Code PIN (au moins 4 chiffres)';

  @override
  String get securityPinSaved => 'Code PIN enregistré';

  @override
  String get securityPinTooShort =>
      'Le code PIN doit comporter au moins 4 chiffres.';

  @override
  String get securityNoLockMethod =>
      'Définissez un code PIN ou activez la biométrie pour utiliser le verrouillage de session.';

  @override
  String get securityLockNow => 'Verrouiller maintenant';

  @override
  String get securityQueueSection => 'File d\'audit';

  @override
  String securityQueuePending(int count) {
    return '$count entrées en attente de synchronisation';
  }

  @override
  String get securityQueueAllSynced =>
      'Toutes les entrées d\'audit sont synchronisées';

  @override
  String securityQueueLastSync(String time) {
    return 'Dernière synchronisation : $time';
  }

  @override
  String securityQueueError(String error) {
    return 'Dernière erreur : $error';
  }

  @override
  String get securitySyncNow => 'Synchroniser maintenant';

  @override
  String get securityVerifyChain => 'Vérifier la chaîne';

  @override
  String securityChainValid(int count) {
    return 'Chaîne d\'audit vérifiée ($count entrées)';
  }

  @override
  String securityChainBroken(int sequence) {
    return 'Chaîne d\'audit rompue à l\'entrée $sequence';
  }

  @override
  String get securityLockedTitle => 'Session verrouillée';

  @override
  String get securityUnlockBiometric => 'Déverrouiller par biométrie';

  @override
  String get securityUnlockReason =>
      'Authentifiez-vous pour déverrouiller Fattura Facile';

  @override
  String get securityPinLabel => 'Code PIN';

  @override
  String get securityUnlock => 'Déverrouiller';

  @override
  String get securityWrongPin => 'Code PIN incorrect';

  @override
  String get securityTooManyAttempts =>
      'Trop de tentatives. Réessayez dans un instant.';

  @override
  String get piiUnmaskTitle => 'Afficher les données protégées';

  @override
  String piiUnmaskBody(String field) {
    return 'L\'affichage de $field est consigné dans le journal d\'audit. Saisissez une justification.';
  }

  @override
  String get piiJustificationLabel => 'Justification (au moins 10 caractères)';

  @override
  String get piiJustificationTooShort =>
      'La justification doit comporter au moins 10 caractères.';

  @override
  String get piiUnmaskConfirm => 'Afficher';

  @override
  String get piiUnmaskCancel => 'Annuler';

  @override
  String get piiUnmaskFailed => 'La valeur n\'a pas pu être affichée.';

  @override
  String get piiUnmaskForbidden =>
      'Vous n\'êtes pas autorisé à afficher ce champ.';

  @override
  String get piiUnmaskDemo => 'Afficher le champ protégé';

  @override
  String get cogTitle => 'Suggestions IA';

  @override
  String get cogModule => 'Revue IA';

  @override
  String get cogCaptureHint =>
      'Dictez ou saisissez une demande, p. ex. \"devis 2 chaises pour Muster AG\"';

  @override
  String get cogKindLabel => 'Créer';

  @override
  String get cogKindSalesQuote => 'Devis';

  @override
  String get cogKindPurchaseOrder => 'Bon de commande';

  @override
  String get cogKindSupportTicket => 'Ticket de support';

  @override
  String get cogKindContact => 'Contact';

  @override
  String get cogKindAccountingCoding => 'Imputation comptable';

  @override
  String get cogKindReconciliationMatch => 'Rapprochement';

  @override
  String get cogKindAnomaly => 'Anomalie';

  @override
  String get cogKindLatePaymentRisk => 'Risque de retard de paiement';

  @override
  String get cogKindChurnRisk => 'Risque de perte client';

  @override
  String get cogKindReorder => 'Réapprovisionnement';

  @override
  String get cogKindCashFlowAlert => 'Alerte de trésorerie';

  @override
  String get cogKindOther => 'Suggestion';

  @override
  String get cogSend => 'Envoyer';

  @override
  String get cogDictate => 'Dicter';

  @override
  String get cogTextTooShort => 'Saisissez au moins 10 caractères.';

  @override
  String get cogCaptureSent => 'Envoyé. Le brouillon attend votre validation.';

  @override
  String get cogCaptureQueued =>
      'Enregistré hors ligne. Envoi dès le retour de la connexion.';

  @override
  String cogCaptureRejected(String detail) {
    return 'La demande n\'a pas été acceptée : $detail';
  }

  @override
  String cogQueuedCount(int count) {
    return '$count demandes en attente d\'envoi';
  }

  @override
  String get cogDismiss => 'Ignorer';

  @override
  String get cogConfidenceHigh => 'Élevée';

  @override
  String get cogConfidenceMedium => 'Moyenne';

  @override
  String get cogConfidenceLow => 'Faible';

  @override
  String cogConfidence(int percent) {
    return 'Confiance $percent %';
  }

  @override
  String get cogEmpty => 'Aucune suggestion à valider';

  @override
  String get cogApprove => 'Approuver';

  @override
  String get cogReject => 'Rejeter';

  @override
  String get cogRejectTitle => 'Rejeter la suggestion';

  @override
  String get cogRejectReason => 'Motif (au moins 3 caractères)';

  @override
  String get cogReasonTooShort => 'Saisissez au moins 3 caractères.';

  @override
  String get cogCancel => 'Annuler';

  @override
  String get cogApproved => 'Suggestion approuvée.';

  @override
  String get cogRejected => 'Suggestion rejetée.';

  @override
  String get cogErrForbidden =>
      'Votre rôle n\'autorise pas les suggestions IA.';

  @override
  String get cogErrAlreadyDecided =>
      'Déjà décidé par un autre utilisateur. Liste actualisée.';

  @override
  String cogErrInvalid(String detail) {
    return 'La proposition est incomplète : $detail';
  }

  @override
  String get cogErrOffline =>
      'Vous êtes hors ligne. Réessayez une fois reconnecté.';

  @override
  String get cogErrRateLimited => 'Trop de requêtes. Réessayez plus tard.';

  @override
  String get cogErrProvider => 'Le service IA est momentanément indisponible.';

  @override
  String get cogErrNotFound => 'Cette suggestion n\'existe plus.';

  @override
  String get cogErrUnknown => 'Une erreur est survenue.';

  @override
  String get cogAlertTitle => 'Alerte haute priorité';

  @override
  String get cogAlertReview => 'Examiner';

  @override
  String get cogPriorityHigh => 'Haute priorité';

  @override
  String get cogRetry => 'Réessayer';

  @override
  String get cogOfflineCached => 'Suggestions enregistrées (hors ligne)';
}

/// The translations for French, as used in Switzerland (`fr_CH`).
class AppLocalizationsFrCh extends AppLocalizationsFr {
  AppLocalizationsFrCh() : super('fr_CH');

  @override
  String get securityTitle => 'Sécurité';

  @override
  String get securityEncryptionSection => 'Stockage chiffré';

  @override
  String get securityDbEncrypted => 'La base de données locale est chiffrée';

  @override
  String get securityDbNotEncrypted =>
      'La base de données locale n\'est pas encore chiffrée';

  @override
  String securityKeyStored(String backend) {
    return 'La clé de chiffrement est conservée dans $backend';
  }

  @override
  String get securityKeyMissing =>
      'Aucune clé de chiffrement dans le stockage sécurisé';

  @override
  String get securityBackendKeychain => 'Keychain';

  @override
  String get securityBackendKeystore => 'Android Keystore';

  @override
  String get securityBackendSecure => 'le stockage sécurisé de la plateforme';

  @override
  String get securityLockSection => 'Verrouillage de session';

  @override
  String get securityLockEnabled => 'Verrouiller après inactivité';

  @override
  String get securityLockTimeout => 'Délai de verrouillage';

  @override
  String get securityTimeout30s => '30 secondes';

  @override
  String get securityTimeout1m => '1 minute';

  @override
  String get securityTimeout5m => '5 minutes';

  @override
  String get securityTimeout15m => '15 minutes';

  @override
  String get securitySetPin => 'Définir un code PIN';

  @override
  String get securityPinHint => 'Code PIN (au moins 4 chiffres)';

  @override
  String get securityPinSaved => 'Code PIN enregistré';

  @override
  String get securityPinTooShort =>
      'Le code PIN doit comporter au moins 4 chiffres.';

  @override
  String get securityNoLockMethod =>
      'Définissez un code PIN ou activez la biométrie pour utiliser le verrouillage de session.';

  @override
  String get securityLockNow => 'Verrouiller maintenant';

  @override
  String get securityQueueSection => 'File d\'audit';

  @override
  String securityQueuePending(int count) {
    return '$count entrées en attente de synchronisation';
  }

  @override
  String get securityQueueAllSynced =>
      'Toutes les entrées d\'audit sont synchronisées';

  @override
  String securityQueueLastSync(String time) {
    return 'Dernière synchronisation : $time';
  }

  @override
  String securityQueueError(String error) {
    return 'Dernière erreur : $error';
  }

  @override
  String get securitySyncNow => 'Synchroniser maintenant';

  @override
  String get securityVerifyChain => 'Vérifier la chaîne';

  @override
  String securityChainValid(int count) {
    return 'Chaîne d\'audit vérifiée ($count entrées)';
  }

  @override
  String securityChainBroken(int sequence) {
    return 'Chaîne d\'audit rompue à l\'entrée $sequence';
  }

  @override
  String get securityLockedTitle => 'Session verrouillée';

  @override
  String get securityUnlockBiometric => 'Déverrouiller par biométrie';

  @override
  String get securityUnlockReason =>
      'Authentifiez-vous pour déverrouiller Fattura Facile';

  @override
  String get securityPinLabel => 'Code PIN';

  @override
  String get securityUnlock => 'Déverrouiller';

  @override
  String get securityWrongPin => 'Code PIN incorrect';

  @override
  String get securityTooManyAttempts =>
      'Trop de tentatives. Réessayez dans un instant.';

  @override
  String get piiUnmaskTitle => 'Afficher les données protégées';

  @override
  String piiUnmaskBody(String field) {
    return 'L\'affichage de $field est consigné dans le journal d\'audit. Saisissez une justification.';
  }

  @override
  String get piiJustificationLabel => 'Justification (au moins 10 caractères)';

  @override
  String get piiJustificationTooShort =>
      'La justification doit comporter au moins 10 caractères.';

  @override
  String get piiUnmaskConfirm => 'Afficher';

  @override
  String get piiUnmaskCancel => 'Annuler';

  @override
  String get piiUnmaskFailed => 'La valeur n\'a pas pu être affichée.';

  @override
  String get piiUnmaskForbidden =>
      'Vous n\'êtes pas autorisé à afficher ce champ.';

  @override
  String get piiUnmaskDemo => 'Afficher le champ protégé';
}
