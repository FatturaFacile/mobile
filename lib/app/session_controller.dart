import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/error/failure.dart';
import '../features/auth/domain/auth_models.dart';
import 'providers.dart';

/// Signed-out or ready with the hydrated bootstrap context.
sealed class SessionState {
  const SessionState();
}

final class SignedOut extends SessionState {
  const SignedOut({this.error, this.twoFactorRequired = false});

  final Failure? error;
  final bool twoFactorRequired;
}

final class SignedIn extends SessionState {
  const SignedIn(this.bootstrap);

  final Bootstrap bootstrap;
}

/// Owns the session: restore, sign-in, tenant switch and sign-out.
class SessionController extends AsyncNotifier<SessionState> {
  @override
  Future<SessionState> build() async {
    final AuthSession? stored = await ref.read(authRepositoryProvider).restore();
    return stored == null ? const SignedOut() : _hydrate();
  }

  Future<void> signIn({required String email, required String password, required String deviceId, required String platform}) async {
    state = const AsyncLoading<SessionState>();
    final result = await ref.read(authRepositoryProvider).signIn(email: email, password: password, deviceId: deviceId, platform: platform);
    state = AsyncData<SessionState>(
      await result.match(
        (Failure f) async => SignedOut(error: f),
        (LoginOutcome o) async => switch (o) {
          LoginAuthorized() => await _hydrate(),
          LoginTwoFactorRequired() => const SignedOut(twoFactorRequired: true),
        },
      ),
    );
  }

  /// Re-scopes requests and local queries to [tenantId], then reloads the context and delta-syncs.
  Future<void> switchTenant(String tenantId) async {
    await ref.read(authRepositoryProvider).switchTenant(tenantId);
    state = AsyncData<SessionState>(await _hydrate());
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    state = const AsyncData<SessionState>(SignedOut());
  }

  Future<SessionState> _hydrate() async {
    final result = await ref.read(authRepositoryProvider).bootstrap();
    return result.match<SessionState>(
      (Failure f) => SignedOut(error: f),
      (Bootstrap b) => SignedIn(b),
    );
  }
}

final AsyncNotifierProvider<SessionController, SessionState> sessionProvider =
    AsyncNotifierProvider<SessionController, SessionState>(SessionController.new);
