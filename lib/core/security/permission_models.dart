import 'dart:convert';

/// What a field policy does with a value for the signed-in user.
enum FieldVisibility {
  visible,
  masked,
  hidden;

  static FieldVisibility parse(String? value) => switch (value) {
    'masked' => FieldVisibility.masked,
    'hidden' => FieldVisibility.hidden,
    _ => FieldVisibility.visible,
  };
}

/// How one field of one resource is shown to the signed-in user.
class FieldPolicy {
  const FieldPolicy({
    required this.resource,
    required this.field,
    required this.visibility,
    this.kind = 'amount',
  });

  factory FieldPolicy.fromJson(Map<String, dynamic> json) => FieldPolicy(
    resource: '${json['resource']}',
    field: '${json['field']}',
    visibility: FieldVisibility.parse(json['visibility'] as String?),
    kind: (json['kind'] as String?) ?? 'amount',
  );

  final String resource;
  final String field;
  final FieldVisibility visibility;

  /// `amount` or `iban`; it decides the mask.
  final String kind;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'resource': resource,
    'field': field,
    'visibility': visibility.name,
    'kind': kind,
  };
}

/// The effective permissions and field policies of one user in one tenant and company
/// (`GET /profile/permissions`), kept locally for offline enforcement.
class PermissionSnapshot {
  const PermissionSnapshot({
    required this.tenantId,
    required this.userId,
    required this.permissions,
    required this.fieldPolicies,
    required this.fetchedAt,
    this.companyId,
  });

  /// Builds a snapshot from the `data` member of the API answer.
  factory PermissionSnapshot.fromApi(
    Map<String, dynamic> data, {
    required String tenantId,
    required String userId,
    String? companyId,
    DateTime? now,
  }) {
    return PermissionSnapshot(
      tenantId: tenantId,
      userId: userId,
      companyId: companyId,
      permissions: <String>[
        for (final dynamic p
            in (data['permissions'] as List<dynamic>? ?? <dynamic>[]))
          '$p',
      ],
      fieldPolicies: <FieldPolicy>[
        for (final dynamic p
            in (data['field_policies'] as List<dynamic>? ?? <dynamic>[]))
          FieldPolicy.fromJson(p as Map<String, dynamic>),
      ],
      fetchedAt: now ?? DateTime.now().toUtc(),
    );
  }

  /// Rebuilds a snapshot from the JSON payload kept in the local database.
  factory PermissionSnapshot.fromStored(
    String payload, {
    required String tenantId,
    required String userId,
    String? companyId,
    required DateTime fetchedAt,
  }) {
    final Object? decoded = jsonDecode(payload);
    return PermissionSnapshot.fromApi(
      decoded is Map<String, dynamic> ? decoded : <String, dynamic>{},
      tenantId: tenantId,
      userId: userId,
      companyId: companyId,
      now: fetchedAt,
    );
  }

  final String tenantId;
  final String userId;
  final String? companyId;
  final List<String> permissions;
  final List<FieldPolicy> fieldPolicies;
  final DateTime fetchedAt;

  /// The part stored at rest: permissions and field policies only, never a masked value.
  String payload() => jsonEncode(<String, dynamic>{
    'permissions': permissions,
    'field_policies': <Map<String, dynamic>>[
      for (final FieldPolicy p in fieldPolicies) p.toJson(),
    ],
  });
}
