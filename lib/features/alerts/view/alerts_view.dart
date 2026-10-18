import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/responsive_page.dart';
import '../../inventory/model/inventory_item.dart';
import '../cubit/alerts_cubit.dart';
import '../cubit/alerts_state.dart';
import '../widgets/alert_item_card.dart';
import '../widgets/alerts_empty_state.dart';
import '../widgets/alerts_header.dart';
import '../widgets/alerts_overview.dart';
import '../widgets/alerts_status_filters.dart';

class AlertsView extends StatelessWidget {
  const AlertsView({required this.onOpenItem, super.key});

  final ValueChanged<InventoryItem> onOpenItem;

  @override
  Widget build(BuildContext context) {
    return ResponsivePage(
      child: BlocBuilder<AlertsCubit, AlertsState>(
        builder: (context, state) {
          final items = state.items;
          final summary = state.summary;
          return NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification.metrics.extentAfter < 320) {
                unawaited(context.read<AlertsCubit>().loadNextPage());
              }
              return false;
            },
            child: CustomScrollView(
              key: const PageStorageKey('alerts-list'),
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AlertsHeader(
                        totalCount: summary.lowCount + summary.outOfStockCount,
                      ),
                      const SizedBox(height: AppDimensions.space16),
                      AlertsOverview(summary: summary),
                      const SizedBox(height: AppDimensions.space12),
                      AlertsStatusFilters(
                        selected: state.selectedStatus,
                        onSelected: context.read<AlertsCubit>().selectStatus,
                      ),
                      const SizedBox(height: AppDimensions.space16),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'الأصناف المحتاجة انتباه',
                              style: AppTextStyles.sectionTitle,
                            ),
                          ),
                          Text(
                            '${items.length}',
                            textDirection: TextDirection.ltr,
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.space8),
                    ],
                  ),
                ),
                if (items.isEmpty)
                  SliverToBoxAdapter(
                    child: AlertsEmptyState(isFiltering: state.isFiltering),
                  )
                else
                  SliverList.separated(
                    itemCount: items.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppDimensions.space8),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return AlertItemCard(
                        key: ValueKey('alert-${item.routeId}'),
                        item: item,
                        onTap: () => onOpenItem(item),
                      );
                    },
                  ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 12)),
              ],
            ),
          );
        },
      ),
    );
  }
}
