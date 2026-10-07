import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/status_visuals.dart';
import '../../../core/widgets/filter_chip_bar.dart';
import '../../../core/widgets/filter_chip_option.dart';
import '../../inventory/model/inventory_item.dart';

class AlertsStatusFilters extends StatelessWidget {
  const AlertsStatusFilters({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final StockStatus? selected;
  final ValueChanged<StockStatus?> onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChipBar<StockStatus?>(
      keyPrefix: 'alerts-status',
      selected: selected,
      onSelected: onSelected,
      options: [
        const FilterChipOption<StockStatus?>(
          value: null,
          label: 'الكل',
          foreground: AppColors.accentDark,
          background: AppColors.accentVerySoft,
        ),
        for (final status in const [StockStatus.outOfStock, StockStatus.low])
          FilterChipOption<StockStatus?>(
            value: status,
            label: status.label,
            foreground: status.color,
            background: status.background,
          ),
      ],
    );
  }
}
