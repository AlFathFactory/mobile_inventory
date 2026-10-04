import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class InventoryHeader extends StatelessWidget {
  const InventoryHeader({required this.totalCount, super.key});

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
                'المخزون',
                style: AppTextStyles.sectionTitle.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 2),
              Text(
                'تصفّح الأصناف وتابع حالة توفرها',
                style: AppTextStyles.body.copyWith(color: AppColors.neutral600),
              ),
            ],
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.accentVerySoft,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              children: [
                Text(
                  '$totalCount',
                  textDirection: TextDirection.ltr,
                  style: AppTextStyles.number.copyWith(
                    color: AppColors.accentDark,
                    fontSize: 18,
                  ),
                ),
                Text(
                  'صنف',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.accentDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
