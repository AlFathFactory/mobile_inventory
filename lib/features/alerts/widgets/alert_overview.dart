import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_components.dart';
import '../model/alert_summary.dart';

class AlertOverview extends StatelessWidget {
  const AlertOverview({required this.summary, super.key});

  final AlertSummary summary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SummaryCard(
            label: 'مخزون منخفض',
            value: '${summary.lowCount}',
            valueColor: AppColors.low,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SummaryCard(
            label: 'نفد المخزون',
            value: '${summary.outOfStockCount}',
            valueColor: AppColors.out,
          ),
        ),
      ],
    );
  }
}
