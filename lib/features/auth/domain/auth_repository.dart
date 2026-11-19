import 'package:fpdart/fpdart.dart';

import '../../../core/error/failure.dart';
import 'auth_models.dart';

/// Authentication, session persistence and bootstrap hydration.
abstract interface class AuthRepository {
  /// Runs authorize + token exchange (PKCE S256) and registers the device.
  Future<Either<Failure, LoginOutcome>> signIn({
    required String email,
    required String password,
    required String deviceId,
    required String platform,
    String? deviceName,
    String? appVersion,
  });

  /// Restores a stored session into the request context; `null` when signed out.
  Future<AuthSession?> restore();

  /// Points all requests (and local queries) at another tenant.
  Future<void> switchTenant(String tenantId);

  /// `GET /mobile/bootstrap`.
  Future<Either<Failure, Bootstrap>> bootstrap();

  /// Forgets credentials locally.
  Future<void> signOut();
}
