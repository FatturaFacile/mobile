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
    Locale('en'),
    Locale('fr'),
    Locale('it'),
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
