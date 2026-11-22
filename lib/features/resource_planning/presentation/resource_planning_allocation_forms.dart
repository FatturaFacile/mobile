import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../design/ff_tokens.dart';
import '../domain/resource_planning_models.dart';
import '../domain/resource_planning_repository.dart';
import 'resource_planning_controller.dart';
import 'resource_planning_strings.dart';
import 'resource_planning_ui.dart';

/// Opens the project picker and returns the chosen project, or null when it was dismissed.
Future<ProjectRef?> pickProject(BuildContext context) =>
    Navigator.of(context).push<ProjectRef>(
      MaterialPageRoute<ProjectRef>(
        builder: (BuildContext _) => const ProjectPickerPage(),
      ),
    );

/// Message that reports the result of an allocation write: the done label, the overload verdict and the warnings.
String allocationResultMessage(
  ResourcePlanningStrings s,
  RS doneLabel,
  AllocationMutationResult result,
) => <String>[
  s(doneLabel),
  if (result.overload.isOverloaded)
    s(
      RS.overloadedBooking,
      params: <String, Object>{'n': result.overload.peakLoadPercent.round()},
    ),
  for (final ApiCode w in result.warnings) s.violation(w.code),
].join(' - ');

DateTime _parseDay(String ymdText) {
  final DateTime? parsed = DateTime.tryParse(ymdText);
  return parsed == null
      ? DateTime.now()
      : DateTime.utc(parsed.year, parsed.month, parsed.day);
}

// --- Project picker --------------------------------------------------------------------------------------------

/// Searchable list of the projects. When the list cannot be loaded (no access, offline) a validated project id input
/// takes its place, so a soft booking can still be committed.
class ProjectPickerPage extends ConsumerStatefulWidget {
  const ProjectPickerPage({super.key});

  @override
  ConsumerState<ProjectPickerPage> createState() => _ProjectPickerPageState();
}

class _ProjectPickerPageState extends ConsumerState<ProjectPickerPage> {
  final TextEditingController _search = TextEditingController();
  final TextEditingController _manualId = TextEditingController();
  bool _manualInvalid = false;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(projectSearchProvider.notifier).search(''),
    );
  }

  @override
  void dispose() {
    _search.dispose();
    _manualId.dispose();
    super.dispose();
  }

  void _useManualId() {
    final String id = _manualId.text.trim();
    if (!isUuid(id)) {
      setState(() => _manualInvalid = true);
      return;
    }
    Navigator.of(context).pop(ProjectRef(id: id, name: id));
  }

  @override
  Widget build(BuildContext context) {
    final ResourcePlanningStrings s = rpStrings(ref);
    final PlanningLoad<List<ProjectRef>> state = ref.watch(projectSearchProvider);
    final List<ProjectRef>? projects = state.data;
    final FfColors c = rpColors(context);
    return Scaffold(
      appBar: AppBar(title: Text(s(RS.pickProjectTitle))),
      body: ListView(
        padding: const EdgeInsets.all(FfSpace.space4),
        children: <Widget>[
          TextField(
            key: const Key('rp-project-search'),
            controller: _search,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              labelText: s(RS.searchProjects),
              suffixIcon: IconButton(
                key: const Key('rp-project-search-go'),
                icon: const Icon(Icons.search),
                onPressed: () => ref
                    .read(projectSearchProvider.notifier)
                    .search(_search.text),
              ),
            ),
            onSubmitted: (String v) =>
                ref.read(projectSearchProvider.notifier).search(v),
          ),
          const SizedBox(height: FfSpace.space3),
          if (state.loading && projects == null)
            const Center(child: CircularProgressIndicator())
          else if (state.error != null) ...<Widget>[
            Text(
              s(RS.projectListUnavailable),
              key: const Key('rp-project-list-unavailable'),
              style: TextStyle(color: c.textMuted),
            ),
            const SizedBox(height: FfSpace.space2),
            TextField(
              key: const Key('rp-project-id-input'),
              controller: _manualId,
              decoration: InputDecoration(
                labelText: s(RS.projectIdManual),
                errorText: _manualInvalid ? s(RS.issueInvalidProjectId) : null,
              ),
              onChanged: (String _) {
                if (_manualInvalid) {
                  setState(() => _manualInvalid = false);
                }
              },
            ),
            const SizedBox(height: FfSpace.space2),
            FilledButton(
              key: const Key('rp-project-id-use'),
              onPressed: _useManualId,
              child: Text(s(RS.useProjectId)),
            ),
          ] else if (projects != null && projects.isEmpty)
            Padding(
              padding: const EdgeInsets.all(FfSpace.space5),
              child: Center(
                child: Text(
                  s(RS.noProjects),
                  key: const Key('rp-projects-empty'),
                ),
              ),
            )
          else if (projects != null)
            for (final ProjectRef p in projects)
              ListTile(
                key: Key('rp-project-${p.id}'),
                title: Text(p.name),
                subtitle: p.number.isEmpty ? null : Text(p.number),
                onTap: () => Navigator.of(context).pop(p),
              ),
        ],
      ),
    );
  }
}

// --- Create allocation -----------------------------------------------------------------------------------------

/// Form of a new allocation: employee, booking type, project or opportunity, dates, hours per day, billable flag,
/// notes, overload policy and the skills the booking needs.
class AllocationFormPage extends ConsumerStatefulWidget {
  const AllocationFormPage({this.initialEmployeeId, super.key});

  /// Employee preselected, e.g. from a candidate suggestion.
  final String? initialEmployeeId;

  @override
  ConsumerState<AllocationFormPage> createState() => _AllocationFormPageState();
}

class _AllocationFormPageState extends ConsumerState<AllocationFormPage> {
  final TextEditingController _hours = TextEditingController(text: '8');
  final TextEditingController _opportunity = TextEditingController();
  final TextEditingController _notes = TextEditingController();
  late DateTimeRange _range;
  String? _employeeId;
  BookingType _type = BookingType.softTentative;
  ProjectRef? _project;
  bool _billable = true;
  bool _allowOverload = true;
  final Set<String> _skillIds = <String>{};
  List<AllocationDraftIssue> _issues = const <AllocationDraftIssue>[];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _employeeId = widget.initialEmployeeId;
    final DateTime now = ref.read(resourcePlanningClockProvider)();
    final DateTime start = DateTime.utc(now.year, now.month, now.day);
    _range = DateTimeRange(start: start, end: start.add(const Duration(days: 4)));
    Future<void>.microtask(() {
      ref.read(resourcesProvider.notifier).load();
      ref.read(skillsProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _hours.dispose();
    _opportunity.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: _range.start.subtract(const Duration(days: 365)),
      lastDate: _range.start.add(const Duration(days: 1095)),
      initialDateRange: _range,
    );
    if (picked != null) {
      setState(() => _range = picked);
    }
  }

  Future<void> _pickProject() async {
    final ProjectRef? picked = await pickProject(context);
    if (picked != null && mounted) {
      setState(() => _project = picked);
    }
  }

  AllocationDraft _draft() => AllocationDraft(
    employeeId: _employeeId ?? '',
    bookingType: _type,
    startDate: ymd(_range.start),
    endDate: ymd(_range.end),
    allocatedHoursPerDay: parseDecimal(_hours.text) ?? 0,
    projectId: _project?.id,
    opportunityId: _type.isSoft ? _opportunity.text : null,
    isBillable: _billable,
    notes: _notes.text,
    allowOverload: _allowOverload,
    requiredSkillIds: _skillIds.toList()..sort(),
  );

  Future<void> _save(ResourcePlanningStrings s) async {
    final AllocationDraft draft = _draft();
    final List<AllocationDraftIssue> issues = draft.validate();
    setState(() => _issues = issues);
    if (issues.isNotEmpty) {
      return;
    }
    setState(() => _saving = true);
    final AllocationActionOutcome outcome = await ref
        .read(allocationsProvider.notifier)
        .create(draft);
    if (!mounted) {
      return;
    }
    final AllocationMutationResult? result = outcome.result;
    if (result == null) {
      setState(() => _saving = false);
      rpSnack(
        context,
        resourcePlanningErrorMessage(s, outcome.error!),
        messageKey: const Key('rp-action-message'),
      );
      return;
    }
    rpSnack(
      context,
      allocationResultMessage(s, RS.allocationCreated, result),
      messageKey: const Key('rp-action-message'),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final ResourcePlanningStrings s = rpStrings(ref);
    final FfColors c = rpColors(context);
    final PlanningLoad<List<ResourceLookup>> resources = ref.watch(resourcesProvider);
    final List<ResourceLookup> employees = resources.data ?? const <ResourceLookup>[];
    final PlanningLoad<List<Skill>> skillsState = ref.watch(skillsProvider);
    final List<Skill> skills = skillsState.data ?? const <Skill>[];
    return Scaffold(
      appBar: AppBar(title: Text(s(RS.allocationFormTitle))),
      body: ListView(
        padding: const EdgeInsets.all(FfSpace.space4),
        children: <Widget>[
          Text(s(RS.employeeField)),
          if (resources.error != null && employees.isEmpty)
            rpErrorBox(
              s,
              resources.error!,
              () => ref.read(resourcesProvider.notifier).load(),
              key: const Key('rp-form-employees-error'),
            )
          else if (resources.data != null && employees.isEmpty)
            Text(s(RS.noEmployees), key: const Key('rp-form-no-employees'))
          else
            DropdownButton<String>(
              key: const Key('rp-form-employee'),
              isExpanded: true,
              value: employees.any((ResourceLookup e) => e.employeeId == _employeeId)
                  ? _employeeId
                  : null,
              items: <DropdownMenuItem<String>>[
                for (final ResourceLookup e in employees)
                  DropdownMenuItem<String>(
                    value: e.employeeId,
                    child: Text(e.fullName),
                  ),
              ],
              onChanged: (String? v) => setState(() => _employeeId = v),
            ),
          const SizedBox(height: FfSpace.space3),
          Text(s(RS.bookingTypeField)),
          SegmentedButton<BookingType>(
            key: const Key('rp-form-type'),
            segments: <ButtonSegment<BookingType>>[
              ButtonSegment<BookingType>(
                value: BookingType.softTentative,
                label: Text(s(RS.softBadge)),
              ),
              ButtonSegment<BookingType>(
                value: BookingType.hardCommitted,
                label: Text(s(RS.hardBadge)),
              ),
            ],
            selected: <BookingType>{_type},
            onSelectionChanged: (Set<BookingType> v) =>
                setState(() => _type = v.first),
          ),
          const SizedBox(height: FfSpace.space3),
          Text(s(RS.projectField)),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  _project?.label ?? s(RS.noProjectChosen),
                  key: const Key('rp-form-project-label'),
                  style: TextStyle(color: _project == null ? c.textMuted : null),
                ),
              ),
              if (_project != null)
                IconButton(
                  key: const Key('rp-form-project-clear'),
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _project = null),
                ),
              OutlinedButton(
                key: const Key('rp-form-project-pick'),
                onPressed: _pickProject,
                child: Text(s(RS.chooseProject)),
              ),
            ],
          ),
          if (_type.isSoft)
            TextField(
              key: const Key('rp-form-opportunity'),
              controller: _opportunity,
              decoration: InputDecoration(labelText: s(RS.opportunityIdField)),
            ),
          const SizedBox(height: FfSpace.space3),
          OutlinedButton.icon(
            key: const Key('rp-form-period'),
            onPressed: _pickRange,
            icon: const Icon(Icons.date_range_outlined),
            label: Text(
              '${s(RS.period)}: ${ymd(_range.start)} - ${ymd(_range.end)}',
            ),
          ),
          TextField(
            key: const Key('rp-form-hours'),
            controller: _hours,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: s(RS.hoursPerDayField)),
          ),
          SwitchListTile(
            key: const Key('rp-form-billable'),
            contentPadding: EdgeInsets.zero,
            title: Text(s(RS.billable)),
            value: _billable,
            onChanged: (bool v) => setState(() => _billable = v),
          ),
          SwitchListTile(
            key: const Key('rp-form-overload'),
            contentPadding: EdgeInsets.zero,
            title: Text(s(RS.allowOverloadField)),
            value: _allowOverload,
            onChanged: (bool v) => setState(() => _allowOverload = v),
          ),
          if (skills.isNotEmpty) ...<Widget>[
            Text(s(RS.requiredSkillsField)),
            Wrap(
              spacing: FfSpace.space2,
              children: <Widget>[
                for (final Skill k in skills)
                  FilterChip(
                    key: Key('rp-form-skill-${k.id}'),
                    label: Text(k.skillName),
                    selected: _skillIds.contains(k.id),
                    onSelected: (bool on) => setState(() {
                      if (on) {
                        _skillIds.add(k.id);
                      } else {
                        _skillIds.remove(k.id);
                      }
                    }),
                  ),
              ],
            ),
          ],
          TextField(
            key: const Key('rp-form-notes'),
            controller: _notes,
            maxLines: 2,
            decoration: InputDecoration(labelText: s(RS.notesField)),
          ),
          if (_issues.isNotEmpty)
            Padding(
              key: const Key('rp-form-issues'),
              padding: const EdgeInsets.only(top: FfSpace.space3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  for (final AllocationDraftIssue i in _issues)
                    Text(
                      allocationIssueLabel(s, i),
                      key: Key('rp-form-issue-${i.name}'),
                      style: TextStyle(color: c.danger),
                    ),
                ],
              ),
            ),
          const SizedBox(height: FfSpace.space4),
          FilledButton(
            key: const Key('rp-form-save'),
            onPressed: _saving ? null : () => _save(s),
            child: Text(s(RS.saveAction)),
          ),
        ],
      ),
    );
  }
}

// --- Edit allocation (rebalance) -------------------------------------------------------------------------------

/// Edits an existing allocation through the rebalance endpoint: resize (dates, hours per day), shift by any number of
/// days, reassign to a colleague or split in two, plus a confirmed delete.
class AllocationEditPage extends ConsumerStatefulWidget {
  const AllocationEditPage({required this.allocation, super.key});

  final ResourceAllocation allocation;

  @override
  ConsumerState<AllocationEditPage> createState() => _AllocationEditPageState();
}

class _AllocationEditPageState extends ConsumerState<AllocationEditPage> {
  late RebalanceStrategy _strategy;
  late DateTime _start;
  late DateTime _end;
  late DateTime _splitDate;
  late final TextEditingController _hours;
  final TextEditingController _shiftDays = TextEditingController(text: '7');
  String? _newEmployeeId;
  String? _splitEmployeeId;
  String? _issue;
  bool _busy = false;

  ResourceAllocation get _a => widget.allocation;

  @override
  void initState() {
    super.initState();
    _strategy = RebalanceStrategy.resize;
    _start = _parseDay(_a.startDate);
    _end = _parseDay(_a.endDate);
    final int span = _end.difference(_start).inDays;
    _splitDate = _start.add(Duration(days: span <= 0 ? 0 : (span + 1) ~/ 2));
    _hours = TextEditingController(text: rpHours(_a.allocatedHoursPerDay));
    Future<void>.microtask(() => ref.read(resourcesProvider.notifier).load());
  }

  @override
  void dispose() {
    _hours.dispose();
    _shiftDays.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDay(DateTime initial) => showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime.utc(initial.year - 2),
    lastDate: DateTime.utc(initial.year + 5),
  );

  /// The request of the chosen strategy, or null (with the issue stored) when the input is not acceptable.
  RebalanceRequest? _request(ResourcePlanningStrings s) {
    switch (_strategy) {
      case RebalanceStrategy.resize:
        final double? hours = parseDecimal(_hours.text);
        if (hours == null || hours <= 0 || hours > maxAllocationHoursPerDay) {
          _issue = s(RS.issueInvalidHours);
          return null;
        }
        if (_end.isBefore(_start)) {
          _issue = s(RS.violationInvalidPeriod);
          return null;
        }
        final bool startChanged = ymd(_start) != _a.startDate;
        final bool endChanged = ymd(_end) != _a.endDate;
        final bool hoursChanged = hours != _a.allocatedHoursPerDay;
        if (!startChanged && !endChanged && !hoursChanged) {
          _issue = s(RS.issueNothingChanged);
          return null;
        }
        return RebalanceRequest(
          strategy: RebalanceStrategy.resize,
          startDate: startChanged ? ymd(_start) : null,
          endDate: endChanged ? ymd(_end) : null,
          allocatedHoursPerDay: hoursChanged ? hours : null,
        );
      case RebalanceStrategy.shift:
        final int? days = int.tryParse(_shiftDays.text.trim());
        if (days == null || days == 0) {
          _issue = s(RS.issueShiftDays);
          return null;
        }
        return RebalanceRequest.shiftBy(days);
      case RebalanceStrategy.reassign:
        final String? employee = _newEmployeeId;
        if (employee == null || employee == _a.employeeId) {
          _issue = s(RS.issueEmployeeRequired);
          return null;
        }
        return RebalanceRequest.reassignTo(employee);
      case RebalanceStrategy.split:
        final DateTime from = _parseDay(_a.startDate);
        final DateTime to = _parseDay(_a.endDate);
        if (!_splitDate.isAfter(from) || _splitDate.isAfter(to)) {
          _issue = s(RS.issueSplitDate);
          return null;
        }
        return RebalanceRequest(
          strategy: RebalanceStrategy.split,
          splitDate: ymd(_splitDate),
          employeeId: _splitEmployeeId,
        );
    }
  }

  Future<void> _apply(ResourcePlanningStrings s) async {
    _issue = null;
    final RebalanceRequest? request = _request(s);
    if (request == null) {
      setState(() {});
      return;
    }
    setState(() => _busy = true);
    final AllocationActionOutcome outcome = await ref
        .read(allocationsProvider.notifier)
        .rebalance(_a, request);
    if (!mounted) {
      return;
    }
    final AllocationMutationResult? result = outcome.result;
    if (result == null) {
      setState(() => _busy = false);
      rpSnack(
        context,
        resourcePlanningErrorMessage(s, outcome.error!),
        messageKey: const Key('rp-action-message'),
      );
      return;
    }
    rpSnack(
      context,
      allocationResultMessage(s, RS.allocationUpdated, result),
      messageKey: const Key('rp-action-message'),
    );
    Navigator.of(context).pop(true);
  }

  Future<void> _delete(ResourcePlanningStrings s) async {
    final bool confirmed = await rpConfirm(
      context,
      s,
      title: s(RS.deleteAllocationTitle),
      body: s(RS.deleteAllocationBody, params: <String, Object>{'name': _a.employeeName}),
    );
    if (!confirmed || !mounted) {
      return;
    }
    setState(() => _busy = true);
    final PlanningOutcome outcome = await ref
        .read(allocationsProvider.notifier)
        .delete(_a);
    if (!mounted) {
      return;
    }
    if (!outcome.ok) {
      setState(() => _busy = false);
      rpSnack(
        context,
        resourcePlanningErrorMessage(s, outcome.error!),
        messageKey: const Key('rp-action-message'),
      );
      return;
    }
    rpSnack(
      context,
      s(RS.allocationDeleted),
      messageKey: const Key('rp-action-message'),
    );
    Navigator.of(context).pop(true);
  }

  Widget _employeeDropdown({
    required Key key,
    required List<ResourceLookup> employees,
    required String? value,
    required ValueChanged<String?> onChanged,
    String? noneLabel,
  }) => DropdownButton<String>(
    key: key,
    isExpanded: true,
    value: employees.any((ResourceLookup e) => e.employeeId == value) ? value : null,
    hint: noneLabel == null ? null : Text(noneLabel),
    items: <DropdownMenuItem<String>>[
      for (final ResourceLookup e in employees)
        if (e.employeeId != _a.employeeId)
          DropdownMenuItem<String>(value: e.employeeId, child: Text(e.fullName)),
    ],
    onChanged: onChanged,
  );

  @override
  Widget build(BuildContext context) {
    final ResourcePlanningStrings s = rpStrings(ref);
    final FfColors c = rpColors(context);
    final List<ResourceLookup> employees =
        ref.watch(resourcesProvider).data ?? const <ResourceLookup>[];
    return Scaffold(
      appBar: AppBar(title: Text(s(RS.allocationEditTitle))),
      body: ListView(
        padding: const EdgeInsets.all(FfSpace.space4),
        children: <Widget>[
          Text(_a.employeeName, style: Theme.of(context).textTheme.titleSmall),
          if (_a.referenceName != null) Text(_a.referenceName!),
          Text(
            '${_a.startDate} - ${_a.endDate} - ${rpHours(_a.allocatedHoursPerDay)} ${s(RS.hoursPerDay)}',
            style: TextStyle(color: c.textMuted),
          ),
          const SizedBox(height: FfSpace.space3),
          SegmentedButton<RebalanceStrategy>(
            key: const Key('rp-edit-strategy'),
            segments: <ButtonSegment<RebalanceStrategy>>[
              ButtonSegment<RebalanceStrategy>(
                value: RebalanceStrategy.resize,
                label: Text(s(RS.strategyResize)),
              ),
              ButtonSegment<RebalanceStrategy>(
                value: RebalanceStrategy.shift,
                label: Text(s(RS.strategyShift)),
              ),
              ButtonSegment<RebalanceStrategy>(
                value: RebalanceStrategy.reassign,
                label: Text(s(RS.strategyReassign)),
              ),
              ButtonSegment<RebalanceStrategy>(
                value: RebalanceStrategy.split,
                label: Text(s(RS.strategySplit)),
              ),
            ],
            selected: <RebalanceStrategy>{_strategy},
            onSelectionChanged: (Set<RebalanceStrategy> v) => setState(() {
              _strategy = v.first;
              _issue = null;
            }),
          ),
          const SizedBox(height: FfSpace.space3),
          if (_strategy == RebalanceStrategy.resize) ...<Widget>[
            OutlinedButton(
              key: const Key('rp-edit-start'),
              onPressed: () async {
                final DateTime? d = await _pickDay(_start);
                if (d != null) {
                  setState(() => _start = DateTime.utc(d.year, d.month, d.day));
                }
              },
              child: Text('${s(RS.startDateField)}: ${ymd(_start)}'),
            ),
            OutlinedButton(
              key: const Key('rp-edit-end'),
              onPressed: () async {
                final DateTime? d = await _pickDay(_end);
                if (d != null) {
                  setState(() => _end = DateTime.utc(d.year, d.month, d.day));
                }
              },
              child: Text('${s(RS.endDateField)}: ${ymd(_end)}'),
            ),
            TextField(
              key: const Key('rp-edit-hours'),
              controller: _hours,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: s(RS.hoursPerDayField)),
            ),
          ] else if (_strategy == RebalanceStrategy.shift)
            TextField(
              key: const Key('rp-edit-shift-days'),
              controller: _shiftDays,
              keyboardType: const TextInputType.numberWithOptions(signed: true),
              decoration: InputDecoration(labelText: s(RS.shiftDaysField)),
            )
          else if (_strategy == RebalanceStrategy.reassign) ...<Widget>[
            Text(s(RS.newEmployeeField)),
            _employeeDropdown(
              key: const Key('rp-edit-employee'),
              employees: employees,
              value: _newEmployeeId,
              onChanged: (String? v) => setState(() => _newEmployeeId = v),
            ),
          ] else ...<Widget>[
            OutlinedButton(
              key: const Key('rp-edit-split-date'),
              onPressed: () async {
                final DateTime? d = await _pickDay(_splitDate);
                if (d != null) {
                  setState(() => _splitDate = DateTime.utc(d.year, d.month, d.day));
                }
              },
              child: Text('${s(RS.splitDateField)}: ${ymd(_splitDate)}'),
            ),
            Text(s(RS.newEmployeeField)),
            _employeeDropdown(
              key: const Key('rp-edit-split-employee'),
              employees: employees,
              value: _splitEmployeeId,
              noneLabel: _a.employeeName,
              onChanged: (String? v) => setState(() => _splitEmployeeId = v),
            ),
          ],
          if (_issue != null)
            Padding(
              padding: const EdgeInsets.only(top: FfSpace.space3),
              child: Text(
                _issue!,
                key: const Key('rp-edit-issue'),
                style: TextStyle(color: c.danger),
              ),
            ),
          const SizedBox(height: FfSpace.space4),
          FilledButton(
            key: const Key('rp-edit-apply'),
            onPressed: _busy ? null : () => _apply(s),
            child: Text(s(RS.applyChange)),
          ),
          const SizedBox(height: FfSpace.space2),
          OutlinedButton.icon(
            key: const Key('rp-edit-delete'),
            onPressed: _busy ? null : () => _delete(s),
            icon: Icon(Icons.delete_outline, color: c.danger),
            label: Text(s(RS.deleteAction), style: TextStyle(color: c.danger)),
          ),
        ],
      ),
    );
  }
}
