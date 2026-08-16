import 'package:flutter/foundation.dart';

import 'inventory_item.dart';

@immutable
class InventoryFilter {
  const InventoryFilter({
    this.statuses = const {},
    this.categories = const {},
    this.projects = const {},
  });

  final Set<StockStatus> statuses;
  final Set<String> categories;
  final Set<String> projects;

  bool get isEmpty =>
      statuses.isEmpty && categories.isEmpty && projects.isEmpty;

  int get selectionCount =>
      statuses.length + categories.length + projects.length;
}
