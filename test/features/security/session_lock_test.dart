import 'package:fattura_facile/app/providers.dart';
import 'package:fattura_facile/core/network/api_client.dart';
import 'package:fattura_facile/core/security/secure_key_store.dart';
import 'package:fattura_facile/features/security/data/device_authenticator.dart';
import 'package:fattura_facile/features/security/data/session_lock_controller.dart';
import 'package:fattura_facile/features/security/presentation/session_lock_gate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class FakeAuthenticator implements DeviceAuthenticator {
  FakeAuthenticator({this.available = true, this.succeeds = true});

  bool available;
  bool succeeds;
  int prompts = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<bool> authenticate(String reason) async {
    prompts++;
    return succeeds;
  }
}

ProviderContainer containerWith(
  MemorySecureKeyStore vault,
  FakeAuthenticator auth, {
  DateTime Function()? clock,
}) {
  final ProviderContainer c = ProviderContainer(
    overrides: <Override>[
      secureKeyStoreProvider.overrideWithValue(vault),
      deviceAuthenticatorProvider.overrideWithValue(auth),
      if (clock != null) securityClockProvider.overrideWithValue(clock),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('SessionLockController', () {
    test(
      'defaults: disabled, no unlock method means it cannot be enabled',
      () async {
        final ProviderContainer c = containerWith(
          MemorySecureKeyStore(),
          FakeAuthenticator(available: false),
        );
        final SessionLockController ctl = c.read(sessionLockProvider.notifier);
        await ctl.load();
        await ctl.setEnabled(true);
        expect(c.read(sessionLockProvider).enabled, isFalse);
        expect(c.read(sessionLockProvider).active, isFalse);
      },
    );

    test(
      'PIN is validated, stored hashed, and settings persist across a reload',
      () async {
        final MemorySecureKeyStore vault = MemorySecureKeyStore();
        ProviderContainer c = containerWith(
          vault,
          FakeAuthenticator(available: false),
        );
        SessionLockController ctl = c.read(sessionLockProvider.notifier);
        await ctl.load();
        expect(await ctl.setPin('12'), isFalse);
        expect(await ctl.setPin('12ab'), isFalse);
        expect(await ctl.setPin('2468'), isTrue);
        expect(vault.values[SecureKeyNames.pinHash], isNot(contains('2468')));
        await ctl.setEnabled(true);
        await ctl.setTimeout(const Duration(minutes: 1));

        c = containerWith(vault, FakeAuthenticator(available: false));
        ctl = c.read(sessionLockProvider.notifier);
        await ctl.load();
        final SessionLockState s = c.read(sessionLockProvider);
        expect(s.enabled, isTrue);
        expect(s.timeout, const Duration(minutes: 1));
        expect(s.pinSet, isTrue);
        expect(
          s.locked,
          isTrue,
          reason: 'a restarted app with the lock on starts locked',
        );
      },
    );

    test('unlock with the right PIN, reject the wrong one, then lock out after repeated failures', () async {
      DateTime now = DateTime(2026);
      final ProviderContainer c = containerWith(
        MemorySecureKeyStore(),
        FakeAuthenticator(available: false),
        clock: () => now,
      );
      final SessionLockController ctl = c.read(sessionLockProvider.notifier);
      await ctl.load();
      await ctl.setPin('2468');
      await ctl.setEnabled(true);
      ctl.lock();
      expect(c.read(sessionLockProvider).locked, isTrue);

      for (int i = 0; i < maxPinAttempts - 1; i++) {
        expect(await ctl.unlockWithPin('0000'), PinResult.wrong);
      }
      expect(await ctl.unlockWithPin('0000'), PinResult.lockedOut);
      expect(
        await ctl.unlockWithPin('2468'),
        PinResult.lockedOut,
        reason: 'even the right PIN waits out the lockout',
      );
      now = now.add(pinLockout + const Duration(seconds: 1));
      expect(await ctl.unlockWithPin('2468'), PinResult.unlocked);
      expect(c.read(sessionLockProvider).locked, isFalse);
    });

    test('biometric unlock follows the OS result', () async {
      final FakeAuthenticator auth = FakeAuthenticator(succeeds: false);
      final ProviderContainer c = containerWith(MemorySecureKeyStore(), auth);
      final SessionLockController ctl = c.read(sessionLockProvider.notifier);
      await ctl.load();
      await ctl.setEnabled(true);
      ctl.lock();
      expect(await ctl.unlockWithBiometrics('why'), isFalse);
      expect(c.read(sessionLockProvider).locked, isTrue);
      auth.succeeds = true;
      expect(await ctl.unlockWithBiometrics('why'), isTrue);
      expect(c.read(sessionLockProvider).locked, isFalse);
    });

    test('resume after a background longer than the timeout locks, a short one does not', () async {
      DateTime now = DateTime(2026);
      final ProviderContainer c = containerWith(
        MemorySecureKeyStore(),
        FakeAuthenticator(),
        clock: () => now,
      );
      final SessionLockController ctl = c.read(sessionLockProvider.notifier);
      await ctl.load();
      await ctl.setEnabled(true);
      await ctl.setTimeout(const Duration(seconds: 30));
      ctl.lock();
      await ctl.unlockWithBiometrics('r');

      ctl.onBackgrounded();
      now = now.add(const Duration(seconds: 10));
      ctl.onResumed();
      expect(c.read(sessionLockProvider).locked, isFalse);

      ctl.onBackgrounded();
      now = now.add(const Duration(seconds: 31));
      ctl.onResumed();
      expect(c.read(sessionLockProvider).locked, isTrue);
    });
  });

  group('SessionLockGate', () {
    Future<ProviderContainer> pump(
      WidgetTester tester,
      MemorySecureKeyStore vault, {
      bool enforce = true,
    }) async {
      final ProviderContainer c = ProviderContainer(
        overrides: <Override>[
          secureKeyStoreProvider.overrideWithValue(vault),
          deviceAuthenticatorProvider.overrideWithValue(
            FakeAuthenticator(available: false),
          ),
          requestContextProvider.overrideWithValue(RequestContext()),
        ],
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(
            home: SessionLockGate(
              enforce: enforce,
              child: const Scaffold(body: Text('secret content')),
            ),
          ),
        ),
      );
      await tester.pump();
      return c;
    }

    Future<MemorySecureKeyStore> vaultWithPin({int timeoutSeconds = 30}) async {
      final MemorySecureKeyStore vault = MemorySecureKeyStore();
      final ProviderContainer c = containerWith(
        vault,
        FakeAuthenticator(available: false),
      );
      final SessionLockController ctl = c.read(sessionLockProvider.notifier);
      await ctl.load();
      await ctl.setPin('2468');
      await ctl.setEnabled(true);
      await ctl.setTimeout(Duration(seconds: timeoutSeconds));
      return vault;
    }

    testWidgets(
      'starts locked when enabled, and a correct PIN reveals the content',
      (WidgetTester tester) async {
        final MemorySecureKeyStore vault =
            await tester.runAsync(vaultWithPin) as MemorySecureKeyStore;
        await pump(tester, vault);
        await tester.pump();

        expect(find.byKey(const Key('session-lock-screen')), findsOneWidget);
        await tester.enterText(find.byKey(const Key('unlock-pin')), '0000');
        await tester.tap(find.byKey(const Key('unlock-pin-submit')));
        await tester.pump();
        await tester.pump();
        expect(find.text('Wrong PIN'), findsOneWidget);

        await tester.enterText(find.byKey(const Key('unlock-pin')), '2468');
        await tester.tap(find.byKey(const Key('unlock-pin-submit')));
        await tester.pump();
        await tester.pump();
        expect(find.byKey(const Key('session-lock-screen')), findsNothing);
        expect(find.text('secret content'), findsOneWidget);
      },
    );

    testWidgets(
      'locks after the inactivity timeout and a touch restarts the countdown',
      (WidgetTester tester) async {
        final MemorySecureKeyStore vault =
            await tester.runAsync(vaultWithPin) as MemorySecureKeyStore;
        final ProviderContainer c = await pump(tester, vault);
        c.read(sessionLockProvider.notifier).lockForInactivity();
        await tester.pump();
        await tester.enterText(find.byKey(const Key('unlock-pin')), '2468');
        await tester.tap(find.byKey(const Key('unlock-pin-submit')));
        await tester.pump();
        await tester.pump();
        expect(find.byKey(const Key('session-lock-screen')), findsNothing);

        await tester.pump(const Duration(seconds: 20));
        await tester.tapAt(const Offset(5, 5));
        await tester.pump(const Duration(seconds: 20));
        expect(
          find.byKey(const Key('session-lock-screen')),
          findsNothing,
          reason: 'the touch restarted the 30 s timer',
        );

        await tester.pump(const Duration(seconds: 11));
        expect(find.byKey(const Key('session-lock-screen')), findsOneWidget);
      },
    );

    testWidgets('does not lock before sign-in', (WidgetTester tester) async {
      final MemorySecureKeyStore vault =
          await tester.runAsync(vaultWithPin) as MemorySecureKeyStore;
      await pump(tester, vault, enforce: false);
      await tester.pump();
      expect(find.byKey(const Key('session-lock-screen')), findsNothing);
      expect(find.text('secret content'), findsOneWidget);
    });
  });
}
