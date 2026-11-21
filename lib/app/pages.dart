import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/localization/translation_service.dart';
import '../core/network/api_client.dart';
import '../core/sync/sync_indicator.dart';
import '../core/sync/sync_orchestrator.dart';
import '../features/auth/domain/auth_models.dart';
import '../features/entities/entity_definition.dart';
import '../features/entities/entity_pages.dart';
import '../features/purchase_requisitions/notifications/pr_notification_handler.dart';
import '../features/purchase_requisitions/presentation/providers/pr_providers.dart';
import '../features/purchase_requisitions/presentation/screens/pr_hub_screen.dart';
import '../features/wms/data/wms_repository.dart';
import '../features/wms/ui/wms_app.dart' show WmsHome;
import '../features/workflow/workflow_pages.dart';
import '../l10n/app_localizations.dart';
import 'providers.dart';
import 'session_controller.dart';

/// Email + password sign-in (PKCE flow runs in [SessionController]).
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({
    this.deviceId = 'device',
    this.platform = 'android',
    super.key,
  });

  final String deviceId;
  final String platform;

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TranslationService t = ref.watch(translationProvider);
    final AsyncValue<SessionState> session = ref.watch(sessionProvider);
    final SessionState? current = session.value;
    final bool busy = session.isLoading;
    String? message;
    if (current is SignedOut) {
      if (current.twoFactorRequired) {
        message = t.t('mobile.login.twoFactor');
      } else if (current.error != null) {
        message = current.error!.message.isNotEmpty
            ? current.error!.message
            : t.t('mobile.login.failed');
      }
    }
    return Scaffold(
      appBar: AppBar(title: Text(t.t('mobile.login.title'))),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              key: const Key('login-email'),
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: t.t('mobile.login.email')),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('login-password'),
              controller: _password,
              obscureText: true,
              decoration: InputDecoration(
                labelText: t.t('mobile.login.password'),
              ),
            ),
            if (message != null) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                message,
                key: const Key('login-error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              key: const Key('login-submit'),
              onPressed: busy
                  ? null
                  : () => ref
                        .read(sessionProvider.notifier)
                        .signIn(
                          email: _email.text.trim(),
                          password: _password.text,
                          deviceId: widget.deviceId,
                          platform: widget.platform,
                        ),
              child: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(t.t('mobile.login.submit')),
            ),
          ],
        ),
      ),
    );
  }
}

/// Module launcher gated by the RBAC modules in the bootstrap payload.
class HomePage extends ConsumerWidget {
  const HomePage({required this.session, super.key});

  final SignedIn session;

  void _openWms(BuildContext context, WidgetRef ref) {
    final RequestContext ctx = ref.read(requestContextProvider);
    final WmsRepository repo = HttpWmsRepository(
      config: ApiConfig(
        baseUrl: ref.read(appConfigProvider).apiBaseUrl,
        token: ctx.accessToken ?? '',
        tenantId: ctx.tenantId ?? '',
        locale: ctx.languageCode,
      ),
    );
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => WmsHome(repository: repo)));
  }

  void _openModule(BuildContext context, WidgetRef ref, String module) {
    final Bootstrap b = session.bootstrap;
    final Widget? page = switch (module) {
      'barcode_scanner' || 'pick_lists' => null,
      'clock' => ClockPage(tenantId: b.tenantId),
      'approvals_inbox' => ApprovalsPage(tenantId: b.tenantId),
      'purchase_requisitions' || 'procurement_requisitions' => PrHubScreen(
        tenantId: b.tenantId,
        userId: b.userId,
        userName: b.userName,
        defaultCurrency: b.currency,
      ),
      _ when moduleEntity.containsKey(module) => EntityListPage(
        def: entityDefinitions[moduleEntity[module]]!,
        tenantId: b.tenantId,
        userId: b.userId,
        syncEntities: b.syncEntities,
      ),
      _ => ModuleUnavailablePage(module: module),
    };
    if (page == null) {
      _openWms(context, ref);
      return;
    }
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  String _moduleLabel(
    BuildContext context,
    TranslationService t,
    String module,
  ) {
    final String translated = t.t('mobile.module.$module');
    if (translated.isNotEmpty) {
      return translated;
    }
    if (module == 'purchase_requisitions' ||
        module == 'procurement_requisitions') {
      return AppLocalizations.of(context).prModuleTitle;
    }
    return '';
  }

  Future<void> _onPushPayload(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> payload,
  ) async {
    final Bootstrap b = session.bootstrap;
    final PrNotificationResult result = await ref
        .read(prNotificationHandlerProvider)
        .handlePayload(
          payload,
          activeTenantId: b.tenantId,
          actorId: b.userId,
          actorName: b.userName,
          navigatorKey: ref.read(navigatorKeyProvider),
        );
    if (!context.mounted) {
      return;
    }
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String? snack = switch (result.outcome) {
      PrNotificationOutcome.approvedOnline => l10n.prApprovedConfirmation,
      PrNotificationOutcome.approvedQueuedOffline =>
        l10n.prApprovedQueuedOffline,
      PrNotificationOutcome.rejectedOnline => l10n.prRejectedConfirmation,
      PrNotificationOutcome.rejectedQueuedOffline =>
        l10n.prRejectedQueuedOffline,
      PrNotificationOutcome.failed =>
        result.message?.isNotEmpty == true
            ? result.message!
            : l10n.prGenericError,
      PrNotificationOutcome.navigatedToDetail ||
      PrNotificationOutcome.needsRejectionReason ||
      PrNotificationOutcome.ignored => null,
    };
    if (snack != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(snack)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TranslationService t = ref.watch(translationProvider);
    final String tenantId = session.bootstrap.tenantId;
    final SyncUiState sync =
        ref.watch(syncUiProvider(tenantId)).value ??
        const SyncUiState(SyncUiKind.synced);
    final List<String> modules = session.bootstrap.modules;
    ref.listen<AsyncValue<Map<String, dynamic>>>(prPushEventsStreamProvider, (
      AsyncValue<Map<String, dynamic>>? _,
      AsyncValue<Map<String, dynamic>> next,
    ) {
      final Map<String, dynamic>? payload = next.value;
      if (payload != null) {
        _onPushPayload(context, ref, payload);
      }
    });
    return SyncLifecycle(
      tenantId: tenantId,
      entities: session.bootstrap.syncEntities,
      child: _scaffold(context, ref, t, tenantId, sync, modules),
    );
  }

  Widget _scaffold(
    BuildContext context,
    WidgetRef ref,
    TranslationService t,
    String tenantId,
    SyncUiState sync,
    List<String> modules,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Text(session.bootstrap.tenantName),
        actions: <Widget>[
          Center(
            child: SyncStatusIndicator(
              state: sync,
              translations: t,
              onRetry: () => ref
                  .read(syncOrchestratorProvider)
                  .run(tenantId, session.bootstrap.syncEntities),
            ),
          ),
          IconButton(
            key: const Key('open-conflicts'),
            tooltip: t.t('mobile.conflicts.title'),
            icon: const Icon(Icons.rule_folder_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ConflictsPage(
                  tenantId: tenantId,
                  syncEntities: session.bootstrap.syncEntities,
                ),
              ),
            ),
          ),
          IconButton(
            key: const Key('switch-tenant'),
            tooltip: t.t('mobile.tenant.switch'),
            icon: const Icon(Icons.swap_horiz),
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              builder: (_) => TenantSwitcher(activeTenantId: tenantId),
            ),
          ),
          IconButton(
            key: const Key('sign-out'),
            tooltip: t.t('mobile.home.signOut'),
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(sessionProvider.notifier).signOut(),
          ),
        ],
      ),
      body: modules.isEmpty
          ? Center(child: Text(t.t('mobile.home.noModules')))
          : GridView.count(
              padding: const EdgeInsets.all(16),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: <Widget>[
                for (final String m in modules)
                  Card(
                    key: Key('module-$m'),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => _openModule(context, ref, m),
                      child: Center(
                        child: Text(
                          _moduleLabel(context, t, m),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

/// Chooses login or home from the session state.
class RootPage extends ConsumerWidget {
  const RootPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(sessionProvider)
        .when(
          skipLoadingOnReload: true,
          data: (SessionState s) => switch (s) {
            SignedIn() => HomePage(session: s),
            SignedOut() => const LoginPage(),
          },
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (Object e, StackTrace _) => const LoginPage(),
        );
  }
}
