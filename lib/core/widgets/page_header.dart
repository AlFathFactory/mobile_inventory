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
  });

  final String title;
  // final String? eyebrow;
  final IconData? icon;
  final VoidCallback? onIconTap;

  @override
  Widget build(BuildContext context) {
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
            shape: const CircleBorder(
              side: BorderSide(color: AppColors.divider),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onIconTap,
              customBorder: const CircleBorder(),
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
