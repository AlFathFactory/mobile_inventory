import 'package:flutter/foundation.dart';

import '../../../../core/data/repositories/page.dart';
import '../../../inventory/model/inventory_movement.dart';
import '../../model/report_filter.dart';

@immutable
class ReportsData {
  const ReportsData({required this.snapshot, required this.movements});

  final ReportSnapshot snapshot;
  final PageResult<InventoryMovement> movements;
}
