import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../model/dashboard_models.dart';

class CategorySummaryCard extends StatelessWidget {
  const CategorySummaryCard({
    required this.summary,
    required this.onTap,
    super.key,
  });

  final CategorySummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.accentVerySoft,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.category_outlined,
              size: 17,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summary.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text('${summary.itemCount} صنف', style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
