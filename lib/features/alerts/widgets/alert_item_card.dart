import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/status_visuals.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../inventory/model/inventory_item.dart';
import '../../inventory/widgets/inventory_category_icon.dart';

/// Alerts-specific item presentation optimized for urgency.
///
/// Softer than a full warning surface: category identity stays neutral
/// while urgency is carried by the status badge and quantity color.
/// Tapping only navigates to Item Details (read-only).
class AlertItemCard extends StatelessWidget {
  const AlertItemCard({required this.item, required this.onTap, super.key});

  final InventoryItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsetsDirectional.fromSTEB(12, 12, 10, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InventoryCategoryIcon(category: item.category, size: 46),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    StatusBadge(item.status),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        'الحد ${item.minimum}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardTitle,
                ),
                const SizedBox(height: 3),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    item.code,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.code,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Flexible(
                      child: _AlertContextLabel(
                        icon: Icons.category_outlined,
                        label: item.category,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Text('·', style: AppTextStyles.caption),
                    ),
                    Flexible(
                      child: _AlertContextLabel(
                        icon: Icons.location_on_outlined,
                        label: item.project,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _AlertQuantity(item: item),
        ],
      ),
    );
  }
}

class _AlertContextLabel extends StatelessWidget {
  const _AlertContextLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.neutral500),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption,
          ),
        ),
      ],
    );
  }
}

class _AlertQuantity extends StatelessWidget {
  const _AlertQuantity({required this.item});

  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${item.quantity}',
          textDirection: TextDirection.ltr,
          style: AppTextStyles.number.copyWith(
            color: item.status.color,
            fontSize: 22,
          ),
        ),
        const Text('وحدة', style: AppTextStyles.caption),
        const SizedBox(height: 6),
        const Icon(
          Icons.arrow_back_rounded,
          size: 17,
          color: AppColors.neutral500,
        ),
      ],
    );
  }
}
