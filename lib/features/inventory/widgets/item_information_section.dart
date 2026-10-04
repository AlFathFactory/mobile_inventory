import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
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
      if (item.expiry case final expiry?)
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
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Padding(
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
        ),
      ],
    );
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
