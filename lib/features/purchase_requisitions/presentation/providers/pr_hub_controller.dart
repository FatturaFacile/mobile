import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/purchase_requisition_repository.dart';
import 'pr_providers.dart';

/// Active segment on the Purchase Requisitions Hub screen.
enum PrHubTab { myRequests, toApprove }

/// UI state of the Purchase Requisitions Hub screen.
class PrHubState {
  const PrHubState({
    this.activeTab = PrHubTab.myRequests,
    this.isRefreshing = false,
  });

  final PrHubTab activeTab;
  final bool isRefreshing;

  /// Returns a modified copy of [PrHubState].
  PrHubState copyWith({PrHubTab? activeTab, bool? isRefreshing}) {
    return PrHubState(
      activeTab: activeTab ?? this.activeTab,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

/// Manages active tab selection and manual pull-to-refresh sync on the Hub screen.
class PrHubController extends Notifier<PrHubState> {
  bool _disposed = false;

  @override
  PrHubState build() {
    ref.onDispose(() => _disposed = true);
    return const PrHubState();
  }

  /// Switches the visible hub segment.
  void selectTab(PrHubTab tab) {
    state = state.copyWith(activeTab: tab);
  }

  /// Runs a full offline-first PR sync cycle for [tenantId].
  Future<PrSyncSummary> refresh(String tenantId) async {
    state = state.copyWith(isRefreshing: true);
    try {
      return await ref
          .read(syncPurchaseRequisitionsUseCaseProvider)
          .call(tenantId);
    } finally {
      if (!_disposed) {
        state = state.copyWith(isRefreshing: false);
      }
    }
  }
}

/// Provider for [PrHubController].
final NotifierProvider<PrHubController, PrHubState> prHubControllerProvider =
    NotifierProvider.autoDispose<PrHubController, PrHubState>(
      PrHubController.new,
    );
