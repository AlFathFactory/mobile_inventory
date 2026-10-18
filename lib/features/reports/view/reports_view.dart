import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/data/repositories/load_state.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/widgets/responsive_page.dart';
import '../cubit/reports_cubit.dart';
import '../cubit/reports_state.dart';
import '../widgets/report_date_range_picker.dart';
import '../widgets/report_filters.dart';
import '../widgets/reports_empty_state.dart';
import '../widgets/reports_header.dart';
import '../widgets/reports_movement_list.dart';
import '../widgets/reports_overview.dart';
import '../widgets/reports_period_selector.dart';
import '../widgets/reports_results_header.dart';

class ReportsView extends StatelessWidget {
  const ReportsView({this.controller, super.key});
  final ReportsCubit? controller;
  Future<void> _pick(BuildContext context) async {
    final cubit = context.read<ReportsCubit>();
    final value = await showReportDateRangePicker(
      context: context,
      initialRange: cubit.state.dateRange,
    );
    if (value != null) cubit.selectDateRange(value);
  }

  @override
  Widget build(BuildContext context) => controller == null
      ? _content(context)
      : BlocProvider.value(
          value: controller!,
          child: Builder(builder: _content),
        );

  Widget _content(BuildContext context) => ResponsivePage(
    child: BlocBuilder<ReportsCubit, ReportsState>(
      builder: (context, state) {
        final cubit = context.read<ReportsCubit>();
        final movements = state.movements;
        return NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n.metrics.extentAfter < 320) unawaited(cubit.loadNextPage());
            return false;
          },
          child: CustomScrollView(
            key: const PageStorageKey('reports-list'),
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ReportsHeader(totalCount: state.snapshot.total),
                    const SizedBox(height: AppDimensions.space16),
                    ReportsOverview(snapshot: state.snapshot),
                    const SizedBox(height: AppDimensions.space12),
                    ReportsPeriodSelector(
                      period: state.period,
                      hasCustomRange: state.dateRange != null,
                      onSelectPeriod: cubit.selectPeriod,
                      onPickCustom: () => _pick(context),
                    ),
                    const SizedBox(height: AppDimensions.space12),
                    ReportFilters(controller: cubit),
                    const SizedBox(height: AppDimensions.space16),
                    ReportsResultsHeader(
                      count: movements.length,
                      hasActiveFilters: state.hasActiveFilters,
                      onClear: cubit.clearFilters,
                    ),
                    const SizedBox(height: AppDimensions.space8),
                  ],
                ),
              ),
              if (state.isLoading && movements.isEmpty)
                const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state.status == DataLoadStatus.failure &&
                  movements.isEmpty)
                SliverToBoxAdapter(
                  child: Center(child: Text('تعذر تحميل التقارير.')),
                )
              else if (movements.isEmpty)
                SliverToBoxAdapter(
                  child: ReportsEmptyState(
                    hasActiveFilters: state.hasActiveFilters,
                  ),
                )
              else
                SliverToBoxAdapter(
                  child: ReportsMovementList(movements: movements),
                ),
              if (state.isLoadingMore)
                const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 12)),
            ],
          ),
        );
      },
    ),
  );
}
