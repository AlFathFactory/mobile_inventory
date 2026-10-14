import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'features/alerts/data/repositories/alerts_repository.dart';
import 'features/dashboard/data/repositories/dashboard_repository.dart';
import 'features/inventory/data/repositories/inventory_repository.dart';
import 'features/inventory/data/repositories/item_details_repository.dart';
import 'features/inventory/data/repositories/movement_history_repository.dart';

class MyApp extends StatefulWidget {
  const MyApp({
    super.key,
    this.previewLoadDelay = const Duration(milliseconds: 650),
    this.dashboardRepository,
    this.alertsRepository,
    this.inventoryRepository,
    this.itemDetailsRepository,
    this.movementHistoryRepository,
  });

  final Duration previewLoadDelay;
  final DashboardRepository? dashboardRepository;
  final AlertsRepository? alertsRepository;
  final InventoryRepository? inventoryRepository;
  final ItemDetailsRepository? itemDetailsRepository;
  final MovementHistoryRepository? movementHistoryRepository;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppRouter _appRouter = AppRouter(
    previewLoadDelay: widget.previewLoadDelay,
    dashboardRepository: widget.dashboardRepository,
    alertsRepository: widget.alertsRepository,
    inventoryRepository: widget.inventoryRepository,
    itemDetailsRepository: widget.itemDetailsRepository,
    movementHistoryRepository: widget.movementHistoryRepository,
  );

  @override
  void dispose() {
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
        child: child ?? const SizedBox.shrink(),
      ),
      routerConfig: _appRouter.router,
    );
  }
}
