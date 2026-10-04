import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../inventory/model/inventory_movement.dart';
import 'reports_timeline_item.dart';

/// Connected timeline surface for the filtered report movements.
class ReportsMovementList extends StatelessWidget {
  const ReportsMovementList({required this.movements, super.key});

  final List<InventoryMovement> movements;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            for (var index = 0; index < movements.length; index++)
              ReportsTimelineItem(
                key: ValueKey(movements[index].id),
                movement: movements[index],
                showConnector: index != movements.length - 1,
              ),
          ],
        ),
      ),
    );
  }
}
