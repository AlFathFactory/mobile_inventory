import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/status_visuals.dart';
import '../../inventory/model/inventory_movement.dart';
import '../../inventory/widgets/movement_metadata.dart';
import '../../inventory/widgets/movement_rail.dart';
import '../../inventory/widgets/quantity_transition.dart';

/// Reports flavor of the shared movement timeline language.
///
/// Same rail, metadata and balance treatment as Movement History, with
/// the item identity on top since the list spans multiple items.
class ReportsTimelineItem extends StatelessWidget {
  const ReportsTimelineItem({
    required this.movement,
    required this.showConnector,
    super.key,
  });

  final InventoryMovement movement;
  final bool showConnector;

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
          MovementRail(type: movement.type, showConnector: showConnector),
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
                          movement.itemName,
                          maxLines: 2,
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
                    child: Text(
                      movement.itemCode,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.code,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        movement.type.label,
                        style: AppTextStyles.caption.copyWith(
                          color: movement.type.color,
                          fontWeight: FontWeight.w700,
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
