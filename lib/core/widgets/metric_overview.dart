import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_text_styles.dart';
import 'app_card.dart';

class OverviewMetric {
  const OverviewMetric({
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
}

class MetricOverview extends StatelessWidget {
  const MetricOverview({required this.metrics, super.key});

  final List<OverviewMetric> metrics;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
      child: Row(
        children: [
          for (var index = 0; index < metrics.length; index++) ...[
            Expanded(child: _MetricSegment(metric: metrics[index])),
            if (index != metrics.length - 1)
              Container(width: 1, height: 68, color: AppColors.divider),
          ],
        ],
      ),
    );
  }
}

class _MetricSegment extends StatelessWidget {
  const _MetricSegment({required this.metric});

  final OverviewMetric metric;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${metric.label}: ${metric.count}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: metric.background,
                shape: BoxShape.circle,
              ),
              child: SizedBox.square(
                dimension: 32,
                child: Icon(
                  metric.icon,
                  size: AppDimensions.iconSmall,
                  color: metric.color,
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.space4),
            Text(
              '${metric.count}',
              textDirection: TextDirection.ltr,
              maxLines: 1,
              style: AppTextStyles.number.copyWith(
                color: metric.color,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: AppDimensions.space2),
            Text(
              metric.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
