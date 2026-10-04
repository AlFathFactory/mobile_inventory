import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({required this.onNotificationsTap, super.key});

  final VoidCallback onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'أهلًا، صباح الخير 👋',
                style: AppTextStyles.sectionTitle.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 2),
              Text(
                'إليك حالة المخزون اليوم · المخزن الرئيسي',
                style: AppTextStyles.body.copyWith(color: AppColors.neutral600),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Material(
          color: AppColors.surface,
          shape: const CircleBorder(),
          child: InkWell(
            key: const Key('dashboard-notifications'),
            onTap: onNotificationsTap,
            customBorder: const CircleBorder(),
            child: const SizedBox.square(
              dimension: 46,
              child: Icon(
                Icons.notifications_none_rounded,
                color: AppColors.text,
                size: 23,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
