import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:fattura_facile/app/app.dart';
import 'package:fattura_facile/app/providers.dart';
import 'package:fattura_facile/core/database/app_database.dart';
import 'package:fattura_facile/core/localization/translation_service.dart';
import 'package:fattura_facile/core/security/pkce.dart';
import 'package:fattura_facile/core/security/token_store.dart';
import 'package:fattura_facile/core/sync/sync_indicator.dart';
import 'package:fattura_facile/core/sync/sync_orchestrator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../core/sync_engine_test.dart' show FakeAdapter, json;

Map<String, dynamic> bootstrapBody(List<String> modules, {String tenant = 't1'}) => <String, dynamic>{
      'data': <String, dynamic>{
        'user': <String, dynamic>{'id': 'u1', 'name': 'Anna', 'email': 'a@x.it', 'roles': <String>['employee']},
        'tenant': <String, dynamic>{'id': tenant, 'name': 'Acme $tenant', 'default_currency': 'EUR'},
        'modules': modules,
        'locales': <String>['it', 'en'],
        'sync': <String, dynamic>{'entities': <String>['expenses']},
        'badges': <String, dynamic>{'pending_approvals': 0, 'unread_documents': 0},
      },
    };

/// Drift needs real async, which widget tests do not give: the sync cycle is covered in sync_orchestrator_test.
class _NoopOrchestrator extends SyncOrchestrator {
  _NoopOrchestrator(super.engine);

  @override
  Future<void> run(String tenantId, List<String> entities) async {}
}

void main() {
  late AppDatabase db;
  late FakeAdapter adapter;
  late MemoryTokenStore store;
  late List<RequestOptions> seen;

  Future<Widget> app(WidgetTester tester, {List<String> modules = const <String>['expenses', 'clock']}) async {
    db = AppDatabase(NativeDatabase.memory());
    store = MemoryTokenStore();
    seen = <RequestOptions>[];
    adapter = FakeAdapter((RequestOptions o) {
      seen.add(o);
      switch (o.path) {
        case '/mobile/auth/pkce/authorize':
          return json(200, <String, dynamic>{'data': <String, dynamic>{'code': 'c1'}});
        case '/mobile/auth/pkce/token':
          return json(201, <String, dynamic>{
            'data': <String, dynamic>{'access_token': 'tok', 'tenant_id': 't1', 'device_session_id': 'd1'},
          });
        case '/mobile/tenants':
          return json(200, <String, dynamic>{
            'data': <Map<String, dynamic>>[
              <String, dynamic>{'tenant_id': 't1', 'tenant_name': 'Acme t1'},
              <String, dynamic>{'tenant_id': 't2', 'tenant_name': 'Beta SA'},
            ],
          });
        default:
          return json(200, bootstrapBody(modules, tenant: o.headers['X-Tenant-Id']?.toString() ?? 't1'));
      }
    });
    final ProviderContainer container = ProviderContainer(overrides: <Override>[
      databaseProvider.overrideWithValue(db),
      tokenStoreProvider.overrideWithValue(store),
      connectivityProvider.overrideWith((Ref ref) => Stream<bool>.value(true)),
      syncOrchestratorProvider.overrideWith((Ref ref) => _NoopOrchestrator(ref.watch(syncEngineProvider))),
      syncUiProvider.overrideWith((Ref ref, String id) => Stream<SyncUiState>.value(const SyncUiState(SyncUiKind.synced))),
    ]);
    addTearDown(container.dispose);
    addTearDown(() => tester.runAsync(db.close));
    (container.read(dioProvider)).httpClientAdapter = adapter;
    container.read(dioProvider).options.validateStatus = (int? s) => s != null && s < 300;
    // The shipped translations arrive from the API; seed the cache exactly like a fetch would.
    final TranslationService t = container.read(translationProvider);
    final Dio dio = container.read(dioProvider);
    dio.interceptors.add(InterceptorsWrapper(onRequest: (RequestOptions o, RequestInterceptorHandler h) {
      if (o.path.startsWith('/translations/')) {
        h.resolve(Response<dynamic>(requestOptions: o, data: <String, dynamic>{
          'translations': <String, String>{
            'mobile.login.title': 'Sign in',
            'mobile.login.email': 'Email',
            'mobile.login.password': 'Password',
            'mobile.login.submit': 'Go',
            'mobile.module.expenses': 'Expenses',
            'mobile.module.clock': 'Clock',
            'mobile.sync.online': 'Synced',
            'mobile.sync.offline': 'Offline mode',
            'mobile.sync.syncing': 'Syncing {count} items',
          },
        }));
        return;
      }
      h.next(o);
    }));
    await tester.runAsync(() => t.load('en'));
    return UncontrolledProviderScope(container: container, child: const FatturaFacileApp());
  }

  testWidgets('sign-in runs PKCE, stores the token and shows RBAC-gated modules', (WidgetTester tester) async {
    await tester.pumpWidget(await app(tester, modules: <String>['expenses']));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('login-submit')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('login-email')), 'a@x.it');
    await tester.enterText(find.byKey(const Key('login-password')), 'secret');
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    final RequestOptions authorize = seen.firstWhere((RequestOptions o) => o.path == '/mobile/auth/pkce/authorize');
    final Map<String, dynamic> sent = authorize.data as Map<String, dynamic>;
    final RequestOptions token = seen.firstWhere((RequestOptions o) => o.path == '/mobile/auth/pkce/token');
    final String verifier = (token.data as Map<String, dynamic>)['code_verifier'] as String;
    expect(PkcePair.fromVerifier(verifier).challenge, sent['code_challenge']);
    expect(await store.readToken(), 'tok');
    final RequestOptions boot = seen.lastWhere((RequestOptions o) => o.path == '/mobile/bootstrap');
    expect(boot.headers['Authorization'], 'Bearer tok');
    expect(boot.headers['X-Tenant-Id'], 't1');

    expect(find.byKey(const Key('module-expenses')), findsOneWidget);
    expect(find.byKey(const Key('module-clock')), findsNothing);
    expect(find.text('Expenses'), findsOneWidget);
    expect(find.byKey(const Key('sync-indicator')), findsOneWidget);
  });

  testWidgets('restored session skips the login and sign-out clears the credentials', (WidgetTester tester) async {
    final Widget w = await app(tester);
    await store.save(token: 'old', tenantId: 't9');
    await tester.pumpWidget(w);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('login-submit')), findsNothing);
    expect(seen.last.headers['X-Tenant-Id'], 't9');

    await tester.tap(find.byKey(const Key('sign-out')));
    await tester.pumpAndSettle();
    expect(await store.readToken(), isNull);
    expect(find.byKey(const Key('login-submit')), findsOneWidget);
  });

  testWidgets('tenant switcher lists the user companies and re-scopes the session', (WidgetTester tester) async {
    final Widget w = await app(tester);
    await store.save(token: 'tok', tenantId: 't1');
    await tester.pumpWidget(w);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('switch-tenant')));
    await tester.pumpAndSettle();
    expect(find.text('Beta SA'), findsOneWidget);
    await tester.tap(find.byKey(const Key('tenant-t2')));
    await tester.pumpAndSettle();

    expect(seen.last.path, '/mobile/bootstrap');
    expect(seen.last.headers['X-Tenant-Id'], 't2');
    expect(await store.readTenantId(), 't2');
  });

  testWidgets('modules without a mobile screen say so instead of doing nothing', (WidgetTester tester) async {
    final Widget w = await app(tester, modules: <String>['leave']);
    await store.save(token: 'tok', tenantId: 't1');
    await tester.pumpWidget(w);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('module-leave')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('module-unavailable')), findsOneWidget);
  });

  test('sync indicator state: offline beats error beats syncing', () {
    expect(SyncUiState.derive(online: false, pending: 2, failed: 1).kind, SyncUiKind.offline);
    expect(SyncUiState.derive(online: true, pending: 2, failed: 1).kind, SyncUiKind.error);
    expect(SyncUiState.derive(online: true, pending: 2, failed: 0).kind, SyncUiKind.syncing);
    expect(SyncUiState.derive(online: true, pending: 0, failed: 0).kind, SyncUiKind.synced);
  });

  test('PKCE challenge is the unpadded base64url SHA-256 of the verifier', () {
    // RFC 7636 appendix B vector.
    expect(
      PkcePair.fromVerifier('dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk').challenge,
      'E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM',
    );
    expect(jsonEncode(PkcePair.generate().verifier.length >= 43), 'true');
  });
}
