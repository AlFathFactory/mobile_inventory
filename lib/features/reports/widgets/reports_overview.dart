import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/status_visuals.dart';
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
    return DecoratedBox(
      key: const Key('reports-overview'),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: _OverviewSegment(
                count: snapshot.total,
                label: 'إجمالي الحركات',
                color: AppColors.accentDark,
                background: AppColors.accentVerySoft,
                icon: Icons.insights_rounded,
              ),
            ),
            Container(width: 1, height: 44, color: AppColors.divider),
            Expanded(
              child: _OverviewSegment(
                count: snapshot.issues,
                label: 'صرف',
                color: MovementType.issue.color,
                background: MovementType.issue.background,
                icon: Icons.north_east_rounded,
              ),
            ),
            Container(width: 1, height: 44, color: AppColors.divider),
            Expanded(
              child: _OverviewSegment(
                count: snapshot.additions,
                label: 'إضافة',
                color: MovementType.addition.color,
                background: MovementType.addition.background,
                icon: Icons.south_west_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewSegment extends StatelessWidget {
  const _OverviewSegment({
    required this.count,
    required this.label,
    required this.color,
    required this.background,
    required this.icon,
  });

  final int count;
  final String label;
  final Color color;
  final Color background;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: background,
                shape: BoxShape.circle,
              ),
              child: SizedBox.square(
                dimension: 30,
                child: Icon(icon, size: 16, color: color),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '$count',
                textDirection: TextDirection.ltr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.number.copyWith(
                  color: color,
                  fontSize: 24,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
