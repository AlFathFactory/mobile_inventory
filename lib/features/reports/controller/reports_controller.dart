import 'package:flutter/foundation.dart';

import '../../inventory/model/inventory_movement.dart';
import '../model/report_filter.dart';

class ReportsController extends ChangeNotifier {
  ReportsController(List<InventoryMovement> movements)
    : _movements = List.unmodifiable(movements);

  static final DateTime _previewDate = DateTime(2026, 8, 16);

  final List<InventoryMovement> _movements;
  MovementType? _selectedType;
  ReportPeriod _period = ReportPeriod.last30Days;
  String? _project;
  String? _category;

  MovementType? get selectedType => _selectedType;
  ReportPeriod get period => _period;
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
        final matchesPeriod =
            _period == ReportPeriod.all || !movement.date.isBefore(cutoff);
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
    if (_period == period) return;
    _period = period;
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
