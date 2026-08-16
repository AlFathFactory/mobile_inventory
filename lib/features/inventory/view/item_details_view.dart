import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_components.dart';
import '../../../core/router/app_routes.dart';
import '../model/inventory_item.dart';
import '../model/inventory_movement.dart';
import '../widgets/movement_card.dart';

class ItemDetailsView extends StatelessWidget {
  const ItemDetailsView({
    required this.item,
    required this.movements,
    super.key,
  });

  final InventoryItem item;
  final List<InventoryMovement> movements;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل الصنف')),
      body: SafeArea(
        top: false,
        child: ResponsivePage(
          child: ListView(
            key: const Key('item-details-list'),
            children: [
              Text(item.name, style: AppTextStyles.pageTitle),
              const SizedBox(height: 4),
              Row(
                children: [
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(item.code, style: AppTextStyles.code),
                  ),
                  const SizedBox(width: 10),
                  StatusBadge(item.status),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: SummaryCard(
                      label: 'الرصيد الحالي',
                      value: '${item.quantity}',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SummaryCard(
                      label: 'الحد الأدنى',
                      value: '${item.minimum}',
                      valueColor: AppColors.neutral700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  children: [
                    KeyValueRow(label: 'التصنيف', value: item.category),
                    const Divider(height: 1),
                    KeyValueRow(label: 'المشروع', value: item.project),
                    if (item.supplier != null) ...[
                      const Divider(height: 1),
                      KeyValueRow(label: 'المورد', value: item.supplier!),
                    ],
                    const Divider(height: 1),
                    KeyValueRow(label: 'الكود الداخلي', value: item.code),
                    if (item.expiry != null) ...[
                      const Divider(height: 1),
                      KeyValueRow(label: 'تاريخ الانتهاء', value: item.expiry!),
                    ],
                    if (item.notes != null) ...[
                      const Divider(height: 1),
                      KeyValueRow(label: 'ملاحظات', value: item.notes!),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const SectionHeader(title: 'سجل الحركات'),
              const SizedBox(height: 5),
              // DecoratedBox(
              //   decoration: BoxDecoration(
              //     color: AppColors.accentVerySoft,
              //     borderRadius: BorderRadius.circular(8),
              //     border: Border.all(color: AppColors.accentSoft),
              //   ),
              //   child: const Padding(
              //     padding: EdgeInsets.all(12),
              //     child: Text(
              //       'الحركات التالية بيانات تاريخية تعكس ما حدث وقت العملية — قد يختلف المشروع أو المورد المسجّل بها عن بيانات الصنف الحالية.',
              //       style: AppTextStyles.caption,
              //     ),
              //   ),
              // ),
              const SizedBox(height: 12),
              if (movements.isEmpty)
                const EmptyState(
                  title: 'لا يوجد سجل تجريبي لهذا الصنف',
                  message: 'ستظهر الحركات هنا عند ربط مصدر البيانات.',
                )
              else ...[
                MovementCard(movement: movements.first, showItem: false),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  key: const Key('open-movement-history'),
                  onPressed: () => context.pushNamed(
                    AppRouteNames.itemHistory,
                    pathParameters: {'code': item.code},
                  ),
                  icon: const Icon(Icons.history_rounded),
                  label: const Text('عرض السجل الكامل'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
