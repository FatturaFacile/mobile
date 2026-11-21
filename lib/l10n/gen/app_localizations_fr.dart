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
  String get dssTitle => 'DSS exécutif';

  @override
  String dssSyncedAt(String time) {
    return 'Synchronisé $time';
  }

  @override
  String dssOfflineSince(String time) {
    return 'Hors ligne · synchronisé $time';
  }

  @override
  String get dssNeverSynced => 'Pas encore synchronisé';

  @override
  String get dssSyncing => 'Synchronisation…';

  @override
  String get dssAllEntities => 'Toutes les entités';

  @override
  String get dssLegalEntity => 'Entité juridique';

  @override
  String get dssCurrency => 'Devise';

  @override
  String get dssPeriodMtd => 'MTD';

  @override
  String get dssPeriodQtd => 'QTD';

  @override
  String get dssPeriodYtd => 'YTD';

  @override
  String get dssPeriodL12m => 'L12M';

  @override
  String get dssKpiRevenue => 'Chiffre d\'affaires';

  @override
  String get dssKpiGrossMargin => 'Marge brute %';

  @override
  String get dssKpiEbitda => 'EBITDA';

  @override
  String get dssKpiNetCash => 'Flux de trésorerie net';

  @override
  String get dssKpiCcc => 'Cycle de conversion de trésorerie';

  @override
  String get dssKpiDso => 'DSO';

  @override
  String dssDays(String value) {
    return '$value j';
  }

  @override
  String get dssKpiUnavailable => 'Aucune source de données';

  @override
  String get dssNoData => 'Pas encore de données';

  @override
  String get dssNoDataBody =>
      'Connectez-vous à Internet et tirez vers le bas pour charger les chiffres de direction.';

  @override
  String get dssVsBaseline => 'vs référence';

  @override
  String get dssAlertsTitle => 'Alertes stratégiques';

  @override
  String get dssNoAlerts => 'Aucune alerte active.';

  @override
  String get dssSeverityCritical => 'Critique';

  @override
  String get dssSeverityWarning => 'Avertissement';

  @override
  String get dssSeverityInfo => 'Info';

  @override
  String get dssAlertMarginErosion => 'Érosion de la marge brute';

  @override
  String get dssAlertDsoSpike => 'Hausse du DSO';

  @override
  String get dssAlertCustomerConcentration => 'Concentration sur un client';

  @override
  String get dssAlertBudgetOverrun => 'Dépassement budgétaire';

  @override
  String get dssAlertOutlier => 'Valeur aberrante par rapport à l\'historique';

  @override
  String dssAlertSummaryMarginErosion(String value, String threshold) {
    return 'La marge brute a baissé de $value pts (limite $threshold pts).';
  }

  @override
  String dssAlertSummaryDsoSpike(String value, String threshold) {
    return 'Le DSO a augmenté de $value jours (limite $threshold).';
  }

  @override
  String dssAlertSummaryCustomerConcentration(
    String label,
    String value,
    String threshold,
  ) {
    return '$label représente $value% du chiffre d\'affaires (limite $threshold%).';
  }

  @override
  String dssAlertSummaryBudgetOverrun(String value, String threshold) {
    return 'Budget dépassé de $value% (limite $threshold%).';
  }

  @override
  String dssAlertSummaryOutlier(String value, String threshold) {
    return 'Écart de $value σ (seuil $threshold σ).';
  }

  @override
  String get dssRootCause => 'Cause principale';

  @override
  String get dssRecommendedAction => 'Action recommandée';

  @override
  String get dssCauseMarginErosion =>
      'Le coût des marchandises progresse plus vite que les prix, ou le mix se déplace vers des produits à faible marge.';

  @override
  String get dssActionMarginErosion =>
      'Revoyez les tarifs et les coûts fournisseurs ; utilisez la simulation what-if pour chiffrer une hausse de prix.';

  @override
  String get dssCauseDsoSpike =>
      'Les clients paient plus tard, ou de grosses factures sont en retard.';

  @override
  String get dssActionDsoSpike =>
      'Lancez les relances sur les plus anciennes factures et convenez de plans de paiement avec les plus gros débiteurs.';

  @override
  String get dssCauseCustomerConcentration =>
      'Un seul client génère une part disproportionnée du chiffre d\'affaires.';

  @override
  String get dssActionCustomerConcentration =>
      'Diversifiez le portefeuille clients et sécurisez un contrat à long terme avec ce client.';

  @override
  String get dssCauseBudgetOverrun =>
      'Les dépenses réelles de cette ligne budgétaire dépassent le montant approuvé.';

  @override
  String get dssActionBudgetOverrun =>
      'Gelez les dépenses discrétionnaires de la ligne et demandez un plan de redressement au responsable du centre de coûts.';

  @override
  String get dssCauseOutlier =>
      'La dernière valeur est très éloignée de sa moyenne historique.';

  @override
  String get dssActionOutlier =>
      'Vérifiez les données sources, puis confirmez si la variation est une vraie tendance.';

  @override
  String get dssTopCustomers => '5 meilleurs clients';

  @override
  String get dssBottomCustomers => '5 derniers clients';

  @override
  String get dssTopProducts => '5 meilleurs produits';

  @override
  String get dssBottomProducts => '5 derniers produits';

  @override
  String get dssNetMargin => 'Marge nette';

  @override
  String get dssParetoCore => 'Cœur';

  @override
  String get dssValueDestroying => 'Destructeur de valeur';

  @override
  String get dssVarianceTitle => 'Pont EBITDA';

  @override
  String get dssVarBaseline => 'Référence';

  @override
  String get dssVarVolume => 'Volume';

  @override
  String get dssVarPrice => 'Prix';

  @override
  String get dssVarCogs => 'Coût des ventes';

  @override
  String get dssVarOpex => 'OPEX';

  @override
  String get dssVarFx => 'Change';

  @override
  String get dssVarActual => 'Réel';

  @override
  String get dssWhatIfTitle => 'Simulation what-if';

  @override
  String get dssWhatIfPrice => 'Variation des prix';

  @override
  String get dssWhatIfCogs => 'Variation du coût des ventes';

  @override
  String get dssWhatIfCurrent => 'Actuel';

  @override
  String get dssWhatIfSimulated => 'EBITDA simulé';

  @override
  String get dssWhatIfChange => 'Variation';

  @override
  String get dssWhatIfReset => 'Réinitialiser';

  @override
  String get dssWhatIfOnDevice =>
      'Calculé sur cet appareil à partir des derniers chiffres synchronisés.';

  @override
  String get dssErrUnauthorized => 'Votre session a expiré. Reconnectez-vous.';

  @override
  String get dssErrForbidden => 'Vous n\'avez pas accès au DSS exécutif.';

  @override
  String get dssErrFailed =>
      'Le serveur n\'a pas pu fournir les chiffres. Affichage des dernières données synchronisées.';

  @override
  String get dssClose => 'Fermer';
}
