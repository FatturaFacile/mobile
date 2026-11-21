import 'dart:typed_data';

import 'payslip_models.dart';

abstract interface class PayslipRepository {
  /// The employee's payslips, newest first. Throws [PayslipException].
  Future<List<PayslipEntry>> list();

  /// Downloads the decrypted PDF. The server writes the append-only access audit row (timestamp, IP, device,
  /// [biometricConfirmed]); the bytes are returned in memory only. Throws [PayslipException].
  Future<Uint8List> open(
    String distributionId,
    PayslipKind kind, {
    required bool biometricConfirmed,
  });
}
