import 'package:flutter/material.dart';

import '../../../core/widgets/app_components.dart';
import '../../inventory/model/inventory_item.dart';
import '../../inventory/widgets/inventory_item_card.dart';
import '../controller/alerts_controller.dart';
import '../widgets/alert_overview.dart';

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
          return Column(
            children: [
              const PageHeader(title: 'تنبيهات المخزون'),
              const SizedBox(height: 16),
              AlertOverview(summary: controller.summary),
              const SizedBox(height: 13),
              FilterChipBar<StockStatus?>(
                options: const [
                  FilterChipOption(value: null, label: 'الكل'),
                  FilterChipOption(value: StockStatus.outOfStock, label: 'نفد'),
                  FilterChipOption(value: StockStatus.low, label: 'منخفض'),
                ],
                selected: controller.selectedStatus,
                onSelected: controller.selectStatus,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: items.isEmpty
                    ? const SingleChildScrollView(
                        child: EmptyState(title: 'لا توجد تنبيهات مطابقة'),
                      )
                    : ListView.separated(
                        key: const PageStorageKey('alerts-list'),
                        itemCount: items.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return InventoryItemCard(
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
