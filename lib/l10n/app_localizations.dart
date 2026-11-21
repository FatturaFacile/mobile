// ignore_for_file: deprecated_member_use
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
/// import 'l10n/app_localizations.dart';
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
