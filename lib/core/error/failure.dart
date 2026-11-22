/// Typed failure surfaced to the UI instead of thrown exceptions.
sealed class Failure {
  const Failure(this.message);

  final String message;
}

/// No connectivity or transport error; the operation may be retried later.
final class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

/// 401: the session must be re-established.
final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure(super.message);
}

/// 403: the user lacks the RBAC permission.
final class ForbiddenFailure extends Failure {
  const ForbiddenFailure(super.message);
}

/// 422: server-side validation errors keyed by field.
final class ValidationFailure extends Failure {
  const ValidationFailure(
    super.message, {
    this.fieldErrors = const <String, List<String>>{},
  });

  final Map<String, List<String>> fieldErrors;
}

/// 409/412: the server copy changed; needs conflict handling.
final class ConflictFailure extends Failure {
  const ConflictFailure(super.message);
}

/// Anything else reported by the server (5xx, unexpected payloads).
final class ServerFailure extends Failure {
  const ServerFailure(super.message, {this.statusCode});

  final int? statusCode;
}
