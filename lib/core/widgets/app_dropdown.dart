import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    required this.value,
    required this.hint,
    required this.options,
    required this.onChanged,
    super.key,
  });

  final T? value;
  final String hint;
  final Map<T, String> options;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: 11, end: 5),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            hint: Text(hint, style: AppTextStyles.caption),
            isDense: true,
            borderRadius: BorderRadius.circular(10),
            style: AppTextStyles.label,
            items: [
              for (final entry in options.entries)
                DropdownMenuItem<T>(value: entry.key, child: Text(entry.value)),
            ],
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}
