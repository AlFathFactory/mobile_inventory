import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class ReportsEmptyState extends StatelessWidget {
  const ReportsEmptyState({required this.hasActiveFilters, super.key});

  final bool hasActiveFilters;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const Key('reports-empty-state'),
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 18),
      child: Column(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: hasActiveFilters
                  ? AppColors.accentVerySoft
                  : AppColors.surfaceMuted,
              shape: BoxShape.circle,
            ),
            child: SizedBox.square(
              dimension: 64,
              child: Icon(
                hasActiveFilters
                    ? Icons.filter_alt_off_outlined
                    : Icons.history_toggle_off_rounded,
                size: 29,
                color: hasActiveFilters
                    ? AppColors.accent
                    : AppColors.neutral500,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            hasActiveFilters ? 'لا توجد حركات مطابقة' : 'لا توجد حركات بعد',
            style: AppTextStyles.sectionTitle,
          ),
          const SizedBox(height: 5),
          Text(
            hasActiveFilters
                ? 'جرّب تغيير الفترة أو الفلاتر المحددة.'
                : 'ستظهر حركات المخزون هنا عند تسجيلها.',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}
