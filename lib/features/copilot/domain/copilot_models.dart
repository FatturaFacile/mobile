import 'dart:convert';

/// Lifecycle of a human-in-the-loop action proposed by the assistant.
enum ActionStatus { none, pending, confirmed, rejected, executed, failed }

ActionStatus parseActionStatus(Object? raw) => switch (raw) {
  'pending' => ActionStatus.pending,
  'confirmed' => ActionStatus.confirmed,
  'rejected' => ActionStatus.rejected,
  'executed' => ActionStatus.executed,
  'failed' => ActionStatus.failed,
  _ => ActionStatus.none,
};

List<dynamic> _list(Object? v) => v is List ? v : const <dynamic>[];

/// Context of the screen the user was on when prompting.
class CopilotContext {
  const CopilotContext({this.route, this.entityType, this.entityId});

  final String? route;
  final String? entityType;
  final String? entityId;

  bool get isEmpty => route == null && entityType == null && entityId == null;

  Map<String, dynamic> toJson() => <String, dynamic>{
    if (route != null) 'route': route,
    if (entityType != null) 'entity_type': entityType,
    if (entityId != null) 'entity_id': entityId,
  };
}

/// A source attached to an answer: regulatory reference or in-app entity link.
class Citation {
  const Citation({
    required this.type,
    required this.label,
    this.title,
    this.sectionRef,
    this.jurisdiction,
    this.entityType,
    this.entityId,
    this.route,
  });

  factory Citation.fromJson(Map<String, dynamic> j) => Citation(
    type: '${j['type'] ?? 'regulatory'}',
    label: '${j['label'] ?? ''}',
    title: j['title'] as String?,
    sectionRef: j['section_ref'] as String?,
    jurisdiction: j['jurisdiction'] as String?,
    entityType: j['entity_type'] as String?,
    entityId: j['entity_id']?.toString(),
    route: j['route'] as String?,
  );

  final String type;
  final String label;
  final String? title;
  final String? sectionRef;
  final String? jurisdiction;
  final String? entityType;
  final String? entityId;
  final String? route;

  bool get isEntity => type == 'entity';
}

/// Chart/table payload attached to an answer.
class Visualization {
  const Visualization({
    required this.type,
    this.title,
    this.columns = const <String>[],
    this.rows = const <List<Object?>>[],
    this.labels = const <String>[],
    this.datasets = const <ChartDataset>[],
    this.metric,
    this.value,
  });

  factory Visualization.fromJson(Map<String, dynamic> j) {
    final List<dynamic> rawColumns = _list(j['columns']);
    final List<String> columns = rawColumns
        .map((dynamic c) => c is Map ? '${c['label'] ?? c['key'] ?? ''}' : '$c')
        .toList();
    final List<String> keys = rawColumns
        .map((dynamic c) => c is Map ? '${c['key'] ?? c['label'] ?? ''}' : '$c')
        .toList();
    return Visualization(
      type: '${j['type'] ?? 'table'}',
      title: j['title'] as String?,
      columns: columns,
      rows: _list(j['rows']).map<List<Object?>>((dynamic r) {
        if (r is List) return List<Object?>.from(r);
        if (r is Map) return keys.map<Object?>((String k) => r[k]).toList();
        return <Object?>[r];
      }).toList(),
      labels: _list(j['labels']).map((dynamic e) => '$e').toList(),
      datasets: _list(j['datasets'])
          .whereType<Map<dynamic, dynamic>>()
          .map(
            (Map<dynamic, dynamic> d) =>
                ChartDataset.fromJson(Map<String, dynamic>.from(d)),
          )
          .toList(),
      metric: j['metric']?.toString(),
      value: j['value'],
    );
  }

  final String type;
  final String? title;
  final List<String> columns;
  final List<List<Object?>> rows;
  final List<String> labels;
  final List<ChartDataset> datasets;
  final String? metric;
  final Object? value;
}

class ChartDataset {
  const ChartDataset({required this.label, required this.data});

  factory ChartDataset.fromJson(Map<String, dynamic> j) => ChartDataset(
    label: '${j['label'] ?? ''}',
    data: _list(j['data'])
        .map(
          (dynamic v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0,
        )
        .toList(),
  );

  final String label;
  final List<double> data;
}

/// An action the assistant wants to run once the user confirms it.
class ProposedAction {
  const ProposedAction({
    required this.tool,
    required this.module,
    required this.summary,
    this.arguments = const <String, dynamic>{},
    this.details = const <String, dynamic>{},
    this.editableFields = const <String>[],
    this.error,
  });

  factory ProposedAction.fromJson(Map<String, dynamic> j) => ProposedAction(
    tool: '${j['tool'] ?? ''}',
    module: '${j['module'] ?? ''}',
    summary: '${j['summary'] ?? ''}',
    arguments: j['arguments'] is Map
        ? Map<String, dynamic>.from(j['arguments'] as Map)
        : const <String, dynamic>{},
    details: j['details'] is Map
        ? Map<String, dynamic>.from(j['details'] as Map)
        : const <String, dynamic>{},
    editableFields: _list(j['editable_fields'])
        .map((dynamic e) => '$e')
        .toList(),
    error: j['error']?.toString(),
  );

  final String tool;
  final String module;
  final String summary;
  final Map<String, dynamic> arguments;
  final Map<String, dynamic> details;

  /// Dotted paths (e.g. `items.0.quantity`) the user may override.
  final List<String> editableFields;
  final String? error;

  /// Current value at a dotted path inside [arguments].
  Object? valueAt(String path) {
    Object? cur = arguments;
    for (final String part in path.split('.')) {
      if (cur is Map) {
        cur = cur[part];
      } else if (cur is List) {
        final int? i = int.tryParse(part);
        cur = i != null && i >= 0 && i < cur.length ? cur[i] : null;
      } else {
        return null;
      }
    }
    return cur;
  }
}

enum MessageRole { user, assistant }

class CopilotMessage {
  const CopilotMessage({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    required this.createdAt,
    this.citations = const <Citation>[],
    this.visualization,
    this.proposedAction,
    this.actionStatus = ActionStatus.none,
    this.streaming = false,
  });

  factory CopilotMessage.fromJson(Map<String, dynamic> j) => CopilotMessage(
    id: '${j['id']}',
    conversationId: '${j['conversation_id'] ?? ''}',
    role: j['role'] == 'user' ? MessageRole.user : MessageRole.assistant,
    content: '${j['content_markdown'] ?? ''}',
    createdAt:
        DateTime.tryParse('${j['created_at']}') ??
        DateTime.fromMillisecondsSinceEpoch(0),
    citations: _list(j['citations'])
        .whereType<Map<dynamic, dynamic>>()
        .map(
          (Map<dynamic, dynamic> c) =>
              Citation.fromJson(Map<String, dynamic>.from(c)),
        )
        .toList(),
    visualization: j['visualization'] is Map
        ? Visualization.fromJson(
            Map<String, dynamic>.from(j['visualization'] as Map),
          )
        : null,
    proposedAction: j['proposed_action'] is Map
        ? ProposedAction.fromJson(
            Map<String, dynamic>.from(j['proposed_action'] as Map),
          )
        : null,
    actionStatus: parseActionStatus(j['action_status']),
  );

  factory CopilotMessage.fromPayload(String payload) =>
      CopilotMessage.fromJson(jsonDecode(payload) as Map<String, dynamic>);

  final String id;
  final String conversationId;
  final MessageRole role;
  final String content;
  final DateTime createdAt;
  final List<Citation> citations;
  final Visualization? visualization;
  final ProposedAction? proposedAction;
  final ActionStatus actionStatus;

  /// Local-only: tokens are still arriving.
  final bool streaming;

  CopilotMessage copyWith({
    String? id,
    String? content,
    List<Citation>? citations,
    Visualization? visualization,
    ProposedAction? proposedAction,
    ActionStatus? actionStatus,
    bool? streaming,
  }) => CopilotMessage(
    id: id ?? this.id,
    conversationId: conversationId,
    role: role,
    content: content ?? this.content,
    createdAt: createdAt,
    citations: citations ?? this.citations,
    visualization: visualization ?? this.visualization,
    proposedAction: proposedAction ?? this.proposedAction,
    actionStatus: actionStatus ?? this.actionStatus,
    streaming: streaming ?? this.streaming,
  );
}

class CopilotConversation {
  const CopilotConversation({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.title,
  });

  factory CopilotConversation.fromJson(Map<String, dynamic> j) =>
      CopilotConversation(
        id: '${j['id']}',
        title: j['title'] as String?,
        createdAt:
            DateTime.tryParse('${j['created_at']}') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        updatedAt:
            DateTime.tryParse('${j['updated_at'] ?? j['created_at']}') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );

  final String id;
  final String? title;
  final DateTime createdAt;
  final DateTime updatedAt;
}

/// One server-sent event of a streamed answer.
sealed class CopilotEvent {
  const CopilotEvent();
}

final class MessageStarted extends CopilotEvent {
  const MessageStarted();
}

final class ToolCalled extends CopilotEvent {
  const ToolCalled(this.name);
  final String name;
}

final class ToolResulted extends CopilotEvent {
  const ToolResulted(this.name);
  final String name;
}

final class VisualizationEvent extends CopilotEvent {
  const VisualizationEvent(this.visualization);
  final Visualization visualization;
}

final class ActionProposedEvent extends CopilotEvent {
  const ActionProposedEvent(this.action);
  final ProposedAction action;
}

final class TokenEvent extends CopilotEvent {
  const TokenEvent(this.text);
  final String text;
}

final class MessageCompleted extends CopilotEvent {
  const MessageCompleted({
    required this.messageId,
    required this.conversationId,
  });
  final String messageId;
  final String conversationId;
}

final class StreamError extends CopilotEvent {
  const StreamError(this.message);
  final String message;
}
