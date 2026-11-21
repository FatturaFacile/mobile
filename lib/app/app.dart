import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:material_ui/material_ui.dart';

import '../design/ff_tokens.dart';
import '../features/copilot/presentation/copilot_controller.dart';
import '../features/copilot/presentation/copilot_sheet.dart';
import '../features/purchase_requisitions/notifications/pr_notification_payload.dart';
import '../features/purchase_requisitions/presentation/providers/pr_providers.dart';
import '../features/purchase_requisitions/presentation/screens/pr_detail_screen.dart';
import '../features/purchase_requisitions/presentation/screens/pr_hub_screen.dart';
import '../features/security/presentation/session_lock_gate.dart';
import '../l10n/ff_strings.dart';
import '../l10n/gen/app_localizations.dart';
import 'pages.dart';
import 'providers.dart';
import 'session_controller.dart';

/// Application root: Material 3 theme from the web-frontend tokens, localized delegates, session-driven home.
class FatturaFacileApp extends ConsumerStatefulWidget {
  const FatturaFacileApp({super.key});

  @override
  ConsumerState<FatturaFacileApp> createState() => _FatturaFacileAppState();
}

class _FatturaFacileAppState extends ConsumerState<FatturaFacileApp> {
  late final CopilotRouteObserver _observer = CopilotRouteObserver(
    ref.read(copilotContextTrackerProvider),
  );

  @override
  Widget build(BuildContext context) {
    final GlobalKey<NavigatorState> navKey = ref.watch(navigatorKeyProvider);
    return MaterialApp(
      title: 'Fattura Facile',
      navigatorKey: navKey,
      navigatorObservers: <NavigatorObserver>[_observer],
      theme: ffThemeData(),
      darkTheme: ffThemeData(brightness: Brightness.dark),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        FfStrings.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      onGenerateRoute: (RouteSettings settings) {
        final String? name = settings.name;
        if (name == null || name == '/') {
          return null;
        }
        final SessionState? session = ref.read(sessionProvider).value;
        if (session is! SignedIn) {
          return null;
        }
        final Uri? uri = Uri.tryParse(name);
        if (uri == null) {
          return null;
        }
        final PrNotificationPayload? payload =
            PrNotificationPayload.tryParseUri(uri);
        if (payload != null) {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => PrDetailScreen(
              tenantId: session.bootstrap.tenantId,
              requisitionId: payload.requisitionId,
              actorId: session.bootstrap.userId,
              actorName: session.bootstrap.userName,
              approvalId: payload.approvalId,
              oneClickToken: payload.oneClickToken,
              isManagerApproval: true,
              openRejectSheetOnLoad:
                  payload.action == PrNotificationAction.reject,
            ),
          );
        }
        if (uri.path == '/procurement/purchase-requisitions') {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => PrHubScreen(
              tenantId: session.bootstrap.tenantId,
              userId: session.bootstrap.userId,
              userName: session.bootstrap.userName,
              defaultCurrency: session.bootstrap.currency,
            ),
          );
        }
        return null;
      },
      home: const RootPage(),
      builder: (BuildContext context, Widget? child) => SessionLockGate(
        enforce: ref.watch(sessionProvider).value is SignedIn,
        child: Stack(
          children: <Widget>[
            child ?? const SizedBox.shrink(),
            if (ref.watch(sessionProvider).value is SignedIn)
              Positioned(
                right: FfSpace.space4,
                bottom: FfSpace.space6 * 2.5,
                child: _CopilotTrigger(
                  onPressed: () {
                    final BuildContext? navContext =
                        navKey.currentContext;
                    if (navContext != null) showCopilotSheet(navContext);
                  },
                ),
              ),
          ],
        ),
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
