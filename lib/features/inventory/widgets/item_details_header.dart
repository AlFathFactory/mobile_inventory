import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../model/inventory_item.dart';
import 'inventory_category_icon.dart';

class ItemDetailsHeader extends StatelessWidget {
  const ItemDetailsHeader({required this.item, super.key});

  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InventoryCategoryIcon(category: item.category, size: 66, iconSize: 29),
        const SizedBox(height: 14),
        Text(
          item.name,
          style: AppTextStyles.sectionTitle.copyWith(fontSize: 21),
        ),
        const SizedBox(height: 5),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Text(item.code, style: AppTextStyles.code),
        ),
        const SizedBox(height: 11),
        Wrap(
          spacing: 8,
          runSpacing: 7,
          children: [
            _ContextPill(icon: Icons.category_outlined, label: item.category),
            _ContextPill(icon: Icons.location_on_outlined, label: item.project),
          ],
        ),
      ],
    );
  }
}

class _ContextPill extends StatelessWidget {
  const _ContextPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: AppColors.neutral600),
            const SizedBox(width: 5),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.neutral700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
