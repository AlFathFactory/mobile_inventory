import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';

class AlertsEmptyState extends StatelessWidget {
  const AlertsEmptyState({required this.isFiltering, super.key});

  /// True when a status filter is active but matches nothing.
  /// False when there are no alerts at all.
  final bool isFiltering;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      key: const Key('alerts-empty-state'),
      title: isFiltering ? 'لا توجد تنبيهات مطابقة' : 'المخزون بحالة جيدة',
      message: isFiltering
          ? 'جرّب اختيار حالة مختلفة.'
          : 'لا توجد أصناف تحتاج انتباهك حاليًا',
      icon: isFiltering
          ? Icons.filter_alt_off_outlined
          : Icons.check_circle_outline_rounded,
      iconColor: isFiltering ? AppColors.accent : AppColors.safe,
      iconBackground: isFiltering
          ? AppColors.accentVerySoft
          : AppColors.safeSoft,
    );
  }
}
