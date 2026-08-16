import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_components.dart';
import '../controller/inventory_controller.dart';
import '../model/inventory_item.dart';
import '../widgets/inventory_filter_sheet.dart';
import '../widgets/inventory_item_card.dart';

class InventoryView extends StatefulWidget {
  const InventoryView({
    required this.controller,
    required this.onOpenItem,
    super.key,
  });

  final InventoryController controller;
  final ValueChanged<InventoryItem> onOpenItem;

  @override
  State<InventoryView> createState() => _InventoryViewState();
}

class _InventoryViewState extends State<InventoryView> {
  late final TextEditingController _searchController = TextEditingController(
    text: widget.controller.query,
  );

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsivePage(
      child: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, child) {
          final isLoading = widget.controller.isLoading;
          final items = isLoading
              ? widget.controller.allItems.take(5).toList(growable: false)
              : widget.controller.visibleItems;
          return Column(
            children: [
              const PageHeader(title: 'المخزون'),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('inventory-search'),
                      controller: _searchController,
                      onChanged: widget.controller.setQuery,
                      textInputAction: TextInputAction.search,
                      decoration: const InputDecoration(
                        hintText: 'ابحث باسم الصنف أو الكود',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Badge(
                    isLabelVisible: !widget.controller.filter.isEmpty,
                    label: Text('${widget.controller.filter.selectionCount}'),
                    child: IconButton.outlined(
                      key: const Key('open-inventory-filters'),
                      onPressed: () =>
                          showInventoryFilterSheet(context, widget.controller),
                      icon: const Icon(Icons.tune_rounded),
                      tooltip: 'فلترة',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 11),
              FilterChipBar<StockStatus?>(
                options: const [
                  FilterChipOption(value: null, label: 'الكل'),
                  FilterChipOption(value: StockStatus.safe, label: 'آمن'),
                  FilterChipOption(value: StockStatus.low, label: 'منخفض'),
                ],
                selected: widget.controller.quickStatus,
                onSelected: widget.controller.setQuickStatus,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('${items.length} أصناف', style: AppTextStyles.label),
                  const Spacer(),
                  const Icon(
                    Icons.swap_vert_rounded,
                    size: 16,
                    color: AppColors.neutral500,
                  ),
                  const SizedBox(width: 3),
                  const Text('مرتبة: آخر حركة', style: AppTextStyles.caption),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: items.isEmpty
                    ? const SingleChildScrollView(
                        child: EmptyState(title: 'لا توجد أصناف مطابقة'),
                      )
                    : ListView.separated(
                        key: const PageStorageKey('inventory-list'),
                        itemCount: items.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return InventoryItemCard(
                            key: ValueKey(item.code),
                            item: item,
                            onTap: () => widget.onOpenItem(item),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
