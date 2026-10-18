import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_dimensions.dart';
import '../../../core/widgets/responsive_page.dart';
import '../cubit/inventory_cubit.dart';
import '../cubit/inventory_state.dart';
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
  const InventoryView({required this.onOpenItem, super.key});

  final ValueChanged<InventoryItem> onOpenItem;

  @override
  State<InventoryView> createState() => _InventoryViewState();
}

class _InventoryViewState extends State<InventoryView> {
  late final TextEditingController _searchController = TextEditingController(
    text: context.read<InventoryCubit>().state.query,
  );
  late final ScrollController _scrollController = ScrollController()
    ..addListener(_loadNextPageNearEnd);

  @override
  void initState() {
    super.initState();
  }

  void _syncSearchText() {
    final query = context.read<InventoryCubit>().state.query;
    if (_searchController.text == query) return;
    _searchController.value = TextEditingValue(
      text: query,
      selection: TextSelection.collapsed(offset: query.length),
    );
  }

  void _loadNextPageNearEnd() {
    if (!_scrollController.hasClients ||
        _scrollController.position.extentAfter > 320) {
      return;
    }
    unawaited(context.read<InventoryCubit>().loadNextPage());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<InventoryCubit>().setQuery('');
  }

  @override
  Widget build(BuildContext context) {
    return ResponsivePage(
      child: BlocListener<InventoryCubit, InventoryState>(
        listenWhen: (previous, current) => previous.query != current.query,
        listener: (context, state) => _syncSearchText(),
        child: BlocBuilder<InventoryCubit, InventoryState>(
          builder: (context, state) {
            final isLoading = state.isLoading;
            final items = isLoading
                ? state.items.take(5).toList(growable: false)
                : state.visibleItems;
            return CustomScrollView(
              key: const PageStorageKey('inventory-list'),
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InventoryHeader(totalCount: state.items.length),
                      const SizedBox(height: AppDimensions.space16),
                      InventorySearchToolbar(
                        controller: _searchController,
                        showClear: state.query.isNotEmpty,
                        filterCount: state.filter.selectionCount,
                        onChanged: context.read<InventoryCubit>().setQuery,
                        onClear: _clearSearch,
                        onFilterTap: () => showInventoryFilterSheet(context),
                      ),
                      const SizedBox(height: AppDimensions.space12),
                      InventoryStatusFilters(
                        selected: state.quickStatus,
                        onSelected: context
                            .read<InventoryCubit>()
                            .setQuickStatus,
                      ),
                      const SizedBox(height: AppDimensions.space16),
                      InventoryCategoryBar(
                        categories: state.categories,
                        selectedCategories: state.filter.categories,
                        onSelected: context
                            .read<InventoryCubit>()
                            .setBrowseCategory,
                      ),
                      const SizedBox(height: AppDimensions.space16),
                      InventoryResultsHeader(
                        resultCount: items.length,
                        hasFilters:
                            state.quickStatus != null || !state.filter.isEmpty,
                      ),
                      const SizedBox(height: AppDimensions.space8),
                    ],
                  ),
                ),
                if (items.isEmpty)
                  SliverToBoxAdapter(
                    child: InventoryEmptyState(query: state.query),
                  )
                else
                  SliverList.separated(
                    itemCount: items.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppDimensions.space8),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return InventoryItemCard(
                        key: ValueKey(item.routeId),
                        item: item,
                        showCatalogueContext: true,
                        onTap: () => widget.onOpenItem(item),
                      );
                    },
                  ),
                SliverPadding(
                  padding: EdgeInsets.only(
                    bottom: AppDimensions.bottomNavigationScrollClearance(
                      context,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
