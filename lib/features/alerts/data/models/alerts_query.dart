import 'package:flutter/foundation.dart';

import '../../../../core/data/repositories/page.dart';
import '../../../inventory/model/inventory_item.dart';

@immutable
class AlertsQuery {
  const AlertsQuery({
    this.page = const PageRequest(),
    this.search = '',
    this.statuses = const {},
    this.categories = const {},
  });

  final PageRequest page;
  final String search;
  final Set<StockStatus> statuses;
  final Set<String> categories;
}
