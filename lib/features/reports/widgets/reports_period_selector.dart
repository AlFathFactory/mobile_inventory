import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../model/report_filter.dart';

/// Glanceable period control: all, last 30 days, or a custom range.
///
/// Custom-range picking itself stays in the existing date dialog; the
/// controller logic is untouched.
class ReportsPeriodSelector extends StatelessWidget {
  const ReportsPeriodSelector({
    required this.period,
    required this.hasCustomRange,
    required this.onSelectPeriod,
    required this.onPickCustom,
    super.key,
  });

  final ReportPeriod period;
  final bool hasCustomRange;
  final ValueChanged<ReportPeriod> onSelectPeriod;
  final VoidCallback onPickCustom;

  @override
  Widget build(BuildContext context) {
    final hasSelectedCustomRange =
        period == ReportPeriod.custom && hasCustomRange;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        border: Border.all(color: AppColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.space4),
        child: Row(
          children: [
            Expanded(
              child: _PeriodSegment(
                key: const ValueKey('reports-period-الكل'),
                label: 'الكل',
                selected: period == ReportPeriod.all,
                onTap: () => onSelectPeriod(ReportPeriod.all),
              ),
            ),
            const SizedBox(width: AppDimensions.space4),
            Expanded(
              child: _PeriodSegment(
                key: const ValueKey('reports-period-آخر 30 يوم'),
                label: 'آخر 30 يوم',
                selected: period == ReportPeriod.last30Days,
                onTap: () => onSelectPeriod(ReportPeriod.last30Days),
              ),
            ),
            const SizedBox(width: AppDimensions.space4),
            Expanded(
              child: _PeriodSegment(
                key: const ValueKey('reports-period-مخصص'),
                label: 'مخصص',
                selected: hasSelectedCustomRange,
                dot: hasSelectedCustomRange,
                onTap: onPickCustom,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodSegment extends StatelessWidget {
  const _PeriodSegment({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
    this.dot = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.surface : Colors.transparent,
      borderRadius: BorderRadius.circular(AppDimensions.radiusControl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusControl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppDimensions.minTouchTarget,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (dot) ...[
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.label.copyWith(
                      color: selected
                          ? AppColors.accentDark
                          : AppColors.neutral700,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
