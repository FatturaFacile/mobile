// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get copilotTitle => 'Copilot';

  @override
  String get copilotTooltip => 'Open Copilot';

  @override
  String get copilotInputHint => 'Ask anything about your ERP…';

  @override
  String get copilotSend => 'Send';

  @override
  String get copilotEmptyTitle => 'How can I help?';

  @override
  String get copilotEmptyBody =>
      'Ask about invoices, stock, due dates or Swiss and Italian regulations.';

  @override
  String get copilotNewChat => 'New conversation';

  @override
  String get copilotHistory => 'History';

  @override
  String get copilotNoHistory => 'No recent conversations';

  @override
  String get copilotUntitled => 'Untitled conversation';

  @override
  String get copilotDeleteConversation => 'Delete conversation';

  @override
  String get copilotOfflineBanner =>
      'You are offline: saved conversations are read-only.';

  @override
  String get copilotThinking => 'Thinking…';

  @override
  String copilotToolRunning(String tool) {
    return 'Running $tool…';
  }

  @override
  String get copilotConfirm => 'Confirm & Execute';

  @override
  String get copilotCancel => 'Cancel';

  @override
  String get copilotActionTitle => 'Proposed action';

  @override
  String get copilotEditableFields => 'Edit values before confirming';

  @override
  String get copilotActionPending => 'Awaiting confirmation';

  @override
  String get copilotActionConfirmed => 'Confirmed';

  @override
  String get copilotActionRejected => 'Cancelled';

  @override
  String get copilotActionExecuted => 'Executed';

  @override
  String get copilotActionFailed => 'Failed';

  @override
  String get copilotSources => 'Sources';

  @override
  String get copilotRouteUnavailable =>
      'This screen is not available in the app.';

  @override
  String get copilotRetry => 'Retry';

  @override
  String get copilotErrForbidden =>
      'You do not have permission to use Copilot or this action.';

  @override
  String get copilotErrNotFound => 'Item not found.';

  @override
  String get copilotErrConflict =>
      'The action was already cancelled or has failed.';

  @override
  String get copilotErrInvalid => 'Invalid values or the action failed.';

  @override
  String get copilotErrRateLimited =>
      'Too many requests or quota exhausted. Try again later.';

  @override
  String get copilotErrProvider => 'The AI model is currently unavailable.';

  @override
  String get copilotErrOffline =>
      'You are offline. Try again when you are back online.';

  @override
  String get copilotErrUnknown => 'Something went wrong.';

  @override
  String get copilotClose => 'Close';

  @override
  String get securityTitle => 'Security';

  @override
  String get securityEncryptionSection => 'Encrypted storage';

  @override
  String get securityDbEncrypted => 'Local database is encrypted';

  @override
  String get securityDbNotEncrypted => 'Local database is not encrypted yet';

  @override
  String securityKeyStored(String backend) {
    return 'Encryption key is stored in $backend';
  }

  @override
  String get securityKeyMissing => 'No encryption key found in secure storage';

  @override
  String get securityBackendKeychain => 'Keychain';

  @override
  String get securityBackendKeystore => 'Android Keystore';

  @override
  String get securityBackendSecure => 'platform secure storage';

  @override
  String get securityLockSection => 'Session lock';

  @override
  String get securityLockEnabled => 'Lock after inactivity';

  @override
  String get securityLockTimeout => 'Lock timeout';

  @override
  String get securityTimeout30s => '30 seconds';

  @override
  String get securityTimeout1m => '1 minute';

  @override
  String get securityTimeout5m => '5 minutes';

  @override
  String get securityTimeout15m => '15 minutes';

  @override
  String get securitySetPin => 'Set PIN';

  @override
  String get securityPinHint => 'PIN (at least 4 digits)';

  @override
  String get securityPinSaved => 'PIN saved';

  @override
  String get securityPinTooShort => 'The PIN must have at least 4 digits.';

  @override
  String get securityNoLockMethod =>
      'Set a PIN or enable biometrics to use the session lock.';

  @override
  String get securityLockNow => 'Lock now';

  @override
  String get securityQueueSection => 'Audit queue';

  @override
  String securityQueuePending(int count) {
    return '$count entries waiting to sync';
  }

  @override
  String get securityQueueAllSynced => 'All audit entries are synced';

  @override
  String securityQueueLastSync(String time) {
    return 'Last sync: $time';
  }

  @override
  String securityQueueError(String error) {
    return 'Last error: $error';
  }

  @override
  String get securitySyncNow => 'Sync now';

  @override
  String get securityVerifyChain => 'Verify chain';

  @override
  String securityChainValid(int count) {
    return 'Audit chain verified ($count entries)';
  }

  @override
  String securityChainBroken(int sequence) {
    return 'Audit chain broken at entry $sequence';
  }

  @override
  String get securityLockedTitle => 'Session locked';

  @override
  String get securityUnlockBiometric => 'Unlock with biometrics';

  @override
  String get securityUnlockReason => 'Authenticate to unlock Fattura Facile';

  @override
  String get securityPinLabel => 'PIN';

  @override
  String get securityUnlock => 'Unlock';

  @override
  String get securityWrongPin => 'Wrong PIN';

  @override
  String get securityTooManyAttempts =>
      'Too many attempts. Try again in a moment.';

  @override
  String get piiUnmaskTitle => 'Reveal protected data';

  @override
  String piiUnmaskBody(String field) {
    return 'Revealing $field is recorded in the audit trail. Enter a justification.';
  }

  @override
  String get piiJustificationLabel => 'Justification (at least 10 characters)';

  @override
  String get piiJustificationTooShort =>
      'The justification must have at least 10 characters.';

  @override
  String get piiUnmaskConfirm => 'Reveal';

  @override
  String get piiUnmaskCancel => 'Cancel';

  @override
  String get piiUnmaskFailed => 'The value could not be revealed.';

  @override
  String get piiUnmaskForbidden => 'You are not allowed to reveal this field.';

  @override
  String get piiUnmaskDemo => 'Reveal protected field';
}
