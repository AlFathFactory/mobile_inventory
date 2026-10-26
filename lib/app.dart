import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_theme.dart';
import 'core/widgets/connection_overlay.dart';
import 'core/router/app_router.dart';
import 'core/router/app_routes.dart';
import 'features/alerts/data/repositories/alerts_repository.dart';
import 'features/dashboard/data/repositories/dashboard_repository.dart';
import 'features/inventory/data/repositories/inventory_repository.dart';
import 'features/inventory/data/repositories/item_details_repository.dart';
import 'features/inventory/data/repositories/movement_history_repository.dart';
import 'features/reports/data/repositories/reports_repository.dart';

class MyApp extends StatefulWidget {
  const MyApp({
    super.key,
    this.previewLoadDelay = const Duration(milliseconds: 650),
    this.dashboardRepository,
    this.alertsRepository,
    this.inventoryRepository,
    this.itemDetailsRepository,
    this.movementHistoryRepository,
    this.reportsRepository,
    this.connectionLost = false,
    this.isRetryingConnection = false,
    this.onRetryConnection,
    this.initialLocation,
    this.onLocationChanged,
  });

  final Duration previewLoadDelay;
  final DashboardRepository? dashboardRepository;
  final AlertsRepository? alertsRepository;
  final InventoryRepository? inventoryRepository;
  final ItemDetailsRepository? itemDetailsRepository;
  final MovementHistoryRepository? movementHistoryRepository;
  final ReportsRepository? reportsRepository;
  final bool connectionLost;
  final bool isRetryingConnection;
  final VoidCallback? onRetryConnection;
  final String? initialLocation;
  final ValueChanged<String>? onLocationChanged;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppRouter _appRouter = AppRouter(
    previewLoadDelay: widget.previewLoadDelay,
    initialLocation: widget.initialLocation ?? AppRoutePaths.dashboard,
    dashboardRepository: widget.dashboardRepository,
    alertsRepository: widget.alertsRepository,
    inventoryRepository: widget.inventoryRepository,
    itemDetailsRepository: widget.itemDetailsRepository,
    movementHistoryRepository: widget.movementHistoryRepository,
    reportsRepository: widget.reportsRepository,
  );

  @override
  void initState() {
    super.initState();
    _appRouter.router.routeInformationProvider.addListener(_reportLocation);
  }

  void _reportLocation() {
    widget.onLocationChanged?.call(
      _appRouter.router.routeInformationProvider.value.uri.toString(),
    );
  }

  @override
  void dispose() {
    _appRouter.router.routeInformationProvider.removeListener(_reportLocation);
    _appRouter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'مراقبة المخزون',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: Stack(
          children: [
            child ?? const SizedBox.shrink(),
            if (widget.connectionLost)
              Positioned.fill(
                child: ConnectionOverlay(
                  isRetrying: widget.isRetryingConnection,
                  onRetry: widget.onRetryConnection,
                ),
              ),
          ],
        ),
      ),
      routerConfig: _appRouter.router,
    );
  }
}
