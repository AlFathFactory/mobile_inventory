import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/status_visuals.dart';
import '../../../core/widgets/section_header.dart';
import '../../inventory/model/inventory_movement.dart';

class RecentActivitySection extends StatelessWidget {
  const RecentActivitySection({
    required this.movements,
    required this.onShowReports,
    super.key,
  });

  final List<InventoryMovement> movements;
  final VoidCallback onShowReports;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'أحدث حركات المخزون'),
        const SizedBox(height: 5),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(14, 14, 14, 8),
            child: Column(
              children: [
                for (var index = 0; index < movements.length; index++)
                  _ActivityItem(
                    key: ValueKey('dashboard-${movements[index].id}'),
                    movement: movements[index],
                    showConnector: index != movements.length - 1,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 11),
        Material(
          color: AppColors.accentVerySoft,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            key: const Key('open-reports-from-dashboard'),
            onTap: onShowReports,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
              child: Row(
                children: [
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.accentSoft,
                      shape: BoxShape.circle,
                    ),
                    child: SizedBox.square(
                      dimension: 38,
                      child: Icon(
                        Icons.insights_rounded,
                        color: AppColors.accentDark,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تقارير وحركة المخزون',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.text,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'استكشف التفاصيل والاتجاهات',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.accent,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActivityItem extends StatelessWidget {
  const _ActivityItem({
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

  String get _description => switch (movement.type) {
    MovementType.addition => 'تمت إضافة ${movement.quantity} وحدة',
    MovementType.issue => 'تم صرف ${movement.quantity} وحدات',
    MovementType.returned => 'تم إرجاع ${movement.quantity} وحدات',
    MovementType.adjustment => 'تمت تسوية ${movement.quantity} وحدات',
  };

  String get _date =>
      '${movement.date.day}/${movement.date.month}/${movement.date.year}';

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 40,
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
              padding: EdgeInsets.only(bottom: showConnector ? 16 : 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_description, style: AppTextStyles.cardTitle),
                  const SizedBox(height: 2),
                  Text(
                    movement.itemName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          movement.project,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.neutral700,
                          ),
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
        ],
      ),
    );
  }
}
