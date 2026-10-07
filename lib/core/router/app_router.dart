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
  bool _isOpeningItem = false;

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
                  onShowInventory: (category) =>
                      _showInventory(context, category),
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
                        onBack: () =>
                            _closeItemDetails(context, state.extra as String?),
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
                            onBack: () => _closeMovementHistory(context, item),
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
    // The detail page is presented above the selected tab. Keep one push in
    // flight so a rapid double tap cannot duplicate it on the root navigator.
    if (_isOpeningItem || _findItem(item.code) == null) return;

    FocusManager.instance.primaryFocus?.unfocus();
    _isOpeningItem = true;
    context
        .pushNamed<void>(
          AppRouteNames.itemDetails,
          pathParameters: {'code': item.code},
          extra: _originRouteFor(context),
        )
        .then<void>(
          (_) => _isOpeningItem = false,
          onError: (_, _) => _isOpeningItem = false,
        );
  }

  void _showInventory(BuildContext context, String? category) {
    // Dashboard data is local preview data, but tolerate a stale category if
    // this entry point is ever fed by a route or refreshed data source.
    if (category != null && inventoryController.categories.contains(category)) {
      inventoryController.filterByCategory(category);
    } else {
      inventoryController.clearFilters();
    }
    context.goNamed(AppRouteNames.inventory);
  }

  String _originRouteFor(BuildContext context) {
    return switch (GoRouterState.of(context).matchedLocation) {
      AppRoutePaths.alerts => AppRouteNames.alerts,
      AppRoutePaths.reports => AppRouteNames.reports,
      _ => AppRouteNames.inventory,
    };
  }

  void _closeItemDetails(BuildContext context, String? fallbackRoute) {
    if (router.canPop()) {
      router.pop();
      return;
    }
    context.goNamed(fallbackRoute ?? AppRouteNames.inventory);
  }

  void _closeMovementHistory(BuildContext context, InventoryItem item) {
    if (router.canPop()) {
      router.pop();
      return;
    }
    context.goNamed(
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
