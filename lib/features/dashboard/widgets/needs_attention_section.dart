import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/status_visuals.dart';
import '../../../core/widgets/section_header.dart';
import '../../inventory/model/inventory_item.dart';

class NeedsAttentionSection extends StatelessWidget {
  const NeedsAttentionSection({
    required this.items,
    required this.onShowAll,
    super.key,
  });

  final List<InventoryItem> items;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'يحتاج انتباهك',
          actionLabel: 'كل التنبيهات',
          onAction: onShowAll,
        ),
        Text(
          'أصناف اقتربت من الحد الأدنى أو نفدت',
          style: AppTextStyles.caption,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 138,
          child: ListView.separated(
            key: const Key('dashboard-attention-items'),
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) => SizedBox(
              width: 236,
              child: _AttentionItem(item: items[index], onTap: onShowAll),
            ),
          ),
        ),
      ],
    );
  }
}

class _AttentionItem extends StatelessWidget {
  const _AttentionItem({required this.item, required this.onTap});

  final InventoryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: item.status.background,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    item.status == StockStatus.outOfStock
                        ? Icons.error_outline_rounded
                        : Icons.warning_amber_rounded,
                    size: 20,
                    color: item.status.color,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    item.status.label,
                    style: AppTextStyles.label.copyWith(
                      color: item.status.color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${item.quantity} وحدة',
                    textDirection: TextDirection.rtl,
                    style: AppTextStyles.label.copyWith(
                      color: item.status.color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                item.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.cardTitle,
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        item.code,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.code.copyWith(
                          color: AppColors.neutral700,
                        ),
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_back_rounded,
                    size: 18,
                    color: AppColors.neutral700,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
