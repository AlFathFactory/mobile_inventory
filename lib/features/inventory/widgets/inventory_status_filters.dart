import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/status_visuals.dart';
import '../../../core/widgets/filter_chip_bar.dart';
import '../../../core/widgets/filter_chip_option.dart';
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
    return FilterChipBar<StockStatus?>(
      keyPrefix: 'inventory-status',
      selected: selected,
      onSelected: onSelected,
      options: [
        const FilterChipOption<StockStatus?>(
          value: null,
          label: 'الكل',
          foreground: AppColors.accentDark,
          background: AppColors.accentVerySoft,
        ),
        for (final status in StockStatus.values)
          FilterChipOption<StockStatus?>(
            value: status,
            label: status == StockStatus.safe ? 'متوفر' : status.label,
            foreground: status.color,
            background: status.background,
          ),
      ],
    );
  }
}
