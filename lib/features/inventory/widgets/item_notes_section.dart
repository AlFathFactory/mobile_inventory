import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class ItemNotesSection extends StatelessWidget {
  const ItemNotesSection({required this.notes, super.key});

  final String notes;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('item-notes-section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ملاحظات', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 10),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.warmSurface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.notes_rounded,
                  size: 20,
                  color: AppColors.peach,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    notes,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.neutral800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
