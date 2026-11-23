import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../design/ff_tokens.dart';
import '../domain/project_portfolio_models.dart';
import '../l10n/project_portfolio_strings.dart';
import 'project_detail_page.dart';
import 'project_portfolio_controller.dart';
import 'project_portfolio_labels.dart';

/// Module key of the portfolio in the bootstrap payload.
const String projectPortfolioModule = 'project_portfolio';

/// Portfolio of the projects: filter by status, search by code or name, progress at a glance. It reads SQLite
/// only and refreshes it in the background, so it works the same offline.
class ProjectPortfolioPage extends ConsumerStatefulWidget {
  const ProjectPortfolioPage({super.key});

  @override
  ConsumerState<ProjectPortfolioPage> createState() =>
      _ProjectPortfolioPageState();
}

class _ProjectPortfolioPageState extends ConsumerState<ProjectPortfolioPage> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(portfolioSyncControllerProvider.notifier).refresh(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ProjectPortfolioStrings s = ProjectPortfolioStrings.of(context);
    final PortfolioSyncState sync = ref.watch(portfolioSyncControllerProvider);
    final PortfolioFilter filter = ref.watch(portfolioFilterProvider);
    final AsyncValue<List<Project>> projects = ref.watch(
      portfolioProjectsProvider,
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(s.t(PP.title)),
        bottom: sync.syncing
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(minHeight: 2),
              )
            : null,
      ),
      body: Column(
        children: <Widget>[
          if (sync.offline) _Banner(text: s.t(PP.offlineBanner)),
          if (sync.failed) _Banner(text: s.t(PP.syncFailed), isError: true),
          Padding(
            padding: const EdgeInsets.all(FfSpace.space3),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: s.t(PP.searchHint),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: ref.read(portfolioFilterProvider.notifier).setQuery,
            ),
          ),
          _StatusChips(strings: s, selected: filter.status),
          Expanded(
            child: RefreshIndicator(
              onRefresh: ref
                  .read(portfolioSyncControllerProvider.notifier)
                  .refresh,
              child: projects.when(
                data: (List<Project> all) {
                  final List<Project> visible = filter.apply(all);
                  if (visible.isEmpty) {
                    return ListView(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.all(FfSpace.space6),
                          child: Center(child: Text(s.t(PP.noProjects))),
                        ),
                      ],
                    );
                  }
                  return ListView.separated(
                    itemCount: visible.length,
                    separatorBuilder: (BuildContext _, int _) =>
                        const Divider(height: 1),
                    itemBuilder: (BuildContext context, int index) =>
                        _ProjectTile(project: visible[index], strings: s),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (Object e, StackTrace _) =>
                    Center(child: Text(s.t(PP.syncFailed))),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text, this.isError = false});

  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: isError ? scheme.errorContainer : scheme.tertiaryContainer,
      padding: const EdgeInsets.symmetric(
        horizontal: FfSpace.space4,
        vertical: FfSpace.space2,
      ),
      child: Text(text),
    );
  }
}

class _StatusChips extends ConsumerWidget {
  const _StatusChips({required this.strings, required this.selected});

  final ProjectPortfolioStrings strings;
  final ProjectStatus? selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PortfolioFilterController controller = ref.read(
      portfolioFilterProvider.notifier,
    );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: FfSpace.space3),
      child: Row(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: FfSpace.space2),
            child: ChoiceChip(
              label: Text(strings.t(PP.filterAll)),
              selected: selected == null,
              onSelected: (bool _) => controller.setStatus(null),
            ),
          ),
          for (final ProjectStatus status in ProjectStatus.values)
            Padding(
              padding: const EdgeInsets.only(right: FfSpace.space2),
              child: ChoiceChip(
                label: Text(strings.status(status)),
                selected: selected == status,
                onSelected: (bool _) => controller.setStatus(status),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProjectTile extends StatelessWidget {
  const _ProjectTile({required this.project, required this.strings});

  final Project project;
  final ProjectPortfolioStrings strings;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return ListTile(
      title: Text('${project.projectCode} · ${project.name}'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '${strings.status(project.status)} · '
            '${strings.projectType(project.projectType)}',
            style: text.bodySmall,
          ),
          const SizedBox(height: FfSpace.space1),
          LinearProgressIndicator(
            value: (project.percentComplete / 100).clamp(0, 1).toDouble(),
            minHeight: 4,
          ),
        ],
      ),
      trailing: Text(formatPercent(project.percentComplete)),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext _) => ProjectDetailPage(projectId: project.id),
        ),
      ),
    );
  }
}
