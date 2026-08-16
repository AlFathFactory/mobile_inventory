import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_components.dart';

class StockHealthCard extends StatelessWidget {
  const StockHealthCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('حالة المخزون', style: AppTextStyles.cardTitle),
          const SizedBox(height: 13),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: const SizedBox(
              height: 9,
              child: Row(
                children: [
                  Expanded(flex: 411, child: ColoredBox(color: AppColors.safe)),
                  Expanded(flex: 14, child: ColoredBox(color: AppColors.low)),
                  Expanded(flex: 3, child: ColoredBox(color: AppColors.out)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(
                child: _HealthLegend(
                  label: 'آمن',
                  value: '411',
                  color: AppColors.safe,
                ),
              ),
              Expanded(
                child: _HealthLegend(
                  label: 'منخفض',
                  value: '14',
                  color: AppColors.low,
                ),
              ),
              Expanded(
                child: _HealthLegend(
                  label: 'نفد',
                  value: '3',
                  color: AppColors.out,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HealthLegend extends StatelessWidget {
  const _HealthLegend({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Flexible(child: Text('$label $value', style: AppTextStyles.caption)),
      ],
    );
  }
}
