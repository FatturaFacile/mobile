import 'package:material_ui/material_ui.dart';

import '../../../design/ff_tokens.dart';
import '../domain/baseline_variance.dart';
import '../domain/project_plan.dart';
import '../domain/project_portfolio_models.dart';
import '../l10n/project_portfolio_strings.dart';
import 'portfolio_ui.dart';
import 'project_portfolio_labels.dart';

/// Result of the node form: the edited (or new) values.
class NodeFormResult {
  const NodeFormResult({
    required this.title,
    required this.nodeType,
    required this.plannedHours,
    required this.actualHours,
    required this.plannedCost,
    required this.actualCost,
    required this.plannedRevenue,
    required this.percentComplete,
    this.startDate,
    this.endDate,
  });

  final String title;
  final WbsNodeType nodeType;
  final double plannedHours;
  final double actualHours;
  final double plannedCost;
  final double actualCost;
  final double plannedRevenue;
  final double percentComplete;
  final DateTime? startDate;
  final DateTime? endDate;
}

/// Bottom sheet to create ([node] null) or edit a WBS node. Figures of a summary node are rolled up from its
/// children, so their fields are read-only there.
Future<NodeFormResult?> showNodeForm(
  BuildContext context, {
  WbsNode? node,
  bool isSummary = false,
}) => showModalBottomSheet<NodeFormResult>(
  context: context,
  isScrollControlled: true,
  builder: (BuildContext _) => _NodeForm(node: node, isSummary: isSummary),
);

class _NodeForm extends StatefulWidget {
  const _NodeForm({required this.node, required this.isSummary});

  final WbsNode? node;
  final bool isSummary;

  @override
  State<_NodeForm> createState() => _NodeFormState();
}

class _NodeFormState extends State<_NodeForm> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _plannedHours;
  late final TextEditingController _actualHours;
  late final TextEditingController _plannedCost;
  late final TextEditingController _actualCost;
  late final TextEditingController _plannedRevenue;
  late final TextEditingController _progress;
  late WbsNodeType _type;
  DateTime? _start;
  DateTime? _end;

  @override
  void initState() {
    super.initState();
    final WbsNode? n = widget.node;
    _title = TextEditingController(text: n?.title ?? '');
    _plannedHours = _number(n?.plannedHours);
    _actualHours = _number(n?.actualHours);
    _plannedCost = _number(n?.plannedCost);
    _actualCost = _number(n?.actualCost);
    _plannedRevenue = _number(n?.plannedRevenue);
    _progress = _number(n?.percentComplete);
    _type = n?.nodeType ?? WbsNodeType.workPackage;
    _start = n?.startDate;
    _end = n?.endDate;
  }

  static TextEditingController _number(double? value) => TextEditingController(
    text: value == null || value == 0 ? '' : formatQuantity(value),
  );

  @override
  void dispose() {
    for (final TextEditingController c in <TextEditingController>[
      _title,
      _plannedHours,
      _actualHours,
      _plannedCost,
      _actualCost,
      _plannedRevenue,
      _progress,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pick(bool start) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: (start ? _start : _end) ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 15),
    );
    if (picked == null) {
      return;
    }
    final DateTime day = DateTime.utc(picked.year, picked.month, picked.day);
    setState(() {
      if (start) {
        _start = day;
        _end ??= day;
      } else {
        _end = day;
      }
    });
  }

  String? _optionalNumber(String? text, ProjectPortfolioStrings s) {
    if (text == null || text.trim().isEmpty) {
      return null;
    }
    final double? value = parseDecimal(text);
    return value == null || value < 0 ? s.t(PP.invalidNumber) : null;
  }

  double _read(TextEditingController c) => parseDecimal(c.text) ?? 0;

  void _submit() {
    if (!(_form.currentState?.validate() ?? false)) {
      return;
    }
    Navigator.of(context).pop(
      NodeFormResult(
        title: _title.text.trim(),
        nodeType: _type,
        plannedHours: _read(_plannedHours),
        actualHours: _read(_actualHours),
        plannedCost: _read(_plannedCost),
        actualCost: _read(_actualCost),
        plannedRevenue: _read(_plannedRevenue),
        percentComplete: _read(_progress),
        startDate: _start,
        endDate: _type == WbsNodeType.milestone ? _start : _end,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ProjectPortfolioStrings s = ProjectPortfolioStrings.of(context);
    final bool milestone = _type == WbsNodeType.milestone;
    final bool editing = widget.node != null;
    final bool figuresLocked = widget.isSummary;
    return Padding(
      padding: EdgeInsets.only(
        left: FfSpace.space4,
        right: FfSpace.space4,
        top: FfSpace.space4,
        bottom: MediaQuery.of(context).viewInsets.bottom + FfSpace.space4,
      ),
      child: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                editing ? s.t(PP.edit) : s.t(PP.addNode),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: FfSpace.space3),
              TextFormField(
                controller: _title,
                decoration: InputDecoration(labelText: s.t(PP.nodeTitle)),
                validator: (String? v) =>
                    (v ?? '').trim().isEmpty ? s.t(PP.required) : null,
              ),
              DropdownButtonFormField<WbsNodeType>(
                initialValue: _type,
                decoration: InputDecoration(labelText: s.t(PP.nodeType)),
                items: <DropdownMenuItem<WbsNodeType>>[
                  for (final WbsNodeType type in WbsNodeType.values)
                    DropdownMenuItem<WbsNodeType>(
                      value: type,
                      child: Text(s.nodeType(type)),
                    ),
                ],
                onChanged: (WbsNodeType? v) =>
                    setState(() => _type = v ?? _type),
              ),
              const SizedBox(height: FfSpace.space2),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pick(true),
                      child: Text(
                        '${s.t(PP.startDate)}: ${formatDate(context, _start)}',
                      ),
                    ),
                  ),
                  if (!milestone) ...<Widget>[
                    const SizedBox(width: FfSpace.space2),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _pick(false),
                        child: Text(
                          '${s.t(PP.endDate)}: ${formatDate(context, _end)}',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (!milestone && !figuresLocked)
                _field(_plannedHours, s.t(PP.plannedHours), s),
              if (!figuresLocked) ...<Widget>[
                _field(_plannedCost, s.t(PP.plannedCost), s),
                _field(_plannedRevenue, s.t(PP.plannedRevenue), s),
              ],
              if (editing && !figuresLocked) ...<Widget>[
                if (!milestone) _field(_actualHours, s.t(PP.actualHours), s),
                _field(_actualCost, s.t(PP.actualCost), s),
                TextFormField(
                  controller: _progress,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: '${s.t(PP.percentComplete)} (0-100)',
                  ),
                  validator: (String? v) {
                    final String? bad = _optionalNumber(v, s);
                    if (bad != null) {
                      return bad;
                    }
                    final double value = parseDecimal(v ?? '') ?? 0;
                    return value > 100 ? s.t(PP.errProgress) : null;
                  },
                ),
              ],
              const SizedBox(height: FfSpace.space4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(s.t(PP.cancel)),
                  ),
                  const SizedBox(width: FfSpace.space2),
                  FilledButton(onPressed: _submit, child: Text(s.t(PP.save))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    ProjectPortfolioStrings s,
  ) => TextFormField(
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(labelText: label),
    validator: (String? v) => _optionalNumber(v, s),
  );
}

/// The link chosen in the dependency form.
class DependencyFormResult {
  const DependencyFormResult({
    required this.predecessorNodeId,
    required this.successorNodeId,
    required this.type,
    required this.lagDays,
  });

  final String predecessorNodeId;
  final String successorNodeId;
  final DependencyType type;
  final int lagDays;
}

/// Bottom sheet to link two nodes of [plan]; [fixedNodeId] pre-selects the node the user came from as successor.
Future<DependencyFormResult?> showDependencyForm(
  BuildContext context,
  ProjectPlan plan, {
  String? fixedNodeId,
}) => showModalBottomSheet<DependencyFormResult>(
  context: context,
  isScrollControlled: true,
  builder: (BuildContext _) =>
      _DependencyForm(plan: plan, fixedNodeId: fixedNodeId),
);

class _DependencyForm extends StatefulWidget {
  const _DependencyForm({required this.plan, this.fixedNodeId});

  final ProjectPlan plan;
  final String? fixedNodeId;

  @override
  State<_DependencyForm> createState() => _DependencyFormState();
}

class _DependencyFormState extends State<_DependencyForm> {
  String? _predecessor;
  String? _successor;
  DependencyType _type = DependencyType.fs;
  final TextEditingController _lag = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    _successor = widget.fixedNodeId;
  }

  @override
  void dispose() {
    _lag.dispose();
    super.dispose();
  }

  List<DropdownMenuItem<String>> _items() => <DropdownMenuItem<String>>[
    for (final WbsNode n in widget.plan.nodes)
      DropdownMenuItem<String>(
        value: n.id,
        child: Text('${n.wbsCode} ${n.title}', overflow: TextOverflow.ellipsis),
      ),
  ];

  @override
  Widget build(BuildContext context) {
    final ProjectPortfolioStrings s = ProjectPortfolioStrings.of(context);
    final int? lag = int.tryParse(_lag.text.trim());
    final bool ready =
        _predecessor != null && _successor != null && lag != null;
    return Padding(
      padding: EdgeInsets.only(
        left: FfSpace.space4,
        right: FfSpace.space4,
        top: FfSpace.space4,
        bottom: MediaQuery.of(context).viewInsets.bottom + FfSpace.space4,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              s.t(PP.addDependency),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            DropdownButtonFormField<String>(
              initialValue: _predecessor,
              isExpanded: true,
              decoration: InputDecoration(labelText: s.t(PP.predecessor)),
              items: _items(),
              onChanged: (String? v) => setState(() => _predecessor = v),
            ),
            DropdownButtonFormField<String>(
              initialValue: _successor,
              isExpanded: true,
              decoration: InputDecoration(labelText: s.t(PP.successor)),
              items: _items(),
              onChanged: (String? v) => setState(() => _successor = v),
            ),
            DropdownButtonFormField<DependencyType>(
              initialValue: _type,
              decoration: InputDecoration(labelText: s.t(PP.dependencies)),
              items: <DropdownMenuItem<DependencyType>>[
                for (final DependencyType t in DependencyType.values)
                  DropdownMenuItem<DependencyType>(
                    value: t,
                    child: Text('${t.wire.toUpperCase()} · ${s.dependency(t)}'),
                  ),
              ],
              onChanged: (DependencyType? v) =>
                  setState(() => _type = v ?? _type),
            ),
            TextField(
              controller: _lag,
              keyboardType: const TextInputType.numberWithOptions(signed: true),
              decoration: InputDecoration(
                labelText: s.t(PP.lagDays),
                errorText: lag == null ? s.t(PP.invalidNumber) : null,
              ),
              onChanged: (String _) => setState(() {}),
            ),
            const SizedBox(height: FfSpace.space4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(s.t(PP.cancel)),
                ),
                const SizedBox(width: FfSpace.space2),
                FilledButton(
                  onPressed: ready
                      ? () => Navigator.of(context).pop(
                          DependencyFormResult(
                            predecessorNodeId: _predecessor!,
                            successorNodeId: _successor!,
                            type: _type,
                            lagDays: lag,
                          ),
                        )
                      : null,
                  child: Text(s.t(PP.save)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The CUP and CIG typed by the user (null clears the code).
class CodesFormResult {
  const CodesFormResult({this.cup, this.cig});

  final String? cup;
  final String? cig;
}

/// Dialog to edit the public-funding codes; it validates the format before it closes.
Future<CodesFormResult?> showCodesDialog(
  BuildContext context, {
  String? cup,
  String? cig,
}) => showDialog<CodesFormResult>(
  context: context,
  builder: (BuildContext _) => _CodesDialog(cup: cup, cig: cig),
);

class _CodesDialog extends StatefulWidget {
  const _CodesDialog({this.cup, this.cig});

  final String? cup;
  final String? cig;

  @override
  State<_CodesDialog> createState() => _CodesDialogState();
}

class _CodesDialogState extends State<_CodesDialog> {
  late final TextEditingController _cup = TextEditingController(
    text: widget.cup ?? '',
  );
  late final TextEditingController _cig = TextEditingController(
    text: widget.cig ?? '',
  );

  @override
  void dispose() {
    _cup.dispose();
    _cig.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ProjectPortfolioStrings s = ProjectPortfolioStrings.of(context);
    final bool cupOk = ProcurementCodes.isValidCup(_cup.text);
    final bool cigOk = ProcurementCodes.isValidCig(_cig.text);
    return AlertDialog(
      title: Text(s.t(PP.publicFunding)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            controller: _cup,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: s.t(PP.cupCode),
              errorText: cupOk ? null : s.t(PP.invalidCup),
            ),
            onChanged: (String _) => setState(() {}),
          ),
          TextField(
            controller: _cig,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: s.t(PP.cigCode),
              errorText: cigOk ? null : s.t(PP.invalidCig),
            ),
            onChanged: (String _) => setState(() {}),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(s.t(PP.cancel)),
        ),
        FilledButton(
          onPressed: cupOk && cigOk
              ? () => Navigator.of(context).pop(
                  CodesFormResult(
                    cup: ProcurementCodes.normalize(_cup.text),
                    cig: ProcurementCodes.normalize(_cig.text),
                  ),
                )
              : null,
          child: Text(s.t(PP.save)),
        ),
      ],
    );
  }
}

/// Asks for a name and returns it (empty when left blank); null when cancelled.
Future<String?> showNameDialog(
  BuildContext context, {
  required String title,
  required String label,
}) => showDialog<String>(
  context: context,
  builder: (BuildContext _) => _NameDialog(title: title, label: label),
);

class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.title, required this.label});

  final String title;
  final String label;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  final TextEditingController _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ProjectPortfolioStrings s = ProjectPortfolioStrings.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _name,
        decoration: InputDecoration(labelText: widget.label),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(s.t(PP.cancel)),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_name.text.trim()),
          child: Text(s.t(PP.save)),
        ),
      ],
    );
  }
}
