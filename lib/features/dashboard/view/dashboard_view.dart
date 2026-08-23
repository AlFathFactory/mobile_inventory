import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_components.dart';
import '../../inventory/model/inventory_movement.dart';
import '../../inventory/widgets/movement_card.dart';
import '../model/dashboard_models.dart';
import '../widgets/CategorySummaryCard.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({
    required this.metrics,
    required this.categories,
    required this.recentMovements,
    required this.onShowInventory,
    required this.onShowAlerts,
    required this.onShowReports,
    super.key,
  });

  final List<DashboardMetric> metrics;
  final List<CategorySummary> categories;
  final List<InventoryMovement> recentMovements;
  final ValueChanged<String?> onShowInventory;
  final VoidCallback onShowAlerts;
  final VoidCallback onShowReports;

  @override
  Widget build(BuildContext context) {
    return ResponsivePage(
      child: ListView(
        key: const PageStorageKey('dashboard-list'),
        children: [
          PageHeader(
            title: 'مصنع الفتح · المخزن الرئيسي',
            icon: Icons.notifications_none_rounded,
            onIconTap: onShowAlerts,
          ),
          const SizedBox(height: 17),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var index = 0; index < metrics.length; index++) ...[
                Expanded(
                  child: SummaryCard(
                    label: metrics[index].label,
                    value: '${metrics[index].value}',
                    valueColor: switch (index) {
                      1 => AppColors.low,
                      2 => AppColors.out,
                      _ => AppColors.text,
                    },
                  ),
                ),
                if (index != metrics.length - 1) const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 13),
          SectionHeader(
            title: 'الأقسام / التصنيفات',
            actionLabel: 'عرض الكل',
            onAction: () => onShowInventory(null),
          ),
          const SizedBox(height: 7),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categories.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              mainAxisExtent: 70,
            ),
            itemBuilder: (context, index) {
              final category = categories[index];
              return CategorySummaryCard(
                summary: category,
                onTap: () => onShowInventory(category.name),
              );
            },
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: 'أحدث حركات المخزون'),
          const SizedBox(height: 7),
          for (var index = 0; index < recentMovements.length; index++) ...[
            MovementCard(
              key: ValueKey('dashboard-${recentMovements[index].id}'),
              movement: recentMovements[index],
            ),
            if (index != recentMovements.length - 1) const SizedBox(height: 10),
          ],
          const SizedBox(height: 10),
          FilledButton.tonalIcon(
            key: const Key('open-reports-from-dashboard'),
            onPressed: onShowReports,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              visualDensity: VisualDensity.compact,
            ),
            icon: const Icon(Icons.bar_chart_outlined, size: 19),
            label: const Text('عرض كل التقارير'),
          ),
        ],
      ),
    );
  }
}
