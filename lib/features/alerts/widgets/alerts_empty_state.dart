import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class AlertsEmptyState extends StatelessWidget {
  const AlertsEmptyState({required this.isFiltering, super.key});

  /// True when a status filter is active but matches nothing.
  /// False when there are no alerts at all.
  final bool isFiltering;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const Key('alerts-empty-state'),
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 18),
      child: Column(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: isFiltering
                  ? AppColors.accentVerySoft
                  : AppColors.safeSoft,
              shape: BoxShape.circle,
            ),
            child: SizedBox.square(
              dimension: 64,
              child: Icon(
                isFiltering
                    ? Icons.filter_alt_off_outlined
                    : Icons.check_circle_outline_rounded,
                size: 29,
                color: isFiltering ? AppColors.accent : AppColors.safe,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            isFiltering ? 'لا توجد تنبيهات مطابقة' : 'المخزون بحالة جيدة',
            style: AppTextStyles.sectionTitle,
          ),
          const SizedBox(height: 5),
          Text(
            isFiltering
                ? 'جرّب اختيار حالة مختلفة.'
                : 'لا توجد أصناف تحتاج انتباهك حاليًا',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}
