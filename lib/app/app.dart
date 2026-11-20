import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:material_ui/material_ui.dart';

import '../design/ff_tokens.dart';
import '../features/copilot/presentation/copilot_controller.dart';
import '../features/copilot/presentation/copilot_sheet.dart';
import 'pages.dart';
import 'providers.dart';
import 'session_controller.dart';

/// Application root: Material 3 theme from the web-frontend tokens, session-driven home.
class FatturaFacileApp extends ConsumerStatefulWidget {
  const FatturaFacileApp({super.key});

  @override
  ConsumerState<FatturaFacileApp> createState() => _FatturaFacileAppState();
}

class _FatturaFacileAppState extends ConsumerState<FatturaFacileApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late final CopilotRouteObserver _observer = CopilotRouteObserver(
    ref.read(copilotContextTrackerProvider),
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fattura Facile',
      navigatorKey: _navigatorKey,
      navigatorObservers: <NavigatorObserver>[_observer],
      theme: ffThemeData(),
      darkTheme: ffThemeData(brightness: Brightness.dark),
      home: const RootPage(),
      builder: (BuildContext context, Widget? child) => Stack(
        children: <Widget>[
          child ?? const SizedBox.shrink(),
          if (ref.watch(sessionProvider).value is SignedIn)
            Positioned(
              right: FfSpace.space4,
              bottom: FfSpace.space6 * 2.5,
              child: _CopilotTrigger(
                onPressed: () {
                  final BuildContext? navContext = _navigatorKey.currentContext;
                  if (navContext != null) showCopilotSheet(navContext);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _CopilotTrigger extends ConsumerWidget {
  const _CopilotTrigger({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String label = copilotStrings(
      ref.read(requestContextProvider).languageCode,
    ).copilotTooltip;
    return Semantics(
      label: label,
      button: true,
      child: FloatingActionButton(
        key: const Key('copilot-trigger'),
        heroTag: 'copilot-trigger',
        onPressed: onPressed,
        child: const Icon(Icons.auto_awesome),
      ),
    );
  }
}

/// Wraps [FatturaFacileApp] in the provider scope.
Widget buildApp({List<Override> overrides = const <Override>[]}) {
  return ProviderScope(overrides: overrides, child: const FatturaFacileApp());
}
