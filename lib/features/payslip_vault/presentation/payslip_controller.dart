import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../security/data/device_authenticator.dart';
import '../../security/data/session_lock_controller.dart';
import '../data/payslip_repository_impl.dart';
import '../domain/payslip_models.dart';
import '../domain/payslip_repository.dart';

final Provider<PayslipRepository> payslipRepositoryProvider =
    Provider<PayslipRepository>(
      (Ref ref) => PayslipRepositoryImpl(ref.watch(dioProvider)),
    );

/// Opens a document only after the device biometric check; the PDF stays in memory.
class PayslipOpener {
  const PayslipOpener(this._repo, this._auth);

  final PayslipRepository _repo;
  final DeviceAuthenticator _auth;

  /// Whether the device can prompt for biometrics (false: the access is audited unconfirmed).
  Future<bool> biometricAvailable() => _auth.isAvailable();

  Future<Uint8List> open(
    PayslipEntry entry,
    PayslipKind kind, {
    required String reason,
  }) async {
    final bool available = await _auth.isAvailable();
    if (available && !await _auth.authenticate(reason)) {
      throw const PayslipException(PayslipErrorKind.biometricRequired);
    }
    return _repo.open(
      entry.distributionId,
      kind,
      biometricConfirmed: available,
    );
  }
}

final Provider<PayslipOpener> payslipOpenerProvider = Provider<PayslipOpener>(
  (Ref ref) => PayslipOpener(
    ref.watch(payslipRepositoryProvider),
    ref.watch(deviceAuthenticatorProvider),
  ),
);

@immutable
class PayslipListState {
  const PayslipListState({
    this.entries = const <PayslipEntry>[],
    this.loading = false,
    this.error,
  });

  final List<PayslipEntry> entries;
  final bool loading;
  final PayslipException? error;
}

class PayslipListController extends Notifier<PayslipListState> {
  @override
  PayslipListState build() => const PayslipListState();

  Future<void> load() async {
    state = PayslipListState(entries: state.entries, loading: true);
    try {
      final List<PayslipEntry> rows = List<PayslipEntry>.of(
        await ref.read(payslipRepositoryProvider).list(),
      )..sort(_newestFirst);
      state = PayslipListState(entries: rows);
    } on PayslipException catch (e) {
      state = PayslipListState(entries: state.entries, error: e);
    }
  }

  static int _newestFirst(PayslipEntry a, PayslipEntry b) {
    final int y = b.year.compareTo(a.year);
    return y != 0 ? y : b.month.compareTo(a.month);
  }
}

final NotifierProvider<PayslipListController, PayslipListState>
payslipListProvider = NotifierProvider<PayslipListController, PayslipListState>(
  PayslipListController.new,
);
