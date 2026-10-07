import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/page_header.dart';

class AlertsHeader extends StatelessWidget {
  const AlertsHeader({required this.totalCount, super.key});

  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return PageHeader(
      title: 'تنبيهات المخزون',
      subtitle: 'تابع الأصناف التي تحتاج انتباهك',
      trailing: PageCountBadge(
        value: totalCount,
        label: 'تحتاج انتباه',
        foreground: AppColors.low,
        background: AppColors.lowSoft,
      ),
    );
  }
}
