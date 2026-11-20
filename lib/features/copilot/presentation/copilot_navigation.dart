import 'package:flutter/widgets.dart';
import 'package:drift/drift.dart' show BooleanExpressionOperators;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../app/session_controller.dart';
import '../../../core/database/app_database.dart';
import '../../entities/entity_definition.dart';
import '../../entities/entity_pages.dart';
import '../domain/copilot_models.dart';

/// Resolves an entity citation to an in-app page, or `null` when the app has no screen for it.
/// Opens the record form when the record is in the offline store, else the entity list.
Future<Widget?> resolveCitationPage(WidgetRef ref, Citation c) async {
  final SessionState? session = ref.read(sessionProvider).value;
  if (session is! SignedIn) return null;
  final String? key = _entityKey(c);
  if (key == null) return null;
  final EntityDef def = entityDefinitions[key]!;
  final String tenant = session.bootstrap.tenantId;
  final String userId = session.bootstrap.userId;
  final String? id = c.entityId;
  if (id != null && id.isNotEmpty) {
    final AppDatabase db = ref.read(databaseProvider);
    final List<EntityRecord> rows =
        await (db.select(db.entityRecords)
              ..where(
                ($EntityRecordsTable t) =>
                    t.tenantId.equals(tenant) &
                    t.entity.equals(key) &
                    (t.id.equals(id) | t.serverId.equals(id)),
              )
              ..limit(1))
            .get();
    if (rows.isNotEmpty)
      return EntityFormPage(
        def: def,
        tenantId: tenant,
        userId: userId,
        record: rows.first,
      );
  }
  return EntityListPage(
    def: def,
    tenantId: tenant,
    userId: userId,
    syncEntities: session.bootstrap.syncEntities,
  );
}

/// Maps `entity_type` (or the first segment of `route`) to a key of [entityDefinitions].
String? _entityKey(Citation c) {
  final List<String> candidates = <String>[
    if (c.entityType != null) c.entityType!,
    if (c.route != null)
      ...c.route!.split('/').where((String s) => s.isNotEmpty),
  ];
  for (final String raw in candidates) {
    final String t = raw.toLowerCase().replaceAll('-', '_');
    for (final String k in <String>[
      t,
      '${t}s',
      if (t.endsWith('s')) t.substring(0, t.length - 1),
    ]) {
      if (entityDefinitions.containsKey(k)) return k;
    }
    final String? viaModule = moduleEntity[t];
    if (viaModule != null) return viaModule;
  }
  return null;
}

/// Context carried by an entity route so Copilot knows which record is open.
CopilotContext entityContext(String entity, String? id) => CopilotContext(
  route: '/$entity${id == null ? '' : '/$id'}',
  entityType: entity,
  entityId: id,
);
