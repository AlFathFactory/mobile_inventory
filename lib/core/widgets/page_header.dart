import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class PageHeader extends StatelessWidget {
  const PageHeader({
    required this.title,
    super.key,
    // this.eyebrow,
    this.icon,
    this.onIconTap,
    this.iconBorderRadius = const BorderRadius.all(Radius.circular(16)),
    this.iconBorderColor = AppColors.divider,
    this.iconBorderWidth = 1,
  });

  final String title;
  // final String? eyebrow;
  final IconData? icon;
  final VoidCallback? onIconTap;
  final BorderRadiusGeometry iconBorderRadius;
  final Color iconBorderColor;
  final double iconBorderWidth;

  @override
  Widget build(BuildContext context) {
    final iconShape = RoundedRectangleBorder(
      borderRadius: iconBorderRadius,
      side: BorderSide(color: iconBorderColor, width: iconBorderWidth),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 5),
              Text(title, style: AppTextStyles.pageTitle),
            ],
          ),
        ),
        if (icon != null)
          Material(
            color: AppColors.surface,
            shape: iconShape,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onIconTap,
              customBorder: iconShape,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(icon, color: AppColors.text, size: 24),
              ),
            ),
          ),
      ],
    );
  }
}
