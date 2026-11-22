/// Public-procurement codes (CUP, CIG) and the comparison of the current plan with a frozen baseline.
library;

import 'dart:convert';

import 'project_portfolio_models.dart';

/// Format checks for the codes of public-funded projects. They are not checksums: the authority is the server.
abstract final class ProcurementCodes {
  static final RegExp _cup = RegExp(r'^[A-Z0-9]{15}$');
  static final RegExp _cig = RegExp(r'^[A-Z0-9]{10}$');

  /// Upper-cases and strips blanks; null when nothing is left.
  static String? normalize(String? raw) {
    final String value = (raw ?? '').replaceAll(RegExp(r'\s'), '').toUpperCase();
    return value.isEmpty ? null : value;
  }

  /// Codice Unico di Progetto: 15 alphanumeric characters. An empty value is valid (the field is optional).
  static bool isValidCup(String? raw) {
    final String? value = normalize(raw);
    return value == null || _cup.hasMatch(value);
  }

  /// Codice Identificativo di Gara: 10 alphanumeric characters. An empty value is valid.
  static bool isValidCig(String? raw) {
    final String? value = normalize(raw);
    return value == null || _cig.hasMatch(value);
  }
}

/// One node of a baseline snapshot.
class BaselineNode {
  const BaselineNode({
    required this.id,
    required this.wbsCode,
    required this.title,
    this.startDate,
    this.endDate,
    this.plannedHours = 0,
    this.plannedCost = 0,
    this.plannedRevenue = 0,
  });

  final String id;
  final String wbsCode;
  final String title;
  final DateTime? startDate;
  final DateTime? endDate;
  final double plannedHours;
  final double plannedCost;
  final double plannedRevenue;
}

/// How far a node moved from the baseline. Positive day values mean later than planned, positive amounts mean more
/// than planned.
class NodeVariance {
  const NodeVariance({
    required this.nodeId,
    required this.wbsCode,
    required this.title,
    this.startSlipDays,
    this.finishSlipDays,
    this.hoursDelta = 0,
    this.costDelta = 0,
    this.revenueDelta = 0,
    this.addedSinceBaseline = false,
    this.removedSinceBaseline = false,
  });

  final String nodeId;
  final String wbsCode;
  final String title;
  final int? startSlipDays;
  final int? finishSlipDays;
  final double hoursDelta;
  final double costDelta;
  final double revenueDelta;

  /// The node did not exist when the baseline was captured.
  final bool addedSinceBaseline;

  /// The node is in the baseline but was deleted afterwards.
  final bool removedSinceBaseline;

  bool get hasDrift =>
      addedSinceBaseline ||
      removedSinceBaseline ||
      (startSlipDays ?? 0) != 0 ||
      (finishSlipDays ?? 0) != 0 ||
      hoursDelta != 0 ||
      costDelta != 0 ||
      revenueDelta != 0;
}

abstract final class BaselineVariance {
  /// The nodes frozen in [baseline]; a snapshot that does not parse yields an empty list.
  static List<BaselineNode> nodesOf(ProjectBaseline baseline) {
    try {
      final Object? decoded = jsonDecode(baseline.snapshotJson);
      final Object? list = decoded is Map ? decoded['nodes'] : decoded;
      if (list is! List) {
        return const <BaselineNode>[];
      }
      return <BaselineNode>[
        for (final Object? item in list)
          if (item is Map) _node(Map<String, dynamic>.from(item)),
      ];
    } on FormatException {
      return const <BaselineNode>[];
    }
  }

  /// The snapshot text of the current plan, as stored in a new baseline.
  static String snapshotOf(List<WbsNode> nodes) => jsonEncode(<String, dynamic>{
    'nodes': <Map<String, dynamic>>[
      for (final WbsNode n in nodes)
        <String, dynamic>{
          'id': n.id,
          'wbs_code': n.wbsCode,
          'title': n.title,
          'start_date': n.toJson()['start_date'],
          'end_date': n.toJson()['end_date'],
          'planned_hours': n.plannedHours,
          'planned_cost': n.plannedCost,
          'planned_revenue': n.plannedRevenue,
        },
    ],
  });

  /// The drift of [current] from [baseline], one entry per node of either side, in outline order.
  static List<NodeVariance> compare(
    ProjectBaseline baseline,
    List<WbsNode> current,
  ) {
    final Map<String, BaselineNode> frozen = <String, BaselineNode>{
      for (final BaselineNode n in nodesOf(baseline)) n.id: n,
    };
    final List<NodeVariance> result = <NodeVariance>[];
    for (final WbsNode node in current) {
      final BaselineNode? was = frozen.remove(node.id);
      if (was == null) {
        result.add(
          NodeVariance(
            nodeId: node.id,
            wbsCode: node.wbsCode,
            title: node.title,
            addedSinceBaseline: true,
          ),
        );
        continue;
      }
      result.add(
        NodeVariance(
          nodeId: node.id,
          wbsCode: node.wbsCode,
          title: node.title,
          startSlipDays: _daysBetween(was.startDate, node.startDate),
          finishSlipDays: _daysBetween(was.endDate, node.endDate),
          hoursDelta: node.plannedHours - was.plannedHours,
          costDelta: node.plannedCost - was.plannedCost,
          revenueDelta: node.plannedRevenue - was.plannedRevenue,
        ),
      );
    }
    for (final BaselineNode gone in frozen.values) {
      result.add(
        NodeVariance(
          nodeId: gone.id,
          wbsCode: gone.wbsCode,
          title: gone.title,
          removedSinceBaseline: true,
        ),
      );
    }
    return result;
  }

  /// Days from [from] to [to]; null when either is unknown.
  static int? _daysBetween(DateTime? from, DateTime? to) =>
      from == null || to == null ? null : to.difference(from).inDays;

  static BaselineNode _node(Map<String, dynamic> json) => BaselineNode(
    id: '${json['id']}',
    wbsCode: '${json['wbs_code'] ?? ''}',
    title: '${json['title'] ?? ''}',
    startDate: _parseDate(json['start_date']),
    endDate: _parseDate(json['end_date']),
    plannedHours: _parseNumber(json['planned_hours']),
    plannedCost: _parseNumber(json['planned_cost']),
    plannedRevenue: _parseNumber(json['planned_revenue']),
  );

  static DateTime? _parseDate(Object? value) {
    final DateTime? parsed = DateTime.tryParse('$value');
    if (parsed == null) {
      return null;
    }
    return DateTime.utc(parsed.year, parsed.month, parsed.day);
  }

  static double _parseNumber(Object? value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
}
