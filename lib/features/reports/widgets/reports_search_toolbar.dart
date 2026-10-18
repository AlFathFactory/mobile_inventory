import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';

class ReportsSearchToolbar extends StatelessWidget {
  const ReportsSearchToolbar({
    required this.controller,
    required this.showClear,
    required this.onChanged,
    required this.onClear,
    super.key,
  });

  final TextEditingController controller;
  final bool showClear;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.radiusControl),
      borderSide: BorderSide.none,
    );
    return TextField(
      key: const Key('reports-search'),
      controller: controller,
      onChanged: onChanged,
      textDirection: TextDirection.rtl,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'ابحث باسم الصنف أو الكود أو المشروع',
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.neutral600),
        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.accent),
        suffixIcon: showClear
            ? IconButton(
                key: const Key('clear-reports-search'),
                onPressed: onClear,
                tooltip: 'مسح البحث',
                icon: const Icon(Icons.close_rounded, size: 19),
              )
            : null,
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: AppColors.accent, width: 1.4),
        ),
      ),
    );
  }
}
