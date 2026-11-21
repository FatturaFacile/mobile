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

  @override
  String get prModuleTitle => 'Demandes d\'achat';

  @override
  String get prHubTitle => 'Demandes d\'achat (DA)';

  @override
  String get prTabMyRequests => 'Mes demandes';

  @override
  String get prTabToApprove => 'À approuver';

  @override
  String get prEmptyMyRequests => 'Aucune demande d\'achat pour le moment';

  @override
  String get prEmptyToApprove =>
      'Aucune demande en attente de votre approbation';

  @override
  String get prCreateAction => 'Nouvelle DA';

  @override
  String get prRefreshTooltip => 'Actualiser';

  @override
  String get prDraftLocalNumber => 'Brouillon local';

  @override
  String get prOfflineBanner =>
      'Mode hors ligne : brouillons et approbations seront synchronisés dès le retour du réseau';

  @override
  String get prStatusDraft => 'Brouillon';

  @override
  String get prStatusPendingApproval => 'En attente d\'approbation';

  @override
  String get prStatusApproved => 'Approuvée';

  @override
  String get prStatusRejected => 'Rejetée';

  @override
  String get prStatusBudgetExceeded => 'Budget dépassé';

  @override
  String get prStatusConvertedToRdo => 'Convertie en consultation';

  @override
  String get prStatusConvertedToPo => 'Convertie en commande';

  @override
  String get prStatusCancelled => 'Annulée';

  @override
  String get prSyncSynced => 'Synchronisée';

  @override
  String get prSyncPendingUpload => 'En attente de sync';

  @override
  String get prSyncError => 'Erreur de sync';

  @override
  String get prSyncRetry => 'Relancer la sync';

  @override
  String get prQueuedForSync =>
      'Mise en file d\'attente pour synchronisation automatique';

  @override
  String get prDraftSavedOffline => 'Brouillon enregistré localement';

  @override
  String get prSubmittedSuccess => 'Demande d\'achat soumise pour approbation';

  @override
  String prSyncCompletedSubmitted(String number) {
    return 'DA $number synchronisée et soumise';
  }

  @override
  String prSyncCompletedBudgetBlocked(String number) {
    return 'DA $number bloquée par le contrôle budgétaire après sync';
  }

  @override
  String get prSyncCompletedApproval => 'Décision d\'approbation synchronisée';

  @override
  String get prUrgencyLow => 'Basse';

  @override
  String get prUrgencyNormal => 'Normale';

  @override
  String get prUrgencyHigh => 'Haute';

  @override
  String get prUrgencyCritical => 'Critique';

  @override
  String prLinkedRdoLabel(String number) {
    return 'RDO $number';
  }

  @override
  String prLinkedPoLabel(String number) {
    return 'BC $number';
  }

  @override
  String get prLinkedDocumentsTitle => 'Documents d\'achat liés';

  @override
  String get prCreateTitle => 'Nouvelle demande d\'achat';

  @override
  String get prEditTitle => 'Modifier la demande';

  @override
  String get prCostCenterLabel => 'Centre de coûts';

  @override
  String get prCostCenterRequired => 'Sélectionnez un centre de coûts';

  @override
  String get prProjectLabel => 'Projet (Facultatif)';

  @override
  String get prProjectNone => 'Aucun projet';

  @override
  String get prUrgencyLabel => 'Urgence';

  @override
  String get prCurrencyLabel => 'Devise';

  @override
  String get prDeliveryDateLabel => 'Date de livraison souhaitée';

  @override
  String get prDeliveryDateHint => 'Choisir une date';

  @override
  String get prJustificationLabel => 'Justification économique';

  @override
  String get prJustificationHint =>
      'Expliquez le besoin opérationnel ou l\'impact';

  @override
  String get prJustificationRequired =>
      'La justification économique est requise pour soumettre';

  @override
  String get prLinesSectionTitle => 'Lignes de demande';

  @override
  String get prLinesEmpty => 'Aucune ligne ajoutée';

  @override
  String get prLinesRequired => 'Ajoutez au moins une ligne avant de soumettre';

  @override
  String get prAddLineAction => 'Ajouter une ligne';

  @override
  String get prScanBarcodeAction => 'Scanner code-barres';

  @override
  String get prSaveDraftOffline => 'Enregistrer brouillon (Hors ligne)';

  @override
  String get prSubmitForApproval => 'Soumettre pour approbation';

  @override
  String get prTotalAmountLabel => 'Montant total';

  @override
  String get prLineTypeCatalog => 'Recherche catalogue';

  @override
  String get prLineTypeFreeText => 'Saisie libre';

  @override
  String get prCatalogSearchHint => 'Rechercher par SKU, code-barres ou nom';

  @override
  String get prCatalogEmpty => 'Aucun article correspondant trouvé';

  @override
  String prBarcodeMatched(String item) {
    return 'Article ajouté : $item';
  }

  @override
  String prBarcodeNotFound(String code) {
    return 'Aucun article trouvé pour le code \"$code\"';
  }

  @override
  String get prLineDescriptionLabel => 'Description';

  @override
  String get prLineQuantityLabel => 'Quantité';

  @override
  String get prLineUnitPriceLabel => 'Prix unitaire';

  @override
  String get prLineUomLabel => 'Unité de mesure';

  @override
  String get prLineNotesLabel => 'Notes (Facultatif)';

  @override
  String get prLineAddConfirm => 'Ajouter à la demande';

  @override
  String get prFieldRequired => 'Champ obligatoire';

  @override
  String get prInvalidNumber => 'Saisissez un nombre valide';

  @override
  String get prMustBePositive => 'La valeur doit être supérieure à zéro';

  @override
  String get prBudgetTitle => 'Budget du centre de coûts';

  @override
  String get prBudgetOfflineInfo =>
      'Hors ligne : le contrôle budgétaire en temps réel s\'exécutera lors de la synchronisation.';

  @override
  String get prBudgetChecking => 'Vérification du budget en cours...';

  @override
  String get prBudgetStatusOk => 'Dans le budget';

  @override
  String get prBudgetStatusWarning => 'Alerte budget';

  @override
  String get prBudgetStatusHardBlock => 'Budget dépassé (Bloqué)';

  @override
  String get prBudgetAllocated => 'Alloué';

  @override
  String get prBudgetCommitted => 'Engagé';

  @override
  String get prBudgetAvailable => 'Disponible';

  @override
  String get prBudgetRequested => 'Demandé';

  @override
  String get prBudgetRemaining => 'Restant';

  @override
  String prBudgetUtilization(String percent) {
    return '$percent% utilisé';
  }

  @override
  String get prBudgetWarningDialogTitle => 'Alerte seuil budgétaire';

  @override
  String get prBudgetWarningDialogBody =>
      'Cette demande dépasse le seuil d\'alerte du centre de coûts. Voulez-vous la soumettre quand même ?';

  @override
  String get prBudgetWarningProceed => 'Soumettre quand même';

  @override
  String get prBudgetHardBlockSubmitBlocked =>
      'Soumission bloquée : budget du centre de coûts dépassé.';

  @override
  String get prDetailTitle => 'Détail de la DA';

  @override
  String get prRequesterLabel => 'Demandeur';

  @override
  String get prRequestedDateLabel => 'Demandée le';

  @override
  String get prApprovalProgressTitle => 'Circuit d\'approbation';

  @override
  String prApprovalLevelLabel(int level) {
    return 'Niveau $level';
  }

  @override
  String get prApprovalStepApproved => 'Approuvé';

  @override
  String get prApprovalStepPending => 'En attente';

  @override
  String get prApprovalStepRejected => 'Rejeté';

  @override
  String get prApprovalStepWaiting => 'En file';

  @override
  String get prAuditTrailTitle => 'Journal d\'audit des approbations';

  @override
  String get prAuditTrailEmpty => 'Aucun événement d\'approbation enregistré';

  @override
  String get prAuditActionSubmitted => 'Soumise';

  @override
  String get prAuditActionApproved => 'Approuvée';

  @override
  String get prAuditActionRejected => 'Rejetée';

  @override
  String get prAuditActionBudgetWarning => 'Alerte budget';

  @override
  String get prAuditActionBudgetBlocked => 'Blocage budget';

  @override
  String get prAuditActionEscalated => 'Escaladée';

  @override
  String get prAuditActionConverted => 'Convertie';

  @override
  String get prChannelWeb => 'Web';

  @override
  String get prChannelMobileApp => 'App Mobile';

  @override
  String get prChannelMobilePush => 'Push 1-Tap';

  @override
  String get prChannelEmailOneClick => 'E-mail 1-Clic';

  @override
  String get prChannelSystem => 'Système';

  @override
  String get prPendingSyncTag => 'Sync en attente';

  @override
  String get prApproveOneTap => 'Approuver 1-Tap';

  @override
  String get prRejectAction => 'Rejeter';

  @override
  String get prApprovedConfirmation => 'Demande approuvée';

  @override
  String get prApprovedQueuedOffline =>
      'Approbation mise en file hors ligne ; elle sera synchronisée à la reconnexion';

  @override
  String get prRejectedConfirmation => 'Demande rejetée';

  @override
  String get prRejectedQueuedOffline =>
      'Rejet mis en file hors ligne ; il sera synchronisé à la reconnexion';

  @override
  String get prRejectSheetTitle => 'Rejeter la demande';

  @override
  String get prRejectReasonLabel => 'Motif du rejet';

  @override
  String get prRejectReasonHint => 'Indiquez clairement la raison du rejet';

  @override
  String get prRejectReasonRequired => 'Un motif de rejet est obligatoire';

  @override
  String get prRejectConfirmAction => 'Confirmer le rejet';

  @override
  String get prCancelAction => 'Annuler';

  @override
  String get prNotFound => 'Demande d\'achat introuvable';

  @override
  String get prGenericError =>
      'Impossible de terminer l\'opération. Réessayez.';

  @override
  String prLevelBadge(int current, int total) {
    return 'Niveau $current/$total';
  }

  @override
  String get mfgModuleTitle => 'Ingénierie de production';

  @override
  String get mfgHubTitle => 'Ingénierie de production';

  @override
  String get mfgTabRoutings => 'Gammes';

  @override
  String get mfgTabMachines => 'Machines';

  @override
  String get mfgTabOee => 'TRS';

  @override
  String get mfgSyncAction => 'Synchroniser';

  @override
  String get mfgSyncFailed => 'Échec de la synchronisation, données hors ligne';

  @override
  String get mfgEmptyRoutings => 'Aucune gamme disponible hors ligne';

  @override
  String get mfgEmptyMachines => 'Aucune machine disponible hors ligne';

  @override
  String get mfgEmptyOee => 'Aucune donnée TRS disponible hors ligne';

  @override
  String mfgRevisionLabel(String revision) {
    return 'Rév. $revision';
  }

  @override
  String mfgStepsCount(int count) {
    return '$count opérations';
  }

  @override
  String mfgStepTitle(int sequence, String code) {
    return '$sequence · $code';
  }

  @override
  String mfgWorkCenterLabel(String code) {
    return 'Poste de travail $code';
  }

  @override
  String mfgMinutesValue(String value) {
    return '$value min';
  }

  @override
  String get mfgSetupTime => 'Réglage';

  @override
  String get mfgRunTime => 'Exécution / unité';

  @override
  String get mfgQueueTime => 'File d\'attente';

  @override
  String get mfgMoveTime => 'Transfert';

  @override
  String get mfgSubcontracted => 'Sous-traité';

  @override
  String get mfgCalculatorTitle => 'Délai et coût';

  @override
  String get mfgLotQuantity => 'Quantité du lot';

  @override
  String get mfgIncludeOverlap => 'Chevauchement des lots de transfert';

  @override
  String get mfgCalculate => 'Calculer';

  @override
  String get mfgCalcInvalid => 'Saisissez une quantité supérieure à zéro';

  @override
  String get mfgCalcMissingWorkCenter =>
      'Un poste de travail de cette gamme n\'est pas disponible hors ligne';

  @override
  String get mfgTotalLeadTime => 'Délai total';

  @override
  String get mfgSerialLeadTime => 'Sans chevauchement';

  @override
  String get mfgOverlapSaving => 'Gain par chevauchement';

  @override
  String get mfgTotalCost => 'Coût total';

  @override
  String get mfgUnitCost => 'Coût par unité';

  @override
  String get mfgCostSetup => 'Réglage';

  @override
  String get mfgCostMachine => 'Machine';

  @override
  String get mfgCostLabor => 'Main-d\'œuvre directe';

  @override
  String get mfgCostOverhead => 'Frais généraux';

  @override
  String get mfgCostSubcontracting => 'Sous-traitance';

  @override
  String get mfgCostMaterialNote =>
      'Le coût des matières n\'est pas inclus hors ligne';

  @override
  String mfgMachineStatus(String status) {
    return 'Statut : $status';
  }

  @override
  String get mfgIndustria40 => 'Industrie 4.0';

  @override
  String get mfgTransizione50 => 'Transizione 5.0';

  @override
  String mfgIdealCycle(String seconds) {
    return 'Cycle idéal : $seconds s/unité';
  }

  @override
  String get mfgTelemetryNever => 'Pas de télémétrie';

  @override
  String get mfgTelemetryStale => 'Télémétrie périmée';

  @override
  String get mfgTelemetryOnline => 'Télémétrie en ligne';

  @override
  String mfgOeeValue(String percent) {
    return 'TRS $percent%';
  }

  @override
  String get mfgAvailability => 'Disponibilité';

  @override
  String get mfgPerformance => 'Performance';

  @override
  String get mfgQuality => 'Qualité';

  @override
  String mfgOeeTarget(String percent) {
    return 'Objectif $percent%';
  }

  @override
  String get mfgOeeMeetsTarget => 'Objectif atteint';

  @override
  String mfgOeeBelowTarget(String gap) {
    return '$gap pts sous l\'objectif';
  }

  @override
  String mfgOeePeriod(String from, String to) {
    return '$from – $to';
  }

  @override
  String get mfgGoodUnits => 'Unités bonnes';

  @override
  String get mfgScrapUnits => 'Rebuts';

  @override
  String get mfgReworkUnits => 'Retouches';

  @override
  String get mfgOperatingMinutes => 'Temps de fonctionnement';

  @override
  String get mfgLossesTitle => 'Six grandes pertes (minutes)';

  @override
  String get mfgLossEquipmentFailure => 'Panne d\'équipement';

  @override
  String get mfgLossSetupAdjustment => 'Réglages';

  @override
  String get mfgLossMinorStops => 'Micro-arrêts';

  @override
  String get mfgLossReducedSpeed => 'Vitesse réduite';

  @override
  String get mfgLossProcessDefects => 'Défauts de process';

  @override
  String get mfgLossStartupRejects => 'Rebuts de démarrage';

  @override
  String get mfgTitle => 'Atelier';

  @override
  String get mfgOrdersEmpty =>
      'Aucun ordre de fabrication lancé sur cet appareil. Actualisez une fois en ligne.';

  @override
  String get mfgScanPrompt => 'Scannez un ordre, un lot ou une machine';

  @override
  String get mfgScanButton => 'Scanner';

  @override
  String get mfgScanManualHint => 'Saisir ou scanner un code';

  @override
  String mfgScanUnknown(String code) {
    return 'Code non reconnu : $code';
  }

  @override
  String mfgScanOrderNotFound(String code) {
    return 'L\'ordre $code n\'est pas sur cet appareil. Actualisez une fois en ligne.';
  }

  @override
  String mfgScanMachineNotFound(String code) {
    return 'Machine $code inconnue.';
  }

  @override
  String get mfgScanSelectOrderFirst =>
      'Sélectionnez d\'abord un ordre de fabrication.';

  @override
  String get mfgCameraTitle => 'Pointez la caméra vers le code';

  @override
  String get mfgCameraUnavailable => 'Caméra indisponible. Saisissez le code.';

  @override
  String get mfgOperations => 'Opérations';

  @override
  String get mfgMaterials => 'Matériaux';

  @override
  String get mfgReceipt => 'Réceptionner la production';

  @override
  String get mfgGenealogy => 'Généalogie';

  @override
  String get mfgGenealogyOffline => 'La généalogie nécessite une connexion.';

  @override
  String mfgProgress(String done, String target, String uom) {
    return '$done sur $target $uom';
  }

  @override
  String mfgOpenQty(String qty, String uom) {
    return 'Ouvert : $qty $uom';
  }

  @override
  String get mfgStagedLots => 'Lots préparés';

  @override
  String get mfgNoStaged =>
      'Aucun lot préparé. Scannez une étiquette de matière première.';

  @override
  String mfgSelectLine(String lot) {
    return 'À quel matériau appartient le lot $lot ?';
  }

  @override
  String mfgLotStaged(String lot) {
    return 'Lot $lot préparé';
  }

  @override
  String get mfgQuantity => 'Quantité';

  @override
  String get mfgBackflush => 'Décharger (backflush)';

  @override
  String mfgBackflushQueued(int count) {
    return '$count sorties en file';
  }

  @override
  String get mfgPosted => 'enregistré';

  @override
  String get mfgCheckIn => 'S\'enregistrer sur la machine';

  @override
  String mfgCheckedIn(String machine) {
    return 'Enregistré : $machine';
  }

  @override
  String get mfgSetup => 'Réglage';

  @override
  String get mfgRun => 'Production';

  @override
  String get mfgStartSetup => 'Démarrer le réglage';

  @override
  String get mfgStartRun => 'Démarrer la production';

  @override
  String get mfgPause => 'Pause';

  @override
  String get mfgResume => 'Reprendre';

  @override
  String get mfgPhaseIdle => 'Arrêté';

  @override
  String get mfgPhaseSetup => 'Réglage en cours';

  @override
  String get mfgPhaseRun => 'En production';

  @override
  String get mfgPhasePaused => 'En pause';

  @override
  String get mfgDowntime => 'Arrêt machine';

  @override
  String get mfgGood => 'Bons';

  @override
  String get mfgScrap => 'Rebuts';

  @override
  String get mfgScrapReason => 'Motif du rebut';

  @override
  String get mfgFinalOperation => 'Dernière confirmation de cette opération';

  @override
  String get mfgConfirm => 'Confirmer l\'opération';

  @override
  String get mfgConfirmQueued =>
      'Enregistré. Envoi dès que vous êtes en ligne.';

  @override
  String get mfgErrNothingToPost => 'Rien à confirmer pour l\'instant.';

  @override
  String get mfgErrScrapReason => 'Indiquez le motif du rebut.';

  @override
  String get mfgErrQuantity => 'Saisissez une quantité supérieure à zéro.';

  @override
  String get mfgErrNotExecutable =>
      'Cet ordre n\'est pas lancé en fabrication.';

  @override
  String get mfgQcTitle => 'Liste de contrôle qualité';

  @override
  String get mfgQcPlan => 'Plan de contrôle';

  @override
  String get mfgQcNoPlans => 'Aucun plan de contrôle sur cet appareil.';

  @override
  String get mfgQcMeasured => 'Valeur mesurée';

  @override
  String mfgQcTolerance(String min, String max) {
    return 'Tolérance de $min à $max';
  }

  @override
  String get mfgQcInTolerance => 'Dans la tolérance';

  @override
  String get mfgQcOutOfTolerance => 'Hors tolérance';

  @override
  String get mfgQcInspected => 'Quantité contrôlée';

  @override
  String get mfgQcNotes => 'Remarques';

  @override
  String get mfgQcSignOff => 'Valider';

  @override
  String get mfgQcSignOffQueued => 'Contrôle validé et mis en file.';

  @override
  String get mfgReceiptLot => 'Numéro de lot';

  @override
  String get mfgReceiptQueued => 'Réception mise en file.';

  @override
  String mfgSyncPending(int count) {
    return '$count en attente d\'envoi';
  }

  @override
  String get mfgSyncAllSent => 'Tout est envoyé';

  @override
  String get mfgSyncNow => 'Synchroniser maintenant';

  @override
  String get mfgRefresh => 'Actualiser';

  @override
  String get mfgRefreshFailed =>
      'Actualisation impossible. Données enregistrées affichées.';

  @override
  String get mfgQueueTitle => 'File d\'envoi';

  @override
  String get mfgQueueEmpty => 'Rien en attente d\'envoi.';

  @override
  String get mfgQueueRejected => 'Refusé par le serveur';

  @override
  String mfgQueueRetryAt(String time) {
    return 'Nouvelle tentative à $time';
  }

  @override
  String get mfgQueueRetry => 'Réessayer';

  @override
  String get mfgQueueDiscard => 'Abandonner';

  @override
  String get mfgKindIssue => 'Sortie de matière';

  @override
  String get mfgKindConfirm => 'Confirmation d\'opération';

  @override
  String get mfgKindReceipt => 'Réception de production';

  @override
  String get mfgKindCheckIn => 'Enregistrement machine';

  @override
  String get mfgKindInspection => 'Contrôle qualité';

  @override
  String get mfgStatusReleased => 'Lancé';

  @override
  String get mfgStatusInProgress => 'En cours';

  @override
  String get mfgCancel => 'Annuler';

  @override
  String get mfgAdd => 'Ajouter';
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
