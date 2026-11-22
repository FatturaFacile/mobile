import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/localization/translation_service.dart';
import '../core/network/api_client.dart';
import '../core/sync/sync_indicator.dart';
import '../core/sync/sync_orchestrator.dart';
import '../features/ai_cognitive/presentation/ai_suggestions_page.dart';
import '../features/auth/domain/auth_models.dart';
import '../features/copilot/presentation/copilot_controller.dart'
    show copilotStrings;
import '../features/entities/entity_definition.dart';
import '../features/field_service/l10n/field_service_strings.dart';
import '../features/field_service/presentation/field_service_home_page.dart';
import '../features/dss/presentation/executive_dss_page.dart';
import '../features/analytical_accounting/presentation/analytical_page.dart';
import '../features/customer_lifecycle/presentation/customer_lifecycle_page.dart';
import '../features/project_evm/presentation/project_evm_page.dart';
import '../features/project_portfolio/l10n/project_portfolio_strings.dart';
import '../features/project_portfolio/presentation/project_portfolio_page.dart';
import '../features/general_ledger/presentation/gl_pages.dart';
import '../features/general_ledger/presentation/gl_strings.dart';
import '../features/security/presentation/security_providers.dart';
import '../features/payslip_vault/presentation/payslip_pages.dart';
import '../features/gelato/presentation/gelato_page.dart';
import '../features/inventory_count/domain/inventory_count_models.dart'
    show inventoryCountModule;
import '../features/inventory_count/presentation/inventory_count_pages.dart';
import '../features/helpdesk/notifications/helpdesk_push_handler.dart';
import '../features/helpdesk/notifications/helpdesk_push_payload.dart';
import '../features/helpdesk/presentation/helpdesk_controller.dart';
import '../features/helpdesk/presentation/helpdesk_pages.dart';
import '../features/helpdesk/presentation/helpdesk_strings.dart';
import '../features/resource_planning/presentation/resource_planning_pages.dart';
import '../features/shift_planning/presentation/shift_pages.dart';
import '../features/shop_floor/presentation/shop_floor_home_page.dart';
import '../features/security/presentation/security_screen.dart';
import '../features/entities/entity_pages.dart';
import '../features/manufacturing/presentation/screens/manufacturing_hub_screen.dart';
import '../features/purchase_requisitions/notifications/pr_notification_handler.dart';
import '../features/purchase_requisitions/presentation/providers/pr_providers.dart';
import '../features/purchase_requisitions/presentation/screens/pr_hub_screen.dart';
import '../features/wms/data/wms_repository.dart';
import '../features/wms/ui/wms_app.dart' show WmsHome;
import '../features/workflow/workflow_pages.dart';
import '../l10n/gen/app_localizations.dart';
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

/// RBAC module key that unlocks the AI suggestion queue and the cognitive capture.
const String aiReviewModule = 'ai_review';

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
      'executive_dss' => const ExecutiveDssPage(),
      'project_profitability' => const ProjectEvmPage(),
      projectPortfolioModule => const ProjectPortfolioPage(),
      'analytical_accounting' => const AnalyticalAccountingPage(),
      'customer_360' => const CustomerLifecyclePage(),
      aiReviewModule => const AiSuggestionsPage(),
      shiftSelfServiceModule => const ShiftHomePage(),
      resourcePlanningModule => const ResourcePlanningHomePage(),
      gelatoModule => const GelatoHomePage(),
      generalLedgerModule => const GlHomePage(),
      _ when fieldServiceModules.contains(module) => FieldServiceHomePage(
        tenantId: b.tenantId,
        technicianId: b.userId,
      ),
      helpdeskModule => const HelpdeskQueuePage(),
      payslipVaultModule => const PayslipVaultPage(),
      inventoryCountModule => const InventoryCountListPage(),
      _ when shopFloorModules.contains(module) => ShopFloorHomePage(
        tenantId: b.tenantId,
        userId: b.userId,
      ),
      'purchase_requisitions' || 'procurement_requisitions' => PrHubScreen(
        tenantId: b.tenantId,
        userId: b.userId,
        userName: b.userName,
        defaultCurrency: b.currency,
      ),
      'manufacturing' ||
      'production_engineering' ||
      'manufacturing_routing' => ManufacturingHubScreen(tenantId: b.tenantId),
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
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: RouteSettings(name: '/modules/$module'),
        builder: (_) => page,
      ),
    );
  }

  /// Label from the API dictionary; the AI and purchase requisition modules fall back to bundled strings
  /// until the backend ships them.
  String _moduleLabel(
    BuildContext context,
    WidgetRef ref,
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
    if (shopFloorModules.contains(module)) {
      return AppLocalizations.of(context).mfgTitle;
    }
    if (module == generalLedgerModule) {
      return GlStrings(ref.read(requestContextProvider).languageCode)(GL.title);
    }
    if (fieldServiceModules.contains(module)) {
      final List<String> tag = ref
          .read(requestContextProvider)
          .languageCode
          .split(RegExp('[-_]'));
      return FieldServiceStrings.forLocale(
        Locale(tag.first, tag.length > 1 ? tag[1] : null),
      ).t(FsmText.moduleTitle);
    }
    if (module == projectPortfolioModule) {
      return ProjectPortfolioStrings.forLanguage(
        ref.read(requestContextProvider).languageCode,
      ).t(PP.title);
    }
    if (module == helpdeskModule) {
      return HelpdeskStrings(ref.read(requestContextProvider).languageCode)(
        HL.title,
      );
    }
    if (module == aiReviewModule) {
      return copilotStrings(ref.read(requestContextProvider).languageCode)
          .cogModule;
    }
    if (module == 'manufacturing' ||
        module == 'production_engineering' ||
        module == 'manufacturing_routing') {
      return AppLocalizations.of(context).mfgModuleTitle;
    }
    return '';
  }

  Future<void> _onPushPayload(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> payload,
  ) async {
    final Bootstrap b = session.bootstrap;
    final HelpdeskPushResult helpdesk = ref
        .read(helpdeskPushHandlerProvider)
        .handle(payload, navigatorKey: ref.read(navigatorKeyProvider));
    if (helpdesk.outcome != HelpdeskPushOutcome.ignored) {
      final HelpdeskPushPayload? hp = helpdesk.payload;
      if (helpdesk.alert && hp != null && context.mounted) {
        final HelpdeskStrings hs = HelpdeskStrings(
          ref.read(requestContextProvider).languageCode,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${hs.pushTitle(hp.isSlaEvent, hp.isBreach)} ${hp.ticketNumber ?? ''}'
                  .trim(),
            ),
          ),
        );
      }
      return;
    }
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
            key: const Key('open-security'),
            tooltip: ref.watch(securityStringsProvider).securityTitle,
            icon: const Icon(Icons.shield_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => SecurityScreen(tenantId: tenantId),
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
      body: Column(
        children: <Widget>[
          if (modules.contains(aiReviewModule))
            AiAlertBanner(
              onOpen: () => _openModule(context, ref, aiReviewModule),
            ),
          Expanded(child: _modules(context, ref, t, modules)),
        ],
      ),
    );
  }

  Widget _modules(
    BuildContext context,
    WidgetRef ref,
    TranslationService t,
    List<String> modules,
  ) {
    return modules.isEmpty
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
                        _moduleLabel(context, ref, t, m),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
            ],
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
