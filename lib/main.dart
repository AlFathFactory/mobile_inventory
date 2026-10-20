import 'package:flutter/material.dart';

import 'app.dart';
import 'core/data/local/hive_cache_database.dart';
import 'core/data/services/supabase_bootstrap.dart';
import 'features/inventory/data/local/inventory_local_data_source.dart';
import 'features/alerts/data/repositories/alerts_repository_factory.dart';
import 'features/dashboard/data/repositories/dashboard_repository_factory.dart';
import 'features/inventory/data/repositories/inventory_repository_factory.dart';
import 'features/inventory/data/repositories/item_details_repository_factory.dart';
import 'features/inventory/data/repositories/movement_history_repository_factory.dart';
import 'features/reports/data/repositories/reports_repository_factory.dart';

export 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final client = await SupabaseBootstrap.initialize();
  final inventoryLocalDataSource = client == null
      ? null
      : HiveInventoryLocalDataSource(
          await HiveCacheDatabase.initializeFlutter(),
        );
  final dashboardRepository = DashboardRepositoryFactory.create(client);
  final alertsRepository = AlertsRepositoryFactory.create(client);
  final inventoryRepository = InventoryRepositoryFactory.create(
    client,
    localDataSource: inventoryLocalDataSource,
  );
  final itemDetailsRepository = ItemDetailsRepositoryFactory.create(client);
  final movementHistoryRepository = MovementHistoryRepositoryFactory.create(
    client,
  );
  final reportsRepository = ReportsRepositoryFactory.create(client);
  runApp(
    MyApp(
      dashboardRepository: dashboardRepository,
      alertsRepository: alertsRepository,
      inventoryRepository: inventoryRepository,
      itemDetailsRepository: itemDetailsRepository,
      movementHistoryRepository: movementHistoryRepository,
      reportsRepository: reportsRepository,
    ),
  );
}
