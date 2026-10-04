import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Compact before → after balance pill for movement rows.
///
/// Numbers stay LTR while the arrow follows the ambient (RTL) direction.
class QuantityTransition extends StatelessWidget {
  const QuantityTransition({
    required this.before,
    required this.after,
    super.key,
  });

  final int before;
  final int after;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('الرصيد', style: AppTextStyles.caption),
            const SizedBox(width: 6),
            Flexible(
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  '$before',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.neutral700,
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Icon(
                Icons.arrow_back_rounded,
                size: 14,
                color: AppColors.neutral500,
              ),
            ),
            Flexible(
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  '$after',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
