import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/metric_overview.dart';
import '../model/alert_summary.dart';

class AlertsOverview extends StatelessWidget {
  const AlertsOverview({required this.summary, super.key});

  final AlertSummary summary;

  @override
  Widget build(BuildContext context) {
    return MetricOverview(
      key: const Key('alerts-overview'),
      metrics: [
        OverviewMetric(
          count: summary.lowCount,
          label: 'مخزون منخفض',
          color: AppColors.low,
          background: AppColors.lowSoft,
          icon: Icons.warning_amber_rounded,
        ),
        OverviewMetric(
          count: summary.outOfStockCount,
          label: 'نفد المخزون',
          color: AppColors.out,
          background: AppColors.outSoft,
          icon: Icons.error_outline_rounded,
        ),
      ],
    );
  }
}
