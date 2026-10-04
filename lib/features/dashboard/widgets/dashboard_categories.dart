import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/section_header.dart';
import '../model/dashboard_models.dart';
import 'category_summary_card.dart';

class DashboardCategories extends StatelessWidget {
  const DashboardCategories({
    required this.categories,
    required this.onCategoryTap,
    required this.onShowAll,
    super.key,
  });

  final List<CategorySummary> categories;
  final ValueChanged<CategorySummary> onCategoryTap;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'تصفّح الأقسام',
          actionLabel: 'عرض الكل',
          onAction: onShowAll,
        ),
        Text('وصول أسرع إلى أصناف المخزن', style: AppTextStyles.caption),
        const SizedBox(height: 12),
        SizedBox(
          height: 122,
          child: ListView.separated(
            key: const Key('dashboard-categories'),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final category = categories[index];
              return SizedBox(
                width: 132,
                child: CategorySummaryCard(
                  summary: category,
                  onTap: () => onCategoryTap(category),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
