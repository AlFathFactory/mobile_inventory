import 'package:flutter/material.dart';

import '../../../core/widgets/responsive_page.dart';
import '../../inventory/model/inventory_item.dart';
import '../../inventory/model/inventory_movement.dart';
import '../model/dashboard_models.dart';
import '../widgets/dashboard_categories.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/dashboard_quick_actions.dart';
import '../widgets/dashboard_search.dart';
import '../widgets/inventory_overview.dart';
import '../widgets/needs_attention_section.dart';
import '../widgets/recent_activity_section.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({
    required this.metrics,
    required this.categories,
    required this.attentionItems,
    required this.recentMovements,
    required this.onShowInventory,
    required this.onShowAlerts,
    required this.onShowReports,
    super.key,
  });

  final List<DashboardMetric> metrics;
  final List<CategorySummary> categories;
  final List<InventoryItem> attentionItems;
  final List<InventoryMovement> recentMovements;
  final ValueChanged<String?> onShowInventory;
  final VoidCallback onShowAlerts;
  final VoidCallback onShowReports;

  @override
  Widget build(BuildContext context) {
    return ResponsivePage(
      child: ListView(
        key: const PageStorageKey('dashboard-list'),
        padding: const EdgeInsets.only(bottom: 12),
        children: [
          DashboardHeader(onNotificationsTap: onShowAlerts),
          const SizedBox(height: 18),
          DashboardSearch(onTap: () => onShowInventory(null)),
          const SizedBox(height: 22),
          InventoryOverview(metrics: metrics),
          const SizedBox(height: 24),
          DashboardCategories(
            categories: categories,
            onShowAll: () => onShowInventory(null),
            onCategoryTap: (category) => onShowInventory(category.name),
          ),
          const SizedBox(height: 25),
          NeedsAttentionSection(items: attentionItems, onShowAll: onShowAlerts),
          const SizedBox(height: 25),
          RecentActivitySection(
            movements: recentMovements,
            onShowReports: onShowReports,
          ),
        ],
      ),
    );
  }
}
