import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/data/repositories/data_result.dart';
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

  void _syncSearchText() {
    final query = context.read<InventoryCubit>().state.query;
    if (_searchController.text == query) return;
    _searchController.value = TextEditingValue(
      text: query,
      selection: TextSelection.collapsed(offset: query.length),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
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
            final items = state.visibleItems;
            return CustomScrollView(
              key: const PageStorageKey('inventory-list'),
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InventoryHeader(totalCount: state.items.length),
                      if (state.isCached) ...[
                        const SizedBox(height: AppDimensions.space8),
                        Text(
                          'تُعرض بيانات المخزون المحفوظة على هذا الجهاز'
                          '${state.lastSuccessfulSync == null ? '' : ' · آخر مزامنة: ${state.lastSuccessfulSync!.toLocal()}'}',
                        ),
                      ],
                      if (state.refreshFailure != null ||
                          (state.failure != null && items.isNotEmpty))
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'تعذر تحديث البيانات. قد تكون النسخة المعروضة قديمة.',
                          ),
                        ),
                      if (state.refreshSucceeded == true)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text('تم تحديث بيانات المخزون'),
                        ),
                      if (state.isServerBacked &&
                          (items.isNotEmpty || state.isCached)) ...[
                        const SizedBox(height: AppDimensions.space8),
                        OutlinedButton.icon(
                          onPressed: state.isRefreshing
                              ? null
                              : () => context.read<InventoryCubit>().refresh(),
                          icon: state.isRefreshing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.refresh),
                          label: const Text('تحديث'),
                        ),
                      ],
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
                if (isLoading && items.isEmpty)
                  const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (state.failure != null && items.isEmpty)
                  SliverToBoxAdapter(
                    child: Center(
                      child: Column(
                        children: [
                          Text(switch (state.failure!.kind) {
                            DataFailureKind.offline =>
                              'لا يوجد اتصال بالإنترنت',
                            DataFailureKind.unavailable =>
                              'تعذر الوصول إلى خدمة البيانات',
                            _ => 'تعذر تحميل المخزون',
                          }),
                          const SizedBox(height: 8),
                          Text(
                            state.failure!.kind == DataFailureKind.offline
                                ? 'لا توجد بيانات مخزون محفوظة على هذا الجهاز حتى الآن. اتصل بالإنترنت وحاول مرة أخرى.'
                                : state.failure!.message,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: state.isLoading
                                ? null
                                : () => context.read<InventoryCubit>().retry(),
                            child: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (items.isEmpty)
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
                if (state.isLoadingMore)
                  const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (state.hasMore)
                  SliverToBoxAdapter(
                    child: Center(
                      child: OutlinedButton(
                        onPressed: state.isRefreshing
                            ? null
                            : () =>
                                  context.read<InventoryCubit>().loadNextPage(),
                        child: Text(
                          state.loadMoreFailure == null
                              ? 'عرض المزيد'
                              : 'تعذر تحميل المزيد، إعادة المحاولة',
                        ),
                      ),
                    ),
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
