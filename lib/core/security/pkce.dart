import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// PKCE (RFC 7636) verifier/challenge pair using the S256 method.
class PkcePair {
  const PkcePair({required this.verifier, required this.challenge});

  /// Generates a 64-character URL-safe verifier and its SHA-256 challenge.
  factory PkcePair.generate({Random? random}) {
    final Random rng = random ?? Random.secure();
    final List<int> bytes = List<int>.generate(48, (int _) => rng.nextInt(256));
    return PkcePair.fromVerifier(base64UrlEncode(bytes).replaceAll('=', ''));
  }

  factory PkcePair.fromVerifier(String verifier) {
    final String challenge = base64UrlEncode(
      sha256.convert(ascii.encode(verifier)).bytes,
    ).replaceAll('=', '');
    return PkcePair(verifier: verifier, challenge: challenge);
  }

  final String verifier;
  final String challenge;
}
