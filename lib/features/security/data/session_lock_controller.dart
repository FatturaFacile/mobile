import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/security/secure_key_store.dart';
import 'device_authenticator.dart';

/// Selectable inactivity timeouts.
const List<Duration> sessionLockTimeouts = <Duration>[
  Duration(seconds: 30),
  Duration(minutes: 1),
  Duration(minutes: 5),
  Duration(minutes: 15),
];

const Duration defaultSessionLockTimeout = Duration(minutes: 5);
const int minPinLength = 4;
const int maxPinAttempts = 5;
const Duration pinLockout = Duration(seconds: 30);

@immutable
class SessionLockState {
  const SessionLockState({
    this.loaded = false,
    this.enabled = false,
    this.timeout = defaultSessionLockTimeout,
    this.locked = false,
    this.pinSet = false,
    this.biometricAvailable = false,
    this.lockedOutUntil,
  });

  final bool loaded;
  final bool enabled;
  final Duration timeout;
  final bool locked;
  final bool pinSet;
  final bool biometricAvailable;
  final DateTime? lockedOutUntil;

  /// The lock can only be used when the user has a way to open it again.
  bool get hasUnlockMethod => pinSet || biometricAvailable;

  /// Whether the gate should enforce the lock at all.
  bool get active => enabled && hasUnlockMethod;

  SessionLockState copyWith({
    bool? loaded,
    bool? enabled,
    Duration? timeout,
    bool? locked,
    bool? pinSet,
    bool? biometricAvailable,
    DateTime? lockedOutUntil,
    bool clearLockout = false,
  }) => SessionLockState(
    loaded: loaded ?? this.loaded,
    enabled: enabled ?? this.enabled,
    timeout: timeout ?? this.timeout,
    locked: locked ?? this.locked,
    pinSet: pinSet ?? this.pinSet,
    biometricAvailable: biometricAvailable ?? this.biometricAvailable,
    lockedOutUntil: clearLockout
        ? null
        : (lockedOutUntil ?? this.lockedOutUntil),
  );
}

/// Result of a PIN attempt.
enum PinResult { unlocked, wrong, lockedOut }

/// Owns the session-lock settings (kept in the Keychain/Keystore) and the locked flag.
class SessionLockController extends Notifier<SessionLockState> {
  int _failedAttempts = 0;
  DateTime? _backgroundedAt;

  SecureKeyStore get _store => ref.read(secureKeyStoreProvider);
  DeviceAuthenticator get _auth => ref.read(deviceAuthenticatorProvider);
  DateTime _now() => ref.read(securityClockProvider)();

  @override
  SessionLockState build() => const SessionLockState();

  /// Reads persisted settings. Storage failures fall back to the defaults (lock disabled).
  Future<void> load() async {
    bool enabled = false;
    Duration timeout = defaultSessionLockTimeout;
    bool pinSet = false;
    try {
      enabled = (await _store.read(SecureKeyNames.lockEnabled)) == '1';
      final int? seconds = int.tryParse(
        await _store.read(SecureKeyNames.lockTimeoutSeconds) ?? '',
      );
      if (seconds != null && seconds > 0) {
        timeout = Duration(seconds: seconds);
      }
      pinSet = (await _store.read(SecureKeyNames.pinHash)) != null;
    } catch (_) {
      // Secure storage unavailable (e.g. unsupported platform): keep the lock disabled.
    }
    final bool bio = await _auth.isAvailable();
    // A device that restarts the app while the lock is enabled starts locked.
    state = SessionLockState(
      loaded: true,
      enabled: enabled,
      timeout: timeout,
      pinSet: pinSet,
      biometricAvailable: bio,
      locked: enabled && (pinSet || bio),
    );
  }

  Future<void> setEnabled(bool value) async {
    if (value && !state.hasUnlockMethod) {
      return;
    }
    await _store.write(SecureKeyNames.lockEnabled, value ? '1' : '0');
    state = state.copyWith(
      enabled: value,
      locked: value ? state.locked : false,
    );
  }

  Future<void> setTimeout(Duration value) async {
    await _store.write(SecureKeyNames.lockTimeoutSeconds, '${value.inSeconds}');
    state = state.copyWith(timeout: value);
  }

  /// Stores a salted SHA-256 of [pin]. Returns `false` when the PIN is too short.
  Future<bool> setPin(String pin) async {
    if (!isValidPin(pin)) {
      return false;
    }
    final String salt = const Uuid().v4();
    await _store.write(SecureKeyNames.pinSalt, salt);
    await _store.write(SecureKeyNames.pinHash, _hashPin(salt, pin));
    state = state.copyWith(pinSet: true);
    return true;
  }

  static bool isValidPin(String pin) =>
      pin.length >= minPinLength && RegExp(r'^\d+$').hasMatch(pin);

  void lock() {
    if (state.active) {
      state = state.copyWith(locked: true);
    }
  }

  /// Called by the gate when the inactivity timer fires.
  void lockForInactivity() => lock();

  void onBackgrounded() => _backgroundedAt = _now();

  /// Locks when the app stayed in the background longer than the timeout.
  void onResumed() {
    final DateTime? since = _backgroundedAt;
    _backgroundedAt = null;
    if (since != null &&
        state.active &&
        _now().difference(since) >= state.timeout) {
      state = state.copyWith(locked: true);
    }
  }

  Future<bool> unlockWithBiometrics(String reason) async {
    if (!state.biometricAvailable) {
      return false;
    }
    final bool ok = await _auth.authenticate(reason);
    if (ok) {
      _unlocked();
    }
    return ok;
  }

  Future<PinResult> unlockWithPin(String pin) async {
    final DateTime now = _now();
    final DateTime? until = state.lockedOutUntil;
    if (until != null && now.isBefore(until)) {
      return PinResult.lockedOut;
    }
    final String? salt = await _store.read(SecureKeyNames.pinSalt);
    final String? hash = await _store.read(SecureKeyNames.pinHash);
    if (salt != null &&
        hash != null &&
        _constantTimeEquals(_hashPin(salt, pin), hash)) {
      _unlocked();
      return PinResult.unlocked;
    }
    _failedAttempts++;
    if (_failedAttempts >= maxPinAttempts) {
      _failedAttempts = 0;
      state = state.copyWith(lockedOutUntil: now.add(pinLockout));
      return PinResult.lockedOut;
    }
    return PinResult.wrong;
  }

  void _unlocked() {
    _failedAttempts = 0;
    state = state.copyWith(locked: false, clearLockout: true);
  }

  String _hashPin(String salt, String pin) =>
      sha256.convert(utf8.encode('$salt:$pin')).toString();

  bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) {
      return false;
    }
    int diff = 0;
    for (int i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}

final Provider<SecureKeyStore> secureKeyStoreProvider =
    Provider<SecureKeyStore>((Ref ref) => FlutterSecureKeyStore());

final Provider<DeviceAuthenticator> deviceAuthenticatorProvider =
    Provider<DeviceAuthenticator>((Ref ref) => LocalAuthAuthenticator());

final Provider<DateTime Function()> securityClockProvider =
    Provider<DateTime Function()>((Ref ref) => DateTime.now);

final NotifierProvider<SessionLockController, SessionLockState>
sessionLockProvider = NotifierProvider<SessionLockController, SessionLockState>(
  SessionLockController.new,
);
