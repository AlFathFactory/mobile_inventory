import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/data/repositories/data_result.dart';
import '../../../core/data/repositories/page.dart';
import '../data/models/inventory_query.dart';
import '../data/repositories/inventory_repository.dart';
import '../model/inventory_filter.dart';
import '../model/inventory_item.dart';

class InventoryController extends ChangeNotifier {
  InventoryController({
    List<InventoryItem>? items,
    InventoryRepository? repository,
    bool serverBacked = false,
    bool initiallyLoading = true,
    Duration searchDebounce = const Duration(milliseconds: 300),
  }) : assert(items != null || repository != null),
       _items = List.of(items ?? const <InventoryItem>[]),
       _repository = repository,
       _serverBacked = serverBacked,
       _isLoading = initiallyLoading,
       _searchDebounce = searchDebounce;

  final InventoryRepository? _repository;
  final bool _serverBacked;
  final Duration _searchDebounce;
  final List<InventoryItem> _items;
  String _query = '';
  StockStatus? _quickStatus;
  InventoryFilter _filter = const InventoryFilter();
  bool _isLoading;
  bool _isLoadingMore = false;
  String? _nextCursor;
  DataFailure? _failure;
  Timer? _searchTimer;
  int _requestRevision = 0;

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _nextCursor != null;
  bool get isServerBacked => _serverBacked;
  DataFailure? get failure => _failure;
  String get query => _query;
  StockStatus? get quickStatus => _quickStatus;
  InventoryFilter get filter => _filter;
  List<InventoryItem> get allItems => List.unmodifiable(_items);

  List<String> get categories =>
      _items.map((item) => item.category).toSet().toList(growable: false)
        ..sort();

  List<String> get projects =>
      _items
          .map((item) => item.project)
          .where((project) => project.isNotEmpty)
          .toSet()
          .toList(growable: false)
        ..sort();

  List<InventoryItem> get visibleItems {
    if (isServerBacked) return List.unmodifiable(_items);
    return _items
        .where((item) => _matches(item, _filter))
        .toList(growable: false);
  }

  int resultCountFor(InventoryFilter filter) {
    return _items.where((item) => _matches(item, filter)).length;
  }

  bool _matches(InventoryItem item, InventoryFilter filter) {
    final normalizedQuery = _query.trim().toLowerCase();
    final matchesQuery =
        normalizedQuery.isEmpty ||
        item.name.toLowerCase().contains(normalizedQuery) ||
        item.code.toLowerCase().contains(normalizedQuery);
    final matchesQuick = _quickStatus == null || item.status == _quickStatus;
    final matchesStatus =
        filter.statuses.isEmpty || filter.statuses.contains(item.status);
    final matchesCategory =
        filter.categories.isEmpty || filter.categories.contains(item.category);
    final matchesProject =
        filter.projects.isEmpty || filter.projects.contains(item.project);
    return matchesQuery &&
        matchesQuick &&
        matchesStatus &&
        matchesCategory &&
        matchesProject;
  }

  Future<void> loadPreviewData({
    Duration delay = const Duration(milliseconds: 650),
  }) async {
    if (!_isLoading) return;
    if (isServerBacked) return _reload();
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    final repository = _repository;
    if (repository != null) {
      final result = await repository.fetchItems(const InventoryQuery());
      switch (result) {
        case DataSuccess(:final value):
          _items
            ..clear()
            ..addAll(value.items);
          _failure = null;
        case DataError(:final failure):
          _failure = failure;
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  void setQuery(String value) {
    if (_query == value) return;
    _query = value;
    notifyListeners();
    if (!isServerBacked) return;
    _searchTimer?.cancel();
    _searchTimer = Timer(_searchDebounce, _reload);
  }

  void setQuickStatus(StockStatus? status) {
    if (_quickStatus == status) return;
    _quickStatus = status;
    notifyListeners();
    _refreshRemote();
  }

  void applyFilters(InventoryFilter filter) {
    _filter = InventoryFilter(
      statuses: Set.unmodifiable(filter.statuses),
      categories: Set.unmodifiable(filter.categories),
      projects: Set.unmodifiable(filter.projects),
    );
    notifyListeners();
    _refreshRemote();
  }

  void filterByCategory(String category) {
    _query = '';
    _quickStatus = null;
    _filter = InventoryFilter(categories: {category});
    notifyListeners();
    _refreshRemote();
  }

  void setBrowseCategory(String? category) {
    final categories = category == null ? const <String>{} : {category};
    if (setEquals(_filter.categories, categories)) return;
    _filter = InventoryFilter(
      statuses: _filter.statuses,
      categories: categories,
      projects: _filter.projects,
    );
    notifyListeners();
    _refreshRemote();
  }

  void clearFilters({bool includeQuery = false}) {
    _quickStatus = null;
    _filter = const InventoryFilter();
    if (includeQuery) _query = '';
    notifyListeners();
    _refreshRemote();
  }

  Future<void> loadNextPage() async {
    if (!isServerBacked || _isLoading || _isLoadingMore) return;
    final cursor = _nextCursor;
    if (cursor == null) return;
    final query = _remoteQuery(cursor: cursor);
    if (query == null) return;

    final revision = _requestRevision;
    _isLoadingMore = true;
    notifyListeners();
    final result = await _repository!.fetchItems(query);
    if (revision != _requestRevision) return;

    switch (result) {
      case DataSuccess(:final value):
        final knownIds = _items.map((item) => item.routeId).toSet();
        _items.addAll(value.items.where((item) => knownIds.add(item.routeId)));
        _nextCursor = value.nextCursor;
        _failure = null;
      case DataError(:final failure):
        _failure = failure;
    }
    _isLoadingMore = false;
    notifyListeners();
  }

  void _refreshRemote() {
    if (!isServerBacked) return;
    _searchTimer?.cancel();
    unawaited(_reload());
  }

  Future<void> _reload() async {
    if (!isServerBacked) return;
    final query = _remoteQuery();
    final revision = ++_requestRevision;
    _isLoading = true;
    _isLoadingMore = false;
    notifyListeners();

    if (query == null) {
      _items.clear();
      _nextCursor = null;
      _failure = null;
      _isLoading = false;
      notifyListeners();
      return;
    }

    final result = await _repository!.fetchItems(query);
    if (revision != _requestRevision) return;

    switch (result) {
      case DataSuccess(:final value):
        _items
          ..clear()
          ..addAll(value.items);
        _nextCursor = value.nextCursor;
        _failure = null;
      case DataError(:final failure):
        _failure = failure;
        // Initial preview-shaped skeleton data must never become a silent
        // fallback when live Supabase has been configured.
        if (_items.every((item) => !item.hasBackendIdentity)) _items.clear();
    }
    _isLoading = false;
    notifyListeners();
  }

  InventoryQuery? _remoteQuery({String? cursor}) {
    final selectedStatuses = _filter.statuses;
    if (_quickStatus != null &&
        selectedStatuses.isNotEmpty &&
        !selectedStatuses.contains(_quickStatus)) {
      return null;
    }
    final statuses = selectedStatuses.isNotEmpty
        ? selectedStatuses
        : _quickStatus == null
        ? const <StockStatus>{}
        : {_quickStatus!};
    return InventoryQuery(
      page: PageRequest(cursor: cursor),
      search: _query,
      statuses: statuses,
      categories: _filter.categories,
      projects: _filter.projects,
    );
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _requestRevision++;
    super.dispose();
  }
}
