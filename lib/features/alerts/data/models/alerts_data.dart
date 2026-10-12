import 'package:flutter/foundation.dart';

import '../../../../core/data/repositories/page.dart';
import '../../../inventory/model/inventory_item.dart';
import '../../model/alert_summary.dart';

@immutable
class AlertsData {
  const AlertsData({required this.summary, required this.alerts});

  final AlertSummary summary;
  final PageResult<InventoryItem> alerts;
}
