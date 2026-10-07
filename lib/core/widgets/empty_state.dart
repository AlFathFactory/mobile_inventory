import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_text_styles.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.title,
    super.key,
    this.message = 'جرّب تغيير البحث أو الفلاتر المحددة.',
    this.icon = Icons.inventory_2_outlined,
    this.iconColor = AppColors.neutral600,
    this.iconBackground = AppColors.surfaceMuted,
    this.padding = const EdgeInsets.symmetric(vertical: 40, horizontal: 18),
  });

  final String title;
  final String message;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: iconBackground,
              shape: BoxShape.circle,
            ),
            child: SizedBox.square(
              dimension: 64,
              child: Icon(icon, size: 29, color: iconColor),
            ),
          ),
          const SizedBox(height: AppDimensions.space12),
          Text(title, style: AppTextStyles.sectionTitle),
          const SizedBox(height: AppDimensions.space4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}
