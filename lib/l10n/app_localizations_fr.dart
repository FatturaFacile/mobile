// ignore_for_file: deprecated_member_use

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

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
}
