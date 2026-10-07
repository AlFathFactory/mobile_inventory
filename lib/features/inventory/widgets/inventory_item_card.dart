import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/status_visuals.dart';
import '../../../core/widgets/app_components.dart';
import '../model/inventory_item.dart';
import 'inventory_category_icon.dart';

class InventoryItemCard extends StatelessWidget {
  const InventoryItemCard({
    required this.item,
    super.key,
    this.onTap,
    this.showCatalogueContext = false,
  });

  final InventoryItem item;
  final VoidCallback? onTap;
  final bool showCatalogueContext;

  @override
  Widget build(BuildContext context) {
    if (showCatalogueContext) {
      return _CatalogueItemCard(item: item, onTap: onTap);
    }
    return _CompactItemCard(item: item, onTap: onTap);
  }
}

class _CatalogueItemCard extends StatelessWidget {
  const _CatalogueItemCard({required this.item, required this.onTap});

  final InventoryItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsetsDirectional.fromSTEB(12, 12, 10, 12),
      child: Row(
        children: [
          InventoryCategoryIcon(category: item.category, size: 50),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                const SizedBox(height: 8),
                Row(
                  children: [
                    Flexible(
                      child: _ContextLabel(
                        icon: Icons.category_outlined,
                        label: item.category,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Text('·', style: AppTextStyles.caption),
                    ),
                    Flexible(
                      child: _ContextLabel(
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
          _CatalogueQuantity(item: item),
        ],
      ),
    );
  }
}

class _ContextLabel extends StatelessWidget {
  const _ContextLabel({required this.icon, required this.label});

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

class _CatalogueQuantity extends StatelessWidget {
  const _CatalogueQuantity({required this.item});

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
        Text('وحدة', style: AppTextStyles.caption),
        const SizedBox(height: 7),
        StatusBadge(item.status),
      ],
    );
  }
}

class _CompactItemCard extends StatelessWidget {
  const _CompactItemCard({required this.item, required this.onTap});

  final InventoryItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(width: 4, color: item.status.color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 11, 14, 11),
                child: Row(
                  children: [
                    _ItemIcon(item: item),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.cardTitle,
                          ),
                          const SizedBox(height: 4),
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text(
                              item.code,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.code,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _QuantityBadge(item: item),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemIcon extends StatelessWidget {
  const _ItemIcon({required this.item});

  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: item.status.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        Icons.inventory_2_outlined,
        size: 20,
        color: item.status.color,
      ),
    );
  }
}

class _QuantityBadge extends StatelessWidget {
  const _QuantityBadge({required this.item});

  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 54),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: item.status.background,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Text(
        '${item.quantity}',
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        style: AppTextStyles.number.copyWith(
          color: item.status.color,
          fontSize: 20,
        ),
      ),
    );
  }
}
