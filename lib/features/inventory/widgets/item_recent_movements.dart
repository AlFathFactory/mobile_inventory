import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/status_visuals.dart';
import '../model/inventory_movement.dart';

class ItemRecentMovements extends StatelessWidget {
  const ItemRecentMovements({
    required this.movements,
    required this.onViewAll,
    super.key,
  });

  final List<InventoryMovement> movements;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('أحدث الحركات', style: AppTextStyles.sectionTitle),
            ),
            if (movements.isNotEmpty)
              Text('آخر ${movements.length}', style: AppTextStyles.caption),
          ],
        ),
        const SizedBox(height: 10),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
          ),
          child: movements.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(
                        Icons.history_toggle_off_rounded,
                        color: AppColors.neutral500,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'لا توجد حركات مسجلة لهذا الصنف.',
                          style: AppTextStyles.body,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        14,
                        14,
                        14,
                        6,
                      ),
                      child: Column(
                        children: [
                          for (var index = 0; index < movements.length; index++)
                            _RecentMovementRow(
                              movement: movements[index],
                              showConnector: index != movements.length - 1,
                            ),
                        ],
                      ),
                    ),
                    Material(
                      color: AppColors.accentVerySoft,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(22),
                      ),
                      child: InkWell(
                        key: const Key('open-movement-history'),
                        onTap: onViewAll,
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(22),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.history_rounded,
                                size: 19,
                                color: AppColors.accent,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'عرض سجل الحركات الكامل',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: false,
                                  style: AppTextStyles.label.copyWith(
                                    color: AppColors.accentDark,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_back_rounded,
                                size: 19,
                                color: AppColors.accent,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _RecentMovementRow extends StatelessWidget {
  const _RecentMovementRow({
    required this.movement,
    required this.showConnector,
  });

  final InventoryMovement movement;
  final bool showConnector;

  IconData get _icon => switch (movement.type) {
    MovementType.addition => Icons.south_west_rounded,
    MovementType.issue => Icons.north_east_rounded,
    MovementType.returned => Icons.keyboard_return_rounded,
    MovementType.adjustment => Icons.tune_rounded,
  };

  String get _quantity {
    final value = movement.quantity.abs();
    return switch (movement.type) {
      MovementType.addition || MovementType.returned => '+$value',
      MovementType.issue => '-$value',
      MovementType.adjustment => movement.quantity > 0 ? '+$value' : '-$value',
    };
  }

  String get _date =>
      '${movement.date.day}/${movement.date.month}/${movement.date.year}';

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 38,
            child: Column(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: movement.type.background,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox.square(
                    dimension: 36,
                    child: Icon(_icon, size: 18, color: movement.type.color),
                  ),
                ),
                if (showConnector)
                  Expanded(
                    child: Container(
                      width: 1,
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      color: AppColors.divider,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: showConnector ? 16 : 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(movement.type.label, style: AppTextStyles.cardTitle),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          movement.project,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 5),
                        child: Text('·', style: AppTextStyles.caption),
                      ),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(_date, style: AppTextStyles.caption),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _quantity,
            textDirection: TextDirection.ltr,
            style: AppTextStyles.number.copyWith(
              color: movement.type.color,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}
