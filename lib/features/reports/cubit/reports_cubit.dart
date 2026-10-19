import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/data/repositories/data_result.dart';
import '../../../core/data/repositories/load_state.dart';
import '../../../core/data/repositories/page.dart';
import '../../inventory/model/inventory_movement.dart';
import '../data/models/reports_query.dart';
import '../data/repositories/reports_repository.dart';
import '../model/report_filter.dart';
import 'reports_state.dart';

class ReportsCubit extends Cubit<ReportsState> {
  ReportsCubit(List<InventoryMovement> movements)
    : _preview = List.unmodifiable(movements),
      _repository = null,
      _clock = (() => DateTime(2026, 8, 16)),
      pageSize = 20,
      super(
        ReportsState(
          status: movements.isEmpty
              ? DataLoadStatus.empty
              : DataLoadStatus.success,
          movements: List.unmodifiable(movements),
          snapshot: const ReportSnapshot(total: 128, issues: 74, additions: 39),
        ),
      );
  ReportsCubit.withRepository({
    required ReportsRepository repository,
    DateTime Function()? clock,
    this.pageSize = 20,
  }) : _repository = repository,
       _preview = null,
       _clock = clock ?? DateTime.now,
       super(const ReportsState());
  final ReportsRepository? _repository;
  final List<InventoryMovement>? _preview;
  final DateTime Function() _clock;
  final int pageSize;
  Timer? _searchTimer;
  int _revision = 0;
  MovementType? get selectedType => state.selectedType;
  ReportPeriod get period => state.period;
  DateTimeRange? get dateRange => state.dateRange;
  String? get project => state.project;
  String? get category => state.category;
  List<String> get projects => state.projects;
  List<String> get categories => state.categories;
  List<InventoryMovement> get visibleMovements => state.movements;
  bool get hasActiveFilters => state.hasActiveFilters;
  bool get isLoadingMore => state.isLoadingMore;
  bool get hasMore => state.hasMore;
  String get query => state.query;
  DataFailure? get failure => state.failure;
  ReportSnapshot get snapshot => state.snapshot;
  Future<void> load({Duration delay = Duration.zero}) async {
    if (_repository == null) return;
    final revision = ++_revision;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (isClosed || revision != _revision) return;
    final options = await _repository.fetchFilterOptions();
    if (isClosed || revision != _revision) return;
    if (options case DataSuccess(:final value)) {
      emit(
        state.copyWith(categories: value.categories, projects: value.projects),
      );
    }
    await _reload();
  }

  void selectType(MovementType? value) {
    if (state.selectedType == value) return;
    _changed(state.copyWith(selectedType: value, clearType: value == null));
  }

  void selectPeriod(ReportPeriod value) {
    if (value == ReportPeriod.custom || state.period == value) return;
    _changed(state.copyWith(period: value, clearDateRange: true));
  }

  void selectDateRange(DateTimeRange range) {
    final a = DateUtils.dateOnly(range.start),
        b = DateUtils.dateOnly(range.end);
    final value = DateTimeRange(
      start: a.isBefore(b) ? a : b,
      end: a.isBefore(b) ? b : a,
    );
    if (state.period == ReportPeriod.custom &&
        state.dateRange?.start == value.start &&
        state.dateRange?.end == value.end) {
      return;
    }
    _changed(state.copyWith(period: ReportPeriod.custom, dateRange: value));
  }

  void selectProject(String? value) {
    if (state.project != value) {
      _changed(state.copyWith(project: value, clearProject: value == null));
    }
  }

  void selectCategory(String? value) {
    if (state.category != value) {
      _changed(state.copyWith(category: value, clearCategory: value == null));
    }
  }

  void setQuery(String value) {
    if (state.query == value) return;
    _searchTimer?.cancel();
    _revision++;
    emit(
      state.copyWith(
        query: value,
        clearNextCursor: true,
        clearFailure: true,
        isLoadingMore: false,
      ),
    );
    if (_preview != null) {
      _applyPreviewQuery();
    } else {
      _searchTimer = Timer(
        const Duration(milliseconds: 300),
        () => unawaited(_reload()),
      );
    }
  }

  void clearFilters() {
    if (!state.hasActiveFilters) return;
    _changed(
      state.copyWith(
        period: ReportPeriod.all,
        clearType: true,
        clearDateRange: true,
        clearProject: true,
        clearCategory: true,
        clearQuery: true,
      ),
    );
  }

  void _changed(ReportsState updated) {
    _revision++;
    emit(
      updated.copyWith(
        clearNextCursor: true,
        clearFailure: true,
        isLoadingMore: false,
      ),
    );
    final preview = _preview;
    if (preview != null) {
      final query = _query();
      final rows = preview
          .where((row) {
            final date = DateUtils.dateOnly(row.date);
            final search = state.query.trim().toLowerCase();
            return (search.isEmpty ||
                    row.itemName.toLowerCase().contains(search) ||
                    row.itemCode.toLowerCase().contains(search) ||
                    row.project.toLowerCase().contains(search)) &&
                (query.types.isEmpty || query.types.contains(row.type)) &&
                (query.categories.isEmpty ||
                    query.categories.contains(row.category)) &&
                (query.projects.isEmpty ||
                    query.projects.contains(row.project)) &&
                (query.startDate == null || !date.isBefore(query.startDate!)) &&
                (query.endDate == null || !date.isAfter(query.endDate!));
          })
          .toList(growable: false);
      emit(
        state.copyWith(
          movements: rows,
          status: rows.isEmpty ? DataLoadStatus.empty : DataLoadStatus.success,
        ),
      );
    } else {
      unawaited(_reload());
    }
  }

  void _applyPreviewQuery() {
    final preview = _preview;
    if (preview == null) return;
    final query = _query();
    final search = state.query.trim().toLowerCase();
    final rows = preview
        .where((row) {
          final date = DateUtils.dateOnly(row.date);
          return (search.isEmpty ||
                  row.itemName.toLowerCase().contains(search) ||
                  row.itemCode.toLowerCase().contains(search) ||
                  row.project.toLowerCase().contains(search)) &&
              (query.types.isEmpty || query.types.contains(row.type)) &&
              (query.categories.isEmpty ||
                  query.categories.contains(row.category)) &&
              (query.projects.isEmpty ||
                  query.projects.contains(row.project)) &&
              (query.startDate == null || !date.isBefore(query.startDate!)) &&
              (query.endDate == null || !date.isAfter(query.endDate!));
        })
        .toList(growable: false);
    emit(
      state.copyWith(
        movements: rows,
        status: rows.isEmpty ? DataLoadStatus.empty : DataLoadStatus.success,
      ),
    );
  }

  Future<void> _reload() async {
    final repo = _repository;
    if (repo == null) return;
    final revision = ++_revision;
    emit(
      state.copyWith(
        status: DataLoadStatus.loading,
        clearNextCursor: true,
        clearFailure: true,
        isLoadingMore: false,
      ),
    );
    final result = await repo.fetchReports(_query());
    if (isClosed || revision != _revision) return;
    switch (result) {
      case DataSuccess(:final value):
        emit(
          state.copyWith(
            status: value.movements.items.isEmpty
                ? DataLoadStatus.empty
                : DataLoadStatus.success,
            movements: value.movements.items,
            snapshot: value.snapshot,
            nextCursor: value.movements.nextCursor,
            clearNextCursor: value.movements.nextCursor == null,
            clearFailure: true,
          ),
        );
      case DataError(:final failure):
        emit(state.copyWith(status: DataLoadStatus.failure, failure: failure));
    }
  }

  Future<void> loadNextPage() async {
    final repo = _repository, cursor = state.nextCursor;
    if (repo == null ||
        cursor == null ||
        state.isLoadingMore ||
        state.isLoading) {
      return;
    }
    final revision = _revision;
    emit(state.copyWith(isLoadingMore: true));
    final result = await repo.fetchReports(_query(cursor: cursor));
    if (isClosed || revision != _revision) return;
    switch (result) {
      case DataSuccess(:final value):
        final ids = state.movements.map((e) => e.id).toSet();
        emit(
          state.copyWith(
            status: DataLoadStatus.success,
            movements: [
              ...state.movements,
              ...value.movements.items.where((e) => ids.add(e.id)),
            ],
            snapshot: value.snapshot,
            nextCursor: value.movements.nextCursor,
            clearNextCursor: value.movements.nextCursor == null,
            clearFailure: true,
            isLoadingMore: false,
          ),
        );
      case DataError(:final failure):
        emit(
          state.copyWith(
            status: DataLoadStatus.failure,
            failure: failure,
            clearNextCursor: true,
            isLoadingMore: false,
          ),
        );
    }
  }

  ReportsQuery _query({String? cursor}) => ReportsQuery(
    page: PageRequest(limit: pageSize, cursor: cursor),
    types: state.selectedType == null ? const {} : {state.selectedType!},
    categories: state.category == null ? const {} : {state.category!},
    projects: state.project == null ? const {} : {state.project!},
    search: state.query,
    startDate: state.period == ReportPeriod.last30Days
        ? DateUtils.dateOnly(_clock().subtract(const Duration(days: 30)))
        : state.period == ReportPeriod.custom
        ? state.dateRange?.start
        : null,
    endDate: state.period == ReportPeriod.last30Days
        ? DateUtils.dateOnly(_clock())
        : state.period == ReportPeriod.custom
        ? state.dateRange?.end
        : null,
  );
  @override
  Future<void> close() {
    _searchTimer?.cancel();
    _revision++;
    return super.close();
  }

  void dispose() => close();
}

typedef ReportsController = ReportsCubit;
