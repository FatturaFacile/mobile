import 'dart:async';

import 'project_plan.dart';
import 'project_portfolio_models.dart';

/// Why a local edit was refused before it reached the outbox; the UI maps it to a localized message.
enum PortfolioErrorKind {
  notFound,
  invalidTitle,
  invalidDates,
  invalidProgress,
  invalidAmount,
  invalidCup,
  invalidCig,
  dependencyCycle,
  duplicateDependency,
  crossProject,
}

class PortfolioException implements Exception {
  const PortfolioException(this.kind);

  final PortfolioErrorKind kind;

  @override
  String toString() => 'PortfolioException($kind)';
}

enum PortfolioSyncStatus { synced, offline, failed }

class PortfolioSyncResult {
  const PortfolioSyncResult(this.status, {this.pending = 0});

  final PortfolioSyncStatus status;

  /// Entities that could not be pulled (the cache of those is left as it was).
  final int pending;
}

/// Offline-first access to the portfolio: reads come from SQLite, writes go to SQLite and the sync outbox.
abstract class ProjectPortfolioRepository {
  Stream<List<Project>> watchProjects(String tenantId);

  /// The plan of one project, recomputed (roll-up, CPM) on every local change; null while the project is unknown.
  Stream<ProjectPlan?> watchPlan(String tenantId, String projectId);

  /// Sends the outbox, then pulls the four entities.
  Future<PortfolioSyncResult> sync(String tenantId);

  Future<void> updateProject(String tenantId, Project edited);

  Future<String> createNode(
    String tenantId, {
    required String projectId,
    required String title,
    String? parentNodeId,
    WbsNodeType nodeType = WbsNodeType.workPackage,
    double plannedHours = 0,
    double plannedCost = 0,
    double plannedRevenue = 0,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Saves the writable fields of [edited] that differ from the stored node.
  Future<void> updateNode(String tenantId, WbsNode edited);

  /// Deletes the node, its descendants and every dependency that touches them.
  Future<void> deleteNode(String tenantId, String nodeId);

  Future<String> addDependency(
    String tenantId, {
    required String projectId,
    required String predecessorNodeId,
    required String successorNodeId,
    DependencyType type = DependencyType.fs,
    int lagDays = 0,
  });

  Future<void> removeDependency(String tenantId, String dependencyId);

  /// Freezes the current plan as the next baseline of the project.
  Future<String> captureBaseline(
    String tenantId, {
    required String projectId,
    required String name,
  });
}
