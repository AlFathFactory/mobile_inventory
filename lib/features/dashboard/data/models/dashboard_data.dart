import 'package:flutter/foundation.dart';

import '../../../inventory/model/inventory_item.dart';
import '../../../inventory/model/inventory_movement.dart';
import '../../model/dashboard_models.dart';

@immutable
class DashboardData {
  const DashboardData({
    required this.metrics,
    required this.categories,
    required this.attentionItems,
    required this.recentMovements,
  });

  final List<DashboardMetric> metrics;
  final List<CategorySummary> categories;
  final List<InventoryItem> attentionItems;
  final List<InventoryMovement> recentMovements;
}
