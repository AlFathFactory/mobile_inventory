import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class InventoryResultsHeader extends StatelessWidget {
  const InventoryResultsHeader({
    required this.resultCount,
    required this.hasFilters,
    super.key,
  });

  final int resultCount;
  final bool hasFilters;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  hasFilters ? 'النتائج' : 'كل الأصناف',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardTitle,
                ),
              ),
              const SizedBox(width: 7),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  child: Text(
                    '$resultCount',
                    textDirection: TextDirection.ltr,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.neutral700,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        const Icon(
          Icons.visibility_outlined,
          size: 16,
          color: AppColors.neutral500,
        ),
        const SizedBox(width: 5),
        const Text('للعرض فقط', style: AppTextStyles.caption),
      ],
    );
  }
}
