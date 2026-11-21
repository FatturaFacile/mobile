import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Hash of the predecessor of the first entry of a chain (64 hex zeros).
final String auditGenesisHash = '0' * 64;

/// Deterministic JSON: object keys sorted recursively, no insignificant whitespace.
String canonicalJson(Object? value) => jsonEncode(_canonical(value));

Object? _canonical(Object? value) {
  if (value is Map) {
    final List<String> keys = value.keys.map((Object? k) => '$k').toList()
      ..sort();
    return <String, Object?>{
      for (final String k in keys) k: _canonical(value[k]),
    };
  }
  if (value is Iterable) {
    return value.map(_canonical).toList();
  }
  return value;
}

/// Hash primitives of the audit chain.
///
/// `payload_hash = SHA-256(canonical payload JSON)` and
/// `record_hash  = HMAC-SHA256(deviceKey, previous_hash || payload_hash || canonical metadata JSON)`.
class AuditHasher {
  const AuditHasher(this._deviceKey);

  final List<int> _deviceKey;

  String payloadHash(Map<String, Object?> payload) =>
      payloadHashOfJson(canonicalJson(payload));

  static String payloadHashOfJson(String canonicalPayload) =>
      sha256.convert(utf8.encode(canonicalPayload)).toString();

  String recordHash({
    required String previousHash,
    required String payloadHash,
    required String metadataJson,
  }) {
    final Hmac hmac = Hmac(sha256, _deviceKey);
    return hmac
        .convert(utf8.encode('$previousHash$payloadHash$metadataJson'))
        .toString();
  }
}
