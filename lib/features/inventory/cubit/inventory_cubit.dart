import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/data/repositories/data_result.dart';
import '../../../core/data/repositories/page.dart';
import '../../../core/data/services/supabase_failure_mapper.dart';
import '../../../core/utils/search_normalizer.dart';
import '../data/models/inventory_query.dart';
import '../data/repositories/inventory_repository.dart';
import '../model/inventory_filter.dart';
import '../model/inventory_item.dart';
import 'inventory_state.dart';

class InventoryCubit extends Cubit<InventoryState> {
  InventoryCubit({
    List<InventoryItem>? items,
    InventoryRepository? repository,
    bool serverBacked = false,
    bool initiallyLoading = true,
    Duration searchDebounce = const Duration(milliseconds: 300),
  }) : assert(items != null || repository != null),
       _repository = repository,
       _searchDebounce = searchDebounce,
       super(
         InventoryState(
           items: items ?? const [],
           isServerBacked: serverBacked,
           isLoading: initiallyLoading,
         ),
       ) {
    if (repository case final InventoryCacheReadable cache) {
      _cacheSubscription = cache.cacheEvents.listen((event) {
        if (isClosed) return;
        if (event.failure case final failure?) {
          emit(state.copyWith(refreshFailure: failure));
        } else {
          emit(state.copyWith(clearRefreshFailure: true));
          if (!state.isRefreshing) unawaited(reload());
        }
      });
    }
  }

  final InventoryRepository? _repository;
  final Duration _searchDebounce;
  Timer? _searchTimer;
  StreamSubscription<InventoryCacheEvent>? _cacheSubscription;
  int _requestRevision = 0;

  List<InventoryItem> get allItems => state.items;
  List<InventoryItem> get visibleItems => state.visibleItems;
  List<String> get categories => state.categories;
  List<String> get projects => state.projects;
  InventoryFilter get filter => state.filter;
  String get query => state.query;
  StockStatus? get quickStatus => state.quickStatus;
  bool get isServerBacked => state.isServerBacked;

  Future<void> loadPreviewData({
    Duration delay = const Duration(milliseconds: 650),
  }) async {
    if (!state.isLoading) return;
    if (state.isServerBacked) return reload();
    final revision = ++_requestRevision;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (isClosed || revision != _requestRevision) return;
    final repository = _repository;
    if (repository == null) {
      emit(state.copyWith(isLoading: false));
      return;
    }
    final result = await repository.fetchItems(const InventoryQuery());
    if (isClosed || revision != _requestRevision) return;
    switch (result) {
      case DataSuccess(:final value):
        emit(
          state.copyWith(
            items: value.items,
            clearFailure: true,
            isLoading: false,
          ),
        );
      case DataError(:final failure):
        emit(state.copyWith(failure: failure, isLoading: false));
    }
    final categories = await repository.fetchCategories();
    if (isClosed || revision != _requestRevision) return;
    if (categories case DataSuccess(:final value)) {
      emit(state.copyWith(categories: value));
    }
  }

  void setQuery(String value) {
    if (state.query == value) return;
    if (normalizeSearchTerm(state.query) == normalizeSearchTerm(value)) {
      emit(state.copyWith(query: value));
      return;
    }
    _invalidateRequests();
    emit(
      state.copyWith(
        items: state.isServerBacked ? const [] : null,
        isLoading: state.isServerBacked ? true : null,
        query: value,
        clearFailure: true,
        clearNextCursor: true,
        isLoadingMore: false,
      ),
    );
    if (!state.isServerBacked) return;
    _searchTimer?.cancel();
    _searchTimer = Timer(_searchDebounce, () => unawaited(reload()));
  }

  void setQuickStatus(StockStatus? status) {
    if (state.quickStatus == status) return;
    _updateQueryState(
      state.copyWith(quickStatus: status, clearQuickStatus: status == null),
    );
  }

  void applyFilters(InventoryFilter filter) {
    _updateQueryState(state.copyWith(filter: _immutableFilter(filter)));
  }

  void filterByCategory(String category) {
    _updateQueryState(
      state.copyWith(
        query: '',
        clearQuickStatus: true,
        filter: InventoryFilter(categories: {category}),
      ),
    );
  }

  void setBrowseCategory(String? category) {
    final categories = category == null ? const <String>{} : {category};
    if (setEquals(state.filter.categories, categories)) return;
    _updateQueryState(
      state.copyWith(
        filter: InventoryFilter(
          statuses: state.filter.statuses,
          categories: categories,
          projects: state.filter.projects,
        ),
      ),
    );
  }

  void clearFilters({bool includeQuery = false}) {
    _updateQueryState(
      state.copyWith(
        filter: const InventoryFilter(),
        clearQuickStatus: true,
        query: includeQuery ? '' : null,
      ),
    );
  }

  Future<void> reload() async {
    if (!state.isServerBacked) return;
    final revision = ++_requestRevision;
    final query = _remoteQuery();
    emit(
      state.copyWith(
        isLoading: true,
        isLoadingMore: false,
        clearNextCursor: true,
        clearFailure: true,
      ),
    );
    if (query == null) {
      emit(
        state.copyWith(
          items: const [],
          isLoading: false,
          clearNextCursor: true,
        ),
      );
      return;
    }
    late final DataResult<PageResult<InventoryItem>> result;
    try {
      result = await _repository!.fetchItems(query);
    } on Object catch (error) {
      if (isClosed || revision != _requestRevision) return;
      emit(
        state.copyWith(
          failure: SupabaseFailureMapper.from(error),
          isLoading: false,
        ),
      );
      return;
    }
    if (isClosed || revision != _requestRevision) return;
    switch (result) {
      case DataSuccess(:final value):
        DateTime? lastSync;
        if (_repository case final InventoryCacheReadable cache) {
          lastSync = await cache.lastSuccessfulSync();
          if (isClosed || revision != _requestRevision) return;
        }
        emit(
          state.copyWith(
            items: value.items,
            isCached: lastSync != null,
            lastSuccessfulSync: lastSync,
            nextCursor: value.nextCursor,
            clearNextCursor: value.nextCursor == null,
            clearFailure: true,
            isLoading: false,
          ),
        );
      case DataError(:final failure):
        emit(state.copyWith(failure: failure, isLoading: false));
    }
    DataResult<List<String>> categories;
    try {
      categories = await _repository.fetchCategories();
    } on Object {
      return;
    }
    if (isClosed || revision != _requestRevision) return;
    if (categories case DataSuccess(:final value)) {
      emit(state.copyWith(categories: value));
    }
  }

  Future<void> retry() {
    if (state.isLoading || state.isRefreshing) return Future.value();
    return reload();
  }

  Future<void> refresh() async {
    if (state.isRefreshing || state.isLoading) return;
    emit(
      state.copyWith(
        isRefreshing: true,
        clearRefreshFailure: true,
        clearRefreshResult: true,
      ),
    );
    final repository = _repository;
    try {
      if (repository case final InventoryCacheRefreshable cacheRepository) {
        await cacheRepository.refreshCache();
      }
      if (!isClosed) {
        await reload();
        if (!isClosed) {
          emit(
            state.copyWith(
              isRefreshing: false,
              refreshSucceeded: state.failure == null,
              refreshFailure: state.failure,
              clearRefreshFailure: state.failure == null,
            ),
          );
        }
      }
    } on Object catch (error) {
      if (!isClosed) {
        emit(
          state.copyWith(
            isRefreshing: false,
            refreshFailure: SupabaseFailureMapper.from(error),
            refreshSucceeded: false,
          ),
        );
      }
    }
  }

  Future<void> loadNextPage() async {
    if (!state.isServerBacked ||
        state.isLoading ||
        state.isLoadingMore ||
        state.isRefreshing) {
      return;
    }
    final cursor = state.nextCursor;
    if (cursor == null) return;
    final query = _remoteQuery(cursor: cursor);
    if (query == null) return;
    final revision = _requestRevision;
    emit(state.copyWith(isLoadingMore: true, clearLoadMoreFailure: true));
    late final DataResult<PageResult<InventoryItem>> result;
    try {
      result = await _repository!.fetchItems(query);
    } on Object catch (error) {
      if (!isClosed && revision == _requestRevision) {
        emit(
          state.copyWith(
            isLoadingMore: false,
            loadMoreFailure: SupabaseFailureMapper.from(error),
          ),
        );
      }
      return;
    }
    if (isClosed || revision != _requestRevision) return;
    switch (result) {
      case DataSuccess(:final value):
        final knownIds = state.items.map((item) => item.routeId).toSet();
        emit(
          state.copyWith(
            items: [
              ...state.items,
              ...value.items.where((item) => knownIds.add(item.routeId)),
            ],
            nextCursor: value.nextCursor,
            clearNextCursor: value.nextCursor == null,
            clearFailure: true,
            clearLoadMoreFailure: true,
            isLoadingMore: false,
          ),
        );
      case DataError(:final failure):
        emit(state.copyWith(loadMoreFailure: failure, isLoadingMore: false));
    }
  }

  void _updateQueryState(InventoryState updated) {
    _searchTimer?.cancel();
    _invalidateRequests();
    emit(
      updated.copyWith(
        items: state.isServerBacked ? const [] : null,
        isLoading: state.isServerBacked ? true : null,
        clearFailure: true,
        clearNextCursor: true,
        isLoadingMore: false,
      ),
    );
    if (state.isServerBacked) {
      unawaited(reload());
    }
  }

  InventoryQuery? _remoteQuery({String? cursor}) {
    final selected = state.filter.statuses;
    if (state.quickStatus != null &&
        selected.isNotEmpty &&
        !selected.contains(state.quickStatus)) {
      return null;
    }
    final statuses = selected.isNotEmpty
        ? selected
        : state.quickStatus == null
        ? const <StockStatus>{}
        : {state.quickStatus!};
    return InventoryQuery(
      page: PageRequest(cursor: cursor),
      search: normalizeSearchTerm(state.query),
      statuses: statuses,
      categories: state.filter.categories,
      projects: state.filter.projects,
    );
  }

  InventoryFilter _immutableFilter(InventoryFilter filter) => InventoryFilter(
    statuses: Set.unmodifiable(filter.statuses),
    categories: Set.unmodifiable(filter.categories),
    projects: Set.unmodifiable(filter.projects),
  );

  void _invalidateRequests() => _requestRevision++;

  @override
  Future<void> close() {
    _searchTimer?.cancel();
    _cacheSubscription?.cancel();
    _invalidateRequests();
    return super.close();
  }
}
