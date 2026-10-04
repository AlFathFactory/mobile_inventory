import 'package:flutter/material.dart';

import '../../../core/widgets/responsive_page.dart';
import '../controller/inventory_controller.dart';
import '../model/inventory_item.dart';
import '../widgets/inventory_category_bar.dart';
import '../widgets/inventory_empty_state.dart';
import '../widgets/inventory_filter_sheet.dart';
import '../widgets/inventory_header.dart';
import '../widgets/inventory_item_card.dart';
import '../widgets/inventory_results_header.dart';
import '../widgets/inventory_search_toolbar.dart';
import '../widgets/inventory_status_filters.dart';

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

  void _clearSearch() {
    _searchController.clear();
    widget.controller.setQuery('');
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InventoryHeader(totalCount: widget.controller.allItems.length),
              const SizedBox(height: 16),
              InventorySearchToolbar(
                controller: _searchController,
                showClear: widget.controller.query.isNotEmpty,
                filterCount: widget.controller.filter.selectionCount,
                onChanged: widget.controller.setQuery,
                onClear: _clearSearch,
                onFilterTap: () =>
                    showInventoryFilterSheet(context, widget.controller),
              ),
              const SizedBox(height: 13),
              InventoryStatusFilters(
                selected: widget.controller.quickStatus,
                onSelected: widget.controller.setQuickStatus,
              ),
              const SizedBox(height: 15),
              InventoryCategoryBar(
                categories: widget.controller.categories,
                selectedCategories: widget.controller.filter.categories,
                onSelected: widget.controller.setBrowseCategory,
              ),
              const SizedBox(height: 15),
              InventoryResultsHeader(
                resultCount: items.length,
                hasFilters:
                    widget.controller.quickStatus != null ||
                    !widget.controller.filter.isEmpty,
              ),
              const SizedBox(height: 9),
              Expanded(
                child: items.isEmpty
                    ? SingleChildScrollView(
                        child: InventoryEmptyState(
                          query: widget.controller.query,
                        ),
                      )
                    : ListView.separated(
                        key: const PageStorageKey('inventory-list'),
                        padding: const EdgeInsets.only(bottom: 12),
                        itemCount: items.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 9),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return InventoryItemCard(
                            key: ValueKey(item.code),
                            item: item,
                            showCatalogueContext: true,
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
