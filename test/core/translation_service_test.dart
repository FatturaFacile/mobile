import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:fattura_facile/core/database/app_database.dart';
import 'package:fattura_facile/core/localization/translation_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'sync_engine_test.dart' show FakeAdapter, json;

void main() {
  late AppDatabase db;
  late FakeAdapter adapter;
  late TranslationService service;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    adapter = FakeAdapter(
      (RequestOptions o) => json(200, <String, dynamic>{
        'locale': 'it',
        'translations': <String, String>{'hello': 'Ciao {name}'},
      }),
    );
    service = TranslationService(
      db,
      Dio(BaseOptions(baseUrl: 'http://x/api/v1'))..httpClientAdapter = adapter,
    );
  });

  tearDown(() => db.close());

  test('loads from the API and interpolates params', () async {
    await service.load('it');
    expect(
      service.t('hello', params: <String, Object>{'name': 'Anna'}),
      'Ciao Anna',
    );
  });

  test('missing keys are empty, never the raw key', () async {
    await service.load('it');
    expect(service.t('unknown.key'), '');
  });

  test('falls back to the SQLite cache when offline', () async {
    await service.load('it');
    adapter.handler = (RequestOptions o) =>
        throw DioException.connectionError(requestOptions: o, reason: 'down');
    final TranslationService offline = TranslationService(
      db,
      Dio(BaseOptions(baseUrl: 'http://x'))..httpClientAdapter = adapter,
    );
    await offline.load('it');
    expect(
      offline.t('hello', params: <String, Object>{'name': 'Bo'}),
      'Ciao Bo',
    );
    expect(jsonEncode(offline.locale), '"it"');
  });
}
