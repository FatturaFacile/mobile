import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('de', 'CH'),
    Locale('en'),
    Locale('fr'),
    Locale('fr', 'CH'),
    Locale('it'),
    Locale('it', 'CH'),
    Locale('it', 'IT'),
  ];

  /// No description provided for @copilotTitle.
  ///
  /// In en, this message translates to:
  /// **'Copilot'**
  String get copilotTitle;

  /// No description provided for @copilotTooltip.
  ///
  /// In en, this message translates to:
  /// **'Open Copilot'**
  String get copilotTooltip;

  /// No description provided for @copilotInputHint.
  ///
  /// In en, this message translates to:
  /// **'Ask anything about your ERP…'**
  String get copilotInputHint;

  /// No description provided for @copilotSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get copilotSend;

  /// No description provided for @copilotEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'How can I help?'**
  String get copilotEmptyTitle;

  /// No description provided for @copilotEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Ask about invoices, stock, due dates or Swiss and Italian regulations.'**
  String get copilotEmptyBody;

  /// No description provided for @copilotNewChat.
  ///
  /// In en, this message translates to:
  /// **'New conversation'**
  String get copilotNewChat;

  /// No description provided for @copilotHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get copilotHistory;

  /// No description provided for @copilotNoHistory.
  ///
  /// In en, this message translates to:
  /// **'No recent conversations'**
  String get copilotNoHistory;

  /// No description provided for @copilotUntitled.
  ///
  /// In en, this message translates to:
  /// **'Untitled conversation'**
  String get copilotUntitled;

  /// No description provided for @copilotDeleteConversation.
  ///
  /// In en, this message translates to:
  /// **'Delete conversation'**
  String get copilotDeleteConversation;

  /// No description provided for @copilotOfflineBanner.
  ///
  /// In en, this message translates to:
  /// **'You are offline: saved conversations are read-only.'**
  String get copilotOfflineBanner;

  /// No description provided for @copilotThinking.
  ///
  /// In en, this message translates to:
  /// **'Thinking…'**
  String get copilotThinking;

  /// No description provided for @copilotToolRunning.
  ///
  /// In en, this message translates to:
  /// **'Running {tool}…'**
  String copilotToolRunning(String tool);

  /// No description provided for @copilotConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm & Execute'**
  String get copilotConfirm;

  /// No description provided for @copilotCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get copilotCancel;

  /// No description provided for @copilotActionTitle.
  ///
  /// In en, this message translates to:
  /// **'Proposed action'**
  String get copilotActionTitle;

  /// No description provided for @copilotEditableFields.
  ///
  /// In en, this message translates to:
  /// **'Edit values before confirming'**
  String get copilotEditableFields;

  /// No description provided for @copilotActionPending.
  ///
  /// In en, this message translates to:
  /// **'Awaiting confirmation'**
  String get copilotActionPending;

  /// No description provided for @copilotActionConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get copilotActionConfirmed;

  /// No description provided for @copilotActionRejected.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get copilotActionRejected;

  /// No description provided for @copilotActionExecuted.
  ///
  /// In en, this message translates to:
  /// **'Executed'**
  String get copilotActionExecuted;

  /// No description provided for @copilotActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get copilotActionFailed;

  /// No description provided for @copilotSources.
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get copilotSources;

  /// No description provided for @copilotRouteUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This screen is not available in the app.'**
  String get copilotRouteUnavailable;

  /// No description provided for @copilotRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get copilotRetry;

  /// No description provided for @copilotErrForbidden.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to use Copilot or this action.'**
  String get copilotErrForbidden;

  /// No description provided for @copilotErrNotFound.
  ///
  /// In en, this message translates to:
  /// **'Item not found.'**
  String get copilotErrNotFound;

  /// No description provided for @copilotErrConflict.
  ///
  /// In en, this message translates to:
  /// **'The action was already cancelled or has failed.'**
  String get copilotErrConflict;

  /// No description provided for @copilotErrInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid values or the action failed.'**
  String get copilotErrInvalid;

  /// No description provided for @copilotErrRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many requests or quota exhausted. Try again later.'**
  String get copilotErrRateLimited;

  /// No description provided for @copilotErrProvider.
  ///
  /// In en, this message translates to:
  /// **'The AI model is currently unavailable.'**
  String get copilotErrProvider;

  /// No description provided for @copilotErrOffline.
  ///
  /// In en, this message translates to:
  /// **'You are offline. Try again when you are back online.'**
  String get copilotErrOffline;

  /// No description provided for @copilotErrUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get copilotErrUnknown;

  /// No description provided for @copilotClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get copilotClose;

  /// No description provided for @securityTitle.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get securityTitle;

  /// No description provided for @securityEncryptionSection.
  ///
  /// In en, this message translates to:
  /// **'Encrypted storage'**
  String get securityEncryptionSection;

  /// No description provided for @securityDbEncrypted.
  ///
  /// In en, this message translates to:
  /// **'Local database is encrypted'**
  String get securityDbEncrypted;

  /// No description provided for @securityDbNotEncrypted.
  ///
  /// In en, this message translates to:
  /// **'Local database is not encrypted yet'**
  String get securityDbNotEncrypted;

  /// No description provided for @securityKeyStored.
  ///
  /// In en, this message translates to:
  /// **'Encryption key is stored in {backend}'**
  String securityKeyStored(String backend);

  /// No description provided for @securityKeyMissing.
  ///
  /// In en, this message translates to:
  /// **'No encryption key found in secure storage'**
  String get securityKeyMissing;

  /// No description provided for @securityBackendKeychain.
  ///
  /// In en, this message translates to:
  /// **'Keychain'**
  String get securityBackendKeychain;

  /// No description provided for @securityBackendKeystore.
  ///
  /// In en, this message translates to:
  /// **'Android Keystore'**
  String get securityBackendKeystore;

  /// No description provided for @securityBackendSecure.
  ///
  /// In en, this message translates to:
  /// **'platform secure storage'**
  String get securityBackendSecure;

  /// No description provided for @securityLockSection.
  ///
  /// In en, this message translates to:
  /// **'Session lock'**
  String get securityLockSection;

  /// No description provided for @securityLockEnabled.
  ///
  /// In en, this message translates to:
  /// **'Lock after inactivity'**
  String get securityLockEnabled;

  /// No description provided for @securityLockTimeout.
  ///
  /// In en, this message translates to:
  /// **'Lock timeout'**
  String get securityLockTimeout;

  /// No description provided for @securityTimeout30s.
  ///
  /// In en, this message translates to:
  /// **'30 seconds'**
  String get securityTimeout30s;

  /// No description provided for @securityTimeout1m.
  ///
  /// In en, this message translates to:
  /// **'1 minute'**
  String get securityTimeout1m;

  /// No description provided for @securityTimeout5m.
  ///
  /// In en, this message translates to:
  /// **'5 minutes'**
  String get securityTimeout5m;

  /// No description provided for @securityTimeout15m.
  ///
  /// In en, this message translates to:
  /// **'15 minutes'**
  String get securityTimeout15m;

  /// No description provided for @securitySetPin.
  ///
  /// In en, this message translates to:
  /// **'Set PIN'**
  String get securitySetPin;

  /// No description provided for @securityPinHint.
  ///
  /// In en, this message translates to:
  /// **'PIN (at least 4 digits)'**
  String get securityPinHint;

  /// No description provided for @securityPinSaved.
  ///
  /// In en, this message translates to:
  /// **'PIN saved'**
  String get securityPinSaved;

  /// No description provided for @securityPinTooShort.
  ///
  /// In en, this message translates to:
  /// **'The PIN must have at least 4 digits.'**
  String get securityPinTooShort;

  /// No description provided for @securityNoLockMethod.
  ///
  /// In en, this message translates to:
  /// **'Set a PIN or enable biometrics to use the session lock.'**
  String get securityNoLockMethod;

  /// No description provided for @securityLockNow.
  ///
  /// In en, this message translates to:
  /// **'Lock now'**
  String get securityLockNow;

  /// No description provided for @securityQueueSection.
  ///
  /// In en, this message translates to:
  /// **'Audit queue'**
  String get securityQueueSection;

  /// No description provided for @securityQueuePending.
  ///
  /// In en, this message translates to:
  /// **'{count} entries waiting to sync'**
  String securityQueuePending(int count);

  /// No description provided for @securityQueueAllSynced.
  ///
  /// In en, this message translates to:
  /// **'All audit entries are synced'**
  String get securityQueueAllSynced;

  /// No description provided for @securityQueueLastSync.
  ///
  /// In en, this message translates to:
  /// **'Last sync: {time}'**
  String securityQueueLastSync(String time);

  /// No description provided for @securityQueueError.
  ///
  /// In en, this message translates to:
  /// **'Last error: {error}'**
  String securityQueueError(String error);

  /// No description provided for @securitySyncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get securitySyncNow;

  /// No description provided for @securityVerifyChain.
  ///
  /// In en, this message translates to:
  /// **'Verify chain'**
  String get securityVerifyChain;

  /// No description provided for @securityChainValid.
  ///
  /// In en, this message translates to:
  /// **'Audit chain verified ({count} entries)'**
  String securityChainValid(int count);

  /// No description provided for @securityChainBroken.
  ///
  /// In en, this message translates to:
  /// **'Audit chain broken at entry {sequence}'**
  String securityChainBroken(int sequence);

  /// No description provided for @securityLockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Session locked'**
  String get securityLockedTitle;

  /// No description provided for @securityUnlockBiometric.
  ///
  /// In en, this message translates to:
  /// **'Unlock with biometrics'**
  String get securityUnlockBiometric;

  /// No description provided for @securityUnlockReason.
  ///
  /// In en, this message translates to:
  /// **'Authenticate to unlock Fattura Facile'**
  String get securityUnlockReason;

  /// No description provided for @securityPinLabel.
  ///
  /// In en, this message translates to:
  /// **'PIN'**
  String get securityPinLabel;

  /// No description provided for @securityUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get securityUnlock;

  /// No description provided for @securityWrongPin.
  ///
  /// In en, this message translates to:
  /// **'Wrong PIN'**
  String get securityWrongPin;

  /// No description provided for @securityTooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again in a moment.'**
  String get securityTooManyAttempts;

  /// No description provided for @piiUnmaskTitle.
  ///
  /// In en, this message translates to:
  /// **'Reveal protected data'**
  String get piiUnmaskTitle;

  /// No description provided for @piiUnmaskBody.
  ///
  /// In en, this message translates to:
  /// **'Revealing {field} is recorded in the audit trail. Enter a justification.'**
  String piiUnmaskBody(String field);

  /// No description provided for @piiJustificationLabel.
  ///
  /// In en, this message translates to:
  /// **'Justification (at least 10 characters)'**
  String get piiJustificationLabel;

  /// No description provided for @piiJustificationTooShort.
  ///
  /// In en, this message translates to:
  /// **'The justification must have at least 10 characters.'**
  String get piiJustificationTooShort;

  /// No description provided for @piiUnmaskConfirm.
  ///
  /// In en, this message translates to:
  /// **'Reveal'**
  String get piiUnmaskConfirm;

  /// No description provided for @piiUnmaskCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get piiUnmaskCancel;

  /// No description provided for @piiUnmaskFailed.
  ///
  /// In en, this message translates to:
  /// **'The value could not be revealed.'**
  String get piiUnmaskFailed;

  /// No description provided for @piiUnmaskForbidden.
  ///
  /// In en, this message translates to:
  /// **'You are not allowed to reveal this field.'**
  String get piiUnmaskForbidden;

  /// No description provided for @piiUnmaskDemo.
  ///
  /// In en, this message translates to:
  /// **'Reveal protected field'**
  String get piiUnmaskDemo;

  /// No description provided for @cogTitle.
  ///
  /// In en, this message translates to:
  /// **'AI suggestions'**
  String get cogTitle;

  /// No description provided for @cogModule.
  ///
  /// In en, this message translates to:
  /// **'AI review'**
  String get cogModule;

  /// No description provided for @cogCaptureHint.
  ///
  /// In en, this message translates to:
  /// **'Dictate or type a request, e.g. \"quote 2 chairs for Muster AG\"'**
  String get cogCaptureHint;

  /// No description provided for @cogKindLabel.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get cogKindLabel;

  /// No description provided for @cogKindSalesQuote.
  ///
  /// In en, this message translates to:
  /// **'Sales quote'**
  String get cogKindSalesQuote;

  /// No description provided for @cogKindPurchaseOrder.
  ///
  /// In en, this message translates to:
  /// **'Purchase order'**
  String get cogKindPurchaseOrder;

  /// No description provided for @cogKindSupportTicket.
  ///
  /// In en, this message translates to:
  /// **'Support ticket'**
  String get cogKindSupportTicket;

  /// No description provided for @cogKindContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get cogKindContact;

  /// No description provided for @cogKindAccountingCoding.
  ///
  /// In en, this message translates to:
  /// **'Accounting coding'**
  String get cogKindAccountingCoding;

  /// No description provided for @cogKindReconciliationMatch.
  ///
  /// In en, this message translates to:
  /// **'Reconciliation match'**
  String get cogKindReconciliationMatch;

  /// No description provided for @cogKindAnomaly.
  ///
  /// In en, this message translates to:
  /// **'Anomaly'**
  String get cogKindAnomaly;

  /// No description provided for @cogKindLatePaymentRisk.
  ///
  /// In en, this message translates to:
  /// **'Late payment risk'**
  String get cogKindLatePaymentRisk;

  /// No description provided for @cogKindChurnRisk.
  ///
  /// In en, this message translates to:
  /// **'Churn risk'**
  String get cogKindChurnRisk;

  /// No description provided for @cogKindReorder.
  ///
  /// In en, this message translates to:
  /// **'Reorder'**
  String get cogKindReorder;

  /// No description provided for @cogKindCashFlowAlert.
  ///
  /// In en, this message translates to:
  /// **'Cash flow alert'**
  String get cogKindCashFlowAlert;

  /// No description provided for @cogKindOther.
  ///
  /// In en, this message translates to:
  /// **'Suggestion'**
  String get cogKindOther;

  /// No description provided for @cogSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get cogSend;

  /// No description provided for @cogDictate.
  ///
  /// In en, this message translates to:
  /// **'Dictate'**
  String get cogDictate;

  /// No description provided for @cogTextTooShort.
  ///
  /// In en, this message translates to:
  /// **'Write at least 10 characters.'**
  String get cogTextTooShort;

  /// No description provided for @cogCaptureSent.
  ///
  /// In en, this message translates to:
  /// **'Sent. The draft is waiting for your review.'**
  String get cogCaptureSent;

  /// No description provided for @cogCaptureQueued.
  ///
  /// In en, this message translates to:
  /// **'Saved offline. It will be sent when the connection returns.'**
  String get cogCaptureQueued;

  /// No description provided for @cogCaptureRejected.
  ///
  /// In en, this message translates to:
  /// **'The request was not accepted: {detail}'**
  String cogCaptureRejected(String detail);

  /// No description provided for @cogQueuedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} captures waiting to be sent'**
  String cogQueuedCount(int count);

  /// No description provided for @cogDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get cogDismiss;

  /// No description provided for @cogConfidenceHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get cogConfidenceHigh;

  /// No description provided for @cogConfidenceMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get cogConfidenceMedium;

  /// No description provided for @cogConfidenceLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get cogConfidenceLow;

  /// No description provided for @cogConfidence.
  ///
  /// In en, this message translates to:
  /// **'Confidence {percent}%'**
  String cogConfidence(int percent);

  /// No description provided for @cogEmpty.
  ///
  /// In en, this message translates to:
  /// **'No suggestions waiting for review'**
  String get cogEmpty;

  /// No description provided for @cogApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get cogApprove;

  /// No description provided for @cogReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get cogReject;

  /// No description provided for @cogRejectTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject suggestion'**
  String get cogRejectTitle;

  /// No description provided for @cogRejectReason.
  ///
  /// In en, this message translates to:
  /// **'Reason (at least 3 characters)'**
  String get cogRejectReason;

  /// No description provided for @cogReasonTooShort.
  ///
  /// In en, this message translates to:
  /// **'Enter at least 3 characters.'**
  String get cogReasonTooShort;

  /// No description provided for @cogCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cogCancel;

  /// No description provided for @cogApproved.
  ///
  /// In en, this message translates to:
  /// **'Suggestion approved.'**
  String get cogApproved;

  /// No description provided for @cogRejected.
  ///
  /// In en, this message translates to:
  /// **'Suggestion rejected.'**
  String get cogRejected;

  /// No description provided for @cogErrForbidden.
  ///
  /// In en, this message translates to:
  /// **'Your role is not allowed to use AI suggestions.'**
  String get cogErrForbidden;

  /// No description provided for @cogErrAlreadyDecided.
  ///
  /// In en, this message translates to:
  /// **'Already decided by someone else. The list was refreshed.'**
  String get cogErrAlreadyDecided;

  /// No description provided for @cogErrInvalid.
  ///
  /// In en, this message translates to:
  /// **'The proposal is incomplete: {detail}'**
  String cogErrInvalid(String detail);

  /// No description provided for @cogErrOffline.
  ///
  /// In en, this message translates to:
  /// **'You are offline. Try again when you are back online.'**
  String get cogErrOffline;

  /// No description provided for @cogErrRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Try again later.'**
  String get cogErrRateLimited;

  /// No description provided for @cogErrProvider.
  ///
  /// In en, this message translates to:
  /// **'The AI service is unavailable right now.'**
  String get cogErrProvider;

  /// No description provided for @cogErrNotFound.
  ///
  /// In en, this message translates to:
  /// **'This suggestion no longer exists.'**
  String get cogErrNotFound;

  /// No description provided for @cogErrUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get cogErrUnknown;

  /// No description provided for @cogAlertTitle.
  ///
  /// In en, this message translates to:
  /// **'High-priority alert'**
  String get cogAlertTitle;

  /// No description provided for @cogAlertReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get cogAlertReview;

  /// No description provided for @cogPriorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High priority'**
  String get cogPriorityHigh;

  /// No description provided for @cogRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get cogRetry;

  /// No description provided for @cogOfflineCached.
  ///
  /// In en, this message translates to:
  /// **'Showing saved suggestions (offline)'**
  String get cogOfflineCached;

  /// No description provided for @dssTitle.
  ///
  /// In en, this message translates to:
  /// **'Executive DSS'**
  String get dssTitle;

  /// No description provided for @dssSyncedAt.
  ///
  /// In en, this message translates to:
  /// **'Synced {time}'**
  String dssSyncedAt(String time);

  /// No description provided for @dssOfflineSince.
  ///
  /// In en, this message translates to:
  /// **'Offline · synced {time}'**
  String dssOfflineSince(String time);

  /// No description provided for @dssNeverSynced.
  ///
  /// In en, this message translates to:
  /// **'Not synced yet'**
  String get dssNeverSynced;

  /// No description provided for @dssSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing…'**
  String get dssSyncing;

  /// No description provided for @dssAllEntities.
  ///
  /// In en, this message translates to:
  /// **'All entities'**
  String get dssAllEntities;

  /// No description provided for @dssLegalEntity.
  ///
  /// In en, this message translates to:
  /// **'Legal entity'**
  String get dssLegalEntity;

  /// No description provided for @dssCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get dssCurrency;

  /// No description provided for @dssPeriodMtd.
  ///
  /// In en, this message translates to:
  /// **'MTD'**
  String get dssPeriodMtd;

  /// No description provided for @dssPeriodQtd.
  ///
  /// In en, this message translates to:
  /// **'QTD'**
  String get dssPeriodQtd;

  /// No description provided for @dssPeriodYtd.
  ///
  /// In en, this message translates to:
  /// **'YTD'**
  String get dssPeriodYtd;

  /// No description provided for @dssPeriodL12m.
  ///
  /// In en, this message translates to:
  /// **'L12M'**
  String get dssPeriodL12m;

  /// No description provided for @dssKpiRevenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get dssKpiRevenue;

  /// No description provided for @dssKpiGrossMargin.
  ///
  /// In en, this message translates to:
  /// **'Gross margin %'**
  String get dssKpiGrossMargin;

  /// No description provided for @dssKpiEbitda.
  ///
  /// In en, this message translates to:
  /// **'EBITDA'**
  String get dssKpiEbitda;

  /// No description provided for @dssKpiNetCash.
  ///
  /// In en, this message translates to:
  /// **'Net cash flow'**
  String get dssKpiNetCash;

  /// No description provided for @dssKpiCcc.
  ///
  /// In en, this message translates to:
  /// **'Cash conversion cycle'**
  String get dssKpiCcc;

  /// No description provided for @dssKpiDso.
  ///
  /// In en, this message translates to:
  /// **'DSO'**
  String get dssKpiDso;

  /// No description provided for @dssDays.
  ///
  /// In en, this message translates to:
  /// **'{value} d'**
  String dssDays(String value);

  /// No description provided for @dssKpiUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No data source'**
  String get dssKpiUnavailable;

  /// No description provided for @dssNoData.
  ///
  /// In en, this message translates to:
  /// **'No data yet'**
  String get dssNoData;

  /// No description provided for @dssNoDataBody.
  ///
  /// In en, this message translates to:
  /// **'Connect to the internet and pull down to load the executive figures.'**
  String get dssNoDataBody;

  /// No description provided for @dssVsBaseline.
  ///
  /// In en, this message translates to:
  /// **'vs baseline'**
  String get dssVsBaseline;

  /// No description provided for @dssAlertsTitle.
  ///
  /// In en, this message translates to:
  /// **'Strategic alerts'**
  String get dssAlertsTitle;

  /// No description provided for @dssNoAlerts.
  ///
  /// In en, this message translates to:
  /// **'No active alerts.'**
  String get dssNoAlerts;

  /// No description provided for @dssSeverityCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get dssSeverityCritical;

  /// No description provided for @dssSeverityWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get dssSeverityWarning;

  /// No description provided for @dssSeverityInfo.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get dssSeverityInfo;

  /// No description provided for @dssAlertMarginErosion.
  ///
  /// In en, this message translates to:
  /// **'Gross margin erosion'**
  String get dssAlertMarginErosion;

  /// No description provided for @dssAlertDsoSpike.
  ///
  /// In en, this message translates to:
  /// **'DSO spike'**
  String get dssAlertDsoSpike;

  /// No description provided for @dssAlertCustomerConcentration.
  ///
  /// In en, this message translates to:
  /// **'Single-customer concentration'**
  String get dssAlertCustomerConcentration;

  /// No description provided for @dssAlertBudgetOverrun.
  ///
  /// In en, this message translates to:
  /// **'Budget overrun'**
  String get dssAlertBudgetOverrun;

  /// No description provided for @dssAlertOutlier.
  ///
  /// In en, this message translates to:
  /// **'Outlier against history'**
  String get dssAlertOutlier;

  /// No description provided for @dssAlertSummaryMarginErosion.
  ///
  /// In en, this message translates to:
  /// **'Gross margin fell {value} pts (limit {threshold} pts).'**
  String dssAlertSummaryMarginErosion(String value, String threshold);

  /// No description provided for @dssAlertSummaryDsoSpike.
  ///
  /// In en, this message translates to:
  /// **'DSO rose by {value} days (limit {threshold}).'**
  String dssAlertSummaryDsoSpike(String value, String threshold);

  /// No description provided for @dssAlertSummaryCustomerConcentration.
  ///
  /// In en, this message translates to:
  /// **'{label} is {value}% of revenue (limit {threshold}%).'**
  String dssAlertSummaryCustomerConcentration(
    String label,
    String value,
    String threshold,
  );

  /// No description provided for @dssAlertSummaryBudgetOverrun.
  ///
  /// In en, this message translates to:
  /// **'Over budget by {value}% (limit {threshold}%).'**
  String dssAlertSummaryBudgetOverrun(String value, String threshold);

  /// No description provided for @dssAlertSummaryOutlier.
  ///
  /// In en, this message translates to:
  /// **'Deviation of {value} σ (threshold {threshold} σ).'**
  String dssAlertSummaryOutlier(String value, String threshold);

  /// No description provided for @dssRootCause.
  ///
  /// In en, this message translates to:
  /// **'Root cause'**
  String get dssRootCause;

  /// No description provided for @dssRecommendedAction.
  ///
  /// In en, this message translates to:
  /// **'Recommended action'**
  String get dssRecommendedAction;

  /// No description provided for @dssCauseMarginErosion.
  ///
  /// In en, this message translates to:
  /// **'Cost of goods is growing faster than prices, or the mix is shifting to low-margin products.'**
  String get dssCauseMarginErosion;

  /// No description provided for @dssActionMarginErosion.
  ///
  /// In en, this message translates to:
  /// **'Review price lists and supplier costs; open the what-if check to size a price increase.'**
  String get dssActionMarginErosion;

  /// No description provided for @dssCauseDsoSpike.
  ///
  /// In en, this message translates to:
  /// **'Customers are paying later, or large invoices are overdue.'**
  String get dssCauseDsoSpike;

  /// No description provided for @dssActionDsoSpike.
  ///
  /// In en, this message translates to:
  /// **'Start dunning on the oldest invoices and agree payment plans with the largest debtors.'**
  String get dssActionDsoSpike;

  /// No description provided for @dssCauseCustomerConcentration.
  ///
  /// In en, this message translates to:
  /// **'One customer generates a disproportionate share of revenue.'**
  String get dssCauseCustomerConcentration;

  /// No description provided for @dssActionCustomerConcentration.
  ///
  /// In en, this message translates to:
  /// **'Diversify the customer base and secure a long-term contract with this customer.'**
  String get dssActionCustomerConcentration;

  /// No description provided for @dssCauseBudgetOverrun.
  ///
  /// In en, this message translates to:
  /// **'Actual spending on this budget line exceeds the approved amount.'**
  String get dssCauseBudgetOverrun;

  /// No description provided for @dssActionBudgetOverrun.
  ///
  /// In en, this message translates to:
  /// **'Freeze discretionary spend on the line and ask the cost-centre owner for a recovery plan.'**
  String get dssActionBudgetOverrun;

  /// No description provided for @dssCauseOutlier.
  ///
  /// In en, this message translates to:
  /// **'The latest value is far from its historical average.'**
  String get dssCauseOutlier;

  /// No description provided for @dssActionOutlier.
  ///
  /// In en, this message translates to:
  /// **'Check the source data for errors, then confirm whether the change is a real trend.'**
  String get dssActionOutlier;

  /// No description provided for @dssTopCustomers.
  ///
  /// In en, this message translates to:
  /// **'Top 5 customers'**
  String get dssTopCustomers;

  /// No description provided for @dssBottomCustomers.
  ///
  /// In en, this message translates to:
  /// **'Bottom 5 customers'**
  String get dssBottomCustomers;

  /// No description provided for @dssTopProducts.
  ///
  /// In en, this message translates to:
  /// **'Top 5 products'**
  String get dssTopProducts;

  /// No description provided for @dssBottomProducts.
  ///
  /// In en, this message translates to:
  /// **'Bottom 5 products'**
  String get dssBottomProducts;

  /// No description provided for @dssNetMargin.
  ///
  /// In en, this message translates to:
  /// **'Net margin'**
  String get dssNetMargin;

  /// No description provided for @dssParetoCore.
  ///
  /// In en, this message translates to:
  /// **'Core'**
  String get dssParetoCore;

  /// No description provided for @dssValueDestroying.
  ///
  /// In en, this message translates to:
  /// **'Eroding value'**
  String get dssValueDestroying;

  /// No description provided for @dssVarianceTitle.
  ///
  /// In en, this message translates to:
  /// **'EBITDA bridge'**
  String get dssVarianceTitle;

  /// No description provided for @dssVarBaseline.
  ///
  /// In en, this message translates to:
  /// **'Baseline'**
  String get dssVarBaseline;

  /// No description provided for @dssVarVolume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get dssVarVolume;

  /// No description provided for @dssVarPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get dssVarPrice;

  /// No description provided for @dssVarCogs.
  ///
  /// In en, this message translates to:
  /// **'COGS'**
  String get dssVarCogs;

  /// No description provided for @dssVarOpex.
  ///
  /// In en, this message translates to:
  /// **'OPEX'**
  String get dssVarOpex;

  /// No description provided for @dssVarFx.
  ///
  /// In en, this message translates to:
  /// **'FX'**
  String get dssVarFx;

  /// No description provided for @dssVarActual.
  ///
  /// In en, this message translates to:
  /// **'Actual'**
  String get dssVarActual;

  /// No description provided for @dssWhatIfTitle.
  ///
  /// In en, this message translates to:
  /// **'What-if quick check'**
  String get dssWhatIfTitle;

  /// No description provided for @dssWhatIfPrice.
  ///
  /// In en, this message translates to:
  /// **'Price change'**
  String get dssWhatIfPrice;

  /// No description provided for @dssWhatIfCogs.
  ///
  /// In en, this message translates to:
  /// **'COGS change'**
  String get dssWhatIfCogs;

  /// No description provided for @dssWhatIfCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get dssWhatIfCurrent;

  /// No description provided for @dssWhatIfSimulated.
  ///
  /// In en, this message translates to:
  /// **'Simulated EBITDA'**
  String get dssWhatIfSimulated;

  /// No description provided for @dssWhatIfChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get dssWhatIfChange;

  /// No description provided for @dssWhatIfReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get dssWhatIfReset;

  /// No description provided for @dssWhatIfOnDevice.
  ///
  /// In en, this message translates to:
  /// **'Computed on this device from the last synced figures.'**
  String get dssWhatIfOnDevice;

  /// No description provided for @dssErrUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Sign in again.'**
  String get dssErrUnauthorized;

  /// No description provided for @dssErrForbidden.
  ///
  /// In en, this message translates to:
  /// **'You do not have access to the Executive DSS.'**
  String get dssErrForbidden;

  /// No description provided for @dssErrFailed.
  ///
  /// In en, this message translates to:
  /// **'The server could not provide the figures. Showing the last synced data.'**
  String get dssErrFailed;

  /// No description provided for @dssClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get dssClose;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'fr', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'de':
      {
        switch (locale.countryCode) {
          case 'CH':
            return AppLocalizationsDeCh();
        }
        break;
      }
    case 'fr':
      {
        switch (locale.countryCode) {
          case 'CH':
            return AppLocalizationsFrCh();
        }
        break;
      }
    case 'it':
      {
        switch (locale.countryCode) {
          case 'CH':
            return AppLocalizationsItCh();
          case 'IT':
            return AppLocalizationsItIt();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
