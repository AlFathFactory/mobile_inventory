import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/alerts/controller/alerts_controller.dart';
import '../../features/alerts/view/alerts_view.dart';
import '../../features/dashboard/view/dashboard_view.dart';
import '../../features/inventory/controller/inventory_controller.dart';
import '../../features/inventory/model/inventory_item.dart';
import '../../features/inventory/view/inventory_view.dart';
import '../../features/inventory/view/item_details_view.dart';
import '../../features/inventory/view/movement_history_view.dart';
import '../../features/reports/controller/reports_controller.dart';
import '../../features/reports/view/reports_view.dart';
import '../data/preview_data.dart';
import 'app_shell.dart';
import 'app_routes.dart';
import 'not_found_view.dart';

class AppRouter {
  AppRouter({required Duration previewLoadDelay}) {
    unawaited(inventoryController.loadPreviewData(delay: previewLoadDelay));
  }

  final rootNavigatorKey = GlobalKey<NavigatorState>();
  final inventoryController = InventoryController(
    items: PreviewData.catalogItems,
  );
  final alertsController = AlertsController(PreviewData.alertItems);
  final reportsController = ReportsController(PreviewData.reportMovements);

  late final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutePaths.dashboard,
    errorBuilder: (context, state) => const NotFoundView(),
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(
          navigationShell: navigationShell,
          loadingController: inventoryController,
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutePaths.dashboard,
                name: AppRouteNames.dashboard,
                builder: (context, state) => DashboardView(
                  metrics: PreviewData.dashboardMetrics,
                  categories: PreviewData.categories,
                  attentionItems: PreviewData.alertItems,
                  recentMovements: PreviewData.reportMovements
                      .take(3)
                      .toList(growable: false),
                  onShowInventory: (category) {
                    if (category == null) {
                      inventoryController.clearFilters();
                    } else {
                      inventoryController.filterByCategory(category);
                    }
                    context.goNamed(AppRouteNames.inventory);
                  },
                  onShowAlerts: () => context.goNamed(AppRouteNames.alerts),
                  onShowReports: () => context.goNamed(AppRouteNames.reports),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutePaths.inventory,
                name: AppRouteNames.inventory,
                builder: (context, state) => InventoryView(
                  controller: inventoryController,
                  onOpenItem: (item) => _openItem(context, item),
                ),
                routes: [
                  GoRoute(
                    parentNavigatorKey: rootNavigatorKey,
                    path: ':code',
                    name: AppRouteNames.itemDetails,
                    builder: (context, state) {
                      final item = _findItem(state.pathParameters['code']);
                      if (item == null) return const NotFoundView();
                      return ItemDetailsView(
                        item: item,
                        movements: PreviewData.movementsFor(item.code),
                      );
                    },
                    routes: [
                      GoRoute(
                        parentNavigatorKey: rootNavigatorKey,
                        path: 'history',
                        name: AppRouteNames.itemHistory,
                        builder: (context, state) {
                          final item = _findItem(state.pathParameters['code']);
                          if (item == null) return const NotFoundView();
                          return MovementHistoryView(
                            item: item,
                            movements: PreviewData.movementsFor(item.code),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutePaths.alerts,
                name: AppRouteNames.alerts,
                builder: (context, state) => AlertsView(
                  controller: alertsController,
                  onOpenItem: (item) => _openItem(context, item),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutePaths.reports,
                name: AppRouteNames.reports,
                builder: (context, state) =>
                    ReportsView(controller: reportsController),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  InventoryItem? _findItem(String? code) {
    if (code == null) return null;
    for (final item in PreviewData.items) {
      if (item.code == code) return item;
    }
    return null;
  }

  void _openItem(BuildContext context, InventoryItem item) {
    context.pushNamed(
      AppRouteNames.itemDetails,
      pathParameters: {'code': item.code},
    );
  }

  void dispose() {
    router.dispose();
    inventoryController.dispose();
    alertsController.dispose();
    reportsController.dispose();
  }
}
