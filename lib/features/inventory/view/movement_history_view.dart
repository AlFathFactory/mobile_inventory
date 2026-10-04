import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/responsive_page.dart';
import '../model/inventory_item.dart';
import '../model/inventory_movement.dart';
import '../widgets/movement_history_header.dart';
import '../widgets/movement_history_summary.dart';
import '../widgets/movement_timeline_item.dart';

class MovementHistoryView extends StatelessWidget {
  const MovementHistoryView({
    required this.item,
    required this.movements,
    super.key,
  });

  final InventoryItem item;
  final List<InventoryMovement> movements;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('سجل الحركات')),
      body: SafeArea(
        top: false,
        child: ResponsivePage(
          child: ListView(
            key: const Key('movement-history-list'),
            padding: const EdgeInsets.only(bottom: 16),
            children: [
              MovementHistoryHeader(item: item),
              if (movements.isNotEmpty) ...[
                const SizedBox(height: 16),
                MovementHistorySummary(movements: movements),
              ],
              const SizedBox(height: 16),
              if (movements.isEmpty)
                const DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.all(Radius.circular(22)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Icon(
                          Icons.history_toggle_off_rounded,
                          color: AppColors.neutral500,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'لا توجد حركات مسجلة لهذا الصنف.',
                            style: AppTextStyles.body,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        for (var index = 0; index < movements.length; index++)
                          MovementTimelineItem(
                            key: ValueKey(movements[index].id),
                            movement: movements[index],
                            showConnector: index != movements.length - 1,
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
