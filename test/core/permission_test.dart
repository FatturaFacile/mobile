import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:fattura_facile/core/database/app_database.dart';
import 'package:fattura_facile/core/network/auth_problem_interceptor.dart';
import 'package:fattura_facile/core/security/permission_models.dart';
import 'package:fattura_facile/core/security/permission_repository.dart';
import 'package:fattura_facile/core/security/permission_service.dart';
import 'package:fattura_facile/core/security/permission_widgets.dart';
import 'package:fattura_facile/core/security/snapshot_cipher.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'sync_engine_test.dart' show FakeAdapter, json;

PermissionSnapshot snapshot({
  String tenant = 't1',
  String user = 'u1',
  String? company,
  List<String> permissions = const <String>[],
  List<FieldPolicy> policies = const <FieldPolicy>[],
}) {
  return PermissionSnapshot(
    tenantId: tenant,
    userId: user,
    companyId: company,
    permissions: permissions,
    fieldPolicies: policies,
    fetchedAt: DateTime.utc(2027, 1, 1),
  );
}

Map<String, dynamic> apiAnswer(
  List<String> permissions, [
  List<Map<String, dynamic>> policies = const <Map<String, dynamic>>[],
]) => <String, dynamic>{
  'success': true,
  'data': <String, dynamic>{
    'permissions': permissions,
    'field_policies': policies,
    'company_id': null,
  },
};

void main() {
  group('PermissionService', () {
    test('denies everything until a snapshot is applied, then honours exact keys and wildcards', () {
      final PermissionService service = PermissionService();
      expect(service.isGranted('crm.contacts.view'), isFalse);

      service.apply(
        snapshot(permissions: <String>['crm.contacts.view', 'ledger.*']),
      );
      expect(service.isGranted('crm.contacts.view'), isTrue);
      expect(service.isGranted('crm.contacts.delete'), isFalse);
      expect(service.isGranted('ledger.journals.post'), isTrue);
      expect(service.isGranted('hr.payroll.view'), isFalse);

      service.apply(snapshot(permissions: <String>['*']));
      expect(service.isGranted('any.thing.at_all'), isTrue);

      service.apply(null);
      expect(service.isGranted('any.thing.at_all'), isFalse);
    });

    test('the most restrictive field visibility wins and unknown fields stay visible', () {
      final PermissionService service = PermissionService()
        ..apply(
          snapshot(
            policies: const <FieldPolicy>[
              FieldPolicy(
                resource: 'hr.employee',
                field: 'salary',
                visibility: FieldVisibility.masked,
              ),
              FieldPolicy(
                resource: 'hr.employee',
                field: 'salary',
                visibility: FieldVisibility.hidden,
              ),
              FieldPolicy(
                resource: 'hr.employee',
                field: 'iban',
                visibility: FieldVisibility.masked,
                kind: 'iban',
              ),
            ],
          ),
        );

      expect(
        service.visibilityOf('hr.employee', 'salary'),
        FieldVisibility.hidden,
      );
      expect(
        service.visibilityOf('hr.employee', 'iban'),
        FieldVisibility.masked,
      );
      expect(
        service.visibilityOf('hr.employee', 'email'),
        FieldVisibility.visible,
      );
      expect(service.kindOf('hr.employee', 'iban'), 'iban');
    });
  });

  group('FieldMask', () {
    test('masks IBANs keeping country and last four, amounts as bullets, hidden as nothing', () {
      expect(
        FieldMask.iban('CH93 0076 2011 6238 5295 7'),
        'CH** **** **** **** *295 7',
      );
      expect(
        FieldMask.iban('IT60X0542811101000000123456').replaceAll(' ', ''),
        allOf(startsWith('IT'), endsWith('3456')),
      );
      expect(FieldMask.iban('x'), FieldMask.amount);

      expect(
        FieldMask.render(83250.5, FieldVisibility.masked, 'amount'),
        '•••',
      );
      expect(
        FieldMask.render(83250.5, FieldVisibility.hidden, 'amount'),
        isNull,
      );
      expect(
        FieldMask.render(
          'CH9300762011623852957',
          FieldVisibility.masked,
          'iban',
        ),
        'CH** **** **** **** *295 7',
      );
      expect(
        FieldMask.render(83250.5, FieldVisibility.masked, 'amount'),
        isNot(contains('83250')),
      );
      expect(
        FieldMask.render('plain', FieldVisibility.visible, 'amount'),
        'plain',
      );
    });
  });

  group('widgets', () {
    testWidgets(
      'PermissionGate shows its child only while the permission is held',
      (WidgetTester tester) async {
        final PermissionService service = PermissionService();
        await tester.pumpWidget(
          MaterialApp(
            home: PermissionGate(
              service: service,
              permission: 'invoicing.invoices.approve',
              child: const Text('Approve'),
            ),
          ),
        );
        expect(find.text('Approve'), findsNothing);

        service.apply(
          snapshot(permissions: <String>['invoicing.invoices.approve']),
        );
        await tester.pump();
        expect(find.text('Approve'), findsOneWidget);

        service.apply(null);
        await tester.pump();
        expect(find.text('Approve'), findsNothing);
      },
    );

    testWidgets('PermissionGate renders the fallback when denied', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PermissionGate(
            service: PermissionService(),
            permission: 'a.b.view',
            fallback: const Text('Denied'),
            child: const Text('Secret'),
          ),
        ),
      );
      expect(find.text('Denied'), findsOneWidget);
      expect(find.text('Secret'), findsNothing);
    });

    testWidgets(
      'MaskedText shows the mask with a reserved badge, nothing when hidden and the value when visible',
      (WidgetTester tester) async {
        final PermissionService service = PermissionService()
          ..apply(
            snapshot(
              policies: const <FieldPolicy>[
                FieldPolicy(
                  resource: 'hr.employee',
                  field: 'salary',
                  visibility: FieldVisibility.masked,
                ),
              ],
            ),
          );
        Widget build(String field, Object? value) => MaterialApp(
          home: Scaffold(
            body: MaskedText(
              service: service,
              resource: 'hr.employee',
              field: field,
              value: value,
              reservedLabel: 'Reserved',
            ),
          ),
        );

        await tester.pumpWidget(build('salary', 83250.5));
        expect(find.text('•••'), findsOneWidget);
        expect(find.text('Reserved'), findsOneWidget);
        expect(find.textContaining('83250'), findsNothing);

        service.apply(
          snapshot(
            policies: const <FieldPolicy>[
              FieldPolicy(
                resource: 'hr.employee',
                field: 'salary',
                visibility: FieldVisibility.hidden,
              ),
            ],
          ),
        );
        await tester.pump();
        expect(find.text('•••'), findsNothing);
        expect(find.text('Reserved'), findsNothing);

        await tester.pumpWidget(build('email', 'a@b.test'));
        expect(find.text('a@b.test'), findsOneWidget);
      },
    );
  });

  group('SnapshotCipher', () {
    test('round-trips, detects tampering and refuses another key', () async {
      final AesGcmSnapshotCipher cipher =
          await AesGcmSnapshotCipher.ephemeral();
      final String stored = await cipher.encrypt(
        '{"permissions":["secret.reports.view"]}',
      );

      expect(stored, startsWith('enc:v1:'));
      expect(stored, isNot(contains('secret.reports')));
      expect(
        await cipher.decrypt(stored),
        '{"permissions":["secret.reports.view"]}',
      );
      expect(await cipher.encrypt('same'), isNot(await cipher.encrypt('same')));

      final String tampered = '${stored.substring(0, stored.length - 6)}AAAAAA';
      await expectLater(cipher.decrypt(tampered), throwsA(anything));
      await expectLater(
        (await AesGcmSnapshotCipher.ephemeral()).decrypt(stored),
        throwsA(anything),
      );
      await expectLater(cipher.decrypt('clear text'), throwsFormatException);
    });
  });

  group('PermissionRepository', () {
    late AppDatabase db;
    late FakeAdapter adapter;
    late PermissionService service;
    late PermissionRepository repository;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      adapter = FakeAdapter(
        (RequestOptions o) =>
            json(200, apiAnswer(<String>['crm.contacts.view'])),
      );
      service = PermissionService();
      repository = PermissionRepository(
        db,
        Dio(BaseOptions(baseUrl: 'http://x/api/v1'))
          ..httpClientAdapter = adapter,
        service,
        await AesGcmSnapshotCipher.ephemeral(),
      );
    });

    tearDown(() => db.close());

    test('syncs the snapshot, applies it and stores it encrypted', () async {
      final PermissionSnapshot? synced = await repository.sync(
        tenantId: 't1',
        userId: 'u1',
      );

      expect(synced!.permissions, <String>['crm.contacts.view']);
      expect(service.isGranted('crm.contacts.view'), isTrue);
      final List<PermissionSnapshotRow> rows = await db
          .select(db.permissionSnapshots)
          .get();
      expect(rows.single.payload, startsWith('enc:v1:'));
      expect(rows.single.payload, isNot(contains('crm.contacts')));
    });

    test('isolates snapshots per tenant, user and company', () async {
      await repository.sync(tenantId: 't1', userId: 'u1');
      adapter.handler = (RequestOptions o) =>
          json(200, apiAnswer(<String>['hr.payroll.view']));
      await repository.sync(tenantId: 't1', userId: 'u1', companyId: 'c1');

      expect(
        (await repository.loadCached(
          tenantId: 't1',
          userId: 'u1',
        ))!.permissions,
        <String>['crm.contacts.view'],
      );
      expect(
        (await repository.loadCached(
          tenantId: 't1',
          userId: 'u1',
          companyId: 'c1',
        ))!.permissions,
        <String>['hr.payroll.view'],
      );
      expect(await repository.loadCached(tenantId: 't2', userId: 'u1'), isNull);
      expect(await repository.loadCached(tenantId: 't1', userId: 'u2'), isNull);
      expect(
        await repository.loadCached(
          tenantId: 't1',
          userId: 'u1',
          companyId: 'c2',
        ),
        isNull,
      );
    });

    test('works offline from the cache', () async {
      await repository.sync(tenantId: 't1', userId: 'u1');
      service.apply(null);
      adapter.handler = (RequestOptions o) =>
          throw DioException.connectionError(requestOptions: o, reason: 'down');

      final PermissionSnapshot? offline = await repository.sync(
        tenantId: 't1',
        userId: 'u1',
      );

      expect(offline!.permissions, <String>['crm.contacts.view']);
      expect(service.isGranted('crm.contacts.view'), isTrue);
    });

    test('never falls back to cached rights the server refused', () async {
      await repository.sync(tenantId: 't1', userId: 'u1');
      adapter.handler = (RequestOptions o) =>
          json(403, <String, dynamic>{'code': 'permission_denied'});
      final Dio dio = Dio(BaseOptions(baseUrl: 'http://x/api/v1'))
        ..httpClientAdapter = adapter;
      final PermissionRepository strict = PermissionRepository(
        db,
        dio,
        service,
        await AesGcmSnapshotCipher.ephemeral(),
      );

      expect(await strict.sync(tenantId: 't1', userId: 'u1'), isNull);
      expect(service.isGranted('crm.contacts.view'), isFalse);
    });

    test('a revoked user gets no cached rights back, a fresh sync restores them, purge wipes all', () async {
      await repository.sync(tenantId: 't1', userId: 'u1');
      await repository.sync(tenantId: 't1', userId: 'u2');

      await repository.revokeUser('u1');
      expect(service.isGranted('crm.contacts.view'), isFalse);
      expect(await repository.loadCached(tenantId: 't1', userId: 'u1'), isNull);
      expect(
        await repository.loadCached(tenantId: 't1', userId: 'u2'),
        isNotNull,
      );

      await repository.sync(tenantId: 't1', userId: 'u1');
      expect(
        await repository.loadCached(tenantId: 't1', userId: 'u1'),
        isNotNull,
      );

      await repository.purge();
      expect(await repository.loadCached(tenantId: 't1', userId: 'u2'), isNull);
    });
  });

  group('AuthProblemInterceptor', () {
    late List<ApiProblem> problems;
    late FakeAdapter adapter;
    late Dio dio;

    setUp(() {
      problems = <ApiProblem>[];
      adapter = FakeAdapter(
        (RequestOptions o) => json(200, <String, dynamic>{}),
      );
      dio = Dio(BaseOptions(baseUrl: 'http://x/api/v1'))
        ..httpClientAdapter = adapter
        ..interceptors.add(
          AuthProblemInterceptor(
            onProblem: (ApiProblem p) async => problems.add(p),
          ),
        );
    });

    Future<void> failWith(
      int status,
      Object body, [
      String path = '/invoices',
    ]) async {
      adapter.handler = (RequestOptions o) => json(status, body);
      await expectLater(dio.get<dynamic>(path), throwsA(isA<DioException>()));
    }

    test(
      'a 401 is a remote revocation, except on the login endpoints',
      () async {
        await failWith(401, <String, dynamic>{});
        await failWith(401, <String, dynamic>{}, '/auth/login');
        await failWith(401, <String, dynamic>{}, '/auth/passkeys/login');

        expect(problems, <ApiProblem>[ApiProblem.sessionRevoked]);
      },
    );

    test(
      'the structured 403 codes are reported, codeless 403s are not',
      () async {
        await failWith(403, <String, dynamic>{'code': 'permission_denied'});
        await failWith(403, <String, dynamic>{'code': 'mfa_required'});
        await failWith(403, <String, dynamic>{
          'code': 'company_access_revoked',
        });
        await failWith(403, <String, dynamic>{'message': 'no'});
        await failWith(500, <String, dynamic>{'code': 'permission_denied'});

        expect(problems, <ApiProblem>[
          ApiProblem.permissionDenied,
          ApiProblem.mfaRequired,
          ApiProblem.companyAccessRevoked,
        ]);
      },
    );
  });
}
