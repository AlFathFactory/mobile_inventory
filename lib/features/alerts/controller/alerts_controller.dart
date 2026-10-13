import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/data/repositories/data_result.dart';
import '../../../core/data/repositories/page.dart';
import '../../inventory/model/inventory_item.dart';
import '../data/models/alerts_query.dart';
import '../data/repositories/alerts_repository.dart';
import '../model/alert_summary.dart';

class AlertsController extends ChangeNotifier {
  AlertsController({
    required AlertsRepository repository,
    Duration searchDebounce = const Duration(milliseconds: 300),
  }) : _repository = repository,
       _searchDebounce = searchDebounce;

  final AlertsRepository _repository;
  final Duration _searchDebounce;
  final List<InventoryItem> _items = [];
  StockStatus? _selectedStatus;
  AlertSummary _summary = const AlertSummary(lowCount: 0, outOfStockCount: 0);
  String _search = '';
  Set<String> _categories = const {};
  Set<String> _projects = const {};
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _nextCursor;
  DataFailure? _failure;
  Timer? _searchTimer;
  int _requestRevision = 0;

  StockStatus? get selectedStatus => _selectedStatus;
  AlertSummary get summary => _summary;
  List<InventoryItem> get visibleItems => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _nextCursor != null;
  bool get isFiltering =>
      _selectedStatus != null ||
      _search.isNotEmpty ||
      _categories.isNotEmpty ||
      _projects.isNotEmpty;
  DataFailure? get failure => _failure;
  String get search => _search;
  Set<String> get categories => _categories;
  Set<String> get projects => _projects;

  Future<void> load({Duration delay = Duration.zero}) async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    await _reload();
  }

  Future<void> selectStatus(StockStatus? status) async {
    if (_selectedStatus == status) return;
    _selectedStatus = status;
    notifyListeners();
    await _reload();
  }

  void setSearch(String value) {
    if (_search == value) return;
    _search = value;
    notifyListeners();
    _searchTimer?.cancel();
    _searchTimer = Timer(_searchDebounce, _reload);
  }

  void setCategories(Set<String> values) {
    if (setEquals(_categories, values)) return;
    _categories = Set.unmodifiable(values);
    notifyListeners();
    unawaited(_reload());
  }

  void setProjects(Set<String> values) {
    if (setEquals(_projects, values)) return;
    _projects = Set.unmodifiable(values);
    notifyListeners();
    unawaited(_reload());
  }

  Future<void> loadNextPage() async {
    if (_isLoading || _isLoadingMore) return;
    final cursor = _nextCursor;
    if (cursor == null) return;

    final revision = _requestRevision;
    _isLoadingMore = true;
    notifyListeners();
    final result = await _repository.fetchAlerts(_query(cursor: cursor));
    if (revision != _requestRevision) return;

    switch (result) {
      case DataSuccess(:final value):
        final knownIds = _items.map((item) => item.routeId).toSet();
        _items.addAll(
          value.alerts.items.where((item) => knownIds.add(item.routeId)),
        );
        _summary = value.summary;
        _nextCursor = value.alerts.nextCursor;
        _failure = null;
      case DataError(:final failure):
        _failure = failure;
    }
    _isLoadingMore = false;
    notifyListeners();
  }

  Future<void> _reload() async {
    final revision = ++_requestRevision;
    _isLoading = true;
    _isLoadingMore = false;
    notifyListeners();

    final result = await _repository.fetchAlerts(_query());
    if (revision != _requestRevision) return;

    switch (result) {
      case DataSuccess(:final value):
        _items
          ..clear()
          ..addAll(value.alerts.items);
        _summary = value.summary;
        _nextCursor = value.alerts.nextCursor;
        _failure = null;
      case DataError(:final failure):
        _failure = failure;
        if (_items.isEmpty) {
          _summary = const AlertSummary(lowCount: 0, outOfStockCount: 0);
          _nextCursor = null;
        }
    }
    _isLoading = false;
    notifyListeners();
  }

  AlertsQuery _query({String? cursor}) {
    return AlertsQuery(
      page: PageRequest(cursor: cursor),
      search: _search,
      statuses: _selectedStatus == null ? const {} : {_selectedStatus!},
      categories: _categories,
      projects: _projects,
    );
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _requestRevision++;
    super.dispose();
  }
}
