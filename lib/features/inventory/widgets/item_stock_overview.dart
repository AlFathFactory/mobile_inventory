import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/status_visuals.dart';
import '../../../core/widgets/status_badge.dart';
import '../model/inventory_item.dart';

class ItemStockOverview extends StatelessWidget {
  const ItemStockOverview({required this.item, super.key});

  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: item.status.background,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'الرصيد الحالي',
                    style: AppTextStyles.label.copyWith(
                      color: item.status.color,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${item.quantity}',
                            textDirection: TextDirection.ltr,
                            style: AppTextStyles.number.copyWith(
                              color: item.status.color,
                              fontSize: 38,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsetsDirectional.only(
                              start: 6,
                              bottom: 3,
                            ),
                            child: Text(
                              'وحدة',
                              style: AppTextStyles.body.copyWith(
                                color: item.status.color,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 9),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: StatusBadge(item.status),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 112),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.vertical_align_bottom_rounded,
                        size: 19,
                        color: AppColors.neutral600,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${item.minimum}',
                        textDirection: TextDirection.ltr,
                        style: AppTextStyles.number.copyWith(fontSize: 20),
                      ),
                      const Text(
                        'الحد الأدنى',
                        style: AppTextStyles.caption,
                        textAlign: TextAlign.center,
                        softWrap: true,
                      ),
                    ],
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
