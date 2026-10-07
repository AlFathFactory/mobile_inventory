import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_text_styles.dart';

class PageHeader extends StatelessWidget {
  const PageHeader({
    required this.title,
    super.key,
    this.subtitle,
    this.trailing,
    this.icon,
    this.iconKey,
    this.onIconTap,
    this.iconTooltip,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final IconData? icon;
  final Key? iconKey;
  final VoidCallback? onIconTap;
  final String? iconTooltip;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.screenTitle,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: AppDimensions.space2),
                Text(
                  subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.neutral700,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppDimensions.space12),
          trailing!,
        ],
        if (icon != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: AppDimensions.space12,
            ),
            child: IconButton.filledTonal(
              key: iconKey,
              onPressed: onIconTap,
              tooltip: iconTooltip,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.text,
                shape: const CircleBorder(),
              ),
              icon: Icon(icon),
            ),
          ),
      ],
    );
  }
}

class PageCountBadge extends StatelessWidget {
  const PageCountBadge({
    required this.value,
    required this.label,
    super.key,
    this.foreground = AppColors.accentDark,
    this.background = AppColors.accentVerySoft,
  });

  final int value;
  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 68,
          maxWidth: 96,
          minHeight: 52,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(AppDimensions.radiusControl),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$value',
                  textDirection: TextDirection.ltr,
                  maxLines: 1,
                  style: AppTextStyles.number.copyWith(
                    color: foreground,
                    fontSize: 18,
                  ),
                ),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(color: foreground),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
