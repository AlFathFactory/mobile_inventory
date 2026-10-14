import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/data/repositories/load_state.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/widgets/app_components.dart';
import '../controller/dashboard_controller.dart';
import 'dashboard_view.dart';

/// Composition root for the Dashboard tab: owns the controller, maps its
/// load state onto loading/failure/data UI, and keeps `DashboardView`
/// purely presentational.
class DashboardRouteView extends StatefulWidget {
  const DashboardRouteView({
    required this.controller,
    required this.onShowInventory,
    required this.onShowAlerts,
    required this.onShowReports,
    super.key,
  });

  final DashboardController controller;
  final ValueChanged<String?> onShowInventory;
  final VoidCallback onShowAlerts;
  final VoidCallback onShowReports;

  @override
  State<DashboardRouteView> createState() => _DashboardRouteViewState();
}

class _DashboardRouteViewState extends State<DashboardRouteView> {
  @override
  void initState() {
    super.initState();
    unawaited(widget.controller.load());
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final state = widget.controller.state;
        return switch (state.status) {
          DataLoadStatus.success => DashboardView(
            metrics: state.data!.metrics,
            categories: state.data!.categories,
            attentionItems: state.data!.attentionItems,
            recentMovements: state.data!.recentMovements,
            onShowInventory: widget.onShowInventory,
            onShowAlerts: widget.onShowAlerts,
            onShowReports: widget.onShowReports,
          ),
          DataLoadStatus.failure => Scaffold(
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
                      onPressed: widget.controller.load,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          DataLoadStatus.initial ||
          DataLoadStatus.loading ||
          DataLoadStatus.empty => const Scaffold(
            body: SafeArea(child: Center(child: CircularProgressIndicator())),
          ),
        };
      },
    );
  }
}
