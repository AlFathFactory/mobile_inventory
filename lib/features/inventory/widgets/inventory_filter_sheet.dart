import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/status_visuals.dart';
import '../controller/inventory_controller.dart';
import '../model/inventory_filter.dart';
import '../model/inventory_item.dart';

Future<void> showInventoryFilterSheet(
  BuildContext context,
  InventoryController controller,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    clipBehavior: Clip.antiAlias,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => InventoryFilterSheet(controller: controller),
  );
}

class InventoryFilterSheet extends StatefulWidget {
  const InventoryFilterSheet({required this.controller, super.key});

  final InventoryController controller;

  @override
  State<InventoryFilterSheet> createState() => _InventoryFilterSheetState();
}

class _InventoryFilterSheetState extends State<InventoryFilterSheet> {
  late Set<StockStatus> _statuses = {...widget.controller.filter.statuses};
  late Set<String> _categories = {...widget.controller.filter.categories};
  late Set<String> _projects = {...widget.controller.filter.projects};

  InventoryFilter get _draft => InventoryFilter(
    statuses: _statuses,
    categories: _categories,
    projects: _projects,
  );

  int get _resultCount => widget.controller.resultCountFor(_draft);

  void _toggle<T>(Set<T> values, T value, bool selected) {
    setState(() => selected ? values.add(value) : values.remove(value));
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.88,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'تصفية المخزون',
                        style: AppTextStyles.sectionTitle,
                      ),
                      Text(
                        'اختر ما يساعدك للوصول إلى الصنف',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.neutral600,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _statuses = {};
                    _categories = {};
                    _projects = {};
                  }),
                  child: const Text('مسح الكل'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _FilterSection<StockStatus>(
                  title: 'الحالة',
                  values: StockStatus.values,
                  selectedValues: _statuses,
                  labelFor: (value) => value.label,
                  onChanged: (value, selected) =>
                      _toggle(_statuses, value, selected),
                ),
                const SizedBox(height: 22),
                _FilterSection<String>(
                  title: 'التصنيف',
                  values: widget.controller.categories,
                  selectedValues: _categories,
                  labelFor: (value) => value,
                  onChanged: (value, selected) =>
                      _toggle(_categories, value, selected),
                ),
                const SizedBox(height: 22),
                _FilterSection<String>(
                  title: 'المشروع',
                  values: widget.controller.projects,
                  selectedValues: _projects,
                  labelFor: (value) => value,
                  onChanged: (value, selected) =>
                      _toggle(_projects, value, selected),
                ),
              ],
            ),
          ),
          DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 18,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('إلغاء'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        key: const Key('apply-inventory-filters'),
                        onPressed: () {
                          widget.controller.applyFilters(_draft);
                          Navigator.pop(context);
                        },
                        child: Text('عرض $_resultCount نتائج'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterSection<T> extends StatelessWidget {
  const _FilterSection({
    required this.title,
    required this.values,
    required this.selectedValues,
    required this.labelFor,
    required this.onChanged,
  });

  final String title;
  final List<T> values;
  final Set<T> selectedValues;
  final String Function(T value) labelFor;
  final void Function(T value, bool selected) onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.cardTitle),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final value in values)
              FilterChip(
                label: Text(labelFor(value)),
                selected: selectedValues.contains(value),
                showCheckmark: false,
                onSelected: (selected) => onChanged(value, selected),
              ),
          ],
        ),
      ],
    );
  }
}
