import 'package:flutter/foundation.dart';

import '../../../../core/data/repositories/page.dart';
import '../../model/inventory_item.dart';

@immutable
class InventoryQuery {
  const InventoryQuery({
    this.page = const PageRequest(),
    this.search = '',
    this.statuses = const {},
    this.categories = const {},
    this.projects = const {},
  });

  final PageRequest page;
  final String search;
  final Set<StockStatus> statuses;
  final Set<String> categories;
  final Set<String> projects;
}
