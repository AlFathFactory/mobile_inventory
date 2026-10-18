import 'package:flutter/material.dart';

import '../../../core/data/repositories/data_result.dart';
import '../../../core/data/repositories/load_state.dart';
import '../../inventory/model/inventory_movement.dart';
import '../model/report_filter.dart';

class ReportsState {
  const ReportsState({
    this.status = DataLoadStatus.initial,
    this.movements = const [],
    this.snapshot = const ReportSnapshot(total: 0, issues: 0, additions: 0),
    this.failure,
    this.selectedType,
    this.period = ReportPeriod.all,
    this.dateRange,
    this.project,
    this.category,
    this.projects = const [],
    this.categories = const [],
    this.nextCursor,
    this.isLoadingMore = false,
  });
  final DataLoadStatus status;
  final List<InventoryMovement> movements;
  final ReportSnapshot snapshot;
  final DataFailure? failure;
  final MovementType? selectedType;
  final ReportPeriod period;
  final DateTimeRange? dateRange;
  final String? project;
  final String? category;
  final List<String> projects;
  final List<String> categories;
  final String? nextCursor;
  final bool isLoadingMore;
  bool get isLoading => status == DataLoadStatus.loading;
  bool get hasMore => nextCursor != null;
  bool get hasActiveFilters =>
      period != ReportPeriod.all ||
      selectedType != null ||
      project != null ||
      category != null;
  int get activeFilterCount =>
      (period != ReportPeriod.all ? 1 : 0) +
      (selectedType != null ? 1 : 0) +
      (project != null ? 1 : 0) +
      (category != null ? 1 : 0);
  ReportsState copyWith({
    DataLoadStatus? status,
    List<InventoryMovement>? movements,
    ReportSnapshot? snapshot,
    DataFailure? failure,
    bool clearFailure = false,
    MovementType? selectedType,
    bool clearType = false,
    ReportPeriod? period,
    DateTimeRange? dateRange,
    bool clearDateRange = false,
    String? project,
    bool clearProject = false,
    String? category,
    bool clearCategory = false,
    List<String>? projects,
    List<String>? categories,
    String? nextCursor,
    bool clearNextCursor = false,
    bool? isLoadingMore,
  }) => ReportsState(
    status: status ?? this.status,
    movements: movements ?? this.movements,
    snapshot: snapshot ?? this.snapshot,
    failure: clearFailure ? null : (failure ?? this.failure),
    selectedType: clearType ? null : (selectedType ?? this.selectedType),
    period: period ?? this.period,
    dateRange: clearDateRange ? null : (dateRange ?? this.dateRange),
    project: clearProject ? null : (project ?? this.project),
    category: clearCategory ? null : (category ?? this.category),
    projects: projects ?? this.projects,
    categories: categories ?? this.categories,
    nextCursor: clearNextCursor ? null : (nextCursor ?? this.nextCursor),
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
  );
}
