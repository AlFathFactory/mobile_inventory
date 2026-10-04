import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class InventoryEmptyState extends StatelessWidget {
  const InventoryEmptyState({required this.query, super.key});

  final String query;

  @override
  Widget build(BuildContext context) {
    final hasQuery = query.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 18),
      child: Column(
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.accentVerySoft,
              shape: BoxShape.circle,
            ),
            child: SizedBox.square(
              dimension: 64,
              child: Icon(
                Icons.search_off_rounded,
                size: 29,
                color: AppColors.accent,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            hasQuery ? 'لا توجد نتائج للبحث' : 'لا توجد أصناف مطابقة',
            style: AppTextStyles.sectionTitle,
          ),
          const SizedBox(height: 5),
          Text(
            hasQuery
                ? 'تحقق من اسم الصنف أو الكود وحاول مرة أخرى.'
                : 'جرّب اختيار حالة أو قسم مختلف.',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}
