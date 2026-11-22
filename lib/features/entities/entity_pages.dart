import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../core/database/app_database.dart';
import '../../core/localization/translation_service.dart';
import '../../core/sync/sync_engine.dart';
import '../../core/sync/sync_orchestrator.dart';
import '../copilot/domain/copilot_models.dart';
import 'entity_definition.dart';

Map<String, dynamic> _payload(EntityRecord r) =>
    jsonDecode(r.payload) as Map<String, dynamic>;

/// Offline list of one resource: reads only from SQLite, writes go through the outbox.
class EntityListPage extends ConsumerStatefulWidget {
  const EntityListPage({
    required this.def,
    required this.tenantId,
    required this.userId,
    required this.syncEntities,
    super.key,
  });

  final EntityDef def;
  final String tenantId;
  final String userId;
  final List<String> syncEntities;

  @override
  ConsumerState<EntityListPage> createState() => _EntityListPageState();
}

class _EntityListPageState extends ConsumerState<EntityListPage> {
  String _query = '';

  Future<void> _open({EntityRecord? record}) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: RouteSettings(
          name:
              '/${widget.def.entity}${record == null ? '' : '/${record.serverId ?? record.id}'}',
          arguments: CopilotContext(
            route: '/${widget.def.entity}',
            entityType: widget.def.entity,
            entityId: record == null ? null : (record.serverId ?? record.id),
          ),
        ),
        builder: (_) => EntityFormPage(
          def: widget.def,
          tenantId: widget.tenantId,
          userId: widget.userId,
          record: record,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TranslationService t = ref.watch(translationProvider);
    final SyncEngine engine = ref.watch(syncEngineProvider);
    final EntityDef def = widget.def;
    return Scaffold(
      appBar: AppBar(title: Text(t.t('mobile.entity.${def.entity}'))),
      floatingActionButton: def.canCreate
          ? FloatingActionButton(
              key: const Key('entity-add'),
              tooltip: t.t('mobile.common.add'),
              onPressed: () => _open(),
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              key: const Key('entity-search'),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: t.t('mobile.common.search'),
              ),
              onChanged: (String v) =>
                  setState(() => _query = v.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<EntityRecord>>(
              stream: engine.watch(widget.tenantId, def.entity),
              builder:
                  (
                    BuildContext context,
                    AsyncSnapshot<List<EntityRecord>> snap,
                  ) {
                    final List<EntityRecord> rows =
                        (snap.data ?? <EntityRecord>[]).where((EntityRecord r) {
                          return _query.isEmpty ||
                              def
                                  .title(_payload(r))
                                  .toLowerCase()
                                  .contains(_query);
                        }).toList()..sort(
                          (EntityRecord a, EntityRecord b) =>
                              b.updatedAt.compareTo(a.updatedAt),
                        );
                    if (rows.isEmpty) {
                      return Center(
                        child: Text(
                          t.t('mobile.common.empty'),
                          key: const Key('entity-empty'),
                        ),
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () => ref
                          .read(syncOrchestratorProvider)
                          .run(widget.tenantId, widget.syncEntities),
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: rows.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (BuildContext context, int i) =>
                            _tile(context, t, engine, rows[i]),
                      ),
                    );
                  },
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    TranslationService t,
    SyncEngine engine,
    EntityRecord r,
  ) {
    final EntityDef def = widget.def;
    final Map<String, dynamic> data = _payload(r);
    final String? subtitle = def.subtitle?.call(data);
    final Widget tile = ListTile(
      key: Key('record-${r.id}'),
      title: Text(def.title(data)),
      subtitle: subtitle == null || subtitle.isEmpty ? null : Text(subtitle),
      trailing: switch (r.syncStatus) {
        SyncStatus.synced => null,
        SyncStatus.conflict => Tooltip(
          message: t.t('mobile.common.conflict'),
          child: const Icon(Icons.warning_amber_outlined),
        ),
        _ => Tooltip(
          message: t.t('mobile.common.pending'),
          child: const Icon(Icons.cloud_upload_outlined),
        ),
      },
      onTap: def.canEdit
          ? () => _open(record: r)
          : () => _showDetail(context, t, data),
    );
    if (!def.canDelete) {
      return tile;
    }
    return Dismissible(
      key: ValueKey<String>('dismiss-${r.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Theme.of(context).colorScheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_outline),
      ),
      onDismissed: (_) => engine.delete(
        tenantId: widget.tenantId,
        entity: def.entity,
        id: r.id,
        path: def.writePath,
      ),
      child: tile,
    );
  }

  void _showDetail(
    BuildContext context,
    TranslationService t,
    Map<String, dynamic> data,
  ) {
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(widget.def.title(data)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            for (final FieldDef f in widget.def.fields)
              if (data[f.key] != null)
                Text('${t.t('mobile.field.${f.key}')}: ${data[f.key]}'),
          ],
        ),
        actions: <Widget>[
          if (widget.def.entity == 'payslip_documents')
            TextButton(
              key: const Key('payslip-read'),
              onPressed: () {
                ref
                    .read(syncEngineProvider)
                    .enqueueCommand(
                      tenantId: widget.tenantId,
                      entity: 'payslip_read_receipts',
                      path: '/mobile/payslips/${data['id']}/read-receipt',
                    );
                Navigator.of(ctx).pop();
              },
              child: Text(t.t('mobile.payslip.markRead')),
            ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(t.t('mobile.common.close')),
          ),
        ],
      ),
    );
  }
}

/// Create / edit form generated from the [EntityDef]; saving never waits for the network.
class EntityFormPage extends ConsumerStatefulWidget {
  const EntityFormPage({
    required this.def,
    required this.tenantId,
    required this.userId,
    this.record,
    super.key,
  });

  final EntityDef def;
  final String tenantId;
  final String userId;
  final EntityRecord? record;

  @override
  ConsumerState<EntityFormPage> createState() => _EntityFormPageState();
}

class _EntityFormPageState extends ConsumerState<EntityFormPage> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _controllers;
  final Map<String, String?> _relations = <String, String?>{};

  @override
  void initState() {
    super.initState();
    final Map<String, dynamic> existing = widget.record == null
        ? <String, dynamic>{}
        : _payload(widget.record!);
    _controllers = <String, TextEditingController>{
      for (final FieldDef f in widget.def.fields)
        f.key: TextEditingController(
          text: '${existing[f.key] ?? f.defaultValue ?? ''}',
        ),
    };
    for (final FieldDef f in widget.def.fields.where(
      (FieldDef f) => f.kind == FieldKind.relation,
    )) {
      _relations[f.key] = existing[f.key] as String?;
    }
  }

  @override
  void dispose() {
    for (final TextEditingController c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, dynamic> _values() {
    final Map<String, dynamic> values = <String, dynamic>{};
    for (final FieldDef f in widget.def.fields) {
      if (f.kind == FieldKind.relation) {
        if (_relations[f.key] != null) {
          values[f.key] = _relations[f.key];
        }
        continue;
      }
      final String raw = _controllers[f.key]!.text.trim();
      if (raw.isEmpty) {
        continue;
      }
      values[f.key] = f.kind == FieldKind.number
          ? (num.tryParse(raw.replaceAll(',', '.')) ?? raw)
          : raw;
    }
    return widget.def.toBody?.call(values) ?? values;
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) {
      return;
    }
    final SyncEngine engine = ref.read(syncEngineProvider);
    final Map<String, dynamic> body = _values();
    if (widget.record == null) {
      await engine.create(
        tenantId: widget.tenantId,
        entity: widget.def.entity,
        path: widget.def.writePath,
        data: body,
        userId: widget.userId,
      );
    } else {
      await engine.update(
        tenantId: widget.tenantId,
        entity: widget.def.entity,
        id: widget.record!.id,
        path: widget.def.writePath,
        changes: body,
        userId: widget.userId,
      );
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _pick(FieldDef f) async {
    final DateTime now = DateTime.now();
    final DateTime? day = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (day == null || !mounted) {
      return;
    }
    if (f.kind == FieldKind.date) {
      _controllers[f.key]!.text = day.toIso8601String().substring(0, 10);
      return;
    }
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
    );
    if (time == null) {
      return;
    }
    _controllers[f.key]!.text = DateTime(
      day.year,
      day.month,
      day.day,
      time.hour,
      time.minute,
    ).toIso8601String();
  }

  @override
  Widget build(BuildContext context) {
    final TranslationService t = ref.watch(translationProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(t.t('mobile.entity.${widget.def.entity}')),
        actions: <Widget>[
          TextButton(
            key: const Key('entity-save'),
            onPressed: _save,
            child: Text(t.t('mobile.common.save')),
          ),
        ],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            for (final FieldDef f in widget.def.fields) ...<Widget>[
              _field(t, f),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }

  Widget _field(TranslationService t, FieldDef f) {
    final String label = t.t('mobile.field.${f.key}');
    String? validate(String? v) => f.required && (v == null || v.trim().isEmpty)
        ? t.t('mobile.common.required')
        : null;
    if (f.kind == FieldKind.relation) {
      return _RelationField(
        key: Key('field-${f.key}'),
        label: label,
        entity: f.relatedEntity!,
        tenantId: widget.tenantId,
        value: _relations[f.key],
        required: f.required,
        requiredMessage: t.t('mobile.common.required'),
        onChanged: (String? v) => _relations[f.key] = v,
      );
    }
    final bool picker =
        f.kind == FieldKind.date || f.kind == FieldKind.dateTime;
    return TextFormField(
      key: Key('field-${f.key}'),
      controller: _controllers[f.key],
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: picker ? const Icon(Icons.event) : null,
      ),
      readOnly: picker,
      onTap: picker ? () => _pick(f) : null,
      maxLines: f.kind == FieldKind.multiline ? 4 : 1,
      keyboardType: f.kind == FieldKind.number
          ? const TextInputType.numberWithOptions(decimal: true)
          : null,
      validator: validate,
    );
  }
}

class _RelationField extends ConsumerWidget {
  const _RelationField({
    required this.label,
    required this.entity,
    required this.tenantId,
    required this.value,
    required this.required,
    required this.requiredMessage,
    required this.onChanged,
    super.key,
  });

  final String label;
  final String entity;
  final String tenantId;
  final String? value;
  final bool required;
  final String requiredMessage;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<List<EntityRecord>>(
      stream: ref.watch(syncEngineProvider).watch(tenantId, entity),
      builder: (BuildContext context, AsyncSnapshot<List<EntityRecord>> snap) {
        final List<EntityRecord> rows = snap.data ?? <EntityRecord>[];
        final EntityDef? related = entityDefinitions[entity];
        return DropdownButtonFormField<String>(
          initialValue: rows.any((EntityRecord r) => r.id == value)
              ? value
              : null,
          decoration: InputDecoration(labelText: label),
          items: <DropdownMenuItem<String>>[
            for (final EntityRecord r in rows)
              DropdownMenuItem<String>(
                value: r.id,
                child: Text(
                  related?.title(_payload(r)) ?? r.id,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: onChanged,
          validator: (String? v) =>
              required && v == null ? requiredMessage : null,
        );
      },
    );
  }
}
