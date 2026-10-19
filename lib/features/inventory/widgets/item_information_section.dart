import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../model/inventory_item.dart';

class ItemInformationSection extends StatelessWidget {
  const ItemInformationSection({required this.item, super.key});

  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    final entries = <_InformationEntry>[
      _InformationEntry(
        icon: Icons.location_on_outlined,
        label: 'المشروع',
        value: item.project,
      ),
      if (item.supplier case final supplier?)
        _InformationEntry(
          icon: Icons.local_shipping_outlined,
          label: 'المورد',
          value: supplier,
        ),
      if (item.expiry case final expiry? when item.tableName != 'paints')
        _InformationEntry(
          icon: Icons.event_outlined,
          label: 'تاريخ الانتهاء',
          value: expiry,
        ),
      _InformationEntry(
        icon: Icons.low_priority_rounded,
        label: 'الحد الأدنى للمخزون',
        value: '${item.minimum} وحدة',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('معلومات الصنف', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 10),
        AppCard(
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              for (var index = 0; index < entries.length; index++) ...[
                _InformationRow(entry: entries[index]),
                if (index != entries.length - 1) const SizedBox(height: 14),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class ItemCategoryAttributesSection extends StatelessWidget {
  const ItemCategoryAttributesSection({required this.item, super.key});

  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    final attributes = item.categorySpecificAttributes;
    if (attributes.isEmpty) return const SizedBox.shrink();

    return Column(
      key: const Key('item-category-attributes'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('تفاصيل الصنف', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 10),
        AppCard(
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              for (var index = 0; index < attributes.length; index++) ...[
                _InformationRow(
                  entry: _InformationEntry(
                    icon: Icons.tune_outlined,
                    label: attributes[index].label,
                    value: _formatDate(attributes[index].value),
                  ),
                ),
                if (index != attributes.length - 1) const SizedBox(height: 14),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(String value) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(value);
    if (match == null) return value;
    return '${match.group(3)}/${match.group(2)}/${match.group(1)}';
  }
}

class _InformationRow extends StatelessWidget {
  const _InformationRow({required this.entry});

  final _InformationEntry entry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(12),
          ),
          child: SizedBox.square(
            dimension: 38,
            child: Icon(entry.icon, size: 18, color: AppColors.neutral700),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.label, style: AppTextStyles.caption),
              const SizedBox(height: 1),
              Text(
                entry.value,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InformationEntry {
  const _InformationEntry({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}
