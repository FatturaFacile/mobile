import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/providers.dart';
import '../../../design/ff_tokens.dart';
import '../domain/resource_planning_models.dart';
import '../domain/resource_planning_repository.dart';
import 'resource_planning_allocation_forms.dart';
import 'resource_planning_controller.dart';
import 'resource_planning_setup_pages.dart';
import 'resource_planning_strings.dart';
import 'resource_planning_ui.dart';

export 'resource_planning_ui.dart' show resourcePlanningErrorMessage;

/// RBAC module key of the resource planning screens (capacity, allocations, candidates, utilization).
const String resourcePlanningModule = 'resource_planning';

/// Background and foreground colors of a saturation band, taken from the theme.
({Color background, Color foreground}) bandColors(
  FfColors c,
  SaturationBand band,
) => switch (band) {
  SaturationBand.green => (background: c.successBg, foreground: c.success),
  SaturationBand.yellow => (background: c.warningBg, foreground: c.warning),
  SaturationBand.red => (background: c.dangerBg, foreground: c.danger),
  SaturationBand.none => (background: c.surfaceAlt, foreground: c.textMuted),
};

String _bandLabel(ResourcePlanningStrings s, SaturationBand band) =>
    switch (band) {
      SaturationBand.none => s(RS.bandNone),
      SaturationBand.green => s(RS.bandGreen),
      SaturationBand.yellow => s(RS.bandYellow),
      SaturationBand.red => s(RS.bandRed),
    };

String _pct(double v) => '${v.round()}%';

String _hours(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

FfColors _colors(BuildContext context) =>
    Theme.of(context).extension<FfColors>() ?? FfColors.light;

ResourcePlanningStrings _strings(WidgetRef ref) => ResourcePlanningStrings(
  ref.watch(requestContextProvider).languageCode,
);

/// Entry point: capacity saturation, allocation agenda, candidate suggestions and billable utilization.
class ResourcePlanningHomePage extends ConsumerWidget {
  const ResourcePlanningHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ResourcePlanningStrings s = _strings(ref);
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: Text(s(RS.title)),
          bottom: TabBar(
            isScrollable: true,
            tabs: <Widget>[
              Tab(key: const Key('rp-tab-capacity'), text: s(RS.tabCapacity)),
              Tab(
                key: const Key('rp-tab-allocations'),
                text: s(RS.tabAllocations),
              ),
              Tab(
                key: const Key('rp-tab-candidates'),
                text: s(RS.tabCandidates),
              ),
              Tab(
                key: const Key('rp-tab-utilization'),
                text: s(RS.tabUtilization),
              ),
              Tab(key: const Key('rp-tab-setup'), text: s(RS.tabSetup)),
            ],
          ),
        ),
        body: const TabBarView(
          children: <Widget>[
            CapacityTab(),
            AllocationsTab(),
            CandidatesTab(),
            UtilizationTab(),
            SetupTab(),
          ],
        ),
      ),
    );
  }
}

Widget _errorBox(
  ResourcePlanningStrings s,
  ResourcePlanningException error,
  VoidCallback onRetry, {
  Key? key,
}) => Padding(
  padding: const EdgeInsets.all(FfSpace.space4),
  child: Column(
    key: key,
    children: <Widget>[
      Text(resourcePlanningErrorMessage(s, error)),
      TextButton(onPressed: onRetry, child: Text(s(RS.retry))),
    ],
  ),
);

// --- Capacity --------------------------------------------------------------------------------------------------

class CapacityTab extends ConsumerStatefulWidget {
  const CapacityTab({super.key});

  @override
  ConsumerState<CapacityTab> createState() => _CapacityTabState();
}

class _CapacityTabState extends ConsumerState<CapacityTab> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() => ref.read(capacityProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final ResourcePlanningStrings s = _strings(ref);
    final PlanningLoad<CapacityHeatmap> state = ref.watch(capacityProvider);
    final CapacityHeatmap? heatmap = state.data;
    return RefreshIndicator(
      onRefresh: () => ref.read(capacityProvider.notifier).load(),
      child: ListView(
        padding: const EdgeInsets.all(FfSpace.space4),
        children: <Widget>[
          if (state.error != null && heatmap == null)
            _errorBox(
              s,
              state.error!,
              () => ref.read(capacityProvider.notifier).load(),
              key: const Key('rp-capacity-error'),
            ),
          if (state.loading && heatmap == null)
            const Center(child: CircularProgressIndicator())
          else if (heatmap != null)
            CapacityHeatmapList(heatmap: heatmap, strings: s),
        ],
      ),
    );
  }
}

/// Heatmap as a list: an overload alert, the band legend and one card per employee with a colored cell per period.
class CapacityHeatmapList extends StatelessWidget {
  const CapacityHeatmapList({
    required this.heatmap,
    required this.strings,
    super.key,
  });

  final CapacityHeatmap heatmap;
  final ResourcePlanningStrings strings;

  @override
  Widget build(BuildContext context) {
    final FfColors c = _colors(context);
    final List<HeatmapRow> overloaded = heatmap.overloadedRows;
    if (heatmap.rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(FfSpace.space5),
        child: Center(
          child: Text(
            strings(RS.noCapacityRows),
            key: const Key('rp-capacity-empty'),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (overloaded.isNotEmpty)
          Container(
            key: const Key('rp-overload-alert'),
            margin: const EdgeInsets.only(bottom: FfSpace.space3),
            padding: const EdgeInsets.all(FfSpace.space3),
            decoration: BoxDecoration(
              color: c.dangerBg,
              borderRadius: BorderRadius.circular(FfRadius.md),
            ),
            child: Row(
              children: <Widget>[
                Icon(Icons.warning_amber_rounded, color: c.danger),
                const SizedBox(width: FfSpace.space2),
                Expanded(
                  child: Text(
                    strings(
                      RS.overloadAlert,
                      params: <String, Object>{'n': overloaded.length},
                    ),
                    style: TextStyle(color: c.danger),
                  ),
                ),
              ],
            ),
          ),
        _Legend(strings: strings),
        const SizedBox(height: FfSpace.space3),
        for (final HeatmapRow row in heatmap.rows)
          _HeatmapRowCard(row: row, strings: strings),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.strings});

  final ResourcePlanningStrings strings;

  @override
  Widget build(BuildContext context) {
    final FfColors c = _colors(context);
    return Wrap(
      spacing: FfSpace.space3,
      runSpacing: FfSpace.space1,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        Text(strings(RS.legendTitle)),
        for (final SaturationBand b in const <SaturationBand>[
          SaturationBand.green,
          SaturationBand.yellow,
          SaturationBand.red,
        ])
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: bandColors(c, b).foreground,
                  borderRadius: BorderRadius.circular(FfRadius.sm),
                ),
              ),
              const SizedBox(width: FfSpace.space1),
              Text(_bandLabel(strings, b)),
            ],
          ),
      ],
    );
  }
}

class _HeatmapRowCard extends StatelessWidget {
  const _HeatmapRowCard({required this.row, required this.strings});

  final HeatmapRow row;
  final ResourcePlanningStrings strings;

  @override
  Widget build(BuildContext context) {
    final FfColors c = _colors(context);
    final SaturationBand worst = row.worstBand;
    return Card(
      key: Key('rp-row-${row.employeeId}'),
      margin: const EdgeInsets.only(bottom: FfSpace.space3),
      child: Padding(
        padding: const EdgeInsets.all(FfSpace.space3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    row.employeeName,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Container(
                  key: Key('rp-peak-${row.employeeId}'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: FfSpace.space2,
                    vertical: FfSpace.space1,
                  ),
                  decoration: BoxDecoration(
                    color: bandColors(c, worst).background,
                    borderRadius: BorderRadius.circular(FfRadius.sm),
                  ),
                  child: Text(
                    '${strings(RS.peakLoad)} ${_pct(row.peakLoadPercent)}',
                    style: TextStyle(color: bandColors(c, worst).foreground),
                  ),
                ),
              ],
            ),
            if (row.departmentName != null)
              Text(
                row.departmentName!,
                style: TextStyle(color: c.textMuted),
              ),
            const SizedBox(height: FfSpace.space2),
            Wrap(
              spacing: FfSpace.space1,
              runSpacing: FfSpace.space1,
              children: <Widget>[
                for (final HeatmapCell cell in row.cells)
                  _CellChip(
                    rowId: row.employeeId,
                    cell: cell,
                    strings: strings,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CellChip extends StatelessWidget {
  const _CellChip({
    required this.rowId,
    required this.cell,
    required this.strings,
  });

  final String rowId;
  final HeatmapCell cell;
  final ResourcePlanningStrings strings;

  @override
  Widget build(BuildContext context) {
    final FfColors c = _colors(context);
    final ({Color background, Color foreground}) colors = bandColors(
      c,
      cell.band,
    );
    final String period = cell.periodStart.length >= 10
        ? cell.periodStart.substring(5)
        : cell.periodStart;
    return Tooltip(
      message:
          '${strings(RS.netHours)}: ${_hours(cell.netAvailableHours)} - '
          '${strings(RS.bookedHours)}: ${_hours(cell.bookedHours)} - '
          '${strings(RS.freeHours)}: ${_hours(cell.freeHours)}',
      child: Container(
        key: Key('rp-cell-$rowId-${cell.periodStart}'),
        width: 56,
        padding: const EdgeInsets.symmetric(vertical: FfSpace.space1),
        decoration: BoxDecoration(
          color: colors.background,
          border: Border.all(color: colors.foreground),
          borderRadius: BorderRadius.circular(FfRadius.sm),
        ),
        child: Column(
          children: <Widget>[
            Text(
              period,
              style: TextStyle(fontSize: 10, color: c.textMuted),
            ),
            Text(
              cell.band == SaturationBand.none ? '-' : _pct(cell.loadPercent),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: colors.foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Allocations -----------------------------------------------------------------------------------------------

class AllocationsTab extends ConsumerStatefulWidget {
  const AllocationsTab({super.key});

  @override
  ConsumerState<AllocationsTab> createState() => _AllocationsTabState();
}

class _AllocationsTabState extends ConsumerState<AllocationsTab> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(allocationsProvider.notifier).load(),
    );
  }

  Future<void> _run(
    Future<AllocationActionOutcome> Function() action,
    ResourcePlanningStrings s,
    RS doneLabel,
  ) async {
    final AllocationActionOutcome outcome = await action();
    if (!mounted) {
      return;
    }
    final AllocationMutationResult? result = outcome.result;
    final String message;
    if (result == null) {
      message = resourcePlanningErrorMessage(s, outcome.error!);
    } else {
      message = allocationResultMessage(s, doneLabel, result);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, key: const Key('rp-action-message'))),
    );
  }

  /// Commits a soft booking. One that only has an opportunity first asks for the project to commit it to.
  Future<void> _convert(
    ResourceAllocation allocation,
    ResourcePlanningStrings s,
  ) async {
    String? projectId;
    if (!allocation.canConvertWithoutProject) {
      final ProjectRef? picked = await pickProject(context);
      if (picked == null || !mounted) {
        return;
      }
      projectId = picked.id;
    }
    await _run(
      () => ref
          .read(allocationsProvider.notifier)
          .convertToHard(allocation, projectId: projectId),
      s,
      RS.convertDone,
    );
  }

  Future<void> _openForm(Widget page) => Navigator.of(
    context,
  ).push<bool>(MaterialPageRoute<bool>(builder: (BuildContext _) => page));

  @override
  Widget build(BuildContext context) {
    final ResourcePlanningStrings s = _strings(ref);
    final PlanningLoad<List<ResourceAllocation>> state = ref.watch(
      allocationsProvider,
    );
    final List<ResourceAllocation>? rows = state.data;
    final AllocationsController controller = ref.read(
      allocationsProvider.notifier,
    );
    return RefreshIndicator(
      onRefresh: controller.load,
      child: ListView(
        padding: const EdgeInsets.all(FfSpace.space4),
        children: <Widget>[
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              key: const Key('rp-add-allocation'),
              onPressed: () => _openForm(const AllocationFormPage()),
              icon: const Icon(Icons.add),
              label: Text(s(RS.addAllocation)),
            ),
          ),
          const SizedBox(height: FfSpace.space3),
          if (state.error != null && rows == null)
            _errorBox(
              s,
              state.error!,
              controller.load,
              key: const Key('rp-allocations-error'),
            ),
          if (state.loading && rows == null)
            const Center(child: CircularProgressIndicator())
          else if (rows != null && rows.isEmpty)
            Padding(
              padding: const EdgeInsets.all(FfSpace.space5),
              child: Center(
                child: Text(
                  s(RS.noAllocations),
                  key: const Key('rp-allocations-empty'),
                ),
              ),
            )
          else if (rows != null)
            for (final ResourceAllocation a in rows)
              AllocationCard(
                allocation: a,
                strings: s,
                onConvert: a.isSoft ? () => _convert(a, s) : null,
                onEdit: () => _openForm(AllocationEditPage(allocation: a)),
                onMove: (int days) =>
                    _run(() => controller.move(a, days), s, RS.moveDone),
              ),
        ],
      ),
    );
  }
}

/// One allocation of the agenda with its soft/hard badge and the convert and move actions.
class AllocationCard extends StatelessWidget {
  const AllocationCard({
    required this.allocation,
    required this.strings,
    required this.onMove,
    this.onConvert,
    this.onEdit,
    super.key,
  });

  final ResourceAllocation allocation;
  final ResourcePlanningStrings strings;

  /// Null when the booking is hard. A soft booking without a project asks for one before it is committed.
  final VoidCallback? onConvert;

  /// Opens the editor (resize, shift, reassign, split, delete); the button is hidden when null.
  final VoidCallback? onEdit;

  /// Moves the allocation by a number of days.
  final void Function(int days) onMove;

  @override
  Widget build(BuildContext context) {
    final FfColors c = _colors(context);
    final ResourceAllocation a = allocation;
    final Color badgeFg = a.isSoft ? c.warning : c.success;
    final Color badgeBg = a.isSoft ? c.warningBg : c.successBg;
    return Card(
      key: Key('rp-alloc-${a.id}'),
      margin: const EdgeInsets.only(bottom: FfSpace.space3),
      child: Padding(
        padding: const EdgeInsets.all(FfSpace.space3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    a.employeeName,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Container(
                  key: Key('rp-badge-${a.id}'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: FfSpace.space2,
                    vertical: FfSpace.space1,
                  ),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(FfRadius.sm),
                  ),
                  child: Text(
                    a.isSoft ? strings(RS.softBadge) : strings(RS.hardBadge),
                    style: TextStyle(color: badgeFg),
                  ),
                ),
              ],
            ),
            if (a.referenceName != null) Text(a.referenceName!),
            Text(
              '${a.startDate} - ${a.endDate}',
              style: TextStyle(color: c.textMuted),
            ),
            Text(
              '${_hours(a.allocatedHoursPerDay)} ${strings(RS.hoursPerDay)} - '
              '${_hours(a.totalAllocatedHours)} ${strings(RS.totalHours)} - '
              '${a.isBillable ? strings(RS.billable) : strings(RS.internal)}',
              style: TextStyle(color: c.textMuted),
            ),
            if (a.isOverloaded)
              Padding(
                key: Key('rp-alloc-overload-${a.id}'),
                padding: const EdgeInsets.only(top: FfSpace.space1),
                child: Text(
                  strings(
                    RS.overloadedBooking,
                    params: <String, Object>{'n': a.peakLoadPercent.round()},
                  ),
                  style: TextStyle(color: c.danger),
                ),
              ),
            if (a.isSoft && !a.canConvertWithoutProject)
              Padding(
                padding: const EdgeInsets.only(top: FfSpace.space1),
                child: Text(
                  strings(RS.convertNeedsProject),
                  key: Key('rp-alloc-needs-project-${a.id}'),
                  style: TextStyle(color: c.textMuted),
                ),
              ),
            const SizedBox(height: FfSpace.space2),
            Wrap(
              spacing: FfSpace.space2,
              children: <Widget>[
                if (a.isSoft)
                  FilledButton(
                    key: Key('rp-convert-${a.id}'),
                    onPressed: onConvert,
                    child: Text(strings(RS.convertToHard)),
                  ),
                if (onEdit != null)
                  OutlinedButton(
                    key: Key('rp-edit-${a.id}'),
                    onPressed: onEdit,
                    child: Text(strings(RS.editAction)),
                  ),
                OutlinedButton(
                  key: Key('rp-move-back-${a.id}'),
                  onPressed: () => onMove(-7),
                  child: Text(strings(RS.moveBack)),
                ),
                OutlinedButton(
                  key: Key('rp-move-forward-${a.id}'),
                  onPressed: () => onMove(7),
                  child: Text(strings(RS.moveForward)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// --- Candidates ------------------------------------------------------------------------------------------------

class CandidatesTab extends ConsumerStatefulWidget {
  const CandidatesTab({super.key});

  @override
  ConsumerState<CandidatesTab> createState() => _CandidatesTabState();
}

class _CandidatesTabState extends ConsumerState<CandidatesTab> {
  String? _skillId;
  int _minLevel = 3;
  double _hoursPerDay = 8;
  late DateTimeRange _range;

  @override
  void initState() {
    super.initState();
    final DateTime today = ref.read(resourcePlanningClockProvider)();
    final DateTime start = DateTime.utc(today.year, today.month, today.day);
    _range = DateTimeRange(
      start: start,
      end: start.add(const Duration(days: 28)),
    );
    Future<void>.microtask(
      () => ref.read(candidatesProvider.notifier).loadSkills(),
    );
  }

  Future<void> _pickRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: _range.start.subtract(const Duration(days: 30)),
      lastDate: _range.start.add(const Duration(days: 730)),
      initialDateRange: _range,
    );
    if (picked != null) {
      setState(() => _range = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ResourcePlanningStrings s = _strings(ref);
    final CandidatesState state = ref.watch(candidatesProvider);
    final List<Skill> skills = state.skills.data ?? const <Skill>[];
    final FfColors c = _colors(context);
    final List<Candidate>? found = state.candidates;
    return ListView(
      padding: const EdgeInsets.all(FfSpace.space4),
      children: <Widget>[
        Text(s(RS.candidatesIntro)),
        const SizedBox(height: FfSpace.space3),
        if (state.skills.error != null && skills.isEmpty)
          _errorBox(
            s,
            state.skills.error!,
            () => ref.read(candidatesProvider.notifier).loadSkills(),
            key: const Key('rp-skills-error'),
          )
        else if (state.skills.data != null && skills.isEmpty)
          Text(s(RS.noSkills), key: const Key('rp-no-skills'))
        else ...<Widget>[
          Text(s(RS.roleSkill)),
          DropdownButton<String>(
            key: const Key('rp-skill'),
            isExpanded: true,
            value: skills.any((Skill k) => k.id == _skillId) ? _skillId : null,
            items: <DropdownMenuItem<String>>[
              for (final Skill k in skills)
                DropdownMenuItem<String>(
                  value: k.id,
                  child: Text('${k.category} / ${k.skillName}'),
                ),
            ],
            onChanged: (String? v) => setState(() => _skillId = v),
          ),
          Text(s(RS.minLevel)),
          DropdownButton<int>(
            key: const Key('rp-level'),
            isExpanded: true,
            value: _minLevel,
            items: <DropdownMenuItem<int>>[
              for (int l = 1; l <= 5; l++)
                DropdownMenuItem<int>(value: l, child: Text('$l')),
            ],
            onChanged: (int? v) => setState(() => _minLevel = v ?? _minLevel),
          ),
          Text(s(RS.hoursPerDay)),
          DropdownButton<double>(
            key: const Key('rp-hours'),
            isExpanded: true,
            value: _hoursPerDay,
            items: <DropdownMenuItem<double>>[
              for (final double h in const <double>[2, 4, 6, 8])
                DropdownMenuItem<double>(value: h, child: Text(_hours(h))),
            ],
            onChanged: (double? v) =>
                setState(() => _hoursPerDay = v ?? _hoursPerDay),
          ),
          OutlinedButton.icon(
            key: const Key('rp-period'),
            onPressed: _pickRange,
            icon: const Icon(Icons.date_range_outlined),
            label: Text(
              '${s(RS.period)}: ${ymd(_range.start)} - ${ymd(_range.end)}',
            ),
          ),
          const SizedBox(height: FfSpace.space3),
          FilledButton(
            key: const Key('rp-search'),
            onPressed: _skillId == null || state.searching
                ? null
                : () => ref
                      .read(candidatesProvider.notifier)
                      .search(
                        CandidateQuery(
                          startDate: ymd(_range.start),
                          endDate: ymd(_range.end),
                          allocatedHoursPerDay: _hoursPerDay,
                          requirements: <SkillRequirement>[
                            SkillRequirement(
                              skillId: _skillId!,
                              minLevel: _minLevel,
                            ),
                          ],
                          includeIneligible: true,
                        ),
                      ),
            child: Text(s(RS.search)),
          ),
        ],
        if (state.searching)
          const Padding(
            padding: EdgeInsets.all(FfSpace.space4),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (state.error != null)
          Padding(
            padding: const EdgeInsets.only(top: FfSpace.space3),
            child: Text(
              resourcePlanningErrorMessage(s, state.error!),
              key: const Key('rp-search-error'),
              style: TextStyle(color: c.danger),
            ),
          ),
        if (found != null && found.isEmpty && !state.searching)
          Padding(
            padding: const EdgeInsets.all(FfSpace.space4),
            child: Center(
              child: Text(
                s(RS.noCandidates),
                key: const Key('rp-no-candidates'),
              ),
            ),
          ),
        if (found != null)
          for (final Candidate cand in found)
            _CandidateCard(candidate: cand, strings: s),
      ],
    );
  }
}

class _CandidateCard extends StatelessWidget {
  const _CandidateCard({required this.candidate, required this.strings});

  final Candidate candidate;
  final ResourcePlanningStrings strings;

  @override
  Widget build(BuildContext context) {
    final FfColors c = _colors(context);
    final Candidate cand = candidate;
    return Card(
      key: Key('rp-candidate-${cand.employeeId}'),
      margin: const EdgeInsets.only(top: FfSpace.space3),
      child: Padding(
        padding: const EdgeInsets.all(FfSpace.space3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    cand.employeeName,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Text(
                  cand.eligible
                      ? strings(RS.eligible)
                      : strings(RS.notEligible),
                  key: Key('rp-eligible-${cand.employeeId}'),
                  style: TextStyle(color: cand.eligible ? c.success : c.danger),
                ),
              ],
            ),
            if (cand.departmentName != null)
              Text(cand.departmentName!, style: TextStyle(color: c.textMuted)),
            Text('${strings(RS.score)}: ${_hours(cand.score)}'),
            Text(
              '${strings(RS.availableHours)}: ${_hours(cand.availableHours)}',
            ),
            Text(
              '${strings(RS.peakAfter)}: ${_pct(cand.peakLoadAfterPercent)}',
              style: TextStyle(color: cand.wouldOverload ? c.danger : null),
            ),
            if (cand.matchedSkills.isNotEmpty)
              Text(
                cand.matchedSkills
                    .map((MatchedSkill m) => '${m.skillName} ${m.level}')
                    .join(', '),
                style: TextStyle(color: c.textMuted),
              ),
            for (final CandidateBlocker b in cand.blockers)
              Text(
                strings.blocker(b.code),
                key: Key('rp-blocker-${cand.employeeId}-${b.code}'),
                style: TextStyle(color: c.danger),
              ),
          ],
        ),
      ),
    );
  }
}

// --- Utilization -----------------------------------------------------------------------------------------------

class UtilizationTab extends ConsumerStatefulWidget {
  const UtilizationTab({super.key});

  @override
  ConsumerState<UtilizationTab> createState() => _UtilizationTabState();
}

class _UtilizationTabState extends ConsumerState<UtilizationTab> {
  UtilizationGroup _group = UtilizationGroup.resource;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(utilizationProvider.notifier).load(groupBy: _group),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ResourcePlanningStrings s = _strings(ref);
    final PlanningLoad<UtilizationReport> state = ref.watch(utilizationProvider);
    final UtilizationReport? report = state.data;
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(utilizationProvider.notifier).load(groupBy: _group),
      child: ListView(
        padding: const EdgeInsets.all(FfSpace.space4),
        children: <Widget>[
          Text(
            s(RS.utilizationTitle),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: FfSpace.space3),
          SegmentedButton<UtilizationGroup>(
            key: const Key('rp-group'),
            segments: <ButtonSegment<UtilizationGroup>>[
              ButtonSegment<UtilizationGroup>(
                value: UtilizationGroup.resource,
                label: Text(s(RS.groupResource)),
              ),
              ButtonSegment<UtilizationGroup>(
                value: UtilizationGroup.department,
                label: Text(s(RS.groupDepartment)),
              ),
              ButtonSegment<UtilizationGroup>(
                value: UtilizationGroup.costCenter,
                label: Text(s(RS.groupCostCenter)),
              ),
            ],
            selected: <UtilizationGroup>{_group},
            onSelectionChanged: (Set<UtilizationGroup> v) {
              setState(() => _group = v.first);
              ref.read(utilizationProvider.notifier).load(groupBy: _group);
            },
          ),
          const SizedBox(height: FfSpace.space3),
          if (state.error != null && report == null)
            _errorBox(
              s,
              state.error!,
              () =>
                  ref.read(utilizationProvider.notifier).load(groupBy: _group),
              key: const Key('rp-utilization-error'),
            ),
          if (state.loading && report == null)
            const Center(child: CircularProgressIndicator())
          else if (report != null && report.rows.isEmpty)
            Padding(
              padding: const EdgeInsets.all(FfSpace.space5),
              child: Center(
                child: Text(
                  s(RS.noUtilization),
                  key: const Key('rp-utilization-empty'),
                ),
              ),
            )
          else if (report != null) ...<Widget>[
            UtilizationCard(
              cardKey: const Key('rp-utilization-totals'),
              row: report.totals,
              title: s(RS.totals),
              strings: s,
            ),
            for (final UtilizationRow row in report.rows)
              UtilizationCard(
                cardKey: Key('rp-utilization-${row.keyId ?? row.keyName}'),
                row: row,
                title: row.keyName,
                strings: s,
              ),
          ],
        ],
      ),
    );
  }
}

/// Target versus actual (and forecast) billable utilization of one resource, department or cost center.
class UtilizationCard extends StatelessWidget {
  const UtilizationCard({
    required this.row,
    required this.title,
    required this.strings,
    this.cardKey,
    super.key,
  });

  final UtilizationRow row;
  final String title;
  final ResourcePlanningStrings strings;
  final Key? cardKey;

  @override
  Widget build(BuildContext context) {
    final FfColors c = _colors(context);
    final Color statusColor = switch (row.status) {
      UtilizationStatus.onTarget => c.success,
      UtilizationStatus.belowTarget => c.danger,
      UtilizationStatus.aboveTarget => c.warning,
    };
    final String statusText = switch (row.status) {
      UtilizationStatus.onTarget => strings(RS.statusOnTarget),
      UtilizationStatus.belowTarget => strings(RS.statusBelowTarget),
      UtilizationStatus.aboveTarget => strings(RS.statusAboveTarget),
    };
    final double progress = (row.actualBillablePercent / 100).clamp(0.0, 1.0);
    return Card(
      key: cardKey,
      margin: const EdgeInsets.only(bottom: FfSpace.space3),
      child: Padding(
        padding: const EdgeInsets.all(FfSpace.space3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Text(statusText, style: TextStyle(color: statusColor)),
              ],
            ),
            const SizedBox(height: FfSpace.space2),
            LinearProgressIndicator(value: progress, color: statusColor),
            const SizedBox(height: FfSpace.space2),
            Text(
              '${strings(RS.actual)} ${_pct(row.actualBillablePercent)} - '
              '${strings(RS.forecast)} ${_pct(row.forecastBillablePercent)} - '
              '${strings(RS.target)} ${_pct(row.targetPercent)}',
            ),
            Text(
              '${strings(RS.gap)}: ${row.gapPercent >= 0 ? '+' : ''}'
              '${row.gapPercent.toStringAsFixed(1)}',
              style: TextStyle(color: c.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
