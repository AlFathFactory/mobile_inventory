import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class InventoryCategoryIcon extends StatelessWidget {
  const InventoryCategoryIcon({
    required this.category,
    super.key,
    this.size = 48,
    this.iconSize = 22,
  });

  final String category;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final visuals = _CategoryVisuals.fromName(category);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: visuals.background,
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: SizedBox.square(
        dimension: size,
        child: Icon(visuals.icon, size: iconSize, color: visuals.foreground),
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
