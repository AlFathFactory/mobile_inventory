import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/status_visuals.dart';
import '../../../core/widgets/app_components.dart';
import '../model/inventory_movement.dart';

class MovementCard extends StatelessWidget {
  const MovementCard({required this.movement, super.key, this.showItem = true});

  final InventoryMovement movement;
  final bool showItem;

  static const _months = <String>[
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  @override
  Widget build(BuildContext context) {
    final date =
        '${movement.date.day} ${_months[movement.date.month - 1]} ${movement.date.year}';
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: movement.type.background,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  child: Text(
                    movement.type.label,
                    style: AppTextStyles.label.copyWith(
                      color: movement.type.color,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Text(date, style: AppTextStyles.caption),
            ],
          ),
          if (showItem) ...[
            const SizedBox(height: 10),
            Text(movement.itemName, style: AppTextStyles.cardTitle),
            const SizedBox(height: 3),
            Text(
              '${movement.category} · ${movement.project}',
              style: AppTextStyles.caption,
            ),
          ],
          const SizedBox(height: 12),
          QuantityTransition(movement: movement),
          if (movement.partyName != null) ...[
            const SizedBox(height: 10),
            Text.rich(
              TextSpan(
                style: AppTextStyles.caption,
                children: [
                  TextSpan(text: '${movement.partyLabel}: '),
                  TextSpan(
                    text: movement.partyName,
                    style: AppTextStyles.label.copyWith(color: AppColors.text),
                  ),
                ],
              ),
            ),
          ],
          if (movement.purchaseOrder != null)
            KeyValueRow(label: 'أمر الشراء', value: movement.purchaseOrder!),
          if (movement.note != null)
            KeyValueRow(label: 'ملاحظة', value: movement.note!),
        ],
      ),
    );
  }
}

class QuantityTransition extends StatelessWidget {
  const QuantityTransition({required this.movement, super.key});

  final InventoryMovement movement;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          children: [
            Text(
              '${movement.quantity} وحدة',
              style: AppTextStyles.label.copyWith(color: AppColors.text),
            ),
            const Spacer(),
            Text('${movement.before}', style: AppTextStyles.caption),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Icon(
                Icons.arrow_back_rounded,
                size: 16,
                color: AppColors.neutral500,
              ),
            ),
            Text(
              '${movement.after}',
              style: AppTextStyles.label.copyWith(color: AppColors.text),
            ),
          ],
        ),
      ),
    );
  }
}
