import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/security/encrypted_storage.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../data/session_lock_controller.dart';
import '../domain/audit_entry.dart';
import 'security_providers.dart';

final auditQueueStatusProvider = FutureProvider.autoDispose
    .family<AuditQueueStatus, String>(
      (Ref ref, String tenantId) =>
          ref.watch(auditQueueProvider).status(tenantId),
    );

/// Encryption status, session lock settings and offline audit queue state.
class SecurityScreen extends ConsumerStatefulWidget {
  const SecurityScreen({required this.tenantId, super.key});

  final String tenantId;

  @override
  ConsumerState<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends ConsumerState<SecurityScreen> {
  String? _message;
  bool _busy = false;

  String _time(DateTime d) {
    final DateTime l = d.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${l.year}-${two(l.month)}-${two(l.day)} ${two(l.hour)}:${two(l.minute)}';
  }

  Future<void> _syncNow() async {
    setState(() => _busy = true);
    await ref.read(auditSyncAdapterProvider).sync(widget.tenantId);
    ref.invalidate(auditQueueStatusProvider(widget.tenantId));
    if (mounted) {
      setState(() => _busy = false);
    }
  }

  Future<void> _verify(AppLocalizations l) async {
    final AuditChainVerification v = await ref
        .read(auditQueueProvider)
        .verifyChain(widget.tenantId);
    if (!mounted) {
      return;
    }
    setState(
      () => _message = v.valid
          ? l.securityChainValid(v.checked)
          : l.securityChainBroken(v.brokenAtSequence ?? 0),
    );
  }

  Future<void> _setPin(AppLocalizations l) async {
    final TextEditingController controller = TextEditingController();
    final String? pin = await showDialog<String>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(l.securitySetPin),
        content: TextField(
          key: const Key('pin-field'),
          controller: controller,
          obscureText: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: l.securityPinHint),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l.piiUnmaskCancel),
          ),
          FilledButton(
            key: const Key('pin-save'),
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: Text(l.securitySetPin),
          ),
        ],
      ),
    );
    controller.dispose();
    if (pin == null) {
      return;
    }
    final bool ok = await ref.read(sessionLockProvider.notifier).setPin(pin);
    if (mounted) {
      setState(
        () => _message = ok ? l.securityPinSaved : l.securityPinTooShort,
      );
    }
  }

  String _backend(AppLocalizations l, KeyBackend b) => switch (b) {
    KeyBackend.keychain => l.securityBackendKeychain,
    KeyBackend.androidKeystore => l.securityBackendKeystore,
    KeyBackend.platformSecureStorage => l.securityBackendSecure,
  };

  String _timeoutLabel(AppLocalizations l, Duration d) => switch (d.inSeconds) {
    30 => l.securityTimeout30s,
    60 => l.securityTimeout1m,
    300 => l.securityTimeout5m,
    900 => l.securityTimeout15m,
    _ => '${d.inSeconds}s',
  };

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = ref.watch(securityStringsProvider);
    final SessionLockState lock = ref.watch(sessionLockProvider);
    final AsyncValue<EncryptionStatus> enc = ref.watch(
      encryptionStatusProvider,
    );
    final AsyncValue<AuditQueueStatus> queue = ref.watch(
      auditQueueStatusProvider(widget.tenantId),
    );
    final Duration timeout = sessionLockTimeouts.contains(lock.timeout)
        ? lock.timeout
        : defaultSessionLockTimeout;
    return Scaffold(
      appBar: AppBar(title: Text(l.securityTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _Section(l.securityEncryptionSection),
          enc.when(
            data: (EncryptionStatus s) => Column(
              children: <Widget>[
                ListTile(
                  key: const Key('encryption-db'),
                  leading: Icon(
                    s.databaseEncrypted ? Icons.lock : Icons.lock_open,
                  ),
                  title: Text(
                    s.databaseEncrypted
                        ? l.securityDbEncrypted
                        : l.securityDbNotEncrypted,
                  ),
                ),
                ListTile(
                  key: const Key('encryption-key'),
                  leading: Icon(
                    s.keyInSecureStorage ? Icons.key : Icons.key_off,
                  ),
                  title: Text(
                    s.keyInSecureStorage
                        ? l.securityKeyStored(_backend(l, s.keyBackend))
                        : l.securityKeyMissing,
                  ),
                ),
              ],
            ),
            loading: () => const LinearProgressIndicator(),
            error: (Object e, StackTrace _) =>
                ListTile(title: Text(l.securityKeyMissing)),
          ),
          _Section(l.securityLockSection),
          SwitchListTile(
            key: const Key('lock-enabled'),
            title: Text(l.securityLockEnabled),
            subtitle: lock.hasUnlockMethod
                ? null
                : Text(l.securityNoLockMethod),
            value: lock.enabled,
            onChanged: lock.hasUnlockMethod
                ? (bool v) =>
                      ref.read(sessionLockProvider.notifier).setEnabled(v)
                : null,
          ),
          ListTile(
            title: Text(l.securityLockTimeout),
            trailing: DropdownButton<Duration>(
              key: const Key('lock-timeout'),
              value: timeout,
              items: <DropdownMenuItem<Duration>>[
                for (final Duration d in sessionLockTimeouts)
                  DropdownMenuItem<Duration>(
                    value: d,
                    child: Text(_timeoutLabel(l, d)),
                  ),
              ],
              onChanged: (Duration? d) {
                if (d != null) {
                  ref.read(sessionLockProvider.notifier).setTimeout(d);
                }
              },
            ),
          ),
          ListTile(
            key: const Key('set-pin'),
            leading: const Icon(Icons.pin_outlined),
            title: Text(l.securitySetPin),
            onTap: () => _setPin(l),
          ),
          if (lock.active)
            ListTile(
              key: const Key('lock-now'),
              leading: const Icon(Icons.lock_clock),
              title: Text(l.securityLockNow),
              onTap: () => ref.read(sessionLockProvider.notifier).lock(),
            ),
          _Section(l.securityQueueSection),
          queue.when(
            data: (AuditQueueStatus s) => Column(
              children: <Widget>[
                ListTile(
                  key: const Key('queue-status'),
                  leading: Icon(
                    s.pending == 0
                        ? Icons.cloud_done_outlined
                        : Icons.cloud_upload_outlined,
                  ),
                  title: Text(
                    s.pending == 0
                        ? l.securityQueueAllSynced
                        : l.securityQueuePending(s.pending),
                  ),
                  subtitle: s.lastSyncedAt == null
                      ? null
                      : Text(l.securityQueueLastSync(_time(s.lastSyncedAt!))),
                ),
                if (s.lastError != null)
                  ListTile(
                    key: const Key('queue-error'),
                    title: Text(l.securityQueueError(s.lastError!)),
                  ),
              ],
            ),
            loading: () => const LinearProgressIndicator(),
            error: (Object e, StackTrace _) =>
                ListTile(title: Text(l.securityQueueError('$e'))),
          ),
          Wrap(
            spacing: 8,
            children: <Widget>[
              FilledButton.tonal(
                key: const Key('sync-audit'),
                onPressed: _busy ? null : _syncNow,
                child: Text(l.securitySyncNow),
              ),
              OutlinedButton(
                key: const Key('verify-chain'),
                onPressed: () => _verify(l),
                child: Text(l.securityVerifyChain),
              ),
            ],
          ),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_message!, key: const Key('security-message')),
            ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 4),
    child: Text(label, style: Theme.of(context).textTheme.titleMedium),
  );
}
