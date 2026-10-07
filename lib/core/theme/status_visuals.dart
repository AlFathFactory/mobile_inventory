import 'package:flutter/material.dart';

import '../../features/inventory/model/inventory_item.dart';
import '../../features/inventory/model/inventory_movement.dart';
import 'app_colors.dart';

extension StockStatusVisuals on StockStatus {
  String get label => switch (this) {
    StockStatus.safe => 'آمن',
    StockStatus.low => 'منخفض',
    StockStatus.outOfStock => 'نفد',
  };

  Color get color => switch (this) {
    StockStatus.safe => AppColors.safe,
    StockStatus.low => AppColors.low,
    StockStatus.outOfStock => AppColors.out,
  };

  Color get background => switch (this) {
    StockStatus.safe => AppColors.safeSoft,
    StockStatus.low => AppColors.lowSoft,
    StockStatus.outOfStock => AppColors.outSoft,
  };
}

extension MovementTypeVisuals on MovementType {
  String get label => switch (this) {
    MovementType.addition => 'إضافة',
    MovementType.issue => 'صرف',
    MovementType.returned => 'مرتجع',
    MovementType.adjustment => 'تسوية',
  };

  Color get color => switch (this) {
    MovementType.addition => AppColors.safe,
    MovementType.issue => AppColors.low,
    MovementType.returned => AppColors.returnColor,
    MovementType.adjustment => AppColors.neutral700,
  };

  Color get background => switch (this) {
    MovementType.addition => AppColors.safeSoft,
    MovementType.issue => AppColors.lowSoft,
    MovementType.returned => AppColors.returnSoft,
    MovementType.adjustment => AppColors.neutral300,
  };
}
