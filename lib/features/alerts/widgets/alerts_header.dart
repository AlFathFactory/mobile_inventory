import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class AlertsHeader extends StatelessWidget {
  const AlertsHeader({required this.totalCount, super.key});

  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'تنبيهات المخزون',
                style: AppTextStyles.sectionTitle.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 2),
              Text(
                'تابع الأصناف التي تحتاج انتباهك',
                style: AppTextStyles.body.copyWith(color: AppColors.neutral600),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 72),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.lowSoft,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$totalCount',
                    textDirection: TextDirection.ltr,
                    style: AppTextStyles.number.copyWith(
                      color: AppColors.low,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    'تحتاج انتباه',
                    style: AppTextStyles.caption.copyWith(color: AppColors.low),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
