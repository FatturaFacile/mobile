import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../data/customer_lifecycle_remote_data_source.dart';
import '../domain/customer_lifecycle_models.dart';
import '../l10n/customer_lifecycle_strings.dart';
import 'customer_lifecycle_controller.dart';

/// Customer 360 for field technicians and sales agents: search a customer, then its health, post-sales KPIs and the timeline of
/// every touchpoint. Online only: the data is read from the web-api on demand.
class CustomerLifecyclePage extends ConsumerStatefulWidget {
  const CustomerLifecyclePage({super.key});

  @override
  ConsumerState<CustomerLifecyclePage> createState() =>
      _CustomerLifecyclePageState();
}

class _CustomerLifecyclePageState extends ConsumerState<CustomerLifecyclePage> {
  final TextEditingController _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final CustomerLifecycleStrings s = CustomerLifecycleStrings.of(context);
    final CustomerLifecycleState state = ref.watch(
      customerLifecycleControllerProvider,
    );
    final CustomerLifecycleController controller = ref.read(
      customerLifecycleControllerProvider.notifier,
    );
    final CustomerLifecycleView? view = state.view;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.t(CL.title)),
        bottom: state.loading
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(minHeight: 2),
              )
            : null,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              TextField(
                key: const Key('lifecycle-search'),
                controller: _query,
                decoration: InputDecoration(
                  labelText: s.t(CL.search),
                  prefixIcon: const Icon(Icons.search),
                ),
                onChanged: controller.search,
              ),
              if (state.error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    key: const Key('lifecycle-error'),
                    _errorText(s, state.error!),
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              if (state.selected == null || view == null) ...<Widget>[
                for (final LifecycleContact contact in state.results)
                  ListTile(
                    key: Key('lifecycle-contact-${contact.id}'),
                    title: Text(contact.label),
                    onTap: () => controller.select(contact),
                  ),
                if (state.noAccount)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      key: const Key('lifecycle-no-account'),
                      s.t(CL.noAccount),
                    ),
                  ),
              ] else ...<Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    state.selected!.label,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                _Kpis(strings: s, summary: view.summary),
                const SizedBox(height: 16),
                Text(
                  s.t(CL.timeline),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Wrap(
                  spacing: 8,
                  children: <Widget>[
                    for (final String type in kTimelineTypes)
                      FilterChip(
                        key: Key('lifecycle-filter-$type'),
                        label: Text(s.type(type)),
                        selected: state.types.contains(type),
                        onSelected: (bool on) => controller.filter(
                          on
                              ? <String>[...state.types, type]
                              : state.types
                                    .where((String t) => t != type)
                                    .toList(),
                        ),
                      ),
                  ],
                ),
                if (view.timeline.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(s.t(CL.noEvents)),
                  ),
                for (final CustomerTimelineEvent event in view.timeline)
                  ListTile(
                    key: Key('lifecycle-event-${event.id}'),
                    title: Text(event.title),
                    subtitle: Text(
                      '${s.type(event.type)} · '
                      '${event.occurredAt.toLocal().toString().substring(0, 16)}'
                      '${event.status == null ? '' : ' · ${event.status}'}',
                    ),
                    trailing: event.amount == null ? null : Text(event.amount!),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _errorText(CustomerLifecycleStrings s, LifecycleErrorKind kind) =>
      switch (kind) {
        LifecycleErrorKind.offline => s.t(CL.offline),
        LifecycleErrorKind.forbidden => s.t(CL.forbidden),
        _ => s.t(CL.failed),
      };
}

class _Kpis extends StatelessWidget {
  const _Kpis({required this.strings, required this.summary});

  final CustomerLifecycleStrings strings;
  final CustomerLifecycleSummary summary;

  @override
  Widget build(BuildContext context) {
    final CustomerLifecycleKpis k = summary.kpis;
    final List<(String, String)> cards = <(String, String)>[
      (strings.t(CL.health), summary.healthIndex.toStringAsFixed(1)),
      (strings.t(CL.churn), summary.churnRisk ?? '-'),
      (strings.t(CL.lifetimeValue), k.lifetimeValue),
      (strings.t(CL.pipeline), k.openPipelineValue),
      (strings.t(CL.overdue), k.overdueReceivableAmount),
      (strings.t(CL.openTickets), '${k.openTickets}'),
      (strings.t(CL.slaBreach), '${k.slaBreachRate.toStringAsFixed(1)} %'),
      (strings.t(CL.mttr), k.mttrHours?.toStringAsFixed(1) ?? '-'),
      (strings.t(CL.contracts), '${k.activeContracts}'),
      (strings.t(CL.coverage), strings.coverageLabel(k.contractCoverage)),
      (strings.t(CL.hoursRemaining), k.contractHoursRemaining),
      (strings.t(CL.interventionsOpen), '${k.interventionsScheduled}'),
      (strings.t(CL.interventionsDone), '${k.interventionsCompleted}'),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final (String, String) card in cards)
          SizedBox(
            width: 150,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      card.$1,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      card.$2,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
