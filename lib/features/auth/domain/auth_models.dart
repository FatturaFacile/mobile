/// Immutable result of a completed sign-in.
class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.tenantId,
    this.deviceSessionId,
  });

  final String accessToken;
  final String tenantId;
  final String? deviceSessionId;
}

/// Outcome of the first login step.
sealed class LoginOutcome {
  const LoginOutcome();
}

/// Credentials accepted; the app now redeems the one-time code.
final class LoginAuthorized extends LoginOutcome {
  const LoginAuthorized(this.session);

  final AuthSession session;
}

/// The user must complete two-factor authentication first.
final class LoginTwoFactorRequired extends LoginOutcome {
  const LoginTwoFactorRequired();
}

/// Profile and context returned by `GET /mobile/bootstrap`.
class Bootstrap {
  const Bootstrap({
    required this.userId,
    required this.userName,
    required this.email,
    required this.roles,
    required this.tenantId,
    required this.tenantName,
    required this.currency,
    required this.locales,
    required this.workspaces,
    required this.modules,
    required this.syncEntities,
    required this.pendingApprovals,
    required this.unreadDocuments,
    required this.updateRequired,
  });

  factory Bootstrap.fromJson(Map<String, dynamic> j) {
    final Map<String, dynamic> user =
        (j['user'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final Map<String, dynamic> tenant =
        (j['tenant'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final Map<String, dynamic> badges =
        (j['badges'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final Map<String, dynamic> sync =
        (j['sync'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final Map<String, dynamic> app =
        (j['app'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    List<String> strings(Object? v) =>
        (v as List<dynamic>? ?? <dynamic>[]).map((dynamic e) => '$e').toList();
    return Bootstrap(
      userId: '${user['id']}',
      userName: '${user['name'] ?? ''}',
      email: '${user['email'] ?? ''}',
      roles: strings(user['roles']),
      tenantId: '${tenant['id']}',
      tenantName: '${tenant['name'] ?? ''}',
      currency: '${tenant['default_currency'] ?? ''}',
      locales: strings(j['locales']),
      workspaces: strings(j['workspaces']),
      modules: strings(j['modules']),
      syncEntities: strings(sync['entities']),
      pendingApprovals: (badges['pending_approvals'] as num?)?.toInt() ?? 0,
      unreadDocuments: (badges['unread_documents'] as num?)?.toInt() ?? 0,
      updateRequired: app['update_required'] == true,
    );
  }

  final String userId;
  final String userName;
  final String email;
  final List<String> roles;
  final String tenantId;
  final String tenantName;
  final String currency;
  final List<String> locales;
  final List<String> workspaces;
  final List<String> modules;
  final List<String> syncEntities;
  final int pendingApprovals;
  final int unreadDocuments;
  final bool updateRequired;

  /// RBAC gate used by routes, menus and actions.
  bool hasModule(String module) => modules.contains(module);
}
