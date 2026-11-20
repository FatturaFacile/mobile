import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:material_ui/material_ui.dart';

import '../design/ff_tokens.dart';
import 'pages.dart';

/// Application root: Material 3 theme from the web-frontend tokens, session-driven home.
class FatturaFacileApp extends StatelessWidget {
  const FatturaFacileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fattura Facile',
      theme: ffThemeData(),
      darkTheme: ffThemeData(brightness: Brightness.dark),
      home: const RootPage(),
    );
  }
}

/// Wraps [FatturaFacileApp] in the provider scope.
Widget buildApp({List<Override> overrides = const <Override>[]}) {
  return ProviderScope(overrides: overrides, child: const FatturaFacileApp());
}
