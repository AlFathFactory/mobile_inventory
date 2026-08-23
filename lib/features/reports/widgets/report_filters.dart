import 'package:flutter/material.dart';

import '../../../core/widgets/app_components.dart';
import '../../inventory/model/inventory_movement.dart';
import '../controller/reports_controller.dart';
import '../model/report_filter.dart';
import 'report_date_range_picker.dart';

class ReportFilters extends StatelessWidget {
  const ReportFilters({required this.controller, super.key});

  final ReportsController controller;

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final dateRange = controller.dateRange;
    final customPeriodLabel = dateRange == null
        ? 'تحديد التاريخ'
        : '${localizations.formatShortDate(dateRange.start)}'
              ' – '
              '${localizations.formatShortDate(dateRange.end)}';
    final projectOptions = <String, String>{
      '': 'المشروع: الكل',
      for (final project in controller.projects) project: project,
    };
    final categoryOptions = <String, String>{
      '': 'التصنيف: الكل',
      for (final category in controller.categories) category: category,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            SizedBox(
              width: 180,
              height: 36,
              child: AppDropdown<ReportPeriod>(
                value: controller.period,
                hint: 'الفترة',
                options: {
                  ReportPeriod.last30Days: 'آخر 30 يوم',
                  ReportPeriod.all: 'كل الفترات',
                  ReportPeriod.custom: customPeriodLabel,
                },
                onChanged: (value) async {
                  if (value == null) return;
                  if (value == ReportPeriod.custom) {
                    final range = await showReportDateRangePicker(
                      context: context,
                      initialRange: controller.dateRange,
                    );
                    if (range != null) controller.selectDateRange(range);
                    return;
                  }
                  controller.selectPeriod(value);
                },
              ),
            ),
            SizedBox(
              width: 150,
              height: 36,
              child: AppDropdown<String>(
                value: controller.project ?? '',
                hint: 'المشروع',
                options: projectOptions,
                onChanged: (value) => controller.selectProject(
                  value == null || value.isEmpty ? null : value,
                ),
              ),
            ),
            SizedBox(
              width: 150,
              height: 36,
              child: AppDropdown<String>(
                value: controller.category ?? '',
                hint: 'التصنيف',
                options: categoryOptions,
                onChanged: (value) => controller.selectCategory(
                  value == null || value.isEmpty ? null : value,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        FilterChipBar<MovementType?>(
          options: const [
            FilterChipOption(value: null, label: 'الكل'),
            FilterChipOption(value: MovementType.addition, label: 'إضافة'),
            FilterChipOption(value: MovementType.issue, label: 'صرف'),
            FilterChipOption(value: MovementType.returned, label: 'مرتجع'),
          ],
          selected: controller.selectedType,
          onSelected: controller.selectType,
        ),
      ],
    );
  }
}
