import 'dart:io';
import 'dart:ui' show PlatformDispatcher;

import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'core/database/app_database.dart';
import 'core/localization/translation_service.dart';

/// `flutter run --dart-define=API_BASE_URL=https://host` (defaults to production).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final Directory dir = await getApplicationSupportDirectory();
  final AppDatabase db = AppDatabase(NativeDatabase.createInBackground(File(p.join(dir.path, 'fattura_facile.sqlite'))));

  final ProviderContainer container = ProviderContainer(
    overrides: <Override>[databaseProvider.overrideWithValue(db)],
  );
  final String device = PlatformDispatcher.instance.locale.languageCode;
  final String language = supportedLanguages.contains(device) ? device : 'en';
  container.read(requestContextProvider).languageCode = language;
  await container.read(translationProvider).load(language);

  runApp(UncontrolledProviderScope(container: container, child: const FatturaFacileApp()));
}
