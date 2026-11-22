import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../design/ff_tokens.dart';
import '../domain/resource_planning_models.dart';
import 'resource_planning_controller.dart';
import 'resource_planning_strings.dart';
import 'resource_planning_ui.dart';

/// Opens a form in a scrollable bottom sheet that stays above the keyboard.
Future<void> _showFormSheet(BuildContext context, WidgetBuilder builder) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(FfSpace.space4),
          child: builder(ctx),
        ),
      ),
    );

/// Title, inline failure message and the save / cancel row shared by the setup forms.
class _SheetFrame extends StatelessWidget {
  const _SheetFrame({
    required this.title,
    required this.strings,
    required this.saveKey,
    required this.onSave,
    required this.children,
    this.issues = const <String>[],
    this.failure,
    this.saving = false,
  });

  final String title;
  final ResourcePlanningStrings strings;
  final Key saveKey;
  final VoidCallback onSave;
  final List<Widget> children;
  final List<String> issues;
  final String? failure;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    final FfColors c = rpColors(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: FfSpace.space3),
        ...children,
        for (final String issue in issues)
          Padding(
            padding: const EdgeInsets.only(top: FfSpace.space1),
            child: Text(issue, key: const Key('rp-sheet-issue'), style: TextStyle(color: c.danger)),
          ),
        if (failure != null)
          Padding(
            padding: const EdgeInsets.only(top: FfSpace.space1),
            child: Text(failure!, key: const Key('rp-sheet-error'), style: TextStyle(color: c.danger)),
          ),
        const SizedBox(height: FfSpace.space3),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            TextButton(
              key: const Key('rp-sheet-cancel'),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(strings(RS.cancelAction)),
            ),
            const SizedBox(width: FfSpace.space2),
            FilledButton(
              key: saveKey,
              onPressed: saving ? null : onSave,
              child: Text(strings(RS.saveAction)),
            ),
          ],
        ),
      ],
    );
  }
}

// --- Setup hub -------------------------------------------------------------------------------------------------

/// Entry list of the configuration screens: skills, employee skill profiles, utilization targets, local holidays.
class SetupTab extends ConsumerWidget {
  const SetupTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ResourcePlanningStrings s = rpStrings(ref);
    Widget entry(String key, IconData icon, String label, Widget page) => ListTile(
      key: Key(key),
      leading: Icon(icon),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push<void>(
        MaterialPageRoute<void>(builder: (BuildContext _) => page),
      ),
    );
    return ListView(
      children: <Widget>[
        entry('rp-setup-skills', Icons.psychology_outlined, s(RS.setupSkills), const SkillsPage()),
        entry('rp-setup-profiles', Icons.badge_outlined, s(RS.setupProfiles), const SkillProfilesPage()),
        entry('rp-setup-targets', Icons.flag_outlined, s(RS.setupTargets), const UtilizationTargetsPage()),
        entry('rp-setup-holidays', Icons.event_busy_outlined, s(RS.setupHolidays), const LocalHolidaysPage()),
      ],
    );
  }
}

// --- Skills ----------------------------------------------------------------------------------------------------

/// Skill taxonomy: list with create, edit and delete.
class SkillsPage extends ConsumerStatefulWidget {
  const SkillsPage({super.key});

  @override
  ConsumerState<SkillsPage> createState() => _SkillsPageState();
}

class _SkillsPageState extends ConsumerState<SkillsPage> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() => ref.read(skillsProvider.notifier).load());
  }

  Future<void> _delete(Skill skill, ResourcePlanningStrings s) async {
    final bool ok = await rpConfirm(
      context,
      s,
      title: s(RS.deleteAction),
      body: s(RS.deleteSkillBody, params: <String, Object>{'name': skill.skillName}),
    );
    if (!ok || !mounted) {
      return;
    }
    final PlanningOutcome outcome = await ref.read(skillsProvider.notifier).delete(skill);
    if (!mounted) {
      return;
    }
    rpSnack(
      context,
      outcome.ok ? s(RS.skillDeleted) : resourcePlanningErrorMessage(s, outcome.error!),
      messageKey: const Key('rp-action-message'),
    );
  }

  Future<void> _edit(Skill? skill) => _showFormSheet(
    context,
    (BuildContext _) => SkillForm(existing: skill),
  );

  @override
  Widget build(BuildContext context) {
    final ResourcePlanningStrings s = rpStrings(ref);
    final FfColors c = rpColors(context);
    final PlanningLoad<List<Skill>> state = ref.watch(skillsProvider);
    final List<Skill>? skills = state.data;
    return Scaffold(
      appBar: AppBar(title: Text(s(RS.setupSkills))),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('rp-skill-add'),
        onPressed: () => _edit(null),
        icon: const Icon(Icons.add),
        label: Text(s(RS.addSkill)),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(skillsProvider.notifier).load(),
        child: ListView(
          padding: const EdgeInsets.only(bottom: 88),
          children: <Widget>[
            if (state.error != null && skills == null)
              rpErrorBox(s, state.error!, () => ref.read(skillsProvider.notifier).load(), key: const Key('rp-skills-error'))
            else if (state.loading && skills == null)
              const Center(child: CircularProgressIndicator())
            else if (skills != null && skills.isEmpty)
              Padding(
                padding: const EdgeInsets.all(FfSpace.space5),
                child: Center(child: Text(s(RS.noSkills), key: const Key('rp-skills-empty'))),
              )
            else if (skills != null)
              for (final Skill k in skills)
                ListTile(
                  key: Key('rp-skill-${k.id}'),
                  title: Text(k.skillName),
                  subtitle: Text(
                    k.requiresCertification
                        ? '${k.category} - ${k.certificationCode ?? ''}'
                        : k.category,
                    style: TextStyle(color: c.textMuted),
                  ),
                  onTap: () => _edit(k),
                  trailing: IconButton(
                    key: Key('rp-skill-delete-${k.id}'),
                    icon: Icon(Icons.delete_outline, color: c.danger),
                    onPressed: () => _delete(k, s),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

/// Create or edit form of a skill.
class SkillForm extends ConsumerStatefulWidget {
  const SkillForm({this.existing, super.key});

  final Skill? existing;

  @override
  ConsumerState<SkillForm> createState() => _SkillFormState();
}

class _SkillFormState extends ConsumerState<SkillForm> {
  late final TextEditingController _category = TextEditingController(text: widget.existing?.category ?? '');
  late final TextEditingController _name = TextEditingController(text: widget.existing?.skillName ?? '');
  late final TextEditingController _code = TextEditingController(text: widget.existing?.certificationCode ?? '');
  late bool _requiresCertification = widget.existing?.requiresCertification ?? false;
  List<SkillDraftIssue> _issues = const <SkillDraftIssue>[];
  ResourcePlanningException? _failure;
  bool _saving = false;

  @override
  void dispose() {
    _category.dispose();
    _name.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _save(ResourcePlanningStrings s) async {
    final SkillDraft draft = SkillDraft(
      category: _category.text,
      skillName: _name.text,
      requiresCertification: _requiresCertification,
      certificationCode: _code.text,
    );
    final List<SkillDraftIssue> issues = draft.validate();
    setState(() {
      _issues = issues;
      _failure = null;
    });
    if (issues.isNotEmpty) {
      return;
    }
    setState(() => _saving = true);
    final PlanningOutcome outcome = await ref
        .read(skillsProvider.notifier)
        .save(draft, existing: widget.existing);
    if (!mounted) {
      return;
    }
    if (!outcome.ok) {
      setState(() {
        _saving = false;
        _failure = outcome.error;
      });
      return;
    }
    rpSnack(context, s(RS.skillSaved), messageKey: const Key('rp-action-message'));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final ResourcePlanningStrings s = rpStrings(ref);
    return _SheetFrame(
      title: widget.existing == null ? s(RS.addSkill) : s(RS.editSkill),
      strings: s,
      saveKey: const Key('rp-skill-save'),
      onSave: () => _save(s),
      saving: _saving,
      issues: <String>[for (final SkillDraftIssue i in _issues) skillIssueLabel(s, i)],
      failure: _failure == null ? null : resourcePlanningErrorMessage(s, _failure!),
      children: <Widget>[
        TextField(
          key: const Key('rp-skill-category'),
          controller: _category,
          decoration: InputDecoration(labelText: s(RS.skillCategoryField)),
        ),
        TextField(
          key: const Key('rp-skill-name'),
          controller: _name,
          decoration: InputDecoration(labelText: s(RS.skillNameField)),
        ),
        SwitchListTile(
          key: const Key('rp-skill-requires-cert'),
          contentPadding: EdgeInsets.zero,
          title: Text(s(RS.requiresCertificationField)),
          value: _requiresCertification,
          onChanged: (bool v) => setState(() => _requiresCertification = v),
        ),
        if (_requiresCertification)
          TextField(
            key: const Key('rp-skill-cert-code'),
            controller: _code,
            decoration: InputDecoration(labelText: s(RS.certificationCodeField)),
          ),
      ],
    );
  }
}

// --- Employee skill profiles -----------------------------------------------------------------------------------

/// Skill profile of one employee: proficiency per skill with the certificate verdict; upsert and delete.
class SkillProfilesPage extends ConsumerStatefulWidget {
  const SkillProfilesPage({this.initialEmployeeId, super.key});

  final String? initialEmployeeId;

  @override
  ConsumerState<SkillProfilesPage> createState() => _SkillProfilesPageState();
}

class _SkillProfilesPageState extends ConsumerState<SkillProfilesPage> {
  String? _employeeId;

  @override
  void initState() {
    super.initState();
    _employeeId = widget.initialEmployeeId;
    Future<void>.microtask(() {
      ref.read(resourcesProvider.notifier).load();
      ref.read(skillsProvider.notifier).load();
      final String? id = _employeeId;
      if (id != null) {
        ref.read(skillProfilesProvider.notifier).load(id);
      }
    });
  }

  void _choose(String? id) {
    setState(() => _employeeId = id);
    if (id != null) {
      ref.read(skillProfilesProvider.notifier).load(id);
    }
  }

  Future<void> _edit(EmployeeSkillProfile? profile) {
    final String? employee = _employeeId;
    if (employee == null) {
      return Future<void>.value();
    }
    return _showFormSheet(
      context,
      (BuildContext _) => SkillProfileForm(employeeId: employee, existing: profile),
    );
  }

  Future<void> _delete(EmployeeSkillProfile profile, ResourcePlanningStrings s) async {
    final bool ok = await rpConfirm(
      context,
      s,
      title: s(RS.deleteAction),
      body: s(RS.deleteProfileBody, params: <String, Object>{'name': profile.skillName}),
    );
    if (!ok || !mounted) {
      return;
    }
    final PlanningOutcome outcome = await ref.read(skillProfilesProvider.notifier).delete(profile);
    if (!mounted) {
      return;
    }
    rpSnack(
      context,
      outcome.ok ? s(RS.profileDeleted) : resourcePlanningErrorMessage(s, outcome.error!),
      messageKey: const Key('rp-action-message'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ResourcePlanningStrings s = rpStrings(ref);
    final FfColors c = rpColors(context);
    final List<ResourceLookup> employees = ref.watch(resourcesProvider).data ?? const <ResourceLookup>[];
    final PlanningLoad<List<EmployeeSkillProfile>> state = ref.watch(skillProfilesProvider);
    final List<EmployeeSkillProfile>? profiles = state.data;
    return Scaffold(
      appBar: AppBar(title: Text(s(RS.setupProfiles))),
      floatingActionButton: _employeeId == null
          ? null
          : FloatingActionButton.extended(
              key: const Key('rp-profile-add'),
              onPressed: () => _edit(null),
              icon: const Icon(Icons.add),
              label: Text(s(RS.addProfile)),
            ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(FfSpace.space4, FfSpace.space4, FfSpace.space4, 88),
        children: <Widget>[
          Text(s(RS.employeeField)),
          DropdownButton<String>(
            key: const Key('rp-profiles-employee'),
            isExpanded: true,
            value: employees.any((ResourceLookup e) => e.employeeId == _employeeId) ? _employeeId : null,
            items: <DropdownMenuItem<String>>[
              for (final ResourceLookup e in employees)
                DropdownMenuItem<String>(value: e.employeeId, child: Text(e.fullName)),
            ],
            onChanged: _choose,
          ),
          const SizedBox(height: FfSpace.space3),
          if (_employeeId == null)
            Text(s(RS.chooseEmployeeHint), key: const Key('rp-profiles-hint'), style: TextStyle(color: c.textMuted))
          else if (state.error != null && profiles == null)
            rpErrorBox(
              s,
              state.error!,
              () => ref.read(skillProfilesProvider.notifier).load(_employeeId!),
              key: const Key('rp-profiles-error'),
            )
          else if (state.loading && profiles == null)
            const Center(child: CircularProgressIndicator())
          else if (profiles != null && profiles.isEmpty)
            Padding(
              padding: const EdgeInsets.all(FfSpace.space5),
              child: Center(child: Text(s(RS.noProfiles), key: const Key('rp-profiles-empty'))),
            )
          else if (profiles != null)
            for (final EmployeeSkillProfile p in profiles)
              Card(
                key: Key('rp-profile-${p.id}'),
                child: ListTile(
                  title: Text('${p.skillName} - ${p.proficiencyLevel}/5'),
                  subtitle: Text(
                    <String>[
                      p.category,
                      if (p.validUntilDate != null) '${s(RS.validUntilField)} ${p.validUntilDate}',
                      if (p.requiresCertification) certificationStatusLabel(s, p.certificationStatus),
                    ].join(' - '),
                    style: TextStyle(color: p.certificationStatus.isBlocking || !p.isValid ? c.danger : c.textMuted),
                  ),
                  onTap: () => _edit(p),
                  trailing: IconButton(
                    key: Key('rp-profile-delete-${p.id}'),
                    icon: Icon(Icons.delete_outline, color: c.danger),
                    onPressed: () => _delete(p, s),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

/// Upsert form of an employee skill profile.
class SkillProfileForm extends ConsumerStatefulWidget {
  const SkillProfileForm({required this.employeeId, this.existing, super.key});

  final String employeeId;
  final EmployeeSkillProfile? existing;

  @override
  ConsumerState<SkillProfileForm> createState() => _SkillProfileFormState();
}

class _SkillProfileFormState extends ConsumerState<SkillProfileForm> {
  late String? _skillId = widget.existing?.skillId;
  late int _level = widget.existing?.proficiencyLevel ?? 3;
  late String? _validUntil = widget.existing?.validUntilDate;
  List<SkillProfileDraftIssue> _issues = const <SkillProfileDraftIssue>[];
  ResourcePlanningException? _failure;
  bool _saving = false;

  Future<void> _pickDate() async {
    final DateTime now = ref.read(resourcePlanningClockProvider)();
    final DateTime initial = DateTime.tryParse(_validUntil ?? '') ?? now;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.utc(now.year - 5),
      lastDate: DateTime.utc(now.year + 20),
    );
    if (picked != null) {
      setState(() => _validUntil = ymd(picked));
    }
  }

  Future<void> _save(ResourcePlanningStrings s) async {
    final SkillProfileDraft draft = SkillProfileDraft(
      employeeId: widget.employeeId,
      skillId: _skillId ?? '',
      proficiencyLevel: _level,
      validUntilDate: _validUntil,
    );
    final List<SkillProfileDraftIssue> issues = draft.validate();
    setState(() {
      _issues = issues;
      _failure = null;
    });
    if (issues.isNotEmpty) {
      return;
    }
    setState(() => _saving = true);
    final PlanningOutcome outcome = await ref.read(skillProfilesProvider.notifier).save(draft);
    if (!mounted) {
      return;
    }
    if (!outcome.ok) {
      setState(() {
        _saving = false;
        _failure = outcome.error;
      });
      return;
    }
    rpSnack(context, s(RS.profileSaved), messageKey: const Key('rp-action-message'));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final ResourcePlanningStrings s = rpStrings(ref);
    final List<Skill> skills = ref.watch(skillsProvider).data ?? const <Skill>[];
    return _SheetFrame(
      title: s(RS.addProfile),
      strings: s,
      saveKey: const Key('rp-profile-save'),
      onSave: () => _save(s),
      saving: _saving,
      issues: <String>[for (final SkillProfileDraftIssue i in _issues) profileIssueLabel(s, i)],
      failure: _failure == null ? null : resourcePlanningErrorMessage(s, _failure!),
      children: <Widget>[
        Text(s(RS.skillField)),
        DropdownButton<String>(
          key: const Key('rp-profile-skill'),
          isExpanded: true,
          value: skills.any((Skill k) => k.id == _skillId) ? _skillId : null,
          items: <DropdownMenuItem<String>>[
            for (final Skill k in skills)
              DropdownMenuItem<String>(value: k.id, child: Text('${k.category} / ${k.skillName}')),
          ],
          onChanged: (String? v) => setState(() => _skillId = v),
        ),
        Text(s(RS.proficiencyField)),
        DropdownButton<int>(
          key: const Key('rp-profile-level'),
          isExpanded: true,
          value: _level,
          items: <DropdownMenuItem<int>>[
            for (int l = minProficiencyLevel; l <= maxProficiencyLevel; l++)
              DropdownMenuItem<int>(value: l, child: Text('$l')),
          ],
          onChanged: (int? v) => setState(() => _level = v ?? _level),
        ),
        Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton(
                key: const Key('rp-profile-valid-until'),
                onPressed: _pickDate,
                child: Text('${s(RS.validUntilField)}: ${_validUntil ?? s(RS.noExpiry)}'),
              ),
            ),
            if (_validUntil != null)
              IconButton(
                key: const Key('rp-profile-valid-clear'),
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _validUntil = null),
              ),
          ],
        ),
      ],
    );
  }
}

// --- Utilization targets ---------------------------------------------------------------------------------------

/// Scope of a utilization target in the editor.
enum TargetScope { tenant, department, costCenter }

/// Utilization targets: the tenant default plus one per department or cost center, upserted from an editor.
class UtilizationTargetsPage extends ConsumerStatefulWidget {
  const UtilizationTargetsPage({super.key});

  @override
  ConsumerState<UtilizationTargetsPage> createState() => _UtilizationTargetsPageState();
}

class _UtilizationTargetsPageState extends ConsumerState<UtilizationTargetsPage> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() {
      ref.read(utilizationTargetsProvider.notifier).load();
      ref.read(resourcesProvider.notifier).load();
    });
  }

  String _scopeName(ResourcePlanningStrings s, UtilizationTarget t, List<ResourceLookup> resources) {
    if (t.isDefault) {
      return s(RS.scopeDefault);
    }
    if (t.departmentId != null) {
      final String name = resources
          .firstWhere(
            (ResourceLookup r) => r.departmentId == t.departmentId,
            orElse: () => ResourceLookup(employeeId: '', fullName: '', departmentName: t.departmentId),
          )
          .departmentName ?? t.departmentId!;
      return '${s(RS.scopeDepartment)}: $name';
    }
    final String name = resources
        .firstWhere(
          (ResourceLookup r) => r.costCenterId == t.costCenterId,
          orElse: () => ResourceLookup(employeeId: '', fullName: '', costCenterName: t.costCenterId),
        )
        .costCenterName ?? t.costCenterId!;
    return '${s(RS.scopeCostCenter)}: $name';
  }

  Future<void> _edit(UtilizationTarget? target) => _showFormSheet(
    context,
    (BuildContext _) => UtilizationTargetForm(existing: target),
  );

  @override
  Widget build(BuildContext context) {
    final ResourcePlanningStrings s = rpStrings(ref);
    final PlanningLoad<List<UtilizationTarget>> state = ref.watch(utilizationTargetsProvider);
    final List<UtilizationTarget>? targets = state.data;
    final List<ResourceLookup> resources = ref.watch(resourcesProvider).data ?? const <ResourceLookup>[];
    return Scaffold(
      appBar: AppBar(title: Text(s(RS.setupTargets))),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('rp-target-add'),
        onPressed: () => _edit(null),
        icon: const Icon(Icons.add),
        label: Text(s(RS.addTarget)),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(utilizationTargetsProvider.notifier).load(),
        child: ListView(
          padding: const EdgeInsets.only(bottom: 88),
          children: <Widget>[
            if (state.error != null && targets == null)
              rpErrorBox(
                s,
                state.error!,
                () => ref.read(utilizationTargetsProvider.notifier).load(),
                key: const Key('rp-targets-error'),
              )
            else if (state.loading && targets == null)
              const Center(child: CircularProgressIndicator())
            else if (targets != null && targets.isEmpty)
              Padding(
                padding: const EdgeInsets.all(FfSpace.space5),
                child: Center(child: Text(s(RS.noTargets), key: const Key('rp-targets-empty'))),
              )
            else if (targets != null)
              for (final UtilizationTarget t in targets)
                ListTile(
                  key: Key('rp-target-${t.id}'),
                  title: Text(_scopeName(s, t, resources)),
                  trailing: Text(rpPercent(t.targetPercent)),
                  onTap: () => _edit(t),
                ),
          ],
        ),
      ),
    );
  }
}

/// Editor of a utilization target; the scope decides which department or cost center the value applies to.
class UtilizationTargetForm extends ConsumerStatefulWidget {
  const UtilizationTargetForm({this.existing, super.key});

  final UtilizationTarget? existing;

  @override
  ConsumerState<UtilizationTargetForm> createState() => _UtilizationTargetFormState();
}

class _UtilizationTargetFormState extends ConsumerState<UtilizationTargetForm> {
  late TargetScope _scope = widget.existing == null || widget.existing!.isDefault
      ? TargetScope.tenant
      : widget.existing!.departmentId != null
      ? TargetScope.department
      : TargetScope.costCenter;
  late String? _departmentId = widget.existing?.departmentId;
  late String? _costCenterId = widget.existing?.costCenterId;
  late final TextEditingController _percent = TextEditingController(
    text: widget.existing == null ? '' : rpHours(widget.existing!.targetPercent),
  );
  String? _issue;
  ResourcePlanningException? _failure;
  bool _saving = false;

  @override
  void dispose() {
    _percent.dispose();
    super.dispose();
  }

  Future<void> _save(ResourcePlanningStrings s) async {
    final double? percent = parseDecimal(_percent.text);
    final String? department = _scope == TargetScope.department ? _departmentId : null;
    final String? costCenter = _scope == TargetScope.costCenter ? _costCenterId : null;
    String? issue;
    if (percent == null || percent < 0 || percent > 100) {
      issue = s(RS.issueTargetPercent);
    } else if ((_scope == TargetScope.department && department == null) ||
        (_scope == TargetScope.costCenter && costCenter == null)) {
      issue = s(RS.issueScopeRequired);
    }
    setState(() {
      _issue = issue;
      _failure = null;
    });
    if (issue != null) {
      return;
    }
    final UtilizationTargetDraft draft = UtilizationTargetDraft(
      targetPercent: percent!,
      departmentId: department,
      costCenterId: costCenter,
    );
    setState(() => _saving = true);
    final PlanningOutcome outcome = await ref.read(utilizationTargetsProvider.notifier).save(draft);
    if (!mounted) {
      return;
    }
    if (!outcome.ok) {
      setState(() {
        _saving = false;
        _failure = outcome.error;
      });
      return;
    }
    rpSnack(context, s(RS.targetSaved), messageKey: const Key('rp-action-message'));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final ResourcePlanningStrings s = rpStrings(ref);
    final List<ResourceLookup> resources = ref.watch(resourcesProvider).data ?? const <ResourceLookup>[];
    final Map<String, String> departments = <String, String>{
      for (final ResourceLookup r in resources)
        if (r.departmentId != null) r.departmentId!: r.departmentName ?? r.departmentId!,
    };
    final Map<String, String> costCenters = <String, String>{
      for (final ResourceLookup r in resources)
        if (r.costCenterId != null) r.costCenterId!: r.costCenterName ?? r.costCenterId!,
    };
    return _SheetFrame(
      title: s(RS.addTarget),
      strings: s,
      saveKey: const Key('rp-target-save'),
      onSave: () => _save(s),
      saving: _saving,
      issues: <String>[?_issue],
      failure: _failure == null ? null : resourcePlanningErrorMessage(s, _failure!),
      children: <Widget>[
        SegmentedButton<TargetScope>(
          key: const Key('rp-target-scope'),
          segments: <ButtonSegment<TargetScope>>[
            ButtonSegment<TargetScope>(value: TargetScope.tenant, label: Text(s(RS.scopeDefault))),
            ButtonSegment<TargetScope>(value: TargetScope.department, label: Text(s(RS.scopeDepartment))),
            ButtonSegment<TargetScope>(value: TargetScope.costCenter, label: Text(s(RS.scopeCostCenter))),
          ],
          selected: <TargetScope>{_scope},
          onSelectionChanged: (Set<TargetScope> v) => setState(() => _scope = v.first),
        ),
        if (_scope == TargetScope.department)
          DropdownButton<String>(
            key: const Key('rp-target-department'),
            isExpanded: true,
            hint: Text(s(RS.departmentField)),
            value: departments.containsKey(_departmentId) ? _departmentId : null,
            items: <DropdownMenuItem<String>>[
              for (final MapEntry<String, String> d in departments.entries)
                DropdownMenuItem<String>(value: d.key, child: Text(d.value)),
            ],
            onChanged: (String? v) => setState(() => _departmentId = v),
          ),
        if (_scope == TargetScope.costCenter)
          DropdownButton<String>(
            key: const Key('rp-target-cost-center'),
            isExpanded: true,
            hint: Text(s(RS.costCenterField)),
            value: costCenters.containsKey(_costCenterId) ? _costCenterId : null,
            items: <DropdownMenuItem<String>>[
              for (final MapEntry<String, String> c in costCenters.entries)
                DropdownMenuItem<String>(value: c.key, child: Text(c.value)),
            ],
            onChanged: (String? v) => setState(() => _costCenterId = v),
          ),
        TextField(
          key: const Key('rp-target-percent'),
          controller: _percent,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: s(RS.targetPercentField)),
        ),
      ],
    );
  }
}

// --- Local holidays --------------------------------------------------------------------------------------------

/// Tenant local holidays: list, add and remove.
class LocalHolidaysPage extends ConsumerStatefulWidget {
  const LocalHolidaysPage({super.key});

  @override
  ConsumerState<LocalHolidaysPage> createState() => _LocalHolidaysPageState();
}

class _LocalHolidaysPageState extends ConsumerState<LocalHolidaysPage> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() => ref.read(localHolidaysProvider.notifier).load());
  }

  Future<void> _remove(LocalHoliday holiday, ResourcePlanningStrings s) async {
    final bool ok = await rpConfirm(
      context,
      s,
      title: s(RS.deleteAction),
      body: s(RS.deleteHolidayBody, params: <String, Object>{'name': holiday.name}),
    );
    if (!ok || !mounted) {
      return;
    }
    final PlanningOutcome outcome = await ref.read(localHolidaysProvider.notifier).remove(holiday);
    if (!mounted) {
      return;
    }
    rpSnack(
      context,
      outcome.ok ? s(RS.holidayRemoved) : resourcePlanningErrorMessage(s, outcome.error!),
      messageKey: const Key('rp-action-message'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ResourcePlanningStrings s = rpStrings(ref);
    final FfColors c = rpColors(context);
    final PlanningLoad<List<LocalHoliday>> state = ref.watch(localHolidaysProvider);
    final List<LocalHoliday>? holidays = state.data;
    return Scaffold(
      appBar: AppBar(title: Text(s(RS.setupHolidays))),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('rp-holiday-add'),
        onPressed: () => _showFormSheet(context, (BuildContext _) => const LocalHolidayForm()),
        icon: const Icon(Icons.add),
        label: Text(s(RS.addHoliday)),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(localHolidaysProvider.notifier).load(),
        child: ListView(
          padding: const EdgeInsets.only(bottom: 88),
          children: <Widget>[
            if (state.error != null && holidays == null)
              rpErrorBox(
                s,
                state.error!,
                () => ref.read(localHolidaysProvider.notifier).load(),
                key: const Key('rp-holidays-error'),
              )
            else if (state.loading && holidays == null)
              const Center(child: CircularProgressIndicator())
            else if (holidays != null && holidays.isEmpty)
              Padding(
                padding: const EdgeInsets.all(FfSpace.space5),
                child: Center(child: Text(s(RS.noHolidays), key: const Key('rp-holidays-empty'))),
              )
            else if (holidays != null)
              for (final LocalHoliday h in holidays)
                ListTile(
                  key: Key('rp-holiday-${h.id}'),
                  title: Text(h.name),
                  subtitle: Text(
                    <String>[
                      h.dateLabel,
                      if (h.year == null) s(RS.yearlyHoliday),
                      h.country,
                      ?h.regionCode,
                      ?h.municipality,
                      if (h.dayFraction < 1) s(RS.halfDayField),
                    ].join(' - '),
                    style: TextStyle(color: c.textMuted),
                  ),
                  trailing: IconButton(
                    key: Key('rp-holiday-delete-${h.id}'),
                    icon: Icon(Icons.delete_outline, color: c.danger),
                    onPressed: () => _remove(h, s),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

/// Add form of a local holiday.
class LocalHolidayForm extends ConsumerStatefulWidget {
  const LocalHolidayForm({super.key});

  @override
  ConsumerState<LocalHolidayForm> createState() => _LocalHolidayFormState();
}

class _LocalHolidayFormState extends ConsumerState<LocalHolidayForm> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _region = TextEditingController();
  final TextEditingController _municipality = TextEditingController();
  final TextEditingController _day = TextEditingController();
  final TextEditingController _year = TextEditingController();
  String _country = holidayCountries.first;
  int _month = 1;
  bool _halfDay = false;
  List<String> _issues = const <String>[];
  ResourcePlanningException? _failure;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _region.dispose();
    _municipality.dispose();
    _day.dispose();
    _year.dispose();
    super.dispose();
  }

  Future<void> _save(ResourcePlanningStrings s) async {
    final int? day = int.tryParse(_day.text.trim());
    final String yearText = _year.text.trim();
    final int? year = yearText.isEmpty ? null : int.tryParse(yearText);
    final LocalHolidayDraft draft = LocalHolidayDraft(
      country: _country,
      regionCode: _region.text,
      municipality: _municipality.text,
      month: _month,
      day: day ?? 0,
      year: year,
      name: _name.text,
      dayFraction: _halfDay ? 0.5 : 1,
    );
    final List<String> issues = <String>[
      for (final LocalHolidayDraftIssue i in draft.validate()) holidayIssueLabel(s, i),
      if (yearText.isNotEmpty && year == null) s(RS.issueHolidayDate),
    ];
    setState(() {
      _issues = issues;
      _failure = null;
    });
    if (issues.isNotEmpty) {
      return;
    }
    setState(() => _saving = true);
    final PlanningOutcome outcome = await ref.read(localHolidaysProvider.notifier).add(draft);
    if (!mounted) {
      return;
    }
    if (!outcome.ok) {
      setState(() {
        _saving = false;
        _failure = outcome.error;
      });
      return;
    }
    rpSnack(context, s(RS.holidayAdded), messageKey: const Key('rp-action-message'));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final ResourcePlanningStrings s = rpStrings(ref);
    return _SheetFrame(
      title: s(RS.addHoliday),
      strings: s,
      saveKey: const Key('rp-holiday-save'),
      onSave: () => _save(s),
      saving: _saving,
      issues: _issues,
      failure: _failure == null ? null : resourcePlanningErrorMessage(s, _failure!),
      children: <Widget>[
        TextField(
          key: const Key('rp-holiday-name'),
          controller: _name,
          decoration: InputDecoration(labelText: s(RS.holidayNameField)),
        ),
        Text(s(RS.countryField)),
        DropdownButton<String>(
          key: const Key('rp-holiday-country'),
          isExpanded: true,
          value: _country,
          items: <DropdownMenuItem<String>>[
            for (final String c in holidayCountries) DropdownMenuItem<String>(value: c, child: Text(c)),
          ],
          onChanged: (String? v) => setState(() => _country = v ?? _country),
        ),
        TextField(
          key: const Key('rp-holiday-region'),
          controller: _region,
          decoration: InputDecoration(labelText: s(RS.regionField)),
        ),
        TextField(
          key: const Key('rp-holiday-municipality'),
          controller: _municipality,
          decoration: InputDecoration(labelText: s(RS.municipalityField)),
        ),
        Text(s(RS.monthField)),
        DropdownButton<int>(
          key: const Key('rp-holiday-month'),
          isExpanded: true,
          value: _month,
          items: <DropdownMenuItem<int>>[
            for (int m = 1; m <= 12; m++) DropdownMenuItem<int>(value: m, child: Text('$m')),
          ],
          onChanged: (int? v) => setState(() => _month = v ?? _month),
        ),
        TextField(
          key: const Key('rp-holiday-day'),
          controller: _day,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: s(RS.dayField)),
        ),
        TextField(
          key: const Key('rp-holiday-year'),
          controller: _year,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: s(RS.yearField)),
        ),
        SwitchListTile(
          key: const Key('rp-holiday-half'),
          contentPadding: EdgeInsets.zero,
          title: Text(s(RS.halfDayField)),
          value: _halfDay,
          onChanged: (bool v) => setState(() => _halfDay = v),
        ),
      ],
    );
  }
}
