import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../model/inventory_item.dart';
import 'inventory_category_icon.dart';

/// Compact item context header, visually connected to Item Details.
class MovementHistoryHeader extends StatelessWidget {
  const MovementHistoryHeader({required this.item, super.key});

  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InventoryCategoryIcon(category: item.category, size: 46),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.cardTitle.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 3),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  item.code,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.code,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      item.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 5),
                    child: Text('·', style: AppTextStyles.caption),
                  ),
                  Flexible(
                    child: Text(
                      item.project,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
