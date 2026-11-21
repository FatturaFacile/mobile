import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/error/failure.dart';
import '../core/network/auth_problem_interceptor.dart';
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
    final AuthSession? stored = await ref
        .read(authRepositoryProvider)
        .restore();
    return stored == null ? const SignedOut() : _hydrate();
  }

  Future<void> signIn({
    required String email,
    required String password,
    required String deviceId,
    required String platform,
  }) async {
    state = const AsyncLoading<SessionState>();
    final result = await ref
        .read(authRepositoryProvider)
        .signIn(
          email: email,
          password: password,
          deviceId: deviceId,
          platform: platform,
        );
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
    await ref.read(permissionRepositoryProvider).purge();
    state = const AsyncData<SessionState>(SignedOut());
  }

  /// Reacts to what the server withdrew: a remote revocation (401) or the loss of the company ends the session at once and
  /// wipes every local credential and cached right; stale permissions are reloaded; a missing second factor asks for it.
  Future<void> onApiProblem(ApiProblem problem) async {
    switch (problem) {
      case ApiProblem.sessionRevoked:
        await _endLocally(
          const SignedOut(error: UnauthorizedFailure('session_revoked')),
        );
      case ApiProblem.companyAccessRevoked:
        await _endLocally(
          const SignedOut(error: ForbiddenFailure('company_access_revoked')),
        );
      case ApiProblem.mfaRequired:
        await _endLocally(
          const SignedOut(
            error: ForbiddenFailure('mfa_required'),
            twoFactorRequired: true,
          ),
        );
      case ApiProblem.permissionDenied:
        await refreshPermissions();
    }
  }

  /// Reloads the permissions of the signed-in user (the server answered permission_denied).
  Future<void> refreshPermissions() async {
    final SessionState? current = state.value;
    if (current is SignedIn) {
      await ref
          .read(permissionRepositoryProvider)
          .sync(
            tenantId: current.bootstrap.tenantId,
            userId: current.bootstrap.userId,
          );
    }
  }

  Future<void> _endLocally(SessionState next) async {
    await ref.read(authRepositoryProvider).signOut();
    await ref.read(permissionRepositoryProvider).purge();
    state = AsyncData<SessionState>(next);
  }

  Future<SessionState> _hydrate() async {
    final result = await ref.read(authRepositoryProvider).bootstrap();
    final SessionState next = result.match<SessionState>(
      (Failure f) => SignedOut(error: f),
      (Bootstrap b) => SignedIn(b),
    );
    if (next is SignedIn) {
      await ref
          .read(permissionRepositoryProvider)
          .sync(
            tenantId: next.bootstrap.tenantId,
            userId: next.bootstrap.userId,
          );
    }
    return next;
  }
}

final AsyncNotifierProvider<SessionController, SessionState> sessionProvider =
    AsyncNotifierProvider<SessionController, SessionState>(
      SessionController.new,
    );
