import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fattura_facile/design/ff_tokens.dart';
import 'package:fattura_facile/features/payslip_vault/data/payslip_repository_impl.dart';
import 'package:fattura_facile/features/payslip_vault/domain/payslip_models.dart';
import 'package:fattura_facile/features/payslip_vault/domain/payslip_repository.dart';
import 'package:fattura_facile/features/payslip_vault/presentation/payslip_controller.dart';
import 'package:fattura_facile/features/payslip_vault/presentation/payslip_pages.dart';
import 'package:fattura_facile/features/payslip_vault/presentation/payslip_strings.dart';
import 'package:fattura_facile/features/security/data/device_authenticator.dart';
import 'package:fattura_facile/features/security/data/session_lock_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.handler);

  final ResponseBody Function(RequestOptions o) handler;
  final List<RequestOptions> calls = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object body, [int status = 200]) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: <String, List<String>>{
    Headers.contentTypeHeader: <String>['application/json'],
  },
);

class _FakeRepo implements PayslipRepository {
  List<PayslipEntry> rows = <PayslipEntry>[];
  final List<bool> opened = <bool>[];
  PayslipException? listError;

  @override
  Future<List<PayslipEntry>> list() async {
    if (listError != null) {
      throw listError!;
    }
    return rows;
  }

  @override
  Future<Uint8List> open(
    String distributionId,
    PayslipKind kind, {
    required bool biometricConfirmed,
  }) async {
    opened.add(biometricConfirmed);
    return Uint8List.fromList(<int>[1, 2, 3]);
  }
}

class _FakeAuth implements DeviceAuthenticator {
  _FakeAuth({this.available = true, this.ok = true});

  final bool available;
  final bool ok;
  int prompts = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<bool> authenticate(String reason) async {
    prompts++;
    return ok;
  }
}

PayslipEntry _entry(String id, int y, int m, {DateTime? viewed}) =>
    PayslipEntry(
      distributionId: id,
      year: y,
      month: m,
      netAmount: 1234.5,
      hasCedolino: true,
      hasCu: m == 12,
      firstViewedAt: viewed,
    );

void main() {
  group('models', () {
    test('fromJson parses the API row', () {
      final PayslipEntry e = PayslipEntry.fromJson(const <String, dynamic>{
        'distribution_id': 7,
        'year': 2026,
        'month': '3',
        'net_amount': '1500.25',
        'has_cedolino': true,
        'has_cu': false,
        'first_viewed_at': '2026-04-01T10:00:00Z',
      });
      expect(e.distributionId, '7');
      expect(e.month, 3);
      expect(e.netAmount, 1500.25);
      expect(e.hasCu, isFalse);
      expect(e.viewed, isTrue);
      expect(e.firstViewedAt, DateTime.utc(2026, 4, 1, 10));
    });

    test('missing optionals stay null', () {
      final PayslipEntry e = PayslipEntry.fromJson(const <String, dynamic>{
        'distribution_id': 'a',
        'year': 2025,
        'month': 1,
        'has_cedolino': true,
        'has_cu': true,
      });
      expect(e.netAmount, isNull);
      expect(e.viewed, isFalse);
    });
  });

  group('repository', () {
    test('list unwraps data and open posts kind + biometric flag', () async {
      final Dio dio = Dio();
      final _Adapter a = _Adapter((RequestOptions o) {
        if (o.method == 'GET') {
          return _json(<String, dynamic>{
            'data': <Map<String, dynamic>>[
              <String, dynamic>{
                'distribution_id': 1,
                'year': 2026,
                'month': 2,
                'has_cedolino': true,
                'has_cu': false,
              },
            ],
          });
        }
        return ResponseBody.fromBytes(
          <int>[37, 80, 68, 70],
          200,
          headers: <String, List<String>>{
            Headers.contentTypeHeader: <String>['application/pdf'],
          },
        );
      });
      dio.httpClientAdapter = a;
      final PayslipRepositoryImpl repo = PayslipRepositoryImpl(dio);

      expect((await repo.list()).single.distributionId, '1');
      final Uint8List pdf = await repo.open(
        '1',
        PayslipKind.cu,
        biometricConfirmed: true,
      );
      expect(pdf, <int>[37, 80, 68, 70]);
      final RequestOptions post = a.calls.last;
      expect(post.path, '/italian-payroll/my-payslips/1/open');
      expect(post.data, <String, dynamic>{
        'document_kind': 'cu',
        'biometric_confirmed': true,
      });
    });

    test('HTTP statuses map to error kinds', () async {
      Future<PayslipErrorKind> kindFor(int status) async {
        final Dio dio = Dio()
          ..httpClientAdapter = _Adapter(
            (_) => _json(<String, String>{}, status),
          );
        try {
          await PayslipRepositoryImpl(dio).list();
        } on PayslipException catch (e) {
          return e.kind;
        }
        throw StateError('no error');
      }

      expect(await kindFor(401), PayslipErrorKind.unauthorized);
      expect(await kindFor(403), PayslipErrorKind.forbidden);
      expect(await kindFor(404), PayslipErrorKind.notFound);
      expect(await kindFor(500), PayslipErrorKind.unknown);
    });
  });

  group('opener', () {
    final PayslipEntry entry = _entry('1', 2026, 1);

    test('refused biometrics: no download', () async {
      final _FakeRepo repo = _FakeRepo();
      final _FakeAuth auth = _FakeAuth(ok: false);
      await expectLater(
        PayslipOpener(
          repo,
          auth,
        ).open(entry, PayslipKind.cedolino, reason: 'r'),
        throwsA(
          isA<PayslipException>().having(
            (PayslipException e) => e.kind,
            'kind',
            PayslipErrorKind.biometricRequired,
          ),
        ),
      );
      expect(auth.prompts, 1);
      expect(repo.opened, isEmpty);
    });

    test('unavailable biometrics: downloads with confirmed=false', () async {
      final _FakeRepo repo = _FakeRepo();
      final _FakeAuth auth = _FakeAuth(available: false);
      await PayslipOpener(repo, auth).open(entry, PayslipKind.cu, reason: 'r');
      expect(auth.prompts, 0);
      expect(repo.opened, <bool>[false]);
    });

    test('success: downloads with confirmed=true', () async {
      final _FakeRepo repo = _FakeRepo();
      await PayslipOpener(
        repo,
        _FakeAuth(),
      ).open(entry, PayslipKind.cedolino, reason: 'r');
      expect(repo.opened, <bool>[true]);
    });
  });

  test('every locale defines every label', () {
    for (final MapEntry<String, Map<PV, String>> t
        in payslipLocaleTables.entries) {
      for (final PV k in PV.values) {
        expect(t.value[k], isNotNull, reason: '${t.key} misses $k');
        expect(t.value[k], isNotEmpty, reason: '${t.key} empty $k');
      }
    }
    expect(
      payslipLocaleTables.keys,
      containsAll(<String>['it', 'en', 'de', 'fr']),
    );
    expect(const PayslipStrings('xx')(PV.title), 'Confidential vault');
  });

  group('page', () {
    late _FakeRepo repo;
    late _FakeAuth auth;

    setUp(() {
      repo = _FakeRepo()
        ..rows = <PayslipEntry>[
          _entry('a', 2025, 11),
          _entry('b', 2025, 12, viewed: DateTime.utc(2026, 1, 5, 12)),
        ];
      auth = _FakeAuth();
    });

    Widget host() => ProviderScope(
      overrides: [
        payslipRepositoryProvider.overrideWithValue(repo),
        deviceAuthenticatorProvider.overrideWithValue(auth),
        payslipViewerBuilderProvider.overrideWithValue(
          (Uint8List bytes, String title) =>
              Scaffold(body: Text('viewer ${bytes.length} $title')),
        ),
      ],
      child: MaterialApp(theme: ffThemeData(), home: const PayslipVaultPage()),
    );

    testWidgets('lists cedolini newest first, CU, net and viewed state', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      expect(find.text('Monthly payslips'), findsOneWidget);
      expect(find.text('Annual CU'), findsOneWidget);
      expect(find.byKey(const Key('payslip-cedolino-b')), findsOneWidget);
      expect(find.byKey(const Key('payslip-cu-b')), findsOneWidget);
      expect(find.byKey(const Key('payslip-cu-a')), findsNothing);
      expect(
        tester.getTopLeft(find.byKey(const Key('payslip-cedolino-b'))).dy,
        lessThan(
          tester.getTopLeft(find.byKey(const Key('payslip-cedolino-a'))).dy,
        ),
      );
      expect(find.textContaining('1234.50'), findsWidgets);
      expect(find.textContaining('Never opened'), findsWidgets);
      expect(find.textContaining('First opened'), findsWidgets);
      expect(find.byKey(const Key('payslip-audit-notice')), findsOneWidget);
      expect(find.byKey(const Key('payslip-no-biometric')), findsNothing);
    });

    testWidgets('opening prompts biometrics then shows the viewer', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('payslip-open-cedolino-a')));
      await tester.pumpAndSettle();

      expect(auth.prompts, 1);
      expect(repo.opened, <bool>[true]);
      expect(find.text('viewer 3 Payslip 2025-11'), findsOneWidget);
    });

    testWidgets('refused biometrics shows the error and downloads nothing', (
      WidgetTester tester,
    ) async {
      auth = _FakeAuth(ok: false);
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('payslip-open-cedolino-a')));
      await tester.pumpAndSettle();

      expect(repo.opened, isEmpty);
      expect(find.byKey(const Key('payslip-error')), findsOneWidget);
      expect(
        find.text('Identity not confirmed. The document was not opened.'),
        findsOneWidget,
      );
    });

    testWidgets('no biometrics shows the notice', (WidgetTester tester) async {
      auth = _FakeAuth(available: false);
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('payslip-no-biometric')), findsOneWidget);
    });

    testWidgets('empty and error states, retry recovers', (
      WidgetTester tester,
    ) async {
      repo
        ..rows = <PayslipEntry>[]
        ..listError = const PayslipException(PayslipErrorKind.offline);
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();
      expect(
        find.text('No connection. Documents are never stored on the device.'),
        findsOneWidget,
      );

      repo.listError = null;
      await tester.tap(find.byKey(const Key('payslip-retry')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('payslip-empty')), findsOneWidget);
      expect(find.byKey(const Key('payslip-error')), findsNothing);
    });
  });
}
