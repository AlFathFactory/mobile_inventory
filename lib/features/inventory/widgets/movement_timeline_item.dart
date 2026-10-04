import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/status_visuals.dart';
import '../model/inventory_movement.dart';
import 'movement_metadata.dart';
import 'quantity_transition.dart';

/// One entry of the movement history timeline.
///
/// Shows type, signed quantity, date, resulting balance and only the
/// metadata that is actually available.
class MovementTimelineItem extends StatelessWidget {
  const MovementTimelineItem({
    required this.movement,
    required this.showConnector,
    super.key,
  });

  final InventoryMovement movement;
  final bool showConnector;

  IconData get _icon => switch (movement.type) {
    MovementType.addition => Icons.south_west_rounded,
    MovementType.issue => Icons.north_east_rounded,
    MovementType.returned => Icons.keyboard_return_rounded,
    MovementType.adjustment => Icons.tune_rounded,
  };

  String get _signedQuantity {
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
              padding: EdgeInsets.only(bottom: showConnector ? 16 : 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          movement.type.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.cardTitle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _signedQuantity,
                        textDirection: TextDirection.ltr,
                        style: AppTextStyles.number.copyWith(
                          color: movement.type.color,
                          fontSize: 17,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(_date, style: AppTextStyles.caption),
                  ),
                  const SizedBox(height: 7),
                  QuantityTransition(
                    before: movement.before,
                    after: movement.after,
                  ),
                  const SizedBox(height: 7),
                  MovementMetadata(movement: movement),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
