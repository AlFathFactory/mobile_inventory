import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../model/dashboard_models.dart';

class InventoryOverview extends StatelessWidget {
  const InventoryOverview({required this.metrics, super.key});

  final List<DashboardMetric> metrics;

  @override
  Widget build(BuildContext context) {
    final total = metrics.isNotEmpty ? metrics.first : null;
    final low = metrics.length > 1 ? metrics[1] : null;
    final out = metrics.length > 2 ? metrics[2] : null;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.accentDark,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'نظرة سريعة على المخزون',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.accentSoft,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        '${total?.value ?? 0}',
                        textDirection: TextDirection.ltr,
                        style: AppTextStyles.number.copyWith(
                          color: Colors.white,
                          fontSize: 36,
                        ),
                      ),
                      Text(
                        total?.label ?? 'إجمالي الأصناف',
                        style: AppTextStyles.body.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox.square(
                    dimension: 52,
                    child: Icon(
                      Icons.inventory_2_outlined,
                      color: Colors.white,
                      size: 25,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _SupportingMetric(
                    metric: low,
                    icon: Icons.trending_down_rounded,
                    color: AppColors.lowSoft,
                    foreground: AppColors.low,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SupportingMetric(
                    metric: out,
                    icon: Icons.error_outline_rounded,
                    color: AppColors.outSoft,
                    foreground: AppColors.out,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportingMetric extends StatelessWidget {
  const _SupportingMetric({
    required this.metric,
    required this.icon,
    required this.color,
    required this.foreground,
  });

  final DashboardMetric? metric;
  final IconData icon;
  final Color color;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 19, color: foreground),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${metric?.value ?? 0}',
                    textDirection: TextDirection.ltr,
                    style: AppTextStyles.number.copyWith(
                      color: foreground,
                      fontSize: 19,
                    ),
                  ),
                  Text(
                    metric?.label ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
