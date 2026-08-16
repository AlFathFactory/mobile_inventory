import 'dart:async';

import 'package:flutter/foundation.dart';

import '../model/inventory_filter.dart';
import '../model/inventory_item.dart';

class InventoryController extends ChangeNotifier {
  InventoryController({
    required List<InventoryItem> items,
    bool initiallyLoading = true,
  }) : _items = List.unmodifiable(items),
       _isLoading = initiallyLoading;

  final List<InventoryItem> _items;
  String _query = '';
  StockStatus? _quickStatus;
  InventoryFilter _filter = const InventoryFilter();
  bool _isLoading;

  bool get isLoading => _isLoading;
  String get query => _query;
  StockStatus? get quickStatus => _quickStatus;
  InventoryFilter get filter => _filter;
  List<InventoryItem> get allItems => _items;

  List<String> get categories =>
      _items.map((item) => item.category).toSet().toList(growable: false)
        ..sort();

  List<String> get projects =>
      _items.map((item) => item.project).toSet().toList(growable: false)
        ..sort();

  List<InventoryItem> get visibleItems {
    final normalizedQuery = _query.trim().toLowerCase();
    return _items
        .where((item) {
          final matchesQuery =
              normalizedQuery.isEmpty ||
              item.name.toLowerCase().contains(normalizedQuery) ||
              item.code.toLowerCase().contains(normalizedQuery);
          final matchesQuick =
              _quickStatus == null || item.status == _quickStatus;
          final matchesStatus =
              _filter.statuses.isEmpty ||
              _filter.statuses.contains(item.status);
          final matchesCategory =
              _filter.categories.isEmpty ||
              _filter.categories.contains(item.category);
          final matchesProject =
              _filter.projects.isEmpty ||
              _filter.projects.contains(item.project);
          return matchesQuery &&
              matchesQuick &&
              matchesStatus &&
              matchesCategory &&
              matchesProject;
        })
        .toList(growable: false);
  }

  Future<void> loadPreviewData({
    Duration delay = const Duration(milliseconds: 650),
  }) async {
    if (!_isLoading) return;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    _isLoading = false;
    notifyListeners();
  }

  void setQuery(String value) {
    if (_query == value) return;
    _query = value;
    notifyListeners();
  }

  void setQuickStatus(StockStatus? status) {
    if (_quickStatus == status) return;
    _quickStatus = status;
    notifyListeners();
  }

  void applyFilters(InventoryFilter filter) {
    _filter = InventoryFilter(
      statuses: Set.unmodifiable(filter.statuses),
      categories: Set.unmodifiable(filter.categories),
      projects: Set.unmodifiable(filter.projects),
    );
    notifyListeners();
  }

  void filterByCategory(String category) {
    _quickStatus = null;
    _filter = InventoryFilter(categories: {category});
    notifyListeners();
  }

  void clearFilters({bool includeQuery = false}) {
    _quickStatus = null;
    _filter = const InventoryFilter();
    if (includeQuery) _query = '';
    notifyListeners();
  }
}
