import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_text_styles.dart';
import 'filter_chip_option.dart';

class FilterChipBar<T> extends StatelessWidget {
  const FilterChipBar({
    required this.options,
    required this.selected,
    required this.onSelected,
    super.key,
    this.keyPrefix = 'filter',
  });

  final List<FilterChipOption<T>> options;
  final T selected;
  final ValueChanged<T> onSelected;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final option in options) ...[
            _AppFilterChip(
              key: ValueKey('$keyPrefix-${option.label}'),
              option: option,
              selected: option.value == selected,
              onTap: () => onSelected(option.value),
            ),
            if (option != options.last)
              const SizedBox(width: AppDimensions.space8),
          ],
        ],
      ),
    );
  }
}

class _AppFilterChip<T> extends StatelessWidget {
  const _AppFilterChip({
    required this.option,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final FilterChipOption<T> option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = option.foreground ?? AppColors.accentDark;
    final background = option.background ?? AppColors.accentVerySoft;
    final radius = BorderRadius.circular(AppDimensions.radiusControl);

    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? background : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: selected
                ? foreground.withValues(alpha: 0.28)
                : AppColors.divider,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppDimensions.minTouchTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (selected) ...[
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: foreground,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    option.label,
                    style: AppTextStyles.label.copyWith(
                      color: selected ? foreground : AppColors.neutral700,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
