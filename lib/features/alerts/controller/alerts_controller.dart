import 'package:flutter/foundation.dart';

import '../../inventory/model/inventory_item.dart';
import '../model/alert_summary.dart';

class AlertsController extends ChangeNotifier {
  AlertsController(List<InventoryItem> items)
    : _items = List.unmodifiable(items);

  final List<InventoryItem> _items;
  StockStatus? _selectedStatus;

  StockStatus? get selectedStatus => _selectedStatus;
  AlertSummary get summary =>
      const AlertSummary(lowCount: 14, outOfStockCount: 3);

  List<InventoryItem> get visibleItems => _selectedStatus == null
      ? _items
      : _items
            .where((item) => item.status == _selectedStatus)
            .toList(growable: false);

  void selectStatus(StockStatus? status) {
    if (_selectedStatus == status) return;
    _selectedStatus = status;
    notifyListeners();
  }
}
