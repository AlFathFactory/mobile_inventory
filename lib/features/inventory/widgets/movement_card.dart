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

  String get _formattedDate =>
      '${movement.date.day} ${_months[movement.date.month - 1]} ${movement.date.year}';

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _MovementIcon(type: movement.type),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        showItem ? movement.itemName : movement.type.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.cardTitle,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        showItem
                            ? '${movement.category} · ${movement.project}'
                            : _formattedDate,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption,
                      ),
                      if (showItem) ...[
                        const SizedBox(height: 7),
                        Wrap(
                          spacing: 8,
                          runSpacing: 5,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _TypeBadge(type: movement.type),
                            _MetaItem(
                              icon: Icons.calendar_today_outlined,
                              label: _formattedDate,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _QuantityBadge(movement: movement),
              ],
            ),
          ),

          if (_hasDetails) ...[
            const Divider(height: 1, color: AppColors.divider),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Column(
                children: [
                  if (movement.partyName != null)
                    _DetailRow(
                      icon: Icons.person_outline_rounded,
                      label: movement.partyLabel ?? 'الجهة',
                      value: movement.partyName!,
                    ),
                  if (movement.purchaseOrder != null)
                    _DetailRow(
                      icon: Icons.receipt_long_outlined,
                      label: 'أمر الشراء',
                      value: movement.purchaseOrder!,
                    ),
                  if (movement.note != null)
                    _DetailRow(
                      icon: Icons.notes_rounded,
                      label: 'ملاحظة',
                      value: movement.note!,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool get _hasDetails =>
      movement.partyName != null ||
      movement.purchaseOrder != null ||
      movement.note != null;
}

class _MovementIcon extends StatelessWidget {
  const _MovementIcon({required this.type});

  final MovementType type;

  IconData get _icon => switch (type) {
    MovementType.addition => Icons.add_rounded,
    MovementType.issue => Icons.north_east_rounded,
    MovementType.returned => Icons.keyboard_return_rounded,
    MovementType.adjustment => Icons.tune_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: type.color,
        borderRadius: BorderRadius.circular(11),
        boxShadow: [
          BoxShadow(
            color: type.color.withAlpha(45),
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(_icon, size: 22, color: Colors.white),
    );
  }
}

class _QuantityBadge extends StatelessWidget {
  const _QuantityBadge({required this.movement});

  final InventoryMovement movement;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 54),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: movement.type.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${movement.quantity}',
            textDirection: TextDirection.ltr,
            style: AppTextStyles.number.copyWith(
              color: movement.type.color,
              fontSize: 18,
            ),
          ),
          Text(
            'وحدة',
            style: AppTextStyles.caption.copyWith(
              color: movement.type.color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});

  final MovementType type;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: type.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          type.label,
          style: AppTextStyles.caption.copyWith(
            color: type.color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.neutral500),
        const SizedBox(width: 4),
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.neutral500),
          const SizedBox(width: 7),
          SizedBox(width: 50, child: Text(label, style: AppTextStyles.caption)),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.label.copyWith(color: AppColors.text),
            ),
          ),
        ],
      ),
    );
  }
}
