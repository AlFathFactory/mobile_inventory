import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/status_visuals.dart';
import '../model/inventory_movement.dart';

/// Lightweight single-surface summary: total plus per-type counts.
///
/// Only types that actually occurred are shown; nothing renders for an
/// empty history (the view shows an empty state instead).
class MovementHistorySummary extends StatelessWidget {
  const MovementHistorySummary({required this.movements, super.key});

  final List<InventoryMovement> movements;

  int _count(MovementType type) =>
      movements.where((movement) => movement.type == type).length;

  @override
  Widget build(BuildContext context) {
    final stats = <_SummaryStat>[
      _SummaryStat(
        label: 'إضافة',
        count: _count(MovementType.addition),
        color: MovementType.addition.color,
        background: MovementType.addition.background,
        signed: true,
      ),
      _SummaryStat(
        label: 'صرف',
        count: _count(MovementType.issue),
        color: MovementType.issue.color,
        background: MovementType.issue.background,
        signed: true,
      ),
      _SummaryStat(
        label: 'مرتجع',
        count: _count(MovementType.returned),
        color: MovementType.returned.color,
        background: MovementType.returned.background,
        signed: true,
      ),
      _SummaryStat(
        label: 'تسوية',
        count: _count(MovementType.adjustment),
        color: MovementType.adjustment.color,
        background: MovementType.adjustment.background,
        signed: false,
      ),
    ].where((stat) => stat.count > 0).toList(growable: false);

    return DecoratedBox(
      key: const Key('movement-history-summary'),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'ملخص السجل',
                    style: AppTextStyles.label.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                ),
                Text(
                  '${movements.length}',
                  textDirection: TextDirection.ltr,
                  style: AppTextStyles.caption,
                ),
                const SizedBox(width: 4),
                const Text('حركات', style: AppTextStyles.caption),
              ],
            ),
            if (stats.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [for (final stat in stats) _StatPill(stat: stat)],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryStat {
  const _SummaryStat({
    required this.label,
    required this.count,
    required this.color,
    required this.background,
    required this.signed,
  });

  final String label;
  final int count;
  final Color color;
  final Color background;
  final bool signed;
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.stat});

  final _SummaryStat stat;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: stat.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${stat.count}',
              textDirection: TextDirection.ltr,
              style: AppTextStyles.label.copyWith(
                color: stat.color,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              stat.label,
              style: AppTextStyles.caption.copyWith(
                color: stat.color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
