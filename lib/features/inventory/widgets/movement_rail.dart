import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/status_visuals.dart';
import '../model/inventory_movement.dart';

/// Shared timeline rail: soft semantic icon with an optional connector.
///
/// Used by both Movement History and Reports so the activity language
/// stays identical.
class MovementRail extends StatelessWidget {
  const MovementRail({
    required this.type,
    required this.showConnector,
    super.key,
  });

  final MovementType type;
  final bool showConnector;

  IconData get _icon => switch (type) {
    MovementType.addition => Icons.south_west_rounded,
    MovementType.issue => Icons.north_east_rounded,
    MovementType.returned => Icons.keyboard_return_rounded,
    MovementType.adjustment => Icons.tune_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 38,
      child: Column(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: type.background,
              shape: BoxShape.circle,
            ),
            child: SizedBox.square(
              dimension: 36,
              child: Icon(_icon, size: 18, color: type.color),
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
    );
  }
}
