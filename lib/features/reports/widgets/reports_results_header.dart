import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Lightweight results context with an inline clear action when filters
/// are active.
class ReportsResultsHeader extends StatelessWidget {
  const ReportsResultsHeader({
    required this.count,
    required this.hasActiveFilters,
    required this.onClear,
    super.key,
  });

  final int count;
  final bool hasActiveFilters;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'نتائج الفترة المحددة',
                style: AppTextStyles.sectionTitle,
              ),
              const SizedBox(height: 2),
              Text('$count من الحركات', style: AppTextStyles.caption),
            ],
          ),
        ),
        if (hasActiveFilters)
          TextButton.icon(
            key: const Key('clear-reports-inline'),
            onPressed: onClear,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.accentDark,
              visualDensity: VisualDensity.compact,
            ),
            icon: const Icon(Icons.close_rounded, size: 16),
            label: const Text('مسح الفلاتر'),
          ),
      ],
    );
  }
}
