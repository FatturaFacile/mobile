import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../database/app_database.dart';

/// Locales shipped by the backend.
const List<String> supportedLanguages = <String>['it', 'en', 'de', 'fr'];

/// Loads the API translation dictionary, caches it in SQLite and serves lookups offline.
///
/// A missing key never leaks to the UI: [t] returns an empty string.
class TranslationService {
  TranslationService(this._db, this._dio);

  final AppDatabase _db;
  final Dio _dio;
  Map<String, String> _dictionary = <String, String>{};
  String _locale = 'en';

  String get locale => _locale;

  /// Switches language: tries the network first, falls back to the cached copy.
  Future<void> load(String locale, {String tenantId = ''}) async {
    _locale = supportedLanguages.contains(locale) ? locale : 'en';
    try {
      final Response<dynamic> res = await _dio.get<dynamic>(
        '/translations/$_locale',
      );
      final dynamic body = res.data;
      final dynamic raw = body is Map
          ? (body['translations'] ??
                (body['data'] is Map
                    ? (body['data'] as Map)['translations']
                    : null))
          : null;
      if (raw is Map && raw.isNotEmpty) {
        final Map<String, String> fresh = raw.map(
          (dynamic k, dynamic v) => MapEntry<String, String>('$k', '$v'),
        );
        await _persist(_locale, tenantId, fresh);
        _dictionary = fresh;
        return;
      }
    } on DioException {
      // Offline or server error: use the cached dictionary below.
    }
    _dictionary = await _cached(_locale, tenantId);
  }

  /// Translated label, with `{name}` placeholders replaced; empty when unknown.
  String t(
    String key, {
    Map<String, Object> params = const <String, Object>{},
  }) {
    String text = _dictionary[key] ?? '';
    params.forEach(
      (String k, Object v) => text = text.replaceAll('{$k}', '$v'),
    );
    return text;
  }

  Future<void> _persist(
    String locale,
    String tenantId,
    Map<String, String> dict,
  ) async {
    await _db.batch((Batch b) {
      b.deleteWhere(
        _db.translations,
        (Translations t) =>
            t.locale.equals(locale) & t.tenantId.equals(tenantId),
      );
      b.insertAll(
        _db.translations,
        dict.entries.map(
          (MapEntry<String, String> e) => TranslationsCompanion.insert(
            locale: locale,
            key: e.key,
            value: e.value,
            tenantId: Value<String>(tenantId),
          ),
        ),
      );
    });
  }

  Future<Map<String, String>> _cached(String locale, String tenantId) async {
    final List<Translation> rows =
        await (_db.select(_db.translations)..where(
              (Translations t) =>
                  t.locale.equals(locale) & t.tenantId.equals(tenantId),
            ))
            .get();
    return <String, String>{for (final Translation r in rows) r.key: r.value};
  }
}
