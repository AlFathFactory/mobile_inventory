import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';

class InventoryEmptyState extends StatelessWidget {
  const InventoryEmptyState({required this.query, super.key});

  final String query;

  @override
  Widget build(BuildContext context) {
    final hasQuery = query.trim().isNotEmpty;
    return EmptyState(
      title: hasQuery ? 'لا توجد نتائج للبحث' : 'لا توجد أصناف مطابقة',
      message: hasQuery
          ? 'تحقق من اسم الصنف أو الكود وحاول مرة أخرى.'
          : 'جرّب اختيار حالة أو قسم مختلف.',
      icon: Icons.search_off_rounded,
      iconColor: AppColors.accent,
      iconBackground: AppColors.accentVerySoft,
    );
  }
}
