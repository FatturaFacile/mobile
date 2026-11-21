import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../data/session_lock_controller.dart';
import 'security_providers.dart';

/// Locks the app after the configured inactivity or background timeout.
///
/// While locked the wrapped [child] is hidden from the screen reader and from touches, and an opaque
/// unlock screen (biometrics and/or PIN) is stacked on top.
class SessionLockGate extends ConsumerStatefulWidget {
  const SessionLockGate({
    required this.child,
    required this.enforce,
    super.key,
  });

  final Widget child;

  /// `false` before sign-in: nothing to protect yet.
  final bool enforce;

  @override
  ConsumerState<SessionLockGate> createState() => _SessionLockGateState();
}

class _SessionLockGateState extends ConsumerState<SessionLockGate>
    with WidgetsBindingObserver {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future<void>.microtask(() async {
      await ref.read(sessionLockProvider.notifier).load();
      if (mounted) {
        _restartTimer();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final SessionLockController controller = ref.read(
      sessionLockProvider.notifier,
    );
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      controller.onBackgrounded();
    } else if (state == AppLifecycleState.resumed && widget.enforce) {
      controller.onResumed();
    }
  }

  void _restartTimer() {
    _timer?.cancel();
    final SessionLockState s = ref.read(sessionLockProvider);
    if (!widget.enforce || !s.active || s.locked) {
      return;
    }
    _timer = Timer(s.timeout, () {
      if (mounted && widget.enforce) {
        ref.read(sessionLockProvider.notifier).lockForInactivity();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<SessionLockState>(sessionLockProvider, (
      SessionLockState? prev,
      SessionLockState next,
    ) {
      if (prev == null ||
          prev.locked != next.locked ||
          prev.active != next.active ||
          prev.timeout != next.timeout) {
        _restartTimer();
      }
    });
    final SessionLockState state = ref.watch(sessionLockProvider);
    final bool locked = widget.enforce && state.active && state.locked;
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _restartTimer(),
      child: Stack(
        children: <Widget>[
          ExcludeSemantics(
            excluding: locked,
            child: IgnorePointer(ignoring: locked, child: widget.child),
          ),
          if (locked)
            Positioned.fill(
              child: Overlay(
                initialEntries: <OverlayEntry>[
                  OverlayEntry(builder: (BuildContext _) => const LockScreen()),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Opaque unlock screen.
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  final TextEditingController _pin = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  Future<void> _biometric(AppLocalizations l) => ref
      .read(sessionLockProvider.notifier)
      .unlockWithBiometrics(l.securityUnlockReason);

  Future<void> _submitPin(AppLocalizations l) async {
    final PinResult r = await ref
        .read(sessionLockProvider.notifier)
        .unlockWithPin(_pin.text);
    if (!mounted) {
      return;
    }
    _pin.clear();
    setState(() {
      _error = switch (r) {
        PinResult.unlocked => null,
        PinResult.wrong => l.securityWrongPin,
        PinResult.lockedOut => l.securityTooManyAttempts,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = ref.watch(securityStringsProvider);
    final SessionLockState state = ref.watch(sessionLockProvider);
    return Scaffold(
      key: const Key('session-lock-screen'),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(Icons.lock_outline, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    l.securityLockedTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 24),
                  if (state.biometricAvailable)
                    FilledButton.icon(
                      key: const Key('unlock-biometric'),
                      onPressed: () => _biometric(l),
                      icon: const Icon(Icons.fingerprint),
                      label: Text(l.securityUnlockBiometric),
                    ),
                  if (state.pinSet) ...<Widget>[
                    const SizedBox(height: 16),
                    TextField(
                      key: const Key('unlock-pin'),
                      controller: _pin,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      onSubmitted: (_) => _submitPin(l),
                      decoration: InputDecoration(
                        labelText: l.securityPinLabel,
                        errorText: _error,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      key: const Key('unlock-pin-submit'),
                      onPressed: () => _submitPin(l),
                      child: Text(l.securityUnlock),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
