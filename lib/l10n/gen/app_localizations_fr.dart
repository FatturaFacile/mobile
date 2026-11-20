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
}
