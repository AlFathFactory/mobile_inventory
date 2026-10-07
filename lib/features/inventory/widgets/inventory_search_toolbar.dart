import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';

class InventorySearchToolbar extends StatelessWidget {
  const InventorySearchToolbar({
    required this.controller,
    required this.showClear,
    required this.filterCount,
    required this.onChanged,
    required this.onClear,
    required this.onFilterTap,
    super.key,
  });

  final TextEditingController controller;
  final bool showClear;
  final int filterCount;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            key: const Key('inventory-search'),
            controller: controller,
            onChanged: onChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'ابحث باسم الصنف أو الكود',
              hintStyle: AppTextStyles.body.copyWith(
                color: AppColors.neutral600,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.accent,
              ),
              suffixIcon: showClear
                  ? IconButton(
                      key: const Key('clear-inventory-search'),
                      onPressed: onClear,
                      tooltip: 'مسح البحث',
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 19,
                        color: AppColors.neutral600,
                      ),
                    )
                  : null,
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: _border,
              enabledBorder: _border,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  AppDimensions.radiusControl,
                ),
                borderSide: const BorderSide(
                  color: AppColors.accent,
                  width: 1.4,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 9),
        _FilterButton(count: filterCount, onTap: onFilterTap),
      ],
    );
  }

  static final _border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppDimensions.radiusControl),
    borderSide: BorderSide.none,
  );
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: count > 0 ? AppColors.accentVerySoft : AppColors.surface,
      borderRadius: BorderRadius.circular(AppDimensions.radiusControl),
      child: InkWell(
        key: const Key('open-inventory-filters'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusControl),
        child: SizedBox.square(
          dimension: 52,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: Icon(
                  Icons.tune_rounded,
                  color: count > 0
                      ? AppColors.accentDark
                      : AppColors.neutral700,
                  size: 22,
                ),
              ),
              if (count > 0)
                PositionedDirectional(
                  top: 7,
                  end: 7,
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: SizedBox.square(
                      dimension: 18,
                      child: Center(
                        child: Text(
                          '$count',
                          textDirection: TextDirection.ltr,
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
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
