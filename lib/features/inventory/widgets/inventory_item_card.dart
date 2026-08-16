import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_components.dart';
import '../model/inventory_item.dart';

class InventoryItemCard extends StatelessWidget {
  const InventoryItemCard({required this.item, super.key, this.onTap});

  final InventoryItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final quantityColor = switch (item.status) {
      StockStatus.safe => AppColors.text,
      StockStatus.low => AppColors.lowQuantity,
      StockStatus.outOfStock => AppColors.out,
    };

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardTitle,
                ),
                const SizedBox(height: 3),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(item.code, style: AppTextStyles.code),
                ),
                const SizedBox(height: 7),
                Text(
                  '${item.category} · ${item.project}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.quantity}',
                style: AppTextStyles.number.copyWith(color: quantityColor),
              ),
              Text('الأدنى ${item.minimum}', style: AppTextStyles.caption),
              const SizedBox(height: 9),
              StatusBadge(item.status),
            ],
          ),
        ],
      ),
    );
  }
}
