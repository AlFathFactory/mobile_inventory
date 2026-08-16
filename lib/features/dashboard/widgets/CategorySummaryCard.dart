import 'package:flutter/material.dart';
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
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            summary.name,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.cardTitle,
          ),
          Text('${summary.itemCount} صنف', style: AppTextStyles.caption),
        ],
      ),
    );
  }
}
