import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../data/customer_lifecycle_remote_data_source.dart';
import '../domain/customer_lifecycle_models.dart';

final Provider<CustomerLifecycleRemoteDataSource>
customerLifecycleRemoteProvider = Provider<CustomerLifecycleRemoteDataSource>(
  (Ref ref) => CustomerLifecycleRemoteDataSource(ref.watch(dioProvider)),
);

class CustomerLifecycleState {
  const CustomerLifecycleState({
    this.results = const <LifecycleContact>[],
    this.selected,
    this.view,
    this.types = const <String>[],
    this.loading = false,
    this.noAccount = false,
    this.error,
  });

  final List<LifecycleContact> results;
  final LifecycleContact? selected;
  final CustomerLifecycleView? view;

  /// The timeline types the filter keeps; empty means all of them.
  final List<String> types;
  final bool loading;

  /// The selected customer has no CRM account behind it.
  final bool noAccount;
  final LifecycleErrorKind? error;

  CustomerLifecycleState copyWith({
    List<LifecycleContact>? results,
    LifecycleContact? selected,
    CustomerLifecycleView? Function()? view,
    List<String>? types,
    bool? loading,
    bool? noAccount,
    LifecycleErrorKind? Function()? error,
  }) => CustomerLifecycleState(
    results: results ?? this.results,
    selected: selected ?? this.selected,
    view: view == null ? this.view : view(),
    types: types ?? this.types,
    loading: loading ?? this.loading,
    noAccount: noAccount ?? this.noAccount,
    error: error == null ? this.error : error(),
  );
}

/// Online customer 360: search a customer, read its summary and filtered timeline from the web-api.
class CustomerLifecycleController extends Notifier<CustomerLifecycleState> {
  String? _accountId;

  CustomerLifecycleRemoteDataSource get _remote =>
      ref.read(customerLifecycleRemoteProvider);

  @override
  CustomerLifecycleState build() => const CustomerLifecycleState();

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = state.copyWith(results: <LifecycleContact>[]);
      return;
    }
    try {
      final List<LifecycleContact> found = await _remote.searchContacts(
        query.trim(),
      );
      state = state.copyWith(results: found, error: () => null);
    } on LifecycleRemoteException catch (e) {
      state = state.copyWith(error: () => e.kind);
    }
  }

  Future<void> select(LifecycleContact contact) async {
    state = state.copyWith(
      selected: contact,
      view: () => null,
      types: <String>[],
      loading: true,
      noAccount: false,
      error: () => null,
    );
    try {
      _accountId = await _remote.findAccountId(contact.id);
      final String? accountId = _accountId;
      if (accountId == null) {
        state = state.copyWith(loading: false, noAccount: true);
        return;
      }
      final CustomerLifecycleSummary summary = await _remote.summary(accountId);
      final List<CustomerTimelineEvent> timeline = await _remote.timeline(
        accountId,
      );
      state = state.copyWith(
        view: () => CustomerLifecycleView(summary: summary, timeline: timeline),
        loading: false,
      );
    } on LifecycleRemoteException catch (e) {
      state = state.copyWith(loading: false, error: () => e.kind);
    }
  }

  /// Keeps only the timeline [types] (empty keeps all) and reloads the timeline.
  Future<void> filter(List<String> types) async {
    final String? accountId = _accountId;
    final CustomerLifecycleView? current = state.view;
    if (accountId == null || current == null) {
      return;
    }
    state = state.copyWith(types: types, error: () => null);
    try {
      final List<CustomerTimelineEvent> timeline = await _remote.timeline(
        accountId,
        types: types,
      );
      state = state.copyWith(
        view: () =>
            CustomerLifecycleView(summary: current.summary, timeline: timeline),
      );
    } on LifecycleRemoteException catch (e) {
      state = state.copyWith(error: () => e.kind);
    }
  }
}

final NotifierProvider<CustomerLifecycleController, CustomerLifecycleState>
customerLifecycleControllerProvider =
    NotifierProvider<CustomerLifecycleController, CustomerLifecycleState>(
      CustomerLifecycleController.new,
    );
