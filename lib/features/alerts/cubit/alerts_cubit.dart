import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/data/repositories/data_result.dart';
import '../../../core/data/repositories/page.dart';
import '../../inventory/model/inventory_item.dart';
import '../data/models/alerts_query.dart';
import '../data/repositories/alerts_repository.dart';
import '../model/alert_summary.dart';
import 'alerts_state.dart';

class AlertsCubit extends Cubit<AlertsState> {
  AlertsCubit({
    required AlertsRepository repository,
    Duration searchDebounce = const Duration(milliseconds: 300),
  }) : _repository = repository,
       _searchDebounce = searchDebounce,
       super(AlertsState());

  final AlertsRepository _repository;
  final Duration _searchDebounce;
  Timer? _searchTimer;
  int _requestRevision = 0;

  Future<void> load({Duration delay = Duration.zero}) async {
    final revision = ++_requestRevision;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (isClosed || revision != _requestRevision) return;
    await _loadFirstPage(revision);
  }

  Future<void> retry() => reload();

  Future<void> refresh() => reload();

  Future<void> reload() async {
    final revision = ++_requestRevision;
    await _loadFirstPage(revision);
  }

  Future<void> selectStatus(StockStatus? status) async {
    if (state.selectedStatus == status) return;
    _searchTimer?.cancel();
    _invalidatePendingRequests();
    emit(
      state.copyWith(
        selectedStatus: status,
        clearSelectedStatus: status == null,
        clearFailure: true,
        clearNextCursor: true,
        isLoadingMore: false,
      ),
    );
    final revision = ++_requestRevision;
    await _loadFirstPage(revision);
  }

  void setSearch(String value) {
    if (state.search == value) return;
    _invalidatePendingRequests();
    emit(
      state.copyWith(
        search: value,
        clearFailure: true,
        clearNextCursor: true,
        isLoadingMore: false,
      ),
    );
    _searchTimer?.cancel();
    _searchTimer = Timer(_searchDebounce, () => unawaited(reload()));
  }

  void setCategories(Set<String> values) {
    if (setEquals(state.categories, values)) return;
    _updateFilters(categories: values);
  }

  void setProjects(Set<String> values) {
    if (setEquals(state.projects, values)) return;
    _updateFilters(projects: values);
  }

  Future<void> loadNextPage() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    final cursor = state.nextCursor;
    if (cursor == null) return;

    final revision = _requestRevision;
    emit(state.copyWith(isLoadingMore: true, clearFailure: true));
    final result = await _repository.fetchAlerts(_query(cursor: cursor));
    if (isClosed || revision != _requestRevision) return;

    switch (result) {
      case DataSuccess(:final value):
        final knownIds = state.items.map((item) => item.routeId).toSet();
        final items = <InventoryItem>[
          ...state.items,
          ...value.alerts.items.where((item) => knownIds.add(item.routeId)),
        ];
        emit(
          state.copyWith(
            status: items.isEmpty ? AlertsStatus.empty : AlertsStatus.success,
            items: items,
            summary: value.summary,
            nextCursor: value.alerts.nextCursor,
            clearNextCursor: value.alerts.nextCursor == null,
            clearFailure: true,
            isLoadingMore: false,
          ),
        );
      case DataError(:final failure):
        emit(state.copyWith(failure: failure, isLoadingMore: false));
    }
  }

  void _updateFilters({Set<String>? categories, Set<String>? projects}) {
    _searchTimer?.cancel();
    _invalidatePendingRequests();
    emit(
      state.copyWith(
        categories: categories,
        projects: projects,
        clearFailure: true,
        clearNextCursor: true,
        isLoadingMore: false,
      ),
    );
    unawaited(reload());
  }

  Future<void> _loadFirstPage(int revision) async {
    if (isClosed || revision != _requestRevision) return;
    emit(
      state.copyWith(
        status: AlertsStatus.loading,
        clearFailure: true,
        clearNextCursor: true,
        isLoadingMore: false,
      ),
    );

    final result = await _repository.fetchAlerts(_query());
    if (isClosed || revision != _requestRevision) return;

    switch (result) {
      case DataSuccess(:final value):
        emit(
          state.copyWith(
            status: value.alerts.items.isEmpty
                ? AlertsStatus.empty
                : AlertsStatus.success,
            items: value.alerts.items,
            summary: value.summary,
            nextCursor: value.alerts.nextCursor,
            clearNextCursor: value.alerts.nextCursor == null,
            clearFailure: true,
            isLoadingMore: false,
          ),
        );
      case DataError(:final failure):
        emit(
          state.copyWith(
            status: AlertsStatus.failure,
            failure: failure,
            summary: state.items.isEmpty
                ? const AlertSummary(lowCount: 0, outOfStockCount: 0)
                : null,
            clearNextCursor: state.items.isEmpty,
            isLoadingMore: false,
          ),
        );
    }
  }

  AlertsQuery _query({String? cursor}) {
    return AlertsQuery(
      page: PageRequest(cursor: cursor),
      search: state.search,
      statuses: state.selectedStatus == null
          ? const {}
          : {state.selectedStatus!},
      categories: state.categories,
      projects: state.projects,
    );
  }

  void _invalidatePendingRequests() {
    _requestRevision++;
  }

  @override
  Future<void> close() {
    _searchTimer?.cancel();
    _invalidatePendingRequests();
    return super.close();
  }
}
