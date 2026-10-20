import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/alerts/cubit/alerts_cubit.dart';
import '../../features/alerts/data/repositories/alerts_repository.dart';
import '../../features/alerts/data/repositories/preview_alerts_repository.dart';
import '../../features/alerts/view/alerts_view.dart';
import '../../features/dashboard/cubit/dashboard_cubit.dart';
import '../../features/dashboard/data/repositories/dashboard_repository.dart';
import '../../features/dashboard/data/repositories/preview_dashboard_repository.dart';
import '../../features/dashboard/view/dashboard_route_view.dart';
import '../../features/inventory/cubit/inventory_cubit.dart';
import '../../features/inventory/data/repositories/inventory_repository.dart';
import '../../features/inventory/data/repositories/item_details_repository.dart';
import '../../features/inventory/data/repositories/movement_history_repository.dart';
import '../../features/inventory/data/repositories/preview_inventory_repository.dart';
import '../../features/inventory/model/inventory_item.dart';
import '../../features/inventory/model/inventory_movement.dart';
import '../../features/inventory/view/inventory_view.dart';
import '../../features/inventory/view/item_details_route_view.dart';
import '../../features/reports/cubit/reports_cubit.dart';
import '../../features/reports/data/repositories/preview_reports_repository.dart';
import '../../features/reports/data/repositories/reports_repository.dart';
import '../../features/reports/view/reports_view.dart';
import '../data/preview_data.dart';
import 'app_shell.dart';
import 'app_routes.dart';
import 'not_found_view.dart';

class AppRouter {
  AppRouter({
    required Duration previewLoadDelay,
    DashboardRepository? dashboardRepository,
    AlertsRepository? alertsRepository,
    InventoryRepository? inventoryRepository,
    ItemDetailsRepository? itemDetailsRepository,
    MovementHistoryRepository? movementHistoryRepository,
    ReportsRepository? reportsRepository,
  }) : itemDetailsRepository =
           itemDetailsRepository ?? const PreviewInventoryRepository(),
       movementHistoryRepository =
           movementHistoryRepository ?? const PreviewInventoryRepository(),
       alertsCubit = AlertsCubit(
         repository: alertsRepository ?? const PreviewAlertsRepository(),
       ),
       dashboardCubit = DashboardCubit(
         repository: dashboardRepository ?? const PreviewDashboardRepository(),
       ),
       inventoryCubit = _createInventoryCubit(inventoryRepository),
       reportsCubit = ReportsCubit.withRepository(
         repository: reportsRepository ?? const PreviewReportsRepository(),
         clock:
             reportsRepository == null ||
                 reportsRepository is PreviewReportsRepository
             ? (() => DateTime(2026, 8, 16))
             : DateTime.now,
       ) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scheduleMicrotask(() {
        if (_disposed) return;
        unawaited(
          dashboardCubit.load(
            delay:
                dashboardRepository == null ||
                    dashboardRepository is PreviewDashboardRepository
                ? previewLoadDelay
                : Duration.zero,
          ),
        );
        unawaited(inventoryCubit.loadPreviewData(delay: previewLoadDelay));
        unawaited(
          alertsCubit.load(
            delay:
                alertsRepository == null ||
                    alertsRepository is PreviewAlertsRepository
                ? previewLoadDelay
                : Duration.zero,
          ),
        );
        unawaited(
          reportsCubit.load(
            delay:
                reportsRepository == null ||
                    reportsRepository is PreviewReportsRepository
                ? previewLoadDelay
                : Duration.zero,
          ),
        );
      });
    });
  }

  final rootNavigatorKey = GlobalKey<NavigatorState>();
  final DashboardCubit dashboardCubit;
  final InventoryCubit inventoryCubit;
  final AlertsCubit alertsCubit;
  final ItemDetailsRepository itemDetailsRepository;
  final MovementHistoryRepository movementHistoryRepository;
  final ReportsCubit reportsCubit;
  bool _isOpeningItem = false;
  bool _disposed = false;

  late final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutePaths.dashboard,
    errorBuilder: (context, state) => const NotFoundView(),
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutePaths.dashboard,
                name: AppRouteNames.dashboard,
                builder: (context, state) => BlocProvider.value(
                  value: dashboardCubit,
                  child: DashboardRouteView(
                    onShowInventory: (category) =>
                        _showInventory(context, category),
                    onShowAlerts: () => context.goNamed(AppRouteNames.alerts),
                    onShowReports: () => context.goNamed(AppRouteNames.reports),
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutePaths.inventory,
                name: AppRouteNames.inventory,
                builder: (context, state) => BlocProvider.value(
                  value: inventoryCubit,
                  child: InventoryView(
                    onOpenItem: (item) => _openItem(context, item),
                  ),
                ),
                routes: [
                  GoRoute(
                    parentNavigatorKey: rootNavigatorKey,
                    path: ':code',
                    name: AppRouteNames.itemDetails,
                    builder: (context, state) {
                      return ItemDetailsRouteView(
                        routeId: state.pathParameters['code'] ?? '',
                        repository: itemDetailsRepository,
                        movementRepository: movementHistoryRepository,
                        onBack: () => _closeItemDetails(
                          context,
                          _validOriginRoute(state.extra),
                        ),
                      );
                    },
                  ),
                  GoRoute(
                    parentNavigatorKey: rootNavigatorKey,
                    path: ':code/history',
                    name: AppRouteNames.itemHistory,
                    builder: (context, state) {
                      final routeId = state.pathParameters['code'] ?? '';
                      final extra = state.extra;
                      final initialItem =
                          extra is InventoryItem && extra.routeId == routeId
                          ? extra
                          : null;
                      return ItemHistoryRouteView(
                        routeId: routeId,
                        repository: itemDetailsRepository,
                        movementRepository: movementHistoryRepository,
                        initialItem: initialItem,
                        onBack: (item) => _closeMovementHistory(
                          context,
                          item,
                          directRoute: initialItem == null,
                        ),
                      );
                    },
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
                builder: (context, state) => BlocProvider.value(
                  value: alertsCubit,
                  child: AlertsView(
                    onOpenItem: (item) => _openItem(context, item),
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutePaths.reports,
                name: AppRouteNames.reports,
                builder: (context, state) => BlocProvider.value(
                  value: reportsCubit,
                  child: ReportsView(
                    onOpenMovement: (movement) {
                      _openMovement(context, movement);
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  static InventoryCubit _createInventoryCubit(InventoryRepository? repository) {
    if (repository == null || repository is PreviewInventoryRepository) {
      return InventoryCubit(
        items: PreviewData.catalogItems,
        repository: repository ?? const PreviewInventoryRepository(),
      );
    }
    return InventoryCubit(repository: repository, serverBacked: true);
  }

  InventoryItem? _findItem(String? routeId) {
    if (routeId == null) return null;
    for (final item in inventoryCubit.state.items) {
      if (item.routeId == routeId ||
          (!item.hasBackendIdentity && item.code == routeId)) {
        return item;
      }
    }
    if (!inventoryCubit.state.isServerBacked) {
      for (final item in PreviewData.items) {
        if (item.routeId == routeId) return item;
      }
    }
    return null;
  }

  void _openItem(BuildContext context, InventoryItem item) {
    // The detail page is presented above the selected tab. Keep one push in
    // flight so a rapid double tap cannot duplicate it on the root navigator.
    if (_isOpeningItem ||
        (!item.hasBackendIdentity && _findItem(item.routeId) == null)) {
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    _isOpeningItem = true;
    context
        .pushNamed<void>(
          AppRouteNames.itemDetails,
          pathParameters: {'code': item.routeId},
          extra: _originRouteFor(context),
        )
        .then<void>(
          (_) => _isOpeningItem = false,
          onError: (_, _) => _isOpeningItem = false,
        );
  }

  void _openMovement(BuildContext context, InventoryMovement movement) {
    final routeId = movement.itemRouteId;
    if (routeId == null || _isOpeningItem) return;
    FocusManager.instance.primaryFocus?.unfocus();
    _isOpeningItem = true;
    context
        .pushNamed<void>(
          AppRouteNames.itemDetails,
          pathParameters: {'code': routeId},
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
    if (category != null &&
        (inventoryCubit.state.isServerBacked ||
            inventoryCubit.state.categories.contains(category))) {
      inventoryCubit.filterByCategory(category);
    } else {
      inventoryCubit.clearFilters(includeQuery: true);
    }
    context.goNamed(AppRouteNames.inventory);
  }

  String? _validOriginRoute(Object? extra) {
    if (extra is! String) return null;
    return switch (extra) {
      AppRouteNames.inventory ||
      AppRouteNames.alerts ||
      AppRouteNames.reports => extra,
      _ => null,
    };
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

  void _closeMovementHistory(
    BuildContext context,
    InventoryItem item, {
    required bool directRoute,
  }) {
    if (!directRoute && router.canPop()) {
      router.pop();
      return;
    }
    context.goNamed(
      AppRouteNames.itemDetails,
      pathParameters: {'code': item.routeId},
    );
  }

  void dispose() {
    _disposed = true;
    router.dispose();
    dashboardCubit.close();
    inventoryCubit.close();
    alertsCubit.close();
    reportsCubit.close();
  }
}
