import 'package:flutter/foundation.dart';

import '../../../core/data/repositories/data_result.dart';
import '../../inventory/model/inventory_item.dart';
import '../model/alert_summary.dart';

enum AlertsStatus { initial, loading, success, empty, failure }

@immutable
class AlertsState {
  AlertsState({
    this.status = AlertsStatus.initial,
    List<InventoryItem> items = const [],
    this.summary = const AlertSummary(lowCount: 0, outOfStockCount: 0),
    this.failure,
    this.selectedStatus,
    this.search = '',
    Set<String> categories = const {},
    Set<String> projects = const {},
    this.nextCursor,
    this.isLoadingMore = false,
  }) : items = List.unmodifiable(items),
       categories = Set.unmodifiable(categories),
       projects = Set.unmodifiable(projects);

  final AlertsStatus status;
  final List<InventoryItem> items;
  final AlertSummary summary;
  final DataFailure? failure;
  final StockStatus? selectedStatus;
  final String search;
  final Set<String> categories;
  final Set<String> projects;
  final String? nextCursor;
  final bool isLoadingMore;

  bool get isLoading => status == AlertsStatus.loading;
  bool get hasMore => nextCursor != null;
  bool get isFiltering =>
      selectedStatus != null ||
      search.isNotEmpty ||
      categories.isNotEmpty ||
      projects.isNotEmpty;

  AlertsState copyWith({
    AlertsStatus? status,
    List<InventoryItem>? items,
    AlertSummary? summary,
    DataFailure? failure,
    bool clearFailure = false,
    StockStatus? selectedStatus,
    bool clearSelectedStatus = false,
    String? search,
    Set<String>? categories,
    Set<String>? projects,
    String? nextCursor,
    bool clearNextCursor = false,
    bool? isLoadingMore,
  }) {
    return AlertsState(
      status: status ?? this.status,
      items: items ?? this.items,
      summary: summary ?? this.summary,
      failure: clearFailure ? null : (failure ?? this.failure),
      selectedStatus: clearSelectedStatus
          ? null
          : (selectedStatus ?? this.selectedStatus),
      search: search ?? this.search,
      categories: categories ?? this.categories,
      projects: projects ?? this.projects,
      nextCursor: clearNextCursor ? null : (nextCursor ?? this.nextCursor),
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}
