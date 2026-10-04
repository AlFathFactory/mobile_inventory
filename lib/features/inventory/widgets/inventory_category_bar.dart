import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class InventoryCategoryBar extends StatelessWidget {
  const InventoryCategoryBar({
    required this.categories,
    required this.selectedCategories,
    required this.onSelected,
    super.key,
  });

  final List<String> categories;
  final Set<String> selectedCategories;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الأقسام',
          style: AppTextStyles.label.copyWith(
            color: AppColors.text,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          key: const Key('inventory-categories'),
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _CategoryOption(
                label: 'كل الأقسام',
                selected: selectedCategories.isEmpty,
                onTap: () => onSelected(null),
              ),
              for (final category in categories) ...[
                const SizedBox(width: 7),
                _CategoryOption(
                  label: category,
                  selected:
                      selectedCategories.length == 1 &&
                      selectedCategories.contains(category),
                  onTap: () => onSelected(category),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryOption extends StatelessWidget {
  const _CategoryOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.text : AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        key: ValueKey('inventory-category-$label'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: selected ? Colors.white : AppColors.neutral700,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
