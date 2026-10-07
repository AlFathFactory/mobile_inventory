import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';

class ReportsEmptyState extends StatelessWidget {
  const ReportsEmptyState({required this.hasActiveFilters, super.key});

  final bool hasActiveFilters;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      key: const Key('reports-empty-state'),
      title: hasActiveFilters ? 'لا توجد حركات مطابقة' : 'لا توجد حركات بعد',
      message: hasActiveFilters
          ? 'جرّب تغيير الفترة أو الفلاتر المحددة.'
          : 'ستظهر حركات المخزون هنا عند تسجيلها.',
      icon: hasActiveFilters
          ? Icons.filter_alt_off_outlined
          : Icons.history_toggle_off_rounded,
      iconColor: hasActiveFilters ? AppColors.accent : AppColors.neutral600,
      iconBackground: hasActiveFilters
          ? AppColors.accentVerySoft
          : AppColors.surfaceMuted,
    );
  }
}
