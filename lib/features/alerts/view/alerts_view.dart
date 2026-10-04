import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/responsive_page.dart';
import '../../inventory/model/inventory_item.dart';
import '../controller/alerts_controller.dart';
import '../widgets/alert_item_card.dart';
import '../widgets/alerts_empty_state.dart';
import '../widgets/alerts_header.dart';
import '../widgets/alerts_overview.dart';
import '../widgets/alerts_status_filters.dart';

class AlertsView extends StatelessWidget {
  const AlertsView({
    required this.controller,
    required this.onOpenItem,
    super.key,
  });

  final AlertsController controller;
  final ValueChanged<InventoryItem> onOpenItem;

  @override
  Widget build(BuildContext context) {
    return ResponsivePage(
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, child) {
          final items = controller.visibleItems;
          final summary = controller.summary;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AlertsHeader(
                totalCount: summary.lowCount + summary.outOfStockCount,
              ),
              const SizedBox(height: 16),
              AlertsOverview(summary: summary),
              const SizedBox(height: 13),
              AlertsStatusFilters(
                selected: controller.selectedStatus,
                onSelected: controller.selectStatus,
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'الأصناف المحتاجة انتباه',
                      style: AppTextStyles.sectionTitle,
                    ),
                  ),
                  Text(
                    '${items.length}',
                    textDirection: TextDirection.ltr,
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Expanded(
                child: items.isEmpty
                    ? SingleChildScrollView(
                        child: AlertsEmptyState(
                          isFiltering: controller.selectedStatus != null,
                        ),
                      )
                    : ListView.separated(
                        key: const PageStorageKey('alerts-list'),
                        padding: const EdgeInsets.only(bottom: 12),
                        itemCount: items.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 9),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return AlertItemCard(
                            key: ValueKey('alert-${item.code}'),
                            item: item,
                            onTap: () => onOpenItem(item),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
