import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/data/repositories/data_result.dart';
import '../../../core/data/repositories/load_state.dart';
import '../../../core/data/repositories/page.dart';
import '../../inventory/model/inventory_movement.dart';
import '../data/models/reports_query.dart';
import '../data/repositories/reports_repository.dart';
import '../model/report_filter.dart';

class ReportsController extends ChangeNotifier {
  /// Compatibility path for existing preview screens and widget tests.
  ReportsController(List<InventoryMovement> movements)
    : _previewMovements = List.unmodifiable(movements),
      _repository = null,
      pageSize = 20,
      _clock = (() => DateTime(2026, 8, 16)) {
    _movements.addAll(movements);
    _snapshot = const ReportSnapshot(total: 128, issues: 74, additions: 39);
    _state = movements.isEmpty
        ? const DataLoadState.empty()
        : DataLoadState.success(List.unmodifiable(movements));
  }

  ReportsController.withRepository({
    required ReportsRepository repository,
    DateTime Function()? clock,
    this.pageSize = 20,
  }) : _repository = repository,
       _previewMovements = null,
       _clock = clock ?? DateTime.now;

  final ReportsRepository? _repository;
  final List<InventoryMovement>? _previewMovements;
  final DateTime Function() _clock;
  final int pageSize;
  final List<InventoryMovement> _movements = [];
  MovementType? _selectedType;
  ReportPeriod _period = ReportPeriod.all;
  DateTimeRange? _dateRange;
  String? _project;
  String? _category;
  ReportSnapshot _snapshot = const ReportSnapshot(
    total: 0,
    issues: 0,
    additions: 0,
  );
  DataLoadState<List<InventoryMovement>> _state = const DataLoadState.initial();
  String? _nextCursor;
  bool _isLoadingMore = false;
  int _revision = 0;
  List<String> _categories = const [];
  List<String> _projects = const [];

  MovementType? get selectedType => _selectedType;
  ReportPeriod get period => _period;
  DateTimeRange? get dateRange => _dateRange;
  String? get project => _project;
  String? get category => _category;
  ReportSnapshot get snapshot => _snapshot;
  DataLoadState<List<InventoryMovement>> get state => _state;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _nextCursor != null;
  DataFailure? get failure => _state.failure;
  List<InventoryMovement> get visibleMovements => List.unmodifiable(_movements);
  List<String> get projects {
    final preview = _previewMovements;
    return preview == null
        ? _projects
        : _options(preview, (movement) => movement.project);
  }

  List<String> get categories {
    final preview = _previewMovements;
    return preview == null
        ? _categories
        : _options(preview, (movement) => movement.category);
  }

  bool get hasActiveFilters =>
      _period != ReportPeriod.all ||
      _selectedType != null ||
      _project != null ||
      _category != null;
  int get activeFilterCount =>
      (_period != ReportPeriod.all ? 1 : 0) +
      (_selectedType != null ? 1 : 0) +
      (_project != null ? 1 : 0) +
      (_category != null ? 1 : 0);

  Future<void> load({Duration delay = Duration.zero}) async {
    if (_repository == null) return;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    final options = await _repository.fetchFilterOptions();
    if (options case DataSuccess(:final value)) {
      _categories = value.categories;
      _projects = value.projects;
      notifyListeners();
    }
    await _reload();
  }

  void selectType(MovementType? type) {
    if (_selectedType == type) return;
    _selectedType = type;
    _filtersChanged();
  }

  void selectPeriod(ReportPeriod period) {
    if (period == ReportPeriod.custom || _period == period) return;
    _period = period;
    _dateRange = null;
    _filtersChanged();
  }

  void selectDateRange(DateTimeRange range) {
    final first = DateUtils.dateOnly(range.start);
    final second = DateUtils.dateOnly(range.end);
    final normalized = DateTimeRange(
      start: first.isBefore(second) ? first : second,
      end: first.isBefore(second) ? second : first,
    );
    if (_period == ReportPeriod.custom &&
        _dateRange?.start == normalized.start &&
        _dateRange?.end == normalized.end) {
      return;
    }
    _period = ReportPeriod.custom;
    _dateRange = normalized;
    _filtersChanged();
  }

  void selectProject(String? project) {
    if (_project == project) return;
    _project = project;
    _filtersChanged();
  }

  void selectCategory(String? category) {
    if (_category == category) return;
    _category = category;
    _filtersChanged();
  }

  void clearFilters() {
    if (!hasActiveFilters) return;
    _selectedType = null;
    _period = ReportPeriod.all;
    _dateRange = null;
    _project = null;
    _category = null;
    _filtersChanged();
  }

  Future<void> loadNextPage() async {
    final repository = _repository;
    final cursor = _nextCursor;
    if (repository == null ||
        cursor == null ||
        _isLoadingMore ||
        _state.isLoading) {
      return;
    }
    final revision = _revision;
    _isLoadingMore = true;
    notifyListeners();
    final result = await repository.fetchReports(_query(cursor: cursor));
    if (revision != _revision) return;
    switch (result) {
      case DataSuccess(:final value):
        final ids = _movements.map((movement) => movement.id).toSet();
        _movements.addAll(
          value.movements.items.where((row) => ids.add(row.id)),
        );
        _snapshot = value.snapshot;
        _nextCursor = value.movements.nextCursor;
        _state = DataLoadState.success(List.unmodifiable(_movements));
      case DataError(:final failure):
        _nextCursor = null;
        _state = DataLoadState.failed(
          failure,
          previousData: List.unmodifiable(_movements),
        );
    }
    _isLoadingMore = false;
    notifyListeners();
  }

  void _filtersChanged() {
    final preview = _previewMovements;
    if (preview != null) {
      final query = _query();
      final start = query.startDate;
      final end = query.endDate;
      _movements
        ..clear()
        ..addAll(
          preview.where((row) {
            final date = DateUtils.dateOnly(row.date);
            return (query.types.isEmpty || query.types.contains(row.type)) &&
                (query.categories.isEmpty ||
                    query.categories.contains(row.category)) &&
                (query.projects.isEmpty ||
                    query.projects.contains(row.project)) &&
                (start == null || !date.isBefore(start)) &&
                (end == null || !date.isAfter(end));
          }),
        );
      _state = _movements.isEmpty
          ? const DataLoadState.empty()
          : DataLoadState.success(List.unmodifiable(_movements));
      notifyListeners();
      return;
    }
    unawaited(_reload());
  }

  Future<void> _reload() async {
    final repository = _repository;
    if (repository == null) return;
    final revision = ++_revision;
    _nextCursor = null;
    _isLoadingMore = false;
    _state = DataLoadState.loading(previousData: List.unmodifiable(_movements));
    notifyListeners();
    final result = await repository.fetchReports(_query());
    if (revision != _revision) return;
    switch (result) {
      case DataSuccess(:final value):
        _movements
          ..clear()
          ..addAll(value.movements.items);
        _snapshot = value.snapshot;
        _nextCursor = value.movements.nextCursor;
        _state = _movements.isEmpty
            ? const DataLoadState.empty()
            : DataLoadState.success(List.unmodifiable(_movements));
      case DataError(:final failure):
        _state = DataLoadState.failed(
          failure,
          previousData: _movements.isEmpty
              ? null
              : List.unmodifiable(_movements),
        );
    }
    notifyListeners();
  }

  ReportsQuery _query({String? cursor}) => ReportsQuery(
    page: PageRequest(limit: pageSize, cursor: cursor),
    types: _selectedType == null ? const {} : {_selectedType!},
    categories: _category == null ? const {} : {_category!},
    projects: _project == null ? const {} : {_project!},
    startDate: switch (_period) {
      ReportPeriod.all => null,
      ReportPeriod.last30Days => DateUtils.dateOnly(
        _clock().subtract(const Duration(days: 30)),
      ),
      ReportPeriod.custom => _dateRange?.start,
    },
    endDate: switch (_period) {
      ReportPeriod.all => null,
      ReportPeriod.last30Days => DateUtils.dateOnly(_clock()),
      ReportPeriod.custom => _dateRange?.end,
    },
  );

  List<String> _options(
    List<InventoryMovement> values,
    String Function(InventoryMovement) select,
  ) => values.map(select).toSet().toList()..sort();

  @override
  void dispose() {
    _revision++;
    super.dispose();
  }
}
