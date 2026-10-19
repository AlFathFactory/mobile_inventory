import 'package:flutter/foundation.dart';

import '../../../core/data/repositories/data_result.dart';
import '../model/inventory_filter.dart';
import '../model/inventory_item.dart';

@immutable
class InventoryState {
  InventoryState({
    List<InventoryItem> items = const [],
    required this.isServerBacked,
    this.isLoading = true,
    this.isLoadingMore = false,
    this.nextCursor,
    this.failure,
    this.query = '',
    this.quickStatus,
    this.filter = const InventoryFilter(),
    List<String> categories = const [],
  }) : items = List.unmodifiable(items),
       categoryOptions = List.unmodifiable(categories);

  final List<InventoryItem> items;
  final bool isServerBacked;
  final bool isLoading;
  final bool isLoadingMore;
  final String? nextCursor;
  final DataFailure? failure;
  final String query;
  final StockStatus? quickStatus;
  final InventoryFilter filter;
  final List<String> categoryOptions;

  bool get hasMore => nextCursor != null;
  List<String> get categories {
    if (categoryOptions.isNotEmpty) return categoryOptions;
    return items.map((item) => item.category).toSet().toList(growable: false)
      ..sort();
  }

  List<String> get projects =>
      items
          .map((item) => item.project)
          .where((project) => project.isNotEmpty)
          .toSet()
          .toList(growable: false)
        ..sort();
  List<InventoryItem> get visibleItems => isServerBacked
      ? items
      : items.where((item) => matches(item, filter)).toList(growable: false);

  int resultCountFor(InventoryFilter values) =>
      items.where((item) => matches(item, values)).length;

  bool matches(InventoryItem item, InventoryFilter values) {
    final normalizedQuery = query.trim().toLowerCase();
    return (normalizedQuery.isEmpty ||
            item.name.toLowerCase().contains(normalizedQuery) ||
            item.code.toLowerCase().contains(normalizedQuery)) &&
        (quickStatus == null || item.status == quickStatus) &&
        (values.statuses.isEmpty || values.statuses.contains(item.status)) &&
        (values.categories.isEmpty ||
            values.categories.contains(item.category)) &&
        (values.projects.isEmpty || values.projects.contains(item.project));
  }

  InventoryState copyWith({
    List<InventoryItem>? items,
    bool? isLoading,
    bool? isLoadingMore,
    String? nextCursor,
    bool clearNextCursor = false,
    DataFailure? failure,
    bool clearFailure = false,
    String? query,
    StockStatus? quickStatus,
    bool clearQuickStatus = false,
    InventoryFilter? filter,
    List<String>? categories,
  }) => InventoryState(
    items: items ?? this.items,
    isServerBacked: isServerBacked,
    isLoading: isLoading ?? this.isLoading,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    nextCursor: clearNextCursor ? null : (nextCursor ?? this.nextCursor),
    failure: clearFailure ? null : (failure ?? this.failure),
    query: query ?? this.query,
    quickStatus: clearQuickStatus ? null : (quickStatus ?? this.quickStatus),
    filter: filter ?? this.filter,
    categories: categories ?? categoryOptions,
  );
}
