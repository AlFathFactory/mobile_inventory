import 'package:flutter/material.dart';

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
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ReportsHeader(totalCount: snapshot.total),
              const SizedBox(height: 16),
              ReportsOverview(snapshot: snapshot),
              const SizedBox(height: 13),
              ReportsPeriodSelector(
                period: controller.period,
                hasCustomRange: controller.dateRange != null,
                onSelectPeriod: controller.selectPeriod,
                onPickCustom: () => _pickCustomRange(context),
              ),
              const SizedBox(height: 12),
              ReportFilters(controller: controller),
              const SizedBox(height: 15),
              ReportsResultsHeader(
                count: movements.length,
                hasActiveFilters: controller.hasActiveFilters,
                onClear: controller.clearFilters,
              ),
              const SizedBox(height: 9),
              Expanded(
                child: movements.isEmpty
                    ? SingleChildScrollView(
                        child: ReportsEmptyState(
                          hasActiveFilters: controller.hasActiveFilters,
                        ),
                      )
                    : ListView(
                        key: const PageStorageKey('reports-list'),
                        padding: const EdgeInsets.only(bottom: 12),
                        children: [ReportsMovementList(movements: movements)],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
