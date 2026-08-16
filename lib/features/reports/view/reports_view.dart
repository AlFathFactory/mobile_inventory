import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_components.dart';
import '../../inventory/widgets/movement_card.dart';
import '../controller/reports_controller.dart';
import '../widgets/report_filters.dart';

class ReportsView extends StatelessWidget {
  const ReportsView({required this.controller, super.key});

  final ReportsController controller;

  @override
  Widget build(BuildContext context) {
    return ResponsivePage(
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, child) {
          final movements = controller.visibleMovements;
          final snapshot = controller.snapshot;
          return Column(
            children: [
              const PageHeader(title: 'التقارير'),
              const SizedBox(height: 14),
              ReportFilters(controller: controller),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SummaryCard(
                      label: 'إجمالي الحركات',
                      value: '${snapshot.total}',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SummaryCard(
                      label: 'صرف',
                      value: '${snapshot.issues}',
                      valueColor: AppColors.accent,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SummaryCard(
                      label: 'إضافة',
                      value: '${snapshot.additions}',
                      valueColor: AppColors.safe,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: movements.isEmpty
                    ? const SingleChildScrollView(
                        child: EmptyState(title: 'لا توجد حركات مطابقة'),
                      )
                    : ListView.separated(
                        key: const PageStorageKey('reports-list'),
                        itemCount: movements.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) => MovementCard(
                          key: ValueKey(movements[index].id),
                          movement: movements[index],
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
