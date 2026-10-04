import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/status_visuals.dart';
import '../model/inventory_item.dart';

class InventoryStatusFilters extends StatelessWidget {
  const InventoryStatusFilters({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final StockStatus? selected;
  final ValueChanged<StockStatus?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _StatusOption(
            label: 'الكل',
            selected: selected == null,
            foreground: AppColors.accentDark,
            background: AppColors.accentVerySoft,
            onTap: () => onSelected(null),
          ),
          const SizedBox(width: 7),
          for (final status in StockStatus.values) ...[
            _StatusOption(
              label: status == StockStatus.safe ? 'متوفر' : status.label,
              selected: selected == status,
              foreground: status.color,
              background: status.background,
              onTap: () => onSelected(status),
            ),
            if (status != StockStatus.values.last) const SizedBox(width: 7),
          ],
        ],
      ),
    );
  }
}

class _StatusOption extends StatelessWidget {
  const _StatusOption({
    required this.label,
    required this.selected,
    required this.foreground,
    required this.background,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color foreground;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? background : AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        key: ValueKey('inventory-status-$label'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: foreground,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: AppTextStyles.label.copyWith(
                  color: selected ? foreground : AppColors.neutral700,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
