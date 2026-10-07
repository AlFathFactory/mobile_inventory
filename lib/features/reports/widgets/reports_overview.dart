import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/status_visuals.dart';
import '../../../core/widgets/metric_overview.dart';
import '../../inventory/model/inventory_movement.dart';
import '../model/report_filter.dart';

/// One connected summary surface: total plus issues/additions.
///
/// Snapshot numbers describe the full picture while the list below shows
/// the matching preview movements.
class ReportsOverview extends StatelessWidget {
  const ReportsOverview({required this.snapshot, super.key});

  final ReportSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return MetricOverview(
      key: const Key('reports-overview'),
      metrics: [
        OverviewMetric(
          count: snapshot.total,
          label: 'إجمالي الحركات',
          color: AppColors.accentDark,
          background: AppColors.accentVerySoft,
          icon: Icons.insights_rounded,
        ),
        OverviewMetric(
          count: snapshot.issues,
          label: 'صرف',
          color: MovementType.issue.color,
          background: MovementType.issue.background,
          icon: Icons.north_east_rounded,
        ),
        OverviewMetric(
          count: snapshot.additions,
          label: 'إضافة',
          color: MovementType.addition.color,
          background: MovementType.addition.background,
          icon: Icons.south_west_rounded,
        ),
      ],
    );
  }
}
