import 'package:flutter/material.dart';

import '../../../core/theme/app_dimensions.dart';
import '../../../core/widgets/responsive_page.dart';
import '../controller/reports_controller.dart';
import '../widgets/report_date_range_picker.dart';
import '../widgets/report_filters.dart';
import '../widgets/reports_empty_state.dart';
import '../widgets/reports_header.dart';
import '../widgets/reports_movement_list.dart';
import '../widgets/reports_overview.dart';
import '../widgets/reports_period_selector.dart';
import '../widgets/reports_results_header.dart';

class ReportsView extends StatelessWidget {
  const ReportsView({required this.controller, super.key});

  final ReportsController controller;

  Future<void> _pickCustomRange(BuildContext context) async {
    final selected = await showReportDateRangePicker(
      context: context,
      initialRange: controller.dateRange,
    );
    if (selected != null) controller.selectDateRange(selected);
  }

  @override
  Widget build(BuildContext context) {
    return ResponsivePage(
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, child) {
          final movements = controller.visibleMovements;
          final snapshot = controller.snapshot;
          return CustomScrollView(
            key: const PageStorageKey('reports-list'),
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ReportsHeader(totalCount: snapshot.total),
                    const SizedBox(height: AppDimensions.space16),
                    ReportsOverview(snapshot: snapshot),
                    const SizedBox(height: AppDimensions.space12),
                    ReportsPeriodSelector(
                      period: controller.period,
                      hasCustomRange: controller.dateRange != null,
                      onSelectPeriod: controller.selectPeriod,
                      onPickCustom: () => _pickCustomRange(context),
                    ),
                    const SizedBox(height: AppDimensions.space12),
                    ReportFilters(controller: controller),
                    const SizedBox(height: AppDimensions.space16),
                    ReportsResultsHeader(
                      count: movements.length,
                      hasActiveFilters: controller.hasActiveFilters,
                      onClear: controller.clearFilters,
                    ),
                    const SizedBox(height: AppDimensions.space8),
                  ],
                ),
              ),
              if (movements.isEmpty)
                SliverToBoxAdapter(
                  child: ReportsEmptyState(
                    hasActiveFilters: controller.hasActiveFilters,
                  ),
                )
              else
                SliverToBoxAdapter(
                  child: ReportsMovementList(movements: movements),
                ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 12)),
            ],
          );
        },
      ),
    );
  }
}
