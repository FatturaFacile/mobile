import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/providers.dart';
import '../../../design/ff_tokens.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../domain/copilot_models.dart';
import 'action_card.dart';
import 'compact_markdown.dart';
import 'copilot_controller.dart';
import 'copilot_navigation.dart';
import 'visualization_view.dart';

/// Opens the Copilot as a responsive modal bottom sheet (full width on phones, centred panel on tablets).
Future<void> showCopilotSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    constraints: BoxConstraints(
      maxWidth: MediaQuery.sizeOf(context).width >= 720 ? 640 : double.infinity,
    ),
    builder: (BuildContext ctx) =>
        const FractionallySizedBox(heightFactor: 0.92, child: CopilotPanel()),
  );
}

class CopilotPanel extends ConsumerStatefulWidget {
  const CopilotPanel({super.key});

  @override
  ConsumerState<CopilotPanel> createState() => _CopilotPanelState();
}

class _CopilotPanelState extends ConsumerState<CopilotPanel> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _showHistory = false;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(copilotControllerProvider.notifier).open(),
    );
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final String text = _input.text;
    if (text.trim().isEmpty) {
      return;
    }
    _input.clear();
    ref.read(copilotControllerProvider.notifier).send(text);
  }

  Future<void> _openCitation(AppLocalizations l, Citation c) async {
    if (!c.isEntity) {
      await showDialog<void>(
        context: context,
        builder: (BuildContext ctx) => AlertDialog(
          title: Text(c.title ?? c.label),
          content: Text(
            <String?>[
              c.label,
              c.sectionRef,
              c.jurisdiction,
            ].whereType<String>().where((String s) => s.isNotEmpty).join('\n'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l.copilotClose),
            ),
          ],
        ),
      );
      return;
    }
    final Widget? page = await resolveCitationPage(ref, c);
    if (!mounted) {
      return;
    }
    if (page == null) {
      ScaffoldMessenger.maybeOf(context)
          ?.showSnackBar(SnackBar(content: Text(l.copilotRouteUnavailable)));
      return;
    }
    final NavigatorState nav = Navigator.of(context);
    nav.pop(); // close the sheet, then show the record underneath
    nav.push(
      MaterialPageRoute<void>(
        settings: RouteSettings(
          name: c.route ?? '/${c.entityType}',
          arguments: CopilotContext(
            route: c.route,
            entityType: c.entityType,
            entityId: c.entityId,
          ),
        ),
        builder: (_) => page,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final CopilotState s = ref.watch(copilotControllerProvider);
    final CopilotController ctrl = ref.read(copilotControllerProvider.notifier);
    final AppLocalizations l = copilotStrings(
      ref.read(requestContextProvider).languageCode,
    );
    ref.listen<CopilotState>(copilotControllerProvider, (
      CopilotState? a,
      CopilotState b,
    ) {
      if (_scroll.hasClients &&
          (a?.messages.length != b.messages.length ||
              (b.messages.isNotEmpty &&
                  a?.messages.lastOrNull?.content !=
                      b.messages.last.content))) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scroll.hasClients) {
            _scroll.jumpTo(_scroll.position.maxScrollExtent);
          }
        });
      }
    });
    final FfColors c =
        Theme.of(context).extension<FfColors>() ?? FfColors.light;
    return Column(
      key: const Key('copilot-panel'),
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: FfSpace.space4),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  l.copilotTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                key: const Key('copilot-history'),
                tooltip: l.copilotHistory,
                icon: const Icon(Icons.history),
                onPressed: () => setState(() => _showHistory = !_showHistory),
              ),
              IconButton(
                key: const Key('copilot-new'),
                tooltip: l.copilotNewChat,
                icon: const Icon(Icons.add_comment_outlined),
                onPressed: () {
                  ctrl.newChat();
                  setState(() => _showHistory = false);
                },
              ),
            ],
          ),
        ),
        if (s.offline)
          Container(
            key: const Key('copilot-offline'),
            width: double.infinity,
            color: c.warningBg,
            padding: const EdgeInsets.all(FfSpace.space2),
            child: Text(
              l.copilotOfflineBanner,
              style: TextStyle(color: c.warning, fontSize: FfFont.sm),
            ),
          ),
        if (s.error != null)
          MaterialBanner(
            key: const Key('copilot-error'),
            content: Text(copilotErrorText(l, s.error!)),
            actions: <Widget>[
              TextButton(
                onPressed: ctrl.clearError,
                child: Text(l.copilotClose),
              ),
            ],
          ),
        Expanded(
          child: _showHistory ? _history(s, ctrl, l) : _messages(s, ctrl, l),
        ),
        const Divider(height: 1),
        SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              FfSpace.space3,
              FfSpace.space2,
              FfSpace.space3,
              FfSpace.space2 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Expanded(
                  child: TextField(
                    key: const Key('copilot-input'),
                    controller: _input,
                    minLines: 1,
                    maxLines: 4,
                    enabled: !s.offline,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: l.copilotInputHint,
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: FfSpace.space2),
                IconButton.filled(
                  key: const Key('copilot-send'),
                  tooltip: l.copilotSend,
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  onPressed: s.busy || s.offline ? null : _send,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _history(CopilotState s, CopilotController ctrl, AppLocalizations l) {
    if (s.history.isEmpty) {
      return Center(child: Text(l.copilotNoHistory));
    }
    return ListView(
      children: <Widget>[
        for (final CopilotConversation conv in s.history)
          ListTile(
            key: Key('conv-${conv.id}'),
            selected: conv.id == s.conversationId,
            title: Text(
              conv.title ?? l.copilotUntitled,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              conv.updatedAt.toLocal().toString().split('.').first,
            ),
            trailing: IconButton(
              tooltip: l.copilotDeleteConversation,
              icon: const Icon(Icons.delete_outline),
              onPressed: s.offline ? null : () => ctrl.delete(conv.id),
            ),
            onTap: () {
              ctrl.select(conv.id);
              setState(() => _showHistory = false);
            },
          ),
      ],
    );
  }

  Widget _messages(CopilotState s, CopilotController ctrl, AppLocalizations l) {
    if (s.messages.isEmpty && !s.loading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(FfSpace.space5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                l.copilotEmptyTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: FfSpace.space2),
              Text(l.copilotEmptyBody, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      key: const Key('copilot-messages'),
      controller: _scroll,
      padding: const EdgeInsets.all(FfSpace.space3),
      itemCount: s.messages.length,
      separatorBuilder: (_, _) => const SizedBox(height: FfSpace.space3),
      itemBuilder: (BuildContext context, int i) {
        final CopilotMessage m = s.messages[i];
        return MessageBubble(
          key: ValueKey<String>('msg-${m.id}'),
          message: m,
          strings: l,
          status: m.streaming && i == s.messages.length - 1
              ? (s.activity != null
                    ? l.copilotToolRunning(s.activity!)
                    : l.copilotThinking)
              : null,
          onCitation: (Citation c) => _openCitation(l, c),
          onConfirm: (Map<String, Object?> o) => ctrl.confirm(m.id, o),
          onReject: () => ctrl.reject(m.id),
        );
      },
    );
  }
}

/// One chat bubble: markdown, visualization, citation chips and the action card.
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    required this.message,
    required this.strings,
    required this.onCitation,
    required this.onConfirm,
    required this.onReject,
    this.status,
    super.key,
  });

  final CopilotMessage message;
  final AppLocalizations strings;
  final String? status;
  final void Function(Citation) onCitation;
  final Future<void> Function(Map<String, Object?>) onConfirm;
  final Future<void> Function() onReject;

  @override
  Widget build(BuildContext context) {
    final bool mine = message.role == MessageRole.user;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final double maxWidth = MediaQuery.sizeOf(context).width * 0.88;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          padding: const EdgeInsets.all(FfSpace.space3),
          decoration: BoxDecoration(
            color: mine ? scheme.primaryContainer : scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(FfRadius.lg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (message.content.isNotEmpty)
                mine ? Text(message.content) : CompactMarkdown(message.content),
              if (status != null && message.content.isEmpty)
                Text(
                  status!,
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              if (message.visualization != null) ...<Widget>[
                const SizedBox(height: FfSpace.space2),
                VisualizationView(message.visualization!),
              ],
              if (message.proposedAction != null) ...<Widget>[
                const SizedBox(height: FfSpace.space2),
                ActionCard(
                  message: message,
                  strings: strings,
                  onConfirm: onConfirm,
                  onReject: onReject,
                ),
              ],
              if (message.citations.isNotEmpty) ...<Widget>[
                const SizedBox(height: FfSpace.space2),
                Wrap(
                  spacing: FfSpace.space2,
                  children: <Widget>[
                    for (final Citation c in message.citations)
                      ActionChip(
                        key: Key(
                          c.isEntity
                              ? 'entity-chip-${c.entityId}'
                              : 'source-chip-${c.label}',
                        ),
                        avatar: Icon(
                          c.isEntity
                              ? Icons.open_in_new
                              : Icons.menu_book_outlined,
                          size: 16,
                        ),
                        label: Text(c.label),
                        onPressed: () => onCitation(c),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
