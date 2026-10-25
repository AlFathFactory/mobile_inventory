import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_dimensions.dart';
import '../../../core/widgets/app_loading_skeleton.dart';
import '../../../core/widgets/app_components.dart';
import '../cubit/dashboard_cubit.dart';
import '../cubit/dashboard_state.dart';
import 'dashboard_view.dart';

/// Maps Cubit state onto loading/failure/data UI and keeps `DashboardView`
/// purely presentational.
class DashboardRouteView extends StatelessWidget {
  const DashboardRouteView({
    required this.onShowInventory,
    required this.onShowAlerts,
    required this.onShowReports,
    super.key,
  });

  final ValueChanged<String?> onShowInventory;
  final VoidCallback onShowAlerts;
  final VoidCallback onShowReports;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        return switch (state.status) {
          DashboardStatus.success => DashboardView(
            metrics: state.data!.metrics,
            categories: state.data!.categories,
            attentionItems: state.data!.attentionItems,
            recentMovements: state.data!.recentMovements,
            onShowInventory: onShowInventory,
            onShowAlerts: onShowAlerts,
            onShowReports: onShowReports,
          ),
          DashboardStatus.failure => Scaffold(
            body: SafeArea(
              child: ResponsivePage(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    EmptyState(
                      title: 'تعذر تحميل لوحة المتابعة',
                      message: state.failure!.message,
                      icon: Icons.cloud_off_outlined,
                    ),
                    const SizedBox(height: AppDimensions.space12),
                    TextButton.icon(
                      key: const Key('retry-dashboard'),
                      onPressed: context.read<DashboardCubit>().retry,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          DashboardStatus.initial || DashboardStatus.loading => const Scaffold(
            body: SafeArea(child: AppLoadingSkeleton()),
          ),
        };
      },
    );
  }
}
