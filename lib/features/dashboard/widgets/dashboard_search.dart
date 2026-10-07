import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';

class DashboardSearch extends StatelessWidget {
  const DashboardSearch({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppDimensions.radiusControl),
      child: InkWell(
        key: const Key('dashboard-search'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusControl),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 13, 10, 13),
          child: Row(
            children: [
              const Icon(
                Icons.search_rounded,
                color: AppColors.accent,
                size: 23,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  'ابحث عن صنف أو كود...',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.neutral600,
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.accentVerySoft,
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusSmall,
                  ),
                ),
                child: const SizedBox.square(
                  dimension: 34,
                  child: Icon(
                    Icons.tune_rounded,
                    size: 18,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
