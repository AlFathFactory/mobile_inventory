import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/filter_chip_bar.dart';
import '../../../core/widgets/filter_chip_option.dart';

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
        FilterChipBar<String?>(
          key: const Key('inventory-categories'),
          keyPrefix: 'inventory-category',
          selected: selectedCategories.isEmpty
              ? null
              : selectedCategories.length == 1
              ? selectedCategories.single
              : '\u0000multiple',
          onSelected: onSelected,
          options: [
            const FilterChipOption<String?>(
              value: null,
              label: 'كل الأقسام',
              foreground: Colors.white,
              background: AppColors.text,
            ),
            for (final category in categories)
              FilterChipOption<String?>(
                value: category,
                label: category,
                foreground: Colors.white,
                background: AppColors.text,
              ),
          ],
        ),
      ],
    );
  }
}
