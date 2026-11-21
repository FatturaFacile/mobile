import 'package:flutter/foundation.dart';

import 'permission_models.dart';

/// Holds the permission snapshot in force and answers authorization questions from it. Deny by default: without a
/// snapshot nothing is granted and every field with a policy stays protected. Widgets listen to it.
class PermissionService extends ChangeNotifier {
  PermissionSnapshot? _snapshot;

  PermissionSnapshot? get snapshot => _snapshot;

  /// Replaces the snapshot in force; `null` denies everything (sign-out, revocation).
  void apply(PermissionSnapshot? snapshot) {
    _snapshot = snapshot;
    notifyListeners();
  }

  /// `*` and `module.*` grant, as on the server.
  bool isGranted(String permission) {
    final PermissionSnapshot? s = _snapshot;
    if (s == null) {
      return false;
    }
    if (s.permissions.contains('*') || s.permissions.contains(permission)) {
      return true;
    }
    final int dot = permission.indexOf('.');
    return dot > 0 &&
        s.permissions.contains('${permission.substring(0, dot)}.*');
  }

  /// The most restrictive visibility the policies give a field; visible when none mentions it.
  FieldVisibility visibilityOf(String resource, String field) {
    FieldVisibility result = FieldVisibility.visible;
    for (final FieldPolicy p
        in _snapshot?.fieldPolicies ?? const <FieldPolicy>[]) {
      if (p.resource == resource &&
          p.field == field &&
          p.visibility.index > result.index) {
        result = p.visibility;
      }
    }
    return result;
  }

  /// The kind (`amount` or `iban`) of the policy of a field, which decides its mask.
  String kindOf(String resource, String field) {
    for (final FieldPolicy p
        in _snapshot?.fieldPolicies ?? const <FieldPolicy>[]) {
      if (p.resource == resource && p.field == field) {
        return p.kind;
      }
    }
    return 'amount';
  }
}

/// Masks of protected values: amounts as `•••`, IBANs keeping the country and the last four characters.
abstract final class FieldMask {
  static const String amount = '•••';

  /// `CH93 0076 2011 6238 5295 7` becomes `CH** **** **** **** *295 7`.
  static String iban(Object? value) {
    final String compact = '$value'
        .replaceAll(RegExp(r'\s+'), '')
        .toUpperCase();
    if (compact.length < 8 || !RegExp(r'^[A-Z]{2}').hasMatch(compact)) {
      return amount;
    }
    final String masked =
        compact.substring(0, 2) +
        '*' * (compact.length - 6) +
        compact.substring(compact.length - 4);
    final StringBuffer out = StringBuffer();
    for (int i = 0; i < masked.length; i++) {
      if (i > 0 && i % 4 == 0) {
        out.write(' ');
      }
      out.write(masked[i]);
    }
    return out.toString();
  }

  /// The text to show for [value], or `null` for a hidden field.
  static String? render(
    Object? value,
    FieldVisibility visibility,
    String kind,
  ) => switch (visibility) {
    FieldVisibility.hidden => null,
    FieldVisibility.masked => kind == 'iban' ? iban(value) : amount,
    FieldVisibility.visible => value == null ? '' : '$value',
  };
}
