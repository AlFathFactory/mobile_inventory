import 'package:flutter/material.dart';

import '../../features/inventory/model/inventory_item.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_text_styles.dart';
import '../theme/status_visuals.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});

  final StockStatus status;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: status.background,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          status.label,
          style: AppTextStyles.caption.copyWith(
            color: status.color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
