import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:fattura_facile/app/providers.dart';
import 'package:fattura_facile/core/database/app_database.dart';
import 'package:fattura_facile/core/error/failure.dart';
import 'package:fattura_facile/core/network/api_client.dart';
import 'package:fattura_facile/core/security/encrypted_storage.dart';
import 'package:fattura_facile/core/security/secure_key_store.dart';
import 'package:fattura_facile/features/security/data/pii_unmask_repository.dart';
import 'package:fattura_facile/features/security/data/session_lock_controller.dart';
import 'package:fattura_facile/features/security/presentation/pii_unmask_dialog.dart';
import 'package:fattura_facile/features/security/presentation/security_providers.dart';
import 'package:fattura_facile/features/security/presentation/security_screen.dart';
import 'package:fattura_facile/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:material_ui/material_ui.dart';

import '../../core/sync_engine_test.dart' show FakeAdapter, json;
import 'session_lock_test.dart' show FakeAuthenticator;

void main() {
  final AppLocalizations en = securityStrings('en');

  group('security strings in the 5 supported locales', () {
    test('resolve regional variants and fall back to the base language', () {
      expect(
        securityStrings('it', countryCode: 'CH').securityTitle,
        'Sicurezza',
      );
      expect(
        securityStrings('de', countryCode: 'CH').securityDbEncrypted,
        'Die lokale Datenbank ist verschlüsselt',
      );
      expect(
        securityStrings('fr', countryCode: 'CH').securityTitle,
        'Sécurité',
      );
      expect(
        securityStrings('it', countryCode: 'IT').securityUnlock,
        'Sblocca',
      );
      expect(securityStrings('en').securityTitle, 'Security');
      expect(
        securityStrings('de', countryCode: 'AT').securityTitle,
        'Sicherheit',
      );
      expect(securityStrings('xx').securityTitle, 'Security');
    });

    test('every locale answers every security string', () {
      for (final Locale l in const <Locale>[
        Locale('it', 'CH'),
        Locale('de', 'CH'),
        Locale('fr', 'CH'),
        Locale('en'),
        Locale('it', 'IT'),
      ]) {
        final AppLocalizations s = lookupAppLocalizations(l);
        expect(s.piiUnmaskBody('iban'), contains('iban'), reason: '$l');
        expect(s.securityQueuePending(3), contains('3'), reason: '$l');
        expect(s.securityChainBroken(7), contains('7'), reason: '$l');
      }
    });
  });

  group('PiiUnmaskDialog', () {
    Future<void> open(
      WidgetTester tester,
      UnmaskCall call,
      void Function(String?) onResult,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) => Scaffold(
              body: TextButton(
                onPressed: () async => onResult(
                  await showPiiUnmaskDialog(
                    context,
                    strings: en,
                    field: 'iban',
                    onUnmask: call,
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    FilledButton confirm(WidgetTester tester) =>
        tester.widget<FilledButton>(find.byKey(const Key('pii-confirm')));

    testWidgets(
      'confirm stays disabled until the justification has 10 characters',
      (WidgetTester tester) async {
        final List<String> sent = <String>[];
        String? result = 'unset';
        await open(tester, (String j) async {
          sent.add(j);
          return const Right<Failure, String>('IT60X0542811101000000123456');
        }, (String? v) => result = v);

        expect(confirm(tester).onPressed, isNull);
        await tester.enterText(
          find.byKey(const Key('pii-justification')),
          'too short',
        );
        await tester.pump();
        expect(confirm(tester).onPressed, isNull);
        expect(
          find.text('The justification must have at least 10 characters.'),
          findsOneWidget,
        );

        await tester.enterText(
          find.byKey(const Key('pii-justification')),
          '   audit ticket 42   ',
        );
        await tester.pump();
        expect(confirm(tester).onPressed, isNotNull);
        await tester.tap(find.byKey(const Key('pii-confirm')));
        await tester.pumpAndSettle();

        expect(sent, <String>['audit ticket 42']);
        expect(result, 'IT60X0542811101000000123456');
      },
    );

    testWidgets(
      'cancel resolves null without calling the API; failures keep the dialog open',
      (WidgetTester tester) async {
        int calls = 0;
        String? result = 'unset';
        await open(tester, (String j) async {
          calls++;
          return const Left<Failure, String>(ForbiddenFailure(''));
        }, (String? v) => result = v);

        await tester.enterText(
          find.byKey(const Key('pii-justification')),
          'valid justification',
        );
        await tester.pump();
        await tester.tap(find.byKey(const Key('pii-confirm')));
        await tester.pumpAndSettle();
        expect(
          find.text('You are not allowed to reveal this field.'),
          findsOneWidget,
        );
        expect(find.byKey(const Key('pii-unmask-dialog')), findsOneWidget);

        await tester.tap(find.byKey(const Key('pii-cancel')));
        await tester.pumpAndSettle();
        expect(result, isNull);
        expect(calls, 1);
      },
    );
  });

  group('HttpPiiUnmaskRepository', () {
    test('posts the contract body and rejects short justifications before the network', () async {
      final FakeAdapter adapter = FakeAdapter(
        (RequestOptions o) => json(200, <String, dynamic>{
          'data': <String, dynamic>{'value': 'secret'},
        }),
      );
      final Dio dio = Dio(BaseOptions(baseUrl: 'https://x.test/api/v1'))
        ..httpClientAdapter = adapter;
      final HttpPiiUnmaskRepository repo = HttpPiiUnmaskRepository(
        dio,
        RequestContext(),
      );

      final Either<Failure, String> short = await repo.unmask(
        entityType: 'customer',
        entityId: '9',
        field: 'iban',
        justification: 'short',
      );
      expect(short.isLeft(), isTrue);
      expect(adapter.calls, isEmpty);

      final Either<Failure, String> ok = await repo.unmask(
        entityType: 'customer',
        entityId: '9',
        field: 'iban',
        justification: 'ticket #123 review',
      );
      expect(ok.getOrElse((_) => ''), 'secret');
      expect(adapter.calls.single.method, 'POST');
      expect(adapter.calls.single.path, piiUnmaskPath);
      expect(adapter.calls.single.data, <String, Object?>{
        'entity_type': 'customer',
        'entity_id': '9',
        'field': 'iban',
        'justification': 'ticket #123 review',
      });
      expect(piiUnmaskEndpoint, '/api/v1/security/pii/unmask');
    });
  });

  group('SecurityScreen', () {
    testWidgets(
      'shows encryption, lock settings and queue status, and can change the timeout',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        late AppDatabase db;
        late MemorySecureKeyStore vault;
        late ProviderContainer container;
        await tester.runAsync(() async {
          db = AppDatabase(NativeDatabase.memory());
          vault = MemorySecureKeyStore();
          container = ProviderContainer(
            overrides: <Override>[
              databaseProvider.overrideWithValue(db),
              secureKeyStoreProvider.overrideWithValue(vault),
              deviceAuthenticatorProvider.overrideWithValue(
                FakeAuthenticator(),
              ),
              requestContextProvider.overrideWithValue(RequestContext()),
              databaseCipherProbeProvider.overrideWithValue(
                const StaticCipherProbe(),
              ),
            ],
          );
          await container.read(sessionLockProvider.notifier).load();
          await container
              .read(auditQueueProvider)
              .record(
                tenantId: 't1',
                entityType: 'invoice',
                entityId: '1',
                action: 'view',
              );
        });
        addTearDown(() async {
          container.dispose();
          await tester.runAsync(db.close);
        });

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: SecurityScreen(tenantId: 't1')),
          ),
        );
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump();

        expect(
          find.text('Local database is not encrypted yet'),
          findsOneWidget,
        );
        expect(
          find.textContaining('Encryption key is stored in'),
          findsOneWidget,
        );
        expect(find.text('1 entries waiting to sync'), findsOneWidget);
        expect(find.text('5 minutes'), findsOneWidget);

        await tester.tap(find.byKey(const Key('lock-enabled')));
        await tester.pump();
        expect(container.read(sessionLockProvider).enabled, isTrue);

        await tester.tap(find.byKey(const Key('lock-timeout')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('1 minute').last);
        await tester.pumpAndSettle();
        expect(
          container.read(sessionLockProvider).timeout,
          const Duration(minutes: 1),
        );
        expect(vault.values[SecureKeyNames.lockTimeoutSeconds], '60');

        await tester.tap(find.byKey(const Key('verify-chain')));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump();
        expect(find.text('Audit chain verified (1 entries)'), findsOneWidget);
      },
    );
  });
}
