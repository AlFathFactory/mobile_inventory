import 'package:flutter/material.dart';

import '../../../core/theme/app_dimensions.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
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
    this.onBack,
    super.key,
  });

  final InventoryItem item;
  final List<InventoryMovement> movements;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل الحركات'),
        leading: onBack == null
            ? null
            : BackButton(
                key: const Key('movement-history-back'),
                onPressed: onBack,
              ),
      ),
      body: SafeArea(
        top: false,
        child: ResponsivePage(
          child: ListView(
            key: const Key('movement-history-list'),
            padding: const EdgeInsets.only(bottom: 16),
            children: [
              MovementHistoryHeader(item: item),
              if (movements.isNotEmpty) ...[
                const SizedBox(height: AppDimensions.space16),
                MovementHistorySummary(movements: movements),
              ],
              const SizedBox(height: AppDimensions.space16),
              if (movements.isEmpty)
                const EmptyState(
                  title: 'لا توجد حركات مسجلة',
                  message: 'لا توجد حركات مسجلة لهذا الصنف.',
                  icon: Icons.history_toggle_off_rounded,
                )
              else
                AppCard(
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
            ],
          ),
        ),
      ),
    );
  }
}
