import 'package:flutter/material.dart';

import '../../inventory/model/inventory_movement.dart';
import '../model/report_filter.dart';

class ReportsController extends ChangeNotifier {
  ReportsController(List<InventoryMovement> movements)
    : _movements = List.unmodifiable(movements);

  static final DateTime _previewDate = DateTime(2026, 8, 16);

  final List<InventoryMovement> _movements;
  MovementType? _selectedType;
  ReportPeriod _period = ReportPeriod.last30Days;
  DateTimeRange? _dateRange;
  String? _project;
  String? _category;

  MovementType? get selectedType => _selectedType;
  ReportPeriod get period => _period;
  DateTimeRange? get dateRange => _dateRange;
  String? get project => _project;
  String? get category => _category;
  ReportSnapshot get snapshot =>
      const ReportSnapshot(total: 128, issues: 74, additions: 39);

  List<String> get projects =>
      _movements
          .map((movement) => movement.project)
          .toSet()
          .toList(growable: false)
        ..sort();

  List<String> get categories =>
      _movements
          .map((movement) => movement.category)
          .toSet()
          .toList(growable: false)
        ..sort();

  List<InventoryMovement> get visibleMovements => _movements
      .where((movement) {
        final cutoff = _previewDate.subtract(const Duration(days: 30));
        final movementDate = DateUtils.dateOnly(movement.date);
        final matchesPeriod = switch (_period) {
          ReportPeriod.last30Days => !movementDate.isBefore(cutoff),
          ReportPeriod.all => true,
          ReportPeriod.custom =>
            _dateRange != null &&
                !movementDate.isBefore(_dateRange!.start) &&
                !movementDate.isAfter(_dateRange!.end),
        };
        final matchesType =
            _selectedType == null || movement.type == _selectedType;
        final matchesProject = _project == null || movement.project == _project;
        final matchesCategory =
            _category == null || movement.category == _category;
        return matchesPeriod &&
            matchesType &&
            matchesProject &&
            matchesCategory;
      })
      .toList(growable: false);

  void selectType(MovementType? type) {
    if (_selectedType == type) return;
    _selectedType = type;
    notifyListeners();
  }

  void selectPeriod(ReportPeriod period) {
    if (period == ReportPeriod.custom) return;
    if (_period == period) return;
    _period = period;
    _dateRange = null;
    notifyListeners();
  }

  void selectDateRange(DateTimeRange range) {
    final first = DateUtils.dateOnly(range.start);
    final second = DateUtils.dateOnly(range.end);
    final normalizedRange = DateTimeRange(
      start: first.isBefore(second) ? first : second,
      end: first.isBefore(second) ? second : first,
    );
    if (_period == ReportPeriod.custom &&
        _dateRange?.start == normalizedRange.start &&
        _dateRange?.end == normalizedRange.end) {
      return;
    }
    _period = ReportPeriod.custom;
    _dateRange = normalizedRange;
    notifyListeners();
  }

  void selectProject(String? project) {
    if (_project == project) return;
    _project = project;
    notifyListeners();
  }

  void selectCategory(String? category) {
    if (_category == category) return;
    _category = category;
    notifyListeners();
  }
}
