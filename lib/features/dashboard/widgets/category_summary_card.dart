import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../model/dashboard_models.dart';

class CategorySummaryCard extends StatelessWidget {
  const CategorySummaryCard({
    required this.summary,
    required this.onTap,
    super.key,
  });

  final CategorySummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final visuals = _CategoryVisuals.fromName(summary.name);

    return Material(
      color: visuals.background,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        key: Key('dashboard-category-${summary.name}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(visuals.icon, color: visuals.foreground, size: 24),
              const Spacer(),
              Text(
                summary.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.label.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                '${summary.itemCount} صنف',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.neutral700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryVisuals {
  const _CategoryVisuals({
    required this.icon,
    required this.foreground,
    required this.background,
  });

  factory _CategoryVisuals.fromName(String name) {
    if (name.contains('دهانات')) {
      return const _CategoryVisuals(
        icon: Icons.format_paint_outlined,
        foreground: AppColors.peach,
        background: AppColors.peachSoft,
      );
    }
    if (name.contains('مسامير')) {
      return const _CategoryVisuals(
        icon: Icons.hardware_outlined,
        foreground: AppColors.neutral700,
        background: AppColors.surfaceMuted,
      );
    }
    if (name.contains('اسطوانات')) {
      return const _CategoryVisuals(
        icon: Icons.propane_tank_outlined,
        foreground: AppColors.low,
        background: AppColors.lowSoft,
      );
    }
    if (name.contains('كهرباء')) {
      return const _CategoryVisuals(
        icon: Icons.bolt_outlined,
        foreground: AppColors.accent,
        background: AppColors.accentVerySoft,
      );
    }
    if (name.contains('لحام')) {
      return const _CategoryVisuals(
        icon: Icons.construction_outlined,
        foreground: AppColors.lavender,
        background: AppColors.lavenderSoft,
      );
    }
    return const _CategoryVisuals(
      icon: Icons.inventory_2_outlined,
      foreground: AppColors.safe,
      background: AppColors.safeSoft,
    );
  }

  final IconData icon;
  final Color foreground;
  final Color background;
}
