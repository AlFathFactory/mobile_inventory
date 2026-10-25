import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../core/data/repositories/data_result.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/widgets/recovery_panel.dart';
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
  late final TextEditingController _searchController;
  bool _scrollGestureActive = false;
  bool _paginationTriggeredThisGesture = false;

  static const _loadingItem = InventoryItem(
    code: 'ITEM-000',
    name: 'صنف من المخزون',
    category: 'المخزون',
    project: 'المشروع',
    quantity: 10,
    minimum: 2,
  );

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: context.read<InventoryCubit>().state.query,
    );
  }

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

  bool _handleScroll(ScrollNotification notification) {
    if (notification.depth != 0) return false;
    if (notification is ScrollStartNotification &&
        notification.dragDetails != null) {
      _scrollGestureActive = true;
      _paginationTriggeredThisGesture = false;
    }
    if (notification is ScrollEndNotification) {
      _scrollGestureActive = false;
    }
    final movingTowardEnd = switch (notification) {
      ScrollUpdateNotification(:final scrollDelta) => (scrollDelta ?? 0) > 0,
      OverscrollNotification(:final overscroll) => overscroll > 0,
      _ => false,
    };
    if (!_scrollGestureActive ||
        _paginationTriggeredThisGesture ||
        !movingTowardEnd ||
        notification.metrics.extentAfter > 300) {
      return false;
    }
    final cubit = context.read<InventoryCubit>();
    final state = cubit.state;
    if (state.hasMore &&
        !state.isLoading &&
        !state.isLoadingMore &&
        !state.isRefreshing) {
      _paginationTriggeredThisGesture = true;
      unawaited(cubit.loadNextPage());
    }
    return false;
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
            final failure = state.failure;
            if (failure != null &&
                items.isEmpty &&
                !isLoading &&
                !state.isCached) {
              return Column(
                children: [
                  const InventoryHeader(totalCount: 0),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        child: RecoveryPanel(
                          icon: failure.kind == DataFailureKind.offline
                              ? Icons.wifi_off_rounded
                              : Icons.cloud_off_rounded,
                          title: switch (failure.kind) {
                            DataFailureKind.offline =>
                              'لا يوجد اتصال بالإنترنت',
                            DataFailureKind.unavailable =>
                              'تعذر الوصول إلى خدمة البيانات',
                            _ => 'تعذر تحميل المخزون',
                          },
                          message: switch (failure.kind) {
                            DataFailureKind.offline =>
                              'لا توجد بيانات مخزون محفوظة على هذا الجهاز حتى الآن. تحقق من اتصالك بالإنترنت وحاول مرة أخرى.',
                            DataFailureKind.unavailable =>
                              'خدمة البيانات غير متاحة حاليًا. حاول مرة أخرى بعد قليل.',
                            _ =>
                              'حدث خطأ أثناء تحميل بيانات المخزون. حاول مرة أخرى.',
                          },
                          onRetry: () => context.read<InventoryCubit>().retry(),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
            return NotificationListener<ScrollNotification>(
              onNotification: _handleScroll,
              child: RefreshIndicator(
                onRefresh: () => context.read<InventoryCubit>().refresh(),
                child: CustomScrollView(
                  key: const PageStorageKey('inventory-list'),
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InventoryHeader(totalCount: state.items.length),
                          if (state.isCached) ...[
                            const SizedBox(height: AppDimensions.space8),
                            Text(
                              'دون اتصال: تُعرض الأصناف التي فُتحت صفحاتها سابقًا فقط. قد لا تشمل نتائج البحث كل المخزون'
                              '${state.lastSuccessfulSync == null ? '' : ' · آخر حفظ: ${state.lastSuccessfulSync!.toLocal()}'}',
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
                          const SizedBox(height: AppDimensions.space16),
                          InventorySearchToolbar(
                            controller: _searchController,
                            showClear: state.query.isNotEmpty,
                            filterCount: state.filter.selectionCount,
                            onChanged: context.read<InventoryCubit>().setQuery,
                            onClear: _clearSearch,
                            onFilterTap: () =>
                                showInventoryFilterSheet(context),
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
                                state.quickStatus != null ||
                                !state.filter.isEmpty,
                          ),
                          const SizedBox(height: AppDimensions.space8),
                        ],
                      ),
                    ),
                    if (isLoading && items.isEmpty)
                      SliverToBoxAdapter(
                        child: Skeletonizer(
                          enabled: true,
                          child: Column(
                            children: [
                              for (var index = 0; index < 3; index++) ...[
                                const InventoryItemCard(
                                  item: _loadingItem,
                                  showCatalogueContext: true,
                                ),
                                const SizedBox(height: AppDimensions.space8),
                              ],
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
                    else if (state.loadMoreFailure != null)
                      SliverToBoxAdapter(
                        child: Center(
                          child: Text(
                            'تعذر تحميل المزيد. اسحب لأعلى للمحاولة مرة أخرى',
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
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
