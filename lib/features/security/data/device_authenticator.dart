import 'package:local_auth/local_auth.dart';

/// Biometric (Face ID / fingerprint) prompt abstraction so the lock logic stays testable.
abstract interface class DeviceAuthenticator {
  /// `true` when the device has enrolled biometrics or a device credential the OS can prompt for.
  Future<bool> isAvailable();

  /// Shows the OS prompt; `true` only on success. Never throws.
  Future<bool> authenticate(String reason);
}

/// `local_auth` implementation (Keychain/LAContext on iOS, BiometricPrompt on Android).
class LocalAuthAuthenticator implements DeviceAuthenticator {
  LocalAuthAuthenticator([LocalAuthentication? auth])
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<bool> isAvailable() async {
    try {
      if (!await _auth.isDeviceSupported()) {
        return false;
      }
      return (await _auth.getAvailableBiometrics()).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
      );
    } catch (_) {
      return false;
    }
  }
}

/// Authenticator for platforms without biometrics (and the default in tests).
class NoBiometricAuthenticator implements DeviceAuthenticator {
  const NoBiometricAuthenticator();

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<bool> authenticate(String reason) async => false;
}
