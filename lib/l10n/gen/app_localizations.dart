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

  /// Launcher card title for the Purchase Requisitions module
  ///
  /// In en, this message translates to:
  /// **'Purchase Requisitions'**
  String get prModuleTitle;

  /// AppBar title on the Purchase Requisitions Hub screen
  ///
  /// In en, this message translates to:
  /// **'Purchase Requisitions'**
  String get prHubTitle;

  /// Segmented tab label for the user's purchase requisitions
  ///
  /// In en, this message translates to:
  /// **'My Requests'**
  String get prTabMyRequests;

  /// Segmented tab label for manager approval inbox
  ///
  /// In en, this message translates to:
  /// **'To Approve'**
  String get prTabToApprove;

  /// Empty state text on My Requests tab
  ///
  /// In en, this message translates to:
  /// **'No purchase requisitions yet'**
  String get prEmptyMyRequests;

  /// Empty state text on To Approve tab
  ///
  /// In en, this message translates to:
  /// **'No requisitions waiting for your approval'**
  String get prEmptyToApprove;

  /// Tooltip and button label to create a new purchase requisition
  ///
  /// In en, this message translates to:
  /// **'New Requisition'**
  String get prCreateAction;

  /// Refresh icon button tooltip
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get prRefreshTooltip;

  /// Fallback title for a local PR that does not yet have a server number
  ///
  /// In en, this message translates to:
  /// **'Local Draft'**
  String get prDraftLocalNumber;

  /// Banner shown when device is offline
  ///
  /// In en, this message translates to:
  /// **'Offline mode: drafts and approvals will sync automatically when online'**
  String get prOfflineBanner;

  /// PR status: draft
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get prStatusDraft;

  /// PR status: pending approval
  ///
  /// In en, this message translates to:
  /// **'Pending Approval'**
  String get prStatusPendingApproval;

  /// PR status: approved
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get prStatusApproved;

  /// PR status: rejected
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get prStatusRejected;

  /// PR status: budget exceeded
  ///
  /// In en, this message translates to:
  /// **'Budget Exceeded'**
  String get prStatusBudgetExceeded;

  /// PR status: converted to request for quotation (RDO)
  ///
  /// In en, this message translates to:
  /// **'Converted to RDO'**
  String get prStatusConvertedToRdo;

  /// PR status: converted to purchase order (PO)
  ///
  /// In en, this message translates to:
  /// **'Converted to PO'**
  String get prStatusConvertedToPo;

  /// PR status: cancelled
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get prStatusCancelled;

  /// Sync badge: synced
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get prSyncSynced;

  /// Sync badge: waiting to upload
  ///
  /// In en, this message translates to:
  /// **'Pending sync'**
  String get prSyncPendingUpload;

  /// Sync badge: sync error
  ///
  /// In en, this message translates to:
  /// **'Sync error'**
  String get prSyncError;

  /// Action button to retry synchronization
  ///
  /// In en, this message translates to:
  /// **'Retry sync'**
  String get prSyncRetry;

  /// Feedback shown when a submission or decision is queued offline
  ///
  /// In en, this message translates to:
  /// **'Queued for automatic sync when online'**
  String get prQueuedForSync;

  /// Snackbar when a draft is saved offline
  ///
  /// In en, this message translates to:
  /// **'Draft saved locally'**
  String get prDraftSavedOffline;

  /// Snackbar when a PR is submitted online
  ///
  /// In en, this message translates to:
  /// **'Purchase requisition submitted for approval'**
  String get prSubmittedSuccess;

  /// Notification banner when an offline-queued PR submission completes upon reconnection
  ///
  /// In en, this message translates to:
  /// **'Requisition {number} synced and submitted'**
  String prSyncCompletedSubmitted(String number);

  /// Notification banner when an offline-queued PR fails budget hard-block upon sync
  ///
  /// In en, this message translates to:
  /// **'Requisition {number} blocked by budget check after sync'**
  String prSyncCompletedBudgetBlocked(String number);

  /// Notification banner when an offline approval or rejection finishes syncing
  ///
  /// In en, this message translates to:
  /// **'Approval decision synced'**
  String get prSyncCompletedApproval;

  /// Urgency level: low
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get prUrgencyLow;

  /// Urgency level: normal
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get prUrgencyNormal;

  /// Urgency level: high
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get prUrgencyHigh;

  /// Urgency level: critical
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get prUrgencyCritical;

  /// Badge showing linked RDO reference
  ///
  /// In en, this message translates to:
  /// **'RDO {number}'**
  String prLinkedRdoLabel(String number);

  /// Badge showing linked PO reference
  ///
  /// In en, this message translates to:
  /// **'PO {number}'**
  String prLinkedPoLabel(String number);

  /// Section title for linked RDO and PO documents
  ///
  /// In en, this message translates to:
  /// **'Linked Procurement Documents'**
  String get prLinkedDocumentsTitle;

  /// AppBar title on the create PR screen
  ///
  /// In en, this message translates to:
  /// **'New Purchase Requisition'**
  String get prCreateTitle;

  /// AppBar title when editing an existing PR draft
  ///
  /// In en, this message translates to:
  /// **'Edit Requisition'**
  String get prEditTitle;

  /// Cost Center field label
  ///
  /// In en, this message translates to:
  /// **'Cost Center'**
  String get prCostCenterLabel;

  /// Validation error when Cost Center is not selected
  ///
  /// In en, this message translates to:
  /// **'Select a Cost Center'**
  String get prCostCenterRequired;

  /// Project picker label
  ///
  /// In en, this message translates to:
  /// **'Project (Optional)'**
  String get prProjectLabel;

  /// Option representing no linked project
  ///
  /// In en, this message translates to:
  /// **'No project'**
  String get prProjectNone;

  /// Urgency selector label
  ///
  /// In en, this message translates to:
  /// **'Urgency'**
  String get prUrgencyLabel;

  /// Currency selector label
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get prCurrencyLabel;

  /// Requested delivery date field label
  ///
  /// In en, this message translates to:
  /// **'Requested Delivery Date'**
  String get prDeliveryDateLabel;

  /// Hint text for requested delivery date
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get prDeliveryDateHint;

  /// Economic justification text field label
  ///
  /// In en, this message translates to:
  /// **'Economic Justification'**
  String get prJustificationLabel;

  /// Hint for economic justification field
  ///
  /// In en, this message translates to:
  /// **'Explain business need or operational impact'**
  String get prJustificationHint;

  /// Validation error when justification is empty on submit
  ///
  /// In en, this message translates to:
  /// **'Economic justification is required to submit'**
  String get prJustificationRequired;

  /// Section title for PR line items
  ///
  /// In en, this message translates to:
  /// **'Line Items'**
  String get prLinesSectionTitle;

  /// Placeholder text when PR has no lines
  ///
  /// In en, this message translates to:
  /// **'No line items added yet'**
  String get prLinesEmpty;

  /// Validation error when submitting with no lines
  ///
  /// In en, this message translates to:
  /// **'Add at least one line item before submitting'**
  String get prLinesRequired;

  /// Button label to open the add line item sheet
  ///
  /// In en, this message translates to:
  /// **'Add Item'**
  String get prAddLineAction;

  /// Button label to add a line via barcode scan
  ///
  /// In en, this message translates to:
  /// **'Scan Barcode'**
  String get prScanBarcodeAction;

  /// Button label to save draft locally offline
  ///
  /// In en, this message translates to:
  /// **'Save Draft (Offline)'**
  String get prSaveDraftOffline;

  /// Button label to submit PR for approval
  ///
  /// In en, this message translates to:
  /// **'Submit for Approval'**
  String get prSubmitForApproval;

  /// Total amount label
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get prTotalAmountLabel;

  /// Segment label for catalog item lookup
  ///
  /// In en, this message translates to:
  /// **'Catalog Search'**
  String get prLineTypeCatalog;

  /// Segment label for free-text item entry
  ///
  /// In en, this message translates to:
  /// **'Free-Text Entry'**
  String get prLineTypeFreeText;

  /// Search field hint in catalog item picker
  ///
  /// In en, this message translates to:
  /// **'Search catalog by SKU, barcode, or name'**
  String get prCatalogSearchHint;

  /// Empty search state in catalog picker
  ///
  /// In en, this message translates to:
  /// **'No matching catalog items found'**
  String get prCatalogEmpty;

  /// Feedback when barcode scan matches a catalog product
  ///
  /// In en, this message translates to:
  /// **'Added catalog item: {item}'**
  String prBarcodeMatched(String item);

  /// Feedback when barcode scan does not match any catalog item
  ///
  /// In en, this message translates to:
  /// **'No catalog item found for code \"{code}\"'**
  String prBarcodeNotFound(String code);

  /// Line item description field label
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get prLineDescriptionLabel;

  /// Line item quantity field label
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get prLineQuantityLabel;

  /// Line item unit price field label
  ///
  /// In en, this message translates to:
  /// **'Unit Price'**
  String get prLineUnitPriceLabel;

  /// Line item unit of measure field label
  ///
  /// In en, this message translates to:
  /// **'Unit of Measure'**
  String get prLineUomLabel;

  /// Line item optional notes label
  ///
  /// In en, this message translates to:
  /// **'Notes (Optional)'**
  String get prLineNotesLabel;

  /// Confirm button in add line item bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Add to Requisition'**
  String get prLineAddConfirm;

  /// Generic required field validation message
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get prFieldRequired;

  /// Numeric format validation error
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number'**
  String get prInvalidNumber;

  /// Positive numeric validation error
  ///
  /// In en, this message translates to:
  /// **'Value must be greater than zero'**
  String get prMustBePositive;

  /// Title of Cost Center budget check card
  ///
  /// In en, this message translates to:
  /// **'Cost Center Budget'**
  String get prBudgetTitle;

  /// Message when budget check cannot run because device is offline
  ///
  /// In en, this message translates to:
  /// **'Offline: real-time budget check will run automatically upon sync.'**
  String get prBudgetOfflineInfo;

  /// Loading label while calling budget-preview
  ///
  /// In en, this message translates to:
  /// **'Checking Cost Center budget...'**
  String get prBudgetChecking;

  /// Budget status badge: within budget
  ///
  /// In en, this message translates to:
  /// **'Within Budget'**
  String get prBudgetStatusOk;

  /// Budget status badge: threshold warning
  ///
  /// In en, this message translates to:
  /// **'Budget Warning'**
  String get prBudgetStatusWarning;

  /// Budget status badge: hard block
  ///
  /// In en, this message translates to:
  /// **'Budget Exceeded (Blocked)'**
  String get prBudgetStatusHardBlock;

  /// Allocated budget figure label
  ///
  /// In en, this message translates to:
  /// **'Allocated'**
  String get prBudgetAllocated;

  /// Committed budget figure label
  ///
  /// In en, this message translates to:
  /// **'Committed'**
  String get prBudgetCommitted;

  /// Available budget figure label
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get prBudgetAvailable;

  /// Requested PR amount label
  ///
  /// In en, this message translates to:
  /// **'Requested'**
  String get prBudgetRequested;

  /// Remaining budget after request label
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get prBudgetRemaining;

  /// Budget utilization percentage label
  ///
  /// In en, this message translates to:
  /// **'{percent}% utilized'**
  String prBudgetUtilization(String percent);

  /// Title of dialog asking user to confirm submission despite budget warning
  ///
  /// In en, this message translates to:
  /// **'Budget Threshold Warning'**
  String get prBudgetWarningDialogTitle;

  /// Body of budget warning confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'This requisition exceeds the Cost Center warning threshold. Do you want to submit it anyway?'**
  String get prBudgetWarningDialogBody;

  /// Confirm button on budget warning dialog
  ///
  /// In en, this message translates to:
  /// **'Submit Anyway'**
  String get prBudgetWarningProceed;

  /// Error banner when submission is prevented by budget hard-block
  ///
  /// In en, this message translates to:
  /// **'Submission blocked: Cost Center budget exceeded.'**
  String get prBudgetHardBlockSubmitBlocked;

  /// AppBar title on the PR detail screen
  ///
  /// In en, this message translates to:
  /// **'Requisition Detail'**
  String get prDetailTitle;

  /// Requester name label
  ///
  /// In en, this message translates to:
  /// **'Requester'**
  String get prRequesterLabel;

  /// Creation/request date label
  ///
  /// In en, this message translates to:
  /// **'Requested on'**
  String get prRequestedDateLabel;

  /// Title of the multi-level approval progress section
  ///
  /// In en, this message translates to:
  /// **'Approval Workflow'**
  String get prApprovalProgressTitle;

  /// Label for an approval workflow level
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String prApprovalLevelLabel(int level);

  /// Approval step status: approved
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get prApprovalStepApproved;

  /// Approval step status: pending
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get prApprovalStepPending;

  /// Approval step status: rejected
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get prApprovalStepRejected;

  /// Approval step status: waiting for previous levels
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get prApprovalStepWaiting;

  /// Section title for immutable approval audit history
  ///
  /// In en, this message translates to:
  /// **'Approval Audit Trail'**
  String get prAuditTrailTitle;

  /// Empty state for audit log section
  ///
  /// In en, this message translates to:
  /// **'No approval events recorded yet'**
  String get prAuditTrailEmpty;

  /// Audit log action: submitted
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get prAuditActionSubmitted;

  /// Audit log action: approved
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get prAuditActionApproved;

  /// Audit log action: rejected
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get prAuditActionRejected;

  /// Audit log action: budget warning
  ///
  /// In en, this message translates to:
  /// **'Budget Warning'**
  String get prAuditActionBudgetWarning;

  /// Audit log action: budget blocked
  ///
  /// In en, this message translates to:
  /// **'Budget Blocked'**
  String get prAuditActionBudgetBlocked;

  /// Audit log action: escalated
  ///
  /// In en, this message translates to:
  /// **'Escalated'**
  String get prAuditActionEscalated;

  /// Audit log action: converted to RDO or PO
  ///
  /// In en, this message translates to:
  /// **'Converted'**
  String get prAuditActionConverted;

  /// Approval channel: web
  ///
  /// In en, this message translates to:
  /// **'Web'**
  String get prChannelWeb;

  /// Approval channel: mobile app
  ///
  /// In en, this message translates to:
  /// **'Mobile App'**
  String get prChannelMobileApp;

  /// Approval channel: mobile push notification 1-tap action
  ///
  /// In en, this message translates to:
  /// **'Push 1-Tap'**
  String get prChannelMobilePush;

  /// Approval channel: email one-click
  ///
  /// In en, this message translates to:
  /// **'Email 1-Click'**
  String get prChannelEmailOneClick;

  /// Approval channel: system
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get prChannelSystem;

  /// Tag shown on local optimistic audit log entries awaiting server sync
  ///
  /// In en, this message translates to:
  /// **'Pending sync'**
  String get prPendingSyncTag;

  /// Primary manager action button to approve a PR in 1 tap
  ///
  /// In en, this message translates to:
  /// **'1-Tap Approve'**
  String get prApproveOneTap;

  /// Secondary manager action button to reject a PR
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get prRejectAction;

  /// Snackbar shown after approving a PR online
  ///
  /// In en, this message translates to:
  /// **'Requisition approved'**
  String get prApprovedConfirmation;

  /// Snackbar shown after approving a PR while offline
  ///
  /// In en, this message translates to:
  /// **'Approval queued offline and will sync on reconnection'**
  String get prApprovedQueuedOffline;

  /// Snackbar shown after rejecting a PR online
  ///
  /// In en, this message translates to:
  /// **'Requisition rejected'**
  String get prRejectedConfirmation;

  /// Snackbar shown after rejecting a PR while offline
  ///
  /// In en, this message translates to:
  /// **'Rejection queued offline and will sync on reconnection'**
  String get prRejectedQueuedOffline;

  /// Title of the rejection reason bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Reject Requisition'**
  String get prRejectSheetTitle;

  /// Label of the mandatory rejection reason field
  ///
  /// In en, this message translates to:
  /// **'Rejection Reason'**
  String get prRejectReasonLabel;

  /// Hint text for rejection reason field
  ///
  /// In en, this message translates to:
  /// **'Provide a clear reason for rejecting this requisition'**
  String get prRejectReasonHint;

  /// Validation error when submitting rejection without a reason
  ///
  /// In en, this message translates to:
  /// **'A rejection reason is mandatory'**
  String get prRejectReasonRequired;

  /// Confirm button in the rejection bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Confirm Rejection'**
  String get prRejectConfirmAction;

  /// Cancel button label
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get prCancelAction;

  /// Message when a requisition cannot be located locally or remotely
  ///
  /// In en, this message translates to:
  /// **'Purchase requisition not found'**
  String get prNotFound;

  /// Fallback error message
  ///
  /// In en, this message translates to:
  /// **'Unable to complete the operation. Please try again.'**
  String get prGenericError;

  /// Compact level progress badge
  ///
  /// In en, this message translates to:
  /// **'Level {current}/{total}'**
  String prLevelBadge(int current, int total);

  /// Mod 061 production engineering: mfgModuleTitle
  ///
  /// In en, this message translates to:
  /// **'Production Engineering'**
  String get mfgModuleTitle;

  /// Mod 061 production engineering: mfgHubTitle
  ///
  /// In en, this message translates to:
  /// **'Production Engineering'**
  String get mfgHubTitle;

  /// Mod 061 production engineering: mfgTabRoutings
  ///
  /// In en, this message translates to:
  /// **'Routings'**
  String get mfgTabRoutings;

  /// Mod 061 production engineering: mfgTabMachines
  ///
  /// In en, this message translates to:
  /// **'Machines'**
  String get mfgTabMachines;

  /// Mod 061 production engineering: mfgTabOee
  ///
  /// In en, this message translates to:
  /// **'OEE'**
  String get mfgTabOee;

  /// Mod 061 production engineering: mfgSyncAction
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get mfgSyncAction;

  /// Mod 061 production engineering: mfgSyncFailed
  ///
  /// In en, this message translates to:
  /// **'Sync failed, showing offline data'**
  String get mfgSyncFailed;

  /// Mod 061 production engineering: mfgEmptyRoutings
  ///
  /// In en, this message translates to:
  /// **'No routings available offline'**
  String get mfgEmptyRoutings;

  /// Mod 061 production engineering: mfgEmptyMachines
  ///
  /// In en, this message translates to:
  /// **'No machines available offline'**
  String get mfgEmptyMachines;

  /// Mod 061 production engineering: mfgEmptyOee
  ///
  /// In en, this message translates to:
  /// **'No OEE data available offline'**
  String get mfgEmptyOee;

  /// Mod 061 production engineering: mfgRevisionLabel
  ///
  /// In en, this message translates to:
  /// **'Rev. {revision}'**
  String mfgRevisionLabel(String revision);

  /// Mod 061 production engineering: mfgStepsCount
  ///
  /// In en, this message translates to:
  /// **'{count} steps'**
  String mfgStepsCount(int count);

  /// Mod 061 production engineering: mfgStepTitle
  ///
  /// In en, this message translates to:
  /// **'{sequence} · {code}'**
  String mfgStepTitle(int sequence, String code);

  /// Mod 061 production engineering: mfgWorkCenterLabel
  ///
  /// In en, this message translates to:
  /// **'Work centre {code}'**
  String mfgWorkCenterLabel(String code);

  /// Mod 061 production engineering: mfgMinutesValue
  ///
  /// In en, this message translates to:
  /// **'{value} min'**
  String mfgMinutesValue(String value);

  /// Mod 061 production engineering: mfgSetupTime
  ///
  /// In en, this message translates to:
  /// **'Setup'**
  String get mfgSetupTime;

  /// Mod 061 production engineering: mfgRunTime
  ///
  /// In en, this message translates to:
  /// **'Run / unit'**
  String get mfgRunTime;

  /// Mod 061 production engineering: mfgQueueTime
  ///
  /// In en, this message translates to:
  /// **'Queue'**
  String get mfgQueueTime;

  /// Mod 061 production engineering: mfgMoveTime
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get mfgMoveTime;

  /// Mod 061 production engineering: mfgSubcontracted
  ///
  /// In en, this message translates to:
  /// **'Subcontracted'**
  String get mfgSubcontracted;

  /// Mod 061 production engineering: mfgCalculatorTitle
  ///
  /// In en, this message translates to:
  /// **'Lead time and cost'**
  String get mfgCalculatorTitle;

  /// Mod 061 production engineering: mfgLotQuantity
  ///
  /// In en, this message translates to:
  /// **'Lot quantity'**
  String get mfgLotQuantity;

  /// Mod 061 production engineering: mfgIncludeOverlap
  ///
  /// In en, this message translates to:
  /// **'Overlap transfer batches'**
  String get mfgIncludeOverlap;

  /// Mod 061 production engineering: mfgCalculate
  ///
  /// In en, this message translates to:
  /// **'Calculate'**
  String get mfgCalculate;

  /// Mod 061 production engineering: mfgCalcInvalid
  ///
  /// In en, this message translates to:
  /// **'Enter a quantity greater than zero'**
  String get mfgCalcInvalid;

  /// Mod 061 production engineering: mfgCalcMissingWorkCenter
  ///
  /// In en, this message translates to:
  /// **'A work centre of this routing is not available offline'**
  String get mfgCalcMissingWorkCenter;

  /// Mod 061 production engineering: mfgTotalLeadTime
  ///
  /// In en, this message translates to:
  /// **'Total lead time'**
  String get mfgTotalLeadTime;

  /// Mod 061 production engineering: mfgSerialLeadTime
  ///
  /// In en, this message translates to:
  /// **'Without overlap'**
  String get mfgSerialLeadTime;

  /// Mod 061 production engineering: mfgOverlapSaving
  ///
  /// In en, this message translates to:
  /// **'Overlap saving'**
  String get mfgOverlapSaving;

  /// Mod 061 production engineering: mfgTotalCost
  ///
  /// In en, this message translates to:
  /// **'Total cost'**
  String get mfgTotalCost;

  /// Mod 061 production engineering: mfgUnitCost
  ///
  /// In en, this message translates to:
  /// **'Cost per unit'**
  String get mfgUnitCost;

  /// Mod 061 production engineering: mfgCostSetup
  ///
  /// In en, this message translates to:
  /// **'Setup'**
  String get mfgCostSetup;

  /// Mod 061 production engineering: mfgCostMachine
  ///
  /// In en, this message translates to:
  /// **'Machine run'**
  String get mfgCostMachine;

  /// Mod 061 production engineering: mfgCostLabor
  ///
  /// In en, this message translates to:
  /// **'Direct labour'**
  String get mfgCostLabor;

  /// Mod 061 production engineering: mfgCostOverhead
  ///
  /// In en, this message translates to:
  /// **'Overhead'**
  String get mfgCostOverhead;

  /// Mod 061 production engineering: mfgCostSubcontracting
  ///
  /// In en, this message translates to:
  /// **'Subcontracting'**
  String get mfgCostSubcontracting;

  /// Mod 061 production engineering: mfgCostMaterialNote
  ///
  /// In en, this message translates to:
  /// **'Material cost is not included offline'**
  String get mfgCostMaterialNote;

  /// Mod 061 production engineering: mfgMachineStatus
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String mfgMachineStatus(String status);

  /// Mod 061 production engineering: mfgIndustria40
  ///
  /// In en, this message translates to:
  /// **'Industria 4.0'**
  String get mfgIndustria40;

  /// Mod 061 production engineering: mfgTransizione50
  ///
  /// In en, this message translates to:
  /// **'Transizione 5.0'**
  String get mfgTransizione50;

  /// Mod 061 production engineering: mfgIdealCycle
  ///
  /// In en, this message translates to:
  /// **'Ideal cycle: {seconds} s/unit'**
  String mfgIdealCycle(String seconds);

  /// Mod 061 production engineering: mfgTelemetryNever
  ///
  /// In en, this message translates to:
  /// **'No telemetry'**
  String get mfgTelemetryNever;

  /// Mod 061 production engineering: mfgTelemetryStale
  ///
  /// In en, this message translates to:
  /// **'Telemetry stale'**
  String get mfgTelemetryStale;

  /// Mod 061 production engineering: mfgTelemetryOnline
  ///
  /// In en, this message translates to:
  /// **'Telemetry online'**
  String get mfgTelemetryOnline;

  /// Mod 061 production engineering: mfgOeeValue
  ///
  /// In en, this message translates to:
  /// **'OEE {percent}%'**
  String mfgOeeValue(String percent);

  /// Mod 061 production engineering: mfgAvailability
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get mfgAvailability;

  /// Mod 061 production engineering: mfgPerformance
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get mfgPerformance;

  /// Mod 061 production engineering: mfgQuality
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get mfgQuality;

  /// Mod 061 production engineering: mfgOeeTarget
  ///
  /// In en, this message translates to:
  /// **'Target {percent}%'**
  String mfgOeeTarget(String percent);

  /// Mod 061 production engineering: mfgOeeMeetsTarget
  ///
  /// In en, this message translates to:
  /// **'Target met'**
  String get mfgOeeMeetsTarget;

  /// Mod 061 production engineering: mfgOeeBelowTarget
  ///
  /// In en, this message translates to:
  /// **'Below target by {gap} pts'**
  String mfgOeeBelowTarget(String gap);

  /// Mod 061 production engineering: mfgOeePeriod
  ///
  /// In en, this message translates to:
  /// **'{from} – {to}'**
  String mfgOeePeriod(String from, String to);

  /// Mod 061 production engineering: mfgGoodUnits
  ///
  /// In en, this message translates to:
  /// **'Good units'**
  String get mfgGoodUnits;

  /// Mod 061 production engineering: mfgScrapUnits
  ///
  /// In en, this message translates to:
  /// **'Scrap'**
  String get mfgScrapUnits;

  /// Mod 061 production engineering: mfgReworkUnits
  ///
  /// In en, this message translates to:
  /// **'Rework'**
  String get mfgReworkUnits;

  /// Mod 061 production engineering: mfgOperatingMinutes
  ///
  /// In en, this message translates to:
  /// **'Operating time'**
  String get mfgOperatingMinutes;

  /// Mod 061 production engineering: mfgLossesTitle
  ///
  /// In en, this message translates to:
  /// **'Six big losses (minutes)'**
  String get mfgLossesTitle;

  /// Mod 061 production engineering: mfgLossEquipmentFailure
  ///
  /// In en, this message translates to:
  /// **'Equipment failure'**
  String get mfgLossEquipmentFailure;

  /// Mod 061 production engineering: mfgLossSetupAdjustment
  ///
  /// In en, this message translates to:
  /// **'Setup and adjustment'**
  String get mfgLossSetupAdjustment;

  /// Mod 061 production engineering: mfgLossMinorStops
  ///
  /// In en, this message translates to:
  /// **'Minor stops'**
  String get mfgLossMinorStops;

  /// Mod 061 production engineering: mfgLossReducedSpeed
  ///
  /// In en, this message translates to:
  /// **'Reduced speed'**
  String get mfgLossReducedSpeed;

  /// Mod 061 production engineering: mfgLossProcessDefects
  ///
  /// In en, this message translates to:
  /// **'Process defects'**
  String get mfgLossProcessDefects;

  /// Mod 061 production engineering: mfgLossStartupRejects
  ///
  /// In en, this message translates to:
  /// **'Start-up rejects'**
  String get mfgLossStartupRejects;
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
