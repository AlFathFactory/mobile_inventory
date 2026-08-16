import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_components.dart';
import '../../inventory/model/inventory_item.dart';
import '../../inventory/widgets/inventory_item_card.dart';
import '../model/dashboard_models.dart';
import '../widgets/CategorySummaryCard.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({
    required this.metrics,
    required this.categories,
    required this.attentionItems,
    required this.onShowInventory,
    required this.onShowAlerts,
    required this.onOpenItem,
    super.key,
  });

  final List<DashboardMetric> metrics;
  final List<CategorySummary> categories;
  final List<InventoryItem> attentionItems;
  final ValueChanged<String?> onShowInventory;
  final VoidCallback onShowAlerts;
  final ValueChanged<InventoryItem> onOpenItem;

  @override
  Widget build(BuildContext context) {
    return ResponsivePage(
      child: ListView(
        key: const PageStorageKey('dashboard-list'),
        children: [
          PageHeader(
            // eyebrow: 'مصنع الوادي · المخزن الرئيسي',
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
          // const StockHealthCard(),
          // const SizedBox(height: 20),
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
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.45,
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
          const SectionHeader(title: 'أصناف تحتاج الانتباه'),
          const SizedBox(height: 7),
          for (var index = 0; index < attentionItems.length; index++) ...[
            InventoryItemCard(
              item: attentionItems[index],
              onTap: () => onOpenItem(attentionItems[index]),
            ),
            if (index != attentionItems.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}
