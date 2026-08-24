import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../inventory/model/inventory_movement.dart';
import '../controller/reports_controller.dart';
import '../model/report_filter.dart';
import 'report_date_range_picker.dart';

class ReportFilters extends StatelessWidget {
  const ReportFilters({required this.controller, super.key});

  final ReportsController controller;

  int get _secondaryFilterCount =>
      (controller.selectedType != null ? 1 : 0) +
      (controller.project != null ? 1 : 0) +
      (controller.category != null ? 1 : 0);

  @override
  Widget build(BuildContext context) {
    final l10n = MaterialLocalizations.of(context);
    final range = controller.dateRange;
    final dateLabel = switch (controller.period) {
      ReportPeriod.custom when range != null =>
        DateUtils.isSameDay(range.start, range.end)
            ? l10n.formatShortDate(range.start)
            : '${l10n.formatShortDate(range.start)} – '
                  '${l10n.formatShortDate(range.end)}',
      ReportPeriod.last30Days => 'آخر 30 يوم',
      _ => 'كل الأيام',
    };

    return Row(
      children: [
        Expanded(
          child: _CompactAction(
            key: const Key('report-date-filter'),
            icon: Icons.calendar_today_rounded,
            label: dateLabel,
            selected: controller.period != ReportPeriod.all,
            onTap: () async {
              final selected = await showReportDateRangePicker(
                context: context,
                initialRange: controller.dateRange,
              );
              if (selected != null) controller.selectDateRange(selected);
            },
            onClear: controller.period == ReportPeriod.all
                ? null
                : () => controller.selectPeriod(ReportPeriod.all),
          ),
        ),
        const SizedBox(width: 8),
        _CompactAction(
          key: const Key('open-more-report-filters'),
          icon: Icons.tune_rounded,
          label: 'الفلاتر',
          selected: _secondaryFilterCount > 0,
          badge: _secondaryFilterCount,
          onTap: () => _showFilterSheet(context),
        ),
      ],
    );
  }

  Future<void> _showFilterSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      constraints: const BoxConstraints(maxWidth: 600),
      builder: (sheetContext) => ListenableBuilder(
        listenable: controller,
        builder: (context, child) {
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              20,
              0,
              20,
              20 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'تصفية النتائج',
                        style: AppTextStyles.sectionTitle,
                      ),
                    ),
                    if (controller.hasActiveFilters)
                      TextButton(
                        key: const Key('clear-report-filters'),
                        onPressed: controller.clearFilters,
                        child: const Text('مسح الكل'),
                      ),
                  ],
                ),
                Text(
                  'اختر ما تحتاجه فقط، ويمكنك تغييره في أي وقت.',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 18),
                const _FilterLabel('نوع الحركة'),
                const SizedBox(height: 8),
                _MovementTypeBar(
                  selected: controller.selectedType,
                  onSelected: controller.selectType,
                ),
                const SizedBox(height: 18),
                _SheetSelect(
                  key: const Key('report-project-filter'),
                  label: 'المشروع',
                  icon: Icons.business_center_outlined,
                  value: controller.project,
                  allLabel: 'كل المشاريع',
                  options: controller.projects,
                  onChanged: controller.selectProject,
                ),
                const SizedBox(height: 14),
                _SheetSelect(
                  key: const Key('report-category-filter'),
                  label: 'التصنيف',
                  icon: Icons.category_outlined,
                  value: controller.category,
                  allLabel: 'كل التصنيفات',
                  options: controller.categories,
                  onChanged: controller.selectCategory,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    key: const Key('apply-report-filters'),
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('عرض النتائج'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CompactAction extends StatelessWidget {
  const _CompactAction({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
    this.onClear,
    this.badge = 0,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.accent : AppColors.neutral800;
    return Material(
      color: selected ? AppColors.accentVerySoft : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? AppColors.accentSoft : AppColors.neutral300,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 46,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 19, color: color),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.label.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (badge > 0) ...[
                  const SizedBox(width: 7),
                  Container(
                    constraints: const BoxConstraints(minWidth: 20),
                    height: 20,
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      badge.toString(),
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                if (onClear != null) ...[
                  const SizedBox(width: 4),
                  InkResponse(
                    key: const Key('clear-report-date-filter'),
                    onTap: onClear,
                    radius: 18,
                    child: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterLabel extends StatelessWidget {
  const _FilterLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: AppTextStyles.label.copyWith(
      color: AppColors.neutral800,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _SheetSelect extends StatelessWidget {
  const _SheetSelect({
    required this.label,
    required this.icon,
    required this.value,
    required this.allLabel,
    required this.options,
    required this.onChanged,
    super.key,
  });

  final String label;
  final IconData icon;
  final String? value;
  final String allLabel;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      key: ValueKey('$label-${value ?? 'all'}'),
      initialValue: value ?? '',
      isExpanded: true,
      borderRadius: BorderRadius.circular(16),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: AppColors.accent),
        fillColor: AppColors.surfaceMuted,
      ),
      items: [
        DropdownMenuItem(value: '', child: Text(allLabel)),
        for (final option in options)
          DropdownMenuItem(value: option, child: Text(option)),
      ],
      onChanged: (selected) =>
          onChanged(selected == null || selected.isEmpty ? null : selected),
    );
  }
}

class _MovementTypeBar extends StatelessWidget {
  const _MovementTypeBar({required this.selected, required this.onSelected});

  final MovementType? selected;
  final ValueChanged<MovementType?> onSelected;

  @override
  Widget build(BuildContext context) {
    const options = <(MovementType?, String, Color, Color)>[
      (null, 'الكل', AppColors.accent, AppColors.accentVerySoft),
      (MovementType.addition, 'إضافة', AppColors.safe, AppColors.safeSoft),
      (MovementType.issue, 'صرف', AppColors.low, AppColors.lowSoft),
      (
        MovementType.returned,
        'مرتجع',
        AppColors.returnColor,
        AppColors.returnSoft,
      ),
    ];
    return Row(
      children: [
        for (var index = 0; index < options.length; index++) ...[
          Expanded(
            child: _TypeButton(
              option: options[index],
              selected: selected == options[index].$1,
              onTap: () => onSelected(options[index].$1),
            ),
          ),
          if (index != options.length - 1) const SizedBox(width: 7),
        ],
      ],
    );
  }
}

class _TypeButton extends StatelessWidget {
  const _TypeButton({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final (MovementType?, String, Color, Color) option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? option.$4 : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? option.$3 : AppColors.neutral300,
          width: selected ? 1.4 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('report-movement-${option.$2}'),
        onTap: onTap,
        child: SizedBox(
          height: 44,
          child: Center(
            child: Text(
              option.$2,
              maxLines: 1,
              style: AppTextStyles.caption.copyWith(
                color: selected ? option.$3 : AppColors.neutral700,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
