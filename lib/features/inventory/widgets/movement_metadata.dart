import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../model/inventory_movement.dart';

/// Secondary movement information.
///
/// Renders a compact row per available field only — never empty rows.
class MovementMetadata extends StatelessWidget {
  const MovementMetadata({required this.movement, super.key});

  final InventoryMovement movement;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      _MetadataRow(icon: Icons.location_on_outlined, value: movement.project),
      if (movement.partyName case final partyName?)
        _MetadataRow(
          icon: Icons.person_outline_rounded,
          value: '${movement.partyLabel ?? 'الجهة'}: $partyName',
        ),
      if (movement.purchaseOrder case final order?)
        _MetadataRow(
          icon: Icons.receipt_long_outlined,
          label: 'أمر الشراء',
          value: order,
          valueDirection: TextDirection.ltr,
        ),
      if (movement.note case final note?)
        _MetadataRow(icon: Icons.notes_rounded, value: note),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < rows.length; index++) ...[
          if (index != 0) const SizedBox(height: 4),
          rows[index],
        ],
      ],
    );
  }
}

class _MetadataRow extends StatelessWidget {
  const _MetadataRow({
    required this.icon,
    required this.value,
    this.label,
    this.valueDirection,
  });

  final IconData icon;
  final String value;
  final String? label;
  final TextDirection? valueDirection;

  @override
  Widget build(BuildContext context) {
    final content = Text(
      value,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.caption,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: AppColors.neutral500),
        const SizedBox(width: 5),
        if (label == null)
          Expanded(child: content)
        else ...[
          Text('$label:', style: AppTextStyles.caption),
          const SizedBox(width: 4),
          Expanded(
            child: valueDirection == null
                ? content
                : Directionality(
                    textDirection: valueDirection!,
                    child: content,
                  ),
          ),
        ],
      ],
    );
  }
}
